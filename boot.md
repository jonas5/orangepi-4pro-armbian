# Orange Pi 4 Pro (Allwinner A733 / sun60iw2) Booting Guide for Mainline Linux 7.1.5

This technical guide summarizes all required fixes, architectural details, and configuration settings for booting mainline Linux kernels (7.1.5) on the Orange Pi 4 Pro single-board computer.

---

## 1. Overview & Board Architecture

* **SoC**: Allwinner A733 (`sun60iw2`, 8-core Cortex-A73/A53, GICv3, 12 GB LPDDR5).
* **Boot Chain**:
  `BOOT0` $\rightarrow$ `ATF BL31` (32-bit U-Boot) $\rightarrow$ `Mainline Linux kernel 7.1.5`

  1. **BOOT0**: Primary bootloader residing in internal ROM/SRAM. Initializes basic system clocks and the LPDDR5 DRAM controller.
  2. **ATF BL31 (32-bit U-Boot)**: ARM Trusted Firmware BL31 initializes EL3 runtime services and transfers control to the vendor 32-bit U-Boot (2018.05 branch) running in AArch32 mode at entry point `0x41000000`.
  3. **Mainline Linux Kernel 7.1.5**: 64-bit ARM64 (`aarch64`) kernel booted in AArch64 EL2/EL1 mode via the `booti` command.

---

## 2. DRAM Memory Layout & Load Addresses

To ensure successful booting, DRAM load addresses must use non-overlapping memory ranges within the 32-bit address space accessible by U-Boot.

### Memory Layout Table

| Address Variable | DRAM Load Address | Offset / Size Buffer | Description |
| :--- | :--- | :--- | :--- |
| `kernel_addr_r` | `0x41000000` | Base Address | Aligns with ATF BL31 jump target `0x41000000`. Holds the uncompressed kernel `Image`. |
| `fdt_addr_r` | `0x4a000000` | +160 MB | Placed at a 160 MB offset into DRAM (`0x4a000000`). Holds the Flattened Device Tree (DTB). |
| `ramdisk_addr_r` | `0x4b000000` | +176 MB (+16 MB buffer) | Positioned at a 176 MB offset into DRAM (`0x4b000000`). Holds the initial RAM disk image (`uInitrd`). |

### Rationale & Fixes

* **ATF Jump Alignment**: ATF BL31 passes execution to U-Boot / Kernel jump target at `0x41000000`. Setting `kernel_addr_r = 0x41000000` matches this hardware expectation.
* **Initrd Image Overwrite Prevention**: Default vendor environment settings placed `ramdisk_addr_r` at `0x43000000`. A ~42.6 MB uncompressed kernel image loaded at `0x41000000` expands past `0x43600000`, completely corrupting an ~8.7 MB initrd image located at `0x43000000`. Relocating `ramdisk_addr_r` to `0x4b000000` guarantees a safe 160 MB space for kernel decompression and a 16 MB buffer before the initrd image.

---

## 3. U-Boot Relocation & DTB Overrides

### Disabling Relocation (`fdt_high` and `initrd_high`)

```uboot
setenv fdt_high "off"
setenv initrd_high "off"
```

* **Purpose**: Disables DTB and initrd high memory relocation in 32-bit U-Boot.
* **Problem Solved**: Vendor U-Boot operates in 32-bit mode. By default, U-Boot attempts to relocate the DTB and initrd to top-of-RAM addresses (e.g., `0x4fa00000`). In 32-bit mode, this triggers allocation/space errors (`FDT_ERR_NOSPACE`) and memory corruption around `0x4fa00000`. Setting `fdt_high = "off"` and `initrd_high = "off"` forces U-Boot to pass the DTB and initrd in-place at `fdt_addr_r` (`0x4a000000`) and `ramdisk_addr_r` (`0x4b000000`).

### Overriding Zero-RAM Bug in Vendor U-Boot

```uboot
fdt addr ${fdt_addr_r}
fdt resize 0x10000
fdt set /memory reg <0x0 0x40000000 0x3 0x00000000>
```

* **Purpose**: Overrides vendor U-Boot's zero-RAM bug in the Device Tree memory node.
* **Problem Solved**: Vendor U-Boot contains a bug where `bi_dram[0].size = 0`. Prior to booting the kernel, U-Boot's automatic DTB fixup overwrote the `/memory` node in the DTB with 0 bytes of RAM, causing the Linux kernel to panic immediately upon boot.
* **Fix Details**: The command `fdt set /memory reg <0x0 0x40000000 0x3 0x00000000>` explicitly configures 12 GB of LPDDR5 RAM starting at physical address `0x40000000` (Base = `0x0000000040000000`, Size = `0x0000000300000000` / 12 GiB).

---

## 4. Hardware UART & Earlycon Configuration

### Debug Header Identification

* Physical 3-pin debug header `J7104` is connected to **`UART0`** (pins **PB9** [TX] / **PB10** [RX], MMIO base address `0x02500000`).
* **Note**: Do NOT confuse `J7104` (`UART0`) with `UART2` (MMIO `0x02502000`), which is mapped to the 40-pin GPIO header.

### Device Tree Nodes & Clock Configuration

In the device tree source (`.dts`):

```dts
/ {
    aliases {
        serial0 = &uart0;
    };

    chosen {
        stdout-path = "serial0:115200n8";
    };
};

&uart0 {
    pinctrl-names = "default";
    pinctrl-0 = <&uart0_pb_pins>;
    status = "okay";
    clock-frequency = <24000000>;
};
```

* **Clock Frequency**: `clock-frequency = <24000000>;` specifies the 24 MHz APB1 clock. This ensures U-Boot and the Linux 8250 serial driver compute the exact baud divisor of `13` ($24\,000\,000 / (16 \times 115\,200) \approx 13.02$) for clean 115,200 baud communication.

### Kernel Boot Arguments (Bootargs)

```text
earlycon=uart8250,mmio32,0x02500000,115200n8,24000000 console=ttyS0,115200n8
```

### Kernel Earlycon Driver Declaration

In `drivers/tty/serial/8250/8250_early.c`, register the A733 earlycon compatibility string:

```c
OF_EARLYCON_DECLARE(sun60i_uart, "allwinner,sun60i-a733-uart", early_serial8250_setup);
```

---

## 5. GICv3 Interrupt Controller Base Addresses

The Allwinner A733 incorporates an ARM Generic Interrupt Controller v3 (GICv3). The Distributor and Redistributor base addresses and region sizes must be specified as follows:

| GICv3 Subsystem | Physical Base Address | Size | Description |
| :--- | :--- | :--- | :--- |
| **GICD (Distributor)** | `0x03000000` | `0x10000` (64 KiB) | Manages interrupt distribution and global control across all CPUs. |
| **GICR (Redistributor)** | `0x03080000` | `0x200000` (2 MiB) | Serves 8 CPU redistributor frames (256 KiB per CPU core). |

### Device Tree Definition

```dts
gic: interrupt-controller@3000000 {
    compatible = "arm,gic-v3";
    reg = <0x0 0x03000000 0x0 0x010000>,   /* GICD: 64 KiB */
          <0x0 0x03080000 0x0 0x200000>;  /* GICR: 2 MiB (8 CPUs) */
    interrupt-controller;
    #interrupt-cells = <3>;
    interrupts = <GIC_PPI 9 IRQ_TYPE_LEVEL_HIGH>;
};
```

---

## 6. Kernel Page Table & Architecture Settings

Mainline Linux kernel configuration options must align with the A733 core architecture and memory layout:

```ini
CONFIG_ARM64_4K_PAGES=y
CONFIG_ARM64_VA_BITS_48=y
CONFIG_PGTABLE_LEVELS=4
```

### Key Technical Considerations

* **`CONFIG_ARM64_4K_PAGES=y`**: Selects standard 4 KiB memory page translation granules.
* **`CONFIG_ARM64_VA_BITS_48=y` & `CONFIG_PGTABLE_LEVELS=4`**: Configures a 48-bit Virtual Address space managed via 4-level page tables.
* **Avoid 5-Level LPA2 Tables**: Do NOT enable 52-bit virtual addressing or LPA2 (`CONFIG_ARM64_PA_BITS_52` / 5-level page tables). Attempting to boot Cortex-A73/A53 cores with 5-level page table configurations results in immediate kernel panics during early MMU initialisation.

---

## 7. Complete Working `boot.cmd` Template

Here is the complete, production-ready `boot.cmd` script for booting mainline Linux 7.1.5 on the Orange Pi 4 Pro:

```uboot
# Orange Pi 4 Pro (Allwinner A733 / sun60iw2) - Mainline Linux 7.1.5 Boot Script

# 1. Define non-overlapping DRAM load addresses
setenv kernel_addr_r  "0x41000000"
setenv fdt_addr_r     "0x4a000000"
setenv ramdisk_addr_r "0x4b000000"

# 2. Disable DTB and initrd relocation in 32-bit U-Boot
setenv fdt_high "off"
setenv initrd_high "off"

# 3. Import additional environment settings if available
if ext4load mmc 0:1 ${kernel_addr_r} /boot/orangepiEnv.txt; then
    env import -t ${kernel_addr_r} ${filesize}
fi

# 4. Determine root filesystem PARTUUID
part uuid mmc 0:1 rootdev

# 5. Build kernel command line (bootargs)
setenv consoleargs "earlycon=uart8250,mmio32,0x02500000,115200n8,24000000 console=ttyS0,115200n8"
setenv bootargs "root=PARTUUID=${rootdev} rootwait rw rootfstype=ext4 loglevel=${verbosity} ${consoleargs} cma=${cma} ${extraargs}"

# 6. Optional charger mode flag
if test -n "${charger_mode}"; then
    setenv bootargs "${bootargs} charger_mode=${charger_mode}"
fi

# 7. Load images from boot partition into DRAM
ext4load mmc 0:1 ${ramdisk_addr_r} /boot/uInitrd
setenv initrd_size ${filesize}
ext4load mmc 0:1 ${kernel_addr_r}  /boot/Image
ext4load mmc 0:1 ${fdt_addr_r}      /boot/dtb/allwinner/sun60i-a733-orangepi-4-pro.dtb

# 8. Apply DTB fixups
fdt addr ${fdt_addr_r}
fdt resize 0x10000

# Override vendor U-Boot zero-RAM bug: define 12 GB RAM starting at 0x40000000
fdt set /memory reg <0x0 0x40000000 0x3 0x00000000>

# 9. Boot kernel
booti ${kernel_addr_r} ${ramdisk_addr_r}:${initrd_size} ${fdt_addr_r}
```

### Compilation Command

To produce the compiled binary image `boot.scr`:

```bash
mkimage -C none -A arm -T script -d boot.cmd boot.scr
```

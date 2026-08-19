# Orange Pi 4 Pro — Armbian Build Overlay

Build Armbian images for the **Orange Pi 4 Pro** with mainline Linux 7.1.5 kernel on Allwinner A733 (sun60iw2).

## Hardware

| Component | Details |
|-----------|---------|
| SoC | Allwinner A733 — 2× Cortex-A76 + 6× Cortex-A55, Mali Bifrost GPU |
| RAM | 2/4/8/16 GB LPDDR4X |
| Storage | eMMC (MMC2, 8-bit), microSD (MMC0), SPI NOR flash (16MB) |
| Ethernet | Gigabit (GMAC0, RGMII, RTL8211F) |
| WiFi/BT | AIC8800D80 (SDIO + UART HCI) |
| USB | 1× USB3 Type-C (OTG), 2× USB2 Type-A (EHCI/OHCI) |
| PCIe | x1 Gen3 (RC mode, via combo PHY) |
| Display | MIPI DSI (800×1280, Goodix GT9271 touchscreen) |
| Audio | ES8388 codec (I2C @0x10 + I2S4), 3.5mm headphone jack |
| PMIC | AXP8191 (main DCDC/ALDO/BLDO/CLDO/DLDO/ELDO) + AXP515 (battery/charging) |
| Serial | UART0 debug (115200), UART1 BT HCI, UART2 expansion |
| LEDs | Green status LED (PI8) |

## Pre-built Images

Download from [GitHub Releases](https://github.com/jonas5/orangepi-4pro-armbian-build/releases):

| Image | Size | Release |
|-------|------|---------|
| `Orangepi4pro_1.0.7_debian_bookworm_server_linux7.1.5.img.xz` | 752 MB | Bookworm server |
| `Orangepi4pro_1.0.7_ubuntu_noble_server_linux7.1.5.img.xz` | 673 MB | Noble server |

Flash to SD card with `dd` or [balenaEtcher](https://etcher.balena.io/).

## Building Your Own Image

### Prerequisites

- x86_64 Linux host (Debian/Ubuntu recommended)
- ~25 GB free disk space (more for desktop builds)
- Root access or `sudo` (for loopback mounts and chroot)
- Internet connection

Install dependencies:

```bash
sudo apt-get update
sudo apt-get install -y git gcc make bc bison flex libssl-dev \
    libc6-dev-arm64-cross gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
    qemu-user-static binfmt-support dpkg-dev
# For U-Boot x86-64 toolchain emulation:
sudo dpkg --add-architecture amd64
sudo apt-get update
sudo apt-get install -y libc6:amd64
```

Enable binfmt (allows running x86-64 U-Boot tools on arm64 hosts):

```bash
sudo systemctl restart systemd-binfmt
```

### Step 1: Clone Armbian Build System

```bash
git clone --depth=1 https://github.com/armbian/build.git armbian-build
cd armbian-build
```

### Step 2: Clone This Overlay

```bash
git clone https://github.com/jonas5/orangepi-4pro-armbian-build.git orangepi4pro-overlay
```

### Step 3: Apply the Overlay

```bash
./orangepi4pro-overlay/scripts/apply-overlay.sh ./armbian-build
```

This copies board config, kernel config, kernel patch, and firmware into the Armbian build tree.

### Step 4: Build

**Server image (Bookworm):**

```bash
sudo ./compile.sh \
    BOARD=orangepi4pro \
    BRANCH=next \
    RELEASE=bookworm \
    BUILD_DESKTOP=no \
    BUILD_MINIMAL=yes \
    KERNEL_CONFIGURE=no \
    NO_HOST_RELEASE_CHECK=yes \
    COMPRESS_OUTPUTIMAGE=no \
    BUILD_OPT=image
```

**Server image (Noble):**

```bash
sudo ./compile.sh \
    BOARD=orangepi4pro \
    BRANCH=next \
    RELEASE=noble \
    BUILD_DESKTOP=no \
    BUILD_MINIMAL=yes \
    KERNEL_CONFIGURE=no \
    NO_HOST_RELEASE_CHECK=yes \
    COMPRESS_OUTPUTIMAGE=no \
    BUILD_OPT=image
```

**Desktop image (Bookworm, GNOME):**

```bash
sudo ./compile.sh \
    BOARD=orangepi4pro \
    BRANCH=next \
    RELEASE=bookworm \
    BUILD_DESKTOP=yes \
    DESKTOP_ENVIRONMENT=gnome \
    DESKTOP_APPGROUPS_SELECTED="browsers editors multimedia" \
    KERNEL_CONFIGURE=no \
    NO_HOST_RELEASE_CHECK=yes \
    COMPRESS_OUTPUTIMAGE=no \
    BUILD_OPT=image
```

Images are written to `output/images/`.

### Build Options Reference

| Option | Description |
|--------|-------------|
| `BOARD=orangepi4pro` | Board name |
| `BRANCH=next` | Use mainline Linux 7.1.5 (`current` = vendor 5.15 kernel) |
| `RELEASE=bookworm\|noble` | Debian Bookworm or Ubuntu Noble |
| `BUILD_DESKTOP=no\|yes` | Server or desktop image |
| `BUILD_MINIMAL=yes` | Minimal server image (smaller, fewer packages) |
| `KERNEL_CONFIGURE=no` | Use pre-made defconfig (recommended) |
| `NO_HOST_RELEASE_CHECK=yes` | Required when building on non-matching host distro |
| `COMPRESS_OUTPUTIMAGE=no` | Don't xz-compress output (builds faster) |
| `BUILD_OPT=image` | Required for non-interactive builds |

## Repository Structure

```
orangepi-4pro-armbian-build/
├── config/
│   ├── boards/
│   │   └── orangepi4pro.conf          # Board definition
│   ├── kernel/
│   │   └── linux-sun60iw2-next-a733.config  # Kernel config (all drivers built-in)
│   └── sources/families/
│       └── sun60iw2.conf              # Family config (kernel source, U-Boot, tweaks)
├── patch/
│   ├── kernel/sun60iw2-next/
│   │   └── opi4pro-7.1.5.patch        # Kernel patch (46 files, ~12K lines)
│   └── u-boot/u-boot-sunxi/
│       └── 0001-u-boot-disable-werror-gcc14.patch  # U-Boot GCC14 compat fix
├── firmware/
│   ├── install-firmware.sh            # Firmware installer for target system
│   ├── aic8800d80/                    # AIC8800 WiFi + BT firmware (8 files)
│   ├── npu/libVIPhal.so               # Allwinner NPU HAL library
│   └── bt-tools/
│       ├── brcm_patchram_plus         # Broadcom BT UART firmware loader
│       └── hciattach_opi              # Orange Pi BT HCI attach utility
└── scripts/
    └── apply-overlay.sh               # Overlay installer
```

## Hardware Features (from Device Tree)

### Peripherals Enabled

| Peripheral | Status | Details |
|------------|--------|---------|
| UART0 | ✅ | Debug console, 115200 baud (PH8/PH9) |
| UART1 | ✅ | Bluetooth HCI with RTS/CTS (PG6–PG9) |
| UART2 | ✅ | Expansion header (PB0/PB1) |
| I2C0 (TWI0) | ✅ | AXP515 PMIC @0x34 (PB2/PB3) |
| I2C9 (TWI5) | ✅ | Goodix GT9271 touchscreen @0x14 (PJ25 IRQ, PG10 reset) |
| R_I2C0 | ✅ | AXP8191 PMIC @0x36 + ES8388 audio codec @0x10 (PL0/PL1) |
| MMC0 | ✅ | microSD card, 4-bit, CD on PF6, WP on PF2 |
| MMC1 | ✅ | WiFi SDIO (AIC8800), 4-bit, DDR/HS200, power seq on PI9 |
| MMC2 | ✅ | eMMC, 8-bit, HS200/DDR, non-removable |
| SPI0 | ✅ | NOR flash (16MB), 3 partitions: u-boot, env, root |
| GMAC0 | ✅ | Gigabit Ethernet, RGMII, TX delay=12, RX delay=10, PHY @1 |
| USB OTG | ✅ | Type-C, OTG mode (DWC3) |
| USB EHCI/OHCI | ✅ | 2× USB2 host ports (PH11 reset) |
| PCIe | ✅ | x1 Gen3 RC mode (PH11 reset) |
| GPU | ✅ | Mali Bifrost, Panfrost driver, DCDC2 supply |
| CE | ✅ | Crypto engine |
| THS | ✅ | Thermal sensor (PB12) |
| RTC | ✅ | Real-time clock |
| IOMMU | ✅ | SMMU |
| HWSpinlock | ✅ | Hardware spinlock |
| MSGBOX | ✅ | Inter-processor mailbox |
| NMI INTC | ✅ | Non-maskable interrupt controller |

### Power Management

**AXP8191** (main PMIC, R_AON bus @0x36):

| Rail | Output | Voltage | Always-on |
|------|--------|---------|-----------|
| DCDC1 | VDD_SYS | 1.0–3.8V | Yes |
| DCDC2 | VDD_CPUA (A55) | 0.5–1.54V | Yes |
| DCDC3 | VDD_CPUB (A76) | 0.5–1.54V | Yes |
| DCDC4 | — | 0.5–1.54V | Yes |
| DCDC5 | — | 0.5–1.54V | Yes |
| DCDC6 | VDD_GPU | 0.5–2.76V | Yes |
| DCDC7 | VDD_DRAM | 0.5–1.84V | Yes |
| DCDC8 | VDD_PLL | 0.5–3.4V | Yes |
| DCDC9 | — | 0.5–3.4V | Yes |
| ALDO1–6 | Various analog | 0.5–3.4V | Mixed |
| BLDO1–5 | Various digital | 0.5–3.4V | Mixed |
| CLDO1–5 | Various core | 0.5–3.5V | Mixed |
| DLDO1–6 | Various I/O | 0.5–3.4V | Mixed |
| ELDO1–6 | Various ext | 0.5–3.4V | Mixed |

**AXP515** (battery/charging PMIC, I2C0 @0x34):

| Rail | Output | Voltage |
|------|--------|---------|
| DLDO1–4 | 1.8V always-on | 1.8V |
| ELDO1–2 | 1.8V always-on | 1.8V |
| Drive VBUS | USB OTG VBUS | 5V |

### WiFi / Bluetooth

- **AIC8800D80** combo module
- WiFi: SDIO on MMC1 (PG0–PG5), power sequence via PI9
- BT: UART HCI on UART1 (PG6–PG9), firmware loaded via `brcm_patchram_plus`
- Firmware files: `/lib/firmware/aic8800d80/` (8 files)
- Kernel modules: `aic8800_fdrv`, `aic8800_btlpm`

### Audio

- **ES8388** codec @0x10 on R_I2C0 (PL0/PL1)
- I2S4 data bus (PK0–PK4)
- MCLK from CCU CLK_AUDIO (24.576 MHz)
- 3.5mm headphone jack output
- PulseAudio HDMI + Audio Codec sinks configured for desktop

### Touchscreen

- **Goodix GT9271** @0x14 on I2C9 (PJ26/PJ27)
- IRQ: PJ25 (level-high), Reset: PG10 (active-high)
- Resolution: 1280×800, axes inverted and swapped to match panel

### Display

- MIPI DSI0 (PD0–PD9), 4-lane
- Panel: 800×1280 (portrait)
- HDMI output supported but not default panel
- LVDS, RGB parallel, EDP interfaces available in SoC

### SPI NOR Flash (16MB)

| Partition | Offset | Size | Contents |
|-----------|--------|------|----------|
| u-boot | 0x000000 | 0xF0000 (960KB) | U-Boot bootloader |
| env | 0xF0000 | 0x10000 (64KB) | U-Boot environment |
| root | 0x100000 | 0xF00000 (15MB) | Spare/root |

### Ethernet

- GMAC0, RGMII mode
- External PHY: RTL8211F @MDIO address 1
- TX delay: 12, RX delay: 10
- PHY power: 3.3V fixed regulator (PB13 enable)

## Kernel Configuration

All drivers are built-in (=y), no kernel modules required except WiFi:

```
PREEMPT=y, HZ_250, SMP=y, 64BIT=y
BT=y, BT_HCIUART=y, BT_HCIUART_BCSP=y
PCIE_DW=y, PCIe Gen3
MMC=y, MMC_HS200_1_8V=y, MMC_DDR_1_8V=y
DRM=y, GPU_PANFROST=y
CRYPTO=y, CRYPTO_DEV_SUN8I_CE=y
THERMAL=y
NET=y, STMMAC_ETH=y, PCS=y
USB=y, USB_DWC3=y, USB_EHCI=y, USB_OHCI=y
```

The defconfig enables every peripheral on the board. See `config/kernel/linux-sun60iw2-next-a733.config` for the full list.

## U-Boot

Uses Allwinner vendor U-Boot (2018.05-sun60iw2 branch). Mainline U-Boot does not yet support the A733.

The build process:
1. Compiles U-Boot with `arm-linux-gnueabi-gcc`
2. Compiles board DTS with `dtc` (via QEMU x86-64 emulation on arm64 hosts)
3. Merges `boot0_sdcard.fex` + `boot_package.fex` into final bootloader image
4. Supports SD card and SPI NOR boot

## Firmware Installation

On a running system, install WiFi/BT/NPU firmware:

```bash
sudo ./firmware/install-firmware.sh
```

This installs:
- `/lib/firmware/aic8800d80/` — AIC8800 WiFi + BT firmware (8 files)
- `/usr/lib/libVIPhal.so` — Allwinner NPU HAL library
- `/usr/bin/brcm_patchram_plus` — Broadcom BT UART firmware loader
- `/usr/bin/hciattach_opi` — Orange Pi BT HCI attach utility

## Kernel Source Tree

The kernel patch and standalone build instructions are in the companion repo:

**[jonas5/orangepi-4pro-armbian](https://github.com/jonas5/orangepi-4pro-armbian/tree/linux-7.1.5-opi4pro)**

This contains:
- Unified patch: `opi4pro-7.1.5.patch` (46 files, DTS/DTSI, defconfig, drivers)
- Device tree: `sun60i-a733-orangepi-4-pro.dts`
- All driver sources: CCU, pinctrl, MMC, PHY, DRM, Ethernet, PMIC, thermal, crypto, audio
- Firmware files and installer
- Complete pin mapping documentation

To build the kernel standalone (without Armbian):

```bash
git clone --depth=1 --branch v7.1.5 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git linux-7.1.5
cd linux-7.1.5
git clone https://github.com/jonas5/orangepi-4pro-armbian.git --branch linux-7.1.5-opi4pro --depth=1 repo
patch -p1 < repo/patch/opi4pro-7.1.5.patch
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- orangepi_4pro_defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
```

Output:
- `arch/arm64/boot/Image` — kernel image
- `arch/arm64/boot/dts/allwinner/sun60i-a733-orangepi-4-pro.dtb` — device tree blob

## Known Limitations

- **NPU**: requires vendor HAL (`libVIPhal.so`); open-source support not available
- **Camera/ISP**: not supported (complex multi-unit pipeline)
- **GPU**: Mali Bifrost uses Panfrost driver — functional but no vendor userspace
- **HDMI audio**: not configured (HDMI video works)
- **Bluetooth**: requires firmware loading via `brcm_patchram_plus` or `hciattach_opi`
- **WS2812 RGB LED** (LEDC): not configured by default
- **No mainline U-Boot**: uses vendor 2018.05 U-Boot (no upstream A733 support yet)

## License

GPL-2.0-or-later — consistent with the Linux kernel source tree.

## Disclaimer

**USE AT YOUR OWN RISK.** This repository, its patches, scripts, and documentation are provided "as is" without warranty of any kind. The authors and contributors are not responsible for any damage, data loss, bricked hardware, or other consequences resulting from the use or misuse of this material. Applying kernel patches, modifying device trees, and flashing firmware carry inherent risks including but not limited to hardware damage and loss of warranty. By using this repository you acknowledge that:

- You are solely responsible for any changes you make to your system.
- You should back up all important data before proceeding.
- You should verify compatibility with your specific hardware revision before applying changes.
- Nothing here constitutes legal, financial, or professional advice.

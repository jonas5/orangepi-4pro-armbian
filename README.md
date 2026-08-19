# Orange Pi 4 Pro — Armbian Build (Linux 7.1.5)

Armbian build configuration for the **Orange Pi 4 Pro** (Allwinner A733) with **Linux 7.1.5** mainline kernel support.

## Overview

This repository provides the files needed to build Armbian images for the Orange Pi 4 Pro using Linux 7.1.5. It is designed as an overlay on top of the official [Armbian build system](https://github.com/armbian/build).

## Hardware

| Component | Details |
|-----------|---------|
| SoC | Allwinner A733 (sun60iw2) — 2x Cortex-A76 + 6x Cortex-A55 |
| RAM | 8/16 GB LPDDR4X |
| WiFi/BT | AIC8800D80 (SDIO + UART HCI) |
| Ethernet | Gigabit (GMAC0, RGMII) |
| Storage | eMMC, microSD, SPI NOR flash |
| USB | 1x USB3 Type-C, 2x USB2 Type-A |
| Display | MIPI DSI (800×1280) |
| Audio | ES8388 codec (I2S4) |
| PMIC | AXP8191 + AXP515 |

## Quick Start

### 1. Clone the Armbian build system

```bash
git clone --depth=1 https://github.com/armbian/build armbian-build
cd armbian-build
```

### 2. Apply this overlay

```bash
# Copy board definition
cp /path/to/orangepi-4pro-armbian/config/boards/orangepi4pro.conf \
   external/config/boards/orangepi4pro.conf

# Copy kernel config
cp /path/to/orangepi-4pro-armbian/config/kernel/linux-sun60iw2-next-a733.config \
   external/config/kernel/

# Copy kernel patch
mkdir -p external/patch/kernel/sun60iw2-next
cp /path/to/orangepi-4pro-armbian/patch/kernel/sun60iw2-next/opi4pro-7.1.5.patch \
   external/patch/kernel/sun60iw2-next/

# Copy firmware
cp -r /path/to/orangepi-4pro-armbian/firmware/* external/cache/sources/
```

### 3. Build

```bash
sudo ./compile.sh \
  BOARD=orangepi4pro \
  BRANCH=current \
  RELEASE=bookworm \
  BUILD_DESKTOP=no \
  KERNEL_ONLY=no
```

### 4. Install firmware on the built image

After building, mount the SD card image and run:

```bash
sudo ./firmware/install-firmware.sh /mnt/sdcard
```

## Files

```
orangepi-4pro-armbian/
├ README.md
├ config/
│  ├── boards/
│  │  └── orangepi4pro.conf            # Board definition
│  ├── kernel/
│  │  └── linux-sun60iw2-next-a733.config  # Kernel config for 7.1.5
│  └── sources/
│     └── families/
│        └── sun60iw2-next.inc         # Family config overrides for 7.1.5
├ patch/
│  └── kernel/
│     └── sun60iw2-next/
│        └── opi4pro-7.1.5.patch       # Kernel patch (46 files, 12K lines)
├ firmware/
│  ├── install-firmware.sh             # Firmware installer
│  ├── aic8800d80/                     # AIC8800 WiFi/BT firmware
│  ├── npu/                            # NPU HAL library
│  └── bt-tools/                       # Bluetooth tools
└ scripts/
   └── apply-overlay.sh               # Helper to apply overlay to Armbian tree
```

## Building Standalone (without Armbian)

If you prefer to build the kernel directly:

```bash
git clone --depth=1 --branch v7.1.5 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git linux-7.1.5
cd linux-7.1.5
patch -p1 < /path/to/opi4pro-7.1.5.patch
make orangepi_4pro_defconfig
make -j$(nproc)
```

See [linux-opi4pro-a733](https://github.com/jonas5/orangepi-4pro-armbian) for standalone kernel builds and pre-built .deb packages.

## Kernel Patch

The patch (`opi4pro-7.1.5.patch`) is a unified diff against Linux v7.1.5 that adds:

- **Device tree**: `sun60i-a733-orangepi-4-pro.dts` + `sun60i-a733.dtsi`
- **Drivers**: CCU, pinctrl, MMC, GMAC, PHY, MFD/regulator, DRM, thermal, crypto, sound
- **Defconfig**: `orangepi_4pro_defconfig`
- **Makefile/Kconfig**: All necessary build system entries

All drivers compile cleanly against v7.1.5 with 0 warnings, 0 errors.

## Firmware

The `firmware/` directory contains:

- **AIC8800 WiFi/BT**: 8 firmware files extracted from vendor Android BSP
- **NPU HAL**: `libVIPhal.so` (Allwinner vendor library)
- **BT tools**: `brcm_patchram_plus` and `hciattach_opi`

Run `firmware/install-firmware.sh` to deploy to a rootfs.

## License

GPL-2.0-or-later — consistent with the Linux kernel source tree.

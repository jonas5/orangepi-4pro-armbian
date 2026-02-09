# 📘 README.md — Orange Pi 4 Pro Armbian Mainline Build

## 🧩 Overview

This repository contains a custom Armbian board definition for the **Orange Pi 4 Pro (Allwinner A733 / sun60iw2)**, enabling reproducible builds of **mainline Linux (6.19+)** using the Armbian build framework.

The goal is to provide:

- A clean, minimal, reproducible build environment  
- A fully open DTS/DTSI + patch workflow  
- A safe way to rebuild images without overwriting a working SD card  
- A version‑controlled place for board configs, family configs, kernel configs, and patches  

This repo intentionally excludes all build artifacts, caches, and binary blobs.

---

## 🏗️ Repository Structure
<code>
orangepi-4pro-armbian/
│
├── config/
│   ├── boards/
│   │   └── orangepi-4pro.conf
│   ├── sources/
│   │   └── families/
│   │       └── sun60iw2.conf
│   └── kernel/
│       └── linux-sun60iw2-mainline.config
│
├── patches/
│   ├── kernel/
│   │   └── sun60iw2-mainline/
│   └── u-boot/
│       └── sun60iw2/
│
├── scripts/
│   └── build.sh
│
├── .gitignore
└── README.md
</code>


---

## 🧠 Key Components

### 1. Board Definition (`orangepi-4pro.conf`)

Defines the board‑level metadata used by Armbian:

- `BOARDFAMILY="sun60iw2"`
- Kernel source + branch (mainline stable)
- Kernel config file
- U‑Boot target family

This file contains **only variable assignments**, no functions.

---

### 2. Family Definition (`sun60iw2.conf`)

Implements platform‑specific logic for the Allwinner A733 / sun60iw2 family:

- Declares `LINUXFAMILY="sun60iw2"`
- Enables `BRANCHES="mainline"`
- Disables ATF compilation (`ATF_COMPILE='no'`)
- Disables Armbian’s out‑of‑tree wireless drivers (`SKIP_EXTRA_DRIVERS="yes"`)
- Provides a `write_uboot_platform()` function

#### U‑Boot Handling

Mainline U‑Boot currently does **not** produce a monolithic `u-boot-sunxi-with-spl.bin` for this SoC.

To avoid build failures, the repo uses:
write_uboot_platform() {
echo "Skipping U-Boot write (using existing bootloader)"
return 0
}


This allows the image to boot using the **vendor bootloader** already present on SD/eMMC.

---

### 3. Kernel Configuration

A minimal kernel config is provided:
# config/kernel/linux-sun60iw2-mainline.config


This is used to build Linux 6.19+ with only the essential drivers for early bring‑up.

---

### 4. Patches

All DTS, DTSI, and kernel patches live under:

# patches/kernel/sun60iw2-mainline/

These patches are GPL‑2.0 licensed (matching the kernel) and safe to publish.

**Note:**  
Binary DTB files are *not* included — only source patches.

---

### 5. Build Script

`scripts/build.sh` provides a reproducible build command:
./compile.sh build \
BOARD=orangepi-4pro \
BRANCH=mainline \
BUILD_MINIMAL=yes \
KERNEL_CONFIGURE=no \
RELEASE=bookworm \
SKIP_EXTERNAL_DRIVERS=yes


---

## 🔒 Licensing Notes

All DTS/DTSI files and patches in this repo follow the Linux kernel’s license:
SPDX-License-Identifier: GPL-2.0


This means:

- You are allowed to modify and redistribute them  
- Publishing them on GitHub is fully compliant  
- Only **binary DTB files** are excluded (for safety and clarity)

---

## 🚫 What This Repo Does NOT Contain

To keep the repo clean and safe:

- No `cache/`
- No `output/`
- No `.img` files
- No `.deb` files
- No vendor blobs
- No compiled DTB files
- No boot0 / boot_package.fex
- No proprietary firmware

Everything here is **source only**.

---

## 🚀 Building an Image

Clone Armbian:
git clone https://github.com/armbian/build
cd build
git clone git@github.com:YOURNAME/orangepi-4pro-armbian.git userpatches

Then run:
./userpatches/scripts/build.sh

Your image will appear in:
output/images/



---

## 🧪 Bootloader Strategy

This build currently uses:

- Vendor U‑Boot (from SD/eMMC)
- Mainline kernel 6.19+
- Mainline DTB
- Armbian rootfs

This is the safest approach during early bring‑up.

Switching to full mainline U‑Boot is possible later.

---

## 📡 Why No DTB Files?

DTB binaries are:

- opaque  
- not reviewable  
- potentially dangerous  
- easy to misuse  

Instead, this repo includes:

- DTS  
- DTSI  
- patches  

…which are transparent, safe, and GPL‑compliant.

---

## 🧭 Status

- ✔ Board definition working  
- ✔ Family definition working  
- ✔ Kernel 6.19 builds  
- ✔ Initramfs + uInitrd generated  
- ✔ Image builds successfully  
- ✔ U‑Boot write skipped safely  
- ☐ UART bring‑up  
- ☐ DTS refinement  
- ☐ Regulator/clock/DVFS tuning  
- ☐ HDMI/PCIe/GMAC/WiFi enablement  

















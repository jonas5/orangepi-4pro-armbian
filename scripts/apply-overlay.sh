#!/bin/bash
# apply-overlay.sh — Apply Orange Pi 4 Pro overlay to Armbian build tree
#
# Usage:
#   ./scripts/apply-overlay.sh /path/to/armbian-build
#
# This copies the board definition, kernel config, kernel patch, and firmware
# into the Armbian build tree at the correct locations.

set -euo pipefail

OVERLAY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARMBIAN_DIR="${1:?Usage: $0 /path/to/armbian-build}"

if [[ ! -d "$ARMBIAN_DIR/external/config" ]]; then
    echo "Error: $ARMBIAN_DIR does not look like an Armbian build tree"
    echo "Expected to find external/config/ directory"
    exit 1
fi

echo "Applying Orange Pi 4 Pro overlay to $ARMBIAN_DIR"

# Board definition
echo "  Board definition → external/config/boards/orangepi4pro.conf"
cp "$OVERLAY_DIR/config/boards/orangepi4pro.conf" \
   "$ARMBIAN_DIR/external/config/boards/orangepi4pro.conf"

# Kernel config
echo "  Kernel config → external/config/kernel/linux-sun60iw2-next-a733.config"
cp "$OVERLAY_DIR/config/kernel/linux-sun60iw2-next-a733.config" \
   "$ARMBIAN_DIR/external/config/kernel/"

# Kernel patch
echo "  Kernel patch → external/patch/kernel/sun60iw2-next/"
mkdir -p "$ARMBIAN_DIR/external/patch/kernel/sun60iw2-next"
cp "$OVERLAY_DIR/patch/kernel/sun60iw2-next/opi4pro-7.1.5.patch" \
   "$ARMBIAN_DIR/external/patch/kernel/sun60iw2-next/"

# Firmware
echo "  Firmware → external/cache/sources/firmware/"
mkdir -p "$ARMBIAN_DIR/external/cache/sources/firmware"
cp -r "$OVERLAY_DIR/firmware/"* \
   "$ARMBIAN_DIR/external/cache/sources/firmware/"

echo ""
echo "Overlay applied. Build with:"
echo "  cd $ARMBIAN_DIR"
echo "  sudo ./compile.sh BOARD=orangepi4pro BRANCH=current RELEASE=bookworm BUILD_DESKTOP=no"

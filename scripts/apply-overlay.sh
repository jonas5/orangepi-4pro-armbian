#!/bin/bash
# apply-overlay.sh — Apply Orange Pi 4 Pro overlay to Armbian build tree
#
# Usage:
#   ./scripts/apply-overlay.sh /path/to/armbian-build
#
# Supports both legacy (external/) and new (flat) Armbian build layouts.

set -euo pipefail

OVERLAY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARMBIAN_DIR="${1:?Usage: $0 /path/to/armbian-build}"

# Detect layout: new (flat) or legacy (external/)
if [[ -d "$ARMBIAN_DIR/config/boards" ]]; then
    LAYOUT="flat"
    CFGDIR="$ARMBIAN_DIR/config"
    PATCHDIR="$ARMBIAN_DIR/patch"
elif [[ -d "$ARMBIAN_DIR/external/config" ]]; then
    LAYOUT="external"
    CFGDIR="$ARMBIAN_DIR/external/config"
    PATCHDIR="$ARMBIAN_DIR/external/patch"
else
    echo "Error: $ARMBIAN_DIR does not look like an Armbian build tree"
    echo "Expected config/boards/ or external/config/boards/"
    exit 1
fi

echo "Applying Orange Pi 4 Pro overlay to $ARMBIAN_DIR (layout: $LAYOUT)"

# Board definition
echo "  Board definition → $CFGDIR/boards/orangepi4pro.conf"
mkdir -p "$CFGDIR/boards"
cp "$OVERLAY_DIR/config/boards/orangepi4pro.conf" \
   "$CFGDIR/boards/orangepi4pro.conf"

# Kernel config
echo "  Kernel config → $CFGDIR/kernel/linux-sun60iw2-next-a733.config"
mkdir -p "$CFGDIR/kernel"
cp "$OVERLAY_DIR/config/kernel/linux-sun60iw2-next-a733.config" \
   "$CFGDIR/kernel/"

# Kernel patch
echo "  Kernel patch → $PATCHDIR/kernel/sun60iw2-next/"
mkdir -p "$PATCHDIR/kernel/sun60iw2-next"
cp "$OVERLAY_DIR/patch/kernel/sun60iw2-next/opi4pro-7.1.5.patch" \
   "$PATCHDIR/kernel/sun60iw2-next/"

# Firmware (new layout only — legacy uses cache/)
if [[ "$LAYOUT" == "flat" ]]; then
    echo "  Firmware → packages/firmware/"
    mkdir -p "$ARMBIAN_DIR/packages/firmware"
    cp -r "$OVERLAY_DIR/firmware/"* \
       "$ARMBIAN_DIR/packages/firmware/"
else
    echo "  Firmware → external/cache/sources/firmware/"
    mkdir -p "$ARMBIAN_DIR/external/cache/sources/firmware"
    cp -r "$OVERLAY_DIR/firmware/"* \
       "$ARMBIAN_DIR/external/cache/sources/firmware/"
fi

echo ""
echo "Overlay applied. Build with:"
echo "  cd $ARMBIAN_DIR"
echo "  sudo ./compile.sh BOARD=orangepi4pro BRANCH=next RELEASE=bookworm BUILD_DESKTOP=no BUILD_OPT=image"

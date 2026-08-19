#!/bin/bash
# Install AIC8800 WiFi/BT firmware and NPU userspace for Orange Pi 4 Pro
# Run as root on the target system.
#
# Usage: sudo ./install-firmware.sh [ROOTFS]
#   ROOTFS defaults to / if not specified.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS="${1:-}"

echo "=== Orange Pi 4 Pro Firmware Installer ==="
echo "Target: ${ROOTFS:-/}"
echo ""

# AIC8800 WiFi/BT firmware
echo "[1/3] Installing AIC8800 WiFi/BT firmware..."
mkdir -p "${ROOTFS}/lib/firmware/aic8800d80"
install -m 644 "$SCRIPT_DIR/aic8800d80/"* "${ROOTFS}/lib/firmware/aic8800d80/"

# NPU userspace library
echo "[2/3] Installing NPU HAL library..."
install -m 644 "$SCRIPT_DIR/npu/libVIPhal.so" "${ROOTFS}/usr/lib/"

# Bluetooth tools
echo "[3/3] Installing Bluetooth tools..."
install -m 755 "$SCRIPT_DIR/bt-tools/brcm_patchram_plus" "${ROOTFS}/usr/bin/"
install -m 755 "$SCRIPT_DIR/bt-tools/hciattach_opi" "${ROOTFS}/usr/bin/"

echo ""
echo "=== Firmware installation complete ==="
echo ""
echo "Installed:"
echo "  /lib/firmware/aic8800d80/     - AIC8800 WiFi + BT firmware (8 files)"
echo "  /usr/lib/libVIPhal.so         - Allwinner NPU HAL library"
echo "  /usr/bin/brcm_patchram_plus   - Broadcom BT UART firmware loader"
echo "  /usr/bin/hciattach_opi        - Orange Pi BT HCI attach utility"

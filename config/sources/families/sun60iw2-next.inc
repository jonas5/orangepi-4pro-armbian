# Family overrides for Linux 7.1.5 mainline on Orange Pi 4 Pro
# This file is sourced by sun60iw2.conf when BRANCH=current
#
# Usage: Copy this file's contents into sun60iw2.conf under the 'current)' case,
#        or source it from the family conf.

# --- Paste these lines inside the 'current)' case block in sun60iw2.conf ---

# Override kernel source to mainline 7.1.5
KERNELSOURCE="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"
KERNELBRANCH="tag:v7.1.5"
LINUXCONFIG="linux-sun60iw2-next-a733"
KERNELPATCHDIR="sun60iw2-next"

# Keep existing U-Boot, ATF, overlay settings from sun60iw2.conf
# OVERLAY_PREFIX='sun60i-a733'
# BOOTBRANCH='branch:v2018.05-sun60iw2'
# UBOOT_TARGET_MAP="..."
# etc.

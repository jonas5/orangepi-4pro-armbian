# Orange Pi 4 Pro (Allwinner A733)
BOARD_NAME="Orange Pi 4 Pro"
BOARD_MAINTAINER="community"
BOARD_MAINTAINER_EMAIL=""
BOARDFLAGS=""

# SoC / family
BOARDFAMILY="sun60iw2"
FAMILY="sun60iw2"
ARCH="arm64"

# Kernel selection
# "legacy" = BSP 5.15.x sun60iw2 kernel
KERNEL_TARGET="legacy"

# U-Boot / bootloader
BOOTCONFIG="orangepi_4pro_defconfig"
BOOTLOADER="u-boot"


# Disable vendor U-Boot (Radxa)
UBOOT_USE_GITHUB_BSP="no"
UBOOT_VENDOR="none"


# Device tree (you must ensure this DTB exists in the BSP kernel tree)
FDTFILE="allwinner/sun60i-a733-orangepi-4pro.dtb"

# Image type
IMAGE_TYPE="stable"
DEFAULT_CONSOLE="ttyS0,115200"

# Networking / wireless (adjust once you confirm exact chips)
WIRELESS="yes"
BLUETOOTH="yes"
ETHERNET="yes"

# Storage
SPI="no"
EMMC="yes"
SATA="no"
NVME="yes"
USB="yes"

# Features / capabilities
HAS_HDMI="yes"
HAS_MIPI_DSI="yes"
HAS_MIPI_CSI="yes"
HAS_AUDIO="yes"

# Misc
# Mark as community-supported until tested
SUPPORTED="no"

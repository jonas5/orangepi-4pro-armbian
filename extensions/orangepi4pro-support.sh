# Create UFS aligned image (requires >= Debian 13 (Trixie) Host)
# declare -g DOCKER_ARMBIAN_BASE_IMAGE=debian:trixie # Use this env variable manually
function extension_prepare_config__orangepi4pro {
        display_alert "Copying custom DTS for OPi 4 Pro" "user-extension" "info"

        cp /armbian/arch/arm64/boot/dts/allwinner/sun60i-a733-orangepi-4pro.dts "${LINUXDIR}/arch/arm64/boot/dts/allwinner/"


        EXTENSION="orangepi4pro-dts"
        EXTENSION_DESCRIPTION="Copy custom DTS for Orange Pi 4 Pro"
        EXTENSION_COMPATIBILITY="all"
	EXTRA_IMAGE_SUFFIXES+=("-test")
}

# Armbian boot script for Sunxi / sun60iw2
# Board: Orange Pi 4 Pro (sun60iw2 / sun60i-a733)

setenv kernel_addr_r "0x41000000"
setenv ramdisk_addr_r "0x43000000"
setenv fdt_addr_r "0x4FA00000"
setenv loadaddr "0x40400000"
setenv fdt_high "off"
setenv initrd_high "off"

# Print boot script information
echo "Armbian boot script for Orange Pi 4 Pro (kernel_addr_r=${kernel_addr_r})"

# Default environment values
setenv rootdev "/dev/mmcblk0p1"
setenv rootfstype "ext4"
setenv verbosity "7"
setenv console "both"
setenv earlycon "on"

# Load environment file
if test -e ${devtype} ${devnum}:${distro_bootpart} /boot/armbianEnv.txt; then
	load ${devtype} ${devnum}:${distro_bootpart} ${loadaddr} /boot/armbianEnv.txt
	env import -t ${loadaddr} ${filesize}
elif test -e ${devtype} ${devnum}:${distro_bootpart} /armbianEnv.txt; then
	load ${devtype} ${devnum}:${distro_bootpart} ${loadaddr} /armbianEnv.txt
	env import -t ${loadaddr} ${filesize}
fi

# Ensure kernel_addr_r remains 0x41000000
if test -z "${kernel_addr_r}"; then setenv kernel_addr_r "0x41000000"; fi

# Get root partition UUID if distro_bootpart is available
part uuid ${devtype} ${devnum}:${distro_bootpart} rootdev

if test "${console}" = "display" || test "${console}" = "both"; then setenv consoleargs "console=tty1"; fi
if test "${console}" = "serial" || test "${console}" = "both"; then setenv consoleargs "console=ttyS2,115200n8 ${consoleargs}"; fi
if test "${earlycon}" = "on"; then setenv consoleargs "earlycon=uart8250,mmio32,0x02502000 ${consoleargs}"; fi

setenv bootargs "root=PARTUUID=${rootdev} rootwait rootfstype=${rootfstype} ${consoleargs} ${extraargs} ${extraboardargs}"

# Load initrd / uInitrd
if test -e ${devtype} ${devnum}:${distro_bootpart} /boot/uInitrd; then
	load ${devtype} ${devnum}:${distro_bootpart} ${ramdisk_addr_r} /boot/uInitrd
	setenv initrd_size ${filesize}
elif test -e ${devtype} ${devnum}:${distro_bootpart} /uInitrd; then
	load ${devtype} ${devnum}:${distro_bootpart} ${ramdisk_addr_r} /uInitrd
	setenv initrd_size ${filesize}
else
	setenv ramdisk_addr_r "-"
fi

# Load kernel image
if test -e ${devtype} ${devnum}:${distro_bootpart} /boot/Image; then
	load ${devtype} ${devnum}:${distro_bootpart} ${kernel_addr_r} /boot/Image
elif test -e ${devtype} ${devnum}:${distro_bootpart} /Image; then
	load ${devtype} ${devnum}:${distro_bootpart} ${kernel_addr_r} /Image
elif test -e ${devtype} ${devnum}:${distro_bootpart} /boot/zImage; then
	load ${devtype} ${devnum}:${distro_bootpart} ${kernel_addr_r} /boot/zImage
fi

# Load DTB
if test -e ${devtype} ${devnum}:${distro_bootpart} /boot/dtb/${fdtfile}; then
	load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} /boot/dtb/${fdtfile}
elif test -e ${devtype} ${devnum}:${distro_bootpart} /boot/dtb/allwinner/${fdtfile}; then
	load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} /boot/dtb/allwinner/${fdtfile}
elif test -e ${devtype} ${devnum}:${distro_bootpart} /boot/dtb/allwinner/sun60i-a733-orangepi-4-pro.dtb; then
	load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} /boot/dtb/allwinner/sun60i-a733-orangepi-4-pro.dtb
elif test -e ${devtype} ${devnum}:${distro_bootpart} /dtb/allwinner/sun60i-a733-orangepi-4-pro.dtb; then
	load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} /dtb/allwinner/sun60i-a733-orangepi-4-pro.dtb
fi

fdt addr ${fdt_addr_r}
fdt resize 0x10000

booti ${kernel_addr_r} ${ramdisk_addr_r}:${initrd_size} ${fdt_addr_r}

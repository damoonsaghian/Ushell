echo "this will create a bootable GoboLinux installer, on a removable storage device"
# usage: sh mkinst.sh <target-dir> [<arch>]

target_dir="$1"
[ -z "$target_dir" ] && {
	echo "usage: sh mkinst.sh <target-dir> [<arch>]"
}

arch="$2"
while [ -z "$arch" ]; do
	echo "the following architectures are supported:"
	echo "	1) x86_64"
	echo "	2) aarch64"
	echo "	3) riscv64"
	echo "enter the number of the desired architechture: "
	read -r ans
	case "$ans" in
	1) arch=x86_64 ;;
	2) arch=aarch64 ;;
	3) arch=riscv64 ;;
	esac
done

cd "$target_dir"

# create  an initramfs (for $arch) that includes programs needed to install Uni
# https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage
mkdir initfs
# init, login as root, run install.sh

echo 'acpid
bluez
chrony
cryptsetup
dbus
dinit
doas
dte
eudev
gnunet
linux
netman
pipewire
sbase
sh
upm
tpm2-tools
util-linux
codev-shell
codev' | while read -r pkg_name; do
	ROOT_DIR="$wdir"/initfs sh "$script_dir"/upm.sh install "$pkg_name"
done

echo "bootable installer successfully created"
echo "now boot into the installation media, and follow the instructions"

set -e

if nmcli -v >/dev/null 2>&1; then
	while ! ping -c 2 -w 5 ping.archlinux.org; do
		nmcli d wifi list
		printf "enter the desired SSID: "
		read -r ssid
		nmcli d wifi connect "$ssid"
	done
else
	while ! ping -c 2 -w 5 ping.archlinux.org; do
		wlan_device="$(basename --multiple /sys/class/net/wl* | head -1)"
		iwctl station "$wlan_device" scan
		iwctl station "$wlan_device" get-networks
		printf "enter the desired SSID: "
		read -r ssid
		iwctl station "$wlan_device" connect "$ssid"
	done
fi

[ $(id -u) = 0 ] || {
	echo "non'root installation is not yet implemented"
	exit
	# https://gitlab.postmarketos.org/postmarketOS/coldbrew
}

echo; echo "available storage devices:"
lsblk --nodep -o NAME,SIZE,MODEL,MOUNTPOINTS | while read -r line; do printf "\t$line\n"; done
printf "enter the name of the target device for installation: "
read -r target_device
[ -e /sys/block/"$target_device" ] || {
	echo "there is no storage device named \"$target_device\""
	exit 1
}
# if $target_device is a partition, set it to the parent device
target_device_num="$(cat /sys/class/block/"$target_device"/dev | cut -d ":" -f 1):0"
target_device="$(basename "$(readlink /dev/block/"$target_device_num")")"

sfdisk --quiet --wipe always --label gpt "/dev/$target_device" <<-EOF
size=260M, type=uefi
,
EOF
target_partitions="$(echo /sys/block/"$target_device"/"$target_device"* | sed -n "s/\/sys\/block\/$target_device\///pg")"
target_partition1="$(echo "$target_partitions" | cut -d " " -f1)"
target_partition2="$(echo "$target_partitions" | cut -d " " -f2)"

mkfs.vfat -F 32 /dev/"$target_partition1"
mkfs.btrfs -f /dev/"$target_partition2"

btrfs filesystem mkswapfile --size 4g --uuid clear "$new_root"/var/swapfile
# fstab: /var/swapfile none swap defaults 0 0

mount /dev/"$target_partition2" /mnt
mkdir /mnt/boot
mount /dev/"$target_partition1" /mnt/boot
genfstab -U /mnt >> /mnt/etc/fstab

case "$(uname -m)" in
x86*)
	cpu_vendor_id="$(grep vendor_id /proc/cpuinfo | head -n1 | sed -n "s/vendor_id[[:space:]]*:[[:space:]]*//p")"
	[ "$cpu_vendor_id" = AuthenticAMD ] && ucode=ucode-amd
	[ "$cpu_vendor_id" = GenuineIntel ] && ucode=ucode-intel
;;
esac

chimera-bootstrap "$new_root" base-full-kernel base-full-firmware $ucode systemd-boot linux-stable cryptsetup fwupd bluez \
	base-full-core base-full-console base-full-sound base-full-net-tools networkmanager modemmanager curl \
	btrfs-progs dosfstools util-linux-fdisk util-linux-fstrim util-linux-mkfs \
	chrony opendoas nano less cronie acpid \
	fonts-noto fonts-noto-emoji-ttf fonts-noto-sans-cjk fonts-source-code-pro-otf

chimera-chroot "$new_root" apk add --no-interactive chimera-repo-user
chimera-chroot "$new_root" apk update
chimera-chroot "$new_root" apk add --no-interactive tpm2-tools

# tmp-getkey.sh

# bootup.sh
# run when kernel or systemd-boot are updated

# suspend system with support for hooks (needed for some drivers)
# https://github.com/jirutka/zzz
# doas rules


mkdir -p /mnt/boot/loader/entries
cat <<-EOF > /mnt/boot/loader/loader.conf
default  arch.conf
timeout  0
auto-entries no
editor   no
EOF
root_uuid="$(blkid /dev/"$target_partition2" | sed -nr 's/^.*[[:space:]]+UUID="([^"]*)".*$/\1/p')"
cat <<-EOF > /mnt/boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /$ucode.img
initrd  /initramfs-linux.img
options root=UUID=$root_uuid rw
EOF
cat <<-EOF > /mnt/boot/loader/entries/arch-fallback.conf
title   Arch Linux (fallback initramfs)
linux   /vmlinuz-linux
initrd  /$ucode.img
initrd  /initramfs-linux-fallback.img
options root=UUID=$root_uuid rw
EOF
cat <<-EOF > /mnt/boot/loader/entries/memtest.conf
title Memtest86+
efi /memtest86+/memtest.efi
EOF

chimera-chroot /mnt bootctl install
mkdir -p /mnt/etc/pacman.d/hooks
cat <<-EOF > /mnt/etc/pacman.d/hooks/95-systemd-boot.hook
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd
[Action]
Description = Gracefully upgrading systemd-boot...
When = PostTransaction
Exec = /usr/bin/systemctl restart systemd-boot-update.service
EOF

echo; echo "set root password (can be the same as he one used to encrypt the root partition)"
echo "WARNING! do not use this password carelessly"
echo "in practice, it's only required for manually changing system files, ie almost never"
while ! chimera-chroot "$new_root" passwd; do
	echo "please retry"
done

# create a normal user
chimera-chroot "$new_root" useradd --base-dir / --create-home --shell /usr/local/bin/ushell nu
echo; echo "set lock'screen password"
while ! chimera-chroot "$new_root" passwd nu; do
	echo "please retry"
done

# dinit autologin
ln -s /usr/local/share/util-linux/autologin.sh "$new_root"/usr/local/bin/autologin
chmod +x "$new_root"/usr/local/share/util-linux/autologin.sh

# mono'space fonts:
# , wide characters are forced to squeeze
# , narrow characters are forced to stretch
# , bold characters don't have enough room
# proportional font for code:
# , generous spacing
# , large punctuation
# , and easily distinguishable characters
# , while allowing each character to take up the space that it needs
# Iosevka Aile (just change "I" character)
# "https://github.com/iaolo/iA-Fonts/tree/master/iA%20Writer%20Quattro" (just change "I" character)
# monospace font is still needed for terminal emulator

# strike fiery index-fm maui-station maui-nota maui-pix maui-clip vvave
# qt6-qtbase-printsupport
# kmouth
# communicator

script_dir="$(dirname "$(readlink -f "$0")")"

echo; echo "installation completed successfully"
printf "reboot the system? (Y/n) "
read -r ans
[ "$ans" != n ] && [ "$ans" != no ] && reboot

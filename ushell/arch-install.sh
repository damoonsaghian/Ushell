set -e

while ! ping -c 2 -w 5 ping.archlinux.org; do
	wlan_device="$(basename --multiple /sys/class/net/wl* | head -1)"
	iwctl station "$wlan_device" scan
	iwctl station "$wlan_device" get-networks
	printf "enter the desired SSID: "
	read -r ssid
	iwctl station "$wlan_device" connect "$ssid"
done

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

mount /dev/"$target_partition2" /mnt
mkdir /mnt/boot
mount /dev/"$target_partition1" /mnt/boot
genfstab -U /mnt >> /mnt/etc/fstab

cpu_vendor_id="$(cat /proc/cpuinfo | grep vendor_id | head -n1 | sed -n "s/vendor_id[[:space:]]*:[[:space:]]*//p")"
[ "$cpu_vendor_id" = AuthenticAMD ] && ucode=amd-ucode
[ "$cpu_vendor_id" = GenuineIntel ] && ucode=intel-ucode

pacstrap -K /mnt base $ucode memtest86+-efi linux linux-firmware linux-firmware-marvell wireless-regdb sof-firmware \
	opendoas nano bash-completion man-db btrfs-progs \
	chrony networkmanager bluez bluez-obex pipewire-audio pipewire-pulse wireplumber \
	adobe-source-code-pro-fonts otf-commit-mono-nerd \
	strike fiery index-fm maui-station maui-nota maui-pix maui-clip vvave communicator \
# spectacle
# print-manager
# kmouth
# modemmanager dnsmasq

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

arch-chroot /mnt bootctl install
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

arch-chroot /mnt systemctl enable chronyd systemd-resolved NetworkManager bluetooth obex

ln -sf /usr/share/zoneinfo/Asia/Tehran /mnt/etc/localtime
printf "\nen_US.UTF-8 UTF-8\n" > /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo 'LANG=en_US.UTF-8' > /mnt/etc/locale.conf
echo archlinux > /mnt/etc/hostname

cat <<-'EOF' > /mnt/usr/local/bin/upm
#!/usr/bin/env sh
# wrapper around pacman
case $1 in
install) pacman -S $2 ;;
remove) pacman -Rs $2 ;;
update)
	pacman -Syu
	orphan_pkgs="$(pacman -Qdttq)"
	pacman -Rns $orphan_pkgs
	pacman -Sc
	;;
find) pacman -Ss $2 ;;
esac
EOF
chmod +x /mnt/usr/local/bin/upm
# doas rule for upm

echo -n '#!/usr/bin/env sh
doas $@
' > /mnt/usr/local/bin/sudo

echo; echo "set root password"
while ! arch-chroot /mnt passwd; do
	echo "please retry"
done

# create a normal user
echo
arch-chroot /mnt useradd --base-dir / --create-home --shell /usr/local/bin/ushell nu
echo
echo "set lock'screen password"
while ! arch-chroot /mnt passwd nu; do
	echo "please retry"
done

# autologin

script_dir="$(dirname "$(readlink -f "$0")")"
cp -r "$script_dir"/ushell /mnt/usr/local/share/
echo -n '#!/usr/bin/env sh
[ "$1" = priv ] || {
	run0 setpriv --reuid=nu --regid=nu --groups=input,video,audio sh /usr/local/bin/ushell priv
}
script_dir="$(dirname "$(readlink -f "$0")")"
sh "$script_dir"/ushell.sh
' > /mnt/usr/local/share/ushell/ushell
chmod +x /mnt/usr/local/share/ushell/ushell
ln -sf /usr/local/share/ushell/ushell /mnt/usr/local/bin/
# polkit rule to run0 ushell

exit; reboot

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

printf "WARNING! all the data on \"/dev/$target_device\" will be erased; continue? (y/N) "
read -r answer
[ "$answer" = y ] || exit

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
mkdir /mnt/etc
genfstab -U /mnt > /mnt/etc/fstab

cpu_vendor_id="$(cat /proc/cpuinfo | grep vendor_id | head -n1 | sed -n "s/vendor_id[[:space:]]*:[[:space:]]*//p")"
[ "$cpu_vendor_id" = AuthenticAMD ] && ucode=amd-ucode
[ "$cpu_vendor_id" = GenuineIntel ] && ucode=intel-ucode

pacstrap -K /mnt base $ucode memtest86+-efi linux linux-firmware linux-firmware-marvell sof-firmware \
	fwupd btrfs-progs dosfstools opendoas nano bash-completion man-db \
	chrony networkmanager bluez bluez-obex pipewire-audio pipewire-pulse wireplumber \
	adobe-source-code-pro-fonts noto-fonts-emoji noto-fonts noto-fonts-cjk \
	strike fiery index-fm maui-station maui-nota maui-pix maui-clip vvave communicator

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

arch-chroot /mnt systemctl enable systemd-timesyncd systemd-resolved NetworkManager bluetooth obex

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
echo 'permit nopass nu cmd /usr/local/bin/upm' > /mnt/etc/doas.d/upm.conf

ln -s /usr/bin/doas /mnt/usr/local/bin/sudo

echo; echo "set root password"
while ! arch-chroot /mnt passwd; do
	echo "please retry"
done
arch-chroot /mnt useradd --base-dir / --create-home --shell /usr/local/bin/ushell nu
echo; echo "set lock'screen password"
while ! arch-chroot /mnt passwd nu; do
	echo "please retry"
done

cat <<-'EOF' > /mnt/usr/local/bin/autologin
# set resource limits for realtime applications like the rt module in pipewire
ulimit -r 95 -e -19 -l 4194304

modprobe zram
zramctl /dev/zram0 --algorithm zstd --size "$(($(grep -Po "MemTotal:\s*\K\d+" /proc/meminfo)/2))KiB"
mkswap -U clear /dev/zram0
swapon --discard --priority 100 /dev/zram0

exec login -f nu
EOF
chmod +x /mnt/usr/local/bin/autologin

echo '[Service]
Type=simple
ExecStart=
ExecStart=-/usr/bin/agetty --skip-login --nonewline --noissue --noreset --noclear -l /usr/local/bin/autologin - ${TERM}
' > /mnt/etc/systemd/system/getty@tty1.service.d/autologin.conf
echo '[Service]
Type=simple
ExecStart=
ExecStart=-/usr/bin/agetty --skip-login --nonewline --noissue --noreset --noclear -l /usr/local/bin/autologin - ${TERM}
' > /mnt/etc/systemd/system/getty@tty2.service.d/autologin.conf

script_dir="$(dirname "$(readlink -f "$0")")"
cp -r "$script_dir"/ushell /mnt/usr/local/share/

chmod +x /mnt/usr/local/share/ushell/1.sh
ln -sf /usr/local/share/ushell/1.sh /mnt/usr/local/bin/ushell
cat <<-EOF > /mnt/etc/doas.d/ushell.conf
permit nopass nu cmd setpriv --reuid=nu --regid=nu --groups=input,video,audio /usr/local/bin/ushell priv
permit nopass nu cmd /usr/bin/passwd nu
EOF

echo '#!/bin/sh
case "$2" in
up) doas -u nu sh /usr/local/share/ushell/system.sh tz guess ;;
esac
' > /mnt/etc/NetworkManager/dispatcher.d/09-tz-guess
chmod 755 /mnt/etc/NetworkManager/dispatcher.d/09-tz-guess

echo; echo "installation completed successfully"
printf "reboot the system? (Y/n) "
read -r ans
[ "$ans" != n ] && [ "$ans" != no ] && reboot

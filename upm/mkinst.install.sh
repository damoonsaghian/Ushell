# installs a minimal Linux'based system, with a user interface based on Unish and Uni

script_dir="$(dirname "$(readlink -f "$0")")"

# obtain gnunet namespaces from "$script_dir"/../.meta/gnunet, and put it into "$state_dir"/upm/config

# format a storage device for installing the new system
new_root="$(mktemp -d /Data/Variable/run/user/"$(id u)"/uni.XXX)"
. "$script_dir"/install-mkfs.sh

mkdir -p "$new_root"/{root,tmp,run,proc,sys,dev}
chmod a+w "$target_dir"/tmp

echo "UPM will try to download binary packages (instead of building from source), if they are available for your system"
printf "do you want to always built packages from source? (y/N) "
read -r ans
if [ "$ans" = y ]; then
	mkdir -p "$new_root"/var/lib/upm
	echo "build'from'src" > "$new_root"/var/lib/upm/config
fi

export PATH="$new_root/usr/bin:$PATH"

# upm offline mode, use cache

# eudev eudev-netifnames earlyoom acpid zzz bluez \
# 	networkmanager-cli wireless-regdb mobile-broadband-provider-info ppp-pppoe dnsmasq chrony dcron fwupd
# tasks: udev udev-trigger udev-settle udev-postmount earlyoom acpid bluetooth
# 	networkmanager networkmanager-dispatcher chronyd dcron fwupd

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
tpm2-tools
uni
upm
ushare
unish
util-linux' | {
	gnunet_namespace="$(cat "$scripr_dir"/../.meta/gns)"
	while read -r pkg_name; do
		UPM_ROOT="$target_dir" sh "$script_dir"/upm.sh install "$gnunet_namespace" "$pkg_name"
	done
}

echo '* * * * * ID=autoupdate FREQ=1d/5m autoupdate' > "$new_root"/etc/cron.d/autoupdate

##########
#  boot  #
##########

echo "disable_trigger=yes" > "$new_root"/etc/mkinitfs/mkinitfs.conf

echo '#!/bin/sh
if [ "$1" = "pre-commit" ]; then
    true
elif [ "$1" = "post-commit" ]; then
	[ -f /boot/vmlinuz-stable ] && mv /boot/vmlinuz-stable /boot/vmlinuz
	efi_path="$(echo /usr/lib/systemd/boot/efi/system-boot*.efi)"
    [ -f "$efi_path" ] && mv "$efi_path" /boot/
fi
' > "$new_root"/etc/apk/commit_hooks.d/create-boot-files
chmod +x "$new_root"/etc/apk/commit_hooks.d/create-boot-files

# linux systemd-boot mkinitfs btrfs-progs cryptsetup tpm2-tools
case "$(uname -m)" in
x86*)
	cpu_vendor_id="$(cat /proc/cpuinfo | grep vendor_id | head -n1 | sed -n "s/vendor_id[[:space:]]*:[[:space:]]*//p")"
	# [ "$cpu_vendor_id" = AuthenticAMD ] && install amd-ucode
	# [ "$cpu_vendor_id" = GenuineIntel ] && install intel-ucode
;;
esac

chmod +x "$new_root"/usr/local/share/codev-util/tpm-getkey.sh
ln -s /usr/local/share/codev-util/tpm-getkey.sh "$new_root"/usr/local/bin/tpm-getkey

chroot "$new_root" sh /usr/local/share/systemd-boot/bootup.sh

# systemd-boot

# bootup.sh
# run when kernel or systemd-boot are updated

# micrcodes

# tpm2-tools
# tmp-getkey.sh

# cryptsetup
# with nettle backend

# wireless-regdb
# fwupd

# eudev
# skip eudev-hwids
# https://pkgs.alpinelinux.org/package/edge/main/x86_64/eudev-hwids
# to prevent BadUSB, cerate evdev rule that when a secondary input device is connected:
# , disables the device
# , runs lock

# doas rules for poweroff and reboot of init system

# acpid (listen for, and process, ACPI events related to lid-switch activation and the power and suspend keys)

# https://wiki.archlinux.org/title/Laptop_Mode_Tools
# https://github.com/rickysarraf/laptop-mode-tools
# https://github.com/rickysarraf/laptop-mode-tools/blob/lmt-upstream/Documentation/laptop-mode.txt
# https://github.com/rickysarraf/laptop-mode-tools/wiki
# use xrandr to lower screen refresh rate, when on battery

# suspend system with support for hooks (needed for some drivers)
# https://github.com/jirutka/zzz
# doas rules

# mkinst.sh

# btrfs-progs
# dosfstools
# exfatprogs

# https://github.com/libarchive/libarchive
# --with-nettle --without-openssl
# https://github.com/cybernoid/archivemount

# avahi
# skip avahi-glib

# bluez
# create doas rules to use as normal user

# chrony
# how to sync time over gnunet? vpn over gnunet maybe?

# networkmanager
# crypto=gnutls polkit=false
# wpa_supplicant or iwd (without dhcp)
# modemmanager

# gnutls
# disable p11-kit, cause it's useless
# because when a system is compromized, though it can protect the private key itself,
# it can't prevent using the private key (eg for signing)
# ca-certificates

# tmp2-tss and qtnetwork need openssl

# https://git.lysator.liu.se/lsh/lsh
# https://www.lysator.liu.se/~nisse/lsh/lsh.html
# create ssh and and ssh-keygen executables, and provide at least those options needed by git and upm
# or configure git to use ssh program in a way that is compatible with lsh:
# 	https://github.com/git/git/blob/master/Documentation/config/ssh.adoc

# curl
# http/https only curl (with gnutls backend)
# for http/3:
# https://github.com/ngtcp2/ngtcp2
# https://github.com/lxin/quic (only works on linux)

# https://gitlab.freedesktop.org/pipewire/pipewire
# https://wiki.alpinelinux.org/wiki/PipeWire
# https://docs.voidlinux.org/config/media/pipewire.html
# https://wiki.archlinux.org/title/PipeWire
# https://gitlab.freedesktop.org/pipewire/media-session
# enable pulse, disable gstreamer glib jack
# libpw-v4l2.so
# pipewire-spa-bluez

# autologin.sh
# agetty service for tty1: /usr/bin/getty -n -l /usr/bin/autologin 38400 tty1
# agetty service for tty2: /usr/bin/getty --skip-login -l /usr/bin/autologin tty2 linux

# user services: pipewire, wireplumber, and dbus
# https://manpages.debian.org/trixie/dbus-daemon/dbus-daemon.1.en.html

##########
#  user  #
##########

echo; echo "set root password (can be the same as he one used to encrypt the root partition)"
echo "WARNING! do not use this password carelessly"
echo "in practice, it's only required for manually changing system files, ie almost never"
while ! chroot "$new_root" passwd root; do
	echo "please retry"
done

# create a normal user
chroot "$new_root" adduser --empty-password --home /nu --shell /usr/bin/unish nu
chroot "$new_root" chown nu: /nu

echo; echo "set lock'screen password"
while ! chroot "$new_root" passwd nu; do
	echo "please retry"
done

sed 's@tty1:respawn:\(.*\)getty@tty1:respawn:\1getty -n -l /usr/local/bin/autologin@' \
	"$new_root"/etc/inittab > "$new_root"/etc/inittab.tmp
sed 's@tty2:respawn:\(.*\)getty@tty2:respawn:\1getty -n -l /usr/local/bin/autologin@' \
	"$new_root"/etc/inittab.tmp > "$new_root"/etc/inittab

ln -s /usr/local/share/util-linux/autologin.sh "$new_root"/usr/local/bin/autologin
chmod +x "$new_root"/usr/local/share/util-linux/autologin.sh

echo; echo "installation completed successfully"
printf "reboot the system? (Y/n) "
read -r ans
[ "$ans" != n ] && [ "$ans" != no ] && reboot

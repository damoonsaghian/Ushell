# installs a minimal Linux'based system, with a user interface based on UShell and Uni

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
ushell
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
chroot "$new_root" adduser --empty-password --home /nu --shell /usr/bin/ushell nu
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

############
#  Ushell  #
############

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
#
# monospace font is still needed for terminal emulator
# https://github.com/adobe-fonts/source-code-pro
#
# noto fonts for: math, symbols, emoji, armenian georgian hebrew arabic ethiopic nko,
# 	devanagari gujarati telugu kannada malayalam oriya bengali tamil myanmar thai lao khmer cjk

# harfbuzz
# disable glib

# https://git.outfoxxed.me/quickshell/quickshell
# https://git.outfoxxed.me/quickshell/quickshell/src/branch/master/BUILD.md
# -DSERVICE_PAM=OFF
# mkdir -p /var/cache/src/cli11
# cd /var/cache/src/cli11 || exit
# git clone https://github.com/CLIUtils/CLI11
# cmake -B build -W no-dev -D CMAKE_BUILD_TYPE=None -D CMAKE_INSTALL_PREFIX=$pkg_dir \
# 	-D CLI11_BUILD_TESTS=OFF -D CLI11_BUILD_EXAMPLES=OFF
# cmake --build build && cmake --install build
#
# mkdir -p /var/cache/src/quickshell
# cd /var/cache/src/quickshell || exit
# git clone https://git.outfoxxed.me/quickshell/quickshell
# cmake -G Ninja -B build -W no-dev -D CMAKE_BUILD_TYPE=RelWithDebInfo \
# 	-D CMAKE_INSTALL_PREFIX=$pkg_dir/local -D INSTALL_QML_PREFIX=lib/qt6/qml \
# 	-D CRASH_REPORTER=OFF -D X11=OFF -D SERVICE_POLKIT=OFF \
# 	-D SERVICE_PAM=OFF -D WAYLAND_SESSION_LOCK=OFF -D WAYLAND_TOPLEVEL_MANAGEMENT=OFF
# cmake --build build && cmake --install build

if apk info quickshell >/dev/null 2>&1; then
	apk_new quickshell --virtual .quickshell
else
	apk_new git clang cmake ninja-is-really-ninja pkgconf spirv-tools wayland-protocols qt6-qtshadertools-dev \
		jemalloc-dev pipewire-dev libdrm-dev mesa-dev wayland-dev \
		qt6-qtbase-dev qt6-qtdeclarative-dev qt6-qtsvg-dev qt6-qtwayland-dev --virtual .quickshell
		chroot "$new_root" sh "$script_dir"/upm.sh quickshell
fi
apk_new setpriv doas-sudo-shim musl-locales exfatprogs tzdata geoclue bash bash-completion dbus \
	pipewire pipewire-pulse pipewire-alsa pipewire-echo-cancel pipewire-spa-bluez wireplumber sof-firmware \
	mesa-dri-gallium mesa-va-gallium breeze breeze-icons \
	font-adobe-source-code-pro font-noto font-noto-emoji \
	font-noto-armenian font-noto-georgian font-noto-hebrew font-noto-arabic font-noto-ethiopic font-noto-nko \
	font-noto-devanagari font-noto-gujarati font-noto-telugu font-noto-kannada font-noto-malayalam \
	font-noto-oriya font-noto-bengali font-noto-tamil font-noto-myanmar \
	font-noto-thai font-noto-lao font-noto-khmer font-noto-cjk \
	qt6-qtvirtualkeyboard qt6-qtsensors mauikit-terminal .quickshell --virtual .codev-shell
rc_new dbus
rc_new --nu dbus
rc_new --nu pipewire
rc_new --nu wireplumber

cp -r "$script_dir"/../codev-shell "$new_root"/usr/local/share/codev-shell
chmod +x "$new_root"/usr/local/share/codev-shell/codev-shell.sh
ln -s "$new_root"/usr/local/share/codev-shell/codev-shell.sh "$new_root"/usr/local/bin/codev-shell

cat <<-EOF > "$new_root"/etc/doas.d/codev-shell.conf
permit nopass nu cmd setpriv --reuid=nu --regid=nu --groups=input,video,audio /usr/local/bin/codev-shell priv
permit nopass nu cmd /usr/bin/passwd nu
EOF

echo '#!/bin/sh
case "$2" in
up) sudo -u nu sh /usr/local/share/codev-shell/system.sh tz guess ;;
esac
' > /etc/NetworkManager/dispatcher.d/09-dispatch-script
chmod 755 /etc/NetworkManager/dispatcher.d/09-dispatch-script

# dte (terminal text editor)
# https://gitlab.com/craigbarnes/dte/-/blob/master/docs/packaging.md
# make ICONV_DISABLE=1 BUILTIN_SYNTAX_FILES='dte config ini sh'

#########
#  Uni  #
#########

# qtbase
# cmake args: -DFEATURE_glib=OFF -DFEATURE_xcb_xlib=OFF
#
# https://github.com/qt/qtimageformats
# https://github.com/qt/qtsvg
# https://invent.kde.org/frameworks/kimageformats/
#
# https://github.com/qt/qt3d
# https://github.com/qt/qtcharts
# https://github.com/qt/qtdatavis3d
# https://github.com/qt/qtgraphs
# https://github.com/qt/qtlocation (OpenStreetMap viewer)
# https://github.com/qt/qtlottie
# https://github.com/qt/qtquick3d
# https://github.com/qt/qtquick3dphysics
# https://github.com/qt/qtquicktimeline
# https://github.com/qt/qtwayland
#
# https://github.com/qt/qtsensors
# https://github.com/qt/qtsensors/tree/dev/src/plugins/sensors/sensorfw
# https://github.com/sailfishos/sensorfw
# https://github.com/sailfishos/sensorfw/blob/master/doc/PLUGIN-GUIDE
#
# qt-poppler
# ENABLE_NSS3=OFF ENABLE_GPGME=OFF ENABLE_QT5=OFF ENABLE_GLIB=OFF
#
# qt-multimedia
# ffmpeg backend https://github.com/qt/qtmultimedia/blob/dev/src/plugins/multimedia/ffmpeg/CMakeLists.txt
# 	disable QT_FEATURE_xlib
# https://github.com/qt/qtmultimedia/blob/dev/src/multimedia/CMakeLists.txt
# enable alsa, disable pulse
# ffmpeg (use libpw-v4l2.so instead of libv4l2.so)
#
# https://github.com/qt/qtspeech
# with flite backend

# https://github.com/movableink/webkit
# https://github.com/movableink/webkit/blob/master/Source/cmake/OptionsQt.cmake
#
# https://github.com/qt/qtwebchannel
#
# link gcrypt statcally
# or replace it with nettle:
# https://blog.cranksoftware.com/webkit-porting-tips-the-good-the-bad-and-the-ugly/
# https://ariya.io/2011/06/your-webkit-port-is-special-just-like-every-other-port
# https://trac.webkit.org/wiki/SuccessfulPortHowTo
# https://trac.webkit.org/wiki/WikiStart
# https://github.com/WebKit/WebKit/blob/main/Source/cmake/OptionsGTK.cmake

# KDE framworks
# kio, syntax-highlighting, and all KF addons that they need
# https://invent.kde.org/libraries/kquickimageeditor
#
# build karchive without libcrypto dependency
#
# https://invent.kde.org/frameworks/solid
# udev backend (no udisks)
# no upower BUILD_DEVICE_BACKEND_upower
#
# libmtp without gcrypt
# https://sourceforge.net/p/libmtp/code/ci/master/tree/INSTALL

# maui
# filebrowsing texteditor imagetools terminal
# documents (pdf viewer using qt-poppler)

apk_new mauikit mauikit-filebrowsing mauikit-texteditor mauikit-imagetools mauikit-documents \
	kio-extras kimageformats qt6-qtsvg \
	qt6-qtmultimedia ffmpeg-libavcodec qt6-qtwebengine qt6-qtlocation geoclue qt6-qtremoteobjects qt6-qtspeech \
	qt6-qtcharts qt6-qtgraphs qt6-qtdatavis3d qt6-qtquick3d qt6-qt3d qt6-qtquicktimeline \
	gnunet openssh aria2 archivemount --virtual .uni
# qt6-qtquick3dphysics qt6-qtlottie
cp -r "$script_dir"/../uni "$new_root"/usr/local/share/
mkdir -p "$new_root"/usr/local/share/icons/hicolor/scalable/apps
ln -s /usr/local/share/uni/data/uni.svg "$new_root"/usr/local/share/icons/hicolor/scalable/apps/

mkdir -p "$new_root"/usr/local/share/applications
echo '[Desktop Entry]
Name=Uni
Comment=Collaborative Development
Icon=uni
exec=qml6 /usr/local/share/uni/main.qml
StartupNotify=true
Type=Application
' > "$new_root"/usr/local/share/applications/uni.desktop

chmod +x "$new_root"/usr/local/share/uni/sd.sh
ln -s /usr/local/share/uni/sd.sh "$new_root"/usr/local/bin/sd
echo 'permit nopass nu cmd /usr/local/bin/sd' > "$new_root"/etc/doas.d/sd.conf

echo; echo "installation completed successfully"
printf "reboot the system? (Y/n) "
read -r ans
[ "$ans" != n ] && [ "$ans" != no ] && reboot

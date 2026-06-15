# a unified collaborative development environment, and an ideal frontend for GNUnet, with command'based user interface

# deps: bash qt6wayland quickshell

# https://git.outfoxxed.me/quickshell/quickshell
# https://git.outfoxxed.me/quickshell/quickshell/src/branch/master/BUILD.md

'''
echo -n '#!/usr/bin/env sh
[ "$1" = priv ] || {
	doas setpriv --reuid=nu --regid=nu --groups=input,video,audio sh /usr/bin/ushell priv
}
script_dir="$(dirname "$(readlink -f "$0")")"
sh "$script_dir"/ushell.sh
' > $pkg_path/exec/ushell
'''

'''
cat <<-EOF > /etc/doas.d/ushell.conf
permit nopass nu cmd setpriv --reuid=nu --regid=nu --groups=input,video,audio /usr/bin/ushell priv
permit nopass nu cmd /usr/bin/passwd nu
EOF
'''

'''
echo '#!/bin/sh
case "$2" in
up)
	ushell_dir="$(dirname "$(readlink -f /usr/bin/ushell)")"
	doas -u nu sh "$ushell_dir"/system.sh tz guess
	;;
esac
' > /etc/NetworkManager/dispatcher.d/09-tz-guess
chmod 755 /etc/NetworkManager/dispatcher.d/09-tz-guess
'''

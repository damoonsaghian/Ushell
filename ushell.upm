# deps: bash qt6wayland quickshell mauikit-terminal

# ushell/1.sh -> exec/ushell-priv
echo -n '#!/usr/bin/env sh
script_dir="$(dirname "$(readlink -f "$0")")"
setpriv --reuid=nu --regid=nu --groups=input,dri /usr/bin/ushell-priv
' > exec/ushell
chmod +x exec/ushell exec/ushell-priv
echo 'permit nopass nu cmd setpriv --reuid=nu --regid=nu --groups=input,dri /usr/bin/ushell-priv"' > \
	/mnt/etc/doas.d/ushell.conf

# make a symbolic link from ushell.tz-guess.sh to  /etc/NetworkManager/dispatcher.d/09-tz-guess
# chmod 755 ushell.tz-guess.sh

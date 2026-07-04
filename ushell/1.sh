script_dir="$(dirname "$(readlink -f "$0")")"

[ -f /etc/profile ] && . /etc/profile
for profile_script in /usr/share/profile/*.sh; do
	[ -f "$profile_script" ] && . "$profile_script"
done

export TZ="$HOME/.config/tz"
export SHELL="doas -u \"$USER\" /usr/bin/bash --noprofile --norc -i \"$script_dir\"/bashrc.sh"
export PATH="/usr/local/bin:/usr/bin:/$HOME/.local/bin"
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
rm -rf "$XDG_RUNTIME_DIR"
mkdir -pm 0700 "$XDG_RUNTIME_DIR"

# run dinit user services

umask 022

start_cli() {
	# ask:
	# , auto repair (if no internet and no LAN, setup network; upm update; also if not on tty1, restart tty1)
	# , backup
	# , copy projects
	# , terminal: ask user for lockscreen password, and exit if wrong
	
	$SHELL
}

if [ "$(tty)" = "/dev/tty1" ] && [ "$(id -u)" != 0 ]; then
	qs "$script_dir"/main.qml || start_cli
else
	start_cli
fi

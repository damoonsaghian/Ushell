# install "upm" to user's home directory

script_dir="$(dirname "$(readlink -f "$0")")"

state_dir="$XDG_STATE_HOME"
[ -z "$state_dir" ] && state_dir="$HOME"/.local/state

echo "UPM will try to download binary packages (instead of building from source), if they are available for your system"
printf "do you want to always built packages from source? (y/N) "
read -r ans
if [ "$ans" = y ]; then
	mkdir -p "$state_dir"/upm
	echo "build'from'src" > "$state_dir"/upm/config
fi

# obtain gnunet namespaces from "$script_dir"/../.meta/gnunet, and put it into "$state_dir"/upm/config

gnunet_namespace="$(cat "$scripr_dir"/../.meta/gns)"
sh "$script_dir"/upm.sh install "$gnunet_namespace" upm

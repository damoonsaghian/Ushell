# download/publish from/to gnunet and web (hashbang)
# unet download <uri> <path>
# unet publish <path> <uri>

# download from hashbang, only when gnunet executable is not available
# or downloading from gnunet fails after a timeout
# echo 'either "gnunet" or "curl" or "wget" is required'

# publish: 1, ego is in list; 2, want to put ego in list
# pull req

# https://www.gnunet.org/en/use.html
# https://git.gnunet.org/gnunet.git/tree/src
# https://docs.gnunet.org/latest/users/subsystems.html
# https://docs.gnunet.org/latest/users/configuration.html#access-control-for-gnunet
# https://manpages.debian.org/unstable/gnunet/gnunet.1.en.html
# https://manpages.debian.org/unstable/gnunet/
# https://wiki.archlinux.org/title/GNUnet

# at least 50% namespaces (excluding revoked ones) must agree

# to download new version, download gnunet dir file (non'recursively)
# use gnunet-directory to get CHK of the files to be downloaded
# use gnunet-publish --simulate-only to obtain the CHK of old files in $project_dir/.cache/gnunet/download
# if there is a common CHK with different filenames, rename the file
# if there is a gnunet dir file with a new CHK, do the above for it
# now download the whole directory recursively
# this way, only changed files will be transfered

# how to sync time over gnunet? vpn over gnunet maybe?

hash2path() {}

path2hash() {
	# for any file in wdir, newer than the hash file (in pristine), calculate its hash, hardlink it to its hash'named path
	# for any entry in the hash file, if the file exists in wdir, hardlink it too
}

gn_download() {
	dest_dir="$1"
	
	# download "$dest_dir"/hashlist (<hash> <relative-path>)
	# for each line, if there is a file named <hash> in the old dir, hardlink it
	# otherwise, download it
	# in the end remove the old dir
}

gn_publish() {
	# create ref links of the files in $project_dir/.data/gnunet/publish
	# skip .cache directory, and symlinks
	# run gnunet-publish
	# this way GNUnet can publish the files using the indexed method
	
	# gnunet://fs/sks/$gnunet_namespace/$publish_name
}

web_download() {
	# curl or wget
	# download .data/hashes
	
	# download "$dest_dir"/hashlist (<hash> <relative-path>)
	# for each line, if there is a file named <hash> in the old dir, hardlink it
	# otherwise, download it
	# in the end remove the old dir
}

hashbang_register() {
	# we still need a website so the unfortunate users of conventional internet can see and find us
	
	# hasbang can be used as free web host that allows to signup using http post
	# https://github.com/hashbang/hashbang.sh/blob/master/src/hashbang.html
	# https://github.com/hashbang/shell-server/blob/master/ansible/tasks/packages/main.yml
	# create a user in one of "hashbang.sh" servers
	# https://github.com/hashbang/hashbang.sh/blob/master/src/hashbang.sh
	
	# currently, the ~/Public folder isn't exposed over HTTP by default
	# use the `SimpleHTTPServer.service` systemd unit file (in `~/.config/systemd/user`, modify it to set port)
	# download ~/.config/systemd/user/SimpleHTTPServer@.service
	# rename to SimpleHTTPServer@1025.service and upload to ~/.config/systemd/user/
	# https://github.com/hashbang/dotfiles/blob/master/hashbang/.config/systemd/user/SimpleHTTPServer%40.service
	# https://github.com/hashbang/shell-server/blob/master/ansible/tasks/hashbang/templates/etc/skel/Mail/new/msg.welcome.j2
	
	# create an html web'page "~/Public/project_name/index.html", showing the files in the project
	# when converting to html, convert tabs to html tables, to have elastic tabstops
	
	# hashbang init:
	
	# if "remote_host" or "user" are empty, ask for them
	
	printf "\nHost %s\n  User %s\n" "$remote_host" "$user" >> ~/.ssh/config
	
	{ echo "$user" | sed -n "/^[a-z][a-z0-9]{0,30}$/!{q1}"; } || {
		echo "\"$user\" is not a valid username"
		echo "a valid username must:"
		echo ", be between between 1 and 31 characters long"
		echo ", consist of only 0-9 and a-z (lowercase only)"
		echo ", begin with a letter"
		exit 1
	}
	
	ssh "$user"@"$remote_host" && return
	
	# if there is no SSH keys, create a key pair
	# ssh-keygen -t ed25519
	# openssh key format: ssh-ed25519 ...
	
	echo
	echo " please choose a server to create your account on"
	echo
	hbar
	printf -- '  %-1s | %-4s | %-36s | %-8s | %-8s\n' \
		"#" "Host" "Location" "Users" "Latency"
	hbar
	
	host_data=$(wget -q -O - --header 'Accept:text/plain' https://hashbang.sh/server/stats)
	
	while IFS="|" read -r host _ location current_users max_users _; do
		host=$(echo "$host" | cut -d. -f1)
		latency=$(time_cmd "wget -q -O /dev/null \"${host}.hashbang.sh\"")
		n=$((n+1))
		printf -- '  %-1s | %-4s | %-36s | %8s | %-8s\n' \
			"$n" \
			"$host" \
			"$location" \
			"$current_users/$max_users" \
			"$latency"
	done <<-INPUT
	"$host_data"
	INPUT
	
	echo
	while true; do
		printf ' Enter Number 1-%i : ' "$n"
		read -r choice
		case "$choice" in
			''|*[!0-9]*) number="no";;
		esac
		if [ "$number" != "no" ] && [ "$choice" -ge 1 ] && [ "$choice" -le $n ]; then
			break;
		fi
	done
	
	host=$(echo "$host_data" | head -n "$choice" - | tail -n1 | cut -d \| -f1)
	
	pulic_key=$(cat ~/.ssh/id_ed25519.pub)
	host=de1.hashbang.sh
	wget --post-data="{\"user\":\"$user\",\"key\":\"$public_key\",\"host\":\"$host\"}" \
		--header='Content-Type: application/json' https://hashbang.sh/user/create
	
	# use ssh-keygen to sign/verify files
	# use gnunet-identity to obtain the Ed25519 key
	# openssh public key format: ed25519 ... user@hostname
	# openssh private key format:
	# -----BEGIN OPENSSH PRIVATE KEY-----
	# base64-encoded data, that may also be encrypted with a passphrase
	# -----END OPENSSH PRIVATE KEY-----
	# https://hstechdocs.helpsystems.com/manuals/globalscape/eft82/mergedprojects/admin/ssh_key_formats.htm
	# https://en.wikipedia.org/wiki/PKCS_8
}

web_publish() {
	# curl or wget
	
	# if there is no .data/url, call hashbang_register
	
	# if .data/url is empty, exit quietly
}

mkpristine() {
	dest_dir="$1"
	cp -r --reflink=auto "$dest_dir"/* "$dest_dir"/.data/gnunet/pristine
	# to download new version, download gnunet dir file (non'recursively)
	# use gnunet-directory to get CHK of the files to be downloaded
	# use gnunet-publish --simulate-only to obtain the CHK of old files in $project_dir/.cache/gnunet/download
	# if there is a common CHK with different filenames, rename the file
	# if there is a gnunet dir file with a new CHK, do the above for it
	# now download the whole directory recursively
	# this method ensures that a simple file rename will not impose a download
}

pkg_download() {
	local url="$1"
	local pkg_name="$2"
	local pkg_name_build="$pkg_name-$ARCH"
	# download directories
	local dl_dir="$cache_dir/pkg/packages/$gn_namespace/$pkg_name"
	local dl_build_dir="$cache_dir/pkg/$ARCH/$gn_namespace/$pkg_name"
	
	# url protocol can be gnunet or http
	# gn_download
	# web_download
	
	# if gn_namespace is revoked try the alternative ones from .data/gnunet/$gn_namespace
	# also print a warning
	
	# if there is no line equal to "build'from'src" in "$state_dir/pkg/config"
	# 	download $pkg_name_build from $gn_namespace into "$dl_build_dir"
	# 	result="$(gn-download "$gn_namespace" "$pkg_namebuild" "$dl_build_dir")"
	# 	[ result = "not fount" ] || return
	# download the package from "$pkg_url" to "$dl_dir"
	# unet download "$uri" "$dl_dir"
}

pkg_publish() {
	src_dir="$1"
	
	# url protocol can be gnunet or http
	# gn_publish
	# web_publish
	
	# sks identifier to publish pakage: <project_name>-pkg
	
	# make hardlinks from "$src_dir/.gnunet/publish" to "~/.local/pkg/$gnunet_namespace/$pkg_name"
	
	# make hard links from "imp" file, plus all files in ".cache/pkg/builds/<arch>/" minus "imp" directory,
	# and put them in ".cache/pkg/builds-published/<arch>/"
	gn-publish "~/.local/pkg/published/$gnunet_namespace/$pkg_name" $gnunet_namespace $pkg_name-pkg
	
	gn-publish ".cache/pkg/builds-published/$ARCH/" $gnunet_namespace $pkg_name-$ARCH
}

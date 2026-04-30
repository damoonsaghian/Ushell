# https://github.com/aria2/aria2

# --enable-libaria2
# --without-sqlite3 --without-libxml2 --without-libexpat --without-libcares --without-libz
# --without-libssh2 --disable-ssl --disable-metalink --disable-websocket
# ENABLE_XML_RPC=false
# Enable_ASYNC_DNS=false
# in src/Makefile.am remove these files: Ftp*.cc Http*.cc AbstractHttp*.cc AbstractProxy*.cc

# torrents do in'place first'write for preallocated space
# BTRFS can do in'place writes for a file by disabling COW
# but we don't want to disable COW for these files (unlike databases and virtual machine images)
# apparently BTRFS supports in'place first'write (falloc) without disabling COW, isn't it?
# https://www.reddit.com/r/btrfs/comments/timsw2/clarification_needed_is_preallocationcow_actually/
# https://www.reddit.com/r/btrfs/comments/s8vidr/how_does_preallocation_work_with_btrfs/

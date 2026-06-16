# Cbuild for gnunet

# https://git.gnunet.org/gnunet.git/tree/src

# gnunet.conf
'''
[hostlist]
# Options:
# -p : provide a hostlist as a hostlist servers
# -b : bootstrap using configured hostlist servers
# -e : enable learning advertised hostlists
# -a : advertise hostlist to other servers
OPTIONS = -b -e -a -p
'''

# intresting fact: gnunet uses UDP to discover peers on local net

# https://docs.gnunet.org/latest/users/configuration.html#limitations-and-known-bugs
# https://docs.gnunet.org/latest/users/subsystems.html#transport-ng-next-generation-transport-management
# https://en.wikipedia.org/wiki/Long-range_Wi-Fi

# LoRa communicator for emergency communications (when normal network infrastructure is down)
# https://en.wikipedia.org/wiki/LoRa
# generally it's a good idea to include LoRa in mobile devices, and provide a manual switch that will send emergency signals

# for now, build libsodium and gcrypt internally, and link statically
# it will be good if GNUnet replaces them with nettle
# and even add NTRU on top, for more security (like in openssh)

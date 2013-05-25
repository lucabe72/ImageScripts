set -e

SDIR=$(cd -- $(dirname $0) && pwd)

mkdir -p PVRMod
cp $1/source/drivers/net/macvtap.c PVRMod
patch -p0 < $SDIR/Patches/PVR/broadcast_arp_packets.diff
echo "obj-m = macvtap.o" > PVRMod/Makefile
make -C $1 M=$(pwd)/PVRMod



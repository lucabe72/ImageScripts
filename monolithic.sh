set -e

SDIR=$(cd -- $(dirname $0) && pwd)

GUEST_CONFIG=config-3.4-guest-32
HOST_CONFIG=config-3.4-host-32
export HOST_ARCH=x86
export GUEST_ARCH=x86

while getopts 4 opt
 do
  case "$opt" in
    4)		HOST_ARCH=x86_64; HOST_CONFIG=config-3.4-host-64;;
    [?])	print >&2 "Usage: $0 [-4]"
		exit 1;;
  esac
 done

sh $SDIR/create_image.sh test.img 512 32
sh $SDIR/create_image.sh opt1.img 48
export ARCH=$GUEST_ARCH
sh $SDIR/buildguest.sh $SDIR/core.gz $SDIR/Configs/$GUEST_CONFIG opt1.img test.img
sh $SDIR/grubit.sh test.img
export ARCH=$HOST_ARCH
sh $SDIR/buildhostlin.sh $SDIR/core.gz $SDIR/Configs/$HOST_CONFIG test.img
sh $SDIR/buildkvm.sh test.img

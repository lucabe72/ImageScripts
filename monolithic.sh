set -e

GUEST_CONFIG=config-3.4-guest-32
HOST_CONFIG=config-3.4-host-32
export HOST_ARCH=x86
export GUEST_ARCH=x86

while getopts 48 opt
 do
  case "$opt" in
    4)		HOST_ARCH=x86_64; HOST_CONFIG=config-3.4-host-64;;
    8)		GUEST_ARCH=x86_64; GUEST_CONFIG=config-3.4-guest-64;;
    [?])	print >&2 "Usage: $0 [-4]"
		exit 1;;
  esac
 done

sh create_image.sh test.img 512 32
sh create_image.sh opt1.img 48
export ARCH=$GUEST_ARCH
sh buildguest.sh $(pwd)/core.gz $(pwd)/Configs/$GUEST_CONFIG opt1.img test.img
sh grubit.sh test.img
export ARCH=$HOST_ARCH
sh buildhostlin.sh $(pwd)/core.gz $(pwd)/Configs/$HOST_CONFIG test.img
sh buildkvm.sh test.img

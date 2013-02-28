set -e

SDIR=$(cd -- $(dirname $0) && pwd)

GUEST_CONFIG=config-3.4-guest-32
HOST_CONFIG=config-3.4-host-32
export HOST_ARCH=x86
export GUEST_ARCH=x86
CORE=$SDIR/core.gz
KVER=3.4.14
EXTRAKNAME="-vrhost"

while getopts 48ckn opt
 do
  case "$opt" in
    4)		HOST_ARCH=x86_64; HOST_CONFIG=config-3.4-host-64;;
    8)		GUEST_ARCH=x86_64; GUEST_CONFIG=config-3.4-guest-64;;
    c)		CORE=$(pwd)/test.gz;;
    k)		KEEPIMAGE=YesPlease;;
    n)		KVM_PATCHES=Patches/Netmap/kvm-git
    [?])	print >&2 "Usage: $0 [-4]"
		exit 1;;
  esac
 done

if test -e $CORE;
 then
  echo $CORE already exists
 else
  echo Building $CORE
  sh buildcore.sh $CORE
 fi

export KVER
export EXTRAKNAME
if [ x$KEEPIMAGE = x ]
 then
  sh $SDIR/create_image.sh test.img 512 32
  sh $SDIR/grubit.sh test.img
 fi
sh $SDIR/create_image.sh opt1.img 48
export ARCH=$GUEST_ARCH
sh $SDIR/buildguest.sh $CORE $SDIR/Configs/$GUEST_CONFIG opt1.img test.img
export ARCH=$HOST_ARCH
sh $SDIR/buildhostlin.sh $CORE $SDIR/Configs/$HOST_CONFIG test.img
sh $SDIR/buildkvm.sh test.img qemu-kvm-git $KVM_PATCHES 

set -e

SDIR=$(cd -- $(dirname $0) && pwd)

. $(dirname $0)/utils.sh

export HOST_ARCH=x86
export GUEST_ARCH=x86
CORE=$SDIR/core.gz
HOST_KVER=3.4.14
GUEST_KVER=3.4.14
EXTRAKNAME="-vrhost"
KVM_NAME=qemu-kvm-git

while getopts 48cknq:v: opt
 do
  case "$opt" in
    4)		HOST_ARCH=x86_64;;
    8)		GUEST_ARCH=x86_64;;
    c)		CORE=$(pwd)/test.gz;;
    k)		KEEPIMAGE=YesPlease;;
    n)		KVM_PATCHES=Patches/Netmap/kvm-git;;
    q)		KVM_NAME=$OPTARG;;
    v)		HOST_KVER=$OPTARG;;
    [?])	print >&2 "Usage: $0 [-4]"
		exit 1;;
  esac
 done

if test -e $CORE;
 then
  echo $CORE already exists
 else
  echo Building $CORE
  sh $SDIR/buildcore.sh $CORE
 fi

export EXTRAKNAME
if [ x$KEEPIMAGE = x ]
 then
  sh $SDIR/create_image.sh test.img 512 32
  sh $SDIR/grubit.sh test.img
 fi
sh $SDIR/create_image.sh opt1.img 48
export KVER=$GUEST_KVER
export ARCH=$GUEST_ARCH
GUEST_CONFIG=$(get_kernel_config_name $GUEST_KVER $GUEST_ARCH guest)
sh $SDIR/buildguest.sh $CORE $SDIR/Configs/$GUEST_CONFIG opt1.img $PWD/Out/Guest
sh $SDIR/buildquagga.sh opt1.img 0.99.22
sh $SDIR/installguest.sh opt1.img $PWD/Out/Guest test.img
export KVER=$HOST_KVER
export ARCH=$HOST_ARCH
HOST_CONFIG=$(get_kernel_config_name $HOST_KVER $HOST_ARCH host)
sh $SDIR/buildhostlin.sh $CORE $SDIR/Configs/$HOST_CONFIG test.img
sh $SDIR/buildkvm.sh test.img $KVM_NAME $KVM_PATCHES 

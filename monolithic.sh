set -e

SDIR=$(cd -- $(dirname $0) && pwd)

. $(dirname $0)/utils.sh

export HOST_ARCH=x86
export GUEST_ARCH=x86
CORE=$(pwd)/test.gz
HOST_KVER=3.4.14
GUEST_KVER=3.4.14
OVSVER=2.0.0
EXTRAKNAME="-vrhost"
KVM_NAME=qemu-kvm-git

while getopts 48c:knq:v:V:o: opt
 do
  case "$opt" in
    4)		HOST_ARCH=x86_64;;
    8)		GUEST_ARCH=x86_64;;
    c)		CORE=$OPTARG;;
    k)		KEEPIMAGE=YesPlease;;
    n)		NETMAP_PATCH=YesPlease;;
    q)		KVM_NAME=$OPTARG;;
    v)		HOST_KVER=$OPTARG;;
    V)		GUEST_KVER=$OPTARG;;
    o)		OVSVER=$OPTARG;;
    [?])	print >&2 "Usage: $0 [-4]"
		exit 1;;
  esac
 done

MY_ARCH=$(arch)
if test -e $CORE;
 then
  echo $CORE already exists
 else
  echo Building $CORE
  if [ $MY_ARCH = x86_64 ];
   then
    export ARCH=x86
   fi
  sh $SDIR/buildcore.sh $CORE
 fi

if [ $NETMAP_PATCH = YesPlease ]
 then
  if [ $KVM_NAME = qemu-kvm-git ]
   then
    KVM_PATCHES=Patches/Netmap/qemu-kvm-git
   else
    Q_MAJ=$(echo $KVM_NAME | cut -f 2 -d '-' | cut -d '.' -f 1)
    Q_MIN=$(echo $KVM_NAME | cut -f 2 -d '-' | cut -d '.' -f 2)
    KVM_PATCHES=Patches/Netmap/v$Q_MAJ.$Q_MIN
   fi
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
sh $SDIR/buildquagga.sh opt1.img 0.99.22
sh $SDIR/buildguest.sh $CORE $SDIR/Configs/$GUEST_CONFIG opt1.img test.img
#sh $SDIR/installguest.sh opt1.img $PWD/Out/Guest test.img
export KVER=$HOST_KVER
export ARCH=$HOST_ARCH
HOST_CONFIG=$(get_kernel_config_name $HOST_KVER $HOST_ARCH host)
sh $SDIR/buildhostlin.sh  $CORE $SDIR/Configs/$HOST_CONFIG test.img
sh $SDIR/buildovs.sh      test.img $OVSVER 
sh $SDIR/buildkvm.sh      test.img $KVM_NAME $KVM_PATCHES 
sh $SDIR/buildiproute2.sh test.img 3.12.0
sh $SDIR/buildethtool.sh  test.img 3.12.1

set -e

SDIR=$(cd -- $(dirname $0) && pwd)

. $(dirname $0)/utils.sh

export HOST_ARCH=x86
export GUEST_ARCH=x86
CORE=$SDIR/core.gz
HOST_KVER=3.4.14
GUEST_KVER=3.4.14
CLICK_KVER=3.0.36
EXTRAKNAME="-vrhost"
KVM_NAME=qemu-kvm-git

while getopts 48 opt
 do
  case "$opt" in
    4)		ARCHP="$ARCHP -4";;
    8)		ARCHP="$ARCHP -8";;
    [?])	print >&2 "Usage: $0 [-4] [-8]"
		exit 1;;
  esac
 done

sh $SDIR/monolithic.sh $ARCHP
sh $SDIR/create_image.sh opt2.img 48
MY_ARCH=$(arch)
if [ $MY_ARCH = x86_64 ];
 then
  ARCH=x86_64
 else
  ARCH=x86
 fi
GUEST_CONFIG=$(get_kernel_config_name $CLICK_KVER $ARCH guest)
export ARCH
sh $SDIR/buildclick.sh $SDIR/core.gz $SDIR/Configs/$GUEST_CONFIG $(pwd)/opt2.img test.img

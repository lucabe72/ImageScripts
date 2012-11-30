SDIR=$(cd -- $(dirname $0) && pwd)

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
MY_ARCH=$(/bin/arch)
if [ $MY_ARCH = x86_64 ];
 then
  GUEST_CONFIG=config-3.0.36-guest-64
  ARCH=x86_64
 else
  GUEST_CONFIG=config-3.0.36-guest-32
  ARCH=x86
 fi
export ARCH
sh $SDIR/buildclick.sh $SDIR/core.gz $SDIR/Configs/$GUEST_CONFIG $(pwd)/opt2.img test.img

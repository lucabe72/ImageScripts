set -e

SDIR=$(cd -- $(dirname $0) && pwd)

KERN_CONFIG=config-3.4-pktgen-32
ARCH=x86
CORE=$SDIR/core.gz
KVER=3.4.14

while getopts 4c opt
 do
  case "$opt" in
    4)		ARCH=x86_64; KERN_CONFIG=config-3.4-pktgen-64;;
    c)		CORE=$(pwd)/test.gz;;
    [?])	print >&2 "Usage: $0 [-4 -c]"
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
sh $SDIR/create_image.sh test.img 512 32
sh $SDIR/grubit.sh test.img
export ARCH
sh $SDIR/buildhostlin.sh $CORE $SDIR/Configs/$KERN_CONFIG test.img
sh $SDIR/buildtestscripts.sh test.img

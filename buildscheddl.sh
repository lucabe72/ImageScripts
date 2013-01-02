set -e

CPUS=8
TARGET_PATH=/home/vrouter
OUT_DIR=$PWD/Out/Host
TMP_DIR=/tmp/BuildHost
KVER=3.7.1

. $(dirname $0)/utils.sh
. $(dirname $0)/opts_parse.sh

patch_kernel()
{
  PATCHES=$(ls $1)
  TMP=$(pwd)

  cd $2
  for p in $PATCHES
   do
    ls $TMP/$1/$p
    patch -p1 < $TMP/$1/$p
   done

  cd $TMP
}

if test -e $TMP_DIR/bzImage;
 then
  echo $TMP_DIR/bzImage already exists
 else
  #make_kernel $TMP_DIR $2
  get_kernel     linux-$KVER
  patch_kernel	Patches/DLPatches linux-$KVER
  build_kernel   linux-$KVER $TMP/Configs/config-3.7.1-dl-host $CPUS
  install_kernel linux-$KVER $TMP_DIR
 fi
mkdir -p $OUT_DIR
mv $TMP_DIR/bzImage $OUT_DIR



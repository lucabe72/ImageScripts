set -e

TARGET_PATH=/home/vrouter
OUT_DIR=$PWD/Out/Host
TMP_DIR=/tmp/BuildHost
KVER=3.7.1

. $(dirname $0)/utils.sh
CPUS=$(get_j)
. $(dirname $0)/opts_parse.sh

if test -e $TMP_DIR/bzImage;
 then
  echo $TMP_DIR/bzImage already exists
 else
  #make_kernel $TMP_DIR $2
  get_kernel     linux-$KVER
  patch_source   Patches/DLPatches linux-$KVER
  build_kernel   linux-$KVER $TMP/Configs/config-3.7.1-dl-host $CPUS
  install_kernel linux-$KVER $TMP_DIR
 fi
mkdir -p $OUT_DIR
mv $TMP_DIR/bzImage $OUT_DIR



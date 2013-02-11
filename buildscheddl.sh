set -e

SDIR=$(cd -- $(dirname $0) && pwd)
TARGET_PATH=/home/vrouter
OUT_DIR=$PWD/Out/Host
TMP_DIR=/tmp/BuildHost
KVER=3.7.1
PATCHES=$SDIR/Patches/DLPatches

. $(dirname $0)/utils.sh
CPUS=$(get_j)
. $(dirname $0)/opts_parse.sh

if test -e $TMP_DIR/bzImage;
 then
  echo $TMP_DIR/bzImage already exists
 else
  make_kernel $TMP_DIR $2 build-host$KVER$EXTRAKNAME $PATCHES
 fi
mkdir -p $OUT_DIR
mv $TMP_DIR/bzImage $OUT_DIR

update_initramfs $1 $TMP_DIR $OUT_DIR

mkdir -p bin
mkdir -p build-chdl
cd       build-chdl
make -f $SDIR/chdl/Makefile SRCDIR=$SDIR/chdl
cp chdl ../bin
cd ..

#$3: Host image -> Install kernel and core in the boot directory 
if [ x$3 != x ];
 then
  echo copying to image...
  mount_partition $3 img1 /mnt
  sudo cp $OUT_DIR/core.gz /mnt/boot/core-$KVER$EXTRAKNAME.gz
  sudo cp $OUT_DIR/bzImage /mnt/boot/vmlinuz-$KVER$EXTRAKNAME
  umount_partition /mnt
 fi

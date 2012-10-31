set -e

CPUS=8
TARGET_PATH=/home/vrouter
OUT_DIR=$PWD/Out/Host
TMP_DIR=/tmp/BuildHost
KVER=3.4.14

source $(dirname $0)/utils.sh
source $(dirname $0)/opts_parse.sh

if test -e $TMP_DIR;
 then
  echo $TMP_DIR already exists
 else
  make_kernel $TMP_DIR $2
 fi
mkdir -p $OUT_DIR
mv $TMP_DIR/bzImage $OUT_DIR

extract_initramfs $1  $TMP_DIR/tmproot
sudo rm -rf $TMP_DIR/tmproot/lib/modules/*
sudo cp -r  $TMP_DIR/lib/modules/* $TMP_DIR/tmproot/lib/modules
mk_initramfs $TMP_DIR/tmproot $OUT_DIR/core.gz

if [[ x$3 != x ]];
 then
  echo copying to image...
  mount_partition $3 img1 /mnt
  sudo cp $OUT_DIR/core.gz /mnt/boot/core-$KVER.gz
  sudo cp $OUT_DIR/bzImage /mnt/boot/vmlinuz-$KVER
  sudo umount /mnt
  sudo /sbin/losetup -d /dev/loop0
 fi

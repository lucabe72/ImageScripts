set -e

TARGET_PATH=/home/vrouter
OUT_DIR=$PWD/Out/Host
TMP_DIR=/tmp/BuildHost
KVER=3.4.14

. $(dirname $0)/utils.sh
CPUS=$(get_j)
. $(dirname $0)/opts_parse.sh

if test -e $TMP_DIR/bzImage;
 then
  echo $TMP_DIR/bzImage already exists
 else
  make_kernel $TMP_DIR $2 build-host$KVER
 fi
mkdir -p $OUT_DIR
mv $TMP_DIR/bzImage $OUT_DIR

update_initramfs $1 $TMP_DIR $OUT_DIR

#$3: Host image -> Install kernel and core in the boot directory 
if [ x$3 != x ];
 then
  echo copying to image...
  mount_partition $3 img1 /mnt
  sudo cp $OUT_DIR/core.gz /mnt/boot/core-$KVER.gz
  sudo cp $OUT_DIR/bzImage /mnt/boot/vmlinuz-$KVER
  cp /mnt/boot/grub/menu.lst /tmp/GRUB/menu.lst
  cat >> /tmp/GRUB/menu.lst << EOF
title		VRouter
root		(hd0,0)
kernel		/boot/vmlinuz-$KVER waitusb=5 nodhcp nozswap opt=LABEL=VRouter user=vrouter home=LABEL=VRouter
initrd		/boot/core-$KVER.gz
EOF
  sudo cp /tmp/GRUB/menu.lst /mnt/boot/grub/menu.lst
  sync
  sudo umount /mnt
  sudo /sbin/losetup -d /dev/loop0
 fi

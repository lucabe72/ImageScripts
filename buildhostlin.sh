set -e

CPUS=8
TARGET_PATH=/home/vrouter
OUT_DIR=$PWD/Out/Host
TMP_DIR=/tmp/BuildHost
KVER=3.6.2
KVER=3.4.14

. $(dirname $0)/utils.sh

get_kernel() {
  if test -e linux-$KVER;
   then
    echo linux-$KVER already exists
   else
    if test -e linux-$KVER.tar.bz2;
     then
      echo linux-$KVER.tar.bz2 already exists
     else
      wget http://www.kernel.org/pub/linux/kernel/v3.0/linux-$KVER.tar.bz2
     fi
    tar xvjf linux-$KVER.tar.bz2
   fi
}

build_kernel() {
  cd linux-$KVER
echo  cp $1 .config
  cp $1 .config
  make oldconfig
  make -j $2
  cd ..
}

install_kernel() {
  cd linux-$KVER
  make INSTALL_MOD_PATH=$1 modules_install
  cp arch/x86/boot/bzImage $1
  cd ..
}

make_host_kernel() {
echo Make host $1 $2
  get_kernel
echo build
  build_kernel $2 $CPUS
  install_kernel $1
}

while getopts v: opt
 do
  case "$opt" in
    v)		KVER=$OPTARG;;
    [?])	print >&2 "Usage: $0 [-v <version>] <core> <config> [<host image>]"
		exit 1;;
  esac
 done



make_host_kernel $TMP_DIR $2
mkdir -p $OUT_DIR
mv $TMP_DIR/bzImage $OUT_DIR

extract_initramfs $1  $TMP_DIR/tmproot
sudo rm -rf $TMP_DIR/tmproot/lib/modules/*
sudo mkdir -p $TMP_DIR/tmproot/lib/modules
sudo cp -r  $TMP_DIR/lib/modules/* $TMP_DIR/tmproot/lib/modules
mk_initramfs $TMP_DIR/tmproot $OUT_DIR/core.gz

if [ x$3 != x ];
 then
  echo copying to image...
  mount_partition $3 img1 /mnt
  sudo cp $OUT_DIR/core.gz /mnt/boot/core-$KVER.gz
  sudo cp $OUT_DIR/bzImage /mnt/boot/vmlinuz-$KVER
  sudo umount /mnt
  sudo /sbin/losetup -d /dev/loop0
 fi

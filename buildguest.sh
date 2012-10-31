set -e

CPUS=8
TARGET_PATH=/home/vrouter
OUT_DIR=$PWD/Out/Guest
TMP_DIR=/tmp/BuildGuest
KVER=3.4.14

source $(dirname $0)/utils.sh

get_kernel() {
  if test -e $1;
   then
    echo $1 already exists
   else
    if test -e $1.tar.bz2;
     then
      echo $1.tar.bz2 already exists
     else
      wget http://www.kernel.org/pub/linux/kernel/v3.0/$1.tar.bz2
     fi
    tar xvjf $1.tar.bz2
   fi
}

build_kernel() {
  cd $1
  cp $2 .config
  make oldconfig
  make -j $3
  cd ..
}

install_kernel() {
  cd $1
  make INSTALL_MOD_PATH=$2 modules_install
  cp arch/x86/boot/bzImage $2
  cd ..
}

make_kernel() {
  get_kernel     linux-$KVER
  build_kernel   linux-$KVER $2 $CPUS
  install_kernel linux-$KVER $1
}

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
  GUEST_IMG=$3
  mount_partition $GUEST_IMG img1 /mnt
  sudo mkdir -p /mnt/opt
  cat > /tmp/bootlocal.sh << EOF
ifconfig eth0 192.168.1.3
ifconfig eth0:1 192.168.2.3
ifconfig eth0 txqueuelen 20000
echo 1 > /proc/sys/net/ipv4/ip_forward
EOF
  chmod +x /tmp/bootlocal.sh
  sudo cp /tmp/bootlocal.sh /mnt/opt/bootlocal.sh
  sudo umount /mnt
  sleep 1
  sudo /sbin/losetup -d /dev/loop0
 fi

if [[ x$4 != x ]];
 then
  mount_partition $4 img5 /mnt
  sudo mkdir -p /mnt/home/vrouter/Net/Core/boot
  sudo cp $OUT_DIR/core.gz /mnt/home/vrouter/Net/Core/boot
  sudo cp $OUT_DIR/bzImage /mnt/home/vrouter/Net/Core/boot/vmlinuz
  sudo cp $GUEST_IMG /mnt/home/vrouter/Net
  sudo umount /mnt
  sudo /sbin/losetup -d /dev/loop0
 fi

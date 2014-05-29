set -e

PARTITION_NAME=VRouter
VRUSER=vrouter
TMP_DIR=/tmp/L
TARGET_PATH=/home/$VRUSER/Public-LXC
SITE=http://linuxcontainers.org/downloads/

. $(dirname $0)/utils.sh
CPUS=$(get_j)

get_lxc() {
  if test -e $1;
   then
    echo $1 already exists
   else
    if test -e $1.tar.gz;
     then
      echo $1.tar.gz already exists
     else
      wget --no-check-certificate $SITE/$1.tar.gz
     fi
    tar xvzf $1.tar.gz
   fi
}

build_lxc() {
  mkdir -p $4
  cd $4
  ../$3/configure --prefix=$1 --disable-capabilities --disable-doc
  make -j $2
  cd ..
}

install_lxc() {
  cd $2
  make DESTDIR=$1 install
  strip $1/home/$VRUSER/bin/* || echo cannot strip some scripts - see errors
  cd ..
}

make_lxc() {
  get_lxc     lxc-$2
  build_lxc   $TARGET_PATH $CPUS lxc-$2 build-lxc-$2
  install_lxc $1 build-lxc-$2
}

update_home() {
  mkdir -p mnt
  mount_partition $1 img$2 mnt

  if test -e mnt/home;
   then
    echo Home already exists, good!
   else
    sudo mkdir mnt/home
   fi

  sudo cp -a $3 mnt/home

  LABEL=$(sudo /sbin/e2label /dev/loop0)
  if [ x$LABEL = x ]
   then
    sudo /sbin/e2label /dev/loop0 $PARTITION_NAME
   else
    PARTITION_NAME=$LABEL
   fi
  umount_partition mnt
  rm -rf mnt
}

add_to_grub() {
  mkdir mnt
  mount_partition $1 img1 mnt
  cp mnt/boot/grub/menu.lst /tmp/GRUB/menu.lst
  cat >> /tmp/GRUB/menu.lst << EOF
title		VRouter
root		(hd0,0)
kernel		/boot/vmlinuz-$KVER$EXTRAKNAME waitusb=5 nodhcp nozswap opt=LABEL=$PARTITION_NAME user=vrouter home=LABEL=$PARTITION_NAME
initrd		/boot/core-$KVER$EXTRAKNAME.gz
EOF
  sudo cp /tmp/GRUB/menu.lst mnt/boot/grub/menu.lst
  umount_partition mnt
  rm -rf mnt
}
 

make_lxc    $TMP_DIR $2
update_home $1 5 $TMP_DIR/home/$VRUSER
add_to_grub $1

#wget http://linuxcontainers.org/downloads/lxc-0.9.0.tar.gz
#tar xvzf lxc-0.9.0.tar.gz
#cd lxc-0.9.0
#./configure --prefix=/home/vrouter/LXC --disable-capabilities --disable-doc
#make -j 3
#DESTDIR=/tmp/L make install
#cd ..

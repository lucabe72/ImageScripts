set -e

VRUSER=rtester
SCRIPTS_REPO=http://www.disi.unitn.it/~abeni/PublicGits/Sfingi/TestScripts.git
TMP_DIR=/tmp/Tester

. $(dirname $0)/utils.sh
CPUS=$(get_j)
. $(dirname $0)/opts_parse.sh

get_scripts() {
  if test -e TestScripts;
   then
    cd TestScripts
    git pull
    cd ..
   else
    git clone $SCRIPTS_REPO
   fi
}

update_home() {
  mkdir mnt
  mount_partition $1 img$2 mnt

  if test -e mnt/home;
   then
    echo Home already exists, good!
   else
    sudo mkdir mnt/home
   fi

  sudo cp -a $3 mnt/home

  sudo mkdir -p mnt/opt

  sudo /sbin/e2label /dev/loop0 RTester 
  umount_partition mnt
  rm -rf mnt
}

add_to_grub() {
  mkdir mnt
  mount_partition $1 img1 mnt
  cp mnt/boot/grub/menu.lst /tmp/GRUB/menu.lst
  cat >> /tmp/GRUB/menu.lst << EOF
title		Router Tester
root		(hd0,0)
kernel		/boot/vmlinuz-$KVER waitusb=5 nodhcp nozswap opt=LABEL=RTester user=rtester home=LABEL=RTester
initrd		/boot/core-$KVER.gz
EOF
  sudo cp /tmp/GRUB/menu.lst mnt/boot/grub/menu.lst
  umount_partition mnt
  rm -rf mnt
}

get_scripts
mkdir -p $TMP_DIR/home/$VRUSER/Net
cp -a TestScripts/* $TMP_DIR/home/$VRUSER/Net
IMG=$1
update_home $IMG 5 $TMP_DIR/home/$VRUSER
add_to_grub $IMG

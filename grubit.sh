set -e

CPUS=8
KVER=3.4.14

source $(dirname $0)/utils.sh

get_grub() {
  if test -e grub-0.97;
   then
    echo GRUB already exists
   else
    tar xvzf $(dirname $0)/grub-legacy.tgz
   fi
}

build_grub() {
#aclocal-1.9 && automake-1.9 && autoconf
  cd grub-0.97
  ./configure --prefix=$1
  make -j $2
  cd ..
}

install_grub() {
  cd grub-0.97
  make install
  cd ..
}

copy_grub() {
  MY_ARCH=$(ls $2/lib/grub/)
  echo GRUB Architecture: $MY_ARCH
  mount_partition $1 img1 /mnt
  sudo mkdir -p /mnt/boot/grub
  sudo cp $2/lib/grub/$MY_ARCH/stage? /mnt/boot/grub
  cat > /tmp/GRUB/menu.lst << EOF
default		0
timeout		5
title		VRouter
root		(hd0,0)
kernel		/boot/vmlinuz-$KVER waitusb=5 nodhcp nozswap opt=LABEL=VRouter user=vrouter home=LABEL=VRouter
initrd		/boot/core-$KVER.gz
EOF
  sudo cp /tmp/GRUB/menu.lst /mnt/boot/grub/menu.lst
  sudo umount /mnt
  sudo /sbin/losetup -d /dev/loop0
  $2/sbin/grub --device-map=/dev/null << EOF
device (hd0) $1
root (hd0,0)
setup (hd0)
EOF
}

get_grub
build_grub /tmp/GRUB $CPUS
install_grub
copy_grub $1 /tmp/GRUB

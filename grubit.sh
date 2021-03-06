set -e

KVER=3.4.14
TMP_DIR=/tmp/GRUB

. $(dirname $0)/utils.sh
CPUS=$(get_j)
. $(dirname $0)/opts_parse.sh

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
EOF
  sudo cp /tmp/GRUB/menu.lst /mnt/boot/grub/menu.lst
  umount_partition /mnt
  $2/sbin/grub --device-map=/dev/null << EOF
device (hd0) $1
root (hd0,0)
setup (hd0)
EOF
}

. $(dirname $0)/opts_parse.sh

get_grub
build_grub $TMP_DIR $CPUS
install_grub
copy_grub $1 $TMP_DIR

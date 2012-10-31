set -e

CPUS=8
TARGET_PATH=/home/vrouter
OUT_DIR=$PWD/Out/Click
TMP_DIR=/tmp/Click
KVER=3.0.36

source $(dirname $0)/utils.sh

get_click() {
  if test -e click;
   then
    echo click already exists
   else
    git clone git://read.cs.ucla.edu/git/click
    git checkout -b test1 003061d8180c711f6c78b5395584772c1175205e
   fi
}

build_click() {
  cd click
  ./configure --prefix=$1 --with-linux=$PWD/../linux-3.0.36
  make -j $2
  cd ..
}

install_click() {
  cd click
  DESTDIR=$1 make install
  cd ..
}

strip_click() {
  rm -rf $1/include
  rm $1/lib/*.a
  rm -rf $1/share/man
  strip $1/bin/*
  strip $1/sbin/*
}

update_home() {
  mkdir mnt
  mount_partition $1 img1 mnt

  if test -e mnt/home;
   then
    echo Home already exists, good!
   else
    sudo mkdir mnt/home
   fi

  sudo cp -a $2 mnt$TARGET_PATH

  sudo umount mnt
  rm -rf mnt
  sudo /sbin/losetup -d /dev/loop0
}

get_libs() {
  APPS_BIN="click"
  APPS_SBIN="click-install click-uninstall"
  PROVIDED_LIBS="libpthread.so libgcc_s.so libc.so librt.so libstdc++.so libm.so libdl.so"

  for A in $APPS_BIN
   do
    get_exec_libs $1/bin/$A $1/lib
   done

  for A in $APPS_SBIN
   do
    get_exec_libs $1/sbin/$A $1/lib
   done

  for L in $PROVIDED_LIBS
   do
    rm $1/lib/$L*
   done
}

make_click_kernel() {
  get_kernel     linux-$KVER
  build_kernel   linux-$KVER $2 $CPUS
  install_kernel linux-$KVER $1
  get_click
  build_click $TARGET_PATH $CPUS
  install_click $1
  get_libs $1$TARGET_PATH
  strip_click $1$TARGET_PATH
}


make_click_kernel $TMP_DIR $3
mkdir -p $OUT_DIR
mv $TMP_DIR/bzImage $OUT_DIR

extract_initramfs $1  $TMP_DIR/tmproot
sudo rm -rf $TMP_DIR/tmproot/lib/modules/*
sudo cp -r  $TMP_DIR/lib/modules/* $TMP_DIR/tmproot/lib/modules
mk_initramfs $TMP_DIR/tmproot $OUT_DIR/core.gz

cp $2 $OUT_DIR/opt1.img
update_home $OUT_DIR/opt1.img $TMP_DIR$TARGET_PATH

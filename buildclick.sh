set -e

CPUS=8
TARGET_PATH=/home/vrouter
TMP_DIR=/tmp/Click
OUT_DIR=$PWD/Out/Click

. $(dirname $0)/utils.sh

get_kernel() {
  if test -e linux-3.0.36;
   then
    echo linux-3.0.36 already exists
   else
    if test -e linux-3.0.36.tar.bz2;
     then
      echo linux-3.0.36.tar.bz2 already exists
     else
      wget http://www.kernel.org/pub/linux/kernel/v3.0/linux-3.0.36.tar.bz2
     fi
    tar xvjf linux-3.0.36.tar.bz2
   fi
}

get_click() {
  if test -e click;
   then
    echo click already exists
   else
    git clone git://read.cs.ucla.edu/git/click
    cd click
    git checkout -b test1 003061d8180c711f6c78b5395584772c1175205e
    cd ..
   fi
}

build_kernel() {
  cd linux-3.0.36
  cp $1 .config
  make oldconfig
  make -j $2
  cd ..
}

install_kernel() {
  cd linux-3.0.36
  make INSTALL_MOD_PATH=$1 modules_install
  cp arch/x86/boot/bzImage $1
  cd ..
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
  get_kernel
  get_click
  build_kernel $2 $CPUS
  install_kernel $1
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

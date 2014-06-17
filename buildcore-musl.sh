set -e

SDIR=$(cd -- $(dirname $0) && pwd)
CONFIG_FILE=$SDIR/Configs/config-busybox-2
BBVER=1.20.2
MARCH=x86_64
TRIPLETT=$MARCH-linux-musl
COMPILER_PATH=$(dirname $(which $TRIPLETT-gcc))/..

. $(dirname $0)/utils.sh
CPUS=$(get_j)
. $(dirname $0)/opts_parse.sh

copy_musl() {
  mkdir -p $1/lib
  cp -a $COMPILER_PATH/$TRIPLETT/lib/*.so $1/lib
  P=$(pwd)
  cd $1/lib
  ln -s libc.so ld-musl-$MARCH.so.1
  strip libc.so
  cd $P
}

get_bb() {
  if test -e $1;
   then
    echo $1 already exists
   else
    if test -e $1.tar.bz2;
     then
      echo $1.tar.bz2 already exists
     else
      wget http://www.busybox.net/downloads//$1.tar.bz2
     fi
    tar xvjf $1.tar.bz2
   fi
}

build_bb() {
  BUILDDIR=$4

  mkdir -p $BUILDDIR
  cd       $BUILDDIR
  cp $2 .config
  make -C $(pwd)/../$1 O=$(pwd) oldconfig ARCH=$MARCH CROSS_COMPILE=$TRIPLETT-
  make -j $3 ARCH=$MARCH CROSS_COMPILE=$TRIPLETT-
  cd ..
}

install_bb() {
  cd $1
  rm -rf _install
  make ARCH=$MARCH CROSS_COMPILE=$TRIPLETT- install
  cd ..
}

build_root() {
  cd $1
  cp -a $SDIR/etc _install/etc
  cp $SDIR/sbin/* _install/sbin
  rm -f _install/linuxrc
  rm -f _install/init
  ln -s /bin/busybox _install/init

  mkdir -p _install/proc

  mkdir -p _install/lib
  copy_musl _install
  cd ..
}

#FIXME!
get_sudo() {
  if test -e $1;
   then
    echo $1 already exists
   else
    if test -e $1.tar.gz;
     then
      echo $1.tar.gz already exists
     else
      wget http://www.sudo.ws/sudo/dist/$1.tar.gz
     fi
    tar xvzf $1.tar.gz
   fi
}

build_sudo() {
  BUILDDIR=$3

  mkdir -p $BUILDDIR
  cd       $BUILDDIR
  ../$1/configure --prefix=/ --disable-authentication --disable-shadow --disable-pam-session --disable-zlib --without-lecture --without-sendmail --without-umask --without-interfaces --without-pam --host=$MARCH-linux CC=$TRIPLETT-gcc
  make -j $2
  cd ..
}

install_sudo() {
  BBBUILD=$2

  cd $1
  rm -rf /tmp/S
  make DESTDIR=/tmp/S install
  cp /tmp/S/bin/sudo $BBBUILD/_install/bin
  strip $BBBUILD/_install/bin/sudo

  cd ..
}

get_bb		busybox-$BBVER
patch_source	$SDIR/Patches/BusyBox/$BBVER busybox-$BBVER 
build_bb	busybox-$BBVER $CONFIG_FILE $CPUS bb_build-$BBVER
install_bb	bb_build-$BBVER
build_root	bb_build-$BBVER

get_sudo	sudo-1.7.10p3
build_sudo	sudo-1.7.10p3 $CPUS sudo_build-1.7.10p3
install_sudo	sudo_build-1.7.10p3 $(pwd)/bb_build-$BBVER

mk_initramfs bb_build-$BBVER/_install $1 NoSUDO

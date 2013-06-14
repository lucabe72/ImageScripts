set -e

SDIR=$(cd -- $(dirname $0) && pwd)
CONFIG_FILE=$SDIR/Configs/config-busybox-2
BBVER=1.20.2

. $(dirname $0)/utils.sh
CPUS=$(get_j)
. $(dirname $0)/opts_parse.sh

get_exec_libs_root() {
  LIBS=$(ldd $1 | cut -f 2 | cut -d ' ' -f 3)
  LD_LINUX=$(strings $1 | grep ld-linux)
  for L in $LIBS
   do
    DIR=$(dirname $L | cut -f 2 -d '/')
    cp $L $2/$DIR
   done
  cp $LD_LINUX $2/$(dirname $LD_LINUX)
}

fetch_lib() {
  D=$(ldd /bin/ls | grep libc | cut -f 3 -d ' ' | xargs dirname)
  LIB=$(find $D -name $2)
  if [ "x$LIB" != "x" ];
   then
    cp $LIB $3/$1
   else
    echo Fetch Lib: $2 not found in $D - doing nothing
   fi
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
  make -C $(pwd)/../$1 O=$(pwd) oldconfig
  make -j $3
  cd ..
}

install_bb() {
  cd $1
  rm -rf _install
  make install
  cd ..
}

#FIXME: Why are this needed? Just for completeness?
fetch_std_libs() {
  cd $1
  fetch_lib /lib/ libpthread.so.0 _install
  fetch_lib /lib/ librt.so.1 _install
  fetch_lib /lib/ libdl.so.2 _install
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
  get_exec_libs_root _install/bin/busybox _install
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
  ../$1/configure --prefix=/ --disable-authentication --disable-shadow --disable-pam-session --disable-zlib --without-lecture --without-sendmail --without-umask --without-interfaces --without-pam
  make -j $2
  cd ..
}

install_sudo() {
  BBBUILD=$2

  cd $1
  rm -rf /tmp/S
  make DESTDIR=/tmp/S install
  cp /tmp/S/bin/sudo $BBBUILD/_install/bin
  get_exec_libs_root $BBBUILD/_install/bin/sudo $BBBUILD/_install

  #FIXME: Check this!
  fetch_lib /lib/   libnss_compat* $BBBUILD/_install
  fetch_lib /lib/   libnss_files*  $BBBUILD/_install

  cd ..
}

get_bb		busybox-$BBVER
patch_source	$SDIR/Patches/BusyBox/$BBVER busybox-$BBVER 
build_bb	busybox-$BBVER $CONFIG_FILE $CPUS bb_build-$BBVER
install_bb	bb_build-$BBVER
build_root	bb_build-$BBVER
fetch_std_libs	bb_build-$BBVER

get_sudo	sudo-1.7.10p3
build_sudo	sudo-1.7.10p3 $CPUS sudo_build-1.7.10p3
install_sudo	sudo_build-1.7.10p3 $(pwd)/bb_build-$BBVER

mk_initramfs bb_build-$BBVER/_install $1 NoSUDO

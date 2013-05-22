set -e

SDIR=$(cd -- $(dirname $0) && pwd)
CFG=$SDIR/Configs/config-busybox-2
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
  tar xvjf $SDIR/busybox-$BBVER.tar.bz2
  patch_source $SDIR/Patches/BusyBox/$BBVER busybox-$BBVER 
}

build_bb() {
  cd busybox-$BBVER
  cp $CFG .config
  make oldconfig
  make -j $CPUS
  rm -rf _install
  make install
  cd ..
}

build_root() {
  cd busybox-$BBVER
  cp -a $SDIR/etc _install/etc
  cp $SDIR/sbin/* _install/sbin
  rm -f _install/linuxrc
  rm -f _install/init
  ln -s /bin/busybox _install/init

  mkdir -p _install/proc

  #FIXME!
  mkdir -p _install/lib64
  mkdir -p _install/lib
  get_exec_libs_root _install/bin/busybox _install
  cd ..
}

get_sudo() {
  tar xvzf $SDIR/sudo-1.7.10p3.tar.gz
}

build_sudo() {
  cd sudo-1.7.10p3
  ./configure --prefix=/ --disable-authentication --disable-shadow --disable-pam-session --disable-zlib --without-lecture --without-sendmail --without-umask --without-interfaces --without-pam
  make -j $CPUS
  cd ..
}

install_sudo() {
  cd sudo-1.7.10p3
  rm -rf /tmp/S
  make DESTDIR=/tmp/S install
  cp /tmp/S/bin/sudo ../busybox-$BBVER/_install/bin
  get_exec_libs_root ../busybox-$BBVER/_install/bin/sudo ../busybox-$BBVER/_install

  fetch_lib /lib/   libnss_compat* ../busybox-$BBVER/_install
  fetch_lib /lib/   libnss_files*  ../busybox-$BBVER/_install
  fetch_lib /lib64/ libnss_compat* ../busybox-$BBVER/_install
  fetch_lib /lib64/ libnss_files*  ../busybox-$BBVER/_install

  cd ..
}

get_bb
build_bb
build_root

cd busybox-$BBVER
fetch_lib /lib/ libpthread.so.0 _install
fetch_lib /lib/ librt.so.1 _install
fetch_lib /lib/ libdl.so.2 _install
cd ..

get_sudo
build_sudo
install_sudo

mk_initramfs busybox-$BBVER/_install $1 NoSUDO

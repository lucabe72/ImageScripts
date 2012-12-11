SRCD=$(pwd)
CFG=$(pwd)/Configs/config-busybox

get_exec_libs() {
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
  LIB=$(find $1 -name $2)
  cp $LIB $3/$1
}

tar xvjf busybox-1.20.2.tar.bz2
cd busybox-1.20.2
cp $CFG .config
make oldconfig
make
make install
cp -a $SRCD/etc _install/etc
cp $SRCD/usr_sbin/* _install/usr/sbin
cp $SRCD/sbin/* _install/sbin
rm _install/linuxrc
ln -s /bin/busybox _install/init

#FIXME!
mkdir _install/lib64
mkdir _install/lib
get_exec_libs _install/bin/busybox _install
cd ..

tar xvzf sudo-1.7.10p3.tar.gz
cd sudo-1.7.10p3
./configure --prefix=/ --disable-authentication --disable-shadow --disable-pam-session --disable-zlib --without-lecture --without-sendmail --without-umask --without-interfaces --without-pam
make -j 6
rm -rf /tmp/S
make DESTDIR=/tmp/S install
cp /tmp/S/bin/sudo ../busybox-1.20.2/_install/bin
get_exec_libs ../busybox-1.20.2/_install/bin/sudo ../busybox-1.20.2/_install

fetch_lib /lib libnss_compat* ../busybox-1.20.2/_install
fetch_lib /lib libnss_files* ../busybox-1.20.2/_install
fetch_lib /lib64 libnss_compat* ../busybox-1.20.2/_install
fetch_lib /lib64 libnss_files* ../busybox-1.20.2/_install

cd ..


cd busybox-1.20.2/_install
find . | cpio -o -H newc | gzip > ../../$1


set -e

PARTITION_NAME=VRouter
VRUSER=vrouter
TMP_DIR=/tmp/Quagga
TARGET_PATH=/home/$VRUSER/Public-Quagga

. $(dirname $0)/utils.sh
CPUS=$(get_j)

get_quagga() {
  if test -e $1;
   then
    echo $1 already exists
   else
    if test -e $1.tar.gz;
     then
      echo $1.tar.gz already exists
     else
      wget http://download.savannah.gnu.org/releases/quagga/$1.tar.gz
     fi
    tar xvzf $1.tar.gz
   fi
}

build_quagga() {
  cd $3
  ./configure --prefix=$1 --disable-doc
  make -j $2
  cd ..
}

install_quagga() {
  cd $2
  make DESTDIR=$1 install
  cd ..
}

fetch_lib() {
  if test -e $1;
   then
    LIB=$(find $1 -name $2)
    cp $LIB $3/$1
   else
    echo Fetch Lib: $1 does not exist - doing nothing
   fi
}

get_libs64() {
echo Get libs 64
  STD_LIBS="libpthread.so libgcc_s.so libc.so librt.so libm.so libdl.so"
  LD_LINUX=$(strings $1/sbin/zebra | grep ld-linux)

  mkdir -p $1/lib64

  for A in $STD_LIBS
   do
    fetch_lib /lib64/ $A* $1
   done

  cp $LD_LINUX $1/lib64

}

make_quagga() {
  get_quagga quagga-$2
  build_quagga $TARGET_PATH $CPUS quagga-$2
  install_quagga $1 quagga-$2

  MY_ARCH=$(arch)
  if [ $MY_ARCH = x86_64 ];
   then
    get_libs64 $1$TARGET_PATH
   else
#    get_libs $1$TARGET_PATH
     echo 32bit
   fi
  fetch_lib /lib/   libnss_compat* $1$TARGET_PATH
  fetch_lib /lib/   libnss_files*  $1$TARGET_PATH
  fetch_lib /lib64/ libnss_compat* $1$TARGET_PATH
  fetch_lib /lib64/ libnss_files*  $1$TARGET_PATH
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

  umount_partition mnt
  rm -rf mnt
}

make_quagga $TMP_DIR $2
update_home $1 1     $TMP_DIR/home/$VRUSER

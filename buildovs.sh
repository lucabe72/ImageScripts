set -e

PARTITION_NAME=VRouter
VRUSER=vrouter
TMP_DIR=/tmp/OVS
TARGET_PATH=/home/$VRUSER/Public-OpenVSwitch

. $(dirname $0)/utils.sh
CPUS=$(get_j)

get_ovs() {
  if test -e $1;
   then
    echo $1 already exists
   else
    if test -e $1.tar.gz;
     then
      echo $1.tar.gz already exists
     else
      wget http://openvswitch.org/releases/$1.tar.gz
     fi
    tar xvzf $1.tar.gz
   fi
}

build_ovs() {
  cd $3
  ./configure --prefix=$1 --disable-ssl --enable-ndebug --with-linux=$4
  make -j $2
  cd ..
}

install_ovs() {
  cd $2
  make DESTDIR=$1 install
  cd ..
}

get_libs64() {
echo Get libs 64
  APPS_BIN="ovs-vsctl"
  APPS_SBIN=""
  APPS_LIBS=""
  PROVIDED_LIBS=""
  LD_LINUX=$(strings $1/bin/ovs-vsctl | grep ld-linux)

  mkdir -p $1/lib64

  for A in $APPS_BIN
   do
    get_exec_libs $1/bin/$A $1/lib64
   done

  for A in $APPS_SBIN
   do
    get_exec_libs $1/sbin/$A $1/lib64
   done

  for A in $APPS_LIBS
   do
    get_exec_libs $1/lib/$A $1/lib64
   done

  for L in $PROVIDED_LIBS
   do
    rm -f $1/lib64/$L*
   done

  cp $LD_LINUX $1/lib64
}

make_ovs() {
  get_ovs openvswitch-$2
  build_ovs $TARGET_PATH $CPUS openvswitch-$2 $3
  install_ovs $1 openvswitch-$2

  MY_ARCH=$(arch)
  if [ $MY_ARCH = x86_64 ];
   then
    get_libs64 $1$TARGET_PATH
   else
     echo 32bit
   fi
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

make_ovs    $TMP_DIR $2 $(pwd)/build-host$KVER$EXTRAKNAME 
update_home $1 5     $TMP_DIR/home/$VRUSER


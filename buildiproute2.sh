set -e

PARTITION_NAME=VRouter
VRUSER=vrouter
TMP_DIR=/tmp/IPRoute2
TARGET_PATH=/home/$VRUSER/Public-IPRoute2
SITE=https://www.kernel.org/pub/linux/utils/net/iproute2

. $(dirname $0)/utils.sh
CPUS=$(get_j)

get_iproute2() {
  if test -e $1;
   then
    echo $1 already exists
   else
    if test -e $1.tar.gz;
     then
      echo $1.tar.gz already exists
     else
      wget $SITE/$1.tar.gz
     fi
    tar xvzf $1.tar.gz
   fi
}

build_ip() {
  # $1: Prefix... How to use it?
  cd $3
  make  SUBDIRS="lib ip" -j $2
  cd ..
}

install_ip() {
  cd $2
  make SUBDIRS="lib ip" DESTDIR=$1-tmp install
  mkdir -p $1/home/$VRUSER
  cp -a $1-tmp/sbin $1/home/$VRUSER/bin
  strip $1/home/$VRUSER/bin/* || echo cannot strip some scripts - see errors
  cd ..
}

make_ip() {
  get_iproute2 iproute2-$2
  build_ip $TARGET_PATH $CPUS iproute2-$2
  install_ip $1 iproute2-$2
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

make_ip     $TMP_DIR $2
update_home $1 5 $TMP_DIR/home/$VRUSER


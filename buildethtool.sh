set -e

PARTITION_NAME=VRouter
VRUSER=vrouter
TMP_DIR=/tmp/EthTool
TARGET_PATH=/home/$VRUSER
SITE=https://www.kernel.org/pub/software/network/ethtool

. $(dirname $0)/utils.sh
CPUS=$(get_j)

get_ethtool() {
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

build_ethtool() {
  cd $3
  ./configure --sbindir=$1/bin
  make -j $2
  cd ..
}

install_ethtool() {
  cd $2
  make DESTDIR=$1 install
  cd ..
}

make_ethtool() {
  get_ethtool     ethtool-$2
  build_ethtool   $TARGET_PATH $CPUS ethtool-$2
  install_ethtool $1 ethtool-$2
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

make_ethtool $TMP_DIR $2
update_home  $1 5 $TMP_DIR/home/$VRUSER

set -e

PARTITION_NAME=VRouter
VRUSER=vrouter
TMP_DIR=/tmp/Quagga

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

make_quagga() {
  get_quagga quagga-$2
  build_quagga /home/$VRUSER/Public-Quagga $CPUS quagga-$2
  install_quagga $1 quagga-$2
}

update_home() {
  mkdir mnt
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

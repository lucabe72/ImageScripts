set -e

VRUSER=vrouter
CPUS=8
TMP_DIR=/tmp/KVM
SCRIPTS_REPO=http://www.disi.unitn.it/~abeni/PublicGits/Sfingi/VRouter-Scripts.git

. $(dirname $0)/utils.sh

get_scripts() {
  if test -e VRouter-Scripts;
   then
    cd VRouter-Scripts
    git pull
    cd ..
   else
    git clone $SCRIPTS_REPO
   fi
}

get_kvm() {
  if test -e qemu-kvm-git;
   then
    echo KVM already exists
   else
    tar xvzf $(dirname $0)/qemu-kvm.tgz
   fi
}

build_kvm() {
  cd qemu-kvm-git
  ./configure --prefix=$1
  make -j $2
  cd ..
}

install_kvm() {
  cd qemu-kvm-git
  make DESTDIR=$1 install
  cd ..
}

get_libs() {
  APPS="qemu-system-x86_64"
  PROVIDED_LIBS="libpthread.so libgcc_s.so libc.so librt.so libstdc++.so libm.so libdl.so"

  mkdir -p $2/lib
  for A in $APPS
   do
    get_exec_libs $1/bin/$A $2/lib
   done

  for L in $PROVIDED_LIBS
   do
    rm -f $2/lib/$L*
   done
}

make_kvm() {
  get_kvm
  build_kvm /home/$VRUSER/Public-KVM-Test $CPUS
  install_kvm $1
  get_libs $1/home/$VRUSER/Public-KVM-Test $1/home/$VRUSER
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

  sudo umount mnt
  rm -rf mnt
  sudo /sbin/e2label /dev/loop0 VRouter
  sleep 1 # Why is this needed?
  sudo /sbin/losetup -d /dev/loop0
}


make_kvm $TMP_DIR
get_scripts
mkdir -p $TMP_DIR/home/$VRUSER/Net
cp VRouter-Scripts/* $TMP_DIR/home/$VRUSER/Net
#mkdir -p $OUT_DIR
#cp $1 $OUT_DIR/opt1.img
#IMG=$OUT_DIR/opt1.img
IMG=$1
cp -r $(dirname $0)/bin $TMP_DIR/home/$VRUSER
update_home $IMG 5 $TMP_DIR/home/$VRUSER


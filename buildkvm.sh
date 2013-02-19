set -e

PARTITION_NAME=VRouter
VRUSER=vrouter
TMP_DIR=/tmp/KVM
SCRIPTS_REPO=http://www.disi.unitn.it/~abeni/PublicGits/Sfingi/VRouter-Scripts.git

. $(dirname $0)/utils.sh
CPUS=$(get_j)
. $(dirname $0)/opts_parse.sh

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
  if test -e $1;
   then
    echo KVM already exists
   else
    tar xvzf $(dirname $0)/$1.tgz
   fi
}

build_kvm() {
  cd $3
  ./configure --prefix=$1
  make -j $2
  cd ..
}

install_kvm() {
  cd $2
  make DESTDIR=$1 install
  cd ..
}

get_libs() {
  PROVIDED_LIBS="$4"

  mkdir -p $2/lib
  for A in $3
   do
    get_exec_libs $1/bin/$A $2/lib
   done

  for L in $PROVIDED_LIBS
   do
    rm -f $2/lib/$L*
   done
}

get_libs64() {
echo Get libs 64
  LD_LINUX=$(strings $1/bin/$3 | grep ld-linux)
  mkdir -p $2/lib64
  for A in $3
   do
    get_exec_libs $1/bin/$A $2/lib64
   done

  cp $LD_LINUX $2/lib64
}

make_kvm() {
  PROVIDED_LIBS="libpthread.so libgcc_s.so libc.so librt.so libstdc++.so libm.so libdl.so"
  get_kvm $2
  build_kvm /home/$VRUSER/Public-KVM-Test $CPUS $2
  install_kvm $1 $2
  MY_ARCH=$(arch)
  if [ $MY_ARCH = x86_64 ];
   then
    get_libs64 $1/home/$VRUSER/Public-KVM-Test $1/home/$VRUSER qemu-system-x86_64
   else
    get_libs $1/home/$VRUSER/Public-KVM-Test $1/home/$VRUSER qemu-system-x86_64 "$PROVIDED_LIBS"
   fi
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

  sudo mkdir -p mnt/opt
  MY_ARCH=$(arch)
  if [ $MY_ARCH = x86_64 ];
   then
    cat > /tmp/bootlocal.sh << EOF
cp -a /home/vrouter/lib64 /
EOF
    chmod +x /tmp/bootlocal.sh
    sudo cp /tmp/bootlocal.sh mnt/opt/bootlocal.sh
   fi

  LABEL=$(sudo /sbin/e2label /dev/loop0)
  if [ x$LABEL = x ]
   then
    sudo /sbin/e2label /dev/loop0 $PARTITION_NAME
   else
    PARTITION_NAME=$LABEL
   fi
  umount_partition mnt
  rm -rf mnt
}

add_to_grub() {
  mkdir mnt
  mount_partition $1 img1 mnt
  cp mnt/boot/grub/menu.lst /tmp/GRUB/menu.lst
  cat >> /tmp/GRUB/menu.lst << EOF
title		VRouter
root		(hd0,0)
kernel		/boot/vmlinuz-$KVER$EXTRAKNAME waitusb=5 nodhcp nozswap opt=LABEL=$PARTITION_NAME user=vrouter home=LABEL=$PARTITION_NAME
initrd		/boot/core-$KVER$EXTRAKNAME.gz
EOF
  sudo cp /tmp/GRUB/menu.lst mnt/boot/grub/menu.lst
  umount_partition mnt
  rm -rf mnt
}
 
make_kvm $TMP_DIR $2 
get_scripts
mkdir -p               $TMP_DIR/home/$VRUSER/Net
mkdir -p               $TMP_DIR/home/$VRUSER/bin
cp VRouter-Scripts/*   $TMP_DIR/home/$VRUSER/Net
#mkdir -p $OUT_DIR
#cp $1 $OUT_DIR/opt1.img
#IMG=$OUT_DIR/opt1.img
IMG=$1
cp $(dirname $0)/bin/* $TMP_DIR/home/$VRUSER/bin
if test -e bin;
 then
  cp bin/*             $TMP_DIR/home/$VRUSER/bin
 fi
update_home $IMG 5     $TMP_DIR/home/$VRUSER
add_to_grub $IMG

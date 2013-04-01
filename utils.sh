mount_partition()
{
  SIZE=$(echo $(/sbin/sfdisk -l -u S $1 | grep $2) | cut -d ' ' -f 4)
  START=$(echo $(/sbin/sfdisk -l -u S $1 | grep $2) | cut -d ' ' -f 2)
  echo Size: $SIZE
  echo Start: $START
  START=$((START*512))
  SIZE=$((SIZE*512))

  sudo /sbin/losetup -o $START /dev/loop0 $1
  sudo mount /dev/loop0 $3
}

umount_partition() {
  set +e	# umount can fail due to some daemons doing stupid things with loopback devices
  until sudo umount $1
   do
    echo UMount returned $?
    sleep 1
   done 
  set -e
  sleep 1 
  sudo /sbin/losetup -d /dev/loop0
}

format_partition() {
  echo Formatting partition $2 on $1
  echo Getting partition information...
  SIZE=$(echo $(/sbin/sfdisk -l -u S $1 | grep img$2) | cut -d ' ' -f 4)
  START=$(echo $(/sbin/sfdisk -l -u S $1 | grep img$2) | cut -d ' ' -f 2)
  echo Size: $SIZE
  echo Start: $START
  START=$((START*512))
  SIZE=$((SIZE*512))

  echo Creating a FS on the partition...
  sudo /sbin/losetup --offset $START --sizelimit $SIZE /dev/loop0 $1
  sudo /sbin/mkfs.ext3 /dev/loop0
  sudo /sbin/losetup -d /dev/loop0
}

get_cpus() {
  echo $(grep processor /proc/cpuinfo | wc -l)
}

get_j() {
  C=$(get_cpus)
  if [ $C -ne 1 ]
   then
     C=$((C-1))
   fi
  echo $C
}

get_exec_libs() {
  LIBS=$(ldd $1 | cut -f 2 | cut -d ' ' -f 3)
  for L in $LIBS
   do
    cp $L $2
   done
}

extract_initramfs() {
  echo Extract $1 $2
  HERE=$PWD
  sudo rm -rf $2
  mkdir $2
  cd $2
  zcat $1 | sudo cpio -i
  cd $HERE
}

mk_initramfs() {
  echo MkInitRAMFs $1 $2
  HERE=$PWD
  cd $1
  sudo find . | sudo cpio -o -H newc | gzip > $2
  cd $HERE
}

update_initramfs()
{
  extract_initramfs $1  $2/tmproot
  sudo rm -rf   $2/tmproot/lib/modules/*
  sudo mkdir -p $2/tmproot/lib/modules
  sudo cp -r    $2/lib/modules/* $2/tmproot/lib/modules
  mk_initramfs  $2/tmproot $3/core.gz
}

get_kernel() {
  if test -e $1;
   then
    echo $1 already exists
   else
    if test -e $1.tar.bz2;
     then
      echo $1.tar.bz2 already exists
     else
      wget http://www.kernel.org/pub/linux/kernel/v3.0/$1.tar.bz2
     fi
    tar xvjf $1.tar.bz2
   fi
}

build_kernel() {
  BUILDDIR=$4

  mkdir -p $BUILDDIR
  cd       $BUILDDIR
  cp $2 .config
  make -C $(pwd)/../$1 O=$(pwd) oldconfig
  make -j $3
  cd ..
}

install_kernel() {
  BUILDDIR=$2

  cd $BUILDDIR
  make INSTALL_MOD_PATH=$1 modules_install
  cp arch/x86/boot/bzImage $1
  cd ..
}

patch_source()
{
  PATCHES=$(ls $1)
  TMP=$(pwd)

  if test -e $2/.patched;
   then
    echo $2 is already patched
   else
    cd $2
    touch .patched
    for p in $PATCHES
     do
      ls $1/$p
      patch -p1 < $1/$p
     done
    cd $TMP
   fi
}

make_kernel() {
  DIR=linux-$KVER
  INSTALL_DIR=$1
  CONFIG_FILE=$2
  BUILDDIR=$3
  PATCH_DIR=$4

  get_kernel     $DIR
  if [ x$PATCH_DIR != x ];
   then
    patch_source $PATCH_DIR linux-$KVER
   fi
  build_kernel   $DIR $CONFIG_FILE $CPUS $BUILDDIR
  install_kernel $INSTALL_DIR $BUILDDIR
}


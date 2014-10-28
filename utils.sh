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
  sync
  sudo umount $1
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
  sleep 1
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
     if [ $L = not ]
      then
       echo Warning! Not finding some library...
      else 
       if [ ! -e $2/$(basename $L) ]
        then
         cp $L $2
        fi
      fi
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
  if [ x$3 != x ];
   then
    SUDO=""
    echo MkInitRAMFs $1 $2 NoSUDO
   else
    SUDO=sudo
    echo MkInitRAMFs $1 $2 SUDO
   fi
  
  HERE=$PWD
  cd $1
  $SUDO find . | $SUDO cpio -o -H newc | gzip > $2
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

get_kernel_config_name()
{
  MAJ=$(echo $1 | cut -d '.' -f 1)
  MIN=$(echo $1 | cut -d '.' -f 2)
  V=$MAJ.$MIN

  if [ $2 = x86 ]
   then
    B=32
   else if [ $2 = x86_64 ]
     then
      B=64
     else
      B=unknown
     fi
   fi

  echo config-$V-$3-$B
}

get_kernel_path() {
  MAJ=$(echo $KVER | cut -d '.' -f 1)
  MIN=$(echo $KVER | cut -d '.' -f 2)
  RES=v$MAJ.$MIN
  if [ $MAJ = 3 ]
   then
    if [ $MIN != 0 ]
     then
      RES=v3.x
     fi
   fi
  echo $RES
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
      KPATH=$(get_kernel_path $KVER)
      wget http://www.kernel.org/pub/linux/kernel/$KPATH/$1.tar.gz
     fi
    tar xvzf $1.tar.gz
   fi
}

build_kernel() {
  BUILDDIR=$4

  mkdir -p $BUILDDIR
  cd       $BUILDDIR
  cp $2 .config
  make -C $(pwd)/../$1 O=$(pwd) oldnoconfig #oldconfig
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


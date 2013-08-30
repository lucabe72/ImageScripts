set -e

SDIR=$(cd -- $(dirname $0) && pwd)

. $(dirname $0)/utils.sh

export HOST_ARCH=x86
CORE=$(pwd)/test.gz
HOST_KVER=3.10.6
EXTRAKNAME="-vrhost"
PARTITION_NAME=SWRouter
TMP_DIR=/tmp/SWR
VRUSER=swrouter

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
title           SWRouter $KVER$RTC
root            (hd0,0)
kernel          /boot/vmlinuz-$KVER$EXTRAKNAME waitusb=5 nodhcp nozswap opt=LABEL=$PARTITION_NAME user=$VRUSER home=LABEL=$PARTITION_NAME
initrd          /boot/core-$KVER$EXTRAKNAME.gz
EOF
  sudo cp /tmp/GRUB/menu.lst mnt/boot/grub/menu.lst
  umount_partition mnt
  rm -rf mnt
}

download_rt_patch() {
  wget https://www.kernel.org/pub/linux/kernel/projects/rt/$1/patch-$2.patch.bz2 || wget https://www.kernel.org/pub/linux/kernel/projects/rt/$1/older/patch-$2.patch.bz2
  bunzip2 patch-$2.patch.bz2
  mv patch-$2.patch $3
}

get_rt_patch() {
#  wget https://www.kernel.org/pub/linux/kernel/projects/rt/3.10/patches-3.10.6-rt3.tar.bz2
#  tar xvjf patches-3.10.6-rt3.tar.bz2
#  mv patches patches-3.10.6-rt3
  MAJ=$(echo $1 | cut -d '.' -f 1)
  MIN=$(echo $1 | cut -d '.' -f 2)
  VER_PREFIX=$MAJ.$MIN
  RTVER=$(echo $2 | cut -d '-' -f 1)
  FEAT=$(echo $2 | cut -d '-' -f 2)
  mkdir -p $3
  if [ $FEAT != $RTVER ]
   then
    echo RT: $2 Feat: $FEAT
#    wget https://www.kernel.org/pub/linux/kernel/projects/rt/$VER_PREFIX/features/patch-$1-$2.patch.bz2
#    bunzip2 patch-$1-$2.patch.bz2
#    mv patch-$1-$2.patch $3/1patch-$1-$2.patch
    download_rt_patch $VER_PREFIX/features $1-$2 $3/1patch-$1-$2.patch
#    VER_PREFIX="$VER_PREFIX/older"
   fi
#  wget https://www.kernel.org/pub/linux/kernel/projects/rt/$VER_PREFIX/patch-$1-$RTVER.patch.bz2 || wget https://www.kernel.org/pub/linux/kernel/projects/rt/$VER_PREFIX/older/patch-$1-$RTVER.patch.bz2
#  bunzip2 patch-$1-$RTVER.patch.bz2
#  mv patch-$1-$RTVER.patch $3/0patch-$1-$RTVER.patch
  download_rt_patch $VER_PREFIX $1-$RTVER $3/0patch-$1-$RTVER.patch
}

build_nena_drivers() {
  rm -rf $1-$2-nena
  cp -r linux-$2/drivers/net/ethernet/intel/$1 $1-$2-nena
  cd $1-$2-nena
  cp $SDIR/nena-stubs.h .
  echo \#include \"nena-stubs.h\" >> e1000.h
  make -C $(pwd)/../build-host$2$EXTRAKNAME M=$(pwd) modules
  cp $1.ko $TMP_DIR/home/$VRUSER/$1-$2$EXTRAKNAME.ko
  cd ..
}

while getopts 4Crkv:R: opt
 do
  case "$opt" in
    4)		HOST_ARCH=x86_64;;
    C)		CORE=$DSIR/core.gz;;
    v)		HOST_KVER=$OPTARG;;
    r)          EXTRAKNAME="$EXTRAKNAME-rt"; RT=YesPlease;;
    R)          EXTRAKNAME="$EXTRAKNAME-$OPTARG"; RT=$OPTARG;;
    k)		KEEPIMAGE=YesPlease;;
    [?])	print >&2 "Usage: $0 [-4]"
		exit 1;;
  esac
 done

if test -e $CORE;
 then
  echo $CORE already exists
 else
  echo Building $CORE
  sh $SDIR/buildcore.sh $CORE
 fi

export EXTRAKNAME
if [ x$KEEPIMAGE = x ]
 then
  sh $SDIR/create_image.sh test.img 512 256 
  sh $SDIR/grubit.sh test.img
 fi
if [ x$RT != x ]
 then
  get_rt_patch $HOST_KVER $RT patches-$HOST_KVER-$RT
  RTC=-rt
  PATCHES=$(pwd)/patches-$HOST_KVER-$RT
 fi
export KVER=$HOST_KVER
export ARCH=$HOST_ARCH
export KERN_PATCHES=$PATCHES
HOST_CONFIG=$(get_kernel_config_name $HOST_KVER $HOST_ARCH host)$RTC
sh $SDIR/buildhostlin.sh $CORE $SDIR/Configs/$HOST_CONFIG test.img
mkdir -p $TMP_DIR/home/$VRUSER
if [ x$RT != x ]
 then
  build_nena_drivers e1000e $HOST_KVER
 fi
update_home test.img 5 $TMP_DIR/home/$VRUSER
add_to_grub test.img

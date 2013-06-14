set -e

SDIR=$(cd -- $(dirname $0) && pwd)

if [ x$KVER = x ]
 then
  KVER=3.4.14
 fi
#EXTRAKNAME="-vrhost"
BUILD_DIR=build-host$KVER$EXTRAKNAME
OUT=Out/netmap-drivers

. $(dirname $0)/utils.sh
CPUS=$(get_j)

get_intel_drivers() {
  if test -e $1;
   then
    echo $1 already exists
   else
    if test -e $1.tar.gz;
     then
      echo $1.tar.gz already exists
     else
#      echo Please download $1.tar.gz from somewhere, and put it here
#      exit
#       cp $SDIR/$1.tar.gz .
      wget http://downloads.sourceforge.net/e1000/$1.tar.gz
     fi
    tar xvzf $1.tar.gz
   fi
}

get_version_from_name() {
  TMP=$(echo $1   | cut -d '-' -f 2)
  MAJ=$(echo $TMP | cut -d '.' -f 1)
  MIN=$(echo $TMP | cut -d '.' -f 2)
  SUB=$(echo $TMP | cut -d '.' -f 3)
  echo $MAJ.$MIN.$SUB
}

build_netmap() {
  cd $1/LINUX
  EXTRA="-I$(pwd) -I$(pwd)/../sys -I$(pwd)/../sys/dev -DCONFIG_NETMAP"
  make -j$3 -C $(pwd)/../../build-host$KVER$EXTRAKNAME M=$(pwd) DRIVERS=$2 EXTRA_CFLAGS="$EXTRA" modules
  cd ../..
}

get_original_netmap() {
  wget http://info.iet.unipi.it/~luigi/doc/20120813-netmap.tgz
  tar xvf 20120813-netmap.tgz
  mv netmap $1
}

get_netmap_drivers() {
  cd $1/LINUX
  make KSRC=$(pwd)/../../$2 get-drivers
  cd ../..
}

if test -e $BUILD_DIR;
 then
  echo $BUILD_DIR exists, good
 else
  echo Cannot find $BUILD_DIR
  exit
 fi

if [ x$1 != x ];
 then
  FNAME=$(basename $1)
  DVER=$(get_version_from_name $FNAME)
  echo Version: $DVER
 fi

if [ x$DVER = x ]
 then
  get_original_netmap netmap-module
  get_netmap_drivers netmap-module build-host$KVER$EXTRAKNAME e1000e
  DRV=e1000e/
 else
  get_intel_drivers e1000e-$DVER
  #cd e1000e-$DVER
  #patch -p1 < $SDIR/e1000e.diff
  patch_source $SDIR/Patches/e1000e-nm e1000e-$DVER
  cp $SDIR/if_e1000e_netmap.h e1000e-$DVER/src
  #cd ..
  DRV=../../e1000e-$DVER/src/

  tar xvzf $SDIR/nm-module.tgz
 fi

build_netmap netmap-module $DRV $CPUS

mkdir -p                              $OUT
cp netmap-module/LINUX/netmap_lin.ko  $OUT
cp netmap-module/LINUX/$DRV/e1000e.ko $OUT


set -e

SDIR=$(cd -- $(dirname $0) && pwd)

DVER=2.2.14
KVER=3.4.14
EXTRAKNAME="-vrhost"
BUILD_DIR=build-host$KVER$EXTRAKNAME

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
       cp $SDIR/$1.tar.gz .
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
  make KSRC=$(pwd)/../../build-host$KVER$EXTRAKNAME DRIVERS=../../$2/src/
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

get_intel_drivers e1000e-$DVER
#cd e1000e-$DVER
#patch -p1 < $SDIR/e1000e.diff
patch_source $SDIR/Patches/e1000e-nm e1000e-$DVER
cp $SDIR/if_e1000e_netmap.h e1000e-$DVER/src
#cd ..

tar xvzf $SDIR/nm-module.tgz
build_netmap netmap-module e1000e-$DVER

cp netmap-module/LINUX/netmap_lin.ko .
cp e1000e-$DVER/src/e1000e.ko        .


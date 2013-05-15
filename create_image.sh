set -e

. $(dirname $0)/utils.sh

image_create() {
  echo Creating $1 - size $2MB...
  dd if=/dev/zero of=$1 seek=$2 count=0 bs=$((1024*1024))
}

partitions_create() {
  echo Creating partitions on $1... - sizes $3
  if [ $2 -eq $3 ];
   then
    /sbin/sfdisk $1  << EOF
;
;
;
;
EOF
   else
    /sbin/sfdisk -uM $1  << EOF
,$3;
,,E;
;
;
,,L;
EOF
   fi
}

INAME=$1
ISIZE=$2
PSIZE=$3
if [ x$PSIZE = x ];
 then
  PSIZE=$2
 fi

image_create $INAME $ISIZE
partitions_create $INAME $ISIZE $PSIZE
format_partition $INAME 1

echo Mounting the partition...
mount_partition $INAME img1 /mnt
sudo touch /mnt/here

echo Cleaning up...
umount_partition /mnt

if [ $PSIZE -ne $ISIZE ];
 then
  echo Formatting 5
  format_partition $INAME 5
 fi


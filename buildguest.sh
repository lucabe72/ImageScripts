set -e

TARGET_PATH=/home/vrouter
OUT_DIR=$4
TMP_DIR=/tmp/BuildGuest
if [ x$IFACES = x ]
 then
  IFACES="eth0-192.168.1.3 eth0:0-192.168.2.3"
 fi

. $(dirname $0)/utils.sh
CPUS=$(get_j)
. $(dirname $0)/opts_parse.sh

if test -e $TMP_DIR/bzImage;
 then
  echo $TMP_DIR/bzImage already exists
 else
  make_kernel $TMP_DIR $2 build-guest$KVER
 fi
mkdir -p $OUT_DIR
mv $TMP_DIR/bzImage $OUT_DIR

update_initramfs $1 $TMP_DIR $OUT_DIR

#$3: Guest image -> Configure the net
if [ x$3 != x ];
 then
  GUEST_IMG=$3
  mount_partition $GUEST_IMG img1 /mnt
  sudo mkdir -p /mnt/opt
  rm -f /tmp/bootlocal.sh
  for I in $IFACES
   do
    NAME=$(echo $I | cut -d '-' -f 1)
    IP=$(echo $I | cut -d '-' -f 2)
    echo /sbin/ifconfig $NAME $IP >> /tmp/bootlocal.sh
    echo /sbin/ifconfig $NAME txqueuelen 20000 >> /tmp/bootlocal.sh
   done
  cat >> /tmp/bootlocal.sh << EOF
echo 1 > /proc/sys/net/ipv4/ip_forward
EOF
  chmod +x /tmp/bootlocal.sh
  sudo cp /tmp/bootlocal.sh /mnt/opt/bootlocal.sh
  umount_partition /mnt

 fi

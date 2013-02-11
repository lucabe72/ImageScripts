set -e

TARGET_PATH=/home/vrouter
OUT_DIR=$PWD/Out/Guest
TMP_DIR=/tmp/BuildGuest

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
  cat > /tmp/bootlocal.sh << EOF
/sbin/ifconfig eth0 192.168.1.3
/sbin/ifconfig eth0:1 192.168.2.3
/sbin/ifconfig eth0 txqueuelen 20000
echo 1 > /proc/sys/net/ipv4/ip_forward
EOF
  chmod +x /tmp/bootlocal.sh
  sudo cp /tmp/bootlocal.sh /mnt/opt/bootlocal.sh
  umount_partition /mnt
 fi

#$4: Host image -> Install guest image and stuff in /home/vrouter
if [ x$4 != x ];
 then
  mount_partition $4 img5 /mnt
  sudo mkdir -p /mnt/home/vrouter/Net/Core/boot
  sudo cp -a $OUT_DIR/core.gz /mnt/home/vrouter/Net/Core/boot
  sudo cp -a $OUT_DIR/bzImage /mnt/home/vrouter/Net/Core/boot/vmlinuz
  sudo cp -a $GUEST_IMG /mnt/home/vrouter/Net
  umount_partition /mnt
 fi

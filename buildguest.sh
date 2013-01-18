set -e

TARGET_PATH=/home/vrouter
OUT_DIR=$PWD/Out/Guest
TMP_DIR=/tmp/BuildGuest
KVER=3.4.14

. $(dirname $0)/utils.sh
CPUS=$(get_j)
. $(dirname $0)/opts_parse.sh

if test -e $TMP_DIR/bzImage;
 then
  echo $TMP_DIR/bzImage already exists
 else
  make_kernel $TMP_DIR $2
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
ifconfig eth0 192.168.1.3
ifconfig eth0:1 192.168.2.3
ifconfig eth0 txqueuelen 20000
echo 1 > /proc/sys/net/ipv4/ip_forward
EOF
  chmod +x /tmp/bootlocal.sh
  sudo cp /tmp/bootlocal.sh /mnt/opt/bootlocal.sh
  sudo umount /mnt
  sleep 1
  sudo /sbin/losetup -d /dev/loop0
 fi

#$4: Host image -> Install guest image and stuff in /home/vrouter
if [ x$4 != x ];
 then
  mount_partition $4 img5 /mnt
  sudo mkdir -p /mnt/home/vrouter/Net/Core/boot
  sudo cp $OUT_DIR/core.gz /mnt/home/vrouter/Net/Core/boot
  sudo cp $OUT_DIR/bzImage /mnt/home/vrouter/Net/Core/boot/vmlinuz
  sudo cp $GUEST_IMG /mnt/home/vrouter/Net
  sync
  sudo umount /mnt
  sudo /sbin/losetup -d /dev/loop0
 fi

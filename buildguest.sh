set -e

TARGET_PATH=/home/vrouter
OUT_DIR=$PWD/Out/Guest
TMP_DIR=/tmp/BuildGuest
if [ x$IFACES = x ]
 then
  IFACES="eth0-192.168.1.3 eth0:0-192.168.2.3"
 fi

. $(dirname $0)/utils.sh
CPUS=$(get_j)
. $(dirname $0)/opts_parse.sh

net_config() {
  mount_partition $1 img$2 /mnt
  sudo mkdir -p /mnt/opt
  rm -f /tmp/bootlocal.sh
  for I in $3
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
}

guest_install() {
  mount_partition $1 img$2 /mnt
  sudo mkdir -p /mnt/home/vrouter/Net/Core/boot
  sudo cp -a $OUT_DIR/core.gz /mnt/home/vrouter/Net/Core/boot
  sudo cp -a $OUT_DIR/bzImage /mnt/home/vrouter/Net/Core/boot/vmlinuz
  sudo cp -a $3 /mnt/home/vrouter/Net
  umount_partition /mnt
}

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
  net_config $3 1 "$IFACES"
 fi

#$4: Host image -> Install guest image and stuff in /home/vrouter
if [ x$4 != x ];
 then
  guest_install $4 5 $3
 fi

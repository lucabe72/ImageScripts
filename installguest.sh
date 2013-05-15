set -e

. $(dirname $0)/utils.sh
CPUS=$(get_j)
. $(dirname $0)/opts_parse.sh

#$4: Host image -> Install guest image and stuff in /home/vrouter
mount_partition $3 img5 /mnt
sudo mkdir -p /mnt/home/vrouter/Net/Core/boot
sudo cp -a $2/core.gz /mnt/home/vrouter/Net/Core/boot
sudo cp -a $2/bzImage /mnt/home/vrouter/Net/Core/boot/vmlinuz
sudo cp -a $1 /mnt/home/vrouter/Net
umount_partition /mnt

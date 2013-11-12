BINDIR=`dirname $0`

# testimage.sh is for testing an image file directly in KVM,
# without writing the image to a USB drive and booting a physical
# machine with it.
# testimage.sh requires support for nested KVM instances.

# check nested kvm is enabled (should give Y)
#cat /sys/module/kvm_intel/parameters/nested

TAP=tap1
IMAGE=test.img

# tap setup
sudo ip tuntap add dev $TAP mode tap user $USER # not sure user is needed
sudo ip link set dev $TAP up
sudo ip link set dev $TAP promisc on # not sure this is needed

# tap IP setup
#sh $BINDIR/ethset.sh $TAP

# start the VM (memory can be less, but we configure L2 VMs with 512M)
sudo modprobe kvm
sudo qemu-system-x86_64 -m 2048 -smp 3 -hda $IMAGE -enable-kvm -net tap,ifname=$TAP,script=no,downscript=no -net nic,model=e1000 &

# functional test
echo "run \"sh $BINDIR/test-cont.sh 1000 $TAP\""

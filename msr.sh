GUEST_ARCH=x86
GUEST_CONFIG=config-3.0.36-guest-32

while getopts 4 opt
 do
  case "$opt" in
    4)		GUEST_ARCH=x86_64; GUEST_CONFIG=config-3.0.36-guest-64;;
    [?])	print >&2 "Usage: $0 [-4]"
		exit 1;;
  esac
 done

sh monolithic.sh -4
sh create_image.sh opt2.img 48
export ARCH=$GUEST_ARCH
sh buildclick.sh $(pwd)/core.gz $(pwd)/opt2.img $(pwd)/Configs/$GUEST_CONFIG test.img

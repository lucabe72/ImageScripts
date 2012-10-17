set -e

sh create_image.sh test.img 512 32
sh create_image.sh opt1.img 48
sh buildguest.sh $(pwd)/core.gz $(pwd)/Configs/config-3.4-guest-32 opt1.img test.img
sh grubit.sh test.img
sh buildhostlin.sh $(pwd)/core.gz $(pwd)/Configs/config-3.4-host test.img
sh buildkvm.sh test.img

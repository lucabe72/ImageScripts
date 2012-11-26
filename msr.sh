sh monolithic.sh -4
sh create_image.sh opt2.img 48
sh buildclick.sh $(pwd)/core.gz $(pwd)/opt2.img $(pwd)/Configs/config-3.0.36-guest-64 test.img

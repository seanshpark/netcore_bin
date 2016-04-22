#!/bin/sh
cd ~/git/coreclr
#time ROOTFS_DIR=~/arm-rootfs-coreclr/ ./build.sh clean arm cross verbose skipmscorlib
time ROOTFS_DIR=~/arm-rootfs-coreclr/ ./build.sh clean arm cross verbose
cd ~/git/corefx
time ROOTFS_DIR=~/arm-rootfs-corefx/ ./build.sh clean arm cross verbose native skiptests
time ./build.sh clean verbose skiptests
#cd ~/git/coreclr
#time ROOTFS_DIR=~/arm-softfp-rootfs-coreclr/ ./build.sh clean arm-softfp cross verbose skipmscorlib
#cd ~/git/coreclr
#time ./build.sh verbose
#cd ~/git/cli
#time ./build.sh
#cd ~/git/roslyn
#time make

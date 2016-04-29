#!/bin/sh
cd ~/git/coreclr
ROOTFS_DIR=~/arm-rootfs-coreclr/ time ./build.sh clean arm cross verbose
cd ~/git/corefx
ROOTFS_DIR=~/arm-rootfs-corefx/ time ./build.sh clean arm cross verbose native skiptests
time ./build.sh clean verbose skiptests
#cd ~/git/coreclr
#ROOTFS_DIR=~/arm-softfp-rootfs-coreclr/ time ./build.sh clean arm-softfp cross verbose

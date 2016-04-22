#!/bin/sh
cd ~/git/coreclr
time ./build.sh verbose
time ROOTFS_DIR=~/arm-rootfs-coreclr/ ./build.sh clean arm cross verbose skipmscorlib
time ROOTFS_DIR=~/arm-softfp-rootfs-coreclr/ ./build.sh clean arm-softfp cross verbose skipmscorlib
cd ~/git/corefx
time ./build.sh verbose skiptests
time ROOTFS_DIR=~/arm-rootfs-corefx/ ./build.sh clean arm cross verbose native skiptests
cd ~/git/cli
time ./build.sh
cd ~/git/roslyn
time make

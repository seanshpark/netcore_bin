#!/bin/sh
cd ~/git/coreclr
ROOTFS_DIR=~/arm-rootfs-coreclr/ ./cross/build-rootfs.sh arm
ROOTFS_DIR=~/arm-softfp-rootfs-coreclr/ ./cross/build-rootfs.sh arm-softfp
cd ~/git/corefx
ROOTFS_DIR=~/arm-rootfs-corefx/ ./cross/build-rootfs.sh arm

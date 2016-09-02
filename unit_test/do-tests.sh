#!/bin/bash

export UNW_ARM_UNWIND_METHOD=6

function usage
{
    echo ''
    echo "Usage: $(basename $0) [Debug|Release]"
    echo ''
}

while [ -n "$1" ]
do
    case $1 in
        -?|-h|--help)
            usage
            exit
            ;;
        Debug|Release)
            CONFIGURATION=$1
            ;;
        *)
            EXTRA_OPTIONS="$EXTRA_OPTIONS $1"
            ;;
    esac
    shift
done

if [ -z "$CONFIGURATION" ]
then
    CONFIGURATION=Release
fi

BASE_PATH=$(pwd)
TEST_ROOT=/home/sjlee/Windows_NT.x86.$CONFIGURATION
OVERLAY_DIR=$TEST_ROOT/Tests/coreoverlay

set -x
./runtest.sh \
    --testRootDir="$TEST_ROOT" \
    --coreOverlayDir="$OVERLAY_DIR" \
    --show-time \
    $EXTRA_OPTIONS \
    | tee $BASE_PATH/Linux.arm.${CONFIGURATION}-Windows_NT.x86.${CONFIGURATION}.log
set +x

#   --no-lf-conversion \
#   --verbose \

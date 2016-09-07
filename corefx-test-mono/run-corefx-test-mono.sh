#!/bin/bash

export UNW_ARM_UNWIND_METHOD=6

function usage
{
    echo ''
    echo "Usage: [CORECLR_BINS=./coreclr/bin/Product/Linux.arm.Release] $(basename $0) {Debug|Release}"
    echo ''
}

if [ $# -eq 0 ]; then
    usage
    exit
fi

#
# parse command-line options
#
while [ -n "$1" ]
do
    case $1 in
        -?|-h|--help)
            usage
            exit
            ;;
        Debug|Release)
            TEST_CONFIGURATION=$1
            ;;
		*)
			EXTRA_OPTIONS="$EXTRA_OPTIONS $1"
			;;
    esac
    shift
done

BASE_PATH=$(pwd)

./run-test-mono.sh --sequential --configurationGroup ${TEST_CONFIGURATION} --coreclr-bins $BASE_PATH/coreclr/bin/Product/Linux.arm.Release --mscorlib-bins $BASE_PATH/coreclr/bin/Product/Linux.arm.Release --corefx-tests $BASE_PATH/corefx/bin/tests --corefx-native-bins $BASE_PATH/corefx/bin/Linux.arm.Release/Native --corefx-packages $BASE_PATH/corefx/packages $EXTRA_OPTIONS | tee $BASE_PATH/corefx-Linux.arm.Release-test.log

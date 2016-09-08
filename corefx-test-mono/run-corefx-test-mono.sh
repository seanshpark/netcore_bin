#!/bin/bash

export UNW_ARM_UNWIND_METHOD=6

function usage
{
    echo ''
    echo "Usage: [CORECLR_BINS=./coreclr/bin/Product/Linux.${ARCH}.Release] $(basename $0) {Debug|Release}"
    echo ''
}

function check_cpu_architecture 
{
    local CPUName=$(uname -p)
    local __arch=

    # Some Linux platforms report unknown for platform, but the arch for machine.
    if [ "$CPUName" == "unknown" ]; then
        CPUName=$(uname -m)
    fi

    case $CPUName in
        i686)
            __arch=x86
            ;;
        x86_64)
            __arch=x64
            ;;
        armv7l)
            __arch=arm
            ;;
        aarch64)
            __arch=arm64
            ;;
        *)
            echo "Unknown CPU $CPUName detected, configuring as if for x64"
            __arch=x64
            ;;
    esac

    echo "$__arch"
}

ARCH=$(check_cpu_architecture)

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

./run-test-mono.sh --sequential --configurationGroup ${TEST_CONFIGURATION} --coreclr-bins $BASE_PATH/coreclr/bin/Product/Linux.${ARCH}.Release --mscorlib-bins $BASE_PATH/coreclr/bin/Product/Linux.${ARCH}.Release --corefx-tests $BASE_PATH/corefx/bin/tests --corefx-native-bins $BASE_PATH/corefx/bin/Linux.${ARCH}.Release/Native --corefx-packages $BASE_PATH/corefx/packages $EXTRA_OPTIONS | tee $BASE_PATH/corefx-Linux.${ARCH}.Release-test.log

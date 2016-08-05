#!/bin/bash
#
# Written by Sung-Jae Lee (sjlee@mail.com)
#

function usage
{
    echo ''
    echo "Usage: [BASE_PATH=<git_base>] $(basename $0) [option]"
    echo ''
    echo '    [option]'
    echo '        -? | -h | --help : Print this instruction.'
    echo '     --copy-overlay-only : Don'"'"'t copy full CoreCLR test package. Instead, copy coreoverlay directory only.'
    echo ''
    exit
}

# set $BASE_PATH
if [ -z "$BASE_PATH" ]; then
    BASE_PATH=$(pwd)
fi

# initialize variable
TARGET_DEVICE=pi2home
CORECLR_TEST_SET=Windows_NT.x86.Release
OVERLAY=$CORECLR_TEST_SET/Tests/coreoverlay
COREFX_TEST_SET=corefx-Linux.arm.Release-test
DATETIME=$(date +%Y%m%d-%T)
COPY_OVERLAY_ONLY=
EXTRA_OPTIONS=
TOTAL_RESULT=
TOTAL_EXIT_CODE=0

# define functions
function check_result
{
    local RESULT=$1
    local EXIT_CODE=$2

    TOTAL_RESULT="${TOTAL_RESULT}${RESULT}"
    echo "[BUILD RESULT: $RESULT]"

    if [ "$RESULT" -ne "0" ]
    then
        let "$TOTAL_EXIT_CODE+=$EXIT_CODE"
        exit $EXIT_CODE
    fi
}

# check commandline options
while [ -n "$1" ]
do
    case $1 in
        -?|-h|--help)
            usage
            ;;
        --copy-overlay-only)
            COPY_OVERLAY_ONLY=1
            ;;
        *)
            EXTRA_OPTIONS="${EXTRA_OPTIONS} $1"
            ;;
    esac
    shift
done

# build coreclr
echo '[CLEAN & BUILD CORECLR]'
cd $BASE_PATH/coreclr
./clean.sh
ROOTFS_DIR=$HOME/arm-rootfs-coreclr/ time ./build.sh arm cross release verbose clang3.8 |& tee $BASE_PATH/coreclr-build-${DATETIME}.log
check_result $? 1

# build corefx
cd $BASE_PATH/corefx
./clean.sh
echo '[CLEAN & BUILD COREFX-NATIVE]'
ROOTFS_DIR=$HOME/arm-rootfs-corefx/ time ./build-native.sh -release -buildArch=arm -- cross verbose /p:TestWithoutNativeImages=true |& tee $BASE_PATH/corefx-native-build-${DATETIME}.log
check_result $? 2

echo '[CLEAN & BUILD COREFX-MANAGED]'
ROOTFS_DIR=$HOME/arm-rootfs-corefx/ time ./build-managed.sh -release -SkipTests -- /p:TestWithoutNativeImages=true |& tee $BASE_PATH/corefx-managed-build-${DATETIME}.log
check_result $? 4

if [ "$TOTAL_EXIT_CODE" -ne "0" ]
then
    echo "[SCRIPT STOPPED WITH $TOTAL_EXIT_CODE ($TOTAL_RESULT)]"
    exit $TOTAL_EXIT_CODE
fi

# build test running set
cd $BASE_PATH
echo '[BUILD CORECLR TEST PACKAGE]'
dotnet-runtest.sh Linux.arm.Release --build-overlay-only
echo '[BUILD COREFX TEST PACKAGE]'
build-corefx-test.sh Linux.arm.Release

# copy test running set to target
echo "[COPY CORECLR TEST PACKAGE TO TARGET DEVICE]"
if [ "$COPY_OVERLAY_ONLY" == "1" ]
then
    ssh $TARGET_DEVICE "rm -rf $OVERLAY"
    scp -r coreclr/bin/tests/$OVERLAY ${TARGET_DEVICE}:$CORECLR_TEST_SET/Tests
else
    ssh $TARGET_DEVICE "rm -rf $CORECLR_TEST_SET"
    scp -r coreclr/bin/tests/$CORECLR_TEST_SET ${TARGET_DEVICE}:
fi
echo "[COPY COREFX TEST PACKAGE TO TARGET DEVICE]"
ssh $TARGET_DEVICE "rm -rf $COREFX_TEST_SET"
scp -r $COREFX_TEST_SET ${TARGET_DEVICE}:

# run test
echo "[RUN CORECLR UNIT_TEST ON THE DEVICE]"
ssh $TARGET_DEVICE "cd ~/unit_test;screen -S coreclr-${DATETIME} -d -m time ./do-tests.sh"
echo "[RUN COREFX UNIT_TEST ON THE DEVICE]"
ssh $TARGET_DEVICE "export UNW_ARM_UNWIND_METHOD=6;cd ~/$COREFX_TEST_SET;screen -S corefx-${DATETIME} -d -m time ./run-corefx-test.sh Release"

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
    echo '                   clean : Do clean build.'
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
COMMAND_LINE="$(basename $0) $*"
TARGET_DEVICE=pi2home
CORECLR_TEST_SET=Windows_NT.x86.Release
OVERLAY=$CORECLR_TEST_SET/Tests/coreoverlay
COREFX_TEST_SET=corefx-Linux.arm.Release-test
DATETIME=$(date +%Y%m%d-%T)
CLEAN_BUILD=0
COPY_OVERLAY_ONLY=
EXTRA_OPTIONS=
TOTAL_RESULT=""
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
        let "TOTAL_EXIT_CODE+=$EXIT_CODE"
        echo "[SCRIPT STOPPED WITH $TOTAL_EXIT_CODE ($TOTAL_RESULT)]"
        exit $TOTAL_EXIT_CODE
    fi
}

function do_clean
{
    if [ "$CLEAN_BUILD" == "1" ]
    then
        echo "[CLEAN $1]"
        ./clean.sh
    fi
}

# check commandline options
while [ -n "$1" ]
do
    case $1 in
        -?|-h|--help)
            usage
            ;;
        clean)
            CLEAN_BUILD=1
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

echo "$COMMAND_LINE"
echo ''

# build coreclr
cd $BASE_PATH/coreclr
do_clean "CORECLR"
echo '[BUILD CORECLR]'
echo "ROOTFS_DIR=$HOME/arm-rootfs-coreclr/ time ./build.sh arm cross release verbose clang3.8 |& tee $BASE_PATH/coreclr-build-${DATETIME}.log" | tee $BASE_PATH/coreclr-build-${DATETIME}.log
ROOTFS_DIR=$HOME/arm-rootfs-coreclr/ time ./build.sh arm cross release verbose clang3.8 |& tee -a $BASE_PATH/coreclr-build-${DATETIME}.log
check_result $? 1

# build corefx
cd $BASE_PATH/corefx
do_clean "COREFX"
echo '[BUILD COREFX-NATIVE]'
echo "ROOTFS_DIR=$HOME/arm-rootfs-corefx/ time ./build-native.sh -release -buildArch=arm -- cross verbose /p:TestWithoutNativeImages=true |& tee $BASE_PATH/corefx-native-build-${DATETIME}.log" | tee $BASE_PATH/corefx-native-build-${DATETIME}.log
ROOTFS_DIR=$HOME/arm-rootfs-corefx/ time ./build-native.sh -release -buildArch=arm -- cross verbose /p:TestWithoutNativeImages=true |& tee -a $BASE_PATH/corefx-native-build-${DATETIME}.log
check_result $? 2

echo '[BUILD COREFX-MANAGED]'
echo "ROOTFS_DIR=$HOME/arm-rootfs-corefx/ time ./build-managed.sh -release -SkipTests -- /p:TestWithoutNativeImages=true |& tee $BASE_PATH/corefx-managed-build-${DATETIME}.log" | tee $BASE_PATH/corefx-managed-build-${DATETIME}.log
ROOTFS_DIR=$HOME/arm-rootfs-corefx/ time ./build-managed.sh -release -SkipTests -- /p:TestWithoutNativeImages=true |& tee -a $BASE_PATH/corefx-managed-build-${DATETIME}.log
check_result $? 4

if [ "$TOTAL_EXIT_CODE" -ne "0" ]
then
    echo "[SCRIPT STOPPED WITH $TOTAL_EXIT_CODE ($TOTAL_RESULT)]"
    exit $TOTAL_EXIT_CODE
fi

# build test running set
cd $BASE_PATH
if [ -e "$BASE_PATH/coreclr/bin/tests/$OVERLAY" ]
then
    rm -rf $BASE_PATH/coreclr/bin/tests/$OVERLAY
fi
echo '[BUILD CORECLR TEST PACKAGE]'
dotnet-runtest.sh Linux.arm.Release --build-overlay-only

if [ -e "$BASE_PATH/$COREFX_TEST_SET" ]
then
    rm -rf $BASE_PATH/$COREFX_TEST_SET
fi
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

# notify
if [ -n "$NOTIFY" ]; then
    echo "$NOTIFY \"[$(hostname -s)] $COMMAND_LINE $TOTAL_RESULT $(date)\""
    $NOTIFY "[$(hostname -s)] $COMMAND_LINE $TOTAL_RESULT $(date)"
fi

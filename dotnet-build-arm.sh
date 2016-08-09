#!/bin/bash
#
# Written by Sung-Jae Lee (sjlee@mail.com)
#

function usage
{
    echo ''
    echo "Usage: [BASE_PATH=<git base>] [TARGET_DEVICE=<target hostname>] $(basename $0) [option]"
    echo ''
    echo '    [option]'
    echo '        -? | -h | --help : Print this instruction.'
    echo '                   clean : Do clean build.'
    echo '                 verbose : Verbose output.'
    echo '                   debug : Build Debug configuration.'
    echo '                 release : Build Release configuration. <default>'
    echo '                     all : Build all. <default>'
    echo '                 coreclr : Build CoreCLR.'
    echo '                  corefx : Build CoreFX.'
    echo '           corefx-native : Build CoreFX native only.'
    echo '          corefx-managed : Build CoreFX managed only.'
    echo ''
    echo '                --softfp : Target arm-softfp'
    echo '            --skip-build : Skip build.'
    echo '            --build-test : Build unit test package.'
    echo '              --run-test : Build unit test package and running on target device.'
    echo '     --copy-overlay-only : Don'"'"'t copy full CoreCLR test package. Instead, copy coreoverlay directory only.'
    echo '      --enable-jit-debug : Enable JIT code debugging with lldb + libsos.dll.'
    echo '             --outerloop : Build corefx outloop test.'
    echo ''
    exit
}

# set $BASE_PATH
if [ -z "$BASE_PATH" ]; then
    BASE_PATH=$(pwd)
fi

# set $TARGET_DEVICE
if [ -z "$TARGET_DEVICE" ]; then
    TARGET_DEVICE=pi2
fi

# initialize configuration variable
COMMAND_LINE="$(basename $0) $*"
CONFIGURATION=release
CLEAN_BUILD=0
VERBOSE=
SKIP_BUILD=0
COPY_OVERLAY_ONLY=
EXTRA_OPTIONS=
TOTAL_RESULT=
TOTAL_EXIT_CODE=0
BUILD_TEST=0
RUN_TEST=0
TIME=
ENABLE_JIT_DEBUG=
OUTERLOOP=
BUILD_CORECLR=0
BUILD_COREFX_NATIVE=0
BUILD_COREFX_MANAGED=0
ARCHITECTURE=arm

function message
{
    echo ''
    echo $1
    echo ''
}

# define functions
function check_result
{
    local RESULT=$1
    local EXIT_CODE=$2

    TOTAL_RESULT="${TOTAL_RESULT}${RESULT}"
    message "[BUILD RESULT: $RESULT]"

    if [ "$RESULT" -ne "0" ]
    then
        let "TOTAL_EXIT_CODE+=$EXIT_CODE"
        message "[SCRIPT STOPPED WITH $TOTAL_EXIT_CODE ($TOTAL_RESULT)]"
        exit $TOTAL_EXIT_CODE
    fi
}

function do_clean
{
    if [ "$CLEAN_BUILD" == "1" ]
    then
        message "[CLEAN $1]"
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
        verbose)
            VERBOSE=verbose
            ;;
        release|debug)
            CONFIGURATION=$1
            ;;
        coreclr)
            BUILD_CORECLR=1
            ;;
        corefx)
            BUILD_COREFX_NATIVE=1
            BUILD_COREFX_MANAGED=1
            ;;
        corefx-native)
            BUILD_COREFX_NATIVE=1
            ;;
        corefx-managed)
            BUILD_COREFX_MANAGED=1
            ;;
        --skip-build)
            SKIP_BUILD=1
            ;;
        --build-test)
            BUILD_TEST=1
            ;;
        --run-test)
            BUILD_TEST=1
            RUN_TEST=1
            ;;
        --copy-overlay-only)
            COPY_OVERLAY_ONLY=1
            ;;
        --enable-jit-debug)
            ENABLE_JIT_DEBUG="cmakeargs -DFEATURE_GDBJIT=TRUE"
            ;;
        --outerloop)
            OUTERLOOP="-Outerloop=true"
            ;;
        --softfp)
            ARCHITECTURE=arm-softfp
            ;;
        *)
            EXTRA_OPTIONS="${EXTRA_OPTIONS} $1"
            ;;
    esac
    shift
done

if [ "$BUILD_CORECLR" == "0" ] && [ "$BUILD_COREFX_NATIVE" == "0" ] && [ "$BUILD_COREFX_MANAGED" == "0" ]
then
    BUILD_CORECLR=1
    BUILD_COREFX_NATIVE=1
    BUILD_COREFX_MANAGED=1
fi

# initialize variable
CONFIGURATION=$(echo $CONFIGURATION | tr '[:upper:]' '[:lower:]')
CAP_CONFIGURATION=$(echo $CONFIGURATION | tr 'rd' 'RD')
CORECLR_TEST_SET=Windows_NT.x86.$CAP_CONFIGURATION
OVERLAY=$CORECLR_TEST_SET/Tests/coreoverlay
COREFX_TEST_SET=corefx-Linux.${ARCHITECTURE}.$CAP_CONFIGURATION-test
DATETIME=$(date +%Y%m%d-%T)

echo "$COMMAND_LINE"
echo ''
echo "CONFIGURATION=$(echo $CONFIGURATION | tr '[:upper:]' '[:lower:]')"
echo "CORECLR_TEST_SET=Windows_NT.x86.$CAP_CONFIGURATION"
echo "OVERLAY=$CORECLR_TEST_SET/Tests/coreoverlay"
echo "COREFX_TEST_SET=corefx-Linux.${ARCHITECTURE}.$CAP_CONFIGURATION-test"
echo "TARGET_DEVICE=$TARGET_DEVICE"
echo "DATETIME=$(date +%Y%m%d-%T)"
echo ''

# build coreclr
if [ "$SKIP_BUILD" != "1" ]  && [ "$BUILD_CORECLR" == "1" ]
then
    cd $BASE_PATH/coreclr
    do_clean "CORECLR"

    message "[BUILD CORECLR]"
    echo "ROOTFS_DIR=$HOME/${ARCHITECTURE}-rootfs-coreclr/ $TIME ./build.sh ${ARCHITECTURE} cross $CONFIGURATION $VERBOSE $ENABLE_JIT_DEBUG clang3.8 |& tee $BASE_PATH/coreclr-build-${DATETIME}.log" | tee $BASE_PATH/coreclr-build-${DATETIME}.log
    ROOTFS_DIR=$HOME/${ARCHITECTURE}-rootfs-coreclr/ $TIME ./build.sh ${ARCHITECTURE} cross $CONFIGURATION $VERBOSE $ENABLE_JIT_DEBUG clang3.8 |& tee -a $BASE_PATH/coreclr-build-${DATETIME}.log
    RESULT=$?
    check_result $RESULT 1
fi

# build corefx
if [ "$SKIP_BUILD" != "1" ]
then
    if [ "$BUILD_COREFX_NATIVE" == "1" ] || [ "$BUILD_COREFX_MANAGED" == "1" ]
    then
        cd $BASE_PATH/corefx
        do_clean "COREFX"
    fi

    if [ "$BUILD_COREFX_NATIVE" == "1" ]
    then
        message "[BUILD COREFX-NATIVE]"
        echo "ROOTFS_DIR=$HOME/${ARCHITECTURE}-rootfs-corefx/ $TIME ./build-native.sh -$CONFIGURATION -buildArch=${ARCHITECTURE} $OUTERLOOP -- cross $VERBOSE /p:TestWithoutNativeImages=true |& tee $BASE_PATH/corefx-native-build-${DATETIME}.log" | tee $BASE_PATH/corefx-native-build-${DATETIME}.log
        ROOTFS_DIR=$HOME/${ARCHITECTURE}-rootfs-corefx/ $TIME ./build-native.sh -$CONFIGURATION -buildArch=${ARCHITECTURE} -- cross $VERBOSE /p:TestWithoutNativeImages=true |& tee -a $BASE_PATH/corefx-native-build-${DATETIME}.log
        RESULT=$?
        check_result $RESULT 2
    fi

    if [ "$BUILD_COREFX_MANAGED" == "1" ]
    then
        message "[BUILD COREFX-MANAGED]"
        echo "ROOTFS_DIR=$HOME/${ARCHITECTURE}-rootfs-corefx/ $TIME ./build-managed.sh -$CONFIGURATION -SkipTests $OUTERLOOP -- /p:TestWithoutNativeImages=true |& tee $BASE_PATH/corefx-managed-build-${DATETIME}.log" | tee $BASE_PATH/corefx-managed-build-${DATETIME}.log
        ROOTFS_DIR=$HOME/${ARCHITECTURE}-rootfs-corefx/ $TIME ./build-managed.sh -$CONFIGURATION -SkipTests -- /p:TestWithoutNativeImages=true |& tee -a $BASE_PATH/corefx-managed-build-${DATETIME}.log
        RESULT=$?
        check_result $RESULT 4
    fi
fi

if [ "$TOTAL_EXIT_CODE" -ne "0" ]
then
    message "[SCRIPT STOPPED WITH $TOTAL_EXIT_CODE ($TOTAL_RESULT)]"
    exit $TOTAL_EXIT_CODE
fi

if [ "$BUILD_TEST" == "1" ]
then
    # build test running set
    cd $BASE_PATH
    if [ -e "$BASE_PATH/coreclr/bin/tests/$OVERLAY" ]
    then
        rm -rf $BASE_PATH/coreclr/bin/tests/$OVERLAY
    fi
    message "[BUILD CORECLR TEST PACKAGE]"
    dotnet-runtest.sh Linux.${ARCHITECTURE}.$CAP_CONFIGURATION --build-overlay-only

    if [ -e "$BASE_PATH/$COREFX_TEST_SET" ]
    then
        rm -rf $BASE_PATH/$COREFX_TEST_SET
    fi
    message "[BUILD COREFX TEST PACKAGE]"
    build-corefx-test.sh Linux.${ARCHITECTURE}.$CAP_CONFIGURATION
fi

if [ "$RUN_TEST" == "1" ]
then
    # copy test running set to target
    message "[COPY CORECLR TEST PACKAGE TO TARGET DEVICE]"
    if [ "$COPY_OVERLAY_ONLY" == "1" ]
    then
        ssh $TARGET_DEVICE "rm -rf $OVERLAY"
        scp -r coreclr/bin/tests/$OVERLAY ${TARGET_DEVICE}:$CORECLR_TEST_SET/Tests
    else
        ssh $TARGET_DEVICE "rm -rf $CORECLR_TEST_SET"
        scp -r coreclr/bin/tests/$CORECLR_TEST_SET ${TARGET_DEVICE}:
    fi
    message "[COPY COREFX TEST PACKAGE TO TARGET DEVICE]"
    ssh $TARGET_DEVICE "rm -rf $COREFX_TEST_SET"
    scp -r $COREFX_TEST_SET ${TARGET_DEVICE}:

    # run test
    message "[RUN CORECLR UNIT_TEST ON THE DEVICE]"
    echo "ssh $TARGET_DEVICE cd ~/unit_test;screen -S coreclr-${DATETIME} -d -m time ./do-tests.sh $CAP_CONFIGURATION"
    ssh $TARGET_DEVICE "cd ~/unit_test;screen -S coreclr-${DATETIME} -d -m time ./do-tests.sh $CAP_CONFIGURATION"
    message "[RUN COREFX UNIT_TEST ON THE DEVICE]"
    echo "ssh $TARGET_DEVICE export UNW_ARM_UNWIND_METHOD=6;cd ~/$COREFX_TEST_SET;screen -S corefx-${DATETIME} -d -m time ./run-corefx-test.sh $CAP_CONFIGURATION"
    ssh $TARGET_DEVICE "export UNW_ARM_UNWIND_METHOD=6;cd ~/$COREFX_TEST_SET;screen -S corefx-${DATETIME} -d -m time ./run-corefx-test.sh $CAP_CONFIGURATION"
fi

# notify
if [ -n "$NOTIFY" ]; then
    message "$NOTIFY \"[$(hostname -s)] $COMMAND_LINE [$TOTAL_RESULT] $(date '+%D %T')\""
    $NOTIFY "[$(hostname -s)] $COMMAND_LINE [$TOTAL_RESULT] $(date '+%D %T')"
fi

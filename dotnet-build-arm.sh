#!/bin/bash
#
# Written by Sung-Jae Lee (sjlee@mail.com)
#

function usage
{
    echo ''
    echo "Usage: [ENV=<value>] $(basename $0) [option]"
    echo ''
    echo '    [ENV=<value>]'
    echo "       [BASE_PATH=<git base>]"
    echo "       [TARGET_DEVICE=<target hostname>]"
    echo "       [ROOTFS_DIR=<RootFS for CoreCLR and CoreFX>]"
    echo "       [ROOTFS_DIRCLR=<RootFS for CoreCLR>]"
    echo "       [ROOTFS_DIRFX=<RootFS for CoreFX>]"
    echo "       [LLVM_ARM_HOME=<LLVM ARM home for CoreCLR/sosplugin>]"
    echo ''
    echo '    [option]'
    echo '        -? | -h | --help : Print this instruction.'
    echo '                   clean : Do clean build.'
    echo '                 verbose : Verbose output.'
    echo '                   debug : Build Debug configuration.'
    echo '                 release : Build Release configuration.'
    echo '                     all : Build all.'
    echo '                 coreclr : Build CoreCLR.'
    echo '                  corefx : Build CoreFX.'
    echo '           corefx-native : Build CoreFX native only.'
    echo '          corefx-managed : Build CoreFX managed only.'
    echo ''
    echo '            --skip-build : Skip build.'
    echo '      --skip-build-tests : Skip build tests (PAL tests for CoreCLR, unit tests for CoreFX)'
    echo '                --softfp : Target arm-softfp'
    echo '      --enable-jit-debug : Enable JIT code debugging with lldb + libsos.dll.'
    echo ''
    echo '            --build-test : Build unit test package.'
    echo '             --copy-test : Copy test package to target device.'
    echo '              --run-test : Run unit test package and running on target device.'
    echo ''
    echo '    --build-coreclr-test : Build coreclr unit test package.'
    echo '     --build-corefx-test : Build corefx unit test package.'
    echo '     --copy-coreclr-test : Copy coreclr unit test package to target device.'
    echo '      --copy-corefx-test : Copy corefx unit test package to target device.'
    echo '      --run-coreclr-test : Run coreclr unit test package and running on target device.'
    echo '       --run-corefx-test : Run corefx unit test package and running on target device.'
    echo ''
    echo '     --copy-overlay-only : Don'"'"'t copy full CoreCLR test package. Instead, copy coreoverlay directory only.'
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

# set this path
__Bash_Source="${BASH_SOURCE[0]}"
while [ -h "$__Bash_Source" ]; do # resolve $SOURCE until the file is no longer a symlink
  __Bash_dir="$( cd -P "$( dirname "$__Bash_Source" )" && pwd )"
  __Bash_Source="$(readlink "$__Bash_Source")"
  [[ $__Bash_Source != /* ]] && __Bash_Source="$__Bash_dir/$__Bash_Source" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
__Bash_dir="$( cd -P "$( dirname "$__Bash_Source" )" && pwd )"


# initialize configuration variable
COMMAND_LINE="$(basename $0) $*"
CONFIGURATION=
CLEAN_BUILD=0
VERBOSE=
SKIP_BUILD=0
COPY_OVERLAY_ONLY=
EXTRA_OPTIONS=
TOTAL_RESULT=
TOTAL_EXIT_CODE=0
TIME=
ENABLE_JIT_DEBUG=
OUTERLOOP=
BUILD_CORECLR=0
BUILD_COREFX_NATIVE=0
BUILD_COREFX_MANAGED=0
SKIP_TESTS=
SKIP_BUILD_TESTS=
ARCHITECTURE=arm
BUILD_CORECLR_TEST=0
COPY_CORECLR_TEST=0
RUN_CORECLR_TEST=0
BUILD_COREFX_TEST=0
COPY_COREFX_TEST=0
RUN_COREFX_TEST=0

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

if [ $# == 0 ]
then
    usage
    exit
fi

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
        all)
            BUILD_CORECLR=1
            BUILD_COREFX_NATIVE=1
            BUILD_COREFX_MANAGED=1
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
        --skip-build-tests)
            SKIP_TESTS=skiptests
            SKIP_BUILD_TESTS="/p:BuildTests=false"
            ;;
        --skip-build)
            SKIP_BUILD=1
            ;;
        --build-test)
            BUILD_CORECLR_TEST=1
            BUILD_COREFX_TEST=1
            ;;
        --build-coreclr-test)
            BUILD_CORECLR_TEST=1
            ;;
        --build-corefx-test)
            BUILD_COREFX_TEST=1
            ;;
        --copy-test)
            COPY_CORECLR_TEST=1
            COPY_COREFX_TEST=1
            ;;
        --copy-coreclr-test)
            COPY_CORECLR_TEST=1
            ;;
        --copy-corefx-test)
            COPY_COREFX_TEST=1
            ;;
        --run-test)
            RUN_CORECLR_TEST=1
            RUN_COREFX_TEST=1
            ;;
        --run-coreclr-test)
            RUN_CORECLR_TEST=1
            ;;
        --run-corefx-test)
            RUN_COREFX_TEST=1
            ;;
        --copy-overlay-only)
            COPY_OVERLAY_ONLY=1
            ;;
        --enable-jit-debug)
            ENABLE_JIT_DEBUG="cmakeargs -DFEATURE_GDBJIT=TRUE"
            ;;
        --outerloop)
            OUTERLOOP="/p:Outerloop=true"
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

if [ -z "$CONFIGURATION" ]
then
    echo "ERROR: need build configuration."
    exit 1
fi

if [ "$BUILD_CORECLR" == "0" ] && [ "$BUILD_COREFX_NATIVE" == "0" ] && [ "$BUILD_COREFX_MANAGED" == "0" ]
then
    SKIP_BUILD=1
#    BUILD_CORECLR=1
#    BUILD_COREFX_NATIVE=1
#    BUILD_COREFX_MANAGED=1
fi

# initialize variable
CONFIGURATION=$(echo $CONFIGURATION | tr '[:upper:]' '[:lower:]')
CAP_CONFIGURATION=$(echo $CONFIGURATION | tr 'rd' 'RD')
CORECLR_TEST_SET=Windows_NT.x86.$CAP_CONFIGURATION
OVERLAY=$CORECLR_TEST_SET/Tests/coreoverlay
COREFX_TEST_SET=corefx-Linux.${ARCHITECTURE}.$CAP_CONFIGURATION-test
DATETIME=$(date +%Y%m%d-%T)

# root fs for cross building
__RootfsDirClr=$HOME/${ARCHITECTURE}-rootfs-coreclr
__RootfsDirFx=$HOME/${ARCHITECTURE}-rootfs-corefx

if [[ -n "$ROOTFS_DIR" ]]
then
    __RootfsDirClr=$ROOTFS_DIR
    __RootfsDirFx=$ROOTFS_DIR
fi
if [[ -n "$ROOTFS_DIRCLR" ]]
then
    __RootfsDirClr=$ROOTFS_DIRCLR
fi
if [[ -n "$ROOTFS_DIRFX" ]]
then
    __RootfsDirFx=$ROOTFS_DIRFX
fi

echo "$COMMAND_LINE"
echo ''
echo "CONFIGURATION=$(echo $CONFIGURATION | tr '[:upper:]' '[:lower:]')"
echo "CORECLR_TEST_SET=Windows_NT.x86.$CAP_CONFIGURATION"
echo "OVERLAY=$CORECLR_TEST_SET/Tests/coreoverlay"
echo "COREFX_TEST_SET=corefx-Linux.${ARCHITECTURE}.$CAP_CONFIGURATION-test"
echo "TARGET_DEVICE=$TARGET_DEVICE"
echo "ROOTFS_DIRCLR=$__RootfsDirClr"
echo "ROOTFS_DIRFX=$__RootfsDirFx"
echo "LLVM_ARM_HOME=$LLVM_ARM_HOME"
echo "DATETIME=$(date +%Y%m%d-%T)"
echo ''

# build coreclr
if [ "$SKIP_BUILD" != "1" ]  && [ "$BUILD_CORECLR" == "1" ]
then
    cd $BASE_PATH/coreclr
    do_clean "CORECLR"

    message "[BUILD CORECLR]"
    echo "LLVM_ARM_HOME=$LLVM_ARM_HOME ROOTFS_DIR=$__RootfsDirClr $TIME ./build.sh ${ARCHITECTURE} cross $CONFIGURATION $VERBOSE $ENABLE_JIT_DEBUG clang3.8 $SKIP_TESTS 2>&1 | tee $BASE_PATH/coreclr-build-${DATETIME}.log" | tee $BASE_PATH/coreclr-build-${DATETIME}.log
    LLVM_ARM_HOME=$LLVM_ARM_HOME ROOTFS_DIR=$__RootfsDirClr $TIME ./build.sh ${ARCHITECTURE} cross $CONFIGURATION $VERBOSE $ENABLE_JIT_DEBUG clang3.8 $SKIP_TESTS 2>&1 | tee -a $BASE_PATH/coreclr-build-${DATETIME}.log
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
        echo "ROOTFS_DIR=$__RootfsDirFx/ $TIME ./build-native.sh -$CONFIGURATION -buildArch=${ARCHITECTURE} -- /p:SkipTests=true $SKIP_BUILD_TESTS cross $VERBOSE $OUTERLOOP /p:TestWithoutNativeImages=true 2>&1 | tee $BASE_PATH/corefx-native-build-${DATETIME}.log" | tee $BASE_PATH/corefx-native-build-${DATETIME}.log
        ROOTFS_DIR=$__RootfsDirFx/ $TIME ./build-native.sh -$CONFIGURATION -buildArch=${ARCHITECTURE} -- /p:SkipTests=true $SKIP_BUILD_TESTS cross $VERBOSE $OUTERLOOP /p:TestWithoutNativeImages=true 2>&1 | tee -a $BASE_PATH/corefx-native-build-${DATETIME}.log
        RESULT=$?
        check_result $RESULT 2
    fi

    if [ "$BUILD_COREFX_MANAGED" == "1" ]
    then
        message "[BUILD COREFX-MANAGED]"
        echo "ROOTFS_DIR=$__RootfsDirFx/ $TIME ./build-managed.sh -$CONFIGURATION -- /p:SkipTests=true $SKIP_BUILD_TESTS $OUTERLOOP /p:TestWithoutNativeImages=true 2>&1 | tee $BASE_PATH/corefx-managed-build-${DATETIME}.log" | tee $BASE_PATH/corefx-managed-build-${DATETIME}.log
        ROOTFS_DIR=$__RootfsDirFx/ $TIME ./build-managed.sh -$CONFIGURATION -- /p:SkipTests=true $SKIP_BUILD_TESTS $OUTERLOOP /p:TestWithoutNativeImages=true 2>&1 | tee -a $BASE_PATH/corefx-managed-build-${DATETIME}.log
        RESULT=$?
        check_result $RESULT 4
    fi
fi

if [ "$TOTAL_EXIT_CODE" -ne "0" ]
then
    message "[SCRIPT STOPPED WITH $TOTAL_EXIT_CODE ($TOTAL_RESULT)]"
    exit $TOTAL_EXIT_CODE
fi

# build test running set
if [ "$BUILD_CORECLR_TEST" == "1" ]
then
    cd $BASE_PATH
    if [ -e "$BASE_PATH/coreclr/bin/tests/$OVERLAY" ]
    then
        rm -rf $BASE_PATH/coreclr/bin/tests/$OVERLAY
    fi
    message "[BUILD CORECLR TEST PACKAGE]"
    $__Bash_dir/dotnet-runtest.sh Linux.${ARCHITECTURE}.$CAP_CONFIGURATION --build-overlay-only
fi

if [ "$BUILD_COREFX_TEST" == "1" ]
then
    cd $BASE_PATH
    if [ -e "$BASE_PATH/$COREFX_TEST_SET" ]
    then
        rm -rf $BASE_PATH/$COREFX_TEST_SET
    fi
    message "[BUILD COREFX TEST PACKAGE]"
    $__Bash_dir/build-corefx-test.sh Linux.${ARCHITECTURE}.$CAP_CONFIGURATION
fi

# copy test running set to target
if [ "$COPY_CORECLR_TEST" == "1" ]
then
    message "[COPY CORECLR TEST PACKAGE TO TARGET DEVICE]"
    if [ "$COPY_OVERLAY_ONLY" == "1" ]
    then
        ssh $TARGET_DEVICE "rm -rf $OVERLAY"
        scp -r coreclr/bin/tests/$OVERLAY ${TARGET_DEVICE}:$CORECLR_TEST_SET/Tests
    else
        ssh $TARGET_DEVICE "rm -rf $CORECLR_TEST_SET"
        scp -r coreclr/bin/tests/$CORECLR_TEST_SET ${TARGET_DEVICE}:
    fi
fi

if [ "$COPY_COREFX_TEST" == "1" ]
then
    message "[COPY COREFX TEST PACKAGE TO TARGET DEVICE]"
    ssh $TARGET_DEVICE "rm -rf $COREFX_TEST_SET"
    scp -r $COREFX_TEST_SET ${TARGET_DEVICE}:
fi

# run test
if [ "$RUN_CORECLR_TEST" == "1" ]
then
    message "[RUN CORECLR UNIT_TEST ON THE DEVICE]"
    if [ "$COPY_OVERLAY_ONLY" == "1" ]
    then
        echo "ssh $TARGET_DEVICE cd ~/unit_test;screen -S coreclr-${DATETIME} -d -m time ./do-tests.sh $CAP_CONFIGURATION --no-lf-conversion"
        ssh $TARGET_DEVICE "cd ~/unit_test;screen -S coreclr-${DATETIME} -d -m time ./do-tests.sh $CAP_CONFIGURATION --no-lf-conversion"
    else
        echo "ssh $TARGET_DEVICE cd ~/unit_test;screen -S coreclr-${DATETIME} -d -m time ./do-tests.sh $CAP_CONFIGURATION"
        ssh $TARGET_DEVICE "cd ~/unit_test;screen -S coreclr-${DATETIME} -d -m time ./do-tests.sh $CAP_CONFIGURATION"
    fi
fi

if [ "$RUN_COREFX_TEST" == "1" ]
then
    message "[RUN COREFX UNIT_TEST ON THE DEVICE]"
    echo "ssh $TARGET_DEVICE export UNW_ARM_UNWIND_METHOD=6;cd ~/$COREFX_TEST_SET;screen -S corefx-${DATETIME} -d -m time ./run-corefx-test.sh $CAP_CONFIGURATION"
    ssh $TARGET_DEVICE "export UNW_ARM_UNWIND_METHOD=6;cd ~/$COREFX_TEST_SET;screen -S corefx-${DATETIME} -d -m time ./run-corefx-test.sh $CAP_CONFIGURATION"
fi

# notify
if [ -n "$NOTIFY" ]; then
    message "$NOTIFY \"[$(hostname -s)] $COMMAND_LINE [$TOTAL_RESULT] $(date '+%D %T')\""
    $NOTIFY "[$(hostname -s)] $COMMAND_LINE [$TOTAL_RESULT] $(date '+%D %T')"
fi

#
# | Example of setting $NOTIFY in `~/.profile` |
#
# export NOTIFY="twidge dmsend lemmaa"
#

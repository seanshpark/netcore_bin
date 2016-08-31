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
    echo '      --skip-build-tests : Skip build tests (PAL tests for CoreCLR, unit tests for CoreFX)'
    echo '    --skip-build-package : Skip build NuGet package'
    echo ''
    echo '            --skip-build : Skip build.'
    echo '      --enable-jit-debug : Enable JIT code debugging with lldb + libsos.dll.'
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

# initialize configuration variable
COMMAND_LINE="$(basename $0) $*"
CONFIGURATION=
CLEAN_BUILD=0
VERBOSE=
SKIP_BUILD=0
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
SKIP_NUGET=
SKIP_BUILD_PACKAGES=

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
            SKIP_BUILD_TESTS=/p:BuildTests=false
            ;;
        --skip-build-package)
            SKIP_NUGET=skipnuget
            SKIP_BUILD_PACKAGES=/p:BuildPackages=false
            ;;
        --skip-build)
            SKIP_BUILD=1
            ;;
        --enable-jit-debug)
            ENABLE_JIT_DEBUG="cmakeargs -DFEATURE_GDBJIT=TRUE"
            ;;
        --outerloop)
            OUTERLOOP="/p:Outerloop=true"
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
fi

# initialize variable
CONFIGURATION=$(echo $CONFIGURATION | tr '[:upper:]' '[:lower:]')
DATETIME=$(date +%Y%m%d-%T)

echo "$COMMAND_LINE"
echo ''
echo "CONFIGURATION=$(echo $CONFIGURATION | tr '[:upper:]' '[:lower:]')"
echo "DATETIME=$(date +%Y%m%d-%T)"
echo ''

# build coreclr
if [ "$SKIP_BUILD" != "1" ]  && [ "$BUILD_CORECLR" == "1" ]
then
    cd $BASE_PATH/coreclr
    do_clean "CORECLR"

    message "[BUILD CORECLR]"
    echo "$TIME ./build.sh $CONFIGURATION $SKIP_TESTS $SKIP_NUGET $VERBOSE $ENABLE_JIT_DEBUG clang3.8 2>&1 | tee $BASE_PATH/coreclr-build-${DATETIME}.log" | tee $BASE_PATH/coreclr-build-${DATETIME}.log
    $TIME ./build.sh $CONFIGURATION $SKIP_TESTS $SKIP_NUGET $VERBOSE $ENABLE_JIT_DEBUG clang3.8 2>&1 | tee -a $BASE_PATH/coreclr-build-${DATETIME}.log
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
        echo "$TIME ./build-native.sh -$CONFIGURATION -- $SKIP_BUILD_PACKAGES /p:SkipTests=true $VERBOSE $OUTERLOOP /p:TestWithoutNativeImages=true 2>&1 | tee $BASE_PATH/corefx-native-build-${DATETIME}.log" | tee $BASE_PATH/corefx-native-build-${DATETIME}.log
        $TIME ./build-native.sh -$CONFIGURATION -- $SKIP_BUILD_PACKAGES /p:SkipTests=true $VERBOSE $OUTERLOOP /p:TestWithoutNativeImages=true 2>&1 | tee -a $BASE_PATH/corefx-native-build-${DATETIME}.log
        RESULT=$?
        check_result $RESULT 2
    fi

    if [ "$BUILD_COREFX_MANAGED" == "1" ]
    then
        message "[BUILD COREFX-MANAGED]"
        echo "$TIME ./build-managed.sh -$CONFIGURATION -- $SKIP_BUILD_TESTS $SKIP_BUILD_PACKAGES /p:SkipTests=true $OUTERLOOP /p:TestWithoutNativeImages=true 2>&1 | tee $BASE_PATH/corefx-managed-build-${DATETIME}.log" | tee $BASE_PATH/corefx-managed-build-${DATETIME}.log
        $TIME ./build-managed.sh -$CONFIGURATION -- $SKIP_BUILD_TESTS $SKIP_BUILD_PACKAGES /p:SkipTests=true $OUTERLOOP /p:TestWithoutNativeImages=true 2>&1 | tee -a $BASE_PATH/corefx-managed-build-${DATETIME}.log
        RESULT=$?
        check_result $RESULT 4
    fi
fi

if [ "$TOTAL_EXIT_CODE" -ne "0" ]
then
    message "[SCRIPT STOPPED WITH $TOTAL_EXIT_CODE ($TOTAL_RESULT)]"
    exit $TOTAL_EXIT_CODE
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

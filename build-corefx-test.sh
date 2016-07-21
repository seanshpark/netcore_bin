#!/usr/bin/env bash
        
function usage
{
    echo ''
    echo "Usage: [BASE_PATH=<git_base>] [TEST_ROOT=./corefx-<target>-test] $(basename $0) <target> [option]"
    echo ''
    echo 'target : os.architecture.configuration'
    echo '                    os = Linux | OSX | Windows'
    echo '          architecture = x64 | x86 | arm64 | arm | arm-softfp'
    echo '         configuration = Debug | Release'
    echo ''
}

if [ $# -eq 0 ]; then
    usage
    exit
fi

TARGET=(${1//./ })

OS=${TARGET[0]}
ARCHITECTURE=${TARGET[1]}
BUILD=${TARGET[2]}

if [ -z "$BASE_PATH" ]; then
    BASE_PATH=$(pwd)
fi

LOG_FILE="$BASE_PATH/$(basename ${0}).log"

if [ -z "$TEST_ROOT" ]; then
    TEST_ROOT=./corefx-${OS}.${ARCHITECTURE}.${BUILD}-test
fi

#CORECLR_BIN=$TEST_ROOT/coreclr/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}
CORECLR_BIN=$TEST_ROOT/coreclr/bin/Product
TESTS=$TEST_ROOT/corefx/bin/tests
#COREFX_NATIVE=$TEST_ROOT/corefx/bin/${OS}.${ARCHITECTURE}.${BUILD}/Native
COREFX_NATIVE=$TEST_ROOT/corefx/bin/${OS}.${ARCHITECTURE}.${BUILD}
#PACKAGES=$TEST_ROOT/corefx/packages
PACKAGES=$TEST_ROOT/corefx

mkdir -p $CORECLR_BIN
mkdir -p $TESTS
mkdir -p $COREFX_NATIVE
mkdir -p $PACKAGES

cp -a $BASE_PATH/coreclr/bin/Product/${OS}.${ARCHITECTURE}.${BUILD} $CORECLR_BIN
cp -a $BASE_PATH/corefx/bin/tests/*.${BUILD} $TESTS
cp -a $BASE_PATH/corefx/bin/${OS}.${ARCHITECTURE}.${BUILD}/Native $COREFX_NATIVE
cp -a $BASE_PATH/corefx/packages $PACKAGES

cp -a $BASE_PATH/corefx/run-test.sh $TEST_ROOT

#./run-test.sh \
#--sequential \
#--coreclr-bins /home/sjlee/git/coreclr/bin/Product/Linux.arm.Debug \
#--mscorlib-bins /home/sjlee/git/coreclr/bin/Product/Linux.arm.Debug \
#--corefx-tests /home/sjlee/git/corefx/bin/tests \
#--corefx-native-bins /home/sjlee/git/corefx/bin/Linux.arm.Debug/Native \
#--corefx-packages /home/sjlee/git/corefx/packages \
#| tee $LOG_FILE

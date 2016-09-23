#!/usr/bin/env bash
        
function usage
{
    echo ''
    echo "Usage: [BASE_PATH=<git_base>] [TEST_ROOT=./corefx-<target>-test] $(basename $0) <target>"
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

if [ -z $OS ] || [ -z $ARCHITECTURE ] || [ -z $BUILD ]; then
    usage
    exit
fi

if [ -z "$BASE_PATH" ]; then
    BASE_PATH=$(pwd)
fi

LOG_FILE="$BASE_PATH/$(basename ${0}).log"

if [ -z "$TEST_ROOT" ]; then
    TEST_ROOT=./corefx-${OS}.${ARCHITECTURE}.${BUILD}-test
fi

mkdir -p "$TEST_ROOT"

CORECLR_BIN=$TEST_ROOT/coreclr/bin/Product
TESTS=$TEST_ROOT/corefx/bin/tests
COREFX_NATIVE=$TEST_ROOT/corefx/bin/${OS}.${ARCHITECTURE}.${BUILD}
PACKAGES=$TEST_ROOT/corefx
TEST_SCRIPT=$TEST_ROOT/run-corefx-test.sh

function generate_test_runner_script
{
    cat <<END > $TEST_SCRIPT
#!/bin/bash

export UNW_ARM_UNWIND_METHOD=6

function usage
{
    echo ''
    echo "Usage: [CORECLR_BINS=./coreclr/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}] \$(basename \$0) {Debug|Release}"
    echo ''
}

if [ \$# -eq 0 ]; then
    usage
    exit
fi

#
# parse command-line options
#
while [ -n "\$1" ]
do
    case \$1 in
        -?|-h|--help)
            usage
            exit
            ;;
        Debug|Release)
            TEST_CONFIGURATION=\$1
            ;;
		*)
			EXTRA_OPTIONS="\$EXTRA_OPTIONS \$1"
			;;
    esac
    shift
done

BASE_PATH=\$(pwd)

./run-test.sh \
--sequential \
--configurationGroup \${TEST_CONFIGURATION} \
--coreclr-bins \$BASE_PATH/coreclr/bin/Product/${OS}.${ARCHITECTURE}.${BUILD} \
--mscorlib-bins \$BASE_PATH/coreclr/bin/Product/${OS}.${ARCHITECTURE}.${BUILD} \
--corefx-tests \$BASE_PATH/corefx/bin/tests \
--corefx-native-bins \$BASE_PATH/corefx/bin/${OS}.${ARCHITECTURE}.${BUILD}/Native \
--corefx-packages \$BASE_PATH/corefx/packages \
\$EXTRA_OPTIONS \
|& tee \$BASE_PATH/$(basename $TEST_ROOT).log
END

    chmod 775 $TEST_SCRIPT
}

generate_test_runner_script

mkdir -p "$CORECLR_BIN"
mkdir -p "$TESTS"
mkdir -p "$COREFX_NATIVE"
mkdir -p "$PACKAGES"

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
#$EXTRA_OPTIONS \
#| tee $LOG_FILE

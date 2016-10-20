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

CORECLR_BIN=$TEST_ROOT/coreclr/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}
TESTS=$TEST_ROOT/corefx/bin/tests
COREFX_NATIVE=$TEST_ROOT/corefx/bin/${OS}.${ARCHITECTURE}.${BUILD}/Native
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

function copy_test_packages
{
    export PACKAGE_SRC_DIR=$2
    export PACKAGE_TARGET_DIR=$3

    find $1 -name RunTests.sh -exec grep copy_and_check {} \; \
        | grep -v "function copy_and_check" \
        | sed -e "s/copy_and_check //" \
        | sed -e "s/\ $EXECUTION_DIR.*//" \
        | sort \
        | uniq \
        | sed -e "s/\$PACKAGE_DIR\(.*\)/mkdir -p \$(dirname \$PACKAGE_TARGET_DIR\1); cp -a \$PACKAGE_SRC_DIR\1 \$PACKAGE_TARGET_DIR\1/" \
        | /bin/bash
}

generate_test_runner_script

mkdir -p "$CORECLR_BIN"
mkdir -p "$TESTS"
mkdir -p "$COREFX_NATIVE"
mkdir -p "$PACKAGES"

cp -a $BASE_PATH/coreclr/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}/*.dll $CORECLR_BIN
cp -a $BASE_PATH/coreclr/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}/*.so $CORECLR_BIN
cp -a $BASE_PATH/coreclr/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}/coreconsole $CORECLR_BIN
cp -a $BASE_PATH/coreclr/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}/corerun $CORECLR_BIN
cp -a $BASE_PATH/coreclr/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}/crossgen $CORECLR_BIN
cp -a $BASE_PATH/coreclr/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}/ilasm $CORECLR_BIN
cp -a $BASE_PATH/coreclr/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}/ildasm $CORECLR_BIN
cp -a $BASE_PATH/coreclr/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}/mcs $CORECLR_BIN
cp -a $BASE_PATH/coreclr/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}/superpmi $CORECLR_BIN

cp -a $BASE_PATH/corefx/bin/tests/*.${BUILD} $TESTS

cp -a $BASE_PATH/corefx/bin/${OS}.${ARCHITECTURE}.${BUILD}/Native/*.so $COREFX_NATIVE
cp -a $BASE_PATH/corefx/bin/${OS}.${ARCHITECTURE}.${BUILD}/Native/*.a $COREFX_NATIVE

copy_test_packages "$TEST_ROOT/corefx/bin/tests" "$BASE_PATH/corefx/packages" "$TEST_ROOT/corefx/packages"

cp -a $BASE_PATH/corefx/run-test.sh $TEST_ROOT

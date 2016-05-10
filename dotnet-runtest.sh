#!/bin/bash -x

function usage
{
	echo ''
	echo "Usage: [BASE_PATH=<git_base>] [TEST_SET=Windows_NT.x64.Release] $(basename $0) <target> [option]"
	echo ''
	echo 'target : os.architecture.configuration'
	echo '                    os = Linux | OSX | Windows'
	echo '          architecture = x64 | x86 | arm64 | arm | arm-softfp'
	echo '         configuration = debug | release'
	echo ''
	echo 'option : <path> of '--testDir=' | <path> of '--testDirFile=' | <options>'
	echo ''
}

if [ $# -eq 0 ]
then
	usage
	exit
fi

TARGET=(${1//./ })

OS=${TARGET[0]}
ARCHITECTURE=${TARGET[1]}
BUILD=${TARGET[2]}

if [ -z "$BASE_PATH" ]
then
	BASE_PATH=~/git
fi
CORECLR=$BASE_PATH/coreclr
COREFX=$BASE_PATH/corefx

echo "TEST SET: ${TEST_SET:=Windows_NT.x64.Debug}"

TEST_BASE=$CORECLR/tests
TEST_ROOT=$CORECLR/bin/tests/$TEST_SET
TEST_CASE=

if [ -n "$4" ]
then
	TEST_CASE=$4
	if [ -f "$TEST_CASE" ]
	then
		TEST_CASE="--testDirFile=$TEST_CASE"
	else
		if [ -d "$TEST_ROOT/$TEST_CASE" ]
		then
			TEST_CASE="--testDir=$4"
		fi
	fi
fi

$TEST_BASE/runtest.sh \
	--testRootDir="$TEST_ROOT" \
	--testNativeBinDir="$CORECLR/bin/obj/${OS}.${ARCHITECTURE}.${BUILD}/tests" \
	--coreClrBinDir="$CORECLR/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}" \
	--mscorlibDir="$CORECLR/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}" \
	--coreFxBinDir="$COREFX/bin/AnyOS.AnyCPU.${BUILD};$COREFX/bin/Unix.AnyCPU.${BUILD};$COREFX/bin/${OS}.AnyCPU.${BUILD};$COREFX/bin/${OS}.${ARCHITECTURE}.${BUILD};" \
	--coreFxNativeBinDir="$COREFX/bin/${OS}.${ARCHITECTURE}.${BUILD}" \
	$TEST_CASE

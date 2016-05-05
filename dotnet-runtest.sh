#!/bin/bash -x
TARGET=(${1//./ })

OS=${TARGET[0]}
ARCHITECTURE=${TARGET[1]}
BUILD=${TARGET[2]}

HOME=$(echo ~)
GIT_ROOT=$HOME/git
CORECLR=$GIT_ROOT/coreclr
COREFX=$GIT_ROOT/corefx

TEST_SET=Windows_NT.x64.Debug
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
	--coreFxBinDir="$COREFX/bin/${OS}.AnyCPU.${BUILD}" \
	--coreFxNativeBinDir="$COREFX/bin/${OS}.${ARCHITECTURE}.${BUILD}" \
	$TEST_CASE

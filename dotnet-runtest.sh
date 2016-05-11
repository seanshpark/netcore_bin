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
CORECLR=$BASE_PATH/coreclr
COREFX=$BASE_PATH/corefx

LOG_FILE="$BASE_PATH/$(basename ${0}).log"
#TIME="time -o $LOG_FILE -a"
TIME="time"

#
# check log file
#
if [ -e $LOG_FILE ]; then
	rm -f $LOG_FILE
fi

COMMAND_LINE="$@"
echo $COMMAND_LINE >> $LOG_FILE
date >> $LOG_FILE

if [ -z "$TEST_SET" ]; then
	TEST_SET=Windows_NT.x64.$BUILD
fi

echo "TEST SET: $TEST_SET" | tee -a $LOG_FILE
echo $TEST_SET

TEST_BASE=$CORECLR/bin/tests
TEST_ROOT=$TEST_BASE/$TEST_SET
TEST_CASE=

#
# prepare test
#
if [ ! -d $TEST_BASE ]; then
	mkdir -p $TEST_BASE
fi

if [ ! -d $TEST_ROOT ]; then
	HASH=$(git -C $CORECLR log -1 --pretty=%H)
	TEST_ARCHIVE=~/${TEST_SET}.${HASH}.zip

	if [ ! -e $TEST_ARCHIVE ]; then
		HASH=$(ls -t ${TEST_SET} | head -1)
	fi

	if [ ! -e $TEST_ARCHIVE ]; then
		echo "ERROR:missing test case ${TEST_SET}."
		exit -1
	fi

	echo "Installing test case ${TEST_SET}..."
	unzip $TEST_ARCHIVE -d $TEST_BASE
fi

#
# optional parameters
#

if [ -n "$4" ]; then
	TEST_CASE=$4
	if [ -f "$TEST_CASE" ]; then
		TEST_CASE="--testDirFile=$TEST_CASE"
	else
		if [ -d "$TEST_ROOT/$TEST_CASE" ]; then
			TEST_CASE="--testDir=$4"
		fi
	fi
fi

$CORECLR/tests/runtest.sh \
	--testRootDir="$TEST_ROOT" \
	--testNativeBinDir="$CORECLR/bin/obj/${OS}.${ARCHITECTURE}.${BUILD}/tests" \
	--coreClrBinDir="$CORECLR/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}" \
	--mscorlibDir="$CORECLR/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}" \
	--coreFxBinDir="$COREFX/bin/AnyOS.AnyCPU.${BUILD};$COREFX/bin/Unix.AnyCPU.${BUILD};$COREFX/bin/${OS}.AnyCPU.${BUILD};$COREFX/bin/${OS}.${ARCHITECTURE}.${BUILD};" \
	--coreFxNativeBinDir="$COREFX/bin/${OS}.${ARCHITECTURE}.${BUILD}" \
	$TEST_CASE \
	| tee -a $LOG_FILE

#CMD="$CORECLR/tests/runtest.sh \
#	--testRootDir="$TEST_ROOT" \
#	--testNativeBinDir="$CORECLR/bin/obj/${OS}.${ARCHITECTURE}.${BUILD}/tests" \
#	--coreClrBinDir="$CORECLR/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}" \
#	--mscorlibDir="$CORECLR/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}" \
#	--coreFxBinDir="$COREFX/bin/AnyOS.AnyCPU.${BUILD};$COREFX/bin/Unix.AnyCPU.${BUILD};$COREFX/bin/${OS}.AnyCPU.${BUILD};$COREFX/bin/${OS}.${ARCHITECTURE}.${BUILD};" \
#	--coreFxNativeBinDir="$COREFX/bin/${OS}.${ARCHITECTURE}.${BUILD}" \
#	$TEST_CASE \
#	| tee -a $LOG_FILE"

#echo $CMD | tee -a $LOG_FILE
#eval "$CMD"

if [ -n "$NOTIFY" ]; then
	$NOTIFY "$(hostname -s): $(basename $0) $COMMAND_LINE complete!"
fi

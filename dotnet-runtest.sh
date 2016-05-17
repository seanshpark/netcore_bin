#!/bin/bash

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
date | tee -a $LOG_FILE

if [ -z "$TEST_SET" ]; then
	TEST_SET=Windows_NT.x64.$BUILD
fi

echo "TEST SET: $TEST_SET" | tee -a $LOG_FILE

TEST_BASE=$CORECLR/bin/tests
TEST_ROOT=$TEST_BASE/$TEST_SET

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
		TEST_ARCHIVE=~/$(ls -t ~ | grep $TEST_SET | head -1)
	fi

	if [ ! -e $TEST_ARCHIVE ]; then
		echo "ERROR:missing test case ${TEST_SET}."
		exit -1
	fi

	echo "Installing test case ${TEST_SET}..."
	unzip $TEST_ARCHIVE -d $TEST_BASE/$TEST_SET
fi

#
# optional parameters
#
TEST_CASE=
EXTRA_OPTION=

shift
while [ -n "$1" ]; do
	case $1 in
		--*)
            EXTRA_OPTION="$EXTRA_OPTION $1"
			;;
		*)
			if [ -f "$TEST_CASE" ]; then
				TEST_CASE="--testDirFile=$TEST_CASE"
			else
				if [ -d "$TEST_ROOT/$TEST_CASE" ]; then
					TEST_CASE="--testDir=$1"
				fi
			fi
			;;
	esac
    shift
done

echo "$CORECLR/tests/runtest.sh" | tee -a $LOG_FILE
echo "	--testRootDir=$TEST_ROOT" | tee -a $LOG_FILE
echo "	--testNativeBinDir=$CORECLR/bin/obj/${OS}.${ARCHITECTURE}.${BUILD}" | tee -a $LOG_FILE
echo "	--coreClrBinDir=$CORECLR/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}" | tee -a $LOG_FILE
echo "	--mscorlibDir=$CORECLR/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}" | tee -a $LOG_FILE
echo "	--coreFxBinDir=$COREFX/bin/${OS}.${ARCHITECTURE}.${BUILD};$COREFX/bin/${OS}.AnyCPU.${BUILD};$COREFX/bin/Unix.AnyCPU.${BUILD};$COREFX/bin/AnyOS.AnyCPU.${BUILD};" | tee -a $LOG_FILE
echo "	--coreFxNativeBinDir=$COREFX/bin/${OS}.${ARCHITECTURE}.${BUILD}" | tee -a $LOG_FILE
echo "	$TEST_CASE $EXTRA_OPTION" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

$CORECLR/tests/runtest.sh \
	--testRootDir="$TEST_ROOT" \
	--testNativeBinDir="$CORECLR/bin/obj/${OS}.${ARCHITECTURE}.${BUILD}" \
	--coreClrBinDir="$CORECLR/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}" \
	--mscorlibDir="$CORECLR/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}" \
	--coreFxBinDir="$COREFX/bin/${OS}.${ARCHITECTURE}.${BUILD};$COREFX/bin/${OS}.AnyCPU.${BUILD};$COREFX/bin/Unix.AnyCPU.${BUILD};$COREFX/bin/AnyOS.AnyCPU.${BUILD};" \
	--coreFxNativeBinDir="$COREFX/bin/${OS}.${ARCHITECTURE}.${BUILD}" \
	$TEST_CASE $EXTRA_OPTION \
	| tee -a $LOG_FILE

date | tee -a $LOG_FILE

if [ -n "$NOTIFY" ]; then
	$NOTIFY \"$(hostname -s): $(basename $0) $COMMAND_LINE complete. - $(date)\"
fi

#!/bin/bash
#
#   Copyright 2016 by Sung-Jae Lee (sjlee@mail.com)
#

#
# set default configuration
#
BUILD_ARM=
BUILD_SOFTFP=
BUILD_HOST=
BUILD_MANAGED=
BUILD_CLI=
BUILD_ROSLYN=
BUILD_TYPE=debug
CLEAN=
VERBOSE=
DISTCLEAN=
SKIPMSCORLIB=
SKIPTESTS=skiptests

#
# etc.
#
if [ -z "$BASE_PATH" ]
then
	BASE_PATH=$(pwd)
fi

LOG_FILE="$BASE_PATH/$(basename ${0}).log"
#TIME="time -o $LOG_FILE -a"
TIME="time"

#
# define functions
#

function usage
{
	echo ''
	echo "Usage: [BASE_PATH=<git_base>] $(basename $0) [command] [trget] [configuration] [mode] [option]"
	echo ''
	echo '      command : update | sync | distclean'
	echo '       target : default | all | arm, arm-softfp, host, cli, loslyn, managed'
	echo 'configuration : (debug) | release | checked'
	echo '         mode : quick'
	echo '       option : clean, verbose, skipmscorlib, {(skiptests) | no-skiptests}, native-only'
	echo ''
}

function time_stamp
{
	date >> $LOG_FILE
}

function task_stamp
{
	echo "" >> $LOG_FILE
	echo "$1" >> $LOG_FILE
	echo "BRANCH:$(git branch | grep '^*')" >> $LOG_FILE
	echo "HASH:$(git log -1 --pretty=%H)" >> $LOG_FILE
}

function sync
{
	BRANCH=$(git -C $1 branch | grep '*' | cut -d' ' -f2-)
	UPSTREAM=$(git -C $1 remote | grep -v origin)

	echo "" >> $LOG_FILE
	echo ">>>> sync [$1] to upstream <<<<" >> $LOG_FILE
	git -C $1 fetch --all
	git -C $1 merge $UPSTREAM/$BRANCH
	git -C $1 push
	git -C $1 pull --rebase
	echo "BRANCH:$(git branch | grep '^*')" >> $LOG_FILE
	echo "HASH:$(git log -1 --pretty=%H)" >> $LOG_FILE
}

function sync_repo 
{
	case $# in
		0)
			for repo in $(find $BASE_PATH -maxdepth 1 -type d)
			do
				if [ -e $repo/.git ]
				then
					sync $repo
				fi
			done
			;;
		*)
			while [ -n "$1" ] && [ -e $1/.git ]
			do
				sync $1
				shift
			done
			;;
	esac
	time_stamp
}

function update
{
	BRANCH=$(git -C $1 branch | grep '*' | cut -d' ' -f2-)
	UPSTREAM=$(git -C $1 remote | grep -v origin)

	echo "" >> $LOG_FILE
	echo ">>>> update [$1] <<<<" >> $LOG_FILE
	git -C $1 pull --rebase
	echo "BRANCH:$(git branch | grep '^*')" >> $LOG_FILE
	echo "HASH:$(git log -1 --pretty=%H)" >> $LOG_FILE
}

function update_repo 
{
	case $# in
		0)
			for repo in $(find $BASE_PATH -maxdepth 1 -type d)
			do
				if [ -e $repo/.git ]
				then
					update $repo
				fi
			done
			;;
		*)
			while [ -n "$1" ] && [ -e $1/.git ]
			do
				update $1
				shift
			done
			;;
	esac
	time_stamp
}

function distclean 
{
	for repo in $(find $BASE_PATH -maxdepth 1 -type d)
	do
		if [ -e $repo/.git ]
		then
			git -C $repo clean -xdf
		fi
	done
	time_stamp
}

#
# print usage
#
if [ $# -eq 0 ]
then
	usage
fi

#
# check log file
#
if [ -e $LOG_FILE ]
then
	rm -f $LOG_FILE
fi

COMMAND_LINE="$@"
echo $COMMAND_LINE >> $LOG_FILE
date >> $LOG_FILE

#
# parse command-line options
#
while [ -n "$1" ]
do
	case $1 in
		default)
			BUILD_ARM=YES
			BUILD_SOFTFP=
			BUILD_HOST=YES
			BUILD_MANAGED=YES
			BUILD_CLI=
			BUILD_ROSLYN=
			;;
		all)
			BUILD_ARM=YES
			BUILD_SOFTFP=YES
			BUILD_HOST=YES
			BUILD_MANAGED=YES
			BUILD_CLI=YES
			BUILD_ROSLYN=YES
			;;
		managed)
			BUILD_MANAGED=YES
			;;
		quick)
			CLEAN=
			SKIPMSCORLIB=
			SKIPTESTS=skiptests
			break
			;;
		arm)
			BUILD_ARM=YES
			BUILD_MANAGED=YES
			;;
		arm-softfp)
			BUILD_SOFTFP=YES
			BUILD_MANAGED=YES
			;;
		host)
			BUILD_HOST=YES
			BUILD_MANAGED=YES
			;;
		cli)
			BUILD_CLI=YES
			;;
		loslyn)
			BUILD_ROSLYN=YES
			;;
		skipmscorlib)
			SKIPMSCORLIB=$1
			;;
		skiptests)
			SKIPTESTS=$1
			;;
		no-skiptests)
			SKIPTESTS=
			;;
		debug|release|checked)
			BUILD_TYPE=$1
			;;
		native-only)
			BUILD_MANAGED=
			;;
		clean)
			CLEAN=$1
			;;
		verbose)
			VERBOSE=$1
			;;
		distclean)
			distclean | tee -a $LOG_FILE
			exit
			;;
		sync)
			shift
			sync_repo $@ | tee -a $LOG_FILE
			exit
			;;
		update)
			shift
			update_repo $@ | tee -a $LOG_FILE
			exit
			;;
	esac
	shift
done

#
# build arm native
#
if [ "$BUILD_ARM" = "YES" ]
then
	cd $BASE_PATH/coreclr
	task_stamp "[CORECLR - cross arm]"

	ROOTFS_DIR=~/arm-rootfs-coreclr/ $TIME ./build.sh $BUILD_TYPE $CLEAN arm cross $VERBOSE $SKIPMSCORLIB #$SKIPTESTS
	echo "CROSS ARM build result $?" >> $LOG_FILE
	time_stamp

	cd $BASE_PATH/corefx
	task_stamp "[COREFX - cross arm native]"

	ROOTFS_DIR=~/arm-rootfs-corefx/ $TIME ./build.sh native $BUILD_TYPE $CLEAN arm cross $VERBOSE $SKIPTESTS
	echo "CROSS ARM NATIVE build result $?" >> $LOG_FILE
	time_stamp
fi

#
# build arm-softfp native
#
if [ "$BUILD_SOFTFP" = "YES" ]
then
	cd $BASE_PATH/coreclr
	task_stamp "[CORECLR - cross arm-softfp]"

	ROOTFS_DIR=~/arm-softfp-rootfs-coreclr/ $TIME ./build.sh $BUILD_TYPE $CLEAN arm-softfp cross $VERBOSE $SKIPMSCORLIB #$SKIPTESTS 
	echo "CROSS ARM-SOFTFP build result $?" >> $LOG_FILE
	time_stamp
fi

#
# build host native
#
if [ "$BUILD_HOST" = "YES" ]
then
	cd $BASE_PATH/coreclr
	task_stamp "[CORECLR - host]"

	$TIME ./build.sh $BUILD_TYPE $CLEAN $VERBOSE
	echo "build result $?" >> $LOG_FILE
	time_stamp

	cd $BASE_PATH/corefx
	task_stamp "[COREFX - host]"

	$TIME ./build.sh native $BUILD_TYPE $CLEAN $VERBOSE $SKIPTESTS
	echo "HOST build result $?" >> $LOG_FILE
	time_stamp
fi

#
# build managed assembly
#
if [ "$BUILD_MANAGED" = "YES" ]
then
	cd $BASE_PATH/corefx
	task_stamp "[COREFX - managed]"

	$TIME ./build.sh managed $BUILD_TYPE $CLEAN $VERBOSE $SKIPTESTS
	echo "MANAGED build result $?" >> $LOG_FILE
	time_stamp
fi

#
# build cli
#
if [ "$BUILD_CLI" = "YES" ]
then
	cd $BASE_PATH/cli
	task_stamp "[CLI]"

	$TIME ./build.sh $BUILD_TYPE
	echo "CLI build result $?" >> $LOG_FILE
	time_stamp
fi

#
# build roslyn
#
if [ "$BUILD_ROSLYN" = "YES" ]
then
	cd $BASE_PATH/roslyn
	task_stamp "[ROSLYN]"

	$TIME make
	echo "ROSLYN build result $?" >> $LOG_FILE
	time_stamp
fi

date >> $LOG_FILE
if [ -n "$NOTIFY" ]
then
    $NOTIFY \"$(hostname -s): $(basename $0) $COMMAND_LINE complete with $? - $(date)\"
fi

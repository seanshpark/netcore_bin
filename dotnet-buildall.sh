#!/bin/bash -x
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
DISTCLEAN=
SKIPMSCORLIB=
SKIPTESTS=skiptests

#
# etc.
#
BASE_PATH=~/git
LOG_FILE="$BASE_PATH/$(basename ${0}).log"
#TIME="time -o $LOG_FILE -a"
TIME="time"

#
# check log file
#
if [ -e $LOG_FILE ]
then
	rm -f $LOG_FILE
fi

echo $@ >> $LOG_FILE
date >> $LOG_FILE

#
# define functions
#

function time_stamp
{
	date >> $LOG_FILE
}

function sync
{
	BRANCH=$(git -C $1 branch | grep '*' | cut -d' ' -f2-)
	UPSTREAM=$(git -C $1 remote | grep -v origin)

	echo ">>>> sync [$1] to upstream <<<<"
	git -C $1 fetch --all
	git -C $1 merge $UPSTREAM/$BRANCH
	git -C $1 push
	git -C $1 pull --rebase
	echo
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
# parse command-line options
#
while [ -n "$1" ]
do
	case $1 in
		all)
			BUILD_ARM=YES
			BUILD_SOFTFP=YES
			BUILD_HOST=YES
			BUILD_MANAGED=YES
			BUILD_CLI=YES
			BUILD_ROSLYN=YES
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
		softfp)
			BUILD_SOFTFP=YES
			BUILD_MANAGED=YES
			;;
		host)
			BUILD_HOST=YES
			BUILD_MANAGED=YES
			;;
		CLI)
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
		debug|release|checked)
			BUILD_TYPE=$1
			;;
		native-only)
			BUILD_MANAGED=
			;;
		clean)
			CLEAN=$1
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
			;;
	esac
	shift
done

#
# build arm native
#
if [ "$BUILD_ARM" = "YES" ]
then
	echo "[CORECLR - cross arm]" >> $LOG_FILE
	cd $BASE_PATH/coreclr
	ROOTFS_DIR=~/arm-rootfs-coreclr/ $TIME ./build.sh $BUILD_TYPE $CLEAN arm cross verbose $SKIPTESTS $SKIPMSCORLIB 
	echo "cross arm build result $?" >> $LOG_FILE
	time_stamp

	echo "[COREFX - cross arm native]" >> $LOG_FILE
	cd $BASE_PATH/corefx
	ROOTFS_DIR=~/arm-rootfs-corefx/ $TIME ./build.sh native $BUILD_TYPE $CLEAN arm cross verbose $SKIPTESTS
	echo "cross arm native build result $?" >> $LOG_FILE
	time_stamp
fi

#
# build arm-softfp native
#
if [ "$BUILD_SOFTFP" = "YES" ]
then
	echo "[CORECLR - cross arm-softfp]" >> $LOG_FILE
	cd $BASE_PATH/coreclr
	ROOTFS_DIR=~/arm-softfp-rootfs-coreclr/ $TIME ./build.sh $BUILD_TYPE $CLEAN arm-softfp cross verbose $SKIPTESTS $SKIPMSCORLIB 
	echo "cross arm-softfp build result $?" >> $LOG_FILE
	time_stamp
fi

#
# build host native
#
if [ "$BUILD_HOST" = "YES" ]
then
	echo "[CORECLR - host]" >> $LOG_FILE
	cd $BASE_PATH/coreclr
	$TIME ./build.sh $BUILD_TYPE $CLEAN verbose
	echo "build result $?" >> $LOG_FILE
	time_stamp

	echo "[COREFX - host]" >> $LOG_FILE
	cd $BASE_PATH/corefx
	$TIME ./build.sh native $BUILD_TYPE $CLEAN verbose $SKIPTESTS
	echo "host build result $?" >> $LOG_FILE
	time_stamp
fi

#
# build managed assembly
#
if [ "$BUILD_MANAGED" = "YES" ]
then
	echo "[COREFX - managed]" >> $LOG_FILE
	cd $BASE_PATH/corefx
	$TIME ./build.sh managed $BUILD_TYPE $CLEAN verbose $SKIPTESTS
	echo "managed build result $?" >> $LOG_FILE
	time_stamp
fi

#
# build cli
#
if [ "$BUILD_CLI" = "YES" ]
then
	echo "[CLI]" >> $LOG_FILE
	cd $BASE_PATH/cli
	$TIME ./build.sh $BUILD_TYPE
	echo "build result $?" >> $LOG_FILE
	time_stamp
fi

#
# build roslyn
#
if [ "$BUILD_ROSLYN" = "YES" ]
then
	echo "[ROSLYN]" >> $LOG_FILE
	cd $BASE_PATH/roslyn
	$TIME make
	echo "build result $?" >> $LOG_FILE
	time_stamp
fi

date >> $LOG_FILE

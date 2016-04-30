#!/bin/sh
CLEAN=
SKIPMSCORLIB=
SKIPTESTS=skiptests
LOG_FILE=~/git/dotnet_buildall.log
TIME="time -o $LOG_FILE -a"
TIME=$(which time)
TIME="time"

if [ -e $LOG_FILE ];
then
	rm -f $LOG_FILE
fi

while [ -n "$1" ]
do
	case $1 in
		clean)
			$CLEAN=clean
			;;
		skipmscorlib)
			$SKIPMSCORLIB=skipmscorlib
			;;
		skiptests)
			$SKIPTESTS=skiptests
			;;
	esac
	shift
done

echo "[CORECLR - cross arm]" >> $LOG_FILE
cd ~/git/coreclr
ROOTFS_DIR=~/arm-rootfs-coreclr/ $TIME ./build.sh $CLEAN arm cross verbose $SKIPMSCORLIB
echo "[COREFX - cross arm native]" >> $LOG_FILE
cd ~/git/corefx
ROOTFS_DIR=~/arm-rootfs-corefx/ $TIME ./build.sh $CLEAN arm cross verbose native $SKIPTESTS
$TIME ./build.sh verbose $SKIPTESTS
echo "[CORECLR - cross arm-softfp]" >> $LOG_FILE
cd ~/git/coreclr
ROOTFS_DIR=~/arm-softfp-rootfs-coreclr/ $TIME ./build.sh $CLEAN arm-softfp cross verbose $SKIPMSCORLIB
echo "[CORECLR]" >> $LOG_FILE
cd ~/git/coreclr
$TIME ./build.sh $CLEAN verbose
echo "[CLI]" >> $LOG_FILE
cd ~/git/cli
$TIME ./build.sh
echo "[ROSLYN]" >> $LOG_FILE
cd ~/git/roslyn
$TIME make

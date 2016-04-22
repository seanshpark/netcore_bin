#!/bin/sh
GIT_BASE=~/git
CORECLR_BASE=$GIT_BASE/coreclr
COREFX_BASE=$GIT_BASE/corefx
CLI_BASE=$GIT_BASE/cli

TARGET=~/dotnet/arm.NETCore

mkdir -p $TARGET/runtime
mkdir -p $TARGET/packages
cd $TARGET

#find $CORECLR_BASE/bin/Product/Linux.arm.Debug -name *.exe -exec cp -a {} $TARGET/runtime \;
find $CORECLR_BASE/bin/Product/Linux.arm.Debug -name *.dll -exec cp -a {} $TARGET/runtime \;
####find $CORECLR_BASE/bin/Product/Linux.arm.Debug -name *.pdb -exec cp -a {} $TARGET/runtime \;

cp -a $CORECLR_BASE/bin/Product/Linux.arm.Debug/corerun $TARGET/runtime/
cp -a $CORECLR_BASE/bin/Product/Linux.arm.Debug/*.so $TARGET/runtime/
#cp -a $CORECLR_BASE/bin/Product/Linux.arm.Debug/libcoreclr.so $TARGET~/runtime/
#cp -a $CORECLR_BASE/bin/Product/Linux.arm.Debug/mscorlib.dll $TARGET~/runtime/
#cp -a $CORECLR_BASE/bin/Product/Linux.arm.Debug/System.Globalization.Native.so $TARGET~/runtime/

#find $COREFX_BASE/bin/AnyOS.AnyCPU.Debug -name *.exe -exec cp -a {} $TARGET/runtime \;
find $COREFX_BASE/bin/AnyOS.AnyCPU.Debug -name *.dll -exec cp -a {} $TARGET/runtime \;
####find $COREFX_BASE/bin/AnyOS.AnyCPU.Debug -name *.pdb -exec cp -a {} $TARGET/runtime \;

#find $COREFX_BASE/bin/Linux.AnyCPU.Debug -name *.exe -exec cp -a {} $TARGET/runtime \;
find $COREFX_BASE/bin/Linux.AnyCPU.Debug -name *.dll -exec cp -a {} $TARGET/runtime \;
####find $COREFX_BASE/bin/Linux.AnyCPU.Debug -name *.pdb -exec cp -a {} $TARGET/runtime \;
#cp -a $COREFX_BASE/bin/Linux.AnyCPU.Debug/System.Console/System.Console.dll $TARGET/runtime/
#cp -a $COREFX_BASE/bin/Linux.AnyCPU.Debug/System.Diagnostics.Debug/System.Diagnostics.Debug.dll $TARGET/runtime/
cp -a $COREFX_BASE/bin/Linux.arm.Debug/Native/*.so $TARGET/runtime/

#!/bin/bash -x
TEST_SET=Windows_NT.x64.Debug
OS=$1
ARCHITECTURE=$2
BUILD=$3

HOME=$(echo ~)
GIT_ROOT=$HOME/git
CORECLR=$GIT_ROOT/coreclr
COREFX=$GIT_ROOT/corefx
TEST_ROOT=$CORECLR/tests

$TEST_ROOT/runtest.sh --testRootDir="${CORECLR}/bin/tests/${TEST_SET}" --testNativeBinDir="${CORECLR}/bin/obj/${OS}.${ARCHITECTURE}.${BUILD}/tests" --coreClrBinDir="${CORECLR}/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}" --coreFxBinDir="${COREFX}/bin/${OS}.AnyCPU.${BUILD}" --coreFxNativeBinDir="${COREFX}/bin/${OS}.${ARCHITECTURE}.${BUILD}"

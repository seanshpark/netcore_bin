#!/bin/bash
rm -f mscorlib.dll
rm -f *.ni.dll
ln -s {,lib}System.Globalization.Native.so
ln -s {,lib}System.IO.Compression.Native.so
ln -s {,lib}System.Native.so
ln -s {,lib}System.Net.Http.Native.so
ln -s {,lib}System.Net.Security.Native.so
ln -s {,lib}System.Security.Cryptography.Native.so

export MONO_PATH=$(pwd)
export LD_LIBRARY_PATH="$(pwd):$LD_LIBRARY_PATH"

#!/bin/bash

if [ -z "$1" ]; then
	echo "Error: Provide the executable filename as the first argument."
	exit;
fi

if [ ! -e "$1" ]; then
	echo "Error: File '$1' not found."
	exit;
fi

OVERLAY_PATH=$HOME/dotnet-overlay
CMD_ARGS=$@

export CORECLR_GDBJIT=$1

set -x
lldb-3.8 \
-o "target create $OVERLAY_PATH/corerun" \
-o "settings set target.run-args $CMD_ARGS" \
-o "plugin load $OVERLAY_PATH/libsosplugin.so" \
-o "process launch -s" \
-o "process handle -s false SIGUSR1 SIGUSR2" \
-o "breakpoint set -n EEStartup" \
-o "breakpoint set -n MethodCompiled" \
-o "process continue" \
#-o "thread step-out" \
-o "br del"

#!/usr/bin/env bash

if [ -z "$BASE_PATH" ]; then
    BASE_PATH=$(pwd)
fi

LOG_FILE="$BASE_PATH/$(basename ${0}).log"

cd ~/git/corefx
./run-test.sh \
--sequential \
--coreclr-bins /home/sjlee/git/coreclr/bin/Product/Linux.arm.Debug \
--mscorlib-bins /home/sjlee/git/coreclr/bin/Product/Linux.arm.Debug \
--corefx-tests /home/sjlee/git/corefx/bin/tests \
--corefx-native-bins /home/sjlee/git/corefx/bin/Linux.arm.Debug/Native \
--corefx-packages /home/sjlee/git/corefx/packages \
|& tee $LOG_FILE

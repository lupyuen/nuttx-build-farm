#!/usr/bin/env bash
#  Run NuttX Build Farm for macOS

set -e  #  Exit when any command fails
set -x  #  Echo commands

## Run a NuttX CI Job on macOS
# ./run-job-macos.sh arm-01

## Run All NuttX CI Jobs on macOS
./run-ci-macos.sh

#!/usr/bin/env bash
#  Run NuttX Build Farm for macOS

set -e  #  Exit when any command fails
set -x  #  Echo commands

## Set the GitHub Token
## export GITHUB_TOKEN=...
. $HOME/github-token-macos.sh

## Run a NuttX CI Job on macOS
# ./run-job-macos.sh arm-01

## Run All NuttX CI Jobs on macOS
./run-ci-macos.sh

## echo utc_time=$(date -u +'%Y-%m-%dT%H:%M:%S')
## echo local_time=$(date +'%Y-%m-%dT%H:%M:%S')

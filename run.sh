#!/usr/bin/env bash
#  Run NuttX Build Farm for macOS

## Set the GitHub Token
## export GITHUB_TOKEN=...
. $HOME/github-token-macos.sh

set -e  #  Exit when any command fails
set -x  #  Echo commands

## Run All NuttX CI Jobs on macOS
./run-ci-macos.sh

## Run One Single NuttX CI Job on macOS
# ./run-job-macos.sh risc-v-05

exit
tmp_dir=/tmp/241116
pushd $tmp_dir

## test_example.py: Reduce the timeout to 1 second
## Change: p.sendCommand("pipe", "redirect_reader: Returning success", timeout=60)
## To:     p.sendCommand("pipe", "redirect_reader: Returning success", timeout=1)
file=nuttx-patched/tools/ci/testrun/script/test_example/test_example.py
tmp_file=$tmp_dir/test_example.py
search='timeout=[0-9]*'
replace='timeout=1'
cat $file \
  | sed "s/$search/$replace/g" \
  >$tmp_file
mv $tmp_file $file

## test_openposix_.py: Reduce the timeout to 1 second
## Change: p.sendCommand( \n "ltp_interfaces_mq_send_4_2", ["PASSED", "passed", "Passed", "PASS"], timeout=10 \n )
## To:     p.sendCommand( \n "ltp_interfaces_mq_send_4_2", ["PASSED", "passed", "Passed", "PASS"], timeout=1 \n )
file=nuttx-patched/tools/ci/testrun/script/test_open_posix/test_openposix_.py
tmp_file=$tmp_dir/test_openposix_.py
search='timeout=[0-9]*'
replace='timeout=1'
cat $file \
  | sed "s/$search/$replace/g" \
  >$tmp_file
mv $tmp_file $file

#!/usr/bin/env bash
## Build and Test NuttX
## ./build-test.sh knsh64 /tmp/build-test.log
## ./build-test.sh knsh64 /tmp/build-test.log HEAD HEAD
## ./build-test.sh knsh64 /tmp/build-test.log HEAD HEAD https://github.com/apache/nuttx master https://github.com/apache/nuttx-apps master
echo "Now running https://github.com/lupyuen/nuttx-build-farm/blob/main/build-test.sh $1 $2 $3 $4 $5 $6 $7 $8"

set -e  #  Exit when any command fails
set -x  #  Echo commands

## First Parameter is the Build Test Script, like "knsh64"
script=$1
if [[ "$script" == "" ]]; then
  echo "ERROR: Script is missing (e.g. knsh64)"
  exit 1
fi

## Second Parameter is the Log File, like "/tmp/build-test.log"
log=$2
if [[ "$log" == "" ]]; then
  echo "ERROR: Log File is missing (e.g. /tmp/build-test.log)"
  exit 1
fi

## Get the Script Directory
script_path="${BASH_SOURCE}"
script_dir="$(cd -P "$(dirname -- "${script_path}")" >/dev/null 2>&1 && pwd)"

## Get the `script` option
if [ "`uname`" == "Linux" ]; then
  script_option=-c
else
  script_option=
fi

## Build and Test NuttX
function build_test {
  local script=$1
  local log=$2
  pushd /tmp
  script $log \
    $script_option \
    "$script_dir/build-test-$script.sh $3 $4 $5 $6 $7 $8"
  popd

  ## Find errors and warnings
  clean_log $log
  find_messages $log
}

## Strip the control chars
function clean_log {
  local log_file=$1
  local tmp_file=$log_file.tmp
  cat $log_file \
    | tr -d '\r' \
    | tr -d '\r' \
    | sed 's/\x08/ /g' \
    | sed 's/\x1B(B//g' \
    | sed 's/\x1B\[K//g' \
    | sed 's/\x1B[<=>]//g' \
    | sed 's/\x1B\[[0-9:;<=>?]*[!]*[A-Za-z]//g' \
    | sed 's/\x1B[@A-Z\\\]^_]\|\x1B\[[0-9:;<=>?]*[-!"#$%&'"'"'()*+,.\/]*[][\\@A-Z^_`a-z{|}~]//g' \
    | cat -v \
    >$tmp_file
  mv $tmp_file $log_file
  echo ----- "Done! $log_file"
}

## Search for Errors and Warnings
function find_messages {
  local log_file=$1
  local tmp_file=$log_file.tmp
  local msg_file=$log_file.msg
  local pattern='^(.*):(\d+):(\d+):\s+(warning|fatal error|error):\s+(.*)$'
  grep '^\*\*\*\*\*' $log_file \
    > $msg_file || true
  grep -P "$pattern" $log_file \
    | uniq \
    >> $msg_file || true
  cat $msg_file $log_file >$tmp_file
  mv $tmp_file $log_file

  ## Count the Successful Commits by non-matching "test fail"
  ## ***** BUILD / TEST FAILED FOR THIS COMMIT: nuttx @ 657247bda89d60112d79bb9b8d223eca5f9641b5 / nuttx-apps @ a6b9e718460a56722205c2a84a9b07b94ca664aa
  set +e  ## Ignore errors
  grep -i "test fail" $msg_file
  res=$?
  set -e  ## Exit when any command fails
  if [[ "$res" == "1" ]]; then  ## No Matches
    ((num_success++)) || true
  fi
}

## Build and Test NuttX
build_test \
  $script \
  $log \
  $3 $4 $5 $6 $7 $8

set +x ; echo "***** Done!" ; set -x

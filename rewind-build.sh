#!/usr/bin/env bash
## Rewind the NuttX Build for a bunch of Commits.
## sudo ./rewind-build.sh ox64:nsh

## Given a NuttX Target (ox64:nsh):
## Build the Target for the Latest Commit
## If it fails: Rebuild with Previous Commit and Next Commit
## Repeat with Previous 20 Commits
## Upload Every Build Log to GitHub Gist

echo Now running https://github.com/lupyuen/nuttx-build-farm/blob/main/rewind-build.sh

set -e  ## Exit when any command fails
set -x  ## Echo commands

# First Parameter is Target, like "ox64:nsh"
target=$1
if [[ "$target" == "" ]]; then
  echo "ERROR: Target Parameter is missing (e.g. ox64:nsh)"
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

## Build the NuttX Commit for the Target
function build_commit {
  local log=$1
  local timestamp=$2
  local apps_hash=$3
  local nuttx_hash=$4
  local prev_hash=$5
  local next_hash=$6

  ## Run the Build Job and find errors / warnings
  run_job \
    $log \
    $timestamp \
    $apps_hash \
    $nuttx_hash \
    $next_hash \
    $prev_hash
  clean_log $log
  find_messages $log

  ## Upload the log
  ## TODO: upload_log $log $job $nuttx_hash $apps_hash
}

## Run the Build Job
function run_job {
  local log_file=$1
  local timestamp=$2
  local apps_hash=$3
  local nuttx_hash=$4
  local prev_hash=$5
  local next_hash=$6
  pushd /tmp
  script $log_file \
    $script_option \
    " \
      $script_dir/rewind-commit.sh \
        $target \
        $timestamp \
        $apps_hash \
        $nuttx_hash \
        $prev_hash \
        $next_hash \
    "
  popd
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
}

## Upload to GitHub Gist
function upload_log {
  local log_file=$1
  local job=$2
  local nuttx_hash=$3
  local apps_hash=$4
  cat $log_file | \
    gh gist create \
    --public \
    --desc "[$job] CI Log for nuttx @ $nuttx_hash / nuttx-apps @ $apps_hash" \
    --filename "ci-$job.log"
}

## Create the Temp Folder
tmp_dir=/tmp/rewind-build/$target
rm -rf $tmp_dir
mkdir -p $tmp_dir
cd $tmp_dir

## Get the Latest NuttX Apps Commit
git clone https://github.com/apache/nuttx-apps apps
pushd apps
apps_hash=$(git rev-parse HEAD)
popd

## Build the Latest 20 Commits
git clone https://github.com/apache/nuttx
cd nuttx
for commit in $(
  TZ=UTC0 \
  git log \
  -20 \
  --date='format-local:%Y-%m-%dT%H:%M:%S' \
  --format="%cd,%H"
); do
  ## Commit looks like 2024-11-24T09:52:42,9f9cc7ecebd97c1a6b511a1863b1528295f68cd7
  timestamp=$(echo $commit | cut -d ',' -f 1)  ## 2024-11-24T09:52:42
  next_hash=$(echo $commit | cut -d ',' -f 2)  ## 9f9cc7ecebd97c1a6b511a1863b1528295f68cd7
  if [[ "$prev_hash" == "" ]]; then
    prev_hash=$next_hash
  fi; 
  if [[ "$nuttx_hash" == "" ]]; then
    nuttx_hash=$next_hash
  fi; 

  echo Building Commit $nuttx_hash  
  build_commit \
    $tmp_dir/$nuttx_hash \
    $timestamp \
    $apps_hash \
    $nuttx_hash \
    $next_hash \
    $prev_hash \
    &

  ## Throttle our downloads from GitHub
  date ; sleep 60

  ## Shift the Commits
  prev_hash=$nuttx_hash
  nuttx_hash=$next_hash
done

## Wait for Background Tasks to complete
fg || true

## Free up the Docker disk space
sudo docker system prune --force

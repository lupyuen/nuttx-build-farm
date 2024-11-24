#!/usr/bin/env bash
## Rewind the NuttX Build for a bunch of Commits.
## sudo ./rewind-build.sh ox64:nsh

## Given a NuttX Target (ox64:nsh):
## Build the Target for the Latest Commit
## If it fails: Rebuild with Previous Commit and Next Commit
## Repeat with Previous 20 Commits

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

## Create the Temp Folder
tmp_dir=/tmp/rewind-build/$target
# rm -rf $tmp_dir
mkdir -p $tmp_dir
cd $tmp_dir

## Run the job
function run_job {
  local timestamp=$1
  local apps_hash=$2
  local nuttx_hash=$3
  local prev_hash=$4
  local next_hash=$5
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

## Build the NuttX Commit for the Target
function build_commit {
  local timestamp=$1
  local apps_hash=$2
  local nuttx_hash=$3
  local prev_hash=$4
  local next_hash=$5

  ## Run the Build Job and find errors / warnings
  run_job \
    $timestamp \
    $apps_hash \
    $nuttx_hash \
    $next_hash \
    $prev_hash
  # clean_log
  # find_messages

  ## Upload the log
  # upload_log $job $nuttx_hash $apps_hash
}

## Get the Latest NuttX Apps Commit
# git clone https://github.com/apache/nuttx-apps apps
pushd apps
apps_hash=$(git rev-parse HEAD)
popd

## Build the Latest 20 Commits
# git clone https://github.com/apache/nuttx
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
  log_file=$tmp_dir/$nuttx_hash
  build_commit \
    $timestamp \
    $apps_hash \
    $nuttx_hash \
    $next_hash \
    $prev_hash \
    &
  sleep 10

  prev_hash=$nuttx_hash
  nuttx_hash=$next_hash
done

## Wait for Background Tasks to complete
fg

## Free up the Docker disk space
sudo docker system prune --force

#!/usr/bin/env bash
## Rewind the NuttX Build for a bunch of Commits.
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
rm -rf $tmp_dir
mkdir -p $tmp_dir
cd $tmp_dir

## Find the Latest 20 Commits
git clone https://github.com/apache/nuttx
cd nuttx
for commit in $(git log -20 --pretty=format:"%H")
do
  echo Testing Commit $commit
  git reset --hard $commit
  sleep 5
  test_once $commit
done

## Run the CI Job and find errors / warnings
run_job $job
clean_log
find_messages

## Get the hashes for NuttX and Apps
nuttx_hash=$(
  cat $log_file \
  | grep --only-matching -E "nuttx/tree/[0-9a-z]+" \
  | grep --only-matching -E "[0-9a-z]+$" --max-count=1
)
apps_hash=$(
  cat $log_file \
  | grep --only-matching -E "nuttx-apps/tree/[0-9a-z]+" \
  | grep --only-matching -E "[0-9a-z]+$" --max-count=1
)

## Upload the log
upload_log $job $nuttx_hash $apps_hash

## Free up the Docker disk space
sudo docker system prune --force

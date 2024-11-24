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
rm -rf $tmp_dir
mkdir -p $tmp_dir
cd $tmp_dir

function build_commit {
  local nuttx_hash=$1
  local apps_hash=$1

  ## Run the CI Job and find errors / warnings
  run_job $job
  clean_log
  find_messages

  ## Upload the log
  upload_log $job $nuttx_hash $apps_hash
}

## Build the Latest 20 Commits
git clone https://github.com/apache/nuttx
cd nuttx
for commit in $(
  TZ=UTC0 \
  git log \
  -20 \
  --date='format-local:%Y-%m-%dT%H:%M:%S' \
  --format="%cd %H"
); do
  echo Building Commit $commit
  log_file=$tmp_dir/$commit
  build_commit $nuttx_hash $apps_hash
done

## Free up the Docker disk space
sudo docker system prune --force

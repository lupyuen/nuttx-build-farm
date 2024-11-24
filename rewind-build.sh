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
tmp_dir=/tmp/rewind-build/$target
####log_file=/tmp/release-$device.log

## Get the Script Directory
script_path="${BASH_SOURCE}"
script_dir="$(cd -P "$(dirname -- "${script_path}")" >/dev/null 2>&1 && pwd)"

## Get the `script` option
if [ "`uname`" == "Linux" ]; then
  script_option=-c
else
  script_option=
fi

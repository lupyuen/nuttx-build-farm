#!/usr/bin/env bash
## Rewind the NuttX Build for One Single Commit.
## Given a NuttX Target (ox64:nsh):
## Build the Target for the Commit
## If it fails: Rebuild with Previous Commit and Next Commit

echo Now running https://github.com/lupyuen/nuttx-build-farm/blob/main/rewind-commit.sh
echo Called by https://github.com/lupyuen/nuttx-build-farm/blob/main/rewind-build.sh

set -e  ## Exit when any command fails
set -x  ## Echo commands

## First Parameter is Target, like "ox64:nsh"
target=$1
if [[ "$target" == "" ]]; then
  echo "ERROR: Target is missing (e.g. ox64:nsh)"
  exit 1
fi

## Second Parameter is the Commit Hash of NuttX Apps Repo, like "d6edbd0cec72cb44ceb9d0f5b932cbd7a2b96288"
apps_hash=$2
if [[ "$apps_hash" == "" ]]; then
  echo "ERROR: NuttX Apps Hash is missing (e.g. d6edbd0cec72cb44ceb9d0f5b932cbd7a2b96288)"
  exit 1
fi

## Third Parameter is the Commit Hash of NuttX Repo, like "7f84a64109f94787d92c2f44465e43fde6f3d28f"
nuttx_hash=$3
if [[ "$nuttx_hash" == "" ]]; then
  echo "ERROR: NuttX Commit Hash is missing (e.g. 7f84a64109f94787d92c2f44465e43fde6f3d28f)"
  exit 1
fi

## Fourth Parameter is the Previous Commit Hash of NuttX Repo, like "7f84a64109f94787d92c2f44465e43fde6f3d28f"
prev_hash=$4
if [[ "$prev_hash" == "" ]]; then
  echo "ERROR: Previous NuttX Commit Hash is missing (e.g. 7f84a64109f94787d92c2f44465e43fde6f3d28f)"
  exit 1
fi

## Fifth Parameter is the Next Commit Hash of NuttX Repo, like "7f84a64109f94787d92c2f44465e43fde6f3d28f"
next_hash=$5
if [[ "$next_hash" == "" ]]; then
  echo "ERROR: Next NuttX Commit Hash is missing (e.g. 7f84a64109f94787d92c2f44465e43fde6f3d28f)"
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

## Show the System Info
set | grep TMUX || true
neofetch
sleep 10

## Download the Docker Image
sudo docker pull \
  ghcr.io/apache/nuttx/apache-nuttx-ci-linux:latest
sleep 10

## Build NuttX in Docker Container
## If CI Test Hangs: Kill it after 1 hour
function build_nuttx {
  local nuttx_commit=$1
  local apps_commit=$2
  set +e  ## Ignore errors
  sudo docker run -it \
    ghcr.io/apache/nuttx/apache-nuttx-ci-linux:latest \
    /bin/bash -c "
    uname -a ;
    cd ;
    pwd ;
    git clone https://github.com/apache/nuttx ;
    git clone https://github.com/apache/nuttx-apps apps ;
    echo Building NuttX Commit $nuttx_commit ;
    pushd nuttx ; git reset --hard $nuttx_commit ; popd ;
    echo Building NuttX Apps Commit $apps_commit ;
    pushd nuttx ; git reset --hard $app_commit ; popd ;
    pushd nuttx ; echo NuttX Source: https://github.com/apache/nuttx/tree/\$(git rev-parse HEAD) ; popd ;
    pushd apps  ; echo NuttX Apps: https://github.com/apache/nuttx-apps/tree/\$(git rev-parse HEAD) ; popd ;
    sleep 10 ;
    cd nuttx ;
    ( sleep 3600 ; echo Killing pytest after timeout... ; pkill -f pytest )&
    (
      (./tools.configure $target && make -j) || (echo '***** BUILD FAILED' ; exit 1)
    );
  "
  local res=$?
  set -e  ## Exit when any command fails
  echo res=$res
}

## Build the Target for the Commit
res=build_nuttx nuttx_hash apps_hash
echo res=$res

## If it fails: Rebuild with Previous Commit and Next Commit
# build_nuttx prev_hash apps_hash
# build_nuttx next_hash apps_hash

## Monitor the Disk Space (in case Docker takes too much)
df -H

#!/usr/bin/env bash
## Rewind the NuttX Build for One Single Commit.
## Given a NuttX Target (ox64:nsh):
## Build the Target for the Commit
## If it fails: Rebuild with Previous Commit and Next Commit
## sudo ./rewind-commit.sh ox64:nsh 2024-11-24T00:00:00 d6edbd0cec72cb44ceb9d0f5b932cbd7a2b96288 7f84a64109f94787d92c2f44465e43fde6f3d28f 7f84a64109f94787d92c2f44465e43fde6f3d28f 7f84a64109f94787d92c2f44465e43fde6f3d28f

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

## Second Parameter is the Timestamp of the NuttX Repo, like "2024-11-24T00:00:00"
timestamp=$2
if [[ "$timestamp" == "" ]]; then
  echo "ERROR: Timestamp is missing (e.g. ox64:nsh)"
  exit 1
fi

## Third Parameter is the Commit Hash of NuttX Apps Repo, like "d6edbd0cec72cb44ceb9d0f5b932cbd7a2b96288"
apps_hash=$3
if [[ "$apps_hash" == "" ]]; then
  echo "ERROR: NuttX Apps Hash is missing (e.g. d6edbd0cec72cb44ceb9d0f5b932cbd7a2b96288)"
  exit 1
fi

## Fourth Parameter is the Commit Hash of NuttX Repo, like "7f84a64109f94787d92c2f44465e43fde6f3d28f"
nuttx_hash=$4
if [[ "$nuttx_hash" == "" ]]; then
  echo "ERROR: NuttX Hash is missing (e.g. 7f84a64109f94787d92c2f44465e43fde6f3d28f)"
  exit 1
fi

## Fifth Parameter is the Previous Commit Hash of NuttX Repo, like "7f84a64109f94787d92c2f44465e43fde6f3d28f"
prev_hash=$5
if [[ "$prev_hash" == "" ]]; then
  echo "ERROR: Previous NuttX Hash is missing (e.g. 7f84a64109f94787d92c2f44465e43fde6f3d28f)"
  exit 1
fi

## Sixth Parameter is the Next Commit Hash of NuttX Repo, like "7f84a64109f94787d92c2f44465e43fde6f3d28f"
next_hash=$6
if [[ "$next_hash" == "" ]]; then
  echo "ERROR: Next NuttX Hash is missing (e.g. 7f84a64109f94787d92c2f44465e43fde6f3d28f)"
  exit 1
fi

## Show the System Info
set | grep TMUX || true
neofetch

## Download the Docker Image
sudo docker pull \
  ghcr.io/apache/nuttx/apache-nuttx-ci-linux:latest

## Build NuttX in Docker Container
## If CI Test Hangs: Kill it after 1 hour
function build_nuttx {
  local nuttx_commit=$1
  local apps_commit=$2
  set +e  ## Ignore errors
  sudo docker run -it \
    ghcr.io/apache/nuttx/apache-nuttx-ci-linux:latest \
    /bin/bash -c "
    set -e ;
    set -x ;
    uname -a ;
    cd ;
    pwd ;
    git clone https://github.com/apache/nuttx ;
    git clone https://github.com/apache/nuttx-apps apps ;
    echo Building NuttX Commit $nuttx_commit ;
    pushd nuttx ; git reset --hard $nuttx_commit ; popd ;
    echo Building NuttX Apps Commit $apps_commit ;
    pushd apps  ; git reset --hard $apps_commit ; popd ;
    pushd nuttx ; echo NuttX Source: https://github.com/apache/nuttx/tree/\$(git rev-parse HEAD) ; popd ;
    pushd apps  ; echo NuttX Apps: https://github.com/apache/nuttx-apps/tree/\$(git rev-parse HEAD) ; popd ;
    cd nuttx ;
    ( sleep 3600 ; echo Killing pytest after timeout... ; pkill -f pytest )&
    (
      (./tools/configure.sh $target && make -j) || (res=\$? ; echo '***** BUILD FAILED' ; exit \$res)
    )
  "
  res=$?
  set -e  ## Exit when any command fails
  echo res=$res
}

## Build the Target for the Commit
echo "Building This Commit: nuttx=$nuttx_hash, apps=$apps_hash"
build_nuttx $nuttx_hash $apps_hash
echo res=$res

## If it fails: Rebuild with Previous Commit and Next Commit
if [[ "$res" != "0" ]]; then
  echo "***** BUILD FAILED FOR THIS COMMIT"
  echo "Building Previous Commit: nuttx=$prev_hash, apps=$apps_hash"
  res=
  build_nuttx $prev_hash $apps_hash
  echo res=$res
  if [[ "$res" != "0" ]]; then
    echo "***** BUILD FAILED FOR PREVIOUS COMMIT"
  fi

  echo "Building Next Commit: nuttx=$next_hash, apps=$apps_hash"
  res=
  build_nuttx $next_hash $apps_hash
  echo res=$res
  if [[ "$res" != "0" ]]; then
    echo "***** BUILD FAILED FOR NEXT COMMIT"
  fi
fi

## Monitor the Disk Space (in case Docker takes too much)
df -H

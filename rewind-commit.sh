#!/usr/bin/env bash
## Rewind the NuttX Build for One Single Commit.
## Read the article: https://lupyuen.github.io/articles/ci6
## sudo ./rewind-commit.sh ox64:nsh 7f84a64109f94787d92c2f44465e43fde6f3d28f d6edbd0cec72cb44ceb9d0f5b932cbd7a2b96288 2024-11-24T00:00:00 7f84a64109f94787d92c2f44465e43fde6f3d28f 7f84a64109f94787d92c2f44465e43fde6f3d28f
## sudo ./rewind-commit.sh rv-virt:citest 656883fec5561ca91502a26bf018473ca0229aa4 3c4ddd2802a189fccc802230ab946d50a97cb93c
## ./rewind-commit.sh rv-virt:knsh64_test HEAD HEAD

## Given a NuttX Target (ox64:nsh):
## Build / Test the Target for the Commit
## If it fails: Rebuild / Retest with Previous Commit and Next Commit

echo Now running https://github.com/lupyuen/nuttx-build-farm/blob/main/rewind-commit.sh $1 $2 $3 $4 $5 $6
echo Called by https://github.com/lupyuen/nuttx-build-farm/blob/main/rewind-build.sh

set -e  ## Exit when any command fails
set -x  ## Echo commands

## First Parameter is Target, like "ox64:nsh"
target=$1
if [[ "$target" == "" ]]; then
  echo "ERROR: Target is missing (e.g. ox64:nsh)"
  exit 1
fi

## Second Parameter is the Commit Hash of NuttX Repo, like "7f84a64109f94787d92c2f44465e43fde6f3d28f"
nuttx_hash=$2
if [[ "$nuttx_hash" == "" ]]; then
  echo "ERROR: NuttX Hash is missing (e.g. 7f84a64109f94787d92c2f44465e43fde6f3d28f)"
  exit 1
fi

## Third Parameter is the Commit Hash of NuttX Apps Repo, like "d6edbd0cec72cb44ceb9d0f5b932cbd7a2b96288"
apps_hash=$3
if [[ "$apps_hash" == "" ]]; then
  echo "ERROR: NuttX Apps Hash is missing (e.g. d6edbd0cec72cb44ceb9d0f5b932cbd7a2b96288)"
  exit 1
fi

## (Optional) Fourth Parameter is the Timestamp of the NuttX Commit, like "2024-11-24T00:00:00"
timestamp=$4
if [[ "$timestamp" == "" ]]; then
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S")
fi

## (Optional) Fifth Parameter is the Previous Commit Hash of NuttX Repo, like "7f84a64109f94787d92c2f44465e43fde6f3d28f"
prev_hash=$5
if [[ "$prev_hash" == "" ]]; then
  prev_hash=$nuttx_hash
fi

## (Optional) Sixth Parameter is the Next Commit Hash of NuttX Repo, like "7f84a64109f94787d92c2f44465e43fde6f3d28f"
next_hash=$6
if [[ "$next_hash" == "" ]]; then
  next_hash=$nuttx_hash
fi

## Show the System Info
set | grep TMUX || true
neofetch

## Get the Script Directory
script_path="${BASH_SOURCE}"
script_dir="$(cd -P "$(dirname -- "${script_path}")" >/dev/null 2>&1 && pwd)"

## Build NuttX in Docker Container
## If CI Test Hangs: Kill it after 1 hour
## We follow the CI Log Format, so that ingest-nuttx-builds will
## ingest our log into NuttX Dashboard and appear in NuttX Build History
## https://github.com/lupyuen/ingest-nuttx-builds/blob/main/src/main.rs
## ====================================================================================
## Configuration/Tool: adafruit-kb2040/nshsram,
## 2024-11-25 03:25:20
## ------------------------------------------------------------------------------------
function build_nuttx {
  local nuttx_commit=$1
  local apps_commit=$2
  local target_slash=$(echo $target | tr ':' '/')
  local timestamp_space=$(echo $timestamp | tr 'T' ' ')

  set +x  ## Disable Echo
  echo "===================================================================================="
  echo "Configuration/Tool: $target_slash,"
  echo "$timestamp_space"
  echo "------------------------------------------------------------------------------------"
  set -x  ## Enable Echo

  set +x  ## Disable Echo
  if [[ "$target" == "rv-virt:knsh64_test" ]]; then
    ## Build and Test Locally: QEMU RISC-V knsh64
    set +e  ## Ignore errors
    set -x  ## Enable Echo
    $script_dir/build-test-knsh64.sh $nuttx_commit $apps_commit
    res=$?
    set -e  ## Exit when any command fails
  else
    ## Build NuttX with Docker
    ## Download the Docker Image
    sudo docker pull \
      ghcr.io/apache/nuttx/apache-nuttx-ci-linux:latest

    set +e  ## Ignore errors
    set -x  ## Enable Echo
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
      echo Building nuttx @ $nuttx_commit / nuttx-apps @ $apps_commit ;
      pushd nuttx ; git reset --hard $nuttx_commit ; popd ;
      pushd apps  ; git reset --hard $apps_commit  ; popd ;
      pushd nuttx ; echo NuttX Source: https://github.com/apache/nuttx/tree/\$(git rev-parse HEAD)    ; popd ;
      pushd apps  ; echo NuttX Apps: https://github.com/apache/nuttx-apps/tree/\$(git rev-parse HEAD) ; popd ;
      cd nuttx ;
      ( sleep 3600 ; echo Killing pytest after timeout... ; pkill -f pytest )&
      (
        (./tools/configure.sh $target && make -j) || (res=\$? ; echo '***** BUILD FAILED' ; exit \$res)
      )
    "
    res=$?
    set -e  ## Exit when any command fails
  fi

  set +x  ## Disable Echo
  echo res=$res
  echo "===================================================================================="
  set -x  ## Enable Echo
}

## Build / Test the Target for the Commit
echo "Building This Commit: nuttx @ $nuttx_hash / nuttx-apps @ $apps_hash"
build_nuttx $nuttx_hash $apps_hash
echo res=$res

## If it fails: Rebuild with Previous Commit and Next Commit
if [[ "$res" != "0" ]]; then
  echo "***** BUILD / TEST FAILED FOR THIS COMMIT: nuttx @ $nuttx_hash / nuttx-apps @ $apps_hash"

  if [[ "$prev_hash" != "$nuttx_hash" ]]; then
    echo "Building Previous Commit: nuttx @ $prev_hash / nuttx-apps @ $apps_hash"
    res=
    build_nuttx $prev_hash $apps_hash
    echo res=$res
    if [[ "$res" != "0" ]]; then
      echo "***** BUILD / TEST FAILED FOR PREVIOUS COMMIT: nuttx @ $prev_hash / nuttx-apps @ $apps_hash"
    fi
  fi

  if [[ "$next_hash" != "$nuttx_hash" ]]; then
    echo "Building Next Commit: nuttx @ $next_hash / nuttx-apps @ $apps_hash"
    res=
    build_nuttx $next_hash $apps_hash
    echo res=$res
    if [[ "$res" != "0" ]]; then
      echo "***** BUILD / TEST FAILED FOR NEXT COMMIT: nuttx @ $next_hash / nuttx-apps @ $apps_hash"
    fi
  fi
fi

## Monitor the Disk Space (in case Docker takes too much)
df -H

#!/usr/bin/env bash
## Build and Test NuttX for Avaota-A1 (avaota-a1:nsh)
## ./build-test-avaota.sh
## ./build-test-avaota.sh HEAD HEAD
## ./build-test-avaota.sh HEAD HEAD https://github.com/apache/nuttx master https://github.com/apache/nuttx-apps master
## ./build-test-avaota.sh HEAD HEAD https://github.com/lupyuen2/wip-nuttx avaota2
echo "Now running https://github.com/lupyuen/nuttx-build-farm/blob/main/build-test-avaota.sh $1 $2 $3 $4 $5 $6"

set -e  #  Exit when any command fails
set -x  #  Echo commands

## Server that controls Avaota-A1
export AVAOTA_SERVER=thinkcentre

nuttx_hash=$1  ## Optional NuttX Hash (HEAD)
apps_hash=$2   ## Optional Apps Hash (HEAD)
nuttx_url=$3   ## Optional NuttX URL (https://github.com/apache/nuttx)
nuttx_ref=$4   ## Optional NuttX Ref (master)
apps_url=$5    ## Optional Apps URL (https://github.com/apache/nuttx-apps
apps_ref=$6    ## Optional Apps Ref (master)
neofetch

## Set the defaults
if [[ "$nuttx_hash" == "" ]]; then
  nuttx_hash=HEAD
fi
if [[ "$apps_hash" == "" ]]; then
  apps_hash=HEAD
fi
if [[ "$nuttx_url" == "" ]]; then
  nuttx_url=https://github.com/apache/nuttx
fi
if [[ "$nuttx_ref" == "" ]]; then
  nuttx_ref=master
fi
if [[ "$apps_url" == "" ]]; then
  apps_url=https://github.com/apache/nuttx-apps
fi
if [[ "$apps_ref" == "" ]]; then
  apps_ref=master
fi

## Get the Script Directory
script_path="${BASH_SOURCE}"
script_dir="$(cd -P "$(dirname -- "${script_path}")" >/dev/null 2>&1 && pwd)"

## Run in a Temp Folder
nuttx_ref2=$(echo $nuttx_ref | tr '/' '_')
apps_ref2=$(echo $apps_ref | tr '/' '_')
tmp_path=/tmp/build-test-avaota-$nuttx_ref2-$apps_ref2
rm -rf $tmp_path
mkdir $tmp_path
cd $tmp_path

## Download NuttX and Apps
git clone $nuttx_url nuttx --branch $nuttx_ref
git clone $apps_url  apps  --branch $apps_ref

## Switch to this NuttX Commit
if [[ "$nuttx_hash" != "" ]]; then
  pushd nuttx
  git reset --hard $nuttx_hash
  popd
fi

## Switch to this Apps Commit
if [[ "$apps_hash" != "" ]]; then
  pushd apps
  git reset --hard $apps_hash
  popd
fi

## Dump the NuttX and Apps Hash
set +x  ## Disable Echo
pushd nuttx ; echo NuttX Source: https://github.com/apache/nuttx/tree/$(git rev-parse HEAD) ; popd
pushd apps  ; echo NuttX Apps: https://github.com/apache/nuttx-apps/tree/$(git rev-parse HEAD) ; popd
set -x  ## Enable Echo

## Show the GCC and Rust versions
aarch64-none-elf-gcc -v
rustup --version || true
rustc  --version || true

## Configure the NuttX Build
cd nuttx
tools/configure.sh avaota-a1:nsh

## Build the NuttX Kernel
make -j
aarch64-none-elf-size nuttx

## Build the NuttX Apps
make -j export
pushd ../apps
./tools/mkimport.sh -z -x ../nuttx/nuttx-export-*.tar.gz
make -j import
popd

## Generate Initial RAM Disk
genromfs -f initrd -d ../apps/bin -V "NuttXBootVol"

## Prepare a Padding with 64 KB of zeroes
head -c 65536 /dev/zero >/tmp/nuttx.pad

## Append Padding and Initial RAM Disk to NuttX Kernel
cat nuttx.bin /tmp/nuttx.pad initrd \
  >Image

## Copy the NuttX Image to MicroSD
scp Image $AVAOTA_SERVER:/tmp/Image
ssh $AVAOTA_SERVER ls -l /tmp/Image
ssh $AVAOTA_SERVER sudo /home/user/copy-image.sh

## Run the NuttX Test
cd $script_dir
expect ./avaota.exp

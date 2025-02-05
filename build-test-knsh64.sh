#!/usr/bin/env bash
## Build and Test NuttX for QEMU RISC-V 64-bit (Kernel Build)
## ./build-test-knsh64.sh
## ./build-test-knsh64.sh HEAD HEAD
## ./build-test-knsh64.sh HEAD HEAD https://github.com/apache/nuttx master https://github.com/apache/nuttx-apps master
echo "Now running https://github.com/lupyuen/nuttx-build-farm/blob/main/build-test-knsh64.sh $1 $2 $3 $4 $5 $6"

set -e  #  Exit when any command fails
set -x  #  Echo commands

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

## Run in a Temp Folder
tmp_path=/tmp/build-test-knsh64-$nuttx_ref-$apps_ref
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
riscv-none-elf-gcc -v
rustup --version || true
rustc  --version || true

## Configure the NuttX Build
cd nuttx
tools/configure.sh rv-virt:knsh64

## Build the NuttX Kernel
make -j
riscv-none-elf-size nuttx

## Build the NuttX Apps
make -j export
pushd ../apps
./tools/mkimport.sh -z -x ../nuttx/nuttx-export-*.tar.gz
make -j import
popd

## Run the NuttX Test
qemu-system-riscv64 --version
script=qemu-riscv-knsh64
wget https://raw.githubusercontent.com/lupyuen/nuttx-riscv64/main/$script.exp
expect ./$script.exp

## Build "tcl" (required by "expect")
# wget https://core.tcl-lang.org/tcl/tarball/release/tcl.tar.gz
# tar xf tcl.tar.gz
# pushd tcl/unix
# ./configure
# make -j
# make -j install
# popd

## Build "expect"
# wget https://sourceforge.net/projects/expect/files/Expect/5.45.4/expect5.45.4.tar.gz/download
# mv download expect5.45.4.tar.gz
# tar xf expect5.45.4.tar.gz
# pushd expect5.45.4
# ./configure
# make -j
# make -j install
# popd

## Build "neofetch"
# git clone https://github.com/dylanaraps/neofetch
# pushd neofetch
# make -j install
# popd

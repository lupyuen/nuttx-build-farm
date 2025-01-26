#!/usr/bin/env bash
## Build and Test NuttX for QEMU RISC-V 64-bit (Kernel Build)
echo "***** Now running https://github.com/lupyuen/nuttx-build-farm/blob/main/build-test-knsh64.sh $1 $2"

set -e  #  Exit when any command fails
set -x  #  Echo commands

nuttx_hash=$1  ## Optional NuttX Hash
apps_hash=$2  ## Optional Apps Hash
tmp_path=/tmp/build-test-knsh64
rm -rf $tmp_path
mkdir $tmp_path
cd $tmp_path

## Build and run "neofetch"
git clone https://github.com/dylanaraps/neofetch
pushd neofetch
make -j install
popd
neofetch

## Build "tcl" (required by "expect")
wget https://core.tcl-lang.org/tcl/tarball/release/tcl.tar.gz
tar xf tcl.tar.gz
pushd tcl/unix
./configure
make -j
make -j install
popd

## Build "expect"
wget https://sourceforge.net/projects/expect/files/Expect/5.45.4/expect5.45.4.tar.gz/download
mv download expect5.45.4.tar.gz
tar xf expect5.45.4.tar.gz
pushd expect5.45.4
./configure
make -j
make -j install
popd

## Download NuttX and Apps
git clone https://github.com/apache/nuttx
git clone https://github.com/apache/nuttx-apps apps

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

## Dump the git hash
pushd nuttx ; echo NuttX Source: https://github.com/apache/nuttx/tree/$(git rev-parse HEAD) ; popd
pushd apps  ; echo NuttX Apps: https://github.com/apache/nuttx-apps/tree/$(git rev-parse HEAD) ; popd

## Show the GCC and Rust versions
riscv-none-elf-gcc -v
rustup --version || true
rustc  --version || true

## Configure the build
cd nuttx
tools/configure.sh rv-virt:knsh64

## Preserve the build config
cp .config nuttx.config

## Run the build
make -j

## Build Apps Filesystem
make export
pushd ../apps
./tools/mkimport.sh -z -x ../nuttx/nuttx-export-*.tar.gz
make import
popd

## Show the size
riscv-none-elf-size nuttx

## Run the test
qemu-system-riscv64 --version
script=qemu-riscv-knsh64
wget https://raw.githubusercontent.com/lupyuen/nuttx-riscv64/main/$script.exp
chmod +x $script.exp
./$script.exp

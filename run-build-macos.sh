#!/usr/bin/env bash
## Download the NuttX Toolchains and Run a NuttX Build on macOS:
##   brew install neofetch
##   ./run-build-macos.sh raspberrypi-pico:nsh
##   ./run-build-macos.sh ox64:nsh
##   ./run-build-macos.sh esp32s3-devkit:nsh

## To re-download the toolchains:
##   rm -rf /tmp/run-build-macos
## Read the article: https://lupyuen.github.io/articles/ci5

echo Now running https://github.com/lupyuen/nuttx-build-farm/blob/main/run-build-macos.sh $1
echo utc_time=$(date -u +'%Y-%m-%dT%H:%M:%S')
echo local_time=$(date +'%Y-%m-%dT%H:%M:%S')

set -e  #  Exit when any command fails
set -x  #  Echo commands

## Parameter is NuttX Target, like "ox64:nsh"
target=$1
if [[ "$target" == "" ]]; then
  echo "ERROR: Target Parameter is missing (e.g. ox64:nsh)"
  exit 1
fi

## Extract the Board and Config from Target
board=$(echo $target | cut -d ':' -f 1)
config=$(echo $target | cut -d ':' -f 2)
if [[ "$board" == "" ]]; then
  echo "ERROR: Board is missing (e.g. ox64)"
  exit 1
fi
if [[ "$config" == "" ]]; then
  echo "ERROR: Config is missing (e.g. nsh)"
  exit 1
fi

## Show the System Info
neofetch
uname -a

## Get the Script Directory
script_path="${BASH_SOURCE}"
script_dir="$(cd -P "$(dirname -- "${script_path}")" >/dev/null 2>&1 && pwd)"

## Remove Homebrew ar from PATH. It shall become /usr/bin/ar
export PATH=$(
  echo $PATH \
    | tr ':' '\n' \
    | grep -v "/opt/homebrew/opt/make/libexec/gnubin" \
    | grep -v "/opt/homebrew/opt/coreutils/libexec/gnubin" \
    | grep -v "/opt/homebrew/opt/binutils/bin" \
    | tr '\n' ':'
)
if [[ $(which ar) != "/usr/bin/ar" ]]; then
  echo "ERROR: Expected 'which ar' to return /usr/bin/ar, not $(which ar)"
  exit 1
fi

## Preserve the Tools Folder
tmp_dir=/tmp/run-build-macos
tools_dir=$tmp_dir/tools
if [[ -d $tools_dir ]]; then
  rm -rf /tmp/tools
  mv $tools_dir /tmp
fi

## Create the Temp Folder and restore the Tools Folder
rm -rf $tmp_dir
mkdir $tmp_dir
cd $tmp_dir
if [[ -d /tmp/tools ]]; then
  mv /tmp/tools .
fi

## Somehow wasi-sdk always fails. We re-download.
rm -rf $tmp_dir/tools/wasi-sdk*

## Checkout NuttX Repo and NuttX Apps
git clone https://github.com/apache/nuttx
git clone https://github.com/apache/nuttx-apps apps
pushd nuttx ; echo NuttX Source: https://github.com/apache/nuttx/tree/$(git rev-parse HEAD) ; popd
pushd apps  ; echo NuttX Apps: https://github.com/apache/nuttx-apps/tree/$(git rev-parse HEAD) ; popd

## Patch the macOS CI Job for Apple Silicon: darwin_arm64.sh
## Which will trigger an "uncommitted files" warning later
pushd nuttx
$script_dir/patch-ci-macos.sh
git status
popd

## Suppress the uncommitted darwin_arm64.sh warning:
## We copy the patched "nuttx" folder to "nuttx-patched"
## Then restore the original "nuttx" folder
cp -r nuttx nuttx-patched
pushd nuttx
git restore tools/ci
git status
popd

## Patch the CI Job cibuild.sh to point to "nuttx-patched"
## Change: CIPLAT=${CIWORKSPACE}/nuttx/tools/ci/platforms
## To:     CIPLAT=${CIWORKSPACE}/nuttx-patched/tools/ci/platforms
file=nuttx-patched/tools/ci/cibuild.sh
tmp_file=$tmp_dir/cibuild.sh
search='\/nuttx\/tools\/'
replace='\/nuttx-patched\/tools\/'
cat $file \
  | sed "s/$search/$replace/g" \
  >$tmp_file
mv $tmp_file $file
chmod +x $file

## If CI Test Hangs: Kill it after 1 hour
( sleep 3600 ; echo Killing pytest after timeout... ; pkill -f pytest )&

## CI Build expects this Target Format:
## /arm/rp2040/raspberrypi-pico/configs/nsh,CONFIG_ARM_TOOLCHAIN_GNU_EABI
## /risc-v/bl808/ox64/configs/nsh
## /xtensa/esp32s3/esp32s3-devkit/configs/nsh
target_file=$tmp_dir/target.dat
rm -f $target_file
echo "/arm/*/$board/configs/$config,CONFIG_ARM_TOOLCHAIN_GNU_EABI" >>$target_file
echo "/arm64/*/$board/configs/$config" >>$target_file
echo "/avr/*/$board/configs/$config" >>$target_file
echo "/risc-v/*/$board/configs/$config" >>$target_file
echo "/sim/*/$board/configs/$config" >>$target_file
echo "/x86_64/*/$board/configs/$config" >>$target_file
echo "/xtensa/*/$board/configs/$config" >>$target_file

## Run the CI Job in "nuttx-patched"
## ./cibuild.sh -i -c -A -R testlist/macos.dat
## ./cibuild.sh -i -c -A -R testlist/arm-01.dat
pushd nuttx-patched/tools/ci
(
  ./cibuild.sh -i -c -A -R $target_file \
    || echo '***** BUILD FAILED'
)
popd

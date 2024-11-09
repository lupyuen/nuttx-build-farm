#!/usr/bin/env bash
## Run a NuttX CI Job on macOS
## To re-download the toolchain: rm -rf /tmp/run-job-macos
## Read the article: https://lupyuen.codeberg.page/articles/ci2.html

echo Now running https://github.com/lupyuen/nuttx-build-farm/blob/main/run-job-macos.sh
echo Called by https://github.com/lupyuen/nuttx-build-farm/blob/main/run-ci-macos.sh
echo utc_time=$(date -u +'%Y-%m-%dT%H:%M:%S')
echo local_time=$(date +'%Y-%m-%dT%H:%M:%S')

set -e  #  Exit when any command fails
set -x  #  Echo commands

# Parameter is CI Job, like "arm-01"
job=$1

## Show the System Info
neofetch
uname -a

## Get the Script Directory
script_path="${BASH_SOURCE}"
script_dir="$(cd -P "$(dirname -- "${script_path}")" >/dev/null 2>&1 && pwd)"

## Preserve the Tools Folder
tmp_dir=/tmp/run-job-macos
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

## Checkout NuttX Repo and NuttX Apps
git clone https://github.com/apache/nuttx
git clone https://github.com/apache/nuttx-apps apps
pushd nuttx ; echo NuttX Source: https://github.com/apache/nuttx/tree/$(git rev-parse HEAD) ; popd
pushd apps  ; echo NuttX Apps: https://github.com/apache/nuttx-apps/tree/$(git rev-parse HEAD) ; popd

## Patch the macOS CI Job for Apple Silicon: darwin.sh
pushd nuttx
$script_dir/patch-ci-macos.sh
git status
popd

## Suppress darwin.sh warning: We rename "nuttx/tools/ci" as "nuttx/tools/__pycache__"
## Why __pycache__? Because it's skipped by "nuttx/tools/.gitignore"
pushd nuttx
mv tools/ci tools/__pycache__
git restore tools/ci
git status
popd

## Patch CI Job cibuild.sh to point to __pycache__
## Change: CIPLAT=${CIWORKSPACE}/nuttx/tools/ci/platforms
## To:     CIPLAT=${CIWORKSPACE}/nuttx/tools/__pycache__/platforms
file=nuttx/tools/__pycache__/cibuild.sh
tmp_file=$tmp_dir/cibuild.sh
search='\/ci\/'
replace='\/__pycache__\/'
cat $file \
  | sed "s/$search/$replace/g" \
  >$tmp_file
mv $tmp_file $file
chmod +x $file

## Run the CI Job in __pycache__
## ./cibuild.sh -i -c -A -R testlist/macos.dat
## ./cibuild.sh -i -c -A -R testlist/arm-01.dat
pushd nuttx/tools/__pycache__
(
  ./cibuild.sh -i -c -A -R testlist/$job.dat \
    || echo '***** BUILD FAILED'
)
popd

## Monitor the Disk Space
df -H

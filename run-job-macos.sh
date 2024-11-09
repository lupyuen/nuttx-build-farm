#!/usr/bin/env bash
## Run a NuttX CI Job on macOS
## Read the article: https://lupyuen.codeberg.page/articles/ci2.html

echo Now running https://github.com/lupyuen/nuttx-build-farm/blob/main/run-job-macos.sh
echo Called by https://github.com/lupyuen/nuttx-build-farm/blob/main/run-ci-macos.sh

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

## Create the Temp Folder
tmp_dir=/tmp/run-job-macos
rm -rf $tmp_dir
mkdir $tmp_dir
cd $tmp_dir

## Checkout NuttX Repo and NuttX Apps
git clone https://github.com/apache/nuttx
git clone https://github.com/apache/nuttx-apps apps
pushd nuttx ; echo NuttX Source: https://github.com/apache/nuttx/tree/$(git rev-parse HEAD) ; popd
pushd apps  ; echo NuttX Apps: https://github.com/apache/nuttx-apps/tree/$(git rev-parse HEAD) ; popd

## Patch the CI Job for Apple Silicon Mac
pushd nuttx
$script_dir/patch-ci-macos.sh
popd

## Run the CI Job
## ./cibuild.sh -i -c -A -R testlist/macos.dat
## ./cibuild.sh -i -c -A -R testlist/arm-01.dat
pushd nuttx/tools/ci
(
  ./cibuild.sh -i -c -A -R testlist/$job.dat \
    || echo '***** BUILD FAILED'
)
popd

## Monitor the Disk Space
df -H

#!/usr/bin/env bash
## Run a NuttX CI Job on macOS:
##   brew install neofetch
##   ./run-job-macos.sh arm-01

## To re-download the toolchain: rm -rf /tmp/run-job-macos
## Read the article: https://lupyuen.github.io/articles/ci5

echo Now running https://github.com/lupyuen/nuttx-build-farm/blob/main/run-job-macos.sh $1
echo Called by https://github.com/lupyuen/nuttx-build-farm/blob/main/run-ci-macos.sh
echo utc_time=$(date -u +'%Y-%m-%dT%H:%M:%S')
echo local_time=$(date +'%Y-%m-%dT%H:%M:%S')

set -e  #  Exit when any command fails
set -x  #  Echo commands

# Parameter is CI Job, like "arm-01"
job=$1
if [[ "$job" == "" ]]; then
  echo "ERROR: Job Parameter is missing (e.g. arm-01)"
  exit 1
fi

## Show the System Info
set | grep TMUX || true
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

## Remove "sudo" from the macOS CI Job for Apple Silicon, because it hangs the job, waiting for password: darwin_arm64.sh
## https://github.com/apache/nuttx/pull/15146#issuecomment-2540844777
## Change: sudo hdiutil attach ${basefile}.dmg
## To:     ## NOTUSED: sudo hdiutil attach ${basefile}.dmg
file=nuttx-patched/tools/ci/platforms/darwin_arm64.sh
tmp_file=$tmp_dir/darwin_arm64.sh
search='sudo'
replace='## NOTUSED: sudo'
cat $file \
  | sed "s/$search/$replace/g" \
  >$tmp_file
mv $tmp_file $file
chmod +x $file

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

## Exclude clang Targets from macOS Build, because they will fail due to unknown arch
## "/arm/lpc54xx,CONFIG_ARM_TOOLCHAIN_CLANG"
## https://github.com/apache/nuttx/pull/14691#issuecomment-2466518544
tmp_file=$tmp_dir/rewrite-testlist.dat
for file in nuttx-patched/tools/ci/testlist/*.dat; do
  grep -v "CLANG" \
    $file \
    >$tmp_file
  mv $tmp_file $file
done

## If CI Test Hangs: Kill it after 1 hour
( sleep 3600 ; echo Killing pytest after timeout... ; pkill -f pytest )&

## Run the CI Job in "nuttx-patched"
## ./cibuild.sh -i -c -A -R testlist/macos.dat
## ./cibuild.sh -i -c -A -R testlist/arm-01.dat
pushd nuttx-patched/tools/ci
(
  ./cibuild.sh -i -c -A -R testlist/$job.dat \
    || echo '***** BUILD FAILED'
)
popd

## Monitor the Disk Space
df -H

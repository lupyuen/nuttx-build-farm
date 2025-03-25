#!/usr/bin/env bash
## Daily Build and Test for Avaota-A1 and StarPro64
## crontab -e
## Daily Build and Test for Avaota-A1 and StarPro64: Every Day at 00:00 UTC
## 0 0 * * * /home/luppy/nuttx-build-farm/daily-test.sh 2>&1 | logger -t nuttx-daily-test

set -e  #  Exit when any command fails

## Set the GitHub Token
## export GITHUB_TOKEN=...
. $HOME/github-token.sh

## TODO
export PATH=$HOME/xpack-riscv-none-elf-gcc-13.2.0-2/bin:$PATH
export PATH=$HOME/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin:$PATH
. "$HOME/.cargo/env"

set -x  #  Echo commands

## Get the Script Directory
script_path="${BASH_SOURCE}"
script_dir="$(cd -P "$(dirname -- "${script_path}")" >/dev/null 2>&1 && pwd)"

## Build and Test for Avaota-A1
script=avaota
log_file=/tmp/daily-test-$script
echo >$log_file
$script_dir/build-test.sh $script $log_file || true
cat $log_file | \
  gh gist create \
  --public \
  --desc "Daily Build and Test for Avaota-A1 A527 SBC" \
  --filename "daily-build-test-$script.log"

## Build and Test for StarPro64
script=starpro64
log_file=/tmp/daily-test-$script
echo >$log_file
$script_dir/build-test.sh $script $log_file || true
cat $log_file | \
  gh gist create \
  --public \
  --desc "Daily Build and Test for StarPro64 EIC7700X SBC" \
  --filename "daily-build-test-$script.log"

## Build and Test for Oz64
script=oz64
log_file=/tmp/daily-test-$script
echo >$log_file
$script_dir/build-test.sh $script $log_file || true
cat $log_file | \
  gh gist create \
  --public \
  --desc "Daily Build and Test for Oz64 SG2000 SBC" \
  --filename "daily-build-test-$script.log"

#!/usr/bin/env bash
## Daily Build and Test for Avaota-A1 and StarPro64
## crontab -e
## Daily Build and Test for Avaota-A1 and StarPro64: Every Day at 00:00 UTC
## 0 0 * * * /home/luppy/nuttx-build-farm/daily-test.sh 2>&1 | logger -t nuttx-daily-test

## Set the GitHub Token
## export GITHUB_TOKEN=...
. $HOME/github-token.sh

## Or GitLab Token
## export GITLAB_TOKEN=...
## . $HOME/gitlab-token.sh

## TODO
export PATH=$HOME/xpack-riscv-none-elf-gcc-13.2.0-2/bin:$PATH
export PATH=$HOME/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin:$PATH
. "$HOME/.cargo/env"

set -e  #  Exit when any command fails
set -x  #  Echo commands

## Build and Test for Avaota-A1
script=avaota
log_file=/tmp/daily-test-$script
./build-test.sh $script $log_file
cat $log_file | \
  gh gist create \
  --public \
  --desc "Daily Build and Test for Avaota-A1 A527 SBC" \
  --filename "daily-build-test-$script.log"

## Build and Test for StarPro64
script=starpro64
log_file=/tmp/daily-test-$script
./build-test.sh $script $log_file
cat $log_file | \
  gh gist create \
  --public \
  --desc "Daily Build and Test for StarPro64 EIC7700X SBC" \
  --filename "daily-build-test-$script.log"

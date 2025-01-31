#!/usr/bin/env bash
## Daily Cron Job: NuttX Build + Test + Rewind for RISC-V QEMU (64-bit Kernel Build)

set -e  ## Exit when any command fails

## TODO: Set PATH
export PATH="$HOME/xpack-riscv-none-elf-gcc-13.2.0-2/bin:$PATH"

## Set the GitLab Token
## export GITLAB_TOKEN=...
. $HOME/gitlab-token.sh

## Set the Mastodon Token
## export MASTODON_TOKEN=...
. $HOME/mastodon-token.sh

set -x  ## Echo commands

## Configure NuttX for RISC-V QEMU (64-bit Kernel Build)
target=rv-virt:knsh64_test8
nuttx_hash=HEAD
apps_hash=HEAD
min_commits=1
max_commits=20

## Get the Script Directory
script_path="${BASH_SOURCE}"
script_dir="$(cd -P "$(dirname -- "${script_path}")" >/dev/null 2>&1 && pwd)"

## NuttX Build + Test + Rewind for RISC-V QEMU (64-bit Kernel Build)
cd $script_dir
./rewind-build.sh \
  $target \
  $nuttx_hash \
  $apps_hash \
  $min_commits \
  $max_commits

#!/usr/bin/env bash
## Run NuttX Build Farm for macOS
## Read the article: https://lupyuen.github.io/articles/ci5

## Set the GitHub Token
## export GITHUB_TOKEN=...
. $HOME/github-token-macos.sh

## Or GitLab Token
## export GITLAB_TOKEN=...
## . $HOME/gitlab-token-macos.sh

set -e  #  Exit when any command fails
set -x  #  Echo commands

## Run All NuttX CI Jobs on macOS
./run-ci-macos.sh

## Run One Single NuttX CI Job on macOS
## ./run-job-macos.sh risc-v-05

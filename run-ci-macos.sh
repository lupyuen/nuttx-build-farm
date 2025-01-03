#!/usr/bin/env bash
## Run All NuttX CI Jobs on macOS:
##   brew install neofetch gh glab
##   . $HOME/github-token.sh && ./run-ci-macos.sh
##   . $HOME/gitlab-token.sh && ./run-ci-macos.sh

## GitHub Token: Should have Gist Permission
## github-token.sh contains:
##   export GITHUB_TOKEN=...

## GitLab Token: User Settings > Access tokens > Select Scopes
##   api: Grants complete read/write access to the API, including all groups and projects, the container registry, the dependency proxy, and the package registry.
## gitlab-token.sh contains:
##   export GITLAB_TOKEN=...
##   export GITLAB_USER=lupyuen
##   export GITLAB_REPO=nuttx-build-log
## Which means the GitLab Snippets will be created in the existing GitLab Repo "lupyuen/nuttx-build-log"

## To re-download the toolchain: rm -rf /tmp/run-job-macos
  ## Read the article: https://lupyuen.github.io/articles/ci5

echo Now running https://github.com/lupyuen/nuttx-build-farm/blob/main/run-ci-macos.sh
device=ci

set -x  ## Echo commands

## Get the Script Directory
script_path="${BASH_SOURCE}"
script_dir="$(cd -P "$(dirname -- "${script_path}")" >/dev/null 2>&1 && pwd)"
log_file=/tmp/release-$device.log

## Get the `script` option
if [ "`uname`" == "Linux" ]; then
  script_option=-c
else
  script_option=
fi

## Run the job
function run_job {
  local job=$1
  pushd /tmp
  script $log_file \
    $script_option \
    $script_dir/run-job-macos.sh $job
  popd
}

## Strip the control chars
function clean_log {
  local tmp_file=/tmp/release-tmp.log
  cat $log_file \
    | tr -d '\r' \
    | tr -d '\r' \
    | sed 's/\x08/ /g' \
    | sed 's/\x1B(B//g' \
    | sed 's/\x1B\[K//g' \
    | sed 's/\x1B[<=>]//g' \
    | sed 's/\x1B\[[0-9:;<=>?]*[!]*[A-Za-z]//g' \
    | sed 's/\x1B[@A-Z\\\]^_]\|\x1B\[[0-9:;<=>?]*[-!"#$%&'"'"'()*+,.\/]*[][\\@A-Z^_`a-z{|}~]//g' \
    | cat -v \
    >$tmp_file
  mv $tmp_file $log_file
  echo ----- "Done! $log_file"
}

## Search for Errors and Warnings
function find_messages {
  local tmp_file=/tmp/release-tmp.log
  local msg_file=/tmp/release-msg.log
  local pattern='^(.*):(\d+):(\d+):\s+(warning|fatal error|error):\s+(.*)$'
  grep '^\*\*\*\*\*' $log_file \
    > $msg_file
  grep -E "$pattern" $log_file \
    | uniq \
    >> $msg_file
  cat $msg_file $log_file >$tmp_file
  mv $tmp_file $log_file
}

## Upload to GitLab Snippet or GitHub Gist
function upload_log {
  local job=$1
  local nuttx_hash=$2
  local apps_hash=$3
  local desc="[$job] CI Log for nuttx @ $nuttx_hash / nuttx-apps @ $apps_hash"
  local filename="ci-$job.log"
  if [[ "$GITLAB_TOKEN" != "" ]]; then
    if [[ "$GITLAB_USER" == "" ]]; then
      echo '$GITLAB_USER is missing (e.g. lupyuen)'
      exit 1
    fi
    if [[ "$GITLAB_REPO" == "" ]]; then
      echo '$GITLAB_REPO is missing (e.g. nuttx-build-log)'
      exit 1
    fi
    cat $log_file | \
      glab snippet new \
        --repo "$GITLAB_USER/$GITLAB_REPO" \
        --visibility public \
        --title "$desc" \
        --filename "$filename"
  else
    cat $log_file | \
      gh gist create \
        --public \
        --desc "$desc" \
        --filename "$filename"
  fi
}

## Skip to a Random CI Job. Assume max 32 CI Jobs.
let "skip = $RANDOM % 32"
echo Skipping $skip CI Jobs...

## Repeat forever for All CI Jobs, excluding:
## arm-05: "nrf5340-dk/rpmsghci_nimble_cpuapp: apps/wireless/bluetooth/nimble/mynewt-nimble/nimble/host/services/gatt/src/ble_svc_gatt.c:174:9: error: variable 'rc' set but not used"
## arm-07: "ucans32k146/se05x: mv: illegal option -- T"
## xtensa-02: "esp32s3-devkit/qemu_debug: common/xtensa_hostfs.c:102:24: error: 'SIMCALL_O_NONBLOCK' undeclared"
## xtensa-02: "esp32s3-devkit/knsh: sed: 1: invalid command code ."
## arm64-01: "imx93-evk/bootloader: ld: library not found for -lcrt0.o"
## sim-01, 02, 03: "clang: error: invalid argument 'medium' to -mcmodel="
## other: "micropendous3/hello: make: avr-objcopy: Bad CPU type in executable"
## x86_64-01: "argtable3/src/arg_rex.c:295:10: fatal error: setjmp.h: No such file or directory"
## risc-v-05: CI Test may hang, we move to the end
## Arm32 Jobs run hotter (80 deg C) than RISC-V Jobs (70 deg C). So we stagger the jobs.
for (( ; ; )); do
  for job in \
    arm-08 risc-v-06 \
    arm-09 xtensa-01 \
    arm-10 arm-11 arm-12 arm-13 arm-14 \
    arm-01 risc-v-01 \
    arm-02 risc-v-02 \
    arm-03 risc-v-03 \
    arm-04 risc-v-04 \
    arm-06 risc-v-05
  do
    ## Skip to a Random CI Job
    if [[ $skip -gt 0 ]]; then
      let skip--
      continue
    fi

    ## Run the CI Job and find errors / warnings
    run_job $job
    clean_log
    find_messages

    ## Get the hashes for NuttX and Apps
    nuttx_hash=$(
      cat $log_file \
      | grep --only-matching -E 'nuttx/tree/[0-9a-z]+' \
      | grep --only-matching -E '[0-9a-z]+$' --max-count=1
    )
    apps_hash=$(
      cat $log_file \
      | grep --only-matching -E 'nuttx-apps/tree/[0-9a-z]+' \
      | grep --only-matching -E '[0-9a-z]+$' --max-count=1
    )

    ## Upload the log
    upload_log $job $nuttx_hash $apps_hash
    date ; sleep 20
  done

  ## Re-download the toolchain, in case the files got messed up
  rm -rf /tmp/run-job-macos
done

## Here's how we delete the 20 latest gists
function delete_gists {
  local gist_ids=($(gh gist list --limit 20 | cut -f 1 | xargs))
  for gist_id in "${gist_ids[@]}"; do
    gh gist delete $gist_id
  done
}

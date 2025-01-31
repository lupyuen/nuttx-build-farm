#!/usr/bin/env bash
## Rewind the NuttX Build for a bunch of Commits.
## Read the article: https://lupyuen.github.io/articles/ci6
## Results will appear in the NuttX Dashboard > NuttX Build History:
##   sudo apt install neofetch glab gh
##   sudo sh -c '. ../github-token.sh && ./rewind-build.sh ox64:nsh'
##   sudo sh -c '. ../gitlab-token.sh && ./rewind-build.sh ox64:nsh'
##   sudo sh -c '. ../github-token.sh && ./rewind-build.sh rv-virt:citest 656883fec5561ca91502a26bf018473ca0229aa4 3c4ddd2802a189fccc802230ab946d50a97cb93c'
##   sudo sh -c '. ../gitlab-token.sh && ./rewind-build.sh rv-virt:citest 656883fec5561ca91502a26bf018473ca0229aa4 3c4ddd2802a189fccc802230ab946d50a97cb93c'
##   . ../gitlab-token.sh && glab auth status && ./rewind-build.sh rv-virt:knsh64_test7 aa0aecbd80a2ce69ee33ced41b7677f8521acd43 a6b9e718460a56722205c2a84a9b07b94ca664aa

## Free up the Docker disk space:
## (Warning: Will delete all Docker Containers currently NOT running!)
##   sudo docker system prune --force

## Given a NuttX Target (ox64:nsh):
##   Build the Target for the Latest Commit
##   If it fails: Rebuild with Previous Commit and Next Commit
##   Repeat with Previous 20 Commits
##   Upload Every Build Log to GitHub Gist

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

echo Now running https://github.com/lupyuen/nuttx-build-farm/blob/main/rewind-build.sh $1 $2 $3 $4 $5

set -e  ## Exit when any command fails
set -x  ## Echo commands

# First Parameter is Target, like "ox64:nsh"
target=$1
if [[ "$target" == "" ]]; then
  echo "ERROR: Target Parameter is missing (e.g. ox64:nsh)"
  exit 1
fi

## (Optional) Second Parameter is the Starting Commit Hash of NuttX Repo, like "7f84a64109f94787d92c2f44465e43fde6f3d28f"
nuttx_commit=$2

## (Optional) Third Parameter is the Commit Hash of NuttX Apps Repo, like "d6edbd0cec72cb44ceb9d0f5b932cbd7a2b96288"
apps_commit=$3

## (Optional) Fourth Parameter is the Minimum Number of Commits to Build Successfully
min_commits=$4
if [[ "$min_commits" == "" ]]; then
  min_commits=20
fi

## (Optional) Fifth Parameter is the Maximum Number of Commits to Build Successfully / Unsuccessfully
max_commits=$5
if [[ "$max_commits" == "" ]]; then
  max_commits=20
fi

## Get the Script Directory
script_path="${BASH_SOURCE}"
script_dir="$(cd -P "$(dirname -- "${script_path}")" >/dev/null 2>&1 && pwd)"

## Get the `script` option
if [ "`uname`" == "Linux" ]; then
  script_option=-c
else
  script_option=
fi

## Build the NuttX Commit for the Target
function build_commit {
  local log=$1
  local timestamp=$2
  local apps_hash=$3
  local nuttx_hash=$4
  local prev_hash=$5
  local next_hash=$6

  ## Run the Build Job and find errors / warnings
  run_job \
    $log \
    $timestamp \
    $apps_hash \
    $nuttx_hash \
    $prev_hash \
    $next_hash
  clean_log $log
  find_messages $log

  ## Upload the log
  local job=unknown
  upload_log \
    $log \
    $job \
    $nuttx_hash \
    $apps_hash \
    $timestamp
}

## Run the Build Job
function run_job {
  local log_file=$1
  local timestamp=$2
  local apps_hash=$3
  local nuttx_hash=$4
  local prev_hash=$5
  local next_hash=$6
  pushd /tmp
  script $log_file \
    $script_option \
    " \
      $script_dir/rewind-commit.sh \
        $target \
        $nuttx_hash \
        $apps_hash \
        $timestamp \
        $prev_hash \
        $next_hash \
    "
  popd
}

## Strip the control chars
function clean_log {
  local log_file=$1
  local tmp_file=$log_file.tmp
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
  local log_file=$1
  local tmp_file=$log_file.tmp
  local msg_file=$log_file.msg
  local pattern='^(.*):(\d+):(\d+):\s+(warning|fatal error|error):\s+(.*)$'
  grep '^\*\*\*\*\*' $log_file \
    > $msg_file || true
  grep -P "$pattern" $log_file \
    | uniq \
    >> $msg_file || true
  cat $msg_file $log_file >$tmp_file
  mv $tmp_file $log_file

  ## Count the Successful Commits by non-matching "test fail"
  ## ***** BUILD / TEST FAILED FOR THIS COMMIT: nuttx @ 657247bda89d60112d79bb9b8d223eca5f9641b5 / nuttx-apps @ a6b9e718460a56722205c2a84a9b07b94ca664aa
  set +e  ## Ignore errors
  grep -i "test fail" $msg_file
  res=$?
  set -e  ## Exit when any command fails
  if [[ "$res" == "1" ]]; then  ## No Matches
    ((num_success++)) || true
  fi
}

## Upload to GitLab Snippet or GitHub Gist
function upload_log {
  local log_file=$1
  local job=$2
  local nuttx_hash=$3
  local apps_hash=$4
  local timestamp=$5
  local desc="[$job] CI Log for $target @ $timestamp / nuttx @ $nuttx_hash / nuttx-apps @ $apps_hash"
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

## Create the Temp Folder
tmp_dir=/tmp/rewind-build-$target
rm -rf $tmp_dir
mkdir -p $tmp_dir
cd $tmp_dir

## Get the Latest NuttX Apps Commit (if not provided)
if [[ "$apps_commit" != "" ]]; then
  apps_hash=$apps_commit
else
  git clone https://github.com/apache/nuttx-apps apps
  pushd apps
  apps_hash=$(git rev-parse HEAD)
  popd
fi

## If NuttX Commit is provided: Rewind to the commit
git clone https://github.com/apache/nuttx
cd nuttx
if [[ "$nuttx_commit" != "" ]]; then
  git reset --hard $nuttx_commit
fi

## Build the Latest 20 Commits
num_commits=$max_commits
num_success=0
count=1
for commit in $(
  TZ=UTC0 \
  git log \
  -$(( $num_commits + 1 )) \
  --date='format-local:%Y-%m-%dT%H:%M:%S' \
  --format="%cd,%H"
); do
  ## Commit looks like 2024-11-24T09:52:42,9f9cc7ecebd97c1a6b511a1863b1528295f68cd7
  prev_timestamp=$(echo $commit | cut -d ',' -f 1)  ## 2024-11-24T09:52:42
  prev_hash=$(echo $commit | cut -d ',' -f 2)  ## 9f9cc7ecebd97c1a6b511a1863b1528295f68cd7
  if [[ "$next_hash" == "" ]]; then
    next_hash=$prev_hash
  fi
  if [[ "$nuttx_hash" == "" ]]; then
    nuttx_hash=$prev_hash
  fi
  if [[ "$timestamp" == "" ]]; then
    timestamp=$prev_timestamp
    continue  ## Shift the Previous into Present
  fi

  set +x ; echo "***** #$count of $num_commits: Building nuttx @ $nuttx_hash / nuttx_apps @ $apps_hash" ; set -x ; sleep 10
  build_commit \
    $tmp_dir/$nuttx_hash.log \
    $timestamp \
    $apps_hash \
    $nuttx_hash \
    $prev_hash \
    $next_hash

  ## Shift the Commits
  next_hash=$nuttx_hash
  nuttx_hash=$prev_hash
  timestamp=$prev_timestamp
  ((count++)) || true

  ## Stop when we have reached the Minimum Number of Successful Commits
  if [[ "$num_success" == "$min_commits" ]]; then
    break
  fi
  date
done

## Wait for Background Tasks to complete
fg || true

set +x ; echo "***** Done!" ; set -x

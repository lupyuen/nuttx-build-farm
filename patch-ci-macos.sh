#!/usr/bin/env bash
## Patch the NuttX CI Job for macOS (darwin_arm64.sh), so that it runs on Build Farm
## Read the article: https://lupyuen.github.io/articles/ci5

## We change the Python Environment from:
##   python_tools() { ...
##     python3 -m venv --system-site-packages /opt/homebrew ...
##     # workaround for Cython issue
## To:
##   NOTUSED_python_tools() { ...
##     python3 -m venv --system-site-packages /opt/homebrew ...
##   }
##   python_tools() {
##     python3 -m venv .venv
##     source .venv/bin/activate
##     # workaround for Cython issue

## Remember to remove Homebrew ar from PATH:
## https://github.com/lupyuen/nuttx-build-farm/blob/main/run-job-macos.sh
## export PATH=$(
##   echo $PATH \
##     | tr ':' '\n' \
##     | grep -v "/opt/homebrew/opt/make/libexec/gnubin" \
##     | grep -v "/opt/homebrew/opt/coreutils/libexec/gnubin" \
##     | grep -v "/opt/homebrew/opt/binutils/bin" \
##     | tr '\n' ':'
## )
## which ar ## Should show /usr/bin/ar

echo Now running https://github.com/lupyuen/nuttx-build-farm/blob/main/patch-ci-macos.sh
echo Called by https://github.com/lupyuen/nuttx-build-farm/blob/main/run-job-macos.sh

set -e  #  Exit when any command fails
set -x  #  Echo commands

## Create the Temp Folder
tmp_dir=/tmp/macos-build-farm
rm -rf $tmp_dir
mkdir $tmp_dir

## We shall rewrite darwin_arm64.sh
file=tools/ci/platforms/darwin_arm64.sh
tmp_file=$tmp_dir/darwin_arm64.sh

## Search and replace in the file
function rewrite_file {
  cat $file \
    | sed "s/$search/$replace/g" \
    >$tmp_file
  mv $tmp_file $file
}

## Change: python_tools() {
## To:     NOTUSED_python_tools() {
search='^python_tools() {'
replace='NOTUSED_python_tools() {'
rewrite_file

## Change: # workaround for Cython issue
## To:     } \r python_tools() { \r python3 -m venv .venv \r source .venv/bin/activate \r # workaround for Cython issue
search='^  # workaround for Cython issue'
replace=$(
cat <<'EOF' | tr '\n' '\r'
}

python_tools() {
  #### TODO: We fixed the Python Environment
  python3 -m venv .venv
  source .venv\/bin\/activate

  # workaround for Cython issue
EOF
)
rewrite_file

## Change \r back to \n
cat $file \
  | tr '\r' '\n' \
  >$tmp_file
mv $tmp_file $file
chmod +x $file

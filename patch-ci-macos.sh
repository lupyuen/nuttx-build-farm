#!/usr/bin/env bash
## Patch the NuttX CI Job for macOS, so that it runs on Apple Silicon Mac
## Read the article: https://lupyuen.codeberg.page/articles/ci2.html

echo Now running https://github.com/lupyuen/nuttx-build-farm/blob/main/patch-ci-macos.sh
echo Called by https://github.com/lupyuen/nuttx-build-farm/blob/main/run-job-macos.sh

set -e  #  Exit when any command fails
set -x  #  Echo commands

## Create the Temp Folder
tmp_dir=/tmp/macos-build-farm
rm -rf $tmp_dir
mkdir $tmp_dir

## We shall rewrite darwin.sh
file=tools/ci/platforms/darwin.sh
tmp_file=$tmp_dir/darwin.yml

## Search and replace in the file
function rewrite_file {
  cat $file \
    | sed "s/$search/$replace/g" \
    >$tmp_file
  mv $tmp_file $file
}

## Change: basefile=arm-gnu-toolchain-13.2.rel1-darwin-x86_64-arm-none-eabi
## To:     basefile=arm-gnu-toolchain-13.2.rel1-darwin-arm64-arm-none-eabi #### TODO
search='-darwin-x86_64-arm-none-eabi'
replace='-darwin-arm64-arm-none-eabi #### TODO: We changed to Arm64 macOS'
rewrite_file

## Change: basefile=arm-gnu-toolchain-13.2.Rel1-darwin-x86_64-aarch64-none-elf
## To:     basefile=arm-gnu-toolchain-13.2.Rel1-darwin-arm64-aarch64-none-elf #### TODO
search='-darwin-x86_64-aarch64-none-elf'
replace='-darwin-arm64-aarch64-none-elf #### TODO: We changed to Arm64 macOS'
rewrite_file

## Change: basefile=xpack-riscv-none-elf-gcc-13.2.0-2-darwin-x64
## To:     basefile=xpack-riscv-none-elf-gcc-13.2.0-2-darwin-arm64 #### TODO
search='-darwin-x64'
replace='-darwin-arm64 #### TODO: We changed to Arm64 macOS'
rewrite_file

## Change: basefile=xtensa-esp32-elf-12.2.0_20230208-x86_64-apple-darwin
## To:     basefile=xtensa-esp32-elf-12.2.0_20230208-aarch64-apple-darwin #### TODO
search='-x86_64-apple-darwin'
replace='-aarch64-apple-darwin #### TODO: We changed to Arm64 macOS'
rewrite_file

## Change: add_path() {
## To:     add_path() { ... } \r NOTUSED_add_path() {
search='^add_path() {'
replace=$(
cat <<'EOF' | tr '\n' '\r'
set -x  #  Echo commands
add_path() {
  PATH=$1:${PATH}
  #### TODO: We removed Homebrew ar from PATH
  PATH=$(
    echo $PATH \\
      | tr ':' '\\n' \\
      | grep -v "\/opt\/homebrew\/opt\/make\/libexec\/gnubin" \\
      | grep -v "\/opt\/homebrew\/opt\/coreutils\/libexec\/gnubin" \\
      | grep -v "\/opt\/homebrew\/opt\/binutils\/bin" \\
      | tr '\\n' ':'
  )
  echo "**** PATH=$PATH" | tr ':' '\\n'
  which ar ## Should show \/usr\/bin\/ar
}

NOTUSED_add_path() {
EOF
)
rewrite_file

## Change: python_tools() {
## To:     NOTUSED_python_tools() {
search='^python_tools() {'
replace='NOTUSED_python_tools() {'
rewrite_file

## Change: # workaround for Cython issue
## To:     } \r python_tools() { \r ... \r # workaround for Cython issue
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

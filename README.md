![Ubuntu and macOS Build Farm for Apache NuttX RTOS](https://lupyuen.github.io/images/ci3-title.jpg)

# Ubuntu and macOS Build Farm for Apache NuttX RTOS

Read the articles...

- ["Your very own Build Farm for Apache NuttX RTOS"](https://lupyuen.codeberg.page/articles/ci2.html)

- ["Optimising the Continuous Integration for Apache NuttX RTOS"](https://lupyuen.codeberg.page/articles/ci3.html)

- ["Continuous Integration Dashboard for Apache NuttX RTOS"](https://lupyuen.github.io/articles/ci4)

- ["darwin.sh: Port NuttX CI Job to macOS-14"](https://github.com/apache/nuttx/pull/14691)

__Highly Esteemed Members of our NuttX Build Farm:__

1.  [__jerpelea__](https://gist.github.com/jerpelea)  (Ubuntu)
1.  [__lvanasse__](https://gist.github.com/lvanasse) (Ubuntu)
1.  [__nuttxpr__](https://gist.github.com/nuttxpr) (Ubuntu i5)
1.  [__nuttxlinux__](https://gist.github.com/nuttxlinux) (Ubuntu Xeon)
1.  [__nuttxmacos__](https://gist.github.com/nuttxmacos) (macOS M2 Pro)

__To Join Ubuntu Build Farm:__

Please tell me your Gist ID. See ["Build NuttX for All Target Groups"](https://lupyuen.codeberg.page/articles/ci2.html#build-nuttx-for-all-target-groups).

```bash
## TODO: Install Docker Engine
## https://docs.docker.com/engine/install/ubuntu/

## Download the scripts
git clone https://github.com/lupyuen/nuttx-release
cd nuttx-release

## Login to GitHub in Headless Mode
sudo apt install gh neofetch
sudo gh auth login

## (1) What Account: "GitHub.com"
## (2) Preferred Protocol: "HTTPS"
## (3) Authenticate GitHub CLI: "Login with a web browser"
## (4) Copy the One-Time Code, press Enter
## (5) Press "q" to quit the Text Browser that appears
## (6) Switch to Firefox Browser and load https://github.com/login/device
## (7) Enter the One-Time Code. GitHub Login will proceed.
## See https://stackoverflow.com/questions/78890002/how-to-do-gh-auth-login-when-run-in-headless-mode

## Run the Build Job forever: arm-01 ... arm-14
sudo ./run-ci.sh
```

(GitHub Token should also work, see below)

To keep the Build Farm running after logout: Use `tmux`...

```bash
## First Time: Run tmux and start `sudo ./run-ci.sh`
sudo apt install tmux
tmux

## Next Time: Attach to the previous tmux session
tmux a
```

For a super-duper Server-Class Xeon PC: Run multiple jobs `run-ci.sh`, `run-ci2.sh`, `run-ci3.sh`, `run-ci4.sh`

__To Join macOS Build Farm:__

Please tell me your Gist ID:

```bash
## TODO: Install Xcode Command Line Tools, brew, autoconf, wget
## Then install these tools
brew install gh neofetch

## Download the scripts
git clone https://github.com/lupyuen/nuttx-build-farm
cd nuttx-build-farm

## Set the GitHub Token: export GITHUB_TOKEN=...
## To create GitHub Token: GitHub Settings > Developer Settings > Tokens (Classic) > Generate New Token (Classic)
## Check the following:
## repo (Full control of private repositories)
## repo:status (Access commit status)
## repo_deployment (Access deployment status)
## public_repo (Access public repositories)
## repo:invite (Access repository invitations)
## security_events (Read and write security events)
## gist (Create gists)
. $HOME/github-token-macos.sh

## Start the macOS Build Task
./run-ci-macos.sh

## To re-download the toolchain, if the files get messed up:
## rm -rf /tmp/run-job-macos
```

[(See the Install Log)](https://gist.github.com/lupyuen/0603bbf9c6c6102c0446415602200f87)

[(See the Build Logs)](https://gist.github.com/nuttxmacos)

__Warning:__ This will max out all 12 CPU Cores of Mac Mini M2 Pro. Running at a boiling hot 100 deg C!

![This will max out all 12 CPU Cores of Mac Mini M2 Pro. Running at a boiling hot 100 deg C!](https://lupyuen.github.io/images/ci5-arm32.png)

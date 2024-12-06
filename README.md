![Ubuntu and macOS Build Farm for Apache NuttX RTOS](https://lupyuen.github.io/images/ci4-flow.jpg)

# Ubuntu and macOS Build Farm for Apache NuttX RTOS

Read the articles...

- ["Your very own Build Farm for Apache NuttX RTOS"](https://lupyuen.codeberg.page/articles/ci2.html)

- ["Optimising the Continuous Integration for Apache NuttX RTOS (GitHub Actions)"](https://lupyuen.codeberg.page/articles/ci3.html)

- ["Continuous Integration Dashboard for Apache NuttX RTOS (Prometheus and Grafana)"](https://lupyuen.github.io/articles/ci4)

- ["darwin.sh: Port NuttX CI Job to macOS-14"](https://github.com/apache/nuttx/pull/14691)

__Highly Esteemed Members of our NuttX Build Farm:__

1.  [__jerpelea__](https://gist.github.com/jerpelea)  (Ubuntu)
1.  [__lvanasse__](https://gist.github.com/lvanasse) (Ubuntu)
1.  [__lupyuen__](https://gitlab.com/lupyuen/nuttx-build-log/-/snippets/) (Ubuntu Xeon)
1.  [__nuttxmacos2__](https://gitlab.com/nuttxmacos2/nuttx-build-log/-/snippets/) (macOS M2 Pro)
1.  [__nuttxpr__](https://gist.github.com/nuttxpr) (Ubuntu i5 and Ubuntu Xeon)
1.  [__nuttxmacos__](https://gist.github.com/nuttxmacos) (blocked by GitHub sigh)
1.  [__nuttxlinux__](https://gist.github.com/nuttxlinux) (blocked by GitHub sigh)

__To Join Ubuntu Build Farm:__

Please tell me your User ID for GitLab Snippets or GitHub Gist. See ["Build NuttX for All Target Groups"](https://lupyuen.codeberg.page/articles/ci2.html#build-nuttx-for-all-target-groups).

```bash
## TODO: Install Docker Engine
## https://docs.docker.com/engine/install/ubuntu/

## Download the scripts
git clone https://github.com/lupyuen/nuttx-release
cd nuttx-release
sudo apt install neofetch glab gh

## For GitLab Snippets:
sudo sh -c '. ../gitlab-token.sh && ./run-ci.sh 1'

## For GitHub Gists:
sudo sh -c '. ../github-token.sh && ./run-ci.sh 1'

## Change '1' to a Unique Instance ID. Each instance of this script will run under a different Instance ID.

## GitLab Token: User Settings > Access Tokens > Select Scopes
##   api: Grants complete read/write access to the API, including all groups and projects, the container registry, the dependency proxy, and the package registry.
## gitlab-token.sh contains:
##   export GITLAB_TOKEN=...
##   export GITLAB_USER=lupyuen
##   export GITLAB_REPO=nuttx-build-log

## GitHub Token: Should have Gist Permission
## github-token.sh contains:
##   export GITHUB_TOKEN=...
```

To keep the Build Farm running after logout: Use `tmux`...

```bash
## First Time: Run tmux and start `sudo ./run-ci.sh`
sudo apt install tmux
tmux

## Next Time: Attach to the previous tmux session
tmux a
```

For a super-duper Server-Class Xeon PC: Run multiple jobs with a different Instance ID...

```bash
## Remember to run tmux before each sudo
sudo sh -c '. ../gitlab-token.sh && ./run-ci.sh 1'
sudo sh -c '. ../gitlab-token.sh && ./run-ci.sh 2'
sudo sh -c '. ../gitlab-token.sh && ./run-ci.sh 3'
sudo sh -c '. ../gitlab-token.sh && ./run-ci.sh 4'
```

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

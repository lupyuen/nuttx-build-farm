# Ubuntu and macOS Build Farm for Apache NuttX RTOS

Read the article...
- ["Your very own Build Farm for Apache NuttX RTOS"](https://lupyuen.codeberg.page/articles/ci2.html)

For Ubuntu Build Farm:
- [nuttx-release/run-ci.sh](https://github.com/lupyuen/nuttx-release/blob/main/run-ci.sh)
- [nuttx-release/run-job.sh](https://github.com/lupyuen/nuttx-release/blob/main/run-job.sh)

For macOS Build Farm:

```bash
## Download the source files
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
```

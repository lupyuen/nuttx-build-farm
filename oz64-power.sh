#!/usr/bin/env bash
## Power Oz64 On or Off
## ./oz64-power on
## ./oz64-power off
echo "Now running https://github.com/lupyuen/nuttx-build-farm/blob/main/oz64-power.sh $1"

set -e  ## Exit when any command fails
set -x  ## Echo commands

## First Parameter is on or off
state=$1
if [[ "$state" == "" ]]; then
  echo "ERROR: Specify 'on' or 'off'"
  exit 1
fi

## Get the Home Assistant Token, copied from http://localhost:8123/profile/security
## export HOME_ASSISTANT_TOKEN=xxxx
set +x  ##  Disable echo
. $HOME/home-assistant-token.sh
set -x  ##  Enable echo

## Set the Home Assistant Server
export HOME_ASSISTANT_SERVER=luppys-mac-mini.local:8123

set +x  ##  Disable echo
echo "----- Power $state Oz64"
curl \
    -X POST \
    -H "Authorization: Bearer $HOME_ASSISTANT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"entity_id\": \"automation.oz64_power_$state\"}" \
    http://$HOME_ASSISTANT_SERVER/api/services/automation/trigger
set -x  ##  Enable echo

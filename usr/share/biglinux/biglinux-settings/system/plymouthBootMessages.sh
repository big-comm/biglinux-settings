#!/bin/bash

configFile="/etc/biglinux/plymouth-community.conf"
runScript="/usr/share/biglinux/biglinux-settings/system/plymouthBootMessagesRun.sh"

# check current status
if [ "$1" == "check" ]; then
  if grep -Eq '^[[:space:]]*SHOW_BOOT_MESSAGES[[:space:]]*=[[:space:]]*true([[:space:]]*(#.*)?)?$' "$configFile" 2>/dev/null; then
    echo "true"
  else
    echo "false"
  fi

# change the state
elif [ "$1" == "toggle" ]; then
  state="$2"
  pkexec "$runScript" "$state"
  exit $?
fi

#!/bin/bash

# check current status
if [ "$1" == "check" ]; then
  cmdline="$(grep -E '^GRUB_CMDLINE_LINUX(_DEFAULT)?=' /etc/default/grub 2>/dev/null)"
  cmdline="${cmdline//\"/ }"
  cmdline="${cmdline//\'/ }"
  if [[ " $cmdline " == *" nowatchdog "* ]] && [[ " $cmdline " == *" tsc=nowatchdog "* ]];then
    echo "true"
  else
    echo "false"
  fi

# change the state
elif [ "$1" == "toggle" ]; then
  state="$2"
  if [ "$state" == "true" ]; then
    pkexec /usr/share/biglinux/biglinux-settings/performance/noWatchdogRun.sh "enable" "$USER" "$DISPLAY" "$XAUTHORITY" "$DBUS_SESSION_BUS_ADDRESS" "$LANG" "$LANGUAGE"
    exitCode=$?
  else
    pkexec /usr/share/biglinux/biglinux-settings/performance/noWatchdogRun.sh "disable" "$USER" "$DISPLAY" "$XAUTHORITY" "$DBUS_SESSION_BUS_ADDRESS" "$LANG" "$LANGUAGE"
    exitCode=$?
  fi
  exit $exitCode
fi

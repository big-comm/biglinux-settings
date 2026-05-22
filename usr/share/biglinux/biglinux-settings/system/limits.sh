#!/bin/bash
LIMITS_FILE="/etc/security/limits.d/99-biglinux-settings.conf"

# check current status
if [ "$1" == "check" ]; then
  if [[ -r "$LIMITS_FILE" ]] &&
    grep -qE '^@audio[[:space:]]+-[[:space:]]+rtprio[[:space:]]+90$' "$LIMITS_FILE" &&
    grep -qE '^@audio[[:space:]]+-[[:space:]]+memlock[[:space:]]+unlimited$' "$LIMITS_FILE"; then
    echo "true"
  else
    echo "false"
  fi

# change the state
elif [ "$1" == "toggle" ]; then
  state="$2"
  if [ "$state" == "true" ]; then
    pkexec /usr/share/biglinux/biglinux-settings/system/limitsRun.sh "enable" "$USER" "$DISPLAY" "$XAUTHORITY" "$DBUS_SESSION_BUS_ADDRESS" "$LANG" "$LANGUAGE"
    exitCode=$?
  else
    pkexec /usr/share/biglinux/biglinux-settings/system/limitsRun.sh "disable" "$USER" "$DISPLAY" "$XAUTHORITY" "$DBUS_SESSION_BUS_ADDRESS" "$LANG" "$LANGUAGE"
    exitCode=$?
  fi
  exit $exitCode
fi

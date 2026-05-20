#!/bin/bash

state="$1"
configDir="/etc/biglinux"
configFile="$configDir/plymouth-community.conf"

if [ "$state" != "true" ] && [ "$state" != "false" ]; then
  exit 1
fi

mkdir -p "$configDir"

if [ -f "$configFile" ]; then
  if grep -qE '^[[:space:]]*SHOW_BOOT_MESSAGES[[:space:]]*=' "$configFile"; then
    sed -i "s/^[[:space:]]*SHOW_BOOT_MESSAGES[[:space:]]*=.*/SHOW_BOOT_MESSAGES=$state/" "$configFile"
  else
    printf '\nSHOW_BOOT_MESSAGES=%s\n' "$state" >> "$configFile"
  fi
else
  {
    printf '# BigCommunity Plymouth settings\n'
    printf 'SHOW_BOOT_MESSAGES=%s\n' "$state"
  } > "$configFile"
fi

chmod 0644 "$configFile"

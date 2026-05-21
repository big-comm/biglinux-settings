#!/bin/bash

state="$1"
configDir="/etc/biglinux"
configFile="$configDir/plymouth-community.conf"
themeScript="/usr/share/plymouth/themes/community/animated-boot.script"

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

if [ -f "$themeScript" ]; then
  if [ "$state" == "true" ]; then
    sed -i \
      -e 's|^[[:space:]]*#[[:space:]]*\(Plymouth\.SetDisplayMessageFunction.*\)|\1|' \
      -e 's|^[[:space:]]*#[[:space:]]*\(Plymouth\.SetHideMessageFunction.*\)|\1|' \
      -e 's|^[[:space:]]*#[[:space:]]*\(Plymouth\.SetUpdateStatusFunction.*\)|\1|' \
      "$themeScript"
  else
    sed -i \
      -e 's|^[[:space:]]*\(Plymouth\.SetDisplayMessageFunction.*\)|# \1|' \
      -e 's|^[[:space:]]*\(Plymouth\.SetHideMessageFunction.*\)|# \1|' \
      -e 's|^[[:space:]]*\(Plymouth\.SetUpdateStatusFunction.*\)|# \1|' \
      "$themeScript"
  fi
fi

if command -v plymouth-set-default-theme >/dev/null 2>&1; then
  plymouth-set-default-theme -R community
elif command -v mkinitcpio >/dev/null 2>&1; then
  mkinitcpio -P
fi

#!/bin/bash

# check current status
if [ "$1" == "check" ]; then
  if pacman -Q jamesdsp &>/dev/null && \
     grep -q 'AutoStartEnabled=true' "$HOME/.config/jamesdsp/application.conf" 2>/dev/null; then
    echo "true"
  else
    echo "false"
  fi

# change the state
elif [ "$1" == "toggle" ]; then
  state="$2"
  jamesdsp_conf="$HOME/.config/jamesdsp/application.conf"
  if [ "$state" == "true" ]; then
    if ! pacman -Q jamesdsp &>/dev/null; then
      pkexec $PWD/devices/jamesdspRun.sh "install" "$USER" "$DISPLAY" "$XAUTHORITY" "$DBUS_SESSION_BUS_ADDRESS" "$LANG" "$LANGUAGE"
    fi
    mkdir -p "$HOME/.config/jamesdsp/presets"
    cp '/etc/skel/.config/jamesdsp/presets/big-jamesdsp.conf' "$HOME/.config/jamesdsp/presets/big-jamesdsp.conf"
    jamesdsp --set master_enable=true
    sed -i 's|AutoStartEnabled=false|AutoStartEnabled=true|g' "$jamesdsp_conf" 2>/dev/null
    systemctl enable --now --user jamesdsp-autostart.service
    exitCode=$?
  else
    jamesdsp --set master_enable=false
    sed -i 's|AutoStartEnabled=true|AutoStartEnabled=false|g' "$jamesdsp_conf" 2>/dev/null
    systemctl disable --now --user jamesdsp-autostart.service
    exitCode=$?
  fi
  exit $exitCode
fi

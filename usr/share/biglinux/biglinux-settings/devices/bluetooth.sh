#!/bin/bash

# Detect the first BlueZ adapter via D-Bus
_adapter_path() {
  busctl tree org.bluez 2>/dev/null | grep -oP '/org/bluez/hci\d+' | head -1
}

# check current status
if [[ "$1" == "check" ]]; then
  adapter="$(_adapter_path)"
  if [[ -z "$adapter" ]]; then
    echo "false"
    exit 0
  fi

  powered="$(busctl get-property org.bluez "$adapter" org.bluez.Adapter1 Powered 2>/dev/null)"
  if [[ "$powered" == "b true" ]]; then
    echo "true"
  else
    echo "false"
  fi

# change the state
elif [[ "$1" == "toggle" ]]; then
  adapter="$(_adapter_path)"
  if [[ -z "$adapter" ]]; then
    exit 1
  fi

  if [[ "$2" == "true" ]]; then
    busctl set-property org.bluez "$adapter" org.bluez.Adapter1 Powered b true
  else
    busctl set-property org.bluez "$adapter" org.bluez.Adapter1 Powered b false
  fi
  exit $?
fi

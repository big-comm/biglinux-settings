#!/bin/bash

#Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# check current status
if [ "$1" == "check" ]; then
  if pacman -Q ollama &>/dev/null && ! pacman -Q ollama-vulkan &>/dev/null && ! pacman -Q ollama-rocm &>/dev/null && ! pacman -Q ollama-cuda &>/dev/null ; then
    echo "true"
  else
    echo "false"
  fi

# change the state
elif [ "$1" == "toggle" ]; then
  state="$2"
  if [ "$state" == "true" ]; then
    pkexec /usr/share/biglinux/biglinux-settings/ai/ollamaCpuRun.sh "install" "$USER" "$DISPLAY" "$XAUTHORITY" "$DBUS_SESSION_BUS_ADDRESS" "$LANG" "$LANGUAGE"
    exitCode=$?
  else
    pkexec /usr/share/biglinux/biglinux-settings/ai/ollamaCpuRun.sh "uninstall" "$USER" "$DISPLAY" "$XAUTHORITY" "$DBUS_SESSION_BUS_ADDRESS" "$LANG" "$LANGUAGE"
    exitCode=$?
  fi
  exit $exitCode
fi

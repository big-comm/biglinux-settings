#!/bin/bash

# check current status
if [ "$1" == "check" ]; then
  if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] || [[ "$XDG_CURRENT_DESKTOP" == *"Plasma"* ]];then
    if [[ "$(LANG=C kreadconfig6 --file kwinrc --group Plugins --key kzonesEnabled)" == "true" ]] && pacman -Q kwin-scripts-kzones &>/dev/null; then
      echo "true"
    else
      echo "false"
    fi
  fi

# change the state
elif [ "$1" == "toggle" ]; then
  state="$2"
  if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] || [[ "$XDG_CURRENT_DESKTOP" == *"Plasma"* ]];then
    if [ "$state" == "true" ]; then
      if ! pacman -Q kwin-scripts-kzones &>/dev/null; then
        pkexec $PWD/usability/kzonesRun.sh "install" "$USER" "$DISPLAY" "$XAUTHORITY" "$DBUS_SESSION_BUS_ADDRESS" "$LANG" "$LANGUAGE"
      fi
      kwriteconfig6 --file kwinrc --group Plugins --key kzonesEnabled true
      qdbus6 org.kde.KWin /KWin reconfigure
      exitCode=$?
    else
      kwriteconfig6 --file kwinrc --group Plugins --key kzonesEnabled false
      qdbus6 org.kde.KWin /KWin reconfigure
      exitCode=$?
    fi
  fi
  exit $exitCode
fi

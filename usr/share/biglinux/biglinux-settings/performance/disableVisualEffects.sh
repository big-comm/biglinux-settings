#!/bin/bash

#Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# check current status
if [ "$1" == "check" ]; then
  if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] || [[ "$XDG_CURRENT_DESKTOP" == *"Plasma"* ]];then
    if [[ -n "$(qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadedEffects)" ]]; then
      echo "false"
    else
      echo "true"
    fi
  fi

# change the state
elif [ "$1" == "toggle" ]; then
  state="$2"
  if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] || [[ "$XDG_CURRENT_DESKTOP" == *"Plasma"* ]];then
    if [ "$state" == "true" ]; then
      effects=$(qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadedEffects)
      rm -f "$HOME/.config/biglinux-settings/effectsEnable"
      for effect in ${effects[@]}; do
        mkdir -p "$HOME/.config/biglinux-settings"
        echo "$effect" >> "$HOME/.config/biglinux-settings/effectsEnable"
        kwriteconfig6 --file kwinrc --group Plugins --key "${effect}Enabled" false
        qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect "$effect"
      done
      exitCode=$?
    else
      effects=$(cat "$HOME/.config/biglinux-settings/effectsEnable")
      for effect in ${effects[@]}; do
        kwriteconfig6 --file kwinrc --group Plugins --key "${effect}Enabled" true
        qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect "$effect"
      done
      exitCode=$?
    fi
  fi
  exit $exitCode
fi

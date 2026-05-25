#!/bin/bash

#Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# check current status
if [ "$1" == "check" ]; then
  if [[ -d "$HOME/.local/share/krita/pykrita/ai_diffusion" ]] && pacman -Q krita &>/dev/null; then
    echo "true"
  else
    echo "false"
  fi

# change the state
elif [ "$1" == "toggle" ]; then
  state="$2"
  if [ "$state" == "true" ]; then
    if ! pacman -Q krita &>/dev/null; then
      pkexec /usr/share/biglinux/biglinux-settings/ai/kritaRun.sh "install" "$USER" "$DISPLAY" "$XAUTHORITY" "$DBUS_SESSION_BUS_ADDRESS" "$LANG" "$LANGUAGE"
    fi
    killall krita
    diffusionUrl=$(curl -s "https://api.github.com/repos/Acly/krita-ai-diffusion/releases/latest" | grep "browser_download_url" | grep ".zip" | head -n 1 | cut -d '"' -f 4)
    wget $diffusionUrl -O /tmp/krita_ai_diffusion.zip
    7z x /tmp/krita_ai_diffusion.zip -o${HOME}/.local/share/krita/pykrita/
    rm /tmp/krita_ai_diffusion.zip
    mkdir -p $HOME/.local/share/krita/actions/
    cp $HOME/.local/share/krita/pykrita/ai_diffusion/ai_diffusion.action $HOME/.local/share/krita/actions/
    kwriteconfig6 --file kritarc --group "python" --key "enable_ai_diffusion" "true"
    exitCode=$?
  else
    killall krita
    rm -rf "$HOME/.local/share/krita/pykrita"
    rm -rf "$HOME/.local/share/krita/ai_diffusion/server/models"
    rm -rf "$HOME/.local/share/krita/ai_diffusion/server/venv"
    sed -i '/krita/d' $HOME/.bashrc
    kwriteconfig6 --file kritarc --group "python" --key "enable_ai_diffusion" "false"
    exitCode=$?
  fi
  exit $exitCode
fi

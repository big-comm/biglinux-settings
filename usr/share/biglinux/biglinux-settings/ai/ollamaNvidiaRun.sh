#!/bin/bash

#Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# Assign the received arguments to variables with clear names
function="$1"

# Executes the root tasks.
updateTask() {
  if [[ "$function" == "install" ]]; then
    pacman -Syu --noconfirm ollama-cuda
    systemctl enable --now ollama.service
  else
    systemctl disable --now ollama.service
    pacman -Rcs --noconfirm ollama-cuda
  fi
  exitCode=$?
}
updateTask

# Exits the script with the correct exit code
exit $exitCode

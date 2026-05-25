#!/bin/bash

# Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# Arguments
function="$1"

installTask() {
  if [[ "$function" == "install" ]]; then
    # Ensure required system dependencies
    pacman -Syu --needed --noconfirm nodejs npm ripgrep
    depStatus=$?
    if [ "$depStatus" -ne 0 ]; then
      exitCode=$depStatus
      return
    fi
    # Install OpenClaude globally via npm
    npm install -g @gitlawb/openclaude
    exitCode=$?
  else
    npm uninstall -g @gitlawb/openclaude
    exitCode=$?
  fi
}
installTask

exit $exitCode

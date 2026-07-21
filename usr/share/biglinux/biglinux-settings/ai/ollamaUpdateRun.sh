#!/bin/bash

# Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# Arguments

# Detect installed Ollama variants
installedPkgs=""
for pkg in ollama ollama-vulkan ollama-cuda ollama-rocm; do
  if pacman -Q "$pkg" &>/dev/null; then
    installedPkgs="$installedPkgs $pkg"
  fi
done

if [ -z "$installedPkgs" ]; then
  gettext "No Ollama packages are installed. Enable an Ollama variant first."
  echo
  exit 0
fi

updateTask() {
  pacman -Syu --needed --noconfirm $installedPkgs
  exitCode=$?
}
updateTask

exit $exitCode

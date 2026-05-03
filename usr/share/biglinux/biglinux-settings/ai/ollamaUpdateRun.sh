#!/bin/bash

# Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# Arguments
originalUser="$1"
userDisplay="$2"
userXauthority="$3"
userDbusAddress="$4"
userLang="$5"
userLanguage="$6"

runAsUser() {
  su "$originalUser" -c "export DISPLAY='$userDisplay'; export XAUTHORITY='$userXauthority'; export DBUS_SESSION_BUS_ADDRESS='$userDbusAddress'; export LANG='$userLang'; export LC_ALL='$userLang'; export LANGUAGE='$userLanguage'; $1"
}

# Detect installed Ollama variants
installedPkgs=""
for pkg in ollama ollama-vulkan ollama-cuda ollama-rocm; do
  if pacman -Q "$pkg" &>/dev/null; then
    installedPkgs="$installedPkgs $pkg"
  fi
done

if [ -z "$installedPkgs" ]; then
  zenityText=$"No Ollama packages are installed. Enable an Ollama variant first."
  runAsUser "zenity --info --title=\"Ollama Update\" --text=\"$zenityText\""
  exit 0
fi

# Progress dialog via named pipe
pipePath="/tmp/ollama_update_pipe_$$"
mkfifo "$pipePath"

zenityTitle=$"Updating Ollama"
zenityText=$"Synchronizing repositories and updating Ollama, please wait..."
runAsUser "zenity --progress --title=\"$zenityTitle\" --text=\"$zenityText\" --pulsate --auto-close --no-cancel < '$pipePath'" &

updateTask() {
  pacman -Syu --needed --noconfirm $installedPkgs
  exitCode=$?
}
updateTask > "$pipePath"

rm "$pipePath"

if [[ "$exitCode" == "0" ]]; then
  zenityText=$"Ollama updated successfully!"
  runAsUser "zenity --info --text=\"$zenityText\""
else
  zenityText=$"Failed to update Ollama."
  zenity --error --text="$zenityText"
fi

exit $exitCode

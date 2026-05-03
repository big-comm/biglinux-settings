#!/bin/bash

# Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# Arguments
function="$1"
originalUser="$2"
userDisplay="$3"
userXauthority="$4"
userDbusAddress="$5"
userLang="$6"
userLanguage="$7"

runAsUser() {
  su "$originalUser" -c "export DISPLAY='$userDisplay'; export XAUTHORITY='$userXauthority'; export DBUS_SESSION_BUS_ADDRESS='$userDbusAddress'; export LANG='$userLang'; export LC_ALL='$userLang'; export LANGUAGE='$userLanguage'; $1"
}

# Progress dialog via named pipe
pipePath="/tmp/openclaude_pipe_$$"
mkfifo "$pipePath"

if [[ "$function" == "install" ]]; then
  zenityTitle=$"OpenClaude Install"
  zenityText=$"Installing OpenClaude (nodejs, npm, ripgrep required), please wait..."
else
  zenityTitle=$"OpenClaude Uninstall"
  zenityText=$"Uninstalling OpenClaude, please wait..."
fi
runAsUser "zenity --progress --title=\"$zenityTitle\" --text=\"$zenityText\" --pulsate --auto-close --no-cancel < '$pipePath'" &

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
installTask > "$pipePath" 2>&1

rm "$pipePath"

if [[ "$exitCode" == "0" ]]; then
  if [[ "$function" == "install" ]]; then
    zenityText=$"OpenClaude installed successfully!\n\nRun 'openclaude' in a terminal to start."
    runAsUser "zenity --info --text=\"$zenityText\""
  else
    zenityText=$"OpenClaude removed successfully!"
    runAsUser "zenity --info --text=\"$zenityText\""
  fi
else
  zenityText=$"An error occurred with OpenClaude."
  zenity --error --text="$zenityText"
fi

exit $exitCode

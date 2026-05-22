#!/bin/bash

#Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# Assign the received arguments to variables with clear names
function="$1"
originalUser="$2"
userDisplay="$3"
userXauthority="$4"
userDbusAddress="$5"
userLang="$6"
userLanguage="$7"

# Helper function to run a command as the original user
source "/usr/share/biglinux/biglinux-settings/lib/run-as-user.sh"

# Creates a named pipe (FIFO) for communication with Zenity
pipePath="/tmp/example_pipe_$$"
mkfifo "$pipePath"

# Starts Zenity IN THE BACKGROUND, as the user, with the full environment
if [[ "$function" == "install" ]]; then
  zenityTitle=$"Example Install"
  zenityText=$"Instaling Example, Please wait..."
else
  zenityTitle=$"Example Uninstall"
  zenityText=$"Uninstaling Example, Please wait..."
fi
runAsUser "zenity --progress --title=\"$zenityTitle\" --text=\"$zenityText\" --pulsate --auto-close --no-cancel < '$pipePath'" &

# Executes the root tasks.
updateTask() {
  if [[ "$function" == "install" ]]; then
    pacman -Syu --noconfirm example
    systemctl enable --now example.service
  else
    pacman -Rcs --noconfirm example
    systemctl disable --now example.service
  fi
  exitCode=$?
}
updateTask > "$pipePath"

# Cleans up the pipe
rm "$pipePath"

# Shows the final result to the user, also with the correct theme.
if [[ "$exitCode" == "0" ]] && [[ "$function" == "install" ]]; then
  zenityText=$"Example installed successfully!"
  runAsUser "zenity --info --text=\"$zenityText\""
else
  zenityText=$"Failed to install Example!"
  zenity --info --text="$zenityText"
fi

# Exits the script with the correct exit code
exit $exitCode

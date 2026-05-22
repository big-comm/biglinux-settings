#!/bin/bash

#Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# Assign the received arguments to variables with clear names
timeout="$1"
originalUser="$2"
userDisplay="$3"
userXauthority="$4"
userDbusAddress="$5"
userLang="$6"
userLanguage="$7"

# Helper function to run a command as the original user
source "/usr/share/biglinux/biglinux-settings/lib/run-as-user.sh"

# 1. Creates a named pipe (FIFO) for communication with Zenity
pipePath="/tmp/grub_pipe_$$"
mkfifo "$pipePath"

# 2. Starts Zenity IN THE BACKGROUND, as the user, with the full environment
zenityText=$"Applying, please wait..."
runAsUser "zenity --progress --title='grub' --text=\"$zenityText\" --pulsate --auto-close --no-cancel < '$pipePath'" &

# 3. Executes the root tasks.
updateGrubTask() {
  sed --follow-symlinks -i "/^GRUB_TIMEOUT=/s/=.*/=$timeout/" /etc/default/grub
  update-grub > "$pipePath"
}
updateGrubTask
exitCode=$?

# 4. Cleans up the pipe
rm "$pipePath"

# 5. Shows the final result to the user, also with the correct theme.
if [[ "$exitCode" -eq 0 ]]; then
  zenityText=$"GRUB updated successfully!"
  runAsUser "zenity --info --text=\"$zenityText\""
else
  zenityText=$"An error occurred while updating GRUB."
  runAsUser "zenity --error --text=\"$zenityText\""
fi

# 6. Exits the script with the correct exit code
exit $exitCode

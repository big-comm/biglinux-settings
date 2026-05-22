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
LIMITS_FILE="/etc/security/limits.d/99-biglinux-settings.conf"

# Helper function to run a command as the original user
source "/usr/share/biglinux/biglinux-settings/lib/run-as-user.sh"

# 1. Creates a named pipe (FIFO) for communication with Zenity
pipePath="/tmp/limits_pipe_$$"
mkfifo "$pipePath"

# 2. Starts Zenity IN THE BACKGROUND, as the user, with the full environment
zenityText=$"Applying, please wait..."
runAsUser "zenity --progress --title='Limits' --text=\"$zenityText\" --pulsate --auto-close --no-cancel < '$pipePath'" &

# 3. Executes the root tasks.
updateLimitsTask() {
  if [[ "$function" == "enable" ]]; then
    install -d -m 0755 /etc/security/limits.d
    {
      echo '@audio - rtprio 90'
      echo '@audio - memlock unlimited'
    } > "$LIMITS_FILE"
    chmod 0644 "$LIMITS_FILE"
  else
    rm -f "$LIMITS_FILE"
  fi
}
updateLimitsTask > "$pipePath"
exitCode=$?

# 4. Cleans up the pipe
rm "$pipePath"

# 5. Shows the final result to the user
if [[ "$exitCode" -eq 0 ]]; then
  zenityText=$"Limits updated successfully!"
  runAsUser "zenity --info --text=\"$zenityText\""
else
  zenityText=$"An error occurred while updating Limits."
  runAsUser "zenity --error --text=\"$zenityText\""
fi

# 6. Exits the script with the correct exit code
exit $exitCode

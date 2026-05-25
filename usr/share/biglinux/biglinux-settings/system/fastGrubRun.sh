#!/bin/bash

#Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# Assign the received arguments to variables with clear names
timeout="$1"

# Executes the root tasks.
updateGrubTask() {
  sed --follow-symlinks -i "/^GRUB_TIMEOUT=/s/=.*/=$timeout/" /etc/default/grub
  update-grub
}
updateGrubTask
exitCode=$?

# Exits the script with the correct exit code
exit $exitCode

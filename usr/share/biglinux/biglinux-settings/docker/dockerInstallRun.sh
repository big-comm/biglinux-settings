#!/bin/bash

#Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# Assign the received arguments to variables with clear names
function="$1"
package="$2"
packageName="$3"
port="$4"
originalUser="$5"

# Executes the root tasks.
managePackage() {
  if [[ "$function" == "install" ]]; then
    # Update database and install
    pacman -Syu --needed --noconfirm "$package"
    chown $originalUser: /home/$originalUser/Docker
  elif [[ "$function" == "remove" ]]; then
    # Remove package
    pacman -Rcs --noconfirm "$package"
  fi
  exitCode=$?
}
managePackage

# Exits the script
exit $exitCode

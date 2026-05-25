#!/bin/bash

#Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# Assign the received arguments to variables with clear names
function="$1"

# Executes the root tasks.
updateDockerTask() {
  if [[ "$function" == "install" ]]; then
    pacman -Syu --noconfirm biglinux-docker-config
  elif [[ "$function" == "enable" ]]; then
    systemctl enable --now docker.service
    systemctl start docker.socket
    chmod 666 /var/run/docker.sock
  elif [[ "$function" == "disable" ]]; then
    systemctl disable --now docker.service
    systemctl stop docker.socket
  fi
  exitCode=$?
}
updateDockerTask

# Exits the script with the correct exit code
exit $exitCode

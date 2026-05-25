#!/bin/bash
package="biglinux-docker-nextcloud-plus"
packageName="nextcloud-plus"
port="8286"

# check current status
if [ "$1" == "check" ]; then
  if pacman -Q "$package" &> /dev/null; then
      echo "true"
  else
      echo "false"
  fi

# change the state
elif [ "$1" == "toggle" ]; then
  state="$2"
  if [ "$state" == "true" ]; then
    pkexec /usr/share/biglinux/biglinux-settings/docker/dockerInstallRun.sh "install" "$package" "$packageName" "$port" "$USER" "$DISPLAY" "$XAUTHORITY" "$DBUS_SESSION_BUS_ADDRESS" "$LANG" "$LANGUAGE"
    exitCode=$?
  else
    pkexec /usr/share/biglinux/biglinux-settings/docker/dockerInstallRun.sh "remove" "$package" "$packageName" "$port" "$USER" "$DISPLAY" "$XAUTHORITY" "$DBUS_SESSION_BUS_ADDRESS" "$LANG" "$LANGUAGE"
    exitCode=$?
  fi
  exit $exitCode
fi

#!/bin/bash

runAsUser() {
  local command="$1"
  local pkexec_user
  local user_home

  if [[ -z "$originalUser" || "$originalUser" == "root" ]]; then
    return 1
  fi

  if [[ -n "$PKEXEC_UID" ]]; then
    pkexec_user="$(id -nu "$PKEXEC_UID" 2>/dev/null)" || return 1
    if [[ "$originalUser" != "$pkexec_user" ]]; then
      return 1
    fi
  fi

  if ! id -u "$originalUser" >/dev/null 2>&1; then
    return 1
  fi

  user_home="$(getent passwd "$originalUser" | cut -d: -f6)"
  if [[ -z "$user_home" ]]; then
    user_home="/home/$originalUser"
  fi

  runuser -u "$originalUser" -- env \
    HOME="$user_home" \
    DISPLAY="$userDisplay" \
    XAUTHORITY="$userXauthority" \
    DBUS_SESSION_BUS_ADDRESS="$userDbusAddress" \
    LANG="$userLang" \
    LC_ALL="$userLang" \
    LANGUAGE="$userLanguage" \
    bash -c "$command"
}

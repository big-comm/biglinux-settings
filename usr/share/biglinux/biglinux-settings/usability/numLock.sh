#!/bin/bash

desktop="${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-}}"
desktop="${desktop^^}"
sddm_conf="${NUMLOCK_SDDM_CONF:-/etc/sddm.conf}"
sddm_conf_dir="${NUMLOCK_SDDM_CONF_DIR:-/etc/sddm.conf.d}"

is_de() {
  [[ "$desktop" == *"$1"* ]]
}

has_gsetting() {
  gsettings range "$1" "$2" >/dev/null 2>&1
}

set_gsetting_bool() {
  local schema="$1"
  local key="$2"
  local value="$3"

  if ! has_gsetting "$schema" "$key"; then
    return 1
  fi

  gsettings set "$schema" "$key" "$value" >/dev/null 2>&1 || return 1
  [[ "$(gsettings get "$schema" "$key" 2>/dev/null)" == "$value" ]]
}

get_first_gsetting_bool() {
  local key="$1"
  local schema
  shift

  for schema in "$@"; do
    if has_gsetting "$schema" "$key"; then
      gsettings get "$schema" "$key" 2>/dev/null
      return 0
    fi
  done

  return 1
}

set_first_gsetting_bool() {
  local key="$1"
  local value="$2"
  local schema
  shift 2

  for schema in "$@"; do
    if has_gsetting "$schema" "$key"; then
      set_gsetting_bool "$schema" "$key" "$value"
      return $?
    fi
  done

  return 1
}

run_numlockx() {
  command -v numlockx >/dev/null 2>&1 || return 0
  numlockx "$1" >/dev/null 2>&1 || true
}

sddm_numlock_on() {
  local files=()
  local file line value

  [ -f "$sddm_conf" ] && files+=("$sddm_conf")
  shopt -s nullglob
  files+=("$sddm_conf_dir"/*.conf)
  shopt -u nullglob

  for file in "${files[@]}"; do
    while IFS= read -r line; do
      line="${line%%#*}"
      line="${line,,}"
      if [[ "$line" =~ ^[[:space:]]*numlock[[:space:]]*=[[:space:]]*(on|off)[[:space:]]*$ ]]; then
        value="${BASH_REMATCH[1]}"
      fi
    done < "$file"
  done

  [[ "$value" == "on" ]]
}

kde_user_numlock_value() {
  command -v kreadconfig6 >/dev/null 2>&1 || return 1
  LANG=C kreadconfig6 --group Keyboard --key "NumLock" --file "$HOME/.config/kcminputrc" 2>/dev/null
}

kde_user_numlock_on() {
  [[ "$(kde_user_numlock_value)" == "0" ]]
}

write_kde_user_numlock() {
  local value="$1"
  command -v kwriteconfig6 >/dev/null 2>&1 || return 1
  kwriteconfig6 --group Keyboard --key "NumLock" --file "$HOME/.config/kcminputrc" "$value" || return 1
  [[ "$(kde_user_numlock_value)" == "$value" ]]
}

verify_kde_numlock_state() {
  local expected="$1"

  if [ "$expected" == "true" ]; then
    sddm_numlock_on || kde_user_numlock_on
  else
    ! sddm_numlock_on && ! kde_user_numlock_on
  fi
}

write_xfce_autostart() {
  local numlockx_path

  numlockx_path="$(command -v numlockx)" || return 1
  mkdir -p "$HOME/.config/autostart" || return 1
  cat > "$HOME/.config/autostart/numlockx.desktop" << EOF
[Desktop Entry]
Type=Application
Name=NumLock On
Exec=$numlockx_path on
NoDisplay=true
X-XFCE-Autostart-Override=true
EOF
}

xfce_autostart_enabled() {
  local desktop_file="$HOME/.config/autostart/numlockx.desktop"
  local numlockx_path

  [ -f "$desktop_file" ] || return 1
  ! grep -q "Hidden=true" "$desktop_file" 2>/dev/null || return 1
  numlockx_path="$(command -v numlockx)" || return 1
  grep -qxF "Exec=$numlockx_path on" "$desktop_file"
}

if [ "$1" == "check" ]; then
  if is_de "KDE" || is_de "PLASMA"; then
    if sddm_numlock_on || kde_user_numlock_on; then
      echo "true"
    else
      echo "false"
    fi
  elif is_de "GNOME"; then
    value="$(get_first_gsetting_bool numlock-state \
      org.gnome.desktop.peripherals.keyboard \
      org.gnome.settings-daemon.peripherals.keyboard)"
    if [ $? -ne 0 ]; then
      echo "unsupported"
    elif [[ "$value" == "true" ]]; then
      echo "true"
    else
      echo "false"
    fi
  elif is_de "XFCE"; then
    if ! command -v numlockx >/dev/null 2>&1; then
      echo "unsupported"
    elif xfce_autostart_enabled; then
      echo "true"
    else
      echo "false"
    fi
  elif is_de "CINNAMON"; then
    value="$(get_first_gsetting_bool numlock-state \
      org.cinnamon.desktop.peripherals.keyboard \
      org.cinnamon.settings-daemon.peripherals.keyboard)"
    if [ $? -ne 0 ]; then
      echo "unsupported"
    elif [[ "$value" == "true" ]]; then
      echo "true"
    else
      echo "false"
    fi
  else
    echo "unsupported"
  fi

elif [ "$1" == "toggle" ]; then
  state="$2"

  if is_de "KDE" || is_de "PLASMA"; then
    if [ "$state" == "true" ]; then
      pkexec /usr/share/biglinux/biglinux-settings/usability/numLockRun.sh enable || exit $?
      write_kde_user_numlock "0" || exit $?
      run_numlockx on
    else
      pkexec /usr/share/biglinux/biglinux-settings/usability/numLockRun.sh disable || exit $?
      write_kde_user_numlock "1" || exit $?
      run_numlockx off
    fi
    verify_kde_numlock_state "$state" || exit 1
  elif is_de "GNOME"; then
    if [ "$state" == "true" ]; then
      set_first_gsetting_bool remember-numlock-state true \
        org.gnome.desktop.peripherals.keyboard \
        org.gnome.settings-daemon.peripherals.keyboard || true
      set_first_gsetting_bool numlock-state true \
        org.gnome.desktop.peripherals.keyboard \
        org.gnome.settings-daemon.peripherals.keyboard || exit $?
      run_numlockx on
    else
      set_first_gsetting_bool remember-numlock-state true \
        org.gnome.desktop.peripherals.keyboard \
        org.gnome.settings-daemon.peripherals.keyboard || true
      set_first_gsetting_bool numlock-state false \
        org.gnome.desktop.peripherals.keyboard \
        org.gnome.settings-daemon.peripherals.keyboard || exit $?
      run_numlockx off
    fi
  elif is_de "XFCE"; then
    if [ "$state" == "true" ]; then
      write_xfce_autostart || exit $?
      run_numlockx on
    else
      rm -f "$HOME/.config/autostart/numlockx.desktop" || exit $?
      run_numlockx off
    fi
  elif is_de "CINNAMON"; then
    if [ "$state" == "true" ]; then
      set_first_gsetting_bool remember-numlock-state true \
        org.cinnamon.desktop.peripherals.keyboard \
        org.cinnamon.settings-daemon.peripherals.keyboard || true
      set_first_gsetting_bool numlock-state true \
        org.cinnamon.desktop.peripherals.keyboard \
        org.cinnamon.settings-daemon.peripherals.keyboard || exit $?
      run_numlockx on
    else
      set_first_gsetting_bool remember-numlock-state true \
        org.cinnamon.desktop.peripherals.keyboard \
        org.cinnamon.settings-daemon.peripherals.keyboard || true
      set_first_gsetting_bool numlock-state false \
        org.cinnamon.desktop.peripherals.keyboard \
        org.cinnamon.settings-daemon.peripherals.keyboard || exit $?
      run_numlockx off
    fi
  else
    exit 1
  fi
fi

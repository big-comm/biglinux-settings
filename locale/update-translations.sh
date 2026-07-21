#!/bin/bash
set -euo pipefail

repoDir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repoDir"

temporaryDir="$(mktemp -d)"
trap 'rm -rf -- "$temporaryDir"' EXIT

mapfile -t pythonFiles < <(rg --files usr/share/biglinux/biglinux-settings -g '*.py' | sort)
mapfile -t shellFiles < <(rg --files usr/share/biglinux/biglinux-settings -g '*.sh' | sort)

if [[ -z "${SOURCE_DATE_EPOCH:-}" ]]; then
  sourceDateEpoch=0
  for sourceFile in "${pythonFiles[@]}" "${shellFiles[@]}"; do
    fileEpoch="$(stat -c %Y "$sourceFile")"
    if ((fileEpoch > sourceDateEpoch)); then
      sourceDateEpoch="$fileEpoch"
    fi
  done
  export SOURCE_DATE_EPOCH="$sourceDateEpoch"
fi

xgettext \
  --language=Python \
  --from-code=UTF-8 \
  --keyword=_ \
  --keyword=ngettext:1,2 \
  --sort-by-file \
  --package-name=biglinux-settings \
  --output="$temporaryDir/python.pot" \
  "${pythonFiles[@]}"

xgettext \
  --language=Shell \
  --from-code=UTF-8 \
  --keyword=gettext \
  --sort-by-file \
  --package-name=biglinux-settings \
  --output="$temporaryDir/shell.pot" \
  "${shellFiles[@]}"

msgcat --use-first --sort-by-file \
  "$temporaryDir/python.pot" "$temporaryDir/shell.pot" \
  --output=locale/biglinux-settings.pot

for poFile in locale/*.po; do
  language="$(basename "$poFile" .po)"
  if [[ "$language" == "en" ]]; then
    msgen locale/biglinux-settings.pot --output="$temporaryDir/en.po"
    mv "$temporaryDir/en.po" "$poFile"
  else
    msguniq --use-first "$poFile" --output="$temporaryDir/$language.po"
    msgmerge --quiet --no-fuzzy-matching \
      --lang="$language" \
      "$temporaryDir/$language.po" locale/biglinux-settings.pot \
      --output="$poFile"
  fi

  locale/normalize-po-header.py "$poFile" "$language" locale/biglinux-settings.pot

  moDir="usr/share/locale/$language/LC_MESSAGES"
  mkdir -p "$moDir"
  msgfmt --check "$poFile" --output-file="$moDir/biglinux-settings.mo"
done

"""Centralized configuration for biglinux-settings."""

import gettext
import locale
import os

APP_ID = "br.com.biglinux-settings"
DOMAIN = "biglinux-settings"

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
LOCALE_DIR = os.path.normpath(os.path.join(BASE_DIR, "..", "..", "locale"))
try:
    with open(os.path.join(BASE_DIR, "VERSION"), encoding="utf-8") as version_file:
        APP_VERSION = version_file.read().strip() or "development"
except OSError:
    APP_VERSION = "development"
ICONS_DIR = os.path.join(BASE_DIR, "icons")
CONFIG_DIR = os.path.expanduser("~/.config/biglinux-settings")
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")

try:
    locale.setlocale(locale.LC_ALL, "")
except locale.Error:
    locale.setlocale(locale.LC_ALL, "C")

locale.bindtextdomain(DOMAIN, LOCALE_DIR)
locale.textdomain(DOMAIN)

gettext.bindtextdomain(DOMAIN, LOCALE_DIR)
gettext.textdomain(DOMAIN)
_ = gettext.gettext
ngettext = gettext.ngettext

"""Centralized configuration for biglinux-settings."""

import gettext
import locale
import os

APP_VERSION = "1.1.0"
APP_ID = "br.com.biglinux-settings"
DOMAIN = "biglinux-settings"
LOCALE_DIR = "/usr/share/locale"

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ICONS_DIR = os.path.join(BASE_DIR, "icons")
CONFIG_DIR = os.path.expanduser("~/.config/biglinux-settings")
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")

locale.setlocale(locale.LC_ALL, "")
locale.bindtextdomain(DOMAIN, LOCALE_DIR)
locale.textdomain(DOMAIN)

gettext.bindtextdomain(DOMAIN, LOCALE_DIR)
gettext.textdomain(DOMAIN)
_ = gettext.gettext

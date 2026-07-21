"""Pytest configuration and shared fixtures for biglinux-settings tests."""

import sys
import os
from unittest.mock import MagicMock

# Mock GTK/GLib modules before any app code imports them
gi_mock = MagicMock()
gi_mock.require_version = MagicMock()

# Mock GObject introspection modules
for mod in [
    "gi",
    "gi.repository",
    "gi.repository.Gtk",
    "gi.repository.Adw",
    "gi.repository.Gio",
    "gi.repository.GLib",
    "gi.repository.Gdk",
]:
    sys.modules[mod] = MagicMock()

# Add source directory to path
SRC_DIR = os.path.join(
    os.path.dirname(os.path.dirname(__file__)),
    "usr",
    "share",
    "biglinux",
    "biglinux-settings",
)
sys.path.insert(0, SRC_DIR)

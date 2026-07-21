"""Tests for NetworkManager helpers."""

from network_manager import NetworkManager


def test_split_terse_keeps_escaped_colon():
    assert NetworkManager._split_terse(r"wlan0:wifi:connected:Home\:Office") == [
        "wlan0",
        "wifi",
        "connected",
        "Home:Office",
    ]


def test_split_terse_keeps_trailing_backslash():
    assert NetworkManager._split_terse(r"eth0:ethernet:connected:LAN\\") == [
        "eth0",
        "ethernet",
        "connected",
        "LAN\\",
    ]

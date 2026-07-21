"""Tests for config module."""

from config import APP_ID, DOMAIN, APP_VERSION


def test_app_id_format():
    """APP_ID should follow reverse-domain notation."""
    assert APP_ID.count(".") >= 2


def test_domain_not_empty():
    assert DOMAIN == "biglinux-settings"


def test_version_is_string():
    assert isinstance(APP_VERSION, str)
    assert len(APP_VERSION) > 0

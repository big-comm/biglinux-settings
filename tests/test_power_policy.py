"""Tests for automatic suspend policy persistence."""

import importlib.util
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = (
    ROOT / "usr/share/biglinux/biglinux-settings/sleep/power_policy.py"
)


@pytest.fixture
def policy_module(tmp_path, monkeypatch):
    spec = importlib.util.spec_from_file_location("power_policy", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    monkeypatch.setattr(module, "CONFIG_DIR", tmp_path / "config")
    return module


def test_gsettings_policy_restores_previous_values(policy_module, monkeypatch):
    values = {
        "sleep-inactive-ac-type": "'suspend'",
        "sleep-inactive-ac-timeout": "900",
    }

    def fake_run(command, check=True):
        if command[:2] == ["gsettings", "get"]:
            return subprocess.CompletedProcess(command, 0, values[command[3]] + "\n", "")
        if command[:2] == ["gsettings", "set"]:
            values[command[3]] = command[4]
        return subprocess.CompletedProcess(command, 0, "", "")

    monkeypatch.setattr(policy_module, "run", fake_run)
    monkeypatch.setattr(
        policy_module,
        "gsettings_keys",
        lambda _source: [
            ("org.gnome.settings-daemon.plugins.power", key) for key in values
        ],
    )

    original = values.copy()
    saved = policy_module.read_values("gsettings", "ac")
    policy_module.write_backup("ac", "gsettings", saved)
    policy_module.set_never("gsettings", "ac")

    assert policy_module.is_never("gsettings", "ac")
    policy_module.restore("ac", "gsettings")
    assert values == original


def test_kde_missing_value_is_deleted_on_restore(policy_module, monkeypatch):
    commands = []

    def fake_run(command, check=True):
        commands.append(command)
        return subprocess.CompletedProcess(command, 0, "", "")

    monkeypatch.setattr(policy_module, "run", fake_run)
    monkeypatch.setattr(policy_module, "refresh_kde", lambda: None)
    policy_module.write_backup(
        "battery",
        "kde",
        [
            {
                "file": "powerdevilrc",
                "groups": ["Battery", "SuspendAndShutdown"],
                "key": "AutoSuspendAction",
                "old_value": policy_module.MISSING,
            }
        ],
    )

    policy_module.restore("battery", "kde")
    assert commands[-1][-2:] == ["--delete", ""]


def test_kde_battery_idle_policy_covers_low_battery_profile(policy_module):
    items = policy_module.kde_keys("battery")

    assert {item["groups"][0] for item in items} == {"Battery", "LowBattery"}
    assert all(item["value"] == "0" for item in items)


def test_critical_policy_blocks_manual_battery_idle_restore(
    policy_module, monkeypatch
):
    policy_file = policy_module.CONFIG_DIR / "critical.conf"
    policy_file.parent.mkdir(parents=True)
    policy_file.write_text(
        "PercentageAction=20\n"
        "CriticalPowerAction=Suspend\n"
        "AllowRiskyCriticalPowerAction=true\n"
    )
    monkeypatch.setattr(policy_module, "CRITICAL_POLICY_FILE", policy_file)
    monkeypatch.setattr(policy_module, "backend", lambda: "gsettings")
    monkeypatch.setattr(policy_module.sys, "argv", ["power_policy.py", "toggle", "battery", "false"])

    assert policy_module.main() == 1

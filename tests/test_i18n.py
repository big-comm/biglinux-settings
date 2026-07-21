"""Tests for gettext catalog normalization."""

import importlib.util
from pathlib import Path

from config import LOCALE_DIR


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "locale/normalize-po-header.py"
SPEC = importlib.util.spec_from_file_location("normalize_po_header", MODULE_PATH)
normalize_po_header = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(normalize_po_header)


def test_locale_directory_tracks_the_source_or_installed_tree():
    assert Path(LOCALE_DIR).resolve() == ROOT / "usr/share/locale"


def test_replace_field_collapses_wrapped_duplicates_and_is_idempotent():
    source = '''msgid ""
msgstr ""
"Project-Id-Version: test\\n"
"POT-Creation-Date: 2026-01-01 00:00+0000\\n"
"Plural-Forms: nplurals=3; plural=(n==1 ? 0 : "
"n<5 ? 1 : 2);\\n"
"Plural-Forms: nplurals=3; plural=(n==1 ? 0 : "
"n<5 ? 1 : 2);\\n"

msgid "Example"
msgstr ""
'''
    value = "nplurals=3; plural=(n==1 ? 0 : n<5 ? 1 : 2);"

    normalized = normalize_po_header.replace_field(source, "Plural-Forms", value)

    assert normalized.count('"Plural-Forms:') == 1
    assert normalize_po_header.parse_header(normalized)["Plural-Forms"] == value
    assert normalize_po_header.replace_field(normalized, "Plural-Forms", value) == normalized


def test_replace_field_deduplicates_preserved_translator_metadata():
    source = '''msgid ""
msgstr ""
"POT-Creation-Date: 2026-01-01 00:00+0000\\n"
"Last-Translator: Existing Translator <translator@example.com>\\n"
"Last-Translator: Existing Translator <translator@example.com>\\n"

msgid "Example"
msgstr ""
'''

    normalized = normalize_po_header.replace_field(
        source,
        "Last-Translator",
        "BigLinux Community <community@biglinux.com.br>",
        only_placeholder=True,
    )

    assert normalized.count('"Last-Translator:') == 1
    assert (
        normalize_po_header.parse_header(normalized)["Last-Translator"]
        == "Existing Translator <translator@example.com>"
    )


def test_replace_field_handles_header_without_pot_creation_date():
    source = '''msgid ""
msgstr ""
"Project-Id-Version: test\\n"
"Language: bg\\n"

msgid "Example"
msgstr ""
'''

    normalized = normalize_po_header.replace_field(
        source,
        "PO-Revision-Date",
        "2026-07-21 22:00+0000",
    )

    assert (
        normalize_po_header.parse_header(normalized)["PO-Revision-Date"]
        == "2026-07-21 22:00+0000"
    )

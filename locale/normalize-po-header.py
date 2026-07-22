#!/usr/bin/python3
"""Normalize gettext header fields without touching translations."""

import ast
import json
import subprocess
import sys
from pathlib import Path


POT_DATE_FIELD = "POT-" + "Creation-Date"


def replace_field(text: str, field: str, value: str, only_placeholder: bool = False) -> str:
    marker = 'msgid ""\nmsgstr ""\n'
    marker_start = text.find(marker)
    if marker_start < 0:
        return text

    header_start = marker_start + len(marker)
    header_end = header_start
    quoted_lines = []
    for line in text[header_start:].splitlines(keepends=True):
        if not line.startswith('"'):
            break
        quoted_lines.append(line)
        header_end += len(line)

    decoded = "".join(ast.literal_eval(line.strip()) for line in quoted_lines)
    fields = [line for line in decoded.replace("\\n", "\n").splitlines() if line]
    prefix = f"{field}: "
    matches = [index for index, line in enumerate(fields) if line.startswith(prefix)]
    if matches and only_placeholder:
        current = fields[matches[0]][len(prefix) :]
        if "FULL NAME" not in current and "LANGUAGE" not in current:
            value = current

    if matches:
        insertion_index = matches[0]
        fields = [line for line in fields if not line.startswith(prefix)]
    else:
        pot_index = next(
            (
                index
                for index, line in enumerate(fields)
                if line.startswith(f"{POT_DATE_FIELD}: ")
            ),
            len(fields) - 1,
        )
        insertion_index = pot_index + 1

    fields.insert(insertion_index, f"{field}: {value}")
    rendered = "".join(json.dumps(line + "\n", ensure_ascii=False) + "\n" for line in fields)
    return text[:header_start] + rendered + text[header_end:]


def parse_header(text: str) -> dict[str, str]:
    marker = 'msgid ""\nmsgstr ""\n'
    start = text.find(marker)
    if start < 0:
        return {}
    values = []
    for line in text[start + len(marker) :].splitlines():
        if not line.startswith('"'):
            break
        values.append(ast.literal_eval(line))
    return dict(
        line.split(": ", 1)
        for line in "".join(values).splitlines()
        if ": " in line
    )


def plural_forms(language: str, pot_path: str) -> str:
    overrides = {
        "is": "nplurals=2; plural=(n%10!=1 || n%100==11);",
        "zh": "nplurals=1; plural=0;",
    }
    if language in overrides:
        return overrides[language]
    result = subprocess.run(
        [
            "msginit",
            "--no-translator",
            f"--locale={language}",
            f"--input={pot_path}",
            "--output-file=-",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    return parse_header(result.stdout)["Plural-Forms"]


def main() -> int:
    if len(sys.argv) != 4:
        return 2
    path = Path(sys.argv[1])
    language = sys.argv[2]
    pot_path = sys.argv[3]
    text = path.read_text(encoding="utf-8")
    revision = parse_header(text).get(
        POT_DATE_FIELD, "YEAR-MO-DA HO:MI+ZONE"
    )
    text = text.replace('#, fuzzy\nmsgid ""\nmsgstr ""', 'msgid ""\nmsgstr ""', 1)
    text = replace_field(text, "PO-Revision-Date", revision)
    text = replace_field(
        text,
        "Last-Translator",
        "BigLinux Community <community@biglinux.com.br>",
        only_placeholder=True,
    )
    text = replace_field(
        text,
        "Language-Team",
        f"BigLinux Community ({language})",
        only_placeholder=True,
    )
    text = replace_field(text, "Language", language)
    text = replace_field(text, "Plural-Forms", plural_forms(language, pot_path))
    path.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

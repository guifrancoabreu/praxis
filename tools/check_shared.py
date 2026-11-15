#!/usr/bin/env python3
"""Verify that cross-platform content lives in shared/ and is used from there.

The catalogs are consumed by the iOS app (bundled from ios/Praxis.xcodeproj) and, later,
by the Android app (Gradle assets pointing at the same directory). A catalog script that
still writes to the old ios/Praxis/Resources path would silently leave the app on stale
data, so this check fails the build instead.

Run from anywhere: python3 tools/check_shared.py
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG_DIR = ROOT / "shared" / "catalog"
READER_DIR = ROOT / "shared" / "reader"
READER_FILES = ["reader.css", "reader.js", "reader-link.js", "reader-progress.js", "reader-images.js"]
SCRIPTS = {
    "tools/build_catalog.py": "catalog-pt.json",
    "tools/build_catalog_en.py": "catalog-en.json",
    "tools/build_catalog_es.py": "catalog-es.json",
}
OUT_PATTERN = re.compile(r"^OUT\s*=\s*os\.path\.join\([^)]*\)", re.MULTILINE)
PATH_STRING = re.compile(r'"([^"]+)"')

errors: list[str] = []


def check_catalogs() -> None:
    if not CATALOG_DIR.is_dir():
        errors.append(f"missing directory: {CATALOG_DIR.relative_to(ROOT)}")
        return
    for name in sorted(SCRIPTS.values()):
        path = CATALOG_DIR / name
        if not path.is_file():
            errors.append(f"missing catalog: {path.relative_to(ROOT)}")
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            errors.append(f"unreadable catalog {path.relative_to(ROOT)}: {error}")
            continue
        if not isinstance(data, dict) or not isinstance(data.get("authors"), list):
            errors.append(f"catalog {path.relative_to(ROOT)} has no authors array")
        elif not data["authors"]:
            errors.append(f"catalog {path.relative_to(ROOT)} has an empty authors array")


def check_script_outputs() -> None:
    for script, catalog in SCRIPTS.items():
        path = ROOT / script
        if not path.is_file():
            errors.append(f"missing script: {script}")
            continue
        text = path.read_text(encoding="utf-8")
        if "ios/Praxis/Resources" in text or '"Praxis", "Resources"' in text:
            errors.append(f"{script} still points at the old ios/Praxis/Resources path")
        match = OUT_PATTERN.search(text)
        if not match:
            errors.append(f"{script} has no OUT assignment")
            continue
        parts = PATH_STRING.findall(match.group(0))
        if catalog not in parts:
            errors.append(f"{script} OUT does not end with {catalog}")
        if "shared" not in parts or "catalog" not in parts:
            errors.append(f"{script} OUT does not resolve under shared/catalog")


def check_reader() -> None:
    for name in READER_FILES:
        path = READER_DIR / name
        if not path.is_file():
            errors.append(f"missing reader asset: {path.relative_to(ROOT)}")
            continue
        if not path.read_text(encoding="utf-8").strip():
            errors.append(f"empty reader asset: {path.relative_to(ROOT)}")
    document = READER_DIR / "reader.js"
    if document.is_file():
        text = document.read_text(encoding="utf-8")
        for token in ["window.webkit", "messageHandlers"]:
            if token in text:
                errors.append(f"reader.js must stay platform-neutral but mentions {token}")
        for placeholder in ["__READER_CSS__", "__READER_LINK__", "__READER_PROGRESS__", "__READER_IMAGES__"]:
            if placeholder not in text:
                errors.append(f"reader.js is missing the {placeholder} placeholder")


def main() -> int:
    check_catalogs()
    check_reader()
    check_script_outputs()
    if errors:
        print("shared content check failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1
    print(f"shared content OK: {len(SCRIPTS)} catalogs and {len(READER_FILES)} reader assets")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

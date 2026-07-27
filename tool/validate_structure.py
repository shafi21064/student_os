#!/usr/bin/env python3
"""Lightweight project validation for environments without the Flutter SDK."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIRS = [ROOT / "lib", ROOT / "test"]
REQUIRED = [
    ROOT / "pubspec.yaml",
    ROOT / "lib" / "main.dart",
    ROOT / "lib" / "app" / "router.dart",
    ROOT / "setup.sh",
    ROOT / "ATTRIBUTIONS.md",
]

errors: list[str] = []
for path in REQUIRED:
    if not path.exists():
        errors.append(f"Missing required file: {path.relative_to(ROOT)}")

dart_files = sorted(path for directory in SOURCE_DIRS for path in directory.rglob("*.dart"))
if not dart_files:
    errors.append("No Dart source files found")

pairs = {"(": ")", "[": "]", "{": "}"}
closing = set(pairs.values())

for path in dart_files:
    text = path.read_text(encoding="utf-8")

    # Internal package imports must resolve to files in lib/.
    for match in re.finditer(r"package:studentos/([^'\"]+)", text):
        target = ROOT / "lib" / match.group(1)
        if not target.exists():
            errors.append(f"Broken import in {path.relative_to(ROOT)}: {match.group(0)}")

    # A pragmatic delimiter pass that ignores strings and comments well enough
    # for this generated source tree. Flutter analyze remains authoritative.
    stack: list[tuple[str, int]] = []
    quote: str | None = None
    escaped = False
    line_comment = False
    block_comment = False
    index = 0
    while index < len(text):
        char = text[index]
        nxt = text[index + 1] if index + 1 < len(text) else ""
        if line_comment:
            if char == "\n":
                line_comment = False
            index += 1
            continue
        if block_comment:
            if char == "*" and nxt == "/":
                block_comment = False
                index += 2
            else:
                index += 1
            continue
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            index += 1
            continue
        if char == "/" and nxt == "/":
            line_comment = True
            index += 2
            continue
        if char == "/" and nxt == "*":
            block_comment = True
            index += 2
            continue
        if char in {"'", '"'}:
            quote = char
        elif char in pairs:
            stack.append((char, index))
        elif char in closing:
            if not stack or pairs[stack[-1][0]] != char:
                errors.append(f"Delimiter mismatch in {path.relative_to(ROOT)} at offset {index}")
                break
            stack.pop()
        index += 1
    if stack:
        errors.append(f"Unclosed delimiter in {path.relative_to(ROOT)}")

pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8") if (ROOT / "pubspec.yaml").exists() else ""
for asset_dir in ("assets/reference/", "assets/branding/"):
    if asset_dir not in pubspec:
        errors.append(f"Asset directory not declared: {asset_dir}")
    if not (ROOT / asset_dir).exists():
        errors.append(f"Asset directory missing: {asset_dir}")

router = (ROOT / "lib" / "app" / "router.dart").read_text(encoding="utf-8") if (ROOT / "lib" / "app" / "router.dart").exists() else ""
route_count = len(re.findall(r"\bpath:\s*['\"]", router))
controller_count = len(list((ROOT / "lib").rglob("*_controller.dart")))

print(f"Dart files: {len(dart_files)}")
print(f"Routes: {route_count}")
print(f"Riverpod controller files: {controller_count}")

if errors:
    print("Structural validation failed:", file=sys.stderr)
    for error in errors:
        print(f"- {error}", file=sys.stderr)
    raise SystemExit(1)

print("Structural validation passed.")

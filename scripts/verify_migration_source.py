#!/usr/bin/env python3
"""Verify the active migration directory exactly matches the reviewed DB ledger manifest."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
directory = root / "supabase" / "migrations"
manifest_path = directory / "ledger.manifest"
expected = [line.strip() for line in manifest_path.read_text(encoding="utf-8").splitlines() if line.strip()]
actual = sorted(path.name for path in directory.glob("*.sql"))
pattern = re.compile(r"^(\d{14})_[a-z0-9_]+\.sql$")

invalid = [name for name in actual if not pattern.fullmatch(name)]
versions = [pattern.fullmatch(name).group(1) for name in actual if pattern.fullmatch(name)]
duplicates = sorted({version for version in versions if versions.count(version) > 1})
missing = sorted(set(expected) - set(actual))
unexpected = sorted(set(actual) - set(expected))
empty = sorted(path.name for path in directory.glob("*.sql") if path.stat().st_size == 0)

if invalid or duplicates or missing or unexpected or empty or expected != sorted(expected):
    if invalid: print("Invalid migration filenames:", *invalid, sep="\n  ")
    if duplicates: print("Duplicate migration versions:", *duplicates, sep="\n  ")
    if missing: print("Missing active migrations:", *missing, sep="\n  ")
    if unexpected: print("Unreviewed active migrations:", *unexpected, sep="\n  ")
    if empty: print("Empty migration files:", *empty, sep="\n  ")
    if expected != sorted(expected): print("ledger.manifest must be sorted by filename")
    sys.exit(1)

print(f"Migration source coverage verified: {len(actual)} active files, no gaps, no extras, no empty files.")

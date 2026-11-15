#!/usr/bin/env python3
"""Validate the recovered live migration archive without executing SQL."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / "supabase" / "live-schema-history"
ACTIVE = ROOT / "supabase" / "migrations"
EXPECTED_COUNT = 86
EXPECTED_FIRST = "20261102154652"
EXPECTED_LAST = "20261114204951"
EXPECTED_ACTIVE_ONLY = {"20261110120000"}
FILENAME = re.compile(r"^(?P<version>\d{14})_(?P<name>[A-Za-z0-9_-]+)\.sql$")


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    if not ARCHIVE.is_dir():
        fail(f"missing recovered archive: {ARCHIVE}")

    archive_files = sorted(ARCHIVE.glob("*.sql"))
    if len(archive_files) != EXPECTED_COUNT:
        fail(f"expected {EXPECTED_COUNT} archive files, found {len(archive_files)}")

    archive_by_version: dict[str, Path] = {}
    for path in archive_files:
        match = FILENAME.fullmatch(path.name)
        if match is None:
            fail(f"invalid archive filename: {path.name}")
        version = match.group("version")
        if version in archive_by_version:
            fail(f"duplicate archive version: {version}")
        if not path.read_text(encoding="utf-8").strip():
            fail(f"empty archived SQL: {path.name}")
        archive_by_version[version] = path

    versions = sorted(archive_by_version)
    if versions[0] != EXPECTED_FIRST or versions[-1] != EXPECTED_LAST:
        fail(f"unexpected archive version range: {versions[0]}..{versions[-1]}")

    active_files = sorted(ACTIVE.glob("*.sql"))
    active_by_version: dict[str, Path] = {}
    for path in active_files:
        match = FILENAME.fullmatch(path.name)
        if match is None:
            fail(f"invalid active migration filename: {path.name}")
        version = match.group("version")
        if version in active_by_version:
            fail(f"duplicate active migration version: {version}")
        active_by_version[version] = path

    active_only = set(active_by_version) - set(archive_by_version)
    if active_only != EXPECTED_ACTIVE_ONLY:
        fail(f"unexpected active-only migration versions: {sorted(active_only)}")

    shared = set(active_by_version) & set(archive_by_version)
    exact = {
        version for version in shared
        if active_by_version[version].read_bytes() == archive_by_version[version].read_bytes()
    }
    mismatched = shared - exact

    print(
        "Live migration archive verified: "
        f"{len(archive_files)} records ({EXPECTED_FIRST}..{EXPECTED_LAST}); "
        f"{len(active_files)} active files; "
        f"{len(shared)} shared version IDs; "
        f"{len(exact)} byte-identical shared files; "
        f"{len(mismatched)} shared files require SQL-content reconciliation; "
        f"{len(active_only)} active-only pending migration."
    )
    print(
        "NOTE: this check does not execute SQL, certify semantic equivalence, "
        "or prove a clean database replay."
    )


if __name__ == "__main__":
    main()

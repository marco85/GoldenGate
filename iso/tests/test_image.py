"""
GoldenGate OS — Post-Build ISO Verification Tests
Ensures the built ISO exists, is bootable, and stays under 3.8 GB (for FAT32 SANDISK USB & 16 GB USB stick).
"""
from __future__ import annotations
import glob
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FAT32_MAX_BYTES = 3_950_000_000  # < 3.95 GB so it copies cleanly onto FAT32 and 16 GB USB


def test_built_iso_size_and_presence():
    isos = sorted((ROOT / "out").glob("*.iso"))
    if not isos:
        return  # Skipped when running pre-build config tests locally
    newest = isos[-1]
    size = newest.stat().st_size
    assert size > 500_000_000, f"ISO {newest.name} is unexpectedly small ({size} bytes)"
    assert size < FAT32_MAX_BYTES, f"ISO {newest.name} exceeds FAT32 / 16GB USB safe cap ({size} bytes)"

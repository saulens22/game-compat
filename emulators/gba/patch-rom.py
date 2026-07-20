#!/usr/bin/env python3
"""Verify a local FireRed file and apply the official Radical Red UPS patch."""

from __future__ import annotations

import argparse
import hashlib
import io
import os
import struct
import urllib.request
import zlib
import zipfile
from pathlib import Path

PATCH_URL = "https://patch.radicalred.net/patches/4.1.zip"
PATCH_ZIP_SHA256 = "0413e4c4072fe03e909c65d737d94ef1bb30b91ef8c1b673c5b3e8c22e85102a"
SOURCE_MD5 = "e26ee0d44e809351c8ce2d73c7400cdd"
SOURCE_SHA1 = "41cb23d8dccc8ebd7c649cd8fbb58eeace6e2fdc"


def decode_vli(data: bytes, cursor: int) -> tuple[int, int]:
    value = 0
    shift = 0
    while True:
        byte = data[cursor]
        cursor += 1
        value += (byte & 0x7F) << shift
        if byte & 0x80:
            return value, cursor
        shift += 7
        value += 1 << shift


def apply_ups(source: bytes, patch: bytes) -> bytes:
    if not patch.startswith(b"UPS1") or len(patch) < 16:
        raise ValueError("not a valid UPS patch")
    expected_patch_crc = struct.unpack("<I", patch[-4:])[0]
    if zlib.crc32(patch[:-4]) & 0xFFFFFFFF != expected_patch_crc:
        raise ValueError("UPS patch CRC does not match")
    expected_source_crc, expected_output_crc = struct.unpack("<II", patch[-12:-4])
    if zlib.crc32(source) & 0xFFFFFFFF != expected_source_crc:
        raise ValueError("UPS patch rejects this source ROM")

    cursor = 4
    source_size, cursor = decode_vli(patch, cursor)
    output_size, cursor = decode_vli(patch, cursor)
    if source_size != len(source):
        raise ValueError(f"UPS expects {source_size} source bytes, got {len(source)}")
    output = bytearray(source[:output_size])
    output.extend(b"\0" * (output_size - len(output)))
    offset = 0
    while cursor < len(patch) - 12:
        relative, cursor = decode_vli(patch, cursor)
        offset += relative
        while patch[cursor] != 0:
            source_byte = source[offset] if offset < len(source) else 0
            output[offset] = source_byte ^ patch[cursor]
            offset += 1
            cursor += 1
        cursor += 1
        offset += 1
    if zlib.crc32(output) & 0xFFFFFFFF != expected_output_crc:
        raise ValueError("patched output CRC does not match UPS metadata")
    return bytes(output)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path, help="clean FireRed 1.0 USA input file")
    parser.add_argument(
        "--output", type=Path,
        default=Path(os.environ.get("EMULATION_ROOT", Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "game-compat/emulation")) / "roms/gba/Pokemon - Radical Red 4.1.gba",
    )
    args = parser.parse_args()
    source = args.source.read_bytes()
    if hashlib.md5(source).hexdigest() != SOURCE_MD5 or hashlib.sha1(source).hexdigest() != SOURCE_SHA1:
        raise SystemExit("Source rejected: expected the clean FireRed 1.0 USA dump documented in README.md")

    request = urllib.request.Request(PATCH_URL, headers={"User-Agent": "game-compat-radical-red"})
    with urllib.request.urlopen(request, timeout=30) as response:
        archive = response.read()
    if hashlib.sha256(archive).hexdigest() != PATCH_ZIP_SHA256:
        raise SystemExit("Official patch archive changed; review and update the documented version before using it")
    with zipfile.ZipFile(io.BytesIO(archive)) as bundle:
        patch = bundle.read("4.1.ups")
    output = apply_ups(source, patch)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.output.with_suffix(args.output.suffix + ".new")
    temporary.write_bytes(output)
    temporary.replace(args.output)
    print(f"Created: {args.output}")
    print(f"Output CRC32: {zlib.crc32(output) & 0xFFFFFFFF:08x}")
    print(f"Output SHA-256: {hashlib.sha256(output).hexdigest()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

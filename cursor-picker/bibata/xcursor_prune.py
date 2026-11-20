#!/usr/bin/env python3
"""Trim Material Bibata Xcursor bitmaps to the sizes this session uses.

Upstream ships 19 nominal sizes per shape (12-96 px): ~187 KB per shape and
~30 MB per theme. Keeping 24 and 48 px cuts a theme to well under 1 MB while
still covering a 24 px cursor and 2x scaling. Every trimmed file is re-loaded
through libXcursor before it is accepted.
"""

from __future__ import annotations

import argparse
import ctypes
import os
import struct
import sys

MAGIC = b"Xcur"
IMAGE = 0xFFFD0002


def parse(data: bytes):
    magic, header, version, ntoc = struct.unpack_from("<4sIII", data, 0)
    if magic != MAGIC:
        raise ValueError("not an Xcursor file")
    toc = sorted(
        (struct.unpack_from("<III", data, header + 12 * index) for index in range(ntoc)),
        key=lambda entry: entry[2],
    )
    entries = []
    for index, (kind, subtype, position) in enumerate(toc):
        end = toc[index + 1][2] if index + 1 < len(toc) else len(data)
        entries.append((kind, subtype, data[position:end]))
    return version, entries


def prune(path: str, sizes: set[int]) -> tuple[int, int]:
    with open(path, "rb") as handle:
        version, entries = parse(handle.read())
    keep = [entry for entry in entries if entry[0] == IMAGE and entry[1] in sizes]
    if not keep:
        return len(entries), 0
    table = bytearray()
    body = bytearray()
    offset = 16 + 12 * len(keep)
    for kind, subtype, chunk in keep:
        table += struct.pack("<III", kind, subtype, offset + len(body))
        body += chunk
    out = struct.pack("<4sIII", MAGIC, 16, version, len(keep)) + bytes(table) + bytes(body)
    temporary = f"{path}.prune.tmp"
    with open(temporary, "wb") as handle:
        handle.write(out)
    os.chmod(temporary, os.stat(path).st_mode & 0o777)
    os.replace(temporary, path)
    return len(entries), len(keep)


def xcursor_sizes(path: str) -> list[int] | None:
    lib = ctypes.CDLL("libXcursor.so.1")

    class Image(ctypes.Structure):
        _fields_ = [
            ("version", ctypes.c_uint),
            ("size", ctypes.c_uint),
            ("width", ctypes.c_uint),
            ("height", ctypes.c_uint),
            ("xhot", ctypes.c_uint),
            ("yhot", ctypes.c_uint),
            ("delay", ctypes.c_uint),
            ("pixels", ctypes.POINTER(ctypes.c_uint)),
        ]

    class Images(ctypes.Structure):
        _fields_ = [
            ("nimage", ctypes.c_int),
            ("images", ctypes.POINTER(ctypes.POINTER(Image))),
            ("name", ctypes.c_char_p),
        ]

    lib.XcursorFilenameLoadAllImages.restype = ctypes.POINTER(Images)
    lib.XcursorFilenameLoadAllImages.argtypes = [ctypes.c_char_p]
    lib.XcursorImagesDestroy.argtypes = [ctypes.POINTER(Images)]
    result = lib.XcursorFilenameLoadAllImages(os.fsencode(path))
    if not result:
        return None
    try:
        count = result.contents.nimage
        return sorted({result.contents.images[index].contents.size for index in range(count)})
    finally:
        lib.XcursorImagesDestroy(result)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("prune", "verify"):
        command = sub.add_parser(name)
        command.add_argument("directory")
        command.add_argument("--sizes", default="24,48")
    args = parser.parse_args()

    sizes = {int(size) for size in args.sizes.split(",") if size}
    labels = ",".join(str(size) for size in sorted(sizes))
    files = sorted(
        entry.path for entry in os.scandir(args.directory) if entry.is_file(follow_symlinks=False)
    )
    if not files:
        print(f"no cursor files in {args.directory}", file=sys.stderr)
        return 1

    name = os.path.basename(args.directory)

    if args.command == "prune":
        chunks = shapes = 0
        for path in files:
            before, after = prune(path, sizes)
            chunks += before
            shapes += after
        print(f"{name}: {len(files)} shapes, {chunks} chunks -> {shapes} at {labels} px")
        return 0

    failures = []
    for path in files:
        found = xcursor_sizes(path)
        if found != sorted(sizes):
            failures.append((os.path.basename(path), found))
    if failures:
        for filename, found in failures[:10]:
            print(f"invalid Xcursor data: {filename}: {found}", file=sys.stderr)
        return 1
    print(f"{name}: {len(files)} shapes verified via libXcursor at {labels} px")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

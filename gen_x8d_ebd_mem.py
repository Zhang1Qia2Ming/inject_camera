#!/usr/bin/env python3
"""Convert six packed CSI-2 RAW12 EBD lines to the UYVY-design AXIS ROM."""

import argparse
from pathlib import Path

LINES = 6
WIRE_BYTES_PER_LINE = 5760
PIXELS_PER_LINE = 3840
PIXELS_PER_BEAT = 4


def unpack_raw12(line: bytes) -> list[int]:
    """Decode CSI-2 RAW12: two 12-bit pixels in each three-byte group."""
    pixels: list[int] = []
    for index in range(0, len(line), 3):
        high0, high1, low = line[index : index + 3]
        pixels.append((high0 << 4) | (low & 0x0F))
        pixels.append((high1 << 4) | (low >> 4))
    return pixels


def axis_source_word(pixels: list[int]) -> int:
    """Build the low 56 bits of the MAX_BPC=14 RAW12 AXIS layout.

    PG260 specifies four 14-bit slots, with each 12-bit sample in slot
    bits [13:2].  The generator zero-extends this word onto the 168-bit
    mixed-format AXIS bus.
    """
    target = 0
    for slot, pixel in enumerate(pixels):
        target |= (pixel & 0xFFF) << (slot * 14 + 2)
    return target


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path, help="x8d.bin from the successful card")
    parser.add_argument("output", type=Path, help="Vivado readmemh output")
    args = parser.parse_args()

    packed = args.input.read_bytes()
    expected_size = LINES * WIRE_BYTES_PER_LINE
    if len(packed) != expected_size:
        raise ValueError(f"expected {expected_size} input bytes, got {len(packed)}")

    words: list[int] = []
    for line_index in range(LINES):
        begin = line_index * WIRE_BYTES_PER_LINE
        pixels = unpack_raw12(packed[begin : begin + WIRE_BYTES_PER_LINE])
        if len(pixels) != PIXELS_PER_LINE:
            raise AssertionError(f"line {line_index}: decoded {len(pixels)} pixels")
        for index in range(0, PIXELS_PER_LINE, PIXELS_PER_BEAT):
            words.append(axis_source_word(pixels[index : index + PIXELS_PER_BEAT]))

    args.output.write_text("".join(f"{word:016x}\n" for word in words))
    print(
        f"wrote {len(words)} beats "
        f"({len(words) // LINES} beats/line) to {args.output}"
    )


if __name__ == "__main__":
    main()

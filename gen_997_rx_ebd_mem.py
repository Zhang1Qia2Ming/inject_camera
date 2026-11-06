#!/usr/bin/env python3
"""Convert 997 NvSIPL-received OX08D EBD slots to RAW12 AXIS ROM words."""

import argparse
from pathlib import Path

LINES = 6
SLOTS_PER_LINE = 3840
SLOTS_PER_BEAT = 4


def raw12_axis_word(received_slots: list[int]) -> int:
    """Encode four receive-side uint16 slots as MAX_BPC=14 RAW12 samples.

    The 997 capture stores each EBD byte in the high byte of a little-endian
    uint16 slot. CSI RAW12 carries that byte as sample[11:4]. PG260 places
    each 12-bit sample in bits [13:2] of a 14-bit AXIS component slot.
    """
    word = 0
    for slot_index, received in enumerate(received_slots):
        sample = ((received >> 8) & 0xFF) << 4
        word |= sample << (slot_index * 14 + 2)
    return word


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "input",
        type=Path,
        help="one little-endian uint16 value per line from 997 NvSIPL",
    )
    parser.add_argument("output", type=Path, help="Vivado readmemh output")
    args = parser.parse_args()

    received = [
        int(line, 16)
        for line in args.input.read_text().splitlines()
        if line.strip()
    ]
    expected_slots = LINES * SLOTS_PER_LINE
    if len(received) != expected_slots:
        raise ValueError(
            f"expected {expected_slots} received slots, got {len(received)}"
        )

    words = [
        raw12_axis_word(received[index : index + SLOTS_PER_BEAT])
        for index in range(0, len(received), SLOTS_PER_BEAT)
    ]
    args.output.write_text("".join(f"{word:016x}\n" for word in words))
    print(
        f"wrote {len(words)} beats "
        f"({len(words) // LINES} beats/line) to {args.output}"
    )


if __name__ == "__main__":
    main()

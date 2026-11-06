#!/usr/bin/env python3
"""Preserve six 997 UYVY reserved rows as 64-bit FPGA ROM words."""

import argparse
from pathlib import Path

LINES = 6
SLOTS_PER_LINE = 3840
SLOTS_PER_BEAT = 4


def pack_uyvy_word(received_slots: list[int]) -> int:
    """Pack four consecutive uint16 slots without reinterpreting the bytes."""
    if len(received_slots) != SLOTS_PER_BEAT:
        raise ValueError(f"expected {SLOTS_PER_BEAT} slots")
    word = 0
    for slot_index, received in enumerate(received_slots):
        if not 0 <= received <= 0xFFFF:
            raise ValueError(f"slot out of range: {received}")
        word |= received << (slot_index * 16)
    return word


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "input",
        type=Path,
        help="one uint16 slot per line from the 997 NvSIPL UYVY surface",
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
        pack_uyvy_word(received[index : index + SLOTS_PER_BEAT])
        for index in range(0, len(received), SLOTS_PER_BEAT)
    ]
    args.output.write_text("".join(f"{word:016x}\n" for word in words))
    print(
        f"wrote {len(words)} UYVY beats "
        f"({len(words) // LINES} beats/line) to {args.output}"
    )


if __name__ == "__main__":
    main()

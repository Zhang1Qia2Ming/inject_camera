#!/usr/bin/env python3

import unittest

from gen_997_uyvy_reserved_mem import pack_uyvy_word


class UyvyReservedMemTest(unittest.TestCase):
    def test_preserves_four_received_u16_slots_byte_for_byte(self):
        self.assertEqual(
            pack_uyvy_word([0xDA00, 0x3600, 0x0000, 0x4F00]),
            0x4F0000003600DA00,
        )

    def test_rejects_non_four_slot_input(self):
        with self.assertRaises(ValueError):
            pack_uyvy_word([0xDA00])


if __name__ == "__main__":
    unittest.main()

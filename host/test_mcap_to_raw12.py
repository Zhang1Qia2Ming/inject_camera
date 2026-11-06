#!/usr/bin/env python3

import unittest

import numpy as np

import mcap_to_raw12


def unpack_raw12(data):
    packed = np.frombuffer(data, dtype=np.uint8).reshape(-1, 3)
    p0 = packed[:, 0].astype(np.uint16)
    p0 |= (packed[:, 1] & 0x0F).astype(np.uint16) << 8
    p1 = (packed[:, 1] >> 4).astype(np.uint16)
    p1 |= packed[:, 2].astype(np.uint16) << 4
    pixels = np.empty(p0.size + p1.size, dtype=np.uint16)
    pixels[0::2] = p0
    pixels[1::2] = p1
    return pixels


class PackBayerBggrTest(unittest.TestCase):
    def test_maps_rgb_components_to_bggr_positions(self):
        rgb = np.array(
            [
                [[1, 2, 3], [4, 5, 6]],
                [[7, 8, 9], [10, 11, 12]],
            ],
            dtype=np.uint8,
        )

        packed = mcap_to_raw12.pack_bayer_bggr(rgb)

        self.assertEqual(unpack_raw12(packed).tolist(), [48, 80, 128, 160])


if __name__ == "__main__":
    unittest.main()

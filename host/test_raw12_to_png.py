#!/usr/bin/env python3

import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

import numpy as np

import mcap_to_raw12
import raw12_to_png


class Raw12ToPngTest(unittest.TestCase):
    def test_unpack_restores_bggr_samples(self):
        rgb = np.array(
            [
                [[1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12]],
                [[13, 14, 15], [16, 17, 18], [19, 20, 21], [22, 23, 24]],
                [[25, 26, 27], [28, 29, 30], [31, 32, 33], [34, 35, 36]],
                [[37, 38, 39], [40, 41, 42], [43, 44, 45], [46, 47, 48]],
            ],
            dtype=np.uint8,
        )
        packed = mcap_to_raw12.pack_bayer_bggr(rgb)

        bayer = raw12_to_png.unpack_raw12(packed, width=4, height=4)

        expected = np.array(
            [
                [3, 5, 9, 11],
                [14, 16, 20, 22],
                [27, 29, 33, 35],
                [38, 40, 44, 46],
            ],
            dtype=np.uint16,
        ) << 4
        np.testing.assert_array_equal(bayer, expected)

    def test_frame_name_is_zero_padded_and_orderable(self):
        self.assertEqual(raw12_to_png.frame_name(0), "000000.png")
        self.assertEqual(raw12_to_png.frame_name(1197), "001197.png")

    def test_bggr_preview_preserves_red_and_blue_channels(self):
        rgb = np.zeros((8, 8, 3), dtype=np.uint8)
        rgb[:] = [200, 100, 50]
        packed = mcap_to_raw12.pack_bayer_bggr(rgb)
        bayer = raw12_to_png.unpack_raw12(packed, width=8, height=8)

        bgr = raw12_to_png.bayer_bggr_to_bgr8(bayer)

        np.testing.assert_array_equal(bgr[3, 3], [50, 100, 200])

    def test_pending_frames_support_resume(self):
        with TemporaryDirectory() as directory:
            Path(directory, "000000.png").touch()
            Path(directory, "000002.png").touch()

            pending = raw12_to_png.pending_frame_indices(directory, 4)

            self.assertEqual(pending, [1, 3])


if __name__ == "__main__":
    unittest.main()

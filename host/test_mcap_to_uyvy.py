#!/usr/bin/env python3

import subprocess
import unittest

from mcap_formats import UYVY422, build_decode_command


class UyvyFormatTest(unittest.TestCase):
    def test_format_size_and_ffmpeg_pixel_format(self):
        self.assertEqual(UYVY422.frame_bytes(3840, 2160), 16_588_800)
        cmd = build_decode_command("input.h265", UYVY422, 3840, 2160)
        self.assertIn("uyvy422", cmd)

    def test_ffmpeg_packs_u_y0_v_y1(self):
        # 2x2 YUV420P: Y=[10,20;30,40], U=50, V=60.
        source = bytes([10, 20, 30, 40, 50, 60])
        cmd = [
            "ffmpeg", "-hide_banner", "-loglevel", "error",
            "-f", "rawvideo", "-pixel_format", "yuv420p",
            "-video_size", "2x2", "-i", "-",
            "-frames:v", "1", "-pix_fmt", "uyvy422",
            "-f", "rawvideo", "-",
        ]
        result = subprocess.run(
            cmd, input=source, stdout=subprocess.PIPE, check=True)
        self.assertEqual(
            result.stdout,
            bytes([50, 10, 60, 20, 50, 30, 60, 40]),
        )


if __name__ == "__main__":
    unittest.main()

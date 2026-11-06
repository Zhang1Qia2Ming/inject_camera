#!/usr/bin/env python3

from dataclasses import dataclass

import numpy as np


@dataclass(frozen=True)
class FormatSpec:
    name: str
    suffix: str
    decode_pix_fmt: str
    decoded_bytes_per_pixel: int
    output_bits_per_pixel: int

    def decoded_frame_bytes(self, width, height):
        return width * height * self.decoded_bytes_per_pixel

    def frame_bytes(self, width, height):
        return width * height * self.output_bits_per_pixel // 8


RAW12_BGGR = FormatSpec("raw12", ".raw", "rgb24", 3, 12)
UYVY422 = FormatSpec("uyvy422", ".uyvy", "uyvy422", 2, 16)
FORMAT_SPECS = {
    RAW12_BGGR.name: RAW12_BGGR,
    UYVY422.name: UYVY422,
}


def build_decode_command(h265_path, spec, width, height):
    return [
        "ffmpeg",
        "-hide_banner",
        "-loglevel",
        "error",
        "-vsync",
        "0",
        "-f",
        "hevc",
        "-i",
        str(h265_path),
        "-an",
        "-vf",
        "scale=%d:%d:flags=bilinear" % (width, height),
        "-pix_fmt",
        spec.decode_pix_fmt,
        "-f",
        "rawvideo",
        "-",
    ]


def pack_bayer_bggr(rgb):
    image = rgb.astype(np.uint16) << 4
    height, width = image.shape[:2]
    bayer = np.empty((height, width), np.uint16)
    bayer[0::2, 0::2] = image[0::2, 0::2, 2]
    bayer[0::2, 1::2] = image[0::2, 1::2, 1]
    bayer[1::2, 0::2] = image[1::2, 0::2, 1]
    bayer[1::2, 1::2] = image[1::2, 1::2, 0]
    p0 = bayer[:, 0::2]
    p1 = bayer[:, 1::2]
    packed = np.empty((height, width * 3 // 2), np.uint8)
    packed[:, 0::3] = (p0 & 0xFF).astype(np.uint8)
    packed[:, 1::3] = (
        ((p0 >> 8) & 0x0F) | ((p1 & 0x0F) << 4)
    ).astype(np.uint8)
    packed[:, 2::3] = ((p1 >> 4) & 0xFF).astype(np.uint8)
    return packed.tobytes()

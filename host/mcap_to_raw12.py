#!/usr/bin/env python3
"""Split the three camera topics out of an mcap and pack RAW12 frames.

TX1 / h2c_0: /sensor/camera_forward_far/orig/h265     front 30 deg
TX2 / h2c_1: /sensor/camera_forward_wide/orig/h265    front 120 deg
TX4 / h2c_2: /sensor/camera_backward/orig/h265        rear 120 deg

Each output frame is 3840x2160 BGGR, 12 bits per pixel, tightly packed
little-endian, 12,441,600 bytes. pcie_raw12 sends one frame per write().
"""

import argparse
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import numpy as np
from mcap.reader import make_reader

FRAME_W = 3840
FRAME_H = 2160
FRAME_BYTES = FRAME_W * FRAME_H * 12 // 8
RGB_BYTES = FRAME_W * FRAME_H * 3

LANES = (
    ("tx1_forward_far.raw", "/sensor/camera_forward_far/orig/h265", "TX1 front 30"),
    ("tx2_forward_wide.raw", "/sensor/camera_forward_wide/orig/h265", "TX2 front 120"),
    ("tx4_backward.raw", "/sensor/camera_backward/orig/h265", "TX4 rear 120"),
)


def annexb_payload(message):
    data = message.data
    start = data.find(b"\x00\x00\x00\x01")
    if start < 0:
        return None
    return data[start:]


def has_vps(payload):
    index = 0
    while True:
        start = payload.find(b"\x00\x00\x00\x01", index)
        if start < 0 or start + 4 >= len(payload):
            return False
        nal_type = (payload[start + 4] >> 1) & 0x3F
        if nal_type == 32:
            return True
        index = start + 4


def write_h265(mcap_path, topic, h265_path):
    count = 0
    skipped = 0
    started = False
    with open(mcap_path, "rb") as src, open(h265_path, "wb") as dst:
        reader = make_reader(src)
        for _schema, _channel, message in reader.iter_messages(topics=[topic]):
            payload = annexb_payload(message)
            if payload is None:
                skipped += 1
                continue
            if not started:
                if not has_vps(payload):
                    skipped += 1
                    continue
                started = True
            dst.write(payload)
            count += 1
    return count, skipped


def pack_bayer_bggr(rgb):
    image = rgb.astype(np.uint16) << 4
    bayer = np.empty((FRAME_H, FRAME_W), np.uint16)
    bayer[0::2, 0::2] = image[0::2, 0::2, 2]
    bayer[0::2, 1::2] = image[0::2, 1::2, 1]
    bayer[1::2, 0::2] = image[1::2, 0::2, 1]
    bayer[1::2, 1::2] = image[1::2, 1::2, 0]
    p0 = bayer[:, 0::2]
    p1 = bayer[:, 1::2]
    packed = np.empty((FRAME_H, FRAME_W * 3 // 2), np.uint8)
    packed[:, 0::3] = (p0 & 0xFF).astype(np.uint8)
    packed[:, 1::3] = (((p0 >> 8) & 0x0F) | ((p1 & 0x0F) << 4)).astype(np.uint8)
    packed[:, 2::3] = ((p1 >> 4) & 0xFF).astype(np.uint8)
    return packed.tobytes()


def decode_to_raw(h265_path, raw_path):
    cmd = [
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
        "scale=%d:%d:flags=bilinear" % (FRAME_W, FRAME_H),
        "-pix_fmt",
        "rgb24",
        "-f",
        "rawvideo",
        "-",
    ]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    frames = 0
    with open(raw_path, "wb") as out:
        while True:
            blob = proc.stdout.read(RGB_BYTES)
            if len(blob) == 0:
                break
            if len(blob) != RGB_BYTES:
                proc.kill()
                raise RuntimeError(
                    "%s: short rgb frame %d bytes" % (h265_path, len(blob))
                )
            rgb = np.frombuffer(blob, dtype=np.uint8).reshape(FRAME_H, FRAME_W, 3)
            packed = pack_bayer_bggr(rgb)
            if len(packed) != FRAME_BYTES:
                raise RuntimeError("packed frame is %d bytes" % len(packed))
            out.write(packed)
            frames += 1
            if frames % 50 == 0:
                print("%s frames %d" % (raw_path.name, frames), flush=True)
    err = proc.stderr.read().decode("utf-8", "replace")
    code = proc.wait()
    if code != 0:
        raise RuntimeError("ffmpeg failed (%d): %s" % (code, err.strip()))
    return frames


def convert_lane(mcap, out_dir, tmp, name, topic, label):
    h265_path = tmp / (name + ".h265")
    raw_path = out_dir / name
    print("extract", label, topic, flush=True)
    packets, skipped = write_h265(mcap, topic, h265_path)
    print(
        "  %s packets %d skipped %d h265 %d"
        % (label, packets, skipped, h265_path.stat().st_size),
        flush=True,
    )
    if packets == 0:
        raise RuntimeError("no packets in " + topic)
    frames = decode_to_raw(h265_path, raw_path)
    size = raw_path.stat().st_size
    print("  %s %d frames %d bytes" % (label, frames, size), flush=True)
    if frames == 0 or size != frames * FRAME_BYTES:
        raise RuntimeError("bad raw size %d for %s" % (size, label))
    return frames


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mcap")
    parser.add_argument("out_dir")
    args = parser.parse_args()
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    tmp = Path("/tmp/mcap_h265")
    tmp.mkdir(parents=True, exist_ok=True)

    with ThreadPoolExecutor(max_workers=3) as pool:
        futures = [
            pool.submit(convert_lane, args.mcap, out_dir, tmp, name, topic, label)
            for name, topic, label in LANES
        ]
        for future in futures:
            future.result()
    print("ALL_LANES_DONE", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())

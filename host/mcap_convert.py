#!/usr/bin/env python3
"""Convert the three camera H.265 topics in an MCAP to injection frames."""

import argparse
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import numpy as np
from mcap.reader import make_reader

from mcap_formats import (
    FORMAT_SPECS,
    RAW12_BGGR,
    build_decode_command,
    pack_bayer_bggr,
)

FRAME_W = 3840
FRAME_H = 2160

LANES = (
    ("tx1_forward_far", "/sensor/camera_forward_far/orig/h265", "TX1 front 30"),
    ("tx2_forward_wide", "/sensor/camera_forward_wide/orig/h265", "TX2 front 120"),
    ("tx4_backward", "/sensor/camera_backward/orig/h265", "TX4 rear 120"),
)


def annexb_payload(message):
    start = message.data.find(b"\x00\x00\x00\x01")
    return None if start < 0 else message.data[start:]


def has_vps(payload):
    index = 0
    while True:
        start = payload.find(b"\x00\x00\x00\x01", index)
        if start < 0 or start + 4 >= len(payload):
            return False
        if ((payload[start + 4] >> 1) & 0x3F) == 32:
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


def read_exact(stream, count):
    chunks = []
    remaining = count
    while remaining:
        chunk = stream.read(remaining)
        if not chunk:
            break
        chunks.append(chunk)
        remaining -= len(chunk)
    return b"".join(chunks)


def decode_to_frames(h265_path, output_path, spec):
    command = build_decode_command(h265_path, spec, FRAME_W, FRAME_H)
    process = subprocess.Popen(
        command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    decoded_bytes = spec.decoded_frame_bytes(FRAME_W, FRAME_H)
    output_bytes = spec.frame_bytes(FRAME_W, FRAME_H)
    frames = 0
    with open(output_path, "wb") as output:
        while True:
            blob = read_exact(process.stdout, decoded_bytes)
            if not blob:
                break
            if len(blob) != decoded_bytes:
                process.kill()
                raise RuntimeError(
                    "%s: short decoded frame %d/%d bytes"
                    % (h265_path, len(blob), decoded_bytes)
                )
            if spec is RAW12_BGGR:
                rgb = np.frombuffer(blob, dtype=np.uint8).reshape(
                    FRAME_H, FRAME_W, 3)
                packed = pack_bayer_bggr(rgb)
            else:
                packed = blob
            if len(packed) != output_bytes:
                process.kill()
                raise RuntimeError(
                    "%s: packed frame %d/%d bytes"
                    % (output_path, len(packed), output_bytes)
                )
            output.write(packed)
            frames += 1
            if frames % 50 == 0:
                print("%s frames %d" % (output_path.name, frames), flush=True)

    error = process.stderr.read().decode("utf-8", "replace")
    code = process.wait()
    if code != 0:
        raise RuntimeError("ffmpeg failed (%d): %s" % (code, error.strip()))
    return frames


def convert_lane(mcap_path, out_dir, tmp_dir, spec, stem, topic, label):
    h265_path = tmp_dir / (stem + ".h265")
    output_path = out_dir / (stem + spec.suffix)
    print("extract", label, topic, flush=True)
    packets, skipped = write_h265(mcap_path, topic, h265_path)
    print(
        "  %s packets %d skipped %d h265 %d"
        % (label, packets, skipped, h265_path.stat().st_size),
        flush=True,
    )
    if packets == 0:
        raise RuntimeError("no packets in " + topic)
    frames = decode_to_frames(h265_path, output_path, spec)
    size = output_path.stat().st_size
    expected = frames * spec.frame_bytes(FRAME_W, FRAME_H)
    print("  %s %d frames %d bytes" % (label, frames, size), flush=True)
    if frames == 0 or size != expected:
        raise RuntimeError("bad output size %d for %s" % (size, label))
    return frames


def convert_mcap(mcap_path, out_dir, format_name):
    spec = FORMAT_SPECS[format_name]
    output = Path(out_dir)
    output.mkdir(parents=True, exist_ok=True)
    tmp = Path("/tmp/mcap_h265")
    tmp.mkdir(parents=True, exist_ok=True)
    with ThreadPoolExecutor(max_workers=3) as pool:
        futures = [
            pool.submit(
                convert_lane, mcap_path, output, tmp, spec, stem, topic, label)
            for stem, topic, label in LANES
        ]
        return [future.result() for future in futures]


def main(argv=None, default_format=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("mcap")
    parser.add_argument("out_dir")
    parser.add_argument(
        "--format",
        choices=sorted(FORMAT_SPECS),
        default=default_format or "raw12",
    )
    args = parser.parse_args(argv)
    convert_mcap(args.mcap, args.out_dir, args.format)
    print("ALL_LANES_DONE", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())

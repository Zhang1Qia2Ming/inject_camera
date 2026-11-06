#!/usr/bin/env python3
"""Decode packed 3840x2160 BGGR RAW12 frames into ordered PNG files."""

import argparse
from concurrent.futures import ProcessPoolExecutor, as_completed
import sys
from pathlib import Path

import cv2
import numpy as np

FRAME_W = 3840
FRAME_H = 2160


def frame_name(index):
    return "{:06d}.png".format(index)


def pending_frame_indices(output_dir, frame_count):
    output_dir = Path(output_dir)
    return [
        index for index in range(frame_count)
        if not (output_dir / frame_name(index)).is_file()
    ]


def unpack_raw12(data, width=FRAME_W, height=FRAME_H):
    expected = width * height * 3 // 2
    if len(data) != expected:
        raise ValueError("RAW12 frame is {} bytes, expected {}".format(
            len(data), expected))
    packed = np.frombuffer(data, dtype=np.uint8).reshape(-1, 3)
    p0 = packed[:, 0].astype(np.uint16)
    p0 |= (packed[:, 1] & 0x0F).astype(np.uint16) << 8
    p1 = (packed[:, 1] >> 4).astype(np.uint16)
    p1 |= packed[:, 2].astype(np.uint16) << 4
    bayer = np.empty(p0.size + p1.size, dtype=np.uint16)
    bayer[0::2] = p0
    bayer[1::2] = p1
    return bayer.reshape(height, width)


def bayer_bggr_to_bgr8(bayer):
    bgr16 = cv2.cvtColor(bayer, cv2.COLOR_BayerRG2BGR)
    return (bgr16 >> 4).clip(0, 255).astype(np.uint8)


_WORKER_SOURCE = None
_WORKER_OUTPUT = None
_WORKER_WIDTH = None
_WORKER_HEIGHT = None
_WORKER_COMPRESSION = None


def _init_worker(raw_path, output_dir, width, height, compression):
    global _WORKER_SOURCE, _WORKER_OUTPUT
    global _WORKER_WIDTH, _WORKER_HEIGHT, _WORKER_COMPRESSION
    cv2.setNumThreads(1)
    _WORKER_SOURCE = open(raw_path, "rb")
    _WORKER_OUTPUT = Path(output_dir)
    _WORKER_WIDTH = width
    _WORKER_HEIGHT = height
    _WORKER_COMPRESSION = compression


def _convert_frame(index):
    frame_bytes = _WORKER_WIDTH * _WORKER_HEIGHT * 3 // 2
    _WORKER_SOURCE.seek(index * frame_bytes)
    data = _WORKER_SOURCE.read(frame_bytes)
    bayer = unpack_raw12(data, _WORKER_WIDTH, _WORKER_HEIGHT)
    image = bayer_bggr_to_bgr8(bayer)
    output = _WORKER_OUTPUT / frame_name(index)
    temporary = _WORKER_OUTPUT / (frame_name(index) + ".tmp.png")
    if not cv2.imwrite(
            str(temporary), image,
            [cv2.IMWRITE_PNG_COMPRESSION, _WORKER_COMPRESSION]):
        raise RuntimeError("failed to write {}".format(output))
    temporary.replace(output)
    return index


def convert_file(raw_path, output_dir, width=FRAME_W, height=FRAME_H,
                 compression=1, workers=1):
    raw_path = Path(raw_path)
    output_dir = Path(output_dir)
    frame_bytes = width * height * 3 // 2
    size = raw_path.stat().st_size
    if size == 0 or size % frame_bytes:
        raise ValueError("{} size {} is not a multiple of {}".format(
            raw_path, size, frame_bytes))
    frame_count = size // frame_bytes
    output_dir.mkdir(parents=True, exist_ok=True)
    for temporary in output_dir.glob("*.tmp.png"):
        temporary.unlink()
    pending = pending_frame_indices(output_dir, frame_count)
    completed = frame_count - len(pending)
    if completed:
        print("{}: resuming with {}/{} already complete".format(
            raw_path.name, completed, frame_count), flush=True)
    if pending:
        with ProcessPoolExecutor(
                max_workers=workers,
                initializer=_init_worker,
                initargs=(str(raw_path), str(output_dir), width, height,
                          compression)) as pool:
            futures = [pool.submit(_convert_frame, index) for index in pending]
            for future in as_completed(futures):
                future.result()
                completed += 1
                if completed % 25 == 0 or completed == frame_count:
                    print("{}: {}/{}".format(
                        raw_path.name, completed, frame_count), flush=True)
    return frame_count


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("raw")
    parser.add_argument("output_dir")
    parser.add_argument("--width", type=int, default=FRAME_W)
    parser.add_argument("--height", type=int, default=FRAME_H)
    parser.add_argument("--compression", type=int, choices=range(10), default=1)
    parser.add_argument("--workers", type=int, default=1)
    args = parser.parse_args()
    if args.workers < 1:
        parser.error("--workers must be at least 1")
    count = convert_file(
        args.raw, args.output_dir, args.width, args.height, args.compression,
        args.workers)
    print("DONE {} frames -> {}".format(count, args.output_dir), flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())

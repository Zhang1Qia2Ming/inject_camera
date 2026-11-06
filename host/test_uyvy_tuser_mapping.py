#!/usr/bin/env python3
from pathlib import Path


root = Path(__file__).resolve().parents[1]
source = (
    root / "project_1.srcs/sources_1/new/mipi_gen_uyvy.v"
).read_text()
normalized = " ".join(source.split())
expected = (
    "assign tuser = { 26'b0, 6'h1e, "
    "BYTE_NUM[15:0], "
    "{3'b0, line_count}, frame_number, 15'b0, "
    "(pixel_count == 13'd1) && (line_count == 13'd1) };"
)

assert expected in normalized, (
    "mipi_gen must present the existing AXIS subset converter contract: "
    "datatype in input [69:64], word count [63:48], line [47:32], "
    "frame [31:16], frame start [0]. The converter maps datatype to "
    "PG260 TUSER[6:1]."
)
assert "6'h2c" not in normalized
assert "997_uyvy_reserved_64.mem" in source
assert "output [95:0] video_out_tdata" in normalized
assert "output [95:0] video2_tdata" in normalized
assert "output [95:0] video4_tdata" in normalized
print("PASS test_uyvy_tuser_mapping")

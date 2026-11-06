#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
coe = root / "project_1.srcs/sources_1/coe/data_uyvy.coe"
create_tcl = (root / "create_uyvy_bd.tcl").read_text()
build_tcl = (root / "build_uyvy.tcl").read_text()
bd = (
    root
    / "project_1.srcs/sources_1/bd/design_uyvy/design_uyvy.bd"
).read_text()

assert coe.exists(), "UYVY must use an independent CSI-TX register image"
values = [
    line.strip()
    for line in coe.read_text().splitlines()
    if line.strip() and not line.startswith("memory_")
]
assert values[1] == "00000000000000001110000000011011", (
    "CSI-TX protocol register must be 0xE01B: quad-pixel/four-lane with "
    "LS/LE generation enabled"
)
assert "data.coe" in create_tcl and "data_uyvy.coe" in create_tcl
assert bd.count("../../../../coe/data_uyvy.coe") == 3
for lane in range(3):
    run = f"design_uyvy_axi_traffic_gen_{lane}_0_synth_1"
    assert run in build_tcl, f"build must invalidate stale ATG OOC run {run}"

print("PASS test_uyvy_no_line_sync")

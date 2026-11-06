#!/usr/bin/env python3
from pathlib import Path


root = Path(__file__).resolve().parents[1]
script = (root / "create_uyvy_bd.tcl").read_text()
build = (root / "build_uyvy.tcl").read_text()

assert "CONFIG.S_TDATA_NUM_BYTES {12}" in script
assert "CONFIG.M_TDATA_NUM_BYTES {12}" in script
assert "CONFIG.TDATA_REMAP {tdata[95:0]}" in script
assert (
    "CONFIG.TUSER_REMAP "
    "{tuser[95:70],6'b0,tuser[63:16],9'b0,tuser[69:64],tuser[0]}"
) in script
assert "CONFIG.C_CSI_DATATYPE {YUV422_8b}" in script
assert "CONFIG.C_CSI_MAX_BPC {8}" in script
assert "CONFIG.C_CSI_AXIS_TDATA_WIDTH {96}" in script
assert 'CONFIG.C_CSI_DATATYPE $csi] ne "YUV422_8b"' in build
assert 'CONFIG.C_CSI_MAX_BPC $csi] != 8' in build
assert 'CONFIG.C_CSI_AXIS_TDATA_WIDTH $csi] != 96' in build
assert "UYVY_TUSER_REMAP_VERIFIED" in build
assert "RAW12" not in script[script.index("# Keep one"):], (
    "pure UYVY block-design override must not restore RAW12"
)
print("PASS test_uyvy_bd_mapping")

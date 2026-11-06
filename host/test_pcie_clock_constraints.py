from pathlib import Path


xdc = (Path(__file__).parents[1] / "project_1.srcs/constrs_1/new/pcie.xdc").read_text()
build_tcl = (Path(__file__).parents[1] / "build_uyvy.tcl").read_text()

expected_locations = {
    "bufg_gt_coreclk": "BUFG_GT_X0Y36",
    "bufg_gt_intclk": "BUFG_GT_X0Y46",
    "bufg_gt_mcapclk": "BUFG_GT_X0Y45",
    "bufg_gt_pclk": "BUFG_GT_X0Y44",
    r"gen_cpll_cal_inst\[0\].*bufg_gt_txoutclkmon_inst": "BUFG_GT_X0Y28",
    r"gen_cpll_cal_inst\[1\].*bufg_gt_txoutclkmon_inst": "BUFG_GT_X0Y39",
    r"gen_cpll_cal_inst\[2\].*bufg_gt_txoutclkmon_inst": "BUFG_GT_X0Y24",
    r"gen_cpll_cal_inst\[3\].*bufg_gt_txoutclkmon_inst": "BUFG_GT_X0Y41",
}

assert "\nproc " not in xdc
assert "DESIGN_MODE" not in xdc
assert "get_cells -hierarchical -regexp" in xdc
for cell_pattern, location in expected_locations.items():
    assert cell_pattern in xdc, cell_pattern
    assert location in xdc, location

assert "PCIE_IMPL_LOC_VERIFIED" in build_tcl
assert "INCREMENTAL_CHECKPOINT" in build_tcl
assert "impl_uyvy_mipi_diag" in build_tcl

print("PASS test_pcie_clock_constraints")

#!/usr/bin/env python3
from pathlib import Path
import re


script = (Path(__file__).resolve().parents[1] / "build_uyvy.tcl").read_text()
ooc_run = "design_uyvy_mipi_gen_0_0_synth_1"
reset = f"reset_run ${ooc_run}"

run_lookup = re.compile(
    rf"set\s+{ooc_run}\s+\\?\s*\[get_runs\s+-quiet\s+{ooc_run}\]"
)
assert run_lookup.search(script), (
    "build does not resolve the mipi_gen UYVY out-of-context synthesis run"
)
assert reset in script, "build can reuse a stale mipi_gen UYVY OOC netlist"
assert script.index(reset) < script.index("generate_target all $bd"), (
    "mipi_gen UYVY OOC run must be reset before BD output generation"
)
print("PASS test_uyvy_ooc_refresh")

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VIVADO_SETTINGS="${VIVADO_SETTINGS:-/data/xilinx/Vivado/2020.2/settings64.sh}"
SIM_ROOT="$(mktemp -d /tmp/uyvy_xsim.XXXXXX)"
trap 'rm -rf "$SIM_ROOT"' EXIT

# shellcheck disable=SC1090
source "$VIVADO_SETTINGS"

run_test() {
    local top="$1"
    shift
    mkdir -p "$SIM_ROOT/$top"
    cd "$SIM_ROOT/$top"
    cp "$ROOT/project_1.srcs/sources_1/new/997_uyvy_reserved_64.mem" .
    cp "$ROOT/project_1.srcs/sim_1/new/997_sensor8_ebd_u16.mem" .
    xvlog "$@"
    xvlog -sv "$ROOT/project_1.srcs/sim_1/new/${top}.v"
    xelab "$top" -s "${top}_sim"
    xsim "${top}_sim" -runall | tee xsim.log
    if rg -q '^FAIL' xsim.log; then
        return 1
    fi
    rg -q "^PASS ${top}" xsim.log
}

run_test tb_uyvy_gearbox \
    "$ROOT/project_1.srcs/sources_1/new/uyvy_gearbox.v"

run_test tb_lane_uyvy \
    "$ROOT/project_1.srcs/sources_1/new/pulse_sync.v" \
    "$ROOT/project_1.srcs/sources_1/new/frame_slot.v" \
    "$ROOT/project_1.srcs/sources_1/new/h2c_line_adapt.v" \
    "$ROOT/project_1.srcs/sources_1/new/uyvy_gearbox.v" \
    "$ROOT/project_1.srcs/sources_1/new/lane_inject_uyvy.v"

run_test tb_mipi_gen_uyvy \
    "$ROOT/project_1.srcs/sources_1/new/mipi_gen_uyvy.v"

run_test tb_mipi_gen_uyvy_reserved_rom \
    "$ROOT/project_1.srcs/sources_1/new/mipi_gen_uyvy.v"

run_test tb_mipi_line_gap_diag \
    "$ROOT/project_1.srcs/sources_1/new/mipi_gen_uyvy.v"

# H2C First-Beat Buffer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Eliminate the first-frame H2C/S2MM startup deadlock without changing the external `lane_inject` interface.

**Architecture:** A one-beat register accepts the first H2C beat before S2MM is armed. The RTL pulses fsync, waits 16 H2C clocks, forwards the buffered beat to `h2c_line_adapt`, then transparently streams the rest of the frame.

**Tech Stack:** Verilog, XSim, Vivado 2020.2 Tcl, JTAG Hardware Manager, XSDB, Linux XDMA.

## Global Constraints

- Preserve VIO fsync override and the existing 48-bit debug layout.
- Do not overwrite SD `BOOT.bin`.
- Do not hot-plug PCIe.
- Do not commit Git changes.

---

### Task 1: Reproduce the ready-before-valid deadlock

**Files:**
- Create: `project_1.srcs/sim_1/new/tb_lane_h2c_ready_first.v`
- Use: `project_1.srcs/sources_1/new/lane_inject.v`

- [ ] Create a testbench whose source keeps `h2c_tvalid=0` until
  `h2c_tready=1`, then transmits a two-line frame.
- [ ] Assert that exactly one fsync occurs, no S2MM beat occurs before fsync,
  and all eight input beats arrive unchanged.
- [ ] Run XSim against the current RTL and require failure with
  `host never observed ready`.

### Task 2: Implement the one-beat first-beat buffer

**Files:**
- Modify: `project_1.srcs/sources_1/new/lane_inject.v`

- [ ] Add IDLE, WAIT_ARM, FORWARD_FIRST and STREAM state.
- [ ] In IDLE, expose ready only when `wr_ready` and the one-beat buffer is empty.
- [ ] On the first handshake, store `h2c_tdata/tlast`, pulse fsync and start the 16-cycle wait.
- [ ] Multiplex the buffered first beat into `h2c_line_adapt`; after it is accepted, pass subsequent H2C beats directly.
- [ ] Return to IDLE only on `wr_done`, `wr_abort` or reset.
- [ ] Preserve debug signal meanings and VIO fsync behavior.

### Task 3: Run RTL regressions

**Files:**
- Test: `project_1.srcs/sim_1/new/tb_lane_h2c_ready_first.v`
- Test: `project_1.srcs/sim_1/new/tb_lane_s2mm_arm.v`
- Test: `project_1.srcs/sim_1/new/tb_mipi_pcie.v`

- [ ] Run the new test and require `TB_PASS`, eight beats, one fsync and fsync before S2MM.
- [ ] Run the existing S2MM arm test and require `TB_PASS`.
- [ ] Run the full frame-slot/gearbox/MIPI regression and require `PASS`.

### Task 4: Build the JTAG image

**Files:**
- Use: `impl_inject_debug.tcl`
- Output: `project_1.runs/impl_tx2/design_1_wrapper.bit`
- Output: `project_1.runs/impl_tx2/design_1_wrapper.ltx`

- [ ] Validate the BD diagnostic clocks and connections.
- [ ] Run synthesis and implementation through bitstream generation.
- [ ] Require `write_bitstream Complete!`, zero route errors and non-negative setup/hold timing.

### Task 5: JTAG hardware verification

- [ ] Program the generated bitstream through JTAG without modifying SD.
- [ ] Restart the A53 bare-metal initialization so CSI TX and all three VDMAs are configured.
- [ ] Restore Gen3 x4, BAR0, bus-master command and load XDMA with `h2c_timeout=3`.
- [ ] Run three diagnostic RAW12 lanes until each exceeds 30 completed frames.
- [ ] Capture ILA and require sticky fsync, H2C handshake, S2MM handshake,
  `wr_start`, `wr_done`, TLAST and no abort.
- [ ] Confirm all six VDMA channels remain running with zero error bits.

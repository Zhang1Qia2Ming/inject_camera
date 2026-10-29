# S2MM Safe Debug Implementation Plan

> **For agentic workers:** Execute each task in order and preserve the verified SD BOOT image.

**Goal:** Safely observe lane 0 S2MM startup and first-frame events without clocking ILA/VIO from XDMA `axi_aclk`.

**Architecture:** `pcie_diag` converts lane 0 pulses into sticky bits in the XDMA clock domain and synchronizes a compact status vector into PS `pl_clk0`. The existing ILA remains on `pl_clk0`; the existing low 32-bit PCIe diagnostics remain unchanged.

**Tech Stack:** Verilog, XSim, Vivado 2020.2 Tcl, JTAG Hardware Manager, XSDB, XDMA Linux driver.

## Global Constraints

- Observe lane 0 only.
- Do not overwrite SD `BOOT.bin`.
- Do not hot-plug PCIe.
- Do not commit Git changes.
- Preserve PCIe Gen3 x4 cold-start behavior.

---

### Task 1: RTL regression test and diagnostic bridge

**Files:**
- Modify: `project_1.srcs/sim_1/new/tb_pcie_diag.v`
- Modify: `project_1.srcs/sources_1/new/pcie_diag.v`

- [ ] Extend the testbench with lane 0 debug inputs and short event pulses.
- [ ] Run XSim before the RTL change and verify failure because the new interface/status does not exist.
- [ ] Add source-domain sticky events and two-stage destination-domain synchronization.
- [ ] Run XSim and require `TB_PASS`, including preserved PCIe low bits and all lane event assertions.

### Task 2: Block Design and CDC constraints

**Files:**
- Modify: `connect_pcie_diag.tcl`
- Modify: `impl_inject_debug.tcl`
- Modify: `project_1.srcs/constrs_1/new/pcie.xdc`

- [ ] Connect `lane_inject_0/dbg_bus` to `pcie_diag_0/lane_dbg_bus`.
- [ ] Keep ILA/VIO/diagnostic output clocked by `pl_clk0`.
- [ ] Add a precise false path only to first-stage lane diagnostic synchronizers.
- [ ] Validate BD and generated wrapper structure.

### Task 3: Build and static verification

- [ ] Run synthesis and implementation through bitstream generation.
- [ ] Require implementation completion, zero route errors, non-negative setup/hold timing, and successful debug-core discovery from the generated LTX.
- [ ] Check lints for edited RTL and Tcl files.

### Task 4: JTAG-only hardware test

- [ ] Program the new bitstream through JTAG without changing SD.
- [ ] Confirm PCIe remains Gen3 x4 and endpoint/MMIO IDs remain valid.
- [ ] Load XDMA with `h2c_timeout=3`.
- [ ] Send exactly one RAW12 frame to H2C channel 0.
- [ ] Capture ILA and decode `fsync`, ready, handshakes, completion/abort to identify the first blocking stage.

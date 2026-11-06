# Build the independent UYVY422 implementation without overwriting RAW12 runs.

set root [file dirname [file normalize [info script]]]
open_project [file join $root project_1.xpr]

set bd [get_files -quiet design_uyvy.bd]
if {$bd eq ""} {
  error "design_uyvy.bd is missing; run create_uyvy_bd.tcl first"
}

# Module-reference OOC runs are not invalidated reliably when their RTL
# changes. Reset mipi_gen explicitly so implementation cannot reuse an older
# TUSER layout from design_uyvy_mipi_gen_0_0_synth_1.
set design_uyvy_mipi_gen_0_0_synth_1 \
  [get_runs -quiet design_uyvy_mipi_gen_0_0_synth_1]
if {$design_uyvy_mipi_gen_0_0_synth_1 ne ""} {
  reset_run $design_uyvy_mipi_gen_0_0_synth_1
}

# The UYVY design has a dedicated ATG register image that enables CSI-2
# line-start/line-end short packets, matching the proven receiver-facing
# packet structure. Invalidate all three generated ATG netlists so an older
# data.coe image cannot survive into implementation.
set atg_image [file join $root project_1.srcs sources_1 coe data_uyvy.coe]
set atg_fd [open $atg_image r]
set atg_contents [read $atg_fd]
close $atg_fd
if {![regexp {memory_initialization_vector\s*=\s*\n[01]+\n00000000000000001110000000011011} $atg_contents]} {
  error "UYVY ATG verification failed: protocol register must be 0xE01B (LS/LE enabled)"
}
puts "UYVY_ATG_VERIFIED protocol_config=0xE01B LS_LE=enabled"
foreach atg_run {
  design_uyvy_axi_traffic_gen_0_0_synth_1
  design_uyvy_axi_traffic_gen_1_0_synth_1
  design_uyvy_axi_traffic_gen_2_0_synth_1
} {
  set run [get_runs -quiet $atg_run]
  if {$run ne ""} {
    reset_run $run
  }
}
generate_target all $bd
make_wrapper -files $bd -top -import -force

set source_set [get_filesets sources_1]
set original_top [get_property TOP $source_set]
set_property TOP design_uyvy_wrapper $source_set
update_compile_order -fileset sources_1

# Fail before synthesis if the project no longer resolves to the intended
# three-lane UYVY design.
if {[get_property TOP $source_set] ne "design_uyvy_wrapper"} {
  error "UYVY top verification failed: expected design_uyvy_wrapper"
}
set wrappers [get_files -quiet */design_uyvy_wrapper.v]
if {[llength $wrappers] != 1} {
  error "UYVY top verification failed: wrapper count is [llength $wrappers]"
}
open_bd_design $bd
foreach i {0 1 2} {
  set atg [get_bd_cells axi_traffic_gen_$i]
  set atg_mif [get_property CONFIG.C_ATG_SYSTEM_INIT_DATA_MIF $atg]
  if {![string match "*data_uyvy.coe" $atg_mif]} {
    error "UYVY top verification failed: ATG lane $i uses $atg_mif, expected data_uyvy.coe"
  }
  puts "UYVY_ATG_PATH_VERIFIED lane$i=$atg_mif"
  set lane [get_bd_cells lane_inject_$i]
  if {![string match "*module_ref:lane_inject_uyvy:*" [get_property VLNV $lane]]} {
    error "UYVY top verification failed: lane_inject_$i has wrong module"
  }
  set csi [get_bd_cells mipi_csi2_tx_subsyst_$i]
  if {[get_property CONFIG.C_CSI_DATATYPE $csi] ne "YUV422_8b" ||
      [get_property CONFIG.C_CSI_MAX_BPC $csi] != 8 ||
      [get_property CONFIG.C_CSI_AXIS_TDATA_WIDTH $csi] != 96} {
    error "UYVY top verification failed: CSI lane $i must be YUV422_8b/MAX_BPC8/96-bit"
  }
  set conv [get_bd_cells axis_subset_converter_$i]
  if {[get_property CONFIG.S_TDATA_NUM_BYTES $conv] ne "12" ||
      [get_property CONFIG.M_TDATA_NUM_BYTES $conv] ne "12"} {
    error "UYVY top verification failed: subset lane $i must be 96-bit pass-through"
  }
  set expected_tuser_remap \
    "tuser\[95:70\],6'b0,tuser\[63:16\],9'b0,tuser\[69:64\],tuser\[0\]"
  if {[get_property CONFIG.TUSER_REMAP $conv] ne $expected_tuser_remap} {
    error "UYVY top verification failed: subset lane $i has wrong TUSER remap"
  }
  puts "UYVY_TUSER_REMAP_VERIFIED lane$i DT input\[69:64\] -> PG260\[6:1\]"
}
set generator [get_bd_cells mipi_gen_0]
if {![string match "*module_ref:mipi_gen_uyvy:*" [get_property VLNV $generator]]} {
  error "UYVY top verification failed: mipi_gen_0 has wrong module"
}

# Reserved-row changes must not alter the proven PCIe endpoint configuration.
set xdma [get_bd_cells xdma_0]
foreach {property expected} {
  CONFIG.pf0_device_id 9034
  CONFIG.pl_link_cap_max_link_speed 8.0_GT/s
  CONFIG.pl_link_cap_max_link_width X4
  CONFIG.axisten_freq 250
} {
  set actual [get_property $property $xdma]
  if {$actual ne $expected} {
    error "PCIe pre-synthesis verification failed: $property is $actual, expected $expected"
  }
  puts "PCIE_CONFIG_VERIFIED $property=$actual"
}
puts "UYVY_TOP_VERIFIED design_uyvy_wrapper -> design_uyvy -> 3xlane_inject_uyvy + mipi_gen_uyvy"

if {[llength [get_runs -quiet synth_uyvy]] == 0} {
  create_run synth_uyvy \
    -flow {Vivado Synthesis 2020} \
    -strategy {Vivado Synthesis Defaults}
}
if {[llength [get_runs -quiet impl_uyvy]] == 0} {
  create_run impl_uyvy \
    -parent_run synth_uyvy \
    -flow {Vivado Implementation 2020} \
    -strategy {Vivado Implementation Defaults}
}

reset_run synth_uyvy
set incremental_checkpoint [file join $root project_1.runs impl_uyvy_mipi_diag design_uyvy_wrapper_routed.dcp]
if {![file exists $incremental_checkpoint]} {
  error "hardware-proven UYVY incremental checkpoint is missing: $incremental_checkpoint"
}
set_property INCREMENTAL_CHECKPOINT $incremental_checkpoint [get_runs impl_uyvy]
puts "UYVY_INCREMENTAL_CHECKPOINT $incremental_checkpoint"
# Vivado 2020.2 spawns up to four synthesis helpers per run. Eight concurrent
# OOC runs exceed this 32 GiB host's practical memory limit, so cap the run
# scheduler at two jobs to keep synthesis deterministic and avoid swap/OOM.
launch_runs impl_uyvy -to_step write_bitstream -jobs 2
wait_on_run impl_uyvy

set status [get_property STATUS [get_runs impl_uyvy]]
set progress [get_property PROGRESS [get_runs impl_uyvy]]
puts "UYVY_IMPL_STATUS $status"
puts "UYVY_IMPL_PROGRESS $progress"

if {[string match "*Complete*" $status]} {
  open_run impl_uyvy

  # Do not accept a bitstream unless every PCIe primitive landed at the
  # hardware-proven location from the working RAW12 implementation.
  set pcie_locations [list \
    [list {.*gen_gthe4_channel_inst\[0\]\.GTHE4_CHANNEL_PRIM_INST$} GTHE4_CHANNEL_X0Y4] \
    [list {.*gen_gthe4_channel_inst\[1\]\.GTHE4_CHANNEL_PRIM_INST$} GTHE4_CHANNEL_X0Y5] \
    [list {.*gen_gthe4_channel_inst\[2\]\.GTHE4_CHANNEL_PRIM_INST$} GTHE4_CHANNEL_X0Y6] \
    [list {.*gen_gthe4_channel_inst\[3\]\.GTHE4_CHANNEL_PRIM_INST$} GTHE4_CHANNEL_X0Y7] \
    [list {.*/bufg_gt_sysclk$} BUFG_GT_X0Y30] \
    [list {.*/bufg_gt_coreclk$} BUFG_GT_X0Y36] \
    [list {.*/bufg_gt_intclk$} BUFG_GT_X0Y46] \
    [list {.*/bufg_gt_mcapclk$} BUFG_GT_X0Y45] \
    [list {.*/bufg_gt_pclk$} BUFG_GT_X0Y44] \
    [list {.*gen_cpll_cal_inst\[0\].*bufg_gt_txoutclkmon_inst$} BUFG_GT_X0Y28] \
    [list {.*gen_cpll_cal_inst\[1\].*bufg_gt_txoutclkmon_inst$} BUFG_GT_X0Y39] \
    [list {.*gen_cpll_cal_inst\[2\].*bufg_gt_txoutclkmon_inst$} BUFG_GT_X0Y24] \
    [list {.*gen_cpll_cal_inst\[3\].*bufg_gt_txoutclkmon_inst$} BUFG_GT_X0Y41]]
  foreach spec $pcie_locations {
    lassign $spec pattern expected_loc
    set cells [get_cells -hierarchical -regexp $pattern]
    if {[llength $cells] != 1} {
      error "PCIe implementation verification failed: $pattern matched [llength $cells] cells"
    }
    set actual_loc [get_property LOC $cells]
    if {$actual_loc ne $expected_loc} {
      error "PCIe implementation verification failed: $cells is at $actual_loc, expected $expected_loc"
    }
    puts "PCIE_IMPL_LOC_VERIFIED $cells -> $actual_loc"
  }

  report_timing_summary -file [file join $root uyvy_timing_summary.rpt]
  report_utilization -file [file join $root uyvy_utilization.rpt]
  puts "UYVY_WNS [get_property STATS.WNS [get_runs impl_uyvy]]"
  puts "UYVY_BIT [file join $root project_1.runs impl_uyvy design_uyvy_wrapper.bit]"
}

set_property TOP $original_top $source_set
update_compile_order -fileset sources_1
close_project

if {![string match "*Complete*" $status]} {
  error "UYVY implementation did not complete: $status"
}

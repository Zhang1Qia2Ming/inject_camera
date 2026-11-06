# Build an independent UYVY422 block design from the exported RAW12 design.
# The existing design_1 BD and its successful RAW12 bitstream are not modified.

set root [file dirname [file normalize [info script]]]
set project_file [file join $root project_1.xpr]
set baseline_tcl [file join $root \
  project_1.srcs sources_1 bd design_1 hw_handoff design_1_bd.tcl]
set generated_tcl [file join /tmp design_uyvy_bd.generated.tcl]
set rtl_dir [file join $root project_1.srcs sources_1 new]
set lane_mref_cache [file join $root project_1.srcs sources_1 bd mref lane_inject_uyvy]

# Module-reference metadata is generated from HDL attributes but is not
# reliably refreshed by Vivado 2020.2. Remove only this generated cache so the
# h2c:s2mm and mm2s clock associations are rebuilt from lane_inject_uyvy.v.
if {[file exists $lane_mref_cache]} {
  file delete -force $lane_mref_cache
}

open_project $project_file

set existing_bd [get_files -quiet design_uyvy.bd]
if {$existing_bd ne ""} {
  set existing_bd_dir [file dirname [file normalize $existing_bd]]
  remove_files $existing_bd
  file delete -force $existing_bd_dir
  puts "UYVY_BD_REMOVED $existing_bd_dir"
}

add_files -norecurse [list \
  [file join $rtl_dir uyvy_gearbox.v] \
  [file join $rtl_dir lane_inject_uyvy.v] \
  [file join $rtl_dir mipi_gen_uyvy.v] \
  [file join $rtl_dir 997_uyvy_reserved_64.mem]]
set reserved_mem [get_files 997_uyvy_reserved_64.mem]
set_property FILE_TYPE {Memory Initialization Files} $reserved_mem
set_property USED_IN {synthesis implementation simulation} $reserved_mem
update_compile_order -fileset sources_1
update_ip_catalog -rebuild -scan_changes

set fd [open $baseline_tcl r]
set script [read $fd]
close $fd

set raw12_remap "112'b0,tdata\[47:36\],2'b0,tdata\[35:24\],2'b0,tdata\[23:12\],2'b0,tdata\[11:0\],2'b0"
set uyvy_remap "tdata\[95:0\]"

# Converter 0 inherited several AXIS properties from connections in the
# original GUI project, so write those properties into the generated script
# before changing its width and remap expression.
set conv0_short "CONFIG.M_HAS_TKEEP {1} \\\n   CONFIG.M_TDATA_NUM_BYTES {21} \\\n   CONFIG.M_TDEST_WIDTH {2} \\\n   CONFIG.TDATA_REMAP"
set conv0_full "CONFIG.M_HAS_TKEEP {1} \\\n   CONFIG.M_HAS_TLAST {1} \\\n   CONFIG.M_HAS_TREADY {1} \\\n   CONFIG.M_TDATA_NUM_BYTES {12} \\\n   CONFIG.M_TDEST_WIDTH {2} \\\n   CONFIG.M_TUSER_WIDTH {96} \\\n   CONFIG.S_HAS_TLAST {1} \\\n   CONFIG.S_HAS_TREADY {1} \\\n   CONFIG.S_TDATA_NUM_BYTES {12} \\\n   CONFIG.S_TUSER_WIDTH {96} \\\n   CONFIG.TDATA_REMAP"
set script [string map [list $conv0_short $conv0_full] $script]

set script [string map [list \
  "set design_name design_1" "set design_name design_uyvy" \
  "../../../../coe/data.coe" "../../../../coe/data_uyvy.coe" \
  "set block_name lane_inject\n" "set block_name lane_inject_uyvy\n" \
  "set block_name mipi_gen\n" "set block_name mipi_gen_uyvy\n" \
  "CONFIG.S_TDATA_NUM_BYTES {6}" "CONFIG.S_TDATA_NUM_BYTES {12}" \
  "CONFIG.M_TDATA_NUM_BYTES {21}" "CONFIG.M_TDATA_NUM_BYTES {12}" \
  "CONFIG.TKEEP_REMAP {21'b111111111111111111111}" "CONFIG.TKEEP_REMAP {12'b111111111111}" \
  "CONFIG.TDATA_REMAP {$raw12_remap}" "CONFIG.TDATA_REMAP {$uyvy_remap}" \
  "CONFIG.C_CSI_DATATYPE {RAW12}" "CONFIG.C_CSI_DATATYPE {YUV422_8b}" \
  "CONFIG.C_CSI_AXIS_TDATA_WIDTH {168}" "CONFIG.C_CSI_AXIS_TDATA_WIDTH {96}" \
  "CONFIG.BYTENUM {5760}" "CONFIG.BYTE_NUM {7680}" \
  "CONFIG.H_Active {960}" "CONFIG.H_ACTIVE {960}" \
  "CONFIG.H_Total {2274}" "CONFIG.H_TOTAL {2274}" \
  "CONFIG.V_Active {2166}" "CONFIG.V_ACTIVE {2166}" \
  "CONFIG.V_Total {2200}" "CONFIG.V_TOTAL {2200}" \
] $script]

# Vivado 2020.2 can retain stale module-reference interface metadata. Apply
# the clock-to-AXIS associations explicitly before the generated Tcl connects
# the interfaces and runs validate_bd_design.
set intf_marker "  # Create interface connections"
set intf_assoc "  foreach i {0 1 2} {\n    set_property CONFIG.ASSOCIATED_BUSIF {h2c:s2mm} \[get_bd_pins lane_inject_\${i}/h2c_clk\]\n    set_property CONFIG.ASSOCIATED_BUSIF {mm2s} \[get_bd_pins lane_inject_\${i}/pix_clk\]\n  }\n\n$intf_marker"
set script [string map [list $intf_marker $intf_assoc] $script]

# mipi_gen_uyvy adds a diagnostic clock that is intentionally independent
# from the CSI pixel clock. Attach it to the existing 100 MHz PS debug domain
# before the generated script validates the block design.
set addr_marker "  # Create address segments"
set dbg_clock "  connect_bd_net \[get_bd_pins zynq_ultra_ps_e_0/pl_clk0\] \[get_bd_pins mipi_gen_0/dbg_clk\]\n\n$addr_marker"
set script [string map [list $addr_marker $dbg_clock] $script]

set fd [open $generated_tcl w]
puts -nonewline $fd $script
close $fd

source -notrace $generated_tcl

current_bd_design design_uyvy

# Keep one pure UYVY422-8 contract from the generator through each CSI TX.
for {set i 0} {$i < 3} {incr i} {
  set conv [get_bd_cells axis_subset_converter_$i]
  set_property -dict [list \
    CONFIG.S_TDATA_NUM_BYTES {12} \
    CONFIG.M_TDATA_NUM_BYTES {12} \
    CONFIG.TDATA_REMAP {tdata[95:0]} \
    CONFIG.TUSER_REMAP {tuser[95:70],6'b0,tuser[63:16],9'b0,tuser[69:64],tuser[0]} \
    CONFIG.TKEEP_REMAP {12'b111111111111}] $conv

  set csi [get_bd_cells mipi_csi2_tx_subsyst_$i]
  set_property -dict [list \
    CONFIG.C_CSI_DATATYPE {YUV422_8b} \
    CONFIG.C_CSI_MAX_BPC {8} \
    CONFIG.C_CSI_PIXEL_MODE {4} \
    CONFIG.C_CSI_AXIS_TDATA_WIDTH {96}] $csi
}

validate_bd_design
save_bd_design

puts "UYVY_BD_OK design=[current_bd_design]"
for {set i 0} {$i < 3} {incr i} {
  set csi [get_bd_cells mipi_csi2_tx_subsyst_$i]
  set conv [get_bd_cells axis_subset_converter_$i]
  puts "lane$i datatype=[get_property CONFIG.C_CSI_DATATYPE $csi] max_bpc=[get_property CONFIG.C_CSI_MAX_BPC $csi] pixel_mode=[get_property CONFIG.C_CSI_PIXEL_MODE $csi] csi_width=[get_property CONFIG.C_CSI_AXIS_TDATA_WIDTH $csi] subset_s_bytes=[get_property CONFIG.S_TDATA_NUM_BYTES $conv] subset_m_bytes=[get_property CONFIG.M_TDATA_NUM_BYTES $conv]"
}

close_project

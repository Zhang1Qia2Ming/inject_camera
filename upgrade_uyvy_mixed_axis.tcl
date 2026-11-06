set root [file dirname [file normalize [info script]]]
open_project [file join $root project_1.xpr]
open_bd_design [get_files design_uyvy.bd]

update_module_reference [get_ips design_uyvy_mipi_gen_0_0]

for {set i 0} {$i < 3} {incr i} {
  set conv [get_bd_cells axis_subset_converter_$i]
  set_property -dict [list \
    CONFIG.S_TDATA_NUM_BYTES {21} \
    CONFIG.M_TDATA_NUM_BYTES {21} \
    CONFIG.TDATA_REMAP {tdata[167:0]} \
    CONFIG.TKEEP_REMAP {21'b111111111111111111111}] $conv

  set csi [get_bd_cells mipi_csi2_tx_subsyst_$i]
  set_property -dict [list \
    CONFIG.C_CSI_DATATYPE {RAW12} \
    CONFIG.C_CSI_MAX_BPC {14} \
    CONFIG.C_CSI_PIXEL_MODE {4} \
    CONFIG.C_CSI_AXIS_TDATA_WIDTH {168}] $csi
}

validate_bd_design
save_bd_design
generate_target all [get_files design_uyvy.bd]

for {set i 0} {$i < 3} {incr i} {
  set conv [get_bd_cells axis_subset_converter_$i]
  set csi [get_bd_cells mipi_csi2_tx_subsyst_$i]
  puts "MIXED_AXIS_LANE_$i csi=[get_property CONFIG.C_CSI_DATATYPE $csi] max_bpc=[get_property CONFIG.C_CSI_MAX_BPC $csi] width=[get_property CONFIG.C_CSI_AXIS_TDATA_WIDTH $csi] subset=[get_property CONFIG.S_TDATA_NUM_BYTES $conv]->[get_property CONFIG.M_TDATA_NUM_BYTES $conv]"
}

close_project

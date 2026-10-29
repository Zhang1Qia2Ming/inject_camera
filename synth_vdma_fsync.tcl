open_project /data/work/gmsl_4ev/code/mipi_gmsl/zu4_pcie_gmsl_tx1rx1_6gloop/project_1.xpr
open_bd_design [get_files design_1.bd]

if {[llength [get_bd_cells -quiet xlconstant_s2mm_fsync]] == 0} {
  set gnd [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_s2mm_fsync]
  set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {0}] $gnd
}

foreach i {0 1 2} {
  set_property CONFIG.c_use_s2mm_fsync 1 [get_bd_cells axi_vdma_$i]
}
validate_bd_design

foreach i {0 1 2} {
  set pin [get_bd_pins axi_vdma_$i/s2mm_fsync]
  if {[llength [get_bd_nets -quiet -of_objects $pin]] == 0} {
    connect_bd_net [get_bd_pins xlconstant_s2mm_fsync/dout] $pin
  }
  puts "VDMA$i s2mm_fsync=[get_property CONFIG.c_use_s2mm_fsync [get_bd_cells axi_vdma_$i]] pin_net=[get_bd_nets -quiet -of_objects $pin]"
}
validate_bd_design
save_bd_design

reset_run design_1_axi_vdma_0_0_synth_1
launch_runs design_1_axi_vdma_0_0_synth_1 -jobs 8
wait_on_run design_1_axi_vdma_0_0_synth_1
puts "VDMA_SYNTH [get_property STATUS [get_runs design_1_axi_vdma_0_0_synth_1]]"
exit 0

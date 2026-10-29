open_project project_1.xpr
open_bd_design project_1.srcs/sources_1/bd/design_1/design_1.bd

set lane_ips [list \
    [get_ips design_1_lane_inject_0_0] \
    [get_ips design_1_lane_inject_1_0] \
    [get_ips design_1_lane_inject_2_0]]
update_module_reference $lane_ips

set ila_clk_net [get_bd_nets -of_objects [get_bd_pins ila_0/clk]]
set vio_clk_net [get_bd_nets -of_objects [get_bd_pins vio_inject_debug/clk]]
set ila_probe_net [get_bd_nets -of_objects [get_bd_pins ila_0/probe0]]
set vio_en_net [get_bd_nets -of_objects [get_bd_pins lane_inject_0/dbg_fsync_en]]
set vio_fsync_net [get_bd_nets -of_objects [get_bd_pins lane_inject_0/dbg_fsync]]
set lane_diag_net [get_bd_nets -of_objects [get_bd_pins pcie_diag_0/lane_dbg_bus]]

if {$ila_clk_net ne "/zynq_ultra_ps_e_0_pl_clk0"} {
    error "ILA clock is not PS pl_clk0: $ila_clk_net"
}
if {$vio_clk_net ne "/zynq_ultra_ps_e_0_pl_clk0"} {
    error "VIO clock is not PS pl_clk0: $vio_clk_net"
}
if {![string match "/pcie_diag_0_dbg_bus*" $ila_probe_net]} {
    error "ILA probe is not PCIe diagnostic bus: $ila_probe_net"
}
if {$vio_en_net ne "/vio_inject_debug_probe_out0"} {
    error "VIO enable is not connected: $vio_en_net"
}
if {$vio_fsync_net ne "/vio_inject_debug_probe_out1"} {
    error "VIO fsync is not connected: $vio_fsync_net"
}
if {![string match "/lane_inject_0_dbg_bus*" $lane_diag_net]} {
    error "PCIe diagnostic bridge is not connected to lane 0: $lane_diag_net"
}
set xdma_clk_net [get_bd_nets -of_objects [get_bd_pins xdma_0/axi_aclk]]
set xdma_clk_pins [get_bd_pins -of_objects $xdma_clk_net]
if {[lsearch -exact $xdma_clk_pins "/ila_0/clk"] >= 0 ||
    [lsearch -exact $xdma_clk_pins "/vio_inject_debug/clk"] >= 0} {
    error "Debug core still loads XDMA axi_aclk: $xdma_clk_pins"
}

validate_bd_design
save_bd_design
generate_target all [get_files project_1.srcs/sources_1/bd/design_1/design_1.bd]
set wrapper_files [make_wrapper \
    -files [get_files project_1.srcs/sources_1/bd/design_1/design_1.bd] -top]
foreach wrapper $wrapper_files {
    if {![llength [get_files -quiet $wrapper]]} {
        add_files -norecurse $wrapper
    }
}
update_compile_order -fileset sources_1

reset_run synth_tx2
launch_runs synth_tx2 -jobs 8
wait_on_run synth_tx2
set synth_status [get_property STATUS [get_runs synth_tx2]]
puts "SYNTH_STATUS $synth_status"
if {$synth_status ne "synth_design Complete!"} {
    error "synth_tx2 failed: $synth_status"
}

open_run synth_tx2
set h2c_state_cells [llength \
    [get_cells -hier -quiet -filter {NAME =~ *h2c_state*}]]
set first_data_cells [llength \
    [get_cells -hier -quiet -filter {NAME =~ *first_tdata*}]]
set old_armed_cells [llength \
    [get_cells -hier -quiet -filter {NAME =~ *s2mm_armed*}]]
puts "H2C_STATE_CELLS $h2c_state_cells"
puts "FIRST_DATA_CELLS $first_data_cells"
puts "OLD_S2MM_ARMED_CELLS $old_armed_cells"
if {$h2c_state_cells == 0 || $first_data_cells == 0 ||
    $old_armed_cells != 0} {
    error "top netlist did not pick up the first-beat buffer"
}
close_design

launch_runs impl_tx2 -to_step write_bitstream -jobs 8
wait_on_run impl_tx2
set impl_status [get_property STATUS [get_runs impl_tx2]]
set impl_wns [get_property STATS.WNS [get_runs impl_tx2]]
puts "IMPL_STATUS $impl_status"
puts "IMPL_WNS $impl_wns"
if {$impl_status ne "write_bitstream Complete!"} {
    error "impl_tx2 failed: $impl_status"
}

close_project

open_project project_1.xpr
open_bd_design project_1.srcs/sources_1/bd/design_1/design_1.bd

set lane_ips [list \
    [get_ips design_1_lane_inject_0_0] \
    [get_ips design_1_lane_inject_1_0] \
    [get_ips design_1_lane_inject_2_0]]
update_module_reference $lane_ips

foreach pin [get_bd_pins -quiet ila_0/probe*] {
    set net [get_bd_nets -quiet -of_objects $pin]
    if {[llength $net]} {
        disconnect_bd_net $net $pin
    }
}
set ila_clk [get_bd_nets -quiet -of_objects [get_bd_pins ila_0/clk]]
if {[llength $ila_clk]} {
    disconnect_bd_net $ila_clk [get_bd_pins ila_0/clk]
}
set_property -dict [list \
    CONFIG.C_NUM_OF_PROBES {1} \
    CONFIG.C_PROBE0_WIDTH {48}] [get_bd_cells ila_0]

if {![llength [get_bd_cells -quiet vio_inject_debug]]} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:vio:3.0 vio_inject_debug
}
set_property -dict [list \
    CONFIG.C_NUM_PROBE_IN {0} \
    CONFIG.C_NUM_PROBE_OUT {2} \
    CONFIG.C_PROBE_OUT0_WIDTH {1} \
    CONFIG.C_PROBE_OUT0_INIT_VAL {0x0} \
    CONFIG.C_PROBE_OUT1_WIDTH {1} \
    CONFIG.C_PROBE_OUT1_INIT_VAL {0x0}] [get_bd_cells vio_inject_debug]

if {![llength [get_bd_cells -quiet xlconstant_dbg_zero]]} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_dbg_zero
}
set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {0}] \
    [get_bd_cells xlconstant_dbg_zero]

connect_bd_net [get_bd_pins xdma_0/axi_aclk] \
    [get_bd_pins ila_0/clk] \
    [get_bd_pins vio_inject_debug/clk]
connect_bd_net [get_bd_pins lane_inject_0/dbg_bus] [get_bd_pins ila_0/probe0]
connect_bd_net [get_bd_pins vio_inject_debug/probe_out0] \
    [get_bd_pins lane_inject_0/dbg_fsync_en]
connect_bd_net [get_bd_pins vio_inject_debug/probe_out1] \
    [get_bd_pins lane_inject_0/dbg_fsync]
connect_bd_net [get_bd_pins xlconstant_dbg_zero/dout] \
    [get_bd_pins lane_inject_1/dbg_fsync_en] \
    [get_bd_pins lane_inject_1/dbg_fsync] \
    [get_bd_pins lane_inject_2/dbg_fsync_en] \
    [get_bd_pins lane_inject_2/dbg_fsync]

validate_bd_design
save_bd_design

puts "DEBUG_ILA_CLK [get_bd_nets -of_objects [get_bd_pins ila_0/clk]]"
puts "DEBUG_ILA_PROBE [get_bd_nets -of_objects [get_bd_pins ila_0/probe0]]"
puts "DEBUG_VIO_EN [get_bd_nets -of_objects [get_bd_pins lane_inject_0/dbg_fsync_en]]"
puts "DEBUG_VIO_FSYNC [get_bd_nets -of_objects [get_bd_pins lane_inject_0/dbg_fsync]]"
close_project

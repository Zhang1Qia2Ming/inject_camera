open_project project_1.xpr

set diag_src [file normalize \
    project_1.srcs/sources_1/new/pcie_diag.v]
if {![llength [get_files -quiet $diag_src]]} {
    add_files -norecurse -fileset sources_1 $diag_src
}
update_compile_order -fileset sources_1

open_bd_design project_1.srcs/sources_1/bd/design_1/design_1.bd

set lane_ips [list \
    [get_ips design_1_lane_inject_0_0] \
    [get_ips design_1_lane_inject_1_0] \
    [get_ips design_1_lane_inject_2_0]]
update_module_reference $lane_ips

if {![llength [get_bd_cells -quiet pcie_diag_0]]} {
    create_bd_cell -type module -reference pcie_diag pcie_diag_0
} else {
    update_module_reference [get_ips design_1_pcie_diag_0_0]
}

proc disconnect_pin {pin_name} {
    set pin [get_bd_pins -quiet $pin_name]
    if {![llength $pin]} {
        error "missing BD pin: $pin_name"
    }
    foreach net [get_bd_nets -quiet -of_objects $pin] {
        disconnect_bd_net $net $pin
    }
}

disconnect_pin ila_0/clk
disconnect_pin ila_0/probe0
disconnect_pin vio_inject_debug/clk
foreach pin_name {
    pcie_diag_0/dbg_clk
    pcie_diag_0/axi_aclk
    pcie_diag_0/pcie_rst_n
    pcie_diag_0/user_lnk_up
    pcie_diag_0/lane_dbg_bus
    pcie_diag_0/dbg_bus
} {
    disconnect_pin $pin_name
}

connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] \
    [get_bd_pins ila_0/clk] \
    [get_bd_pins vio_inject_debug/clk] \
    [get_bd_pins pcie_diag_0/dbg_clk]
connect_bd_net [get_bd_pins xdma_0/axi_aclk] \
    [get_bd_pins pcie_diag_0/axi_aclk]
connect_bd_net [get_bd_ports pcie_rst_n] \
    [get_bd_pins pcie_diag_0/pcie_rst_n]
connect_bd_net [get_bd_pins xdma_0/user_lnk_up] \
    [get_bd_pins pcie_diag_0/user_lnk_up]
connect_bd_net [get_bd_pins lane_inject_0/dbg_bus] \
    [get_bd_pins pcie_diag_0/lane_dbg_bus]
connect_bd_net [get_bd_pins pcie_diag_0/dbg_bus] \
    [get_bd_pins ila_0/probe0]

set stale_dbg_net [get_bd_nets -quiet pcie_diag_0_dbg_bus]
if {[llength $stale_dbg_net] &&
    ![llength [get_bd_pins -quiet -of_objects $stale_dbg_net]]} {
    delete_bd_objs $stale_dbg_net
}

validate_bd_design
save_bd_design

puts "DEBUG_ILA_CLK [get_bd_nets -of_objects [get_bd_pins ila_0/clk]]"
puts "DEBUG_VIO_CLK [get_bd_nets -of_objects [get_bd_pins vio_inject_debug/clk]]"
puts "DEBUG_ILA_PROBE [get_bd_nets -of_objects [get_bd_pins ila_0/probe0]]"
puts "DEBUG_AXI_CLK [get_bd_nets -of_objects [get_bd_pins pcie_diag_0/axi_aclk]]"
puts "DEBUG_LINK [get_bd_nets -of_objects [get_bd_pins pcie_diag_0/user_lnk_up]]"
puts "DEBUG_LANE0 [get_bd_nets -of_objects [get_bd_pins pcie_diag_0/lane_dbg_bus]]"

close_project

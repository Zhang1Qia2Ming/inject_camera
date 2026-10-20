# Add TX2 as a second CSI-2 TX that shares TX1's D-PHY clock.
# TX1 keeps SupportLevel 1 (shared logic inside). TX2 uses SupportLevel 0.

open_project /data/work/gmsl_4ev/code/mipi_gmsl/zu4_pcie_gmsl_tx1rx1_6gloop/project_1.xpr
open_bd_design [get_files design_1.bd]

if {[llength [get_bd_intf_ports -quiet mipi_phy_if_1]]} {
  puts "TX2 port already exists"
  exit 0
}

# Re-read mipi_gen.v so the second stream pins are part of the module reference.
set gen_file [lindex [get_files */mipi_gen.v] 0]
puts "GEN_FILE $gen_file"
remove_files $gen_file
add_files -norecurse /data/work/gmsl_4ev/code/mipi_gmsl/zu4_pcie_gmsl_tx1rx1_6gloop/project_1.srcs/sources_1/new/mipi_gen.v
update_compile_order -fileset sources_1
set rc [catch {update_module_reference -verbose [get_ips design_1_mipi_gen_0_0]} msg]
puts "UPDATE_RC $rc"
puts "UPDATE_MSG $msg"
puts "---- mipi_gen pins after refresh ----"
foreach p [lsort [get_bd_pins mipi_gen_0/*]] {
  puts "[get_property DIR $p] [get_property NAME $p]"
}
if {[llength [get_bd_pins -quiet mipi_gen_0/video2_tdata]] == 0} {
  error "mipi_gen was not refreshed; video2_tdata is missing"
}

set tx2 [create_bd_cell -type ip -vlnv xilinx.com:ip:mipi_csi2_tx_subsystem:2.2 mipi_csi2_tx_subsyst_1]
set_property -dict [list \
  CONFIG.CLK_LANE_IO_LOC {J5} \
  CONFIG.CLK_LANE_IO_LOC_NAME {IO_L19P_T3L_N0_DBC_AD9P_65} \
  CONFIG.C_CLK_LANE_IO_POSITION {39} \
  CONFIG.C_CSI_AXIS_TDATA_WIDTH {168} \
  CONFIG.C_CSI_CRC_ENABLE {true} \
  CONFIG.C_CSI_DATATYPE {RAW12} \
  CONFIG.C_CSI_LANES {4} \
  CONFIG.C_CSI_PERIODIC_PATRN_LEN {1024} \
  CONFIG.C_CSI_PERIODIC_TIME {50} \
  CONFIG.C_CSI_PIXEL_MODE {4} \
  CONFIG.C_DATA_LANE0_IO_POSITION {47} \
  CONFIG.C_DATA_LANE1_IO_POSITION {41} \
  CONFIG.C_DATA_LANE2_IO_POSITION {43} \
  CONFIG.C_DATA_LANE3_IO_POSITION {45} \
  CONFIG.C_DPHY_LANES {4} \
  CONFIG.C_HS_LINE_RATE {1200} \
  CONFIG.C_STRETCH_LINE_RATE {1500} \
  CONFIG.DATA_LANE0_IO_LOC {K9} \
  CONFIG.DATA_LANE0_IO_LOC_NAME {IO_L23P_T3U_N8_I2C_SCLK_65} \
  CONFIG.DATA_LANE1_IO_LOC {J6} \
  CONFIG.DATA_LANE1_IO_LOC_NAME {IO_L20P_T3L_N2_AD1P_65} \
  CONFIG.DATA_LANE2_IO_LOC {J7} \
  CONFIG.DATA_LANE2_IO_LOC_NAME {IO_L21P_T3L_N4_AD8P_65} \
  CONFIG.DATA_LANE3_IO_LOC {K8} \
  CONFIG.DATA_LANE3_IO_LOC_NAME {IO_L22P_T3U_N6_DBC_AD0P_65} \
  CONFIG.HP_IO_BANK_SELECTION {65} \
  CONFIG.SupportLevel {0} \
] $tx2

puts "---- TX2 pins ----"
foreach p [lsort [get_bd_pins $tx2/*]] {
  puts "[get_property DIR $p] [get_property NAME $p]"
}

proc tie_pin {src dst} {
  set d [get_bd_pins -quiet $dst]
  if {$d eq ""} {
    puts "skip missing $dst"
    return
  }
  connect_bd_net [get_bd_pins $src] $d
  puts "tied $src -> $dst"
}

tie_pin mipi_csi2_tx_subsyst_0/clkoutphy_out mipi_csi2_tx_subsyst_1/clkoutphy_in
tie_pin mipi_csi2_tx_subsyst_0/pll_lock_out  mipi_csi2_tx_subsyst_1/pll_lock_in
tie_pin mipi_csi2_tx_subsyst_0/txclkesc_out  mipi_csi2_tx_subsyst_1/txclkesc_in
tie_pin mipi_csi2_tx_subsyst_0/txbyteclkhs   mipi_csi2_tx_subsyst_1/txbyteclkhs_in
tie_pin mipi_csi2_tx_subsyst_0/system_rst_out mipi_csi2_tx_subsyst_1/system_rst_in
tie_pin mipi_csi2_tx_subsyst_0/mmcm_lock_out mipi_csi2_tx_subsyst_1/mmcm_lock_in
tie_pin clk_wiz_0/clk_out1 mipi_csi2_tx_subsyst_1/dphy_clk_200M
tie_pin clk_wiz_0/clk_out2 mipi_csi2_tx_subsyst_1/s_axis_aclk
tie_pin proc_sys_reset_mipi/peripheral_aresetn mipi_csi2_tx_subsyst_1/s_axis_aresetn

set conv [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_converter_1]
set_property -dict [list \
  CONFIG.S_TDATA_NUM_BYTES {6} \
  CONFIG.S_TUSER_WIDTH {96} \
  CONFIG.S_HAS_TLAST {1} \
  CONFIG.S_HAS_TREADY {1} \
  CONFIG.M_HAS_TKEEP {1} \
  CONFIG.M_HAS_TLAST {1} \
  CONFIG.M_HAS_TREADY {1} \
  CONFIG.M_TDATA_NUM_BYTES {21} \
  CONFIG.M_TDEST_WIDTH {2} \
  CONFIG.M_TUSER_WIDTH {96} \
] $conv
set_property -dict [list \
  CONFIG.TDATA_REMAP {112'b0,tdata[47:36],2'b0,tdata[35:24],2'b0,tdata[23:12],2'b0,tdata[11:0],2'b0} \
  CONFIG.TDEST_REMAP {2'b00} \
  CONFIG.TKEEP_REMAP {21'b111111111111111111111} \
  CONFIG.TLAST_REMAP {tlast[0]} \
  CONFIG.TUSER_REMAP {tuser[95:70],6'b0,tuser[63:16],9'b0,tuser[69:64],tuser[0]} \
] $conv
connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins axis_subset_converter_1/aclk]
connect_bd_net [get_bd_pins proc_sys_reset_mipi/peripheral_aresetn] [get_bd_pins axis_subset_converter_1/aresetn]
puts "---- mipi_gen pins ----"
foreach p [lsort [get_bd_pins mipi_gen_0/*]] {
  puts "[get_property DIR $p] [get_property NAME $p]"
}
connect_bd_intf_net [get_bd_intf_pins mipi_gen_0/video2] [get_bd_intf_pins axis_subset_converter_1/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins axis_subset_converter_1/M_AXIS] [get_bd_intf_pins mipi_csi2_tx_subsyst_1/s_axis]

set atg [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_traffic_gen:3.0 axi_traffic_gen_1]
set_property -dict [list \
  CONFIG.C_ATG_MODE {AXI4-Lite} \
  CONFIG.C_ATG_SYSTEM_CH1_HIGH {0x44afffff} \
  CONFIG.C_ATG_SYSTEM_CH1_LOW {0x44a00000} \
  CONFIG.C_ATG_SYSTEM_INIT_ADDR_MIF {../../../../coe/addr.coe} \
  CONFIG.C_ATG_SYSTEM_INIT_DATA_MIF {../../../../coe/data.coe} \
] $atg
connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins axi_traffic_gen_1/s_axi_aclk]
connect_bd_net [get_bd_pins proc_sys_reset_mipi/peripheral_aresetn] [get_bd_pins axi_traffic_gen_1/s_axi_aresetn]
connect_bd_intf_net [get_bd_intf_pins axi_traffic_gen_1/M_AXI_LITE_CH1] [get_bd_intf_pins mipi_csi2_tx_subsyst_1/s_axi]

set phy [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mipi_phy_rtl:1.0 mipi_phy_if_1]
connect_bd_intf_net $phy [get_bd_intf_pins mipi_csi2_tx_subsyst_1/mipi_phy_if]

assign_bd_address -offset 0x44A00000 -range 0x00001000 \
  -target_address_space [get_bd_addr_spaces axi_traffic_gen_1/Reg1] \
  [get_bd_addr_segs mipi_csi2_tx_subsyst_1/s_axi/Reg]

validate_bd_design
save_bd_design
puts "BD_OK"

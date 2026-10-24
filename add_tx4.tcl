# TX4: yellow stream already exists on mipi_gen video4.
# Bank 64 cannot share the bank 65 D-PHY PLL, so this PHY owns its PLL
# (SupportLevel 1), the same arrangement TX1 uses. The stream itself stays
# independent and uses the same converter and ATG pattern as TX2.
# Pins from ZU4EV-4通道gmsl管脚对应.xlsx, M9295_T4 P pins.

open_project /data/work/gmsl_4ev/code/mipi_gmsl/zu4_pcie_gmsl_tx1rx1_6gloop/project_1.xpr
open_bd_design [get_files design_1.bd]

if {[llength [get_bd_intf_ports -quiet mipi_phy_if_2]]} {
  puts "TX4 port already exists"
  exit 0
}
if {[llength [get_bd_pins -quiet mipi_gen_0/video4_tdata]] == 0} {
  error "mipi_gen_0/video4 is missing; refresh the module reference first"
}

set tx4 [create_bd_cell -type ip -vlnv xilinx.com:ip:mipi_csi2_tx_subsystem:2.2 mipi_csi2_tx_subsyst_2]
set_property -dict [list \
  CONFIG.CLK_LANE_IO_LOC {AD7} \
  CONFIG.CLK_LANE_IO_LOC_NAME {IO_L4P_T0U_N6_DBC_AD7P_64} \
  CONFIG.C_CLK_LANE_IO_POSITION {6} \
  CONFIG.C_CSI_AXIS_TDATA_WIDTH {168} \
  CONFIG.C_CSI_CRC_ENABLE {true} \
  CONFIG.C_CSI_DATATYPE {RAW12} \
  CONFIG.C_CSI_LANES {4} \
  CONFIG.C_CSI_PERIODIC_PATRN_LEN {1024} \
  CONFIG.C_CSI_PERIODIC_TIME {50} \
  CONFIG.C_CSI_PIXEL_MODE {4} \
  CONFIG.C_DATA_LANE0_IO_POSITION {4} \
  CONFIG.C_DATA_LANE1_IO_POSITION {2} \
  CONFIG.C_DATA_LANE2_IO_POSITION {0} \
  CONFIG.C_DATA_LANE3_IO_POSITION {10} \
  CONFIG.C_DPHY_LANES {4} \
  CONFIG.C_HS_LINE_RATE {1200} \
  CONFIG.C_STRETCH_LINE_RATE {1500} \
  CONFIG.DATA_LANE0_IO_LOC {AB8} \
  CONFIG.DATA_LANE0_IO_LOC_NAME {IO_L3P_T0L_N4_AD15P_64} \
  CONFIG.DATA_LANE1_IO_LOC {AE9} \
  CONFIG.DATA_LANE1_IO_LOC_NAME {IO_L2P_T0L_N2_64} \
  CONFIG.DATA_LANE2_IO_LOC {AC9} \
  CONFIG.DATA_LANE2_IO_LOC_NAME {IO_L1P_T0L_N0_DBC_64} \
  CONFIG.DATA_LANE3_IO_LOC {AB6} \
  CONFIG.DATA_LANE3_IO_LOC_NAME {IO_L6P_T0U_N10_AD6P_64} \
  CONFIG.HP_IO_BANK_SELECTION {64} \
  CONFIG.SupportLevel {1} \
] $tx4

puts "---- TX4 pins ----"
foreach p [lsort [get_bd_pins $tx4/*]] {
  puts "[get_property DIR $p] [get_property NAME $p]"
}

connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins mipi_csi2_tx_subsyst_2/dphy_clk_200M]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins mipi_csi2_tx_subsyst_2/s_axis_aclk]
connect_bd_net [get_bd_pins proc_sys_reset_mipi/peripheral_aresetn] [get_bd_pins mipi_csi2_tx_subsyst_2/s_axis_aresetn]

set conv [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_converter_2]
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
  CONFIG.TDATA_REMAP {112'b0,tdata[47:36],2'b0,tdata[35:24],2'b0,tdata[23:12],2'b0,tdata[11:0],2'b0} \
  CONFIG.TDEST_REMAP {2'b00} \
  CONFIG.TKEEP_REMAP {21'b111111111111111111111} \
  CONFIG.TLAST_REMAP {tlast[0]} \
  CONFIG.TUSER_REMAP {tuser[95:70],6'b0,tuser[63:16],9'b0,tuser[69:64],tuser[0]} \
] $conv
connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins axis_subset_converter_2/aclk]
connect_bd_net [get_bd_pins proc_sys_reset_mipi/peripheral_aresetn] [get_bd_pins axis_subset_converter_2/aresetn]
connect_bd_intf_net [get_bd_intf_pins mipi_gen_0/video4] [get_bd_intf_pins axis_subset_converter_2/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins axis_subset_converter_2/M_AXIS] [get_bd_intf_pins mipi_csi2_tx_subsyst_2/s_axis]

set atg [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_traffic_gen:3.0 axi_traffic_gen_2]
set_property -dict [list \
  CONFIG.C_ATG_MODE {AXI4-Lite} \
  CONFIG.C_ATG_SYSTEM_CH1_HIGH {0x44afffff} \
  CONFIG.C_ATG_SYSTEM_CH1_LOW {0x44a00000} \
  CONFIG.C_ATG_SYSTEM_INIT_ADDR_MIF {../../../../coe/addr.coe} \
  CONFIG.C_ATG_SYSTEM_INIT_DATA_MIF {../../../../coe/data.coe} \
] $atg
connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins axi_traffic_gen_2/s_axi_aclk]
connect_bd_net [get_bd_pins proc_sys_reset_mipi/peripheral_aresetn] [get_bd_pins axi_traffic_gen_2/s_axi_aresetn]
connect_bd_intf_net [get_bd_intf_pins axi_traffic_gen_2/M_AXI_LITE_CH1] [get_bd_intf_pins mipi_csi2_tx_subsyst_2/s_axi]

set phy [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mipi_phy_rtl:1.0 mipi_phy_if_2]
connect_bd_intf_net $phy [get_bd_intf_pins mipi_csi2_tx_subsyst_2/mipi_phy_if]

assign_bd_address -offset 0x44A00000 -range 0x00001000 \
  -target_address_space [get_bd_addr_spaces axi_traffic_gen_2/Reg1] \
  [get_bd_addr_segs mipi_csi2_tx_subsyst_2/s_axi/Reg]

validate_bd_design
save_bd_design
puts "BD_OK"

#PCIe rstn
set_property PACKAGE_PIN H8 [get_ports pcie_rst_n]
set_property IOSTANDARD LVCMOS12 [get_ports pcie_rst_n]

# PCI Express reference clock 100MHz
set_property PACKAGE_PIN Y5 [get_ports {pcie_ref_clk_n[0]}]
set_property PACKAGE_PIN Y6 [get_ports {pcie_ref_clk_p[0]}]



# Channel primitive location constraint
set_property LOC GTHE4_CHANNEL_X0Y4 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y4 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y4 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y4 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y6 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y4 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y4 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y4 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y4 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y7 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin T1 [get_ports gthrxn_in[0]]
#set_property package_pin T2 [get_ports gthrxp_in[0]]
#set_property package_pin R3 [get_ports gthtxn_out[0]]
#set_property package_pin R4 [get_ports gthtxp_out[0]]
# CPLL calibration block constraints
create_clock -period 8.000 [get_pins -filter REF_PIN_NAME=~*O -of_objects [get_cells -hierarchical -filter {NAME =~ *gen_cpll_cal_inst[0].*bufg_gt_txoutclkmon_inst}]]



# Commands for enabled transceiver GTHE4_CHANNEL_X0Y7
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE4_CHANNEL_X0Y5 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[1].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y5 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[1].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y5 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[1].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y5 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[1].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y7 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[1].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y5 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[1].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y5 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[1].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y5 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[1].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y5 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[1].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y6 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[1].*gen_gthe4_channel_inst[1].GTHE4_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin P1 [get_ports gthrxn_in[1]]
#set_property package_pin P2 [get_ports gthrxp_in[1]]
#set_property package_pin N3 [get_ports gthtxn_out[1]]
#set_property package_pin N4 [get_ports gthtxp_out[1]]
# CPLL calibration block constraints
create_clock -period 8.000 [get_pins -filter REF_PIN_NAME=~*O -of_objects [get_cells -hierarchical -filter {NAME =~ *gen_cpll_cal_inst[1].*bufg_gt_txoutclkmon_inst}]]




# False path constraints
# ----------------------------------------------------------------------------------------------------------------------


##set_false_path -to [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_*_reg}] -quiet


#
#
# BITFILE/BITSTREAM compress options
#
#set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN div-1 [current_design]
#set_property BITSTREAM.CONFIG.BPI_SYNC_MODE Type1 [current_design]
#set_property CONFIG_MODE BPI16 [current_design]
#set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
#set_property BITSTREAM.CONFIG.UNUSEDPIN Pulldown [current_design]
#
#
set_false_path -to [get_pins -hier {*sync_reg[0]/D}]
#


set_property PACKAGE_PIN AA11 [get_ports user_lnk_up]
set_property IOSTANDARD LVCMOS33 [get_ports user_lnk_up]

set_property PACKAGE_PIN AE5 [get_ports CLK_200m_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports CLK_200m_clk_p]
set_property PACKAGE_PIN D15 [get_ports bd_id0]
set_property PACKAGE_PIN E15 [get_ports bd_id1]
set_property IOSTANDARD LVCMOS33 [get_ports bd_id0]
set_property IOSTANDARD LVCMOS33 [get_ports bd_id1]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

create_clock -period 4.000 -name PCIE_clk -waveform {0.000 2.000} [get_pins u_design_1_wrapper/design_1_i/xdma_0/inst/axi_aclk]

#create_clock -period 6.700 -name mipi_clk -waveform {0.000 3.350} [get_pins -hierarchical *video_clk*]
connect_debug_port dbg_hub/clk [get_nets mipi_clk]

set_property PACKAGE_PIN A11 [get_ports IIC_1_scl_io]
set_property PACKAGE_PIN B11 [get_ports IIC_1_sda_io]
set_property IOSTANDARD LVCMOS33 [get_ports IIC_1_scl_io]
set_property IOSTANDARD LVCMOS33 [get_ports IIC_1_sda_io]

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]

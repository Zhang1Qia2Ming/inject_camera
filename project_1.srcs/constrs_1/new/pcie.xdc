# PCIe Gen3 x4 on the injection card, plus the 200 MHz board clock.
# One LOC per GTH lane. Package pins are the ones already used on this board.

set_property PACKAGE_PIN H8 [get_ports pcie_rst_n]
set_property IOSTANDARD LVCMOS12 [get_ports pcie_rst_n]

set_property PACKAGE_PIN Y6 [get_ports {pcie_ref_clk_p[0]}]
set_property PACKAGE_PIN Y5 [get_ports {pcie_ref_clk_n[0]}]

set_property LOC GTHE4_CHANNEL_X0Y4 [get_cells -hierarchical -filter {NAME =~ *gen_gthe4_channel_inst\[0\].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y5 [get_cells -hierarchical -filter {NAME =~ *gen_gthe4_channel_inst\[1\].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y6 [get_cells -hierarchical -filter {NAME =~ *gen_gthe4_channel_inst\[2\].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y7 [get_cells -hierarchical -filter {NAME =~ *gen_gthe4_channel_inst\[3\].GTHE4_CHANNEL_PRIM_INST}]

set_property PACKAGE_PIN AE5 [get_ports CLK_200m_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports CLK_200m_clk_p]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

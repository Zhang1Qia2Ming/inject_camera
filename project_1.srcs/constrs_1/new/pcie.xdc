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

# The PCIe diagnostic Gray counter crosses from XDMA axi_aclk into PS pl_clk0.
# Only the first ASYNC_REG stage is unconstrained; the second stage remains timed.
set pcie_diag_axi_meta_cells [get_cells -hierarchical -filter \
    {NAME =~ *pcie_diag_0*axi_gray_meta_reg*}]
set_false_path -quiet -to [get_pins -quiet \
    -of_objects $pcie_diag_axi_meta_cells -filter {REF_PIN_NAME == D}]

# Lane 0 status is made persistent in axi_aclk before crossing into pl_clk0.
# Only the first synchronizer stage is exempted from timing.
set pcie_diag_lane_meta_cells [get_cells -hierarchical -filter \
    {NAME =~ *pcie_diag_0*lane_status_meta_reg*}]
set_false_path -quiet -to [get_pins -quiet \
    -of_objects $pcie_diag_lane_meta_cells -filter {REF_PIN_NAME == D}]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

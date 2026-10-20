//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
//Date        : Mon Oct 19 13:26:20 2026
//Host        : ubuntu running 64-bit Ubuntu 22.04.3 LTS
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (CLK_200m_clk_n,
    CLK_200m_clk_p,
    mipi_phy_if_0_clk_n,
    mipi_phy_if_0_clk_p,
    mipi_phy_if_0_data_n,
    mipi_phy_if_0_data_p,
    mipi_phy_rx_6_clk_n,
    mipi_phy_rx_6_clk_p,
    mipi_phy_rx_6_data_n,
    mipi_phy_rx_6_data_p);
  input CLK_200m_clk_n;
  input CLK_200m_clk_p;
  output mipi_phy_if_0_clk_n;
  output mipi_phy_if_0_clk_p;
  output [3:0]mipi_phy_if_0_data_n;
  output [3:0]mipi_phy_if_0_data_p;
  input mipi_phy_rx_6_clk_n;
  input mipi_phy_rx_6_clk_p;
  input [3:0]mipi_phy_rx_6_data_n;
  input [3:0]mipi_phy_rx_6_data_p;

  wire CLK_200m_clk_n;
  wire CLK_200m_clk_p;
  wire mipi_phy_if_0_clk_n;
  wire mipi_phy_if_0_clk_p;
  wire [3:0]mipi_phy_if_0_data_n;
  wire [3:0]mipi_phy_if_0_data_p;
  wire mipi_phy_rx_6_clk_n;
  wire mipi_phy_rx_6_clk_p;
  wire [3:0]mipi_phy_rx_6_data_n;
  wire [3:0]mipi_phy_rx_6_data_p;

  design_1 design_1_i
       (.CLK_200m_clk_n(CLK_200m_clk_n),
        .CLK_200m_clk_p(CLK_200m_clk_p),
        .mipi_phy_if_0_clk_n(mipi_phy_if_0_clk_n),
        .mipi_phy_if_0_clk_p(mipi_phy_if_0_clk_p),
        .mipi_phy_if_0_data_n(mipi_phy_if_0_data_n),
        .mipi_phy_if_0_data_p(mipi_phy_if_0_data_p),
        .mipi_phy_rx_6_clk_n(mipi_phy_rx_6_clk_n),
        .mipi_phy_rx_6_clk_p(mipi_phy_rx_6_clk_p),
        .mipi_phy_rx_6_data_n(mipi_phy_rx_6_data_n),
        .mipi_phy_rx_6_data_p(mipi_phy_rx_6_data_p));
endmodule

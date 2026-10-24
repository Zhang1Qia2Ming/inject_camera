//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
//Date        : Sat Oct 24 20:34:57 2026
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
    mipi_phy_if_1_clk_n,
    mipi_phy_if_1_clk_p,
    mipi_phy_if_1_data_n,
    mipi_phy_if_1_data_p,
    mipi_phy_if_2_clk_n,
    mipi_phy_if_2_clk_p,
    mipi_phy_if_2_data_n,
    mipi_phy_if_2_data_p,
    mipi_phy_rx_6_clk_n,
    mipi_phy_rx_6_clk_p,
    mipi_phy_rx_6_data_n,
    mipi_phy_rx_6_data_p,
    pcie_mgt_rxn,
    pcie_mgt_rxp,
    pcie_mgt_txn,
    pcie_mgt_txp,
    pcie_ref_clk_n,
    pcie_ref_clk_p,
    pcie_rst_n);
  input CLK_200m_clk_n;
  input CLK_200m_clk_p;
  output mipi_phy_if_0_clk_n;
  output mipi_phy_if_0_clk_p;
  output [3:0]mipi_phy_if_0_data_n;
  output [3:0]mipi_phy_if_0_data_p;
  output mipi_phy_if_1_clk_n;
  output mipi_phy_if_1_clk_p;
  output [3:0]mipi_phy_if_1_data_n;
  output [3:0]mipi_phy_if_1_data_p;
  output mipi_phy_if_2_clk_n;
  output mipi_phy_if_2_clk_p;
  output [3:0]mipi_phy_if_2_data_n;
  output [3:0]mipi_phy_if_2_data_p;
  input mipi_phy_rx_6_clk_n;
  input mipi_phy_rx_6_clk_p;
  input [3:0]mipi_phy_rx_6_data_n;
  input [3:0]mipi_phy_rx_6_data_p;
  input [3:0]pcie_mgt_rxn;
  input [3:0]pcie_mgt_rxp;
  output [3:0]pcie_mgt_txn;
  output [3:0]pcie_mgt_txp;
  input [0:0]pcie_ref_clk_n;
  input [0:0]pcie_ref_clk_p;
  input pcie_rst_n;

  wire CLK_200m_clk_n;
  wire CLK_200m_clk_p;
  wire mipi_phy_if_0_clk_n;
  wire mipi_phy_if_0_clk_p;
  wire [3:0]mipi_phy_if_0_data_n;
  wire [3:0]mipi_phy_if_0_data_p;
  wire mipi_phy_if_1_clk_n;
  wire mipi_phy_if_1_clk_p;
  wire [3:0]mipi_phy_if_1_data_n;
  wire [3:0]mipi_phy_if_1_data_p;
  wire mipi_phy_if_2_clk_n;
  wire mipi_phy_if_2_clk_p;
  wire [3:0]mipi_phy_if_2_data_n;
  wire [3:0]mipi_phy_if_2_data_p;
  wire mipi_phy_rx_6_clk_n;
  wire mipi_phy_rx_6_clk_p;
  wire [3:0]mipi_phy_rx_6_data_n;
  wire [3:0]mipi_phy_rx_6_data_p;
  wire [3:0]pcie_mgt_rxn;
  wire [3:0]pcie_mgt_rxp;
  wire [3:0]pcie_mgt_txn;
  wire [3:0]pcie_mgt_txp;
  wire [0:0]pcie_ref_clk_n;
  wire [0:0]pcie_ref_clk_p;
  wire pcie_rst_n;

  design_1 design_1_i
       (.CLK_200m_clk_n(CLK_200m_clk_n),
        .CLK_200m_clk_p(CLK_200m_clk_p),
        .mipi_phy_if_0_clk_n(mipi_phy_if_0_clk_n),
        .mipi_phy_if_0_clk_p(mipi_phy_if_0_clk_p),
        .mipi_phy_if_0_data_n(mipi_phy_if_0_data_n),
        .mipi_phy_if_0_data_p(mipi_phy_if_0_data_p),
        .mipi_phy_if_1_clk_n(mipi_phy_if_1_clk_n),
        .mipi_phy_if_1_clk_p(mipi_phy_if_1_clk_p),
        .mipi_phy_if_1_data_n(mipi_phy_if_1_data_n),
        .mipi_phy_if_1_data_p(mipi_phy_if_1_data_p),
        .mipi_phy_if_2_clk_n(mipi_phy_if_2_clk_n),
        .mipi_phy_if_2_clk_p(mipi_phy_if_2_clk_p),
        .mipi_phy_if_2_data_n(mipi_phy_if_2_data_n),
        .mipi_phy_if_2_data_p(mipi_phy_if_2_data_p),
        .mipi_phy_rx_6_clk_n(mipi_phy_rx_6_clk_n),
        .mipi_phy_rx_6_clk_p(mipi_phy_rx_6_clk_p),
        .mipi_phy_rx_6_data_n(mipi_phy_rx_6_data_n),
        .mipi_phy_rx_6_data_p(mipi_phy_rx_6_data_p),
        .pcie_mgt_rxn(pcie_mgt_rxn),
        .pcie_mgt_rxp(pcie_mgt_rxp),
        .pcie_mgt_txn(pcie_mgt_txn),
        .pcie_mgt_txp(pcie_mgt_txp),
        .pcie_ref_clk_n(pcie_ref_clk_n),
        .pcie_ref_clk_p(pcie_ref_clk_p),
        .pcie_rst_n(pcie_rst_n));
endmodule

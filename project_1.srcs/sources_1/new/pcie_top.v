`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/27 16:58:52
// Design Name: 
// Module Name: pcie_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pcie_top(
input   CLK_200m_clk_p,
input   CLK_200m_clk_n,
input bd_id0,
    input bd_id1,
  input [3:0]pcie_mgt_rxn,
  input [3:0]pcie_mgt_rxp,
  output [3:0]pcie_mgt_txn,
  output [3:0]pcie_mgt_txp,
  input [0:0]pcie_ref_clk_n,
  input [0:0]pcie_ref_clk_p,
  input pcie_rst_n,
  output user_lnk_up,
  
  output mipi_phy_tx_6_clk_n,
  output mipi_phy_tx_6_clk_p,
  output [3:0]mipi_phy_tx_6_data_n,
  output [3:0]mipi_phy_tx_6_data_p,
    input mipi_phy_rx_6_clk_n,
    input mipi_phy_rx_6_clk_p,
    input [3:0] mipi_phy_rx_6_data_n,
    input [3:0] mipi_phy_rx_6_data_p,
    
    output mipi_phy_tx_1_clk_n,
  output mipi_phy_tx_1_clk_p,
  output [3:0]mipi_phy_tx_1_data_n,
  output [3:0]mipi_phy_tx_1_data_p,
    input mipi_phy_rx_1_clk_n,
    input mipi_phy_rx_1_clk_p,
    input [3:0] mipi_phy_rx_1_data_n,
    input [3:0] mipi_phy_rx_1_data_p
    );

  
  wire mipi_clk;
  wire mipi_rstn;
  
     design_1_wrapper u_design_1_wrapper
       (
       .CLK_200m_clk_p(CLK_200m_clk_p),
       .CLK_200m_clk_n(CLK_200m_clk_n),
       .pcie_mgt_rxn(pcie_mgt_rxn),
        .pcie_mgt_rxp(pcie_mgt_rxp),
        .pcie_mgt_txn(pcie_mgt_txn),
        .pcie_mgt_txp(pcie_mgt_txp),
        .pcie_ref_clk_n(pcie_ref_clk_n),
        .pcie_ref_clk_p(pcie_ref_clk_p),
        .pcie_rst_n(pcie_rst_n),
        .user_lnk_up(user_lnk_up),
        .bd_id({bd_id1,bd_id0}),
        .mipi_phy_tx_6_clk_n    (mipi_phy_tx_6_clk_n),
        .mipi_phy_tx_6_clk_p    (mipi_phy_tx_6_clk_p),
        .mipi_phy_tx_6_data_n    (mipi_phy_tx_6_data_n),
        .mipi_phy_tx_6_data_p    (mipi_phy_tx_6_data_p),

       .mipi_phy_rx_6_clk_n(mipi_phy_rx_6_clk_n),
        .mipi_phy_rx_6_clk_p(mipi_phy_rx_6_clk_p),
        .mipi_phy_rx_6_data_n(mipi_phy_rx_6_data_n),
        .mipi_phy_rx_6_data_p(mipi_phy_rx_6_data_p),
        
        .mipi_phy_tx_1_clk_n    (mipi_phy_tx_1_clk_n),
        .mipi_phy_tx_1_clk_p    (mipi_phy_tx_1_clk_p),
        .mipi_phy_tx_1_data_n    (mipi_phy_tx_1_data_n),
        .mipi_phy_tx_1_data_p    (mipi_phy_tx_1_data_p),

       .mipi_phy_rx_1_clk_n(mipi_phy_rx_1_clk_n),
        .mipi_phy_rx_1_clk_p(mipi_phy_rx_1_clk_p),
        .mipi_phy_rx_1_data_n(mipi_phy_rx_1_data_n),
        .mipi_phy_rx_1_data_p(mipi_phy_rx_1_data_p)

        ); 
    
endmodule

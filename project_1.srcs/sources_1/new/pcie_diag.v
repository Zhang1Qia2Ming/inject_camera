`timescale 1ns / 1ps

module pcie_diag (
	input              dbg_clk,
	input              axi_aclk,
	input              pcie_rst_n,
	input              user_lnk_up,
	input      [47:0]  lane_dbg_bus,
	output     [47:0]  dbg_bus
);
	reg [15:0] axi_bin = 16'd0;
	reg [7:0] lane_seen = 8'd0;

	always @(posedge axi_aclk) begin
		axi_bin <= axi_bin + 16'd1;
		if (lane_dbg_bus[0])
			lane_seen <= 8'd0;
		else
			lane_seen <= lane_seen | {
				lane_dbg_bus[3],
				lane_dbg_bus[6] & lane_dbg_bus[7],
				lane_dbg_bus[8] & lane_dbg_bus[5],
				lane_dbg_bus[12],
				lane_dbg_bus[13],
				lane_dbg_bus[14],
				lane_dbg_bus[9],
				lane_dbg_bus[5]
			};
	end

	wire [15:0] axi_gray = (axi_bin >> 1) ^ axi_bin;
	wire [15:0] lane_status_axi = {
		lane_dbg_bus[0],
		lane_dbg_bus[6],
		lane_dbg_bus[7],
		lane_dbg_bus[8],
		lane_dbg_bus[5],
		lane_dbg_bus[15],
		lane_dbg_bus[11],
		lane_seen,
		1'b0
	};

	(* ASYNC_REG = "TRUE" *) reg [15:0] axi_gray_meta = 16'd0;
	(* ASYNC_REG = "TRUE" *) reg [15:0] axi_gray_sync = 16'd0;
	(* ASYNC_REG = "TRUE" *) reg [15:0] lane_status_meta = 16'd0;
	(* ASYNC_REG = "TRUE" *) reg [15:0] lane_status_sync = 16'd0;
	(* ASYNC_REG = "TRUE" *) reg [1:0] rst_sync = 2'b00;
	(* ASYNC_REG = "TRUE" *) reg [1:0] link_sync = 2'b00;

	reg [15:0] axi_gray_prev = 16'd0;
	reg rst_seen_high = 1'b0;
	reg axi_alive = 1'b0;

	always @(posedge dbg_clk) begin
		axi_gray_meta <= axi_gray;
		axi_gray_sync <= axi_gray_meta;
		lane_status_meta <= lane_status_axi;
		lane_status_sync <= lane_status_meta;
		rst_sync <= {rst_sync[0], pcie_rst_n};
		link_sync <= {link_sync[0], user_lnk_up};

		axi_gray_prev <= axi_gray_sync;
		if (axi_gray_sync != axi_gray_prev)
			axi_alive <= 1'b1;
		if (rst_sync[1])
			rst_seen_high <= 1'b1;
	end

	assign dbg_bus = {
		lane_status_sync,
		axi_gray_sync,
		rst_sync[1],
		rst_seen_high,
		link_sync[1],
		1'b0,
		axi_alive,
		11'd0
	};
endmodule

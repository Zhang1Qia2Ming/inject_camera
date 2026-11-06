`timescale 1ns / 1ps

// Split each 128-bit DDR beat into two 64-bit packed UYVY beats.
// Byte 0 remains tdata[7:0], so output order is low 64 bits then high 64 bits.
module uyvy_gearbox (
	input              clk,
	input              rst,
	input      [127:0] s_tdata,
	input              s_tvalid,
	output             s_tready,
	output     [63:0]  m_tdata,
	output             m_tvalid,
	input              m_tready
);
	reg [127:0] data = 128'd0;
	reg         full = 1'b0;
	reg         high_half = 1'b0;

	wire pop = full && m_tready;
	wire replace = pop && high_half;
	assign s_tready = !full || replace;
	wire push = s_tvalid && s_tready;

	assign m_tdata = high_half ? data[127:64] : data[63:0];
	assign m_tvalid = full;

	always @(posedge clk) begin
		if (rst) begin
			data <= 128'd0;
			full <= 1'b0;
			high_half <= 1'b0;
		end else if (!full) begin
			if (push) begin
				data <= s_tdata;
				full <= 1'b1;
				high_half <= 1'b0;
			end
		end else if (pop) begin
			if (!high_half) begin
				high_half <= 1'b1;
			end else if (push) begin
				data <= s_tdata;
				full <= 1'b1;
				high_half <= 1'b0;
			end else begin
				full <= 1'b0;
				high_half <= 1'b0;
			end
		end
	end
endmodule

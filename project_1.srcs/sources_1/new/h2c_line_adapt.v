`timescale 1ns / 1ps

// One host write is one RAW12 frame and ends with tlast.
// VDMA S2MM wants tlast at the end of every line and tuser on the first beat.
module h2c_line_adapt #(
	parameter LINE_BEATS = 360,
	parameter FRAME_LINES = 2160
) (
	input              clk,
	input              rst,
	input              wr_ready,
	input      [127:0] s_tdata,
	input              s_tvalid,
	input              s_tlast,
	output             s_tready,
	output     [127:0] m_tdata,
	output             m_tvalid,
	output             m_tlast,
	output             m_tuser,
	input              m_tready,
	output reg         wr_start,
	output reg         wr_done,
	output reg         wr_abort
);
	localparam LB = LINE_BEATS;
	localparam FL = FRAME_LINES;

	reg                busy = 1'b0;
	reg [15:0]         beat = 16'd0;
	reg [15:0]         line = 16'd0;

	wire accept = s_tvalid && s_tready;
	wire line_end = (beat == LB - 1);
	wire frame_end = line_end && (line == FL - 1);
	assign s_tready = m_tready && (busy || wr_ready);
	assign m_tdata = s_tdata;
	assign m_tvalid = s_tvalid && (busy || wr_ready);
	assign m_tlast = busy && line_end;
	assign m_tuser = accept && !busy;

	always @(posedge clk) begin
		wr_start <= 1'b0;
		wr_done <= 1'b0;
		wr_abort <= 1'b0;
		if (rst) begin
			busy <= 1'b0;
			beat <= 16'd0;
			line <= 16'd0;
		end else if (accept) begin
			if (!busy) begin
				busy <= 1'b1;
				wr_start <= 1'b1;
				beat <= 16'd1;
				line <= 16'd0;
			end else if (s_tlast && !frame_end) begin
				busy <= 1'b0;
				beat <= 16'd0;
				line <= 16'd0;
				wr_abort <= 1'b1;
			end else if (line_end && !s_tlast && frame_end) begin
				busy <= 1'b0;
				beat <= 16'd0;
				line <= 16'd0;
				wr_abort <= 1'b1;
			end else if (frame_end && s_tlast) begin
				busy <= 1'b0;
				beat <= 16'd0;
				line <= 16'd0;
				wr_done <= 1'b1;
			end else if (line_end) begin
				beat <= 16'd0;
				line <= line + 16'd1;
			end else begin
				beat <= beat + 16'd1;
			end
		end
	end
endmodule

`timescale 1ns / 1ps

// Three-frame occupancy for one lane.
// A write reserves a slot when it starts and publishes the frame when it finishes.
// The reader may start a frame only after that publish. An empty lane does not repeat.
module frame_slot (
	input        wr_clk,
	input        wr_rst,
	input        wr_start,
	input        wr_done,
	input        wr_abort,
	output       wr_ready,

	input        rd_clk,
	input        rd_rst,
	output       frame_ok,
	input        frame_start,
	input        frame_done,
	output reg   fsync
);
	wire rel_wr;
	wire pub_rd;

	pulse_sync u_rel (
		.src_clk(rd_clk), .src_rst(rd_rst), .src_pulse(frame_done),
		.dst_clk(wr_clk), .dst_rst(wr_rst), .dst_pulse(rel_wr)
	);
	pulse_sync u_pub (
		.src_clk(wr_clk), .src_rst(wr_rst), .src_pulse(wr_done),
		.dst_clk(rd_clk), .dst_rst(rd_rst), .dst_pulse(pub_rd)
	);

	reg [1:0] reserved = 2'd0;
	wire take = wr_start && (reserved < 2'd3);
	wire give = rel_wr | wr_abort;
	assign wr_ready = (reserved < 2'd3);

	always @(posedge wr_clk) begin
		if (wr_rst)
			reserved <= 2'd0;
		else begin
			case ({take, give})
				2'b10: reserved <= reserved + 2'd1;
				2'b01: if (reserved != 2'd0) reserved <= reserved - 2'd1;
				default: reserved <= reserved;
			endcase
		end
	end

	reg [1:0] filled = 2'd0;
	reg       inflight = 1'b0;
	wire [1:0] filled_pub = (pub_rd && (filled < 2'd3)) ? (filled + 2'd1) : filled;
	assign frame_ok = inflight ? (filled_pub > 2'd1) : (filled_pub != 2'd0);

	always @(posedge rd_clk) begin
		if (rd_rst) begin
			filled <= 2'd0;
			inflight <= 1'b0;
			fsync <= 1'b0;
		end else begin
			fsync <= 1'b0;
			filled <= filled_pub;
			if (frame_done && (filled_pub != 2'd0))
				filled <= filled_pub - 2'd1;
			if (frame_start) begin
				inflight <= 1'b1;
				fsync <= 1'b1;
			end else if (frame_done) begin
				inflight <= 1'b0;
			end
		end
	end
endmodule

`timescale 1ns / 1ps

// One-cycle pulse in the source clock becomes one pulse in the destination clock.
module pulse_sync (
	input  src_clk,
	input  src_rst,
	input  src_pulse,
	input  dst_clk,
	input  dst_rst,
	output dst_pulse
);
	reg       tog = 1'b0;
	reg [2:0] samp = 3'b000;

	always @(posedge src_clk) begin
		if (src_rst)
			tog <= 1'b0;
		else if (src_pulse)
			tog <= ~tog;
	end

	always @(posedge dst_clk) begin
		if (dst_rst)
			samp <= 3'b000;
		else
			samp <= {samp[1:0], tog};
	end

	assign dst_pulse = samp[2] ^ samp[1];
endmodule

`timescale 1ns / 1ps

module tb_lane_uyvy;
	reg clk = 0;
	reg rst = 1;
	reg [127:0] h2c_tdata = 0;
	reg h2c_tvalid = 0;
	reg h2c_tlast = 0;
	wire h2c_tready;
	wire [127:0] s2mm_tdata;
	wire s2mm_tvalid;
	wire s2mm_tlast;
	wire s2mm_tuser;
	reg s2mm_tready = 1;
	reg [127:0] mm2s_tdata = 0;
	reg mm2s_tvalid = 0;
	reg mm2s_tlast = 0;
	reg mm2s_tuser = 0;
	wire mm2s_tready;
	wire [63:0] pix_data;
	wire pix_valid;
	reg pix_ready = 1;
	wire frame_ok;
	reg frame_start = 0;
	reg frame_done = 0;
	wire mm2s_fsync;
	wire s2mm_fsync;
	wire [47:0] dbg_bus;

	integer s2mm_beats = 0;
	integer s2mm_lines = 0;
	integer pix_beats = 0;

	always #5 clk = ~clk;

	lane_inject_uyvy #(.LINE_BEATS(2), .FRAME_LINES(2)) dut (
		.h2c_clk(clk), .h2c_rst(rst),
		.h2c_tdata(h2c_tdata), .h2c_tvalid(h2c_tvalid),
		.h2c_tlast(h2c_tlast), .h2c_tready(h2c_tready),
		.s2mm_tdata(s2mm_tdata), .s2mm_tvalid(s2mm_tvalid),
		.s2mm_tlast(s2mm_tlast), .s2mm_tuser(s2mm_tuser),
		.s2mm_tready(s2mm_tready),
		.pix_clk(clk), .pix_rst(rst),
		.mm2s_tdata(mm2s_tdata), .mm2s_tvalid(mm2s_tvalid),
		.mm2s_tlast(mm2s_tlast), .mm2s_tuser(mm2s_tuser),
		.mm2s_tready(mm2s_tready),
		.pix_data(pix_data), .pix_valid(pix_valid), .pix_ready(pix_ready),
		.frame_ok(frame_ok), .frame_start(frame_start),
		.frame_done(frame_done), .mm2s_fsync(mm2s_fsync),
		.s2mm_fsync(s2mm_fsync), .dbg_fsync_en(1'b0),
		.dbg_fsync(1'b0), .dbg_bus(dbg_bus)
	);

	always @(posedge clk) begin
		if (s2mm_tvalid && s2mm_tready) begin
			s2mm_beats <= s2mm_beats + 1;
			if (s2mm_tlast) begin
				if (((s2mm_beats + 1) % 2) != 0) $fatal;
				s2mm_lines <= s2mm_lines + 1;
			end
		end
		if (pix_valid && pix_ready) begin
			if (pix_data !== (64'h100 + pix_beats)) $fatal;
			pix_beats <= pix_beats + 1;
		end
	end

	task send_h2c;
		input [127:0] data;
		input last;
		begin
			h2c_tdata <= data;
			h2c_tlast <= last;
			h2c_tvalid <= 1;
			do @(posedge clk); while (!h2c_tready);
			h2c_tvalid <= 0;
			h2c_tlast <= 0;
		end
	endtask

	task send_mm2s;
		input [127:0] data;
		begin
			mm2s_tdata <= data;
			mm2s_tvalid <= 1;
			do @(posedge clk); while (!mm2s_tready);
			mm2s_tvalid <= 0;
		end
	endtask

	initial begin
		repeat (4) @(posedge clk);
		rst <= 0;
		send_h2c(128'h1, 0);
		send_h2c(128'h2, 0);
		send_h2c(128'h3, 0);
		send_h2c(128'h4, 1);
		wait (s2mm_lines == 2);
		wait (frame_ok);
		@(posedge clk);
		frame_start <= 1;
		@(posedge clk);
		frame_start <= 0;
		send_mm2s({64'h101, 64'h100});
		send_mm2s({64'h103, 64'h102});
		wait (pix_beats == 4);
		if (s2mm_beats != 4 || s2mm_lines != 2) $fatal;
		$display("PASS tb_lane_uyvy");
		$finish;
	end

	initial begin
		#5000;
		$display("FAIL timeout s2mm=%0d lines=%0d pix=%0d",
			s2mm_beats, s2mm_lines, pix_beats);
		$fatal;
	end
endmodule

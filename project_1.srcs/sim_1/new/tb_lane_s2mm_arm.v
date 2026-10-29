`timescale 1ns / 1ps

module tb_lane_s2mm_arm;
	reg h2c_clk = 1'b0;
	reg pix_clk = 1'b0;
	always #2 h2c_clk = ~h2c_clk;
	always #3 pix_clk = ~pix_clk;

	reg h2c_rst = 1'b1;
	reg pix_rst = 1'b1;
	reg [127:0] h2c_tdata = 128'd0;
	reg h2c_tvalid = 1'b0;
	reg h2c_tlast = 1'b0;
	wire h2c_tready;
	wire [127:0] s2mm_tdata;
	wire s2mm_tvalid;
	wire s2mm_tlast;
	wire s2mm_tuser;
	reg s2mm_tready = 1'b1;
	wire s2mm_fsync;
	wire [47:0] dbg_bus;

	lane_inject #(.LINE_BEATS(4), .FRAME_LINES(2)) dut (
		.h2c_clk(h2c_clk),
		.h2c_rst(h2c_rst),
		.h2c_tdata(h2c_tdata),
		.h2c_tvalid(h2c_tvalid),
		.h2c_tlast(h2c_tlast),
		.h2c_tready(h2c_tready),
		.s2mm_tdata(s2mm_tdata),
		.s2mm_tvalid(s2mm_tvalid),
		.s2mm_tlast(s2mm_tlast),
		.s2mm_tuser(s2mm_tuser),
		.s2mm_tready(s2mm_tready),
		.pix_clk(pix_clk),
		.pix_rst(pix_rst),
		.mm2s_tdata(128'd0),
		.mm2s_tvalid(1'b0),
		.mm2s_tlast(1'b0),
		.mm2s_tuser(1'b0),
		.mm2s_tready(),
		.pix_data(),
		.pix_valid(),
		.pix_ready(1'b1),
		.frame_ok(),
		.frame_start(1'b0),
		.frame_done(1'b0),
		.mm2s_fsync(),
		.s2mm_fsync(s2mm_fsync),
		.dbg_fsync_en(1'b0),
		.dbg_fsync(1'b0),
		.dbg_bus(dbg_bus)
	);

	integer cycles;
	integer fsync_cycle;
	integer ready_cycle;

	initial begin
		#30;
		h2c_rst = 1'b0;
		pix_rst = 1'b0;
		#20;
		h2c_tvalid = 1'b1;

		fsync_cycle = -1;
		ready_cycle = -1;
		for (cycles = 0; cycles < 32; cycles = cycles + 1) begin
			@(posedge h2c_clk);
			#1;
			if (s2mm_fsync && fsync_cycle < 0)
				fsync_cycle = cycles;
			if (h2c_tready && ready_cycle < 0)
				ready_cycle = cycles;
		end

		if (fsync_cycle < 0)
			$fatal(1, "S2MM fsync was not generated after host valid");
		if (ready_cycle < 0)
			$fatal(1, "host transfer was never released");
		if (ready_cycle <= fsync_cycle)
			$fatal(1, "host transfer started before fsync: fsync=%0d ready=%0d",
				fsync_cycle, ready_cycle);

		$display("TB_PASS fsync_cycle=%0d ready_cycle=%0d dbg=%012h",
			fsync_cycle, ready_cycle, dbg_bus);
		$finish;
	end
endmodule

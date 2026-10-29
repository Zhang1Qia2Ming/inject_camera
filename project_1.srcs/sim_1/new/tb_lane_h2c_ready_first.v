`timescale 1ns / 1ps

module tb_lane_h2c_ready_first;
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

	integer sent = 0;
	integer received = 0;
	integer fsync_count = 0;
	integer wait_cycles = 0;
	reg fsync_seen = 1'b0;

	always @(posedge h2c_clk) begin
		if (!h2c_rst && s2mm_fsync) begin
			fsync_seen <= 1'b1;
			fsync_count <= fsync_count + 1;
		end
		if (!h2c_rst && s2mm_tvalid && s2mm_tready) begin
			if (!fsync_seen)
				$fatal(1, "S2MM beat arrived before fsync");
			if (s2mm_tdata !== {120'd0, received[7:0]})
				$fatal(1, "beat %0d data mismatch: %032h",
					received, s2mm_tdata);
			if (s2mm_tuser !== (received == 0))
				$fatal(1, "beat %0d tuser mismatch", received);
			if (s2mm_tlast !== ((received == 3) || (received == 7)))
				$fatal(1, "beat %0d tlast mismatch", received);
			received <= received + 1;
		end
	end

	initial begin
		#30;
		h2c_rst = 1'b0;
		pix_rst = 1'b0;

		// Model the observed XDMA behavior: do not assert valid until the
		// sink first advertises ready.
		while (!h2c_tready && wait_cycles < 64) begin
			@(posedge h2c_clk);
			wait_cycles = wait_cycles + 1;
		end
		if (!h2c_tready)
			$fatal(1, "host never observed ready");

		for (sent = 0; sent < 8; sent = sent + 1) begin
			@(negedge h2c_clk);
			h2c_tdata = {120'd0, sent[7:0]};
			h2c_tlast = (sent == 7);
			h2c_tvalid = 1'b1;
			do begin
				@(posedge h2c_clk);
			end while (!h2c_tready);
			@(negedge h2c_clk);
			h2c_tvalid = 1'b0;
			h2c_tlast = 1'b0;
		end

		wait_cycles = 0;
		while (received < 8 && wait_cycles < 128) begin
			@(posedge h2c_clk);
			wait_cycles = wait_cycles + 1;
		end
		if (received != 8)
			$fatal(1, "received %0d/8 beats", received);
		if (fsync_count != 1)
			$fatal(1, "expected one fsync, got %0d", fsync_count);

		$display("TB_PASS sent=%0d received=%0d fsync=%0d dbg=%012h",
			sent, received, fsync_count, dbg_bus);
		$finish;
	end
endmodule

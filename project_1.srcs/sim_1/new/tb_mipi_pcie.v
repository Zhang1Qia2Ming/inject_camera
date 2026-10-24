`timescale 1ns / 1ps

module tb_mipi_pcie;
	reg clk = 1'b0;
	always #5 clk = ~clk;

	reg rst = 1'b1;

	// Gearbox unit
	reg [127:0] g_tdata;
	reg         g_valid;
	wire        g_ready;
	wire [47:0] g_pix;
	wire        g_pix_valid;
	reg         g_pix_ready;
	raw12_gearbox u_gear (
		.clk(clk), .rst(rst),
		.s_tdata(g_tdata), .s_tvalid(g_valid), .s_tready(g_ready),
		.m_tdata(g_pix), .m_tvalid(g_pix_valid), .m_tready(g_pix_ready)
	);

	// Line adapter unit. Four beats per line, two lines per frame.
	reg         a_ready_slot;
	reg [127:0] a_tdata;
	reg         a_valid;
	reg         a_last;
	wire        a_sready;
	wire [127:0] a_mdata;
	wire        a_mvalid, a_mlast, a_muser, a_mready;
	wire        a_start, a_done, a_abort;
	assign a_mready = 1'b1;
	h2c_line_adapt #(.LINE_BEATS(4), .FRAME_LINES(2)) u_adapt (
		.clk(clk), .rst(rst), .wr_ready(a_ready_slot),
		.s_tdata(a_tdata), .s_tvalid(a_valid), .s_tlast(a_last), .s_tready(a_sready),
		.m_tdata(a_mdata), .m_tvalid(a_mvalid), .m_tlast(a_mlast), .m_tuser(a_muser),
		.m_tready(a_mready),
		.wr_start(a_start), .wr_done(a_done), .wr_abort(a_abort)
	);

	// Read path under test. Short horizontal blanking, full vertical size.
	localparam H_TOTAL = 961;
	localparam V_ACTIVE = 2166;
	localparam FRAME_BEATS = 777600; // 2160 * 5760 / 16

	reg         wr_start_p, wr_done_p, wr_abort_p;
	wire        wr_ready;
	wire        frame_ok, fsync;
	wire        tx1_start, tx1_done, tx1_pix_ready;
	wire [47:0] tx1_pix;
	wire        tx1_pix_valid;
	wire        video_tvalid, video2_tvalid, video4_tvalid;
	wire        video_tlast;
	wire [47:0] video_tdata;
	wire [95:0] video_tuser;

	frame_slot u_slot (
		.wr_clk(clk), .wr_rst(rst),
		.wr_start(wr_start_p), .wr_done(wr_done_p), .wr_abort(wr_abort_p),
		.wr_ready(wr_ready),
		.rd_clk(clk), .rd_rst(rst),
		.frame_ok(frame_ok),
		.frame_start(tx1_start), .frame_done(tx1_done),
		.fsync(fsync)
	);

	reg [127:0] mm_tdata;
	reg         mm_valid;
	wire        mm_ready;
	raw12_gearbox u_mm_gear (
		.clk(clk), .rst(rst),
		.s_tdata(mm_tdata), .s_tvalid(mm_valid), .s_tready(mm_ready),
		.m_tdata(tx1_pix), .m_tvalid(tx1_pix_valid), .m_tready(tx1_pix_ready)
	);

	mipi_gen #(
		.H_Total(H_TOTAL), .H_Active(960),
		.V_Total(V_ACTIVE), .V_Active(V_ACTIVE),
		.BYTENUM(5760)
	) u_gen (
		.clk(clk),
		.video_out_tlast(video_tlast),
		.video_out_tuser(video_tuser),
		.video_out_tvalid(video_tvalid),
		.video_out_tdata(video_tdata),
		.video_out_tready(1'b1),
		.tx1_frame_ok(frame_ok),
		.tx1_frame_start(tx1_start),
		.tx1_frame_done(tx1_done),
		.tx1_pix_data(tx1_pix),
		.tx1_pix_valid(tx1_pix_valid),
		.tx1_pix_ready(tx1_pix_ready),
		.video2_tlast(),
		.video2_tuser(),
		.video2_tvalid(video2_tvalid),
		.video2_tdata(),
		.video2_tready(1'b1),
		.tx2_frame_ok(1'b0),
		.tx2_frame_start(),
		.tx2_frame_done(),
		.tx2_pix_data(48'd0),
		.tx2_pix_valid(1'b0),
		.tx2_pix_ready(),
		.video4_tlast(),
		.video4_tuser(),
		.video4_tvalid(video4_tvalid),
		.video4_tdata(),
		.video4_tready(1'b1),
		.tx4_frame_ok(1'b0),
		.tx4_frame_start(),
		.tx4_frame_done(),
		.tx4_pix_data(48'd0),
		.tx4_pix_valid(1'b0),
		.tx4_pix_ready()
	);

	reg        feeding;
	reg [19:0] src_beat;
	integer    lane2_valids;
	integer    frames_done;
	integer    errors;

	always @(posedge clk) begin
		if (rst) begin
			feeding <= 1'b0;
			src_beat <= 20'd0;
			mm_valid <= 1'b0;
		end else if (fsync) begin
			feeding <= 1'b1;
			src_beat <= 20'd0;
			mm_valid <= 1'b1;
		end else if (mm_valid && mm_ready) begin
			if (src_beat == FRAME_BEATS - 1) begin
				feeding <= 1'b0;
				mm_valid <= 1'b0;
			end else begin
				src_beat <= src_beat + 20'd1;
				mm_valid <= 1'b1;
			end
		end else
			mm_valid <= feeding;
	end

	integer bi;
	always @* begin
		for (bi = 0; bi < 16; bi = bi + 1)
			mm_tdata[bi*8 +: 8] = (src_beat * 16 + bi);
	end

	always @(posedge clk) begin
		if (video2_tvalid || video4_tvalid)
			lane2_valids <= lane2_valids + 1;
		if (tx1_done)
			frames_done <= frames_done + 1;
	end

	task fail;
		input [255:0] msg;
		begin
			$display("FAIL %0s", msg);
			errors = errors + 1;
		end
	endtask

	task gear_test;
		integer n, k;
		reg [47:0] exp_pix;
		begin
			g_valid = 1'b0;
			g_pix_ready = 1'b0;
			@(posedge clk);
			#1;
			for (n = 0; n < 3; n = n + 1) begin
				for (k = 0; k < 16; k = k + 1)
					g_tdata[k*8 +: 8] = n * 16 + k;
				g_valid = 1'b1;
				@(posedge clk);
				#1;
			end
			g_valid = 1'b0;
			#1;
			g_pix_ready = 1'b1;
			for (n = 0; n < 8; n = n + 1) begin
				exp_pix = 48'd0;
				for (k = 0; k < 6; k = k + 1)
					exp_pix[k*8 +: 8] = n * 6 + k;
				if (!g_pix_valid || g_pix !== exp_pix) begin
					$display("FAIL gear beat %0d got %h expect %h valid %b",
						n, g_pix, exp_pix, g_pix_valid);
					errors = errors + 1;
				end
				@(posedge clk);
				#1;
			end
			g_pix_ready = 1'b0;
		end
	endtask

	task adapt_test;
		integer n;
		integer saw_user, saw_last, saw_done, saw_start, saw_abort;
		begin
			a_ready_slot = 1'b1;
			a_valid = 1'b0;
			a_last = 1'b0;
			saw_user = 0;
			saw_last = 0;
			saw_done = 0;
			saw_start = 0;
			saw_abort = 0;
			@(posedge clk);
			#1;
			for (n = 0; n < 8; n = n + 1) begin
				a_tdata = n;
				a_valid = 1'b1;
				a_last = (n == 7);
				#1;
				if (a_muser) saw_user = saw_user + 1;
				if (a_mlast) saw_last = saw_last + 1;
				@(posedge clk);
				#1;
				if (a_start) saw_start = saw_start + 1;
				if (a_done) saw_done = saw_done + 1;
				if (a_abort) saw_abort = saw_abort + 1;
			end
			a_valid = 1'b0;
			a_last = 1'b0;
			if (saw_user != 1) fail("adapt tuser");
			if (saw_last != 2) fail("adapt tlast");
			if (saw_start != 1) fail("adapt start");
			if (saw_done != 1) fail("adapt done");

			// Second beat ends the frame early, so the slot is not published.
			saw_abort = 0;
			a_tdata = 32'h1;
			a_valid = 1'b1;
			a_last = 1'b0;
			@(posedge clk);
			#1;
			a_last = 1'b1;
			a_tdata = 32'h2;
			@(posedge clk);
			#1;
			if (a_abort) saw_abort = saw_abort + 1;
			a_valid = 1'b0;
			a_last = 1'b0;
			repeat (2) begin
				@(posedge clk);
				#1;
				if (a_abort) saw_abort = saw_abort + 1;
			end
			if (saw_abort == 0) fail("adapt abort");
		end
	endtask

	integer lines_done;
	integer beat_in_line;
	reg [47:0] emb0, img0, bot0;
	reg        got_emb, got_img, got_bot;

	always @(posedge clk) begin
		if (rst) begin
			lines_done <= 0;
			beat_in_line <= 0;
		end else if (video_tvalid) begin
			if (lines_done == 0 && beat_in_line == 0) begin
				emb0 <= video_tdata;
				got_emb <= 1'b1;
			end
			if (lines_done == 2 && beat_in_line == 0) begin
				img0 <= video_tdata;
				got_img <= 1'b1;
			end
			if (lines_done == 2162 && beat_in_line == 906) begin
				bot0 <= video_tdata;
				got_bot <= 1'b1;
			end
			if (video_tlast) begin
				lines_done <= lines_done + 1;
				beat_in_line <= 0;
			end else
				beat_in_line <= beat_in_line + 1;
		end
	end

	initial begin
		errors = 0;
		lane2_valids = 0;
		frames_done = 0;
		g_valid = 0;
		g_pix_ready = 0;
		a_ready_slot = 0;
		a_valid = 0;
		a_last = 0;
		wr_start_p = 0;
		wr_done_p = 0;
		wr_abort_p = 0;
		got_emb = 0;
		got_img = 0;
		got_bot = 0;
		repeat (4) @(posedge clk);
		rst = 1'b0;
		@(posedge clk);

		gear_test();
		adapt_test();
		$display("unit tests done errors %0d", errors);

		// Two published frames, then nothing else. TX2 and TX4 stay empty.
		@(posedge clk);
		wr_done_p <= 1'b1;
		@(posedge clk);
		wr_done_p <= 1'b0;
		@(posedge clk);
		wr_done_p <= 1'b1;
		@(posedge clk);
		wr_done_p <= 1'b0;

		begin : wait_frames
			integer guard;
			integer quiet;
			integer valids;
			guard = 0;
			quiet = 0;
			valids = 0;
			while (frames_done < 2 && guard < 4500000) begin
				@(posedge clk);
				#1;
				guard = guard + 1;
				if (video_tvalid) begin
					valids = valids + 1;
					quiet = 0;
				end else
					quiet = quiet + 1;
				if (quiet == 5000 && frames_done == 0) begin
					$display("stall valids %0d tuser %h pixv %b pixr %b ok %b",
						valids, video_tuser, tx1_pix_valid, tx1_pix_ready, frame_ok);
					fail("stalled");
					guard = 4500000;
				end
			end
			if (frames_done != 2)
				fail("frame count");
		end

		repeat (2000) begin
			@(posedge clk);
			if (video_tvalid)
				fail("still sending");
		end

		if (!got_emb || emb0 !== 48'h00000360DA0)
			fail("emb top");
		if (!got_img || img0 !== 48'h050403020100)
			fail("image");
		if (!got_bot || bot0 !== 48'hD80260400DA0)
			fail("emb bot");
		if (lane2_valids != 0)
			fail("idle lane");
		if (frames_done != 2)
			fail("drained");

		if (errors == 0) begin
			$display("PASS");
			$finish;
		end else begin
			$display("FAIL count %0d", errors);
			$fatal(1);
		end
	end
endmodule

`timescale 1ns / 1ps

// Three independent packed UYVY422 CSI-2 streams.
module mipi_gen_uyvy #(
	parameter H_TOTAL = 2274,
	parameter H_ACTIVE = 960,
	parameter V_TOTAL = 2200,
	parameter V_ACTIVE = 2166,
	parameter BYTE_NUM = 7680
) (
	input clk,
	input dbg_clk,
	output video_out_tlast,
	output [95:0] video_out_tuser,
	output video_out_tvalid,
	output [95:0] video_out_tdata,
	input video_out_tready,
	input tx1_frame_ok,
	output tx1_frame_start,
	output tx1_frame_done,
	input [63:0] tx1_pix_data,
	input tx1_pix_valid,
	output tx1_pix_ready,

	output video2_tlast,
	output [95:0] video2_tuser,
	output video2_tvalid,
	output [95:0] video2_tdata,
	input video2_tready,
	input tx2_frame_ok,
	output tx2_frame_start,
	output tx2_frame_done,
	input [63:0] tx2_pix_data,
	input tx2_pix_valid,
	output tx2_pix_ready,

	output video4_tlast,
	output [95:0] video4_tuser,
	output video4_tvalid,
	output [95:0] video4_tdata,
	input video4_tready,
	input tx4_frame_ok,
	output tx4_frame_start,
	output tx4_frame_done,
	input [63:0] tx4_pix_data,
	input tx4_pix_valid,
	output tx4_pix_ready,
	output [47:0] dbg_bus
);
	wire [47:0] mipi_dbg_bus;
	wire [47:0] tx1_state_dbg;
	(* ASYNC_REG = "TRUE" *) reg [47:0] dbg_meta = 48'd0;
	(* ASYNC_REG = "TRUE" *) reg [47:0] dbg_sync = 48'd0;

	always @(posedge dbg_clk) begin
		dbg_meta <= mipi_dbg_bus;
		dbg_sync <= dbg_meta;
	end
	assign dbg_bus = dbg_sync;

	mipi_gen_uyvy_lane #(
		.H_TOTAL(H_TOTAL), .H_ACTIVE(H_ACTIVE),
		.V_TOTAL(V_TOTAL), .V_ACTIVE(V_ACTIVE), .BYTE_NUM(BYTE_NUM)
	) u_tx1 (
		.clk(clk), .tlast(video_out_tlast), .tuser(video_out_tuser),
		.tvalid(video_out_tvalid), .tdata(video_out_tdata),
		.tready(video_out_tready), .frame_ok(tx1_frame_ok),
		.frame_start(tx1_frame_start), .frame_done(tx1_frame_done),
		.pix_data(tx1_pix_data), .pix_valid(tx1_pix_valid),
		.pix_ready(tx1_pix_ready), .state_dbg(tx1_state_dbg)
	);
	mipi_gen_uyvy_lane #(
		.H_TOTAL(H_TOTAL), .H_ACTIVE(H_ACTIVE),
		.V_TOTAL(V_TOTAL), .V_ACTIVE(V_ACTIVE), .BYTE_NUM(BYTE_NUM)
	) u_tx2 (
		.clk(clk), .tlast(video2_tlast), .tuser(video2_tuser),
		.tvalid(video2_tvalid), .tdata(video2_tdata),
		.tready(video2_tready), .frame_ok(tx2_frame_ok),
		.frame_start(tx2_frame_start), .frame_done(tx2_frame_done),
		.pix_data(tx2_pix_data), .pix_valid(tx2_pix_valid),
		.pix_ready(tx2_pix_ready), .state_dbg()
	);
	mipi_gen_uyvy_lane #(
		.H_TOTAL(H_TOTAL), .H_ACTIVE(H_ACTIVE),
		.V_TOTAL(V_TOTAL), .V_ACTIVE(V_ACTIVE), .BYTE_NUM(BYTE_NUM)
	) u_tx4 (
		.clk(clk), .tlast(video4_tlast), .tuser(video4_tuser),
		.tvalid(video4_tvalid), .tdata(video4_tdata),
		.tready(video4_tready), .frame_ok(tx4_frame_ok),
		.frame_start(tx4_frame_start), .frame_done(tx4_frame_done),
		.pix_data(tx4_pix_data), .pix_valid(tx4_pix_valid),
		.pix_ready(tx4_pix_ready), .state_dbg()
	);

	assign mipi_dbg_bus = tx1_state_dbg;
endmodule

module mipi_ila_diag (
	input clk,
	input tx1_v, input tx1_r, input tx1_l,
	input [95:0] tx1_u,
	input tx1_start, input tx1_done,
	input tx2_v, input tx2_r, input tx2_l,
	input tx2_start, input tx2_done,
	input tx4_v, input tx4_r, input tx4_l,
	input tx4_start, input tx4_done,
	output [47:0] dbg_bus
);
	reg [3:0] tx1_seen = 4'd0;
	reg [3:0] tx2_seen = 4'd0;
	reg [3:0] tx4_seen = 4'd0;
	reg [1:0] tx1_frames = 2'd0;
	reg [1:0] tx2_frames = 2'd0;
	reg [1:0] tx4_frames = 2'd0;
	reg [5:0] data_type = 6'd0;
	reg [15:0] byte_num = 16'd0;
	reg tx1_line_open = 1'b0;
	reg tx2_line_open = 1'b0;
	reg tx4_line_open = 1'b0;
	reg tx1_line_gap = 1'b0;
	reg tx2_line_gap = 1'b0;
	reg tx4_line_gap = 1'b0;

	always @(posedge clk) begin
		if (tx1_start || tx1_done) tx1_line_open <= 1'b0;
		if (tx2_start || tx2_done) tx2_line_open <= 1'b0;
		if (tx4_start || tx4_done) tx4_line_open <= 1'b0;

		if (tx1_v && tx1_r) begin
			tx1_seen[0] <= 1'b1;
			// The existing AXIS subset converter remaps input [69:64]
			// to the PG260-facing TUSER[6:1].
			data_type <= tx1_u[69:64];
			byte_num <= tx1_u[63:48];
			tx1_line_open <= !tx1_l;
		end
		else if (tx1_line_open && tx1_r)
			tx1_line_gap <= 1'b1;
		if (tx1_l) tx1_seen[1] <= 1'b1;
		if (tx1_start) tx1_seen[2] <= 1'b1;
		if (tx1_done) begin
			tx1_seen[3] <= 1'b1;
			tx1_frames <= tx1_frames + 2'd1;
		end

		if (tx2_v && tx2_r) begin
			tx2_seen[0] <= 1'b1;
			tx2_line_open <= !tx2_l;
		end
		else if (tx2_line_open && tx2_r)
			tx2_line_gap <= 1'b1;
		if (tx2_l) tx2_seen[1] <= 1'b1;
		if (tx2_start) tx2_seen[2] <= 1'b1;
		if (tx2_done) begin
			tx2_seen[3] <= 1'b1;
			tx2_frames <= tx2_frames + 2'd1;
		end

		if (tx4_v && tx4_r) begin
			tx4_seen[0] <= 1'b1;
			tx4_line_open <= !tx4_l;
		end
		else if (tx4_line_open && tx4_r)
			tx4_line_gap <= 1'b1;
		if (tx4_l) tx4_seen[1] <= 1'b1;
		if (tx4_start) tx4_seen[2] <= 1'b1;
		if (tx4_done) begin
			tx4_seen[3] <= 1'b1;
			tx4_frames <= tx4_frames + 2'd1;
		end
	end

	assign dbg_bus = {
		byte_num, data_type, 2'b0,
		tx4_frames, tx2_frames, tx1_frames,
		tx4_seen, tx2_seen, tx1_seen,
		tx4_line_gap, tx2_line_gap, tx1_line_gap, 3'b0
	};
endmodule

module mipi_gen_uyvy_lane #(
	parameter H_TOTAL = 2274,
	parameter H_ACTIVE = 960,
	parameter V_TOTAL = 2200,
	parameter V_ACTIVE = 2166,
	parameter BYTE_NUM = 7680,
	parameter USE_RESERVED_ROM = 1,
	parameter RESERVED_MEM_FILE = "997_uyvy_reserved_64.mem"
) (
	input clk,
	output tlast,
	output [95:0] tuser,
	output tvalid,
	output [95:0] tdata,
	input tready,
	input frame_ok,
	output frame_start,
	output frame_done,
	input [63:0] pix_data,
	input pix_valid,
	output pix_ready,
	output [47:0] state_dbg
);
	localparam EMB_TOP = 13'd2;
	localparam EMB_BOTTOM = 13'd4;
	// The HIL Query reserves two top and four bottom rows. They remain
	// ordinary UYVY422 packets on the wire; only their frame role differs.
	localparam RESERVED_LINE_WORDS = H_ACTIVE;
	localparam RESERVED_ROM_WORDS = 6 * RESERVED_LINE_WORDS;

	reg running = 1'b0;
	reg [15:0] frame_number = 16'd1;
	reg [12:0] pixel_count = 13'd1;
	reg [12:0] line_count = 13'd1;

	wire top_line = (line_count >= 13'd1) && (line_count <= EMB_TOP);
	wire bottom_line =
		(line_count > (V_ACTIVE - EMB_BOTTOM)) && (line_count <= V_ACTIVE);
	wire reserved_line = top_line || bottom_line;
	wire [12:0] line_beats = H_ACTIVE;
	wire payload_active =
		(pixel_count <= line_beats) && (line_count <= V_ACTIVE);
	wire image_beat = payload_active && !reserved_line;
	wire frame_last =
		(pixel_count == H_TOTAL) && (line_count == V_TOTAL);
	wire [2:0] reserved_slot =
		top_line ? (line_count - 13'd1) :
		(EMB_TOP + line_count - (V_ACTIVE - EMB_BOTTOM + 13'd1));
	wire [12:0] reserved_word_index =
		(reserved_slot * RESERVED_LINE_WORDS) + pixel_count - 13'd1;
	wire [12:0] next_line_count =
		frame_last ? 13'd1 : (line_count + 13'd1);
	wire next_top_line =
		(next_line_count >= 13'd1) && (next_line_count <= EMB_TOP);
	wire next_bottom_line =
		(next_line_count > (V_ACTIVE - EMB_BOTTOM)) &&
		(next_line_count <= V_ACTIVE);
	wire next_reserved_line = next_top_line || next_bottom_line;
	wire [2:0] next_reserved_slot =
		next_top_line ? (next_line_count - 13'd1) :
		(EMB_TOP + next_line_count -
			(V_ACTIVE - EMB_BOTTOM + 13'd1));
	wire [12:0] next_reserved_word_index =
		next_reserved_slot * RESERVED_LINE_WORDS;
	wire [63:0] reserved_data;
	wire [95:0] image_axis_data;
	wire [95:0] reserved_axis_data;
	wire reserved_ready;
	wire beat_ready =
		!payload_active ? 1'b1 :
		(reserved_line ? reserved_ready : pix_valid);
	wire step = running && beat_ready && (!payload_active || tready);
	wire arm = !running && frame_ok;

	generate
		if (USE_RESERVED_ROM != 0) begin : g_reserved_rom
			(* rom_style = "block" *)
			reg [63:0] rom [0:RESERVED_ROM_WORDS-1];
			reg [63:0] data_q = 64'd0;
			reg data_valid = 1'b0;
			reg [12:0] rom_addr = 13'd0;
			wire [12:0] rom_addr_next =
				!running ? 13'd0 :
				((tvalid && tready && reserved_line) &&
				 (pixel_count < line_beats)) ?
					(reserved_word_index + 13'd1) :
				((step && (pixel_count == H_TOTAL)) &&
				 next_reserved_line) ?
					next_reserved_word_index : rom_addr;

			initial $readmemh(RESERVED_MEM_FILE, rom);

			always @(posedge clk) begin
				// One synchronous read port is required for block-ROM
				// inference. rom_addr_next prefetches the following beat.
				rom_addr <= rom_addr_next;
				data_q <= rom[rom_addr_next];

				if (!running) begin
					data_valid <= 1'b1;
				end
				else if (tvalid && tready && reserved_line) begin
					if (pixel_count < line_beats) begin
						data_valid <= 1'b1;
					end
					else begin
						data_valid <= 1'b0;
					end
				end
				else if (step && (pixel_count == H_TOTAL)) begin
					if (next_reserved_line) begin
						data_valid <= 1'b1;
					end
					else begin
						data_valid <= 1'b0;
					end
				end
			end

			assign reserved_data = data_q;
			assign reserved_ready = data_valid;
		end
		else begin : g_no_reserved_rom
			assign reserved_data = 64'h1080108010801080;
			assign reserved_ready = 1'b1;
		end
	endgenerate

	always @(posedge clk) begin
		if (arm)
			running <= 1'b1;
		else if (step && frame_last)
			running <= frame_ok;
	end

	always @(posedge clk) begin
		if (step) begin
			if (pixel_count == H_TOTAL)
				pixel_count <= 13'd1;
			else
				pixel_count <= pixel_count + 13'd1;
		end
	end

	always @(posedge clk) begin
		if (step && frame_last)
			line_count <= 13'd1;
		else if (step && (pixel_count == H_TOTAL))
			line_count <= line_count + 13'd1;
	end

	always @(posedge clk) begin
		if (step && frame_last)
			frame_number <= frame_number + 16'd1;
	end

	assign frame_start = arm || (step && frame_last && frame_ok);
	assign frame_done = step && frame_last;
	assign pix_ready = image_beat && running && tready;

	// PG260 quad-pixel YUV422 layout with MAX_BPC=8.
	function [95:0] pack_uyvy_axis;
		input [63:0] source;
		begin
			pack_uyvy_axis = {
				32'd0,
				source[55:48], // V2
				source[63:56], // Y3
				source[39:32], // U2
				source[47:40], // Y2
				source[23:16], // V0
				source[31:24], // Y1
				source[7:0],   // U0
				source[15:8]   // Y0
			};
		end
	endfunction

	assign image_axis_data = pack_uyvy_axis(pix_data);
	assign reserved_axis_data = pack_uyvy_axis(reserved_data);
	assign tdata = reserved_line ? reserved_axis_data : image_axis_data;
	// This is the input-side contract of the existing AXIS subset converter:
	// it moves [69:64] to PG260 TUSER[6:1] and preserves [63:16] and [0].
	assign tuser = {
		26'b0, 6'h1e,
		BYTE_NUM[15:0],
		{3'b0, line_count}, frame_number, 15'b0,
		(pixel_count == 13'd1) && (line_count == 13'd1)
	};
	assign tvalid = running && payload_active && beat_ready;
	assign tlast = tvalid && (pixel_count == line_beats);
	assign state_dbg = {
		line_count, pixel_count,
		running, reserved_line, payload_active, reserved_ready,
		pix_valid, pix_ready, tvalid, tready, tlast,
		frame_ok, frame_start, frame_done, step, arm,
		reserved_slot, image_beat, next_reserved_line, 3'b0
	};
endmodule

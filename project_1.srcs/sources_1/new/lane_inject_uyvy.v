`timescale 1ns / 1ps

// UYVY lane: 128-bit H2C frame -> VDMA -> 64-bit packed UYVY pixels.
module lane_inject_uyvy #(
	parameter LINE_BEATS = 480,
	parameter FRAME_LINES = 2160
) (
	(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 h2c_clk CLK" *)
	(* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF h2c:s2mm, ASSOCIATED_RESET h2c_rst" *)
	input              h2c_clk,
	(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 h2c_rst RST" *)
	(* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
	input              h2c_rst,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 h2c TDATA" *)
	input      [127:0] h2c_tdata,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 h2c TVALID" *)
	input              h2c_tvalid,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 h2c TLAST" *)
	input              h2c_tlast,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 h2c TREADY" *)
	output             h2c_tready,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s2mm TDATA" *)
	output     [127:0] s2mm_tdata,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s2mm TVALID" *)
	output             s2mm_tvalid,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s2mm TLAST" *)
	output             s2mm_tlast,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s2mm TUSER" *)
	output             s2mm_tuser,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s2mm TREADY" *)
	input              s2mm_tready,

	(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 pix_clk CLK" *)
	(* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF mm2s, ASSOCIATED_RESET pix_rst" *)
	input              pix_clk,
	(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 pix_rst RST" *)
	(* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
	input              pix_rst,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 mm2s TDATA" *)
	input      [127:0] mm2s_tdata,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 mm2s TVALID" *)
	input              mm2s_tvalid,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 mm2s TLAST" *)
	input              mm2s_tlast,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 mm2s TUSER" *)
	input              mm2s_tuser,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 mm2s TREADY" *)
	output             mm2s_tready,
	output     [63:0]  pix_data,
	output             pix_valid,
	input              pix_ready,
	output             frame_ok,
	input              frame_start,
	input              frame_done,
	output             mm2s_fsync,
	output             s2mm_fsync,
	input              dbg_fsync_en,
	input              dbg_fsync,
	output     [47:0]  dbg_bus
);
	wire wr_ready;
	wire wr_start;
	wire wr_done;
	wire wr_abort;
	wire slot_fsync;
	assign mm2s_fsync = slot_fsync;

	localparam H2C_IDLE = 2'd0;
	localparam H2C_WAIT_ARM = 2'd1;
	localparam H2C_FIRST = 2'd2;
	localparam H2C_STREAM = 2'd3;

	reg         in_frame = 1'b0;
	reg [1:0]   h2c_state = H2C_IDLE;
	reg [9:0]   arm_cnt = 10'd0;
	reg         auto_s2mm_fsync = 1'b0;
	reg [127:0] first_tdata = 128'd0;
	reg         first_tlast = 1'b0;
	wire        adapt_h2c_tready;
	(* ASYNC_REG = "TRUE" *) reg [1:0] dbg_fsync_en_sync = 2'b00;
	(* ASYNC_REG = "TRUE" *) reg [1:0] dbg_fsync_sync = 2'b00;

	assign s2mm_fsync =
		dbg_fsync_en_sync[1] ? dbg_fsync_sync[1] : auto_s2mm_fsync;
	assign dbg_bus = {
		22'd0, arm_cnt, in_frame, wr_abort, wr_done, wr_start, wr_ready,
		s2mm_tuser, s2mm_tlast, s2mm_tvalid, h2c_tready, h2c_tvalid,
		s2mm_tready, auto_s2mm_fsync, s2mm_fsync, dbg_fsync_sync[1],
		dbg_fsync_en_sync[1], h2c_rst
	};

	always @(posedge h2c_clk) begin
		if (h2c_rst) begin
			in_frame <= 1'b0;
			h2c_state <= H2C_IDLE;
			arm_cnt <= 10'd0;
			auto_s2mm_fsync <= 1'b0;
			first_tdata <= 128'd0;
			first_tlast <= 1'b0;
			dbg_fsync_en_sync <= 2'b00;
			dbg_fsync_sync <= 2'b00;
		end else begin
			dbg_fsync_en_sync <= {dbg_fsync_en_sync[0], dbg_fsync_en};
			dbg_fsync_sync <= {dbg_fsync_sync[0], dbg_fsync};
			auto_s2mm_fsync <= 1'b0;
			if (wr_start)
				in_frame <= 1'b1;
			if (wr_done || wr_abort) begin
				in_frame <= 1'b0;
				arm_cnt <= 10'd0;
				h2c_state <= H2C_IDLE;
			end else begin
				case (h2c_state)
				H2C_IDLE: begin
					if (h2c_tvalid && h2c_tready) begin
						first_tdata <= h2c_tdata;
						first_tlast <= h2c_tlast;
						h2c_state <= H2C_WAIT_ARM;
						arm_cnt <= 10'd16;
						auto_s2mm_fsync <= 1'b1;
					end
				end
				H2C_WAIT_ARM: begin
					if (arm_cnt != 10'd0)
						arm_cnt <= arm_cnt - 10'd1;
					if (arm_cnt == 10'd1) begin
						arm_cnt <= 10'd0;
						h2c_state <= H2C_FIRST;
					end
				end
				H2C_FIRST: begin
					if (adapt_h2c_tready)
						h2c_state <= H2C_STREAM;
				end
				H2C_STREAM: begin
					if (h2c_tvalid && h2c_tready && h2c_tlast)
						h2c_state <= H2C_IDLE;
				end
				default: h2c_state <= H2C_IDLE;
				endcase
			end
		end
	end

	wire first_forward = (h2c_state == H2C_FIRST);
	wire stream_forward = (h2c_state == H2C_STREAM);
	wire [127:0] adapt_h2c_tdata =
		first_forward ? first_tdata : h2c_tdata;
	wire adapt_h2c_tvalid =
		first_forward ? 1'b1 : (stream_forward && h2c_tvalid);
	wire adapt_h2c_tlast =
		first_forward ? first_tlast : h2c_tlast;
	assign h2c_tready =
		!h2c_rst && !wr_done && !wr_abort &&
		((h2c_state == H2C_IDLE) ? wr_ready :
		(stream_forward && adapt_h2c_tready));

	h2c_line_adapt #(
		.LINE_BEATS(LINE_BEATS),
		.FRAME_LINES(FRAME_LINES)
	) u_adapt (
		.clk(h2c_clk),
		.rst(h2c_rst),
		.wr_ready(wr_ready),
		.s_tdata(adapt_h2c_tdata),
		.s_tvalid(adapt_h2c_tvalid),
		.s_tlast(adapt_h2c_tlast),
		.s_tready(adapt_h2c_tready),
		.m_tdata(s2mm_tdata),
		.m_tvalid(s2mm_tvalid),
		.m_tlast(s2mm_tlast),
		.m_tuser(s2mm_tuser),
		.m_tready(s2mm_tready),
		.wr_start(wr_start),
		.wr_done(wr_done),
		.wr_abort(wr_abort)
	);

	frame_slot u_slot (
		.wr_clk(h2c_clk),
		.wr_rst(h2c_rst),
		.wr_start(wr_start),
		.wr_done(wr_done),
		.wr_abort(wr_abort),
		.wr_ready(wr_ready),
		.rd_clk(pix_clk),
		.rd_rst(pix_rst),
		.frame_ok(frame_ok),
		.frame_start(frame_start),
		.frame_done(frame_done),
		.fsync(slot_fsync)
	);

	uyvy_gearbox u_gear (
		.clk(pix_clk),
		.rst(pix_rst),
		.s_tdata(mm2s_tdata),
		.s_tvalid(mm2s_tvalid),
		.s_tready(mm2s_tready),
		.m_tdata(pix_data),
		.m_tvalid(pix_valid),
		.m_tready(pix_ready)
	);

	wire unused_mm2s = mm2s_tlast ^ mm2s_tuser;
endmodule

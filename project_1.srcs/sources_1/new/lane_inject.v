`timescale 1ns / 1ps

// One RAW12 lane: H2C frame in, VDMA line stream out, VDMA read stream back
// to 48-bit pixels. The frame slot lives across the H2C clock and the pixel clock.
module lane_inject #(
	parameter LINE_BEATS = 360,
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
	output     [47:0]  pix_data,
	output             pix_valid,
	input              pix_ready,
	output             frame_ok,
	input              frame_start,
	input              frame_done,
	output             mm2s_fsync
);
	wire wr_ready;
	wire wr_start;
	wire wr_done;
	wire wr_abort;

	h2c_line_adapt #(
		.LINE_BEATS(LINE_BEATS),
		.FRAME_LINES(FRAME_LINES)
	) u_adapt (
		.clk(h2c_clk),
		.rst(h2c_rst),
		.wr_ready(wr_ready),
		.s_tdata(h2c_tdata),
		.s_tvalid(h2c_tvalid),
		.s_tlast(h2c_tlast),
		.s_tready(h2c_tready),
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
		.fsync(mm2s_fsync)
	);

	raw12_gearbox u_gear (
		.clk(pix_clk),
		.rst(pix_rst),
		.s_tdata(mm2s_tdata),
		.s_tvalid(mm2s_tvalid),
		.s_tready(mm2s_tready),
		.m_tdata(pix_data),
		.m_tvalid(pix_valid),
		.m_tready(pix_ready)
	);
endmodule

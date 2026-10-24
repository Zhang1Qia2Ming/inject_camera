`timescale 1ns / 1ps

// Three independent CSI-2 streams. Each lane has its own line/frame counter
// and advances only on its own tready. A lane starts a frame only when
// frame_ok is high, and image pixels come from pix_data. Embedded lines
// and their CRC stay inside this module. No lane waits for another.
module mipi_gen #
(
parameter H_Total		=	2274,
parameter H_Active	     =	960,
parameter V_Total		=	2200,
parameter V_Active	     =	2166,
parameter BYTENUM	     =	5760
)
(
 input  clk,
 output             	video_out_tlast	,
	 output     [95:0]   video_out_tuser	,
	output             	video_out_tvalid ,
	output       [47:0]  	video_out_tdata	 ,
	input              video_out_tready ,
 input              tx1_frame_ok,
 output             tx1_frame_start,
 output             tx1_frame_done,
 input       [47:0] tx1_pix_data,
 input              tx1_pix_valid,
 output             tx1_pix_ready,
 output             	video2_tlast	,
	 output     [95:0]   video2_tuser	,
	output             	video2_tvalid ,
	output       [47:0]  	video2_tdata	 ,
	input              video2_tready ,
 input              tx2_frame_ok,
 output             tx2_frame_start,
 output             tx2_frame_done,
 input       [47:0] tx2_pix_data,
 input              tx2_pix_valid,
 output             tx2_pix_ready,
 output             	video4_tlast	,
	 output     [95:0]   video4_tuser	,
	output             	video4_tvalid ,
	output       [47:0]  	video4_tdata	 ,
	input              video4_tready ,
 input              tx4_frame_ok,
 output             tx4_frame_start,
 output             tx4_frame_done,
 input       [47:0] tx4_pix_data,
 input              tx4_pix_valid,
 output             tx4_pix_ready
);
mipi_gen_lane #(
	.H_Total(H_Total), .H_Active(H_Active),
	.V_Total(V_Total), .V_Active(V_Active),
	.BYTENUM(BYTENUM)
) u_tx1 (
	.clk(clk),
	.tlast(video_out_tlast),
	.tuser(video_out_tuser),
	.tvalid(video_out_tvalid),
	.tdata(video_out_tdata),
	.tready(video_out_tready),
	.frame_ok(tx1_frame_ok),
	.frame_start(tx1_frame_start),
	.frame_done(tx1_frame_done),
	.pix_data(tx1_pix_data),
	.pix_valid(tx1_pix_valid),
	.pix_ready(tx1_pix_ready)
);
mipi_gen_lane #(
	.H_Total(H_Total), .H_Active(H_Active),
	.V_Total(V_Total), .V_Active(V_Active),
	.BYTENUM(BYTENUM)
) u_tx2 (
	.clk(clk),
	.tlast(video2_tlast),
	.tuser(video2_tuser),
	.tvalid(video2_tvalid),
	.tdata(video2_tdata),
	.tready(video2_tready),
	.frame_ok(tx2_frame_ok),
	.frame_start(tx2_frame_start),
	.frame_done(tx2_frame_done),
	.pix_data(tx2_pix_data),
	.pix_valid(tx2_pix_valid),
	.pix_ready(tx2_pix_ready)
);
mipi_gen_lane #(
	.H_Total(H_Total), .H_Active(H_Active),
	.V_Total(V_Total), .V_Active(V_Active),
	.BYTENUM(BYTENUM)
) u_tx4 (
	.clk(clk),
	.tlast(video4_tlast),
	.tuser(video4_tuser),
	.tvalid(video4_tvalid),
	.tdata(video4_tdata),
	.tready(video4_tready),
	.frame_ok(tx4_frame_ok),
	.frame_start(tx4_frame_start),
	.frame_done(tx4_frame_done),
	.pix_data(tx4_pix_data),
	.pix_valid(tx4_pix_valid),
	.pix_ready(tx4_pix_ready)
);
endmodule

module mipi_gen_lane #
(
parameter H_Total = 2274,
parameter H_Active = 960,
parameter V_Total = 2200,
parameter V_Active = 2166,
parameter BYTENUM = 5760
)
(
input              clk,
output             tlast,
output     [95:0]  tuser,
output             tvalid,
output     [47:0]  tdata,
input              tready,
input              frame_ok,
output             frame_start,
output             frame_done,
input      [47:0]  pix_data,
input              pix_valid,
output             pix_ready
);
localparam EMB_TOP = 13'd2;
localparam EMB_BOT = 13'd4;

reg        running = 1'b0;
reg [15:0] S1_frm_num = 16'd1;
reg [12:0] S1_pcnt = 13'd1, S1_lcnt = 13'd1;
wire       S1_active = (S1_pcnt <= H_Active) && (S1_lcnt <= V_Active);
wire       S1_sof = (S1_pcnt == 13'd1) && (S1_lcnt == 13'd1);
wire       frame_last = (S1_pcnt == H_Total) && (S1_lcnt == V_Total);
// Image beats wait for a pixel. Embedded beats and blanking do not.
wire       image_beat;
wire       beat_ready = image_beat ? pix_valid : 1'b1;
wire       step = running && tready && beat_ready;
wire       arm = !running && frame_ok && tready;

always @(posedge clk) begin
	if (arm)
		running <= 1'b1;
	else if (step && frame_last)
		running <= frame_ok;
end

assign frame_start = arm || (step && frame_last && frame_ok);
assign frame_done = step && frame_last;
assign pix_ready = image_beat && running && tready;

always @(posedge clk) begin
	if (step) begin
		if (S1_pcnt == H_Total)
			S1_pcnt <= 13'd1;
		else
			S1_pcnt <= S1_pcnt + 13'd1;
	end
end

always @(posedge clk) begin
	if (step && (S1_pcnt == H_Total) && (S1_lcnt == V_Total))
		S1_lcnt <= 13'd1;
	else if (step && (S1_pcnt == H_Total) && (S1_lcnt < V_Total))
		S1_lcnt <= S1_lcnt + 13'd1;
end

always @(posedge clk) begin
	if (step && (S1_lcnt == V_Total) && (S1_pcnt == H_Total))
		S1_frm_num <= S1_frm_num + 16'd1;
end

reg [15:0] p_byte_num;
always @(posedge clk)
	p_byte_num <= BYTENUM;

// OX08D10 top embedded line. One beat is four 12-bit pixels.
// CSI-2 RAW12 sends pixel[11:4] as the payload byte and pixel[3:0] in the pack nibble.
// With the low nibble 0, four pixels become the parser record
// DA, addr[15:8], 00, addr[7:0], value, 00.
// Frame sequence is {0x462A,0x462B,0x462C,0x462D}, big-endian.
// Groups 118..121 are the 0x300A/0x300B marker the parser searches for.
function [15:0] emb_addr;
	input [7:0] idx;
	begin
		case (idx)
			8'd0: emb_addr = 16'h3600;
			8'd1: emb_addr = 16'h3601;
			8'd2: emb_addr = 16'h3602;
			8'd3: emb_addr = 16'h3603;
			8'd4: emb_addr = 16'h3604;
			8'd5: emb_addr = 16'h3605;
			8'd6: emb_addr = 16'h3606;
			8'd7: emb_addr = 16'h3607;
			8'd8: emb_addr = 16'h360C;
			8'd9: emb_addr = 16'h360D;
			8'd10: emb_addr = 16'h360E;
			8'd11: emb_addr = 16'h360F;
			8'd12: emb_addr = 16'h300A;
			8'd13: emb_addr = 16'h300B;
			8'd14: emb_addr = 16'h300C;
			8'd15: emb_addr = 16'h302A;
			8'd16: emb_addr = 16'h462A;
			8'd17: emb_addr = 16'h462B;
			8'd18: emb_addr = 16'h462C;
			8'd19: emb_addr = 16'h462D;
			8'd20: emb_addr = 16'h3808;
			8'd21: emb_addr = 16'h3809;
			8'd22: emb_addr = 16'h380A;
			8'd23: emb_addr = 16'h380B;
			8'd24: emb_addr = 16'h380E;
			8'd25: emb_addr = 16'h380F;
			8'd26: emb_addr = 16'h380C;
			8'd27: emb_addr = 16'h380D;
			8'd28: emb_addr = 16'h388C;
			8'd29: emb_addr = 16'h388D;
			8'd30: emb_addr = 16'h350E;
			8'd31: emb_addr = 16'h350F;
			8'd32: emb_addr = 16'h35CE;
			8'd33: emb_addr = 16'h35CF;
			8'd34: emb_addr = 16'h351E;
			8'd35: emb_addr = 16'h351F;
			8'd36: emb_addr = 16'h3518;
			8'd37: emb_addr = 16'h3519;
			8'd38: emb_addr = 16'h351A;
			8'd39: emb_addr = 16'h359E;
			8'd40: emb_addr = 16'h359F;
			8'd41: emb_addr = 16'h3598;
			8'd42: emb_addr = 16'h3599;
			8'd43: emb_addr = 16'h359A;
			8'd44: emb_addr = 16'h35DE;
			8'd45: emb_addr = 16'h35DF;
			8'd46: emb_addr = 16'h35D8;
			8'd47: emb_addr = 16'h35D9;
			8'd48: emb_addr = 16'h35DA;
			8'd49: emb_addr = 16'h355E;
			8'd50: emb_addr = 16'h355F;
			8'd51: emb_addr = 16'h3558;
			8'd52: emb_addr = 16'h3559;
			8'd53: emb_addr = 16'h355A;
			8'd54: emb_addr = 16'h50D0;
			8'd55: emb_addr = 16'h50D1;
			8'd56: emb_addr = 16'h50D2;
			8'd57: emb_addr = 16'h50D3;
			8'd58: emb_addr = 16'h50D4;
			8'd59: emb_addr = 16'h50D5;
			8'd60: emb_addr = 16'h50D6;
			8'd61: emb_addr = 16'h50D7;
			8'd62: emb_addr = 16'h50D8;
			8'd63: emb_addr = 16'h50D9;
			8'd64: emb_addr = 16'h50DA;
			8'd65: emb_addr = 16'h50DB;
			8'd66: emb_addr = 16'h50DC;
			8'd67: emb_addr = 16'h50DD;
			8'd68: emb_addr = 16'h50DE;
			8'd69: emb_addr = 16'h50DF;
			8'd70: emb_addr = 16'h50E8;
			8'd71: emb_addr = 16'h50E9;
			8'd72: emb_addr = 16'h50EA;
			8'd73: emb_addr = 16'h50EB;
			8'd74: emb_addr = 16'h50EC;
			8'd75: emb_addr = 16'h50ED;
			8'd76: emb_addr = 16'h50EE;
			8'd77: emb_addr = 16'h50EF;
			8'd78: emb_addr = 16'h50E0;
			8'd79: emb_addr = 16'h50E1;
			8'd80: emb_addr = 16'h50E2;
			8'd81: emb_addr = 16'h50E3;
			8'd82: emb_addr = 16'h50E4;
			8'd83: emb_addr = 16'h50E5;
			8'd84: emb_addr = 16'h50E6;
			8'd85: emb_addr = 16'h50E7;
			8'd86: emb_addr = 16'h4D4E;
			8'd87: emb_addr = 16'h4D4F;
			8'd88: emb_addr = 16'h4D50;
			8'd89: emb_addr = 16'h4D51;
			8'd90: emb_addr = 16'h4D52;
			8'd91: emb_addr = 16'h4D53;
			8'd92: emb_addr = 16'h4F06;
			8'd93: emb_addr = 16'h4F07;
			8'd94: emb_addr = 16'h4F08;
			8'd95: emb_addr = 16'h4F09;
			8'd96: emb_addr = 16'h4F0A;
			8'd97: emb_addr = 16'h4F0B;
			8'd98: emb_addr = 16'h4F0C;
			8'd99: emb_addr = 16'h4F0D;
			8'd100: emb_addr = 16'h4F0E;
			8'd101: emb_addr = 16'h4F0F;
			8'd102: emb_addr = 16'h5019;
			8'd103: emb_addr = 16'h501A;
			8'd104: emb_addr = 16'h501B;
			8'd105: emb_addr = 16'h501D;
			8'd106: emb_addr = 16'h501E;
			8'd107: emb_addr = 16'h501F;
			8'd108: emb_addr = 16'h5025;
			8'd109: emb_addr = 16'h5026;
			8'd110: emb_addr = 16'h5027;
			8'd111: emb_addr = 16'h5021;
			8'd112: emb_addr = 16'h5022;
			8'd113: emb_addr = 16'h5023;
			8'd114: emb_addr = 16'h4026;
			8'd115: emb_addr = 16'h4027;
			8'd116: emb_addr = 16'h4028;
			8'd117: emb_addr = 16'h4029;
			8'd118: emb_addr = 16'h300A;
			8'd119: emb_addr = 16'h300B;
			8'd120: emb_addr = 16'h300A;
			8'd121: emb_addr = 16'h300B;
			default: emb_addr = 16'h0000;
		endcase
	end
endfunction

function [7:0] emb_value;
	input [7:0] idx;
	input [15:0] frm;
	begin
		case (idx)
			8'd12: emb_value = 8'h58;
			8'd13: emb_value = 8'h08;
			8'd14: emb_value = 8'h44;
			8'd16: emb_value = 8'h00;
			8'd17: emb_value = 8'h00;
			8'd18: emb_value = frm[15:8];
			8'd19: emb_value = frm[7:0];
			8'd118: emb_value = 8'h58;
			8'd119: emb_value = 8'h08;
			8'd120: emb_value = 8'h58;
			8'd121: emb_value = 8'h08;
			default: emb_value = 8'h00;
		endcase
	end
endfunction

// Reflected CRC-32C, one data byte. Polynomial 0x1EDC6F41, no final invert.
function [31:0] crc32c_byte;
	input [31:0] crc;
	input [7:0] data;
	integer i;
	reg [31:0] c;
	begin
		c = crc ^ {24'b0, data};
		for (i = 0; i < 8; i = i + 1)
			c = c[0] ? ((c >> 1) ^ 32'h82F63B78) : (c >> 1);
		crc32c_byte = c;
	end
endfunction

// While top line 1 beats 1..114 are on the wire, fold value bytes 0..113.
// Beats 115..118 carry the checksum. The parser stores each RAW12 pixel in a
// uint16 and hashes byte 7 of groups 0..120, then DA 30 0B 08 and four zeros
// from the unemitted group 122. Line 2 repeats the same bytes. The driver's
// CRC-32C residue is 0x48674BC7.
// Bottom lines are constant. The bottom parser starts at byte 0x1C70 (group
// 910) and, after the full marker match, hashes groups 0..912 plus
// DA 30 0B 08 00 00 00 00. Groups 906..909 hold that checksum.
reg [31:0] emb_crc = 32'hFFFFFFFF;
always @(posedge clk) begin
	if (step) begin
		if ((S1_pcnt == H_Total) && (S1_lcnt == V_Total))
			emb_crc <= 32'hFFFFFFFF;
		else if ((S1_lcnt == 13'd1) && (S1_pcnt >= 13'd1) && (S1_pcnt <= 13'd114))
			emb_crc <= crc32c_byte(emb_crc, emb_value(S1_pcnt[7:0] - 8'd1, S1_frm_num));
	end
end
wire [31:0] emb_csum = emb_crc ^ 32'hEDED056A;

// BGGR, 4 pixels per beat. tdata[11:0] is the first pixel on the line.
// lcnt starts at 1. Lines 1..2 are the top embedded header, lines
// (V_Active-3)..V_Active are the bottom embedded header. Image lines
// copy pix_data. The first image line is lcnt 3.
wire top_line = (S1_lcnt >= 13'd1) && (S1_lcnt <= EMB_TOP);
wire bot_line = (S1_lcnt > (V_Active - EMB_BOT)) && (S1_lcnt <= V_Active);
wire [9:0] grp = S1_pcnt[9:0] - 10'd1;
// Bottom groups 906..913 are the same records as top groups 114..121.
wire [9:0] emb_idx10 = top_line ? grp : (grp - 10'd792);
wire [7:0] emb_idx = emb_idx10[7:0];
// Bottom groups 906..913 reuse the top checksum/marker records 114..121.
wire [15:0] emb_reg = emb_addr(emb_idx);
wire [7:0] emb_byte =
	top_line ?
		((emb_idx == 8'd114) ? emb_csum[7:0] :
		 (emb_idx == 8'd115) ? emb_csum[15:8] :
		 (emb_idx == 8'd116) ? emb_csum[23:16] :
		 (emb_idx == 8'd117) ? emb_csum[31:24] :
		 emb_value(emb_idx, S1_frm_num)) :
		((grp == 10'd906) ? 8'hD8 :
		 (grp == 10'd907) ? 8'h93 :
		 (grp == 10'd908) ? 8'h79 :
		 (grp == 10'd909) ? 8'hE9 :
		 emb_value(emb_idx, 16'd0));
wire [11:0] emb_p0 = {8'hDA, 4'h0};
wire [11:0] emb_p1 = {emb_reg[15:8], 4'h0};
wire [11:0] emb_p2 = {emb_reg[7:0], 4'h0};
wire [11:0] emb_p3 = {emb_byte, 4'h0};
wire emb_beat = top_line ? ((S1_pcnt >= 13'd1) && (S1_pcnt <= 13'd122))
                         : ((S1_pcnt >= 13'd907) && (S1_pcnt <= 13'd914));
wire emb_region = top_line || bot_line;
wire [47:0] emb_data = (emb_region && emb_beat) ? {emb_p3, emb_p2, emb_p1, emb_p0}
                                                : 48'h000000000000;
assign image_beat = S1_active && !emb_region;

assign tdata  = emb_region ? emb_data : pix_data;
assign tuser  = {26'b0, 6'h2c, p_byte_num, S1_frm_num, {3'b0, S1_lcnt}, 15'h0, S1_sof};
assign tvalid = running && S1_active && beat_ready;
assign tlast  = tvalid && (S1_pcnt == H_Active);

endmodule

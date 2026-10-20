`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/14 14:02:13
// Design Name: 
// Module Name: mipi_gen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


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
	output     reg [47:0]  	video_out_tdata	 ,
	input              video_out_tready 
//	input          rstn
    );
// One CSI frame is 2 top embedded lines + 2160 image lines + 4 bottom
// embedded lines. V_Active is that total (2166), not the visible image.
localparam EMB_TOP = 13'd2;
localparam EMB_BOT = 13'd4;
    
//    reg [9:0] rst_cnt;
//    wire video_rstn;
//    always @ (posedge clk) 
//    if(!rstn)
//    rst_cnt <=0;
//    else if(!rst_cnt[9])
//    rst_cnt <=rst_cnt+1;
    
// assign video_rstn= rst_cnt[9];  
    
wire S1_sof, S1_tvalid,S1_tlast;
   reg S1_sof_dly,S1_tvalid_dly,S1_tlast_dly,S1_ready_dly;
   reg S1_start=0;
   reg [23:0] S1_tdata;
   reg [15:0] S1_line_num=1;
   reg [15:0] S1_frm_num=1;
   
   reg [12:0] S1_pcnt=1,S1_lcnt=1;
 
 assign S1_sof = ((S1_pcnt==1)&(S1_lcnt ==1))?1:0;
 assign S1_tlast =(S1_pcnt==H_Active)? 1:0;
 assign S1_tvalid =((S1_pcnt<=H_Active)&(S1_lcnt <=V_Active ))?1:0;
 
   always @ (posedge clk) begin
   if((!S1_ready_dly)&video_out_tready)
   S1_start <=1;
   end
   
   always @ (posedge clk) begin
   S1_ready_dly <= video_out_tready;
   S1_sof_dly <= S1_sof;
   S1_tlast_dly <= S1_tlast;
   end
   
    always @ (posedge clk) 
 if(S1_start&video_out_tready)
    begin
    if(S1_pcnt==H_Total)
        begin
        S1_pcnt <=1;
        end
     else 
        S1_pcnt <= S1_pcnt +1;
    end
 
always @(posedge clk)
if((S1_pcnt == H_Total)&&(S1_lcnt == V_Total))
	S1_lcnt <= 1;
else if((S1_pcnt == H_Total)&&(S1_lcnt < V_Total))
	S1_lcnt <= S1_lcnt + 1'b1;	
else
	S1_lcnt <= S1_lcnt; 
 
//assign line_num= {4'b0,lcnt};
always @(posedge clk)
if(!S1_tlast_dly&S1_tlast)
begin
if(S1_lcnt==V_Total)
S1_line_num <=1;
else
S1_line_num <= S1_line_num+1;

end 

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
	if (S1_start & video_out_tready) begin
		if ((S1_pcnt == H_Total) && (S1_lcnt == V_Total))
			emb_crc <= 32'hFFFFFFFF;
		else if ((S1_lcnt == 13'd1) && (S1_pcnt >= 13'd1) && (S1_pcnt <= 13'd114))
			emb_crc <= crc32c_byte(emb_crc, emb_value(S1_pcnt[7:0] - 8'd1, S1_frm_num));
	end
end
wire [31:0] emb_csum = emb_crc ^ 32'hEDED056A;

// RGGB, 4 pixels per beat. tdata[11:0] is the first pixel on the line.
// lcnt starts at 1. Lines 1..2 are the top embedded header, lines
// (V_Active-3)..V_Active are the bottom embedded header. The first image
// line is the B row (12'hC00); the next image line is black.
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
always @(*) begin
	if ((top_line || bot_line) && emb_beat)
		video_out_tdata = {emb_p3, emb_p2, emb_p1, emb_p0};
	else if (top_line || bot_line)
		video_out_tdata = 48'h000000000000;
	else if (S1_lcnt[0])
		video_out_tdata = 48'hC00000C00000;
	else
		video_out_tdata = 48'h000000000000;
end

  
    always @ (posedge clk) begin
    if((S1_lcnt==V_Total)&(S1_pcnt==H_Total))
    S1_frm_num <= S1_frm_num+1;
    end
   always @ (posedge clk) begin
   if(S1_sof)
   S1_tdata <= 24'b0;
   else if(S1_tvalid)
   S1_tdata <= S1_tdata+1;
   end    
 
 reg [15:0] p_byte_num;
 always @ (posedge clk)
 p_byte_num <=BYTENUM;
 
    assign    video_out_tlast=S1_tlast;
	// tuser[47:32] frame number, tuser[31:16] line number.
	// S1_frm_num increments once at the end of each frame, before the next SOF.
	// S1_lcnt is 1..V_Active while tvalid is high. S1_line_num also counts blanking lines.
	assign    video_out_tuser={26'b0,6'h2c,p_byte_num,S1_frm_num,{3'b0,S1_lcnt},15'h0,S1_sof};
	assign    video_out_tvalid=S1_tvalid;
//	assign    video_out_data={S1_tdata,S1_tdata};
    
endmodule

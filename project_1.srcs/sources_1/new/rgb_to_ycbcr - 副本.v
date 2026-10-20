`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:47:04 08/21/2012 
// Design Name: 
// Module Name:    rgb_to_ycbcr 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module rgb_to_ycbcr(
	input		clk,
	input		[95:0]	s_axi_tdata,
	output      reg s_axi_tready,


	input s_axi_tlast,
	input s_axi_tuser,
	input s_axi_tvalid,
	
	input  m_axi_tready,
	output reg m_axi_tlast,
	output reg m_axi_tuser,
	output reg m_axi_tvalid,
	output	[63:0]	m_axi_tdata

);

	wire		[11:0]	r1_i;
	wire		[11:0]	g1_i;
	wire		[11:0]	b1_i;
	wire		[11:0]	r2_i;
	wire		[11:0]	g2_i;
	wire		[11:0]	b2_i;
	
	wire		[11:0]	r3_i;
	wire		[11:0]	g3_i;
	wire		[11:0]	b3_i;
    wire		[11:0]	r4_i;
	wire		[11:0]	g4_i;
	wire		[11:0]	b4_i;
	
	assign r1_i={s_axi_tdata[23:16],4'b0};
	assign b1_i={s_axi_tdata[15:8],4'b0};
	assign g1_i={s_axi_tdata[7:0],4'b0};
    assign r2_i={s_axi_tdata[47:40],4'b0};
	assign b2_i={s_axi_tdata[39:32],4'b0};
	assign g2_i={s_axi_tdata[31:24],4'b0};
	
	assign r3_i={s_axi_tdata[71:64],4'b0};
	assign b3_i={s_axi_tdata[63:56],4'b0};
	assign g3_i={s_axi_tdata[55:48],4'b0};
    assign r4_i={s_axi_tdata[95:88],4'b0};
	assign b4_i={s_axi_tdata[87:80],4'b0};
	assign g4_i={s_axi_tdata[79:72],4'b0};

/**************   rgb to ycbcr   ************/
	reg	[13:0]	y1;
	reg	[13:0]	cb1;
	reg	[13:0]	cr1;

	reg	[19:0]	y1_r;
	reg	[19:0]	y1_g;
	reg	[19:0]	y1_b;

	reg	[19:0]	cb1_r;
	reg	[19:0]	cb1_g;
	reg	[19:0]	cb1_b;

	reg	[19:0]	cr1_r;
	reg	[19:0]	cr1_g;
	reg	[19:0]	cr1_b;
	
	reg	[13:0]	y2;
	reg	[13:0]	cb2;
	reg	[13:0]	cr2;

	reg	[19:0]	y2_r;
	reg	[19:0]	y2_g;
	reg	[19:0]	y2_b;

	reg	[19:0]	cb2_r;
	reg	[19:0]	cb2_g;
	reg	[19:0]	cb2_b;

	reg	[19:0]	cr2_r;
	reg	[19:0]	cr2_g;
	reg	[19:0]	cr2_b;

    reg	[13:0]	y3;
	reg	[13:0]	cb3;
	reg	[13:0]	cr3;

	reg	[19:0]	y3_r;
	reg	[19:0]	y3_g;
	reg	[19:0]	y3_b;

	reg	[19:0]	cb3_r;
	reg	[19:0]	cb3_g;
	reg	[19:0]	cb3_b;

	reg	[19:0]	cr3_r;
	reg	[19:0]	cr3_g;
	reg	[19:0]	cr3_b;
	
	reg	[13:0]	y4;
	reg	[13:0]	cb4;
	reg	[13:0]	cr4;

	reg	[19:0]	y4_r;
	reg	[19:0]	y4_g;
	reg	[19:0]	y4_b;

	reg	[19:0]	cb4_r;
	reg	[19:0]	cb4_g;
	reg	[19:0]	cb4_b;

	reg	[19:0]	cr4_r;
	reg	[19:0]	cr4_g;
	reg	[19:0]	cr4_b;

	reg last_r0,last_r1,last_r2,last_r3,last_r4,last_r5;
	reg user_r0,user_r1,user_r2,user_r3,user_r4,user_r5;
	reg valid_r0,valid_r1,valid_r2,valid_r3,valid_r4,valid_r5;
    reg ready_r0,ready_r1,ready_r2,ready_r3;
	

	
	reg odd_even=0;
	reg last_dly;
	always @(posedge clk)
	last_dly <=s_axi_tlast;
	
	always @(posedge clk)
	if(!last_dly&s_axi_tlast)
	odd_even <= 0;
	else if(s_axi_tvalid)
	odd_even <= !odd_even;
	
	always @(posedge clk)
	begin
		y1_r  <= (32*r1_i+16*r1_i) + (4*r1_i+2*r1_i);
		y1_g  <= (256*g1_i-64*g1_i) - (8*g1_i+g1_i);
		y1_b  <= 16*b1_i + 2*b1_i + b1_i;
		cb1_b <= 128*b1_i + 2*b1_i;
		cb1_r <= 32*r1_i - 2*r1_i;
		cb1_g <= 64*g1_i + 32*g1_i + 4*g1_i;
		cr1_r <= (128*r1_i+4*r1_i) + (2*r1_i+r1_i);
		cr1_g <= 128*g1_i - 8*g1_i + 2*g1_i;
		cr1_b <= 8*b1_i + 4*b1_i + b1_i;
		
		
		y2_r  <= (32*r2_i+16*r2_i) + (4*r2_i+2*r2_i);
		y2_g  <= (256*g2_i-64*g2_i) - (8*g2_i+g2_i);
		y2_b  <= 16*b2_i + 2*b2_i + b2_i;
		cb2_b <= 128*b2_i + 2*b2_i;
		cb2_r <= 32*r2_i - 2*r2_i;
		cb2_g <= 64*g2_i + 32*g2_i + 4*g2_i;
		cr2_r <= (128*r2_i+4*r2_i) + (2*r2_i+r2_i);
		cr2_g <= 128*g2_i - 8*g2_i + 2*g2_i;
		cr2_b <= 8*b2_i + 4*b2_i + b2_i;
		
		y3_r  <= (32*r3_i+16*r3_i) + (4*r3_i+2*r3_i);
		y3_g  <= (256*g3_i-64*g3_i) - (8*g3_i+g3_i);
		y3_b  <= 16*b3_i + 2*b3_i + b3_i;
		cb3_b <= 128*b3_i + 2*b3_i;
		cb3_r <= 32*r3_i - 2*r3_i;
		cb3_g <= 64*g3_i + 32*g3_i + 4*g3_i;
		cr3_r <= (128*r3_i+4*r3_i) + (2*r3_i+r3_i);
		cr3_g <= 128*g3_i - 8*g3_i + 2*g3_i;
		cr3_b <= 8*b3_i + 4*b3_i + b3_i;
		
		
		y4_r  <= (32*r4_i+16*r4_i) + (4*r4_i+2*r4_i);
		y4_g  <= (256*g4_i-64*g4_i) - (8*g4_i+g4_i);
		y4_b  <= 16*b4_i + 2*b4_i + b4_i;
		cb4_b <= 128*b4_i + 2*b4_i;
		cb4_r <= 32*r4_i - 2*r4_i;
		cb4_g <= 64*g4_i + 32*g4_i + 4*g4_i;
		cr4_r <= (128*r4_i+4*r4_i) + (2*r4_i+r4_i);
		cr4_g <= 128*g4_i - 8*g4_i + 2*g4_i;
		cr4_b <= 8*b4_i + 4*b4_i + b4_i;
		
		
		last_r0 <= s_axi_tlast;
		user_r0 <= s_axi_tuser;
		valid_r0 <= s_axi_tvalid;
		ready_r0 <=m_axi_tready;
		
		last_r1 <= last_r0;
		user_r1 <= user_r0;
		valid_r1 <= valid_r0;
		ready_r1 <=ready_r0;
		
		last_r2 <= last_r1;
		user_r2 <= user_r1;
		valid_r2 <= valid_r1;
        ready_r2 <=ready_r1;
		
		last_r3 <= last_r2;
		user_r3 <= user_r2;
		valid_r3 <= valid_r2;
        ready_r3 <=ready_r2;

	end

	reg	[13:0]	y1_t;
	reg	[12:0]	cb1_t;
	reg	[12:0]	cr1_t;

	reg	cr1_pn;
	reg	cb1_pn;

	reg	[13:0]	y2_t;
	reg	[12:0]	cb2_t;
	reg	[12:0]	cr2_t;

	reg	cr2_pn;
	reg	cb2_pn;
	
	reg	[13:0]	y3_t;
	reg	[12:0]	cb3_t;
	reg	[12:0]	cr3_t;

	reg	cr3_pn;
	reg	cb3_pn;

	reg	[13:0]	y4_t;
	reg	[12:0]	cb4_t;
	reg	[12:0]	cr4_t;

	reg	cr4_pn;
	reg	cb4_pn;
	always @(posedge clk)
	if(valid_r0&ready_r0)
	begin
		y1_t <= y1_r/256 + y1_g/256 + y1_b/256;
		
		if((cb1_b/256) > (cb1_r/256 + cb1_g/256))begin
			cb1_t  <= cb1_b/256 - (cb1_r/256 + cb1_g/256);
			cb1_pn <= 1'b0;
		end
		else begin
			cb1_t  <= cb1_r/256 + cb1_g/256 - cb1_b/256;
			cb1_pn <= 1'b1;
		end 
		
		if((cr1_r/256) > (cr1_g/256 + cr1_b/256))begin
			cr1_t  <= cr1_r/256 - (cr1_g/256 + cr1_b/256);
			cr1_pn <= 1'b0;
		end
		else begin
			cr1_t  <= cr1_g/256 + cr1_b/256 - cr1_r/256;
			cr1_pn <= 1'b1;
		end 	
	end
	
		always @(posedge clk)
		if(valid_r0&ready_r0)
	begin
		y2_t <= y2_r/256 + y2_g/256 + y2_b/256;
		
		if((cb2_b/256) > (cb2_r/256 + cb2_g/256))begin
			cb2_t  <= cb2_b/256 - (cb2_r/256 + cb2_g/256);
			cb2_pn <= 1'b0;
		end
		else begin
			cb2_t  <= cb2_r/256 + cb2_g/256 - cb2_b/256;
			cb2_pn <= 1'b1;
		end 
		
		if((cr2_r/256) > (cr2_g/256 + cr2_b/256))begin
			cr2_t  <= cr2_r/256 - (cr2_g/256 + cr2_b/256);
			cr2_pn <= 1'b0;
		end
		else begin
			cr2_t  <= cr2_g/256 + cr2_b/256 - cr2_r/256;
			cr2_pn <= 1'b1;
		end 	
	end


always @(posedge clk)
	if(valid_r0&ready_r0)
	begin
		y3_t <= y3_r/256 + y3_g/256 + y3_b/256;
		
		if((cb3_b/256) > (cb3_r/256 + cb3_g/256))begin
			cb3_t  <= cb3_b/256 - (cb3_r/256 + cb3_g/256);
			cb3_pn <= 1'b0;
		end
		else begin
			cb3_t  <= cb3_r/256 + cb3_g/256 - cb3_b/256;
			cb3_pn <= 1'b1;
		end 
		
		if((cr3_r/256) > (cr3_g/256 + cr3_b/256))begin
			cr3_t  <= cr3_r/256 - (cr3_g/256 + cr3_b/256);
			cr3_pn <= 1'b0;
		end
		else begin
			cr3_t  <= cr3_g/256 + cr3_b/256 - cr3_r/256;
			cr3_pn <= 1'b1;
		end 	
	end
	
		always @(posedge clk)
		if(valid_r0&ready_r0)
	begin
		y4_t <= y4_r/256 + y4_g/256 + y4_b/256;
		
		if((cb4_b/256) > (cb4_r/256 + cb4_g/256))begin
			cb4_t  <= cb4_b/256 - (cb4_r/256 + cb4_g/256);
			cb4_pn <= 1'b0;
		end
		else begin
			cb4_t  <= cb4_r/256 + cb4_g/256 - cb4_b/256;
			cb4_pn <= 1'b1;
		end 
		
		if((cr4_r/256) > (cr4_g/256 + cr4_b/256))begin
			cr4_t  <= cr4_r/256 - (cr4_g/256 + cr4_b/256);
			cr4_pn <= 1'b0;
		end
		else begin
			cr4_t  <= cr4_g/256 + cr4_b/256 - cr4_r/256;
			cr4_pn <= 1'b1;
		end 	
	end


	reg	[13:0]	y1_t1;
	reg	[14:0]	cb1_t1;
	reg	[14:0]	cr1_t1;

	reg	cr1_pn1;
	reg	cb1_pn1;
	
	reg	[13:0]	y2_t1;
	reg	[14:0]	cb2_t1;
	reg	[14:0]	cr2_t1;

	reg	cr2_pn1;
	reg	cb2_pn1;

    reg	[13:0]	y3_t1;
	reg	[14:0]	cb3_t1;
	reg	[14:0]	cr3_t1;

	reg	cr3_pn1;
	reg	cb3_pn1;
	
	reg	[13:0]	y4_t1;
	reg	[14:0]	cb4_t1;
	reg	[14:0]	cr4_t1;

	reg	cr4_pn1;
	reg	cb4_pn1;

	always @(posedge clk)
	if(valid_r1&ready_r1)
	begin
		y1_t1		<= y1_t;
		cb1_t1		<= cb1_t;
		cr1_t1		<= cr1_t;
		cr1_pn1	<= cr1_pn;
		cb1_pn1	<= cb1_pn;
	end

	always @(posedge clk)
	if(valid_r1&ready_r1)
	begin
		y2_t1		<= y2_t;
		cb2_t1		<= cb2_t;
		cr2_t1		<= cr2_t;
		cr2_pn1	<= cr2_pn;
		cb2_pn1	<= cb2_pn;
	end
	
	always @(posedge clk)
	if(valid_r1&ready_r1)
	begin
		y3_t1		<= y3_t;
		cb3_t1		<= cb3_t;
		cr3_t1		<= cr3_t;
		cr3_pn1	<= cr3_pn;
		cb3_pn1	<= cb3_pn;
	end

	always @(posedge clk)
	if(valid_r1&ready_r1)
	begin
		y4_t1		<= y4_t;
		cb4_t1		<= cb4_t;
		cr4_t1		<= cr4_t;
		cr4_pn1	<= cr4_pn;
		cb4_pn1	<= cb4_pn;
	end
	
	always @(posedge clk)
	if(valid_r2&ready_r2)
	begin
		y1 <= y1_t1;
		if(cb1_pn1 == 1'b0)begin
			if(cb1_t1 >= 12'h7FF)
				cb1 <= 12'hFFF;
			else
				cb1 <= cb1_t1 + 12'h800;
		end
		else begin
			if(cb1_t1 >= 12'h800)
				cb1 <= 12'h000;
			else
				cb1 <= 12'h800 - cb1_t1;
		end
		
		if(cr1_pn1 == 1'b0)begin
			if(cr1_t1 >= 12'h7FF)
				cr1 <= 12'hFFF;
			else
				cr1 <= cr1_t1 + 12'h800;
		end
		else begin
			if(cr1_t1 >= 12'h800)
				cr1 <= 12'h000;
			else
				cr1 <= 12'h800 - cr1_t1;
		end
	end

	always @(posedge clk)
	if(valid_r2&ready_r2)
	begin
		y2 <= y2_t1;
		if(cb2_pn1 == 1'b0)begin
			if(cb2_t1 >= 12'h7FF)
				cb2 <= 12'hFFF;
			else
				cb2 <= cb2_t1 + 12'h800;
		end
		else begin
			if(cb2_t1 >= 12'h800)
				cb2 <= 12'h000;
			else
				cb2 <= 12'h800 - cb2_t1;
		end
		
		if(cr2_pn1 == 1'b0)begin
			if(cr2_t1 >= 12'h7FF)
				cr2 <= 12'hFFF;
			else
				cr2 <= cr2_t1 + 12'h800;
		end
		else begin
			if(cr2_t1 >= 12'h800)
				cr2 <= 12'h000;
			else
				cr2 <= 12'h800 - cr2_t1;
		end
	end
	
	always @(posedge clk)
	if(valid_r2&ready_r2)
	begin
		y3 <= y3_t1;
		if(cb3_pn1 == 1'b0)begin
			if(cb3_t1 >= 12'h7FF)
				cb3 <= 12'hFFF;
			else
				cb3 <= cb3_t1 + 12'h800;
		end
		else begin
			if(cb3_t1 >= 12'h800)
				cb3 <= 12'h000;
			else
				cb3 <= 12'h800 - cb3_t1;
		end
		
		if(cr3_pn1 == 1'b0)begin
			if(cr3_t1 >= 12'h7FF)
				cr3 <= 12'hFFF;
			else
				cr3 <= cr3_t1 + 12'h800;
		end
		else begin
			if(cr3_t1 >= 12'h800)
				cr3 <= 12'h000;
			else
				cr3 <= 12'h800 - cr3_t1;
		end
	end

	always @(posedge clk)
	if(valid_r2&ready_r2)
	begin
		y4 <= y4_t1;
		if(cb4_pn1 == 1'b0)begin
			if(cb4_t1 >= 12'h7FF)
				cb4 <= 12'hFFF;
			else
				cb4 <= cb4_t1 + 12'h800;
		end
		else begin
			if(cb4_t1 >= 12'h800)
				cb4 <= 12'h000;
			else
				cb4 <= 12'h800 - cb4_t1;
		end
		
		if(cr4_pn1 == 1'b0)begin
			if(cr4_t1 >= 12'h7FF)
				cr4 <= 12'hFFF;
			else
				cr4 <= cr4_t1 + 12'h800;
		end
		else begin
			if(cr4_t1 >= 12'h800)
				cr4 <= 12'h000;
			else
				cr4 <= 12'h800 - cr4_t1;
		end
	end
	
	reg [9:0] y1_o,y2_o,y3_o,y4_o;
	reg [9:0] c1_o,c2_o,c3_o,c4_o;	
	
	always @(posedge clk)
	begin
	    y1_o <= y1[11:2];
	    y2_o <= y2[11:2];
	    y3_o <= y3[11:2];
	    y4_o <= y4[11:2];
		m_axi_tlast <= last_r3;
		m_axi_tuser <= user_r3;
		m_axi_tvalid <= valid_r3;
		s_axi_tready <= ready_r3;
		
		c1_o <= cb1[11:2];
		c2_o <= cr2[11:2];
		c3_o <= cb3[11:2];
		c4_o <= cr4[11:2];
	end
	
	
	assign m_axi_tdata={c1_o[9:2],y1_o[9:2],c2_o[9:2],y2_o[9:2],c3_o[9:2],y3_o[9:2],c4_o[9:2],y4_o[9:2]};
	
endmodule

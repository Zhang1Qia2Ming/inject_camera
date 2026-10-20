`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/09/04 15:31:22
// Design Name: 
// Module Name: pcie_to_mipi_withsmos
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


module pcie_to_mipi_withsmos
(
	// axis
	input axis_clk,
	input axis_aresetn,

	// axis
	input [63:0]      s_axis_tdata,
	input               s_axis_tvalid,
	input               s_axis_tlast,
	input               s_axis_tuser,
	output reg          s_axis_tready,//Êä³ö¸øpcie

	// video data       
	input               video_clk,
	input               video_rst,
	                    
	input               video_in_tlast,
	input               video_in_tuser,
	input               video_in_tvalid,
                       	
	output             	video_out_tlast	,
	 output  [95:0]       video_out_tuser	,
	output             	video_out_tvalid ,
	output     [167:0]  	video_out_data	  ,
	input              video_out_tready 
//	input              reg_channel_sel,
//	input              reg_star_app
//	output      reg [15:0] pcie_frm_num    
);

wire             pcie_sof		 		;
	wire             pcie_last	 		;
	reg             pcie_valid	 		;
	wire     [63:0] pcie_data				;
    wire    pcie_ready;


reg  [65:0] fifo_din;
reg           fifo_wen;
wire           fifo_ren;
wire [65:0] fifo_dout;
wire          fifo_full;
wire          fifo_empty;
wire          fifo_almost_full;
wire        fifo_almost_empty;

reg [19:0] video_in_cnt;

reg [15:0] pcie_frmrate=0;
reg [15:0] cmos_frmrate=0;
reg video_in_tuser_dly;

 always @ (posedge video_clk) 
 video_in_tuser_dly <= video_in_tuser;

reg s_axis_tuser_dly;
 always @ (posedge video_clk) 
 s_axis_tuser_dly <= s_axis_tuser;

always @(posedge axis_clk )
begin
if(!s_axis_tuser_dly&s_axis_tuser)
video_in_cnt <= 0;
else if(s_axis_tready & s_axis_tvalid)
video_in_cnt <= video_in_cnt+1;
end

always @(posedge axis_clk or negedge axis_aresetn)
begin
	if(!axis_aresetn)
		s_axis_tready <= 1'b1;
	else if(fifo_almost_full)
		s_axis_tready <= 1'b0;
	else
		s_axis_tready <= 1'b1;
end

always @(posedge axis_clk or negedge axis_aresetn)
begin
	if(!axis_aresetn)
		fifo_wen <= 1'b0;
	else if(s_axis_tready & s_axis_tvalid)
		fifo_wen <= 1'b1;
	else
		fifo_wen <= 1'b0;

end
always @(posedge axis_clk or negedge axis_aresetn)
begin
	if(!axis_aresetn)
		fifo_din <= 0;
	else
		fifo_din <= {s_axis_tuser,s_axis_tlast,s_axis_tdata};
end



pcie_loopback_fifo u_pcie_loopback_fifo (
  .rst(!axis_aresetn),                    // input wire rst
  .wr_clk(axis_clk),              // input wire wr_clk
  .rd_clk(video_clk),              // input wire rd_clk
  .din(fifo_din),                    // input wire [49 : 0] din
  .wr_en(fifo_wen),                // input wire wr_en
  .rd_en(fifo_ren),                // input wire rd_en
  .dout(fifo_dout),                  // output wire [49 : 0] dout
  .full(),                  // output wire full
  .almost_full(),    // output wire almost_full
  .empty(),                // output wire empty
  .almost_empty(),  // output wire almost_empty
  .valid(),
  .prog_full(fifo_almost_full),        // output wire prog_full
  .prog_empty(fifo_almost_empty),      // output wire prog_empty
  .wr_rst_busy(),    // output wire wr_rst_busy
  .rd_rst_busy()    // output wire rd_rst_busy
);

reg [12:0] H_Total		=	3896;//1650;
parameter H_Active	     =	480;//1280;
parameter V_Total		=	1540;//750;
parameter V_Active	     =	1536;//720;

reg [11:0] pcie_pcnt=1,pcie_lcnt=1;
reg ready_dly;

wire fifo_sof;
reg fifo_sof_dly;

reg start=0;

    always @ (posedge video_clk) 
    if(!fifo_sof_dly&fifo_sof&(!start))
    begin
    start <=1;
  pcie_pcnt <= 2;
  end
else if((!fifo_almost_empty)&pcie_ready)
    begin
    if(pcie_pcnt==H_Total)
        begin
        pcie_pcnt <=1;

        end
     else begin

        
        pcie_pcnt <= pcie_pcnt +1;
        end
    end
    else begin
     pcie_pcnt <= pcie_pcnt;
    end
    
// reg pcie_sof_dly;
// always @(posedge video_clk)
//pcie_sof_dly <= fifo_sof;

always @(posedge video_clk)
 if(!fifo_sof_dly&fifo_sof)
  pcie_lcnt <= 1;
 else if((!fifo_almost_empty)&pcie_ready)
 begin
 if((pcie_pcnt == H_Total)&&(pcie_lcnt == V_Total))
	pcie_lcnt <= 1;
else if((pcie_pcnt == H_Total))
	pcie_lcnt <= pcie_lcnt + 1'b1;	
else
	pcie_lcnt <= pcie_lcnt; 
end

assign fifo_sof = fifo_dout[65];
// assign pcie_sof = fifo_sof;//fifo_dout[49];
 assign pcie_last =fifo_dout[64];
 assign fifo_ren =((pcie_pcnt<=H_Active)&(pcie_lcnt <=V_Active )&(!fifo_almost_empty)&pcie_ready)?1:0;
assign pcie_data =fifo_dout[63:0];

always @(posedge video_clk)
if((!fifo_almost_empty)&pcie_ready)
pcie_valid <=fifo_ren;


assign pcie_sof=(!fifo_sof_dly&fifo_sof)?1:0;

always @(posedge video_clk)
fifo_sof_dly <= fifo_sof;

//always @(posedge video_clk)
//if(!fifo_sof_dly&fifo_sof)
//pcie_sof <=1;
//else if(pcie_ready&pcie_valid)
//pcie_sof <=0;


reg [19:0] pcie_data_cnt;

reg pcie_sof_dly;
always @(posedge video_clk)
pcie_sof_dly <= pcie_sof;

always @(posedge video_clk)
if(!pcie_sof_dly&pcie_sof)
pcie_data_cnt <= 0;
else if(pcie_valid&pcie_ready)
pcie_data_cnt<= pcie_data_cnt+1;

wire [63 : 0] m_mipi_tdata;
wire [0 : 0] m_mipi_tuser;
wire m_mipi_tlast;
wire m_mipi_tvalid;

axis_pcie_mipi_fifo u_axis_pcie_mipi_fifo (
  .s_axis_aresetn(axis_aresetn),  // input wire s_axis_aresetn
  .s_axis_aclk(video_clk),        // input wire s_axis_aclk
  .s_axis_tvalid(pcie_valid),    // input wire s_axis_tvalid
  .s_axis_tready(pcie_ready),    // output wire s_axis_tready
  .s_axis_tdata(pcie_data),      // input wire [63 : 0] s_axis_tdata
  .s_axis_tlast(pcie_last),      // input wire s_axis_tlast
  .s_axis_tuser(pcie_sof),      // input wire [0 : 0] s_axis_tuser
  .m_axis_aclk(video_clk),        // input wire m_axis_aclk
  .m_axis_tvalid(m_mipi_tvalid),    // output wire m_axis_tvalid
  .m_axis_tready(video_out_tready),    // input wire m_axis_tready
  .m_axis_tdata(m_mipi_tdata),      // output wire [63 : 0] m_axis_tdata
  .m_axis_tlast(m_mipi_tlast),      // output wire m_axis_tlast
  .m_axis_tuser(m_mipi_tuser)      // output wire [0 : 0] m_axis_tuser
);


assign video_out_data = {56'b0,m_mipi_tdata[63:56],6'b0,m_mipi_tdata[55:48],6'b0,m_mipi_tdata[47:40],6'b0,m_mipi_tdata[39:32],6'b0,m_mipi_tdata[31:24],6'b0,m_mipi_tdata[23:16],6'b0,m_mipi_tdata[15:8],6'b0,m_mipi_tdata[7:0],6'b0};
assign video_out_tuser = {32'b0,16'd3840,16'b1,16'b1,15'h1e,m_mipi_tuser};
assign video_out_tvalid =m_mipi_tvalid;
assign video_out_tlast =m_mipi_tlast;




ila_0 u_ila0 (
	.clk(video_clk), // input wire clk

                                       
	.probe0(pcie_data_cnt), // input wire [47:0]  probe0  
	.probe1(pcie_valid), // input wire [19:0]  probe1 
//	.probe2(relative_num), // input wire [0:0]  probe2
	.probe2(pcie_last),
	.probe3(pcie_ready),
//	.probe5(cmos_is_active),
	.probe4(pcie_sof),
	.probe5(pcie_data)

);

endmodule
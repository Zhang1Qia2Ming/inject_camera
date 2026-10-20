`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/17 14:53:49
// Design Name: 
// Module Name: cout
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


module cout(
    input clk,
    input tuser,
    input tvalid,
    input   tready,
    output  reg vs,
    output reg[21:0] cnt
    );
 
 reg tuser_dly;
 always @(posedge clk)
 tuser_dly <=   tuser;
  
  always @(posedge clk)
  if(!tuser_dly&tuser)
  cnt <=0;
  else if(tvalid&tready)
  cnt<=cnt+1;  
 
 always @(posedge clk)
 if(cnt<50000)
 vs <=0;
 else
 vs <=1;
    
endmodule

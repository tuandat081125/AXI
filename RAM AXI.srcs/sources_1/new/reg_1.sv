`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/13/2026 06:53:40 PM
// Design Name: 
// Module Name: reg_1
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


module reg_1(
  input clk,
  input logic st,
  input logic rst,
  input logic clr,
  output logic dout
  );
 
  always_ff @(posedge clk)
    if(rst)
      dout <= 1'b0;
    else if(clr)
      dout <= 1'b0;
    else if(st)
      dout <= 1'b1;
    else
      dout <= dout;
endmodule

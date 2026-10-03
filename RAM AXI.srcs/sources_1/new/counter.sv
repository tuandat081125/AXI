`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/20/2026 11:19:17 PM
// Design Name: 
// Module Name: counter
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


module counter(
  input logic clk,
  input logic [7:0] din,
  input logic rst,
  input logic ld,
  input logic incr,
  input logic decr,
  output logic zr
);

logic [7:0] cnt;

always @(posedge clk)
  if(rst)
    cnt <= 0;
  else if(ld)
    cnt <= din;
  else if(incr)
    cnt <= cnt + 1;
  else if(decr)
    cnt <= cnt - 1;
  else
    cnt <= cnt;
    
assign zr = ~(|cnt);
  
  
endmodule

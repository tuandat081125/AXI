`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/10/2026 10:30:41 PM
// Design Name: 
// Module Name: ram_axi_slave
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


module ram_axi_slave
( 
  input logic addra,
  input logic valid_addra,
  output logic ready_addra,
  
  output logic douta,
  output logic resp_din,
  output logic valid_douta,
  input logic ready_douta,
  
  input logic addrb,
  input logic valid_addrb,
  output logic ready_addrb,
  
  input logic wrb,
  input logic valid_wrb,
  output logic ready_wrb,
  
  input logic dinb,
  input logic valid_dinb,
  output logic ready_dinb,
  
  output logic respwr,
  output logic valid_respwr,
  input logic ready_respwr,
  
  input logic rst,
  input logic clka,
  input logic clkb
  
  output logic clkb_out,
  output logic [ADDR_WIDTH-1:0] addrb_out,
  output logic enb_out,
  output logic wrtb_out,
  output logic [DATA_WIDTH-1:0] dinb_out
);
  
  typedef enum logic [1:0] {
    IDLE_A,
    READ_A,
    WRITE_A,
    RESP_A
  } state_a;
  
  typedef enum logic [1:0] {
    IDLE_B,
    WRITE_B
  } state_b;
  
  state_a next_stateA;
  state_a current_stateA;
  
  state_b next_stateB;
  state_b current_stateB;
  
  //State change
  always_ff @(posedge clka)
    begin
      if(rst)
        current_stateA <= IDLE_A;
      else
        current_stateA <= next_stateA;
    end
    
  always_ff @(posedge clkb)
    begin
      if(rst)
        current_stateB <= IDLE_B;
      else
        current_stateB <= next_stateB;
    end
    
  //State change logic
  always_ff @(posedge clka)
    begin
      case(current_stateA)
        IDLE_A:
          begin
          if(valid_addra & ready_addra)
            next_stateA <= READ_A;
          end
        READ_A:
          begin
          next_stateA <= WRITE_A;
          end
        WRITE_A:
          begin
          next_stateA <= RESP_A;
          end
        RESP_A:
          begin
          next_stateA <= IDLE_A;
          end
        default:
          begin
          next_stateA <= IDLE_A;
          end
      endcase 
    end
    
  //State logic
  always_comb
    begin
      case(current_stateA)
        IDLE_A:
          begin
          end
        READ_A:
          begin
          addr
          end
        WRITE_A:
          begin
          next_stateA <= RESP_A;
          end
        RESP_A:
          begin
          next_stateA <= IDLE_A;
          end
        default:
          begin
          next_stateA <= IDLE_A;
          end
  
    
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/10/2026 08:53:14 PM
// Design Name: 
// Module Name: ram
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

//v1: nhầm khối 2 của fsm thành sequential 
//v2: viết trộn datapath và controlpath
//v3: tối ưu chu kỳ, bỏ bớt fsm
//v4: lỗi wrb, lỗi viết code addra
//v5: đổi rst thành clr, tách 2 loại


module ram_axi_lite_slave #(
  parameter DATA_WIDTH = 16,
  parameter DEPTH = 1024,
  parameter ADDR_WIDTH = 10
)
( 
  input logic [ADDR_WIDTH-1:0] addra,
  input logic valid_addra,
  output logic ready_addra,
  
  output logic [DATA_WIDTH-1:0] douta,
  output logic [1:0] resprd,
  output logic valid_douta,
  input logic ready_douta,
  
  input logic [ADDR_WIDTH-1:0] addrb,
  input logic valid_addrb,
  output logic ready_addrb,
  
  input logic [DATA_WIDTH-1:0] dinb,
  input logic valid_dinb,
  output logic ready_dinb,
  
  output logic [1:0] respwr,
  output logic valid_respwr,
  input logic ready_respwr,
  
  input logic rst,
  input logic clk
);

  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
  
  logic [ADDR_WIDTH-1:0] addra_reg;
  logic [DATA_WIDTH-1:0] douta_reg;
  logic [ADDR_WIDTH-1:0] addrb_reg;
  logic [DATA_WIDTH-1:0] dinb_reg;
  logic respwr_reg;
  
  logic wrb;
  
  logic addrb_flag;
  logic dinb_flag;
  
  logic ld_dinb;
  logic ld_addrb;
  logic ld_addra;
  logic done_respwr;
  logic done_resprd;
  
  logic st_raddra;
  logic rst_raddra;
  logic clr_raddra;

  logic st_vdouta;
  logic rst_vdouta;
  logic clr_vdouta;

  logic st_raddrb;
  logic rst_raddrb;
  logic clr_raddrb;
  logic st_rdinb;
  logic rst_rdinb;
  logic clr_rdinb;
  logic st_vrespwr;
  logic rst_vrespwr;
  logic clr_vrespwr;
  logic st_addrb_flag;
  logic rst_addrb_flag;
  logic clr_addrb_flag;
  logic st_dinb_flag;
  logic rst_dinb_flag;
  logic clr_dinb_flag;
  
  assign rst_raddra     = rst;
  assign rst_vdouta     = rst;
  assign rst_raddrb     = rst;
  assign rst_rdinb      = rst;
  assign rst_vrespwr    = rst;
  assign rst_addrb_flag = rst;
  assign rst_dinb_flag  = rst;
  
  typedef enum logic [1:0] {
    IDLE_A,
    READ_A
  } state_a;
  
  typedef enum logic [1:0] {
    IDLE_B,
    WRITE_B
  } state_b;
  
  state_a next_stateA;
  state_a current_stateA;
  
  state_b next_stateB;
  state_b current_stateB;
  
  //Port A logic
  always_ff @(posedge clk)
    begin
      if(rst)
        douta_reg <= 0;
      else
        douta_reg <= mem[addra_reg];
    end
    
  assign douta = douta_reg;
  
  //Port B logic
  always_ff @(posedge clk)
    begin
      if(wrb)
        mem[addrb_reg] <= dinb_reg;
    end
  
  //Register Datapath  
  always_ff @(posedge clk)
    begin
      if(ld_addra)
        addra_reg <= addra;
    end
    
  always_ff @(posedge clk)
    begin
      if(ld_dinb)
        dinb_reg <= dinb;
    end
  
  always_ff @(posedge clk)
    begin
      if(ld_addrb)
        addrb_reg <= addrb;
    end
  
  always_ff @(posedge clk)
    begin
      if(done_respwr)
        respwr <= 2'b00;
    end
    
  always_ff @(posedge clk)
    begin
      if(done_resprd)
        resprd <= 2'b00;
    end
   
  assign ld_addrb = ready_addrb && valid_addrb;
  assign ld_dinb = ready_dinb && valid_dinb;
  assign wrb = addrb_flag && dinb_flag;
    
  reg_2 raddra_reg (clk, st_raddra, rst_raddra, clr_raddra, ready_addra);
  reg_1 vdouta_reg (clk, st_vdouta, rst_vdouta, clr_vdouta, valid_douta);
  reg_2 raddrb_reg (clk, st_raddrb, rst_raddrb, clr_raddrb, ready_addrb);
  reg_2 rdinb_reg (clk, st_rdinb, rst_rdinb, clr_rdinb, ready_dinb);
  reg_1 vrespwr_reg (clk, st_vrespwr, rst_vrespwr, clr_vrespwr, valid_respwr);
  reg_1 addrb_flag_reg (clk, st_addrb_flag, rst_addrb_flag, clr_addrb_flag, addrb_flag);
  reg_1 dinb_flag_reg (clk, st_dinb_flag, rst_dinb_flag, clr_dinb_flag, dinb_flag);   
      
  //State change
  always_ff @(posedge clk)
    begin
      if(rst)
        begin
          current_stateA <= IDLE_A;
          current_stateB <= IDLE_B;
        end
      else
        begin
          current_stateA <= next_stateA;
          current_stateB <= next_stateB;
        end
    end
    
  //State change logic
  //Port A
  always_comb
    begin
      case(current_stateA)
        IDLE_A:
          begin
          if(valid_addra & ready_addra)
            next_stateA <= READ_A;
          else
            next_stateA <= IDLE_A;
          end
        READ_A:
          begin
          if(valid_douta & ready_douta)
            next_stateA <= IDLE_A;
          else
            next_stateA <= READ_A;
          end
        default:
          begin
          next_stateA <= IDLE_A;
          end
      endcase 
    end
  
  //Port B 
  always_comb
    begin
      case(current_stateB)
        IDLE_B:
          begin
          if(addrb_flag && dinb_flag)
            next_stateB = WRITE_B;
          else
            next_stateB = IDLE_B;
          end
        WRITE_B:
          begin
          if(ready_respwr && valid_respwr)
            next_stateB = IDLE_B;
          else
            next_stateB = WRITE_B;
          end
        default:
          begin
          next_stateB = IDLE_B;
          end
      endcase 
    end
    
  //State logic 
  //Port A
  always_comb
    begin
      st_raddra   = 1'b0;
      clr_raddra  = 1'b0;
      st_vdouta   = 1'b0;
      clr_vdouta  = 1'b0;
      done_resprd = 1'b0;
      ld_addra    = 1'b0;
      case(current_stateA)
        IDLE_A:
          begin
          ld_addra = valid_addra && ready_addra;
          clr_raddra = valid_addra && ready_addra;
          done_resprd = valid_addra && ready_addra;
          end
        READ_A:
          begin
          st_vdouta = 1'b1;
          clr_vdouta = ready_douta && valid_douta;
          st_raddra = ready_douta && valid_douta;
          end
        default:
          begin
          end
      endcase
    end
   
  //Port B 
  always_comb
    begin
    clr_vrespwr = 1'b0;
    st_vrespwr  = 1'b0;
    st_raddrb   = 1'b0;
    clr_raddrb  = 1'b0;
    st_rdinb    = 1'b0;
    clr_rdinb   = 1'b0;
    st_addrb_flag = 1'b0;
    clr_addrb_flag = 1'b0;
    st_dinb_flag = 1'b0;
    clr_dinb_flag = 1'b0;
    done_respwr = 1'b0;
      case(current_stateB)
        IDLE_B:
          begin
          if(ready_addrb && valid_addrb)
            begin
              clr_raddrb = 1'b1;
              st_addrb_flag = 1'b1;
            end
          if(ready_dinb && valid_dinb)
            begin
              clr_rdinb = 1'b1;
              st_dinb_flag = 1'b1;
            end
          if(addrb_flag && dinb_flag)
            begin
              done_respwr = 1'b1;
              st_vrespwr = 1'b1;
            end
          end
        WRITE_B:
          begin
          clr_dinb_flag = 1'b1;
          clr_addrb_flag = 1'b1;
          if(valid_respwr && ready_respwr)
            begin
              clr_vrespwr = 1'b1;          
              st_raddrb = 1'b1;
              st_rdinb = 1'b1;
            end
          end
        default:
          begin
          end
      endcase 
    end
      
endmodule

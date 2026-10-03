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
//v6: full
//v7: đổi cách đọc từ word thành byte
//v8: vấn đề chỗ địa chỉ aw_reg và ar_reg


module ram #(
  parameter DATA_WIDTH = 128,
  parameter DEPTH = 1024,
  localparam ADDR_WIDTH = $clog2(DEPTH*DATA_WIDTH/8)
)
(
  // Read Address Channel
  input  logic [ADDR_WIDTH-1:0] ARADDR,
  input  logic                  ARVALID,
  input  logic [1:0]            ARBURST,
  input  logic [7:0]            ARLEN, 
  input  logic [2:0]            ARSIZE,
  output logic                  ARREADY,

  // Read Data Channel
  output logic [DATA_WIDTH-1:0] RDATA,
  output logic [1:0]            RRESP,
  output logic                  RVALID,
  output logic                  RLAST,
  input  logic                  RREADY,

  // Write Address Channel
  input  logic [ADDR_WIDTH-1:0] AWADDR,
  input  logic                  AWVALID,
  input  logic [1:0]            AWBURST,
  input  logic [7:0]            AWLEN,    
  input  logic [2:0]            AWSIZE,    
  output logic                  AWREADY,

  // Write Data Channel
  input  logic [DATA_WIDTH-1:0] WDATA,
  input  logic                  WVALID,
  input  logic                  WLAST,
  input  logic [DATA_WIDTH/8-1:0] WSTRB,  
  output logic                  WREADY,

  // Write Response Channel
  output logic [1:0]            BRESP,
  output logic                  BVALID,
  input  logic                  BREADY,

  input logic rst,
  input logic clk
);

  localparam BYTE_OFFSET_WIDTH = $clog2(DATA_WIDTH/8);

  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  // Internal registers
  logic [ADDR_WIDTH-1:0] araddr_reg;
  logic [DATA_WIDTH-1:0] rdata_reg;
  logic [ADDR_WIDTH-1:0] awaddr_reg;
  logic [DATA_WIDTH-1:0] wdata_reg;
  logic                  bresp_reg;
  
  logic [ADDR_WIDTH-1:0] araddr_byte;   // byte address
  logic [ADDR_WIDTH-1:0] awaddr_byte;   // byte address
  
  logic [BYTE_OFFSET_WIDTH-1:0] roffset = araddr_byte[BYTE_OFFSET_WIDTH-1:0];
  logic [BYTE_OFFSET_WIDTH-1:0] woffset = araddr_byte[BYTE_OFFSET_WIDTH-1:0];

  logic wrb;
  logic awflag, wflag;
  
  logic rmode;
  logic wmode;

  logic ld_wdata, ld_awaddr, ld_araddr;
  logic done_bresp, done_rresp;

  logic incr_araddr;
  logic [7:0] arsize_reg;
  logic rst_araddr;
  
  // Các tín hiệu riêng cho rbeat_cnt
  logic rst_rbeat_cnt;
  logic ld_rbeat_cnt;
  logic incr_rbeat_cnt;
  logic decr_rbeat_cnt;
  logic zr_rbeat_cnt;
  
  // Các tín hiệu riêng cho wbeat_cnt
  logic rst_wbeat_cnt;
  logic ld_wbeat_cnt;
  logic incr_wbeat_cnt;
  logic decr_wbeat_cnt;
  logic zr_wbeat_cnt;

  logic ld_rready;
  logic rst_rready;
  
  logic ld_arsize;
  logic incr_araddra;
  
  logic ld_awsize;
  logic incr_awaddr;
  logic [7:0] awsize_reg;
  
  logic ld_rmode;
  logic ld_wmode;              
  // ------------------------------------

  // Handshake control signals
  logic st_arready, init_arready, clr_arready;
  logic st_rvalid,  rst_rvalid,  clr_rvalid;
  logic st_awready, init_awready, clr_awready;
  logic st_wready,  init_wready,  clr_wready;
  logic st_bvalid,  rst_bvalid,  clr_bvalid;
  logic st_awflag,  rst_awflag,  clr_awflag;
  logic st_wflag,   rst_wflag,   clr_wflag;
  

  assign init_arready = rst;
  assign rst_rvalid  = rst;
  assign init_awready = rst;
  assign init_wready  = rst;
  assign rst_bvalid  = rst;
  assign rst_awflag  = rst;
  assign rst_wflag   = rst;
  
  assign araddr_reg = araddr_byte[ADDR_WIDTH-1:BYTE_OFFSET_WIDTH];
  assign awaddr_reg = awaddr_byte[ADDR_WIDTH-1:BYTE_OFFSET_WIDTH];
  
  //Count
  logic burst_cnt;

  // State definitions
  typedef enum logic [1:0] {
    IDLE_A,
    READ_A
  } state_a;

  typedef enum logic [1:0] {
    IDLE_B,
    WRITE_B,
    RESP_B
  } state_b;

  state_a next_stateA, current_stateA;
  state_b next_stateB, current_stateB;

  // Read data path
  always_ff @(posedge clk) begin
    if (rst)
      rdata_reg <= 0;
    else
      rdata_reg <= mem[araddr_reg];
  end
  
  assign RDATA = rdata_reg >> (roffset * 8);

  // Write memory
  always_ff @(posedge clk) begin
    if (wrb) begin
      for (int i = 0; i < 8; i++) begin
        if (WSTRB[i]) begin
          mem[awaddr_reg][i*8 +: 8] = WDATA[i*8 +: 8];
        end
      end
    end
  end
  
  assign wdata_reg = WDATA;

  // Datapath registers
  always_ff @(posedge clk) begin
    if (ld_araddr) begin
      araddr_byte[ADDR_WIDTH-1+BYTE_OFFSET_WIDTH:BYTE_OFFSET_WIDTH] <= ARADDR;
      araddr_byte[BYTE_OFFSET_WIDTH-1:0] <= 0;
    end
    else if (incr_araddr) begin
      araddr_byte <= araddr_byte + arsize_reg;
    end
  end
  
  always_ff @(posedge clk) begin
    if (ld_awaddr) begin
      awaddr_byte[ADDR_WIDTH-1+BYTE_OFFSET_WIDTH:BYTE_OFFSET_WIDTH] <= AWADDR;
      awaddr_byte[BYTE_OFFSET_WIDTH-1:0] <= 0;
    end
    else if (incr_awaddr) begin
      awaddr_byte <= awaddr_byte + awsize_reg;
    end
  end

  always_ff @(posedge clk) begin
    if (done_bresp)
      BRESP <= 2'b00;
  end

  always_ff @(posedge clk) begin
    if (done_rresp)
      RRESP <= 2'b00;
  end
   
  always_ff @(posedge clk) begin
    if (ld_rmode)
      rmode <= ARBURST;
  end
  
  always_ff @(posedge clk) begin
    if (ld_wmode)
      wmode <= AWBURST;
  end
  
  always_ff @(posedge clk) begin
    if(ld_arsize)
      case(ARSIZE)
        3'b000: arsize_reg = 10'd1;
        3'b001: arsize_reg = 10'd2;
        3'b010: arsize_reg = 10'd4;
        3'b011: arsize_reg = 10'd8;
        3'b100: arsize_reg = 10'd16;
        3'b101: arsize_reg = 10'd32;
        3'b110: arsize_reg = 10'd64;
        3'b111: arsize_reg = 10'd128;
        default arsize_reg = arsize_reg;
      endcase      
  end
  
  always_ff @(posedge clk) begin
    if(ld_awsize)
      case(AWSIZE)
        3'b000: awsize_reg = 10'd1;
        3'b001: awsize_reg = 10'd2;
        3'b010: awsize_reg = 10'd4;
        3'b011: awsize_reg = 10'd8;
        3'b100: awsize_reg = 10'd16;
        3'b101: awsize_reg = 10'd32;
        3'b110: awsize_reg = 10'd64;
        3'b111: awsize_reg = 10'd128;
        default: awsize_reg = awsize_reg;
      endcase      
  end

  // Instance of handshake registers
  reg_2 arready_reg (clk, st_arready, init_arready, clr_arready, ARREADY);
  reg_1 rvalid_reg  (clk, st_rvalid,  rst_rvalid,  clr_rvalid,  RVALID);
  reg_2 awready_reg (clk, st_awready, init_awready, clr_awready, AWREADY);
  reg_2 wready_reg  (clk, st_wready,  init_wready,  clr_wready,  WREADY);
  reg_1 bvalid_reg  (clk, st_bvalid,  rst_bvalid,  clr_bvalid,  BVALID);
  
  // Bộ đếm beat cho đọc (Port A)
  counter rbeat_cnt (clk, ARLEN, rst_rbeat_cnt, ld_rbeat_cnt, incr_rbeat_cnt, decr_rbeat_cnt, zr_rbeat_cnt);
  // Bộ đếm beat cho ghi (Port B) - hiện chưa dùng
  counter wbeat_cnt (clk, AWLEN, rst_wbeat_cnt, ld_wbeat_cnt, incr_wbeat_cnt, decr_wbeat_cnt, zr_wbeat_cnt);
  

  // State change
  always_ff @(posedge clk) begin
    if (rst) begin
      current_stateA <= IDLE_A;
      current_stateB <= IDLE_B;
    end else begin
      current_stateA <= next_stateA;
      current_stateB <= next_stateB;
    end
  end

  // State change logic - Port A
  always_comb begin
    case (current_stateA)
      IDLE_A: begin
        if (ARVALID & ARREADY)
          next_stateA = READ_A;
        else
          next_stateA = IDLE_A;
      end
      READ_A: begin
        if (zr_rbeat_cnt)
          next_stateA = IDLE_A;
        else
          next_stateA = READ_A;
      end
      default: next_stateA = IDLE_A;
    endcase
  end

  // State change logic - Port B
  always_comb begin
    case (current_stateB)
      IDLE_B: begin
        if (AWVALID && AWREADY)
          next_stateB = WRITE_B;
        else
          next_stateB = IDLE_B;
      end
      WRITE_B: begin
        if (WLAST)
          next_stateB = RESP_B;
        else
          next_stateB = WRITE_B;
      end
      RESP_B: begin
        next_stateB = IDLE_B;
      end
      default: next_stateB = IDLE_B;
    endcase
  end

  // State logic - Port A
  always_comb begin
    st_arready     = 1'b0;
    clr_arready    = 1'b0;
    st_rvalid      = 1'b0;
    clr_rvalid     = 1'b0;
    done_rresp     = 1'b0;
    ld_araddr      = 1'b0;
    ld_rbeat_cnt   = 1'b0;
    ld_arsize      = 1'b0;
    ld_rready      = 1'b0;
    incr_araddra   = 1'b0;
    incr_rbeat_cnt = 1'b0;
    decr_rbeat_cnt = 1'b0;
    rst_araddr     = 1'b0;
    RLAST          = 1'b0; 
    rst_rbeat_cnt  = 1'b0;

    case (current_stateA)
      IDLE_A: begin
        if (ARVALID && ARREADY) begin
          ld_araddr   = 1'b1;
          clr_arready = 1'b1;
          ld_rbeat_cnt = 1'b1;
          ld_arsize   = 1'b1;
          ld_rready   = 1'b1;
          ld_rmode    = 1'b1;
          st_rvalid   = 1'b1;
        end
      end
      READ_A: begin
        if(zr_rbeat_cnt) begin
          RLAST = 1'b1;
          if(RVALID && RREADY) begin
            st_arready = 1'b1;
            clr_rvalid = 1'b1;
            done_rresp = 1'b1;
          end
        end
        else if(RVALID && RREADY) begin
          incr_araddra = 1'b1;
          decr_rbeat_cnt = 1'b1;
        end
      end
      default: ;
    endcase
  end

  // State logic - Port B (ghi)
  always_comb begin
    clr_bvalid   = 1'b0;
    st_bvalid    = 1'b0;
    st_awready   = 1'b0;
    clr_awready  = 1'b0;
    st_wready    = 1'b0;
    clr_wready   = 1'b0;
    done_bresp   = 1'b0;
    ld_awaddr    = 1'b0;
    wrb          = 1'b0;
    rst_wbeat_cnt = 1'b0;
    ld_wbeat_cnt  = 1'b0;
    incr_wbeat_cnt = 1'b0;
    decr_wbeat_cnt = 1'b0;

    case (current_stateB)
      IDLE_B: begin
        if (AWREADY && AWVALID) begin
          ld_awaddr = 1'b1;
          clr_awready = 1'b1;
          ld_wbeat_cnt = 1'b1;
          ld_awsize = 1'b1;
          ld_wmode = 1'b1;
          st_wready =1'b1;
        end
      end
      WRITE_B: begin
        if (WREADY && WVALID) begin
          wrb = 1'b1;
          incr_awaddr =1'b1;
          if(WLAST) begin
          wrb = 1'b1;
          clr_wready = 1'b1;
          done_bresp = 1'b1;
          st_bvalid  = 1'b1;
          end
        end
      end
      RESP_B: begin
        if (BVALID && BREADY) begin
          clr_bvalid = 1'b1;
          st_awready = 1'b1;
          st_wready  = 1'b1;
        end
      end
      default: ;
    endcase
  end

endmodule
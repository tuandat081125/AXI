`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/04/2026 01:12:53 PM
// Design Name: 
// Module Name: tb_ram_axi_slave
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


module tb_ram_axi_slave;
  parameter DATA_WIDTH = 32;
  parameter DEPTH      = 1024;
  localparam ADDR_WIDTH = $clog2(DEPTH * DATA_WIDTH / 8);

  // Clock và reset
  logic clk;
  logic rst;

  // --------------------------------------------
  // Read Address Channel
  logic [ADDR_WIDTH-1:0] ARADDR;
  logic                  ARVALID;
  logic [1:0]            ARBURST;
  logic [7:0]            ARLEN;
  logic [2:0]            ARSIZE;
  logic                  ARREADY;

  // Read Data Channel
  logic [DATA_WIDTH-1:0] RDATA;
  logic [1:0]            RRESP;
  logic                  RVALID;
  logic                  RLAST;
  logic                  RREADY;

  // Write Address Channel
  logic [ADDR_WIDTH-1:0] AWADDR;
  logic                  AWVALID;
  logic [1:0]            AWBURST;
  logic [7:0]            AWLEN;
  logic [2:0]            AWSIZE;
  logic                  AWREADY;

  // Write Data Channel
  logic [DATA_WIDTH-1:0] WDATA;
  logic                  WVALID;
  logic                  WLAST;
  logic [DATA_WIDTH/8-1:0] WSTRB;
  logic                  WREADY;

  // Write Response Channel
  logic [1:0]            BRESP;
  logic                  BVALID;
  logic                  BREADY;

  // --------------------------------------------
  // DUT instantiation
  ram_axi_slave #(
    .DATA_WIDTH (DATA_WIDTH),
    .DEPTH      (DEPTH)
  ) dut (
    .ARADDR   (ARADDR),
    .ARVALID  (ARVALID),
    .ARBURST  (ARBURST),
    .ARLEN    (ARLEN),
    .ARSIZE   (ARSIZE),
    .ARREADY  (ARREADY),
    .RDATA    (RDATA),
    .RRESP    (RRESP),
    .RVALID   (RVALID),
    .RLAST    (RLAST),
    .RREADY   (RREADY),
    .AWADDR   (AWADDR),
    .AWVALID  (AWVALID),
    .AWBURST  (AWBURST),
    .AWLEN    (AWLEN),
    .AWSIZE   (AWSIZE),
    .AWREADY  (AWREADY),
    .WDATA    (WDATA),
    .WVALID   (WVALID),
    .WLAST    (WLAST),
    .WSTRB    (WSTRB),
    .WREADY   (WREADY),
    .BRESP    (BRESP),
    .BVALID   (BVALID),
    .BREADY   (BREADY),
    .rst      (rst),
    .clk      (clk)
  );

  // --------------------------------------------
  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Reset (giữ nguyên)
  initial begin
    rst = 1;
    #20 rst = 0;
  end

  // --------------------------------------------
  // Monitor
  initial begin
    $monitor("Time = %t, rst=%b, ARADDR=%h, ARVALID=%b, ARREADY=%b, RDATA=%h, RVALID=%b, RLAST=%b, AWADDR=%h, AWVALID=%b, AWREADY=%b, WDATA=%h, WVALID=%b, WREADY=%b, BRESP=%h, BVALID=%b",
             $time, rst, ARADDR, ARVALID, ARREADY, RDATA, RVALID, RLAST, AWADDR, AWVALID, AWREADY, WDATA, WVALID, WREADY, BRESP, BVALID);
  end

  // --------------------------------------------
  // Test stimulus
  initial begin
    // Khởi tạo tất cả tín hiệu
    ARADDR   = 0;
    ARVALID  = 0;
    ARBURST  = 2'b00;      
    ARLEN    = 8'h00;     
    ARSIZE   = 3'b000;   
    RREADY   = 0;

    AWADDR   = 0;
    AWVALID  = 0;
    AWBURST  = 2'b00;
    AWLEN    = 8'h00;
    AWSIZE   = 3'b000;
    WDATA    = 0;
    WVALID   = 0;
    WLAST    = 0;
    WSTRB    = {DATA_WIDTH/8{1'b1}};
    BREADY   = 0;

    // Đợi reset hoàn tất
    @(negedge rst);
    #12; // chờ ổn định
    
    AWADDR = 0;
    AWLEN = 4;
    AWSIZE = 3'b010;
    AWBURST = 1'b1;
    AWVALID = 1'b1;
    
    WDATA = 32'hFFFFFFFF;
    WVALID = 1'b1;
    #40
    WLAST = 1'b1;
    
    #10
    ARADDR = 0;
    ARLEN = 4;
    ARSIZE = 3'b010;
    ARBURST = 1'b1;
    ARVALID = 1'b1;
    
    RREADY = 1'b1;
  end 
endmodule

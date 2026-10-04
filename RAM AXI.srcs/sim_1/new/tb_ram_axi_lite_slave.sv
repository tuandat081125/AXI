module tb_ram_axi_lite_slave;
  parameter DATA_WIDTH = 16;
  parameter DEPTH = 1024;
  parameter ADDR_WIDTH = 10;

  logic clk;
  logic rst;

  // Port A
  logic [ADDR_WIDTH-1:0] addra;
  logic                  valid_addra;
  logic                  ready_addra;
  logic [DATA_WIDTH-1:0] douta;
  logic [1:0]            resprd;
  logic                  valid_douta;
  logic                  ready_douta;

  // Port B
  logic [ADDR_WIDTH-1:0] addrb;
  logic                  valid_addrb;
  logic                  ready_addrb;
  logic [DATA_WIDTH-1:0] dinb;
  logic                  valid_dinb;
  logic                  ready_dinb;
  logic [1:0]            respwr;
  logic                  valid_respwr;
  logic                  ready_respwr;

  // Instance module
  ram #(
    .DATA_WIDTH (DATA_WIDTH),
    .DEPTH      (DEPTH),
    .ADDR_WIDTH (ADDR_WIDTH)
  ) dut (
    .addra        (addra),
    .valid_addra  (valid_addra),
    .ready_addra  (ready_addra),
    .douta        (douta),
    .resprd       (resprd),
    .valid_douta  (valid_douta),
    .ready_douta  (ready_douta),
    .addrb        (addrb),
    .valid_addrb  (valid_addrb),
    .ready_addrb  (ready_addrb),
    .dinb         (dinb),
    .valid_dinb   (valid_dinb),
    .ready_dinb   (ready_dinb),
    .respwr       (respwr),
    .valid_respwr (valid_respwr),
    .ready_respwr (ready_respwr),
    .rst          (rst),
    .clk          (clk)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Tạo reset ban đầu
  initial begin
    rst = 1;
    #20 rst = 0;
  end

  // Khu vực dành cho bạn viết test stimulus
  initial begin
    // Khởi tạo các tín hiệu đầu vào ở trạng thái mặc định (tránh X)
    addra       = 0;
    valid_addra = 0;
    ready_douta = 0;
    addrb       = 0;
    valid_addrb = 0;
    dinb        = 0;
    valid_dinb  = 0;
    ready_respwr= 0;
    @(negedge rst);
    #12;
    addrb = 10'b0000000000;
    valid_addrb = 1'b1;
    dinb = 16'hABCD;
    valid_dinb = 1'b1;
    #5;
    valid_addrb = 1'b0;
    valid_dinb = 1'b0;
    ready_respwr = 1'b1;
    #20;
    addra = 10'b0000000000;
    valid_addra = 1'b1;
    #10;
    ready_douta = 1'b1;
    valid_addra = 1'b0;
    #1000;
    $finish;
  end

  initial begin
    $monitor("Time = %t, rst=%b, addra=%h, valid_addra=%b, ready_addra=%b, douta=%h, valid_douta=%b, addrb=%h, valid_addrb=%b, ready_addrb=%b, dinb=%h, valid_dinb=%b, ready_dinb=%b, respwr=%h, valid_respwr=%b", 
             $time, rst, addra, valid_addra, ready_addra, douta, valid_douta, addrb, valid_addrb, ready_addrb, dinb, valid_dinb, ready_dinb, respwr, valid_respwr);
  end

endmodule
`timescale 1ns/1ps

module tb_axi_concurrent;

reg clk;
reg reset_n;

reg [7:0] cfg_awlen;
reg [7:0] cfg_arlen;

reg [1:0] cfg_awburst;
reg [1:0] cfg_arburst;

reg write_request;
reg read_request;

//--------------------------------------------------
// AXI Wires
//--------------------------------------------------

wire [31:0] awaddr;
wire [7:0]  awlen;
wire [1:0]  awburst;
wire        awvalid;
wire        awready;

wire [31:0] wdata;
wire [3:0]  wstrb;
wire        wvalid;
wire        wlast;
wire        wready;

wire [1:0]  bresp;
wire        bvalid;
wire        bready;

wire [31:0] araddr;
wire [7:0]  arlen;
wire [1:0]  arburst;
wire        arvalid;
wire        arready;

wire [31:0] rdata;
wire [1:0]  rresp;
wire        rvalid;
wire        rlast;
wire        rready;

//--------------------------------------------------
// Clock
//--------------------------------------------------

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

//--------------------------------------------------
// DUT
//--------------------------------------------------

axi_master master_inst(
    .clk(clk),
    .reset_n(reset_n),

    .cfg_awlen(cfg_awlen),
    .cfg_arlen(cfg_arlen),

    .cfg_awburst(cfg_awburst),
    .cfg_arburst(cfg_arburst),

    .awaddr(awaddr),
    .awlen(awlen),
    .awburst(awburst),
    .awvalid(awvalid),
    .awready(awready),

    .wdata(wdata),
    .wstrb(wstrb),
    .wvalid(wvalid),
    .wlast(wlast),
    .wready(wready),

    .bresp(bresp),
    .bvalid(bvalid),
    .bready(bready),

    .araddr(araddr),
    .arlen(arlen),
    .arburst(arburst),
    .arvalid(arvalid),
    .arready(arready),

    .rdata(rdata),
    .rresp(rresp),
    .rvalid(rvalid),
    .rlast(rlast),
    .rready(rready),

    .write_request(write_request),
    .read_request(read_request)
);

axi_slave slave_inst(
    .clk(clk),
    .reset_n(reset_n),

    .awaddr(awaddr),
    .awlen(awlen),
    .awburst(awburst),
    .awvalid(awvalid),
    .awready(awready),

    .wdata(wdata),
    .wstrb(wstrb),
    .wvalid(wvalid),
    .wlast(wlast),
    .wready(wready),

    .bresp(bresp),
    .bvalid(bvalid),
    .bready(bready),

    .araddr(araddr),
    .arlen(arlen),
    .arburst(arburst),
    .arvalid(arvalid),
    .arready(arready),

    .rdata(rdata),
    .rresp(rresp),
    .rvalid(rvalid),
    .rlast(rlast),
    .rready(rready)
);

//--------------------------------------------------
// Monitor
//--------------------------------------------------

always @(posedge clk)
begin
    $display(
    "T=%0t WSTATE=%0d RSTATE=%0d WVALID=%0b RVALID=%0b",
    $time,
    master_inst.write_state,
    master_inst.read_state,
    wvalid,
    rvalid
    );
end

//--------------------------------------------------
// Test
//--------------------------------------------------

integer i;

initial begin

    reset_n = 0;

    write_request = 0;
    read_request  = 0;

    repeat(5) @(posedge clk);

    reset_n = 1;

    //--------------------------------------------------
    // preload memory for reads
    //--------------------------------------------------

    for(i=32;i<40;i=i+1)
        slave_inst.memory[i] = 32'hAAAA0000 + i;

    //--------------------------------------------------
    // CONCURRENT FIXED
    //--------------------------------------------------

    $display("");
    $display("================================");
    $display("CONCURRENT FIXED TEST");
    $display("================================");

    cfg_awlen   = 7;
    cfg_arlen   = 7;

    cfg_awburst = 2'b00;
    cfg_arburst = 2'b00;

    write_request = 1;
    read_request  = 1;

    @(posedge clk);

    write_request = 0;
    read_request  = 0;

    wait(master_inst.write_state == master_inst.WRITE_IDLE &&
         master_inst.read_state  == master_inst.READ_IDLE);
         
     @(posedge clk);

    $display("FIXED TEST COMPLETE");

    //--------------------------------------------------
    // CONCURRENT INCR
    //--------------------------------------------------

    $display("");
    $display("================================");
    $display("CONCURRENT INCR TEST");
    $display("================================");

    cfg_awlen   = 7;
    cfg_arlen   = 7;

    cfg_awburst = 2'b01;
    cfg_arburst = 2'b01;

    write_request = 1;
    read_request  = 1;

    @(posedge clk);

    write_request = 0;
    read_request  = 0;

    wait(master_inst.write_state == master_inst.WRITE_IDLE &&
         master_inst.read_state  == master_inst.READ_IDLE);

    $display("INCR TEST COMPLETE");

    //--------------------------------------------------
    // Memory dump
    //--------------------------------------------------

    $display("");
    $display("================================");
    $display("MEMORY DUMP");
    $display("================================");

    for(i=0;i<20;i=i+1)
        $display("mem[%0d] = %h",
                 i,
                 slave_inst.memory[i]);

    #100;

    $display("ALL TESTS PASSED");
    $finish;

end

endmodule
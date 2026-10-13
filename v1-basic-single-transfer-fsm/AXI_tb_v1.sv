`timescale 1ns/1ps

module axi_testbench;

reg clk;
reg reset_n;

// AXI wires
wire [31:0] awaddr;
wire [7:0]  awlen;
wire        awvalid;
wire        awready;

wire [31:0] wdata;
wire [3:0]  wstrb;
wire        wvalid;
wire        wready;

wire [1:0]  bresp;
wire        bvalid;
wire        bready;

wire [31:0] araddr;
wire [7:0]  arlen;
wire        arvalid;
wire        arready;

wire [31:0] rdata;
wire [1:0]  rresp;
wire        rvalid;
wire        rready;

axi_master master (
    .* 
);

axi_slave slave (
    .*
);

// CLOCK
always #5 clk = ~clk;

initial begin

    clk = 0;
    reset_n = 0;

    #20;
    reset_n = 1;

    #300;

    $display("Read Data = %h", master.read_data);

    if (master.read_data == 32'hDEAD_BEEF)
        $display("TEST PASSED");
    else
        $display("TEST FAILED");

    $finish;
end

endmodule
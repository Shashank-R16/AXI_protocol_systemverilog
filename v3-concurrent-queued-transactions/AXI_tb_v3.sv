`timescale 1ns/1ps

module tb_axi;

    //-----------------------------------------
    // Clock / Reset
    //-----------------------------------------

    reg clk;
    reg reset_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset_n = 0;
        #50;
        reset_n = 1;
    end

    //-----------------------------------------
    // Configuration Signals
    //-----------------------------------------

    reg [7:0] cfg_awaddr;
    reg [7:0] cfg_araddr;

    reg [7:0] cfg_awlen;
    reg [7:0] cfg_arlen;

    reg [1:0] cfg_awburst;
    reg [1:0] cfg_arburst;

    reg write_request;
    reg read_request;

    //-----------------------------------------
    // AXI Interconnect Signals
    //-----------------------------------------

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

    //-----------------------------------------
    // DUTs
    //-----------------------------------------

    axi_master master_inst(

        .clk(clk),
        .reset_n(reset_n),

        .cfg_awaddr(cfg_awaddr),
        .cfg_araddr(cfg_araddr),

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

    //-----------------------------------------
    // Tasks
    //-----------------------------------------

    task issue_write(
        input [7:0] addr,
        input [7:0] len
    );
    begin
        @(posedge clk);

        cfg_awaddr  <= addr;
        cfg_awlen   <= len;
        cfg_awburst <= 2'b01;

        write_request <= 1;

        @(posedge clk);
        write_request <= 0;

        $display("[%0t] WRITE REQUEST addr=%0d len=%0d",
                 $time, addr, len);
    end
    endtask


    task issue_read(
        input [7:0] addr,
        input [7:0] len
    );
    begin
        @(posedge clk);

        cfg_araddr  <= addr;
        cfg_arlen   <= len;
        cfg_arburst <= 2'b01;

        read_request <= 1;

        @(posedge clk);
        read_request <= 0;

        $display("[%0t] READ REQUEST addr=%0d len=%0d",
                 $time, addr, len);
    end
    endtask

    //-----------------------------------------
    // Stimulus
    //-----------------------------------------

    initial begin

        write_request = 0;
        read_request  = 0;

        cfg_awaddr  = 0;
        cfg_araddr  = 0;

        cfg_awlen   = 0;
        cfg_arlen   = 0;

        cfg_awburst = 2'b01;
        cfg_arburst = 2'b01;

        wait(reset_n);

        //---------------------------------
        // TEST 1
        // Independent Write
        //---------------------------------

        $display("\n=================================");
        $display("TEST 1 : SINGLE WRITE");
        $display("=================================\n");

        issue_write(8'd10, 8'd3);

        #200;

        //---------------------------------
        // TEST 2
        // Independent Read
        //---------------------------------

        $display("\n=================================");
        $display("TEST 2 : SINGLE READ");
        $display("=================================\n");

        issue_read(8'd10, 8'd3);

        #200;

        //---------------------------------
        // TEST 3
        // Concurrent Read + Write
        //---------------------------------

        $display("\n=================================");
        $display("TEST 3 : CONCURRENT RW");
        $display("=================================\n");

        fork
            issue_write(8'd20,8'd4);
            issue_read (8'd10,8'd3);
        join

        #300;

        //---------------------------------
        // TEST 4
        // Outstanding Writes
        //---------------------------------

        $display("\n=================================");
        $display("TEST 4 : OUTSTANDING WRITES");
        $display("=================================\n");

        issue_write(8'd30,8'd2);
        issue_write(8'd40,8'd2);
        issue_write(8'd50,8'd2);
        issue_write(8'd60,8'd2);

        #500;

        //---------------------------------
        // TEST 5
        // Outstanding Reads
        //---------------------------------

        $display("\n=================================");
        $display("TEST 5 : OUTSTANDING READS");
        $display("=================================\n");

        issue_read(8'd30,8'd2);
        issue_read(8'd40,8'd2);
        issue_read(8'd50,8'd2);
        issue_read(8'd60,8'd2);

        #500;

        //---------------------------------
        // TEST 6
        // Mixed Outstanding
        //---------------------------------

        $display("\n=================================");
        $display("TEST 6 : MIXED OUTSTANDING");
        $display("=================================\n");

        fork

            begin
                issue_write(8'd70,8'd3);
                issue_write(8'd80,8'd3);
                issue_write(8'd90,8'd3);
            end

            begin
                issue_read(8'd30,8'd2);
                issue_read(8'd40,8'd2);
                issue_read(8'd50,8'd2);
            end

        join

        #1000;

        $display("\n=================================");
        $display("ALL TESTS COMPLETE");
        $display("=================================\n");

        $finish;

    end

    //-----------------------------------------
    // AXI Monitor
    //-----------------------------------------

    always @(posedge clk) begin

        if(awvalid && awready)
            $display("[%0t] AW  addr=%0d len=%0d",
                     $time, awaddr, awlen);

        if(wvalid && wready)
            $display("[%0t] W   data=%h last=%b",
                     $time, wdata, wlast);

        if(bvalid && bready)
            $display("[%0t] B   resp=%0d",
                     $time, bresp);

        if(arvalid && arready)
            $display("[%0t] AR  addr=%0d len=%0d",
                     $time, araddr, arlen);

        if(rvalid && rready)
            $display("[%0t] R   data=%h last=%b",
                     $time, rdata, rlast);

    end

endmodule
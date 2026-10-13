// axi4_tb.sv
// Self-checking verification testbench for AXI4 master-slave system
// Instantiates master and slave directly (no separate top or interface module)

module axi4_tb;

    // =========================================================================
    // Parameters
    // =========================================================================
    localparam ADDR_WIDTH  = 32;
    localparam DATA_WIDTH  = 32;
    localparam ID_WIDTH    = 4;
    localparam STRB_WIDTH  = DATA_WIDTH / 8;
    localparam CLK_PERIOD  = 10;
    localparam MEM_DEPTH   = 256;

    localparam BYTES_PER_WORD = DATA_WIDTH / 8;
    localparam WORD_ADDR_BITS = $clog2(BYTES_PER_WORD);

    // =========================================================================
    // Clock and Reset
    // =========================================================================
    logic ACLK;
    logic ARESETn;

    initial begin
        ACLK = 0;
        forever #(CLK_PERIOD/2) ACLK = ~ACLK;
    end

    // =========================================================================
    // AXI Interconnect Wires
    // =========================================================================
    // AW
    logic [ADDR_WIDTH-1:0]  awaddr;
    logic [7:0]             awlen;
    logic [1:0]             awburst;
    logic [ID_WIDTH-1:0]    awid;
    logic                   awvalid;
    logic                   awready;

    // W
    logic [DATA_WIDTH-1:0]  wdata;
    logic [STRB_WIDTH-1:0]  wstrb;
    logic                   wlast;
    logic                   wvalid;
    logic                   wready;

    // B
    logic [1:0]             bresp;
    logic [ID_WIDTH-1:0]    bid;
    logic                   bvalid;
    logic                   bready;

    // AR
    logic [ADDR_WIDTH-1:0]  araddr;
    logic [7:0]             arlen;
    logic [1:0]             arburst;
    logic [ID_WIDTH-1:0]    arid;
    logic                   arvalid;
    logic                   arready;

    // R
    logic [DATA_WIDTH-1:0]  rdata;
    logic [1:0]             rresp;
    logic                   rlast;
    logic [ID_WIDTH-1:0]    rid;
    logic                   rvalid;
    logic                   rready;

    // =========================================================================
    // User Interface Wires
    // =========================================================================
    logic                    wr_req_valid;
    logic                    wr_req_ready;
    logic [ADDR_WIDTH-1:0]   wr_req_addr;
    logic [7:0]              wr_req_len;
    logic [1:0]              wr_req_burst;
    logic [DATA_WIDTH-1:0]   wr_req_base_data;

    logic                    rd_req_valid;
    logic                    rd_req_ready;
    logic [ADDR_WIDTH-1:0]   rd_req_addr;
    logic [7:0]              rd_req_len;
    logic [1:0]              rd_req_burst;

    logic                    wr_resp_valid;
    logic [ID_WIDTH-1:0]     wr_resp_id;
    logic [1:0]              wr_resp_resp;

    logic                    rd_data_valid;
    logic [DATA_WIDTH-1:0]   rd_data_out;
    logic [ID_WIDTH-1:0]     rd_data_id;
    logic                    rd_data_last;
    logic [1:0]              rd_data_resp;

    // =========================================================================
    // Master Instantiation
    // =========================================================================
    axi4_master #(
        .ADDR_WIDTH      (ADDR_WIDTH),
        .DATA_WIDTH      (DATA_WIDTH),
        .ID_WIDTH        (ID_WIDTH),
        .STRB_WIDTH      (STRB_WIDTH),
        .REQ_QUEUE_DEPTH (4),
        .OT_QUEUE_DEPTH  (4)
    ) u_master (
        .ACLK            (ACLK),
        .ARESETn         (ARESETn),

        .AWADDR          (awaddr),
        .AWLEN           (awlen),
        .AWBURST         (awburst),
        .AWID            (awid),
        .AWVALID         (awvalid),
        .AWREADY         (awready),

        .WDATA           (wdata),
        .WSTRB           (wstrb),
        .WLAST           (wlast),
        .WVALID          (wvalid),
        .WREADY          (wready),

        .BRESP           (bresp),
        .BID             (bid),
        .BVALID          (bvalid),
        .BREADY          (bready),

        .ARADDR          (araddr),
        .ARLEN           (arlen),
        .ARBURST         (arburst),
        .ARID            (arid),
        .ARVALID         (arvalid),
        .ARREADY         (arready),

        .RDATA           (rdata),
        .RRESP           (rresp),
        .RLAST           (rlast),
        .RID             (rid),
        .RVALID          (rvalid),
        .RREADY          (rready),

        .wr_req_valid    (wr_req_valid),
        .wr_req_ready    (wr_req_ready),
        .wr_req_addr     (wr_req_addr),
        .wr_req_len      (wr_req_len),
        .wr_req_burst    (wr_req_burst),
        .wr_req_base_data(wr_req_base_data),

        .rd_req_valid    (rd_req_valid),
        .rd_req_ready    (rd_req_ready),
        .rd_req_addr     (rd_req_addr),
        .rd_req_len      (rd_req_len),
        .rd_req_burst    (rd_req_burst),

        .wr_resp_valid   (wr_resp_valid),
        .wr_resp_id      (wr_resp_id),
        .wr_resp_resp    (wr_resp_resp),

        .rd_data_valid   (rd_data_valid),
        .rd_data_out     (rd_data_out),
        .rd_data_id      (rd_data_id),
        .rd_data_last    (rd_data_last),
        .rd_data_resp    (rd_data_resp)
    );

    // =========================================================================
    // Slave Instantiation
    // =========================================================================
    axi4_slave #(
        .ADDR_WIDTH  (ADDR_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH),
        .ID_WIDTH    (ID_WIDTH),
        .STRB_WIDTH  (STRB_WIDTH),
        .MEM_DEPTH   (MEM_DEPTH),
        .QUEUE_DEPTH (4)
    ) u_slave (
        .ACLK        (ACLK),
        .ARESETn     (ARESETn),

        .AWADDR      (awaddr),
        .AWLEN       (awlen),
        .AWBURST     (awburst),
        .AWID        (awid),
        .AWVALID     (awvalid),
        .AWREADY     (awready),

        .WDATA       (wdata),
        .WSTRB       (wstrb),
        .WLAST       (wlast),
        .WVALID      (wvalid),
        .WREADY      (wready),

        .BRESP       (bresp),
        .BID         (bid),
        .BVALID      (bvalid),
        .BREADY      (bready),

        .ARADDR      (araddr),
        .ARLEN       (arlen),
        .ARBURST     (arburst),
        .ARID        (arid),
        .ARVALID     (arvalid),
        .ARREADY     (arready),

        .RDATA       (rdata),
        .RRESP       (rresp),
        .RLAST       (rlast),
        .RID         (rid),
        .RVALID      (rvalid),
        .RREADY      (rready)
    );

    // =========================================================================
    // Self-Checking Infrastructure
    // =========================================================================
    integer total_tests;
    integer tests_passed;
    integer tests_failed;

    // Reference memory for verification
    logic [DATA_WIDTH-1:0] ref_memory [0:MEM_DEPTH-1];

    // =========================================================================
    // Helper Tasks
    // =========================================================================

    // -----------------------------------------------------------------
    // Reset
    // -----------------------------------------------------------------
    task automatic reset_dut();
        ARESETn          <= 1'b0;
        wr_req_valid     <= 1'b0;
        wr_req_addr      <= '0;
        wr_req_len       <= '0;
        wr_req_burst     <= '0;
        wr_req_base_data <= '0;
        rd_req_valid     <= 1'b0;
        rd_req_addr      <= '0;
        rd_req_len       <= '0;
        rd_req_burst     <= '0;
        repeat (5) @(posedge ACLK);
        ARESETn <= 1'b1;
        repeat (3) @(posedge ACLK);
        $display("[%0t] Reset complete", $time);
    endtask

    // -----------------------------------------------------------------
    // Issue Write Request
    // Waits for wr_req_ready, then asserts valid for one cycle.
    // Also updates the reference memory model.
    // -----------------------------------------------------------------
    task automatic issue_write(
        input logic [ADDR_WIDTH-1:0]  addr,
        input logic [7:0]             len,
        input logic [1:0]             burst,
        input logic [DATA_WIDTH-1:0]  base_data
    );
        // Wait until the master can accept
        while (!wr_req_ready) @(posedge ACLK);

        @(posedge ACLK);
        wr_req_valid     <= 1'b1;
        wr_req_addr      <= addr;
        wr_req_len       <= len;
        wr_req_burst     <= burst;
        wr_req_base_data <= base_data;
        @(posedge ACLK);
        wr_req_valid     <= 1'b0;

        // Update reference memory
        begin
            automatic logic [ADDR_WIDTH-1:0] a = addr;
            for (int beat = 0; beat <= int'(len); beat++) begin
                ref_memory[a[WORD_ADDR_BITS +: $clog2(MEM_DEPTH)]] = base_data + beat;
                if (burst == 2'b01) begin
                    a = a + BYTES_PER_WORD;
                end
                // Fixed burst: a stays same, last value overwrites
            end
            // For fixed burst, only the last write matters at the single address
            if (burst == 2'b00) begin
                ref_memory[addr[WORD_ADDR_BITS +: $clog2(MEM_DEPTH)]] = base_data + int'(len);
            end
        end

        $display("[%0t] WRITE REQUEST: addr=0x%08h len=%0d burst=%0b base_data=0x%08h",
                 $time, addr, len, burst, base_data);
    endtask

    // -----------------------------------------------------------------
    // Issue Read Request
    // -----------------------------------------------------------------
    task automatic issue_read(
        input logic [ADDR_WIDTH-1:0]  addr,
        input logic [7:0]             len,
        input logic [1:0]             burst
    );
        while (!rd_req_ready) @(posedge ACLK);

        @(posedge ACLK);
        rd_req_valid  <= 1'b1;
        rd_req_addr   <= addr;
        rd_req_len    <= len;
        rd_req_burst  <= burst;
        @(posedge ACLK);
        rd_req_valid  <= 1'b0;

        $display("[%0t] READ REQUEST: addr=0x%08h len=%0d burst=%0b",
                 $time, addr, len, burst);
    endtask

    // -----------------------------------------------------------------
    // Wait for Write Response
    // -----------------------------------------------------------------
    task automatic wait_write_response(
        output logic [ID_WIDTH-1:0] resp_id,
        output logic [1:0]          resp_status,
        input  int                  timeout = 500
    );
        int cyc = 0;
        while (!wr_resp_valid && cyc < timeout) begin
            @(posedge ACLK);
            cyc++;
        end

        if (cyc >= timeout) begin
            $display("[%0t] ERROR: Write response timeout after %0d cycles", $time, timeout);
            resp_id     = '0;
            resp_status = 2'b11;
            return;
        end

        resp_id     = wr_resp_id;
        resp_status = wr_resp_resp;
        $display("[%0t] WRITE RESPONSE: ID=%0d RESP=%0b", $time, resp_id, resp_status);
    endtask

    // -----------------------------------------------------------------
    // Collect Read Data and Check Against Reference
    // -----------------------------------------------------------------
    task automatic collect_and_check_read(
        input  logic [ADDR_WIDTH-1:0] start_addr,
        input  int                    expected_beats,
        input  logic [1:0]            burst,
        output int                    errors,
        input  int                    timeout = 500
    );
        automatic logic [ADDR_WIDTH-1:0] check_addr = start_addr;
        automatic logic [DATA_WIDTH-1:0] expected_data;
        automatic int beat = 0;
        automatic int cyc;

        errors = 0;

        while (beat < expected_beats) begin
            cyc = 0;
            while (!rd_data_valid && cyc < timeout) begin
                @(posedge ACLK);
                cyc++;
            end

            if (cyc >= timeout) begin
                $display("[%0t] ERROR: Read data timeout at beat %0d", $time, beat);
                errors++;
                total_tests++;
                tests_failed++;
                return;
            end

            expected_data = ref_memory[check_addr[WORD_ADDR_BITS +: $clog2(MEM_DEPTH)]];
            total_tests++;

            if (rd_data_out === expected_data) begin
                $display("[%0t] OK: Beat %0d addr=0x%08h data=0x%08h ID=%0d last=%0b",
                         $time, beat, check_addr, rd_data_out, rd_data_id, rd_data_last);
                tests_passed++;
            end else begin
                $display("[%0t] ERROR: Beat %0d addr=0x%08h expected=0x%08h got=0x%08h ID=%0d",
                         $time, beat, check_addr, expected_data, rd_data_out, rd_data_id);
                tests_failed++;
                errors++;
            end

            // Check RLAST on last beat
            if (beat == expected_beats - 1) begin
                total_tests++;
                if (rd_data_last) begin
                    tests_passed++;
                end else begin
                    $display("[%0t] ERROR: RLAST not asserted on final beat %0d", $time, beat);
                    tests_failed++;
                    errors++;
                end
            end

            // Advance check address
            if (burst == 2'b01) begin
                check_addr = check_addr + BYTES_PER_WORD;
            end

            beat++;
            if (beat < expected_beats) begin
                @(posedge ACLK); // Wait for next beat
            end
        end
    endtask

    // -----------------------------------------------------------------
    // Wait idle
    // -----------------------------------------------------------------
    task automatic wait_idle(input int cycles);
        repeat (cycles) @(posedge ACLK);
    endtask

    // =========================================================================
    // Test Cases
    // =========================================================================

    // -----------------------------------------------------------------
    // Test 1: Single beat write and read-back
    // -----------------------------------------------------------------
    task automatic test_single_beat();
        logic [ID_WIDTH-1:0] rid_out;
        logic [1:0]          rresp_out;
        int errs;

        $display("\n========== TEST 1: Single Beat Write and Read ==========");

        issue_write(32'h0000_0000, 8'd0, 2'b01, 32'hDEAD_BEEF);
        wait_write_response(rid_out, rresp_out);

        total_tests++;
        if (rresp_out == 2'b00) begin
            $display("  Write response OKAY");
            tests_passed++;
        end else begin
            $display("  ERROR: Bad write response");
            tests_failed++;
        end

        wait_idle(5);

        issue_read(32'h0000_0000, 8'd0, 2'b01);
        collect_and_check_read(32'h0000_0000, 1, 2'b01, errs);

        $display("========== TEST 1 COMPLETE (errors=%0d) ==========\n", errs);
    endtask

    // -----------------------------------------------------------------
    // Test 2: Incrementing burst write and read-back (4 beats)
    // -----------------------------------------------------------------
    task automatic test_incr_burst_4();
        logic [ID_WIDTH-1:0] rid_out;
        logic [1:0]          rresp_out;
        int errs;

        $display("\n========== TEST 2: INCR Burst Write/Read (4 beats) ==========");

        issue_write(32'h0000_0010, 8'd3, 2'b01, 32'h0000_0100);
        wait_write_response(rid_out, rresp_out);

        total_tests++;
        if (rresp_out == 2'b00) tests_passed++;
        else tests_failed++;

        wait_idle(5);

        issue_read(32'h0000_0010, 8'd3, 2'b01);
        collect_and_check_read(32'h0000_0010, 4, 2'b01, errs);

        $display("========== TEST 2 COMPLETE (errors=%0d) ==========\n", errs);
    endtask

    // -----------------------------------------------------------------
    // Test 3: Fixed burst write and read-back
    // -----------------------------------------------------------------
    task automatic test_fixed_burst();
        logic [ID_WIDTH-1:0] rid_out;
        logic [1:0]          rresp_out;
        int errs;

        $display("\n========== TEST 3: FIXED Burst Write/Read ==========");

        // Fixed burst: all 4 beats write to same address
        // Last beat value = base_data + 3 = 0x203
        issue_write(32'h0000_0020, 8'd3, 2'b00, 32'h0000_0200);
        wait_write_response(rid_out, rresp_out);

        total_tests++;
        if (rresp_out == 2'b00) tests_passed++;
        else tests_failed++;

        wait_idle(5);

        // Read back single beat at the fixed address
        issue_read(32'h0000_0020, 8'd0, 2'b00);
        collect_and_check_read(32'h0000_0020, 1, 2'b00, errs);

        $display("========== TEST 3 COMPLETE (errors=%0d) ==========\n", errs);
    endtask

    // -----------------------------------------------------------------
    // Test 4: Multiple outstanding writes
    // -----------------------------------------------------------------
    task automatic test_multiple_outstanding_writes();
        logic [ID_WIDTH-1:0] rid_out;
        logic [1:0]          rresp_out;
        int errs;

        $display("\n========== TEST 4: Multiple Outstanding Writes ==========");

        // Issue 3 writes without waiting for each response
        issue_write(32'h0000_0030, 8'd0, 2'b01, 32'hAAAA_0001);
        issue_write(32'h0000_0034, 8'd0, 2'b01, 32'hBBBB_0002);
        issue_write(32'h0000_0038, 8'd0, 2'b01, 32'hCCCC_0003);

        // Collect all 3 responses
        for (int i = 0; i < 3; i++) begin
            wait_write_response(rid_out, rresp_out);
            total_tests++;
            if (rresp_out == 2'b00) tests_passed++;
            else tests_failed++;
        end

        wait_idle(5);

        // Read back each
        issue_read(32'h0000_0030, 8'd0, 2'b01);
        collect_and_check_read(32'h0000_0030, 1, 2'b01, errs);
        wait_idle(5);

        issue_read(32'h0000_0034, 8'd0, 2'b01);
        collect_and_check_read(32'h0000_0034, 1, 2'b01, errs);
        wait_idle(5);

        issue_read(32'h0000_0038, 8'd0, 2'b01);
        collect_and_check_read(32'h0000_0038, 1, 2'b01, errs);

        $display("========== TEST 4 COMPLETE ==========\n");
    endtask

    // -----------------------------------------------------------------
    // Test 5: Concurrent write and read
    // -----------------------------------------------------------------
    task automatic test_concurrent_wr_rd();
        logic [ID_WIDTH-1:0] rid_out;
        logic [1:0]          rresp_out;
        int errs;

        $display("\n========== TEST 5: Concurrent Write and Read ==========");

        // Pre-load data to read
        issue_write(32'h0000_0040, 8'd1, 2'b01, 32'h0000_5000);
        wait_write_response(rid_out, rresp_out);
        wait_idle(5);

        // Issue write and read concurrently
        fork
            begin
                issue_write(32'h0000_0050, 8'd0, 2'b01, 32'hFFFF_0000);
                wait_write_response(rid_out, rresp_out);
                total_tests++;
                if (rresp_out == 2'b00) tests_passed++;
                else tests_failed++;
            end
            begin
                issue_read(32'h0000_0040, 8'd1, 2'b01);
                collect_and_check_read(32'h0000_0040, 2, 2'b01, errs);
            end
        join

        $display("========== TEST 5 COMPLETE ==========\n");
    endtask

    // -----------------------------------------------------------------
    // Test 6: Multiple outstanding reads
    // -----------------------------------------------------------------
    task automatic test_multiple_outstanding_reads();
        int errs;

        $display("\n========== TEST 6: Multiple Outstanding Reads ==========");

        // Read previously written data
        fork
            begin
                issue_read(32'h0000_0000, 8'd0, 2'b01);
                collect_and_check_read(32'h0000_0000, 1, 2'b01, errs);
            end
            begin
                repeat (3) @(posedge ACLK);
                issue_read(32'h0000_0030, 8'd0, 2'b01);
                collect_and_check_read(32'h0000_0030, 1, 2'b01, errs);
            end
        join

        $display("========== TEST 6 COMPLETE ==========\n");
    endtask

    // -----------------------------------------------------------------
    // Test 7: Long burst (8 beats, incrementing)
    // -----------------------------------------------------------------
    task automatic test_long_burst();
        logic [ID_WIDTH-1:0] rid_out;
        logic [1:0]          rresp_out;
        int errs;

        $display("\n========== TEST 7: Long Burst (8 beats INCR) ==========");

        issue_write(32'h0000_0080, 8'd7, 2'b01, 32'h0000_7000);
        wait_write_response(rid_out, rresp_out);

        total_tests++;
        if (rresp_out == 2'b00) tests_passed++;
        else tests_failed++;

        wait_idle(5);

        issue_read(32'h0000_0080, 8'd7, 2'b01);
        collect_and_check_read(32'h0000_0080, 8, 2'b01, errs);

        $display("========== TEST 7 COMPLETE (errors=%0d) ==========\n", errs);
    endtask

    // -----------------------------------------------------------------
    // Test 8: Back-to-back single writes to adjacent addresses
    // -----------------------------------------------------------------
    task automatic test_back_to_back_singles();
        logic [ID_WIDTH-1:0] rid_out;
        logic [1:0]          rresp_out;
        int errs;

        $display("\n========== TEST 8: Back-to-Back Single Writes ==========");

        for (int i = 0; i < 4; i++) begin
            issue_write(32'h0000_00C0 + i * 4, 8'd0, 2'b01, 32'hC0_00 + i);
        end

        for (int i = 0; i < 4; i++) begin
            wait_write_response(rid_out, rresp_out);
            total_tests++;
            if (rresp_out == 2'b00) tests_passed++;
            else tests_failed++;
        end

        wait_idle(5);

        // Read back as a single 4-beat burst
        issue_read(32'h0000_00C0, 8'd3, 2'b01);
        collect_and_check_read(32'h0000_00C0, 4, 2'b01, errs);

        $display("========== TEST 8 COMPLETE (errors=%0d) ==========\n", errs);
    endtask

    // =========================================================================
    // Main Test Sequence
    // =========================================================================
    initial begin
        $display("=============================================================");
        $display("  AXI4 Master-Slave Verification Testbench");
        $display("=============================================================");

        $dumpfile("axi4_tb.vcd");
        $dumpvars(0, axi4_tb);

        total_tests  = 0;
        tests_passed = 0;
        tests_failed = 0;

        // Initialize reference memory
        for (int i = 0; i < MEM_DEPTH; i++) ref_memory[i] = '0;

        // Reset
        reset_dut();

        // Run all tests
        test_single_beat();
        wait_idle(10);

        test_incr_burst_4();
        wait_idle(10);

        test_fixed_burst();
        wait_idle(10);

        test_multiple_outstanding_writes();
        wait_idle(10);

        test_concurrent_wr_rd();
        wait_idle(10);

        test_multiple_outstanding_reads();
        wait_idle(10);

        test_long_burst();
        wait_idle(10);

        test_back_to_back_singles();
        wait_idle(10);

        // =====================================================================
        // Final Report
        // =====================================================================
        $display("\n=============================================================");
        $display("  FINAL RESULTS");
        $display("=============================================================");
        $display("  Total Checks: %0d", total_tests);
        $display("  Passed:       %0d", tests_passed);
        $display("  Failed:       %0d", tests_failed);
        $display("=============================================================");

        if (tests_failed == 0)
            $display("  >>> ALL TESTS PASSED <<<");
        else
            $display("  >>> SOME TESTS FAILED <<<");

        $display("=============================================================\n");

        #200;
        $finish;
    end

    // =========================================================================
    // Timeout Watchdog
    // =========================================================================
    initial begin
        #200000;
        $display("\n[%0t] FATAL: Simulation timeout!", $time);
        $display("  Checks completed: %0d", total_tests);
        $display("  Passed:           %0d", tests_passed);
        $display("  Failed:           %0d", tests_failed);
        $finish;
    end

endmodule
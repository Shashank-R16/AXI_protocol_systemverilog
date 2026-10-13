// axi4_slave.sv
// AXI4 Slave with FIFO queues, memory model, burst support,
// and independent write/read execution engines

module axi4_slave #(
    parameter ADDR_WIDTH      = 32,
    parameter DATA_WIDTH      = 32,
    parameter ID_WIDTH        = 4,
    parameter STRB_WIDTH      = DATA_WIDTH / 8,
    parameter MEM_DEPTH       = 256,
    parameter QUEUE_DEPTH     = 4
)(
    input  logic                    ACLK,
    input  logic                    ARESETn,

    // AW Channel
    input  logic [ADDR_WIDTH-1:0]   AWADDR,
    input  logic [7:0]              AWLEN,
    input  logic [1:0]              AWBURST,
    input  logic [ID_WIDTH-1:0]     AWID,
    input  logic                    AWVALID,
    output logic                    AWREADY,

    // W Channel
    input  logic [DATA_WIDTH-1:0]   WDATA,
    input  logic [STRB_WIDTH-1:0]   WSTRB,
    input  logic                    WLAST,
    input  logic                    WVALID,
    output logic                    WREADY,

    // B Channel
    output logic [1:0]              BRESP,
    output logic [ID_WIDTH-1:0]     BID,
    output logic                    BVALID,
    input  logic                    BREADY,

    // AR Channel
    input  logic [ADDR_WIDTH-1:0]   ARADDR,
    input  logic [7:0]              ARLEN,
    input  logic [1:0]              ARBURST,
    input  logic [ID_WIDTH-1:0]     ARID,
    input  logic                    ARVALID,
    output logic                    ARREADY,

    // R Channel
    output logic [DATA_WIDTH-1:0]   RDATA,
    output logic [1:0]              RRESP,
    output logic                    RLAST,
    output logic [ID_WIDTH-1:0]     RID,
    output logic                    RVALID,
    input  logic                    RREADY
);

    // =========================================================================
    // Address Conversion
    // =========================================================================
    localparam BYTES_PER_WORD  = DATA_WIDTH / 8;
    localparam WORD_ADDR_BITS  = $clog2(BYTES_PER_WORD);
    localparam MEM_INDEX_BITS  = $clog2(MEM_DEPTH);

    function automatic logic [MEM_INDEX_BITS-1:0] addr_to_index(
        input logic [ADDR_WIDTH-1:0] addr
    );
        return addr[WORD_ADDR_BITS +: MEM_INDEX_BITS];
    endfunction

    // =========================================================================
    // Memory
    // =========================================================================
    logic [DATA_WIDTH-1:0] memory [0:MEM_DEPTH-1];

    // =========================================================================
    // Queue Entry Type
    // =========================================================================
    typedef struct packed {
        logic [1:0]             burst;
        logic [7:0]             len;
        logic [ADDR_WIDTH-1:0]  addr;
        logic [ID_WIDTH-1:0]    id;
    } queue_entry_t;

    // =========================================================================
    // Write Address Queue
    // =========================================================================
    queue_entry_t wq [0:QUEUE_DEPTH-1];
    logic [$clog2(QUEUE_DEPTH):0] wq_head, wq_tail, wq_count;

    wire wq_full  = (wq_count == QUEUE_DEPTH[$clog2(QUEUE_DEPTH):0]);
    wire wq_empty = (wq_count == 0);

    // =========================================================================
    // Read Address Queue
    // =========================================================================
    queue_entry_t rq [0:QUEUE_DEPTH-1];
    logic [$clog2(QUEUE_DEPTH):0] rq_head, rq_tail, rq_count;

    wire rq_full  = (rq_count == QUEUE_DEPTH[$clog2(QUEUE_DEPTH):0]);
    wire rq_empty = (rq_count == 0);

    // =========================================================================
    // Write Path FSM
    // =========================================================================
    typedef enum logic [2:0] {
        WR_IDLE,
        WR_DATA,
        WR_RESP
    } wr_state_t;

    wr_state_t wr_state;

    logic [ADDR_WIDTH-1:0]  wr_addr;
    logic [8:0]             wr_beats_remaining;
    logic [1:0]             wr_burst;
    logic [ID_WIDTH-1:0]    wr_id;

    // =========================================================================
    // Read Path FSM
    // =========================================================================
    typedef enum logic [2:0] {
        RD_IDLE,
        RD_FIRST,
        RD_DATA
    } rd_state_t;

    rd_state_t rd_state;

    logic [ADDR_WIDTH-1:0]  rd_addr;
    logic [8:0]             rd_beats_remaining;
    logic [1:0]             rd_burst;
    logic [ID_WIDTH-1:0]    rd_id;

    // =========================================================================
    // Enqueue/dequeue flags for safe count management
    // =========================================================================
    logic wq_enq, wq_deq;
    logic rq_enq, rq_deq;

    // =========================================================================
    // Main Sequential Block
    // =========================================================================
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            AWREADY <= 1'b0;
            WREADY  <= 1'b0;
            BVALID  <= 1'b0;
            BRESP   <= 2'b00;
            BID     <= '0;

            ARREADY <= 1'b0;
            RVALID  <= 1'b0;
            RDATA   <= '0;
            RRESP   <= 2'b00;
            RLAST   <= 1'b0;
            RID     <= '0;

            wq_head  <= '0;
            wq_tail  <= '0;
            wq_count <= '0;

            rq_head  <= '0;
            rq_tail  <= '0;
            rq_count <= '0;

            wr_state          <= WR_IDLE;
            wr_addr           <= '0;
            wr_beats_remaining<= '0;
            wr_burst          <= '0;
            wr_id             <= '0;

            rd_state          <= RD_IDLE;
            rd_addr           <= '0;
            rd_beats_remaining<= '0;
            rd_burst          <= '0;
            rd_id             <= '0;

            for (int i = 0; i < MEM_DEPTH; i++) begin
                memory[i] <= '0;
            end

        end else begin

            // =============================================================
            // Initialize flags
            // =============================================================
            wq_enq = 1'b0;
            wq_deq = 1'b0;
            rq_enq = 1'b0;
            rq_deq = 1'b0;

            // =============================================================
            // AW CHANNEL: Accept write addresses into queue
            // =============================================================
            // Drive AWREADY combinationally based on queue space
            AWREADY <= !wq_full;

            if (AWVALID && !wq_full) begin
                wq[wq_tail[$clog2(QUEUE_DEPTH)-1:0]].id    <= AWID;
                wq[wq_tail[$clog2(QUEUE_DEPTH)-1:0]].addr  <= AWADDR;
                wq[wq_tail[$clog2(QUEUE_DEPTH)-1:0]].len   <= AWLEN;
                wq[wq_tail[$clog2(QUEUE_DEPTH)-1:0]].burst <= AWBURST;
                wq_tail <= (wq_tail + 1) % QUEUE_DEPTH;
                wq_enq = 1'b1;
            end

            // =============================================================
            // AR CHANNEL: Accept read addresses into queue
            // =============================================================
            ARREADY <= !rq_full;

            if (ARVALID && !rq_full) begin
                rq[rq_tail[$clog2(QUEUE_DEPTH)-1:0]].id    <= ARID;
                rq[rq_tail[$clog2(QUEUE_DEPTH)-1:0]].addr  <= ARADDR;
                rq[rq_tail[$clog2(QUEUE_DEPTH)-1:0]].len   <= ARLEN;
                rq[rq_tail[$clog2(QUEUE_DEPTH)-1:0]].burst <= ARBURST;
                rq_tail <= (rq_tail + 1) % QUEUE_DEPTH;
                rq_enq = 1'b1;
            end

            // =============================================================
            // WRITE PATH FSM
            // =============================================================
            case (wr_state)
                WR_IDLE: begin
                    WREADY <= 1'b0;
                    BVALID <= 1'b0;

                    if (!wq_empty) begin
                        // Latch transaction info BEFORE dequeuing
                        wr_addr           <= wq[wq_head[$clog2(QUEUE_DEPTH)-1:0]].addr;
                        wr_beats_remaining<= {1'b0, wq[wq_head[$clog2(QUEUE_DEPTH)-1:0]].len} + 9'd1;
                        wr_burst          <= wq[wq_head[$clog2(QUEUE_DEPTH)-1:0]].burst;
                        wr_id             <= wq[wq_head[$clog2(QUEUE_DEPTH)-1:0]].id;

                        // Dequeue
                        wq_head <= (wq_head + 1) % QUEUE_DEPTH;
                        wq_deq = 1'b1;

                        WREADY   <= 1'b1;
                        wr_state <= WR_DATA;
                    end
                end

                WR_DATA: begin
                    if (WVALID && WREADY) begin
                        // Perform the write to memory using byte strobes
                        for (int b = 0; b < STRB_WIDTH; b++) begin
                            if (WSTRB[b]) begin
                                memory[addr_to_index(wr_addr)][b*8 +: 8] <= WDATA[b*8 +: 8];
                            end
                        end

                        wr_beats_remaining <= wr_beats_remaining - 9'd1;

                        // Advance address for next beat (before checking WLAST)
                        if (wr_burst == 2'b01) begin
                            wr_addr <= wr_addr + BYTES_PER_WORD;
                        end
                        // Fixed burst: wr_addr unchanged

                        if (WLAST) begin
                            WREADY <= 1'b0;
                            // Generate write response
                            BID    <= wr_id;
                            BRESP  <= 2'b00; // OKAY
                            BVALID <= 1'b1;
                            wr_state <= WR_RESP;
                        end
                    end
                end

                WR_RESP: begin
                    if (BVALID && BREADY) begin
                        BVALID   <= 1'b0;
                        wr_state <= WR_IDLE;
                    end
                end

                default: wr_state <= WR_IDLE;
            endcase

            // =============================================================
            // READ PATH FSM
            // =============================================================
            case (rd_state)
                RD_IDLE: begin
                    RVALID <= 1'b0;
                    RLAST  <= 1'b0;

                    if (!rq_empty) begin
                        // Latch transaction info BEFORE dequeuing
                        rd_addr           <= rq[rq_head[$clog2(QUEUE_DEPTH)-1:0]].addr;
                        rd_beats_remaining<= {1'b0, rq[rq_head[$clog2(QUEUE_DEPTH)-1:0]].len} + 9'd1;
                        rd_burst          <= rq[rq_head[$clog2(QUEUE_DEPTH)-1:0]].burst;
                        rd_id             <= rq[rq_head[$clog2(QUEUE_DEPTH)-1:0]].id;

                        // Dequeue
                        rq_head <= (rq_head + 1) % QUEUE_DEPTH;
                        rq_deq = 1'b1;

                        rd_state <= RD_FIRST;
                    end
                end

                RD_FIRST: begin
                    // Present first beat of read data
                    // rd_addr, rd_id, rd_beats_remaining are now valid
                    RDATA  <= memory[addr_to_index(rd_addr)];
                    RID    <= rd_id;
                    RRESP  <= 2'b00; // OKAY
                    RLAST  <= (rd_beats_remaining == 9'd1);
                    RVALID <= 1'b1;

                    rd_state <= RD_DATA;
                end

                RD_DATA: begin
                    if (RVALID && RREADY) begin
                        rd_beats_remaining <= rd_beats_remaining - 9'd1;

                        if (RLAST) begin
                            // Read transaction complete
                            RVALID   <= 1'b0;
                            RLAST    <= 1'b0;
                            rd_state <= RD_IDLE;
                        end else begin
                            // Advance address
                            if (rd_burst == 2'b01) begin
                                rd_addr <= rd_addr + BYTES_PER_WORD;
                                RDATA   <= memory[addr_to_index(rd_addr + BYTES_PER_WORD)];
                            end else begin
                                // Fixed burst
                                RDATA <= memory[addr_to_index(rd_addr)];
                            end

                            // Is the next beat the last?
                            if (rd_beats_remaining == 9'd2) begin
                                RLAST <= 1'b1;
                            end else begin
                                RLAST <= 1'b0;
                            end
                        end
                    end
                end

                default: rd_state <= RD_IDLE;
            endcase

            // =============================================================
            // QUEUE COUNT UPDATES
            // =============================================================
            case ({wq_enq, wq_deq})
                2'b10:   wq_count <= wq_count + 1;
                2'b01:   wq_count <= wq_count - 1;
                default: wq_count <= wq_count;
            endcase

            case ({rq_enq, rq_deq})
                2'b10:   rq_count <= rq_count + 1;
                2'b01:   rq_count <= rq_count - 1;
                default: rq_count <= rq_count;
            endcase

        end
    end

endmodule
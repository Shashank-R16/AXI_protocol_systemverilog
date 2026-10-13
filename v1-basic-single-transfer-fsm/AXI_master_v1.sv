module axi_master (
    input  wire        clk,
    input  wire        reset_n,

    // Write address
    output reg [31:0] awaddr,
    output reg [7:0]  awlen,
    output reg        awvalid,
    input  wire       awready,

    // Write data
    output reg [31:0] wdata,
    output reg [3:0]  wstrb,
    output reg        wvalid,
    input  wire       wready,

    // Write response
    input  wire [1:0] bresp,
    input  wire       bvalid,
    output reg        bready,

    // Read address
    output reg [31:0] araddr,
    output reg [7:0]  arlen,
    output reg        arvalid,
    input  wire       arready,

    // Read data
    input  wire [31:0] rdata,
    input  wire [1:0]  rresp,
    input  wire        rvalid,
    output reg         rready
);

typedef enum logic [2:0] {
    IDLE,
    WRITE_ADDR,
    WRITE_DATA,
    WRITE_RESP,
    READ_ADDR,
    READ_DATA
} state_t;

state_t state;

reg [31:0] read_data;
reg [1:0]  write_response;
reg [1:0]  read_response;

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin

        state <= IDLE;

        awaddr  <= 0;
        awlen   <= 0;
        awvalid <= 0;

        wdata   <= 0;
        wstrb   <= 0;
        wvalid  <= 0;

        bready  <= 0;

        araddr  <= 0;
        arlen   <= 0;
        arvalid <= 0;

        rready  <= 0;

        read_data       <= 0;
        write_response  <= 0;
        read_response   <= 0;

    end
    else begin

        case(state)

        IDLE: begin
            awaddr  <= 32'h0000_0004;
            awlen   <= 0;
            awvalid <= 1;

            state <= WRITE_ADDR;
        end

        WRITE_ADDR: begin
            if (awvalid && awready) begin
                awvalid <= 0;

                wdata  <= 32'hDEAD_BEEF;
                wstrb  <= 4'b1111;
                wvalid <= 1;

                state <= WRITE_DATA;
            end
        end

        WRITE_DATA: begin
            if (wvalid && wready) begin
                wvalid <= 0;

                bready <= 1;

                state <= WRITE_RESP;
            end
        end

        WRITE_RESP: begin
            if (bvalid && bready) begin
                write_response <= bresp;

                bready <= 0;

                araddr  <= 32'h0000_0004;
                arlen   <= 0;
                arvalid <= 1;

                state <= READ_ADDR;
            end
        end

        READ_ADDR: begin
            if (arvalid && arready) begin
                arvalid <= 0;

                rready <= 1;

                state <= READ_DATA;
            end
        end

        READ_DATA: begin
            if (rvalid && rready) begin
                read_data <= rdata;
                read_response <= rresp;

                rready <= 0;

                state <= IDLE;
            end
        end

        default: state <= IDLE;

        endcase
    end
end

endmodule

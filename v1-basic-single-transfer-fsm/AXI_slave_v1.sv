module axi_slave (

    input  wire        clk,
    input  wire        reset_n,

    // Write address
    input  wire [31:0] awaddr,
    input  wire [7:0]  awlen,
    input  wire        awvalid,
    output reg         awready,

    // Write data
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    input  wire        wvalid,
    output reg         wready,

    // Write response
    output reg [1:0]   bresp,
    output reg         bvalid,
    input  wire        bready,

    // Read address
    input  wire [31:0] araddr,
    input  wire [7:0]  arlen,
    input  wire        arvalid,
    output reg         arready,

    // Read data
    output reg [31:0]  rdata,
    output reg [1:0]   rresp,
    output reg         rvalid,
    input  wire        rready
);

reg [31:0] memory [0:255];

integer addr_reg;

always @(posedge clk or negedge reset_n) begin

    if (!reset_n) begin

        awready <= 0;
        wready  <= 0;

        bvalid  <= 0;
        bresp   <= 2'b00;

        arready <= 0;

        rvalid  <= 0;
        rresp   <= 2'b00;
        rdata   <= 0;

        addr_reg <= 0;

    end
    else begin

        // WRITE ADDRESS
        if (awvalid && !awready) begin
            awready <= 1;
            addr_reg <= awaddr[7:0];
        end
        else begin
            awready <= 0;
        end

        // WRITE DATA
        if (wvalid && !wready) begin

            wready <= 1;

            if (wstrb[0]) memory[addr_reg][7:0]   <= wdata[7:0];
            if (wstrb[1]) memory[addr_reg][15:8]  <= wdata[15:8];
            if (wstrb[2]) memory[addr_reg][23:16] <= wdata[23:16];
            if (wstrb[3]) memory[addr_reg][31:24] <= wdata[31:24];

            bvalid <= 1;
            bresp  <= 2'b00;

        end
        else begin
            wready <= 0;
        end

        // WRITE RESPONSE
        if (bvalid && bready) begin
            bvalid <= 0;
        end

        // READ ADDRESS
        if (arvalid && !arready) begin

            arready <= 1;

            rdata  <= memory[araddr[7:0]];
            rresp  <= 2'b00;
            rvalid <= 1;

        end
        else begin
            arready <= 0;
        end
        // READ DATA
        if (rvalid && rready) begin
            rvalid <= 0;
        end

    end
end
endmodule

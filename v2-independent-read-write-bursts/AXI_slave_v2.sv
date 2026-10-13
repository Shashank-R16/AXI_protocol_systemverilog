module axi_slave(

    input wire clk,
    input wire reset_n,

    //---------------------------------
    // AW
    //---------------------------------

    input wire [31:0] awaddr,
    input wire [7:0] awlen,
    input wire [1:0] awburst,
    input wire awvalid,
    output reg awready,

    //---------------------------------
    // W
    //---------------------------------

    input wire [31:0] wdata,
    input wire [3:0] wstrb,
    input wire wvalid,
    input wire wlast,
    output reg wready,

    //---------------------------------
    // B
    //---------------------------------

    output reg [1:0] bresp,
    output reg bvalid,
    input wire bready,

    //---------------------------------
    // AR
    //---------------------------------

    input wire [31:0] araddr,
    input wire [7:0] arlen,
    input wire [1:0] arburst,
    input wire arvalid,
    output reg arready,

    //---------------------------------
    // R
    //---------------------------------

    output reg [31:0] rdata,
    output reg [1:0] rresp,
    output reg rvalid,
    output reg rlast,
    input wire rready
);

reg [31:0] memory [0:255];

reg [7:0] write_addr_reg;
reg [7:0] read_addr_reg;

reg [7:0] read_count;

always @(posedge clk or negedge reset_n) begin

if(!reset_n) begin

    awready<=0;
    wready<=1;

    bvalid<=0;
    bresp<=0;

    arready<=0;

    rvalid<=0;
    rlast<=0;
    rresp<=0;

    read_count<=0;

end
else begin

    //---------------------------------
    // AW
    //---------------------------------

    awready <= 0;

    if(awvalid) begin
        awready <= 1;
        write_addr_reg <= awaddr[7:0];
    end

    //---------------------------------
    // W
    //---------------------------------

    if(wvalid && wready) begin

    $display(
    "[%0t] WRITE : mem[%0d] <= %h",
    $time,
    write_addr_reg,
    wdata
    );

    memory[write_addr_reg] <= wdata;

        case(awburst)

        2'b00:
            write_addr_reg <= write_addr_reg;

        2'b01:
            write_addr_reg <= write_addr_reg + 1;

        default:
            write_addr_reg <= write_addr_reg;

        endcase

        if(wlast) begin
            bvalid <= 1;
            bresp <= 2'b00;
        end

    end

    //---------------------------------
    // B
    //---------------------------------

    if(bvalid && bready)
        bvalid <= 0;

    //---------------------------------
    // AR
    //---------------------------------

    arready <= 0;

    if(arvalid) begin

        arready <= 1;

        read_addr_reg <= araddr[7:0];
        read_count <= 0;

        rvalid <= 1;
        rdata <= memory[araddr[7:0]];
        rresp <= 2'b00;
        rlast <= (arlen==0);

    end

    //---------------------------------
    // R
    //---------------------------------

    if(rvalid && rready) begin
   $display(
    "[%0t] READ  : mem[%0d] => %h",
    $time,
    read_addr_reg,
    memory[read_addr_reg]
    );

        if(read_count==arlen) begin

            rvalid <= 0;
            rlast <= 0;

        end
        else begin

            read_count <= read_count + 1;

            case(arburst)

            2'b00:
                read_addr_reg <= read_addr_reg;

            2'b01:
                read_addr_reg <= read_addr_reg + 1;

            default:
                read_addr_reg <= read_addr_reg;

            endcase

            if(arburst==2'b01)
                rdata <= memory[read_addr_reg+1];
            else
                rdata <= memory[read_addr_reg];

            rlast <= ((read_count+1)==arlen);

        end

    end

end

end

endmodule
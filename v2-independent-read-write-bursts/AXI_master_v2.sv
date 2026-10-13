module axi_master(

    input wire clk,
    input wire reset_n,

    input wire [7:0] cfg_awlen,
    input wire [7:0] cfg_arlen,

    input wire [1:0] cfg_awburst,
    input wire [1:0] cfg_arburst,

    //-----------------------------------
    // AW
    //-----------------------------------

    output reg [31:0] awaddr,
    output reg [7:0]  awlen,
    output reg [1:0]  awburst,
    output reg        awvalid,
    input  wire       awready,

    //-----------------------------------
    // W
    //-----------------------------------

    output reg [31:0] wdata,
    output reg [3:0]  wstrb,
    output reg        wvalid,
    output reg        wlast,
    input wire        wready,

    //-----------------------------------
    // B
    //-----------------------------------

    input wire [1:0] bresp,
    input wire       bvalid,
    output reg       bready,

    //-----------------------------------
    // AR
    //-----------------------------------

    output reg [31:0] araddr,
    output reg [7:0]  arlen,
    output reg [1:0]  arburst,
    output reg        arvalid,
    input wire        arready,

    //-----------------------------------
    // R
    //-----------------------------------

    input wire [31:0] rdata,
    input wire [1:0]  rresp,
    input wire        rvalid,
    input wire        rlast,
    output reg        rready,

    input write_request,
    input read_request
);

typedef enum logic[2:0]{
    WRITE_IDLE,
    WRITE_ADDR,
    WRITE_DATA,
    WRITE_RESP
}write_state_t;

typedef enum logic[2:0]{
    READ_IDLE,
    READ_ADDR,
    READ_DATA
}read_state_t;

write_state_t write_state;
read_state_t read_state;


reg [31:0] read_data;

reg [31:0] write_data_log [0:255];
reg [31:0] read_data_log  [0:255];

reg [7:0] read_count;

reg [7:0] write_count;

always @(posedge clk or negedge reset_n) begin

    if(!reset_n) begin
        write_state <= WRITE_IDLE;
        read_state <= READ_IDLE;

        awvalid <= 0;
        awaddr <= 0;
        awlen <= 0;
        awburst <= 0;

        wvalid <= 0;
        wlast <= 0;
        wstrb <= 4'hF;
        wdata <= 0;

        bready <= 0;

        arvalid <= 0;
        araddr <= 0;
        arlen <= 0;
        arburst <= 0;

        rready <= 0;

        write_count <= 0;
        read_data <= 0;
        read_count <= 0;

    end
    else begin
        case(write_state)
        WRITE_IDLE:
            if(write_request && !awvalid)
              begin
                awaddr <= 32'h4;
                awlen <= cfg_awlen;
                awburst <= cfg_awburst;
                awvalid <= 1;
                write_state <= WRITE_ADDR;
              end

        //---------------------------------
        WRITE_ADDR:
        //---------------------------------

        begin

            if(awvalid && awready) begin

                awvalid <= 0;

                write_count <= 0;

                wdata <= 32'hDEAD0000;
                wvalid <= 1;

                wlast <= (cfg_awlen==0);

                write_state <= WRITE_DATA;

            end

        end

        //---------------------------------
        WRITE_DATA:
        //---------------------------------

        begin

            if(wvalid && wready) begin

                    write_data_log[write_count] <= wdata;

                if(write_count==awlen) begin

                    wvalid <= 0;
                    wlast <= 0;

                    bready <= 1;

                    write_state <= WRITE_RESP;

                end
                else begin

                    write_count <= write_count + 1;

                    wdata <= 32'hDEAD0000 + write_count + 1;

                    wlast <= ((write_count+1)==awlen);

                end

            end

        end

        //---------------------------------
        WRITE_RESP:
        //---------------------------------

        begin

            if(bvalid && bready) begin

                bready <= 0;
                write_state <= WRITE_IDLE;
            end

        end
        default:
            write_state <= WRITE_IDLE;
        endcase
        case(read_state)
        READ_IDLE:
            if(read_request && !arvalid)
              begin
                     araddr <= 32'h0;
                     arlen <= cfg_arlen;
                     arburst <= cfg_arburst;
                     arvalid <= 1;
                     read_state <= READ_ADDR;

                 end

        //---------------------------------
        READ_ADDR:
        //---------------------------------

        begin

            if(arvalid && arready) begin

                arvalid <= 0;
                read_count <= 0;

                rready <= 1;

                read_state <= READ_DATA;

            end

        end
            READ_DATA:
            begin

                if(rvalid && rready) begin

                    read_data <= rdata;

                    read_data_log[read_count] <= rdata;

                    read_count <= read_count + 1;

                    if(rlast) begin

                        rready <= 0;
                        read_state <= READ_IDLE;

                    end

                end

            end
            default:
                read_state <= READ_IDLE;

        endcase

    end

end

endmodule

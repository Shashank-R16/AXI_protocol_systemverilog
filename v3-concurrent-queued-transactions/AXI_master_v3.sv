module axi_master(

    input wire clk,
    input wire reset_n,

    input wire [7:0] cfg_awaddr,
    input wire [7:0] cfg_araddr,

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

//Multiple Outstanding transactions' Variables
reg [7:0] active_write_addr;
reg [7:0] active_write_len;
reg [1:0] active_write_burst;

reg [7:0] active_read_addr;
reg [7:0] active_read_len;
reg [1:0] active_read_burst;

typedef struct packed {
    logic [7:0] addr;
    logic [7:0] len;
    logic [1:0] burst;
} write_struct;

write_struct write_queue [0:3];
write_struct outstanding_write_queue [0:3]; //used by AW channel to queue requests for W channel

typedef struct packed {
    logic [7:0] addr;
    logic [7:0] len;
    logic [1:0] burst;
} read_struct;

read_struct read_queue [0:3];
read_struct outstanding_read_queue [0:3]; //used by AR channel to queue requests for R channel

reg [1:0] write_head;
reg [1:0] write_tail;

reg [2:0] w_queue_count; //write transactions count

reg [1:0] read_head;
reg [1:0] read_tail;

reg [2:0] r_queue_count; //read transactions count

reg [1:0] outstanding_write_head;
reg [1:0] outstanding_write_tail;
reg [2:0] outstanding_write_count;

reg [1:0] outstanding_read_head;
reg [1:0] outstanding_read_tail;
reg [2:0] outstanding_read_count;

typedef enum logic[1:0]{
    AW_IDLE,
    AW_SEND
}AW_state_struct;

typedef enum logic[1:0]{
    W_IDLE,
    W_SEND
}W_state_struct;

typedef enum logic[1:0]{
    AR_IDLE,
    AR_SEND
}AR_state_struct;

typedef enum logic[1:0]{
    R_IDLE,
    R_SEND
}R_state_struct;

AW_state_struct AW_state;
W_state_struct W_state;
AR_state_struct AR_state;
R_state_struct R_state;

reg [7:0] read_count;

reg [7:0] write_count;

reg [31:0] read_data;

reg [31:0] write_data_log [0:255];
reg [31:0] read_data_log  [0:255];

//reg write_active; //tells if it is Idle or not

always @(posedge clk or negedge reset_n) begin

    if(!reset_n) begin
        AW_state <= AW_IDLE;
        W_state  <= W_IDLE;
        AR_state <= AR_IDLE;
        R_state  <= R_IDLE;

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

        write_head<=0; //oldest write transaction 
        write_tail<=0; //newest write transaction

        read_head<=0; //oldest read transaction 
        read_tail<=0; //newest read transaction 

        w_queue_count<=0; //how many write transactions are waiting in queue
        r_queue_count<=0; //how many read transactions are waiting in queue

        outstanding_write_head <= 0;
        outstanding_write_tail <= 0;
        outstanding_write_count <= 0;

        outstanding_read_head <= 0;
        outstanding_read_tail <= 0;
        outstanding_read_count <= 0;
        //write_active <= 0;

    end
    else begin
        //Loading Logic to and from the queue
        if(write_request && w_queue_count < 4) begin 
            write_queue[write_tail].addr <= cfg_awaddr;
            write_queue[write_tail].len <= cfg_awlen;
            write_queue[write_tail].burst <= cfg_awburst;
            write_tail <= write_tail + 1;
            w_queue_count <= w_queue_count + 1;
        end

        if(read_request && r_queue_count < 4) begin 
            read_queue[read_tail].addr <= cfg_araddr;
            read_queue[read_tail].len <= cfg_arlen;
            read_queue[read_tail].burst <= cfg_arburst;
            read_tail <= read_tail + 1;
            r_queue_count <= r_queue_count + 1;
        end

        case(AW_state)
        AW_IDLE:
            if(w_queue_count>0)
              begin
                awaddr <= write_queue[write_head].addr;
                awlen <= write_queue[write_head].len;
                awburst <= write_queue[write_head].burst;
                awvalid <= 1;
                AW_state <= AW_SEND;
              end 
       
        AW_SEND:

        begin

            if(awvalid && awready && outstanding_write_count<4) begin //AW fsm will stall until W drains entries

                awvalid <= 0;

                write_head <= write_head + 1;
                w_queue_count <= w_queue_count - 1;

                outstanding_write_queue[outstanding_write_tail].addr  <= awaddr;
                outstanding_write_queue[outstanding_write_tail].len   <= awlen;
                outstanding_write_queue[outstanding_write_tail].burst <= awburst;

                outstanding_write_tail <= outstanding_write_tail + 1;
                outstanding_write_count <= outstanding_write_count + 1;

                //write_active <= 1; //we do not need write anymore

                AW_state <= AW_IDLE;

            end
        end
        default:
        AW_state <= AW_IDLE;
        endcase


        case(W_state)
        W_IDLE:
        begin
            if(outstanding_write_count>0) begin
                active_write_addr <= outstanding_write_queue[outstanding_write_head].addr;
                active_write_len <= outstanding_write_queue[outstanding_write_head].len;
                active_write_burst <= outstanding_write_queue[outstanding_write_head].burst;

                outstanding_write_head <= outstanding_write_head + 1;
                outstanding_write_count <= outstanding_write_count - 1;

                write_count <= 0;
                wstrb <= 4'hF;

                wvalid <= 1;
                wdata <= 32'hDEAD0000;

                wlast <= (outstanding_write_queue[outstanding_write_head].len == 0);

                W_state <= W_SEND;
            end
        end

        W_SEND:
        begin if (wvalid && wready) begin
             write_data_log[write_count] <= wdata;

                if(write_count==active_write_len) begin

                    wvalid <= 0;
                    wlast <= 0;
                    //write_active <= 0;

                    bready <= 1;

                    W_state <= W_IDLE;

                end
                else begin

                    write_count <= write_count + 1;

                    wdata <= 32'hDEAD0000 + write_count + 1;

                    wlast <= ((write_count+1)==active_write_len);

                end

            end

        end
        default: 
        W_state <= W_IDLE;
        endcase

        //B resp (only requires this)
        if(bvalid && bready) begin
           bready <= 0;
        end


        case(AR_state)
        AR_IDLE: 
            if(r_queue_count>0)
                begin
                    araddr <= read_queue[read_head].addr;
                    arlen <= read_queue[read_head].len;
                    arburst <= read_queue[read_head].burst;
                    arvalid <= 1;
                    AR_state <= AR_SEND;
                end 
        AR_SEND:
            begin
                if(arvalid && arready && outstanding_read_count<4) begin 

                    arvalid <= 0;

                    read_head <= read_head + 1;
                    r_queue_count <= r_queue_count - 1;

                    outstanding_read_queue[outstanding_read_tail].addr  <= araddr;
                    outstanding_read_queue[outstanding_read_tail].len   <= arlen;
                    outstanding_read_queue[outstanding_read_tail].burst <= arburst;

                    outstanding_read_tail <= outstanding_read_tail + 1;
                    outstanding_read_count <= outstanding_read_count + 1;

                    AR_state <= AR_IDLE;

                end
            end
        default:
            AR_state <= AR_IDLE;
        endcase

        case(R_state)
        R_IDLE:
        begin
            if(outstanding_read_count>0) begin
                active_read_addr <= outstanding_read_queue[outstanding_read_head].addr;
                active_read_len <= outstanding_read_queue[outstanding_read_head].len;
                active_read_burst <= outstanding_read_queue[outstanding_read_head].burst;

                outstanding_read_head <= outstanding_read_head + 1;
                outstanding_read_count <= outstanding_read_count - 1;

                read_count <= 0;
                rready <= 1;

                R_state <= R_SEND;
            end
        end

        R_SEND:
        begin
            if(rvalid && rready && outstanding_read_count<4) begin

                read_data_log[read_count] <= rdata;
                read_count <= read_count + 1;

                if (rlast) begin
                    rready <= 0;
                    R_state <= R_IDLE;
                end
            end
        end
        default: 
            R_state <= R_IDLE;
        endcase
        end
    end
endmodule

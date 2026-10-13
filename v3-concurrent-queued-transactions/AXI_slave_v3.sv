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

reg write_active;
reg read_active;

//used to verify if all the beats in a transfer are completed or not, allows slave to not depend on wlast from master
reg [7:0] write_count;
reg [7:0] read_count; //read counter to assert Rlast

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

typedef struct packed {
    logic [7:0] addr;
    logic [7:0] len;
    logic [1:0] burst;
} read_struct;

read_struct read_queue [0:3];

reg [1:0] write_head;
reg [1:0] write_tail;

reg [2:0] w_queue_count; //write transactions count

reg [1:0] read_head;
reg [1:0] read_tail;

reg [2:0] r_queue_count; //read transactions count


always @(posedge clk or negedge reset_n) begin

if(!reset_n) begin

    awready<=0;
    wready<=0;

    bvalid<=0;
    bresp<=0;

    arready<=0;

    rvalid<=0;
    rlast<=0;
    rresp<=0;

    read_count<=0;
    write_count<=0;

    write_active <= 0;
    read_active <= 0;

    write_head<=0; //oldest write transaction 
    write_tail<=0; //newest write transaction

    read_head<=0; //oldest read transaction 
    read_tail<=0; //newest read transaction 

    w_queue_count<=0; //how many write transactions are waiting in queue
    r_queue_count<=0; //how many read transactions are waiting in queue

end
else begin

    //Loading a new transaction from the queue
    //if there is no write transaction currently active and the queue is not empty, load the data from the FIFO to current  
    if(!write_active && w_queue_count > 0) begin 

        active_write_addr  <= write_queue[write_head].addr;
        active_write_len   <= write_queue[write_head].len;
        active_write_burst <= write_queue[write_head].burst;

        write_head <= write_head + 1;

        w_queue_count <= w_queue_count - 1; 

        write_active <= 1;
        wready <= 1; //asserts wready when a new transaction is loaded from queue
        write_count <= 0;

    end

    //same logic for read
    if(!read_active && r_queue_count > 0) begin 

        active_read_addr  <= read_queue[read_head].addr;
        active_read_len   <= read_queue[read_head].len;
        active_read_burst <= read_queue[read_head].burst;

        read_head <= read_head + 1;

        r_queue_count <= r_queue_count - 1; 

        read_active <= 1;
        rvalid <= 1;
        rresp  <= 2'b00;
        rdata  <= memory[read_queue[read_head].addr];
        read_count <= 0;
        rlast <= (read_queue[read_head].len == 0);

    end


    //---------------------------------
    // AW
    //---------------------------------

    awready <= (w_queue_count < 4); //only read when queue is not full

    if(awvalid && awready) begin 
    //takes the aw request and stores it in the queue, with tail being the latest entry in the queue
        write_queue[write_tail].addr <= awaddr[7:0]; 
        write_queue[write_tail].len <= awlen[7:0];
        write_queue[write_tail].burst <= awburst[7:0];

        write_tail <= write_tail + 1;
        w_queue_count <= w_queue_count + 1; 
    end

    //---------------------------------
    // W
    //---------------------------------
    if(wvalid && wready) begin  
        memory[active_write_addr] <= wdata; //write channel should only care about the active transaction 

            case(active_write_burst)

            2'b00:
                active_write_addr <= active_write_addr;

            2'b01:
                active_write_addr <= active_write_addr + 1;

            default:
                active_write_addr <= active_write_addr;

            endcase    

    if (write_count == (active_write_len)) 

        if(wlast) begin
            write_active <= 0;
            wready <= 0;
            bvalid <= 1;
            bresp <= 2'b00;
        end
        
    
    else     
            write_count <= write_count + 1;
    
    end

    //---------------------------------
    // B
    //---------------------------------

    if(bvalid && bready)
        bvalid <= 0;

    //---------------------------------
    // AR
    //---------------------------------

    arready <= (r_queue_count < 4);

    if(arvalid && arready) begin

        read_queue[read_tail].addr  <= araddr[7:0];
        read_queue[read_tail].len   <= arlen;
        read_queue[read_tail].burst <= arburst;

        read_tail    <= read_tail + 1;
        r_queue_count <= r_queue_count + 1;


    end

    //---------------------------------
    // R
    //---------------------------------

    if(rvalid && rready) begin
        case(active_read_burst)

            2'b00:
                active_read_addr <= active_read_addr;

            2'b01:
                active_read_addr <= active_read_addr + 1;

            default:
                active_read_addr <= active_read_addr;

            endcase

            if(active_read_burst==2'b01)
                rdata <= memory[active_read_addr+1];
            else
                rdata <= memory[active_read_addr];

            rlast <= ((read_count+1)==active_read_len);

        if(read_count==active_read_len) begin

            read_active <= 0;
            rvalid <= 0;
            rlast <= 0;

        end
        else begin
            read_count <= read_count + 1;
        end

    end

end

end

endmodule
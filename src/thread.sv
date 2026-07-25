module thread#(
    parameter BLOCK_DIM=4,
    parameter DATA_LINES=32,
    parameter ADDR_LINES=32
) (
    input logic clk,
    input logic rst_n,
    
    input logic [7:0] blk_id,
    input logic [7:0] thread_id,

    input logic [DATA_LINES-1:0] data_i,
    output logic [ADDR_LINES-1:0] addr,
    output logic [DATA_LINES-1:-0] data_o,
    
    output logic read_wrt,data_req,
    input logic data_valid,
    output logic thread_done
);

    
endmodule
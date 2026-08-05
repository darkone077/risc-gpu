`include "../pu/in_order/src/top_rv32im.sv"
module thread#(
    parameter BLOCK_DIM=4,
    parameter DATA_LINES=32,
    parameter ADDR_LINES=32
) (
    input logic clk,
    input logic rst_n,
    
    input logic [7:0] blk_id,
    input logic [7:0] thread_id,

    input logic [DATA_LINES-1:0] mem_read,inst,
    output logic [ADDR_LINES-1:0] mem_addr,inst_addr,
    output logic [DATA_LINES-1:0] mem_wrt,
    
    output logic inst_read,mem_read_wrt,mem_req,
    output logic [3:0] wrt_stb,
    input logic data_valid,inst_valid,
    output logic thread_done
);
logic done;
top_rv32im THREAD(clk,~rst_n,blk_id,thread_id,inst_read,mem_read_wrt,mem_req,wrt_stb,inst,mem_read,mem_wrt,mem_addr,inst_addr,~inst_valid,~data_valid,done);
assign thread_done=done|~rst_n;


endmodule
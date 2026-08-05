
`include "../src/scheduler.sv"
`include "../src/thread.sv"
module core #(
    parameter THREADS=4,
    parameter DATA_LINES=32,
    parameter ADDR_LINES=32
) (
    input logic clk,
    input logic rst_n,
    
    input logic [7:0] thread_count,
    input logic [7:0] blk_id,

    input logic [DATA_LINES-1:0] read_data [0:THREADS-1],inst [0:THREADS-1],
    output logic [ADDR_LINES-1:0] inst_addr[0:THREADS-1],mem_addr[0:THREADS-1],
    output logic [DATA_LINES-1:0] wrt_data [0:THREADS-1],
    output logic [THREADS-1:0] read_wrt,data_req,inst_read,
    output logic [3:0] wrt_stb [0:THREADS-1],
    input logic [THREADS-1:0] data_valid,inst_valid,
    output logic core_done
);

    logic [THREADS-1:0] thread_en;

    logic [THREADS-1:0] thread_done;

    assign core_done=&thread_done;
    scheduler SC(thread_count,thread_en);

    generate
        genvar i;
        for (i=0;i<THREADS;i++) begin: thread_generator
            thread TH(clk,rst_n&thread_en[i],blk_id,i,read_data[i],inst[i],mem_addr[i],inst_addr[i],wrt_data[i],inst_read[i],read_wrt[i],data_req[i],wrt_stb[i],data_valid[i],inst_valid[i],thread_done[i]);
        end
    endgenerate
    
endmodule
module main_controller #(
    parameter THREADS_PER_BLOCK=4,
    parameter BLOCKS=4
) (
    input logic clk,
    input logic rst_n,
    output logic done,

    input logic [7:0] thread_count,
    input logic [BLOCKS-1:0] completed,
    output logic [BLOCKS-1:0] block_en
    output logic [$clog2(BLOCKS)-1:0] block_id [0:BLOCKS-1],
    output logic [7:0] total_threads_per_block [0:BLOCKS-1]
);
    logic [7:0] total_blocks;
    assign total_blocks=(thread_count+THREADS_PER_BLOCK-1)/THREADS_PER_BLOCK;//acts as ciel(thread_count/thread_per_block)
    logic [7:0] block_counter;
    logic [7:0] blocks_requested_in_cycle;
    
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            for (int i=0; i<BLOCKS; ++i) begin
                block_en[i]<=1'b0;
                block_id[i]<={$clog2(BLOCKS){1'b0}};
                total_threads_per_block[i]<=8'b0;
            end
            block_counter<=8'b0;
            done<=1'b0;
        end
        else begin
            if (|completed) begin
                blocks_requested_in_cycle=8'b0;
                for (int i=0;i<BLOCKS;i++) begin
                    if (completed[i]) begin
                        if (block_counter+blocks_requested_in_cycle<total_blocks) begin
                            block_en[i]<=1'b1;
                            block_id[i]<=block_counter+blocks_requested_in_cycle;
                            blocks_requested_in_cycle=blocks_requested_in_cycle+1;
                            total_threads_per_block[i]<=(block_counter+blocks_requested_in_cycle==total_blocks)?thread_count-(total_blocks-1)*THREADS_PER_BLOCK:THREADS_PER_BLOCK;
                        end
                        else begin
                            block_en<=1'b0;
                        end
                    end
                end
                block_counter<=block_counter+blocks_requested_in_cycle;
            end
            if (block_counter==total_blocks) begin
                done<=1'b1;
            end
        
        end
    end


    
endmodule
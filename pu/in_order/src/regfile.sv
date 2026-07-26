`timescale 1ns/1ps

module regfile (
    input logic clk,
    input logic rst_n,

    input logic [4:0] ad1,
    input logic [4:0] ad2,

    input logic [4:0] ad3,
    input logic [31:0] wd3,
    input logic we3,

    input logic [7:0] blk_id,thread_id, 

    output logic [31:0] rd1,
    output logic [31:0] rd2
);

    logic [31:0] registers [0:31] /*verilator public*/;
    
    always_ff @(negedge clk) begin
        if(~rst_n) begin 
            for(int i=0;i<30;i=i+1) registers[i]<=32'b0;

        end
        else if(we3&&(ad3>0)&&(ad3<30)) registers[ad3]<=wd3;
        registers[30]<={25'b0,blk_id};
        registers[31]<={25'b0,thread_id};
    end
    
    always_comb begin : read

        rd1=registers[ad1];
        rd2=registers[ad2];
        
    end

    
endmodule
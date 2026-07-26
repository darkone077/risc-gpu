`timescale 1ns/1ps

module instmem #(
    parameter WORDS=2519936
) (
    input logic [31:0] mem_ad,
    output logic [31:0] redDat
);
    logic [31:0] ROM [0:WORDS-1];
    initial begin
        $readmemh("../tb/instmem.mem",ROM);
    end
    /* verilator lint_off WIDTHTRUNC */
    assign redDat=ROM[mem_ad[31:2]];

    
endmodule
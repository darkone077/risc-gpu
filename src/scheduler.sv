module scheduler #(
    parameter THREADS=4
) (
    input logic [$clog2(THREADS)-1:0] thread_count,

    output logic [THREADS-1:0] thread_en
);
    always_comb begin
        for (int i=1;i<=THREADS;i++) begin
            if (i<=thread_count) begin
                thread_en[i]=1'b1;
            end
        end
    end    
    
endmodule
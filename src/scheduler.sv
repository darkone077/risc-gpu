module scheduler #(
    parameter THREADS=4
) (
    input logic [7:0] thread_count,

    output logic [THREADS-1:0] thread_en
);
    always_comb begin
        for (int i=0;i<THREADS;i++) begin
            if ((i+1)<=thread_count) begin
                thread_en[i]=1'b1;
            end
            else begin
                thread_en[i]=0;
            end
        end
    end    
    
endmodule
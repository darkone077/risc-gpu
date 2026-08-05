module mem_controller #(
    parameter REQ_CORES=4,//required to be divisible by channels
    parameter ADDR_LINES=32,
    parameter DATA_LINES=32,
    parameter CHANNELS=2
) (
    input logic clk,
    input logic rst_n,
    input logic [REQ_CORES-1:0] data_req,
    input logic [REQ_CORE-1:0] read_wrt,
    input logic [ADDR_LINES-1:0] addr_i [0:REQ_CORES-1],
    input logic [DATA_LINES-1:0] data_i [0:CHANNELS-1],
    input logic [CHANNELS-1:0] data_valid,
    
    output logic [ADDR_LINES-1:0] addr_o [0:CHANNELS-1],
    output logic [DATA_LINES-1:0] data_o [0:REQ_CORES-1],
    output logic [CHANNELS-1:0] wrt_valid,
    output logic [CHANNELS-1:0] addr_valid,
    output logic [REQ_CORES-1:0] data_done
);

    logic [$clog2(REQ_CORES)-1:0] pri_pointer;
    logic [REQ_CORES-1:0] masked_req;
    logic [REQ_CORES-1:0] core_servicing;
    logic [CHANNELS-1:0] addr_valid_comb;
    typedef enum logic [1:0] {IDLE,DATA_READ,DATA_WRT} state_t;
    state_t state,state_nxt [0:CHANNELS-1];

    always_ff@(posedge clk)begin
        if (~rst_n) begin
            data_done<=0;
            addr_valid<=0;
            masked_req<={REQ_CORES{1'b1}};
            for (int i=0;i<CHANNELS;i++) begin
                addr_o[i]<=0;
                state[i]<=IDLE;
            end

            for (int i=0;i<REQ_CORES;i++) begin
                data_o[i]<=0;
            end
        end
        else begin
            
            for (int i=0;i<CHANNELS;i++) begin
                state[i]<=state_nxt[i];
                case (state[i])
                    IDLE:begin
                        for (int j=0;j<REQ_CORES;j++) begin
                            if (masked_req[j]&data_req[j]&state_nxt[i]!=IDLE) begin
                                addr_o[i]<=addr_i[j];
                                addr_valid[i]<=1'b1;
                            end
                        end
                    end 
                    default: 
                endcase
            end
        end
    end

    always_comb begin
        addr_valid_comb=addr_valid;
        for (int i=0;i<CHANNELS;i++) begin
            case (state[i])
                IDLE:begin
                    state_nxt=IDLE;
                    if (data_valid[i]) begin
                        for (int j=0;j<REQ_CORES;j++) begin
                            if (~core_servicing[j]&data_req[j]&state_nxt[i]==IDLE) begin
                                state_nxt[i]=(read_wrt)?DATA_READ:DATA_WRT;
                            end
                        end
                    end
                end
                DATA_READ:begin
                    if (data_valid[i]) begin
                        state_nxt[i]=IDLE;
                    end
                    else begin
                        state_nxt[i]=DATA_READ;
                    end
                end 
                DATA_WRT:begin
                    if (data_valid[i]) begin
                        state_nxt[i]=IDLE;
                    end
                    else begin
                        state_nxt[i]=DATA_WRT;
                    end
                end
                default: begin
                    state_nxt[i]=IDLE;
                end
            endcase
        end
    end
endmodule
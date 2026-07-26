`timescale 1ns/1ps
`include "../src/alu.sv"
`include "../src/ctrl.sv"
`include "../src/datmem.sv"
`include "../src/deex.sv"
`include "../src/extend.sv"
`include "../src/fede.sv"
`include "../src/hazardunit.sv"
`include "../src/instmem.sv"
`include "../src/mewb.sv"
`include "../src/pc.sv"
`include "../src/regfile.sv"
`include "../src/exme.sv"
`include "../src/loadstoredecoder.sv"
`include "../src/loadunit.sv"
`include "../src/divider.sv"

module top_rv32im (
    input logic clk,
    input logic rst,

    input logic [7:0] blk_id,thread_id,

    output logic inst_read,mem_read_wrt,mem_req,
    output logic [3:0] wrt_stb,
    input logic [31:0] inst,mem_read,
    output logic [31:0] mem_wrt,mem_addr,inst_addr,

    input logic inst_busy,mem_busy,
    output logic done
);

    logic [31:0] pcf, pcj;
    logic [31:0] instf;
    logic [31:0] pcd;
    logic [31:0] pc4f;
    logic [31:0] pc4d;
    logic [31:0] instd;
    logic pcSrc;

    assign pcj=ujWrtBcke;
    assign pc4f=pcf+4;
    pc PC(clk,pcSrc,stallf,rst,pc4f,pcj,pcf);
    //instmem IM(pcf,instf,doned);
    always_comb begin : instmem
        inst_read=~(doned|doned_comb);
        instf=inst;
        inst_addr=pcf;
    end


    fede FD(clk,flushd|rst,stalld,instf,pc4f,pcf,instd,pc4d,pcd);

    logic [6:0] op;
    logic [2:0] funct3e,funct3d;
    logic [6:0] funct7;
    assign op=instd[6:0];
    assign funct3d=instd[14:12];
    assign funct7=instd[31:25];
    logic regWrtd,memWrtd,jmpd,brnchd,aluSrcd,readd,div_end;
    logic [1:0] ujMuxd,divCtrld;
    logic [2:0] immSrcd;
    logic [4:0] aluCtrld;
    logic regWrte,memWrte,jmpe,brnche,aluSrce,reade,div_ene;
    logic [1:0] ujMuxe,divCtrle;
    logic [2:0] immSrce;
    logic [4:0] aluCtrle;

    logic doned_comb,doned;

    ctrl Control(instd,regWrtd,memWrtd,jmpd,brnchd,aluSrcd,readd,div_end,doned_comb,ujMuxd,divCtrld,immSrcd,rsltSrcd,aluCtrld);

    always_ff @(posedge clk) begin
        if(~rst_n) begin
            doned<=1'b0;conditions
        end
        if (doned_comb&~doned) begin
            doned<=1'b1;
        end
    end
    logic [4:0] ad1d,ad2d,rdd;
    assign ad1d=instd[19:15];
    assign ad2d=instd[24:20];
    assign rdd=instd[11:7];
    logic [4:0] ad1e,ad2e,rde;
    logic [31:0] rd1d,rd2d;
    logic [31:0] rd1e,rd2e,pce;
    logic [31:0] pc4e;
    logic [31:0] rsltw;

    regfile RF(clk,~rst,ad1d,ad2d,rdw,rsltw,regWrtw,blk_id,thread_id,rd1d,rd2d);

    logic [24:0] imm;
    assign imm=instd[31:7];
    logic [31:0] immextd,immexte;

    extend EXTEND(immSrcd,imm,immextd);

    deex DE(clk,flushe,stalle,regWrtd,memWrtd,jmpd,brnchd,aluSrcd,readd,div_end,rsltSrcd,immSrcd,ujMuxd,aluCtrld,funct3d,divCtrld,regWrte,memWrte,jmpe,brnche,aluSrce,reade,div_ene,rsltSrce,immSrce,ujMuxe,aluCtrle,funct3e,divCtrle,rd1d,rd2d,pcd,pc4d,immextd,ad1d,ad2d,rdd,rd1e,rd2e,pce,pc4e,immexte,ad1e,ad2e,rde);

    logic [31:0] srcAe,srcBe,wrtDe;
    logic [1:0] fwdAe,fwdBe;

    always_comb begin
        case(fwdAe)
            2'b00:
                srcAe=rd1e;
            2'b01:
                srcAe=rsltw;
            2'b10:
                srcAe=aluRsltm;
            2'b11:
                srcAe=ujWrtBckm;
        endcase
    end

    always_comb begin
        case(fwdBe)
            2'b00:
                wrtDe=rd2e;
            2'b01:
                wrtDe=rsltw;
            2'b10:
                wrtDe=aluRsltm;
            default:
                wrtDe=32'bx;
        endcase
    end

    always_comb begin
        case(aluSrce)
            1'b0:
                srcBe=wrtDe;
            1'b1:
                srcBe=immexte;
        endcase
    end

    logic [31:0] ujWrtBcke,aluRslte,divOut,aluOut;
    logic zeroe,lstBite,divBusy,divDone;
    logic [31:0] ujWrtBckm,aluRsltm;

    alu ALU(srcAe,srcBe,aluCtrle,aluOut,zeroe,lstBite);
    divider DIV(clk,~rst,div_ene,divCtrle,srcAe,srcBe,divOut,divBusy,divDone);

    always_comb begin
        aluRslte=(divDone)?divOut:aluOut;
    end

    always_comb begin
        case(ujMuxe)
            2'b00:
                ujWrtBcke=immexte;
            2'b01:
                ujWrtBcke=immexte+pce;
            2'b10:
                ujWrtBcke=immexte+srcAe;
            default:
                ujWrtBcke=32'bxx;
        endcase
    end

    logic regWrtm,memWrtm;
    logic [2:0] rsltSrcm;
    logic [31:0] wrtDm,pc4m;
    logic [4:0] rdm;
    logic readm;
    logic [2:0] funct3m;

    exme EM(clk,stallm,regWrte,memWrte,reade,rsltSrce,funct3e,regWrtm,memWrtm,readm,rsltSrcm,funct3m,aluRslte,wrtDe,pc4e,ujWrtBcke,rde,aluRsltm,wrtDm,pc4m,ujWrtBckm,rdm);

    logic [31:0] wrtDShiftedm;
    logic [31:0] readDm;
    logic [31:0] readDw;
    logic [3:0] strobem;
    loadstoredecoder LSD(aluRsltm,wrtDm,funct3m,wrtDShiftedm,strobem);

    logic [31:0] readDRaw;
    //datmem DM(clk,aluRsltm,wrtDShiftedm,readDRaw,memWrtm,rst);
    always_comb begin : datmem
        mem_addr=aluRsltm;
        mem_wrt=wrtDShiftedm;
        readDRaw=mem_read;
        mem_read_wrt=memWrtm;
        mem_req=memWrtm|readm;
    end

    loadunit LU(funct3m,strobem,readDRaw,readDm);

    logic [31:0] aluRsltw,pc4w,ujWrtBckw;
    logic [4:0] rdw;
    logic regWrtw,memWrtw;
    logic [2:0] rsltSrcw;

    mewb MW(clk,regWrtm,memWrtm,rsltSrcm,regWrtw,memWrtw,rsltSrcw,readDm,pc4m,ujWrtBckm,aluRsltm,rdm,readDw,pc4w,ujWrtBckw,aluRsltw,rdw);

    always_comb begin
        case(rsltSrcw)
            3'b000:
                rsltw=aluRsltw;
            3'b001:
                rsltw=readDw;
            3'b010:
                rsltw=pc4w;
            3'b011:
                rsltw=ujWrtBckw;
            default:
                rsltw=32'b0;
        endcase
    end

    logic stallf,stalld,stalle,stallm,flushd,flushe;

    hazardunit HAZARD(ad1d,ad2d,ad1e,ad2e,rde,rdm,rdw,rsltSrce,rsltSrcm,pcSrc,regWrtm,regWrtw,memBusy,divBusy,instBusy,doned,stallf,stalld,stalle,stallm,flushd,flushe,fwdAe,fwdBe);

    logic bt;

    always_comb begin
        case(funct3e)
            3'b000:
                bt=brnche&zeroe;
            3'b001:
                bt=brnche&~zeroe;
            3'b100:
                bt=brnche&lstBite;
            3'b101:
                bt=brnche&~lstBite;
            3'b110:
                bt=brnche&lstBite;
            3'b111:
                bt=brnche&~lstBite;
            default:
                bt=1'bx;
        endcase
    end

    assign pcSrc=jmpe|bt;

endmodule

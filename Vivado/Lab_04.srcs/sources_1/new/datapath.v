`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/02 09:09:32
// Design Name: 
// Module Name: datapath
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module datapath(
    input wire clka,rst, branch, memtoregM,
    input wire [31:0] instr, mem_rdata,
    output wire zeroM, stallD, pcsrcD,
    output wire [31:0] pc, alu_resultM, writedataM,
    
    input wire jump, pcsrc, alusrc, memtoregE, memtoregW, regwriteE, regwriteM, regwriteW, regdst,
    input wire [2:0] alucontrol
    );

wire [31:0] pc_plus4, rd1D, rd2D, imm_extend, pc_next, pc_next_jump, instr_sl2;
wire [31:0] mem_rdata, alu_srcB, wd3, imm_sl2, pc_branch, pc_branchM;
wire [4:0] write2regE, write2regM, write2regW;
wire [31:0] rd1, rd2, writedataE;
wire stallF, stallE, flushE;

wire [31:0] instrD, pc_plus4D, rd1E, rd2E, pc_plus4E, imm_extendE, alu_result, alu_resultW, mem_rdataW;
wire [4:0] rsD, rtD, rdD, rsE, rtE, rdE, rtM, rdM, rtW, rdW;
wire zero;
wire [31:0] eql1, eql2;

mux2 #(32) eql_1(
    .a(alu_resultM),
    .b(rd1D),
    .s(forwardAD), //pcsrc
    .y(eql1)
);

mux2 #(32) eql_2(
    .a(alu_resultM),
    .b(rd2D),
    .s(forwardBD), //pcsrc
    .y(eql2)
);

assign pcsrcD = ((eql1==eql2)?1:0)&branch;

//pcsrc
//assign pcsrc = zero & beanch;

//assign mem_wdata = rd2;

    //mux2 for pc_next
mux2 #(32) mux_pc(
    .a(pc_branch),
    .b(pc_plus4),
    .s(pcsrcD), //pcsrc
    .y(pc_next)
    );
    
    //left shift 2 for pc_jump instr_index
sl2 sl2_instr(
    .a(instrD),
    .y(instr_sl2)
    );
    
    //mux for pc_jump
mux2 #(32) mux_pc_jump(
//    .a({pc_plus4[31:29],instr_sl2[28:0]}),
    .a({pc_plus4[31:28],instr_sl2[27:0]}),
    .b(pc_next),
    .s(jump), //pcsrc
    .y(pc_next_jump)
    );

    //pc
pc pc1( 
    .clk(clka), //
    .rst(rst), //
    .en(~stallF),
    .din(pc_next_jump), //
    .q(pc) //
);

    //pc + 4
adder pc_plus_4(
    .a(pc), //
    .b(32'd4), //
    .y(pc_plus4) //
    );
    
    // F_D
floprc #(32) r1D(
    .clk(clka), 
    .rst(rst),
    .en(~stallD), 
    .clear(pcsrcD|jump),
    .d(instr),
    .q(instrD)
    );
    
floprc #(32) r2D(
    .clk(clka), 
    .rst(rst), 
    .en(~stallD), 
    .clear(pcsrcD),
    .d(pc_plus4),
    .q(pc_plus4D)
    );





    //imm extend
sign_extend sign_extend1(
    .a(instrD[15:0]),
    .y(imm_extend)
    );
    


assign rtD = instrD[20:16];
assign rdD = instrD[15:11];
assign rsD = instrD[25:21];
  

    //regfile
regfile regfile(
    .clk(clka),
    .we3(regwriteW), //regwrite
    .ra1(instrD[25:21]), //base
    .ra2(instrD[20:16]), //sw, load from rt
    .wa3(write2regW[4:0]), //lw, store to rt
    .wd3(wd3),
    .rd1(rd1D), 
    .rd2(rd2D)
    );
    
floprc #(32) r3E(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1), 
    .clear(flushE),
    .d(rd1D),
    .q(rd1E)
    );

floprc #(32) r4E(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1), 
    .clear(flushE),
    .d(rd2D),
    .q(rd2E)
    );

floprc #(5) r6E(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1), 
    .clear(flushE),
    .d(rtD),
    .q(rtE)
    );

floprc #(5) r7E(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1), 
    .clear(flushE),
    .d(rdD),
    .q(rdE)
    );

floprc #(32) r8E(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1), 
    .clear(flushE),
    .d(pc_plus4D),
    .q(pc_plus4E)
    );
    
floprc #(32) r9E(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1), 
    .clear(flushE),
    .d(imm_extend),
    .q(imm_extendE)
    );

floprc #(5) rs_E(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1), 
    .clear(flushE),
    .d(rsD),
    .q(rsE)
    );
    

    
    //mux2 for wd3, write addr port of regfile
mux2 #(5) mux_wa3(
    .a(rdE),
    .b(rtE),
    .s(regdst), //regdst
    .y(write2regE)
    );
    

    
mux3 #(32) srcA_sel(rd1E, wd3, alu_resultM, forwardAE, rd1);
mux3 #(32) srcB_sel(rd2E, wd3, alu_resultM, forwardBE, rd2);

assign writedataE = rd2;

    //mux2 for alu_srcB
mux2 #(32) mux_alu_srcb(
    .a(imm_extendE),
    .b(rd2),
    .s(alusrc), //alusrc
    .y(alu_srcB)
    );
    
    //alu
alu_always alu(
    .clk(clka),
    .a(rd1),
    .b(alu_srcB),//.b(imm_extend)
    .f(alucontrol[2:0]), //alucontrol
    .y(alu_result),
    .overflow(overflow),
    .zero(zero)
    );
    wire overflow;
    
    //left shift 2 for pc_brranch imm
sl2 sl2_imm(
    .a(imm_extend),
    .y(imm_sl2)
    );
    
    //pc_branch = pc + 4 + (sign_ext imm << 2)
adder pc_branch1(
    .a(pc_plus4D), 
    .b(imm_sl2),
    .y(pc_branch)
    );

floprc #(32) writedata_M(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1), 
    .clear(1'b0),
    .d(writedataE),
    .q(writedataM)
    );    

floprc #(32) r10M(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1), 
    .clear(1'b0),
    .d(alu_result),
    .q(alu_resultM)
    );
    
floprc #(1) r11M(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1), 
    .clear(1'b0),
    .d(zero),
    .q(zeroM)
    );
    
floprc #(32) r12M(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1), 
    .clear(1'b0),
    .d(write2regE),
    .q(write2regM)
    );
    
floprc #(32) r13M(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1), 
    .clear(1'b0),
    .d(pc_branch),
    .q(pc_branchM)
    );
    


floprc #(5) r7M(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1), 
    .clear(1'b0),
    .d(rdE),
    .q(rdM)
    );

//mem_rdata    
floprc #(32) r13W(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1), 
    .clear(1'b0),
    .d(alu_resultM),
    .q(alu_resultW)
    );
    
floprc #(32) r14W(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1), 
    .clear(1'b0),
    .d(mem_rdata),
    .q(mem_rdataW)
    );
    
floprc #(5) r6W(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1), 
    .clear(1'b0),
    .d(write2regM),
    .q(write2regW)
    );


    
    //mux2 for wd3, write data port of regfile
mux2 #(32) mux_wd3(
    .a(mem_rdataW),
    .b(alu_resultW),
    .s(memtoregW), //memtorg
    .y(wd3)
    );
    


wire [1:0] forwardAE, forwardBE;
wire forwardAD, forwardBD;
// hazard
hazard hazard(
    .rsD(rsD), 
    .rtD(rtD),
    .rsE(rsE), 
    .rtE(rtE), 
    .writeregE(write2regE), 
    .writeregM(write2regM), 
    .writeregW(write2regW),
    .regwriteE(regwriteE),
    .regwriteM(regwriteM), 
    .regwriteW(regwriteW),
    .memtoregE(memtoregE),
    .memtoregM(memtoregM),
    .branchD(branch),
    .forwardAE(forwardAE), 
    .forwardBE(forwardBE),
    .forwardAD(forwardAD), 
    .forwardBD(forwardBD),
    .stallF(stallF), 
    .stallD(stallD), 
    .flushE(flushE)

);
    
    always @(*) begin
        $display("clka:%b $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$",clka);
        $display("datapath, write2reg��%b, regwrite: %d, pc: %h, instr: %h, instr[25:21]: %b, instr[20:16]: %b, rd1D: %d, rd1E: %d, alu_srcB: %d, alucontrol:%b, alu_result:%d,memtorg:%b, wd3:%d",write2regE, regwriteE, pc, instrD, instrD[25:21], instrD[20:16], rd1D, rd1E, alu_srcB, alucontrol, alu_resultW, memtoregW, wd3);
        $display("datapath, rd1D:%d,forwardAD:%d,rd2D:%d,forwardBD:%d,alu_resultM:%d, eql1:%d,eql2:%d,branch:%d,pcsrc:%b",rd1D,forwardAD,rd2D,forwardBD,alu_resultM,eql1,eql2,branch,pcsrcD);
        $display("datapath, pcsrc:%b, pc_next:%h,pc_branchM:%h, jump:%b,pc_jump:%h, pc_next_jump:%h", pcsrcD, pc_next,pc_branchM, jump,{pc_plus4[31:28],instr_sl2[27:0]}, pc_next_jump);
        $display("datapath, pc_branch:%h, pc_plus4E:%d, imm_sl2:%d",pc_branch, pc_plus4E, imm_sl2);
        $display("rsD:%d, rtD:%d, rsE:%d, rtE:%d, writeregE:%d, writeregM:%d, writeregW:%d,",instrD[25:21], rtD, rsE, rtE, write2regE, write2regM, write2regW);
        $display("regwriteE:%d, regwriteM:%d, regwriteW:%d, memtoregE:%d, branchD:%d",regwriteE, regwriteM, regwriteW, memtoregE, branch);
        $display("~stallF:%b,pc:%h,instr:%h,instrD:%h",~stallF,pc,instr, instrD);
        $display("pc_plus4:%h,pc_plus4D:%h",pc_plus4, pc_plus4D);
        $display("rd1D:%d,rd1E:%d",rd1D, rd1E);
        $display("rd2D:%d,rd2E:%d",rd2D, rd2E);
        
    end
    

endmodule

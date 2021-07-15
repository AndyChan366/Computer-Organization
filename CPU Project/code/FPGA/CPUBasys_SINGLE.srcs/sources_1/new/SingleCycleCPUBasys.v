`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/05/20 20:56:04
// Design Name: 
// Module Name: SingleCycleCPUBasys
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


module SingleCycleCPUBasys(
        input CLK,
        input Reset,
        output [31:0] curPC,
        output [31:0] nextPC,
        output [31:0] instruction,
        output [5:0] op,
        output [4:0] rs,
        output [4:0] rt,
        output [4:0] rd,
        output [31:0] DB,
        output [31:0] A,
        output [31:0] B,
        output [31:0] result,
        output [1:0] PCSrc
    );
    
    wire zero;
    wire PCWre;       //PC�Ƿ���ĵ��ź�����Ϊ0ʱ�򲻸��ģ�������Ը���
    wire ExtSel;      //��������չ���ź�����Ϊ0ʱ��Ϊ0��չ������Ϊ������չ
    wire InsMemRW;    //ָ��Ĵ�����״̬��������Ϊ0��ʱ��дָ��Ĵ���������Ϊ��ָ��Ĵ���
    wire RegDst;      //д�Ĵ�����Ĵ����ĵ�ַ��Ϊ0��ʱ���ַ����rt��Ϊ1��ʱ���ַ����rd
    wire RegWre;      //�Ĵ�����дʹ�ܣ�Ϊ1��ʱ���д
    wire ALUSrcA;     //����ALU����A��ѡ��˵����룬Ϊ0��ʱ�����ԼĴ�����data1�����Ϊ1��ʱ��������λ��sa
    wire ALUSrcB;     //����ALU����B��ѡ��˵����룬Ϊ0��ʱ�����ԼĴ�����data2�����Ϊ1ʱ��������չ����������
   // wire [1:0]PCSrc;  //��ȡ��һ��pc�ĵ�ַ������ѡ������ѡ�������
    wire [2:0]ALUOp;  //ALU 8�����㹦��ѡ��(000-111)
    wire mRD;         //���ݴ洢���������źţ�Ϊ0��
    wire mWR;         //���ݴ洢��д�����źţ�Ϊ0д
    wire DBDataSrc;    //���ݱ����ѡ��ˣ�Ϊ0����ALU�������������Ϊ1�������ݼĴ�����Data MEM�������  
    wire [31:0] extend;
    wire [31:0] DataOut;
    wire[4:0] sa;
    wire[15:0] immediate;
    wire[25:0] addr;
    /*
        module pcAdd(
            input CLK,               //ʱ��
            input [1:0] PCSrc,             //����ѡ��������
            input [31:0] immediate,  //ƫ����
            input [25:0] addr,
            input [31:0] curPC,
            output [31:0] nextPC  //��ָ���ַ
        );
    */
    pcAdd pcAdd(.Reset(Reset),
                .CLK(CLK),
                .PCSrc(PCSrc),
                .immediate(extend),
                .addr(addr),
                .curPC(curPC),
                .nextPC(nextPC));
    
    /*
        module PC(
           input CLK,               //ʱ��
           input Reset,             //�Ƿ����õ�ַ��0-��ʼ��PC����������µ�ַ
           input PCWre,             //�Ƿ�����µĵ�ַ��0-�����ģ�1-���Ը���
           input [1:0] PCSrc,             //����ѡ��������
           input [31:0] nextPC,  //��ǰָ���ַ
           output reg[31:0] curPC //��һ��ָ��ĵ�ַ
        );
    */
    PC pc(.CLK(CLK),
          .Reset(Reset),
          .PCWre(PCWre),
          .PCSrc(PCSrc),
          .nextPC(nextPC),
          .curPC(curPC));
          
    /*
    module InsMEM(
          input [31:0] IAddr,
          input InsMemRW,             //״̬Ϊ'0'��дָ��Ĵ���������Ϊ��ָ��Ĵ���
          output reg[31:0] IDataOut
      );
    */
    InsMEM InsMEM(.IAddr(curPC), 
                .InsMemRW(InsMemRW), 
                .IDataOut(instruction));
                    
    /*
        module InstructionCut(
            input [31:0] instruction,
            output reg[5:0] op,
            output reg[4:0] rs,
            output reg[4:0] rt,
            output reg[4:0] rd,
            output reg[4:0] sa,
            output reg[15:0] immediate,
            output reg[25:0] addr
        );
    */
    InstructionCut InstructionCut(.instruction(instruction),
                                  .op(op),
                                  .rs(rs),
                                  .rt(rt),
                                  .rd(rd),
                                  .sa(sa),
                                  .immediate(immediate),
                                  .addr(addr));
                                  
    /*
        module ControlUnit(
            input zero,         //ALU�������Ƿ�Ϊ0��Ϊ0ʱ��Ϊ1
            input [5:0] op,     //ָ��Ĳ�����
            output reg PCWre,       //PC�Ƿ���ĵ��ź�����Ϊ0ʱ�򲻸��ģ�������Ը���
            output reg ExtSel,      //��������չ���ź�����Ϊ0ʱ��Ϊ0��չ������Ϊ������չ
            output reg InsMemRW,    //ָ��Ĵ�����״̬��������Ϊ0��ʱ��дָ��Ĵ���������Ϊ��ָ��Ĵ���
            output reg RegDst,      //д�Ĵ�����Ĵ����ĵ�ַ��Ϊ0��ʱ���ַ����rt��Ϊ1��ʱ���ַ����rd
            output reg RegWre,      //�Ĵ�����дʹ�ܣ�Ϊ1��ʱ���д
            output reg ALUSrcA,     //����ALU����A��ѡ��˵����룬Ϊ0��ʱ�����ԼĴ�����data1�����Ϊ1��ʱ��������λ��sa
            output reg ALUSrcB,     //����ALU����B��ѡ��˵����룬Ϊ0��ʱ�����ԼĴ�����data2�����Ϊ1ʱ��������չ����������
            output reg [1:0]PCSrc,  //��ȡ��һ��pc�ĵ�ַ������ѡ������ѡ�������
            output reg [2:0]ALUOp,  //ALU 8�����㹦��ѡ��(000-111)
            output reg mRD,         //���ݴ洢���������źţ�Ϊ0��
            output reg mWR,         //���ݴ洢��д�����źţ�Ϊ0д
            output reg DBDataSrc    //���ݱ����ѡ��ˣ�Ϊ0����ALU�������������Ϊ1�������ݼĴ�����Data MEM�������        
        );
    */
    ControlUnit ControlUnit(.zero(zero),
                            .op(op),
                            .PCWre(PCWre),
                            .ExtSel(ExtSel),
                            .InsMemRW(InsMemRW),
                            .RegDst(RegDst),
                            .RegWre(RegWre),
                            .ALUSrcA(ALUSrcA),
                            .ALUSrcB(ALUSrcB),
                            .PCSrc(PCSrc),
                            .ALUOp(ALUOp),
                            .mRD(mRD),
                            .mWR(mWR),
                            .DBDataSrc(DBDataSrc));
    
    /*
        module RegisterFile(
            input CLK,                  //ʱ��
            input [4:0] ReadReg1,    //rs�Ĵ�����ַ����˿�
            input [4:0] ReadReg2,    //rt�Ĵ�����ַ����˿�
            input [31:0] WriteData,     //д��Ĵ�������������˿�
            input [4:0] WriteReg,       //������д��ļĴ����˿ڣ����ַ��Դrt��rd�ֶ�
            input RegWre,               //WE��дʹ���źţ�Ϊ1ʱ����ʱ�ӱ��ش���д��
            output [31:0] ReadData1,  //rs�Ĵ�����������˿�
            output [31:0] ReadData2   //rt�Ĵ�����������˿�
        );
    */
    RegisterFile RegisterFile(.CLK(CLK),
                              .ReadReg1(rs),
                              .ReadReg2(rt),
                              .WriteData(DB),
                              .WriteReg(RegDst ? rd : rt),
                              .RegWre(RegWre),
                              .ReadData1(A),
                              .ReadData2(B));
                              
    /*
        module ALU(
            input ALUSrcA,
            input ALUSrcB,
            input [31:0] ReadData1,
            input [31:0] ReadData2,
            input [4:0] sa,
            input [31:0] extend,
            input [2:0] ALUOp,
            output reg zero,
            output reg[31:0] result
        );
    */
    ALU alu(.ALUSrcA(ALUSrcA),
            .ALUSrcB(ALUSrcB),
            .ReadData1(A),
            .ReadData2(B),
            .sa(sa),
            .extend(extend),
            .ALUOp(ALUOp),
            .zero(zero),
            .result(result));
    
    /*
        module DataMEM(
            input mRD,
            input mWR,
            input CLK,
            input DBDataSrc,
            input [31:0] DAddr,
            input [31:0] DataIn,
            output reg[31:0] DataOut,
            output reg[31:0] DB
        );
    */
    DataMEM DataMEM(.mRD(mRD),
                    .mWR(mWR),
                    .CLK(CLK),
                    .DBDataSrc(DBDataSrc),
                    .DAddr(result),
                    .DataIn(B),
                    .DataOut(DataOut),
                    .DB(DB));
    
    /*
        module SignZeroExtend(
            input wire [15:0] immediate,    //������
            input ExtSel,                   //״̬'0',0��չ���������λ��չ
            output wire[31:0] extendImmediate
        );
    */
    SignZeroExtend SignZeroExtend(.immediate(immediate),
                                  .ExtSel(ExtSel),
                                  .extendImmediate(extend));
    
endmodule
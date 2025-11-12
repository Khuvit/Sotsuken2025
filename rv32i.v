
module rv32i #(
    //  --------------------------------------------------------------------
    //  parameter declare
    //  --------------------------------------------------------------------
    parameter   MEMORY_S    =   2**8,
    parameter   OPCODE_W    =   7,
    parameter   SHAMT_W     =   5,
    parameter   OP          =   3,
    parameter   PC_W        =   8,
    parameter   REG_W       =   5,
    parameter   DATA_W      =   32,
    parameter   REG_S       =   32,
    parameter   FUNCT3      =   3,
    parameter   FUNCT7      =   7,
    parameter   IMM         =   32,
    parameter   BYTE        =   8,
    parameter   HALF        =   2*BYTE,
    parameter   WORD        =   4*BYTE,
    parameter   STORE_M     =   2
)(
    // input wire
    input wire                  clk,
    input wire                  n_rst,

    // input from instruction mem
    input wire  [DATA_W-1:0]    instruction,
    // output to instruction mem
    output wire [PC_W-1:0]      pc,

    // input from data mem
    input wire  [DATA_W-1:0]    d_in,

    // output to data mem
    output wire                 wr_en,
    output wire [STORE_M-1:0]   mode,
    output wire [PC_W-1:0]      wr_addr,
    output wire [PC_W-1:0]      rd_addr,
    output wire [DATA_W-1:0]    d_out
);

    reg [PC_W - 1:0]        pc_reg;
    reg                     pc_en_reg;
    reg [DATA_W - 1:0]      inst;
    wire                    r_we;

  
    assign pc    = pc_reg;

    //  --------------------------------------------------------------------
    //  Fetch STAGE
    //  --------------------------------------------------------------------


    always @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            pc_reg <= 0;
        end else begin
            pc_reg <= pc_reg + 8'd4;
        end
    end

    always @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            inst <= 0;
        end else begin
            inst <= instruction;
        end
    end


    //  --------------------------------------------------------------------
    //  Decode STAGE
    //  --------------------------------------------------------------------

    wire    [REG_W-1:0]     rs1,rs2,rd;
    wire    [DATA_W-1:0]    rdata1,rdata2;
    wire                    aluop;
    wire    [OPCODE_W-1:0]  opcode;
    wire    [FUNCT3-1:0]    funct3;
    wire    [IMM-1:0]       imm;
    wire    [19:0   ]       sext;

    reg     [REG_W-1:0]     rd_E;
    reg     [DATA_W-1:0]    rdata_E1,rdata_E2;
    reg                     aluop_E;
    reg     [OP-1:0]        funct3_E;
    reg     [IMM-1:0]       imm_E;
    reg     [OPCODE_W-1:0]  opcode_E;

    assign funct7   = inst[31:25];
    assign rs2      = inst[24:20];
    assign rs1      = inst[19:15];
    assign funct3   = inst[14:12];
    assign rd       = inst[11:7];
    assign opcode   = inst[6:0];
    assign aluop    = inst[30];
    assign sext     = {20{inst[31]}};
    assign imm      = {sext, funct7, rs2};
       
    rfile #(
        .REG_W(REG_W),
        .DATA_W(DATA_W),
        .REG_S(REG_S)
    )rfile(
        .clk(clk),
        .a1(rs1),       // read address 1
        .a2(rs2),       // read address 2
        .a3(rd_W),      // write address
        .rd1(rdata1),   // read data 1
        .rd2(rdata2),   // read data 2
        .wd(wd),        // write data
        .we(r_we)       // write enable
    );

    always @(posedge clk) begin
        rdata_E1    <= rdata1;
        rdata_E2    <= rdata2;
        rd_E        <= rd;
        funct3_E    <= funct3;
        aluop_E     <= aluop;
        opcode_E    <= opcode;
        imm_E       <= imm;
    end

    //  --------------------------------------------------------------------
    //  Execute STAGE
    //  --------------------------------------------------------------------

    reg     [DATA_W-1:0]    alu_res_M;
    reg     [REG_W-1:0]     rd_M;
    reg     [FUNCT3-1:0]    funct3_M;
    reg     [DATA_W-1:0]    rdata_M1,rdata_M2;
    reg     [OPCODE_W-1:0]  opcode_M;
    wire    [DATA_W-1:0]    alu_res;
    wire    [DATA_W-1:0]    in_a, in_b;
    wire    [FUNCT3-1:0]    s;
   

    assign beq      = (funct3_E == `OP_BEQ);
    assign bne      = (funct3_E == `OP_BNE);
    assign blt      = (funct3_E == `OP_BLT);
    assign bge      = (funct3_E == `OP_BGE);
    assign bltu     = (funct3_E == `OP_BLTU);
    assign bgeu     = (funct3_E == `OP_BGEU);
    assign s        = (opcode_E[4]) ? funct3_E : 0;
    assign in_a     = rdata_E1;
    assign in_b     = imm_E;

    alu #(
        .DATA_W(DATA_W),
        .SHAMT_W(SHAMT_W),
        .OP(OP)
    )alu(
        .a(in_a),
        .b(in_b),
        .s(s), // need 0
        .ext(aluop_E),
        .y(alu_res)
    );

    always @(posedge clk)begin
        alu_res_M   <= alu_res;
        rd_M        <= rd_E;
        funct3_M    <= funct3_E;
        opcode_M    <= opcode_E;
        rdata_M1    <= rdata_E1;
        rdata_M2    <= rdata_E2;
    end

    //  --------------------------------------------------------------------
    //  Memory STAGE
    //  --------------------------------------------------------------------

    wire    [DATA_W-1:0]    rd_data;

    reg     [OPCODE_W-1:0]  opcode_W;
    reg     [DATA_W-1:0]    rd_data_W;
    reg     [DATA_W-1:0]    alu_res_W;
    reg     [REG_W-1:0]     rd_W;

    assign rd_addr  = alu_res_M;
    assign rd_data  = rd_data_sel(funct3_M,d_in);

    function [DATA_W-1:0] rd_data_sel(
        input [FUNCT3-1:0] funct,
        input [DATA_W-1:0] data
    );
        case(funct)
            3'b000 : rd_data_sel = (data[7]) ? {24'hFFFFFF,data[7:0]}:{24'h0,data[7:0]};
            3'b001 : rd_data_sel = (data[15]) ? {16'hFFFF,data[15:0]}:{16'h0,data[15:0]};
            3'b010 : rd_data_sel = data;
            3'b100 : rd_data_sel = {24'h0,data[7:0]};
            3'b101 : rd_data_sel = {16'h0,data[15:0]};
            default: rd_data_sel = 32'h0;
        endcase
    endfunction


    always @(posedge clk) begin
        opcode_W    <= opcode_M;
        rd_data_W   <= rd_data;
        rd_W        <= rd_M;
        alu_res_W   <= alu_res_M;
    end

    //  --------------------------------------------------------------------
    //  Write Back STAGE
    //  --------------------------------------------------------------------

    wire [DATA_W-1:0]   wd;

    assign wd       = rd_data_W;
    assign r_we     = (opcode_W == `OP_LOAD);
endmodule
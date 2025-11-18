`timescale 1ns/1ps
// ALU のテストベンチ
module tb_alu;

    localparam DATA_W  = 32;
    localparam SHAMT_W = 5;
    localparam OP_W    = 3;

    reg  [DATA_W-1:0] a, b;
    reg  [OP_W-1:0]   s;
    reg               ext;
    wire [DATA_W-1:0] y;

    // DUT
    alu #(
        .DATA_W(DATA_W),
        .SHAMT_W(SHAMT_W),
        .OP(OP_W)
    ) uut (
        .a(a),
        .b(b),
        .s(s),
        .ext(ext),
        .y(y)
    );

    // VCD 出力
    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, tb_alu);
    end

    initial begin
        // 初期化
        a = 0; b = 0; s = 3'b000; ext = 0;
        #5;

        // ---- Test 1: AND 6 & 3 = 2 ----
        $display("=== Test1: AND 6 & 3 ===");
        a = 32'd6;
        b = 32'd3;
        s = 3'b111;  // alu.v のコメントで AND
        ext = 0;
        #5;
        $display("time %0t : y = %0d (Souteichi: 2)", $time, y);

        // ---- Test 2: OR 2 | 1 = 3 ----
        $display("=== Test2: OR 2 | 1 ===");
        a = 32'd2;
        b = 32'd1;
        s = 3'b110;  // OR
        #5;
        $display("time %0t : y = %0d (Souteichi: 3)", $time, y);

        // ---- Test 3: XOR 4 ^ 1 = 5 ----
        $display("=== Test3: XOR 4 ^ 1 ===");
        a = 32'd4;
        b = 32'd1;
        s = 3'b100;  // XOR
        #5;
        $display("time %0t : y = %0d (Souteichi: 5)", $time, y);

        // ---- Test 4: SLL 1 << 3 = 8 ----
        $display("=== Test4: SLL 1 << 3 ===");
        a = 32'd1;
        b = 32'd3;   // shamt = 3
        s = 3'b001;  // SLL
        #5;
        $display("time %0t : y = %0d (Souteichi: 8)", $time, y);

        // ---- Test 5: SRL 16 >> 2 = 4 ----
        $display("=== Test5: SRL 16 >> 2 ===");
        a = 32'd16;
        b = 32'd2;   // shamt = 2
        s = 3'b101;  // SRL/SRA
        ext = 0;     // 0 = SRL
        #5;
        $display("time %0t : y = %0d (Souteichi: 4)", $time, y);

        $display("=== alu test done ===");
        #10;
        $finish;
    end

endmodule

module rfile #(
    parameter REG_W = -1,
    parameter REG_S = -1,
    parameter DATA_W = -1
)(
    input wire                  clk,
    input wire  [REG_W-1:0]     a1,a2,a3,
    output wire  [DATA_W-1:0]   rd1,rd2,
    input wire  [DATA_W-1:0]    wd,
    input wire                  we
);
    reg [DATA_W-1:0] rf [0:REG_S-1];

    //debug ---------------------
    wire [DATA_W-1:0] x1;
    assign x1 = rf[1];
    // -------------------------

    assign rd1 = |a1 == 0 ? 0 : rf[a1];
    assign rd2 = |a2 == 0 ? 0 : rf[a2];

    always @(posedge clk) begin
        if (we) begin
            rf[a3] <= wd;
        end
    end
endmodule
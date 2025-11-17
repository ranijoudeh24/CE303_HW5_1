// mac.v
`timescale 1ns/1ps

module mac (
    input  wire                 clk,
    input  wire                 rstb,         // active-low reset
    input  wire signed  [3:0]   IN,          // signed 4-bit input
    input  wire signed  [3:0]   W,           // signed 4-bit weight
    output reg  signed [11:0]   OUT          // signed 12-bit output
);

    // Pipeline registers
    reg signed [3:0]  in_reg;        // stage 0: registered IN
    reg signed [3:0]  w_reg;         // stage 0: registered W
    reg signed [7:0]  mul_reg;       // stage 1: product of in_reg * w_reg
    reg signed [11:0] acc_reg;       // stage 2: accumulator

    // 4-bit counter to count 0..8 (9 products)
    reg [3:0] cnt;

    // sign-extend multiplier output to 12 bits
    wire signed [11:0] mul_ext = {{4{mul_reg[7]}}, mul_reg};

    // combinational next value of accumulator
    reg signed [11:0] acc_next;

    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            // async reset: everything to 0
            in_reg  <= 4'sd0;
            w_reg   <= 4'sd0;
            mul_reg <= 8'sd0;
            acc_reg <= 12'sd0;
            OUT     <= 12'sd0;
            cnt     <= 4'd0;
        end else begin
            // Stage 0: register inputs
            in_reg  <= IN;
            w_reg   <= W;

            // Stage 1: multiplier pipeline
            mul_reg <= in_reg * w_reg;  // signed multiply

            // Stage 2: accumulator (9 products per window)
            if (cnt == 4'd0) begin
                // start a new accumulation window
                acc_next = mul_ext;
            end else begin
                acc_next = acc_reg + mul_ext;
            end

            acc_reg <= acc_next;

            // Stage 3: output register
            if (cnt == 4'd8) begin
                // after 9th product, capture result and restart count
                OUT <= acc_next;
                cnt <= 4'd0;
            end else begin
                // still accumulating within this window
                OUT <= OUT;        // hold previous output
                cnt <= cnt + 4'd1;
            end
        end
    end

endmodule

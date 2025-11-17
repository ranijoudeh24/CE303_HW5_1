// mac4x4_mac9.v
`timescale 1ns/1ps

module mac (
    input  wire               clk,
    input  wire               rstb,           // active-low async reset
    input  wire signed [3:0]  IN,             // signed 4-bit input
    input  wire signed [3:0]  W,              // signed 4-bit weight
    output reg  signed [11:0] OUT             // signed 12-bit output
);
    // Stage 0: register inputs (pipeline)
    reg signed [3:0] in_r, w_r;

    // Stage 1: multiply and register product (signed 8-bit)
    wire signed [7:0] prod_w = in_r * w_r;
    reg  signed [7:0] prod_r;

    // Stage 2: 9-cycle accumulator and cycle counter
    reg  [3:0]        cyc9;                   // counts 0..8
    reg  signed [11:0] acc;                   // wide enough for 9*max(|prod|)
                                              // max |prod| = 64 -> 9*64 = 576 < 2^10

    // Pipeline + accumulator
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            in_r   <= '0;
            w_r    <= '0;
            prod_r <= '0;
            acc    <= '0;
            cyc9   <= 4'd0;
            OUT    <= '0;
        end else begin
            // Stage 0
            in_r   <= IN;
            w_r    <= W;

            // Stage 1
            prod_r <= prod_w;

            // Stage 2: accumulate over 9 cycles, then output and restart
            if (cyc9 == 4'd0) begin
                acc <= {{4{prod_r[7]}}, prod_r};   // sign-extend 8->12 and start from 0 + prod
            end else begin
                acc <= acc + {{4{prod_r[7]}}, prod_r};
            end

            // Roll the 0..8 counter and update OUT when finishing a window
            if (cyc9 == 4'd8) begin
                OUT  <= acc;        // register final sum
                cyc9 <= 4'd0;
            end else begin
                cyc9 <= cyc9 + 4'd1;
            end
        end
    end
endmodule

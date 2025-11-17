// tb_mac4x4_mac9.v
`timescale 1ns/1ps

module tb_mac4x4_mac9;
    reg                clk;
    reg                rstb;
    reg  signed [3:0]  IN;
    reg  signed [3:0]  W;
    wire signed [11:0] OUT;

    mac4x4_mac9 dut(.clk(clk), .rstb(rstb), .IN(IN), .W(W), .OUT(OUT));

    // Clock: 1.0 ns period (1 GHz)
    initial clk = 0;
    always #0.5 clk = ~clk;

    // Reference pipeline model
    reg  signed [3:0]  in_r, w_r;
    wire signed [7:0]  prod_w = in_r * w_r;
    reg  signed [7:0]  prod_r;

    reg  [3:0]         cyc9;
    reg  signed [11:0] acc;
    reg  signed [11:0] OUT_ref;

    // Simple stimulus: vary IN, W each cycle (nonzero)
    integer i;
    initial begin
        rstb = 0;
        IN   = 0;
        W    = 0;
        in_r = 0;
        w_r  = 0;
        prod_r = 0;
        acc  = 0;
        cyc9 = 0;
        OUT_ref = 0;

        // VCD for waveform inspection
        $dumpfile("tb_mac4x4_mac9.vcd");
        $dumpvars(0, tb_mac4x4_mac9);

        repeat (3) @(posedge clk);
        rstb = 1;

        // Drive ~30 cycles: > two full 9-cycle windows plus pipeline fill
        for (i = 0; i < 30; i = i + 1) begin
            // Drive changing signed 4-bit patterns (avoid all-zero)
            IN <= $signed(((i*3) % 16) - 8);
            W  <= $signed(((i*5+1) % 16) - 8);

            @(posedge clk);

            // Reference pipeline: stage 0 and 1
            in_r  <= IN;
            w_r   <= W;
            prod_r <= prod_w;

            // Reference accumulator and OUT
            if (cyc9 == 4'd0) begin
                acc <= {{4{prod_r[7]}}, prod_r};
            end else begin
                acc <= acc + {{4{prod_r[7]}}, prod_r};
            end

            if (cyc9 == 4'd8) begin
                OUT_ref <= acc;
                cyc9    <= 4'd0;
            end else begin
                cyc9    <= cyc9 + 4'd1;
            end

            // Compare when OUT should be valid (every 9 cycles)
            if (cyc9 == 4'd8) begin
                // Allow 1 cycle for DUT to register OUT (both models match timing)
                @(posedge clk);
                if (OUT !== OUT_ref) begin
                    $display("ERROR @ t=%0t ns: OUT=%0d, expected=%0d", $realtime, OUT, OUT_ref);
                    $stop;
                end else begin
                    $display("PASS  @ t=%0t ns: OUT=%0d", $realtime, OUT);
                end
            end
        end

        $display("ALL TESTS PASSED");
        $finish;
    end
endmodule

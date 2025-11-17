// tb_mac.v
`timescale 1ns/1ps

module tb_mac;

    reg                 clk;
    reg                 rstb;
    reg  signed [3:0]   IN;
    reg  signed [3:0]   W;
    wire signed [11:0]  OUT;

    // DUT
    mac dut (
        .clk (clk),
        .rstb(rstb),
        .IN  (IN),
        .W   (W),
        .OUT (OUT)
    );

    // 1 GHz clock: period = 1 ns
    initial begin
        clk = 1'b0;
        forever #0.5 clk = ~clk;
    end

    // Stimulus sequences (choose anything non-trivial, not all zeros)
    reg signed [3:0] in_vec [0:31];
    reg signed [3:0] w_vec  [0:31];

    integer i;

    initial begin
        // simple deterministic pattern
        in_vec[0]  =  4'sd1;  w_vec[0]  =  4'sd2;
        in_vec[1]  = -4'sd3;  w_vec[1]  =  4'sd1;
        in_vec[2]  =  4'sd4;  w_vec[2]  = -4'sd2;
        in_vec[3]  =  4'sd7;  w_vec[3]  =  4'sd3;
        in_vec[4]  = -4'sd8;  w_vec[4]  =  4'sd4;
        in_vec[5]  =  4'sd5;  w_vec[5]  = -4'sd1;
        in_vec[6]  = -4'sd2;  w_vec[6]  =  4'sd6;
        in_vec[7]  =  4'sd3;  w_vec[7]  = -4'sd3;
        in_vec[8]  = -4'sd4;  w_vec[8]  = -4'sd2;

        // second 9-product window
        in_vec[9]  =  4'sd2;  w_vec[9]  =  4'sd3;
        in_vec[10] =  4'sd1;  w_vec[10] = -4'sd4;
        in_vec[11] = -4'sd5;  w_vec[11] =  4'sd2;
        in_vec[12] =  4'sd7;  w_vec[12] = -4'sd3;
        in_vec[13] = -4'sd6;  w_vec[13] = -4'sd2;
        in_vec[14] =  4'sd5;  w_vec[14] =  4'sd1;
        in_vec[15] = -4'sd1;  w_vec[15] =  4'sd7;
        in_vec[16] =  4'sd3;  w_vec[16] =  4'sd2;
        in_vec[17] = -4'sd8;  w_vec[17] =  4'sd1;

        // default anything else to 0
        for (i = 18; i < 32; i = i + 1) begin
            in_vec[i] = 4'sd0;
            w_vec[i]  = 4'sd0;
        end
    end

    // Reference MAC model (same pipeline depth, used only for checking)
    reg  signed [3:0]   in_ref;
    reg  signed [3:0]   w_ref;
    reg  signed [7:0]   mul_ref;
    reg  signed [11:0]  acc_ref;
    reg  signed [11:0]  out_ref;
    reg  [3:0]          cnt_ref;
    reg                 valid_ref;

    wire signed [11:0]  mul_ext_ref = {{4{mul_ref[7]}}, mul_ref};
    reg  signed [11:0]  acc_next_ref;

    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            in_ref    <= 4'sd0;
            w_ref     <= 4'sd0;
            mul_ref   <= 8'sd0;
            acc_ref   <= 12'sd0;
            out_ref   <= 12'sd0;
            cnt_ref   <= 4'd0;
            valid_ref <= 1'b0;
        end else begin
            // same pipeline as DUT
            in_ref  <= IN;
            w_ref   <= W;
            mul_ref <= in_ref * w_ref;

            if (cnt_ref == 4'd0)
                acc_next_ref = mul_ext_ref;
            else
                acc_next_ref = acc_ref + mul_ext_ref;

            acc_ref <= acc_next_ref;

            if (cnt_ref == 4'd8) begin
                out_ref   <= acc_next_ref;
                cnt_ref   <= 4'd0;
                valid_ref <= 1'b1;
            end else begin
                cnt_ref   <= cnt_ref + 4'd1;
            end
        end
    end

    // Apply stimuli
    initial begin
        rstb = 1'b0;
        IN   = 4'sd0;
        W    = 4'sd0;

        // hold in reset for a few cycles
        repeat (3) @(posedge clk);
        rstb = 1'b1;

        // drive 20 cycles of input values
        for (i = 0; i < 20; i = i + 1) begin
            @(posedge clk);
            IN <= in_vec[i];
            W  <= w_vec[i];
        end

        // let pipeline flush a bit
        repeat (10) @(posedge clk);
        $display("Simulation finished.");
        $finish;
    end

    // Simple monitor: show DUT and reference when valid_ref is asserted.
    always @(posedge clk) begin
        if (rstb && valid_ref) begin
            $display("time=%0t  OUT=%0d  ref=%0d", $time, OUT, out_ref);
        end
    end


endmodule

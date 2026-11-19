// ===========================================================================
// tb/tb_gls_top.v
// Gate-level simulation testbench for the chip top `top`.
//
// `top` combines three blocks:
//   u_adder   combinational ripple carry adder
//   u_pipe    pipelined adder, latency = 1 clock
//   u_addsub  ADD/SUB with a shared adder
//
// The testbench checks all three of them at the same time.
// ===========================================================================
`timescale 1ns / 1ps

module tb_gls_top;

    reg        clk = 1'b0;
    reg        rst = 1'b1;
    reg  [7:0] a, b;
    reg        cin;
    reg        op;
    wire [7:0] sum, psum, sy;
    wire       cout, pcout, ovf;

    integer k;
    integer errors;
    integer exp_comb, exp_pipe, exp_sub;
    integer sign_a, sign_b, sign_r, sign_bb;

    top dut (
        .clk   (clk),
        .rst   (rst),
        .a     (a),
        .b     (b),
        .cin   (cin),
        .op    (op),
        .sum   (sum),
        .cout  (cout),
        .psum  (psum),
        .pcout (pcout),
        .sy    (sy),
        .ovf   (ovf)
    );

    always #5 clk = ~clk;   // 100 MHz

    initial begin
        errors = 0;
        a = 8'h00; b = 8'h00; cin = 1'b0; op = 1'b0;

        repeat (3) @(posedge clk);
        #1 rst = 1'b0;

        for (k = 0; k < 16; k = k + 1) begin
            a   = (k * 37 + 11) & 8'hff;
            b   = (k * 61 + 5) & 8'hff;
            cin = k[0];
            op  = (k % 3 == 0);

            // --- u_adder : a + b + cin (combinational) ---
            exp_comb = a + b + cin;
            // --- u_addsub : a + b or a - b (combinational) ---
            exp_sub  = op ? (a - b) : (a + b);
            // --- u_pipe : a + b + cin (latency 1) ---
            exp_pipe = a + b + cin;

            #1;
            if (sum !== exp_comb[7:0] || cout !== (exp_comb > 255)) begin
                errors = errors + 1;
                $display("GLS top FAIL adder k=%0d a=%h b=%h sum=%h cout=%b",
                         k, a, b, sum, cout);
            end
            if (sy !== exp_sub[7:0]) begin
                errors = errors + 1;
                $display("GLS top FAIL addsub k=%0d a=%h b=%h y=%h", k, a, b, sy);
            end
            sign_a  = (a >= 128);
            sign_b  = (b >= 128);
            sign_r  = (exp_sub[7] == 1'b1);
            sign_bb = op ? (sign_b ^ 1) : sign_b;
            if (ovf !== ((sign_a == sign_bb) && (sign_a != sign_r))) begin
                errors = errors + 1;
                $display("GLS top FAIL ovf k=%0d a=%h b=%h ovf=%b", k, a, b, ovf);
            end

            // the pipelined adder needs two clock edges (latency = 1)
            @(posedge clk);
            @(posedge clk);
            #1;
            if (psum !== exp_pipe[7:0] || pcout !== (exp_pipe > 255)) begin
                errors = errors + 1;
                $display("GLS top FAIL pipe k=%0d a=%h b=%h psum=%h pcout=%b",
                         k, a, b, psum, pcout);
            end
        end

        if (errors == 0)
            $display("GLS top: PASS (16 vectors, 4 checks each)");
        else
            $display("GLS top: FAIL (%0d errors)", errors);
        $finish;
    end

endmodule

// ===========================================================================
// tb/tb_gls_adder8_pipelined.v
// Gate-level simulation testbench for adder8_pipelined.
//
// The design has a latency of one clock cycle: the value that is applied
// before the first rising edge appears on the outputs after the SECOND
// rising edge.  The testbench therefore waits for two rising edges and one
// more nanosecond before it checks the result.
// ===========================================================================
`timescale 1ns / 1ps

module tb_gls_adder8_pipelined;

    reg        clk = 1'b0;
    reg        rst = 1'b1;
    reg  [7:0] a, b;
    reg        cin;
    wire [7:0] sum;
    wire       cout;

    integer k;
    integer errors;
    integer expected;

    adder8_pipelined dut (
        .clk  (clk),
        .rst  (rst),
        .a    (a),
        .b    (b),
        .cin  (cin),
        .sum  (sum),
        .cout (cout)
    );

    always #5 clk = ~clk;   // 100 MHz

    initial begin
        errors = 0;
        a = 8'h00; b = 8'h00; cin = 1'b0;

        repeat (3) @(posedge clk);
        #1 rst = 1'b0;

        for (k = 0; k < 16; k = k + 1) begin
            a   = (k * 37 + 11) & 8'hff;
            b   = (k * 61 + 5) & 8'hff;
            cin = k[0];
            expected = a + b + cin;

            @(posedge clk);
            @(posedge clk);
            #1;

            if (sum !== expected[7:0]) begin
                errors = errors + 1;
                $display("GLS adder8_pipelined FAIL k=%0d a=%h b=%h sum=%h exp=%h",
                         k, a, b, sum, expected[7:0]);
            end
            if (cout !== (expected > 255)) begin
                errors = errors + 1;
                $display("GLS adder8_pipelined FAIL cout k=%0d a=%h b=%h cout=%b",
                         k, a, b, cout);
            end
        end

        if (errors == 0)
            $display("GLS adder8_pipelined: PASS (16 vectors)");
        else
            $display("GLS adder8_pipelined: FAIL (%0d errors)", errors);
        $finish;
    end

endmodule

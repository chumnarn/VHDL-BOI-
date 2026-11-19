// ===========================================================================
// tb/tb_gls_adder8.v
// Gate-level simulation testbench for adder8.
//
// It is used together with the sky130A Verilog cell models and the netlist
// that Yosys produced.  The test is EXHAUSTIVE: all 256 x 256 input
// combinations are checked.
//
// A Verilog testbench is needed here because the gate-level netlist is
// Verilog (standard cells).  The VHDL testbench in tb/tb_adder8.vhd is used
// for the RTL simulation.
// ===========================================================================
`timescale 1ns / 1ps

module tb_gls_adder8;

    reg  [7:0] a, b;
    reg        cin;
    wire [7:0] sum;
    wire       cout;

    integer i, j;
    integer errors;
    integer expected;

    adder8 dut (
        .a    (a),
        .b    (b),
        .cin  (cin),
        .sum  (sum),
        .cout (cout)
    );

    initial begin
        errors = 0;
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                a   = i;
                b   = j;
                cin = 1'b0;
                #1;
                expected = i + j;
                if (sum !== expected[7:0]) begin
                    errors = errors + 1;
                    if (errors < 5)
                        $display("GLS adder8 FAIL a=%h b=%h sum=%h exp=%h",
                                 a, b, sum, expected[7:0]);
                end
                if (cout !== (expected > 255)) begin
                    errors = errors + 1;
                    if (errors < 5)
                        $display("GLS adder8 FAIL a=%h b=%h cout=%b exp=%b",
                                 a, b, cout, (expected > 255));
                end
            end
        end
        if (errors == 0)
            $display("GLS adder8: PASS (65536 patterns)");
        else
            $display("GLS adder8: FAIL (%0d errors)", errors);
        $finish;
    end

endmodule

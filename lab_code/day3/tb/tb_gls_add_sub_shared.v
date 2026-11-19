// ===========================================================================
// tb/tb_gls_add_sub_shared.v
// Gate-level simulation testbench for add_sub_shared.
//
// Exhaustive over all 256 x 256 input combinations, for both ADD and SUB.
// The signed-overflow expectation is the same rule as in the VHDL testbench:
//   ADD: ovf = (sign(a)=sign(b))   and (sign(res) /= sign(a))
//   SUB: ovf = (sign(a)=sign(~b))  and (sign(res) /= sign(a))
// ===========================================================================
`timescale 1ns / 1ps

module tb_gls_add_sub_shared;

    reg  [7:0] a, b;
    reg        op;
    wire [7:0] y;
    wire       ovf;

    integer i, j;
    integer errors;
    integer expected;
    integer sign_a, sign_b, sign_r, sign_bb;

    add_sub_shared dut (
        .a   (a),
        .b   (b),
        .op  (op),
        .y   (y),
        .ovf (ovf)
    );

    task check;
        input integer mode;   // 0 = ADD, 1 = SUB
        begin
            expected = (mode == 0) ? (a + b) : (a - b);
            #1;
            if (y !== expected[7:0]) begin
                errors = errors + 1;
                if (errors < 5)
                    $display("GLS add_sub_shared FAIL mode=%0d a=%h b=%h y=%h exp=%h",
                             mode, a, b, y, expected[7:0]);
            end
            sign_a  = (a >= 128);
            sign_b  = (b >= 128);
            sign_r  = (expected[7] == 1'b1);
            sign_bb = (mode == 0) ? sign_b : (sign_b ^ 1);
            if (ovf !== ((sign_a == sign_bb) && (sign_a != sign_r))) begin
                errors = errors + 1;
                if (errors < 5)
                    $display("GLS add_sub_shared FAIL ovf mode=%0d a=%h b=%h ovf=%b",
                             mode, a, b, ovf);
            end
        end
    endtask

    initial begin
        errors = 0;
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                a  = i;
                b  = j;
                op = 1'b0;
                check(0);
                op = 1'b1;
                check(1);
            end
        end
        if (errors == 0)
            $display("GLS add_sub_shared: PASS (131072 checks)");
        else
            $display("GLS add_sub_shared: FAIL (%0d errors)", errors);
        $finish;
    end

endmodule

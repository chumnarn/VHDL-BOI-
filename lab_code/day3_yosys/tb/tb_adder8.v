// tb_adder8.v
// Self-checking testbench for adder8 (combinational 8-bit adder)
// Lab 3B - Open-source synthesis with Yosys
//
// ไฟล์นี้ถูกใช้ซ้ำสองครั้ง:
//   make sim     -> compile กับ RTL      (rtl/adder8.v)
//   make sim-gls -> compile กับ netlist   (build/adder8_gates.v)
// ถ้าทั้งสองแบบผ่านเหมือนกัน แปลว่า netlist ที่ Yosys สร้างถูกต้อง
`timescale 1ns / 1ps

module tb_adder8;

    reg        cin;
    reg  [7:0] a;
    reg  [7:0] b;
    wire [7:0] sum;
    wire       cout;

    integer    i, j, k;
    integer    pass_cnt;
    integer    fail_cnt;
    reg  [8:0] expected;

    adder8 dut (
        .cin (cin),
        .a   (a),
        .b   (b),
        .sum (sum),
        .cout(cout)
    );

    initial begin
        pass_cnt = 0;
        fail_cnt = 0;
        cin = 1'b0;
        a   = 8'h00;
        b   = 8'h00;

        // ---- Exhaustive check: 2 x 256 x 256 = 131,072 patterns ----
        for (k = 0; k < 2; k = k + 1) begin
            cin = k[0];
            for (i = 0; i < 256; i = i + 1) begin
                a = i[7:0];
                for (j = 0; j < 256; j = j + 1) begin
                    b = j[7:0];
                    #1;
                    expected = {1'b0, i[7:0]} + {1'b0, j[7:0]} + k[0];
                    if ((sum !== expected[7:0]) || (cout !== expected[8])) begin
                        fail_cnt = fail_cnt + 1;
                        if (fail_cnt <= 5) begin
                            $display("FAIL a=%0d b=%0d cin=%0d | got sum=%b cout=%b | exp sum=%b cout=%b",
                                     i, j, k, sum, cout, expected[7:0], expected[8]);
                        end
                    end else begin
                        pass_cnt = pass_cnt + 1;
                    end
                end
            end
        end

        $display("tb_adder8 PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
        if (fail_cnt == 0)
            $display("tb_adder8: ALL 131072 PATTERNS PASS");
        else
            $display("tb_adder8: FAILED");
        $finish;
    end

endmodule

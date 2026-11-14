// tb_adder8_pipe.v
// Self-checking testbench for adder8_pipe (2-stage pipelined adder, latency = 1 clock)
// Lab 3B - Open-source synthesis with Yosys
//
// ใช้ไฟล์นี้ซ้ำสองครั้งเหมือน tb_adder8.v:
//   make sim     -> RTL      (rtl/adder8_pipe.v)
//   make sim-gls -> netlist  (build/adder8_pipe_gates.v)
`timescale 1ns / 1ps

module tb_adder8_pipe;

    reg        clk;
    reg        rst;
    reg        cin;
    reg  [7:0] a;
    reg  [7:0] b;
    wire [7:0] sum;
    wire       cout;

    integer    n;
    integer    pass_cnt;
    integer    fail_cnt;
    reg  [8:0] expected;
    reg  [7:0] exp_a;
    reg  [7:0] exp_b;
    reg        exp_cin;

    adder8_pipe dut (
        .clk (clk),
        .rst (rst),
        .cin (cin),
        .a   (a),
        .b   (b),
        .sum (sum),
        .cout(cout)
    );

    // 100 MHz
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        pass_cnt = 0;
        fail_cnt = 0;
        rst = 1'b1;
        a   = 8'h00;
        b   = 8'h00;
        cin = 1'b0;

        // ---- Reset ----
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        // ---- Latency-aware check ----
        // ใส่ข้อมูลที่ขอบ falling edge จะถูก stage 1 เก็บที่ posedge ถัดไป
        // และผลลัพธ์จะออกที่ posedge อีกครั้งหนึ่ง (latency = 1 clock)
        for (n = 0; n < 64; n = n + 1) begin
            @(negedge clk);
            exp_a   = (n * 37 + 11) & 8'hFF;
            exp_b   = (n * 91 + 7)  & 8'hFF;
            exp_cin = n[0];
            a   = exp_a;
            b   = exp_b;
            cin = exp_cin;
            expected = {1'b0, exp_a} + {1'b0, exp_b} + exp_cin;

            @(posedge clk);   // stage 1: register operands
            @(posedge clk);   // stage 2: compute + register result
            #1;

            if ((sum !== expected[7:0]) || (cout !== expected[8])) begin
                fail_cnt = fail_cnt + 1;
                if (fail_cnt <= 5) begin
                    $display("FAIL vec=%0d a=%0d b=%0d cin=%0d | got sum=%b cout=%b | exp sum=%b cout=%b",
                             n, exp_a, exp_b, exp_cin, sum, cout, expected[7:0], expected[8]);
                end
            end else begin
                pass_cnt = pass_cnt + 1;
            end
        end

        $display("tb_adder8_pipe PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
        if (fail_cnt == 0)
            $display("tb_adder8_pipe: ALL TESTS PASS");
        else
            $display("tb_adder8_pipe: FAILED");
        $finish;
    end

endmodule

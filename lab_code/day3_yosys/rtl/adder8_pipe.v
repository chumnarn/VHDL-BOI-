// adder8_pipe.v
// 8-bit adder แบบ 2-stage pipeline (latency = 1 clock) - Lab 3B
//
// ใช้เปรียบเทียบกับ adder8.v:
//   - combinational : พื้นที่น้อย แต่ critical path ยาว (ripple ผ่าน 8 stage)
//   - pipelined      : พื้นที่มากขึ้น (มี register) แต่ critical path สั้นลง
// Yosys จะรายงานความต่างของ cell count ทั้งสองแบบให้เห็นชัด
//
// Stage 1 : register operands (a, b, cin)
// Stage 2 : คำนวณผลรวมแล้ว register ผลลัพธ์

`timescale 1ns / 1ps

module adder8_pipe (
    input  wire       clk,
    input  wire       rst,
    input  wire       cin,
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum,
    output wire       cout
);
    // ---- Stage 1: register the operands -------------------------------
    reg [7:0] r1_a;
    reg [7:0] r1_b;
    reg       r1_cin;

    always @(posedge clk) begin
        if (rst) begin
            r1_a   <= 8'd0;
            r1_b   <= 8'd0;
            r1_cin <= 1'b0;
        end else begin
            r1_a   <= a;
            r1_b   <= b;
            r1_cin <= cin;
        end
    end

    // ---- Stage 2: compute and register the result ----------------------
    reg [8:0] r2;

    always @(posedge clk) begin
        if (rst) begin
            r2 <= 9'd0;
        end else begin
            r2 <= {1'b0, r1_a} + {1'b0, r1_b} + r1_cin;
        end
    end

    assign sum  = r2[7:0];
    assign cout = r2[8];
endmodule

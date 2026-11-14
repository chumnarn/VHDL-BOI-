// adder8.v
// 8-bit ripple-carry adder (combinational) - Lab 3B: Yosys / LibreLane
//
// ใช้เป็น DUT หลักของแล็บ:
//   1) RTL simulation ด้วย Icarus Verilog (ตรวจ function)
//   2) Yosys generic synthesis  -> ดูจำนวน cell
//   3) Yosys technology mapping -> ดูจำนวน gate
//   4) Gate-level simulation ของ netlist ที่ Yosys สร้าง
//
// หมายเหตุ: ไฟล์นี้เป็น Verilog โดยเฉพาะ เพราะ Yosys อ่าน Verilog ได้โดยตรง
// ส่วน VHDL ต้องผ่าน GHDL front-end ก่อน (ดู scripts/ghdl_to_verilog.sh)

`timescale 1ns / 1ps

module adder8 (
    input  wire       cin,
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum,
    output wire       cout
);
    // การต่อแบบ 9 บิตทำให้ carry ทะลุขึ้นมาที่ bit 8 โดยอัตโนมัติ
    assign {cout, sum} = {1'b0, a} + {1'b0, b} + cin;
endmodule

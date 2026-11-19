// tb_latch_bad.v — GLS testbench สำหรับ netlist ของ latch_bad (ที่สังเคราะห์จาก GHDL --latches)
// ผลที่คาดหวัง: FAIL — เพราะ Yosys ตีความ `always @(e)` เป็น combinational
// แล้วทิ้ง enable ไป ทำให้ netlist ทำงานผิด
`timescale 1ns/1ps

module tb_latch_bad;
  reg  d = 0;
  reg  e = 0;
  wire q;

  integer errors;

  latch_bad dut (.d(d), .e(e), .q(q));

  initial begin
    errors = 0;

    // เปิด latch แล้วใส่ค่า 1
    e = 1; d = 1; #1;
    if (q !== 1'b1) begin
      errors = errors + 1;
      $display("FAIL phase1: latch should follow d=1, got q=%b", q);
    end

    // ปิด latch แล้วเปลี่ยน d — latch ต้อง "คง" ค่าเดิม
    e = 0; d = 0; #1;
    if (q !== 1'b1) begin
      errors = errors + 1;
      $display("FAIL phase2: latch should HOLD 1 after e=0, got q=%b", q);
    end

    $display("GLS tb_latch_bad: errors = %0d", errors);
    if (errors == 0)
      $display("GLS RESULT: PASS");
    else
      $display("GLS RESULT: FAIL");
    $finish;
  end
endmodule

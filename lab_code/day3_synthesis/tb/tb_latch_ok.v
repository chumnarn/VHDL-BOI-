// tb_latch_ok.v — GLS testbench สำหรับ latch_ok.v (รูปแบบที่ Yosys infer ถูกต้อง)
// ผลที่คาดหวัง: PASS
`timescale 1ns/1ps

module tb_latch_ok;
  reg  d = 0;
  reg  e = 0;
  wire q;

  integer errors;

  latch_ok dut (.d(d), .e(e), .q(q));

  initial begin
    errors = 0;

    e = 1; d = 1; #1;
    if (q !== 1'b1) begin
      errors = errors + 1;
      $display("FAIL phase1: latch should follow d=1, got q=%b", q);
    end

    e = 0; d = 0; #1;
    if (q !== 1'b1) begin
      errors = errors + 1;
      $display("FAIL phase2: latch should HOLD 1 after e=0, got q=%b", q);
    end

    $display("GLS tb_latch_ok: errors = %0d", errors);
    if (errors == 0)
      $display("GLS RESULT: PASS");
    else
      $display("GLS RESULT: FAIL");
    $finish;
  end
endmodule

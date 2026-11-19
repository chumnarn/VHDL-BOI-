// latch_ok.v — รูปแบบ latch ที่ YOSYS เข้าใจถูกต้อง
//
// เทียบกับ build/latch_bad_latched.v ที่ GHDL --latches สร้างให้:
//   GHDL เขียน  always @(e) n5_q <= d;   → Yosys ตีความเป็น combinational → enable หาย
//   รูปแบบนี้    always @* if (e) q = d;  → Yosys infer $_DLATCH_ ได้ถูกต้อง
//
// ใช้ไฟล์นี้เมื่ออยากศึกษา/สาธิต latch ที่ map ลง PDK ได้จริง
module latch_ok (
  input  wire d,
  input  wire e,
  output reg  q
);
  always @* begin
    if (e) q = d;      // ไม่มี else -> เป็น latch (level-sensitive storage)
  end
endmodule

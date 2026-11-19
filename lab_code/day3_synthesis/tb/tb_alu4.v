// tb_alu4.v — Gate-Level Simulation testbench สำหรับ alu4
// ใช้ตรวจว่า netlist ที่สังเคราะห์แล้วทำงานเหมือน RTL ทุก input combination
`timescale 1ns/1ps

module tb_alu4;
  reg  [3:0] a;
  reg  [3:0] b;
  reg  [1:0] op;
  wire [3:0] y;
  wire       zero;

  integer errors;
  integer i, j, k;
  reg [3:0] exp_y;

  alu4 dut (.a(a), .b(b), .op(op), .y(y), .zero(zero));

  initial begin
    errors = 0;
    for (i = 0; i < 16; i = i + 1) begin
      for (j = 0; j < 16; j = j + 1) begin
        for (k = 0; k < 4; k = k + 1) begin
          a  = i[3:0];
          b  = j[3:0];
          op = k[1:0];
          #1;
          case (k)
            0:       exp_y = i[3:0] + j[3:0];
            1:       exp_y = i[3:0] - j[3:0];
            2:       exp_y = i[3:0] & j[3:0];
            default: exp_y = i[3:0] | j[3:0];
          endcase
          if (y !== exp_y) begin
            errors = errors + 1;
            $display("MISMATCH a=%h b=%h op=%b y=%h expected=%h", a, b, op, y, exp_y);
          end
          if (zero !== (exp_y == 4'd0)) begin
            errors = errors + 1;
            $display("ZERO MISMATCH a=%h b=%h op=%b zero=%b", a, b, op, zero);
          end
        end
      end
    end

    $display("GLS tb_alu4: checked %0d combinations, errors = %0d", 16*16*4, errors);
    if (errors == 0)
      $display("GLS RESULT: PASS");
    else
      $display("GLS RESULT: FAIL");
    $finish;
  end
endmodule

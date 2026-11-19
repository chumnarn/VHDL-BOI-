// tb_adder8.v — Gate-Level Simulation testbench สำหรับ adder8
`timescale 1ns/1ps

module tb_adder8;
  reg  [7:0] a;
  reg  [7:0] b;
  wire [8:0] sum;
  wire       cout;

  integer errors;
  integer i, j;
  reg [8:0] exp_sum;

  adder8 dut (.a(a), .b(b), .sum(sum), .cout(cout));

  initial begin
    errors = 0;
    for (i = 0; i < 256; i = i + 1) begin
      for (j = 0; j < 256; j = j + 1) begin
        a = i[7:0];
        b = j[7:0];
        #1;
        exp_sum = {1'b0, i[7:0]} + {1'b0, j[7:0]};
        if (sum !== exp_sum) begin
          errors = errors + 1;
          $display("MISMATCH a=%h b=%h sum=%h expected=%h", a, b, sum, exp_sum);
        end
        if (cout !== exp_sum[8]) begin
          errors = errors + 1;
          $display("COUT MISMATCH a=%h b=%h cout=%b expected=%b", a, b, cout, exp_sum[8]);
        end
      end
    end

    $display("GLS tb_adder8: checked %0d combinations, errors = %0d", 256*256, errors);
    if (errors == 0)
      $display("GLS RESULT: PASS");
    else
      $display("GLS RESULT: FAIL");
    $finish;
  end
endmodule

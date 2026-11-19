module alu4
  (input  [3:0] a,
   input  [3:0] b,
   input  [1:0] op,
   output [3:0] y,
   output zero);
  wire [3:0] n7_o;
  wire n9_o;
  wire [3:0] n10_o;
  wire n12_o;
  wire [3:0] n13_o;
  wire n15_o;
  wire [3:0] n16_o;
  wire [2:0] n17_o;
  reg [3:0] n18_o;
  wire n22_o;
  wire n23_o;
  assign y = n18_o; //(module output)
  assign zero = n23_o; //(module output)
  /* rtl/alu4.vhd:27:48  */
  assign n7_o = a + b;
  /* rtl/alu4.vhd:27:7  */
  assign n9_o = op == 2'b00;
  /* rtl/alu4.vhd:28:48  */
  assign n10_o = a - b;
  /* rtl/alu4.vhd:28:7  */
  assign n12_o = op == 2'b01;
  /* rtl/alu4.vhd:29:48  */
  assign n13_o = a & b;
  /* rtl/alu4.vhd:29:7  */
  assign n15_o = op == 2'b10;
  /* rtl/alu4.vhd:30:48  */
  assign n16_o = a | b;
  assign n17_o = {n15_o, n12_o, n9_o};
  /* rtl/alu4.vhd:26:5  */
  always @*
    case (n17_o)
      3'b100: n18_o = n13_o;
      3'b010: n18_o = n10_o;
      3'b001: n18_o = n7_o;
      default: n18_o = n16_o;
    endcase
  /* rtl/alu4.vhd:35:22  */
  assign n22_o = n18_o == 4'b0000;
  /* rtl/alu4.vhd:35:15  */
  assign n23_o = n22_o ? 1'b1 : 1'b0;
endmodule


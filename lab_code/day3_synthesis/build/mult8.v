module mult8
  (input  [7:0] a,
   input  [7:0] b,
   output [15:0] p);
  wire [15:0] n1_o;
  wire [15:0] n2_o;
  wire [15:0] n3_o;
  assign p = n3_o; //(module output)
  /* rtl/mult8.vhd:17:37  */
  assign n1_o = {8'b0, a};  //  uext
  /* rtl/mult8.vhd:17:37  */
  assign n2_o = {8'b0, b};  //  uext
  /* rtl/mult8.vhd:17:37  */
  assign n3_o = n1_o * n2_o; // umul
endmodule


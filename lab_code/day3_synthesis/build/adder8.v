module adder8
  (input  [7:0] a,
   input  [7:0] b,
   output [8:0] sum,
   output cout);
  wire [8:0] s;
  wire [8:0] n2_o;
  wire [8:0] n3_o;
  wire [8:0] n4_o;
  wire n5_o;
  assign sum = s; //(module output)
  assign cout = n5_o; //(module output)
  /* rtl/adder8.vhd:17:10  */
  assign s = n4_o; // (signal)
  /* rtl/adder8.vhd:19:8  */
  assign n2_o = {1'b0, a};  //  uext
  /* rtl/adder8.vhd:19:33  */
  assign n3_o = {1'b0, b};  //  uext
  /* rtl/adder8.vhd:19:31  */
  assign n4_o = n2_o + n3_o;
  /* rtl/adder8.vhd:22:12  */
  assign n5_o = s[8]; // extract
endmodule


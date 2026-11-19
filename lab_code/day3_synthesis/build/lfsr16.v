module lfsr16
  (input  clk,
   input  rst,
   input  load,
   input  [15:0] din,
   output [15:0] q);
  wire [15:0] s;
  wire [14:0] n4_o;
  wire n5_o;
  wire n6_o;
  wire n7_o;
  wire n8_o;
  wire n9_o;
  wire n10_o;
  wire n11_o;
  wire [15:0] n12_o;
  wire [15:0] n13_o;
  wire [15:0] n15_o;
  reg [15:0] n18_q;
  assign q = s; //(module output)
  /* rtl/lfsr16.vhd:17:10  */
  assign s = n18_q; // (signal)
  /* rtl/lfsr16.vhd:27:15  */
  assign n4_o = s[14:0]; // extract
  /* rtl/lfsr16.vhd:27:33  */
  assign n5_o = s[15]; // extract
  /* rtl/lfsr16.vhd:27:43  */
  assign n6_o = s[13]; // extract
  /* rtl/lfsr16.vhd:27:38  */
  assign n7_o = n5_o ^ n6_o;
  /* rtl/lfsr16.vhd:27:53  */
  assign n8_o = s[12]; // extract
  /* rtl/lfsr16.vhd:27:48  */
  assign n9_o = n7_o ^ n8_o;
  /* rtl/lfsr16.vhd:27:63  */
  assign n10_o = s[10]; // extract
  /* rtl/lfsr16.vhd:27:58  */
  assign n11_o = n9_o ^ n10_o;
  /* rtl/lfsr16.vhd:27:29  */
  assign n12_o = {n4_o, n11_o};
  /* rtl/lfsr16.vhd:24:7  */
  assign n13_o = load ? din : n12_o;
  /* rtl/lfsr16.vhd:22:7  */
  assign n15_o = rst ? 16'b0000000000000000 : n13_o;
  /* rtl/lfsr16.vhd:21:5  */
  always @(posedge clk)
    n18_q <= n15_o;
endmodule


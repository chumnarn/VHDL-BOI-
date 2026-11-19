module add_sub_shared
  (input  [7:0] a,
   input  [7:0] b,
   input  op,
   output [7:0] y,
   output ovf);
  wire [7:0] n6_o;
  wire [7:0] n7_o;
  wire [8:0] n8_o;
  wire [8:0] n9_o;
  wire [8:0] n10_o;
  wire [8:0] n12_o;
  wire [8:0] n13_o;
  wire [8:0] n14_o;
  wire [8:0] n15_o;
  wire [7:0] n16_o;
  wire n17_o;
  wire n18_o;
  wire n19_o;
  wire n20_o;
  wire n21_o;
  wire n22_o;
  wire n23_o;
  wire n26_o;
  assign y = n16_o; //(module output)
  assign ovf = n26_o; //(module output)
  /* rtl/add_sub_shared.vhd:34:19  */
  assign n6_o = ~b;
  /* rtl/add_sub_shared.vhd:33:9  */
  assign n7_o = op ? n6_o : b;
  /* rtl/add_sub_shared.vhd:39:15  */
  assign n8_o = {1'b0, a};  //  uext
  /* rtl/add_sub_shared.vhd:47:24  */
  assign n9_o = {1'b0, n7_o};  //  uext
  /* rtl/add_sub_shared.vhd:47:22  */
  assign n10_o = n8_o + n9_o;
  /* rtl/add_sub_shared.vhd:47:38  */
  assign n12_o = n10_o + 9'b000000001;
  /* rtl/add_sub_shared.vhd:49:24  */
  assign n13_o = {1'b0, n7_o};  //  uext
  /* rtl/add_sub_shared.vhd:49:22  */
  assign n14_o = n8_o + n13_o;
  /* rtl/add_sub_shared.vhd:46:9  */
  assign n15_o = op ? n12_o : n14_o;
  /* rtl/add_sub_shared.vhd:52:33  */
  assign n16_o = n15_o[7:0]; // extract
  /* rtl/add_sub_shared.vhd:59:15  */
  assign n17_o = n8_o[7]; // extract
  /* rtl/add_sub_shared.vhd:59:23  */
  assign n18_o = n7_o[7]; // extract
  /* rtl/add_sub_shared.vhd:59:19  */
  assign n19_o = n17_o == n18_o;
  /* rtl/add_sub_shared.vhd:59:35  */
  assign n20_o = n8_o[7]; // extract
  /* rtl/add_sub_shared.vhd:59:44  */
  assign n21_o = n15_o[7]; // extract
  /* rtl/add_sub_shared.vhd:59:39  */
  assign n22_o = n20_o != n21_o;
  /* rtl/add_sub_shared.vhd:59:28  */
  assign n23_o = n22_o & n19_o;
  /* rtl/add_sub_shared.vhd:59:9  */
  assign n26_o = n23_o ? 1'b1 : 1'b0;
endmodule


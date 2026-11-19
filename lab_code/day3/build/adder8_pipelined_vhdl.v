module adder8_pipelined
  (input  clk,
   input  rst,
   input  [7:0] a,
   input  [7:0] b,
   input  cin,
   output [7:0] sum,
   output cout);
  wire [7:0] r1_a;
  wire [7:0] r1_b;
  wire r1_cin;
  wire [7:0] n5_o;
  wire [7:0] n7_o;
  wire n9_o;
  wire [3:0] n19_o;
  wire [8:0] n20_o;
  wire [3:0] n21_o;
  wire [8:0] n22_o;
  wire [8:0] n23_o;
  wire [8:0] n25_o;
  wire [8:0] n26_o;
  wire [8:0] n27_o;
  wire [3:0] n28_o;
  wire [3:0] n29_o;
  wire [8:0] n30_o;
  wire [3:0] n31_o;
  wire [8:0] n32_o;
  wire n33_o;
  wire [8:0] n34_o;
  wire [8:0] n36_o;
  wire [8:0] n37_o;
  wire [8:0] n38_o;
  wire [3:0] n39_o;
  wire n40_o;
  wire [7:0] n41_o;
  wire [7:0] n43_o;
  wire n45_o;
  reg [7:0] n58_q;
  reg [7:0] n59_q;
  reg n60_q;
  reg [7:0] n61_q;
  reg n62_q;
  assign sum = n61_q; //(module output)
  assign cout = n62_q; //(module output)
  /* rtl/adder8_pipelined.vhd:25:12  */
  assign r1_a = n58_q; // (signal)
  /* rtl/adder8_pipelined.vhd:25:18  */
  assign r1_b = n59_q; // (signal)
  /* rtl/adder8_pipelined.vhd:26:12  */
  assign r1_cin = n60_q; // (signal)
  /* rtl/adder8_pipelined.vhd:32:13  */
  assign n5_o = rst ? 8'b00000000 : a;
  /* rtl/adder8_pipelined.vhd:32:13  */
  assign n7_o = rst ? 8'b00000000 : b;
  /* rtl/adder8_pipelined.vhd:32:13  */
  assign n9_o = rst ? 1'b0 : cin;
  /* rtl/adder8_pipelined.vhd:57:43  */
  assign n19_o = r1_a[3:0]; // extract
  /* rtl/adder8_pipelined.vhd:57:23  */
  assign n20_o = {5'b0, n19_o};  //  uext
  /* rtl/adder8_pipelined.vhd:58:43  */
  assign n21_o = r1_b[3:0]; // extract
  /* rtl/adder8_pipelined.vhd:58:23  */
  assign n22_o = {5'b0, n21_o};  //  uext
  /* rtl/adder8_pipelined.vhd:60:30  */
  assign n23_o = n20_o + n22_o;
  /* rtl/adder8_pipelined.vhd:60:35  */
  assign n25_o = n23_o + 9'b000000001;
  /* rtl/adder8_pipelined.vhd:62:30  */
  assign n26_o = n20_o + n22_o;
  /* rtl/adder8_pipelined.vhd:59:17  */
  assign n27_o = r1_cin ? n25_o : n26_o;
  /* rtl/adder8_pipelined.vhd:64:55  */
  assign n28_o = n27_o[3:0]; // extract
  /* rtl/adder8_pipelined.vhd:72:43  */
  assign n29_o = r1_a[7:4]; // extract
  /* rtl/adder8_pipelined.vhd:72:23  */
  assign n30_o = {5'b0, n29_o};  //  uext
  /* rtl/adder8_pipelined.vhd:73:43  */
  assign n31_o = r1_b[7:4]; // extract
  /* rtl/adder8_pipelined.vhd:73:23  */
  assign n32_o = {5'b0, n31_o};  //  uext
  /* rtl/adder8_pipelined.vhd:74:22  */
  assign n33_o = n27_o[4]; // extract
  /* rtl/adder8_pipelined.vhd:75:30  */
  assign n34_o = n30_o + n32_o;
  /* rtl/adder8_pipelined.vhd:75:35  */
  assign n36_o = n34_o + 9'b000000001;
  /* rtl/adder8_pipelined.vhd:77:30  */
  assign n37_o = n30_o + n32_o;
  /* rtl/adder8_pipelined.vhd:74:17  */
  assign n38_o = n33_o ? n36_o : n37_o;
  /* rtl/adder8_pipelined.vhd:79:55  */
  assign n39_o = n38_o[3:0]; // extract
  /* rtl/adder8_pipelined.vhd:80:27  */
  assign n40_o = n38_o[4]; // extract
  assign n41_o = {n39_o, n28_o};
  /* rtl/adder8_pipelined.vhd:49:13  */
  assign n43_o = rst ? 8'b00000000 : n41_o;
  /* rtl/adder8_pipelined.vhd:49:13  */
  assign n45_o = rst ? 1'b0 : n40_o;
  /* rtl/adder8_pipelined.vhd:31:9  */
  always @(posedge clk)
    n58_q <= n5_o;
  /* rtl/adder8_pipelined.vhd:31:9  */
  always @(posedge clk)
    n59_q <= n7_o;
  /* rtl/adder8_pipelined.vhd:31:9  */
  always @(posedge clk)
    n60_q <= n9_o;
  /* rtl/adder8_pipelined.vhd:48:9  */
  always @(posedge clk)
    n61_q <= n43_o;
  /* rtl/adder8_pipelined.vhd:48:9  */
  always @(posedge clk)
    n62_q <= n45_o;
endmodule


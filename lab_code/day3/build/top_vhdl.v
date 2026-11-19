module or_gate
  (input  a,
   input  b,
   output y);
  wire n192_o;
  assign y = n192_o; //(module output)
  /* rtl/full_adder_struct.vhd:41:12  */
  assign n192_o = a | b;
endmodule

module and_gate
  (input  a,
   input  b,
   output y);
  wire n190_o;
  assign y = n190_o; //(module output)
  /* rtl/full_adder_struct.vhd:29:12  */
  assign n190_o = a & b;
endmodule

module xor_gate
  (input  a,
   input  b,
   output y);
  wire n188_o;
  assign y = n188_o; //(module output)
  /* rtl/full_adder_struct.vhd:17:12  */
  assign n188_o = a ^ b;
endmodule

module full_adder_struct
  (input  a,
   input  b,
   input  cin,
   output sum,
   output cout);
  wire s1;
  wire s2;
  wire s3;
  wire u1_y;
  wire u2_y;
  wire u3_y;
  wire u4_y;
  wire u5_y;
  assign sum = u2_y; //(module output)
  assign cout = u5_y; //(module output)
  /* rtl/full_adder_struct.vhd:55:12  */
  assign s1 = u1_y; // (signal)
  /* rtl/full_adder_struct.vhd:55:16  */
  assign s2 = u3_y; // (signal)
  /* rtl/full_adder_struct.vhd:55:20  */
  assign s3 = u4_y; // (signal)
  /* rtl/full_adder_struct.vhd:57:5  */
  xor_gate u1 (
    .a(a),
    .b(b),
    .y(u1_y));
  /* rtl/full_adder_struct.vhd:59:5  */
  xor_gate u2 (
    .a(s1),
    .b(cin),
    .y(u2_y));
  /* rtl/full_adder_struct.vhd:60:5  */
  and_gate u3 (
    .a(a),
    .b(b),
    .y(u3_y));
  /* rtl/full_adder_struct.vhd:61:5  */
  and_gate u4 (
    .a(s1),
    .b(cin),
    .y(u4_y));
  /* rtl/full_adder_struct.vhd:62:5  */
  or_gate u5 (
    .a(s2),
    .b(s3),
    .y(u5_y));
endmodule

module add_sub_shared
  (input  [7:0] a,
   input  [7:0] b,
   input  op,
   output [7:0] y,
   output ovf);
  wire [7:0] n158_o;
  wire [7:0] n159_o;
  wire [8:0] n160_o;
  wire [8:0] n161_o;
  wire [8:0] n162_o;
  wire [8:0] n164_o;
  wire [8:0] n165_o;
  wire [8:0] n166_o;
  wire [8:0] n167_o;
  wire [7:0] n168_o;
  wire n169_o;
  wire n170_o;
  wire n171_o;
  wire n172_o;
  wire n173_o;
  wire n174_o;
  wire n175_o;
  wire n178_o;
  assign y = n168_o; //(module output)
  assign ovf = n178_o; //(module output)
  /* rtl/add_sub_shared.vhd:34:19  */
  assign n158_o = ~b;
  /* rtl/add_sub_shared.vhd:33:9  */
  assign n159_o = op ? n158_o : b;
  /* rtl/add_sub_shared.vhd:39:15  */
  assign n160_o = {1'b0, a};  //  uext
  /* rtl/add_sub_shared.vhd:47:24  */
  assign n161_o = {1'b0, n159_o};  //  uext
  /* rtl/add_sub_shared.vhd:47:22  */
  assign n162_o = n160_o + n161_o;
  /* rtl/add_sub_shared.vhd:47:38  */
  assign n164_o = n162_o + 9'b000000001;
  /* rtl/add_sub_shared.vhd:49:24  */
  assign n165_o = {1'b0, n159_o};  //  uext
  /* rtl/add_sub_shared.vhd:49:22  */
  assign n166_o = n160_o + n165_o;
  /* rtl/add_sub_shared.vhd:46:9  */
  assign n167_o = op ? n164_o : n166_o;
  /* rtl/add_sub_shared.vhd:52:33  */
  assign n168_o = n167_o[7:0]; // extract
  /* rtl/add_sub_shared.vhd:59:15  */
  assign n169_o = n160_o[7]; // extract
  /* rtl/add_sub_shared.vhd:59:23  */
  assign n170_o = n159_o[7]; // extract
  /* rtl/add_sub_shared.vhd:59:19  */
  assign n171_o = n169_o == n170_o;
  /* rtl/add_sub_shared.vhd:59:35  */
  assign n172_o = n160_o[7]; // extract
  /* rtl/add_sub_shared.vhd:59:44  */
  assign n173_o = n167_o[7]; // extract
  /* rtl/add_sub_shared.vhd:59:39  */
  assign n174_o = n172_o != n173_o;
  /* rtl/add_sub_shared.vhd:59:28  */
  assign n175_o = n174_o & n171_o;
  /* rtl/add_sub_shared.vhd:59:9  */
  assign n178_o = n175_o ? 1'b1 : 1'b0;
endmodule

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
  wire [7:0] n94_o;
  wire [7:0] n96_o;
  wire n98_o;
  wire [3:0] n108_o;
  wire [8:0] n109_o;
  wire [3:0] n110_o;
  wire [8:0] n111_o;
  wire [8:0] n112_o;
  wire [8:0] n114_o;
  wire [8:0] n115_o;
  wire [8:0] n116_o;
  wire [3:0] n117_o;
  wire [3:0] n118_o;
  wire [8:0] n119_o;
  wire [3:0] n120_o;
  wire [8:0] n121_o;
  wire n122_o;
  wire [8:0] n123_o;
  wire [8:0] n125_o;
  wire [8:0] n126_o;
  wire [8:0] n127_o;
  wire [3:0] n128_o;
  wire n129_o;
  wire [7:0] n130_o;
  wire [7:0] n132_o;
  wire n134_o;
  reg [7:0] n147_q;
  reg [7:0] n148_q;
  reg n149_q;
  reg [7:0] n150_q;
  reg n151_q;
  assign sum = n150_q; //(module output)
  assign cout = n151_q; //(module output)
  /* rtl/adder8_pipelined.vhd:25:12  */
  assign r1_a = n147_q; // (signal)
  /* rtl/adder8_pipelined.vhd:25:18  */
  assign r1_b = n148_q; // (signal)
  /* rtl/adder8_pipelined.vhd:26:12  */
  assign r1_cin = n149_q; // (signal)
  /* rtl/adder8_pipelined.vhd:32:13  */
  assign n94_o = rst ? 8'b00000000 : a;
  /* rtl/adder8_pipelined.vhd:32:13  */
  assign n96_o = rst ? 8'b00000000 : b;
  /* rtl/adder8_pipelined.vhd:32:13  */
  assign n98_o = rst ? 1'b0 : cin;
  /* rtl/adder8_pipelined.vhd:57:43  */
  assign n108_o = r1_a[3:0]; // extract
  /* rtl/adder8_pipelined.vhd:57:23  */
  assign n109_o = {5'b0, n108_o};  //  uext
  /* rtl/adder8_pipelined.vhd:58:43  */
  assign n110_o = r1_b[3:0]; // extract
  /* rtl/adder8_pipelined.vhd:58:23  */
  assign n111_o = {5'b0, n110_o};  //  uext
  /* rtl/adder8_pipelined.vhd:60:30  */
  assign n112_o = n109_o + n111_o;
  /* rtl/adder8_pipelined.vhd:60:35  */
  assign n114_o = n112_o + 9'b000000001;
  /* rtl/adder8_pipelined.vhd:62:30  */
  assign n115_o = n109_o + n111_o;
  /* rtl/adder8_pipelined.vhd:59:17  */
  assign n116_o = r1_cin ? n114_o : n115_o;
  /* rtl/adder8_pipelined.vhd:64:55  */
  assign n117_o = n116_o[3:0]; // extract
  /* rtl/adder8_pipelined.vhd:72:43  */
  assign n118_o = r1_a[7:4]; // extract
  /* rtl/adder8_pipelined.vhd:72:23  */
  assign n119_o = {5'b0, n118_o};  //  uext
  /* rtl/adder8_pipelined.vhd:73:43  */
  assign n120_o = r1_b[7:4]; // extract
  /* rtl/adder8_pipelined.vhd:73:23  */
  assign n121_o = {5'b0, n120_o};  //  uext
  /* rtl/adder8_pipelined.vhd:74:22  */
  assign n122_o = n116_o[4]; // extract
  /* rtl/adder8_pipelined.vhd:75:30  */
  assign n123_o = n119_o + n121_o;
  /* rtl/adder8_pipelined.vhd:75:35  */
  assign n125_o = n123_o + 9'b000000001;
  /* rtl/adder8_pipelined.vhd:77:30  */
  assign n126_o = n119_o + n121_o;
  /* rtl/adder8_pipelined.vhd:74:17  */
  assign n127_o = n122_o ? n125_o : n126_o;
  /* rtl/adder8_pipelined.vhd:79:55  */
  assign n128_o = n127_o[3:0]; // extract
  /* rtl/adder8_pipelined.vhd:80:27  */
  assign n129_o = n127_o[4]; // extract
  assign n130_o = {n128_o, n117_o};
  /* rtl/adder8_pipelined.vhd:49:13  */
  assign n132_o = rst ? 8'b00000000 : n130_o;
  /* rtl/adder8_pipelined.vhd:49:13  */
  assign n134_o = rst ? 1'b0 : n129_o;
  /* rtl/adder8_pipelined.vhd:31:9  */
  always @(posedge clk)
    n147_q <= n94_o;
  /* rtl/adder8_pipelined.vhd:31:9  */
  always @(posedge clk)
    n148_q <= n96_o;
  /* rtl/adder8_pipelined.vhd:31:9  */
  always @(posedge clk)
    n149_q <= n98_o;
  /* rtl/adder8_pipelined.vhd:48:9  */
  always @(posedge clk)
    n150_q <= n132_o;
  /* rtl/adder8_pipelined.vhd:48:9  */
  always @(posedge clk)
    n151_q <= n134_o;
endmodule

module adder8
  (input  [7:0] a,
   input  [7:0] b,
   input  cin,
   output [7:0] sum,
   output cout);
  wire [8:0] c;
  wire n14_o;
  wire n15_o;
  wire n16_o;
  wire gen_n1_u_n17;
  wire gen_n1_u_n18;
  wire gen_n1_u_sum;
  wire gen_n1_u_cout;
  wire n23_o;
  wire n24_o;
  wire n25_o;
  wire gen_n2_u_n26;
  wire gen_n2_u_n27;
  wire gen_n2_u_sum;
  wire gen_n2_u_cout;
  wire n32_o;
  wire n33_o;
  wire n34_o;
  wire gen_n3_u_n35;
  wire gen_n3_u_n36;
  wire gen_n3_u_sum;
  wire gen_n3_u_cout;
  wire n41_o;
  wire n42_o;
  wire n43_o;
  wire gen_n4_u_n44;
  wire gen_n4_u_n45;
  wire gen_n4_u_sum;
  wire gen_n4_u_cout;
  wire n50_o;
  wire n51_o;
  wire n52_o;
  wire gen_n5_u_n53;
  wire gen_n5_u_n54;
  wire gen_n5_u_sum;
  wire gen_n5_u_cout;
  wire n59_o;
  wire n60_o;
  wire n61_o;
  wire gen_n6_u_n62;
  wire gen_n6_u_n63;
  wire gen_n6_u_sum;
  wire gen_n6_u_cout;
  wire n68_o;
  wire n69_o;
  wire n70_o;
  wire gen_n7_u_n71;
  wire gen_n7_u_n72;
  wire gen_n7_u_sum;
  wire gen_n7_u_cout;
  wire n77_o;
  wire n78_o;
  wire n79_o;
  wire gen_n8_u_n80;
  wire gen_n8_u_n81;
  wire gen_n8_u_sum;
  wire gen_n8_u_cout;
  wire n86_o;
  wire [8:0] n87_o;
  wire [7:0] n88_o;
  assign sum = n88_o; //(module output)
  assign cout = n86_o; //(module output)
  /* rtl/adder8.vhd:25:12  */
  assign c = n87_o; // (signal)
  /* rtl/adder8.vhd:29:42  */
  assign n14_o = a[0]; // extract
  /* rtl/adder8.vhd:29:48  */
  assign n15_o = b[0]; // extract
  /* rtl/adder8.vhd:29:54  */
  assign n16_o = c[0]; // extract
  /* rtl/adder8.vhd:29:59  */
  assign gen_n1_u_n17 = gen_n1_u_sum; // (signal)
  /* rtl/adder8.vhd:29:67  */
  assign gen_n1_u_n18 = gen_n1_u_cout; // (signal)
  /* rtl/adder8.vhd:29:9  */
  full_adder_struct gen_n1_u (
    .a(n14_o),
    .b(n15_o),
    .cin(n16_o),
    .sum(gen_n1_u_sum),
    .cout(gen_n1_u_cout));
  /* rtl/adder8.vhd:29:42  */
  assign n23_o = a[1]; // extract
  /* rtl/adder8.vhd:29:48  */
  assign n24_o = b[1]; // extract
  /* rtl/adder8.vhd:29:54  */
  assign n25_o = c[1]; // extract
  /* rtl/adder8.vhd:29:59  */
  assign gen_n2_u_n26 = gen_n2_u_sum; // (signal)
  /* rtl/adder8.vhd:29:67  */
  assign gen_n2_u_n27 = gen_n2_u_cout; // (signal)
  /* rtl/adder8.vhd:29:9  */
  full_adder_struct gen_n2_u (
    .a(n23_o),
    .b(n24_o),
    .cin(n25_o),
    .sum(gen_n2_u_sum),
    .cout(gen_n2_u_cout));
  /* rtl/adder8.vhd:29:42  */
  assign n32_o = a[2]; // extract
  /* rtl/adder8.vhd:29:48  */
  assign n33_o = b[2]; // extract
  /* rtl/adder8.vhd:29:54  */
  assign n34_o = c[2]; // extract
  /* rtl/adder8.vhd:29:59  */
  assign gen_n3_u_n35 = gen_n3_u_sum; // (signal)
  /* rtl/adder8.vhd:29:67  */
  assign gen_n3_u_n36 = gen_n3_u_cout; // (signal)
  /* rtl/adder8.vhd:29:9  */
  full_adder_struct gen_n3_u (
    .a(n32_o),
    .b(n33_o),
    .cin(n34_o),
    .sum(gen_n3_u_sum),
    .cout(gen_n3_u_cout));
  /* rtl/adder8.vhd:29:42  */
  assign n41_o = a[3]; // extract
  /* rtl/adder8.vhd:29:48  */
  assign n42_o = b[3]; // extract
  /* rtl/adder8.vhd:29:54  */
  assign n43_o = c[3]; // extract
  /* rtl/adder8.vhd:29:59  */
  assign gen_n4_u_n44 = gen_n4_u_sum; // (signal)
  /* rtl/adder8.vhd:29:67  */
  assign gen_n4_u_n45 = gen_n4_u_cout; // (signal)
  /* rtl/adder8.vhd:29:9  */
  full_adder_struct gen_n4_u (
    .a(n41_o),
    .b(n42_o),
    .cin(n43_o),
    .sum(gen_n4_u_sum),
    .cout(gen_n4_u_cout));
  /* rtl/adder8.vhd:29:42  */
  assign n50_o = a[4]; // extract
  /* rtl/adder8.vhd:29:48  */
  assign n51_o = b[4]; // extract
  /* rtl/adder8.vhd:29:54  */
  assign n52_o = c[4]; // extract
  /* rtl/adder8.vhd:29:59  */
  assign gen_n5_u_n53 = gen_n5_u_sum; // (signal)
  /* rtl/adder8.vhd:29:67  */
  assign gen_n5_u_n54 = gen_n5_u_cout; // (signal)
  /* rtl/adder8.vhd:29:9  */
  full_adder_struct gen_n5_u (
    .a(n50_o),
    .b(n51_o),
    .cin(n52_o),
    .sum(gen_n5_u_sum),
    .cout(gen_n5_u_cout));
  /* rtl/adder8.vhd:29:42  */
  assign n59_o = a[5]; // extract
  /* rtl/adder8.vhd:29:48  */
  assign n60_o = b[5]; // extract
  /* rtl/adder8.vhd:29:54  */
  assign n61_o = c[5]; // extract
  /* rtl/adder8.vhd:29:59  */
  assign gen_n6_u_n62 = gen_n6_u_sum; // (signal)
  /* rtl/adder8.vhd:29:67  */
  assign gen_n6_u_n63 = gen_n6_u_cout; // (signal)
  /* rtl/adder8.vhd:29:9  */
  full_adder_struct gen_n6_u (
    .a(n59_o),
    .b(n60_o),
    .cin(n61_o),
    .sum(gen_n6_u_sum),
    .cout(gen_n6_u_cout));
  /* rtl/adder8.vhd:29:42  */
  assign n68_o = a[6]; // extract
  /* rtl/adder8.vhd:29:48  */
  assign n69_o = b[6]; // extract
  /* rtl/adder8.vhd:29:54  */
  assign n70_o = c[6]; // extract
  /* rtl/adder8.vhd:29:59  */
  assign gen_n7_u_n71 = gen_n7_u_sum; // (signal)
  /* rtl/adder8.vhd:29:67  */
  assign gen_n7_u_n72 = gen_n7_u_cout; // (signal)
  /* rtl/adder8.vhd:29:9  */
  full_adder_struct gen_n7_u (
    .a(n68_o),
    .b(n69_o),
    .cin(n70_o),
    .sum(gen_n7_u_sum),
    .cout(gen_n7_u_cout));
  /* rtl/adder8.vhd:29:42  */
  assign n77_o = a[7]; // extract
  /* rtl/adder8.vhd:29:48  */
  assign n78_o = b[7]; // extract
  /* rtl/adder8.vhd:29:54  */
  assign n79_o = c[7]; // extract
  /* rtl/adder8.vhd:29:59  */
  assign gen_n8_u_n80 = gen_n8_u_sum; // (signal)
  /* rtl/adder8.vhd:29:67  */
  assign gen_n8_u_n81 = gen_n8_u_cout; // (signal)
  /* rtl/adder8.vhd:29:9  */
  full_adder_struct gen_n8_u (
    .a(n77_o),
    .b(n78_o),
    .cin(n79_o),
    .sum(gen_n8_u_sum),
    .cout(gen_n8_u_cout));
  /* rtl/adder8.vhd:31:14  */
  assign n86_o = c[8]; // extract
  assign n87_o = {gen_n8_u_n81, gen_n7_u_n72, gen_n6_u_n63, gen_n5_u_n54, gen_n4_u_n45, gen_n3_u_n36, gen_n2_u_n27, gen_n1_u_n18, cin};
  assign n88_o = {gen_n8_u_n80, gen_n7_u_n71, gen_n6_u_n62, gen_n5_u_n53, gen_n4_u_n44, gen_n3_u_n35, gen_n2_u_n26, gen_n1_u_n17};
endmodule

module top
  (input  clk,
   input  rst,
   input  [7:0] a,
   input  [7:0] b,
   input  cin,
   input  op,
   output [7:0] sum,
   output cout,
   output [7:0] psum,
   output pcout,
   output [7:0] sy,
   output ovf);
  wire [7:0] u_adder_sum;
  wire u_adder_cout;
  wire [7:0] u_pipe_sum;
  wire u_pipe_cout;
  wire [7:0] u_addsub_y;
  wire u_addsub_ovf;
  assign sum = u_adder_sum; //(module output)
  assign cout = u_adder_cout; //(module output)
  assign psum = u_pipe_sum; //(module output)
  assign pcout = u_pipe_cout; //(module output)
  assign sy = u_addsub_y; //(module output)
  assign ovf = u_addsub_ovf; //(module output)
  /* rtl/top.vhd:34:5  */
  adder8 u_adder (
    .a(a),
    .b(b),
    .cin(cin),
    .sum(u_adder_sum),
    .cout(u_adder_cout));
  /* rtl/top.vhd:37:5  */
  adder8_pipelined u_pipe (
    .clk(clk),
    .rst(rst),
    .a(a),
    .b(b),
    .cin(cin),
    .sum(u_pipe_sum),
    .cout(u_pipe_cout));
  /* rtl/top.vhd:41:5  */
  add_sub_shared u_addsub (
    .a(a),
    .b(b),
    .op(op),
    .y(u_addsub_y),
    .ovf(u_addsub_ovf));
endmodule


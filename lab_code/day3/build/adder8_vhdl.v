module or_gate
  (input  a,
   input  b,
   output y);
  wire n89_o;
  assign y = n89_o; //(module output)
  /* rtl/full_adder_struct.vhd:41:12  */
  assign n89_o = a | b;
endmodule

module and_gate
  (input  a,
   input  b,
   output y);
  wire n87_o;
  assign y = n87_o; //(module output)
  /* rtl/full_adder_struct.vhd:29:12  */
  assign n87_o = a & b;
endmodule

module xor_gate
  (input  a,
   input  b,
   output y);
  wire n85_o;
  assign y = n85_o; //(module output)
  /* rtl/full_adder_struct.vhd:17:12  */
  assign n85_o = a ^ b;
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

module adder8
  (input  [7:0] a,
   input  [7:0] b,
   input  cin,
   output [7:0] sum,
   output cout);
  wire [8:0] c;
  wire n2_o;
  wire n3_o;
  wire n4_o;
  wire gen_n1_u_n5;
  wire gen_n1_u_n6;
  wire gen_n1_u_sum;
  wire gen_n1_u_cout;
  wire n11_o;
  wire n12_o;
  wire n13_o;
  wire gen_n2_u_n14;
  wire gen_n2_u_n15;
  wire gen_n2_u_sum;
  wire gen_n2_u_cout;
  wire n20_o;
  wire n21_o;
  wire n22_o;
  wire gen_n3_u_n23;
  wire gen_n3_u_n24;
  wire gen_n3_u_sum;
  wire gen_n3_u_cout;
  wire n29_o;
  wire n30_o;
  wire n31_o;
  wire gen_n4_u_n32;
  wire gen_n4_u_n33;
  wire gen_n4_u_sum;
  wire gen_n4_u_cout;
  wire n38_o;
  wire n39_o;
  wire n40_o;
  wire gen_n5_u_n41;
  wire gen_n5_u_n42;
  wire gen_n5_u_sum;
  wire gen_n5_u_cout;
  wire n47_o;
  wire n48_o;
  wire n49_o;
  wire gen_n6_u_n50;
  wire gen_n6_u_n51;
  wire gen_n6_u_sum;
  wire gen_n6_u_cout;
  wire n56_o;
  wire n57_o;
  wire n58_o;
  wire gen_n7_u_n59;
  wire gen_n7_u_n60;
  wire gen_n7_u_sum;
  wire gen_n7_u_cout;
  wire n65_o;
  wire n66_o;
  wire n67_o;
  wire gen_n8_u_n68;
  wire gen_n8_u_n69;
  wire gen_n8_u_sum;
  wire gen_n8_u_cout;
  wire n74_o;
  wire [8:0] n75_o;
  wire [7:0] n76_o;
  assign sum = n76_o; //(module output)
  assign cout = n74_o; //(module output)
  /* rtl/adder8.vhd:25:12  */
  assign c = n75_o; // (signal)
  /* rtl/adder8.vhd:29:42  */
  assign n2_o = a[0]; // extract
  /* rtl/adder8.vhd:29:48  */
  assign n3_o = b[0]; // extract
  /* rtl/adder8.vhd:29:54  */
  assign n4_o = c[0]; // extract
  /* rtl/adder8.vhd:29:59  */
  assign gen_n1_u_n5 = gen_n1_u_sum; // (signal)
  /* rtl/adder8.vhd:29:67  */
  assign gen_n1_u_n6 = gen_n1_u_cout; // (signal)
  /* rtl/adder8.vhd:29:9  */
  full_adder_struct gen_n1_u (
    .a(n2_o),
    .b(n3_o),
    .cin(n4_o),
    .sum(gen_n1_u_sum),
    .cout(gen_n1_u_cout));
  /* rtl/adder8.vhd:29:42  */
  assign n11_o = a[1]; // extract
  /* rtl/adder8.vhd:29:48  */
  assign n12_o = b[1]; // extract
  /* rtl/adder8.vhd:29:54  */
  assign n13_o = c[1]; // extract
  /* rtl/adder8.vhd:29:59  */
  assign gen_n2_u_n14 = gen_n2_u_sum; // (signal)
  /* rtl/adder8.vhd:29:67  */
  assign gen_n2_u_n15 = gen_n2_u_cout; // (signal)
  /* rtl/adder8.vhd:29:9  */
  full_adder_struct gen_n2_u (
    .a(n11_o),
    .b(n12_o),
    .cin(n13_o),
    .sum(gen_n2_u_sum),
    .cout(gen_n2_u_cout));
  /* rtl/adder8.vhd:29:42  */
  assign n20_o = a[2]; // extract
  /* rtl/adder8.vhd:29:48  */
  assign n21_o = b[2]; // extract
  /* rtl/adder8.vhd:29:54  */
  assign n22_o = c[2]; // extract
  /* rtl/adder8.vhd:29:59  */
  assign gen_n3_u_n23 = gen_n3_u_sum; // (signal)
  /* rtl/adder8.vhd:29:67  */
  assign gen_n3_u_n24 = gen_n3_u_cout; // (signal)
  /* rtl/adder8.vhd:29:9  */
  full_adder_struct gen_n3_u (
    .a(n20_o),
    .b(n21_o),
    .cin(n22_o),
    .sum(gen_n3_u_sum),
    .cout(gen_n3_u_cout));
  /* rtl/adder8.vhd:29:42  */
  assign n29_o = a[3]; // extract
  /* rtl/adder8.vhd:29:48  */
  assign n30_o = b[3]; // extract
  /* rtl/adder8.vhd:29:54  */
  assign n31_o = c[3]; // extract
  /* rtl/adder8.vhd:29:59  */
  assign gen_n4_u_n32 = gen_n4_u_sum; // (signal)
  /* rtl/adder8.vhd:29:67  */
  assign gen_n4_u_n33 = gen_n4_u_cout; // (signal)
  /* rtl/adder8.vhd:29:9  */
  full_adder_struct gen_n4_u (
    .a(n29_o),
    .b(n30_o),
    .cin(n31_o),
    .sum(gen_n4_u_sum),
    .cout(gen_n4_u_cout));
  /* rtl/adder8.vhd:29:42  */
  assign n38_o = a[4]; // extract
  /* rtl/adder8.vhd:29:48  */
  assign n39_o = b[4]; // extract
  /* rtl/adder8.vhd:29:54  */
  assign n40_o = c[4]; // extract
  /* rtl/adder8.vhd:29:59  */
  assign gen_n5_u_n41 = gen_n5_u_sum; // (signal)
  /* rtl/adder8.vhd:29:67  */
  assign gen_n5_u_n42 = gen_n5_u_cout; // (signal)
  /* rtl/adder8.vhd:29:9  */
  full_adder_struct gen_n5_u (
    .a(n38_o),
    .b(n39_o),
    .cin(n40_o),
    .sum(gen_n5_u_sum),
    .cout(gen_n5_u_cout));
  /* rtl/adder8.vhd:29:42  */
  assign n47_o = a[5]; // extract
  /* rtl/adder8.vhd:29:48  */
  assign n48_o = b[5]; // extract
  /* rtl/adder8.vhd:29:54  */
  assign n49_o = c[5]; // extract
  /* rtl/adder8.vhd:29:59  */
  assign gen_n6_u_n50 = gen_n6_u_sum; // (signal)
  /* rtl/adder8.vhd:29:67  */
  assign gen_n6_u_n51 = gen_n6_u_cout; // (signal)
  /* rtl/adder8.vhd:29:9  */
  full_adder_struct gen_n6_u (
    .a(n47_o),
    .b(n48_o),
    .cin(n49_o),
    .sum(gen_n6_u_sum),
    .cout(gen_n6_u_cout));
  /* rtl/adder8.vhd:29:42  */
  assign n56_o = a[6]; // extract
  /* rtl/adder8.vhd:29:48  */
  assign n57_o = b[6]; // extract
  /* rtl/adder8.vhd:29:54  */
  assign n58_o = c[6]; // extract
  /* rtl/adder8.vhd:29:59  */
  assign gen_n7_u_n59 = gen_n7_u_sum; // (signal)
  /* rtl/adder8.vhd:29:67  */
  assign gen_n7_u_n60 = gen_n7_u_cout; // (signal)
  /* rtl/adder8.vhd:29:9  */
  full_adder_struct gen_n7_u (
    .a(n56_o),
    .b(n57_o),
    .cin(n58_o),
    .sum(gen_n7_u_sum),
    .cout(gen_n7_u_cout));
  /* rtl/adder8.vhd:29:42  */
  assign n65_o = a[7]; // extract
  /* rtl/adder8.vhd:29:48  */
  assign n66_o = b[7]; // extract
  /* rtl/adder8.vhd:29:54  */
  assign n67_o = c[7]; // extract
  /* rtl/adder8.vhd:29:59  */
  assign gen_n8_u_n68 = gen_n8_u_sum; // (signal)
  /* rtl/adder8.vhd:29:67  */
  assign gen_n8_u_n69 = gen_n8_u_cout; // (signal)
  /* rtl/adder8.vhd:29:9  */
  full_adder_struct gen_n8_u (
    .a(n65_o),
    .b(n66_o),
    .cin(n67_o),
    .sum(gen_n8_u_sum),
    .cout(gen_n8_u_cout));
  /* rtl/adder8.vhd:31:14  */
  assign n74_o = c[8]; // extract
  assign n75_o = {gen_n8_u_n69, gen_n7_u_n60, gen_n6_u_n51, gen_n5_u_n42, gen_n4_u_n33, gen_n3_u_n24, gen_n2_u_n15, gen_n1_u_n6, cin};
  assign n76_o = {gen_n8_u_n68, gen_n7_u_n59, gen_n6_u_n50, gen_n5_u_n41, gen_n4_u_n32, gen_n3_u_n23, gen_n2_u_n14, gen_n1_u_n5};
endmodule


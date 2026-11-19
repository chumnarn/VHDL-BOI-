module shifter
  (input  [7:0] d,
   input  [2:0] shamt,
   input  left,
   output [7:0] y);
  wire n6_o;
  wire [6:0] n7_o;
  wire [7:0] n9_o;
  wire [7:0] n10_o;
  wire n12_o;
  wire [6:0] n13_o;
  wire [7:0] n15_o;
  wire [7:0] n16_o;
  wire n18_o;
  wire [6:0] n19_o;
  wire [7:0] n21_o;
  wire [7:0] n22_o;
  wire n24_o;
  wire [6:0] n25_o;
  wire [7:0] n27_o;
  wire [7:0] n28_o;
  wire n30_o;
  wire [6:0] n31_o;
  wire [7:0] n33_o;
  wire [7:0] n34_o;
  wire n36_o;
  wire [6:0] n37_o;
  wire [7:0] n39_o;
  wire [7:0] n40_o;
  wire n42_o;
  wire [6:0] n43_o;
  wire [7:0] n45_o;
  wire [7:0] n46_o;
  wire n48_o;
  wire [6:0] n49_o;
  wire [7:0] n51_o;
  wire [7:0] n52_o;
  wire n54_o;
  wire [6:0] n55_o;
  wire [7:0] n57_o;
  wire [7:0] n58_o;
  wire n60_o;
  wire [6:0] n61_o;
  wire [7:0] n63_o;
  wire [7:0] n64_o;
  wire n66_o;
  wire [6:0] n67_o;
  wire [7:0] n69_o;
  wire [7:0] n70_o;
  wire n72_o;
  wire [6:0] n73_o;
  wire [7:0] n75_o;
  wire [7:0] n76_o;
  wire n78_o;
  wire [6:0] n79_o;
  wire [7:0] n81_o;
  wire [7:0] n82_o;
  wire n84_o;
  wire [6:0] n85_o;
  wire [7:0] n87_o;
  wire [7:0] n88_o;
  wire n90_o;
  wire [6:0] n91_o;
  wire [7:0] n93_o;
  wire [7:0] n94_o;
  wire n96_o;
  wire [6:0] n97_o;
  wire [7:0] n99_o;
  wire [7:0] n100_o;
  wire [7:0] n101_o;
  assign y = n101_o; //(module output)
  /* rtl/shifter.vhd:26:26  */
  assign n6_o = $unsigned(shamt) > $unsigned(3'b000);
  /* rtl/shifter.vhd:27:19  */
  assign n7_o = d[6:0]; // extract
  /* rtl/shifter.vhd:27:32  */
  assign n9_o = {n7_o, 1'b0};
  /* rtl/shifter.vhd:26:9  */
  assign n10_o = n6_o ? n9_o : d;
  /* rtl/shifter.vhd:26:26  */
  assign n12_o = $unsigned(shamt) > $unsigned(3'b001);
  /* rtl/shifter.vhd:27:19  */
  assign n13_o = n10_o[6:0]; // extract
  /* rtl/shifter.vhd:27:32  */
  assign n15_o = {n13_o, 1'b0};
  /* rtl/shifter.vhd:26:9  */
  assign n16_o = n12_o ? n15_o : n10_o;
  /* rtl/shifter.vhd:26:26  */
  assign n18_o = $unsigned(shamt) > $unsigned(3'b010);
  /* rtl/shifter.vhd:27:19  */
  assign n19_o = n16_o[6:0]; // extract
  /* rtl/shifter.vhd:27:32  */
  assign n21_o = {n19_o, 1'b0};
  /* rtl/shifter.vhd:26:9  */
  assign n22_o = n18_o ? n21_o : n16_o;
  /* rtl/shifter.vhd:26:26  */
  assign n24_o = $unsigned(shamt) > $unsigned(3'b011);
  /* rtl/shifter.vhd:27:19  */
  assign n25_o = n22_o[6:0]; // extract
  /* rtl/shifter.vhd:27:32  */
  assign n27_o = {n25_o, 1'b0};
  /* rtl/shifter.vhd:26:9  */
  assign n28_o = n24_o ? n27_o : n22_o;
  /* rtl/shifter.vhd:26:26  */
  assign n30_o = $unsigned(shamt) > $unsigned(3'b100);
  /* rtl/shifter.vhd:27:19  */
  assign n31_o = n28_o[6:0]; // extract
  /* rtl/shifter.vhd:27:32  */
  assign n33_o = {n31_o, 1'b0};
  /* rtl/shifter.vhd:26:9  */
  assign n34_o = n30_o ? n33_o : n28_o;
  /* rtl/shifter.vhd:26:26  */
  assign n36_o = $unsigned(shamt) > $unsigned(3'b101);
  /* rtl/shifter.vhd:27:19  */
  assign n37_o = n34_o[6:0]; // extract
  /* rtl/shifter.vhd:27:32  */
  assign n39_o = {n37_o, 1'b0};
  /* rtl/shifter.vhd:26:9  */
  assign n40_o = n36_o ? n39_o : n34_o;
  /* rtl/shifter.vhd:26:26  */
  assign n42_o = $unsigned(shamt) > $unsigned(3'b110);
  /* rtl/shifter.vhd:27:19  */
  assign n43_o = n40_o[6:0]; // extract
  /* rtl/shifter.vhd:27:32  */
  assign n45_o = {n43_o, 1'b0};
  /* rtl/shifter.vhd:26:9  */
  assign n46_o = n42_o ? n45_o : n40_o;
  /* rtl/shifter.vhd:26:26  */
  assign n48_o = $unsigned(shamt) > $unsigned(3'b111);
  /* rtl/shifter.vhd:27:19  */
  assign n49_o = n46_o[6:0]; // extract
  /* rtl/shifter.vhd:27:32  */
  assign n51_o = {n49_o, 1'b0};
  /* rtl/shifter.vhd:26:9  */
  assign n52_o = n48_o ? n51_o : n46_o;
  /* rtl/shifter.vhd:32:26  */
  assign n54_o = $unsigned(shamt) > $unsigned(3'b000);
  /* rtl/shifter.vhd:33:25  */
  assign n55_o = d[7:1]; // extract
  /* rtl/shifter.vhd:33:21  */
  assign n57_o = {1'b0, n55_o};
  /* rtl/shifter.vhd:32:9  */
  assign n58_o = n54_o ? n57_o : d;
  /* rtl/shifter.vhd:32:26  */
  assign n60_o = $unsigned(shamt) > $unsigned(3'b001);
  /* rtl/shifter.vhd:33:25  */
  assign n61_o = n58_o[7:1]; // extract
  /* rtl/shifter.vhd:33:21  */
  assign n63_o = {1'b0, n61_o};
  /* rtl/shifter.vhd:32:9  */
  assign n64_o = n60_o ? n63_o : n58_o;
  /* rtl/shifter.vhd:32:26  */
  assign n66_o = $unsigned(shamt) > $unsigned(3'b010);
  /* rtl/shifter.vhd:33:25  */
  assign n67_o = n64_o[7:1]; // extract
  /* rtl/shifter.vhd:33:21  */
  assign n69_o = {1'b0, n67_o};
  /* rtl/shifter.vhd:32:9  */
  assign n70_o = n66_o ? n69_o : n64_o;
  /* rtl/shifter.vhd:32:26  */
  assign n72_o = $unsigned(shamt) > $unsigned(3'b011);
  /* rtl/shifter.vhd:33:25  */
  assign n73_o = n70_o[7:1]; // extract
  /* rtl/shifter.vhd:33:21  */
  assign n75_o = {1'b0, n73_o};
  /* rtl/shifter.vhd:32:9  */
  assign n76_o = n72_o ? n75_o : n70_o;
  /* rtl/shifter.vhd:32:26  */
  assign n78_o = $unsigned(shamt) > $unsigned(3'b100);
  /* rtl/shifter.vhd:33:25  */
  assign n79_o = n76_o[7:1]; // extract
  /* rtl/shifter.vhd:33:21  */
  assign n81_o = {1'b0, n79_o};
  /* rtl/shifter.vhd:32:9  */
  assign n82_o = n78_o ? n81_o : n76_o;
  /* rtl/shifter.vhd:32:26  */
  assign n84_o = $unsigned(shamt) > $unsigned(3'b101);
  /* rtl/shifter.vhd:33:25  */
  assign n85_o = n82_o[7:1]; // extract
  /* rtl/shifter.vhd:33:21  */
  assign n87_o = {1'b0, n85_o};
  /* rtl/shifter.vhd:32:9  */
  assign n88_o = n84_o ? n87_o : n82_o;
  /* rtl/shifter.vhd:32:26  */
  assign n90_o = $unsigned(shamt) > $unsigned(3'b110);
  /* rtl/shifter.vhd:33:25  */
  assign n91_o = n88_o[7:1]; // extract
  /* rtl/shifter.vhd:33:21  */
  assign n93_o = {1'b0, n91_o};
  /* rtl/shifter.vhd:32:9  */
  assign n94_o = n90_o ? n93_o : n88_o;
  /* rtl/shifter.vhd:32:26  */
  assign n96_o = $unsigned(shamt) > $unsigned(3'b111);
  /* rtl/shifter.vhd:33:25  */
  assign n97_o = n94_o[7:1]; // extract
  /* rtl/shifter.vhd:33:21  */
  assign n99_o = {1'b0, n97_o};
  /* rtl/shifter.vhd:32:9  */
  assign n100_o = n96_o ? n99_o : n94_o;
  /* rtl/shifter.vhd:24:5  */
  assign n101_o = left ? n52_o : n100_o;
endmodule


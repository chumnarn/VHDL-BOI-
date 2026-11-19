module fsm_seq
  (input  clk,
   input  rst,
   input  din,
   output [1:0] state);
  wire [1:0] cs;
  wire [1:0] ns;
  wire [1:0] n5_o;
  wire [1:0] n12_o;
  wire n14_o;
  wire n15_o;
  wire [1:0] n18_o;
  wire n20_o;
  wire n22_o;
  wire [2:0] n23_o;
  reg [1:0] n26_o;
  wire n30_o;
  wire n33_o;
  wire n36_o;
  wire [2:0] n37_o;
  reg [1:0] n39_o;
  reg [1:0] n40_q;
  assign state = n39_o; //(module output)
  /* rtl/fsm_seq.vhd:18:10  */
  assign cs = n40_q; // (signal)
  /* rtl/fsm_seq.vhd:18:14  */
  assign ns = n26_o; // (signal)
  /* rtl/fsm_seq.vhd:23:7  */
  assign n5_o = rst ? 2'b00 : ns;
  /* rtl/fsm_seq.vhd:35:9  */
  assign n12_o = din ? 2'b01 : 2'b00;
  /* rtl/fsm_seq.vhd:34:7  */
  assign n14_o = cs == 2'b00;
  /* rtl/fsm_seq.vhd:41:16  */
  assign n15_o = ~din;
  /* rtl/fsm_seq.vhd:41:9  */
  assign n18_o = n15_o ? 2'b10 : 2'b01;
  /* rtl/fsm_seq.vhd:40:7  */
  assign n20_o = cs == 2'b01;
  /* rtl/fsm_seq.vhd:46:7  */
  assign n22_o = cs == 2'b10;
  assign n23_o = {n22_o, n20_o, n14_o};
  /* rtl/fsm_seq.vhd:33:5  */
  always @*
    case (n23_o)
      3'b100: n26_o = 2'b00;
      3'b010: n26_o = n18_o;
      3'b001: n26_o = n12_o;
      default: n26_o = 2'bX;
    endcase
  /* rtl/fsm_seq.vhd:52:19  */
  assign n30_o = cs == 2'b00;
  /* rtl/fsm_seq.vhd:53:18  */
  assign n33_o = cs == 2'b01;
  /* rtl/fsm_seq.vhd:54:18  */
  assign n36_o = cs == 2'b10;
  assign n37_o = {n36_o, n33_o, n30_o};
  /* rtl/fsm_seq.vhd:51:3  */
  always @*
    case (n37_o)
      3'b100: n39_o = 2'b10;
      3'b010: n39_o = 2'b01;
      3'b001: n39_o = 2'b00;
      default: n39_o = 2'bX;
    endcase
  /* rtl/fsm_seq.vhd:22:5  */
  always @(posedge clk)
    n40_q <= n5_o;
endmodule


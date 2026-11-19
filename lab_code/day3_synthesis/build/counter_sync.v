module counter_sync
  (input  clk,
   input  rst,
   input  ce,
   output [7:0] cnt);
  wire [7:0] q;
  wire [7:0] n5_o;
  wire [7:0] n6_o;
  wire [7:0] n8_o;
  reg [7:0] n11_q;
  assign cnt = q; //(module output)
  /* rtl/counter_sync.vhd:17:10  */
  assign q = n11_q; // (signal)
  /* rtl/counter_sync.vhd:25:16  */
  assign n5_o = q + 8'b00000001;
  /* rtl/counter_sync.vhd:24:7  */
  assign n6_o = ce ? n5_o : q;
  /* rtl/counter_sync.vhd:22:7  */
  assign n8_o = rst ? 8'b00000000 : n6_o;
  /* rtl/counter_sync.vhd:21:5  */
  always @(posedge clk)
    n11_q <= n8_o;
endmodule


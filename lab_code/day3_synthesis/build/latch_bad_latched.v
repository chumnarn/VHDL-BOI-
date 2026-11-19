module latch_bad
  (input  d,
   input  e,
   output q);
  wire s;
  reg n5_q;
  assign q = s; //(module output)
  /* rtl/latch_bad.vhd:15:10  */
  assign s = n5_q; // (signal)
  /* rtl/latch_bad.vhd:17:3  */
  always @(e)
    n5_q <= d;
endmodule


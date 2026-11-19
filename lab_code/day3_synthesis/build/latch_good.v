module latch_good
  (input  d,
   input  e,
   output q);
  wire s;
  wire n4_o;
  assign q = s; //(module output)
  /* rtl/latch_good.vhd:15:10  */
  assign s = n4_o; // (signal)
  /* rtl/latch_good.vhd:19:5  */
  assign n4_o = e ? d : 1'b0;
endmodule


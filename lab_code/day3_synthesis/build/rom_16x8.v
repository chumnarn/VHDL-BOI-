module rom_16x8
  (input  [3:0] addr,
   output [7:0] dout);
  wire [30:0] n4_o;
  wire [3:0] n6_o;
  wire [3:0] n8_o;
  wire [7:0] n14_data; // mem_rd
  assign dout = n14_data; //(module output)
  /* rtl/rom_16x8.vhd:26:12  */
  assign n4_o = {27'b0, addr};  //  uext
  /* rtl/rom_16x8.vhd:27:17  */
  assign n6_o = n4_o[3:0];  // trunc
  /* rtl/rom_16x8.vhd:27:17  */
  assign n8_o = 4'b1111 - n6_o;
  /* rtl/rom_16x8.vhd:10:5  */
  reg [7:0] n13[15:0] ; // memory
  initial begin
    n13[15] = 8'b00000000;
    n13[14] = 8'b00000001;
    n13[13] = 8'b00000100;
    n13[12] = 8'b00001001;
    n13[11] = 8'b00010000;
    n13[10] = 8'b00011001;
    n13[9] = 8'b00100100;
    n13[8] = 8'b00110001;
    n13[7] = 8'b01000000;
    n13[6] = 8'b01010101;
    n13[5] = 8'b01101100;
    n13[4] = 8'b10000101;
    n13[3] = 8'b10100000;
    n13[2] = 8'b10111001;
    n13[1] = 8'b11010100;
    n13[0] = 8'b11111111;
    end
  assign n14_data = n13[n8_o];
  /* rtl/rom_16x8.vhd:27:17  */
endmodule


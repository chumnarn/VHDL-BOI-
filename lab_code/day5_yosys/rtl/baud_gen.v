// baud_gen.v
// Programmable baud rate generator (100 MHz clock, default divisor for 115200)
// divisor = CLK_FREQ / BAUD_RATE = 100e6 / 115200 = 868
//
// Verilog equivalent of lab_code/day5/baud_gen.vhd
`default_nettype none

module baud_gen #(
    parameter integer CLK_FREQ  = 100_000_000,  // 100 MHz
    parameter integer BAUD_RATE = 115_200
) (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    output reg  tick
);
    localparam integer DIVISOR = CLK_FREQ / BAUD_RATE;  // 868
    localparam integer LIMIT    = DIVISOR - 1;          // 867
    localparam integer CW       = $clog2(LIMIT + 1);   // 10 bits

    reg [CW-1:0] cnt;

    always @(posedge clk) begin
        if (rst) begin
            cnt  <= {CW{1'b0}};
            tick <= 1'b0;
        end else if (enable) begin
            if (cnt == LIMIT[CW-1:0]) begin
                cnt  <= {CW{1'b0}};
                tick <= 1'b1;
            end else begin
                cnt  <= cnt + 1'b1;
                tick <= 1'b0;
            end
        end else begin
            cnt  <= {CW{1'b0}};
            tick <= 1'b0;
        end
    end
endmodule

`default_nettype wire

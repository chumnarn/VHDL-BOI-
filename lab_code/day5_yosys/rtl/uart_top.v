// uart_top.v
// Top-level UART TX wrapper — top module สำหรับ full chip flow
//
// Verilog equivalent of lab_code/day5/uart_top.vhd
// โครงสร้างเหมือนกันทุกประการ: baud_gen (always running) -> uart_tx
`default_nettype none

module uart_top (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] din,
    input  wire       din_vld,
    output wire       din_rdy,
    output wire       tx
);
    wire baud_tick;

    baud_gen #(
        .CLK_FREQ  (100_000_000),
        .BAUD_RATE (115_200)
    ) u_baud (
        .clk    (clk),
        .rst    (rst),
        .enable (1'b1),          // always running
        .tick   (baud_tick)
    );

    uart_tx u_tx (
        .clk       (clk),
        .rst       (rst),
        .din       (din),
        .din_vld   (din_vld),
        .din_rdy   (din_rdy),
        .baud_tick (baud_tick),
        .tx        (tx)
    );
endmodule

`default_nettype wire

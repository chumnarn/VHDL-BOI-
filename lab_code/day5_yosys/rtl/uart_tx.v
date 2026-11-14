// uart_tx.v
// UART Transmitter, 8-N-1, programmable baud
//
// Verilog equivalent of lab_code/day5/uart_tx.vhd — FSM แบบ Moore-ish
// (state ถูกตัดสินใจจาก register) และมี handshake din_vld / din_rdy
`default_nettype none

module uart_tx (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] din,
    input  wire       din_vld,
    output reg        din_rdy,
    input  wire       baud_tick,
    output reg        tx
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] START = 2'd1;
    localparam [1:0] DATA  = 2'd2;
    localparam [1:0] STOP  = 2'd3;

    reg [1:0] state;
    reg [2:0] bit_idx;
    reg [7:0] shreg;

    always @(posedge clk) begin
        if (rst) begin
            state   <= IDLE;
            bit_idx <= 3'd0;
            shreg   <= 8'd0;
            tx      <= 1'b1;   // idle line = high
            din_rdy <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    tx      <= 1'b1;
                    din_rdy <= 1'b1;
                    if (din_vld) begin
                        shreg   <= din;
                        din_rdy <= 1'b0;
                        state   <= START;
                    end
                end

                START: begin
                    if (baud_tick) begin
                        tx      <= 1'b0;   // start bit
                        state   <= DATA;
                        bit_idx <= 3'd0;
                    end
                end

                DATA: begin
                    if (baud_tick) begin
                        tx <= shreg[bit_idx];
                        if (bit_idx == 3'd7) begin
                            state <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 3'd1;
                        end
                    end
                end

                STOP: begin
                    if (baud_tick) begin
                        tx      <= 1'b1;   // stop bit
                        state   <= IDLE;
                        bit_idx <= 3'd0;
                    end
                end

                default: begin
                    state   <= IDLE;
                    tx      <= 1'b1;
                    din_rdy <= 1'b1;
                end
            endcase
        end
    end
endmodule

`default_nettype wire

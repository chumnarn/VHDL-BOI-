// tb_uart_top.v
// Self-checking testbench for UART TX (Verilog / Icarus Verilog)
//
// เทียบเคียงกับ lab_code/day5/tb_uart_top.vhd — ใช้ testbench ไฟล์นี้กับ
// ทั้ง RTL และ netlist ที่ Yosys สร้าง เพื่อพิสูจน์ว่าการสังเคราะห์
// ไม่ทำให้ฟังก์ชันของ Mini Project เพี้ยน
//
// Sampling rule: one bit cell = BAUD_CYCLES clocks = 868 clocks.
// ทุกบิตถูก sample ที่ "กลาง cell" (ครึ่งหนึ่งของ bit period หลังเริ่ม cell)
// เพราะการ sample ที่ขอบ cell จะกำกวม — transmitter เปลี่ยน tx
// ใน clock edge เดียวกัน
`timescale 1ns / 1ps
`default_nettype none

module tb_uart_top;

    localparam integer CLK_FREQ_HZ = 100_000_000;
    localparam integer BAUD_RATE    = 115_200;
    localparam integer CLK_PERIOD_NS = 10;
    localparam integer BAUD_CYCLES  = CLK_FREQ_HZ / BAUD_RATE;  // 868
    localparam integer HALF_CYCLES  = BAUD_CYCLES / 2;          // 434

    reg        clk = 1'b0;
    reg        rst = 1'b0;
    reg  [7:0] din = 8'h00;
    reg        din_vld = 1'b0;
    wire       din_rdy;
    wire       tx;

    integer pass_cnt = 0;
    integer fail_cnt = 0;
    integer i;
    integer j;
    integer bit_i;

    uart_top dut (
        .clk     (clk),
        .rst     (rst),
        .din     (din),
        .din_vld (din_vld),
        .din_rdy (din_rdy),
        .tx      (tx)
    );

    always #(CLK_PERIOD_NS / 2) clk = ~clk;   // 100 MHz

    // รอ N clock edge แล้วหน่วง 1 ns เพื่อเลี่ยง race กับ DUT
    task wait_cycles;
        input integer n;
        begin
            for (i = 0; i < n; i = i + 1) @(posedge clk);
            #1;
        end
    endtask

    // ส่ง 1 byte แล้วตรวจเฟรม 10 บิตบนสาย tx ทั้งหมด
    task send_and_check;
        input [7:0] b;
        begin
            // 1. รอจน transmitter พร้อมรับ byte ใหม่
            i = 0;
            while ((din_rdy !== 1'b1) && (i < 4 * BAUD_CYCLES)) begin
                @(posedge clk);
                i = i + 1;
            end
            #1;
            if (din_rdy !== 1'b1) begin
                $display("ERROR: timeout waiting for din_rdy");
                fail_cnt = fail_cnt + 1;
            end

            // 2. ส่งข้อมูล + valid strobe (non-blocking เพื่อให้ DUT
            //    เห็นค่าที่ edge ถัดไป เหมือน semantics ของ VHDL)
            din     <= b;
            din_vld <= 1'b1;

            // 3. รอจน transmitter latch byte แล้ว
            i = 0;
            while ((din_rdy !== 1'b0) && (i < 4 * BAUD_CYCLES)) begin
                @(posedge clk);
                i = i + 1;
            end
            #1;
            din_vld <= 1'b0;

            // 4. ซิงก์กับ start bit (tx ตกลงมาเป็น 0)
            i = 0;
            while ((tx !== 1'b0) && (i < 4 * BAUD_CYCLES)) begin
                @(posedge clk);
                i = i + 1;
            end
            #1;
            if (tx !== 1'b0) begin
                $display("ERROR: start bit was never detected");
                fail_cnt = fail_cnt + 1;
            end

            // 5. sample ที่กลางของแต่ละ bit cell
            for (bit_i = 0; bit_i < 10; bit_i = bit_i + 1) begin
                if (bit_i == 0) begin
                    wait_cycles(HALF_CYCLES);   // ครึ่ง bit period จากจุดเริ่ม
                end else begin
                    wait_cycles(BAUD_CYCLES);   // เต็ม 1 bit period
                end

                if (bit_i == 0) begin
                    if (tx !== 1'b0) begin
                        $display("FAIL: start bit, got %b", tx);
                        fail_cnt = fail_cnt + 1;
                    end
                end else if (bit_i == 9) begin
                    if (tx !== 1'b1) begin
                        $display("FAIL: stop bit, got %b", tx);
                        fail_cnt = fail_cnt + 1;
                    end
                end else begin
                    if (tx !== b[bit_i - 1]) begin
                        $display("FAIL: data bit %0d, got %b exp %b",
                                 bit_i - 1, tx, b[bit_i - 1]);
                        fail_cnt = fail_cnt + 1;
                    end
                end
            end

            pass_cnt = pass_cnt + 1;
        end
    endtask

    initial begin
        $display("tb_uart_top: start (BAUD_CYCLES=%0d)", BAUD_CYCLES);

        rst = 1'b1;
        wait_cycles(5);
        rst = 1'b0;
        wait_cycles(20);

        // ชุด pattern เดียวกับ VHDL TB: 0x00, 0xFF, 0x55, 0xAA, 0x42, 0x3C
        send_and_check(8'h00);
        send_and_check(8'hFF);
        send_and_check(8'h55);
        send_and_check(8'hAA);
        send_and_check(8'h42);
        send_and_check(8'h3C);

        if (tx !== 1'b1) begin
            $display("FAIL: TX not idle between frames");
            fail_cnt = fail_cnt + 1;
        end

        $display("tb_uart_top PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
        if (fail_cnt == 0)
            $display("tb_uart_top: ALL PATTERN FRAMES VERIFIED");
        $finish;
    end
endmodule

`default_nettype wire

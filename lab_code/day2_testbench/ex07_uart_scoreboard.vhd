-- ex07_uart_scoreboard.vhd
-- ตัวอย่างประกอบหัวข้อ 2.7.9 — Protocol-driven stimulus + in-order scoreboard
--
-- วัตถุประสงค์: แสดง pattern ที่ใช้จริงในงาน Mini Project
--   1) stimulus process ที่พูด "ภาษาของ protocol" (din_vld / din_rdy handshake)
--   2) monitor process ที่ "ถอด" สัญญาณ serial กลับเป็น byte
--   3) scoreboard = queue ของค่าที่คาดหวัง เทียบแบบ in-order
--   4) ใช้ protected type เป็นช่องทางส่งข้อมูลระหว่าง 2 process
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.uart_sb_pkg.ALL;
use work.tb_support_pkg.ALL;

entity ex07_uart_scoreboard is
    generic (
        CLK_PERIOD_NS : integer := 10;   -- 100 MHz
        BIT_PERIOD_NS : integer := 100   -- baud tick ทุก 100 ns
    );
end entity ex07_uart_scoreboard;

architecture sim of ex07_uart_scoreboard is
    constant CLK_PERIOD : time := 10 ns;
    constant BIT_PERIOD : time := 100 ns;

    -- เฟรมทดสอบ: ค่า 0x00, 0xFF, 0x55, 0xAA, 0x3C
    type byte_array_t is array (natural range <>) of integer;
    constant TEST_BYTES : byte_array_t := (16#00#, 16#FF#, 16#55#, 16#AA#, 16#3C#);

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal din       : std_logic_vector(7 downto 0) := (others => '0');
    signal din_vld   : std_logic := '0';
    signal din_rdy   : std_logic;
    signal baud_tick : std_logic := '0';
    signal tx        : std_logic;

    shared variable sb : byte_queue_t;
begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.uart_tx
        port map (clk => clk, rst => rst, din => din, din_vld => din_vld,
                  din_rdy => din_rdy, baud_tick => baud_tick, tx => tx);

    ------------------------------------------------------------------
    -- baud tick generator: pulse กว้าง 1 คาบนาฬิกาทุก BIT_PERIOD
    -- ข้อควรระวัง: ถ้าสร้างเป็น square wave (toggle ทุกครึ่ง bit period)
    --              transmitter จะก้าวหลาย bit ใน 1 จังหวะ -> ข้อมูลเพี้ยน
    ------------------------------------------------------------------
    baud_gen : process
        variable div : integer := 0;
        constant TICKS_PER_BIT : integer := BIT_PERIOD_NS / CLK_PERIOD_NS;
    begin
        wait until rising_edge(clk);
        div := div + 1;
        if div >= TICKS_PER_BIT then
            div := 0;
            baud_tick <= '1';
        else
            baud_tick <= '0';
        end if;
    end process baud_gen;

    ------------------------------------------------------------------
    -- stimulus: เตรียมค่าคาดหวังทั้งหมดลง queue ก่อน แล้วค่อยส่งเฟรม
    -- (ถ้า push ทีละเฟรมตอนส่งจะเกิด race กับ monitor ที่ pop)
    ------------------------------------------------------------------
    stim : process
        variable b : integer;
    begin
        rst <= '1';
        din_vld <= '0';
        wait for 4 * CLK_PERIOD;
        rst <= '0';
        wait for 2 * CLK_PERIOD;

        for i in TEST_BYTES'range loop
            sb.push(TEST_BYTES(i));
        end loop;

        for i in TEST_BYTES'range loop
            b := TEST_BYTES(i);
            din <= std_logic_vector(to_unsigned(b, 8));
            din_vld <= '1';
            -- ข้อควรระวัง (พิสูจน์แล้วด้วย GHDL 5.0.1 และ ModelSim 2026.1):
            -- "wait until" จะไม่ทำงานทันทีแม้เงื่อนไขจะเป็นจริงอยู่แล้ว
            -- ต้องมี EVENT เกิดขึ้นบน signal ใน sensitivity list ก่อน
            -- ดังนั้น "wait until din_rdy = '1'" ตอนที่ din_rdy เป็น '1' อยู่แล้ว
            -- จะค้างจนกว่า din_rdy จะเปลี่ยนไปมา -> ต้องรอ din_rdy ตกลงเป็น '0'
            -- ซึ่งเป็นสัญญาณว่า DUT รับข้อมูลแล้ว
            wait until din_rdy = '0';
            din_vld <= '0';
            -- รอให้เฟรมจบ (start + 8 data + stop = 10 bit period)
            wait for 11 * BIT_PERIOD;
        end loop;
        wait;
    end process stim;

    ------------------------------------------------------------------
    -- monitor + scoreboard: ถอด serial กลับเป็น byte แล้วเทียบกับ queue
    ------------------------------------------------------------------
    monitor : process
        variable decoded : integer := 0;
        variable expected : integer;
        variable result   : check_result_t := EMPTY_RESULT;
    begin
        for i in TEST_BYTES'range loop
            -- รอจนเห็น start bit (tx ลงจาก '1' เป็น '0')
            wait until falling_edge(tx);
            wait for BIT_PERIOD / 2;         -- มาที่กลาง start bit

            decoded := 0;
            for b in 0 to 7 loop
                wait for BIT_PERIOD;         -- มาที่กลาง data bit ถัดไป
                -- UART ส่ง LSB-first: bit แรกคือน้ำหนัก 2^0
                if tx = '1' then
                    decoded := decoded + (2 ** b);
                end if;
            end loop;

            wait for BIT_PERIOD;             -- กลาง stop bit
            sb.pop(expected);
            if decoded = expected then
                result.passed := result.passed + 1;
            else
                result.failed := result.failed + 1;
                report "FRAME MISMATCH #" & integer'image(i) &
                       " decoded=" & integer'image(decoded) &
                       " expected=" & integer'image(expected)
                    severity error;
            end if;
        end loop;

        report "[S1] frames decoded = " & integer'image(result.passed + result.failed) &
               "  queue remaining = " & integer'image(sb.size);
        report_result("ex07_uart_scoreboard", result);
        std.env.stop;
    end process monitor;

end architecture sim;

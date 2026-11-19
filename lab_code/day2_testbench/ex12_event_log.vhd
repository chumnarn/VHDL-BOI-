-- ex12_event_log.vhd
-- ตัวอย่างประกอบหัวข้อ 2.7.14 — Event log แบบไม่พึ่ง simulator (poor man's waveform)
--
-- วัตถุประสงค์: แสดงวิธีบันทึก timeline ของ signal ลงไฟล์ข้อความ
--           ด้วย STD.TEXTIO จึงได้ log ที่อ่านได้ทุกเครื่องมือ
--           (ทั้ง GHDL และ Questa) ไม่ต้องพึ่ง VCD/FST
--
-- ข้อเปรียบเทียบ:
--   GHDL      : ghdl -r --std=08 ex12_event_log --vcd=wave.vcd
--   Questa    : vsim -c work.ex12_event_log -do "vcd file wave.vcd; log -r /*; run -all; quit -f"
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

entity ex12_event_log is
    generic (
        LOG_FILE : string := "reports/ex12_events.txt"
    );
end entity ex12_event_log;

architecture sim of ex12_event_log is
    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal ce  : std_logic := '0';
    -- initialize cnt ด้วย ไม่งั้น logger จะอ่านค่า 'U' ที่เวลา 0 แล้ว
    -- numeric_std ออก warning "metavalue detected"
    signal cnt : unsigned(7 downto 0) := (others => '0');
begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.counter8
        port map (clk => clk, rst => rst, ce => ce, cnt => cnt);

    ------------------------------------------------------------------
    -- event logger: บันทึกทุกครั้งที่ cnt เปลี่ยน
    ------------------------------------------------------------------
    logger : process (cnt)
        file    logf  : text open write_mode is LOG_FILE;
        variable l    : line;
    begin
        write(l, string'("time_ns"));
        write(l, string'("  count"));
        writeline(logf, l);
        write(l, string'("----------------------"));
        writeline(logf, l);

        write(l, integer'image(integer(now / 1 ns)));
        write(l, string'("  "));
        write(l, to_integer(cnt));
        writeline(logf, l);
    end process logger;

    ------------------------------------------------------------------
    -- stimulus
    ------------------------------------------------------------------
    stim : process
    begin
        wait for 2 * CLK_PERIOD;
        rst <= '0';
        for i in 1 to 6 loop
            ce <= '1' when (i mod 2) = 0 else '0';
            wait until rising_edge(clk);
            wait for 1 ns;
        end loop;
        report "[L1] event log written to " & LOG_FILE;
        report "[L2] final count = " & integer'image(to_integer(cnt));
        std.env.stop;
    end process stim;
end architecture sim;

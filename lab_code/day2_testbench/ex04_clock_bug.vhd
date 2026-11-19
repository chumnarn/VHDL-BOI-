-- ex04_clock_bug.vhd
-- ตัวอย่างประกอบหัวข้อ 2.7.6 — บั๊ก "นาฬิกาไม่เคยตี"
--
-- นี่คือ BUG ที่พบในตัวอย่าง §2.5.2 ของคู่มือหลัก (Manual_Part1_Day1-5.md)
--   signal clk : std_logic;          -- ไม่มี initial value => 'U'
--   clk <= not clk after T / 2;      -- not 'U' = 'U' => ค่าไม่เปลี่ยน => ไม่มี edge
--
-- ผลลัพธ์ที่ต้องเห็น: จำนวน rising edge = 0, FSM ค้างที่ reset
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ex04_clock_bug is
end entity ex04_clock_bug;

architecture sim of ex04_clock_bug is
    constant CLK_PERIOD : time := 10 ns;
    constant RUN_TIME   : time := 200 ns;

    -- บั๊ก: ไม่ใส่ := '0'  --> เริ่มเป็น 'U'
    signal clk : std_logic;
    signal rst : std_logic := '1';
    signal din : std_logic := '0';
    signal detected : std_logic;
    signal edge_count : integer := 0;
begin

    -- บั๊ก: ไม่มี initial value
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.seq_det_moore
        port map (clk => clk, rst => rst, din => din, detected => detected);

    edge_counter : process (clk)
    begin
        if rising_edge(clk) then
            edge_count <= edge_count + 1;
        end if;
    end process edge_counter;

    stim : process
    begin
        rst <= '1';
        wait for 50 ns;
        rst <= '0';
        for i in 1 to 10 loop
            din <= '1';
            wait for CLK_PERIOD;
        end loop;
        wait;
    end process stim;

    finisher : process
    begin
        wait for RUN_TIME;
        report "[BAD] rising edges actually seen = " & integer'image(edge_count);
        report "[BAD] current clk value        = " & std_logic'image(clk);
        report "[BAD] current detected value   = " & std_logic'image(detected);
        report "[BAD] -> the clock never ticked; the DUT stayed in reset";
        std.env.stop;
    end process finisher;

end architecture sim;

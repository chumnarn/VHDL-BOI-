-- ex04_clock_fixed.vhd
-- ตัวอย่างประกอบหัวข้อ 2.7.6 — เวอร์ชันที่แก้แล้ว
--
-- แก้ 2 จุด:
--   1) signal clk : std_logic := '0';   -- ต้องมี initial value
--   2) clk เปลี่ยนค่าจริงทุกครึ่งคาบ => concurrent assignment ถูก trigger ใหม่
--      และสลับไปมาได้เรื่อย ๆ (not clk สลับระหว่าง '0'/'1' เสมอ)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ex04_clock_fixed is
end entity ex04_clock_fixed;

architecture sim of ex04_clock_fixed is
    constant CLK_PERIOD : time := 10 ns;
    constant RUN_TIME   : time := 200 ns;

    -- แก้แล้ว: มี initial value
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal din : std_logic := '0';
    signal detected : std_logic;
    signal edge_count : integer := 0;
begin

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
        report "[GOOD] rising edges actually seen = " & integer'image(edge_count);
        report "[GOOD] current clk value        = " & std_logic'image(clk);
        report "[GOOD] current detected value   = " & std_logic'image(detected);
        report "[GOOD] -> the clock ticks and the FSM runs";
        std.env.stop;
    end process finisher;

end architecture sim;

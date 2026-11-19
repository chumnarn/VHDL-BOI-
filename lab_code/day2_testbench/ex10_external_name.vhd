-- ex10_external_name.vhd
-- ตัวอย่างประกอบหัวข้อ 2.7.12 — External name (VHDL-2008) เข้าถึง signal ภายใน DUT
--
-- วัตถุประสงค์: แสดงวิธีดู "สัญญาณภายใน" ของ DUT โดยไม่ต้องแก้ RTL
--
-- ข้อจำกัดที่พบจริง (ทดสอบทั้ง GHDL 5.0.1 และ ModelSim 2026.1):
--   1) signal ที่จะอ้างถึงต้องประกาศที่ architecture/block level
--      ถ้าประกาศภายใน process จะถูกปฏิเสธว่า
--      "External reference to or into a VHDL process is not allowed"
--   2) path เริ่มต้นด้วยชื่อ entity ระดับบนสุด ไม่ใช่ชื่อ instance ของ TB
--   3) ต้องใช้ --std=08 (หรือ -2008 ใน Questa)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ex10_counter is
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        cnt : out std_logic_vector(7 downto 0)
    );
end entity ex10_counter;

architecture rtl of ex10_counter is
    -- signal ภายในที่ประกาศระดับ architecture (ต้องเป็นแบบนี้ถึงจะอ้างถึงได้)
    -- ใช้ unsigned เพราะ numeric_std ไม่รองรับ + บน std_logic_vector
    signal cnt_i : unsigned(7 downto 0) := (others => '0');
begin
    p : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                cnt_i <= (others => '0');
            else
                cnt_i <= cnt_i + 1;
            end if;
        end if;
    end process;
    cnt <= std_logic_vector(cnt_i);
end architecture rtl;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ex10_external_name is
end entity ex10_external_name;

architecture sim of ex10_external_name is
    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal cnt : std_logic_vector(7 downto 0);
begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.ex10_counter
        port map (clk => clk, rst => rst, cnt => cnt);

    probe : process
        -- external name: ชี้เข้าไปที่ signal ภายในของ DUT
        alias dut_cnt is << signal .ex10_external_name.dut.cnt_i : unsigned(7 downto 0) >>;
    begin
        wait for 2 * CLK_PERIOD;
        rst <= '0';

        wait for 5 * CLK_PERIOD;
        report "[X1] output port cnt = " & integer'image(to_integer(unsigned(cnt)));
        report "[X2] internal cnt_i  = " & integer'image(to_integer(dut_cnt));
        report "[X3] both must be equal (external name reaches inside the DUT)";
        std.env.stop;
        wait;
    end process probe;
end architecture sim;

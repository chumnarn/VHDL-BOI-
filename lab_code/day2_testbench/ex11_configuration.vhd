-- ex11_configuration.vhd
-- ตัวอย่างประกอบหัวข้อ 2.7.13 — Configuration declaration (สลับ DUT โดยไม่ recompile)
--
-- วัตถุประสงค์: แสดงว่า configuration ใช้เลือก architecture ของ DUT ได้
--           โดยไม่ต้องแก้ testbench และไม่ต้อง compile ใหม่
--
-- การใช้งาน (GHDL):
--   ghdl -e --std=08 cfg_using_rtl     # elaborate ผ่าน configuration
--   ghdl -r --std=08 cfg_using_rtl
--   ghdl -e --std=08 cfg_using_alt
--   ghdl -r --std=08 cfg_using_alt
--
-- ข้อสังเกต: ใน flow จริง (เช่น LibreLane/Questa) มักใช้ bind และ generic
--             มากกว่า แต่ configuration ยังเป็นคำสั่งมาตรฐานที่ควรรู้
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ex11_counter is
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        cnt : out std_logic_vector(7 downto 0)
    );
end entity ex11_counter;

-- architecture แบบที่ 1: นับขึ้นทีละ 1
architecture rtl of ex11_counter is
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

-- architecture แบบที่ 2: นับขึ้นทีละ 2 (ใช้ในการทดสอบ configuration)
architecture alt of ex11_counter is
    signal cnt_i : unsigned(7 downto 0) := (others => '0');
begin
    p : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                cnt_i <= (others => '0');
            else
                cnt_i <= cnt_i + 2;
            end if;
        end if;
    end process;
    cnt <= std_logic_vector(cnt_i);
end architecture alt;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ex11_configuration is
end entity ex11_configuration;

architecture sim of ex11_configuration is
    constant CLK_PERIOD : time := 10 ns;

    -- ต้องประกาศ component ไว้ เพื่อให้ configuration จับคู่ architecture
    -- ของ DUT ได้ (ถ้าใช้ direct entity instantiation จะไม่มีชื่อ component
    -- ให้ configuration อ้างถึง)
    component ex11_counter
        port (
            clk : in  std_logic;
            rst : in  std_logic;
            cnt : out std_logic_vector(7 downto 0)
        );
    end component;

    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal cnt : std_logic_vector(7 downto 0);
begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : ex11_counter
        port map (clk => clk, rst => rst, cnt => cnt);

    stim : process
    begin
        wait for 2 * CLK_PERIOD;
        rst <= '0';
        wait for 5 * CLK_PERIOD;
        report "[C1] counter value after 5 clocks = " &
               integer'image(to_integer(unsigned(cnt)));
        report "[C2] rtl architecture gives 5, alt architecture gives 10";
        std.env.stop;
        wait;
    end process stim;
end architecture sim;

-- ---------------------------------------------------------------------
-- configuration: เลือก architecture ของ DUT
-- ---------------------------------------------------------------------
configuration cfg_using_rtl of ex11_configuration is
    for sim
        for dut : ex11_counter use entity work.ex11_counter(rtl);
        end for;
    end for;
end configuration cfg_using_rtl;

configuration cfg_using_alt of ex11_configuration is
    for sim
        for dut : ex11_counter use entity work.ex11_counter(alt);
        end for;
    end for;
end configuration cfg_using_alt;

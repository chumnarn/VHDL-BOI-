-- counter8.vhd
-- ตัวนับ 8-bit แบบ synchronous reset + clock enable (สำเนาเฉพาะ day2_testbench)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter8 is
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        ce  : in  std_logic;
        cnt : out unsigned(7 downto 0)
    );
end entity counter8;

architecture rtl of counter8 is
    signal cnt_i : unsigned(7 downto 0) := (others => '0');
begin
    sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                cnt_i <= (others => '0');
            elsif ce = '1' then
                cnt_i <= cnt_i + 1;
            end if;
        end if;
    end process;

    cnt <= cnt_i;
end architecture rtl;

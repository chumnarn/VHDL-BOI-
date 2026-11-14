-- counter8.vhd
-- 8-bit synchronous counter with synchronous reset and clock enable
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.my_types_pkg.ALL;

entity counter8 is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        ce    : in  std_logic;
        load  : in  std_logic;
        din   : in  unsigned(COUNTER_WIDTH-1 downto 0);
        cnt   : out unsigned(COUNTER_WIDTH-1 downto 0);
        ovf   : out std_logic
    );
end entity counter8;

architecture rtl of counter8 is
    signal cnt_i : unsigned(COUNTER_WIDTH-1 downto 0);
begin
    sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                cnt_i <= (others => '0');
            elsif load = '1' then
                cnt_i <= din;
            elsif ce = '1' then
                cnt_i <= cnt_i + 1;
            end if;
        end if;
    end process;

    cnt <= cnt_i;
    ovf <= '1' when cnt_i = (cnt_i'range => '1') else '0';  -- wrap-around detect (max)
end architecture rtl;
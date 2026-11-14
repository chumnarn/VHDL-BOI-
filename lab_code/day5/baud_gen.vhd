-- baud_gen.vhd
-- Programmable baud rate generator (100 MHz clock, default divisor for 115200)
-- divisor = CLK_FREQ / baud_rate, e.g. 100e6 / 115200 = 868
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity baud_gen is
    generic (
        CLK_FREQ : integer := 100_000_000;     -- 100 MHz
        BAUD_RATE : integer := 115_200
    );
    port (
        clk    : in  std_logic;
        rst    : in  std_logic;
        enable : in  std_logic;
        tick   : out std_logic
    );
end entity baud_gen;

architecture rtl of baud_gen is
    constant DIVISOR : integer     := CLK_FREQ / BAUD_RATE;
    constant LIMIT    : integer     := DIVISOR - 1;
    signal   cnt      : integer range 0 to LIMIT;
begin
    sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                cnt  <= 0;
                tick <= '0';
            else
                if enable = '1' then
                    if cnt = LIMIT then
                        cnt  <= 0;
                        tick <= '1';
                    else
                        cnt  <= cnt + 1;
                        tick <= '0';
                    end if;
                else
                    cnt  <= 0;
                    tick <= '0';
                end if;
            end if;
        end if;
    end process;
end architecture rtl;
-- mux2x1.vhd
-- 2-to-1 MUX - Behavioral style with default assignment (no latch)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux2x1 is
    port (
        a, b : in  std_logic;
        sel  : in  std_logic;
        y    : out std_logic
    );
end entity mux2x1;

architecture rtl of mux2x1 is
begin
    process (a, b, sel)
    begin
        case sel is
            when '0' => y <= a;
            when '1' => y <= b;
            when others => y <= 'X';
        end case;
    end process;
end architecture rtl;
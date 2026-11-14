-- mux4x1_behavioral.vhd
-- 4-to-1 MUX - Behavioral style using process
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux4x1_behavioral is
    port (
        d0, d1, d2, d3 : in  std_logic;
        sel             : in  std_logic_vector(1 downto 0);
        y               : out std_logic
    );
end entity mux4x1_behavioral;

architecture behavioral of mux4x1_behavioral is
begin
    process (d0, d1, d2, d3, sel)
    begin
        case sel is
            when "00"   => y <= d0;
            when "01"   => y <= d1;
            when "10"   => y <= d2;
            when "11"   => y <= d3;
            when others => y <= 'X';
        end case;
    end process;
end architecture behavioral;
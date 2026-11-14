-- dec2x4.vhd
-- 2-to-4 Decoder with active-low enable and active-high outputs
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity dec2x4 is
    port (
        en : in  std_logic;
        a  : in  std_logic_vector(1 downto 0);
        y  : out std_logic_vector(3 downto 0)
    );
end entity dec2x4;

architecture rtl of dec2x4 is
begin
    process (en, a)
    begin
        y <= (others => '0');
        if en = '1' then
            case a is
                when "00"   => y <= "0001";
                when "01"   => y <= "0010";
                when "10"   => y <= "0100";
                when "11"   => y <= "1000";
                when others => y <= (others => '0');
            end case;
        end if;
    end process;
end architecture rtl;
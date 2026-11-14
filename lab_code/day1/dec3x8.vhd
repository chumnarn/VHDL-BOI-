-- dec3x8.vhd
-- 3-to-8 Decoder with active-high enable
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity dec3x8 is
    port (
        en : in  std_logic;
        a  : in  std_logic_vector(2 downto 0);
        y  : out std_logic_vector(7 downto 0)
    );
end entity dec3x8;

architecture rtl of dec3x8 is
begin
    process (en, a)
    begin
        y <= (others => '0');
        if en = '1' then
            case a is
                when "000" => y <= "00000001";
                when "001" => y <= "00000010";
                when "010" => y <= "00000100";
                when "011" => y <= "00001000";
                when "100" => y <= "00010000";
                when "101" => y <= "00100000";
                when "110" => y <= "01000000";
                when "111" => y <= "10000000";
                when others => y <= (others => '0');
            end case;
        end if;
    end process;
end architecture rtl;
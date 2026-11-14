-- tb_dec3x8.vhd
-- Testbench for 3-to-8 decoder
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_dec3x8 is
end entity tb_dec3x8;

architecture sim of tb_dec3x8 is
    signal en : std_logic := '0';
    signal a  : std_logic_vector(2 downto 0) := (others => '0');
    signal y  : std_logic_vector(7 downto 0);
begin
    dut : entity work.dec3x8 port map (en, a, y);

    process
        variable idx : integer;
    begin
        -- en = 0 => all zeros
        en <= '0';
        for i in 0 to 7 loop
            a <= std_logic_vector(to_unsigned(i, 3));
            wait for 5 ns;
            assert y = "00000000"
                report "DEC3x8 en=0 fail: a=" & integer'image(i) &
                       " got=" & integer'image(to_integer(unsigned(y)))
                severity failure;
        end loop;

        -- en = 1 => one-hot
        en <= '1';
        for i in 0 to 7 loop
            a <= std_logic_vector(to_unsigned(i, 3));
            wait for 5 ns;
            idx := i;
            assert y = std_logic_vector(to_unsigned(2**i, 8))
                report "DEC3x8 en=1 fail: a=" & integer'image(i) &
                       " got=" & integer'image(to_integer(unsigned(y))) &
                       " exp=" & integer'image(2**i)
                severity failure;
        end loop;

        report "tb_dec3x8: ALL TESTS PASSED" severity note;
        std.env.stop;
    end process;
end architecture sim;
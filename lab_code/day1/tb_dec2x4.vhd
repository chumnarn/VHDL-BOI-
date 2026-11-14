-- tb_dec2x4.vhd
-- Testbench for 2-to-4 decoder
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_dec2x4 is
end entity tb_dec2x4;

architecture sim of tb_dec2x4 is
    signal en : std_logic := '0';
    signal a  : std_logic_vector(1 downto 0) := (others => '0');
    signal y  : std_logic_vector(3 downto 0);
begin
    dut : entity work.dec2x4 port map (en, a, y);

    process
        type exp_arr is array (0 to 3) of std_logic_vector(3 downto 0);
        constant EXP : exp_arr := ("0001", "0010", "0100", "1000");
        variable idx : integer;
    begin
        -- en = 0 => all zeros
        en <= '0';
        for i in 0 to 3 loop
            a <= std_logic_vector(to_unsigned(i, 2));
            wait for 5 ns;
            assert y = "0000"
                report "DEC2x4 en=0 fail: a=" & integer'image(i) &
                       " got=" & integer'image(to_integer(unsigned(y)))
                severity failure;
        end loop;

        -- en = 1 => one-hot
        en <= '1';
        for i in 0 to 3 loop
            a <= std_logic_vector(to_unsigned(i, 2));
            wait for 5 ns;
            idx := i;
            assert y = EXP(idx)
                report "DEC2x4 en=1 fail: a=" & integer'image(i) &
                       " got=" & integer'image(to_integer(unsigned(y))) &
                       " exp=" & integer'image(to_integer(unsigned(EXP(idx))))
                severity failure;
        end loop;

        report "tb_dec2x4: ALL TESTS PASSED" severity note;
        std.env.stop;
    end process;
end architecture sim;
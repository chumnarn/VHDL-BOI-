-- tb_mux2x1.vhd
-- Testbench for 2-to-1 MUX (exhaustive)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_mux2x1 is
end entity tb_mux2x1;

architecture sim of tb_mux2x1 is
    signal a, b, sel : std_logic := '0';
    signal y         : std_logic;
begin
    dut : entity work.mux2x1 port map (a, b, sel, y);

    process
        procedure check(a, b, sel, exp : std_logic) is
        begin
            assert y = exp
                report "MUX2x1 fail: a=" & std_logic'image(a) &
                       " b=" & std_logic'image(b) &
                       " sel=" & std_logic'image(sel) &
                       " got=" & std_logic'image(y) &
                       " exp=" & std_logic'image(exp)
                severity failure;
        end procedure;
    begin
        a <= '0'; b <= '0'; sel <= '0'; wait for 10 ns;
        check(a, b, sel, '0');

        a <= '1'; b <= '0'; sel <= '0'; wait for 10 ns;
        check(a, b, sel, '1');

        a <= '0'; b <= '1'; sel <= '1'; wait for 10 ns;
        check(a, b, sel, '1');

        a <= '1'; b <= '1'; sel <= '1'; wait for 10 ns;
        check(a, b, sel, '1');

        a <= '0'; b <= '1'; sel <= '0'; wait for 10 ns;
        check(a, b, sel, '0');

        a <= '1'; b <= '0'; sel <= '1'; wait for 10 ns;
        check(a, b, sel, '0');

        report "tb_mux2x1: ALL TESTS PASSED" severity note;
        std.env.stop;
    end process;
end architecture sim;
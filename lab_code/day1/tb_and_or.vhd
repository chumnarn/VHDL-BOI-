-- tb_and_or.vhd
-- Testbench for AND gate and OR gate (exhaustive)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_and_or is
end entity tb_and_or;

architecture sim of tb_and_or is
    signal a, b : std_logic := '0';
    signal y_and, y_or : std_logic;
begin
    u_and : entity work.and_gate port map (a => a, b => b, y => y_and);
    u_or  : entity work.or_gate  port map (a => a, b => b, y => y_or);

    process
        procedure check_and(a, b, exp : std_logic) is
        begin
            assert y_and = exp
                report "AND fail: a=" & std_logic'image(a) &
                       " b=" & std_logic'image(b) &
                       " got=" & std_logic'image(y_and) &
                       " exp=" & std_logic'image(exp)
                severity failure;
        end procedure;

        procedure check_or(a, b, exp : std_logic) is
        begin
            assert y_or = exp
                report "OR fail: a=" & std_logic'image(a) &
                       " b=" & std_logic'image(b) &
                       " got=" & std_logic'image(y_or) &
                       " exp=" & std_logic'image(exp)
                severity failure;
        end procedure;
    begin
        -- Exhaustive: 00, 01, 10, 11
        a <= '0'; b <= '0'; wait for 10 ns;
        check_and(a, b, '0'); check_or(a, b, '0');

        a <= '0'; b <= '1'; wait for 10 ns;
        check_and(a, b, '0'); check_or(a, b, '1');

        a <= '1'; b <= '0'; wait for 10 ns;
        check_and(a, b, '0'); check_or(a, b, '1');

        a <= '1'; b <= '1'; wait for 10 ns;
        check_and(a, b, '1'); check_or(a, b, '1');

        report "tb_and_or: ALL TESTS PASSED" severity note;
        std.env.stop;
    end process;
end architecture sim;
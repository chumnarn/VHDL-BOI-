-- tb_nand4_gate.vhd
-- Testbench for 4-input NAND gate (all 16 patterns)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_nand4_gate is
end entity tb_nand4_gate;

architecture sim of tb_nand4_gate is
    signal a, b, c, d : std_logic := '0';
    signal y           : std_logic;
begin
    dut : entity work.nand4_gate port map (a, b, c, d, y);

    process
        variable cnt : integer := 0;
    begin
        for i in 0 to 15 loop
            a <= std_logic'val((i / 8) mod 2 + 1);  -- '0' or '1'
            b <= std_logic'val((i / 4) mod 2 + 1);
            c <= std_logic'val((i / 2) mod 2 + 1);
            d <= std_logic'val((i)      mod 2 + 1);
            wait for 5 ns;

            assert y = not (a and b and c and d)
                report "NAND4 fail: a=" & std_logic'image(a) &
                       " b=" & std_logic'image(b) &
                       " c=" & std_logic'image(c) &
                       " d=" & std_logic'image(d) &
                       " got=" & std_logic'image(y)
                severity failure;
            cnt := cnt + 1;
        end loop;

        report "tb_nand4_gate: 16 patterns PASSED" severity note;
        std.env.stop;
    end process;
end architecture sim;
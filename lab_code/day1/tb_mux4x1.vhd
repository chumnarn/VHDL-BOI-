-- tb_mux4x1.vhd
-- Testbench for 4-to-1 MUX (compare dataflow vs behavioral)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_mux4x1 is
end entity tb_mux4x1;

architecture sim of tb_mux4x1 is
    signal d0, d1, d2, d3        : std_logic := '0';
    signal sel                   : std_logic_vector(1 downto 0) := (others => '0');
    signal y_df, y_beh           : std_logic;
begin
    u_df  : entity work.mux4x1_dataflow   port map (d0, d1, d2, d3, sel, y_df);
    u_beh : entity work.mux4x1_behavioral port map (d0, d1, d2, d3, sel, y_beh);

    process
        procedure check(sel_v : std_logic_vector(1 downto 0);
                        d0v, d1v, d2v, d3v : std_logic;
                        exp : std_logic) is
        begin
            assert y_df = exp and y_beh = exp and y_df = y_beh
                report "MUX4x1 fail sel=" &
                       " got_df=" & std_logic'image(y_df) &
                       " got_beh=" & std_logic'image(y_beh) &
                       " exp=" & std_logic'image(exp)
                severity failure;
        end procedure;
    begin
        -- Apply distinct values to each input
        d0 <= '0'; d1 <= '0'; d2 <= '1'; d3 <= '1';
        sel <= "00"; wait for 5 ns; check(sel, d0, d1, d2, d3, '0');
        sel <= "01"; wait for 5 ns; check(sel, d0, d1, d2, d3, '0');
        sel <= "10"; wait for 5 ns; check(sel, d0, d1, d2, d3, '1');
        sel <= "11"; wait for 5 ns; check(sel, d0, d1, d2, d3, '1');

        -- Change inputs
        d0 <= '1'; d1 <= '0'; d2 <= '0'; d3 <= '1';
        sel <= "00"; wait for 5 ns; check(sel, d0, d1, d2, d3, '1');
        sel <= "01"; wait for 5 ns; check(sel, d0, d1, d2, d3, '0');
        sel <= "10"; wait for 5 ns; check(sel, d0, d1, d2, d3, '0');
        sel <= "11"; wait for 5 ns; check(sel, d0, d1, d2, d3, '1');

        report "tb_mux4x1: dataflow == behavioral, PASS" severity note;
        std.env.stop;
    end process;
end architecture sim;
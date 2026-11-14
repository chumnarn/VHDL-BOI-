-- tb_seq_moore.vhd
-- Self-checking testbench for Moore sequence detector "101"
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_seq_moore is
end entity tb_seq_moore;

architecture sim of tb_seq_moore is
    constant CLK_PERIOD : time := 10 ns;
    signal clk, rst, din, detected : std_logic;
    signal pass_cnt, fail_cnt     : integer := 0;
begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.seq_det_moore
        port map (clk => clk, rst => rst, din => din, detected => detected);

    stim : process
        variable prev_detected : std_logic := '0';
        procedure check(tag : in string; expected : in std_logic) is
        begin
            if detected /= expected then
                report "FAIL " & tag & ": got " & std_logic'image(detected) &
                       " expected " & std_logic'image(expected)
                    severity error;
                fail_cnt <= fail_cnt + 1;
            else
                pass_cnt <= pass_cnt + 1;
            end if;
        end;
    begin
        rst <= '1'; din <= '0';
        wait for 2 * CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;

        -- pattern 101
        din <= '1'; wait for CLK_PERIOD; check("after 1",    '0');
        din <= '0'; wait for CLK_PERIOD; check("after 10",   '0');
        din <= '1'; wait for CLK_PERIOD; check("after 101",  '1');

        -- back to 0 then 101 again
        din <= '0'; wait for CLK_PERIOD; check("after 1010", '0');
        din <= '0'; wait for CLK_PERIOD; check("after 10100",'0');
        din <= '1'; wait for CLK_PERIOD; check("after 101001",'0');
        din <= '0'; wait for CLK_PERIOD; check("after 1010010",'0');
        din <= '1'; wait for CLK_PERIOD; check("after 10100101",'1');

        report "tb_seq_moore PASS=" & integer'image(pass_cnt) &
               " FAIL=" & integer'image(fail_cnt);
        if fail_cnt = 0 then
            report "tb_seq_moore: ALL TESTS PASSED" severity note;
        end if;
        std.env.stop;
    end process;
end architecture sim;
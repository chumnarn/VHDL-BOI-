-- tb_seq_mealy.vhd
-- Self-checking testbench for Mealy sequence detector "101"
-- Detects "101" with OVERLAPPING detection:
--   the Mealy output is asserted in the same cycle the last bit arrives,
--   and S2 + din='1' returns to S1 so that "10101" reports the sequence twice.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_seq_mealy is
end entity tb_seq_mealy;

architecture sim of tb_seq_mealy is
    constant CLK_PERIOD : time := 10 ns;
    -- IMPORTANT: the clock MUST be initialised to '0'.
    -- Starting from 'U' makes "not clk" evaluate to 'U' forever and the
    -- clock never toggles (no rising edge => the FSM never leaves its
    -- initial state).
    signal clk, rst, din  : std_logic := '0';
    signal detected        : std_logic;
begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.seq_det_mealy
        port map (clk => clk, rst => rst, din => din, detected => detected);

    stim : process
        variable pass_cnt : integer := 0;
        variable fail_cnt : integer := 0;

        procedure check(tag : in string; expected : in std_logic) is
        begin
            if detected /= expected then
                report "FAIL " & tag & ": got " & std_logic'image(detected) &
                       " expected " & std_logic'image(expected)
                    severity error;
                fail_cnt := fail_cnt + 1;
            else
                pass_cnt := pass_cnt + 1;
            end if;
        end procedure;
    begin
        rst <= '1'; din <= '0';
        wait for 2 * CLK_PERIOD;
        rst <= '0';

        -- Align the stimulus with the clock so that every vector is sampled
        -- by exactly one rising edge.
        wait until rising_edge(clk);

        -- TIMING NOTE (Mealy): the output is COMBINATIONAL - it is asserted
        -- WHILE the last bit of the pattern is still on din, and it lasts
        -- only until the next clock edge. The check is therefore done right
        -- at the rising edge (before the state register updates).
        -- This is the key difference to a Moore machine, whose output is
        -- registered and appears one clock later.
        din <= '1'; wait until rising_edge(clk); check("after 1",   '0');
        din <= '0'; wait until rising_edge(clk); check("after 10",  '0');
        din <= '1'; wait until rising_edge(clk); check("after 101", '1');

        -- back to 0 then 101 again
        din <= '0'; wait until rising_edge(clk); check("after 1010", '0');
        din <= '0'; wait until rising_edge(clk); check("after 10100",'0');
        din <= '1'; wait until rising_edge(clk); check("after 101001",'0');
        din <= '0'; wait until rising_edge(clk); check("after 1010010",'0');
        din <= '1'; wait until rising_edge(clk); check("after 10100101",'1');

        -- OVERLAPPING check: "10101" must report "101" twice.
        din <= '0'; wait until rising_edge(clk); check("after 101001010", '0');
        din <= '1'; wait until rising_edge(clk); check("after 1010010101",'1');

        report "tb_seq_mealy PASS=" & integer'image(pass_cnt) &
               " FAIL=" & integer'image(fail_cnt);
        if fail_cnt = 0 then
            report "tb_seq_mealy: ALL TESTS PASSED" severity note;
        end if;
        std.env.stop;
    end process;
end architecture sim;

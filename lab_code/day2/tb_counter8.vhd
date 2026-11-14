-- tb_counter8.vhd
-- Testbench for 8-bit counter with CE and load
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.my_types_pkg.ALL;

entity tb_counter8 is
end entity tb_counter8;

architecture sim of tb_counter8 is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal ce, load : std_logic := '0';
    signal din, cnt : unsigned(COUNTER_WIDTH-1 downto 0);
    signal ovf      : std_logic;
begin
    clk <= not clk after 5 ns;  -- 100 MHz
    dut : entity work.counter8 port map (clk, rst, ce, load, din, cnt, ovf);

    stim : process
    begin
        -- 1) Reset
        wait for 20 ns;
        rst <= '0';

        -- 2) Count with CE
        ce <= '1'; load <= '0'; din <= (others => '0');
        for i in 0 to 5 loop
            wait until rising_edge(clk);
            wait for 1 ns;
        end loop;

        -- 3) Pause counting (CE=0)
        ce <= '0';
        wait for 50 ns;
        assert cnt = to_unsigned(6, COUNTER_WIDTH)
            report "Counter pause fail: got " & integer'image(to_integer(cnt))
            severity failure;

        -- 4) Resume counting
        ce <= '1';
        for i in 0 to 4 loop
            wait until rising_edge(clk);
            wait for 1 ns;
        end loop;
        assert cnt = to_unsigned(10, COUNTER_WIDTH)
            report "Counter resume fail: got " & integer'image(to_integer(cnt))
            severity failure;

        -- 5) Load value (0xA5 = 165)
        load <= '1'; din <= to_unsigned(165, COUNTER_WIDTH);
        wait until rising_edge(clk);
        wait for 1 ns;
        load <= '0';
        assert cnt = to_unsigned(165, COUNTER_WIDTH)
            report "Counter load fail: got " & integer'image(to_integer(cnt))
            severity failure;

        report "tb_counter8: ALL TESTS PASSED" severity note;
        std.env.stop;
    end process;
end architecture sim;
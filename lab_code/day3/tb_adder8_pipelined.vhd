-- tb_adder8_pipelined.vhd
-- Testbench for pipelined 8-bit adder (1 cycle latency)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_adder8_pipelined is
end entity tb_adder8_pipelined;

architecture sim of tb_adder8_pipelined is
    signal clk, rst : std_logic := '0';
    signal a, b, sum : std_logic_vector(7 downto 0) := (others => '0');
    signal cin  : std_logic := '0';
    signal cout : std_logic;
begin
    clk <= not clk after 5 ns;  -- 100 MHz
    dut : entity work.adder8_pipelined
        port map (clk => clk, rst => rst, a => a, b => b, cin => cin, sum => sum, cout => cout);

    process
        variable ia, ib, ic, es, ec : integer;
        variable ev, ey : std_logic_vector(7 downto 0);
        variable exp_cout : std_logic;
    begin
        rst <= '1'; wait for 25 ns;
        rst <= '0';

        -- Random vectors, check output appears 1 cycle later
        for vec in 0 to 7 loop
            ia := vec * 19 mod 256;
            ib := vec * 23 mod 256;
            ic := vec mod 2;
            a <= std_logic_vector(to_unsigned(ia, 8));
            b <= std_logic_vector(to_unsigned(ib, 8));
            -- std_logic'val(ic + 1) would give 'X'/'0' (the std_logic
            -- enumeration starts at 'U'). Use a conditional for a real '0'/'1'.
            cin <= '1' when ic = 1 else '0';
            es := ia + ib + ic;
            ev := std_logic_vector(to_unsigned(es mod 256, 8));
            ec := 1 when es > 255 else 0;

            wait until rising_edge(clk);
            wait until rising_edge(clk);  -- wait 2 cycles: 1 for register, 1 for stable output
            wait for 1 ns;

            assert sum = ev
                report "Pipelined adder fail vec=" & integer'image(vec) &
                       " got=" & integer'image(to_integer(unsigned(sum))) &
                       " exp=" & integer'image(to_integer(unsigned(ev)))
                severity failure;
            if ec = 1 then
                exp_cout := '1';
            else
                exp_cout := '0';
            end if;
            assert cout = exp_cout
                report "Pipelined adder cout fail vec=" & integer'image(vec)
                severity failure;
        end loop;

        report "tb_adder8_pipelined: ALL TESTS PASSED" severity note;
        std.env.stop;
    end process;
end architecture sim;
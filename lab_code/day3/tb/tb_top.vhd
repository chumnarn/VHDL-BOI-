-- tb_top.vhd
-- Chip-level testbench for entity `top` (Lab 3A)
--
-- Phase 1 checks the two combinational blocks (u_adder, u_addsub).
-- Phase 2 checks the pipelined block (u_pipe) and its 1-cycle latency.
--
-- The signed-overflow expectation is derived exactly the same way as in
-- add_sub_shared.vhd:
--   ADD: ovf = (sign(a)=sign(b))   and (sign(res) /= sign(a))
--   SUB: ovf = (sign(a)=sign(~b))  and (sign(res) /= sign(a))
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_top is
end entity tb_top;

architecture sim of tb_top is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal a, b : std_logic_vector(7 downto 0) := (others => '0');
    signal cin  : std_logic := '0';
    signal op   : std_logic := '0';
    signal sum, psum, sy : std_logic_vector(7 downto 0);
    signal cout, pcout, ovf : std_logic;
begin
    clk <= not clk after 5 ns;  -- 100 MHz
    dut : entity work.top
        port map (
            clk => clk, rst => rst, a => a, b => b, cin => cin, op => op,
            sum => sum, cout => cout,
            psum => psum, pcout => pcout,
            sy => sy, ovf => ovf);

    process
        variable ia, ib, exp_int, res_int : integer;
        variable exp_vec : std_logic_vector(7 downto 0);
        variable exp_cout, exp_ovf : std_logic;
        variable sign_a, sign_b, sign_r, sign_bb : std_logic;
        variable op_i : std_logic;
        variable check_cnt : integer := 0;
    begin
        -- Hold the synchronous reset for a few cycles
        wait for 25 ns;
        rst <= '0';

        -- ---------------- Phase 1: combinational blocks ----------------
        for k in 0 to 15 loop
            ia := (k * 37 + 11) mod 256;
            ib := (k * 61 + 5) mod 256;
            -- IMPORTANT: the mode is kept in a VARIABLE.  The signal `op` is
            -- assigned below, but a signal assignment only takes effect at
            -- the end of the current delta cycle - reading `op` here would
            -- still return the value of the PREVIOUS iteration.
            op_i := '1' when (k mod 3) = 0 else '0';
            a    <= std_logic_vector(to_unsigned(ia, 8));
            b    <= std_logic_vector(to_unsigned(ib, 8));
            cin  <= '1' when (k mod 2) = 1 else '0';
            op   <= op_i;

            -- u_adder : a + b + cin
            exp_int := ia + ib + (k mod 2);
            exp_vec := std_logic_vector(to_unsigned(exp_int mod 256, 8));
            exp_cout := '1' when exp_int > 255 else '0';

            -- u_addsub : a + b (ADD) or a - b (SUB), with signed overflow
            if op_i = '1' then
                res_int := (ia - ib) mod 256;
            else
                res_int := (ia + ib) mod 256;
            end if;
            sign_a  := '1' when ia      >= 128 else '0';
            sign_b  := '1' when ib      >= 128 else '0';
            sign_r  := '1' when res_int >= 128 else '0';
            -- the operand that actually enters the adder is ~b in SUB mode
            sign_bb := sign_b when op_i = '0' else (sign_b xor '1');
            exp_ovf := '1' when ((sign_a = sign_bb) and (sign_a /= sign_r)) else '0';

            wait for 5 ns;

            assert sum = exp_vec
                report "tb_top: u_adder sum fail k=" & integer'image(k) &
                       " got=" & integer'image(to_integer(unsigned(sum))) &
                       " exp=" & integer'image(exp_int mod 256)
                severity failure;
            assert cout = exp_cout
                report "tb_top: u_adder cout fail k=" & integer'image(k) &
                       " got=" & std_logic'image(cout) &
                       " exp=" & std_logic'image(exp_cout)
                severity failure;
            assert sy = std_logic_vector(to_unsigned(res_int, 8))
                report "tb_top: u_addsub y fail k=" & integer'image(k) &
                       " got=" & integer'image(to_integer(unsigned(sy))) &
                       " exp=" & integer'image(res_int)
                severity failure;
            assert ovf = exp_ovf
                report "tb_top: u_addsub ovf fail k=" & integer'image(k) &
                       " got=" & std_logic'image(ovf) &
                       " exp=" & std_logic'image(exp_ovf)
                severity failure;

            check_cnt := check_cnt + 4;
        end loop;

        -- ---------------- Phase 2: pipelined block ----------------
        for k in 0 to 7 loop
            ia := (k * 29 + 3) mod 256;
            ib := (k * 53 + 17) mod 256;
            a   <= std_logic_vector(to_unsigned(ia, 8));
            b   <= std_logic_vector(to_unsigned(ib, 8));
            cin <= '1' when (k mod 2) = 1 else '0';

            exp_int := ia + ib + (k mod 2);
            exp_vec := std_logic_vector(to_unsigned(exp_int mod 256, 8));
            exp_cout := '1' when exp_int > 255 else '0';

            wait until rising_edge(clk);
            wait until rising_edge(clk);  -- latency 1: value appears here
            wait for 1 ns;

            assert psum = exp_vec
                report "tb_top: u_pipe sum fail k=" & integer'image(k) &
                       " got=" & integer'image(to_integer(unsigned(psum))) &
                       " exp=" & integer'image(exp_int mod 256)
                severity failure;
            assert pcout = exp_cout
                report "tb_top: u_pipe cout fail k=" & integer'image(k) &
                       " got=" & std_logic'image(pcout) &
                       " exp=" & std_logic'image(exp_cout)
                severity failure;

            check_cnt := check_cnt + 2;
        end loop;

        report "tb_top: CHECKS=" & integer'image(check_cnt) &
               " FAIL=0";
        report "tb_top: ALL TESTS PASSED" severity note;
        std.env.stop;
    end process;
end architecture sim;

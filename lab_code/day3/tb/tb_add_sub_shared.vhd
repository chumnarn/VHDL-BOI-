-- tb_add_sub_shared.vhd
-- Testbench for ADD/SUB shared module
-- NOTE on 'ovf': the DUT reports SIGNED overflow, not carry-out.
--   ADD: ovf = (sign(a)=sign(b))    and (sign(res) /= sign(a))
--   SUB: ovf = (sign(a)=sign(~b))   and (sign(res) /= sign(a))
-- e.g. 0xFF+0x01 = 0x00 has carry-out 1 but ovf = 0
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_add_sub_shared is
end entity tb_add_sub_shared;

architecture sim of tb_add_sub_shared is
    signal a, b, y : std_logic_vector(7 downto 0) := (others => '0');
    signal op      : std_logic := '0';
    signal ovf     : std_logic;
begin
    dut : entity work.add_sub_shared port map (a => a, b => b, op => op, y => y, ovf => ovf);

    process
        variable ia, ib, e_int : integer;
        variable e_vec : std_logic_vector(7 downto 0);
        -- Counters are VARIABLES: a signal assignment would only be applied
        -- at the end of the current delta cycle, so the final report would
        -- read the stale value and miss the last increment.
        variable pass_cnt : integer := 0;
        variable fail_cnt : integer := 0;
    begin
        -- ADD random spot patterns
        a <= "00010010"; b <= "00110100"; op <= '0'; wait for 5 ns;
        e_int := to_integer(unsigned(a)) + to_integer(unsigned(b));
        e_vec := std_logic_vector(to_unsigned(e_int mod 256, 8));
        assert y = e_vec
            report "ADD fail 0x12+0x34 got=" & integer'image(to_integer(unsigned(y))) &
                   " exp=" & integer'image(e_int mod 256)
            severity failure;

        a <= "01111111"; b <= "00000001"; op <= '0'; wait for 5 ns;
        e_int := 127 + 1;
        e_vec := std_logic_vector(to_unsigned(e_int mod 256, 8));
        -- 0x7F + 0x01 = 0x80 which is outside the signed 8-bit range
        -- (-128..127) => signed overflow
        assert y = e_vec and ovf = '1'
            report "ADD signed overflow fail (0x7F+0x01 -> 0x80)"
            severity failure;

        -- 0xFF + 0x01 = 0x00 : the carry-out is 1 but there is NO signed
        -- overflow (-1 + 1 = 0). Carry-out and signed overflow are different.
        a <= "11111111"; b <= "00000001"; op <= '0'; wait for 5 ns;
        assert y = "00000000" and ovf = '0'
            report "ADD no-signed-overflow fail (0xFF+0x01 -> 0x00)"
            severity failure;

        -- SUB random spot patterns
        a <= "00100000"; b <= "00000001"; op <= '1'; wait for 5 ns;
        e_int := 32 - 1;
        e_vec := std_logic_vector(to_unsigned(e_int, 8));
        assert y = e_vec
            report "SUB 32-1 fail got=" & integer'image(to_integer(unsigned(y))) &
                   " exp=" & integer'image(e_int)
            severity failure;

        a <= "00000001"; b <= "00100000"; op <= '1'; wait for 5 ns;
        e_int := 1 - 32 + 256;
        e_vec := std_logic_vector(to_unsigned(e_int mod 256, 8));
        assert y = e_vec
            report "SUB 1-32 (negative) fail got=" & integer'image(to_integer(unsigned(y))) &
                   " exp=" & integer'image(e_int mod 256)
            severity failure;

        -- SUB signed overflow: 0x80 - 0x01 = 0x7F, which is outside the
        -- signed 8-bit range (-128..127) => signed overflow
        a <= "10000000"; b <= "00000001"; op <= '1'; wait for 5 ns;
        assert y = "01111111" and ovf = '1'
            report "SUB signed overflow fail (0x80-0x01 -> 0x7F)"
            severity failure;

        -- Exhaustive ADD 0..15 x 0..15
        for i in 0 to 15 loop
            for j in 0 to 15 loop
                a <= std_logic_vector(to_unsigned(i, 8));
                b <= std_logic_vector(to_unsigned(j, 8));
                op <= '0';
                wait for 5 ns;
                if y /= std_logic_vector(to_unsigned((i + j) mod 256, 8)) then
                    fail_cnt := fail_cnt + 1;
                else
                    pass_cnt := pass_cnt + 1;
                end if;
            end loop;
        end loop;

        -- Exhaustive SUB 0..15 x 0..15
        for i in 0 to 15 loop
            for j in 0 to 15 loop
                a <= std_logic_vector(to_unsigned(i, 8));
                b <= std_logic_vector(to_unsigned(j, 8));
                op <= '1';
                wait for 5 ns;
                if y /= std_logic_vector(to_unsigned(((i - j + 256) mod 256), 8)) then
                    fail_cnt := fail_cnt + 1;
                else
                    pass_cnt := pass_cnt + 1;
                end if;
            end loop;
        end loop;

        report "tb_add_sub_shared PASS=" & integer'image(pass_cnt) &
               " FAIL=" & integer'image(fail_cnt);
        if fail_cnt = 0 then
            report "tb_add_sub_shared: ALL EXHAUSTIVE PATTERNS PASS" severity note;
        end if;
        std.env.stop;
    end process;
end architecture sim;

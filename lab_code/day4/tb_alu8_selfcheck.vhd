-- tb_alu8_selfcheck.vhd
-- Self-checking testbench comparing ALU to reference model
-- Sweeps all 256 x 256 x 4 operations = 262,144 patterns
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_alu8_selfcheck is
end entity tb_alu8_selfcheck;

architecture sim of tb_alu8_selfcheck is
    signal a, b        : std_logic_vector(7 downto 0) := (others => '0');
    signal op          : std_logic_vector(1 downto 0)  := (others => '0');
    signal y_dut, y_ref : std_logic_vector(7 downto 0);
    signal z_dut, z_ref : std_logic;
    signal n_dut, n_ref : std_logic;
    signal pass_cnt, fail_cnt : integer := 0;
begin
    dut : entity work.alu8         port map (a, b, op, y_dut, z_dut, n_dut);
    ref : entity work.ref_model_alu8 port map (a, b, op, y_ref, z_ref, n_ref);

    process
        variable is_first_fail : boolean := true;
    begin
        for opv in 0 to 3 loop
            op <= std_logic_vector(to_unsigned(opv, 2));
            for av in 0 to 255 loop
                a <= std_logic_vector(to_unsigned(av, 8));
                for bv in 0 to 255 loop
                    b <= std_logic_vector(to_unsigned(bv, 8));
                    wait for 1 ns;
                    if y_dut /= y_ref then
                        fail_cnt <= fail_cnt + 1;
                        if is_first_fail then
                            report "First mismatch: op=" & integer'image(opv) &
                                   " a=" & integer'image(av) &
                                   " b=" & integer'image(bv) &
                                   " got=" & integer'image(to_integer(unsigned(y_dut))) &
                                   " exp=" & integer'image(to_integer(unsigned(y_ref)))
                            severity error;
                            is_first_fail := false;
                        end if;
                    else
                        pass_cnt <= pass_cnt + 1;
                    end if;
                    if z_dut /= z_ref then
                        fail_cnt <= fail_cnt + 1;
                    end if;
                    if n_dut /= n_ref then
                        fail_cnt <= fail_cnt + 1;
                    end if;
                end loop;
            end loop;
        end loop;

        report "tb_alu8_selfcheck PASS=" & integer'image(pass_cnt) &
               " FAIL=" & integer'image(fail_cnt);
        if fail_cnt = 0 then
            report "tb_alu8_selfcheck: ALL 262144 PATTERNS PASS" severity note;
        end if;
        std.env.stop;
    end process;
end architecture sim;
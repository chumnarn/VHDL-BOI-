-- tb_adder4.vhd
-- Testbench for 4-bit ripple carry adder (exhaustive: 256 x 256 patterns)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_adder4 is
end entity tb_adder4;

architecture sim of tb_adder4 is
    signal a, b : std_logic_vector(3 downto 0) := (others => '0');
    signal cin  : std_logic := '0';
    signal sum  : std_logic_vector(3 downto 0);
    signal cout : std_logic;
begin
    dut : entity work.adder4_struct port map (a, b, cin, sum, cout);

    process
        variable pass_cnt : integer := 0;
        variable fail_cnt : integer := 0;
    begin
        for c in 0 to 1 loop
            -- std_logic'val(c + 1) would give 'X'/'0' because the std_logic
            -- enumeration starts at 'U'. Use a conditional for a real '0'/'1'.
            cin <= '1' when c = 1 else '0';
            for i in 0 to 15 loop
                for j in 0 to 15 loop
                    a <= std_logic_vector(to_unsigned(i, 4));
                    b <= std_logic_vector(to_unsigned(j, 4));
                    wait for 5 ns;
                    assert sum = std_logic_vector(to_unsigned((i + j + c) mod 16, 4))
                        report "Sum fail: a=" & integer'image(i) &
                               " b=" & integer'image(j) &
                               " cin=" & integer'image(c) &
                               " got=" & integer'image(to_integer(unsigned(sum)))
                        severity failure;
                    if ((i + j + c) > 15) then
                        assert cout = '1'
                            report "Cout fail: a=" & integer'image(i) &
                                   " b=" & integer'image(j) &
                                   " cin=" & integer'image(c) &
                                   " got=" & std_logic'image(cout) &
                                   " exp=1"
                            severity failure;
                    else
                        assert cout = '0'
                            report "Cout fail: a=" & integer'image(i) &
                                   " b=" & integer'image(j) &
                                   " cin=" & integer'image(c) &
                                   " got=" & std_logic'image(cout) &
                                   " exp=0"
                            severity failure;
                    end if;
                    pass_cnt := pass_cnt + 1;
                end loop;
            end loop;
        end loop;

        report "tb_adder4: " & integer'image(pass_cnt) & " patterns tested, 0 failures"
            severity note;
        std.env.stop;
    end process;
end architecture sim;
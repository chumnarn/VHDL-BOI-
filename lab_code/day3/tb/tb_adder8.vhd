-- tb_adder8.vhd
-- Functional testbench for 8-bit adder (sampling a few patterns)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_adder8 is
end entity tb_adder8;

architecture sim of tb_adder8 is
    signal a, b : std_logic_vector(7 downto 0) := (others => '0');
    signal cin  : std_logic := '0';
    signal sum  : std_logic_vector(7 downto 0);
    signal cout : std_logic;
begin
    dut : entity work.adder8 port map (a, b, cin, sum, cout);

    process
        procedure check(tag : string; es : integer; ec : std_logic) is
        begin
            assert sum = std_logic_vector(to_unsigned(es, 8))
                report tag & "  sum fail: got " & integer'image(to_integer(unsigned(sum))) &
                       " exp " & integer'image(es)
                severity failure;
            assert cout = ec
                report tag & "  cout fail: got " & std_logic'image(cout) &
                       " exp " & std_logic'image(ec)
                severity failure;
        end procedure;
    begin
        wait for 5 ns;
        a <= x"12"; b <= x"34"; cin <= '0'; wait for 5 ns;
        check("0x12+0x34", 70, '0');  -- 0x12=18, 0x34=52, sum=70

        a <= x"FF"; b <= x"01"; cin <= '0'; wait for 5 ns;
        check("0xFF+0x01", 0, '1');  -- 255+1 = 256 -> wrap to 0, carry=1

        a <= x"FF"; b <= x"FF"; cin <= '1'; wait for 5 ns;
        check("0xFF+0xFF+1", 255, '1');  -- 255+255+1 = 511 -> 255, carry=1

        a <= x"80"; b <= x"80"; cin <= '0'; wait for 5 ns;
        check("0x80+0x80", 0, '1');  -- 128+128 = 256 -> 0, carry=1

        report "tb_adder8: ALL TESTS PASSED" severity note;
        std.env.stop;
    end process;
end architecture sim;

-- alu8.vhd
-- 8-bit ALU with 4 operations: ADD, SUB, AND, OR
-- Flags: zero (Z), negative (N)
--   op = "00" -> a + b
--   op = "01" -> a - b  (two's complement: a + ~b + 1)
--   op = "10" -> a AND b
--   op = "11" -> a OR  b
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu8 is
    port (
        a, b    : in  std_logic_vector(7 downto 0);
        op      : in  std_logic_vector(1 downto 0);
        y       : out std_logic_vector(7 downto 0);
        z_flag  : out std_logic;
        n_flag  : out std_logic
    );
end entity alu8;

architecture rtl of alu8 is
begin
    process (a, b, op)
        variable bb : unsigned(7 downto 0);
        variable vy : unsigned(8 downto 0);
        variable y8 : unsigned(7 downto 0);
    begin
        -- Compute bb: invert b for SUB
        case op is
            when "01" => bb := not unsigned(b);
            when others => bb := unsigned(b);
        end case;

        -- Compute based on op
        -- NOTE: resize() zero-extends to 9 bits. Without it the AND/OR
        -- branches would build a 16-bit value ("00000000" & a and bb) and
        -- the mismatched length raises "Array lengths do not match".
        case op is
            when "00" => vy := resize(unsigned(a), 9) + resize(bb, 9);
            when "01" => vy := resize(unsigned(a), 9) + resize(bb, 9) + 1;
            when "10" => vy := resize(unsigned(a) and bb, 9);
            when "11" => vy := resize(unsigned(a) or  bb, 9);
            when others => vy := (others => '0');
        end case;

        -- IMPORTANT: drive the outputs from the VARIABLE, not from a signal
        -- that this process assigns. Reading back a signal that the same
        -- process drives returns the OLD value, so "y <= std_logic_vector(yy)"
        -- would latch the previous (or initial 'U') value and never settle.
        y8      := vy(7 downto 0);
        y       <= std_logic_vector(y8);
        z_flag  <= '1' when y8 = (y8'range => '0') else '0';
        n_flag  <= y8(7);
    end process;
end architecture rtl;
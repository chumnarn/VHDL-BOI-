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
    signal yy : unsigned(7 downto 0);
begin
    process (a, b, op)
        variable bb : unsigned(7 downto 0);
        variable va : unsigned(8 downto 0);
        variable vb : unsigned(8 downto 0);
        variable vy : unsigned(8 downto 0);
    begin
        -- Compute bb: invert b for SUB
        case op is
            when "01" => bb := not unsigned(b);
            when others => bb := unsigned(b);
        end case;

        -- Compute based on op
        case op is
            when "00" => vy := ("0" & unsigned(a)) + ("0" & bb);
            when "01" => vy := ("0" & unsigned(a)) + ("0" & bb) + 1;
            when "10" => vy := "00000000" & (unsigned(a) and bb);
            when "11" => vy := "00000000" & (unsigned(a) or  bb);
            when others => vy := (others => '0');
        end case;

        yy <= vy(7 downto 0);
        y      <= std_logic_vector(yy);
        z_flag <= '1' when yy = (yy'range => '0') else '0';
        n_flag <= yy(7);
    end process;
end architecture rtl;
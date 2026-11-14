-- ref_model_alu8.vhd
-- Cycle-accurate reference model of ALU for verification
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ref_model_alu8 is
    port (
        a, b    : in  std_logic_vector(7 downto 0);
        op      : in  std_logic_vector(1 downto 0);
        y       : out std_logic_vector(7 downto 0);
        z_flag  : out std_logic;
        n_flag  : out std_logic
    );
end entity ref_model_alu8;

architecture sim of ref_model_alu8 is
begin
    process (a, b, op)
        variable va_int : integer;
        variable result_int : integer;
        variable result_uv  : unsigned(7 downto 0);
    begin
        case op is
            when "00" => va_int := to_integer(unsigned(a));
                result_int := va_int + to_integer(unsigned(b));
                result_int := ((result_int mod 256) + 256) mod 256;
            when "01" => va_int := to_integer(unsigned(a));
                result_int := va_int - to_integer(unsigned(b));
                result_int := ((result_int mod 256) + 256) mod 256;
            when "10" => result_int := to_integer(unsigned(a) and unsigned(b));
            when "11" => result_int := to_integer(unsigned(a) or  unsigned(b));
            when others => result_int := 0;
        end case;

        result_uv := to_unsigned(result_int, 8);
        y      <= std_logic_vector(result_uv);
        z_flag <= '1' when result_uv = (result_uv'range => '0') else '0';
        n_flag <= result_uv(7);
    end process;
end architecture sim;
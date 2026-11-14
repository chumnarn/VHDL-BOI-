-- add_sub_shared.vhd
-- Resource Sharing: 1 adder reused for ADD or SUB based on mode
-- SUB is implemented as: a - b = a + (~b + 1)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity add_sub_shared is
    port (
        a, b : in  std_logic_vector(7 downto 0);
        op   : in  std_logic;  -- 0 = ADD, 1 = SUB
        y    : out std_logic_vector(7 downto 0);
        ovf  : out std_logic
    );
end entity add_sub_shared;

architecture rtl of add_sub_shared is
    signal bb : unsigned(7 downto 0);
begin
    -- Invert b when SUB
    bb <= unsigned(b)             when op = '0' else
          not unsigned(b);

    -- Shared adder (one unsigned addition)
    p : process (a, bb, op)
        variable va : unsigned(8 downto 0);
        variable vy : unsigned(8 downto 0);
    begin
        va := resize(unsigned(a), 9);

        -- IMPORTANT: '&' has LOWER precedence than '+' in VHDL.
        -- "va + "0" & bb + 1" would be parsed as "(va + "0") & (bb + 1)"
        -- => a 17-bit result and a runtime "Array lengths do not match" error.
        -- Always parenthesise the concatenation, and keep both operands the
        -- same width (9 bits) for numeric_std.
        if op = '1' then
            vy := va + resize(bb, 9) + 1;   -- SUB: a + ~b + 1
        else
            vy := va + resize(bb, 9);       -- ADD
        end if;

        y <= std_logic_vector(vy(7 downto 0));

        -- Signed overflow detection.
        --   ADD (bb = b)    : ovf = (sign(a) == sign(b))    and (sign(res) /= sign(a))
        --   SUB (bb = ~b)   : ovf = (sign(a) == sign(~b))   and (sign(res) /= sign(a))
        -- Both cases collapse to the same expression because bb is always the
        -- operand that actually enters the adder.
        if (va(7) = bb(7)) and (va(7) /= vy(7)) then
            ovf <= '1';
        else
            ovf <= '0';
        end if;
    end process;
end architecture rtl;
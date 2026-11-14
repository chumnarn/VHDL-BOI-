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
        variable va, vy : unsigned(8 downto 0);
    begin
        va := "0" & unsigned(a);
        if op = '1' then
            vy := va + "0" & bb + 1;   -- SUB: a + ~b + 1
        else
            vy := va + "0" & bb;       -- ADD
        end if;

        y <= std_logic_vector(vy(7 downto 0));
        -- Overflow detection (signed)
        if (va(7) = vy(7)) and (va(7) /= bb(7)) then
            ovf <= '1';
        else
            ovf <= '0';
        end if;
    end process;
end architecture rtl;
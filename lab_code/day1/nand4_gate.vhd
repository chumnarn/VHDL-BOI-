-- nand4_gate.vhd
-- 4-input NAND gate - Behavioral style
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity nand4_gate is
    port (
        a, b, c, d : in  std_logic;
        y          : out std_logic
    );
end entity nand4_gate;

architecture behavioral of nand4_gate is
begin
    y <= not (a and b and c and d);
end architecture behavioral;
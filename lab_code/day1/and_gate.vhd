-- and_gate.vhd
-- 2-input AND gate - Dataflow style
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity and_gate is
    port (
        a, b : in  std_logic;
        y    : out std_logic
    );
end entity and_gate;

architecture dataflow of and_gate is
begin
    y <= a and b;
end architecture dataflow;
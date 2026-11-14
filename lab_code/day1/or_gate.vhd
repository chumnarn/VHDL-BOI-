-- or_gate.vhd
-- 2-input OR gate - Dataflow style
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity or_gate is
    port (
        a, b : in  std_logic;
        y    : out std_logic
    );
end entity or_gate;

architecture dataflow of or_gate is
begin
    y <= a or b;
end architecture dataflow;
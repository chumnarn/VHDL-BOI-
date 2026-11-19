-- full_adder_struct.vhd
-- 1-bit Full Adder - Structural modeling using xor/and/or gates
--
-- NOTE: this file is a self-contained copy of lab_code/day2/full_adder_struct.vhd
-- so that lab_code/day3/ can be handed out / copied as one folder.
-- The entity names are identical to the Day 2 version on purpose: adder8.vhd
-- binds a `component full_adder_struct` declaration to it.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity xor_gate is
    port (a, b : in  std_logic; y : out std_logic);
end entity xor_gate;

architecture dataflow of xor_gate is
begin
    y <= a xor b;
end architecture dataflow;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity and_gate is
    port (a, b : in  std_logic; y : out std_logic);
end entity and_gate;

architecture dataflow of and_gate is
begin
    y <= a and b;
end architecture dataflow;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity or_gate is
    port (a, b : in  std_logic; y : out std_logic);
end entity or_gate;

architecture dataflow of or_gate is
begin
    y <= a or b;
end architecture dataflow;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity full_adder_struct is
    port (
        a, b, cin : in  std_logic;
        sum, cout : out std_logic
    );
end entity full_adder_struct;

architecture struct of full_adder_struct is
    signal s1, s2, s3 : std_logic;
begin
    u1 : entity work.xor_gate port map (a, b, s1);
        -- (per-VHDL rules, work.xor_gate is the entity xor_gate in this file)
    u2 : entity work.xor_gate port map (s1, cin, sum);
    u3 : entity work.and_gate port map (a, b, s2);
    u4 : entity work.and_gate port map (s1, cin, s3);
    u5 : entity work.or_gate  port map (s2, s3, cout);
end architecture struct;

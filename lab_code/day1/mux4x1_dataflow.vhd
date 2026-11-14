-- mux4x1_dataflow.vhd
-- 4-to-1 MUX - Dataflow style using concurrent selection
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux4x1_dataflow is
    port (
        d0, d1, d2, d3 : in  std_logic;
        sel             : in  std_logic_vector(1 downto 0);
        y               : out std_logic
    );
end entity mux4x1_dataflow;

architecture dataflow of mux4x1_dataflow is
begin
    y <= d0 when sel = "00" else
         d1 when sel = "01" else
         d2 when sel = "10" else
         d3 when sel = "11" else
         'X';
end architecture dataflow;
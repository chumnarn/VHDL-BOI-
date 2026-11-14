-- top.vhd
-- Top-level wrapper that combines adder8 (DUT) for Precision RTL synthesis
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
    port (
        a, b : in  std_logic_vector(7 downto 0);
        cin  : in  std_logic;
        sum  : out std_logic_vector(7 downto 0);
        cout : out std_logic
    );
end entity top;

architecture struct of top is
begin
    u_adder : entity work.adder8 port map (a, b, cin, sum, cout);
end architecture struct;
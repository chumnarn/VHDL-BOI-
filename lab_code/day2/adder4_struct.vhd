-- adder4_struct.vhd
-- 4-bit Ripple Carry Adder using structural instantiation of 1-bit Full Adder
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity adder4_struct is
    port (
        a, b   : in  std_logic_vector(3 downto 0);
        cin    : in  std_logic;
        sum    : out std_logic_vector(3 downto 0);
        cout   : out std_logic
    );
end entity adder4_struct;

architecture struct of adder4_struct is
    signal c : std_logic_vector(4 downto 0);
begin
    u0 : entity work.full_adder_struct port map (a(0), b(0), c(0), sum(0), c(1));
    u1 : entity work.full_adder_struct port map (a(1), b(1), c(1), sum(1), c(2));
    u2 : entity work.full_adder_struct port map (a(2), b(2), c(2), sum(2), c(3));
    u3 : entity work.full_adder_struct port map (a(3), b(3), c(3), sum(3), c(4));
    c(0) <= cin;
    cout <= c(4);
end architecture struct;
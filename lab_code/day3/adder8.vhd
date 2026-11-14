-- adder8.vhd
-- 8-bit Ripple Carry Adder (non-pipelined baseline)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity adder8 is
    port (
        a, b : in  std_logic_vector(7 downto 0);
        cin  : in  std_logic;
        sum  : out std_logic_vector(7 downto 0);
        cout : out std_logic
    );
end entity adder8;

architecture struct of adder8 is
    component full_adder_struct is
        port (a, b, cin : in  std_logic; sum, cout : out std_logic);
    end component;
    signal c : std_logic_vector(8 downto 0);
begin
    c(0) <= cin;
    gen : for i in 0 to 7 generate
        u : full_adder_struct port map (a(i), b(i), c(i), sum(i), c(i+1));
    end generate;
    cout <= c(8);
end architecture struct;
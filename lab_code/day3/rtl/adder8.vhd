-- adder8.vhd
-- 8-bit Ripple Carry Adder (non-pipelined baseline)
--
-- Synthesis notes:
--   * The ripple structure is deliberately kept so that students can see
--     the area/timing trade-off against adder8_pipelined.vhd.
--   * `component full_adder_struct` binds to the entity of the same name in
--     rtl/full_adder_struct.vhd (both live in library `work`).
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

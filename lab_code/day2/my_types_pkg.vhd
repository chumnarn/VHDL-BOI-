-- my_types_pkg.vhd
-- Package with constants/types reused in Day 2 labs
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package my_types_pkg is
    constant COUNTER_WIDTH : integer := 8;
    constant FIFO_DEPTH    : integer := 16;
    constant DATA_WIDTH    : integer := 8;
    type    fifo_state_t is (EMPTY, PARTIAL, FULL);
end package my_types_pkg;
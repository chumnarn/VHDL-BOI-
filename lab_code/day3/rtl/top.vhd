-- top.vhd
-- Chip-level top for Lab 3A (Precision RTL Synthesis)
--
-- The top deliberately mixes combinational and sequential logic:
--   * u_adder   : purely combinational  -> path a/b/cin  -> sum/cout
--   * u_pipe    : registered (latency 1) -> path clk     -> psum/pcout
--   * u_addsub  : purely combinational  -> path a/b/op   -> sy/ovf
--
-- Because there is a real clock, sdc/top.sdc can use create_clock on the
-- `clk` port and the timing report contains BOTH
--   - register-to-register paths (clocked by sys_clk)
--   - input-to-output paths (constrained by set_input_delay/set_output_delay)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        a, b  : in  std_logic_vector(7 downto 0);
        cin   : in  std_logic;
        op    : in  std_logic;                      -- 0 = ADD, 1 = SUB
        sum   : out std_logic_vector(7 downto 0);   -- combinational adder
        cout  : out std_logic;
        psum  : out std_logic_vector(7 downto 0);   -- pipelined adder (latency 1)
        pcout : out std_logic;
        sy    : out std_logic_vector(7 downto 0);   -- ADD/SUB shared adder
        ovf   : out std_logic
    );
end entity top;

architecture struct of top is
begin
    u_adder : entity work.adder8
        port map (a => a, b => b, cin => cin, sum => sum, cout => cout);

    u_pipe : entity work.adder8_pipelined
        port map (clk => clk, rst => rst, a => a, b => b, cin => cin,
                  sum => psum, cout => pcout);

    u_addsub : entity work.add_sub_shared
        port map (a => a, b => b, op => op, y => sy, ovf => ovf);
end architecture struct;

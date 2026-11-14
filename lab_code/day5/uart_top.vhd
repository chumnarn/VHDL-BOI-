-- uart_top.vhd
-- Top-level UART TX wrapper
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_top is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        din      : in  std_logic_vector(7 downto 0);
        din_vld  : in  std_logic;
        din_rdy  : out std_logic;
        tx       : out std_logic
    );
end entity uart_top;

architecture struct of uart_top is
    signal baud_tick : std_logic;
begin
    u_baud : entity work.baud_gen
        generic map (
            CLK_FREQ => 100_000_000,
            BAUD_RATE => 115_200
        )
        port map (
            clk    => clk,
            rst    => rst,
            enable => '1',       -- always running
            tick   => baud_tick
        );

    u_tx : entity work.uart_tx
        port map (
            clk       => clk,
            rst       => rst,
            din       => din,
            din_vld   => din_vld,
            din_rdy   => din_rdy,
            baud_tick => baud_tick,
            tx        => tx
        );
end architecture struct;
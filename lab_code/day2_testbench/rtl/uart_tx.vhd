-- uart_tx.vhd
-- UART Transmitter 8-N-1 (สำเนาเฉพาะ day2_testbench)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        din       : in  std_logic_vector(7 downto 0);
        din_vld   : in  std_logic;
        din_rdy   : out std_logic;
        baud_tick : in  std_logic;
        tx        : out std_logic
    );
end entity uart_tx;

architecture rtl of uart_tx is
    type state_t is (IDLE, START, DATA, STOP);
    signal state   : state_t;
    signal bit_idx : integer range 0 to 7;
    signal shreg   : std_logic_vector(7 downto 0);
begin
    sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state   <= IDLE;
                bit_idx <= 0;
                shreg   <= (others => '0');
                tx      <= '1';
                din_rdy <= '1';
            else
                case state is
                    when IDLE =>
                        tx <= '1';
                        din_rdy <= '1';
                        if din_vld = '1' then
                            shreg   <= din;
                            din_rdy <= '0';
                            state   <= START;
                        end if;
                    when START =>
                        if baud_tick = '1' then
                            tx <= '0';
                            state <= DATA;
                            bit_idx <= 0;
                        end if;
                    when DATA =>
                        if baud_tick = '1' then
                            tx <= shreg(bit_idx);
                            if bit_idx = 7 then
                                state <= STOP;
                            else
                                bit_idx <= bit_idx + 1;
                            end if;
                        end if;
                    when STOP =>
                        if baud_tick = '1' then
                            tx <= '1';
                            state <= IDLE;
                            bit_idx <= 0;
                        end if;
                end case;
            end if;
        end if;
    end process;
end architecture rtl;

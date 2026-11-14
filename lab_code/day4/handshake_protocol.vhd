-- handshake_protocol.vhd
-- Simple request/acknowledge handshake protocol (producer)
-- Protocol rule: req must remain high until ack is observed
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity handshake_protocol is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        trig     : in  std_logic;
        data_in  : in  std_logic_vector(7 downto 0);
        req      : out std_logic;
        ack      : in  std_logic;
        data_out : out std_logic_vector(7 downto 0)
    );
end entity handshake_protocol;

architecture rtl of handshake_protocol is
    type state_t is (IDLE, START_BIT, WAIT_ACK);
    signal state : state_t;
    signal latch : std_logic_vector(7 downto 0);
begin
    sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state     <= IDLE;
                req       <= '0';
                latch     <= (others => '0');
            else
                case state is
                    when IDLE =>
                        req <= '0';
                        if trig = '1' then
                            latch <= data_in;
                            state <= START_BIT;
                        end if;
                    when START_BIT =>
                        req   <= '1';
                        state <= WAIT_ACK;
                    when WAIT_ACK =>
                        if ack = '1' then
                            req   <= '0';
                            state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

    data_out <= latch when (state = START_BIT or state = WAIT_ACK)
                else (others => '0');
end architecture rtl;
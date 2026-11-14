-- seq_det_moore.vhd
-- Moore FSM: detect pattern "101"
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity seq_det_moore is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        din      : in  std_logic;
        detected : out std_logic
    );
end entity seq_det_moore;

architecture rtl of seq_det_moore is
    type state_t is (S0, S1, S2, S3);
    signal state, next_state : state_t;
begin
    sync_proc : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= S0;
            else
                state <= next_state;
            end if;
        end if;
    end process sync_proc;

    comb_proc : process (state, din)
    begin
        detected <= '0';
        case state is
            when S0 =>
                if din = '1' then next_state <= S1;
                else              next_state <= S0;
                end if;
            when S1 =>
                if din = '0' then next_state <= S2;
                else              next_state <= S1;
                end if;
            when S2 =>
                if din = '1' then next_state <= S3;
                else              next_state <= S0;
                end if;
            when S3 =>
                detected <= '1';
                if din = '1' then next_state <= S1;
                else              next_state <= S0;
                end if;
        end case;
    end process comb_proc;
end architecture rtl;
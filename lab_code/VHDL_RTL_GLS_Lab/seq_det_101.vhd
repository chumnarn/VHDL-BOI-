library ieee;
use ieee.std_logic_1164.all;

entity seq_det_101 is
    port (
        clk      : in  std_logic;
        rst_n    : in  std_logic;
        din      : in  std_logic;
        detected : out std_logic
    );
end entity;

architecture rtl of seq_det_101 is
    type state_t is (idle, seen_1, seen_10, found);
    signal state, next_state : state_t;
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= idle;
            else
                state <= next_state;
            end if;
        end if;
    end process;

    process (all)
    begin
        case state is
            when idle =>
                if din = '1' then
                    next_state <= seen_1;
                else
                    next_state <= idle;
                end if;
            when seen_1 | found =>
                if din = '1' then
                    next_state <= seen_1;
                else
                    next_state <= seen_10;
                end if;
            when seen_10 =>
                if din = '1' then
                    next_state <= found;
                else
                    next_state <= idle;
                end if;
        end case;
    end process;

    detected <= '1' when state = found else '0';
end architecture;

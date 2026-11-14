-- tb_uart_top.vhd
-- Self-checking testbench for UART TX
-- Scoreboard: send known byte, observe tx line over 10 bit periods,
-- verify frame = start(0) | data | stop(1)
--
-- Sampling rule: one bit cell = BAUD_CYCLES clocks = 8680 ns.
-- Every bit is sampled at the CENTRE of its bit cell (half a bit period
-- after the cell starts), which is the only safe place to sample a
-- serial line: sampling on the cell boundary is ambiguous because the
-- transmitter can change tx on the very same clock edge.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_uart_top is
end entity tb_uart_top;

architecture sim of tb_uart_top is
    constant CLK_FREQ_HZ : integer := 100_000_000;
    constant BAUD_RATE    : integer := 115_200;
    constant CLK_PERIOD   : time := 10 ns;
    constant BAUD_CYCLES  : integer := CLK_FREQ_HZ / BAUD_RATE;   -- 868
    constant HALF_CYCLES  : integer := BAUD_CYCLES / 2;           -- 434

    signal clk, rst           : std_logic := '0';
    signal din                : std_logic_vector(7 downto 0) := (others => '0');
    signal din_vld, din_rdy   : std_logic;
    signal tx                 : std_logic;
begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.uart_top port map (clk, rst, din, din_vld, din_rdy, tx);

    stim : process
        variable btest : std_logic_vector(7 downto 0);
        -- Counters are VARIABLES: a signal assignment would only be applied
        -- at the end of the current delta cycle, so the final report would
        -- read the stale value and miss the last increment.
        variable pass_cnt : integer := 0;
        variable fail_cnt : integer := 0;

        -- Send one byte and check the complete 10-bit frame on the tx line.
        procedure send_and_check(b : std_logic_vector(7 downto 0)) is
        begin
            -- 1. wait until the transmitter is ready for a new byte
            for guard in 0 to 4 * BAUD_CYCLES loop
                wait until rising_edge(clk);
                exit when din_rdy = '1';
            end loop;

            -- 2. present the data and the valid strobe
            din     <= b;
            din_vld <= '1';

            -- 3. wait until the transmitter has latched the byte
            for guard in 0 to 4 * BAUD_CYCLES loop
                wait until rising_edge(clk);
                exit when din_rdy = '0';
            end loop;
            din_vld <= '0';

            -- 4. synchronise on the start bit (tx goes low)
            for guard in 0 to 4 * BAUD_CYCLES loop
                wait until rising_edge(clk);
                exit when tx = '0';
            end loop;
            assert tx = '0'
                report "Timeout: start bit was never detected"
                severity failure;

            -- 5. sample every bit cell at its centre
            for bit_i in 0 to 9 loop
                if bit_i = 0 then
                    -- first cell: half a bit period after the start edge
                    for j in 1 to HALF_CYCLES loop
                        wait until rising_edge(clk);
                    end loop;
                else
                    -- one full bit period to the next cell centre
                    for j in 1 to BAUD_CYCLES loop
                        wait until rising_edge(clk);
                    end loop;
                end if;

                if bit_i = 0 then
                    -- start bit
                    assert tx = '0'
                        report "Start bit fail at bit 0: got " & std_logic'image(tx)
                        severity failure;
                elsif bit_i = 9 then
                    -- stop bit
                    assert tx = '1'
                        report "Stop bit fail at bit 9: got " & std_logic'image(tx)
                        severity failure;
                else
                    -- data bit b(bit_i - 1)
                    assert tx = b(bit_i - 1)
                        report "Data bit " & integer'image(bit_i-1) &
                               " fail: got " & std_logic'image(tx) &
                               " exp " & std_logic'image(b(bit_i-1))
                        severity failure;
                end if;
            end loop;

            pass_cnt := pass_cnt + 1;
        end procedure;
    begin
        rst <= '1'; wait for 5 * CLK_PERIOD;
        rst <= '0';
        wait for 200 ns;

        -- Test pattern set: 0x00, 0xFF, 0x55, 0xAA, 0x42, 0x3C
        for sel in 0 to 5 loop
            case sel is
                when 0 => btest := x"00";
                when 1 => btest := x"FF";
                when 2 => btest := x"55";
                when 3 => btest := x"AA";
                when 4 => btest := x"42";
                when others => btest := x"3C";
            end case;
            send_and_check(btest);
            assert tx = '1'
                report "TX not idle between frames"
                severity failure;
        end loop;

        report "tb_uart_top PASS=" & integer'image(pass_cnt) &
               " FAIL=" & integer'image(fail_cnt);
        if fail_cnt = 0 then
            report "tb_uart_top: ALL PATTERN FRAMES VERIFIED" severity note;
        end if;
        std.env.stop;
    end process;
end architecture sim;

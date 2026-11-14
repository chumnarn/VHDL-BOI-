-- tb_uart_top.vhd
-- Self-checking testbench for UART TX
-- Scoreboard: send known byte, observe tx line over 10 bit periods,
-- verify frame = start(0) | data | stop(1)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_uart_top is
end entity tb_uart_top;

architecture sim of tb_uart_top is
    constant CLK_FREQ_HZ : integer := 100_000_000;
    constant BAUD_RATE    : integer := 115_200;
    constant CLK_PERIOD   : time := 10 ns;
    constant BAUD_CYCLES  : integer := CLK_FREQ_HZ / BAUD_RATE;

    signal clk, rst           : std_logic := '0';
    signal din                : std_logic_vector(7 downto 0) := (others => '0');
    signal din_vld, din_rdy   : std_logic;
    signal tx                 : std_logic;

    signal pass_cnt, fail_cnt : integer := 0;
begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.uart_top port map (clk, rst, din, din_vld, din_rdy, tx);

    stim : process
        -- Sample tx at center of each bit period (1.5 baud cycles after detection)
        procedure sample_and_check(b : std_logic_vector(7 downto 0)) is
            variable wait_cycles : integer;
        begin
            -- Wait for the transmitter to finish accepting the byte
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            din_vld <= '0';

            -- Sample 10 bits at baud period
            wait_cycles := BAUD_CYCLES + BAUD_CYCLES / 2;   -- start bit mid-cell
            for bit_i in 0 to 9 loop
                wait until rising_edge(clk);
                for j in 1 to wait_cycles loop
                    wait until rising_edge(clk);
                end loop;

                -- Compare
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

            pass_cnt <= pass_cnt + 1;
        end procedure;
    begin
        rst <= '1'; wait for 5 * CLK_PERIOD;
        rst <= '0';
        wait for 200 ns;

        -- Test pattern set: 0x00, 0xFF, 0x55, 0xAA, 0x42, 0x3C
        for sel in 0 to 5 loop
            case sel is
                when 0 => din <= x"00";
                when 1 => din <= x"FF";
                when 2 => din <= x"55";
                when 3 => din <= x"AA";
                when 4 => din <= x"42";
                when others => din <= x"3C";
            end case;
            din_vld <= '1';
            sample_and_check(din);
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
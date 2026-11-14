-- tb_handshake.vhd
-- Testbench for handshake protocol with concurrent assertion
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_handshake is
end entity tb_handshake;

architecture sim of tb_handshake is
    constant CLK_PERIOD : time := 10 ns;
    signal clk, rst            : std_logic := '0';
    signal trig, req, ack      : std_logic := '0';
    signal data_in, data_out   : std_logic_vector(7 downto 0) := (others => '0');
    signal req_count           : integer := 0;
    signal err_count           : integer := 0;
begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.handshake_protocol
        port map (clk => clk, rst => rst, trig => trig,
                  data_in => data_in, req => req, ack => ack,
                  data_out => data_out);

    -- Acknowledge after a random delay (1-3 cycles) once req goes high
    ack_p : process
    begin
        wait until rising_edge(clk);
        if rst = '1' then
            ack <= '0';
        elsif req = '1' and ack = '0' then
            ack <= '1';
        elsif req = '0' then
            ack <= '0';
        end if;
    end process;

    stim : process
        variable d : integer;
    begin
        rst <= '1'; wait for 3 * CLK_PERIOD;
        rst <= '0';

        for i in 0 to 15 loop
            d := (i * 23) mod 256;
            data_in <= std_logic_vector(to_unsigned(d, 8));
            wait until rising_edge(clk);
            trig <= '1';
            wait until rising_edge(clk);
            trig <= '0';

            -- wait for req to drop
            for wait_i in 0 to 20 loop
                wait until rising_edge(clk);
                exit when req = '0';
            end loop;

            assert req = '0'
                report "REQ did not drop within 20 cycles for pattern " & integer'image(i)
                severity failure;
        end loop;

        report "tb_handshake: ALL HANDSHAKES COMPLETED" severity note;
        std.env.stop;
    end process;

    -- Concurrent check: req must be low during reset.
    -- The DUT drives req from a flip-flop, so at the first rising edge req is
    -- still 'U' (the register has not been updated yet). Sampling it in the
    -- same delta as the clock edge is a race: wait one settle time so the
    -- register update is visible before the check.
    -- NOTE: this process must NOT have a sensitivity list - a process with a
    -- sensitivity list may not contain a wait statement.
    chk_rst_req : process
    begin
        wait until rising_edge(clk);
        wait for 1 ns;
        if rst = '1' then
            assert req = '0'
                report "REQ must be low during reset (at time " &
                       time'image(now) & ")"
                severity failure;
        end if;
    end process;
end architecture sim;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_seq_det_101 is
end entity;

architecture sim of tb_seq_det_101 is
    component seq_det_101 is
        port (
            clk      : in  std_logic;
            rst_n    : in  std_logic;
            din      : in  std_logic;
            detected : out std_logic
        );
    end component;

    constant half_period : time := 5 ns;
    constant sample_delay : time := 4 ns;
    signal clk      : std_logic := '0';
    signal rst_n    : std_logic := '0';
    signal din      : std_logic := '0';
    signal detected : std_logic;
    signal done     : boolean := false;
begin
    dut : seq_det_101
        port map (clk => clk, rst_n => rst_n, din => din, detected => detected);

    clock_gen : process
    begin
        while not done loop
            wait for half_period;
            clk <= not clk;
        end loop;
        wait;
    end process;

    stimulus : process
        variable history : std_logic_vector(2 downto 0) := "000";
        variable checks  : natural := 0;
        variable bits    : std_logic_vector(6 downto 0);

        procedure cycle (reset_value, input_bit : std_logic) is
            variable expected : std_logic;
        begin
            wait until falling_edge(clk);
            rst_n <= reset_value;
            din <= input_bit;

            wait until rising_edge(clk);
            if reset_value = '0' then
                history := "000";
            else
                history := history(1 downto 0) & input_bit;
            end if;

            expected := '0';
            if history = "101" then
                expected := '1';
            end if;

            wait for sample_delay;
            checks := checks + 1;
            assert detected = expected
                report "FAIL check=" & natural'image(checks) &
                       " history=" & to_string(history) &
                       " expected=" & std_logic'image(expected) &
                       " actual=" & std_logic'image(detected)
                severity failure;
        end procedure;
    begin
        assert sample_delay < half_period
            report "sample_delay must precede the next falling edge"
            severity failure;

        cycle('0', '0');
        cycle('1', '1');
        cycle('1', '0');
        cycle('1', '1');
        cycle('1', '0');
        cycle('1', '1');
        cycle('0', '1');

        for word_index in 0 to 127 loop
            bits := std_logic_vector(to_unsigned(word_index, bits'length));
            cycle('0', '0');
            for bit_index in bits'range loop
                cycle('1', bits(bit_index));
            end loop;
        end loop;

        report "PASS checks=" & natural'image(checks) severity note;
        done <= true;
        wait;
    end process;
end architecture;

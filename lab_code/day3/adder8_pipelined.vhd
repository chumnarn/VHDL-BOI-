-- adder8_pipelined.vhd
-- 8-bit adder split into 2 stages of 4-bit with pipeline register
-- Output appears 1 clock after input (latency = 1 cycle)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder8_pipelined is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        a, b  : in  std_logic_vector(7 downto 0);
        cin   : in  std_logic;
        sum   : out std_logic_vector(7 downto 0);
        cout  : out std_logic
    );
end entity adder8_pipelined;

architecture rtl of adder8_pipelined is
    signal r1_a, r1_b : std_logic_vector(7 downto 0);
    signal r1_cin     : std_logic;
    signal low_cout   : std_logic;
begin
    -- Stage 1: register inputs
    stage1 : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r1_a   <= (others => '0');
                r1_b   <= (others => '0');
                r1_cin <= '0';
            else
                r1_a   <= a;
                r1_b   <= b;
                r1_cin <= cin;
            end if;
        end if;
    end process stage1;

    -- Stage 2: combine and register output
    stage2 : process (clk)
        variable va, vb, vs : unsigned(8 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sum  <= (others => '0');
                cout <= '0';
            else
                -- Low nibble add with r1_cin
                va := "0" & unsigned(r1_a(3 downto 0));
                vb := "0" & unsigned(r1_b(3 downto 0));
                if r1_cin = '1' then
                    vs := va + vb + 1;
                else
                    vs := va + vb;
                end if;
                sum(3 downto 0) <= std_logic_vector(vs(3 downto 0));
                low_cout <= vs(4);

                -- High nibble add with carry from low
                va := "0" & unsigned(r1_a(7 downto 4));
                vb := "0" & unsigned(r1_b(7 downto 4));
                if vs(4) = '1' then
                    vs := va + vb + 1;
                else
                    vs := va + vb;
                end if;
                sum(7 downto 4) <= std_logic_vector(vs(3 downto 0));
                cout <= vs(4);
            end if;
        end if;
    end process stage2;
end architecture rtl;
-- counter_sync.vhd — ตัวอย่างประกอบหัวข้อ 3.8 — Synchronous counter + clock enable
-- จุดประสงค์: แสดงการ infer DFF, synchronous reset (mux หน้า DFF) และ clock enable
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_sync is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    ce   : in  std_logic;
    cnt  : out std_logic_vector(7 downto 0)
  );
end entity counter_sync;

architecture rtl of counter_sync is
  signal q : unsigned(7 downto 0);
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        q <= (others => '0');
      elsif ce = '1' then
        q <= q + 1;
      end if;
    end if;
  end process;

  cnt <= std_logic_vector(q);
end architecture rtl;

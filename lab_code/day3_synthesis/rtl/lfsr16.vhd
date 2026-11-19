-- lfsr16.vhd — ตัวอย่างประกอบหัวข้อ 3.8 — 16-bit LFSR (Galois form)
-- จุดประสงค์: แสดงว่า xor feedback กลายเป็น XOR gate และ state register เป็น FF
library ieee;
use ieee.std_logic_1164.all;

entity lfsr16 is
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    load  : in  std_logic;
    din   : in  std_logic_vector(15 downto 0);
    q     : out std_logic_vector(15 downto 0)
  );
end entity lfsr16;

architecture rtl of lfsr16 is
  signal s : std_logic_vector(15 downto 0);
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        s <= (others => '0');
      elsif load = '1' then
        s <= din;
      else
        s <= s(14 downto 0) & (s(15) xor s(13) xor s(12) xor s(10));
      end if;
    end if;
  end process;

  q <= s;
end architecture rtl;

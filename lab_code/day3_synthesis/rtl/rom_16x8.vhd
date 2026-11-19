-- rom_16x8.vhd — ตัวอย่างประกอบหัวข้อ 3.8 — ROM 16x8 จาก constant array
-- จุดประสงค์: แสดงว่า array ที่เป็น constant กลายเป็น ROM (กลายเป็น mux tree ใน generic synthesis)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rom_16x8 is
  port (
    addr : in  std_logic_vector(3 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity rom_16x8;

architecture rtl of rom_16x8 is
  type rom_t is array (0 to 15) of std_logic_vector(7 downto 0);
  constant rom : rom_t := (
    0  => x"00", 1  => x"01", 2  => x"04", 3  => x"09",
    4  => x"10", 5  => x"19", 6  => x"24", 7  => x"31",
    8  => x"40", 9  => x"55", 10 => x"6C", 11 => x"85",
    12 => x"A0", 13 => x"B9", 14 => x"D4", 15 => x"FF"
  );
begin
  process (addr)
    variable idx : integer;
  begin
    idx := to_integer(unsigned(addr));
    dout <= rom(idx);
  end process;
end architecture rtl;

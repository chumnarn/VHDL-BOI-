-- mult8.vhd — ตัวอย่างประกอบหัวข้อ 3.8 — unsigned multiplier 8x8
-- จุดประสงค์: แสดงว่า operator * ของ numeric_std กลายเป็น partial-product array
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mult8 is
  port (
    a    : in  std_logic_vector(7 downto 0);
    b    : in  std_logic_vector(7 downto 0);
    p    : out std_logic_vector(15 downto 0)
  );
end entity mult8;

architecture rtl of mult8 is
begin
  p <= std_logic_vector(unsigned(a) * unsigned(b));
end architecture rtl;

-- adder8.vhd — ตัวอย่างประกอบหัวข้อ 3.8 — unsigned adder 8 bit + carry out
-- จุดประสงค์: แสดงว่า unsigned + unsigned กลายเป็น carry chain และการตัดความกว้าง
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder8 is
  port (
    a     : in  std_logic_vector(7 downto 0);
    b     : in  std_logic_vector(7 downto 0);
    sum   : out std_logic_vector(8 downto 0);
    cout  : out std_logic
  );
end entity adder8;

architecture rtl of adder8 is
  signal s : unsigned(8 downto 0);
begin
  s <= resize(unsigned(a), 9) + resize(unsigned(b), 9);

  sum  <= std_logic_vector(s);
  cout <= s(8);
end architecture rtl;

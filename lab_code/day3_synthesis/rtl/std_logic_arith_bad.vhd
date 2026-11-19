-- std_logic_arith_bad.vhd — ตัวอย่างประกอบหัวข้อ 3.8 — ❌ ใช้ ieee.std_logic_arith ซึ่งสังเคราะห์ไม่ได้
-- จุดประสงค์: แสดงข้อความ error จริงจากตัวสังเคราะห์ เมื่อใช้ std_logic_arith
--           ทางแก้คือเปลี่ยนไปใช้ ieee.numeric_std
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity std_logic_arith_bad is
  port (
    a : in  std_logic_vector(7 downto 0);
    b : in  std_logic_vector(7 downto 0);
    s : out std_logic_vector(7 downto 0)
  );
end entity std_logic_arith_bad;

architecture rtl of std_logic_arith_bad is
begin
  s <= a + b;
end architecture rtl;

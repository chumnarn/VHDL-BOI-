-- latch_bad.vhd — ตัวอย่างประกอบหัวข้อ 3.8 — ❌ บั๊ก: if ไม่ครอบทุก path => LATCH
-- จุดประสงค์: ให้ผู้เรียนเห็นว่า synthesis จะสร้าง LATCH จริง (ไม่ใช่แค่คำเตือน)
library ieee;
use ieee.std_logic_1164.all;

entity latch_bad is
  port (
    d : in  std_logic;
    e : in  std_logic;
    q : out std_logic
  );
end entity latch_bad;

architecture rtl of latch_bad is
  signal s : std_logic;
begin
  process (d, e)
  begin
    if e = '1' then
      s <= d;
    end if;
  end process;

  q <= s;
end architecture rtl;

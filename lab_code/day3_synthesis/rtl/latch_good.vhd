-- latch_good.vhd — ตัวอย่างประกอบหัวข้อ 3.8 — ✅ เวอร์ชันที่แก้แล้ว: if ครอบทุก path => ไม่มี latch
-- จุดประสงค์: ใช้เทียบกับ latch_bad.vhd ในรายงาน cell count
library ieee;
use ieee.std_logic_1164.all;

entity latch_good is
  port (
    d : in  std_logic;
    e : in  std_logic;
    q : out std_logic
  );
end entity latch_good;

architecture rtl of latch_good is
  signal s : std_logic;
begin
  process (d, e)
  begin
    if e = '1' then
      s <= d;
    else
      s <= '0';
    end if;
  end process;

  q <= s;
end architecture rtl;

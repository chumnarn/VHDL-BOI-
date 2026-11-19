-- shifter.vhd — ตัวอย่างประกอบหัวข้อ 3.8 — variable shift (barrel shifter)
-- จุดประสงค์: แสดงว่าการเลื่อนด้วยจำนวนบิตที่ไม่คงที่ กลายเป็น mux tree ขนาด log2(N)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity shifter is
  port (
    d     : in  std_logic_vector(7 downto 0);
    shamt : in  std_logic_vector(2 downto 0);
    left  : in  std_logic;
    y     : out std_logic_vector(7 downto 0)
  );
end entity shifter;

architecture rtl of shifter is
begin
  process (d, shamt, left)
    variable vd : std_logic_vector(7 downto 0);
    variable amt : unsigned(2 downto 0);
  begin
    vd := d;
    amt := unsigned(shamt);
    if left = '1' then
      for i in 0 to 7 loop
        if unsigned(amt) > to_unsigned(i, 3) then
          vd := vd(6 downto 0) & '0';
        end if;
      end loop;
    else
      for i in 0 to 7 loop
        if unsigned(amt) > to_unsigned(i, 3) then
          vd := '0' & vd(7 downto 1);
        end if;
      end loop;
    end if;
    y <= vd;
  end process;
end architecture rtl;

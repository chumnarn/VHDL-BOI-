-- alu4.vhd — ตัวอย่างประกอบหัวข้อ 3.8 — Combinational ALU (case + numeric_std arithmetic)
-- จุดประสงค์: แสดงว่า case statement กลายเป็น mux tree และ operator ของ numeric_std
--             กลายเป็น adder / subtractor จริง
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu4 is
  port (
    a     : in  std_logic_vector(3 downto 0);
    b     : in  std_logic_vector(3 downto 0);
    op    : in  std_logic_vector(1 downto 0);
    y     : out std_logic_vector(3 downto 0);
    zero  : out std_logic
  );
end entity alu4;

architecture rtl of alu4 is
begin
  process (a, b, op)
    variable va, vb : unsigned(3 downto 0);
    variable vr     : std_logic_vector(3 downto 0);
  begin
    va := unsigned(a);
    vb := unsigned(b);
    case op is
      when "00"   => vr := std_logic_vector(va + vb);
      when "01"   => vr := std_logic_vector(va - vb);
      when "10"   => vr := std_logic_vector(va and vb);
      when others => vr := std_logic_vector(va or vb);
    end case;
    y <= vr;
  end process;

  zero <= '1' when y = "0000" else '0';
end architecture rtl;

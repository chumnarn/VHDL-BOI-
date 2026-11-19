-- counter_pkg.vhd
-- ตัวอย่างประกอบหัวข้อ 2.7.4 — Protected type และ Shared variable (VHDL-2000)
--
-- กฎของภาษา: shared variable ต้องมีชนิดเป็น PROTECTED TYPE เท่านั้น
--           (นี่คือเหตุผลที่ shared variable ไม่ได้แทนตัวนับธรรมดาได้:
--            ต้องเขียน protected type พร้อมกลไกล็อกให้ถูกต้อง)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package counter_pkg is
    type counter_t is protected
        procedure increment;
        procedure add (n : in integer);
        procedure reset;
        impure function get_value return integer;
    end protected counter_t;
end package counter_pkg;

package body counter_pkg is
    type counter_t is protected body
        variable value : integer := 0;

        procedure increment is
        begin
            value := value + 1;
        end procedure increment;

        procedure add (n : in integer) is
        begin
            value := value + n;
        end procedure add;

        procedure reset is
        begin
            value := 0;
        end procedure reset;

        impure function get_value return integer is
        begin
            return value;
        end function get_value;
    end protected body counter_t;
end package body counter_pkg;

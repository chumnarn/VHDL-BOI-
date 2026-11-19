-- uart_sb_pkg.vhd
-- ตัวอย่างประกอบหัวข้อ 2.7.9 — Scoreboard แบบ in-order queue
--
-- ใช้ protected type เพื่อให้ stimulus process กับ monitor process
-- ส่งค่าคาดหวังผ่านกันได้อย่างปลอดภัย (ไม่มี race)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package uart_sb_pkg is
    type byte_queue_t is protected
        procedure push (v : in integer);
        procedure pop  (v : out integer);
        -- ต้องเป็น impure function เพราะอ่าน state ภายใน protected type
        impure function size return integer;
    end protected byte_queue_t;
end package uart_sb_pkg;

package body uart_sb_pkg is
    type byte_queue_t is protected body
        constant DEPTH : integer := 256;
        type mem_t is array (0 to DEPTH - 1) of integer;
        variable mem  : mem_t := (others => 0);
        variable head : integer := 0;   -- ตำแหน่งที่ push ถัดไป
        variable tail : integer := 0;   -- ตำแหน่งที่ pop ถัดไป
        variable count : integer := 0;

        procedure push (v : in integer) is
        begin
            if count < DEPTH then
                mem(head) := v;
                head := (head + 1) mod DEPTH;
                count := count + 1;
            end if;
        end procedure push;

        procedure pop (v : out integer) is
        begin
            if count > 0 then
                v := mem(tail);
                tail := (tail + 1) mod DEPTH;
                count := count - 1;
            else
                v := -1;   -- สัญญาณว่า queue ว่าง
            end if;
        end procedure pop;

        impure function size return integer is
        begin
            return count;
        end function size;
    end protected body byte_queue_t;
end package body uart_sb_pkg;

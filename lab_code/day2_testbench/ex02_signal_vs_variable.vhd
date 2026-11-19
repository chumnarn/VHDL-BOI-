-- ex02_signal_vs_variable.vhd
-- ตัวอย่างประกอบหัวข้อ 2.7.4 — Signal vs Variable ใน Testbench
--
-- วัตถุประสงค์: พิสูจน์ว่า
--   1) ตัวนับที่เป็น SIGNAL จะรายงาน "ค่าเก่า" เสมอ (false PASS)
--   2) ตัวนับที่เป็น VARIABLE รายงานค่าจริง
--   3) การนับข้าม process ต้องใช้ shared variable ของ protected type
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library work;
use work.counter_pkg.ALL;

entity ex02_signal_vs_variable is
end entity ex02_signal_vs_variable;

architecture sim of ex02_signal_vs_variable is
    constant N : integer := 10;
    signal sig_cnt    : integer := 0;   -- ผิดวิธี
    signal shared_cnt : integer := 0;   -- นับข้าม process
    -- shared variable ต้องเป็น protected type
    shared variable prot_cnt : counter_t;
begin

    ------------------------------------------------------------------
    -- Demo A : ตัวนับ signal vs variable
    ------------------------------------------------------------------
    demo_counter : process
        variable var_cnt : integer := 0;
    begin
        for i in 1 to N loop
            sig_cnt <= sig_cnt + 1;   -- มีผลท้าย delta cycle
            var_cnt := var_cnt + 1;   -- มีผลทันที
        end loop;
        report "[A1] right after loop: var_cnt=" & integer'image(var_cnt) &
               "  sig_cnt=" & integer'image(sig_cnt) &
               "  (signal is still the OLD value)";
        wait for 0 ns;   -- ปล่อยให้ signal ที่ค้างไว้มีผล
        report "[A2] after wait for 0 ns: var_cnt=" & integer'image(var_cnt) &
               "  sig_cnt=" & integer'image(sig_cnt) &
               "  (signal updated, but too late for the summary)";
        wait for 1 ns;
        report "[A3] after wait for 1 ns: sig_cnt=" & integer'image(sig_cnt);
        wait;
    end process demo_counter;

    ------------------------------------------------------------------
    -- Demo B : นับข้าม process ด้วย shared variable (protected type)
    ------------------------------------------------------------------
    shared_block : block
    begin
        process
        begin
            for i in 1 to N loop
                prot_cnt.increment;
                wait for 1 ns;
            end loop;
            report "[B1] protected shared variable = " &
                   integer'image(prot_cnt.get_value);
            wait;
        end process;
    end block shared_block;

    ------------------------------------------------------------------
    -- Demo C : signal นับข้าม process — ทำไมถึง "ไม่มีใครเห็นค่าที่ถูก"
    ------------------------------------------------------------------
    watcher : process (shared_cnt)
    begin
        report "[C1] watcher sees shared_cnt = " & integer'image(shared_cnt);
    end process watcher;

    counter_proc : process
    begin
        for i in 1 to N loop
            shared_cnt <= shared_cnt + 1;
            wait for 1 ns;
        end loop;
        report "[C2] counter_proc finished the loop, shared_cnt = " &
               integer'image(shared_cnt);
        wait;
    end process counter_proc;

end architecture sim;

-- ex03_wait_statements.vhd
-- ตัวอย่างประกอบหัวข้อ 2.7.5 — Wait statement ทั้ง 4 แบบ
--
--   wait for  <time>   : รอเวลา
--   wait until <cond>   : รอจนเงื่อนไขเป็นจริง
--   wait on   <signal>  : รอจน signal ใด signal หนึ่งเปลี่ยน
--   wait;               : หยุด process ถาวร (จบการทำงานของ process)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ex03_wait_statements is
end entity ex03_wait_statements;

architecture sim of ex03_wait_statements is
    -- กำหนด time resolution เป็น 1 ns เพื่อให้ time'image(now) อ่านง่าย
    constant TIME_RES : time := 1 ns;
    signal stim_sig : std_logic := '0';
    signal ack_sig  : std_logic := '0';
    signal done     : boolean := false;
begin

    ------------------------------------------------------------------
    -- Demo A : wait for
    ------------------------------------------------------------------
    demo_wait_for : process
    begin
        report "[A1] t=" & time'image(now) & "  start";
        wait for 12 ns;
        report "[A2] t=" & time'image(now) & "  after wait for 12 ns";
        wait for 3 ns;
        report "[A3] t=" & time'image(now) & "  after wait for 3 ns (total 15 ns)";
        wait;
    end process demo_wait_for;

    ------------------------------------------------------------------
    -- Demo B : wait until
    -- กฎสำคัญ: process ที่มี sensitivity list ห้ามมี wait statement
    --           wait until จึงต้องอยู่ใน process ที่ไม่มี sensitivity list
    ------------------------------------------------------------------
    demo_wait_until : process
    begin
        wait until stim_sig = '1';
        report "[B1] t=" & time'image(now) &
                   "  wait until woke up because stim_sig = '1'";
        done <= true;
        wait until ack_sig = '1';
        report "[B2] t=" & time'image(now) &
               "  wait until woke up because ack_sig = '1'";
    end process demo_wait_until;

    ------------------------------------------------------------------
    -- Demo C : wait on  (คล้าย sensitivity list แต่ทำงานต่อได้)
    ------------------------------------------------------------------
    demo_wait_on : process
    begin
        wait on stim_sig;
        report "[C1] t=" & time'image(now) &
               "  wait on woke up when stim_sig changed -> " &
               std_logic'image(stim_sig);
        wait on ack_sig;
        report "[C2] t=" & time'image(now) &
               "  wait on woke up when ack_sig changed -> " &
               std_logic'image(ack_sig);
        wait;
    end process demo_wait_on;

    ------------------------------------------------------------------
    -- Demo D : wait; = หยุดถาวร
    ------------------------------------------------------------------
    demo_wait_plain : process
    begin
        report "[D1] t=" & time'image(now) & "  before wait;";
        wait;
        report "[D2] this line is never reached";
    end process demo_wait_plain;

    ------------------------------------------------------------------
    -- ตัวขับเคลื่อน: ส่ง stim -> รอ ack
    ------------------------------------------------------------------
    driver : process
    begin
        wait for 5 ns;
        stim_sig <= '1';
        report "[DRV] t=" & time'image(now) & "  drives stim_sig <= '1'";
        wait until done = true;
        ack_sig <= '1';
        report "[DRV] t=" & time'image(now) & "  drives ack_sig <= '1'";
        wait;
    end process driver;

    finisher : process
    begin
        wait for 40 ns;
        report "[END] t=" & time'image(now) & "  done";
        std.env.stop;
    end process finisher;

end architecture sim;

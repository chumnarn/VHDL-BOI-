-- ex01_delta_cycle.vhd
-- ตัวอย่างประกอบหัวข้อ 2.7.3 — Simulation Cycle และ Delta Cycle ของ VHDL
--
-- วัตถุประสงค์: พิสูจน์ว่า "การอ่าน signal คือการอ่านค่าของ cycle ก่อนหน้า"
-- และว่า delta cycle ไม่ใช่เวลา (now ไม่เดินในระหว่าง delta cycle)
--
-- หมายเหตุ: ข้อความใน report string ต้องเป็น ASCII เท่านั้น
--           (VHDL string literal ใช้ character set แบบ Latin-1 รองรับภาษาไทยไม่ได้)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ex01_delta_cycle is
end entity ex01_delta_cycle;

architecture sim of ex01_delta_cycle is
    -- กำหนด time resolution เป็น 1 ns เพื่อให้ time'image(now) อ่านง่าย
    constant TIME_RES : time := 1 ns;
    -- Demo A/B: signal ที่ process เดียวกันเขียนและอ่าน
    signal sig_a : std_logic := '0';
    -- Demo C: สัญญาณจับคู่ระหว่าง process
    signal ping : std_logic := '0';
    signal pong : std_logic := '0';
begin

    ------------------------------------------------------------------
    -- Demo A + B : variable vs signal และผลของ wait for 0 ns
    ------------------------------------------------------------------
    demo_ab : process
        variable v : std_logic := '0';
    begin
        -- (A1) ตัวแปร (variable) เปลี่ยนค่าทันที
        v := '1';
        report "[A1] t=" & time'image(now) &
               "  after v := '1'      -> v=" & std_logic'image(v) &
               "  (immediate)";
        wait for 0 ns;

        -- (A2) signal เปลี่ยนค่าท้าย delta cycle ไม่ใช่ทันที
        sig_a <= '1';
        report "[A2] t=" & time'image(now) &
               "  after sig_a <= '1'  -> sig_a=" & std_logic'image(sig_a) &
               "  (OLD value!)";
        wait for 0 ns;
        report "[B1] t=" & time'image(now) &
               "  after wait for 0 ns  -> sig_a=" & std_logic'image(sig_a) &
               "  (NEW value, same time)";
        wait for 1 ns;
        report "[B2] t=" & time'image(now) &
               "  after wait for 1 ns  -> sig_a=" & std_logic'image(sig_a);
        wait;
    end process demo_ab;

    ------------------------------------------------------------------
    -- Demo C : chain ข้าม process — ทุก event เกิดที่ now เดียวกัน
    --           แต่คนละ delta cycle
    ------------------------------------------------------------------
    stage1 : process
    begin
        wait for 10 ns;
        ping <= '1';
        report "[C1] t=" & time'image(now) & "  stage1 drives ping <= '1'";
        wait;
    end process stage1;

    stage2 : process (ping)
    begin
        if ping = '1' then
            pong <= '1';
            report "[C2] t=" & time'image(now) &
                   "  stage2 wakes (ping), drives pong <= '1'" &
                   "  -> same now, different delta cycle";
        end if;
    end process stage2;

    stage3 : process (pong)
    begin
        if pong = '1' then
            report "[C3] t=" & time'image(now) &
                   "  stage3 wakes (pong) -> 3-stage chain done" &
                   " with 0 ns of time elapsed";
        end if;
    end process stage3;

end architecture sim;

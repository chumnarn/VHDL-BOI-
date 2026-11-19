-- ex05_procedure_checker.vhd
-- ตัวอย่างประกอบหัวข้อ 2.7.7 — Procedure / Function ใน Testbench
--
-- วัตถุประสงค์: แสดงรูปแบบที่ถูกต้องของ
--   1) procedure ที่ประกาศใน architecture เข้าถึง signal ของ architecture ได้โดยตรง
--   2) procedure ที่มี wait ข้างใน เรียกได้จาก process ที่ไม่มี sensitivity list เท่านั้น
--   3) procedure แบบ inout สะสมผลตรวจใน record
--   4) impure function
--   5) ใช้ package ร่วม tb_support_pkg
--
-- ข้อจำกัดของภาษา (พบจริงจากการรัน): VHDL ไม่อนุญาตให้ใช้แอตทริบิวต์
--   'EVENT / rising_edge() กับ formal parameter ของ subprogram
--   -> ต้องอ้างถึง signal จริงใน scope เสมอ
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library work;
use work.tb_support_pkg.ALL;

entity ex05_procedure_checker is
end entity ex05_procedure_checker;

architecture sim of ex05_procedure_checker is
    constant CLK_PERIOD : time := 10 ns;
    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal din      : std_logic := '0';
    signal detected : std_logic;

    ------------------------------------------------------------------
    -- procedure ที่ประกาศใน architecture declarative part
    -- จึงอ้างถึง signal clk ของ architecture ได้โดยตรง
    -- (ถ้าประกาศใน process แล้วส่ง clk เป็น parameter จะใช้ 'event ไม่ได้)
    ------------------------------------------------------------------
    procedure wait_cycles (n : in integer) is
    begin
        for i in 1 to n loop
            wait until rising_edge(clk);
        end loop;
    end procedure wait_cycles;

begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.seq_det_moore
        port map (clk => clk, rst => rst, din => din, detected => detected);

    stim : process
        variable result : check_result_t := EMPTY_RESULT;

        -- procedure แบบ inout สะสมผลตรวจใน record
        procedure check_bit (got      : in  std_logic;
                             expected : in  std_logic;
                             tag      : in  string;
                             r        : inout check_result_t) is
        begin
            if got = expected then
                r.passed := r.passed + 1;
            else
                r.failed := r.failed + 1;
                report "FAIL " & tag & ": got " & std_logic'image(got) &
                       " expected " & std_logic'image(expected)
                    severity error;
            end if;
        end procedure check_bit;

        -- impure function: อ่านค่าจาก scope นอก (pure function ทำไม่ได้)
        impure function is_high (s : std_logic) return boolean is
        begin
            return s = '1';
        end function is_high;

    begin
        rst <= '1';
        din <= '0';
        wait for 2 * CLK_PERIOD;
        rst <= '0';

        wait_cycles(1);

        -- Moore FSM: detected เป็น output ที่ register ไว้
        -- จึงต้องตรวจหลัง rising edge เสมอ
        din <= '1'; wait_cycles(1); wait for 1 ns;
        check_bit(detected, '0', "after 1", result);

        din <= '0'; wait_cycles(1); wait for 1 ns;
        check_bit(detected, '0', "after 10", result);

        din <= '1'; wait_cycles(1); wait for 1 ns;
        check_bit(detected, '1', "after 101", result);

        if is_high(detected) then
            report "[F1] impure function works (detected = '1')";
        else
            report "[F2] impure function returned the wrong value";
        end if;

        report_result("ex05_procedure_checker", result);
        std.env.stop;
    end process stim;
end architecture sim;

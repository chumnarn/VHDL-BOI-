-- ex09_assertion_severity.vhd
-- ตัวอย่างประกอบหัวข้อ 2.7.11 — Assertion และ Severity level
--
-- วัตถุประสงค์: พิสูจน์ผลของ severity ต่อ exit code ของ simulator
--   รันด้วย -gLEVEL=0 (note) / 1 (warning) / 2 (error) / 3 (failure)
--   แล้วดู exit code ที่ได้
--
-- ข้อควรระวัง: ข้อความใน report string ต้องเป็น ASCII เท่านั้น
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ex09_assertion_severity is
    generic (
        LEVEL : integer := 0   -- 0=note 1=warning 2=error 3=failure
    );
end entity ex09_assertion_severity;

architecture sim of ex09_assertion_severity is
    signal clk   : std_logic := '0';
    signal dummy : std_logic := '0';
begin
    clk <= not clk after 5 ns;

    stim : process
    begin
        wait for 10 ns;
        case LEVEL is
            when 0 =>
                report "severity NOTE: informational message" severity note;
            when 1 =>
                report "severity WARNING: abnormal but not fatal"
                    severity warning;
            when 2 =>
                report "severity ERROR: an error was detected" severity error;
            when others =>
                report "severity FAILURE: test failed, stop the simulation"
                    severity failure;
        end case;
        -- ต้องหยุด simulation ด้วย ไม่งั้นนาฬิกาจะวิ่งต่อไปเรื่อย ๆ
        -- (กรณี severity failure simulator จะหยุดให้ก่อนบรรทัดนี้)
        std.env.stop;
        wait;
    end process stim;
end architecture sim;

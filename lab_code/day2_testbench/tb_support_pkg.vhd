-- tb_support_pkg.vhd
-- ตัวอย่างประกอบหัวข้อ 2.7.7 — TB support package (เครื่องมือร่วมที่ reuse ได้)
--
-- แนวทาง: ย้าย "เครื่องมือที่ใช้ซ้ำ" ออกจาก testbench ไปไว้ใน package
--         แล้วใช้ work.tb_support_pkg.ALL ในทุก testbench
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package tb_support_pkg is

    -- แปลงเวลาเป็นหน่วย ns เพื่อให้ข้อความในรายงานอ่านง่าย
    -- (time'image(now) จะพิมพ์เป็นหน่วยของ time resolution ของ simulator
    --  ซึ่งต่างกันไปตามเครื่องมือ: GHDL เริ่มที่ 1 fs, Questa ที่ 1 ps)
    function time_to_ns (t : time) return string;

    -- ผลการตรวจแบบ self-checking
    type check_result_t is record
        passed : integer;
        failed : integer;
    end record;

    constant EMPTY_RESULT : check_result_t := (passed => 0, failed => 0);

    -- รายงานผลและเลือก severity ตามผล (failure = ทำให้ CI เห็นว่า fail)
    procedure report_result (name : in string; r : in check_result_t);

    -- เปรียบเทียบ std_logic_vector สองตัว พร้อมรายงานค่าที่ต่างกัน
    procedure check_vector (got : in std_logic_vector;
                            expected : in std_logic_vector;
                            tag : in string;
                            r : inout check_result_t);

    -- แปลง std_logic_vector เป็น integer (unsigned)
    function slv_to_int (v : std_logic_vector) return integer;

end package tb_support_pkg;

package body tb_support_pkg is

    function time_to_ns (t : time) return string is
    begin
        return integer'image(integer(t / 1 ns)) & " ns";
    end function time_to_ns;

    procedure report_result (name : in string; r : in check_result_t) is
        constant msg : string := name &
                       "  PASS=" & integer'image(r.passed) &
                       "  FAIL=" & integer'image(r.failed);
    begin
        if r.failed = 0 then
            report msg severity note;
        else
            -- severity failure ทำให้ simulator จบด้วย exit code ไม่เป็นศูนย์
            -- จึงใช้ใน regression ได้โดยไม่ต้อง parse ข้อความ log
            report msg severity failure;
        end if;
    end procedure report_result;

    procedure check_vector (got : in std_logic_vector;
                            expected : in std_logic_vector;
                            tag : in string;
                            r : inout check_result_t) is
    begin
        if got = expected then
            r.passed := r.passed + 1;
        else
            r.failed := r.failed + 1;
            report "FAIL " & tag &
                   " got=" & integer'image(slv_to_int(got)) &
                   " expected=" & integer'image(slv_to_int(expected))
                severity error;
        end if;
    end procedure check_vector;

    function slv_to_int (v : std_logic_vector) return integer is
        variable acc : integer := 0;
    begin
        for i in v'range loop
            acc := acc * 2;
            if v(i) = '1' then
                acc := acc + 1;
            end if;
        end loop;
        return acc;
    end function slv_to_int;

end package body tb_support_pkg;

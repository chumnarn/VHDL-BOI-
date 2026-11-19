-- ex08_file_io.vhd
-- ตัวอย่างประกอบหัวข้อ 2.7.10 — File I/O ด้วย STD.TEXTIO
--
-- วัตถุประสงค์: แสดงการ
--   1) อ่าน test vector จากไฟล์ (hread อ่านเลขฐาน 16)
--   2) เขียนรายงานผลการทดสอบลงไฟล์ (write / writeline)
--   3) path ของไฟล์สัมพัทธ์กับ working directory ของ simulator
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
library work;
use work.tb_support_pkg.ALL;

entity ex08_file_io is
    generic (
        VECTOR_FILE : string  := "vectors/tb_vectors.txt";
        REPORT_FILE  : string  := "reports/ex08_report.txt"
    );
end entity ex08_file_io;

architecture sim of ex08_file_io is
    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal ce  : std_logic := '0';
    signal cnt : unsigned(7 downto 0);
begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.counter8
        port map (clk => clk, rst => rst, ce => ce, cnt => cnt);

    stim : process
        file    vec_file : text open read_mode  is VECTOR_FILE;
        file    rep_file : text open write_mode is REPORT_FILE;
        variable l       : line;
        variable v_bits  : bit_vector(7 downto 0);
        variable v       : integer;
        variable n_read  : integer := 0;
        variable expected: integer := 0;
        variable result  : check_result_t := EMPTY_RESULT;

        -- ข้อควรระวัง: hread จะ fail (assertion failure) ถ้าข้อความในบรรทัด
        -- ไม่ใช่เลขฐาน 16 เช่นบรรทัด comment ที่ขึ้นต้นด้วย "--"
        -- จึงต้องข้ามบรรทัดที่ไม่ใช่เลขฐาน 16 ก่อน
        function is_hex_digit (c : character) return boolean is
        begin
            return (c >= '0' and c <= '9') or
                   (c >= 'A' and c <= 'F') or
                   (c >= 'a' and c <= 'f');
        end function is_hex_digit;
    begin
        rst <= '1';
        wait for 2 * CLK_PERIOD;
        rst <= '0';

        -- ---------------- อ่าน test vector ----------------
        -- ข้อควรระวัง: ในแพ็กเกจมาตรฐาน IEEE.TEXTIO มี HREAD เฉพาะชนิด
        -- BIT_VECTOR เท่านั้น (ไม่มี overload สำหรับ INTEGER)
        -- จึงต้องอ่านเป็น bit_vector แล้วแปลงเอง
        -- (ถ้าใช้ IEEE.STD_LOGIC_TEXTIO จะมี hread สำหรับ integer/unsigned ให้)
        while not endfile(vec_file) loop
            readline(vec_file, l);
            if l'length > 0 and is_hex_digit(l(l'low)) then
                hread(l, v_bits);                 -- อ่านเป็นเลขฐาน 16
                v := 0;
                for i in v_bits'range loop
                    v := v * 2 + bit'pos(v_bits(i));
                end loop;
                n_read := n_read + 1;

                ce <= '1' when (v mod 2) = 1 else '0';
                wait until rising_edge(clk);
                wait for 1 ns;

                if (v mod 2) = 1 then
                    expected := expected + 1;
                end if;

                if to_integer(cnt) /= expected then
                    result.failed := result.failed + 1;
                else
                    result.passed := result.passed + 1;
                end if;
            end if;
        end loop;

        -- ---------------- เขียนรายงาน ----------------
        write(l, string'("ex08_file_io report"));
        writeline(rep_file, l);
        write(l, string'("--------------------"));
        writeline(rep_file, l);
        write(l, string'("vectors read : "));
        write(l, n_read);
        writeline(rep_file, l);
        write(l, string'("passed       : "));
        write(l, result.passed);
        writeline(rep_file, l);
        write(l, string'("failed       : "));
        write(l, result.failed);
        writeline(rep_file, l);
        write(l, string'("final count  : "));
        write(l, to_integer(cnt));
        writeline(rep_file, l);

        report "[F1] vectors read = " & integer'image(n_read) &
               "  passed = " & integer'image(result.passed) &
               "  failed = " & integer'image(result.failed);
        report "[F2] report written to " & REPORT_FILE;

        report_result("ex08_file_io", result);
        std.env.stop;
    end process stim;
end architecture sim;

-- ex06_random_stimulus.vhd
-- ตัวอย่างประกอบหัวข้อ 2.7.8 — Random stimulus ที่ทำซ้ำได้ (reproducible)
--
-- วัตถุประสงค์: แสดงว่า
--   1) ใช้ ieee.math_real.uniform โดยกำหนด seed คงที่ -> ได้ลำดับเดิมทุกครั้ง
--   2) เปลี่ยน seed -> ได้ลำดับใหม่
--   3) ใช้ reference model (นับเองใน TB) ตรวจว่า DUT ตรงกับที่คาด
--   4) checksum ของลำดับสุ่ม ถ้าออกเหมือนเดิมทุกครั้ง = reproducible
--
-- ข้อควรระวัง: VHDL ไม่แยกตัวพิมพ์เล็กใหญ่ -> ชื่อ generic SEED_VALUE
--           กับตัวแปร rng_seed ต้องไม่ชนกัน
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
library work;
use work.tb_support_pkg.ALL;

entity ex06_random_stimulus is
    generic (
        SEED_VALUE : integer := 12345;   -- เปลี่ยนค่านี้เพื่อทดสอบลำดับใหม่
        N_VECTORS  : integer := 200
    );
end entity ex06_random_stimulus;

architecture sim of ex06_random_stimulus is
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
        variable rng_seed1 : integer := SEED_VALUE;
        variable rng_seed2 : integer := SEED_VALUE + 1;
        variable x         : real;
        variable bit_v     : integer;
        variable expected  : integer := 0;   -- reference model
        variable checksum  : integer := 0;
        variable result    : check_result_t := EMPTY_RESULT;
    begin
        rst <= '1';
        wait for 2 * CLK_PERIOD;
        rst <= '0';

        for i in 1 to N_VECTORS loop
            -- สุ่มค่าในช่วง (0,1)
            -- ข้อควรระวัง: IEEE.MATH_REAL แบบมาตรฐานใช้ UNIFORM 2 seed
            --   procedure UNIFORM(variable SEED1, SEED2 : inout POSITIVE;
            --                      variable X : out REAL);
            -- (บาง vendor library มีแบบ seed เดียว ต้องตรวจก่อนใช้ทุกครั้ง)
            uniform(rng_seed1, rng_seed2, x);
            if x < 0.5 then
                bit_v := 0;
            else
                bit_v := 1;
            end if;

            -- modulus ต้องเล็กพอที่ checksum*31 จะไม่ล้น integer (max 2147483647)
            -- ถ้าล้น GHDL จะหยุด simulation ด้วย "overflow detected"
            checksum := (checksum * 31 + bit_v) mod 1000003;

            ce <= '1' when bit_v = 1 else '0';
            wait until rising_edge(clk);
            wait for 1 ns;

            -- reference model: นับเองว่าควรเป็นเท่าไร
            if bit_v = 1 then
                expected := expected + 1;
            end if;

            if to_integer(cnt) /= expected then
                result.failed := result.failed + 1;
                if result.failed = 1 then
                    report "MISMATCH at vector " & integer'image(i) &
                           " got=" & integer'image(to_integer(cnt)) &
                           " expected=" & integer'image(expected)
                        severity error;
                end if;
            else
                result.passed := result.passed + 1;
            end if;
        end loop;

        report "[R1] seed=" & integer'image(SEED_VALUE) &
               "  vectors=" & integer'image(N_VECTORS) &
               "  checksum=" & integer'image(checksum) &
               "  final count=" & integer'image(to_integer(cnt));
        report "[R2] re-run with the same seed and the checksum must match";

        report_result("ex06_random_stimulus", result);
        std.env.stop;
    end process stim;
end architecture sim;

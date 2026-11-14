-- adder8.vhd
-- 8-bit adder (combinational) สำหรับ Lab 3B - Yosys / LibreLane
--
-- Yosys อ่าน Verilog ได้โดยตรง แต่ไม่อ่าน VHDL
-- ต้องใช้ GHDL front-end แปลง VHDL เป็น Verilog ก่อน
-- (ดู scripts/ghdl_to_verilog.sh)
--
-- ไฟล์นี้เป็น "สะพาน" ให้นักเรียนที่เขียน VHDL ได้นำ RTL เดิม
-- ไปเข้า Yosys / LibreLane ได้ โดยไม่ต้องเขียนซ้ำเป็น Verilog

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder8 is
    port (
        cin  : in  std_logic;
        a    : in  std_logic_vector(7 downto 0);
        b    : in  std_logic_vector(7 downto 0);
        sum  : out std_logic_vector(7 downto 0);
        cout : out std_logic
    );
end entity adder8;

architecture rtl of adder8 is
begin
    p : process (cin, a, b)
        variable va : unsigned(8 downto 0);
        variable vb : unsigned(8 downto 0);
        variable vs : unsigned(8 downto 0);
    begin
        -- ใช้ resize() เพื่อให้ทั้งสอง operand ยาว 9 บิตเท่ากัน
        -- (unsigned กับ std_logic_vector เป็นคนละ base type - ห้าม assign ข้ามกัน)
        va := resize(unsigned(a), 9);
        vb := resize(unsigned(b), 9);
        vs := va + vb;
        if cin = '1' then
            vs := vs + 1;
        end if;

        sum  <= std_logic_vector(vs(7 downto 0));
        cout <= vs(8);
    end process;
end architecture rtl;

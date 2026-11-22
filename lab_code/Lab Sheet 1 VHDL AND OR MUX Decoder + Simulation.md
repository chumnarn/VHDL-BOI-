# Lab Sheet 1: VHDL AND/OR/MUX/Decoder + Simulation

Nov 22, 2026 · @Chumnarn Punyasai

เมื่อจบแลปนี้ ผู้เรียนจะมีโมดูล VHDL 4 ตัว (AND, OR, MUX 2-to-1, Decoder 2-to-4) ที่ผ่าน self-checking testbench ครบ 21 assertions โดยไม่มีค่า X หรือ U ในผลลัพธ์

## ข้อมูลแลป

| หัวข้อ | รายละเอียด |
| --- | --- |
| เวลา | 1.5–2 ชั่วโมง |
| ระดับ | เริ่มต้น (Beginner) |
| เครื่องมือ | Questa Advanced Simulator หรือ ModelSim (Siemens EDA), VS Code หรือ Notepad |
| มาตรฐานภาษา | VHDL-2008 (ใช้ `process (all)` และ `std.env.stop`) |
| สิ่งที่ต้องส่ง | ไฟล์ `.vhd` 5 ไฟล์, `run_lab1.do`, ภาพ waveform 1 ภาพ, ภาพ Transcript ที่มีข้อความ PASSED, ตารางบันทึกผลใน Part 8 |

### วัตถุประสงค์การเรียนรู้

1. อธิบายโครงสร้างไฟล์ VHDL: library, entity, architecture
2. เขียนวงจร combinational ได้ทั้งแบบ dataflow (concurrent) และ behavioral (process)
3. ป้องกันการเกิด latch ด้วย default assignment และ `when others`
4. เขียน self-checking testbench ด้วย procedure และ `assert`
5. Compile และ simulate ใน Questa ได้ทั้งแบบ GUI และ batch mode

### ความรู้พื้นฐานที่ควรมี

- Boolean algebra และ truth table ของ AND, OR
- หลักการของ multiplexer และ decoder
- การใช้ command line เบื้องต้น (PowerShell)

### ลำดับงานในแลป

| Part | งาน | เวลาโดยประมาณ |
| --- | --- | --- |
| 0 | เตรียมโฟลเดอร์และไฟล์ | 10 นาที |
| 1–4 | เขียนโมดูล AND, OR, MUX, Decoder | 30 นาที |
| 5 | เขียน testbench | 20 นาที |
| 6 | Compile และ simulate ใน GUI | 20 นาที |
| 7 | รันแบบ batch mode | 10 นาที |
| 8 | ตรวจผลและบันทึก | 15 นาที |
| Bonus | Challenge เพิ่มเติม | ตามเวลาที่เหลือ |

## Part 0: เตรียมโฟลเดอร์และไฟล์ (10 นาที)

**เป้าหมาย:** มีโฟลเดอร์ `lab1_work` ที่มีไฟล์ว่าง 5 ไฟล์ และเรียก `vsim` ได้จาก PowerShell

### 0.1 สร้างโฟลเดอร์งาน

1. เปิด PowerShell
2. พิมพ์คำสั่งสร้างโฟลเดอร์และเข้าไปในโฟลเดอร์นั้น

```powershell
mkdir "E:\lab\VHDL(BOI)\lab1_work"
cd "E:\lab\VHDL(BOI)\lab1_work"
```

> ⚠️ **คำเตือน:** path ที่มีวงเล็บ `( )` ต้องครอบด้วยเครื่องหมายคำพูด เพราะ PowerShell ตีความวงเล็บเป็น expression ถ้าเลือกได้ ให้ใช้ path ที่ไม่มีช่องว่างและไม่มีวงเล็บ เช่น `E:\lab\vhdl_boi\lab1_work` จะลดปัญหากับ Tcl ใน Questa ด้วย

### 0.2 สร้างไฟล์ว่าง 5 ไฟล์

| ไฟล์ | ใช้สำหรับ |
| --- | --- |
| `and_gate.vhd` | AND gate 2 อินพุต |
| `or_gate.vhd` | OR gate 2 อินพุต |
| `mux2x1.vhd` | Multiplexer 2-to-1 |
| `dec2x4.vhd` | Decoder 2-to-4 |
| `tb_lab1.vhd` | Testbench รวมทุกโมดูล |

1. พิมพ์คำสั่งนี้ใน PowerShell (`ni` คือ New-Item)

```powershell
ni and_gate.vhd, or_gate.vhd, mux2x1.vhd, dec2x4.vhd, tb_lab1.vhd
```

2. พิมพ์ `ls` เพื่อดูว่ามีครบ 5 ไฟล์

> 💡 **เคล็ดลับ:** จะสร้างใน VS Code ก็ได้ โดยเปิดโฟลเดอร์ด้วย **File → Open Folder** แล้วกด **New File** ทีละไฟล์ ติดตั้ง extension สำหรับ VHDL จะได้ syntax highlight

### 0.3 ตรวจว่าเรียก Questa/ModelSim ได้

1. พิมพ์คำสั่ง

```powershell
where.exe vsim
```

2. ดูผลลัพธ์ ควรได้ path ของ `vsim.exe` เช่น

```text
C:\Siemens\modelsim_dlx64_2026.1\win64pe\vsim.exe
```

> ⚠️ **คำเตือน:** ใน PowerShell คำว่า `where` เป็น alias ของ `Where-Object` จะไม่แสดงอะไร ต้องพิมพ์ `where.exe` หรือ `Get-Command vsim`

ถ้าไม่พบ `vsim` ให้เปิด Questa/ModelSim จาก Start Menu แทน หรือเพิ่มโฟลเดอร์ที่มี `vsim.exe` เข้าไปใน PATH

> ✅ **จุดตรวจสอบ:** มีไฟล์ครบ 5 ไฟล์ และคำสั่ง `where.exe vsim` แสดง path

## Part 1: AND Gate แบบ Dataflow (10 นาที)

**เป้าหมาย:** เขียน entity `and_gate` ที่ให้ `y = a AND b` ด้วย concurrent signal assignment

| `a` | `b` | `y` |
| --- | --- | --- |
| 0 | 0 | 0 |
| 0 | 1 | 0 |
| 1 | 0 | 0 |
| 1 | 1 | 1 |

### ขั้นตอน

1. เปิดไฟล์ `and_gate.vhd`
2. พิมพ์โค้ดต่อไปนี้ (แนะนำให้พิมพ์เองแทนการ copy เพื่อจำโครงสร้าง)

```vhdl
-- ============================================================
-- File: and_gate.vhd
-- Lab 1 - 2-input AND gate
-- Style: Dataflow (concurrent signal assignment)
-- ============================================================

-- (1) Library clause: เรียกใช้ชนิด std_logic
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- (2) Entity: กำหนดขา I/O
entity and_gate is
    port (
        a, b : in  std_logic;    -- อินพุต 1 บิต 2 ขา
        y    : out std_logic     -- เอาต์พุต 1 บิต
    );
end entity and_gate;

-- (3) Architecture: กำหนดพฤติกรรม
architecture dataflow of and_gate is
begin
    -- ประเมินใหม่ทุกครั้งที่ a หรือ b เปลี่ยน
    y <= a and b;
end architecture dataflow;
```

3. บันทึกไฟล์ด้วย `Ctrl + S`
4. ตรวจ syntax ด้วยตาตามรายการนี้
   - ทุก `entity` ปิดด้วย `end entity`
   - ทุก `architecture` ปิดด้วย `end architecture`
   - ทุก statement ปิดด้วย `;` ยกเว้นบรรทัดสุดท้ายใน `port ( ... )` ซึ่งต้องไม่มี `;`
   - ไม่ตั้งชื่อ signal ซ้ำกับคำสงวน เช่น `signal`, `variable`, `type`, `case`, `if`, `for`, `loop`, `end`, `process`, `entity`, `architecture`, `begin`, `then`, `else`, `when`

> 📝 **หมายเหตุ:** ไฟล์ VHDL ทุกไฟล์มี 3 ส่วนนี้เสมอ: library (ใช้ชนิดข้อมูลอะไร), entity (ภายนอกมีขาอะไร), architecture (ภายในทำงานอย่างไร)

> ✅ **จุดตรวจสอบ:** ไฟล์มีทั้ง 3 ส่วน และชื่อ entity ตรงกับชื่อที่ใช้ใน `end entity and_gate;`

## Part 2: OR Gate แบบ Dataflow (5 นาที)

**เป้าหมาย:** เขียน entity `or_gate` โดยใช้โครงสร้างเดียวกับ AND gate

| `a` | `b` | `y` |
| --- | --- | --- |
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 1 |

### ขั้นตอน

1. เปิดไฟล์ `or_gate.vhd`
2. พิมพ์โค้ด

```vhdl
-- ============================================================
-- File: or_gate.vhd
-- Lab 1 - 2-input OR gate
-- Style: Dataflow
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity or_gate is
    port (
        a, b : in  std_logic;
        y    : out std_logic
    );
end entity or_gate;

architecture dataflow of or_gate is
begin
    y <= a or b;
end architecture dataflow;
```

3. บันทึกไฟล์
4. เปิดไฟล์ `and_gate.vhd` เทียบกัน แล้วสังเกตว่าต่างกันแค่ชื่อ entity และ operator (`and` → `or`)

> ✅ **จุดตรวจสอบ:** ทั้งสองไฟล์ใช้ architecture ชื่อ `dataflow` และมีขาชื่อ `a`, `b`, `y` เหมือนกัน

## Part 3: MUX 2-to-1 แบบ Behavioral (10 นาที)

**เป้าหมาย:** เขียน MUX ที่ส่ง `a` ออกเมื่อ `sel = '0'` และส่ง `b` ออกเมื่อ `sel = '1'` โดยใช้ `process` กับ `case`

| `sel` | `y` |
| --- | --- |
| 0 | `a` |
| 1 | `b` |

### ขั้นตอน

1. เปิดไฟล์ `mux2x1.vhd`
2. พิมพ์โค้ด

```vhdl
-- ============================================================
-- File: mux2x1.vhd
-- Lab 1 - 2-to-1 Multiplexer
-- Style: Behavioral (process)
-- Truth Table:
--   sel | y
--   ----+---
--    0  | a
--    1  | b
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux2x1 is
    port (
        a, b : in  std_logic;
        sel  : in  std_logic;
        y    : out std_logic
    );
end entity mux2x1;

architecture rtl of mux2x1 is
begin
    -- sensitivity list ต้องมีอินพุตทุกตัวที่ process อ่าน
    process (a, b, sel)
    begin
        case sel is
            when '0'    => y <= a;
            when '1'    => y <= b;
            when others => y <= 'X';  -- ครอบคลุมค่า U, X, Z, W, L, H, -
        end case;
    end process;
end architecture rtl;
```

3. บันทึกไฟล์

### ทำไมต้องมี `when others`

- `std_logic` มี 9 ค่า (`U X 0 1 Z W L H -`) แต่ `case` ใน VHDL ต้องครอบคลุมทุกค่า ถ้าไม่มี `when others` จะ compile ไม่ผ่าน
- การกำหนด `y` ในทุกแขนง (รวม `others`) ทำให้เป็นวงจร combinational ล้วน เครื่องมือ synthesis จะไม่สร้าง latch
- ใน simulation ถ้า `sel = 'U'` (ยังไม่ initialize) จะเข้า `others` และได้ `y = 'X'` ช่วยให้เห็นปัญหาได้ง่ายใน waveform

### ทางเลือก: เขียนแบบ Dataflow

ผลเหมือนกัน แต่ไม่ต้องใช้ process (conditional signal assignment)

```vhdl
architecture dataflow of mux2x1 is
begin
    y <= a when sel = '0' else
         b when sel = '1' else
         'X';
end architecture dataflow;
```

> ⚠️ **คำเตือน:** ถ้าใส่ architecture นี้ไว้ในไฟล์เดียวกับ `rtl` testbench ที่เรียก `entity work.mux2x1` โดยไม่ระบุชื่อ architecture จะใช้ตัวที่ compile ทีหลังสุด ให้ระบุให้ชัด เช่น `entity work.mux2x1(rtl)`

### ตัวอย่างเปรียบเทียบ: `if ... else` กับ `process (all)`

ตัวอย่างนี้ใช้ชื่อขา `d0`, `d1` และชื่อ entity `mux2to1` จึงเป็นไฟล์แยก (`mux2to1.vhd`) ไม่ได้ใช้ใน `tb_lab1`

| `sel` | `y` |
| --- | --- |
| 0 | `d0` |
| 1 | `d1` |

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity mux2to1 is
    port (
        d0, d1 : in  std_logic;
        sel    : in  std_logic;
        y      : out std_logic
    );
end entity mux2to1;

architecture rtl of mux2to1 is
begin
    mux_logic : process (all)   -- VHDL-2008: อ่านอะไรก็ sensitive ต่อสิ่งนั้น
    begin
        if sel = '0' then
            y <= d0;
        else
            y <= d1;
        end if;
    end process mux_logic;
end architecture rtl;
```

- `process (all)` ทำให้ process ทำงานใหม่เมื่อ `d0`, `d1` หรือ `sel` เปลี่ยน ไม่ต้องเขียน sensitivity list เอง
- ทั้งสองแขนงกำหนดค่า `y` ครบ จึงไม่เกิด latch
- ต่างจากแบบ `case`: ถ้า `sel` เป็น `'X'` หรือ `'U'` จะเข้า `else` และส่ง `d1` ออกไป ทำให้มองไม่เห็นปัญหา `sel` ไม่ได้ initialize ใน simulation

> ✅ **จุดตรวจสอบ:** `mux2x1.vhd` มี architecture `rtl` ที่มี `when others` และใน sensitivity list มี `a, b, sel` ครบ

## Part 4: Decoder 2-to-4 แบบ Behavioral (10 นาที)

**เป้าหมาย:** เขียน decoder ที่มี enable แบบ active-high เอาต์พุตเป็น one-hot เมื่อ `en = '1'` และเป็น `"0000"` เมื่อ `en = '0'`

| `en` | `a(1)` | `a(0)` | `y(3)` | `y(2)` | `y(1)` | `y(0)` |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | x | x | 0 | 0 | 0 | 0 |
| 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| 1 | 0 | 1 | 0 | 0 | 1 | 0 |
| 1 | 1 | 0 | 0 | 1 | 0 | 0 |
| 1 | 1 | 1 | 1 | 0 | 0 | 0 |

### ขั้นตอน

1. เปิดไฟล์ `dec2x4.vhd`
2. พิมพ์โค้ด

```vhdl
-- ============================================================
-- File: dec2x4.vhd
-- Lab 1 - 2-to-4 Decoder with active-high enable
-- en='0' -> y = "0000"
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity dec2x4 is
    port (
        en : in  std_logic;
        a  : in  std_logic_vector(1 downto 0);
        y  : out std_logic_vector(3 downto 0)
    );
end entity dec2x4;

architecture rtl of dec2x4 is
begin
    process (en, a)
    begin
        -- (1) Default assignment: กำหนดค่าให้ y ก่อนเสมอ
        y <= (others => '0');

        -- (2) เมื่อ enable จึงถอดรหัส a
        if en = '1' then
            case a is
                when "00"   => y <= "0001";
                when "01"   => y <= "0010";
                when "10"   => y <= "0100";
                when "11"   => y <= "1000";
                when others => y <= (others => '0');
            end case;
        end if;
    end process;
end architecture rtl;
```

3. บันทึกไฟล์

### จุดที่ควรสังเกต

- `a` เป็น `std_logic_vector(1 downto 0)` (2 บิต) และ `y` เป็น `std_logic_vector(3 downto 0)` (4 บิต) บิตซ้ายสุดคือ MSB
- `y <= (others => '0')` คือ aggregate ที่กำหนดทุกบิตเป็น 0 ไม่ต้องนับความกว้างเอง
- Default assignment ที่ต้น process ทำให้ `y` มีค่าเสมอแม้ `en = '0'` (ซึ่ง `if` ไม่มี `else`) จึงไม่เกิด latch
- ใน process ค่าที่ assign ทีหลังสุดเป็นตัวที่มีผล ดังนั้นค่าใน `case` จะทับค่า default
- `en` ทำหน้าที่เปิด/ปิดการทำงาน ใช้บ่อยในการเลือก chip หรืออุปกรณ์บน bus

> ✅ **จุดตรวจสอบ:** ความกว้าง vector ในทุก `when` ตรงกับพอร์ต (`a` = 2 บิต, `y` = 4 บิต)

## Part 5: Testbench ทดสอบทุกโมดูล (20 นาที)

**เป้าหมาย:** เขียน self-checking testbench ที่ป้อน input แล้วตรวจ output เองด้วย `assert` รวม 21 กรณี

### โครงสร้าง testbench

1. **Entity ไม่มี port** เพราะเป็นชั้นบนสุดของ simulation
2. **Signals** เป็นสายที่ต่อเข้ากับ DUT (Design Under Test) สัญญาณอินพุตต้องมีค่าเริ่มต้น เช่น `:= '0'` เพื่อไม่ให้เป็น `'U'`
3. **DUT instantiation** ใช้ `entity work.<ชื่อ>` (direct instantiation) ไม่ต้องประกาศ component
4. **Stimulus process** กำหนดค่า รอ 10 ns แล้วเรียก procedure ตรวจผล
5. **Procedure** แยกตามโมดูล (`check_and`, `check_or`, `check_mux`, `check_dec`) แต่ละตัวใช้ `assert` และนับ `pass_cnt`

### ขั้นตอน

1. เปิดไฟล์ `tb_lab1.vhd`
2. พิมพ์โค้ด

```vhdl
-- ============================================================
-- File: tb_lab1.vhd
-- Lab 1 - Testbench for AND, OR, MUX, Decoder
-- Pattern: self-checking with assert
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;     -- ต้องมี เพราะ check_dec ใช้ unsigned / to_integer

entity tb_lab1 is
    -- testbench ไม่มี port
end entity tb_lab1;

architecture sim of tb_lab1 is
    -- ============ Signals เชื่อมต่อ DUT ============
    signal a, b     : std_logic := '0';
    signal sel      : std_logic := '0';
    signal en       : std_logic := '0';
    signal a_dec    : std_logic_vector(1 downto 0) := "00";

    signal y_and    : std_logic;
    signal y_or     : std_logic;
    signal y_mux    : std_logic;
    signal y_dec    : std_logic_vector(3 downto 0);
begin

    -- ============ DUT Instantiation ============
    u_and : entity work.and_gate
        port map (a => a, b => b, y => y_and);

    u_or : entity work.or_gate
        port map (a => a, b => b, y => y_or);

    u_mux : entity work.mux2x1(rtl)
        port map (a => a, b => b, sel => sel, y => y_mux);

    u_dec : entity work.dec2x4
        port map (en => en, a => a_dec, y => y_dec);

    -- ============ Stimulus + Checker ============
    stim : process
        variable pass_cnt : integer := 0;   -- นับจำนวนกรณีที่ผ่าน

        procedure check_and(a_v, b_v : std_logic; exp : std_logic) is
        begin
            assert y_and = exp
                report "AND FAIL: a=" & std_logic'image(a_v) &
                       " b=" & std_logic'image(b_v) &
                       " got=" & std_logic'image(y_and) &
                       " exp=" & std_logic'image(exp)
                severity failure;
            pass_cnt := pass_cnt + 1;
        end procedure;

        procedure check_or(a_v, b_v : std_logic; exp : std_logic) is
        begin
            assert y_or = exp
                report "OR FAIL: a=" & std_logic'image(a_v) &
                       " b=" & std_logic'image(b_v) &
                       " got=" & std_logic'image(y_or) &
                       " exp=" & std_logic'image(exp)
                severity failure;
            pass_cnt := pass_cnt + 1;
        end procedure;

        procedure check_mux(a_v, b_v, sel_v : std_logic; exp : std_logic) is
        begin
            assert y_mux = exp
                report "MUX FAIL: a=" & std_logic'image(a_v) &
                       " b=" & std_logic'image(b_v) &
                       " sel=" & std_logic'image(sel_v) &
                       " got=" & std_logic'image(y_mux) &
                       " exp=" & std_logic'image(exp)
                severity failure;
            pass_cnt := pass_cnt + 1;
        end procedure;

        procedure check_dec(en_v : std_logic;
                            a_v  : std_logic_vector(1 downto 0);
                            exp  : std_logic_vector(3 downto 0)) is
        begin
            assert y_dec = exp
                report "DEC FAIL: en=" & std_logic'image(en_v) &
                       " a="   & integer'image(to_integer(unsigned(a_v))) &
                       " got=" & integer'image(to_integer(unsigned(y_dec))) &
                       " exp=" & integer'image(to_integer(unsigned(exp)))
                severity failure;
            pass_cnt := pass_cnt + 1;
        end procedure;
    begin
        -- ===== Test 1: AND gate (4 patterns) =====
        report "========== Test 1: AND gate ==========" severity note;
        a <= '0'; b <= '0'; wait for 10 ns;  check_and(a, b, '0');
        a <= '0'; b <= '1'; wait for 10 ns;  check_and(a, b, '0');
        a <= '1'; b <= '0'; wait for 10 ns;  check_and(a, b, '0');
        a <= '1'; b <= '1'; wait for 10 ns;  check_and(a, b, '1');

        -- ===== Test 2: OR gate (4 patterns) =====
        report "========== Test 2: OR gate ==========" severity note;
        a <= '0'; b <= '0'; wait for 10 ns;  check_or(a, b, '0');
        a <= '0'; b <= '1'; wait for 10 ns;  check_or(a, b, '1');
        a <= '1'; b <= '0'; wait for 10 ns;  check_or(a, b, '1');
        a <= '1'; b <= '1'; wait for 10 ns;  check_or(a, b, '1');

        -- ===== Test 3: MUX (5 patterns) =====
        report "========== Test 3: MUX ==========" severity note;
        a <= '0'; b <= '0'; sel <= '0'; wait for 10 ns;  check_mux(a, b, sel, '0');
        a <= '1'; b <= '0'; sel <= '0'; wait for 10 ns;  check_mux(a, b, sel, '1');
        a <= '0'; b <= '1'; sel <= '1'; wait for 10 ns;  check_mux(a, b, sel, '1');
        a <= '1'; b <= '1'; sel <= '1'; wait for 10 ns;  check_mux(a, b, sel, '1');
        a <= '1'; b <= '0'; sel <= '1'; wait for 10 ns;  check_mux(a, b, sel, '0');

        -- ===== Test 4: Decoder (8 patterns) =====
        report "========== Test 4: Decoder ==========" severity note;
        en <= '0';   -- disabled: ต้องได้ "0000" ทุก pattern
        a_dec <= "00"; wait for 10 ns;  check_dec(en, a_dec, "0000");
        a_dec <= "01"; wait for 10 ns;  check_dec(en, a_dec, "0000");
        a_dec <= "10"; wait for 10 ns;  check_dec(en, a_dec, "0000");
        a_dec <= "11"; wait for 10 ns;  check_dec(en, a_dec, "0000");

        en <= '1';   -- enabled: one-hot
        a_dec <= "00"; wait for 10 ns;  check_dec(en, a_dec, "0001");
        a_dec <= "01"; wait for 10 ns;  check_dec(en, a_dec, "0010");
        a_dec <= "10"; wait for 10 ns;  check_dec(en, a_dec, "0100");
        a_dec <= "11"; wait for 10 ns;  check_dec(en, a_dec, "1000");

        -- ===== Summary =====
        report "========================================";
        report "Lab 1 PASSED: " & integer'image(pass_cnt) & " assertions";
        report "========================================";
        std.env.stop;   -- VHDL-2008: หยุด simulation
    end process;

end architecture sim;
```

3. บันทึกไฟล์

### จุดที่แก้จากคู่มือต้นฉบับ

| จุด | ต้นฉบับ | ใน Lab Sheet นี้ | เหตุผล |
| --- | --- | --- | --- |
| Library | มีแค่ `STD_LOGIC_1164` | เพิ่ม `use IEEE.NUMERIC_STD.ALL;` | `unsigned` และ `to_integer` อยู่ใน `NUMERIC_STD` ถ้าไม่มีจะ compile ไม่ผ่าน |
| จำนวน assertions | 22 | 21 | AND 4 + OR 4 + MUX 5 + Decoder 8 = 21 |
| ตัวแปร `fail_cnt` | ประกาศไว้แต่ไม่ได้ใช้ | ตัดออก (ใช้ใน Bonus A) | `severity failure` หยุด simulation ทันที จึงไม่มีโอกาสนับ fail |
| MUX instance | `entity work.mux2x1` | `entity work.mux2x1(rtl)` | กันการเลือก architecture ผิดตัวถ้าใส่ `dataflow` ไว้ด้วย |

### ลำดับเวลาของการทดสอบ

แต่ละ pattern ใช้ 10 ns รวม 21 pattern = **210 ns** ใช้ตารางนี้หาตำแหน่งใน waveform

| Test | ช่วงเวลา (ns) | จำนวน pattern |
| --- | --- | --- |
| 1: AND | 0–40 | 4 |
| 2: OR | 40–80 | 4 |
| 3: MUX | 80–130 | 5 |
| 4: Decoder (en=0) | 130–170 | 4 |
| 4: Decoder (en=1) | 170–210 | 4 |

> 💡 **เคล็ดลับ:** ตรวจผลหลัง `wait for 10 ns` เสมอ เพราะ signal ที่ assign ด้วย `<=` จะเปลี่ยนค่าหลัง process หยุดรอเท่านั้น ถ้าตรวจทันทีจะได้ค่าเก่า

> ✅ **จุดตรวจสอบ:** มี `use IEEE.NUMERIC_STD.ALL;` และชื่อ entity ใน `entity work.xxx` ตรงกับไฟล์ design ทั้ง 4 ไฟล์

## Part 6: Compile และ Simulate ใน Questa แบบ GUI (20 นาที)

**เป้าหมาย:** compile ทั้ง 5 ไฟล์ได้ 0 errors และเห็นข้อความ `Lab 1 PASSED: 21 assertions` ใน Transcript

### 6.1 สร้าง Project

1. เปิด Questa จาก Start Menu
2. เลือก **File → New → Project**
3. กรอก **Project Name** = `lab1_vhdl`
4. กำหนด **Project Location** = โฟลเดอร์ `lab1_work`
5. กำหนด **Default Library Name** = `work`
6. กด **OK**

&#91;Screenshot: หน้าต่าง Create Project ที่กรอกครบ 3 ช่อง\]

### 6.2 เพิ่มไฟล์เข้า Project

1. ในหน้าต่าง Add items เลือก **Add Existing File** (หรือเมนู **Project → Add to Project → Existing File...**)
2. กด **Browse** แล้วเลือกทั้ง 5 ไฟล์ด้วย `Ctrl + click`
3. กด **Open** แล้ว **OK**
4. ดูแท็บ **Project** ไฟล์ทั้งหมดจะมีสถานะ `?` (ยังไม่ compile)

### 6.3 ตั้งค่า VHDL-2008

โค้ดใช้ `process (all)` และ `std.env.stop` ซึ่งมีเฉพาะใน VHDL-2008 ถ้าไม่ตั้งค่านี้ `tb_lab1.vhd` อาจ compile ไม่ผ่าน

1. เลือกทั้ง 5 ไฟล์ในแท็บ **Project**
2. คลิกขวา → **Properties...**
3. เปิดแท็บ **VHDL**
4. เลือก **Use 1076-2008** แล้วกด **OK**

### 6.4 Compile

1. เลือกเมนู **Compile → Compile Order...** แล้วกด **Auto Generate** เพื่อให้ compile ไฟล์ design ก่อน testbench
2. เลือกเมนู **Compile → Compile All** (หรือคลิกขวาที่ไฟล์ใดก็ได้ → **Compile → Compile All**)
3. ดู Transcript ด้านล่าง ควรเห็นประมาณนี้

```text
# Compile of and_gate.vhd was successful.
# Compile of or_gate.vhd was successful.
# Compile of mux2x1.vhd was successful.
# Compile of dec2x4.vhd was successful.
# Compile of tb_lab1.vhd was successful.
# 5 compiles, 0 failed with no errors.
```

4. ตรวจว่าสถานะทุกไฟล์เปลี่ยนเป็นเครื่องหมายถูกสีเขียว

> ⚠️ **คำเตือน:** ถ้ามีไฟล์ที่ขึ้น `X` สีแดง ให้ดับเบิลคลิกข้อความ error สีแดงใน Transcript เพื่อกระโดดไปบรรทัดที่ผิด แล้วดูตาราง Troubleshooting ท้ายเอกสาร

### 6.5 เริ่ม Simulation

1. เลือกเมนู **Simulate → Start Simulation...**
2. ในแท็บ **Design** ขยาย `work` แล้วเลือก `tb_lab1`
3. ตั้งค่า optimization ให้มองเห็น signal ทุกตัว (ชื่อตัวเลือกต่างกันตามรุ่น)
   - ถ้ามีช่อง **Enable optimization** ให้กด **Optimization Options...** แล้วเลือก **Apply full visibility to all modules (full debug mode)**
   - หรือเอาเครื่องหมาย **Enable optimization** ออก
4. กด **OK**
5. ดูว่ามีแท็บ **sim** และหน้าต่าง **Objects** แสดง signal ของ `tb_lab1`

> 💡 **เคล็ดลับ:** เทียบเท่ากับพิมพ์ `vsim -voptargs=+acc work.tb_lab1` ใน Transcript

### 6.6 เพิ่ม Signal เข้า Wave Window

1. คลิกขวาที่ `tb_lab1` ในแท็บ **sim**
2. เลือก **Add Wave** (หรือ **Add to → Wave → All items in region**)
3. ตรวจว่า Wave มี `a`, `b`, `sel`, `en`, `a_dec`, `y_and`, `y_or`, `y_mux`, `y_dec`

หรือพิมพ์ใน Transcript:

```tcl
add wave sim:/tb_lab1/*
```

### 6.7 รัน Simulation

1. พิมพ์ใน Transcript แล้วกด Enter

```tcl
run -all
```

2. รอจน simulation หยุดที่ 210 ns (จะมีข้อความ `Break in Process stim` จาก `std.env.stop` ซึ่งเป็นเรื่องปกติ)
3. ใน Wave window กด **Zoom Full** (ปุ่มแว่นขยาย หรือกด `F` ขณะอยู่ใน Wave) เพื่อดูทั้งช่วง

> ⚠️ **คำเตือน:** คู่มือต้นฉบับใช้ `run 200 ns` ซึ่งสั้นกว่า 210 ns ที่ testbench ต้องใช้ จะหยุดก่อน check สุดท้ายและไม่เห็นข้อความ PASSED ให้ใช้ `run -all` หรืออย่างน้อย `run 250 ns`

### 6.8 อ่านผลใน Transcript

```text
# ** Note: ========== Test 1: AND gate ==========
# ** Note: ========== Test 2: OR gate ==========
# ** Note: ========== Test 3: MUX ==========
# ** Note: ========== Test 4: Decoder ==========
# ** Note: ========================================
# ** Note: Lab 1 PASSED: 21 assertions
# ** Note: ========================================
```

แต่ละบรรทัดจะมี `Time: ... ns  Iteration: ...  Instance: /tb_lab1` ต่อท้ายด้วย

### 6.9 ปิด Simulation

1. พิมพ์ `quit -sim` เพื่อปิด simulation แต่คง Questa ไว้ (ใช้เมื่อจะแก้โค้ดแล้ว compile ใหม่)
2. หรือพิมพ์ `quit -f` เพื่อปิด Questa ทั้งโปรแกรม

> ✅ **จุดตรวจสอบ:** Transcript แสดง `Lab 1 PASSED: 21 assertions` และไม่มีข้อความ `** Failure` เก็บภาพ Transcript และ waveform ไว้ส่ง

## Part 7: รันแบบ Batch Mode (10 นาที)

**เป้าหมาย:** รัน compile + simulate ทั้งหมดด้วยคำสั่งเดียว โดยไม่ต้องคลิก GUI เหมาะกับการรันซ้ำหลังแก้โค้ด

### 7.1 สร้างไฟล์ `run_lab1.do`

1. สร้างไฟล์ใหม่ชื่อ `run_lab1.do` ในโฟลเดอร์ `lab1_work`
2. พิมพ์เนื้อหา

```tcl
# ============================================================
# run_lab1.do - Questa batch script for Lab 1
# Usage (PowerShell): vsim -c -do run_lab1.do
# Usage (Questa GUI): do run_lab1.do
# ============================================================

# ถ้า compile พลาด ให้ออกพร้อม exit code 1
onerror {quit -f -code 1}
# เมื่อ std.env.stop หยุด simulation ให้ script ทำต่อ
onbreak {resume}

# Step 1: สร้าง working library
vlib work

# Step 2: Compile (VHDL-2008) เรียง design ก่อน testbench
vcom -2008 -work work and_gate.vhd
vcom -2008 -work work or_gate.vhd
vcom -2008 -work work mux2x1.vhd
vcom -2008 -work work dec2x4.vhd
vcom -2008 -work work tb_lab1.vhd

# Step 3: Header
puts ""
puts "============================================="
puts "Lab 1: VHDL AND/OR/MUX/Decoder + Simulation"
puts "============================================="

# Step 4: Load และ run
vsim -voptargs=+acc work.tb_lab1
run -all
quit -f
```

3. บันทึกไฟล์

> 📝 **หมายเหตุ:** ต้นฉบับใช้ `vsim -do "run 1 us; quit -f" work.tb_lab1` ซ้อนอยู่ใน do file เวอร์ชันนี้แยกเป็น `vsim` / `run -all` / `quit -f` อ่านง่ายกว่าและหยุดตามเวลาจริงของ testbench

### 7.2 รัน script

**วิธี A: ใน Questa GUI**

1. เลือกเมนู **Tools → Tcl → Execute Macro...** แล้วเลือก `run_lab1.do` หรือพิมพ์ `do run_lab1.do` ใน Transcript

> ⚠️ **คำเตือน:** บรรทัด `quit -f` จะปิด Questa ด้วย ถ้ารันใน GUI แล้วอยากดู waveform ต่อ ให้แก้บรรทัดสุดท้ายเป็น `add wave sim:/tb_lab1/*` และย้ายไปไว้ก่อน `run -all`

**วิธี B: ใน PowerShell (แนะนำ)**

1. เข้าโฟลเดอร์งาน

```powershell
cd "E:\lab\VHDL(BOI)\lab1_work"
```

2. รัน script แบบไม่เปิด GUI (`-c` = command-line mode)

```powershell
vsim -c -do run_lab1.do
```

3. ดูผลลัพธ์ ควรมีบรรทัดเหล่านี้

```text
# ** Note: Lab 1 PASSED: 21 assertions
# Errors: 0, Warnings: 0
```

4. ตรวจ exit code ด้วย `$LASTEXITCODE` ค่า `0` หมายถึงผ่าน

> ✅ **จุดตรวจสอบ:** รัน `vsim -c -do run_lab1.do` แล้วเห็น `PASSED: 21 assertions` โดยไม่ต้องเปิด GUI

## Part 8: ตรวจและบันทึกผล (15 นาที)

**เป้าหมาย:** อ่านค่าจาก waveform เอง แล้วเทียบกับ truth table ไม่พึ่งแค่ข้อความ PASSED

### 8.1 บันทึกผลจาก waveform

1. วาง cursor ใน Wave window ที่เวลาตามคอลัมน์แรก (กลางช่วงของแต่ละ pattern)
2. อ่านค่า output แล้วกรอกคอลัมน์ "ค่าที่อ่านได้"
3. กรอก ✓ ถ้าตรงกับค่าที่คาดหวัง

| เวลา (ns) | โมดูล | Input | ค่าที่คาดหวัง | ค่าที่อ่านได้ | ตรง? |
| --- | --- | --- | --- | --- | --- |
| 5 | AND | a=0 b=0 | `y_and`=0 |  |  |
| 15 | AND | a=0 b=1 | `y_and`=0 |  |  |
| 25 | AND | a=1 b=0 | `y_and`=0 |  |  |
| 35 | AND | a=1 b=1 | `y_and`=1 |  |  |
| 45 | OR | a=0 b=0 | `y_or`=0 |  |  |
| 55 | OR | a=0 b=1 | `y_or`=1 |  |  |
| 65 | OR | a=1 b=0 | `y_or`=1 |  |  |
| 75 | OR | a=1 b=1 | `y_or`=1 |  |  |
| 85 | MUX | a=0 b=0 sel=0 | `y_mux`=0 |  |  |
| 95 | MUX | a=1 b=0 sel=0 | `y_mux`=1 |  |  |
| 105 | MUX | a=0 b=1 sel=1 | `y_mux`=1 |  |  |
| 115 | MUX | a=1 b=1 sel=1 | `y_mux`=1 |  |  |
| 125 | MUX | a=1 b=0 sel=1 | `y_mux`=0 |  |  |
| 135–165 | DEC | en=0, a\_dec=00..11 | `y_dec`=0000 |  |  |
| 175 | DEC | en=1 a\_dec=00 | `y_dec`=0001 |  |  |
| 185 | DEC | en=1 a\_dec=01 | `y_dec`=0010 |  |  |
| 195 | DEC | en=1 a\_dec=10 | `y_dec`=0100 |  |  |
| 205 | DEC | en=1 a\_dec=11 | `y_dec`=1000 |  |  |

> 💡 **เคล็ดลับ:** คลิกขวาที่ `y_dec` ใน Wave → **Radix → Binary** เพื่อดูเป็นบิต และกดเครื่องหมาย `+` หน้าชื่อเพื่อกางดูทีละบิต

### 8.2 Validation checklist

- [ ] `y_and` = 1 เฉพาะเมื่อ a=1 และ b=1
- [ ] `y_or` = 1 เมื่อ a=1 หรือ b=1
- [ ] `y_mux` ตาม a เมื่อ sel=0 และตาม b เมื่อ sel=1
- [ ] `y_dec` = 0000 ตลอดช่วง en=0
- [ ] `y_dec` เป็น one-hot (0001, 0010, 0100, 1000) ตาม a\_dec เมื่อ en=1
- [ ] ไม่มี `'X'` หรือ `'U'` (เส้นสีแดง) ใน output หลังเวลา 0 ns
- [ ] Transcript แสดง `PASSED: 21 assertions` และไม่มี `** Failure`

### 8.3 เมื่อ test ล้มเหลว

ถ้า assert ไม่ผ่าน simulation จะหยุดทันที และ Transcript จะแสดงประมาณนี้

```text
# ** Failure: AND FAIL: a='1' b='1' got='0' exp='1'
#    Time: 40 ns  Iteration: 0  Process: /tb_lab1/stim
```

1. อ่านเวลาที่พัง (`Time:`) แล้วเทียบกับตารางลำดับเวลาใน Part 5 ว่าเป็น test ไหน
2. ดับเบิลคลิกข้อความ Failure เพื่อกระโดดไปบรรทัดใน source
3. ตรวจ operator ใน design (`and`, `or`, `xor`, `not`)
4. ตรวจ sensitivity list ว่ามีอินพุตครบ
5. ตรวจค่าคาดหวัง (`exp`) ใน testbench ว่าเขียนถูกตาม truth table
6. ดู signal ภายใน DUT: คลิกขวา instance เช่น `u_and` ในแท็บ **sim** → **Add Wave** แล้วพิมพ์ `restart -f` ตามด้วย `run -all`
7. แก้โค้ด บันทึก compile ใหม่ แล้วรันซ้ำ

> ✅ **จุดตรวจสอบ:** ตาราง 8.1 ตรงครบทุกแถว และทุกข้อใน 8.2 ถูกติ๊ก

## Troubleshooting

| อาการ / ข้อความ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| `Unknown identifier "std_logic"` | ไม่มี `use IEEE.STD_LOGIC_1164.ALL;` | เพิ่ม `library IEEE;` และ `use IEEE.STD_LOGIC_1164.ALL;` บนสุดของไฟล์ |
| `Unknown identifier "to_integer"` หรือ `"unsigned"` | ไม่มี `NUMERIC_STD` | เพิ่ม `use IEEE.NUMERIC_STD.ALL;` |
| `std.env` หรือ `process (all)` ไม่รู้จัก | compile เป็น VHDL-93/2002 | compile ด้วย `vcom -2008` หรือตั้ง **Use 1076-2008** (Part 6.3) ถ้าใช้ 2008 ไม่ได้ ให้แทน `std.env.stop;` ด้วย `report "Simulation finished"; wait;` |
| `VHDL Parser expecting ...` / `near "end"` | ลืม `;`, `end`, หรือวงเล็บไม่ครบ หรือใส่ `;` หลังพอร์ตสุดท้าย | ดูบรรทัดที่แจ้งและบรรทัดก่อนหน้า |
| `Case statement covers only N out of 9 cases` | `case` บน `std_logic` ไม่มี `when others` | เพิ่ม `when others => ...` |
| `Length of expected is 4; length of actual is 2` | ความกว้าง vector ไม่ตรงกัน | ใช้ความกว้างให้ตรง หรือต่อบิต เช่น `y <= "00" & a(1 downto 0);` |
| `Procedure 'check' is ambiguous` | procedure หลายตัวชื่อเดียวกันและ parameter ชนิดเดียวกัน | ตั้งชื่อให้ต่างกัน: `check_and`, `check_or`, `check_mux` |
| `Design unit ... not found` ตอน compile testbench | compile testbench ก่อน design | ใช้ **Compile Order → Auto Generate** หรือ compile ไฟล์ design ก่อน |
| ไม่เห็นข้อความ PASSED | เวลา `run` สั้นกว่า 210 ns | ใช้ `run -all` |
| Wave ไม่มี signal หรือเพิ่มไม่ได้ | optimization ซ่อน signal | เริ่ม sim ด้วย `vsim -voptargs=+acc work.tb_lab1` |
| `'X'` หรือ `'U'` ใน waveform | อินพุตไม่มีค่าเริ่มต้น, มี 2 driver ขับ signal เดียวกัน, หรือพอร์ตไม่ได้ต่อ | ใส่ `:= '0'` ให้ signal อินพุต, ตรวจ port map, ตรวจว่ามีที่เดียวที่ assign signal นั้น |
| คำเตือน `Inferred latch` (ตอน synthesis) | process combinational ไม่ได้ assign output ทุกแขนง | ใส่ default assignment ต้น process หรือเติม `else` (ดูตัวอย่างด้านล่าง) |

### ตัวอย่าง latch: ผิด กับ ถูก

```vhdl
-- ผิด: ไม่มี else → y ต้องจำค่าเดิมเมื่อ sel = '0' → เกิด latch
process (a, b, sel)
begin
    if sel = '1' then
        y <= a;
    end if;
end process;

-- ถูก: ใส่ default ก่อน
process (a, b, sel)
begin
    y <= b;
    if sel = '1' then
        y <= a;
    end if;
end process;
```

> 📝 **หมายเหตุ:** Questa/ModelSim เป็น simulator จะไม่เตือนเรื่อง latch คำเตือนนี้มาจากเครื่องมือ synthesis เช่น Vivado หรือ Quartus จึงต้องเขียนให้ถูกตั้งแต่แรก

## Bonus (ตามเวลาที่เหลือ)

### Bonus A: นับ pass/fail โดยไม่หยุด simulation

`severity failure` หยุดทันทีที่พบข้อผิดตัวแรก ถ้าอยากเห็นข้อผิดทุกตัวในรอบเดียว ให้ใช้ `severity error` และนับเอง

1. เพิ่ม `variable fail_cnt : integer := 0;` ใต้ `pass_cnt` ใน process `stim`
2. แก้ `check_and` (และ procedure อื่นในทำนองเดียวกัน)

```vhdl
procedure check_and(a_v, b_v : std_logic; exp : std_logic) is
begin
    if y_and = exp then
        pass_cnt := pass_cnt + 1;
    else
        fail_cnt := fail_cnt + 1;
        report "AND FAIL: a=" & std_logic'image(a_v) &
               " b=" & std_logic'image(b_v) &
               " got=" & std_logic'image(y_and) &
               " exp=" & std_logic'image(exp)
            severity error;
    end if;
end procedure;
```

3. แทนส่วน Summary ด้วย

```vhdl
report "========================================";
report "PASS: " & integer'image(pass_cnt) & " tests";
report "FAIL: " & integer'image(fail_cnt) & " tests";
if fail_cnt = 0 then
    report "ALL TESTS PASSED" severity note;
else
    report "SOME TESTS FAILED!" severity failure;
end if;
std.env.stop;
```

4. ทดลองแก้ `and_gate.vhd` ให้ผิด (เช่น `y <= a or b;`) แล้วรัน ควรเห็น `FAIL: 2 tests` และ simulation ทำต่อจนจบ
5. แก้กลับให้ถูกต้อง

### Bonus B: Testbench แบบ Direct Input สำหรับ AND gate

testbench แบบง่ายที่สุด: ป้อนค่าทีละคู่ ค้างคู่ละ 10 ns ไม่มี assert ตรวจผลด้วยตาใน Wave window

1. สร้างไฟล์ `tb_and_gate.vhd`

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity tb_and_gate is
end entity tb_and_gate;

architecture sim of tb_and_gate is
    signal a, b : std_logic;
    signal y    : std_logic;
begin
    dut : entity work.and_gate(dataflow)
        port map (a => a, b => b, y => y);

    stimulus : process
    begin
        a <= '0'; b <= '0'; wait for 10 ns;   -- 0 ns:  0 AND 0 = 0
        a <= '0'; b <= '1'; wait for 10 ns;   -- 10 ns: 0 AND 1 = 0
        a <= '1'; b <= '0'; wait for 10 ns;   -- 20 ns: 1 AND 0 = 0
        a <= '1'; b <= '1'; wait for 10 ns;   -- 30 ns: 1 AND 1 = 1
        wait;                                 -- พัก process ที่ 40 ns
    end process stimulus;
end architecture sim;
```

2. รันใน Transcript

```tcl
vlib work
vcom -2008 and_gate.vhd tb_and_gate.vhd
vsim -voptargs=+acc work.tb_and_gate
add wave sim:/tb_and_gate/*
run 40 ns
```

3. ตรวจว่า `y` ขึ้นเป็น `1` ที่ **30 ns** เท่านั้น

| ช่วงเวลา (ns) | `a` | `b` | `y` ที่คาดหวัง |
| --- | --- | --- | --- |
| 0 ถึงก่อน 10 | 0 | 0 | 0 |
| 10 ถึงก่อน 20 | 0 | 1 | 0 |
| 20 ถึงก่อน 30 | 1 | 0 | 0 |
| 30 ถึง 40 | 1 | 1 | 1 |

> 📝 **หมายเหตุ:** ที่เวลา 0 ns จะเห็น `'U'` ช่วงสั้นๆ เพราะ signal ไม่มีค่าเริ่มต้น ค่าจะเปลี่ยนหลัง delta cycle แรก เทียบกับ `tb_lab1` ที่ใส่ `:= '0'` ไว้

### Challenge 1: MUX 4-to-1 จาก MUX 2-to-1 สามตัว

1. สร้างไฟล์ `mux4x1.vhd` ที่มี entity นี้

```vhdl
entity mux4x1 is
    port (
        d0, d1, d2, d3 : in  std_logic;
        sel            : in  std_logic_vector(1 downto 0);
        y              : out std_logic
    );
end entity;
```

2. instantiate `mux2x1` สองตัวเลือกด้วย `sel(0)` และตัวที่สามเลือกผลด้วย `sel(1)` ต้องประกาศ signal ภายใน 2 เส้น
3. เขียน testbench ทดสอบทั้ง 4 ค่าของ `sel`

### Challenge 2: Decoder 3-to-8

```vhdl
entity dec3x8 is
    port (
        en : in  std_logic;
        a  : in  std_logic_vector(2 downto 0);
        y  : out std_logic_vector(7 downto 0)
    );
end entity;
```

ทดสอบแบบ exhaustive: 8 ค่าของ `a` × 2 ค่าของ `en` = 16 กรณี (ลองใช้ `for` loop แทนการเขียนทีละบรรทัด)

### Challenge 3: Binary Encoder 8-to-3

ทำงานตรงข้ามกับ decoder: รับ one-hot 8 บิต แล้วส่งเลขฐานสอง 3 บิต และ `vld = '1'` เมื่อ input เป็น one-hot จริง

```vhdl
entity enc8x3 is
    port (
        en  : in  std_logic;
        a   : in  std_logic_vector(7 downto 0);
        y   : out std_logic_vector(2 downto 0);
        vld : out std_logic
    );
end entity;
```

## คำถามท้ายแลป

1. dataflow style กับ behavioral style ต่างกันอย่างไร ยกตัวอย่างจากแลปนี้อย่างละ 1 ตัว
2. ถ้าลบ `when others` ออกจาก `mux2x1` จะเกิดอะไรขึ้น เพราะอะไร
3. ถ้าลบบรรทัด `y <= (others => '0');` ออกจาก `dec2x4` วงจรที่ได้จาก synthesis จะเปลี่ยนไปอย่างไร
4. ทำไมต้อง `wait for 10 ns` ก่อนเรียก `check_and` ถ้าเรียกทันทีหลัง `a <= ...` จะได้ผลอย่างไร
5. `severity failure` กับ `severity error` ต่างกันอย่างไร ควรใช้แต่ละแบบเมื่อไหร่

## Checklist ก่อนส่งงาน

- [ ] เขียนไฟล์ design 4 ไฟล์ (AND, OR, MUX, Decoder)
- [ ] เขียน testbench `tb_lab1.vhd`
- [ ] Compile ใน Questa ได้ 0 errors
- [ ] Run ใน GUI และเห็น `PASSED: 21 assertions`
- [ ] Run ด้วย `vsim -c -do run_lab1.do` ผ่าน
- [ ] กรอกตาราง 8.1 ครบทุกแถว
- [ ] ตอบคำถามท้ายแลปครบ 5 ข้อ
- [ ] แนบภาพ waveform และ Transcript

ผ่านครบทุกข้อแล้ว พร้อมไปต่อ **Lab 2: ออกแบบ FSM Moore/Mealy + Testbench**

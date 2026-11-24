# Lab 1: Step-by-Step Guide — เขียน VHDL AND/OR/MUX/Decoder + Simulation

> **เวลาใช้งาน:** 1.5–2 ชั่วโมง
> **เครื่องมือ:** Questa Advanced Simulator หรือ ModelSim (Siemens EDA)
> **Output ที่คาดหวัง:** โมดูลตรรกะพื้นฐานที่ simulate ผ่าน ไม่มี X หรือ U ในผลลัพธ์

---

## Step 0: เตรียมโปรเจกต์และไฟล์

### 0.1 สร้าง directory structure

เปิด PowerShell หรือ File Explorer สร้าง directory ดังนี้:

```powershell
# สร้าง folder สำหรับ Lab 1
mkdir E:\lab\VHDL(BOI)\lab1_work
cd E:\lab\VHDL(BOI)\lab1_work
```

หรือใช้ File Explorer:

```
Right-click → New → Folder → ตั้งชื่อ lab1_work
```

### 0.2 สร้างไฟล์ว่าง 5 ไฟล์ ด้วย VS Code / Notepad

| ไฟล์ | ใช้สำหรับ |
| --- | --- |
| `and_gate.vhd` | 2-input AND gate |
| `or_gate.vhd` | 2-input OR gate |
| `mux2x1.vhd` | 2-to-1 Multiplexer |
| `dec2x4.vhd` | 2-to-4 Decoder |
| `tb_lab1.vhd` | Testbench รวมทุกโมดูล |

**วิธีสร้าง (PowerShell):**

```powershell
ni and_gate.vhd, or_gate.vhd, mux2x1.vhd, dec2x4.vhd, tb_lab1.vhd
```

หรือใน VS Code: `File → New File` แล้ว save แต่ละชื่อ

### 0.3 ตรวจสอบ Questa/ModelSim ติดตั้งถูกต้อง

เปิด PowerShell แล้วพิมพ์:

```powershell
where vsim
```

**คาดหวัง:** path ของ vsim.exe เช่น:
```
C:\Siemens\modelsim_dlx64_2026.1\win64pe\vsim.exe
```

ถ้าไม่เจอ → เปิด Questa/ModelSim จาก Start Menu หรือเพิ่ม PATH

---

## Step 1: เขียน AND Gate (Dataflow Style)

### 1.1 เปิดไฟล์ `and_gate.vhd`

ใน VS Code: `File → Open File → and_gate.vhd`

### 1.2 พิมพ์ code ต่อไปนี้

```vhdl
-- ============================================================
-- File: and_gate.vhd
-- Lab 1 - 2-input AND gate
-- Style: Dataflow (concurrent signal assignment)
-- ============================================================

-- 1. Library clause (เรียกใช้ std_logic)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- 2. Entity declaration (I/O ports)
entity and_gate is
    port (
        a, b : in  std_logic;    -- 2 inputs (1-bit)
        y    : out std_logic     -- 1 output (1-bit)
    );
end entity and_gate;

-- 3. Architecture (พฤติกรรม)
architecture dataflow of and_gate is
begin
    -- Concurrent assignment: ทำงานเมื่อ a หรือ b เปลี่ยน
    y <= a and b;
end architecture dataflow;
```

### 1.3 บันทึกไฟล์

- VS Code: `Ctrl + S`
- Notepad: `File → Save`

### 1.4 ตรวจสอบ syntax เบื้องต้น

มองหา:
- ✓ ทุก `entity` มี `end entity`
- ✓ ทุก `architecture` มี `end architecture`
- ✓ มี semicolon (`;`) ปิดทุก statement
- ✓ ไม่มีคำสงวน (reserved word) ผิด

**Reserved word ที่ใช้บ่อย:** `signal`, `variable`, `type`, `case`, `if`, `for`, `loop`, `end`, `process`, `entity`, `architecture`, `begin`, `then`, `else`, `when`

---

## Step 2: เขียน OR Gate (Dataflow Style)

### 2.1 เปิดไฟล์ `or_gate.vhd`

### 2.2 พิมพ์ code

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

### 2.3 บันทึกและเปรียบเทียบกับ AND

สังเกต: ต่างกับ AND gate แค่ **คำสั่ง** (`and` → `or`) เท่านั้น — โครงสร้างเหมือนกัน

---

## Step 3: เขียน 2-to-1 MUX (Behavioral Style)

### 3.1 เปิดไฟล์ `mux2x1.vhd`

### 3.2 พิมพ์ code

```vhdl
-- ============================================================
-- File: mux2x1.vhd
-- Lab 1 - 2-to-1 Multiplexer
-- Style: Behavioral (process)
-- Truth Table:
--   sel  a   b      y
--   0    x   y
--   1    x   y
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
    -- Process ที่ทำงานเมื่อ a, b, หรือ sel เปลี่ยน
    process (a, b, sel)
    begin
        -- ใช้ case เพื่อให้ครบทุกเงื่อนไข
        case sel is
            when '0'       => y <= a;
            when '1'       => y <= b;
            when others    => y <= 'X';  -- ป้องกัน latch
        end case;
    end process;
end architecture rtl;
```

### 3.3 สังเกตที่สำคัญ

- ใส่ `when others => y <= 'X'` เพื่อ **ป้องกัน latch** — ถ้าลืม tool จะเตือน
- `sel = 'U'` (ไม่ initialized) จะ match `when others` ทำให้ tool ไม่สร้าง latch

### 3.4 ทางเลือก: Dataflow style

```vhdl
-- Alternative: dataflow style (ไม่ต้อง process)
architecture dataflow of mux2x1 is
begin
    y <= a when sel = '0' else
         b when sel = '1' else
         'X';
end architecture dataflow;
```

### ตัวอย่างโค้ด 2-to-1 MUX ด้วย `if ... else...` ใน VHDL

2-to-1 Multiplexer เลือกอินพุต `d0` หรือ `d1` ไปยังเอาต์พุต `y` ตามสัญญาณเลือก `sel`

| `sel` | `y` |
|---|---|
| `'0'` | `d0` |
| `'1'` | `d1` |

### `mux2to1.vhd`

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
    mux_logic : process (all)
    begin
        if sel = '0' then
            y <= d0;
        else
            y <= d1;
        end if;
    end process mux_logic;
end architecture rtl;
```

 `process (all)` เป็นไวยากรณ์ VHDL-2008 ที่ทำให้ process ประเมินใหม่เมื่อ `d0`, `d1` หรือ `sel` เปลี่ยน ทั้งสองแขนงกำหนดค่า `y` ครบ จึงสังเคราะห์เป็นวงจร combinational โดยไม่เกิด latch สำหรับ RTL นี้ ถ้า `sel` มีค่าอย่าง `'X'` หรือ `'U'` ใน simulation จะเข้าแขนง `else` เช่นเดียวกับ `'1'`

---

## Step 4: เขียน 2-to-4 Decoder (Behavioral Style)

### 4.1 เปิดไฟล์ `dec2x4.vhd`

### 4.2 พิมพ์ code

```vhdl
-- ============================================================
-- File: dec2x4.vhd
-- Lab 1 - 2-to-4 Decoder with active-high enable
-- Truth Table (en='1'):
--   a(1)  a(0)    y(3) y(2) y(1) y(0)
--   0     0       0    0    0    1
--   0     1       0    0    1    0
--   1     0       0    1    0    0
--   1     1       1    0    0    0
-- en='0' → all outputs = "0000"
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
        -- Default: ปิดใช้งาน → output เป็น 0 ทั้งหมด
        y <= (others => '0');

        -- เมื่อ enable = '1' → ตรวจค่า a
        if en = '1' then
            case a is
                when "00"   => y <= "0001";
                when "01"   => y <= "0010";
                when "10"   => y <= "0100";
                when "11"   => y <= "1000";
                when others => y <= (others => '0');     -- ป้องกัน latch
            end case;
        end if;
    end process;
end architecture rtl;
```

### 4.3 สังเกต

- ใช้ `std_logic_vector(1 downto 0)` สำหรับ a (2 บิต)
- ใช้ `std_logic_vector(3 downto 0)` สำหรับ y (4 บิต)
- **Default assignment** `y <= (others => '0')` ที่จุดเริ่มต้นของ process ป้องกัน latch
- ใช้ `en` (enable) เป็น gate signal — ปกติใช้ใน chip design

---

## Step 5: เขียน Testbench ทดสอบทุกโมดูล

### 5.1 เปิดไฟล์ `tb_lab1.vhd`

### 5.2 พิมพ์ code

```vhdl
-- ============================================================
-- File: tb_lab1.vhd
-- Lab 1 - Testbench for AND, OR, MUX, Decoder
-- Pattern: self-checking with assert
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_lab1 is
    -- testbench ไม่มี port
end entity tb_lab1;

architecture sim of tb_lab1 is
    -- ============ Signals เชื่อมต่อ DUT ============
    signal a, b     : std_logic := '0';
    signal d0, d1     : std_logic := '0';
    signal sel      : std_logic := '0';
    signal en       : std_logic := '0';
    signal a_dec    : std_logic_vector(1 downto 0) := "00";

    signal y_and    : std_logic;
    signal y_or     : std_logic;
    signal y_mux    : std_logic;
    signal y_dec    : std_logic_vector(3 downto 0);
begin

    -- ============ DUT Instantiation ============
    -- 1) AND gate
    u_and : entity work.and_gate
        port map (a => a, b => b, y => y_and);

    -- 2) OR gate
    u_or : entity work.or_gate
        port map (a => a, b => b, y => y_or);

    -- 3) MUX
    u_mux : entity work.mux2to1
        port map (d0 => d0, d1 => d1, sel => sel, y => y_mux);

    -- 4) Decoder
    u_dec : entity work.dec2x4
        port map (en => en, a => a_dec, y => y_dec);

    -- ============ Stimulus + Checker ============
    stim : process
        -- local variable สำหรับนั่ง
        variable pass_cnt : integer := 0;
        variable fail_cnt : integer := 0;

        -- ============================================================
        -- Procedure: ตรวจสอบผลของ AND gate
        -- ============================================================
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

        -- ============================================================
        -- Procedure: ตรวจสอบผลของ OR gate
        -- ============================================================
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

        -- ============================================================
        -- Procedure: ตรวจสอบผลของ MUX
        -- ============================================================
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

        -- ============================================================
        -- Procedure: ตรวจสอบผลของ Decoder
        -- ============================================================
        procedure check_dec(en_v : std_logic; a_v : std_logic_vector(1 downto 0); exp : std_logic_vector(3 downto 0)) is
        begin
            assert y_dec = exp
                report "DEC FAIL: en=" & std_logic'image(en_v) &
                       " a=" & integer'image(to_integer(unsigned(a_v))) &
                       " got=" & integer'image(to_integer(unsigned(y_dec))) &
                       " exp=" & integer'image(to_integer(unsigned(exp)))
                severity failure;
            pass_cnt := pass_cnt + 1;
        end procedure;
    begin
        -- ============================================================
        -- Test 1: AND gate (4 patterns)
        -- ============================================================
        report "========== Test 1: AND gate ==========" severity note;

        a <= '0'; b <= '0'; wait for 10 ns;  check_and(a, b, '0');
        a <= '0'; b <= '1'; wait for 10 ns;  check_and(a, b, '0');
        a <= '1'; b <= '0'; wait for 10 ns;  check_and(a, b, '0');
        a <= '1'; b <= '1'; wait for 10 ns;  check_and(a, b, '1');

        -- ============================================================
        -- Test 2: OR gate (4 patterns)
        -- ============================================================
        report "========== Test 2: OR gate ==========" severity note;

        a <= '0'; b <= '0'; wait for 10 ns;  check_or(a, b, '0');
        a <= '0'; b <= '1'; wait for 10 ns;  check_or(a, b, '1');
        a <= '1'; b <= '0'; wait for 10 ns;  check_or(a, b, '1');
        a <= '1'; b <= '1'; wait for 10 ns;  check_or(a, b, '1');

        -- ============================================================
        -- Test 3: 2-to-1 MUX (4 patterns)
        -- ============================================================
        report "========== Test 3: MUX ==========" severity note;

        a <= '0'; b <= '0'; sel <= '0'; wait for 10 ns;  check_mux(a, b, sel, '0');
        a <= '1'; b <= '0'; sel <= '0'; wait for 10 ns;  check_mux(a, b, sel, '1');
        a <= '0'; b <= '1'; sel <= '1'; wait for 10 ns;  check_mux(a, b, sel, '1');
        a <= '1'; b <= '1'; sel <= '1'; wait for 10 ns;  check_mux(a, b, sel, '1');
        a <= '1'; b <= '0'; sel <= '1'; wait for 10 ns;  check_mux(a, b, sel, '0');

        -- ============================================================
        -- Test 4: 2-to-4 Decoder
        -- ============================================================
        report "========== Test 4: Decoder ==========" severity note;

        -- en=0: output should be "0000" ทุก pattern
        en <= '0';
        a_dec <= "00"; wait for 10 ns;  check_dec(en, a_dec, "0000");
        a_dec <= "01"; wait for 10 ns;  check_dec(en, a_dec, "0000");
        a_dec <= "10"; wait for 10 ns;  check_dec(en, a_dec, "0000");
        a_dec <= "11"; wait for 10 ns;  check_dec(en, a_dec, "0000");

        -- en=1: one-hot encoding
        en <= '1';
        a_dec <= "00"; wait for 10 ns;  check_dec(en, a_dec, "0001");
        a_dec <= "01"; wait for 10 ns;  check_dec(en, a_dec, "0010");
        a_dec <= "10"; wait for 10 ns;  check_dec(en, a_dec, "0100");
        a_dec <= "11"; wait for 10 ns;  check_dec(en, a_dec, "1000");

        -- ============================================================
        -- Summary
        -- ============================================================
        report "========================================";
        report "Lab 1 PASSED: " & integer'image(pass_cnt) & " assertions";
        report "========================================";
        std.env.stop;
    end process;

end architecture sim;
```

### 5.3 บันทึกไฟล์

---

## Step 6: Compile และ Run Simulation ใน Questa (GUI Mode)

### 6.1 เปิด Questa

ดับเบิลคลิกที่ Questa icon หรือ Start Menu → **Questa Advanced Simulator**

### 6.2 สร้าง Project ใหม่

1. **Menu:** `File → New → Project`
3. **Project Name:** `lab1_vhdl`
4. **Project Location:** เลือก folder `E:\lab\VHDL(BOI)\lab1_work` (ที่เราสร้างไว้)
5. **Default library name:** `work`
6. **OK**

หน้าจอจะแสดง Project tab (ซ้าย) และ Transcript (ล่าง)

### 6.3 เพิ่มไฟล์ VHDL เข้า Project

1. **Menu:** `Project → Add to Project → Existing File…`
2. เลือกไฟล์ **5 ไฟล์** ทั้งหมด (กด `Ctrl + click` เลือกทีละไฟล์):
   - `and_gate.vhd`
   - `or_gate.vhd`
   - `mux2x1.vhd`
   - `dec2x4.vhd`
   - `tb_lab1.vhd`
3. **Open**

ตอนนี้ Project tab จะแสดงไฟล์ทั้งหมด พร้อมสถานะ (Compiled/Uncompiled)

### 6.4 Compile ทุกไฟล์

#### วิธี A: คลิกขวาแล้วเลือก Compile All

1. คลิกขวาที่ไฟล์ใดก็ได้ใน Project
3. เลือก **Compile All**

#### วิธี B: ใช้ปุ่ม shortcut

กด **Alt + F9** (คีย์ลัดสำหรับ Compile All)

#### ผลที่คาดหวัง

ใน **Transcript** จะเห็น:
```
vcom -2008 and_gate.vhd or_gate.vhd mux2x1.vhd dec2x4.vhd tb_lab1.vhd
-- Loading package STANDARD
-- Loading package TEXTIO
-- Loading package std_logic_1164
-- Compiling entity and_gate
-- Compiling architecture dataflow of and_gate
-- ...
# **Errors: 0, Warnings: 0**
```

ถ้าเห็น **Errors: 0** แสดงว่าผ่าน

ถ้าเห็น Error: ดูหัวข้อ "Troubleshooting" ที่ท้ายเอกสาร

### 6.5 Load Testbench

1. **Menu:** `Simulate → Start Simulation…`
2. หน้าต่างเปิดขึ้น
3. **แท็บ Design:** ขยาย `work` → จะเห็น `tb_lab1` entity
4. คลิกเลือก `tb_lab1`
5. **แท็บ Optimization:** ตั้งค่า
   - **Optimization Options:** ตั้งให้ `-O0` (ปิด optimization เพื่อ debug)
6. **OK**

ตอนนี้หน้าต่าง Objects จะเปิดขึ้น แสดง signals ทั้งหมด

### 6.6 เพิ่ม Signal เข้า Wave Window

1. **คลิกขวา** ที่ `tb_lab1` ใน **sim** tab (กลาง-บน)
3. เลือก **Add Wave**
4. เลือก:
   - ✅ `a`, `b`, `sel`, `en`, `a_dec`
   - ✅ `y_and`, `y_or`, `y_mux`, `y_dec`

หรือ **คลิกขวาที่ `tb_lab1`** → **Add to Wave → All Signals** (เพิ่มทั้งหมด)

### 6.7 Run Simulation

1. **Transcript** (หน้าต่างล่าง): พิมพ์ `run 200 ns` แล้วกด Enter
3. หรือคลิกปุ่ม **Run** (▶️) ที่ toolbar

### 6.8 ดูผลใน Wave Window

Wave window จะแสดง:
- `a`, `b` สลับค่าตามเวลา
- `y_and` = ผลของ AND gate
- `y_or` = ผลของ OR gate
- `y_mux` = ผลของ MUX
- `y_dec` = ผลของ Decoder

### 6.9 ดู Transcript

ในหน้าต่าง Transcript จะเห็น:
```
# **Note: ========== Test 1: AND gate ==========
# **Note: ========== Test 2: OR gate ==========
# **Note: ========== Test 3: MUX ==========
# **Note: ========== Test 4: Decoder ==========
# **Note: ========================================
# **Note: Lab 1 PASSED: 22 assertions
# **Note: ========================================
```

ถ้าเห็น **PASSED: 22 assertions** แสดงว่าทุกอย่างผ่าน ✅

### 6.10 Quit Simulation

พิมพ์ `quit -f` ใน Transcript

หรือ **Menu:** `File → Quit`

---

## Step 7: Run ใน Batch Mode (สำหรับ reproduce ง่าย)

### 7.1 สร้างไฟล์ script `run_lab1.do`

สร้างไฟล์ชื่อ `run_lab1.do` ใน folder เดียวกัน

**เนื้อหา:**

```tcl
# ============================================================
# run_lab1.do - Questa batch script for Lab 1
# Usage: vsim -do run_lab1.do -c
# Or in Questa: do run_lab1.do
# ============================================================

# Step 1: Create working library
vlib work

# Step 2: Compile all VHDL files (VHDL-2008)
vcom -2008 -work work and_gate.vhd
vcom -2008 -work work or_gate.vhd
vcom -2008 -work work mux2x1.vhd
vcom -2008 -work work dec2x4.vhd
vcom -2008 -work work tb_lab1.vhd

# Step 3: Display header
puts ""
puts "============================================="
puts "Lab 1: VHDL AND/OR/MUX/Decoder + Simulation"
puts "============================================="

# Step 4: Run simulation
vsim -do "run 1 us; quit -f" work.tb_lab1
```

### 7.2 รัน script

#### วิธี A: ใช้ Questa GUI

1. **Menu:** `File → Source → run_lab1.do`
2. หรือพิมพ์ `do run_lab1.do` ใน Transcript

#### วิธี B: ใช้ command line (แนะนำสำหรับ automation)

เปิด PowerShell ใน folder ที่มีไฟล์:

```powershell
cd E:\lab\VHDL(BOI)\lab1_work
vsim -do run_lab1.do -c
```

**ผลที่คาดหวัง:**

```
# Start time: ...
# vcom ... 5 files compiled
# vsim work.tb_lab1
# ...
# **Note: Lab 1 PASSED: 22 assertions
# Errors: 0
```

---

## Step 8: Verify ผลลัพธ์ (Validation Checklist)

ตรวจดูสิ่งเหล่านี้ใน waveform:

| Item | Expected |
| --- | --- |
| `y_and = 1` เฉพาะเมื่อ a=1 และ b=1 | ✅ |
| `y_or = 1` เมื่อ a=1 หรือ b=1 | ✅ |
| `y_mux` เลือก a เมื่อ sel=0, เลือก b เมื่อ sel=1 | ✅ |
| `y_dec = 0001` เมื่อ a=00, en=1 | ✅ |
| `y_dec = 0010` เมื่อ a=01, en=1 | ✅ |
| `y_dec = 0100` เมื่อ a=10, en=1 | ✅ |
| `y_dec = 1000` เมื่อ a=11, en=1 | ✅ |
| ไม่มี `'X'` ปรากฏในผลลัพธ์ | ✅ |
| ไม่มี `'U'` ปรากฏในผลลัพธ์ | ✅ |
| Transcript แสดง "PASSED" และ "0 errors" | ✅ |

---

## Step 9: ขั้นสูง — Debug เมื่อ Test ล้มเหลว

### 9.1 เมื่อ simulation พบ Error

Transcript จะแสดง:

```
# ** Failure: AND FAIL: a=1 b=1 got=0 exp=1
#    Time: 50 ns  Iteration: 1
```

**ขั้นตอน debug:**

1. **คลิกที่ error** เพื่อข้ามไปที่จุดที่เกิด error ใน source code
2. ตรวจสอบ:
   - Operator ถูกต้องหรือไม่? (`and`, `or`, `xor`, `not`)
   - Sensitivity list ครบหรือไม่?
   - Variable และ signal ตรงกันหรือไม่?

### 9.2 ดู Internal Signals

ถ้าต้องการดู signal ภายใน entity:

1. **คลิกขวา** ที่ instance (เช่น `u_and`) ใน **sim** tab
2. **Add to Wave → All Signals**
3. **Run** อีกครั้ง

### 9.3 เปรียบเทียบ RTL กับ Wave

- วาด **truth table** ขึ้นมาเทียบกับ waveform
- ตรวจดูว่าทุก combination ตรงกัน

---

## Step 10: Bonus — สร้าง Self-checking testbench แบบสมบูรณ์

### 10.1 แก้ testbench เพื่อนับ pass/fail

แทนที่จะใช้ `severity failure` (ที่หยุด simulator) ใช้ `severity error` (ที่นับแต่ไม่หยุด):

```vhdl
-- ใน procedure check_and (ปรับปรุง)
procedure check_and(a, b : std_logic; exp : std_logic) is
    variable result : boolean;
begin
    result := (y_and = exp);
    if result then
        pass_cnt := pass_cnt + 1;
    else
        fail_cnt := fail_cnt + 1;
        report "AND FAIL: a=" & std_logic'image(a) &
               " b=" & std_logic'image(b) &
               " got=" & std_logic'image(y_and) &
               " exp=" & std_logic'image(exp)
            severity error;
    end if;
end procedure;
```

### 10.2 แสดงสรุป

```vhdl
-- ท้าย process stim
report "========================================";
report "PASS: " & integer'image(pass_cnt) & " tests";
report "FAIL: " & integer'image(fail_cnt) & " tests";
if fail_cnt = 0 then
    report "ALL TESTS PASSED" severity note;
else
    report "SOME TESTS FAILED!" severity failure;
end if;
```
---
### ตัวอย่าง `tb_and_gate.vhd` — Testbench แบบ Direct Input

กำหนดค่า `a` และ `b` โดยตรงใน `stimulus` process ครบทั้ง 4 คู่ ค้างคู่ละ 10 ns แล้วตรวจ `y` ใน Wave window

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
        port map (
            a => a,
            b => b,
            y => y
        );

    stimulus : process
    begin
        -- 0 ns: 0 AND 0 = 0
        a <= '0';
        b <= '0';
        wait for 10 ns;

        -- 10 ns: 0 AND 1 = 0
        a <= '0';
        b <= '1';
        wait for 10 ns;

        -- 20 ns: 1 AND 0 = 0
        a <= '1';
        b <= '0';
        wait for 10 ns;

        -- 30 ns: 1 AND 1 = 1
        a <= '1';
        b <= '1';
        wait for 10 ns;

        wait;  -- พัก process ที่เวลา 40 ns
    end process stimulus;
end architecture sim;
```

### รันใน QuestaSim หรือ ModelSim

เปิด Transcript จากโฟลเดอร์ที่มี `and_gate.vhd` และ `tb_and_gate.vhd` แล้วรัน

```tcl
vlib work
vcom -2008 and_gate.vhd tb_and_gate.vhd
vsim work.tb_and_gate
add wave sim:/tb_and_gate/*
run 40 ns
```

| ช่วงเวลา (ns) | `a` | `b` | `y` ที่คาดหวัง |
|---|---:|---:|---:|
| 0 ถึงก่อน 10 | 0 | 0 | 0 |
| 10 ถึงก่อน 20 | 0 | 1 | 0 |
| 20 ถึงก่อน 30 | 1 | 0 | 0 |
| 30 ถึง 40 | 1 | 1 | 1 |

ใน Wave window สัญญาณ `y` ควรขึ้นเป็น `1` ที่ **30 ns** เมื่อ `a` และ `b` เป็น `1` พร้อมกัน หลังจาก simulator ประมวลผล delta cycles ณ เวลานั้นแล้ว

---

## Troubleshooting: Common Errors

### Error 1: `Unknown identifier "STD_LOGIC"`

```
** Error: and_gate.vhd(15): Unknown identifier "std_logic".
```

**สาเหตุ:** ลืม `use IEEE.STD_LOGIC_1164.ALL;`

**Fix:** เพิ่มบรรทัดนี้ที่ด้านบน:

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
```

### Error 2: `Expected entity, architecture, ...`

```
** Error: and_gate.vhd(10): VHDL Parser expecting 'entity'.
```

**สาเหตุ:** ลืม `end entity;` หรือวงเล็บไม่ครบ

**Fix:** ตรวจดู syntax ทุก entity/architecture

### Error 3: `Inferred latch`

```
** Warning: and_gate.vhd: Inferred latch for signal "y".
```

**สาเหตุ:** ใน combinational process, output ไม่ได้ assign ในทุก branch

**ตัวอย่าง BAD:**

```vhdl
process (a, b, sel)
begin
    if sel = '1' then
        y <= a;     -- ไม่มี else! → latch
    end if;
end process;
```

**Fix:**

```vhdl
process (a, b, sel)
begin
    y <= b;         -- default ก่อน
    if sel = '1' then
        y <= a;
    end if;
end process;
```

### Error 4: `Length mismatch`

```
** Error: mux2x1.vhd(20): Length of expected is 4; length of actual is 2.
```

**สาเหตุ:** Vector width ไม่ตรงกัน

**Fix:** ใช้ explicit width หรือ slice:

```vhdl
y <= "00" & a(1 downto 0);  -- zero-extend
```

### Error 5: `Procedure overload ambiguity`

```
** Error: Procedure 'check' is ambiguous.
```

**สาเหตุ:** procedure มี parameter 2 ตัว แต่ procedure อื่นก็มี 2 ตัว — VHDL สับสน

**Fix:** ตั้งชื่อให้ต่างกัน:

```vhdl
procedure check_and(...)    -- ไม่ใช่ check(...)
procedure check_or(...)
procedure check_mux(...)
```

### Error 6: `'X'` ปรากฏใน waveform

**สาเหตุ:** มี latch หรือ signal ไม่ initialize

**Debug:**

1. ดู sensitivity list ของ process
2. ตรวจสอบว่ามี default assignment ครบ
3. เช็ค `wait for` มีค่าที่ถูกต้อง

### Error 7: ไม่ได้ `to_integer` (เมื่อใช้ NUMERIC_STD)

```
** Error: Unknown identifier "to_integer".
```

**สาเหตุ:** ลืม `use IEEE.NUMERIC_STD.ALL;`

**Fix:** เพิ่ม `use IEEE.NUMERIC_STD.ALL;`

### Error 8: `std.env` par with VHDL-93

```
** Error: Unknown identifier "std.env".
```

**สาเหตุ:** `std.env.stop` เป็น feature ของ VHDL-2008

**Fix:** ใช้ flag `-2008` เมื่อ compile:

```bash
vcom -2008 tb_lab1.vhd
```

หรือใช้ workaround:

```vhdl
report "Simulation finished" severity note;
wait;
```

---

## Bonus Challenge

### Challenge 1: เพิ่ม 4-to-1 MUX

ออกแบบ 4-to-1 MUX โดยใช้ 2-to-1 MUX เป็น building block:

```vhdl
-- สร้าง entity mux4x1.vhd ที่ instantiate mux2x1 สามตัว
entity mux4x1 is
    port (
        d0, d1, d2, d3 : in  std_logic;
        sel             : in  std_logic_vector(1 downto 0);
        y               : out std_logic
    );
end entity;
```

### Challenge 2: เพิ่ม 3-to-8 Decoder

```vhdl
entity dec3x8 is
    port (
        en : in  std_logic;
        a  : in  std_logic_vector(2 downto 0);
        y  : out std_logic_vector(7 downto 0)
    );
end entity;
```

ทดสอบ exhaustive: 8 patterns × enable = 1 → ทั้งหมด 16 cases

### Challenge 3: Binary Encoder

สร้าง module ที่ทำงานตรงข้ามกับ decoder (8 input → 3 output binary):

```vhdl
entity enc8x3 is
    port (
        en  : in  std_logic;
        a   : in  std_logic_vector(7 downto 0);
        y   : out std_logic_vector(2 downto 0);
        vld : out std_logic   -- valid: =1 เมื่อ input เป็น one-hot
    );
end entity;
```

---

## Checkpoint: ทำเสร็จหรือยัง?

| Item | Status |
| --- | --- |
| เขียน 4 ไฟล์ design (AND, OR, MUX, Decoder) ผ่าน | ☐ |
| เขียน testbench รวม (tb_lab1.vhd) | ☐ |
| Compile ใน Questa ผ่าน 0 errors | ☐ |
| Run simulation ใน GUI และเห็น PASSED | ☐ |
| Run ใน batch mode ผ่าน | ☐ |
| เข้าใจ waveform ทุกตัว | ☐ |
| แก้ไข errors ที่เจอได้ | ☐ |

ถ้าทุกข้อ ✅ ผ่าน → พร้อมไปต่อ Day 2 (Advanced RTL Design)

---

## สรุปสิ่งที่ได้เรียนรู้

1. **โครงสร้าง VHDL**: library, entity, architecture
2. **2 styles**: dataflow (concurrent) vs behavioral (process)
3. **Latch prevention**: default assignment ทุก combinational process
4. **Self-checking testbench**: procedure + counter
6. **Questa workflow**: project → compile → simulate → wave
7. **Batch mode**: do-file สำหรับ automation

---

> **ต่อไป:** Lab 2 — ออกแบบ FSM Moore/Mealy + Testbench

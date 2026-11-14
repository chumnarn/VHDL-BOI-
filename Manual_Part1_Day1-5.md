# คู่มือหลักสูตร Advanced Digital IC and MEMS Design with EDA Verification and Simulation Tools

## ส่วนที่ 1: Digital IC Design & Verification ด้วย VHDL และ Siemens EDA (วันที่ 1 – 5)

---

### ข้อมูลหลักสูตร

| รายการ | รายละเอียด |
| --- | --- |
| ชื่อหลักสูตร | Advanced Digital IC and MEMS Design with EDA Verification and Simulation Tools |
| ผู้จัด | HENISWARE Co., Ltd. (ตัวแทนจำหน่าย Siemens EDA ในประเทศไทย) ร่วมกับ BOI และ MUT |
| ระยะเวลา | 10 วัน วันละ 8 ชั่วโมง รวม 80 ชั่วโมง (ภาคทฤษฎี 40 ชม. + ภาคปฏิบัติ 40 ชม.) |
| ส่วนที่ 1 (เล่มนี้) | วันที่ 1 – 5: Digital IC Design & Verification ด้วย VHDL (40 ชม.) |
| ส่วนที่ 2 | วันที่ 6 – 10: IC Layout และ MEMS Design & Simulation (40 ชม.) |
| เกณฑ์ประเมิน | สอบภาคทฤษฎีและจำลองการทำงานด้วยโปรแกรม |

### เครื่องมือที่ใช้ในส่วนที่ 1 (Siemens EDA / Mentor Graphics)

| เครื่องมือ | บทบาท | ใช้ในวันที่ |
| --- | --- | --- |
| Questa Advanced Simulator | Simulation, Functional Coverage, Assertions | 1, 2, 4, 5 |
| ModelSim | Simulation ระดับ HDL | 1, 2 |
| HDL Designer | สร้าง Block Diagram และสร้างโค้ด VHDL อัตโนมัติ | 2 |
| Precision RTL | RTL Synthesis และ Optimization | 3 |

### เครื่องมือ Open-source เสริม (ทางเลือก — ไม่ต้องมี license)

> ใช้สอนหัวข้อ 3.5 (Yosys / LibreLane), แล็บ 3B และหัวข้อ 5.4–5.5 (RTL-to-GDSII Full Chip Flow)
> — เหมาะกับนักเรียนที่ไม่มี PDK หรือทำเป็นคายนอกเวลา/รายบุคคล
> ดูรายละเอียดที่หัวข้อ 3.5, 3.6, 5.4 และ 5.5

| เครื่องมือ | บทบาท | ใช้ในหัวข้อ | License |
| --- | --- | --- | --- |
| Yosys | RTL → netlist synthesis (pass-based) | 3.5, 3.6, 5.4, 5.5 | Open-source (GPL) |
| LibreLane | Open-source ASIC flow: RTL → GDSII + DRC/LVS | 3.5, 3.6, 5.4, 5.5 | Open-source (Apache-2.0) |
| Icarus Verilog | RTL / Gate-Level Simulation | 3.6, 5.5 | Open-source (GPL) |
| GHDL | สะพาน VHDL → Verilog สำหรับ Yosys | 3.5, 3.6 | Open-source (GPL) |
| OpenROAD, Magic, KLayout, Netgen | P&R, DRC, LVS (มาพร้อมใน nix closure ของ LibreLane) | 5.4, 5.5 | Open-source |
| PDK sky130A | Target library สำหรับสังเคราะห์และ layout | 3.5, 3.6, 5.4, 5.5 | Open-source (Apache-2.0) |

### เกณฑ์การประเมินผลผู้เชี่ยวชาญขั้นสูง

| ระดับ | ช่วงคะแนน | คุณสมบัติของผู้ผ่านการอบรม |
| --- | --- | --- |
| Beginner | 50 – 59 % | เข้าใจพื้นฐาน Digital IC, VHDL, IC Layout และกระบวนการผลิต สามารถเลือกใช้เครื่องมือพื้นฐานได้ แก้ปัญหาง่าย ๆ ได้ด้วยตนเอง |
| Intermediate | 60 – 79 % | วางแผนกระบวนการผลิตได้อย่างเป็นระบบ ประยุกต์ใช้ความรู้เพื่อปรับปรุงประสิทธิภาพ วิเคราะห์และแก้ปัญหาในขั้นตอนออกแบบ/ทดสอบได้ |
| Advanced | ≥ 80 % | ถ่ายทอดองค์ความรู้ได้อย่างเป็นระบบ วิเคราะห์เชิงลึกถึงปัญหาและแนวทางปรับปรุงคุณภาพ อธิบายหลักการและเหตุผลทางเทคนิคได้ถูกต้องตามหลักวิชาการ |

---

## วันที่ 1: Fundamentals of VHDL and Digital IC Design (8 ชั่วโมง)

### วัตถุประสงค์ของวัน
- อธิบายกระบวนการออกแบบวงจรดิจิทัลเปรียบเทียบระหว่าง ASIC และ FPGA ได้
- อธิบายโครงสร้างพื้นฐานของภาษา VHDL และองค์ประกอบสำคัญได้
- เขียนโค้ด VHDL สำหรับโมดูลตรรกะพื้นฐาน (AND, OR, MUX, Decoder) ได้อย่างถูกต้อง
- ดำเนินการ Simulation และวิเคราะห์ waveform เพื่อ Debugging ด้วย Questa หรือ ModelSim ได้

### โครงสร้างเวลา

| เวลา | กิจกรรม | ชม. |
| --- | --- | --- |
| 09:00 – 10:30 | บรรยาย: Digital IC Design Flow (Behavioral → Physical) | 1.5 |
| 10:30 – 10:45 | พัก | – |
| 10:45 – 12:00 | บรรยาย: ASIC vs FPGA, VHDL Building Blocks | 1.25 |
| 12:00 – 13:00 | พักเที่ยง | – |
| 13:00 – 14:30 | บรรยาย: Simulation vs Synthesis, Data Types | 1.5 |
| 14:30 – 14:45 | พัก | – |
| 14:45 – 16:30 | แล็บ 1: เขียนโค้ด AND/OR/MUX/Decoder + Simulation | 1.75 |
| 16:30 – 17:00 | สรุปประจำวัน + ถาม-ตอบ | 0.5 |

---

### 1.1 ภาคทฤษฎี: Digital IC Design Flow

#### 1.1.1 ลำดับชั้นของการออกแบบ (Design Abstraction Levels)

การออกแบบวงจรดิจิทัลสามารถจำลองได้ในหลายระดับของนามธรรม โดยแต่ละระดับให้มุมมองที่แตกต่างกันทั้งด้านความเร็วในการจำลองและความใกล้เคียงกับฮาร์ดแวร์จริง

1. **Behavioral / System Level** – อธิบายฟังก์ชันด้วยอัลกอริทึมหรือโมเดลทางคณิตศาสตร์ ไม่สนใจโครงสร้างฮาร์ดแวร์
2. **Register-Transfer Level (RTL)** – อธิบายการไหลของข้อมูลระหว่างเรจิสเตอร์และตรรกะเชิงผสม เป็นระดับมาตรฐานที่ใช้เขียน VHDL/Verilog เพื่อสังเคราะห์
3. **Logic Gate-Level** – วงจรถูกแทนด้วยเกตมาตรฐาน (NAND, NOR, DFF, MUX ฯลฯ) ผลลัพธ์จาก Synthesis
4. **Physical Design** – แปลงเนตร์ลิสต์เป็นเลย์เอาต์จริงบนซิลิคอน (Floorplan, Placement, Routing)

```
System/Behavioral ──► RTL ──► Logic Gate-Level ──► Physical Layout
 (Algorithm)        (VHDL)    (Netlist)            (GDSII)
```

#### 1.1.2 ASIC vs FPGA

| คุณสมบัติ | ASIC (Application-Specific IC) | FPGA (Field-Programmable Gate Array) |
| --- | --- | --- |
| ต้นทุนเริ่มต้น (NRE) | สูงมาก (mask cost) | ต่ำ |
| ต้นทุนต่อหน่วย (เมื่อผลิตมาก) | ต่ำมาก | สูง |
| ประสิทธิภาพ | สูง (ปรับแต่งได้ตามต้องการ) | ต่ำกว่า (มี overhead ของ programmable fabric) |
| เวลาออกสู่ตลาด | นาน (หลายเดือนถึงปี) | เร็ว (วันถึงสัปดาห์) |
| ความยืดหยุ่นหลังผลิต | ไม่ได้ (ต้องผลิตใหม่) | สูง (โปรแกรมใหม่ได้) |
| เหมาะกับ | ผลิตภัณฑ์ปริมาณมาก, ต้องการ performance สูง | ต้นแบบ, ผลิตปริมาณน้อย, ต้องการ iterate เร็ว |

**ข้อสังเกต:** หลักสูตรนี้เน้น ASIC Flow เป็นหลัก แต่ภาษา VHDL ที่เรียนสามารถใช้ได้ทั้งสองแพลตฟอร์ม

#### 1.1.3 ASIC Design Flow (Front-End vs Back-End)

```
┌────────────────── FRONT-END (ออกแบบเชิงตรรกะ) ──────────────────┐
│                                                                   │
│  Spec ──► RTL Design ──► Functional Verification ──► Synthesis     │
│                                (Simulation)           (Netlist)    │
└───────────────────────────────────────────────────────────────────┘
                              │
┌────────────────── BACK-END (ออกแบบทางกายภาพ) ────────────────────┐
│                                                                   │
│  Floorplan ──► Placement ──► CTS ──► Routing ──► Sign-off          │
│                                                  (DRC, LVS, STA) │
└───────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                          GDSII ──► Fabrication ──► Testing
```

ใน 5 วันแรกเราจะเน้นเฉพาะ Front-End Flow ตั้งแต่ RTL ไปจนถึง Gate-Level Netlist

---

### 1.2 ภาคทฤษฎี: พื้นฐานภาษา VHDL

VHDL (VHSIC Hardware Description Language) เป็นภาษาที่พัฒนาโดยกระทรวงกลาโหมสหรัฐฯ ตั้งแต่ปี ค.ศ. 1980 และกลายเป็นมาตรฐาน IEEE 1076 ใช้อธิบายพฤติกรรมและโครงสร้างของวงจรดิจิทัลได้ทั้งในมุมของ Simulation และ Synthesis

#### 1.2.1 โครงสร้างของไฟล์ VHDL

ไฟล์ VHDL ที่สังเคราะห์ได้ (synthesizable) ต้องประกอบด้วย 3 ส่วนหลักเสมอ:

```vhdl
-- 1) Library/Use clause (เรียกใช้ไลบรารีมาตรฐาน)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- 2) Entity (ประกาศ I/O ของโมดูล – มองจากภายนอก)
entity my_module is
    port (
        a, b : in  std_logic;
        sel  : in  std_logic;
        y    : out std_logic
    );
end entity my_module;

-- 3) Architecture (อธิบายพฤติกรรม/โครงสร้างภายใน)
architecture rtl of my_module is
begin
    -- concurrent statements อยู่ที่นี่
end architecture rtl;
```

#### 1.2.2 Entity

Entity คือ "หน้าต่าง" ของโมดูล บอกว่าโมดูลนี้มีขาอะไรบ้าง เป็นขาเข้าหรือออก ชนิดข้อมูลอะไร คล้ายกับ schematic symbol

- **port mode**: `in`, `out`, `inout`, `buffer`
- **port type**: โดยทั่วไปใช้ `std_logic` หรือ `std_logic_vector`

#### 1.2.3 Architecture

Architecture คือ "ตัวถัง" ภายใน อธิบายการทำงานของวงจร สามารถเขียนได้หลายสไตล์:

| สไตล์ | ลักษณะ | ตัวอย่าง |
| --- | --- | --- |
| Behavioral | ใช้ process, if, case | เหมาะกับ RTL ระดับสูง |
| Dataflow | ใช้ concurrent signal assignment พร้อมนิพจน์บูลีน | เหมาะกับตรรกะเชิงผสม |
| Structural | เรียก component ย่อย ๆ มาต่อกัน | เหมาะกับการสร้าง hierarchy |

หนึ่ง entity สามารถมีได้หลาย architecture เช่น ตัวหนึ่งสำหรับ simulation อีกตัวสำหรับ synthesis

#### 1.2.4 Data Types ที่ใช้บ่อย

| Type | ความหมาย | ใช้เมื่อ |
| --- | --- | --- |
| `std_logic` | สัญญาณดิจิทัล 1 บิต มี 9 ค่า (`'0'`,`'1'`,`'X'`,`'U'`,`'Z'`,`'W'`,`'L'`,`'H'`,`'-'`) | I/O port ทั่วไป |
| `std_logic_vector(N-1 downto 0)` | บัสขนาด N บิต | อาเรย์ของสัญญาณ |
| `integer` | จำนวนเต็ม | ตัวนับใน loop, parameter |
| `boolean` | `TRUE` / `FALSE` | เงื่อนไข, function return |
| `natural`, `positive` | subset ของ integer | ดัชนีที่ไม่เป็นลบ |

ไลบรารีมาตรฐานที่ควรเรียกใช้เกือบทุกไฟล์:
- `IEEE.STD_LOGIC_1164` – กำหนด `std_logic` และ `std_logic_vector`
- `IEEE.NUMERIC_STD` – ฟังก์ชันแปลงชนิดเชิงตัวเลข (`unsigned`, `signed`, `to_unsigned`, …)

#### 1.2.5 Signals vs Variables

| หัวข้อ | Signal | Variable |
| --- | --- | --- |
| ขอบเขตการใช้งาน | ทั่วทั้ง architecture, ระหว่าง process | ภายใน process หรือ function/subprogram เท่านั้น |
| เวลาที่อัปเดตค่า | ปลายรอบ simulation delta (ทุกครั้งที่ process หยุดรอ) | ทันทีที่บรรทัดนั้นรัน |
| ใช้ในการสังเคราะห์ | ใช่ – สร้างเป็น wire/FF จริง | ไม่ – เป็นเพียงตัวแปรชั่วคราวในการจำลอง |
| คำแนะนำ | ใช้สำหรับขาออก, state, bus | ใช้เป็นตัวแปรช่วยคำนวณภายใน process |

ตัวอย่างความแตกต่าง:

```vhdl
process (a, b)
    variable v_temp : std_logic;  -- variable: เปลี่ยนค่าทันที
    signal  s_temp : std_logic;  -- signal:   เปลี่ยนค่าเมื่อ process suspend
begin
    v_temp := a and b;            -- ใช้ได้ทันทีในบรรทัดถัดไป
    s_temp <= a xor b;            -- ค่าใหม่จะเห็นในรอบถัดไป
    y     <= v_temp;              -- เห็นค่า a and b
    z     <= s_temp;              -- เห็นค่า a xor b จากรอบก่อน
end process;
```

---

### 1.3 ภาคทฤษฎี: Simulation vs Synthesis

| มิติ | Simulation | Synthesis |
| --- | --- | --- |
| จุดประสงค์ | ตรวจสอบฟังก์ชัน (functional correctness) | แปลง RTL เป็นเกตระดับฮาร์ดแวร์ |
| เวลาที่รัน | ก่อนผลิต (pre-silicon) | ก่อนส่งไป fab |
| ผลลัพธ์ | waveform, report | netlist, area report, timing report |
| โครงสร้างที่รองรับ | เกือบทุกคำสั่ง VHDL | รับเฉพาะ synthesizable subset |
| เครื่องมือหลักในหลักสูตร | Questa / ModelSim | Precision RTL |

**Synthesizable subset** ที่ควรยึดถือตั้งแต่วันที่ 1:
- หลีกเลี่ยง `wait for`, `assert` ในส่วนที่จะสังเคราะห์
- หลีกเลี่ยง `initial` (ใช้ได้เฉพาะ testbench)
- ใช้ `rising_edge(clk)` เพื่ออธิบาย edge-sensitive logic
- หลีกเลี่ยง `std_logic` ค่า `'X'`, `'U'`, `'Z'` ใน design (ใช้ได้เฉพาะ testbench)
- ใช้ clock, reset แบบ synchronous ทุกครั้งที่เป็นไปได้

---

### 1.4 ภาคปฏิบัติ: แล็บ 1 – โมดูลตรรกะพื้นฐานและ Questa/ModelSim

#### 1.4.1 ตัวอย่างโค้ด VHDL

**Lab 1-1: AND Gate (Dataflow Style)**

```vhdl
-- File: and_gate.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity and_gate is
    port (
        a, b : in  std_logic;
        y    : out std_logic
    );
end entity and_gate;

architecture dataflow of and_gate is
begin
    y <= a and b;
end architecture dataflow;
```

**Lab 1-2: 2-to-1 MUX (Behavioral Style)**

```vhdl
-- File: mux2x1.vhd
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
    process (a, b, sel)
    begin
        if sel = '1' then
            y <= b;
        else
            y <= a;
        end if;
    end process;
end architecture rtl;
```

**Lab 1-3: 2-to-4 Decoder (Behavioral Style)**

```vhdl
-- File: dec2x4.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity dec2x4 is
    port (
        en  : in  std_logic;
        a   : in  std_logic_vector(1 downto 0);
        y   : out std_logic_vector(3 downto 0)
    );
end entity dec2x4;

architecture rtl of dec2x4 is
begin
    process (en, a)
    begin
        y <= (others => '0');
        if en = '1' then
            case a is
                when "00" => y <= "0001";
                when "01" => y <= "0010";
                when "10" => y <= "0100";
                when "11" => y <= "1000";
                when others => y <= (others => '0');
            end case;
        end if;
    end process;
end architecture rtl;
```

**Lab 1-4: Testbench อย่างง่าย**

```vhdl
-- File: tb_mux2x1.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_mux2x1 is
end entity tb_mux2x1;

architecture sim of tb_mux2x1 is
    signal a, b, sel, y : std_logic;
begin
    -- DUT
    dut : entity work.mux2x1
        port map (a => a, b => b, sel => sel, y => y);

    -- Stimulus
    stim : process
    begin
        a <= '0'; b <= '0'; sel <= '0';
        wait for 10 ns;

        a <= '1'; b <= '0'; sel <= '0';
        wait for 10 ns;

        a <= '0'; b <= '1'; sel <= '1';
        wait for 10 ns;

        a <= '1'; b <= '1'; sel <= '1';
        wait for 10 ns;

        report "Simulation finished";
        wait;
    end process;
end architecture sim;
```

#### 1.4.2 ขั้นตอนการใช้งาน Questa Advanced Simulator

**GUI Mode:**

1. เปิด Questa → `File ▸ New ▸ Project`
2. ตั้งชื่อโปรเจกต์ (เช่น `lab1_day1`) และเลือก working library = `work`
3. `Project ▸ Add to Project ▸ Existing File…` เพิ่มไฟล์ `.vhd` ทั้งหมด
4. คอมไพล์: คลิมาร์กไฟล์ใน Project tab → คลิกปุ่ม **Compile** (Alt+F9) หรือคลิกขวา → Compile
5. เริ่ม Simulation: `Simulate ▸ Start Simulation…` → เลือก `tb_mux2x1` ในแท็บ Design
6. เปิด Wave window: คลิกขวาที่สัญญาณใน sim tab → `Add Wave`
7. รัน simulation: พิมพ์ `run 100 ns` ใน transcript หรือกดปุ่ม **Run**
8. วิเคราะห์ waveform, ตรวจสอบค่า y เมื่อ sel เปลี่ยน

**Batch Mode (Tcl):**

ไฟล์ `run.do`:

```tcl
# run.do – Questa batch script
vlib work
vcom -2008 *.vhd
vsim -do "add wave *; run 200 ns" work.tb_mux2x1
```

รันด้วยคำสั่ง:

```bash
vsim -do run.do -c
```

#### 1.4.3 แบบฝึกหัดประจำวันที่ 1

| ข้อ | โจทย์ | ผลที่คาดหวัง |
|-----|--------|----------------|
| 1.1 | เขียน VHDL ของ OR gate และ NAND gate (4 อินพุต) แล้วเขียน testbench ทดสอบครบทุกกรณี | ทุกกรณีผ่าน ไม่มี `'X'` ในผลลัพธ์ |
| 1.2 | เขียน 4-to-1 MUX ในรูปแบบ dataflow และ behavioral เปรียบเทียบผล | ผลลัพธ์เหมือนกัน |
| 1.3 | เขียน 3-to-8 decoder พร้อม enable ใช้ case statement | waveform ตรง truth table |
| 1.4 | ใช้ Questa batch mode สร้าง `.do` file เพื่อรัน simulation ทั้งหมด | รันซ้ำได้ด้วยคำสั่งเดียว |

---

## วันที่ 2: Advanced RTL Design Using VHDL (8 ชั่วโมง)

### วัตถุประสงค์ของวัน
- เขียนโค้ด VHDL สำหรับระบบ Synchronous พร้อมจัดการ Clock, Reset, Clock Enable ได้
- ออกแบบ FSM ทั้งแบบ Moore และ Mealy ได้อย่างเหมาะสม
- เลือกใช้และอธิบายความแตกต่างของ Structural และ Behavioral Modeling ได้
- ปฏิบัติตามแนวทางการออกแบบ RTL ที่ถูกต้อง หลีกเลี่ยง Latch ได้
- สร้าง Testbench และ Debug ด้วย Questa ได้
- ใช้ HDL Designer สร้าง Block Diagram และแปลงเป็นโค้ด VHDL อัตโนมัติได้

### โครงสร้างเวลา

| เวลา | กิจกรรม | ชม. |
| --- | --- | --- |
| 09:00 – 10:30 | บรรยาย: Synchronous Design & Reset Strategy | 1.5 |
| 10:30 – 10:45 | พัก | – |
| 10:45 – 12:00 | บรรยาย: FSM Moore vs Mealy | 1.25 |
| 12:00 – 13:00 | พักเที่ยง | – |
| 13:00 – 14:30 | บรรยาย: RTL Coding Guidelines (Latch, CDC) และ Testbench | 1.5 |
| 14:30 – 14:45 | พัก | – |
| 14:45 – 16:30 | แล็บ 2: FSM + Testbench + HDL Designer | 1.75 |
| 16:30 – 17:00 | สรุปประจำวัน + ถาม-ตอบ | 0.5 |

---

### 2.1 ภาคทฤษฎี: Synchronous Design

#### 2.1.1 หลักการ Synchronous Design

การออกแบบดิจิทัลระดับ ASIC ส่วนใหญ่ใช้ **single-clock synchronous design** เพราะ:
- ง่ายต่อการวิเคราะห์ timing
- ลดปัญหา metastability และ race condition
- เครื่องมือ STA (Static Timing Analysis) ทำงานได้แม่นยำ

โครงสร้างมาตรฐานของ synchronous block:

```vhdl
process (clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            -- synchronous reset
            state <= IDLE;
            cnt   <= (others => '0');
        else
            state <= next_state;
            cnt   <= cnt + 1;
        end if;
    end if;
end process;
```

#### 2.1.2 Reset Strategy

| ประเภท | คุณสมบัติ | ข้อดี | ข้อเสีย |
| --- | --- | --- | --- |
| Synchronous Reset | Reset ตรวจสอบเฉพาะ rising edge ของ clk | ปลอดภัย, ใช้ FF ที่มี reset pin อย่างเดียว, timing analysis ง่าย | ต้องมี clk ทำงานเพื่อ reset |
| Asynchronous Reset | Reset ทำงานทันทีไม่สนใจ clk | รับประกันการเข้าสู่ known state แม้ clk หยุด | ต้อง de-assert synchronously เพื่อป้องกัน recovery/removal |

แนะนำ: ใช้ **Synchronous Reset** เป็นค่า default ยกเว้นข้อกำหนดเฉพาะของ ASIC (เช่น low-power, scan)

#### 2.1.3 Clock Enable (CE)

ใช้เพื่อหยุดการ tick ของ register บางส่วนโดยไม่ต้องปิด clock (ประหยัดพลังงาน, ลด clock tree complexity)

```vhdl
process (clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            cnt <= (others => '0');
        elsif ce = '1' then
            cnt <= cnt + 1;
        end if;
    end if;
end process;
```

---

### 2.2 ภาคทฤษฎี: FSM – Moore vs Mealy

#### 2.2.1 ความแตกต่าง

| หัวข้อ | Moore Machine | Mealy Machine |
| --- | --- | --- |
| เงื่อนไขผลลัพธ์ | ขึ้นกับ state ปัจจุบันเท่านั้น | ขึ้นกับ state ปัจจุบัน **และ** input |
| จำนวน state | มากกว่า (ต้องแยกทุก combination ของ output) | น้อยกว่า |
| Output timing | ออกหลังจาก clock edge (delay 1 cycle) | ออกทันทีที่ input เปลี่ยน (combinational) |
| Glitch | ปลอดภัย | อาจมี glitch ถ้า input ไม่ synchronized |
| เหมาะกับ | control path ที่ต้องการ stability | control path ที่ต้องการ latency ต่ำ |

#### 2.2.2 ตัวอย่าง FSM: Sequence Detector "101"

**Moore Implementation:**

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity seq_det_moore is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        din      : in  std_logic;
        detected : out std_logic
    );
end entity seq_det_moore;

architecture rtl of seq_det_moore is
    type state_t is (S0, S1, S2, S3);  -- S3 = "101"
    signal state, next_state : state_t;
begin
    -- State register
    sync_proc : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= S0;
            else
                state <= next_state;
            end if;
        end if;
    end process sync_proc;

    -- Next-state & output logic
    comb_proc : process (state, din)
    begin
        detected <= '0';  -- default
        case state is
            when S0 =>
                if din = '1' then next_state <= S1;
                else              next_state <= S0;
                end if;
            when S1 =>
                if din = '0' then next_state <= S2;
                else              next_state <= S1;
                end if;
            when S2 =>
                if din = '1' then next_state <= S3;
                else              next_state <= S0;
                end if;
            when S3 =>
                detected <= '1';
                if din = '1' then next_state <= S1;
                else              next_state <= S0;
                end if;
        end case;
    end process comb_proc;
end architecture rtl;
```

**Mealy Implementation:**

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity seq_det_mealy is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        din      : in  std_logic;
        detected : out std_logic
    );
end entity seq_det_mealy;

architecture rtl of seq_det_mealy is
    type state_t is (S0, S1, S2);
    signal state, next_state : state_t;
begin
    sync_proc : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= S0;
            else
                state <= next_state;
            end if;
        end if;
    end process sync_proc;

    comb_proc : process (state, din)
    begin
        detected <= '0';
        case state is
            when S0 =>
                if din = '1' then
                    next_state <= S1;
                else
                    next_state <= S0;
                end if;
            when S1 =>
                if din = '0' then
                    next_state <= S2;
                else
                    next_state <= S1;
                end if;
            when S2 =>
                if din = '1' then
                    next_state <= S1;
                    detected <= '1';   -- output ติดทันที
                else
                    next_state <= S0;
                end if;
        end case;
    end process comb_proc;
end architecture rtl;
```

---

### 2.3 ภาคทฤษฎี: Structural vs Behavioral Modeling

| สไตล์ | ใช้เมื่อ | ตัวอย่าง |
| --- | --- | --- |
| Behavioral | อธิบาย "อะไร" ที่ต้องทำ ด้วย process, if, case | FSM, datapath ที่ซับซ้อน |
| Dataflow | อธิบายด้วย concurrent expression | ตรรกะเชิงผสมขนาดเล็ก, bus assignment |
| Structural | ประกอบ component ย่อย ๆ (เรียก entity อื่น) | hierarchical design, สร้าง wrapper |

ตัวอย่าง Structural:

```vhdl
architecture struct of full_adder is
    component xor_gate is
        port (a, b : in  std_logic; y : out std_logic);
    end component;
    component and_gate is
        port (a, b : in  std_logic; y : out std_logic);
    end component;
    component or_gate  is
        port (a, b : in  std_logic; y : out std_logic);
    end component;
    signal s1, s2, s3 : std_logic;
begin
    u1 : xor_gate port map (a => a, b => b, y => s1);
    u2 : xor_gate port map (a => s1, b => cin, y => sum);
    u3 : and_gate port map (a => a, b => b, y => s2);
    u4 : and_gate port map (a => s1, b => cin, y => s3);
    u5 : or_gate  port map (a => s2, b => s3, y => cout);
end architecture struct;
```

---

### 2.4 ภาคทฤษฎี: RTL Design Guidelines

#### 2.4.1 วิธีหลีกเลี่ยง Latch

Latch เกิดเมื่อ **process** หรือ **concurrent assignment** มี output ที่ไม่ได้กำหนดค่าในทุก path ของเงื่อนไข เป็นอันตรายเพราะ:
- ทำให้ timing analysis ยาก
- อาจเกิด race condition ใน testbench
- ส่วนใหญ่ synthesis tool จะเตือน แต่บางครั้งอาจ miss

**ตัวอย่าง Bad (เกิด Latch):**

```vhdl
process (sel, a, b)
begin
    if sel = '1' then
        y <= a;
    end if;       -- ไม่มี else ⇒ เกิด latch!
end process;
```

**ตัวอย่าง Good (default assignment):**

```vhdl
process (sel, a, b)
begin
    y <= b;       -- default ทุกกรณี
    if sel = '1' then
        y <= a;
    end if;
end process;
```

**ตัวอย่าง Good (full case):**

```vhdl
case sel is
    when "00" => y <= a;
    when "01" => y <= b;
    when "10" => y <= d;
    when "11" => y <= e;
    when others => y <= '0';   -- ป้องกัน latch + handle unknown
end case;
```

#### 2.4.2 Clock Domain Crossing (CDC) – เบื้องต้น

หลักการเบื้องต้น:
- สัญญาณที่ข้าม clock domain ต้องผ่าน **synchronizer** (2-stage FF อย่างน้อย) เพื่อลด metastability
- ใช้ **handshake** หรือ **FIFO** สำหรับข้อมูลหลายบิต
- หลีกเลี่ยงการส่งสัญญาณมากกว่า 1 บิตพร้อมกันโดยไม่มี handshake

---

### 2.5 ภาคทฤษฎี: Testbench

#### 2.5.1 องค์ประกอบของ Testbench ที่ดี

1. **Stimulus generator** – สร้างอินพุตให้ครอบคลุมทุกกรณี
2. **DUT instantiation** – เรียกใช้ Design Under Test
3. **Checker / Monitor** – ตรวจสอบผลลัพธ์อัตโนมัติ
4. **Reporting** – สรุปผล, fail/pass, coverage

#### 2.5.2 Self-Checking Testbench

ตัวอย่างสำหรับ FSM Moore (ตรวจสอบผลอัตโนมัติ):

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_seq_moore is
end entity tb_seq_moore;

architecture sim of tb_seq_moore is
    constant CLK_PERIOD : time := 10 ns;
    signal clk, rst, din, detected : std_logic;
    signal pass_cnt, fail_cnt      : integer := 0;
begin
    -- DUT
    dut : entity work.seq_det_moore
        port map (clk => clk, rst => rst, din => din, detected => detected);

    -- Clock
    clk <= not clk after CLK_PERIOD / 2;

    stim : process
        procedure check(input  : in  std_logic;
                       expect : in  std_logic;
                       tag    : in  string) is
        begin
            if detected /= expect then
                report "FAIL " & tag & ": got " & std_logic'image(detected) &
                       " expected " & std_logic'image(expect)
                    severity error;
                fail_cnt <= fail_cnt + 1;
            else
                pass_cnt <= pass_cnt + 1;
            end if;
        end procedure;
    begin
        rst <= '1'; din <= '0';
        wait for 2 * CLK_PERIOD;
        rst <= '0';

        -- pattern 101
        din <= '1'; wait for CLK_PERIOD; check(din, '0', "1");
        din <= '0'; wait for CLK_PERIOD; check(din, '0', "10");
        din <= '1'; wait for CLK_PERIOD; check(din, '1', "101");

        report "PASS=" & integer'image(pass_cnt) &
               " FAIL=" & integer'image(fail_cnt);
        wait;
    end process stim;
end architecture sim;
```

#### 2.5.3 Packages และ Constants

การแยก constants ออกเป็น package ช่วยให้ reuse ได้และง่ายต่อการแก้ไข:

```vhdl
-- File: my_types_pkg.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package my_types_pkg is
    constant FIFO_DEPTH : integer := 16;
    constant DATA_WIDTH : integer := 8;
    type    fifo_state_t is (EMPTY, PARTIAL, FULL);
end package my_types_pkg;
```

```vhdl
-- เรียกใช้ใน design file
library work;
use work.my_types_pkg.ALL;
```

---

### 2.6 ภาคปฏิบัติ: แล็บ 2 – FSM, Testbench และ HDL Designer

#### 2.6.1 Lab 2-1: ใช้ HDL Designer สร้าง Block Diagram

ขั้นตอน:

1. `File ▸ New ▸ Design` เลือก Project
2. สร้างไฟล์ block diagram: `File ▸ New ▸ Block Diagram`
3. วาง block: คลิกขวา → Add Component → เลือก AND, OR, MUX, DFF จากไลบรารี
4. เชื่อมต่อ wire ระหว่าง block
5. คลิกขวา → **Generate HDL** → เลือก VHDL → ตั้งชื่อ output file
6. ตรวจสอบโค้ด VHDL ที่ได้ เทียบกับโค้ดที่เขียนเอง
7. นำไฟล์ที่ได้ไป simulate ใน Questa เพื่อยืนยันผล

#### 2.6.2 Lab 2-2: Self-Checking Testbench พร้อม Assertion (PSL/VHDL assert)

ใช้ concurrent assertion เพื่อตรวจสอบ property ที่ต้องการ:

```vhdl
-- ในไฟล์ design หรือในไฟล์ตรวจสอบแยก
assert_det : assert never (rst = '1' and rising_edge(clk))
             report "Reset must not be high at clock edge"
             severity failure;
```

#### 2.6.3 Debugging Waveform ใน Questa

เคล็ดลับ:
- ใช้ **Grouping** จัดสัญญาณเป็นกลุ่ม (clk, input, output, internal)
- ใช้ **Divider** แยกกลุ่ม clk, output, internal
- ใช้ **Search** (Ctrl+F) หา transition ที่ต้องการ
- ใช้ **Cursors** วัด timing ระหว่าง event
- คลิกขวา signal → **Add to Wave ▸ Selected Signals**

#### 2.6.4 แบบฝึกหัดประจำวันที่ 2

| ข้อ | โจทย์ | ผลที่คาดหวัง |
|-----|--------|----------------|
| 2.1 | เขียน 8-bit synchronous counter พร้อม CE และ synchronous reset | ทดสอบ count, enable, reset ผ่าน |
| 2.2 | เขียน FSM detector สำหรับ pattern "1101" (Moore) | waveform ตรง truth table |
| 2.3 | เขียน Mealy detector สำหรับ pattern "1101" เปรียบเทียบกับ Moore | จำนวน state, latency ต่างกัน |
| 2.4 | สร้าง self-checking testbench ที่ตรวจสอบผลอัตโนมัติ | PASS count = จำนวน testcase |
| 2.5 | ใช้ HDL Designer สร้าง block diagram ของ full adder 4-bit แล้ว generate HDL | โค้ด VHDL ที่ได้ compile ผ่าน simulate ได้ |

---

## วันที่ 3: RTL Synthesis and Optimization — Precision RTL และ Yosys (8 ชั่วโมง)

### วัตถุประสงค์ของวัน
- ดำเนินการ Synthesis จาก RTL สู่ Netlist พร้อมกำหนด Constraints ได้อย่างถูกต้อง
- วิเคราะห์ Timing และปรับปรุงการออกแบบโดยใช้เทคนิค RTL Optimization ได้
- จัดทำรายงานด้าน Timing และ Resource และแก้ไข Timing Violations ได้อย่างเหมาะสม
- เข้าใจหลักการของ Yosys (open-source synthesis) และขั้นตอนของ Open-source ASIC Flow (LibreLane)
- ฝึกวัดผลสังเคราะห์เป็นตัวเลขจริง (cell count, area, slack) และพิสูจน์ความถูกต้องของ netlist ด้วย Gate-Level Simulation

### โครงสร้างเวลา — แผนมาตรฐาน (8 ชั่วโมง)

| เวลา | กิจกรรม | หัวข้อ | ชม. |
| --- | --- | --- | --- |
| 09:00 – 10:30 | บรรยาย: Synthesis Flow & Constraints | 3.1, 3.2 | 1.5 |
| 10:30 – 10:45 | พัก | – | – |
| 10:45 – 12:00 | บรรยาย: Timing Analysis เบื้องต้น | 3.3 | 1.25 |
| 12:00 – 13:00 | พักเที่ยง | – | – |
| 13:00 – 14:30 | บรรยาย: Optimization Techniques | 3.4 | 1.5 |
| 14:30 – 14:45 | พัก | – | – |
| 14:45 – 16:30 | แล็บ 3: Precision RTL – Synthesis + Timing Report | 3.7 | 1.75 |
| 16:30 – 17:00 | สรุปประจำวัน + ถาม-ตอบ | – | 0.5 |

### โครงสร้างเวลา — แผนขยาย (เพิ่ม 1 ครึ่งวันสำหรับหัวข้อ Open-source)

> เนื้อหา 3.5 (ทฤษฎี Yosys/LibreLane) + 3.6 (แล็บ 3B) ใช้เวลาประมาณ **4 ชั่วโมง**
> จึงแนะนำให้แยกเป็น **ครึ่งวันที่สอง** หรือเป็น **คายนอกเวลา (self-study)**
> — แล็บ 3B ใช้เครื่องมือ open-source ทั้งหมด ไม่ต้องมี commercial license
> และสามารถทำเป็นรายบุคคลนอกห้องเรียนได้

| เวลา | กิจกรรม | หัวข้อ | ชม. |
| --- | --- | --- | --- |
| 09:00 – 10:30 | บรรยาย: การสังเคราะห์ด้วย Yosys — ภายในตัวเครื่องมือ | 3.5 | 1.5 |
| 10:30 – 10:45 | พัก | – | – |
| 10:45 – 12:00 | บรรยาย: Open-source ASIC Flow ด้วย LibreLane + การอ่านผลลัพธ์ | 3.5 | 1.25 |
| 12:00 – 13:00 | พักเที่ยง | – | – |
| 13:00 – 15:30 | แล็บ 3B: Yosys + Gate-Level Simulation + LibreLane (RTL → GDSII) | 3.6 | 2.5 |
| 15:30 – 16:30 | เปรียบเทียบผลลัพธ์ commercial vs open-source + ถาม-ตอบ | 3.6 | 1.0 |
| 16:30 – 17:00 | สรุปประจำวัน | – | 0.5 |

> **ข้อกำหนดสำหรับห้องเรียน:** ต้องเตรียมเครื่องที่มี Linux/WSL พร้อม Yosys, Icarus Verilog,
> GHDL และ LibreLane (ติดตั้งผ่าน nix) รวมถึงเครือข่ายสำหรับดาวน์โหลด PDK sky130A (~1–2 GB)
> ดูวิธีติดตั้งที่ [`lab_code/day3_yosys/librelane/README.md`](lab_code/day3_yosys/librelane/README.md)

---

### 3.1 ภาคทฤษฎี: Synthesis Flow

#### 3.1.1 High-Level View

```
┌──────────┐    ┌─────────────┐    ┌──────────────┐    ┌──────────┐
│ RTL VHDL │ ─► │  Elaboration│ ─► │  Optimization│ ─► │  Netlist │
│  /Verilog│    │  (Parse +   │    │  (Mapping +  │    │ (Gate +  │
└──────────┘    │  Hierarchy) │    │ Optimization)│    │  Timing) │
                └─────────────┘    └──────────────┘    └──────────┘
                          │                  │
                       reports           reports
                          ▼                  ▼
                   (elaboration.log)  (timing.rpt,
                                       area.rpt,
                                       power.rpt)
```

#### 3.1.2 ขั้นตอนหลักใน Precision RTL

1. **Read** – อ่านไฟล์ VHDL/Verilog
2. **Elaborate** – ตีความ + สร้าง GTECH netlist (technology-independent)
4. **Apply Constraints** – clock period, input delay, output delay, false paths, multicycle paths
5. **Compile/Optimize** – mapping เข้าไลบรารีเกตของเทคโนโลยีเป้าหมาย + optimization
6. **Report** – area, timing, power, fanout, congestion

---

### 3.2 ภาคทฤษฎี: Constraints

#### 3.2.1 ประเภทของ Constraints

| ประเภท | ความหมาย | ตัวอย่าง |
| --- | --- | --- |
| Clock | กำหนดความถี่ของ clock | `create_clock -name clk -period 10 [get_ports clk]` |
| Input Delay | เวลาที่ input data มาถึงเทียบกับ clock edge | `set_input_delay -clock clk 2.0 [get_ports din*]` |
| Output Delay | เวลาที่ output data ต้องออกก่อน clock edge ถัดไป | `set_output_delay -clock clk 2.0 [get_ports dout*]` |
| False Path | เส้นทางที่ไม่ต้องวิเคราะห์ timing | `set_false_path -from [get_pins reg_a/Q] -to [get_pins reg_b/D]` |
| Multicycle Path | เส้นทางที่ใช้หลาย cycle | `set_multicycle_path -setup 2 -from ... -to ...` |
| Operating Conditions | Process, Voltage, Temperature | `set_operating_conditions -process typical -voltage 1.0 -temp 25` |

#### 3.2.2 ไฟล์ Constraints (SDC – Synopsys Design Constraints)

Precision RTL รองรับ SDC format ตัวอย่างไฟล์ `constraints.sdc`:

```tcl
# Clock
create_clock -name sys_clk -period 10.0 -waveform {0 5} [get_ports clk]
derive_pll_clocks

# Input/Output delay
set_input_delay  -clock sys_clk 2.0 [get_ports {din*}]
set_output_delay -clock sys_clk 2.0 [get_ports {dout*}]

# False path
set_false_path -from [get_ports rst]

# Drive strength / load
set_driving_cell -lib_cell INVX1 -pin Y [get_ports {din*}]
set_load 0.05 [get_ports {dout*}]
```

---

### 3.3 ภาคทฤษฎี: Timing Analysis เบื้องต้น

#### 3.3.1 Setup และ Hold

สำหรับ register-to-register path:

```
data launch edge: FF_A latch data on rising edge of clk at t=0
data capture edge: FF_B must latch at t=T (next rising edge)

Setup requirement: data must arrive at FF_B.D at least t_setup before t=T
Hold  requirement: data must remain stable at FF_B.D at least t_hold  after  t=T
```

ค่า **slack** บวก = OK, ลบ = violation

```
slack = (data arrival time) - (data required time)
       = (T_clk - delay) - (T_clk - t_setup)
```

#### 3.3.2 Timing Report

ตัวอย่าง timing report (Precision RTL):

```
Path 1: VIOLATED  -0.42 ns
=================================================
Startpoint: counter_reg[3] (rising edge-triggered flip-flop)
Endpoint:   comparator_out_reg/D (rising edge-triggered flip-flop)
Path Group:   sys_clk
Path Type:    max (setup)

Point                                    Incr   Path
-------------------------------------------------------------
clock sys_clk (rise edge)                 0.00   0.00
clock network delay (ideal)               0.00   0.00
counter_reg[3]/CK (DFFRX1)                0.00   0.00 r
counter_reg[3]/Q (DFFRX1)                 0.35   0.35 r
... (combinational) ...
comparator_out_reg/D (DFFRX1)            -0.10   5.42 f
data arrival time                                  5.42
...
data required time                                 5.00
slack (VIOLATED)                                  -0.42
```

---

### 3.4 ภาคทฤษฎี: Optimization Techniques

#### 3.4.1 Retiming

ย้าย flip-flop ข้าม combinational logic เพื่อสมดุล delay แต่ละ stage โดยไม่เปลี่ยนฟังก์ชัน

```
Before:    FF ──► [logic A: 3ns] ──► [logic B: 5ns] ──► FF
After:     FF ──► [logic A: 3ns] ──► FF ──► [logic B: 5ns] ──► FF
                                      ^                      
                          (FF เพิ่ม แต่ critical path ลด)
```

#### 3.4.2 Pipelining

ตัด combinational chain ยาว ๆ แล้วใส่ register คั่น เพิ่ม throughput โดย latency เพิ่ม 1 cycle

```vhdl
-- Before pipelining
y <= (a * b) + (c * d);

-- After pipelining (latency = 1 cycle)
process (clk) begin
    if rising_edge(clk) then
        p <= a * b;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        y <= p + (c * d);
    end if;
end process;
```

#### 3.4.3 Resource Sharing

ใช้ functional unit ร่วมกันเมื่อทำได้ เช่น ALU ที่ทำทั้ง add และ sub โดยใช้ adder ตัวเดียว

```vhdl
-- share adder
process (a, b, sel)
begin
    case sel is
        when ADD => result <= a + b;
        when SUB => result <= a - b;
        when others => result <= (others => '0');
    end case;
end process;
```

#### 3.4.4 Constant Propagation และ Dead Code Elimination

เครื่องมือ synthesis จะทำให้อัตโนมัติ เช่น `if "1" = '1'` จะถูก collapse เป็น always-true

#### 3.4.5 Clock Gating

ลด dynamic power โดยปิด clock ของ register ที่ไม่ทำงานในรอบนั้น (tool จะ infer จาก CE pattern ที่เหมาะสม)

```vhdl
-- สไตล์ที่ tool สามารถ infer clock-gating ได้
process (clk)
begin
    if rising_edge(clk) then
        if ce = '1' then
            reg <= din;
        end if;
    end if;
end process;
```

---

### 3.5 ภาคทฤษฎี: การสังเคราะห์ด้วย Yosys (Open-source Synthesis)

> **เวลาบรรยาย:** 90–120 นาที
> **คู่มือเชิงลึก:** [`Manual_3_5_Yosys_and_LibreLane_Synthesis_DeepDive.md`](Manual_3_5_Yosys_and_LibreLane_Synthesis_DeepDive.md) (24 หัวข้อ)

#### 3.5.1 ทำไมต้องมี Open-source Synthesis

Precision RTL, Genus และ Design Compiler ทำได้ทุกอย่าง แต่มีข้อจำกัดเชิงการศึกษาที่ทำให้
ห้องเรียนขนาด 30 คนเรียนพร้อมกันไม่ได้:

| ข้อจำกัด | ผลกระทบต่อห้องเรียน |
| --- | --- |
| License รายปี / ต่อ seat | นักเรียน 30 คนทำพร้อมกันไม่ได้ |
| ต้องติดตั้งบน Windows + license server | ซับซ้อนสำหรับผู้เรียนออนไลน์ |
| ผูกกับ PDK ของผู้ให้บริการ | เรียนทั่วไปไม่มี PDK ที่ตรงกับเครื่องมือ |
| ไม่มี "raw" netlist ให้ศึกษากระบวนการภายใน | เรียนรู้ไม่ได้ว่า tool ทำอะไรข้างใน |

Open-source ตอบโจทย์นี้ได้ด้วยชุดเครื่องมือที่ใช้ฟรีทั้งหมดและมี source code เปิด:

```
╔══════════════════════════════════════════════════════════════════════╗
║  Open-source ASIC Stack                                           ║
╠══════════════════════════════════════════════════════════════════════╣
║  สังเคราะห์ Logic  : Yosys            (RTL → netlist)             ║
║  Place & Route     : OpenROAD         (floorplan → routing)        ║
║  DRC               : Magic / KLayout                              ║
║  LVS               : Netgen           (schematic ↔ layout)         ║
║  Simulator         : Icarus / Verilator / Questa                   ║
╚══════════════════════════════════════════════════════════════════════╝
```

> **ประเด็นสำหรับผู้สอน:** วันที่ 3 สอน Precision RTL เพราะเป็นเครื่องมือขององค์กร
> ส่วน Yosys เป็น **ทางเลือกฟรี** ที่ให้นักเรียนฝึกกระบวนการเดียวกันโดยไม่ต้องมี license
> และยังเป็นส่วนเตรียมความพร้อมสำหรับภาค IC Layout ใน Day 6–10

#### 3.5.2 Yosys คืออะไร

Yosys เป็น **synthesis framework แบบ pass-based** ที่เขียนด้วย C++

```
Verilog ──read_verilog──► RTLIL ──proc/opt/techmap──► generic cells ──abc──► gate cells
              │              │                              │                       │
         Verilog        ภายในของ Yosys                   $_AND_ $_NAND_ ...      ต่อไปยัง PDK
              │              │                              │                       │
              └──────────────┴──────────────────────────────┴───────────────────────┘
                                    write_verilog
```

- **RTLIL** คือภาษากลาง (intermediate language) ภายในของ Yosys — ทุกอินพุตจะถูกแปลงมาเป็น RTLIL ก่อน
- แต่ละขั้นคือ **pass** หนึ่ง ๆ ที่รับ RTLIL แล้วส่งต่อ จึงเปิดและปิด pass ได้อิสระ
- ทำให้เห็นกระบวนการภายในได้ทุกขั้น ในขณะที่ commercial tool มักเป็นกล่องดำ

#### 3.5.3 ขั้นตอนการทำงานของ Yosys

คำสั่ง `synth -top <name>` จะเรียก pass ชุดนี้ตามลำดับ:

| ลำดับ | Pass | หน้าที่ |
| --- | --- | --- |
| 1 | `hierarchy` | หา top module, จัดการ parameter และ blackbox |
| 2 | `proc` | ย่อย `always`/`process` เป็น mux + flip-flop |
| 3 | `opt` | constant propagation, dead code elimination, share common term |
| 4 | `fsm` | ตรวจจับและย่อย Finite State Machine |
| 5 | `memory` | ย่อย memory เป็น flip-flop หรือ RAM cell |
| 6 | `techmap` | ย่อย operator ระดับสูง (`$add`, `$mul`) เป็น gate ระดับต่ำ |
| 7 | `abc` | **Technology Mapping** — เลือก gate และปรับขนาดให้ delay/area ดีที่สุด |
| 8 | `opt_clean` | ลบ cell ที่ไม่ได้ใช้จริง |

ตัวอย่างสคริปต์:

```tcl
read_verilog rtl/adder8.v
hierarchy -check -top adder8
synth -top adder8
tee -o build/adder8_stat.txt stat
write_verilog -noattr build/adder8_netlist.v
```

> `design -reset` ใช้ล้างสถานะเพื่อเริ่ม module ใหม่ในสคริปต์เดียว (ตามแบบที่ใช้ใน `scripts/synth_generic.ys`)

#### 3.5.4 สะพาน VHDL → Yosys ด้วย GHDL

Yosys อ่าน **Verilog เป็นหลัก** แต่คอร์สนี้สอน VHDL — ทางออกคือใช้ GHDL แปลงก่อน

```bash
# 1) วิเคราะห์
ghdl -a --std=08 rtl/adder8.vhd

# 2) สร้าง Verilog (GHDL 5.x พิมพ์ออก stdout ต้อง redirect เอง)
ghdl synth --std=08 --out=verilog adder8 > build/adder8_from_vhdl.v

# 3) ให้ Yosys อ่าน
yosys -p "read_verilog build/adder8_from_vhdl.v; hierarchy -check -top adder8; synth -top adder8; stat"
```

ทางเลือกอีกทางคือใช้ plugin `yosys-ghdl` ซึ่งมาพร้อมในชุด LibreLane:

```bash
yosys -m ghdl -p "ghdl --std=08 rtl/adder8.vhd -e adder8; prep -top adder8; synth -top adder8; stat"
```

> ⚠️ **ข้อควรระวัง:** การผ่าน GHDL อาจทำให้ **โครงสร้างของ RTL หายไป**
> (เช่น ตัวบวก 1 ตัว + mux 1 ตัว แทนที่จะเป็นตัวบวก 1 ตัวที่มี carry-in)
> ต้องตรวจ `stat` เสมอหลังแปลง — ดูหัวข้อ 3.5.7

#### 3.5.5 ABC และ Liberty — หัวใจของการ map เข้าเทคโนโลยี

**ABC** เป็นเครื่องมือย่อย logic ที่ Yosys เรียกใช้ มี 2 จุดที่ต้องรู้:

```tcl
# map เป็น gate ทั่วไป (ใช้รายการ gate ที่ ABC รองรับ)
abc -g AND,NAND,OR,NOR,XOR,XNOR,MUX
simplemap                        # แปลง cell ภายในกลับเป็น expression เพื่อ simulate ได้

# map เข้า standard cell จริงของ PDK
read_liberty -lib $SKY130_LIB    # โหลดข้อมูล cell (พื้นที่, delay, function)
dfflibmap -liberty $SKY130_LIB  # map flip-flop  ← ต้องมาก่อน abc เสมอ
abc -liberty $SKY130_LIB        # map combinational logic
stat -liberty $SKY130_LIB       # รายงานพื้นที่รวม
```

> ⚠️ **ABC ไม่รองรับ gate type `NOT`** — ถ้าใส่จะได้
> `ERROR: Command syntax error: Unsupported gate type: NOT`
> ตัว inverter ถูกสร้างขึ้นมาอัตโนมัติอยู่แล้ว

**Liberty (`.lib`)** คือไฟล์ที่บรรยายเซลล์มาตรฐานของ PDK แต่ละตัว — ชื่อเซลล์, ขา,
ฟังก์ชัน, พื้นที่, และตาราง delay เมื่อมี `area` ในไฟล์ Yosys จะรายงาน `Chip area` ได้

> ⚠️ ไฟล์ `/usr/share/yosys/cells.lib` ที่ติดมากับ Yosys มี **แต่ DFF ไม่มี gate**
> จึง map combinational logic ไม่ได้ — ต้องใช้ Liberty ของ PDK จริงเสมอ

#### 3.5.6 LibreLane — จาก netlist ถึง GDSII

Yosys จบที่ netlist ส่วน **LibreLane** (fork ของ OpenLane) ต่อ flow ที่เหลือให้ครบ

```
        RTL (Verilog)
            │
            ▼
    ┌──────────────────┐
    │ Yosys + Verilator│  synthesis → netlist
    └────────┬─────────┘
             ▼
    ┌──────────────────┐
    │ OpenROAD         │  floorplan → placement → CTS → routing
    └────────┬─────────┘
             ▼
    ┌──────────────────┐
    │ Magic / KLayout  │  DRC, GDSII
    │ Netgen           │  LVS
    └────────┬─────────┘
             ▼
       adder8_pipe.gds
```

สิ่งที่ต้องรู้เพิ่ม:

1. **ติดตั้งง่ายกว่าที่คิด** — `nix profile install nixpkgs#librelane` ดึง OpenROAD, Magic, KLayout,
   Netgen, Yosys และ yosys-ghdl มาทั้งชุดใน closure เดียว
2. **PDK ฟรี** — ใช้ `--volare-pdk -p sky130A` แล้วจะดาวน์โหลด PDK sky130A
   (open-source, Apache-2.0) ให้อัตโนมัติ
3. **config เป็น YAML** — เขียนครั้งเดียวใช้ซ้ำได้ และเปลี่ยน PDK ได้โดยไม่ต้องแก้ flow

```yaml
DESIGN_NAME: adder8_pipe
VERILOG_FILES: dir::src/*.v
CLOCK_PORT: clk
CLOCK_PERIOD: 10
PNR_SDC_FILE: dir::src/impl.sdc
SIGNOFF_SDC_FILE: dir::src/signoff.sdc
pdk::sky130*:
  FP_CORE_UTIL: 45
```

#### 3.5.7 Yosys vs Precision RTL — เปรียบเทียบเชิงวิศวกรรม

| มิติ | Yosys | Precision RTL |
| --- | --- | --- |
| License | open-source (ฟรี) | commercial (รายปี / ต่อ seat) |
| ภาษานำเข้า | Verilog (ผ่าน GHDL ได้) | VHDL, Verilog, SystemVerilog |
| รูปแบบ | pass-based, เปิดทุกขั้น | proprietary, ส่วนใหญ่เป็นกล่องดำ |
| Optimization | ABC (area/delay) | proprietary, เข้มกว่าในเชิง timing |
| Retiming | มี (`abc -dff`, `clk2fflogic`) | มี (`-retiming`) |
| Constraint | SDC (ผ่าน OpenSTA เมื่ออยู่ใน LibreLane) | SDC เต็มรูปแบบ |
| ผลลัพธ์ | netlist + gate count + area | netlist + area/timing/power report + SDF |
| ใช้ต่อ | สอง, CI, prototype, วิจัย | production flow ขององค์กร |
| เรียนรู้กระบวนการ | **เห็นทุก pass** | เห็นผลลัพธ์ |

> ทั้งสองเครื่องมือทำงานบน **หลักการเดียวกัน**: RTL → generic netlist → technology mapping →
> timing-driven optimization ต่างกันที่ความลึกของ optimization และความสมบูรณ์ของ flow

#### 3.5.8 บทเรียนสำคัญ — สไตล์ RTL มีผลต่อผลสังเคราะห์จริง

ผลจากการรันจริงด้วย Yosys 0.52 โดยใช้โค้ดที่ **ทำงานเหมือนกันทุก pattern**:

| RTL | วิธีเขียน | Yosys cells |
| --- | --- | --- |
| `adder8.v` | `assign {cout,sum} = a+b+cin` | **52** |
| `adder8.vhd` | `vs := va+vb; if cin='1' then vs := vs+1;` | **88** |

ผลลัพธ์ต่างกัน **36 cells (69 %)** ทั้งที่ฟังก์ชันเหมือนกันเป๊ะ สาเหตุคือ

```
RTL แบบ Verilog:  assign {cout,sum} = {1'b0,a} + {1'b0,b} + cin;
                    └── Yosys เห็นเป็นตัวบวก 1 ตัว พร้อม carry-in ──┘

RTL แบบ VHDL:     vs := va + vb;
                   if cin = '1' then vs := vs + 1; end if;
                    └── Yosys เห็นเป็น adder 1 ตัว + mux 1 ตัว ──────┘
```

> **บทเรียน 4 ข้อ:**
> 1. RTL ที่ "ทำงานถูก" ไม่ได้แปลว่า "สังเคราะห์ได้ดี" — รูปแบบโค้ดมีผลต่อ area และ delay
> 2. การเขียนให้ tool เข้าใจ (coding style) เป็นทักษะระดับอาชีวภาพ
> 3. **ต้องวัดผลเสมอ** — `stat` ก่อน/หลังปรับโค้ด ถ้าไม่วัดก็เป็นการเดา
> 4. VHDL ที่ผ่าน GHDL อาจสูญเสียโครงสร้าง — ต้องตรวจ `stat` เสมอหลังแปลง

---

### 3.6 ภาคปฏิบัติ: แล็บ 3B – Yosys และ LibreLane

> **เวลาใช้งาน:** 2.5–3 ชั่วโมง (ครั้งแรกให้เผื่อเวลาดาวน์โหลด PDK)
> **คู่มือฉบับเต็ม:** [`Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md`](Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md) (12 ขั้นตอน)
> **โค้ด:** [`lab_code/day3_yosys/`](lab_code/day3_yosys/)

#### 3.6.1 โครงสร้างโปรเจกต์

```
lab_code/day3_yosys/
├── Makefile                    ← จุดเริ่มต้น (make sim / make synth / ...)
├── run_yosys_lab.sh            ← batch runner รันทุกขั้น + สรุป PASS/FAIL
├── rtl/
│   ├── adder8.v                ← 8-bit adder combinational
│   ├── adder8_pipe.v           ← 8-bit adder 2-stage pipeline
│   └── adder8.vhd              ← เวอร์ชัน VHDL (สำหรับสะพาน GHDL)
├── tb/
│   ├── tb_adder8.v             ← exhaustive 131,072 patterns
│   └── tb_adder8_pipe.v        ← ตรวจ latency ของ pipeline
├── scripts/
│   ├── synth_generic.ys        ← Yosys: generic synthesis
│   ├── synth_gates.ys          ← Yosys: gate-level netlist
│   └── ghdl_to_verilog.sh      ← สะพาน VHDL → Verilog
└── librelane/
    ├── config.yaml             ← config ของ LibreLane 3.x
    └── src/{adder8_pipe.v, impl.sdc, signoff.sdc}
```

#### 3.6.2 ขั้นตอนการทำงาน (12 ขั้นตอน)

| # | ขั้นตอน | คำสั่ง | ผลลัพธ์ที่ต้องได้ |
| --- | --- | --- | --- |
| 1 | เตรียมเครื่องมือ | `yosys -V` / `iverilog -V` / `ghdl --version` / `librelane --version` | 0.52 / 12.0 / 5.0.1 / v3.0.17 |
| 2 | เข้าใจ RTL ที่จะสังเคราะห์ | อ่าน `rtl/adder8.v`, `rtl/adder8_pipe.v` | เข้าใจ latency = 1 clock |
| 3 | RTL Simulation | `make sim` | `PASS=131072 FAIL=0` |
| 4 | Generic Synthesis | `make synth` | `adder8` = 52 cells, `adder8_pipe` = 78 cells |
| 5 | Gate-Level Mapping | `make synth-gate` | `adder8` = 41 cells, `adder8_pipe` = 66 cells |
| 6 | **Gate-Level Simulation** | `make sim-gls` | ผ่าน 131,072 patterns เท่ากับ RTL ✅ |
| 7 | สะพาน VHDL | `make ghdl` | netlist จาก VHDL = 88 cells, ผ่าน 131,072 patterns |
| 8 | Map เข้า sky130 | `make sky130` | 24 cells, area **220.2112 µm²** |
| 9 | LibreLane Full Flow | `make librelane` | รันครบ **80/80 stages** |
| 10 | อ่านผลลัพธ์ | `cat runs/RUN_*/final/metrics.json` | area, slack, DRC, LVS |
| 11 | เปรียบเทียบสอง flow | เทียบตารางในหัวข้อ 3.6.3 | เข้าใจขอบเขตของแต่ละเครื่องมือ |
| 12 | แบบฝึกหัด | Y.1 – Y.8 | ตามตารางในคู่มือ |

#### 3.6.3 ผลลัพธ์จริง — ทั้งหมดมาจากการรันจริง

**Yosys (standalone)**

| Module | Generic cells | Gate cells | GLS |
| --- | --- | --- | --- |
| `adder8` | 52 | 41 | ✅ 131,072 patterns |
| `adder8_pipe` | 78 (รวม `$_SDFF_PP0_` 26) | 66 | ✅ 64 checks |
| `adder8` (จาก VHDL ผ่าน GHDL) | 88 | — | ✅ 131,072 patterns |

**Yosys → sky130 standard cell**

```
   Number of cells:                 24
     sky130_fd_sc_hd__maj3_1         8
     sky130_fd_sc_hd__xnor2_1       16

   Chip area for module '\adder8': 220.211200
```

**LibreLane (RTL → GDSII)**

| รายการ | ค่า |
| --- | --- |
| Stages | **80 / 80** ✅ |
| DRC / LVS / Antenna violations | **0 / 0 / 0** ✅ |
| Setup slack | **5.587222 ns** (0 violation) ✅ |
| Hold slack | **0.317141 ns** (0 violation) ✅ |
| Instances | 399 (stdcell 167, fill 232, buffer 44, tap 30) |
| Nets / IOs | 158 / 30 |
| Instance & core area | 2409.81 µm² |
| Die area | 4331.89 µm² (60.675 × 71.395 µm) |
| Utilization | 68.95 % |
| GDSII | `adder8_pipe.gds` 413,344 bytes |

**คำนวณ Fmax จาก slack** (เชื่อมกลับหัวข้อ 3.3):

```
   critical path = clock period - setup slack = 10 - 5.587222 = 4.412778 ns
   Fmax          = 1 / 4.412778 ns ≈ 226.6 MHz
```

#### 3.6.4 เปรียบเทียบสอง flow

| มิติ | Yosys (standalone) | LibreLane (full flow) |
| --- | --- | --- |
| สิ่งที่ได้ | netlist + cell count | netlist + layout + GDSII |
| พื้นที่ | 220.21 µm² (cell area เฉพาะ) | 2409.81 µm² (รวม fill/buffer/tap) |
| Timing | ไม่มี STA | setup 5.587 ns / hold 0.317 ns |
| DRC / LVS | ไม่มี | ผ่านทั้งคู่ |
| เวลารัน | < 1 วินาที | ~90 วินาที (หลังมี PDK) |

> **ข้อสังเกตที่ต้องอธิบายในห้องเรียน:** RTL cell count (24) **ไม่เท่ากับ**
> final instance count (399) เพราะ OpenROAD เพิ่ม fill cell, clock buffer,
> timing-repair buffer และ tap cell เพื่อให้ layout สมบูรณ์
> → "RTL cell count ≠ final chip"

#### 3.6.5 แบบฝึกหัดประจำแล็บ 3B

| ข้อ | โจทย์ | ผลที่คาดหวัง |
| --- | --- | --- |
| Y.1 | เปรียบเทียบ cell count ของ `adder8` กับ `adder8_pipe` | 52 vs 78 — เพราะ flip-flop 26 ตัว |
| Y.2 | เขียน `adder8` เวอร์ชันใหม่ที่ใช้ cell น้อยลง | cell count ลดลง — อธิบายว่าแก้อะไร |
| Y.3 | อธิบายว่าการที่ testbench เดิมผ่านทั้ง RTL และ netlist พิสูจน์อะไร | functional equivalence ในขอบเขต vector ที่ทดสอบ |
| Y.4 | รัน `make sky130` แล้วหาพื้นที่จริง | 220.2112 µm² จาก 24 cells |
| Y.5 | แก้ `CLOCK_PERIOD` เป็น 5 ns แล้วรัน LibreLane ใหม่ | Fmax สูงขึ้น หรือพบ setup violation |
| Y.6 | เปลี่ยน `FP_CORE_UTIL` เป็น 60 แล้วรันใหม่ เทียบ die area | die area เล็กลง แต่ routing ยากขึ้น |
| Y.7 | ทำ formal equivalence ระหว่าง RTL กับ netlist | `equiv_status -assert` ผ่าน |
| Y.8 | สร้าง `adder8_pipe` เวอร์ชัน VHDL แล้วส่งผ่านสะพาน GHDL | ได้ netlist ที่ผ่านทุก pattern |

---

### 3.7 ภาคปฏิบัติ: แล็บ 3 – Precision RTL

#### 3.7.1 โครงสร้างโปรเจกต์

```
lab3_synth/
├── rtl/
│   ├── adder8.vhd
│   ├── counter8.vhd
│   └── top.vhd
├── constraints/
│   └── top.sdc
├── scripts/
│   └── synth.tcl
└── reports/    (สร้างอัตโนมัติ)
```

#### 3.7.2 Precision RTL – GUI

1. `File ▸ New Project` ตั้งชื่อ ระบุ technology library (เช่น `gscl45nm`)
3. `File ▸ Add Source…` เพิ่มไฟล์ VHDL
4. ตั้ง top module: คลิกขวาไฟล์ → **Set as Top**
5. `Tools ▸ Constraints Editor` หรือ `File ▸ Add Source` เพิ่ม SDC
6. กดปุ่ม **Compile** (ไอคอนรูปสายฟ้า) เพื่อสังเคราะห์
7. ดู Reports:
   - **Area Report** – จำนวน gate, utilization
   - **Timing Report** – slack ต่อ path
   - **Power Report** – dynamic/static power
   - **Netlist** – ไฟล์ `.v` ที่ synthesize แล้ว

#### 3.7.3 Precision RTL – Batch (Tcl script)

ไฟล์ `synth.tcl`:

```tcl
# Setup
set company     "MyCompany"
set design_name "top"
set tech_lib    "/path/to/gscl45nm"

# New project
new_project -name $design_name -technology "$tech_lib"

# Add source files
add_source -type vhdl -work work  rtl/adder8.vhd
add_source -type vhdl -work work  rtl/counter8.vhd
add_source -type vhdl -work work  rtl/top.vhd

# Constraints
add_constraint_file constraints/top.sdc

# Set top
set_top_module top

# Compile
compile -incremental_mapping

# Reports
report_area   -file reports/area.rpt
report_timing -delay max -num_paths 50 -file reports/timing_max.rpt
report_timing -delay min -num_paths 50 -file reports/timing_min.rpt

# Export netlist
export_netlist -format verilog -output netlist/top_netlist.v

# Exit
exit
```

รัน:

```bash
precision -shell -file synth.tcl
```

#### 3.7.4 แก้ไข Timing Violation

ขั้นตอนเมื่อ slack เป็นลบ:

1. ดู **critical path** ใน timing report
2. วิเคราะห์ว่าเกิดจากส่วนใด (combinational, clock network, I/O)
3. เลือกวิธีแก้:
   - **Pipeline** – ใส่ register ตรงกลาง
   - **Retiming** – ย้าย FF (Precision รองรับด้วย option `-retiming`)
   - **Logic optimization** – refactor expression
   - **Relax constraints** – ตรวจสอบว่า constraint สมเหตุสมผล
   - **Floorplan-aware** – ดู congestion (เบื้องต้นไม่ลงรายละเอียด)

#### 3.7.5 แบบฝึกหัดประจำวันที่ 3

| ข้อ | โจทย์ | ผลที่คาดหวัง |
|-----|--------|----------------|
| 3.1 | สังเคราะห์ 8-bit ripple carry adder ด้วย Precision RTL | ได้ netlist + area report |
| 3.2 | ตั้ง clock period 5 ns สังเคราะห์อีกครั้ง สังเกต slack | slack เป็นลบ |
| 3.3 | แก้ไขด้วย pipelining (ใส่ register ระหว่าง full adder) | slack ≥ 0 |
| 3.4 | ลองใช้ Resource Sharing ระหว่าง adder และ subtractor | area ลดลงเทียบกับใช้สองตัวแยก |
| 3.5 | สร้าง Tcl script ที่สังเคราะห์และ export netlist อัตโนมัติ | script รันซ้ำได้ |

---

## วันที่ 4: Design Verification Using Questa (8 ชั่วโมง)

### วัตถุประสงค์ของวัน
- เลือกใช้แนวทาง Verification ที่เหมาะสมตามลักษณะการออกแบบได้
- พัฒนา Testbench แบบ Self-checking และใช้ Assertions เพื่อเพิ่มความแม่นยำในการตรวจสอบได้
- ดำเนินการ Gate-Level Simulation (GLS) พร้อมกำหนด SDF และวิเคราะห์ปัญหา Timing (Setup/Hold) ได้อย่างถูกต้อง

### โครงสร้างเวลา

| เวลา | กิจกรรม | ชม. |
| --- | --- | --- |
| 09:00 – 10:30 | บรรยาย: Verification Methodology | 1.5 |
| 10:30 – 10:45 | พัก | – |
| 10:45 – 12:00 | บรรยาย: Assertions & Functional Coverage | 1.25 |
| 12:00 – 13:00 | พักเที่ยง | – |
| 13:00 – 14:30 | บรรยาย: Gate-Level Simulation & SDF | 1.5 |
| 14:30 – 14:45 | พัก | – |
| 14:45 – 16:30 | แล็บ 4: GLS + Assertion-based TB | 1.75 |
| 16:30 – 17:00 | สรุปประจำวัน + ถาม-ตอบ | 0.5 |

---

### 4.1 ภาคทฤษฎี: Verification Methodology

#### 4.1.1 ระดับของ Verification

| ระดับ | จุดประสงค์ | เทคนิค |
| --- | --- | --- |
| Module/IP | ตรวจสอบบล็อกย่อย | Directed testing, self-checking TB |
| Subsystem/Block | ตรวจสอบการ integrate | Constrained random, assertions |
| Chip/SoC | ตรวจสอบทั้งชิป | UVM, coverage-driven, formal |
| Post-silicon | ตรวจสอบบนซิลิคอนจริง | Validation, characterization |

#### 4.1.2 Directed vs Random vs Coverage-Driven

| เทคนิค | ข้อดี | ข้อเสีย |
| --- | --- | --- |
| Directed Testing | ตรงจุด, ใช้เวลาเขียนน้อย, ง่ายต่อการ debug | ครอบคลุม corner case น้อย, ต้องเขียนเอง |
| Constrained Random | ครอบคลุม scenario กว้าง, ลดเวลาเขียน stimulus | ต้องมี checker/assertion ที่ดี, debug ยากกว่า |
| Coverage-Driven | ปิดจุดอ่อนของ random (ตรวจ coverage เพื่อปิด gap) | ต้องวางแผน + tooling สูง |

#### 4.1.3 Verification Plan (ตัวอย่าง)

```
1. Feature list extraction    – จาก spec ของ design
2. Testbench architecture      – TB, monitor, scoreboard
3. Stimulus generation plan    – directed scenarios + random seeds
4. Checker/Assertion list      – protocol + data integrity
5. Coverage model              – code/functional/coverage points
6. Sign-off criteria           – เป้า coverage ≥ X%
```

---

### 4.2 ภาคทฤษฎี: Assertions

Assertion คือ property ที่ระบุไว้ใน design หรือ testbench เพื่อให้เครื่องมือตรวจสอบ property นั้นระหว่าง simulation (หรือ formal ในกรณี formal verification)

#### 4.2.1 ตัวอย่าง VHDL Assertion (Concurrent)

```vhdl
-- request ต้องคงสถานะสูงจนกว่า grant จะขึ้น
assert_request_high : assert always
    (req = '1') ->
    (req = '1') until (gnt = '1')
    report "REQ must remain high until GNT"
    severity failure;
```

#### 4.2.2 Immediate vs Concurrent Assertion

| ประเภท | ทำงานเมื่อ | ใช้กับ |
| --- | --- | --- |
| Immediate (`assert ... report ... severity ...`) | รันทันทีใน process | ตรวจสอบ simple condition |
| Concurrent (PSL/SVA) | ตรวจตลอดเวลา simulation | property ที่ซับซ้อน, multi-cycle |

#### 4.2.3 Functional Coverage

Questa รองรับ Functional Coverage ผ่าน SystemVerilog covergroup หรือใช้ PSL cover ใน VHDL:

```sv
covergroup cg_alu @(posedge clk);
    cp_op : coverpoint op {
        bins add = {2'b00};
        bins sub = {2'b01};
        bins AND = {2'b10};
        bins OR  = {2'b11};
    }
    cp_flags : coverpoint {flags_z, flags_n} {
        bins zero  = {2'b10};
        bins neg   = {2'b01};
        bins other = default;
    }
    cross cp_op, cp_flags;
endgroup
```

รายงาน coverage ใน Questa: `Tools ▸ Coverage Report`

---

### 4.3 ภาคทฤษฎี: Gate-Level Simulation (GLS)

#### 4.3.1 จุดประสงค์

- ตรวจสอบฟังก์ชันหลัง synthesis (logic-level correctness)
- ตรวจสอบ timing violation (Setup/Hold) ด้วย SDF back-annotation
- ตรวจสอบ X-propagation, glitch, race condition

#### 4.3.2 SDF (Standard Delay Format)

SDF เป็นไฟล์ที่บรรจุ delay ของ cell และ interconnect ที่ได้จาก P&R (หรือจาก synthesis tool รุ่นที่ทำ delay estimation ได้)

โครงสร้าง:

```
(CELL
  (CELLTYPE "DFFRX1")
  (INSTANCE counter_reg[3])
  (DELAY
    (ABSOLUTE
      (IOPATH clk Q (0.18) (0.20))
    )
  )
)
```

#### 4.3.3 Simulation Flow

```
Netlist (gate-level) + SDF ──► Compiled to simulator ──► Run TB ──► Check output
                  │
                  └──► (optional) + parasitics + power intent
```

ใน Questa:

1. Compile netlist จาก Precision RTL เป็น Verilog (ถ้า netlist เป็น Verilog) หรือ VHDL
2. โหลด SDF: `vsim -sdf {/top/u1} = top.sdf top`
4. รัน testbench เดิม
6. ตรวจดู X-propagation และ timing violation ใน transcript

---

### 4.4 ภาคปฏิบัติ: แล็บ 4 – Verification ด้วย Questa

#### 4.4.1 Lab 4-1: Self-Checking Testbench + Assertion

ใช้ FSM จากวันที่ 2 เพิ่ม concurrent assertion:

```vhdl
-- ในไฟล์ tb_seq_moore_assert.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_seq_moore_assert is
end entity tb_seq_moore_assert;

architecture sim of tb_seq_moore_assert is
    signal clk, rst, din, detected : std_logic;
    signal err_cnt : integer := 0;
begin
    dut : entity work.seq_det_moore
        port map (clk, rst, din, detected);

    clk <= not clk after 5 ns;

    stim : process
    begin
        rst <= '1'; din <= '0';
        wait for 25 ns;
        rst <= '0';
        din <= '1'; wait for 10 ns;
        din <= '0'; wait for 10 ns;
        din <= '1'; wait for 10 ns;
        din <= '1'; wait for 10 ns;
        wait for 100 ns;
        report "Error count = " & integer'image(err_cnt);
        std.env.stop;
    end process;

    -- Concurrent check
    chk : process (clk)
        variable prev_d : std_logic := '0';
    begin
        if rising_edge(clk) then
            if detected = '1' and prev_d = '1' then
                report "Glitch detected on detected signal"
                    severity warning;
            end if;
            prev_d := detected;
        end if;
    end process;
end architecture sim;
```

#### 4.4.2 Lab 4-2: Gate-Level Simulation

ใช้ netlist จาก Precision RTL เป็น DUT แทน RTL:

```tcl
# compile_netlist.do
vlib work_gate
vlog -work work_gate netlist/top_netlist.v
vcom -work work_gate rtl/tb_seq_moore.vhd
vsim -sdf /tb_seq_moore/dut=netlist/top.sdf work_gate.tb_seq_moore
add wave *
run 500 ns
```

หรือใน batch:

```tcl
# run_gls.do
vlib work
vlog netlist/top_netlist.v
vcom rtl/tb_seq_moore.vhd
vsim -c -do "add wave *; run 1 us; quit -f" \
     -sdf /tb_seq_moore/dut=top.sdf work.tb_seq_moore
```

#### 4.4.3 Setup/Hold Violation Detection

หาก GLS แสดง `'X'` บนสัญญาณ output หรือ FF ภายใน โดยที่ RTL simulation ปกติดี:
- ตรวจดู SDF – delay ที่มากเกินไปอาจทำให้ setup violation
- ดู transcript – Questa จะพิมพ์ `** Warning: Setup violation ...`
- แก้ไขโดยเพิ่ม clock period หรือ refactor critical path

#### 4.4.4 แบบฝึกหัดประจำวันที่ 4

| ข้อ | โจทย์ | ผลที่คาดหวัง |
|-----|--------|----------------|
| 4.1 | พัฒนา self-checking TB ของ 8-bit ALU (add, sub, AND, OR) โดยใช้ reference model | PASS = 64 |
| 4.2 | เพิ่ม concurrent assertion ตรวจสอบ data ready/valid handshake | assertion ผ่านตลอด |
| 4.3 | ทำ GLS ของ ALU ด้วย netlist + SDF เปรียบเทียบกับ RTL sim | ผลลัพธ์ตรงกันเมื่อไม่มี timing violation |
| 4.4 | บังคับให้ setup violation เกิด (ลด clock period) แล้วสังเกต warning | เห็น warning ใน transcript |
| 4.5 | สร้าง covergroup ตรวจสอบ coverage ของ ALU operations | coverage 100% |

---

## วันที่ 5: Mini Project – Digital IC Design and Verification Flow (8 ชั่วโมง)

### วัตถุประสงค์ของวัน
- ดำเนินกระบวนการออกแบบและตรวจสอบ Digital IC แบบครบวงจรตั้งแต่ RTL ไปจนถึง Gate-Level Simulation ได้
- ออกแบบและพัฒนา Testbench พร้อมตรวจสอบผลการทำงานผ่าน Simulation และวิเคราะห์ Timing ได้
- จัดทำรายงานผลการออกแบบและ Verification พร้อมนำเสนอและอธิบายผลลัพธ์ได้อย่างมีประสิทธิภาพ
- เข้าใจขั้นตอน RTL-to-GDSII (floorplan → placement → CTS → routing → DRC/LVS → GDSII) และอ่านผลลัพธ์ได้
- ส่ง Mini Project ผ่าน Open-source ASIC flow จนได้ GDSII พร้อมผล DRC/LVS จริง

### โครงสร้างเวลา — แผนมาตรฐาน (8 ชั่วโมง)

| เวลา | กิจกรรม | หัวข้อ | ชม. |
| --- | --- | --- | --- |
| 09:00 – 10:00 | บรรยาย: สรุป ASIC Flow + Verification Plan | 5.1, 5.2 | 1.0 |
| 10:00 – 10:15 | พัก | – | – |
| 10:15 – 12:00 | Mini Project – ออกแบบ RTL | 5.3 | 1.75 |
| 12:00 – 13:00 | พักเที่ยง | – | – |
| 13:00 – 14:30 | Mini Project – Verification + Synthesis | 5.3 | 1.5 |
| 14:30 – 14:45 | พัก | – | – |
| 14:45 – 16:30 | Mini Project – GLS + Debug + รายงาน | 5.3 | 1.75 |
| 16:30 – 17:00 | นำเสนอผลงาน + ถาม-ตอบ + สรุปหลักสูตร | – | 0.5 |

### โครงสร้างเวลา — แผนขยาย (เพิ่ม 1 ครึ่งวันสำหรับหัวข้อ Open-source)

> เนื้อหา 5.4 (ทฤษฎี RTL-to-GDSII) + 5.5 (แล็บ 5B) ใช้เวลาประมาณ **4 ชั่วโมง**
> จึงแนะนำให้แยกเป็น **ครึ่งวันที่สอง** หรือทำเป็น **คายนอกเวลา**
> — แล็บ 5B ใช้เครื่องมือ open-source ทั้งหมด ไม่ต้องมี commercial license
> หรือ PDK ขององค์กร และส่ง Mini Project จนถึง GDSII ได้จริง

| เวลา | กิจกรรม | หัวข้อ | ชม. |
| --- | --- | --- | --- |
| 09:00 – 10:30 | บรรยาย: RTL-to-GDSII Full Chip Flow — floorplan, P&R, CTS | 5.4 | 1.5 |
| 10:30 – 10:45 | พัก | – | – |
| 10:45 – 12:00 | บรรยาย: Sign-off (DRC/LVS/Antenna) + การอ่าน `metrics.json` | 5.4 | 1.25 |
| 12:00 – 13:00 | พักเที่ยง | – | – |
| 13:00 – 15:30 | แล็บ 5B: Yosys + GLS + LibreLane (Mini Project UART TX → GDSII) | 5.5 | 2.5 |
| 15:30 – 16:30 | เปิดดู GDSII + เทียบผลกับ Precision RTL + ถาม-ตอบ | 5.5 | 1.0 |
| 16:30 – 17:00 | สรุปประจำวัน | – | 0.5 |

> **ข้อกำหนดสำหรับห้องเรียน:** ต้องเตรียมเครื่องที่มี Linux/WSL พร้อม Yosys, Icarus Verilog
> และ LibreLane (ติดตั้งผ่าน nix) รวมถึงเครือข่ายสำหรับดาวน์โหลด PDK sky130A (~1–2 GB)
> ดูวิธีติดตั้งที่ [`lab_code/day5_yosys/librelane/README.md`](lab_code/day5_yosys/librelane/README.md)

---

### 5.1 ภาคทฤษฎี: ASIC Flow Integration (สรุปจากวันที่ 1-4)

```
┌───────────────────────────────────────────────────────────────────┐
│ 1. SPEC          : กำหนด functional spec, interface, timing       │
│ 2. RTL DESIGN    : VHDL/Verilog ตาม coding style                  │
│ 3. RTL SIM       : self-checking TB + assertions (Questa)         │
│ 4. SYNTHESIS     : Precision RTL (RTL → Netlist + Constraints)    │
│ 5. GLS           : Questa + SDF back-annotation                   │
│ 6. SIGN-OFF      : coverage, timing report, final report          │
└───────────────────────────────────────────────────────────────────┘
```

### 5.2 ภาคทฤษฎี: Verification Plan & Sign-off

Verification Plan ต้องครอบคลุม:
1. **Feature list** – จาก functional spec
2. **Stimulus plan** – กรณีทดสอบที่ต้องครอบคลุม
3. **Checker & Assertion** – ตรวจอะไร, property อะไร
4. **Coverage goals** – code coverage ≥ 95%, functional coverage ≥ 95%
5. **Corner cases** – boundary, reset, error injection
6. **Pass criteria** – เกณฑ์ผ่าน (เช่น no X, no error, coverage ถึงเป้า)

### 5.3 ภาคปฏิบัติ: Mini Project – ตัวอย่างโจทย์และแนวทาง

#### 5.3.1 ตัวอย่างโจทย์ (เลือก 1 ใน 3)

**โจทย์ A: UART Transceiver (TX only)**
- Baud rate generator (programmable divisor)
- 8-N-1 frame
- Self-checking TB ทดสอบ pattern ต่าง ๆ
- สังเคราะห์ด้วย Precision RTL แล้วทำ GLS

**โจทย์ B: SPI Master**
- Configurable clock divider
- CPOL/CPHA selectable
- 8/16-bit transaction
- Scoreboard เปรียบเทียบ MOSI กับ pattern ที่คาดหวัง

**โจทย์ C: Simple MAC (เน้น FSM-heavy)**
- FSM สำหรับ packet handling
- CRC8 checker
- Constrained random stimulus
- Functional coverage ของ packet type

#### 5.3.2 ตัวอย่างโครงสร้างโปรเจกต์ (โจทย์ A – UART TX)

```
mini_project/
├── spec/uart_spec.md
├── rtl/
│   ├── baud_gen.vhd
│   ├── uart_tx.vhd
│   └── uart_top.vhd
├── tb/
│   ├── tb_uart_top.vhd
│   └── ref_model.vhd
├── constraints/
│   └── uart.sdc
├── scripts/
│   ├── synth.tcl
│   └── run_gls.do
└── report/
    └── final_report.md
```

#### 5.3.3 ตัวอย่าง RTL – UART TX (แนะนำ)

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        din      : in  std_logic_vector(7 downto 0);
        din_vld  : in  std_logic;
        din_rdy  : out std_logic;
        tx       : out std_logic
    );
end entity uart_tx;

architecture rtl of uart_tx is
    type state_t is (IDLE, START, DATA, STOP);
    signal state    : state_t;
    signal baud_cnt : integer range 0 to 100;
    signal bit_cnt  : integer range 0 to 8;
    signal data_reg : std_logic_vector(7 downto 0);
begin
    sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state    <= IDLE;
                baud_cnt <= 0;
                bit_cnt  <= 0;
                data_reg <= (others => '0');
                tx       <= '1';      -- idle line
                din_rdy  <= '1';
            else
                case state is
                    when IDLE =>
                        tx <= '1';
                        din_rdy <= '1';
                        if din_vld = '1' then
                            data_reg <= din;
                            state    <= START;
                            baud_cnt <= 0;
                            din_rdy  <= '0';
                        end if;
                    when START =>
                        if baud_cnt = 86 then  -- assume 100MHz / 115200 ~ 868
                            tx       <= '0';
                            baud_cnt <= 0;
                            state    <= DATA;
                            bit_cnt  <= 0;
                        else
                            baud_cnt <= baud_cnt + 1;
                        end if;
                    when DATA =>
                        if baud_cnt = 86 then
                            baud_cnt <= 0;
                            tx <= data_reg(bit_cnt);
                            if bit_cnt = 7 then
                                state <= STOP;
                            else
                                bit_cnt <= bit_cnt + 1;
                            end if;
                        else
                            baud_cnt <= baud_cnt + 1;
                        end if;
                    when STOP =>
                        if baud_cnt = 86 then
                            state    <= IDLE;
                            baud_cnt <= 0;
                            tx       <= '1';
                        else
                            baud_cnt <= baud_cnt + 1;
                            tx       <= '1';
                        end if;
                end case;
            end if;
        end if;
    end process;
end architecture rtl;
```

#### 5.3.4 ตัวอย่าง Self-Checking Testbench + Scoreboard

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_uart_tx is
end entity tb_uart_tx;

architecture sim of tb_uart_tx is
    constant CLK_PERIOD : time := 10 ns;
    signal clk, rst          : std_logic;
    signal din               : std_logic_vector(7 downto 0);
    signal din_vld, din_rdy  : std_logic;
    signal tx                : std_logic;
    signal pass_cnt, fail_cnt : integer := 0;

    -- Scoreboard queue
    type q_byte_arr is array (natural range <>) of std_logic_vector(7 downto 0);
    signal expected_q : q_byte_arr(0 to 63);
    signal q_head, q_tail : integer := 0;
begin
    dut : entity work.uart_tx
        port map (clk => clk, rst => rst,
                  din => din, din_vld => din_vld, din_rdy => din_rdy,
                  tx => tx);

    clk <= not clk after CLK_PERIOD / 2;

    -- Scoreboard checker (observe TX bit-by-bit)
    checker : process
        variable cnt_baud : integer := 0;
        variable bit_idx  : integer := 0;
        variable cur_byte : std_logic_vector(7 downto 0) := (others => '0');
        variable bits_collected : integer := 0;
    begin
        wait until rst = '0';
        wait until rising_edge(clk);

        loop
            wait until rising_edge(clk);
            -- simple: assume baud is multiple of CLK_PERIOD; count edges
            exit when false;
        end loop;
    end process;
```

หมายเหตุ: Scoreboard ที่สมบูรณ์ควรนับ baud tick จริง ๆ ตัวอย่างนี้เป็นเพียง skeleton ให้นักเรียนเขียนต่อใน Lab

#### 5.3.5 Verification Plan ตัวอย่าง

| Feature | Test Scenario | Pass Criteria |
| --- | --- | --- |
| Reset | rst=1 for 5 cycles | tx=1, din_rdy=1 |
| Transmit 0x55 | send 0x55, observe 10 bits | start=0, bits=01010101, stop=1 |
| Back-to-back | send 0x55, 0xAA, 0x00, 0xFF | no extra bits between |
| Glitch protection | change din during transmission | behavior unchanged |
| Coverage | functional coverage of all byte values | ≥ 95% |

#### 5.3.6 Synthesis + GLS

ใช้ Tcl script จากวันที่ 3 ปรับชื่อ module + ใช้ SDC ที่ clock 100 MHz

```tcl
create_clock -name sys_clk -period 10 [get_ports clk]
set_input_delay  -clock sys_clk 2.0 [get_ports {din din_vld rst}]
set_output_delay -clock sys_clk 2.0 [get_ports {tx din_rdy}]
set_false_path -from [get_ports rst]
```

> **ทางเลือกสำหรับนักเรียนที่ไม่มี PDK ขององค์กร:** ใช้ Yosys + Icarus Verilog ตามหัวข้อ 3.5–3.6
> แทน Precision RTL — สังเคราะห์เป็น netlist แล้วทำ GLS ด้วย testbench ไฟล์เดิมได้เลย
> (ส่วน SDF ต้องใช้ของ LibreLane หรือขอจากองค์กร) ดู [`lab_code/day3_yosys/`](lab_code/day3_yosys/)
>
> **ถ้าต้องการไปถึง GDSII:** ใช้ LibreLane ตามหัวข้อ 5.4–5.5
> — ส่ง Mini Project UART TX ผ่าน full chip flow จนได้ GDSII พร้อม DRC/LVS ผ่าน
> ดู [`lab_code/day5_yosys/`](lab_code/day5_yosys/)

รัน GLS แล้วบันทึก waveform เพื่อแนบในรายงาน

#### 5.3.7 Final Verification Report (Template)

ไฟล์ `report/final_report.md`:

```markdown
# Mini Project Report – UART TX

## 1. Design Specification
- Baud rate: 115200
- Frame: 8-N-1
- Clock: 100 MHz

## 2. RTL Design
ไฟล์ rtl/uart_tx.vhd – รายละเอียด state machine

## 3. Verification
- TB: self-checking with scoreboard
- Coverage: code coverage = X%, functional coverage = Y%
- Corner cases ที่ทดสอบ:
  1. reset
  2. byte ทุกค่า 0x00 – 0xFF
  3. back-to-back transmission

## 4. Synthesis Result
- Area: จำนวน gate = X
- Target clock: 10 ns
- Worst slack: Y ns

## 5. Gate-Level Simulation
- SDF back-annotation: ผ่าน
- Setup/Hold: ไม่มี violation

## 6. Conclusion
อธิบายผลลัพธ์และข้อเสนอแนะ
```

#### 5.3.8 แบบฝึกหัดประจำวันที่ 5 (Mini Project Checklist)

| Item | Description | Done |
| --- | --- | --- |
| 1 | RTL design (เลือก 1 โจทย์) | ☐ |
| 2 | Self-checking testbench | ☐ |
| 3 | Functional coverage ≥ 95% | ☐ |
| 4 | Synthesis with constraints (Precision RTL) | ☐ |
| 5 | Gate-Level Simulation with SDF | ☐ |
| 6 | Final report + นำเสนอ 5 นาที | ☐ |

---

### 5.4 ภาคทฤษฎี: RTL-to-GDSII Full Chip Flow (Open-source)

> **เวลาบรรยาย:** 90–120 นาที
> **คู่มือเชิงลึก:** [`Manual_5_4_RTL_to_GDSII_LibreLane_FullChipFlow_DeepDive.md`](Manual_5_4_RTL_to_GDSII_LibreLane_FullChipFlow_DeepDive.md) (19 หัวข้อ)

#### 5.4.1 ทำไมต้องต่อจาก netlist

วันที่ 3 และวันที่ 5 ฝั่ง commercial จบที่ **netlist** ซึ่งยังไม่ใช่ "ชิป"

| สิ่งที่ได้จาก RTL Synthesis | สิ่งที่ยังขาดก่อนส่ง foundry |
| --- | --- |
| netlist ของ standard cell | ตำแหน่งจริงของ cell บนซิลิกอน (placement) |
| พื้นที่โดยประมาณ (cell area) | การเชื่อมต่อด้วยโลหะ (routing) |
| ความเร็วโดยประมาณ (combinational delay) | delay จริงหลัง routing (wire delay, parasitic) |
| จำนวน flip-flop | power grid, tap cell, fill cell |
| — | **DRC** — ข้อบังคับด้านการผลิต |
| — | **LVS** — ยืนยันว่า layout ตรงกับ schematic |
| — | **GDSII** — ไฟล์ที่ foundry รับ |

#### 5.4.2 ภาพรวม RTL-to-GDSII

```
        ┌─────────────────────┐
        │  RTL (Verilog)      │  uart_top.v
        └──────────┬──────────┘
                   │
    ┌──────────────▼───────────────┐
    │ Verilator lint               │  syntax, width, undriven
    │ Yosys synthesis               │  RTL → RTLIL → netlist
    └──────────────┬───────────────┘
                   │  netlist (standard cell)
    ┌──────────────▼───────────────┐
    │ OpenROAD                     │
    │   ├ floorplan                │  core/die, PDN, rows
    │   ├ global + detailed place  │  จัดวาง cell
    │   ├ CTS                       │  สร้าง clock tree + balance skew
    │   ├ global + detailed routing│  เชื่อมต่อ + DRC
    │   └ fill insertion            │  เติม dummy cell
    └──────────────┬───────────────┘
                   │
    ┌──────────────▼───────────────┐
    │ Magic / KLayout               │  DRC, GDSII stream-out, render
    │ Netgen                        │  LVS (netlist ↔ layout)
    │ OpenSTA                       │  multi-corner timing
    └──────────────┬───────────────┘
                   │
        ┌──────────▼──────────┐
        │  uart_top.gds       │  ← ส่ง foundry
        └─────────────────────┘
```

#### 5.4.3 LibreLane — orchestrator ของ flow

LibreLane เป็น **open-source ASIC design flow** ที่รวมเครื่องมือทั้งชุดไว้ในตัวเดียว
(ต่อยอดจาก OpenLane 2.0 ของ Efabless)

| ขั้นตอน | เครื่องมือ | หน้าที่ |
| --- | --- | --- |
| lint | Verilator | ตรวจ syntax, width mismatch, undriven signal |
| synthesis | Yosys (มี `yosys-ghdl`) | RTL → netlist |
| floorplan / P&R / CTS | OpenROAD + OpenSTA | วางและเชื่อมต่อวงจร |
| DRC | Magic + KLayout | ตรวจข้อบังคับด้านการผลิต (สองเครื่องมือตรวจซ้ำกัน) |
| GDSII | Magic + KLayout | stream-out |
| LVS | Netgen | เทียบ schematic ↔ layout |

**ติดตั้งแบบคำสั่งเดียว** — nix ดึงทุกเครื่องมือมาใน closure เดียวกัน:

```bash
nix profile install nixpkgs#librelane
export PATH="$HOME/.nix-profile/bin:$PATH"
librelane --version     # → LibreLane v3.0.17
```

> ⚠️ **nix profile ไม่ถูกโหลดอัตโนมัติใน non-interactive shell** จึงได้
> `librelane: command not found` แม้ติดตั้งแล้ว — สคริปต์ของแล็บตรวจและเพิ่ม PATH ให้เอง

#### 5.4.4 80 stages — เห็นกระบวนการทั้งหมดแบบมีชื่อ

```
กลุ่มงาน                        ตัวอย่าง stage
─────────────────────────────   ─────────────────────────────────────
ตรวจคุณภาพ RTL         01-04   verilator lint, lint checker
สังเคราะห์              05-09   yosys json, yosys synthesis, unmapped cells check
ตรวจ SDC / macro        10-12   openroad check SDC, check macro instances, sta prep
วาง floorplan           13-23   floorplan, die area, cut rows, tap, PDN
วางตำแหน่ง             24-34   IO placement, global placement, detailed placement
สร้าง clock tree        35-38   CTS, resizer, STA
เชื่อมต่อ                39-51   global routing, antenna, detailed routing
เติมและสกัด            52-56   fill insertion, RCX (parasitic), STA post-PnR
ส่งออก GDSII            57-63   magic stream-out, klayout stream-out, magic LEF
ตรวจ DRC                64-67   magic DRC, klayout DRC, checker ทั้งสองฝั่ง
สกัดและ LVS            68-71   magic spice extraction, netgen LVS
ตรวจ timing & sign-off  72-76   setup/hold/maxslew/maxcap, report manufacturability
```

#### 5.4.5 Floorplan — core area vs die area

```
    ┌─────────────────────────────────────────────┐
    │                 DIE (ทั้งหมด)                │  ← รวมรอบขอบ + power ring
    │  ┌───────────────────────────────────────┐  │
    │  │              CORE                     │  │  ← พื้นที่ที่วาง cell ได้จริง
    │  │        (วงจร + routing)               │  │
    │  └───────────────────────────────────────┘  │
    │   ↑ power ring (M1/M2) รอบ core             │
    └─────────────────────────────────────────────┘
```

| ปริมาณ | ความหมาย | ค่าที่วัดได้ (uart_top) |
| --- | --- | --- |
| Core area | พื้นที่ที่ใช้วางวงจรได้ (µm²) | 2805.19 |
| Die area | พื้นที่ทั้งหมดรวมรอบขอบและ power ring (µm²) | **4975.42** |
| Utilization | instance area ÷ core area | **60.12 %** |
| Core bbox | กรอบสี่เหลี่ยมของ core (µm) | `5.52 10.88 59.8 62.56` |

> die area มากกว่า core area ถึง **1.77 เท่า** เพราะมีรอบ power ring และพื้นที่ว่างรอบ core
> การคิด "พื้นที่ชิป = พื้นที่วงจร" จึงผิด — ต้องดูทั้งสองค่า

**`FP_CORE_UTIL` มีผลอย่างไร**

```yaml
pdk::sky130*:
  FP_CORE_UTIL: 45    # % ของ core area ที่จะใช้วาง cell จริง
```

- ค่า **สูง** → core เล็ก → die เล็ก → ถนัด แต่ routing ยาก → DRC violation ง่าย
- ค่า **ต่ำ** → core ใหญ่ → routing สบาย แต่พื้นที่ชิปเปลือง

กับ `uart_top` ที่ใช้ `FP_CORE_UTIL: 45` ได้ utilization จริง **60.12 %**
(สูงกว่า 45 เพราะ OpenROAD เติม buffer/fill/tap เพิ่มในขั้น CTS และ routing repair)

#### 5.4.6 CTS — Clock Tree Synthesis

```
ก่อน CTS (ideal clock):            หลัง CTS (real clock):
    clk ──┬── FF1                       clk
          ├── FF2                       │
          └── FF3                       ├── buf ── buf ── FF1
                                         ├── buf ── FF2
   ทุก FF เห็นขอบ clock พร้อมกัน       └── buf ── FF3
   (ใช้ไม่ได้จริง)                  แต่ FF ที่ปลายสายได้รับ clock ช้ากว่า
                                       → เกิด clock skew
```

| ปริมาณ | ค่าที่วัดได้ (uart_top) |
| --- | --- |
| `clock__skew__worst_setup` | 0.002564 ns |
| `clock__skew__worst_hold` | 0.006135 ns |
| clock buffer | 3 ตัว |

#### 5.4.7 Power Distribution Network

```
   ┌───────────────────────────────────────────┐
   │ ══════════════════════════════════════════ │ ← M2 horizontal (VDD)
   │ ───────────────────────────────────────── │ ← M1 vertical  (VSS)
   │ ══════════════════════════════════════════ │ ← M2 horizontal (VDD)
   │ ───────────────────────────────────────── │ ← M1 vertical  (VSS)
   └───────────────────────────────────────────┘
        power ring รอบ core
```

| Key | ค่าที่วัดได้ |
| --- | --- |
| `design__power_grid_violation__count` | **0** |
| tap cell | 42 ตัว (52.55 µm²) |

> **tap cell** คือ cell ที่ยึด substrate / well tie ให้กับราง VSS
> ถ้าไม่มี tap cell จะเกิด latch-up — เป็นเหตุผลที่ layout จริงต้องมีมากกว่า cell ใน RTL

#### 5.4.8 Sign-off: DRC / LVS / Antenna

สามเรื่องนี้คือ **เกณฑ์ขั้นต่ำที่ foundry จะตรวจก่อนรับงาน**

| ตรวจ | ความหมาย | ผลที่วัดได้ |
| --- | --- | --- |
| **DRC** | layout ผลิตได้จริง (ระยะห่างโลหะ, ขนาด wire, via) — ตรวจ 2 ครั้งด้วย Magic และ KLayout | violations **0** ✅ |
| **LVS** | layout ตรงกับ schematic — เทียบ device / net / pin | error **0**, diff **0/0/0** ✅ |
| **Antenna** | net ต่อกับ poly มากเกินไปจน gate หลุด | net **0**, pin **0** ✅ |

#### 5.4.9 การอ่านผลลัพธ์ — `metrics.json`

```bash
RUN=$(ls -dt runs/RUN_* | head -1)
python3 -c "
import json
m = json.load(open('$RUN/final/metrics.json'))
print('instances :', m.get('design__instance__count'))
print('die area  :', m.get('design__die__area'), 'um^2')
print('setup ws  :', m.get('timing__setup__ws'), 'ns')
print('hold ws   :', m.get('timing__hold__ws'), 'ns')
print('violations:', m.get('design__violations'))
"
```

Key ที่ต้องรู้ (ค่าที่วัดได้จริง):

| Key | ความหมาย | ค่า |
| --- | --- | --- |
| `design__instance__count` | instance ทั้งหมดใน layout | **526** |
| `design__instance__area` | พื้นที่ instance (µm²) | **2805.19** |
| `design__die__area` | พื้นที่ die (µm²) | **4975.42** |
| `design__instance__utilization` | สัดส่วนที่ใช้ | 0.601249 |
| `design__nets` / `design__io` | net / ขา | 153 / 15 |
| `design__violations` | violation รวม | **0** |
| `design__inferred_latch__count` | latch ที่ถูกอนุมาน | **0** |
| `timing__setup__ws` | worst setup slack (ns) | **6.235697** |
| `timing__hold__ws` | worst hold slack (ns) | **0.191574** |
| `antenna__violating__nets` / `__pins` | antenna violation | 0 / 0 |
| `design__lvs_error__count` | LVS error | **0** |
| `power__total` | กำลังรวม (W) | 0.00030398 (303.98 µW) |

#### 5.4.10 Multi-corner Analysis

ชิปจริงทำงานที่ PVT ต่างกัน — flow จึงต้องผ่านทุก corner

| มิติ | ค่า |
| --- | --- |
| Process | slow (ss) / typical (tt) / fast (ff) |
| Voltage | 1.60 V (ss) / 1.80 V (tt) / 1.95 V (ff) |
| Temperature | 100 °C (ss) / 25 °C (tt) / −40 °C (ff) |

ชื่อ corner ที่ได้: `{min,nom,max}_{ff,tt,ss}_{n40C,025C,100C}_{1v95,1v80,1v60}`

| Corner | setup slack (ns) | hold slack (ns) |
| --- | --- | --- |
| `min_ff_n40C_1v95` | 8.965368 | **0.191574** ← worst hold |
| `nom_ff_n40C_1v95` | 8.958746 | 0.194052 |
| `max_ff_n40C_1v95` | 8.951070 | 0.194872 |
| `min_tt_025C_1v80` | 8.300024 | 0.308719 |
| `nom_tt_025C_1v80` | 8.289632 | 0.312889 |
| `max_tt_025C_1v80` | 8.277832 | 0.315234 |
| `min_ss_100C_1v60` | 6.274457 | 0.618923 |
| `nom_ss_100C_1v60` | 6.256837 | 0.626525 |
| **`max_ss_100C_1v60`** | **6.235697** ← worst setup | 0.632267 |

> **setup แย่ที่สุดที่ slow process + ร้อน + แรงดันต่ำ**
> **hold แย่ที่สุดที่ fast process + เย็น** — ตรงข้ามกัน เพราะ cell เร็วขึ้น → data วิ่งถึงเร็วขึ้น

#### 5.4.11 บทเรียน: Yosys เปลี่ยนโครงสร้าง design เอง

สิ่งที่เขียนไว้ในโค้ดคือ `reg [1:0] state` (FSM 4 สถานะ = 2 บิต)
แต่ Yosys สร้าง **4 flip-flop** สำหรับ state จริง ๆ

```
  cell $_DFF_P_ $auto$ff.cc:266:slice$356
    connect \C \clk
    connect \D $abc$765$auto$fsm_map.cc:170:map_fsm$115[0]
    connect \Q \u_tx.state [0]
  end
  ... (อีก 3 ตัว)
```

| | โค้ดเดิม | ผลของ Yosys |
| --- | --- | --- |
| จำนวนบิตของ state | 2 | **4** |
| การเข้ารหัส | binary | **one-hot** (`map_fsm$115[0..3]`) |
| reset | มี | **ไม่มี** (`$_DFF_P_` = plain D flip-flop) |
| flip-flop รวม | 26 | **28** |

> **`fsm` pass ของ Yosys ตรวจจับ FSM แล้วเปลี่ยน encoding เป็น one-hot**
> แลกกับ flip-flop เพิ่ม 2 ตัว แต่ logic decode ของ FSM เล็กลง
> และ **ไม่ต้องใช้ reset อีกต่อไป**
>
> **บทเรียน:** RTL ที่คุณเขียน ไม่ใช่สิ่งที่ถูกสังเคราะห์ — ต้องอ่าน output ของ tool
> ไม่ใช่เชื่อรายงาน

#### 5.4.12 ⚠️ ข้อจำกัดของ slack ที่วัดได้

| ปัจจัย | สถานะในแล็บนี้ | ผลต่อตัวเลข |
| --- | --- | --- |
| I/O delay | ตั้งเป็น **0 ns** | slack สูงกว่าความจริง |
| Clock uncertainty / jitter | **ไม่ได้ตั้ง** | slack สูงกว่าความจริง |
| Clock tree จริง | มี (OpenROAD สร้าง) | รวมแล้ว ✅ |
| Routing delay จริง | มี (จาก detailed routing + RCX) | รวมแล้ว ✅ |
| Multi-corner | 9 corners | รวมแล้ว ✅ |

> ตัวเลขเหล่านี้เป็น "slack ของ design ที่ยังไม่มีข้อกำหนดระบบภายนอก"
> ในงานจริงต้องใส่ I/O delay ตามสเปกและ clock uncertainty ก่อนจึงจะเรียกว่า sign-off ได้

---

### 5.5 ภาคปฏิบัติ: แล็บ 5B – Mini Project จนถึง GDSII

> **เวลาใช้งาน:** 3–3.5 ชั่วโมง (ครั้งแรกให้เผื่อเวลาดาวน์โหลด PDK)
> **คู่มือฉบับเต็ม:** [`Manual_5_5_Lab5B_UART_TX_to_GDSII_LibreLane_StepByStepGuide.md`](Manual_5_5_Lab5B_UART_TX_to_GDSII_LibreLane_StepByStepGuide.md) (12 ขั้นตอน)
> **โค้ด:** [`lab_code/day5_yosys/`](lab_code/day5_yosys/)

#### 5.5.1 โครงสร้างโปรเจกต์

```
lab_code/day5_yosys/
├── Makefile                    ← จุดเริ่มต้น (make sim / make synth / ...)
├── run_yosys_lab.sh            ← batch runner รันทุกขั้น + สรุป PASS/FAIL
├── rtl/
│   ├── baud_gen.v              ← ตัวหาร baud (100 MHz → 115200)
│   ├── uart_tx.v               ← UART Transmitter 8-N-1 (FSM)
│   └── uart_top.v              ← top module สำหรับ full chip flow
├── tb/
│   └── tb_uart_top.v           ← self-checking TB ตรวจเฟรม 10 บิตทั้งหมด
├── scripts/
│   ├── synth_generic.ys        ← Yosys: generic synthesis + hierarchy breakdown
│   └── synth_gates.ys          ← Yosys: gate-level netlist ที่ simulate ได้จริง
└── librelane/
    ├── config.yaml             ← config ของ LibreLane 3.x
    └── src/{impl.sdc, signoff.sdc}
```

> `VERILOG_FILES: dir::../rtl/*.v` ใน `config.yaml` ชี้กลับไปที่ `rtl/` ของแล็บโดยตรง
> จึง **ไม่มีสำเนา RTL สองชุด** — แก้ที่ไฟล์เดียวแล้วทั้ง Yosys และ LibreLane เห็นพร้อมกัน

> **ทำไมต้องมีเวอร์ชัน Verilog?** คอร์สนี้สอน VHDL (`lab_code/day5/`) แต่ Yosys เป็น Verilog-first
> และ GHDL ไม่ได้อยู่ใน flow ของ LibreLane ที่ใช้ → `day5_yosys/rtl/` จึงเป็น
> **สำเนาเชิงวิศวกรรมของ Mini Project เดิม** ต้องแก้ให้ตรงกันและรันทั้งสอง testbench เพื่อยืนยัน

#### 5.5.2 ขั้นตอนการทำงาน (12 ขั้นตอน)

| # | ขั้นตอน | คำสั่ง | ผลลัพธ์ที่ต้องได้ |
| --- | --- | --- | --- |
| 1 | เตรียมเครื่องมือ | `yosys -V` / `iverilog -V` / `librelane --version` | 0.52 / 12.0 / v3.0.17 |
| 2 | เข้าใจ Mini Project | อ่าน `rtl/baud_gen.v`, `rtl/uart_tx.v` | เข้าใจ FSM 4 สถานะ + divider 10 บิต |
| 3 | RTL Simulation | `make sim` | `tb_uart_top PASS=6 FAIL=0` |
| 4 | Generic Synthesis | `make synth` | `baud_gen` 44 · `uart_tx` 74 · รวม 118 cells |
| 5 | Gate-Level Mapping | `make synth-gate` | `uart_top` 112 cells |
| 6 | **Gate-Level Simulation** | `make sim-gls` | ผ่าน 6/6 เฟรมเท่ากับ RTL ✅ |
| 7 | **เปิดโปง one-hot FSM** | `yosys -p "... dump"` | พบ 4 flip-flop state ที่ไม่มี reset |
| 8 | Map เข้า sky130 | `make sky130` | 122 cells, area **1087.2928 µm²** |
| 9 | LibreLane Full Flow | `make librelane` | รันครบ **80/80 stages** |
| 10 | อ่านผลลัพธ์ | `cat runs/RUN_*/final/metrics.json` | area, slack, DRC, LVS |
| 11 | ดู layout | `ls final/render/` + `klayout ...gds` | เห็นภาพชิปจริง |
| 12 | เทียบกับ Lab 3B | เทียบตารางในหัวข้อ 5.5.4 | เข้าใจขอบเขตของแต่ละ flow |

#### 5.5.3 ผลลัพธ์จริง — ทั้งหมดมาจากการรันจริง

**Yosys (standalone)**

| Module | Generic cells | Gate cells |
| --- | --- | --- |
| `baud_gen` | 44 | — |
| `uart_tx` | 74 | — |
| `uart_top` (hierarchical / flatten) | 118 / 116 | **112** |
| `uart_top` → sky130 | — | 122 (area **1087.2928 µm²**) |

**สัดส่วน flip-flop (28 ตัว):**

| Cell type | จำนวน | ที่มา |
| --- | --- | --- |
| `$_SDFF_PP0_` | 11 | baud_gen: cnt 10 บิต + tick 1 บิต |
| `$_SDFFE_PP0P_` | 11 | uart_tx: shreg 8 บิต + bit_idx 3 บิต |
| `$_SDFFE_PP1P_` | 2 | uart_tx: tx + din_rdy (reset เป็น 1) |
| `$_DFF_P_` | 4 | uart_tx: **FSM state one-hot** (ไม่มี reset) |

**LibreLane (RTL → GDSII)**

```
───────────────── Report Manufacturability (DRC, LVS, Antenna) ─────────────────
* Antenna   Passed ✅
* LVS       Passed ✅
* DRC       Passed ✅
Classic - Stage 80 - Report Manufacturability ━━━━━━━━━━━━━━━━━━━━ 80/80 0:01:49
```

| รายการ | ค่า |
| --- | --- |
| Stages | **80 / 80** ✅ |
| `error.log` | **0 bytes** ✅ |
| DRC / LVS / Antenna violations | **0 / 0 / 0** ✅ |
| Setup slack | **6.235697 ns** (0 violation) ✅ |
| Hold slack | **0.191574 ns** (0 violation) ✅ |
| Max slew / max cap / max fanout violations | 0 / 0 / 0 ✅ |
| Inferred latches / unmapped cells | **0 / 0** ✅ |
| Instances | 526 (stdcell 183, fill 343, buffer 20, tap 42, clock buf 3) |
| Sequential cells | 28 |
| Nets / IOs | 153 / 15 (13 ขาสัญญาณ + VGND + VPWR) |
| Instance & core area | 2805.19 µm² |
| Die area | 4975.42 µm² (65.38 × 76.1 µm) |
| Utilization | 60.12 % |
| Power | total 303.98 µW (internal 245.63, switching 58.34, leakage 2.929 nW) |
| GDSII | `uart_top.gds` 517,382 bytes |

**คำนวณ Fmax จาก slack** (เชื่อมกลับหัวข้อ 3.3):

```
   critical path = clock period - setup slack = 10 - 6.235697 = 3.764303 ns
   Fmax          = 1 / 3.764303 ns ≈ 265.7 MHz
```

#### 5.5.4 เปรียบเทียบกับ Lab 3B

| มิติ | `adder8_pipe` (Lab 3B) | `uart_top` (Lab 5B) |
| --- | --- | --- |
| flip-flop | 26 | **28** |
| Instance count (layout) | 399 | **526** |
| Instance area | 2409.81 µm² | **2805.19 µm²** |
| Die area | 4331.89 µm² | **4975.42 µm²** |
| Utilization | 68.95 % | **60.12 %** |
| Setup slack | 5.587222 ns | **6.235697 ns** |
| Hold slack | 0.317141 ns | **0.191574 ns** |
| Fmax | ≈ 226.6 MHz | **≈ 265.7 MHz** |
| I/O | 30 | **15** |

> UART มี FF ใกล้เคียง adder แต่ชิปใหญ่กว่า เพราะมี **gate มากกว่า** (FSM + divider)
> และมี **ขา I/O น้อยกว่า** — พื้นที่จึงมาจาก combinational logic ไม่ใช่ register

#### 5.5.5 แบบฝึกหัดประจำแล็บ 5B

| ข้อ | โจทย์ | ผลที่คาดหวัง |
| --- | --- | --- |
| F.1 | หาพื้นที่ที่ถูกใช้โดย fill cell | 1118.57 µm² จาก 2805.19 µm² (≈ 40 %) |
| F.2 | อธิบายว่าทำไม I/O มี 15 ขา ไม่ใช่ 13 | 13 ขาสัญญาณ + VGND + VPWR ที่ OpenROAD เพิ่มที่ขอบ die |
| F.3 | หา corner ที่ setup slack แย่ที่สุด | `max_ss_100C_1v60` = 6.235697 ns |
| F.4 | หา corner ที่ hold slack แย่ที่สุด | `min_ff_n40C_1v95` = 0.191574 ns |
| F.5 | แก้ `CLOCK_PERIOD` เป็น 5 ns แล้วรันใหม่ | พบ setup violation หรือ slack ลดลงมาก |
| F.6 | แก้ `FP_CORE_UTIL` เป็น 60 แล้วรันใหม่ เทียบ die area | die area เล็กลง แต่ utilization สูงขึ้น |
| F.7 | ใส่ `set_input_delay 2` / `set_output_delay 2` แล้วรันใหม่ | slack ลดลงประมาณ 2 ns ต่อขา |
| F.8 | ดู `final/render/` แล้วอธิบายว่าเห็นอะไรใน layout | เห็น cell สีต่าง ๆ, PDN, I/O pin |
| F.9 | รัน `dump` บน `$_DFF_P_` | พบ 4 ตัว = FSM state one-hot ที่ไม่มี reset |
| F.10 | เปรียบเทียบ instance count ของ RTL กับ layout | RTL 117 cells → layout 526 instances |

---

## ภาคผนวก: เครื่องมือ Siemens EDA – คำสั่งที่ใช้บ่อย

### A.1 Questa / ModelSim – Tcl Commands

| คำสั่ง | ความหมาย |
| --- | --- |
| `vlib <name>` | สร้าง working library |
| `vcom -2008 file.vhd` | คอมไพล์ VHDL (VHDL-2008) |
| `vlog file.v` | คอมไพล์ Verilog |
| `vsim work.tb_top` | เริ่ม simulation |
| `add wave *` | เพิ่มสัญญาณทั้งหมดใน wave |
| `add wave -radix hex /tb_top/dut/*` | เพิ่มสัญญาณแบบ hex |
| `run 1 us` | รัน 1 ไมโครวินาที |
| `force /tb_top/clk 1 0, 0 5 ns -r 10 ns` | สร้าง clock ด้วย force |
| `view wave` / `view structure` | เปิดหน้าต่าง |
| `quit -f` | ออกจากโปรแกรม |
| `vcover merge -out cov.ucdb *.ucdb` | รวม coverage database |

### A.2 Precision RTL – Tcl Commands

| คำสั่ง | ความหมาย |
| --- | --- |
| `new_project` | สร้างโปรเจกต์ |
| `add_source` | เพิ่ม source file |
| `add_constraint_file` | เพิ่ม SDC |
| `set_top_module` | ตั้ง top |
| `compile` | รัน synthesis |
| `report_area` / `report_timing` / `report_power` | สร้างรายงาน |
| `export_netlist` | export netlist |

### A.3 HDL Designer – เมนูสำคัญ

| เมนู | ความหมาย |
| --- | --- |
| File ▸ New ▸ Block Diagram | สร้าง block diagram ใหม่ |
| File ▸ New ▸ State Diagram | สร้าง state diagram |
| Generate HDL | แปลง diagram เป็น VHDL/Verilog |
| Block ▸ Add Component | เพิ่ม component |
| Tools ▸ Library Manager | จัดการไลบรารี |

### A.4 Yosys / LibreLane – คำสั่งที่ใช้บ่อย (หัวข้อ 3.5–3.6)

| คำสั่ง | ความหมาย |
| --- | --- |
| `yosys -s scripts/synth_generic.ys` | รัน Yosys script ตามลำดับ pass |
| `read_verilog <file>` | อ่าน RTL (Verilog) เข้ามา |
| `read_liberty -lib <file.lib>` | โหลดข้อมูล standard cell ของ PDK |
| `hierarchy -check -top <name>` | หา top module และตรวจ hierarchy |
| `synth -top <name>` | รัน pass สังเคราะห์ทั้งชุด |
| `synth -top <name> -noabc` | สังเคราะห์แต่ข้าม ABC (เพื่อ map เอง) |
| `design -reset` | ล้างสถานะเพื่อเริ่ม module ใหม่ |
| `abc -g AND,NAND,OR,NOR,XOR,XNOR,MUX` | map เป็น gate ทั่วไป (⚠️ ABC ไม่รองรับ `NOT`) |
| `abc -liberty <file.lib>` | map เข้า standard cell จริง |
| `dfflibmap -liberty <file.lib>` | map flip-flop — ต้องมาก่อน `abc` เสมอ |
| `simplemap` | แปลง cell ภายในเป็น expression เพื่อให้ Icarus simulate ได้ |
| `stat` / `stat -liberty <file.lib>` | รายงานจำนวน cell และพื้นที่ |
| `tee -o <file> stat` | บันทึกผลของ stat ลงไฟล์ |
| `write_verilog -noattr <file>` | export netlist |
| `ghdl synth --std=08 --out=verilog <top>` | แปลง VHDL → Verilog (⚠️ GHDL 5.x ต้องเรียง option ตามนี้ และ redirect stdout) |
| `librelane --volare-pdk -p sky130A config.yaml` | รัน Open-source ASIC flow ทั้งหมด |
| `klayout <file.gds>` | เปิดดู GDSII |

### A.5 LibreLane / OpenROAD – คำสั่งที่ใช้บ่อย (หัวข้อ 5.4–5.5)

| คำสั่ง | ความหมาย |
| --- | --- |
| `librelane --volare-pdk -p <pdk> config.yaml` | รัน flow ทั้งหมด + ดาวน์โหลด PDK อัตโนมัติ |
| `librelane --manual-pdk -p <pdk> config.yaml` | รัน flow โดยใช้ PDK ที่ติดตั้งเอง |
| `ls -dt runs/RUN_* \| head -1` | หาโฟลเดอร์ผลลัพธ์รอบล่าสุด |
| `cat runs/RUN_*/final/metrics.json` | ตัวเลขทั้งหมดของ flow |
| `cat runs/RUN_*/final/render/` | ภาพเรนเดอร์ 2D ของ layout |
| `klayout runs/RUN_*/final/klayout_gds/*.gds` | เปิดดู GDSII |
| `netgen -batch lvs <spice> <spice> <mag> report.lvs` | ตรวจ LVS ซ้ำด้วยตัวเอง |
| `magic -dnull -noconsole -rcfile <sky130.magicrc> <mag>` | ตรวจ DRC ซ้ำด้วย Magic |
| `nix profile install nixpkgs#librelane` | ติดตั้ง LibreLane + เครื่องมือ ASIC ทั้งชุด |
| `export PATH="$HOME/.nix-profile/bin:$PATH"` | เพิ่ม nix profile ใน PATH (จำเป็นใน non-interactive shell) |

---

## ภาคผนวก: แหล่งอ้างอิงและเอกสารเพิ่มเติม

### B.1 Standards และคู่มือ

- IEEE Std 1076 – VHDL Language Reference Manual (LRM)
- IEEE Std 1076.4 – VHDL Synthesis Package (NUMERIC_STD, NUMERIC_BIT)
- IEEE Std 1800 – SystemVerilog (ใช้สำหรับ assertion/covergroup ร่วมกับ VHDL)
- IEEE Std 1364 – Verilog (สำหรับ netlist interchange)
- IEEE Std 1497 – Standard Delay Format (SDF)
- Synopsys Design Constraints (SDC) Reference Manual

### B.2 เอกสารจากผู้ผลิตเครื่องมือ

- Questa Advanced Simulator User's Manual – Siemens EDA
- ModelSim User's Manual – Siemens EDA
- Precision RTL Synthesis User's Manual – Siemens EDA
- HDL Designer User's Manual – Siemens EDA
- Yosys Manual – https://yosyshq.readthedocs.io
- LibreLane Documentation – https://librelane.readthedocs.io

### B.3 หนังสือแนะนำ

- "VHDL: Programming by Example" – Douglas L. Perry
- "The Designer's Guide to VHDL" – Peter J. Ashenden
- "Digital Design and Verilog HDL Fundamentals" – Joseph Cavanagh
- "Static Timing Analysis for Nanometer Designs" – J. Bhasker, R. Chadha

### B.4 เว็บไซต์อ้างอิง

- Siemens EDA Documentation Portal
- IEEE Xplore (สำหรับ IEEE Std)
- OpenCores (ตัวอย่าง open-source IP)
- EDA Playground (ทดลอง simulation ออนไลน์)
- YosysHQ – https://yosyshq.net (เอกสาร, build และ plugin ของ Yosys)
- LibreLane – https://github.com/librelane/librelane
- OpenLane – https://openlane.readthedocs.io (โครงการต้นทางของ LibreLane)
- Ciel / Volare – https://volare.readthedocs.io (ตัวจัดการ PDK)
- sky130 PDK – https://github.com/google/skywater-pdk
- IHP SG13G2 Open PDK – https://github.com/IHP-GmbH/IHP-Open-PDK

---

## สรุปการเรียนรู้ส่วนที่ 1 (วันที่ 1-5)

เมื่อจบส่วนที่ 1 ผู้เข้าอบรมควรสามารถ:

1. อธิบายกระบวนการออกแบบ ASIC ตั้งแต่ RTL จนถึง Gate-Level ได้
2. เขียน VHDL ที่สังเคราะห์ได้ตามแนวทางมาตรฐาน
3. ออกแบบ FSM ทั้งแบบ Moore และ Mealy ได้
4. ใช้ Questa/ModelSim จำลองการทำงานและ Debug ด้วย waveform ได้
5. สร้าง Self-checking Testbench พร้อม Assertion ได้
6. สังเคราะห์วงจรด้วย Precision RTL พร้อมวิเคราะห์ Timing ได้
7. ทำ Gate-Level Simulation ด้วย SDF back-annotation ได้
8. สังเคราะห์และวัดผลด้วย Yosys ได้ พร้อมพิสูจน์ความถูกต้องของ netlist ด้วย GLS
9. อธิบายความแตกต่างระหว่าง "RTL cell count" กับ "final instance count" ได้
10. อ่านผลลัพธ์จาก Open-source ASIC flow (LibreLane) ได้ — area, slack, DRC, LVS
11. อธิบายกระบวนการ RTL-to-GDSII ได้ตั้งแต่ floorplan, placement, CTS, routing จนถึง sign-off
12. อธิบายได้ว่าทำไม core area ≠ die area และทำไม slack ที่วัดได้ยังไม่ถือว่า sign-off จริง
13. ดำเนินโครงงาน Mini Project ครบกระบวนการได้อย่างเป็นระบบ

**ต่อไป:** ส่วนที่ 2 (วันที่ 6-10) จะกล่าวถึง Basic IC Design, CMOS Layout, MEMS Layout และ MEMS Simulation ด้วย Tanner Tools, L-Edit
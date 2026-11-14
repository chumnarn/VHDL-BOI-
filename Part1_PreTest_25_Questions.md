# Pre-test: Advanced Digital IC Design & Verification (Part 1)

> **คำแนะนำ:** ทำข้อสอบก่อนเริ่มเรียน 25 ข้อ (ใช้เวลา ~45-60 นาที)
> **ระดับความยาก:** Beginner → Advanced
> **คะแนนเต็ม:** 100 คะแนน
> **เฉลย:** ดูได้ที่หน้า "เฉลยโดยละเอียด" ที่ท้ายเอกสาร

---

## คำชี้แจง

- **ข้อ 1-10:** Multiple Choice (4 คะแนน/ข้อ) = 40 คะแนน
- **ข้อ 11-20:** True/False (3 คะแนน/ข้อ) = 30 คะแนน
- **ข้อ 21-25:** Short Answer (6 คะแนน/ข้อ) = 30 คะแนน

**รวม:** 100 คะแนน

---

## Part A: Multiple Choice (ข้อ 1-10)

### ข้อ 1 — VHDL Basics

**โครงสร้าง VHDL พื้นฐานประกอบด้วยส่วนใดบ้าง?**

- A) Entity และ Variable
- B) Library, Entity, Architecture
- C) Package, Function, Procedure
- D) Process, Block, Component

---

### ข้อ 2 — Data Types

**ข้อใดคือค่าทั้ง 9 ของ `std_logic` ที่ถูกต้อง?**

- A) 0, 1, X, Z
- B) 0, 1, X, Z, U, W, L, H, -
- C) 0, 1, ON, OFF, HIGH, LOW
- D) T, F, X, Z, U, NULL

---

### ข้อ 3 — Simulation vs Synthesis

**ข้อใดคือ synthesizable subset ที่ถูกต้อง?**

- A) `wait for 10 ns`
- B) `initial value := 0`
- C) `rising_edge(clk)`
- D) `assert ... report ... severity failure`

---

### ข้อ 4 — Synthesis

**Synthesis tool ทำหน้าที่ใด?**

- A) ตรวจสอบความถูกต้องของ code
- B) แปลง RTL เป็น gate-level netlist
- C) สร้าง waveform
- D) รัน testbench

---

### ข้อ 5 — ASIC vs FPGA

**ข้อใดเป็นข้อดีของ ASIC เหนือ FPGA?**

- A) ต้นทุนต่ำใน low volume
- B) เวลา development สั้นกว่า
- C) Performance สูงกว่า, Power ต่ำกว่า
- D) Reprogrammable

---

### ข้อ 6 — FSM

**Moore Machine มีลักษณะอย่างไร?**

- A) Output ขึ้นกับ state และ input
- B) Output ขึ้นกับ state ปัจจุบันเท่านั้น
- C) Output เป็น combinational เสมอ
- D) Output ไม่ขึ้นกับอะไรเลย

---

### ข้อ 7 — Latch Prevention

**Code ใดที่จะ infer latch?**

```vhdl
-- Option A
process (a, b)
begin
    case sel is
        when "00" => y <= a;
        when "11" => y <= b;
        when others => y <= '0';
    end case;
end process;

-- Option B
process (a, b, sel)
begin
    case sel is
        when "00" => y <= a;
        when "01" => y <= b;
        when others => y <= '0';
    end case;
end process;

-- Option C
process (a, b, sel)
begin
    y <= '0';
    if sel = '0' then y <= a;
    else y <= b;
    end if;
end process;
```

- A) Option A (incomplete when)
- B) Option B (full when but no full else)
- C) Option C (default assignment + full if)
- D) ทุก option เหมือนกัน

---

### ข้อ 8 — Clock Domain Crossing

**Single-bit signal ที่ข้าม clock domain ควรใช้เทคนิคใด?**

- A) Direct wire connection
- B) 2-FF synchronizer
- C) Combinational buffer
- D) Clock gating

---

### ข้อ 9 — SDF

**SDF ใช้สำหรับอะไร?**

- A) Verify RTL
- B) Carry delay annotation for GLS
- C) Generate testbench
- D) Compile VHDL

---

### ข้อ 10 — Functional Coverage

**ข้อใดคือความแตกต่างระหว่าง Code Coverage กับ Functional Coverage?**

- A) Code Coverage = lines executed, Functional Coverage = features tested
- B) เหมือนกัน
- C) Code Coverage = automatic, Functional Coverage = manual
- D) A และ C ถูกต้อง

---

## Part B: True/False (ข้อ 11-20)

### ข้อ 11 — VHDL

**Asynchronous reset ดีกว่า synchronous reset ในทุกกรณี** (T/F)

---

### ข้อ 12 — Data Types

**`std_logic` และ `bit` ใช้แทนกันได้** (T/F)

---

### ข้อ 13 — Simulation

**Simulation ที่ bench ใน RTL ทำงานเร็วกว่า Gate-Level Simulation** (T/F)

---

### ข้อ 14 — Synthesis

**Synthesis สามารถสร้าง asynchronous reset pin ใน FF ที่ไม่มี async reset pin ได้** (T/F)

---

### ข้อ 15 — FSM

**Moore Machine ใช้ state มากกว่า Mealy Machine สำหรับ sequence detector "101"** (T/F)

---

### ข้อ 16 — CDC

**Multi-bit data bus สามารถใช้ 2-FF synchronizer ตรง ๆ ได้** (T/F)

---

### ข้อ 17 — Latch

**Latch ดีกว่า Flip-Flop เพราะใช้พื้นที่น้อยกว่า** (T/F)

---

### ข้อ 18 — Verification

**Functional coverage 100% หมายความว่า design ถูกต้อง** (T/F)

---

### ข้อ 19 — GLS

**Gate-Level Simulation ใช้ SDF สำหรับ delay annotation** (T/F)

---

### ข้อ 20 — SDC

**False path ใน SDC หมายถึงเส้นทางที่ต้องการ timing analysis** (T/F)

---

## Part C: Short Answer (ข้อ 21-25)

### ข้อ 21 — VHDL Building Blocks (6 คะแนน)

**อธิบายความแตกต่างระหว่าง Signal และ Variable ใน VHDL** พร้อมตัวอย่าง (3 ข้อแตกต่าง)

---

### ข้อ 22 — Synchronous Design (6 คะแนน)

**อธิบาย Reset Strategy แบบ Synchronous กับ Asynchronous พร้อมข้อดีข้อเสียของแต่ละแบบ** (ระบุ 3 ข้อดี/ข้อเสียต่อแบบ)

---

### ข้อ 23 — FSM (6 คะแนน)

**เขียน VHDL สำหรับ Mealy Machine ที่ตรวจาบ sequence "10" แบบ overlapping detection**

```vhdl
entity seq_det_mealy_10 is
    port (
        clk : in std_logic;
        rst_n : in std_logic;
        din : in std_logic;
        detected : out std_logic
    );
end entity;
```

---

### ข้อ 24 — Verification Plan (6 คะแนน)

**เขียน Verification Plan สำหรับ UART TX (8-N-1) ประกอบด้วย:**
1. **Feature List** (≥ 5 features)
2. **Test Plan** (≥ 5 test cases)

---

### ข้อ 25 — GLS & Multi-corner (6 คะแนน)

**อธิบาย GLS (Gate-Level Simulation) และเหตุผลที่ต้องรัน multi-corner (typ/fast/slow) พร้อมผลกระทบที่อาจเกิดขึ้นในแต่ละ corner**

---

## เกณฑ์การประเมิน

| Score | Level | Comment |
|-------|-------|---------|
| 90-100 | Excellent | พร้อมเรียน Part 2 |
| 75-89 | Good | ทบทวนจุดที่ผิด |
| 60-74 | Average | ควรทบทวนก่อน Lab 1 |
| 50-59 | Below Average | ทบทวน Day 1-2 ก่อน |
| <50 | Need Review | ต้องปรึกษาผู้สอน |

---

# เฉลยโดยละเอียด

## Part A: Multiple Choice

### ข้อ 1 — **B) Library, Entity, Architecture**

**คำอธิบาย:** โครงสร้าง VHDL พื้นฐานประกอบด้วย 3 ส่วนหลัก:
- **Library** clause: เรียกใช้ packages (`IEEE.STD_LOGIC_1164.ALL`)
- **Entity**: กำหนด I/O ports
- **Architecture**: อธิบายการทำงาน

---

### ข้อ 2 — **B) 0, 1, X, Z, U, W, L, H, -**

**คำอธิบาย:** `std_logic` มี 9 ค่า (IEEE 1164):
- `0`, `1`: Forcing low/high
- `X`: Forcing unknown
- `Z`: High impedance (tri-state)
- `U`: Uninitialized
- `W`: Weak unknown
- `L`, `H`: Weak low/high
- `-`: Don't care

---

### ข้อ 3 — **C) `rising_edge(clk)`**

**คำอธิบาย:**
- ❌ `wait for` ไม่ synthesize
- ❌ `initial` ไม่ synthesize (เฉพาะ testbench)
- ✅ `rising_edge(clk)` synthesize ได้ (สร้าง FF)
- ⚠️ `assert` ใช้ใน design ได้แต่ไม่สร้าง hardware (เป็น property check)

---

### ข้อ 4 — **B) แปลง RTL เป็น gate-level netlist**

**คำอธิบาย:** Synthesis tool (เช่น Precision RTL) แปลง RTL description เป็น gate-level netlist ที่ประกอบด้วย standard cells ของ technology library

---

### ข้อ 5 — **C) Performance สูงกว่า, Power ต่ำกว่า**

**คำอธิบาย:** ASIC มีประสิทธิภาพสูงกว่า (no programmable overhead), Power ต่ำกว่า (custom circuit), แต่ NRE สูงและ time-to-market นาน

---

### ข้อ 6 — **B) Output ขึ้นกับ state ปัจจุบันเท่านั้น**

**คำอธิบาย:** Moore Machine: `Output = f(state)` — output ขึ้นกับ state ปัจจุบันเท่านั้น ทำให้ glitch-free และ predictable timing

---

### ข้อ 7 — **D) ทุก option เหมือนกัน**

**คำอธิบาย:** ดูที่ตัวเลือก:

**Option A:** ❌ `incomplete when` ("01", "10" ไม่ handle → LATCH)

**Option B:** ❌ Sensitivity list ไม่ครบ (ไม่มี `sel` ใน list แต่ใช้ใน case)

**Option C:** ✅ Default assignment + full else → ปลอดภัย

**หมายเหตุ:** ตัวเลือก D ผิด เพราะ Option A และ B มีปัญหา

**เฉลยที่ถูกต้อง: C) Option C**

---

### ข้อ 8 — **B) 2-FF synchronizer**

**คำอธิบาย:** Single-bit CDC ใช้ 2-FF synchronizer เพื่อลด MTBF (Mean Time Between Failures) ในการเกิด metastability

---

### ข้อ 9 — **B) Carry delay annotation for GLS**

**คำอธิบาย:** SDF (Standard Delay Format, IEEE 1497) บรรจุ delay ของ cells และ interconnect เพื่อให้ simulator ใช้ใน GLS

---

### ข้อ 10 — **D) A และ C ถูกต้อง**

**คำอธิบาย:**
- Code Coverage วัดว่า code รันครบหรือไม่ (auto)
- Functional Coverage วัดว่า features ใน spec ถูกทดสอบครบหรือไม่ (user-defined)

---

## Part B: True/False

### ข้อ 11 — **False (F)**

**คำอธิบาย:** Asynchronous reset ดีกว่าในบางกรณี (เช่น power-on reset) แต่ synchronous reset มีข้อดีหลายอย่าง:
- ไม่มี recovery/removal timing issue
- ใช้ FF ที่ไม่มี async reset pin (ประหยัดพื้นที่)
- Timing analysis deterministic

**คำแนะนำ:** ใช้ synchronous reset เป็น default

---

### ข้อ 12 — **False (F)**

**คำอธิบาย:** `std_logic` มี 9 ค่า ส่วน `bit` มี 2 ค่า (0, 1) เท่านั้น การใช้ `std_logic` ดีกว่าเพราะรองรับ tri-state, don't-care, X

---

### ข้อ 13 — **True (T)**

**คำอธิบาย:** RTL sim รันได้ 10K-100K cycles/sec ส่วน GLS ช้ากว่า 1-100× เพราะต้อง compute delay ของทุก gate

---

### ข้อ 14 — **False (F)**

**คำอธิบาย:** Synthesis สร้าง async reset pin ได้ **ก็ต่อเมื่อ target library มี FF ที่มี async reset pin** เท่านั้น (เช่น `DFFARX1`). หาก library มีแต่ `DFFRX1` (sync reset only) tool จะ insert external logic

---

### ข้อ 15 — **True (T)**

**คำอธิบาย:** Moore "101" detector ต้องการ 4 states (S0, S1, S2, S3 ที่ detect), Mealy ต้องการแค่ 3 states (S0, S1, S2) เพราะ detect ที่ S2 + din='1'

---

### ข้อ 16 — **False (F)**

**คำอธิบาย:** Multi-bit data bus ข้าม domain ต้องใช้:
- **Gray code** + 2-FF sync (1 bit เปลี่ยนต่อ cycle)
- **Handshake protocol** (request/acknowledge)
- **Async FIFO** (burst transfer)

ใช้ 2-FF synchronizer ตรง ๆ กับ multi-bit จะเกิด data corruption

---

### ข้อ 17 — **False (F)**

**คำอธิบาย:** Latch **แย่กว่า** flip-flop ใน ASIC design เพราะ:
- Timing analysis ยาก (transparent window)
- Race condition
- Glitch propagation
- DFT ยาก

ใน modern ASIC ใช้ FF เกือบทั้งหมด ยกเว้น low-power design

---

### ข้อ 18 — **False (F)**

**คำอธิบาย:** Functional coverage 100% หมายความว่า **ทุก scenario ใน spec ถูกทดสอบ** แต่ไม่ได้ guarantee correctness เพราะ:
- TB อาจมี bug
- Spec อาจผิด
- Implementation อาจผิด

จำเป็นต้องมี assertions + sign-off criteria

---

### ข้อ 19 — **True (T)**

**คำอธิบาย:** SDF = Standard Delay Format ใช้ annotate delay ของ cells (IOPATH) และ interconnect (NETDELAY) ให้กับ simulator ใน GLS

---

### ข้อ 20 — **False (F)**

**คำอธิบาย:** False path คือเส้นทางที่ **ไม่ต้องการ timing analysis** (เช่น async reset path, CDC path) ตรงข้ามกับคำถาม

---

## Part C: Short Answer

### ข้อ 21 — Signal vs Variable (6 คะแนน)

**ความแตกต่าง:**

| Aspect | Signal | Variable |
|--------|---------|----------|
| **ที่ประกาศ** | Architecture, Package | Process, Function, Procedure |
| **Update timing** | End of process (delta cycle) | ทันที (same line) |
| **Synthesizable** | ✅ กลายเป็น wire/FF | ⚠️ เป็น local scratch |
| **Scope** | ทั่วทั้ง architecture | ภายใน process/subprogram |

**ตัวอย่าง:**

```vhdl
architecture demo of sig_var is
    signal sig_x : std_logic := '0';  -- Signal
begin
    process (a, b)
        variable var_y : std_logic := '0';  -- Variable
    begin
        var_y := a and b;   -- อัปเดตทันที
        sig_x <= a or b;    -- อัปเดตเมื่อจบ process
        z1 <= var_y;        -- = a and b (รอบนี้)
        z2 <= sig_x;        -- = a or b จากรอบก่อน
    end process;
end architecture;
```

**ตัวอย่างที่ 2:** Signal ใช้ระหว่าง processes
```vhdl
process_a : process (clk)
begin
    shared_sig <= data_a;   -- write to signal
end process;
process_b : process (clk)
begin
    read_data <= shared_sig;  -- read from signal (next cycle)
end process;
```

**ตัวอย่างที่ 3:** Variable เป็น scratch ภายใน process
```vhdl
process (a, b)
    variable sum_v : integer := 0;
begin
    sum_v := a + b;   -- scratch calculation
    if sum_v > 255 then
        sum_v := 255;  -- clamp
    end if;
    sum_out <= sum_v;
end process;
```

---

### ข้อ 22 — Reset Strategy (6 คะแนน)

**Synchronous Reset:**

ข้อดี:
1. ✅ Predictable timing (อยู่ภายใต้ clock domain)
2. ✅ ไม่มี recovery/removal timing issue
3. ✅ ใช้ FF ที่ไม่มี async reset pin (ประหยัดพื้นที่ ~10-20%)
5. ✅ สามารถใช้ scan chain ได้ง่าย (DFT)

ข้อเสีย:
1. ⚠️ ต้องมี clock ทำงานเพื่อ reset
2. ⚠️ Reset glitch อาจถูก miss

**Asynchronous Reset:**

ข้อดี:
1. ✅ ทำงานทันทีโดยไม่ต้องมี clock
2. ✅ เหมาะกับ power-on reset

ข้อเสีย:
1. ⚠️ ต้อง de-assert synchronously (reset synchronizer)
2. ⚠️ Recovery/removal timing issues
3. ⚠️ ใช้ FF ที่มี async reset pin (area larger)

**คำแนะนำ:** ใช้ **Hybrid (async assert + sync de-assert)** หรือ **Synchronous Reset** เป็น default

---

### ข้อ 23 — Mealy FSM "10" (6 คะแนน)

```vhdl
-- File: seq_det_mealy_10.vhd
-- Mealy FSM: detect sequence "10" with overlap
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity seq_det_mealy_10 is
    port (
        clk      : in  std_logic;
        rst_n    : in  std_logic;
        din      : in  std_logic;
        detected : out std_logic
    );
end entity;

architecture rtl of seq_det_mealy_10 is
    -- Mealy: 2 states (S0, S1) - detected in S1 + din='0'
    type state_t is (S0, S1);
    signal state, next_state : state_t;
begin
    -- State register
    sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= S0;
            else
                state <= next_state;
            end if;
        end if;
    end process;

    -- Next-state + output logic
    comb : process (state, din)
    begin
        next_state <= state;
        detected <= '0';

        case state is
            when S0 =>
                if din = '1' then
                    next_state <= S1;
                end if;

            when S1 =>
                if din = '0' then
                    next_state <= S0;
                    detected <= '1';  -- Mealy: detected ทันที
                end if;
        end case;
    end process;
end architecture;
```

**State Diagram:**
```
              din='1'              din='0'/det=1
   ┌─────────────┐  ┌─────────────┐
   │             ▼  │             ▼
   S0 ───────────► S1 ───────────► (S0 loop)
   (initial)         (saw '1')       (detect '10')
```

---

### ข้อ 24 — Verification Plan สำหรับ UART TX (6 คะแนน)

**Feature List:**

| ID | Feature | Description | Priority |
|----|---------|-------------|----------|
| F01 | Reset | Sync reset, TX=1 | High |
| F02 | Frame Format | 8-N-1 (1S + 8D + 1T) | Critical |
| F03 | Baud Rate | 115200 bps | High |
| F04 | Data Values | 0x00-0xFF | High |
| F05 | Handshake | din_vld/din_rdy | Medium |
| F06 | Back-to-back | Multiple frames | Medium |
| F07 | tx_done | Pulse after frame | Low |

**Test Plan:**

| Test ID | Description | Stimulus | Pass Criteria |
|---------|-------------|----------|---------------|
| T01 | Reset | rst_n=1 for 5 cycles | tx=1, din_rdy=1 |
| T02 | Send 0x55 | din=0x55, din_vld=1 | start=0, 01010101, stop=1 |
| T03 | Send 0xAA | din=0xAA | start=0, 10101010, stop=1 |
| T04 | All 256 bytes | random din | All frames correct |
| T05 | Back-to-back | 0x55 then 0xAA | 2 correct frames back-to-back |
| T06 | Baud 9600 | change baud | Frame timing × 9600 |

---

### ข้อ 25 — GLS และ Multi-corner (6 คะแนน)

**GLS (Gate-Level Simulation):**

GLS คือการ simulate design ที่ระดับ **gate-level netlist** (หลัง synthesis) โดยใช้ **SDF (Standard Delay Format)** สำหรับ delay annotation

**จุดประสงค์:**
1. Verify functional correctness หลัง synthesis
2. Verify timing correctness (setup/hold)
3. Catch bugs ที่ RTL sim ไม่เห็น (X-propagation, glitches)

**Multi-corner จำเป็นเพราะ:**

ในการผลิตจริง, chip ต้องทำงานได้ในทุกสภาวะ PVT (Process, Voltage, Temperature) ที่กำหนด ไม่ใช่แค่ typical:

**Corner Types:**
- **Typical (typ)**: Process=typical, Voltage=nominal, Temp=25°C
- **Fast (fast)**: Process=fast, Voltage=high, Temp=low → **Hold violations**
- **Slow (slow)**: Process=slow, Voltage=low, Temp=high → **Setup violations**

**ผลกระทบที่อาจเกิดในแต่ละ corner:**

| Corner | Issue | Solution |
|--------|-------|----------|
| **Fast** | Hold violation (data changes too fast) | Add delay cells, strengthen FF |
| **Slow** | Setup violation (data arrives too late) | Increase clock period, pipeline |
| **Typical** | Should pass with margin | (baseline) |

**เหตุผล:**
- **Process** variation: transistor speed varies (fast/slow process corner)
- **Voltage**: lower VDD → slower transistors
- **Temperature**: higher temp → slower transistors (for most cases)

หาก GLS ผ่านทุก corner → design robust across real-world conditions

---

## Scoring Rubric

| Part | Question Type | Max Points | Pass Threshold |
|------|---------------|------------|----------------|
| A | Multiple Choice | 40 (10 × 4) | 28 (70%) |
| B | True/False | 30 (10 × 3) | 21 (70%) |
| C | Short Answer | 30 (5 × 6) | 21 (70%) |
| **Total** | | **100** | **70 (70%)** |

## Grading Scale

| Score | Grade | Action |
|-------|-------|--------|
| 90-100 | A | พร้อมเรียน Part 2 |
| 80-89 | B | พร้อม + ทบทวนจุดที่ผิด |
| 70-79 | C | ผ่าน + ควรทบทวน |
| 60-69 | D | ทบทวนก่อน Lab 1 |
| <60 | F | ต้องเรียนซ้ำ Day 1-2 |

---

## Tips for Success

1. ✅ **อ่านคำถามให้ละเอียด** ก่อนตอบ
2. ✅ **ใช้เวลาพอสมควร** — ไม่รีบ
3. ✅ **ตรวจคำตอบ** ก่อนส่ง
4. ✅ **ทบทวนจุดที่ตอบผิด** กับเฉลย

---

> **หมายเหตุ:** Pre-test นี้ออกแบบให้ทำ **ก่อนเรียน** Day 1 เพื่อวัด baseline ของผู้เข้าอบรม และช่วยปรับ pace การสอน
> คำถามที่ตอบผิด = หัวข้อที่ควรเน้นย้ำในห้องเรียน

---

## 🎓 ขอให้โชคดีกับการเรียนหลักสูตร!

ถ้าผ่านเกณฑ์ 70% → พร้อมเริ่ม Part 1 ได้เลย

ถ้าต่ำกว่า → ปรึกษาผู้สอนเพื่อทบทวนพื้นฐาน
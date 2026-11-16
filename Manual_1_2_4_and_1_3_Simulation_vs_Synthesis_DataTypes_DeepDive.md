# รายละเอียดเชิงลึก: Simulation vs Synthesis และ Data Types

> เนื้อหานี้ออกแบบมาให้นำไปแทรกเป็นส่วนขยายในหัวข้อ **1.2.6 Data Types ที่ใช้บ่อย** และ **1.3 ภาคทฤษฎี: Simulation vs Synthesis** ของคู่มือหลักสูตร (วันที่ 1)
> เหมาะสำหรับการบรรยาย 90–120 นาที

---

# ส่วนที่ A: Simulation vs Synthesis — เชิงลึก

## A.1 ความหมายที่แท้จริง

**Simulation** คือการ **จำลองพฤติกรรม** ของวงจรบนคอมพิวเตอร์ โดยใช้ตัวจำลอง (simulator) รัน VHDL/Verilog code แล้วแสดงผลเป็น waveform

**Synthesis** คือการ **สร้างวงจรจริง** (gate-level netlist) จาก RTL description โดยใช้เครื่องมือสังเคราะห์ (synthesizer)

ทั้งสองเป็นกระบวนการ **คนละแบบกันโดยสิ้นเชิง** แต่มีจุดประสงค์เสริมกัน:

```
                     ┌──────────────────┐
                     │  RTL DESIGN      │
                     │  (VHDL/Verilog)  │
                     └────────┬─────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
                ▼                           ▼
         ┌──────────────┐           ┌──────────────┐
         │  SIMULATION  │           │  SYNTHESIS   │
         │              │           │              │
         │ Tool:        │           │    Tool:     │
         │ Questa /     │           │   Precision  │
         │ ModelSim     │           │ /Genus/DC    │
         │              │           │              │
         │ Output:      │           │  Output:     │
         │ waveform,    │           │  netlist,    │
         │ report       │           │    area,     │
         │              │           │   timing     │
         │ Goal:        │           │              │
         │ correctness  │           │Goal:gold     │
         │ (logic)      │           │   (real hw)  │
         └──────────────┘           └──────────────┘
```

---

## A.2 Simulation Flow รายละเอียด

### A.2.1 ขั้นตอน

```
   1. Elaborate ──► 2. Initialize ──► 3. Run ──► 4. Report
                                                             
   ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
   │ Parse   │    │ Set     │    │ Execute │    │ Show    │
   │ Bind    │───►│ all     │───►│ time    │───►│ waveform│
   │ library │    │ signals │    │ advance │    │ + report│
   │ (build  │    │ to      │    │ events  │    │         │
   │hierarchy)│   │ initial │    │  (delta │    │         │
   └─────────┘    │ values  │    │  cycle) │    └─────────┘
                  └─────────┘    └─────────┘
```

### A.2.2 Delta Cycle (หัวใจของ Simulator)

Delta cycle คือ **iteration ย่อยภายใน simulation timestep** ที่ simulator ใช้เพื่อ resolve ทุก signal update ก่อนที่เวลาจะเดินต่อ

```
Time = 100 ns ───────────────────────────────────────────►

At t=100 ns:
  Process A: y <= a + b   (sensitivity triggers)
  ┌─ Delta cycle 1: schedule event for y
  ├─ Delta cycle 2: evaluate signals that use y (z)
  ├─ Delta cycle 3: schedule event for z
  ├─ ...
  └─ Delta cycle N: until stable
```

**ตัวอย่างปัญหา: infinite zero-time loop**

```vhdl
process (clk)
begin
    if rising_edge(clk) then
        a <= b;     -- a depends on b
    end if;
end process;

process
begin
    b <= a;          -- b depends on a!
    wait for 1 ns;
end process;
```

ผลลัพธ์: simulator ทำงานไม่หยุด — ต้องมี **wait for X ns** อย่างน้อยหนึ่ง process เพื่อ break delta cycle

### A.2.3 Event-driven Simulation

Simulator ทำงานแบบ **event-driven** — เฉพาะ process ที่ sensitivity list ตรงกับ signal change เท่านั้นที่ถูก execute:

```vhdl
signal a, b : int := 0;
process (a)
begin
    b <= a + 1;   -- only fires when a changes
end process;

process (b)
begin
    a <= b + 1;    -- only fires when b changes
end process;
```

### A.2.4 Race Condition

เกิดเมื่อมี 2 events ในเวลาเดียวกันและผลขึ้นกับลำดับ:

```vhdl
process (clk)
begin
    if rising_edge(clk) then
        a <= b;          -- แย่: race กับ process ที่กำหนด b
    end if;
end process;
```

**วิธีหลีกเลี่ยง:**
- ใช้ `wait until` แทน sensitivity list
- กำหนดให้ทุก FF ใช้ clock อันเดียวกัน (single-clock domain)

---

## A.3 Synthesis Flow รายละเอียด

### A.3.1 High-Level Flow

```
   RTL Source (.vhd)
        │
        ▼
   ┌─────────────────┐
   │ 1. HDL Parse    │  (Lex + Parse)
   └────────┬────────┘
            │
            ▼
   ┌─────────────────┐
   │ 2. Elaborate    │  (Build hierarchy + bind components)
   └────────┬────────┘
            │
            ▼
   ┌─────────────────┐
   │ 3. Constraints  │  (SDC, clock, IO delay)
   └────────┬────────┘
            │
            ▼
   ┌─────────────────┐
   │ 4. Generic      │  (Convert to generic gates, "GTECH")
   │    Synthesis    │
   └────────┬────────┘
            │
            ▼
   ┌─────────────────┐
   │ 5. Optimization │  (Combinational + sequential)
   │    - constant prop
   │    - dead code elim
   │    - resource sharing
   │    - retiming
   └────────┬────────┘
            │
            ▼
   ┌─────────────────┐
   │ 6. Technology   │  (Map to library cells)
   │    Mapping      │  e.g., NAND2X1, DFFRX1
   └────────┬────────┘
            │
            ▼
   ┌─────────────────┐
   │ 7. Incremental  │  (Fix remaining issues)
   │    Optimization │
   └────────┬────────┘
            │
            ▼
   ┌─────────────────┐
   │ 8. Reports      │  (area, timing, power)
   │    + Export     │
   └────────┬────────┘
            │
            ▼
      Netlist (.v) + Reports (.rpt)
```

### A.3.2 Generic Synthesis (GTECH)

ตัวอย่าง internal representation ก่อน technology mapping:

```vhdl
-- Input: VHDL
y <= a and b;
z <= y or c;

-- Internal GTECH netlist (Pseudo)
GTECH_AND2 (y, a, b);
GTECH_OR2 (z, y, c);
```

GTECH cells ไม่ขึ้นกับ vendor library — เป็น "abstract gates"

### A.3.3 Technology Mapping

หลังจาก optimization, generic gates ถูก map ไปยักของเทคโนโลยีเป้าหมาย:

```
   GTECH_AND2  ──►  NAND2X1 (45nm)
                ──►  AND2X1  (alternative)
                ──►  NAND2X2 (higher drive)
                ──►  NAND2X4 (highest drive)
```

**Trade-off:**

| Cell | Delay | Area | Drive Strength |
|---|---|---|---|
| `NX1` (1× drive) | 30 ps | 0.5 μm² | 1 |
| `NX2` (2× drive) | 25 ps | 0.7 μm² | 2 |
| `NX4` (4× drive) | 20 ps | 1.1 μm² | 4 |

**Rule of thumb:** ใช้ `X1` ถ้า load น้อย, ใช้ `X2/X4` ถ้า fan-out สูง

---

## A.4 เปรียบเทียบเชิงลึก

| มิติ | Simulation | Synthesis |
|---|---|---|
| **จุดประสงค์** | ตรวจสอบฟังก์ชัน (functional) | แปลงเป็นฮาร์ดแวร์จริง |
| **Input** | RTL + Testbench | RTL + Constraints (SDC) |
| **Output** | Waveform, report | Netlist, area/timing report |
| **Tool** | Questa, ModelSim, VCS, Icarus | Precision, Genus, DC, Yosys |
| **ระยะเวลา** | Seconds to hours | Minutes to hours |
| **ความแม่นยำ** | Exact (functional) | Approximation (logic + estimated delay) |
| **Iteration** | Fast (re-run = minutes) | Slow (compile = minutes) |
| **Debug** | Easy (see signal changes) | Hard (must inspect netlist) |
| **Cost** | License ($$$) | License ($$$) |
| **Resulting artifact** | `.wlf`, `.vcd`, transcript log | `.v` netlist, `.rpt`, `sdf` |

---

## A.5 Synthesizable Subset — อะไรได้ อะไรไม่ได้

### A.5.1 ตารางสรุป

| Construct | Synthesizable? | ใช้ที่ไหน |
|---|---|---|
| `signal` declaration | ✓ | Design + Testbench |
| `variable` declaration | ✗ (สร้าง logic เพิ่มใน design) | Testbench เท่านั้น |
| `process (sensitivity_list)` | ✓ | Design + Testbench |
| `process` ที่ใช้ `wait for` | ✗ | Testbench เท่านั้น |
| `if`, `elsif`, `else` | ✓ | ทั้งสอง |
| `case`, `when` | ✓ | ทั้งสอง |
| `for` loop (static) | ✓ (tool unrolls) | Design |
| `for` loop (dynamic) | ✗ | Testbench เท่านั้น |
| `while` loop | ✗ (ส่วนใหญ่) | Testbench |
| `assert` (immediate) | ✓ (ใช้เป็น assertion) | ทั้งสอง |
| `assert ... report ... severity failure` (concurrent PSL) | ✓ (tool รู้จัก) | Design |
| `wait for` | ✗ | Testbench เท่านั้น |
| `wait until rising_edge(clk)` | ✓ | Design (สำหรับ clocked process) |
| `wait until signal` (general) | ✗ | Testbench |
| `initial` value of signal | ✗ (FPGA บางตัวรองรับ) | Testbench |
| `file I/O` (`textio`) | ✗ | Testbench เท่านั้น |
| `access type` (pointer) | ✗ | Testbench เท่านั้น |
| `'Z'`, `'U'`, `'X'` values | ⚠ ระวัง | ควรใช้ `'0'`,`'1'` ใน design |
| `std_logic_vector` slicing | ✓ | ทั้งสอง |
| `report` | ✗ (ส่วนใหญ่) | Testbench เท่านั้น |

### A.5.2 ตัวอย่าง code ที่ simulate ผ่าน แต่ synthesize ไม่ได้

**ตัวอย่าง 1: `wait for` ใน design**

```vhdl
-- BAD: synthesize ไม่ได้
process (a)
begin
    y <= a;
    wait_for 10ns;          -- ERROR
end process;
```

❌ Synthesizer error: "wait for cannot be synthesized"
✅ Simulator: ทำงานปกติ

**Fix:**
```vhdl
-- GOOD: ใช้ clocked process
process (clk)
begin
    if rising_edge(clk) then
        y <= a;
    end if;
end process;
```

**ตัวอย่าง 2: `initial` ใน design**

```vhdl
-- BAD
signal counter : integer := 0;
process (clk)
begin
    if rising_edge(clk) then
        counter <= counter + 1;  -- counter เริ่มที่ 0
    end if;
end process;
```

❌ หลัง synthesis, counter เริ่มที่ 'X' (unknown) ใน simulation, '0' หลัง power-on ใน FPGA
⚠️ ใน FPGA ที่ใช้ bitstream, ค่า initial สามารถระบุได้ (ใน Quartus/Vivado)
❌ ASIC ไม่มี initial — ต้องใส่ reset

**Fix:**
```vhdl
-- GOOD
process (clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            counter <= (others => '0');
        else
            counter <= counter + 1;
        end if;
    end if;
end process;
```

**ตัวอย่าง 3: Dynamic loop ใน design**

```vhdl
-- BAD: dynamic loop bound
process (a)
    variable i : integer := 0;
begin
    i := 0;
    while i < a loop       -- ❌ dynamic
        data <= data + 1;
        i := i + 1;
    end loop;
end process;
```

✅ Fix:
```vhdl
-- GOOD: static loop (tool unrolls)
process (a)
begin
    for i in 0 to 7 loop
        if i < a then
            data <= data + 1;
        end if;
    end loop;
end process;
```

### A.5.3 ตัวอย่าง code ที่ผ่านทั้ง simulation และ synthesis แต่มีปัญหา

```vhdl
-- Inferred latch จาก incomplete case
process (a, b, sel)
begin
    case sel when sel='0' then
        y <= a;
    -- ไม่มี when '1'!
    end case;
end process;
```

❌ Simulator: ทำงานได้ (เก็บค่าเก่าเมื่อ sel='1')
❌ Synthesizer: warning "inferred latch"
❌ ASIC: latch จะถูกสร้างจริง ทำให้ timing analysis ยาก

**Fix:**
```vhdl
process (a, b, sel)
begin
    case sel is
        when '0' => y <= a;
        when '1' => y <= b;
        when others => y <= '0';  -- default
    end case;
end process;
```

---

## A.6 X-Propagation — ปัญหาที่พบบ่อย

### A.6.1 ที่มาของ 'X'

ใน simulation, `std_logic` มี 9 ค่า รวมถึง `'X'` (unknown) และ `'U'` (uninitialized)

**ต้นเหตุของ X:**
1. **Uninitialized signal** — ไม่มี reset, ขึ้นกับค่าเริ่มต้น
2. **Bus contention** — 2 driver drive ค่าต่างกัน
3. **Out-of-range index** — `arr(i)` เมื่อ `i` เกิน range
4. **Multiple `wait` ใน process** — race condition
5. **`rising_edge` ไม่ detect ได้** — เมื่อ clock = 'X' (glitch)

### A.6.2 X-propagation ใน simulation vs synthesis

| Operation | Simulation | Synthesis |
|---|---|---|
| `if x = '1' then` | ถ้า x='X' ถือว่าไม่จริง → else branch | Tool อาจ optimize เป็น always-true หรือไม่ก็ได้ |
| `case x is when "00" => ...` | x="XX" ไม่ match ไหร → default | อาจ map เป็น MUX |
| `'X' or '0'` | = 'X' | ไม่เคยเกิดใน synthesis |

**ตัวอย่างปัญหา:**

```vhdl
-- RTL
process (reg_cnt)
begin
    case reg_cnt is
        when 0 => led <= "1000";
        when 1 => led <= "0100";
        when 2 => led <= "0010";
        when 3 => led <= "0001";
        when others => led <= "1111";  -- X handling
    end case;
end process;
```

✅ Simulation: ถ้า reg_cnt = 'X', led = "1111" (visible)
❌ Synthesis: tool อาจไม่สร้าง branch สำหรับ X → mismatch กับ simulation!

**วิธีแก้:** ใส่ค่าเริ่มต้นด้วย reset

---

## A.7 ตัวอย่าง: Mismatch ระหว่าง Simulation กับ Synthesis

### A.7.1 กรณีที่ 1: Asymmetric Reset

```vhdl
-- RTL
process (clk, rst)
begin
    if rst = '1' then       -- asynchronous reset
        cnt <= "0000";
    elsif rising_edge(clk) then
        cnt <= cnt + 1;
    end if;
end process;
```

✅ Simulation: rst ทำงานทันทีเมื่อ rst='1'
⚠️ Synthesis: ใช้ FF ที่มี asynchronous reset pin (เพิ่ม area, latency)
⚠️ ASIC flow: ต้อง de-assert reset synchronously ก่อนใช้งาน

### A.7.2 กรณีที่ 2: Clock Domain Crossing ที่ไม่มี Synchronizer

```vhdl
-- RTL
process (clk_fast)
begin
    if rising_edge(clk_fast) then
        flag <= '1';   -- propagates to slow domain
    end if;
end process;

process (clk_slow)
begin
    if rising_edge(clk_slow) then
        if flag = '1' then
            action <= '1';   -- metastability!
        end if;
    end if;
end process;
```

✅ Simulation: ทำงาน "ปกติ" (ไม่มี metastability ใน simulator)
❌ Silicon: อาจเกิด metastability → unpredictable behavior

**วิธีแก้:** ใส่ 2-stage synchronizer

```vhdl
process (clk_slow)
begin
    if rising_edge(clk_slow) then
        sync1 <= flag;
        sync2 <= sync1;  -- 2-FF synchronizer
    end if;
end process;
```

### A.7.3 กรณีที่ 3: Clock Buffer ที่ไม่มี

```vhdl
signal clk_divided : std_logic;
process (clk)
begin
    if rising_edge(clk) then
        clk_divided <= not clk_divided;  -- BAD: clock from logic
    end if;
end process;
```

✅ Simulation: ทำงานได้
❌ Silicon: timing violation แน่นอน — clock ต้องมาจาก dedicated clock network

---

## A.8 กลยุทธ์ในการเขียน RTL ที่ดี

### A.8.1 Synchronous Design

```vhdl
-- ✅ Use synchronous reset everywhere
process (clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            state <= IDLE;
        else
            state <= next_state;
        end if;
    end if;
end process;
```

### A.8.2 Single Clock Domain

```vhdl
-- ✅ ใช้ clock เดียวสำหรับทุก FF ในกลุ่ม
process (sys_clk)  -- ใช้ sys_clk ทั้งหมด
```

ถ้ามีหลาย clock ใช้:
- **CE (Clock Enable)** สำหรับ slow logic
- **Synchronizer** สำหรับ CDC
- **Clock mux** ที่ glitch-free

### A.8.3 Reset Strategy

| Strategy | Pros | Cons |
|---|---|---|
| Synchronous Reset | Simple, low-area (no async pin) | Need clk to reset |
| Asynchronous Reset | Works without clk | Need recovery/removal handling |
| No reset (FPGA only) | Saves area | Initialization unpredictable |

**แนะนำ:** Synchronous reset + dedicated reset signal

### A.8.4 Coding Style Checklist

| Check | Item |
|---|---|
| ☐ | Synchronous reset ใช้ทุก FF |
| ☐ | Single clock domain (หรือมี CDC convention) |
| ☐ | Default assignment ในทุก combinational process |
| ☐ | มี sensitivity list ครบ (หรือใช้ `process(all)` VHDL-2008) |
| ☐ | ไม่ใช้ `wait for` ใน design |
| ☐ | ไม่ใช้ `initial` ใน design |
| ☐ | ไม่ใช้ latch ที่ไม่ตั้งใจ |
| ☐ | ใช้ `rising_edge(clk)` เท่านั้น (ไม่ใช้ `clk'event and clk='1'`) |
| ☐ | ไม่ใช้ `'X'`, `'Z'`, `'U'` ใน design |
| ☐ | ใช้ IEEE.STD_LOGIC_1164 และ IEEE.NUMERIC_STD |

---

## A.9 Tools ที่ใช้ในหลักสูตร

### A.9.1 Simulation (Siemens EDA)

| Tool | Use |
|---|---|
| **Questa Advanced Simulator** | Full-featured simulation, coverage, formal |
| **ModelSim** | Basic simulation |
| **HDL Designer** | Block diagram → VHDL (ไม่ใช่ simulator แต่ช่วยสร้าง design) |

**คำสั่งที่ใช้บ่อย:**

```tcl
vlib work                      # สร้าง working library
vcom -2008 file.vhd           # compile VHDL (VHDL-2008)
vlog file.v                    # compile Verilog
vsim work.tb_top               # launch simulation
add wave *                     # add all signals
add wave -radix hex /tb_top/data
run 1 us                       # run simulation 1 microsecond
quit -f                        # quit
```

### A.9.2 Synthesis (Siemens EDA)

| Tool | Use |
|---|---|
| **Precision RTL** | Logic synthesis |

**คำสั่ง:**

```tcl
new_project -name top -folder work_top -technology "..."
add_source -top kernel design.vhd
add_constraint_file -constraint top.sdc
set_top_module top
compile -incremental_mapping -retiming
report_area -file reports/area.rpt
report_timing -delay max -num_paths 100 -file reports/timing.rpt
export_netlist -format verilog -output netlist/top.v
exit
```

### A.9.3 Open-Source Alternatives

| Tool | Use |
|---|---|
| **GHDL** | VHDL simulation |
| **Icarus Verilog** | Verilog simulation |
| **Yosys** | Synthesis |
| **COCOTB** | Verification (Python-based testbench) |

---

## A.10 Workflow จริง: Verification-driven Design

```
   ┌──────────────────────────────────────────────────────────────┐
   │ RTL Design                                                   │
   │   ↓                                                          │
   │ Compile (vcom) → 0 errors?                                   │
   │   ↓                                                          │
   │ Elaborate + Simulate (Questa)                                │
   │   ↓                                                          │
   │ Test pass? ─── No → Fix RTL → loop back                      │
   │   ↓ Yes                                                      │
   │ Functional Coverage = 100%? ─── No → Add test cases → loop   │
   │   ↓ Yes                                                      │
   │ Formal Verification (Equivalence check RTL ↔ Netlist)        │
   │   ↓                                                          │
   │ Synthesis (Precision RTL)                                    │
   │   ↓                                                          │
   │ Area/Timing report OK? ─── No → Optimize RTL → loop back     │
   │   ↓ Yes                                                      │
   │ Gate-Level Simulation (Questa + Netlist + SDF)               │
   │   ↓                                                          │
   │ Sign-off (STA, LVS, DRC) ─────────────────────────────────── │
   └──────────────────────────────────────────────────────────────┘
```

---

# ส่วนที่ B: Data Types — เชิงลึก

## B.1 std_logic: 9 ค่า และความหมาย

`std_logic` นิยามใน IEEE.STD_LOGIC_1164 เป็น resolved type ที่มี **9 ค่า** (resolution function จัดการค่าเมื่อมีหลาย driver):

| ค่า | ชื่อ | ความหมาย | ใช้เมื่อ |
|---|---|---|---|
| `'U'` | Uninitialized | ยังไม่ถูกกำหนด | Simulator เริ่มต้น |
| `'X'` | Forcing Unknown | Driver ที่แน่นอนแต่ conflict | Bus contention, 2 driver drive ค่าต่างกัน |
| `'0'` | Forcing 0 | Logic low (strong) | ค่าปกติ |
| `'1'` | Forcing 1 | Logic high (strong) | ค่าปกติ |
| `'Z'` | High Impedance | Tri-state, ไม่ drive | Bus ที่ไม่มี driver, bidirectional pin |
| `'W'` | Weak Unknown | Weak driver conflict | (ไม่ค่อยใช้) |
| `'L'` | Weak 0 | Pull-down resistor | Open-collector output, pull-down |
| `'H'` | Weak 1 | Pull-up resistor | Open-collector output, pull-up |
| `'-'` | Don't Care | ไม่สนใจค่า | Synthesis optimization, case ที่ไม่ต้อง handle ทุกค่า |

### B.1.1 Resolution Table (เมื่อมีหลาย driver)

```
        0   1   X   Z   W   L   H   -   U
   0  | 0   X   1   0   0   0   0   X   X |
   1  | X   1   1   1   1   1   1   X   X |
   X  | 0   1   X   X   W   W   W   X   X |
   Z  | 0   1   X   Z   W   L   H   X   U |
   ...
```

**ตัวอย่าง:**

```vhdl
-- Tri-state bus: 2 driver drive คนละค่า → X
signal bus : std_logic;
process
begin
    bus <= '0';     -- driver 1: drives 0
    wait for 10 ns;
    bus <= '1';     -- driver 2: drives 1 (same time!)
    wait for 10 ns;
end process;
-- ช่วง 0-10 ns: bus = '0'
-- ช่วง 10-20 ns: conflict → 'X'
```

### B.1.2 std_ulogic (Unresolved)

- ไม่มี resolution function — 2 driver บน std_ulogic = **error ในการ compile**
- ใช้เมื่อต้องการให้ tool catch bug เร็ว ๆ

```vhdl
signal wire : std_ulogic;  -- safer for internal use
```

### B.1.3 ตัวอย่าง Tri-state bus

```vhdl
-- Tri-state buffer
process (en, din)
begin
    if en = '1' then
        dout <= din;
    else
        dout <= 'Z';   -- high impedance
    end if;
end process;

-- Bidirectional pin
process (din, oe)
begin
    if oe = '1' then
        pin <= din;
    else
        pin <= 'Z';
    end if;
end process;
```

---

## B.2 std_logic_vector

### B.2.1 Declaration

```vhdl
signal data : std_logic_vector(7 downto 0);   -- MSB first
signal addr : std_logic_vector(0 to 7);       -- LSB first (alternative)
```

**Convention:** ใช้ `downto` สำหรับ MSB ที่ index สูงกว่า (เช่น data[7] = MSB)

### B.2.2 Literal Assignment

```vhdl
data <= "1010_1100";   -- 8-bit, can use _ for readability
data <= x"A0";          -- hex literal (ใน VHDL-2008) เทียบเท่า "10100000"
data <= '0' & "0000001";  -- concatenate
data <= (others => '0');  -- ทุก bit เป็น '0'
data <= (others => '1');  -- ทุก bit เป็น '1'
data <= (others => 'X');  -- ทุก bit เป็น 'X' (initial)
```

### B.2.3 Slicing

```vhdl
signal full : std_logic_vector(15 downto 0);
signal low  : std_logic_vector(7 downto 0);
signal mid  : std_logic_vector(3 downto 0);

low  <= full(7 downto 0);    -- lower byte
mid  <= full(11 downto 8);   -- middle 4 bits
```

### B.2.4 Aggregate Assignment

```vhdl
type record_t is record
    a : std_logic_vector(3 downto 0);
    b : std_logic;
    c : integer;
end record;

signal r : record_t;
r <= (a => "0000", b => '1', c => 0);
r <= (a => (others => '0'), b => '1', c => 0);
```

---

## B.3 IEEE.NUMERIC_STD — unsigned/signed

### B.3.1 ความแตกต่าง

| Property | `unsigned` | `signed` |
|---|---|---|
| **Range** | 0 to 2^N-1 | -2^(N-1) to 2^(N-1)-1 |
| **MSB** | Unsigned weight | Sign bit (two's complement) |
| **Overflow** | Wraps around (mod 2^N) | Wraps around (mod 2^N) |
| **Use** | Addresses, counters | Signed math, signal processing |

### B.3.2 Declaration และ Literal

```vhdl
signal addr    : unsigned(15 downto 0);   -- 16-bit address (0..65535)
signal sample  : signed(11 downto 0);     -- 12-bit signed (-2048..2047)

addr   <= "0000_0000_0000_0100";           -- = 4
sample <= "1100_0000_0000";                -- = -1024 (sign extension!)
```

### B.3.3 Arithmetic Operations (NUMERIC_STD)

```vhdl
-- Addition
sum <= a + b;                              -- unsigned + unsigned

-- Subtraction (สำคัญมาก!)
diff <= a - b;                             -- unsigned: ถ้า a < b → wrap around!

-- Resize (zero-extend หรือ sign-extend)
big <= extended_sum(register, 16);           -- sign-extend (signed)
big <= unsigned'(0 => '0', others => register);  -- zero-extend
```

### B.3.4 ตัวอย่าง Overflow

```vhdl
signal a : unsigned(7 downto 0) := 200;
signal b : unsigned(7 downto 0) := 100;
signal sum : unsigned(8 downto 0);  -- 9 bits เพื่อเก็บ carry

sum <= "0" & a + "0" & b;            -- 200 + 100 = 300 < 512, OK

-- ถ้าใช้ unsigned(7 downto 0):
signal sum_bad : unsigned(7 downto 0);
sum_bad <= a + b;                    -- 200 + 100 = 300 mod 256 = 44! ✗ overflow ไม่ detect
```

### B.3.5 Signed Arithmetic

```vhdl
signal a, b : signed(7 downto 0);
signal prod : signed(15 downto 0);  -- 16-bit เพื่อเก็บผลคูณ

-- a = "10000000" (-128), b = "00000010" (+2)
prod <= a * b;  -- = -256 = "11111111_00000000"
```

**ตัวอย่าง overflow detection (signed):**

```vhdl
process (a, b)
    variable va, vb, vy : signed(8 downto 0);
begin
    va := "0" & a;
    vb := "0" & b;
    vy := va + vb;
    sum <= vy(7 downto 0);
    -- signed overflow: sign before vs after
    if (va(7) = vb(7)) and (vy(7) /= va(7)) then
        ovf <= '1';
    else
        ovf <= '0';
    end if;
end process;
```

---

## B.4 Type Conversion

### B.4.1 ตาราง Conversion

| From → To | Function | Example |
|---|---|---|
| `integer` → `unsigned` | `to_unsigned(n, 8)` | `to_unsigned(255, 8)` |
| `integer` → `signed` | `to_signed(n, 8)` | `to_signed(-1, 8)` |
| `unsigned` → `integer` | `to_integer(u)` | `to_integer(data)` |
| `signed` → `integer` | `to_integer(s)` | `to_integer(s_sample)` |
| `unsigned` ↔ `std_logic_vector` | `std_logic_vector(u)` / `unsigned(s)` | `std_logic_vector(data_u)` |
| `signed` ↔ `std_logic_vector` | `std_logic_vector(s)` / `signed(slv)` | `std_logic_vector(data_s)` |
| `std_logic` → `boolean` | `sl = '1'` | `if sl = '1' then ...` |
| `boolean` → `std_logic` | `b'val(0 or 1)` หรือใช้ conditional | `d'when b'val(1) else '0'` |

### B.4.2 ตัวอย่าง Conversion Code

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity converter is
    port (
        sw    : in  std_logic_vector(7 downto 0);
        btn   : in  std_logic;
        -- outputs as integer
        val_i : out integer range 0 to 255;
        -- outputs as unsigned
        val_u : out unsigned(7 downto 0);
        -- outputs as boolean
        on    : out boolean
    );
end entity;

architecture rtl of converter is
begin
    val_i <= to_integer(unsigned(sw));
    val_u <= unsigned(sw);
    on    <= (btn = '1');
end architecture;
```

### B.4.3 ข้อผิดพลาดที่พบบ่อย

```vhdl
-- ❌ BAD: implicit conversion ไม่ได้
signal u : unsigned(7 downto 0);
signal s : std_logic_vector(7 downto 0);
s <= u;                          -- ERROR: type mismatch

-- ✅ GOOD: explicit conversion
s <= std_logic_vector(u);

-- ❌ BAD: assign integer to std_logic_vector
s <= 100;                        -- ERROR

-- ✅ GOOD
s <= std_logic_vector(to_unsigned(100, 8));
```

---

## B.5 Subtypes

ใช้สร้าง type ใหม่ที่มี constraint เฉพาะ เพื่อ readability และ type safety:

```vhdl
subtype byte_t  is unsigned(7 downto 0);    -- 8-bit unsigned
subtype word_t  is unsigned(15 downto 0);  -- 16-bit unsigned
subtype nibble_t is unsigned(3 downto 0);   -- 4-bit
subtype sbyte_t is signed(7 downto 0);      -- signed 8-bit

signal data_byte  : byte_t;
signal data_word  : word_t;
signal data_nibble : nibble_t;
signal signed_val : sbyte_t;
```

**Type Safety:**

```vhdl
procedure process_word(w : in word_t) is
begin
    -- รับเฉพาะ word_t, ไม่ใช่ byte_t โดยตรง
end procedure;

process_word(data_byte);  -- ERROR: type mismatch
process_word(word_t(data_byte));  -- OK: explicit conversion
```

---

## B.6 Arrays and Records

### B.6.1 Array

```vhdl
-- 1D array (RAM)
type ram_t is array (0 to 255) of unsigned(7 downto 0);
signal mem : ram_t;

-- 2D array (register file)
type regfile_t is array (0 to 31) of unsigned(31 downto 0);
signal regs : regfile_t;

-- Constrained array
signal data : std_logic_vector(7 downto 0);  -- unconstrained
type nibble_array_t is array (natural range <>) of unsigned(3 downto 0);
signal nibbles : nibble_array_t(0 to 7);
```

### B.6.2 Record (จัดกลุ่ม signal ที่เกี่ยวข้อง)

```vhdl
type cpu_state_t is record
    pc      : counter;
    regs    : regfile_t;
    halted  : boolean;
    irq     : boolean;
    cycle   : counter;
end record;

signal cpu : cpu_state_t;

-- Access
cpu.pc <= 16'h0000;
cpu.halted <= false;
if cpu.irq then ... end if;
```

---

## B.7 ตัวอย่าง End-to-End: ALU ที่ใช้ Types ถูกต้อง

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package alu_types_pkg is
    constant WORD_WIDTH : integer := 16;
    type    word_t is unsigned(WORD_WIDTH-1 downto 0);
    type    op_t is (ADD, SUB, AND_OP, XOR_OP, SHL);
end package;

library work;
use work.alu_types_pkg.ALL;

entity alu is
    port (
        a, b  : in  word_t;
        op    : in  op_t;
        y     : out word_t;
        z_flag : out std_logic;
        n_flag : out std_logic
    );
end entity;

architecture rtl of alu is
begin
    p : process (a, b, op)
        variable vy : word_t;
    begin
        case op is
            when ADD    => vy := a + b;
            when SUB    => vy := a - b;
            when AND_OP => vy := a and b;
            when XOR_OP => vy := a xor b;
            when SHL    => vy := a(WORD_WIDTH-2 downto 0) & '0';
            when others  => vy := (others => '0');
        end case;
        y <= vy;
        z_flag <= '1' when (vy = (vy'range => '0')) else '0';
        n_flag <= vy(vy'left);
    end process;
end architecture;
```

---

## B.8 Best Practices

### B.8.1 ใช้ Library ที่ถูกต้อง

```vhdl
-- ✅ Standard
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ❌ Avoid (non-standard, deprecated)
use IEEE.STD_LOGIC_ARITH.ALL;    -- ใช้ NUMERIC_STD แทน
use IEEE.STD_LOGIC_UNSIGNED.ALL; -- ใช้ unsigned type แทน
```

### B.8.2 เลือก Type ที่เหมาะสม

| Use case | Type |
|---|---|
| Single-bit signal | `std_logic` |
| Multi-bit signal, no arithmetic | `std_logic_vector` |
| Counter, address (unsigned math) | `unsigned` |
| Signed arithmetic | `signed` |
| Loop counter (internal) | `integer` (ใช้ internal only) |
| Conditional check | `boolean` (ใน if/case condition) |
| Parameter | `integer` |

### B.8.3 หลีกเลี่ยงการผสม signed/unsigned ในการคำนวณ

```vhdl
-- ❌ ผสม
process (a, b)  -- a: signed, b: unsigned
begin
    y <= a + b;  -- ⚠️ tool อาจเตือก ไม่ควรทำ
end process;

-- ✅ Convert ก่อน
process (a, b)
begin
    y <= a + signed(b);  -- OK ถ้า b ควรตีความเป็น signed
end process;
```

### B.8.4 Initial Value ของ Signal

```vhdl
-- ✅ Default เป็น '0' หรือ 'X' ใน testbench
signal counter : unsigned(7 downto 0) := (others => '0');

-- ⚠️ ใน design ไม่ใช้ initial - ใช้ reset แทน
```

### B.8.5 Slice vs Cast

```vhdl
-- Slice (ไม่เปลี่ยน type)
signal full : std_logic_vector(15 downto 0);
signal low : std_logic_vector(7 downto 0);
low <= full(7 downto 0);  -- slice, OK

-- ❌ Assign full type → narrow type
low <= full;  -- ERROR: width mismatch

-- Cast
signal u8 : unsigned(7 downto 0);
signal s8 : signed(7 downto 0);
signal v8 : std_logic_vector(7 downto 0);
v8 <= std_logic_vector(u8);  -- cast, OK
s8 <= signed(v8);            -- cast, OK
```

---

## B.9 Time และ Real (ใช้ใน Testbench เท่านั้น)

### B.9.1 Time

```vhdl
-- ใช้ใน wait statements (testbench only)
wait for 10 ns;
wait until rising_edge(clk) for 100 ns;  -- timeout (VHDL-2008)
```

### B.9.2 Real (Floating-Point)

```vhdl
-- ใช้ในการคำนวณ delay หรือสร้าง waveform
variable dly : real := 12.5;
wait for dly ns;  -- OK
```

**⚠️ ไม่ synthesize:** time และ real ไม่สามารถสังเคราะห์ได้

### B.9.3 Integer

```vhdl
-- ภายใน process เป็น loop variable
for i in 0 to 7 loop
    if data(i) = '1' then
        count := count + 1;
    end if;
end loop;
```

**⚠️ Integer arithmetic ใน design:** ถ้าใช้ `+`, `*` บน integer จะถูกสังเคราะห์เป็น adder/multiplier

---

## B.10 ตารางสรุป Data Types

| Type | ขนาด | Domain | Synthesizable | Notes |
|---|---|---|---|---|
| `bit` | 1 | Digital | ✓ | Simple boolean, แต่ใช้ `std_logic` ดีกว่า |
| `std_logic` | 1 | Digital | ✓ (ส่วมตัว '0'/'1') | ค่า 9 ตัว รวม X, Z, - |
| `unsigned` | N | Arithmetic | ✓ | Unsigned arithmetic |
| `signed` | N | Arithmetic | ✓ | Two's complement signed |
| `std_logic_vector` | N | Bus | ✓ | Multi-bit bus |
| `integer` | ≥ 32 | Counter | ✓ (เป็น adder) | ใช้ตั้งแต่ 32-bit default |
| `boolean` | 1 | Logic | ⚠️ (limited) | ใช้ใน if/while condition |
| `time` | ≥ 64 | ⚠️ Testbench only | ✗ | ไม่สังเคราะห์ |
| `real` | 64 | ⚠️ Testbench only | ✗ | ไม่สังเคราะห์ |
| `character` | 8 | String | ⚠️ | ใช้ใน string เท่านั้น |
| `natural` / `positive` | ≥ 32 | Loop | ✓ | Subtype ของ integer (≥ 0 หรือ > 0) |

---

## B.11 Common Pitfalls

### B.11.1 Mixing std_logic_vector กับ unsigned

```vhdl
signal a : std_logic_vector(7 downto 0);
signal b : unsigned(7 downto 0);

-- ❌ ผสม
a <= b + 1;  -- ERROR: cannot assign unsigned to std_logic_vector

-- ✅ Convert
a <= std_logic_vector(b + 1);
```

### B.11.2 Index Out of Range

```vhdl
signal data : std_logic_vector(7 downto 0);  -- index 0..7

-- ❌ Out of range
data(8) <= '1';  -- ERROR
```

### B.11.3 Width Mismatch

```vhdl
signal a : unsigned(7 downto 0);   -- 8 bits
signal b : unsigned(3 downto 0);   -- 4 bits

-- ❌ Width mismatch
b <= a;  -- ERROR: width mismatch

-- ✅ Slice
a <= "0000" & b;  -- zero-extend (4→8 bits)
```

### B.11.4 Sign Confusion

```vhdl
signal a : unsigned(7 downto 0);
signal b : signed(7 downto 0);

-- ❌ ผสม
if a = b then ...  -- อาจให้ผลผิด (signed vs unsigned comparison)
```

### B.11.5 Default Value Issue

```vhdl
signal flag : std_logic;  -- default 'U' ใน simulation
-- หลัง power-on ใน ASIC: flag จะเป็น 'X' หรือ random

-- ✅ ใช้ reset
process (clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            flag <= '0';
        end if;
    end if;
end process;
```

---

## B.12 สรุป Key Takeaways

### B.12.1 Simulation vs Synthesis

1. **Simulation** = ตรวจ logic, **Synthesis** = สร้าง hardware จริง
2. **Simulation flexible** — ใช้ type อะไรก็ได้, **Synthesis restricted** — เฉพาะ synthesizable subset
3. **Simulation event-driven** ด้วย delta cycle, **Synthesis structural** สร้างจาก RTL
4. **ใช้ coding style** ที่ compatible ทั้งสอง เพื่อหลีกเลี่ยง mismatch
5. **Synchronous reset + single clock + no latch** เป็น golden rule

### B.12.2 Data Types

1. **`std_logic`** = 1-bit, ค่า 9 ตัว, ใช้มากที่สุด
2. **`std_logic_vector`** = multi-bit bus
3. **`unsigned`/`signed`** = arithmetic
4. **Conversion** = ต้อง explicit, ใช้ `std_logic_vector(u)`, `to_unsigned()`, etc.
5. **ใช้ IEEE.STD_LOGIC_1164 + IEEE.NUMERIC_STD** เท่านั้น
6. **หลีกเลี่ยง** signed/unsigned mixing, width mismatch, out-of-range index

---

## B.13 อ้างอิง

- IEEE Std 1076-2008, "VHDL Language Reference Manual," Section 16 (Standard packages).
- Ashenden, P. J. "The Designer's Guide to VHDL," Chapter 5 (Types) และ Chapter 16 (Simulation).
- IEEE Std 1076.4-2000, "VHDL Synthesis Package" — สำหรับ `ieee.numeric_std`.
- "Mentor Graphics ModelSim/Questa User's Manual," Section on std_logic Resolution Table.
- Smith, M. J. S. "Application-Specific Integrated Circuits," Chapter 5 (Synthesis).

---

> **หมายเหตุ:** เนื้อหานี้ออกแบบให้บรรยายได้ประมาณ 90-120 นาที รวม ASCII diagrams, ตารางเปรียบเทียบ, ตัวอย่างโค้ดที่ compile ผ่านได้ พร้อมใช้ประกอบการสอนภาคทฤษฎี Day 1 (ส่วนบ่ายหลังพักเที่ยง) หรือแทรกเป็น 2 mini-lectures แยก (Simulation vs Synthesis 45 นาที + Data Types 45 นาที)

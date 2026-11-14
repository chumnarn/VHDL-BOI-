# Post-test: Advanced Digital IC Design & Verification (Part 1)

> **คำแนะนำ:** ทำข้อสอบหลังเรียนจบ 25 ข้อ (ใช้เวลา ~60 นาที)
> **ระดับความยาก:** Intermediate → Advanced
> **คะแนนเต็ม:** 100 คะแนน
> **เฉลย:** ดูได้ที่หน้า "เฉลยโดยละเอียด" ที่ท้ายเอกสาร

---

## คำชี้แจง

- **ข้อ 1-10:** Multiple Choice (4 คะแนน/ข้อ) = 40 คะแนน
- **ข้อ 11-18:** Code Analysis (5 คะแนน/ข้อ) = 40 คะแนน
- **ข้อ 19-25:** Short Answer (20 คะแนน/ข้อ) = 20 คะแนน

**รวม:** 100 คะแนน

---

## Part A: Multiple Choice (ข้อ 1-10)

### ข้อ 1 — VHDL Signal Update

```vhdl
architecture demo of sig_vht is
    signal x, y, z : std_logic := '0';
begin
    process (a, b)
    begin
        x <= a;
        y <= x;
        z <= y;
    end process;
end architecture;
```

**เมื่อ `a` เปลี่ยนจาก '0' เป็น '1' ในรอบ 1, ค่าของ `x`, `y`, `z` ในรอบถัดไปเป็นอย่างไร?**

- A) x='1', y='1', z='1'
- B) x='1', y='0', z='0' (delta delay)
- C) x='1', y='1', z='0' (1 cycle delay)
- D) x='X', y='X', z='X' (unknown)

---

### ข้อ 2 — Synthesis Optimization

**Code ใดให้ผลลัพธ์การสังเคราะห์ (synthesis) ที่ดีที่สุด?**

```vhdl
-- Option A: Direct multiplication
result <= a * b * c;

-- Option B: Multiplication split
result <= (a * b) * c;

-- Option C: Pipelined multiplication
process (clk)
begin
    if rising_edge(clk) then
        stage1 <= a * b;
        result <= stage1 * c;
    end if;
end process;

-- Option D: Shift-and-add
result <= (a << shift_amount) + b;
```

- A) Option A: direct multiplication
- B) Option B: split multiplication
- C) Option C: pipelined multiplication (latency 1)
- D) Option D: shift-and-add (faster)

---

### ข้อ 3 — FSM State Encoding

**สำหรับ FSM ที่มี performance สูง (high-speed), encoding ใดเหมาะสมที่สุด?**

- A) Binary (sequential)
- B) One-Hot
- C) Gray
- D) Johnson

---

### ข้อ 4 — Reset Strategy

**Design ต้องการ reset ที่ทำงานทันทีที่ power-on และไม่ต้องการ clock ทำงาน ควรเลือก reset แบบใด?**

- A) Synchronous Reset
- B) Asynchronous Reset
- C) Hybrid (Async Assert + Sync De-assert)
- D) ไม่ต้องใช้ reset

---

### ข้อ 5 — Latch Inference

**Code ใดจะ infer latch ที่ output `y`?**

```vhdl
-- Option A
process (sel, a, b)
begin
    if sel = '1' then
        y <= a;
    elsif sel = '0' then
        y <= b;
    end if;
end process;

-- Option B
process (sel, a, b)
begin
    if sel = '1' then
        y <= a;
    end if;
end process;

-- Option C
process (sel, a, b)
begin
    y <= b;
    if sel = '1' then
        y <= a;
    end if;
end process;

-- Option D
process (sel, a, b)
begin
    case sel is
        when '1' => y <= a;
        when others => y <= b;
    end case;
end process;
```

- A) Option A
- B) Option B
- C) Option C
- D) Option D

---

### ข้อ 6 — Clock Domain Crossing

**สัญญาณ multi-bit `counter[7:0]` ที่เปลี่ยนจาก clock 200 MHz ไปยัง clock 100 MHz (unrelated) ควรใช้เทคนิคใด?**

- A) 2-FF synchronizer ทุกบิต
- B) Gray code + 2-FF sync
- C) Direct wire connection
- D) Clock gating

---

### ข้อ 7 — Functional Coverage

**SystemVerilog covergroup ใดให้ coverage ดีที่สุด (มี coverage points มากที่สุด)?**

```systemverilog
// Option A
cp_data : coverpoint data {
    bins all[] = {[0:255]};  // 256 bins
}

// Option B
cp_data : coverpoint data {
    bins zero = {0};
    bins ff   = {255};
    bins mid  = {[1:254]};
}

// Option C
cp_data : coverpoint data {
    bins zero = {0};
    bins ff   = {255};
    bins alt1 = {0x55, 0xAA};
    bins others = default;
}
```

- A) Option A (256 bins, all data)
- B) Option B (3 bins)
- C) Option C (4 bins)
- D) Coverage เท่ากัน

---

### ข้อ 8 — SDF

**SDF command `IOPATH A Y (0.15) (0.20)` หมายความว่าอย่างไร?**

- A) Delay จาก input Y ไป output A คือ 0.15 และ 0.20 ns
- B) Delay จาก input A ไป output Y: rise=0.15, fall=0.20 ns
- C) Delay ของ net A Y เป็น 0.15 และ 0.20
- D) เป็น interconnect delay

---

### ข้อ 9 — GLS Issue

**GLS แสดง `'X'` ใน output แม้ว่า RTL simulation ปกติดี สาเหตุที่เป็นไปได้มากที่สุด?**

- A) Bug ใน testbench
- B) Setup/Hold violation
- C) Testbench ไม่ครอบคลุม
- D) Function mismatch จาก synergize ไม่สมบูรณ์

---

### ข้อ 10 — Verification Methodology

**Cover ที่ดีที่สุดสำหรับ critical block (เช่น FIFO) คือข้อใด?**

- A) Code coverage 100%
- B) Functional coverage 100%
- C) Functional + Assertion + Formal
- D) Random test 1M patterns

---

## Part B: Code Analysis (ข้อ 11-18)

### ข้อ 11 — Bug Detection (5 คะแนน)

**พบ Bug ใน code ต่อไปนี้ อธิบาย bug และแก้ไข:**

```vhdl
-- 8-bit counter with CE
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter_bug is
    port (
        clk : in std_logic;
        rst_n : in std_logic;
        ce : in std_logic;
        cnt : out unsigned(7 downto 0)
    );
end entity;

architecture rtl of counter_bug is
begin
    process (clk)
    begin
        if rising_edge(clk) then
            cnt <= cnt + 1;        -- ⚠️ บรรทัดนี้
        end if;
    end process;
end architecture;
```

**คำถาม:** Bug คืออะไร? แก้ไขอย่างไร?

---

### ข้อ 12 — FSM Correctness (5 คะแนน)

**Moore FSM นี้ถูกต้องหรือไม่? ถ้าผิด อธิบาย:**

```vhdl
type state_t is (S_IDLE, S_RUN, S_DONE);
signal state : state_t;

process (clk)
begin
    if rising_edge(clk) then
        if rst_n = '0' then
            state <= S_IDLE;
        else
            case state is
                when S_IDLE => state <= S_RUN;
                when S_RUN  => state <= S_DONE;
                when S_DONE => state <= S_IDLE;
                when others => state <= S_IDLE;
            end case;
        end if;
    end if;
end process;
```

---

### ข้อ 13 — Synthesis-Ready Code (5 คะแนม)

**Code นี้ compile ผ่าน แต่ synthesis FAIL เพราะอะไร?**

```vhdl
entity async_logic is
    port (
        a, b : in  std_logic;
        y    : out std_logic
    );
end entity;

architecture bad of async_logic is
begin
    y <= a after 5 ns;  -- ⚠️
end architecture;
```

---

### ข้อ 14 — CDC Code (5 คะแนน)

**Code นี้ผ่าน simulation แต่มีปัญหา CDC อธิบาย:**

```vhdl
process (clk_fast)
begin
    if rising_edge(clk_fast) then
        flag_slow <= '1';   -- เปลี่ยนทุก cycle ที่ clk_fast
    end if;
end process;

process (clk_slow)
begin
    if rising_edge(clk_slow) then
        if flag_slow = '1' then   -- ใช้ flag ข้าม domain
            counter <= counter + 1;
        end if;
    end if;
end process;
```

---

### ข้อ 15 — Testbench Bug (5 คะแนน)

**TB นี้ผ่าน TB pass แต่ไม่ได้ verify จริง อธิบาย:**

```vhdl
process
begin
    wait for 1 us;
    assert false
        report "Test failed"
        severity failure;
end process;
```

---

### ข้อ 16 — GLS Analysis (5 คะแนน)

**จาก transcript นี้ วิเคราะห์ปัญหา:**

```
# ** Warning: Setup violation detected
# **         Time: 8.234 ns  Iteration: 50
# **         Path: dut.U1/Q → dut.U2/D
# **         Required setup: 0.150 ns
# **         Actual setup: 0.100 ns
# **         Slack: -0.050 ns
```

---

### ข้อ 17 — Assertion Debug (5 คะแนน)

**Assertion นี้ถูกต้องหรือไม่?**

```vhdl
-- "REQ must remain high until ACK"
assert_req_held : assert always
    (req = '1') -> (req = '1') until (ack = '1')
    report "REQ must remain high until ACK"
    severity failure;
```

---

### ข้อ 18 — Resource Estimation (5 คะแนน)

**จาก spec ต่อไปนี้ ประมาณ FF count และ block RAM ที่ต้องการ:**

```
   Spec: 32-bit CPU with:
   - 32 × 32-bit registers (register file)
   - 4 KB cache (direct-mapped, 4-way set associative)
   - 32-bit ALU with adder, shifter
   - FSM controller (10 states)
```

---

## Part C: Short Answer (ข้อ 19-25)

### ข้อ 19 — Verification Strategy (20 คะแนน)

**ออกแบบ Verification Plan สำหรับ Memory Controller (ที่ใช้ AXI4 interface):**

ประกอบด้วย:
1. **Feature List** (≥ 5 features)
2. **Test Plan** (≥ 5 test cases พร้อม stimulus/expected)
3. **Coverage Goals** (กำหนด coverage targets)
4. **Assertions** (≥ 3 PSL/SVA assertions)

---

### ข้อ 20 — Synthesis Optimization (20 คะแนน)

**ออกแบบ RTL ที่ optimized สำหรับ:**

**Function:** 8-bit saturate adder
```
if (a + b > 255) then result = 255
else result = a + b
```

**ข้อกำหนด:**
- ใช้ FF-based design (synchronous)
- Synthesis-friendly (no latches)
- Low area
- Latency = 1 clock

เขียน VHDL code + อธิบาย optimization ที่ใช้

---

## เกณฑ์การประเมิน

| Score | Level | Comment |
|-------|-------|---------|
| 90-100 | Excellent | พร้อมเรียน Part 2 |
| 80-89 | Very Good | พร้อม + ทบทวนจุดที่ผิด |
| 70-79 | Good | ผ่าน |
| 60-69 | Pass | ต้องเสริม |
| <60 | Need Review | ทบทวนจุดอ่อน |

---

# เฉลยโดยละเอียด

## Part A: Multiple Choice

### ข้อ 1 — **B) x='1', y='0', z='0' (delta delay)**

**คำอธิบาย:**
ใน VHDL, signal assignment ใช้ **delta delay** — ค่าใหม่จะมีผลหลัง process จบ (ที่สุดของ simulation cycle)

```
   Time t:
   - x <= a       (schedule: x will be a next delta)
   - y <= x       (schedule: y will be current x, which is still '0')
   - z <= y       (schedule: z will be current y, which is still '0')

   After process, all signals update:
   - x becomes '1'
   - y becomes old x ('0')
   - z becomes old y ('0')
```

ถ้าต้องการ chain ที่สมบูรณ์ใน 1 delta, ต้องใช้ variable (อัปเดตทันที)

---

### ข้อ 2 — **C) Option C: pipelined multiplication**

**คำอธิบาย:**
- Option A: 2 multipliers ใน 1 cycle → critical path ยาว → ลด clock frequency
- Option B: เหมือน A แต่แยก (ไม่ช่วย)
- Option C: ✅ แบ่ง 2 stages, FF ตรงกลาง → latency 1 cycle, throughput สูง
- Option D: shift-and-add เหมาะกับ shift by constant, ไม่ใช่ arbitrary

**Trade-off:** Pipelining vs Combinational:
- Pipelining: latency +1, throughput สูง, area +FF
- Combinational: latency = 1, throughput ต่ำกว่า (clock period ยาว)

---

### ข้อ 3 — **B) One-Hot**

**คำอธิบาย:**
- Binary: น้อย FF, แต่ multiple-bit transitions → glitches
- ✅ One-Hot: 1 FF per state → single-bit transitions → minimal glitches, fast decode
- Gray: single-bit แต่ complex encoding
- Johnson: น้อยใช้

---

### ข้อ 4 — **B) Asynchronous Reset**

**คำอธิบาย:**
Async reset ทำงานโดยไม่ต้องมี clock → เหมาะกับ power-on reset แต่ต้องมี synchronizer ตอน de-assert

---

### ข้อ 5 — **B) Option B**

**คำอธิบาย:**
- **Option A**: ⚠️ มี elsif แต่ไม่มี else → tool อาจ infer latch
- **Option B**: ❌ ไม่มี else → INFER LATCH (y ไม่ถูก assign ในทุก path)
- **Option C**: ✅ Default assignment + full if → safe
- **Option D**: ✅ Full case with when others → safe

**คำตอบที่ถูก: B) Option B** — เพราะ `if cond then` ที่ไม่มี else จะ infer latch

---

### ข้อ 6 — **B) Gray code + 2-FF sync**

**คำอธิบาย:**
Multi-bit bus ข้าม unrelated domain ต้องใช้:
- **Gray code** (single-bit change per cycle) + 2-FF sync ทุกบิต
- หรือ **Handshake protocol** (request/ack)
- หรือ **Async FIFO**

2-FF sync ตรง ๆ กับ multi-bit → bits เปลี่ยนพร้อมกัน → ไม่ sync กันทุกบิต

---

### ข้อ 7 — **C) Option C (4 bins)**

**คำอธิบาย:**
- Option A: 256 bins → เยอะ, coverage ยาก
- Option B: 3 bins → ครอบคลุมต่ำ
- ✅ Option C: 4 bins + default → coverage targeted + catch most scenarios

ในทางปฏิบัติ, manual bins + default = good balance

---

### ข้อ 8 — **B) Delay จาก input A ไป output Y: rise=0.15, fall=0.20 ns**

**คำอธิบาย:**
IOPATH syntax: `(IOPATH input_pin output_pin (rise) (fall))`

ดังนั้น:
- Input A → Output Y
- Rise delay: 0.15 ns
- Fall delay: 0.20 ns

---

### ข้อ 9 — **B) Setup/Hold violation**

**คำอธิบาย:**
X ใน GLS (ไม่ใช่ RTL) = สัญญาณของ timing issue
- Setup violation: data ไม่ทัน → FF output = X
- Hold violation: data เปลี่ยนเร็วไป → FF output = X
- Uninitialized FF: ไม่มี reset → initial = X

ถ้า RTL ปกติ + GLS มี X = timing issue ที่ RTL sim ไม่เห็น

---

### ข้อ 10 — **C) Functional + Assertion + Formal**

**คำอธิบาย:**
Critical block ต้องการ verification หลายระดับ:
- Functional coverage (features tested)
- Assertions (protocol, properties)
- Formal verification (proof สำหรับ critical properties)

ไม่ควร rely แค่ code coverage หรือ random tests

---

## Part B: Code Analysis

### ข้อ 11 — Bug in Counter

**Bug:** ไม่มี reset path → counter เริ่มที่ X ใน ASIC (FPGA อาจ initialize เป็น 0 แต่ไม่แน่นอน)

**แก้ไข:**
```vhdl
architecture rtl of counter_fixed is
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                cnt <= (others => '0');
            else
                cnt <= cnt + 1;
            end if;
        end if;
    end process;
end architecture;
```

**คำอธิบาย:** Synchronous reset เริ่มที่ค่า known (0) หลัง power-on

---

### ข้อ 12 — FSM Issue

**ปัญหา:**
1. ⚠️ `when others` ใช้ได้ แต่ถ้า state เป็นค่าที่ไม่ได้ encode (e.g., จาก FF glitch) → next state = S_IDLE อาจเป็น silent recovery
2. ⚠️ ไม่มี output logic

**ถ้าเป็น Moore:** ต้องเพิ่ม output logic:
```vhdl
-- Output depends on state
output <= '1' when state = S_DONE else '0';
```

**ถ้าไฟล์ผ่านตามที่ถาม** (Moore FSM): code ถูกต้อง เพราะมี when others ครบ

แต่ควรเพิ่ม: `assert state inside state_s type` ใน TB เพื่อ catch illegal states

---

### ข้อ 13 — Synthesis FAIL

**สาเหตุ:** `after 5 ns` เป็น delay specification — ไม่สามารถ synthesize

**Fix:**
```vhdl
-- Option 1: Remove delay (pure combinational)
y <= a and b;

-- Option 2: Use clocked process (register output)
process (clk)
begin
    if rising_edge(clk) then
        y <= a and b;
    end if;
end process;
```

---

### ข้อ 14 — CDC Issue

**ปัญหา:** `flag_slow` เปลี่ยนที่ `clk_fast` (200 MHz) แต่ใช้ที่ `clk_slow` (100 MHz)
- FF ที่ latch flag_slow ใน clk_slow domain อาจ metastable

**แก้ไข:** ใช้ 2-FF synchronizer:
```vhdl
process (clk_slow)
begin
    if rising_edge(clk_slow) then
        sync1 <= flag_slow;
        sync2 <= sync1;
    end if;
end process;

-- ใช้ sync2 แทน flag_slow
if sync2 = '1' then
    counter <= counter + 1;
end if;
```

---

### ข้อ 15 — TB Bug

**ปัญหา:** `wait for 1 us; assert false ... severity failure` — TB ล้มเหลวตลอด!

ถ้าใช้ `severity failure` จะ **หยุด simulator** ทุกครั้ง

**ถ้า TB ผ่าน** เพราะไม่มี stimulus = ไม่ได้ทดสอบอะไร

**Fix:**
```vhdl
process
begin
    -- Stimulus
    rst_n <= '0'; wait for 100 ns;
    rst_n <= '1';
    -- ... send test patterns ...

    -- Then check
    assert test_passed
        report "Test failed"
        severity failure;
end process;
```

---

### ข้อ 16 — GLS Issue

**ปัญหา:** Setup violation
- Required: 150 ps (FF_U2 setup time)
- Actual: 100 ps
- Slack: **-50 ps** (VIOLATED)

**สาเหตุ:** Combinational delay U1 → U2 นานเกิน clock period - setup time

**แก้ไข (ตัวเลือก):**
1. **เพิ่ม clock period**: 10 ns → 15 ns
2. **Pipeline**: ใส่ FF ระหว่าง U1 → U2
3. **Logic optimization**: ลด delay
4. **Use higher drive cells**: NAND2X1 → NAND2X2

**คำแนะนำ:** เลือก option 2 สำหรับ high-performance design

---

### ข้อ 17 — Assertion Correctness

**ถูกต้อง** ✅

**ตีความ:**
- `(req = '1') -> (req = '1') until (ack = '1')` หมายความว่า
- ถ้า req = '1' → req ต้องเป็น '1' ต่อเนื่องจนกว่า ack จะเป็น '1'

**ตัวอย่าง:**
```
   req:  ─────┐
              └─────────────────── ← ต้องคงเป็น 1 ต่อจนกว่า ack
   ack:        ┌─┐
               │ │
               └─┘
```

**ใช้สำหรับ:** Handshake ที่ต้องให้ req คงอยู่จนกว่า ack จะตอบรับ

---

### ข้อ 18 — Resource Estimation

**32-bit CPU:**

| Resource | FF Count | Comment |
|----------|----------|---------|
| Register File (32 × 32) | 32 × 32 = **1024 FFs** | หรือใช้ SRAM |
| ALU | ~64 FFs | pipeline registers |
| FSM (10 states) | 10 FFs (one-hot) หรือ 4 FFs (binary) | **10 FFs** |
| PC | **32 FFs** |  |
| Other (CSR, status) | ~100 FFs |  |
| **Total FFs** | **~1230 FFs** |  |

**Block RAM (Cache):**
- 4 KB cache = 4 × 1024 × 8 bits = 32 Kbits = 4 BRAMs (each 36 Kb on Xilinx)

**ALU:**
- 32-bit adder: 32 FFs (with pipeline) + combinational gates
- Shifter: 32 FFs

**Total:** ~1.2K FFs, 4 BRAMs, ~500 gates for combinational logic

---

## Part C: Short Answer

### ข้อ 19 — Verification Plan สำหรับ Memory Controller (AXI4)

#### 1. Feature List

| ID | Feature | Description | Priority |
|----|---------|-------------|----------|
| F01 | AXI4 Read Transaction | AR → R response | Critical |
| F02 | AXI4 Write Transaction | AW → W → B | Critical |
| F03 | Outstanding transactions | Multiple in-flight | High |
| F04 | Burst types | FIXED, INCR, WRAP | High |
| F05 | Response handling | OKAY, EXOKAY, ERR | High |
| F06 | Memory protection | MPROT signals | Medium |

#### 2. Test Plan

| Test ID | Description | Stimulus | Expected |
|---------|-------------|----------|----------|
| T01 | Single beat read | AW: addr=0, len=0 | R: data, BRESP=OKAY |
| T02 | 4-beat burst read | AW: addr=0, len=3, burst=INCR | 4 R beats |
| T03 | Single write | AW+W: addr, data | B: BRESP=OKAY |
| T04 | 8-beat WRAP | addr=0, len=7 | Wraps to addr=0 |
| T05 | Out-of-order | 2 outstanding reads | R returns in order |
| T06 | Error response | Invalid address | R: RRESP=DECERR |
| T07 | Narrow transfer | AW: size=010 | 2 data beats |

#### 3. Coverage Goals

- Statement: ≥ 95%
- Branch: ≥ 90%
- Functional coverage: 100%
  - All burst types
  - All response codes
  - All sizes
- Assertion coverage: 100%

#### 4. Assertions

```systemverilog
// 1. AW must precede W
property aw_before_w;
    @(posedge clk) awvalid && awready |=> wvalid;
endproperty

// 2. B after W
property b_after_w;
    @(posedge clk) wvalid && wready && wlast |-> bvalid;
endproperty

// 3. R data integrity
property r_data_ok;
    @(posedge clk) rvalid && rready |-> rdata matches aw addr;
endproperty
```

---

### ข้อ 20 — Saturate Adder (Optimized)

#### VHDL Code

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity saturate_add8 is
    port (
        clk  : in  std_logic;
        rst_n: in  std_logic;
        a, b : in  unsigned(7 downto 0);
        y    : out unsigned(7 downto 0)
    );
end entity;

architecture rtl of saturate_add8 is
    signal sum_ext : unsigned(8 downto 0);
begin
    sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                y <= (others => '0');
            else
                sum_ext <= ("0" & a) + ("0" & b);
                if sum_ext(8) = '1' then  -- overflow
                    y <= (others => '1');  -- saturate to 255
                else
                    y <= sum_ext(7 downto 0);
                end if;
            end if;
        end if;
    end process;
end architecture;
```

#### Optimization ที่ใช้

1. **FF-based**: ไม่มี combinational output → ไม่มี latch
2. **Extended adder**: 9-bit (1 bit extra for overflow detect)
3. **Overflow detection**: ตรวจ MSB ของ sum_ext (overflow bit)
4. **Saturation**: saturate ที่ค่า 255 (0xFF)
5. **Reset**: synchronous, initial state known

#### Resource:
- 8 FFs (output register)
- 1 FF (sum_ext)
- 1 adder (9-bit)
- MUX/control logic: minimal

#### Timing:
- Latency: 1 clock cycle
- Critical path: adder + mux = ~20 F04 inverter delay (good)

---

## Scoring Rubric

| Part | Question Type | Max Points |
|------|---------------|------------|
| A | Multiple Choice | 40 |
| C | Code Analysis | 40 |
| B | Short Answer | 20 |
| **Total** | | **100** |

## Grading Scale

| Score | Grade | Recommendation |
|-------|-------|----------------|
| 90-100 | A | พร้อมเรียน Part 2 |
| 80-89 | B | ทบทวนจุดที่ผิด |
| 70-79 | C | ผ่าน + เสริม |
| 60-69 | D | ทบทวนจุดอ่อน |
| <60 | F | เรียนซ้ำ |

---

## Tips for Success

1. ✅ **อ่าน code ให้ละเอียด** ก่อนตอบ
2. ✅ **วิเคราะห์ทุกมิติ** (functional, timing, area)
3. ✅ **เขียน syntax ที่ถูกต้อง** ใน Short Answer
4. ✅ **ตรวจคำตอบ** ก่อนส่ง

---

## สรุปการเปรียบเทียบ Pre-test vs Post-test

| Topic | Pre-test | Post-test |
|-------|----------|-----------|
| Difficulty | Beginner | Advanced |
| Focus | Conceptual | Multiple Choice |
| Time | 45-60 min | 60 min |
| Code Analysis | 0 questions | 8 questions |
| Open-ended | 5 questions | 2 questions |

---

> **หมายเหตุ:** Post-test นี้เป็น final assessment ของ Part 1
> ทำเสร็จแล้ว = พร้อมสำหรับ Part 2 (IC Layout + MEMS Design)
>
> ถ้าต่ำกว่า 70% → ควรทบทวนจุดที่ผิดในเฉลย

## 🎓 ขอให้โชคดีกับการทำ Post-test!

ถ้าผ่าน → **สำเร็จ Part 1 แล้ว** → พร้อมเรียน Part 2
ถ้าต่ำกว่า → ทบทวนจุดอ่อน + ทำ Lab ใหม่
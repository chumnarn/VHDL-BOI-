# รายละเอียดเชิงลึก: Synchronous Design & Reset Strategy

> เนื้อหานี้ออกแบบมาให้นำไปแทรกเป็นส่วนขยายในหัวข้อ **2.1 ภาคทฤษฎี: Synchronous Design** ของคู่มือหลักสูตร (วันที่ 2)
> เหมาะสำหรับการบรรยาย 90–120 นาที พร้อมตัวอย่างจริงจาก ASIC design

---

## 1. แนวคิด Synchronous Design

### 1.1 Synchronous คืออะไร

ใน **synchronous design** ทุก flip-flop ใช้ **clock ตัวเดียวกัน** (single clock domain) และทุก state transition เกิดที่ **edge ของ clock** เท่านั้น สัญญาณอื่น (data input, output enable) สามารถเปลี่ยนค่าเมื่อใดก็ได้ แต่จะถูก sample ที่ clock edge ถัดไป

```
                  ┌────────────────────────────────┐
                  │          SINGLE CLOCK          │
                  │  ───┐      ┌──────┐            │
                  │     │      │      │            │
   clk:    ───────┘     └──────┘      └────────────┘

   data:   ──────███████░░░░░░░░░████████████░░░░░░░
                      ↑   ↑   ↑   ↑
                      └───── ถูก latch ที่ rising edge
                              (การเปลี่ยนระหว่าง edges
                              ไม่กระทบการทำงาน)
```

**ข้อดี:**
- ✅ Timing analysis deterministic (Static Timing Analysis)
- ✅ ไม่มี race condition ระหว่าง FF
- ✅ Tool สามารถ optimize ได้เต็มที่
- ✅ เขียน verify ง่าย

**ข้อเสีย:**
- ⚠️ Latency = N clock cycles (N = จำนวน FF ใน data path)
- ⚠️ ไม่เหมาะกับ async I/O ที่ต้องตอบสนองทันที
- ⚠️ Clock tree ต้อง balance ดี เพื่อ minimize skew

### 1.2 Asynchronous Design (สิ่งที่ควรหลีกเลี่ยง)

```
   clk1:    ───┐ ┌──────
               │ │      │
   clk1:    ─────┘      └──────┘

   data:    ────────┐
            │       │
   data:    ────────┘

                  ↑      ↑
                  Latch ที่ edge ของ clk1 → ไม่รู้ data เปลี่ยนเมื่อไหร่
                  (race condition)
```

ใน asynchronous design, logic เปลี่ยน state ทันทีเมื่อ input เปลี่ยน — ไม่มี clock กำกับ:
- ❌ Timing analysis เป็นไปไม่ได้ใน ASIC
- ❌ Race condition
- ❌ Hazard, glitches
- ❌ Verification ยาก

**ใน ASIC:** ใช้ **synchronous design เท่านั้น** ยกเว้น:
- Async reset (de-assert synchronously)
- Clock domain crossing (ต้องมี synchronizer)
- Edge detection of async signal

---

## 2. Clock Fundamentals

### 2.1 Clock Parameters

```
                  ┌─────┐         ┌─────┐
                  │     │         │     │
   clk:    ───────┘     └─────────┘     └───
                  │←T→│  │←──T_high──→│
                     T_low
   ────────────────────────────────────────────► time

              T = T_high + T_low  (clock period)
              f = 1/Tclk  (clock frequency)
              duty_cycle = T_high / T × 100%
```

| Parameter | ความหมาย | ตัวอย่าง |
| --- | --- | --- |
| **Period (T)** | เวลาระหว่าง 2 rising edges | 10 ns |
| **Frequency (f)** | 1/T | 100 MHz |
| **Duty cycle** | T_high/T | 50% |
| **Rise time** | เวลาจาก 10% ถึง 90% ของ Vhigh | 100 ps |
| **Fall time** | เวลาจาก 90% ถึง 10% ของ Vlow | 100 ps |
| **Jitter** | variation ของ period | ±50 ps |
| **Skew** | delay ระหว่าง clock ที่จุดต่าง ๆ | 50 ps |

### 2.2 Clock Skew

**Clock Skew** คือ delay ระหว่าง clock ที่ FF ตัวหนึ่ง กับ FF อีกตัวหนึ่ง

```
   Launch edge @ FF_A:           t = 0
   Capture edge @ FF_B:          t = T - skew

   skew = clk_delay at FF_A − clk_delay at FF_B
   (positive skew = launch early, capture late → BAD for setup, GOOD for hold)
   (negative skew = launch late, capture early → BAD for hold, GOOD for setup)
```

**ผลกระทบ:**

```
                    FF_A → combinational → FF_B
   clk at FF_A: ─────┐                         ┌─────
                     │             delay       │
   clk at FF_B: ──────────┐                    ┌─────
                          └───── (skew = δ)────┘

   Setup slack = T - t_setup - (comb_delay) + skew
   Hold slack  = t_hold - (comb_delay) - skew

   ✓ Positive skew → เพิ่ม setup slack แต่ลด hold slack
   ⚠️ Negative skew → ลด setup slack แต่เพิ่ม hold slack
```

### 2.3 Clock Jitter

Jitter คือ **cycle-to-cycle variation** ของ clock period:

```
   ideal:   ─┐    ┌──┐    ┌──┐    ┌──
             └─┼────┼──┼────┼──┼────┼─
               │    │  │    │
    actual:  ─┐  ┌┼┐ ┌┼┐ ┌┼┼┐ ┌┼┐
              └──┘ └─┘ └─┘  └─┘ └─┘└─┘└──
                ↑  ↑  ↑   ↑
                T±jitter
```

Jitter มาจาก PLL/oscillator กิน clock period ที่มีประโยชน์

**Setup slack ต้องพิจารณา jitter:**

```
   Setup slack = T - t_setup - comb_delay - jitter
```

### 2.4 Clock Distribution (Clock Tree)

Clock มาจาก PLL → เข้า chip → กระจายไปยัง FF ทุกตัว ผ่าน **clock tree**:

```
                        Root (PLL output)
                          │
                ┌─────────┼─────────┐
                │         │         │
                B         B         B           (Level 1: 3 buffers)
              ╱ │ ╲     ╱ │ ╲     ╱ │ ╲
             B  B  B   B  B  B   B  B  B       (Level 2)
            ╱│  ╲│     │   │ │   │
           B B  B B     ...   ...   ...        (Level 3)
           ││  ││
           FF FF FF                              (Leaves: FFs)
```

**H-tree: balance delay เท่า ๆ กัน**

---

## 3. Clock Domain Crossing (CDC) — เบื้องต้น

### 3.1 Single Clock Domain

```
   FF1 ──► combinational ──► FF2 ──► combinational ──► FF3
   ─────────────────────────────────────────────────
   │               Same clock                  │
   ─────────────────────────────────────────────────
```

ใน single clock domain: tool จัดการ timing ทั้งหมด

### 3.2 Multi-Clock Domain

```
   CLK_x2 (200 MHz)         CLK_x1 (100 MHz)
        │                        │
        ▼                        ▼
       FF_A ───── data ─────► FF_B
```

ปัญหา: data ที่ latch ที่ CLK_x2 edge อาจถูก sample ที่ CLK_x1 edge ที่ไม่แน่นอน → **metastability**

### 3.3 Metastability

เมื่อ data เปลี่ยนใกล้กับ clock edge มาก ๆ, FF อาจเข้าสู่ **metastable state** (output ค้างระหว่าง 0 และ 1 สักพัก)

```
                              ┌─────────────┐
   data:    ──────┐           │ status      │
                  └───────────┼─────────────┼──────────
                              ↑      ↑      ↑
                          setup   actual   hold
                          time    edge     time
                          
   clk:    ─────┐         ┌─────┐
                └─────────┘
                          ↑ violation!
                          metastable!
```

**Mean Time Between Failures (MTBF):**

```
   MTBF = exp(t_r/τ) / (f_clk1 × f_data × T_window)

   τ = metastability time constant (~10-100 ps)
   t_r = resolution time (วงรอบที่ sync FF ใช้)
   f_clk1, f_data = frequencies
   T_window = data transition window

   MTBF ที่ดี: > 1000 ปี (ปลอดภัย)
```

**วิธีแก้: 2-Stage Synchronizer**

```
   data (async) ──┐
                  ▼
                 FF1 (sync)──┐
                              ▼
                             FF2 (sync)── data_out (synced)

   mtbf = exp(2*T_r/τ) / (f_clk × f_data × T_window)
         ↑ 2 stages = exp(2x) → much higher
```

**Code Template:**

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cdc_synchronizer is
    generic (
        WIDTH : integer := 1
    );
    port (
        clk_dst : in  std_logic;
        rst_n   : in  std_logic;
        async_in : in  std_logic_vector(WIDTH-1 downto 0);
        sync_out : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity;

architecture rtl of cdc_synchronizer is
    signal sync1, sync2 : std_logic_vector(WIDTH-1 downto 0);
begin
    sync : process (clk_dst)
    begin
        if rising_edge(clk_dst) then
            if rst_n = '0' then
                sync1 <= (others => '0');
                sync2 <= (others => '0');
            else
                sync1 <= async_in;
                sync2 <= sync1;
            end if;
        end if;
    end process;

    sync_out <= sync2;
end architecture;
```

---

## 4. Reset Strategy — เชิงลึก

### 4.1 Reset คืออะไร

Reset ใช้เพื่อ **initialize** state ของ sequential elements (FF) ในระบบ ให้อยู่ในสถานะที่กำหนดไว้ล่วงหน้า

**Reset sources:**
- **Power-on Reset (POR)** — ตอน chip power-up
- **External Reset** — pin input (เช่น nRESET จาก MCU)
- **Software Reset** — register write จาก CPU
- **Watchdog Reset** — ตอน hang

### 4.2 Synchronous Reset

```vhdl
process (clk)
begin
    if rising_edge(clk) then
        if rst_n = '0' then      -- active-low
            counter <= (others => '0');
        else
            counter <= counter + 1;
        end if;
    end if;
end process;
```

**ข้อดี:**
- ✅ ใช้ FF ที่ไม่มี reset pin → **ประหยัดพื้นที่**
- ✅ Timing analysis ง่าย (reset เป็น data input ปกติ)
- ✅ ไม่มี recovery/removal timing issue
- ✅ Synchronous กับ clock → deterministic behavior

**ข้อเสีย:**
- ⚠️ ต้องมี clock ทำงานเพื่อ reset
- ⚠️ Glitch บน rst_n อาจไม่ถูก sample (ต้อง pulse ≥ 1 clock period)
- ⚠️ ต้องใส่ block สำหรับ power-on แยก

**Timing Diagram:**

```
   clk:      ───┐    ┌──┐    ┌──┐    ┌──┐
                └────┘  └────┘  └────┘

   rst_n:  ─────┐              ┌────────────
                └──────────────┘

   q:       ──────────────────[reset applied]
                               ↑     [q goes to 0]
                               q = X
                               q = 0 (next rising edge after rst_n goes low)
```

### 4.3 Asynchronous Reset

```vhdl
process (clk, rst_n)
begin
    if rst_n = '0' then                    -- active-low, async
        counter <= (others => '0');
    elsif rising_edge(clk) then
        counter <= counter + 1;
    end if;
end process;
```

**ข้อดี:**
- ✅ ทำงานทันทีเมื่อ rst_n เป็น '0' (ไม่ต้องมี clock)
- ✅ เหมาะกับ power-on reset
- ✅ มักจะ needed สำหรับ chip initialization

**ข้อเสีย:**
- ⚠️ ต้อง de-assert **synchronously** เพื่อป้องกัน recovery/removal violation
- ⚠️ FF ต้องมี asynchronous reset pin → **ใช้พื้นที่มากกว่า**
- ⚠️ STA ต้องวิเคราะห์ recovery/removal timing

**Timing Diagram:**

```
   clk:      ───┐    ┌──┐    ┌──┐    ┌──┐
                └────┘  └────┘  └────┘

   rst_n:  ─────┐                   ┌───────
                └───────────────────┘
                 async            sync de-assertion
                 ↓                 ↓
   q:         q=0   q=0   q=0    (asynchronous reset) → ปล่อยให้นับ
```

### 4.4 Asynchronous Reset with Synchronous De-assertion (แนะนำสำหรับ ASIC)

```vhdl
process (clk, rst_n)
begin
    if rst_n = '0' then                    -- async assert
        counter <= (others => '0');
    elsif rising_edge(clk) then            -- sync de-assert
        counter <= counter + 1;
    end if;
end process;
```

**ข้อดี:**
- ✅ Reset เร็วเมื่อ assert (ไม่ต้องรอ clock)
- ✅ De-assertion synchronous → ไม่มี recovery/removal issue
- ✅ Industry-standard approach

**ข้อเสีย:**
- ⚠️ ใช้ FF with async-reset pin

### 4.5 Reset Distribution Network (Reset Tree)

ใน chip ใหญ่ ๆ, reset signal ต้องถูกกระจายไปยัง FF หลายพันตัว ต้องใช้ **reset tree** เพื่อลด fan-out:

```
                  rst_n (input pin)
                       │
                ┌──────┴──────┐
                │  Reset      │
                │  Buffer     │
                └──────┬──────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        │              │              │
   ┌────┴────┐    ┌────┴────┐    ┌────┴────┐
   │ Region 1│    │ Region 2│    │ Region 3│
   │ Reset   │    │ Reset   │    │ Reset   │
   │ Buffer  │    │ Buffer  │    │ Buffer  │
   └────┬────┘    └────┬────┘    └────┬────┘
        │              │              │
   FF FF FF FF    FF FF FF FF    FF FF FF FF
   (region 1)     (region 2)     (region 3)
```

**Issues:**
- ⚠️ Skew ระหว่าง reset ที่ region ต่าง ๆ
- ⚠️ Fan-out สูงจาก root → ต้อง buffer
- ⚠️ ใน synchronous reset ทุกครั้ง clock + reset = data path → critical path

---

## 5. Reset Recovery และ Removal Timing

### 5.1 ปัญหา: Asynchronous De-assertion

ถ้า reset de-asserted ใกล้ clock edge มาก ๆ → FF อาจ metastable

```
   clk:      ───┐    ┌──┐    ┌──┐
                └────┘  └────┘

   rst_n:  ─────┐           ┌──────
                └───────────┘
                            ↑ de-asserted ใกล้ edge!
                            
   Recovery time: เวลาที่ rst_n ต้อง de-assert ก่อน edge
   Removal time:  เวลาที่ rst_n ต้องคงอยู่หลัง edge
```

**Recovery**: rst_n (de-asserted) ต้องมาก่อน clock edge ≥ recovery_time
**Removal**: rst_n (still asserted) ต้องคงอยู่หลัง clock edge ≥ recovery_time

### 5.2 การแก้: Reset Synchronizer

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reset_sync is
    port (
        clk       : in  std_logic;
        async_rstn: in  std_logic;  -- จาก external pin
        sync_rstn : out std_logic   -- ไปใช้ใน synchronous reset logic
    );
end entity;

architecture rtl of reset_sync is
    signal sync1, sync2 : std_logic;
begin
    -- 2-stage synchronizer
    process (clk)
    begin
        if rising_edge(clk) then
            sync1 <= async_rstn;
            sync2 <= sync1;
        end if;
    end process;

    sync_rstn <= sync2;
end architecture;
```

**Timing Diagram:**

```
   async_rstn:  ─┐                    ┌──
                 └────────────────────┘
                 async                 async(1)
                 assert                de-assert
                  ↓                      ↓
   sync1:                             ─┐
   sync2:                              └─┐ (1 cycle delay)
   sync_rstn:                            └── (2 cycle delay, synchronous!)
```

**หลักการ:**
- async_rstn assert (เป็น '0') → sync_rstn จะเป็น '0' ภายใน 2 clock cycles
- async_rstn de-assert → sync_rstn จะเป็น '1' ภายใน 2-3 cycles (แต่ synchronous)

---

## 6. Clock Enable (CE)

### 6.1 CE คืออะไร

Clock Enable ใช้เพื่อ **ควบคุมการ update** ของ FF โดยไม่ต้องปิด clock

```vhdl
process (clk)
begin
    if rising_edge(clk) then
        if rst_n = '0' then
            cnt <= (others => '0');
        elsif ce = '1' then              -- เฉพาะเมื่อ CE = 1
            cnt <= cnt + 1;
        end if;                           -- ถ้า CE = 0: ค่าค้าง
    end if;
end process;
```

### 6.2 ประโยชน์ของ CE

- **Power saving**: tool สามารถ infer **clock gating** อัตโนมัติ
- **Rate adaptation**: FF ทำงานที่ความถี่ต่ำกว่า clock
- **Avoid multiple clock**: ใช้ CE แทนการสร้าง clock domain ใหม่
- **Skew tool-free**: CE เป็น data signal → ไม่มี clock skew

### 6.3 Coding Style ที่ดี (สำหรับ Inferring Clock Gating)

```vhdl
-- ✅ GOOD: tool สามารถ infer integrated clock gating (ICG) cell
process (clk)
begin
    if rising_edge(clk) then
        if rst_n = '0' then
            reg <= '0';
        elsif ce = '1' then            -- CE ทำหน้าที่ enable
            reg <= next_value;
        end if;
    end if;
end process;
```

```
   clk:    ─┐   ┌──┐    ┌──┐    ┌──┐
            └───┘  └────┘  └────┘
  
  ce:     ───┐          ┌───
             └──────────┘
  
  gclk:    ─┐  ┌─┐       ┌─┐           ← Tool insert: gclk = clk AND ce
            └──┘ └───────┘ └─────
  
  reg:                          ← Update only when gclk has edge
```

### 6.4 Style ที่ไม่แนะนำ

```vhdl
-- ⚠️ BAD: gated CE (hard for clock)
process (clk)
begin
    if rising_edge(clk) then
        if rst_n = '0' then
            reg <= '0';
        else
            if ce = '1' then         -- CE ซ้อนใน else
                reg <= next_value;
            end if;
        end if;
    end if;
end process;
```

หรือ

```vhdl
-- ⚠️ BAD: ใช้ CE แต่ไม่ใส่ default assignment
process (clk)
begin
    if rising_edge(clk) then
        if ce = '1' then
            reg <= data_in;        -- เมื่อ ce=0 → reg ค้าง (ไม่ใช่ inferred latch เพราะ FF)
        end if;
    end if;
end process;
```

### 6.5 CE Patterns

**1. Counter with CE**

```vhdl
process (clk)
begin
    if rising_edge(clk) then
        if rst_n = '0' then
            cnt <= (others => '0');
        elsif ce = '1' then
            cnt <= cnt + 1;
        end if;
    end if;
end process;
```

**2. FSM with CE**

```vhdl
process (clk)
begin
    if rising_edge(clk) then
        if rst_n = '0' then
            state <= IDLE;
        elsif ce = '1' then
            state <= next_state;
        end if;
    end if;
end process;
```

**3. Pipeline with CE**

```vhdl
process (clk)
begin
    if rising_edge(clk) then
        if rst_n = '0' then
            pipe_reg <= (others => '0');
        elsif ce = '1' then
            pipe_reg <= data_in;
        end if;
    end if;
end process;
```

---

## 7. Power-on Reset (POR)

### 7.1 ปัญหา

หลัง power-up:
- FF อาจมีค่า random (ไม่ใช่ '0')
- Logic อาจทำงานผิดเพราะ FF state ไม่ถูกต้อง
- Asynchronous reset อาจไม่ activate ถ้า VDD ยังไม่ stable

### 7.2 POR Circuit

```
                  VDD
                   │
                  ┌────┐
                  │ R  │
                  └────┤
                       │
                       ▼
                  ┌─────┐
                  │ C   │
                  └─────┤
                       │
                       ▼
                     rst_n_initial
                       │
                  ┌─────────┐
                  │ Schmitt │  -- ป้องกัน oscillation
                  │ Trigger │
                  └─────────┘
                       │
                       ▼
                     rst_n (output)
```

**Schmitt trigger** ให้ hysteresis — ป้องกัน noise ระหว่าง power ramp

### 7.3 POR Sequence

```
   VDD:    ──────────┐
                     │
                     │ power ramp
                     │ (10 µs - 100 ms)
                     │
                     ▼
                     ┌───────────
                     │ VDD stable
                     ▼
   rst_n:  ─────────┐
                    └────────────────
                     POR releases
                     after VDD stable
                     for some time
```

### 7.4 Best Practice

- **ใช้ external reset IC** (เช่น TI TPS3890) — ส่ง reset ที่ถูกต้อง
- **Internal POR + External Reset** — redundancy
- **Power-on reset propagation** — distribute reset to all FF

---

## 8. Reset Coding Templates

### 8.1 Synchronous Reset (Active-Low)

```vhdl
process (clk)
begin
    if rising_edge(clk) then
        if rst_n = '0' then
            q <= (others => '0');
        else
            q <= d;
        end if;
    end if;
end process;
```

### 8.2 Asynchronous Reset (Active-Low)

```vhdl
process (clk, rst_n)
begin
    if rst_n = '0' then
        q <= (others => '0');
    elsif rising_edge(clk) then
        q <= d;
    end if;
end process;
```

### 8.3 Asynchronous Reset + Synchronous De-assertion

```vhdl
process (clk, rst_n)
begin
    if rst_n = '0' then
        q <= (others => '0');
    elsif rising_edge(clk) then
        q <= d;
    end if;
end process;
```

### 8.4 Synchronous Reset + Clock Enable

```vhdl
process (clk)
begin
    if rising_edge(clk) then
        if rst_n = '0' then
            q <= (others => '0');
        elsif ce = '1' then
            q <= d;
        end if;
    end if;
end process;
```

### 8.5 Synchronous Reset + Async Set (rare)

```vhdl
process (clk, rst_n, set_n)
begin
    if rst_n = '0' then
        q <= (others => '0');
    elsif set_n = '0' then
        q <= (others => '1');
    elsif rising_edge(clk) then
        q <= d;
    end if;
end process;
```

### 8.6 No Reset (FPGA-only)

```vhdl
process (clk)
begin
    if rising_edge(clk) then
        q <= d;
    end if;
end process;

-- Initialization ใน FPGA bitstream:
-- attribute INIT_8 of my_reg : signal is "00000000";
```

### 8.7 Parameterized Reset (VHDL-2008)

```vhdl
entity reset_template is
    generic (
        WIDTH  : integer := 8;
        RST_POL: std_logic := '0'  -- 0 = active-low, 1 = active-high
    );
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        ce  : in  std_logic;
        d   : in  std_logic_vector(WIDTH-1 downto 0);
        q   : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity;

architecture rtl of reset_template is
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = RST_POL then
                q <= (others => not RST_POL);
            elsif ce = '1' then
                q <= d;
            end if;
        end if;
    end process;
end architecture;
```

---

## 9. Coding Guidelines Summary

### 9.1 Synchronous Design Rules

| Rule | Description |
| --- | --- |
| ✅ | ทุก FF ใช้ clock จาก source เดียวกัน (หรือ CE pattern) |
| ✅ | ใช้ `rising_edge(clk)` เท่านั้น (ไม่ใช้ `clk'event and clk='1'`) |
| ✅ | Sensitivity list มีแค่ clk (หรือ clk, rst_n สำหรับ async) |
| ✅ | Sensitivity list ของ combinational process มีสัญญาณครบทุกตัว |
| ❌ | ห้ามใช้ `wait for` ใน design |
| ❌ | ห้ามมี latch ที่ไม่ตั้งใจ |
| ❌ | ห้ามสร้าง clock จาก logic (gated clock) |

### 9.2 Reset Rules

| Rule | Description |
| --- | --- |
| ✅ | ใช้ synchronous reset เป็น default |
| ✅ | ถ้าใช้ async reset, de-assert ต้อง synchronous |
| ✅ | ทุก FF ต้อง initialize ได้ (มี reset path) |
| ❌ | ห้ามมี FF ที่ไม่มี reset |
| ⚠️ | Asynchronous reset ต้อง de-assert ใกล้ POR |

### 9.3 CDC Rules

| Rule | Description |
| --- | --- |
| ✅ | Single-bit CDC ใช้ 2-FF synchronizer |
| ✅ | Multi-bit CDC ใช้ handshake หรือ Gray code |
| ✅ | Clock 2 ตัว ต้องมี known phase relationship (มาจาก PLL เดียวกัน) หรือ unrelated (ใช้ async synchronizer) |
| ❌ | ห้ามส่ง multi-bit data ข้าม domain โดยไม่มี handshake |

---

## 10. Common Pitfalls

### 10.1 Pitfall 1: Glitch on Reset

```vhdl
-- BAD: rst_n glitch ระหว่าง power-up
process (clk, rst_n)
begin
    if rst_n = '0' then        -- glitch อาจเข้า process หลายครั้ง
        ...
    elsif rising_edge(clk) then
        ...
    end if;
end process;
```

**Fix:**

```vhdl
-- GOOD: ใช้ reset synchronizer
process (clk)
begin
    if rising_edge(clk) then
        if sync_rst_n = '0' then     -- synchronous, glitch-free
            ...
        else
            ...
        end if;
    end if;
end process;
```

### 10.2 Pitfall 2: Mixed Reset Domains

```vhdl
-- BAD: rst_a ใช้กับ FF_A, rst_b ใช้กับ FF_B → fan-out
process (clk, rst_a)
begin
    if rst_a = '0' then
        FF_A <= '0';
    elsif rising_edge(clk) then
        FF_A <= d;
    end if;
end process;

process (clk, rst_b)
begin
    if rst_b = '0' then
        FF_B <= '0';
    elsif rising_edge(clk) then
        FF_B <= FF_A;        -- FF_B depends on FF_A but uses different reset
    end if;
end process;
```

**Fix:** ใช้ reset ตัวเดียวกันสำหรับ FF ที่เชื่อมต่อกัน

### 10.3 Pitfall 3: Reset ไม่ Cover Power-On

```vhdl
-- BAD: ไม่มี POR
process (clk)
begin
    if rising_edge(clk) then
        if rst_n = '0' then
            q <= '0';
        else
            q <= d;
        end if;
    end if;
end process;

-- ถ้า rst_n ไม่ activate ตอน power-on → q อาจเป็น X
```

**Fix:**

```vhdl
-- GOOD: ใช้ internal POR + external reset OR
process (clk, por_n)
begin
    if por_n = '0' then
        q <= '0';
    elsif rising_edge(clk) then
        if ext_rst_n = '0' then
            q <= '0';
        else
            q <= d;
        end if;
    end if;
end process;
```

### 10.4 Pitfall 4: Clock Domain Crossing ที่ไม่มี Synchronizer

```vhdl
-- BAD: signal จาก slow clock → fast clock โดยไม่ sync
process (clk_fast)
begin
    if rising_edge(clk_fast) then
        if flag_slow = '1' then    -- flag_slow เปลี่ยนที่ clk_slow!
            ...
        end if;
    end if;
end process;
```

**Fix: ใช้ 2-FF synchronizer บน flag_slow**

### 10.5 Pitfall 5: การใช้ Async Reset ใน Clock Domain Crossing

```vhdl
-- BAD: synchronizer FF มี async reset → reset glitch อาจเข้า
process (clk_dst, rst_n)
begin
    if rst_n = '0' then
        sync1 <= '0';
        sync2 <= '0';
    elsif rising_edge(clk_dst) then
        sync1 <= async_in;
        sync2 <= sync1;
    end if;
end process;
```

**Fix:** ใช้ synchronous reset บน synchronizer FF

---

## 11. Best Practices สรุป

### 11.1 Reset

| Do | Don't |
| --- | --- |
| Synchronous reset เป็น default | ใช้ async reset โดยไม่จำเป็น |
| ใส่ reset ใน FF ทุกตัว | ปล่อย FF ไม่ initialize |
| ใช้ reset synchronizer สำหรับ external reset | ใช้ rst_n ตรง ๆ จาก pin |
| Active-low reset (rst_n) convention | ผสม active-high กับ active-low |
| ใส่ POR สำหรับ power-on | คิดว่า chip จะ start สะอาด |
| กระจาย reset ด้วย reset tree | ใช้ reset เดียวสำหรับ FF หลายพันตัว (fan-out สูง) |

### 11.2 Clock Enable

| Do | Don't |
| --- | --- |
| ใช้ CE สำหรับ slow logic | สร้าง gated clock จาก logic |
| CE pattern ที่ tool infer ICG ได้ | CE แบบ nested if |
| ใส่ CE register synchronization | ใช้ CE ข้าม clock domain |

### 11.3 CDC

| Do | Don't |
| --- | --- |
| 2-FF synchronizer สำหรับ single-bit CDC | ส่ง signal ข้าม domain ตรง ๆ |
| Gray code สำหรับ multi-bit CDC | ส่ง multi-bit data ข้าม domain โดยไม่ sync |
| Handshake/FIFO สำหรับ burst data | ใช้ FIFO ที่ไม่มี full/empty flag sync |

---

## 12. ตัวอย่างเรียบรับ: Synchronous Reset Counter with CE

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter_sync is
    generic (
        WIDTH : integer := 8
    );
    port (
        clk   : in  std_logic;
        rst_n : in  std_logic;                          -- active-low sync reset
        ce    : in  std_logic;
        load  : in  std_logic;
        din   : in  unsigned(WIDTH-1 downto 0);
        cnt   : out unsigned(WIDTH-1 downto 0)
    );
end entity;

architecture rtl of counter_sync is
    signal cnt_i : unsigned(WIDTH-1 downto 0);
begin
    -- ========================================================
    -- Synchronous, CE-controlled counter with load and reset
    -- ========================================================
    process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                cnt_i <= (others => '0');
            elsif load = '1' then
                cnt_i <= din;                  -- parallel load
            elsif ce = '1' then                -- count when enabled
                cnt_i <= cnt_i + 1;
            end if;
        end if;
    end process;

    cnt <= cnt_i;
end architecture;
```

**Timing Diagram:**

```
   clk:      ─┐    ┌──┐    ┌──┐    ┌──┐    ┌──┐    ┌──┐
              └────┘  └────┘  └────┘  └────┘  └────┘

   rst_n: ────┐
              └─────────────────────────────────────  (de-asserted sync)

   load:  ────────┐             ┌──────────────────
                  └─────────────┘

   ce:        ─────┐     ┌─────┐     ┌──────
                   └─────┘     └─────┘

   cnt:    [0]   0  1  2  3  ←load(0xA5)=>  0xA5+1=0xA6 ...
                                         ↑
                                         loaded value
```

---

## 13. Tools ที่ใช้ตรวจสอบ

### 13.1 Static Checks

- **Lint**: detect multiple clock domains, missing reset
- **CDC tool**: Questa CDC, SpyGlass, Real Intent
- **SDC constraint**: `set_false_path`, `set_max_delay` สำหรับ CDC paths

### 13.2 Dynamic Checks

- **Formal Verification**: เช็ค reset behavior
- **Assertion-based**: เช็ค reset assertion, de-assertion sequence

### 13.3 Questa commands

```tcl
# ตรวจ CDC
check_cdc

# Reset assertions
set_reset_assertions_seq -rst rst_n -clock clk -sync_deassert

# Power-aware STA
report_timing -check_type setup
report_timing -check_type recovery
report_timing -check_type removal
```

---

## 14. สรุป Key Takeaways

1. **Synchronous design** = ใช้ clock ตัวเดียว, deterministic timing
2. **Reset** แบ่งเป็น:
   - **Synchronous** (default) - ง่าย, ประหยัด, ไม่มี recovery/removal
   - **Asynchronous** - เร็ว, ต้อง de-assert sync
   - **Hybrid** (async assert + sync de-assert) - มาตรฐาน ASIC
3. **Clock Enable (CE)**: แทนการสร้าง clock ใหม่, tool infer clock gating
4. **CDC**: 2-FF synchronizer สำหรับ single-bit, handshake/Gray code สำหรับ multi-bit
5. **Power-on Reset**: ต้องมี POR circuit + external reset IC
6. **Reset Distribution**: ใช้ reset tree เพื่อลด fan-out
7. **Common Pitfalls**: glitch on reset, mixed reset domains, missing synchronizer

---

## 15. อ้างอิง

- Cummings, C. E. "Synthesis and Scripting Techniques for Designing Multi-Asynchronous Clock Designs," SNUG 2001.
- Cummings, C. E. "Clock Domain Crossing (CDC) Design & Verification Techniques," SNUG 2008.
- Wirth, N. "Digital Circuit Design: Synchronous vs Asynchronous," 2020.
- "Siemens EDA Precision RTL Synthesis User Manual" — Reset Inference.
- "Questa Advanced Simulator User Manual" — Reset & CDC checks.

---

> **หมายเหตุ:** เนื้อหานี้ออกแบบให้บรรยายได้ประมาณ 90-120 นาที รวม ASCII diagrams, timing diagrams, code templates, MTBF calculation พร้อมใช้ประกอบการสอนภาคทฤษฎี Day 2 เช้า หรือแบ่งเป็น 2 mini-lectures (Synchronous Design 1 ชม. + Reset Strategy 1 ชม.)
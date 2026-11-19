# 2.7 — VHDL Testbench เชิงลึก

> **หัวข้อประกอบการสอน** · วันที่ 2: Advanced RTL Design Using VHDL
> **เวลาบรรยาย** 90–120 นาที · **ระดับ** ปานกลาง → ขั้นสูง
> **ต้องมีเครื่องมือ** ModelSim/Questa 2026.1 (Windows) หรือ GHDL 5.x (Linux/WSL)
> **โค้ดประกอบ** `lab_code/day2_testbench/` — ทุกตัวอย่างในเอกสารนี้รันได้จริงและผลลัพธ์ทุกบรรทัดมาจากการรันจริง

---

## 2.7.0 ทำไมต้องมีหัวข้อนี้

คู่มือฉบับนี้มีเอกสารที่พูดถึง Testbench อยู่แล้ว 3 ฉบับ แต่แต่ละฉบับตอบคำถามคนละข้อ:

| เอกสาร | ตอบคำถามว่า | ระดับ |
| --- | --- | --- |
| `Manual_2_4_2_5_RTL_Guidelines_and_Testbench_DeepDive.md` (ส่วน C) | Testbench ควรมีชั้นอะไรบ้าง, stimulus แบบไหนดี | เมธอโดโลยี |
| `Manual_4_1_Verification_Methodology_DeepDive.md` | ทำ verification อย่างเป็นระบบอย่างไร | กระบวนการ |
| `Manual_4_2_Assertions_and_FunctionalCoverage_DeepDive.md` | เขียน assertion และ coverage อย่างไร | เครื่องมือ |

**ช่องว่างที่ยังไม่มีใครตอบ** คือ "VHDL ทำงานอย่างไรในระดับภาษา" — กลไกที่ทำให้ testbench
ที่ดูถูกต้องในหน้าจอ แต่พังตอนรันจริง

หัวข้อนี้จึงเน้น **กลไกของภาษา** มากกว่าเมธอโดโลยี โดยใช้ตัวอย่างที่รันจริงทั้งหมด
ใน `lab_code/day2_testbench/` เป็นหลักฐาน ไม่ใช่ตัวอย่างสมมติ

### 2.7.0.1 สิ่งที่หัวข้อนี้จะพิสูจน์

ระหว่างเขียนตัวอย่างเพื่อประกอบหัวข้อนี้ ได้พบบั๊กจริง **12 จุด** ทั้งหมดผ่านการรันจริง
บน **GHDL 5.0.1** และ **ModelSim/Questa 2026.1** ตัวอย่างเช่น

1. `clk` ที่ไม่มี initial value → `not clk` = `'U'` → **นาฬิกาไม่เคยตี** (0 rising edge)
2. การอ่าน signal ที่ process เดียวกันเพิ่ง assign → ได้ **ค่าเก่า**
3. ตัวนับ pass/fail ที่เป็น signal → รายงาน `FAIL=0` ทั้งที่มี FAIL จริง → **false PASS**
4. `wait until` ที่เงื่อนไขเป็นจริงอยู่แล้ว → **ไม่ทำงานทันที** ต้องมี event ก่อน
5. `baud_tick` ที่ทำเป็น square wave → DUT ก้าวหลาย bit ใน 1 จังหวะ
6. UART ส่ง LSB-first แต่ monitor decode แบบ MSB-first → ข้อมูลเพี้ยนทั้งเฟรม
7. `hread` ล้มเหลว (assertion failure) เมื่อบรรทัดนั้นเป็น comment
8. `IEEE.TEXTIO` มี `HREAD` เฉพาะ `BIT_VECTOR` — ไม่มี overload สำหรับ `INTEGER`
9. `numeric_std` ไม่รองรับ `+` บน `std_logic_vector` (ต้องเป็น `unsigned`)
10. ไม่มี `std.env.stop` → นาฬิกาวิ่งไม่จบ simulation ค้างจน timeout
11. external name อ้างถึง signal ที่ประกาศภายใน process ไม่ได้
12. `report` string ใส่ภาษาไทยไม่ได้ (VHDL string literal เป็น Latin-1)

บั๊กข้อ 1–4 สำคัญที่สุด เพราะมันเกิดได้กับ testbench ที่ "ดูถูกต้องมาก"

### 2.7.0.2 ⚠️ ตัวอย่างใน §2.5 ของคู่มือหลักมีบั๊กจริง

ตัวอย่าง `tb_seq_moore` ในหัวข้อ 2.5.2 ของ `Manual_Part1_Day1-5.md` ถูกคัดลอกมารันตามต้นฉบับ
ผลที่ได้ (GHDL 5.0.1, `--std=08`):

```
tb_sec25_verbatim.vhd:28:17:@50ns:(report error): FAIL 101: got '0' expected '1'
tb_sec25_verbatim.vhd:46:9:@50ns:(report note): PASS=2 FAIL=0
```

สังเกตว่า **มี FAIL จริง แต่สรุปว่า `FAIL=0`** เพราะสาเหตุต่อไปนี้

| # | บั๊ก | ทำให้เกิดอะไร |
| --- | --- | --- |
| 1 | `signal clk : std_logic;` ไม่มี `:= '0'` | เริ่มเป็น `'U'` → `not clk` = `'U'` → **นาฬิกาไม่เคยตี** → ไม่มี rising edge → FSM ค้างที่ reset → `detected` = `'0'` ตลอด |
| 2 | procedure ประกาศ parameter ชื่อ `input` แต่ **ไม่ได้ใช้** ใน body (body เปรียบเทียบ `detected` กับ `expect`) | checker ไม่ได้ตรวจค่าที่ส่งเข้ามา → ตรวจผิดตัวแปร |
| 3 | `pass_cnt` / `fail_cnt` ประกาศเป็น **signal** | `fail_cnt <= fail_cnt + 1` มีผลท้าย delta cycle → รายงานสุดท้ายอ่านค่าเก่า → **false PASS** |
| 4 | ไม่มี `std.env.stop` และไม่ align กับ clock edge | simulation ค้าง / ตรวจผิดจังหวะ |

หัวข้อ 2.5.2 ในคู่มือหลักได้รับการแก้ไขแล้วในรอบนี้ โดยย้ายคำอธิบายเชิงลึกทั้งหมด
ไปไว้ที่หัวข้อ 2.7 นี้ (ดูหัวข้อ 2.7.3, 2.7.4, 2.7.6)

---

## 2.7.1 ภาพรวม: Testbench 4 ชั้น

```
      ┌─────────────────────────────────────────────────────────────┐
      │                    TESTBENCH (tb_xxx.vhd)                   │
      │                                                             │
      │  ┌────────────┐   ┌─────────────┐   ┌─────────────┐         │
      │  │  Stimulus  │   │   Monitor   │   │   Reporter  │         │
      │  │  process   │   │  process    │   │  process    │         │
      │  │            │   │             │   │             │         │
      │  │ สร้าง input │   │ เก็บ output  │   │ สรุปผล       │         │
      │  │ ตามเวลา    │   │ ไปเทียบ      │   │ PASS/FAIL   │         │
      │  └─────┬──────┘   └──────┬──────┘   └──────┬──────┘         │
      │        │                 │                 │                │
      │        │  signal (ต้องผ่าน clock)            │                │
      └────────┼─────────────────┼─────────────────┼────────────────┘
               │                 │                 │
        ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
        │    DUT      │   │  Checker /  │   │   Log /     │
        │  (entity)   │   │  Scoreboard │   │   Report    │
        │             │   │ (queue)     │   │  (textio)   │
        └─────────────┘   └─────────────┘   └─────────────┘
```

หลักการที่ใช้ตลอดหัวข้อนี้:

1. **DUT ไม่เคยรู้จัก testbench** — DUT เป็น entity ปกติ ใช้กับทั้ง synthesis และ simulation
2. **Stimulus และ Monitor แยก process กัน** — ไม่ใช้ process เดียวทำทั้งสองอย่าง
   เพราะจะเกิด race ระหว่างการขับสัญญาณกับการอ่านค่า
3. **Checker ใช้ตัวแปร (variable) เก็บผล** ไม่ใช้ signal
4. **Reporter เป็นจุดเดียวที่ตัดสิน pass/fail** และเลือก severity ให้เหมาะกับ CI

---

## 2.7.2 กฎของภาษาที่ต้องรู้ก่อนเขียน Testbench

### 2.7.2.1 VHDL ไม่แยกตัวพิมพ์เล็กใหญ่

`SEED` กับ `seed` คือ **ชื่อเดียวกัน** ตัวแปร `seed` จะชนกับ generic `SEED`
ทำให้ compile ไม่ผ่าน หรือผ่านแต่ใช้ค่าผิด

```vhdl
entity ex06_random_stimulus is
    generic ( SEED_VALUE : integer := 12345 );   -- ชื่อที่ดี
end entity;

architecture sim of ex06_random_stimulus is
begin
    stim : process
        variable rng_seed : integer := SEED_VALUE;  -- ห้ามชื่อ SEED!
```

### 2.7.2.2 ⚠️ `report` string ใส่ภาษาไทยไม่ได้

VHDL string literal ใช้ character set แบบ **Latin-1** ข้อความภาษาไทยจึงถูกปฏิเสธทันที

```
error: invalid character not allowed, even in a string
```

ผลจากการรันจริง (GHDL 5.0.1, `--std=08`) — โค้ดที่คัดลอกจากคู่มือหลัก:

```vhdl
report "[A1] หลัง v := '1' -> v=" & std_logic'image(v);   -- ❌ compile error
report "[A1] after v := '1' -> v=" & std_logic'image(v);   -- ✅
```

> **ข้อสังเกต:** ภาษาไทยใน **คอมเมนต์** (`-- ...`) ใช้ได้ปกติเมื่อใช้ `--std=08`
> (แต่ `--std=93` แบบ strict จะปฏิเสธ) เฉพาะ **string literal** เท่านั้นที่ใช้ภาษาไทยไม่ได้

**แนวทางสำหรับคอร์สนี้:** ใช้ภาษาไทยในคอมเมนต์และในเอกสาร ใช้ภาษาอังกฤษใน
`report` string เท่านั้น — เหตุผลทางวิศวกรรมคือ log ของ regression มักถูก grep
ด้วย regex ภาษาอังกฤษ และต้องไม่พังเมื่อส่งผ่านเครื่องมือ CI

### 2.7.2.3 `numeric_std` ไม่รองรับ `std_logic_vector`

```vhdl
signal cnt_i : std_logic_vector(7 downto 0);
cnt_i <= cnt_i + 1;          -- ❌ error: no function declarations for operator "+"
```

ต้องใช้ `unsigned` (หรือ `signed`):

```vhdl
signal cnt_i : unsigned(7 downto 0) := (others => '0');
cnt_i <= cnt_i + 1;          -- ✅
cnt  <= std_logic_vector(cnt_i);   -- แปลงกลับตอนออกจาก DUT
```

หรือถ้าอยากอยู่กับ `std_logic_vector` ตลอด ให้แปลงเฉพาะตอนคำนวณ:
`cnt_i <= std_logic_vector(unsigned(cnt_i) + 1);`

### 2.7.2.4 ลำดับการวิเคราะห์ไฟล์มีความสำคัญ

GHDL (และเครื่องมืออื่น) ต้องวิเคราะห์ **package ก่อน** ไฟล์ที่ `use` มัน

```bash
# ❌ ผิด — ไฟล์เรียงตามตัวอักษร แล้ว tb_support_pkg.vhd จะมาทีหลัง
ghdl -a --std=08 *.vhd

# ✅ ถูก — เรียงลำดับชัดเจน
ghdl -a --std=08 counter_pkg.vhd tb_support_pkg.vhd uart_sb_pkg.vhd \
                 rtl/*.vhd ex*.vhd
```

ข้อความ error ที่จะเห็น:

```
error: unit "tb_support_pkg" not found in library "work"
```

### 2.7.2.5 `context clause` ใช้กับ design unit ถัดไปเท่านั้น

เมื่อมีหลาย design unit ในไฟล์เดียว ต้องประกาศ `library`/`use` ซ้ำ:

```vhdl
library IEEE;                      -- สำหรับ design unit ที่ 1
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity ex10_counter is ... end entity;

architecture rtl of ex10_counter is ... end architecture;

library IEEE;                      -- ต้องประกาศซ้ำสำหรับ design unit ที่ 2
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity ex10_external_name is ... end entity;
```

---

## 2.7.3 Simulation Cycle และ Delta Cycle — หัวใจของ VHDL

นี่คือส่วนที่ทำให้ VHDL ต่างจากภาษาโปรแกรมทั่วไปมากที่สุด และเป็นต้นเหตุของบั๊กเกือบทั้งหมด

### 2.7.3.1 Simulation มี 2 เฟสต่อหนึ่งจังหวะเวลา

```
        เวลาเดินหน้า (now = 10 ns)
                │
                ▼
    ┌───────────────────────────┐
    │   ① UPDATE PHASE          │   ค่าของ signal ที่ถูก assign ถูกอัปเดต
    │      (ส่ง event)           │   แล้วส่ง event ไปยัง process ที่ sensitive
    └───────────┬───────────────┘
                ▼
    ┌───────────────────────────┐
    │   ② COMPUTE PHASE         │   process ที่ตื่นทำงาน อ่านค่า signal
    │      (ทำงานต่อ)            │   ได้ค่า "ใหม่" แล้ว assign ค่าใหม่ต่อไป
    └───────────┬───────────────┘
                ▼
         มีการ assign ใหม่ไหม?
                │ มี
                └──► วนกลับไปที่ ① (เรียกว่า DELTA CYCLE)
                         เวลา now ไม่เดินเลย
```

**กฎเหล็ก:** ถ้า process อ่าน signal ที่มันเองเพิ่ง assign ในรอบเดียวกัน
มันจะได้ **ค่าเก่า** เสมอ เพราะการ assign ใหม่จะมีผลใน update phase ถัดไป

### 2.7.3.2 ผลจริงจาก `ex01_delta_cycle.vhd`

```vhdl
signal sig_a : std_logic := '0';

demo_ab : process
    variable v : std_logic := '0';
begin
    v := '1';
    report "[A1] ... v=" & std_logic'image(v);
    wait for 0 ns;

    sig_a <= '1';
    report "[A2] ... sig_a=" & std_logic'image(sig_a);
    wait for 0 ns;
    report "[B1] ... sig_a=" & std_logic'image(sig_a);
    wait for 1 ns;
    report "[B2] ... sig_a=" & std_logic'image(sig_a);
    wait;
end process;
```

ผลรันจริง — **GHDL 5.0.1**:

```
[A1] t=0 fs  after v := '1'      -> v='1'  (immediate)
[A2] t=0 fs  after sig_a <= '1'  -> sig_a='0'  (OLD value!)
[B1] t=0 fs  after wait for 0 ns  -> sig_a='1'  (NEW value, same time)
[B2] t=1ns  after wait for 1 ns  -> sig_a='1'
```

ผลรันจริง — **ModelSim/Questa 2026.1** (ผลเหมือนกัน แต่หน่วยเวลาต่างกัน):

```
[A1] t=0 ns  after v := '1'      -> v='1'  (immediate)
[A2] t=0 ns  after sig_a <= '1'  -> sig_a='0'  (OLD value!)
[B1] t=0 ns  after wait for 0 ns  -> sig_a='1'  (NEW value, same time)
[B2] t=1 ns  after wait for 1 ns  -> sig_a='1'
```

สรุป 3 ข้อ:

| ข้อ | ข้อสังเกต |
| --- | --- |
| 1 | `variable` เปลี่ยนค่า **ทันที** |
| 2 | `signal` เปลี่ยนค่า **ท้าย delta cycle** — อ่านทันทีได้ค่าเก่า |
| 3 | `wait for 0 ns` เดินหน้า **หนึ่ง delta cycle** โดยที่ `now` **ไม่เปลี่ยน** |

> หมายเหตุเรื่องหน่วยเวลา: GHDL เริ่มที่ time resolution 1 fs จึงพิมพ์ `t=0 fs`
> ส่วน ModelSim เริ่มที่ 1 ns จึงพิมพ์ `t=0 ns` — อย่าคาดหวังว่า `time'image(now)`
> จะพิมพ์หน่วยเดียวกันเสมอ ถ้าต้องการหน่วยที่แน่นอนให้แปลงเอง (ดู `tb_support_pkg.time_to_ns`)

### 2.7.3.3 Delta cycle ไม่ใช่เวลา — พิสูจน์ด้วย chain 3 ชั้น

`ex01_delta_cycle.vhd` มี chain ข้าม 3 process:

```vhdl
stage1 : process                       -- ขับ ping
stage2 : process (ping)                -- ตื่นเมื่อ ping เปลี่ยน ขับ pong
stage3 : process (pong)                -- ตื่นเมื่อ pong เปลี่ยน
```

ผลรันจริง (ทั้งสองเครื่องมือ):

```
[C1] t=10 ns  stage1 drives ping <= '1'
[C2] t=10 ns  stage2 wakes (ping), drives pong <= '1'  -> same now, different delta cycle
[C3] t=10 ns  stage3 wakes (pong) -> 3-stage chain done with 0 ns of time elapsed
```

**เวลาเดินหน้า 0 ns แต่ข้อมูลผ่าน 3 ชั้น** นี่คือหัวใจของ delta cycle

> **คำถามที่พบบ่อยในข้อสอบ:** "ทำไม `wait for 0 ns` ถึงมีผล?"
> → เพราะมันสั่งให้ simulator ทำอีกหนึ่งรอบของ compute phase (delta cycle)
> โดยไม่เดินเวลา ถ้าไม่มีบรรทัดนี้ process จะอ่านค่าเก่าไปตลอด

### 2.7.3.4 กรณีที่พบบ่อย: race ระหว่างการขับกับการอ่าน

```vhdl
-- ❌ ผิด: อ่าน signal ที่ตัวเองเพิ่งขับ -> ได้ค่าเก่า
process
begin
    din <= '1';
    wait for 10 ns;
    if din = '1' then ...   -- อาจได้ค่าเก่าในบาง timing
end process;

-- ✅ ถูก: ใช้ตัวแปรเก็บค่าที่ต้องการส่งออก
process
    variable v : std_logic;
begin
    v := '1';
    din <= v;              -- ส่งออก
    wait for 10 ns;
    -- ถ้าจะใช้ค่าที่ส่ง ใช้ v ไม่ใช่ din
end process;
```

---

## 2.7.4 Signal vs Variable ใน Testbench

### 2.7.4.1 ตารางเปรียบเทียบ

| คุณสมบัติ | Signal | Variable |
| --- | --- | --- |
| มีผลเมื่อไหร่ | ท้าย delta cycle | ทันที |
| สร้าง event ให้ process อื่น | ได้ | ไม่ได้ |
| เก็บค่าประวัติได้ | ได้ (ด้วย `last_value`) | ไม่ได้ |
| เขียนจากหลาย process | ได้ (แต่ต้องระวังการเขียนพร้อมกัน) | ไม่ได้ |
| ใช้นับ pass/fail ใน TB | ❌ **ผิดวิธี** | ✅ **ถูกต้อง** |
| ใช้เก็บค่า "ที่เพิ่งส่ง" | ❌ (ได้ค่าเก่า) | ✅ |

### 2.7.4.2 ผลจริง: ตัวนับ signal รายงานค่าเก่า

`ex02_signal_vs_variable.vhd` นับ 10 ครั้ง แล้วเทียบผล:

```vhdl
for i in 1 to N loop
    sig_cnt <= sig_cnt + 1;   -- มีผลท้าย delta cycle
    var_cnt := var_cnt + 1;   -- มีผลทันที
end loop;
report "[A1] ... var_cnt=" & integer'image(var_cnt) &
       "  sig_cnt=" & integer'image(sig_cnt);
wait for 0 ns;
report "[A2] ... var_cnt=" & integer'image(var_cnt) &
       "  sig_cnt=" & integer'image(sig_cnt);
```

ผลรันจริง (GHDL 5.0.1 และ ModelSim 2026.1 เหมือนกัน):

```
[A1] right after loop: var_cnt=10  sig_cnt=0   (signal is still the OLD value)
[A2] after wait for 0 ns: var_cnt=10  sig_cnt=1  (signal updated, but too late for the summary)
[A3] after wait for 1 ns: sig_cnt=1
```

สังเกตสองอย่าง:

1. **`sig_cnt` เป็น 0 ไม่ใช่ 10** ตอนรายงาน — นี่คือบั๊ก "false PASS" ที่อธิบายบั๊กข้อ 3
   ในตัวอย่าง §2.5 ของคู่มือหลัก (ดูหัวข้อ 2.7.0.2)
2. **หลัง `wait for 0 ns` ค่ากลายเป็น 1 ไม่ใช่ 10** เพราะการ assign ซ้ำ 10 ครั้ง
   ในรอบเดียวกันจะ "ยุบ" เหลือการ assign ล่าสุดเท่านั้น (เพราะเป็น signal เดียวกัน)

### 2.7.4.3 ข้อสรุปสำหรับ testbench

| ต้องการ | ใช้ |
| --- | --- |
| นับ pass/fail ภายใน process | `variable` |
| เก็บค่าที่เพิ่งส่งออก | `variable` |
| ส่งค่าให้ DUT เห็น | `signal` |
| ให้ monitor process อื่นเห็น | `signal` |
| นับข้ามหลาย process | `shared variable` (protected type) |

### 2.7.4.4 Shared variable และ Protected type

VHDL ห้าม `shared variable` ที่มีชนิดธรรมดา — ต้องเป็น **protected type** เท่านั้น
(ข้อบังคับของภาษา พิสูจน์แล้วจาก error ของ GHDL):

```
error: type of a shared variable must be a protected type
```

`counter_pkg.vhd` ในโฟลเดอร์ตัวอย่าง:

```vhdl
package counter_pkg is
    type counter_t is protected
        procedure increment;
        procedure add (n : in integer);
        procedure reset;
        impure function get_value return integer;
    end protected counter_t;
end package counter_pkg;

package body counter_pkg is
    type counter_t is protected body
        variable value : integer := 0;

        procedure increment is
        begin
            value := value + 1;
        end procedure increment;

        impure function get_value return integer is
        begin
            return value;
        end function get_value;
    end protected body counter_t;
end package body counter_pkg;
```

> **ข้อสังเกตสำคัญ:** function ที่อ่าน state ภายใน protected type ต้องเป็น **`impure function`**
> ไม่งั้นจะผิดกฎ pure function (พิสูจน์แล้ว):
> `error: reference to variable "count" violate pure rule for function "size"`

ผลรันจริงจาก `ex02`:

```
[B1] protected shared variable = 10
```

---

## 2.7.5 Wait statement — ทั้ง 4 แบบ และกฎที่คนส่วนใหญ่ไม่รู้

### 2.7.5.1 สี่แบบ

| รูปแบบ | ความหมาย | ใช้เมื่อ |
| --- | --- | --- |
| `wait for <time>;` | รอเวลา | รอจังหวะเวลาแน่นอน |
| `wait until <cond>;` | รอจนเงื่อนไขเป็นจริง | รอ handshake / รอสัญญาณ |
| `wait on <sig_list>;` | รอจน signal ใดตัวหนึ่งเปลี่ยน | รอเหตุการณ์ แล้วทำงานต่อได้ |
| `wait;` | หยุด process ถาวร | จบงานของ process นั้น |

### 2.7.5.2 ⚠️ กฎที่พิสูจน์แล้ว: `wait until` **ไม่ทำงานทันที** แม้เงื่อนไขจะจริงแล้ว

นี่คือข้อค้นพบที่สำคัญที่สุดของหัวข้อนี้ และได้ทดสอบยืนยันตรงกัน
ทั้ง **GHDL 5.0.1** และ **ModelSim/Questa 2026.1**:

```vhdl
signal sig : std_logic := '1';
p : process
begin
    report "A: before wait until (sig is already '1')";
    wait until sig = '1';
    report "B: AFTER wait until -- did it resume immediately?";
    wait for 10 ns;
    report "C: 10 ns later";
    wait;
end process p;
```

ผลรันจริง:

| เครื่องมือ | ผลลัพธ์ |
| --- | --- |
| GHDL 5.0.1 | พิมพ์เฉพาะ `A:` — process **ค้าง** ที่ `wait until` ไม่เคยไปถึง `B:` |
| ModelSim/Questa 2026.1 | พิมพ์เฉพาะ `A:` — เหมือนกัน |

**สาเหตุ:** `wait until` มี sensitivity list โดยปริยาย (signal ที่อยู่ในเงื่อนไข)
process จะตื่นเมื่อ **มี event** เกิดขึ้นบน signal นั้น แล้วจึงค่อยตรวจเงื่อนไข
แม้เงื่อนไขจะเป็นจริงอยู่แล้วก็ตาม — ถ้าไม่มี event ก็ไม่มีการตื่น

> นี่เป็นเหตุผลที่ `wait until rising_edge(clk);` ใช้ได้เสมอ
> เพราะการเปลี่ยนค่าของ clk เป็น **event** โดยธรรมชาติ

### 2.7.5.3 ผลจริงในตัวอย่าง `ex03_wait_statements.vhd`

ตัวอย่างนี้มี handshake จริง (stim → wait_until → done → ack → wait_until):

```
[A1] t=0 ns   start
[D1] t=0 ns   before wait;
[DRV] t=5 ns  drives stim_sig <= '1'
[C1] t=5 ns   wait on woke up when stim_sig changed -> '1'
[B1] t=5 ns   wait until woke up because stim_sig = '1'
[DRV] t=5 ns  drives ack_sig <= '1'
[C2] t=5 ns   wait on woke up when ack_sig changed -> '1'
[B2] t=5 ns   wait until woke up because ack_sig = '1'
[A2] t=12 ns  after wait for 12 ns
[A3] t=15 ns  after wait for 3 ns (total 15 ns)
[END] t=40 ns done
```

### 2.7.5.4 ⚠️ Deadlock ที่เกิดจริงระหว่างทำตัวอย่าง

ระหว่างเขียน `ex07_uart_scoreboard.vhd` ผู้เขียนเขียน handshake แบบนี้ก่อน:

```vhdl
-- ❌ ผิด: deadlock
stim : process
begin
    din_vld <= '1';
    wait until din_rdy = '1';   -- din_rdy เป็น '1' อยู่แล้ว -> ไม่มี event -> ค้าง!
    ...
end process;
```

ผลคือ simulation ไม่เคยจบ เพราะ `din_rdy` ไม่เคยเปลี่ยน (DUT คิดว่าได้รับข้อมูลแล้ว)
จนกว่า stimulus จะปล่อย `din_vld` ซึ่งก็ค้างอยู่ที่ `wait until` — **ตายกัน**

วิธีแก้ที่ถูกต้องคือ **รอการเปลี่ยนแปลง** ของสัญญาณ ไม่ใช่รอค่า:

```vhdl
-- ✅ ถูก: รอให้ DUT "ตกลง" ว่ารับข้อมูลแล้ว (din_rdy ตกลงเป็น '0')
din_vld <= '1';
wait until din_rdy = '0';    -- มี event แน่นอน: din_rdy เปลี่ยน 1 -> 0
din_vld <= '0';
```

หลังแก้แล้ว `ex07` ผ่าน `PASS=5 FAIL=0` (ดูหัวข้อ 2.7.9)

### 2.7.5.5 ⚠️ Process ที่มี sensitivity list ห้ามมี wait statement

ข้อจำกัดของภาษา — GHDL ปฏิเสธทันที:

```
error: wait statement not allowed in a sensitized process
```

| ต้องการ | รูปแบบที่ถูกต้อง |
| --- | --- |
| รอเงื่อนไข | `process` (ไม่มี sensitivity list) + `wait until` |
| ตอบสนองทุกครั้งที่ signal เปลี่ยน | `process (sig)` (ไม่มี wait เลย) |
| ทำทั้งสองอย่าง | แยกเป็น 2 process |

```vhdl
-- ❌ ผิด
demo_wait_until : process (stim_sig)
begin
    if stim_sig = '1' then
        wait until ack_sig = '1';     -- ❌ error
    end if;
end process;

-- ✅ ถูก
demo_wait_until : process
begin
    wait until stim_sig = '1';
    wait until ack_sig = '1';
    done <= true;
end process;
```

---

## 2.7.6 การสร้างนาฬิกา และบั๊ก "นาฬิกาไม่เคยตี"

### 2.7.6.1 รูปแบบมาตรฐาน

```vhdl
constant CLK_PERIOD : time := 10 ns;
signal clk : std_logic := '0';       -- ⚠️ ต้องมี initial value

begin
    clk <= not clk after CLK_PERIOD / 2;
```

### 2.7.6.2 ⚠️ ทำไมต้องมี `:= '0'`

`std_logic` ที่ไม่มี initial value จะมีค่าเป็น `'U'` (uninitialized)
และ `not 'U'` = `'U'` → ค่าไม่เปลี่ยน → นาฬิกาไม่เคยตี

มีรายละเอียดที่ซับซ้อนกว่านั้นอีก: `clk <= not clk after T/2;` เป็น **concurrent signal
assignment** ซึ่ง sensitive ต่อ `clk` ตัวเอง เมื่อ `clk` ถูก assign ค่า `'U'` ซึ่ง
**ไม่ใช่การเปลี่ยนค่า** simulator จะไม่ trigger ใหม่ → การ assign ครั้งถัดไป
ไม่ถูกจัดคิว → **นาฬิกาหยุดที่ 5 ns** ไม่ใช่วิ่งไปเรื่อย ๆ

### 2.7.6.3 ผลจริง — เวอร์ชัน BAD และ GOOD

`ex04_clock_bug.vhd` (BAD — ไม่มี `:= '0'`) รัน 200 ns:

```
[BAD] rising edges actually seen = 0
[BAD] current clk value        = 'U'
[BAD] current detected value   = '0'
[BAD] -> the clock never ticked; the DUT stayed in reset
```

`ex04_clock_fixed.vhd` (GOOD — มี `:= '0'`) รัน 200 ns คาบ 10 ns:

```
[GOOD] rising edges actually seen = 20
[GOOD] current clk value        = '0'
[GOOD] current detected value   = '0'
[GOOD] -> the clock ticks and the FSM runs
```

**ตรวจสอบเองได้:** 200 ns ÷ 10 ns = 20 rising edge ตรงกับผลจริงพอดี ✅

### 2.7.6.4 เคล็ดลับ: ให้ testbench นับ edge ให้

ใส่ edge counter ใน testbench เสมอ จะเป็น "กับดักจับบั๊ก" ที่ถูกที่สุด:

```vhdl
edge_counter : process (clk)
begin
    if rising_edge(clk) then
        edge_count <= edge_count + 1;
    end if;
end process edge_counter;

-- ท้าย testbench
report "rising edges actually seen = " & integer'image(edge_count);
```

ถ้าได้ 0 แปลว่านาฬิกาไม่เคยตี — แก้ปัญหานี้ก่อนไปต่อ
(นี่คือเทคนิคที่ผู้เขียนใช้ตรวจบั๊กข้อ 1 ของคู่มือหลัก)

### 2.7.6.5 Clock ควรมาจาก TB หรือจาก DUT?

| ทางเลือก | เหมาะกับ | ข้อควรระวัง |
| --- | --- | --- |
| TB ขับนาฬิกา | ทุกกรณี (ค่าเริ่มต้น) | ต้องประกาศที่ architecture level ไม่ใช่ใน process |
| DUT สร้างนาฬิกาเอง | design ที่มี PLL/oscillator จำลอง | ต้องออกแบบให้ปิด/เปิดได้ |
| generic กำหนดคาบ | ต้องสแกนหลายความเร็ว | ต้องแปลงเป็น `time` ให้ถูก |

---

## 2.7.7 Procedure และ Function ใน Testbench

### 2.7.7.1 สามรูปแบบที่ต้องรู้

```
┌─────────────────────────────────────────────────────────────────┐
│ ① procedure ใน architecture declarative part                    │
│    → เข้าถึง signal ของ architecture ได้โดยตรง                     │
│    → เหมาะกับ procedure ที่มี wait ข้างใน                            │
├─────────────────────────────────────────────────────────────────┤
│ ② procedure ใน process                                          │
│    → เข้าถึงได้เฉพาะตัวแปรของ process นั้น                            │
│    → เหมาะกับ checker ที่สะสมผลลงใน record                        │
├─────────────────────────────────────────────────────────────────┤
│ ③ function                                                      │
│    → ต้องเป็น pure หรือ impure                                     │
│    → impure ใช้เมื่ออ่าน state ภายนอก                               │
└─────────────────────────────────────────────────────────────────┘
```

### 2.7.7.2 ⚠️ ข้อจำกัด: ใช้ `'event` / `rising_edge` กับ formal parameter ไม่ได้

```vhdl
-- ❌ ผิด
procedure wait_cycles (n : in integer; c : in std_logic) is
begin
    for i in 1 to n loop
        wait until rising_edge(c);      -- error: signal parameter requires a signal name
    end loop;
end procedure;

-- ❌ ผิด (ทางเลือกที่ควรจะใช้ได้ แต่ก็ผิด)
        wait until c'event and c = '1'; -- error: prefix of "event" attribute must denote a signal
```

**เหตุผล:** แอตทริบิวต์ `'EVENT` ต้องใช้กับ signal ที่ "เป็นชื่อจริง" ไม่ใช่ formal parameter
ของ subprogram

**วิธีแก้ที่ถูกต้อง:** ประกาศ procedure ไว้ที่ **architecture declarative part**
เพื่อให้อ้างถึง signal ของ architecture ได้โดยตรง

```vhdl
architecture sim of ex05_procedure_checker is
    signal clk : std_logic := '0';
    ...
    procedure wait_cycles (n : in integer) is      -- ไม่ต้องส่ง clk เข้ามา
    begin
        for i in 1 to n loop
            wait until rising_edge(clk);             -- clk เป็น signal จริง -> อ้างถึงได้
        end loop;
    end procedure wait_cycles;
begin
    ...
end architecture;
```

### 2.7.7.3 Checker แบบสะสมผลใน record

```vhdl
-- tb_support_pkg.vhd
package tb_support_pkg is
    type check_result_t is record
        passed : integer;
        failed : integer;
    end record;

    constant EMPTY_RESULT : check_result_t := (passed => 0, failed => 0);

    procedure report_result (name : in string; r : in check_result_t);
end package;
```

```vhdl
-- ใน testbench
stim : process
    variable result : check_result_t := EMPTY_RESULT;

    procedure check_bit (got      : in  std_logic;
                         expected : in  std_logic;
                         tag      : in  string;
                         r        : inout check_result_t) is
    begin
        if got = expected then
            r.passed := r.passed + 1;
        else
            r.failed := r.failed + 1;
            report "FAIL " & tag & ": got " & std_logic'image(got) &
                   " expected " & std_logic'image(expected)
                severity error;
        end if;
    end procedure check_bit;
begin
    ...
    check_bit(detected, '0', "after 1", result);
    report_result("ex05_procedure_checker", result);
    std.env.stop;
end process;
```

ผลรันจริง:

```
[F1] impure function works (detected = '1')
ex05_procedure_checker  PASS=3  FAIL=0
```

### 2.7.7.4 `report_result` ที่เลือก severity ให้เหมาะกับ CI

```vhdl
procedure report_result (name : in string; r : in check_result_t) is
    constant msg : string := name &
                   "  PASS=" & integer'image(r.passed) &
                   "  FAIL=" & integer'image(r.failed);
begin
    if r.failed = 0 then
        report msg severity note;
    else
        -- severity failure ทำให้ simulator จบด้วย exit code ไม่เป็นศูนย์
        report msg severity failure;
    end if;
end procedure report_result;
```

### 2.7.7.5 Impure function

```vhdl
-- ต้องเป็น impure ถ้าอ่านค่าจาก scope นอก
impure function is_high (s : std_logic) return boolean is
begin
    return s = '1';
end function is_high;
```

ถ้าเขียนเป็น `function` ธรรมดา (pure) จะได้ error:
`error: reference to variable ... violate pure rule`

### 2.7.7.6 TB support package — ย้ายของที่ใช้ซ้ำออกจาก testbench

ข้อดีที่พิสูจน์ได้จากการใช้จริงในตัวอย่างทั้งชุด:

- เขียน checker ครั้งเดียว ใช้ได้ทุก testbench
- เปลี่ยนรูปแบบรายงานที่เดียวทั้งชุด
- การเลือก severity ทำในจุดเดียว → regression ตัดสินผลได้ถูกต้อง

---

## 2.7.8 การสร้าง Stimulus

### 2.7.8.1 สี่รูปแบบ

| รูปแบบ | ข้อดี | ข้อเสีย | ใช้เมื่อ |
| --- | --- | --- | --- |
| Directed | ระบุผลลัพธ์ได้แน่นอน | เขียนยาก ครอบคลุมไม่ได้ทุกกรณี | ตรวจ regression ที่รู้ผลแน่นอน |
| Exhaustive | ครอบคลุม 100% | โตเร็วเป็น 2ⁿ | input space เล็ก (≤ 8–12 บิต) |
| Random | เจอบั๊กที่คิดไม่ถึง | ไม่รับประกันว่าจะเจอ | ค้นหา bug, coverage-driven |
| Protocol-driven | ใกล้เคียงการใช้งานจริง | ต้องเข้าใจ protocol | ทดสอบ block ที่มี handshake |

### 2.7.8.2 ⚠️ Random ต้อง reproducible

Random ที่สุ่มใหม่ทุกครั้งทำให้กลายเป็น "บั๊กที่หายไป" — ต้องมี seed คงที่

```vhdl
entity ex06_random_stimulus is
    generic (
        SEED_VALUE : integer := 12345;   -- เปลี่ยนค่านี้เพื่อทดสอบลำดับใหม่
        N_VECTORS  : integer := 200
    );
end entity;
```

### 2.7.8.3 ⚠️ `IEEE.MATH_REAL.UNIFORM` ใช้ **สอง seed**

```vhdl
-- ❌ ผิด (แบบที่เห็นในตัวอย่างเก่า ๆ บนอินเทอร์เน็ต)
uniform(seed, x);
-- error: can't associate "x" with variable interface "SEED2"

-- ✅ ถูก (ตามมาตรฐาน IEEE 1076)
uniform(rng_seed1, rng_seed2, x);
```

จากการตรวจ source ของ GHDL โดยตรง
(`/usr/lib/ghdl/src/ieee2008/math_real.vhdl`):

```vhdl
procedure UNIFORM(variable SEED1, SEED2 : inout POSITIVE; variable X : out REAL);
```

> บาง vendor library มีแบบ seed เดียว — **ต้องตรวจ package ของเครื่องมือที่ใช้จริงก่อนเสมอ**
> คำสั่งตรวจ: `grep -n "procedure UNIFORM" <path ของ ieee math_real>`

### 2.7.8.4 ผลจริงจาก `ex06_random_stimulus.vhd`

```
[R1] seed=12345  vectors=200  checksum=365623  final count=98
[R2] re-run with the same seed and the checksum must match
ex06_random_stimulus  PASS=200  FAIL=0
```

**ผลสำคัญ:** checksum = **365623** และ final count = **98**
ได้ **เหมือนกันทุกประการ** ทั้งบน GHDL 5.0.1 และ ModelSim/Questa 2026.1
→ ลำดับสุ่มขึ้นกับ seed ไม่ขึ้นกับเครื่องมือ ✅

> **ทำไมถึงสำคัญ:** ถ้า checksum เปลี่ยนเมื่อเปลี่ยนเครื่องมือ แปลว่า random regression
> จะ "หาบั๊กที่หายไป" เวลาทีมใช้เครื่องคนละเครื่อง → ต้องบันทึก seed ไว้ใน log เสมอ

### 2.7.8.5 ใช้ reference model ตรวจแทนการเดาผลลัพธ์

```vhdl
-- reference model: นับเองว่าควรเป็นเท่าไร
if bit_v = 1 then
    expected := expected + 1;
end if;

if to_integer(cnt) /= expected then
    result.failed := result.failed + 1;
    ...
else
    result.passed := result.passed + 1;
end if;
```

reference model ต้อง "คนละทาง" กับ DUT — ถ้าเขียนเหมือน DUT ทุกบรรทัด
ก็จะพัดพร้อมกันและไม่จับบั๊กได้

### 2.7.8.6 ⚠️ integer overflow ใน checksum

```vhdl
-- ❌ ผิด
checksum := (checksum * 31 + bit_v) mod 2147483647;
-- ghdl:error: overflow detected
--   instance: /ex06_random_stimulus/stim

-- ✅ ถูก
checksum := (checksum * 31 + bit_v) mod 1000003;
```

`integer` ใน VHDL มีขอบเขต ±2,147,483,647 — ค่า `checksum * 31` จะล้นก่อนถึงขั้นตอน `mod`
GHDL จับ overflow แล้วหยุด simulation ✅ (ซึ่งเป็นพฤติกรรมที่ดี — อย่าปิดมัน)

---

## 2.7.9 Scoreboard และ Reference Model

### 2.7.9.1 สามชั้นของการตรวจผล

```
┌────────────────────────────────────────────────────────────┐
│ ① Expected-value checker                                   │
│    ทราบค่าที่คาดหวังอยู่แล้ว ทดสอบทีละเคส                        │
│    เหมาะกับ: directed test, กรณีเล็ก                          │
├────────────────────────────────────────────────────────────┤
│ ② Reference model                                          │
│    สร้างโมเดลคู่ขนานที่คำนวณค่าที่ถูกต้องเอง                        │
│    เหมาะกับ: ตรรกะที่ซับซ้อน เช่น ALU, FIFO, CRC                │
├────────────────────────────────────────────────────────────┤
│ ③ Scoreboard (in-order queue)                              │
│    ผู้ผลิตส่งของเข้า queue → ผู้ตรวจดึงออกมาเทียบ                   │
│    เหมาะกับ: protocol ที่มี handshake และ stream ข้อมูล         │
└────────────────────────────────────────────────────────────┘
```

### 2.7.9.2 Scoreboard แบบ queue ต้องใช้ Protected type

`uart_sb_pkg.vhd`:

```vhdl
package uart_sb_pkg is
    type byte_queue_t is protected
        procedure push (v : in integer);
        procedure pop  (v : out integer);
        impure function size return integer;
    end protected byte_queue_t;
end package uart_sb_pkg;
```

### 2.7.9.3 ⚠️ Race ระหว่าง push และ pop

ระหว่างเขียนตัวอย่าง ผู้เขียนเขียนแบบ push ทีละเฟรม:

```vhdl
-- ❌ ผิด: race
for i in TEST_BYTES'range loop
    sb.push(TEST_BYTES(i));      -- push
    ... ส่งเฟรม ...
end loop;
-- monitor pop อาจเกิดก่อน push ของเฟรมถัดไป -> queue ว่าง -> expected = -1
```

ผลรันจริงก่อนแก้:

```
FRAME MISMATCH #1 decoded=0 expected=-1
FRAME MISMATCH #2 decoded=0 expected=-1
FRAME MISMATCH #3 decoded=0 expected=-1
FRAME MISMATCH #4 decoded=0 expected=-1
```

**วิธีแก้: เตรียมค่าคาดหวังทั้งหมดลง queue ก่อนเริ่มส่ง**

```vhdl
-- ✅ ถูก
for i in TEST_BYTES'range loop
    sb.push(TEST_BYTES(i));
end loop;

for i in TEST_BYTES'range loop
    ... ส่งเฟรม ...
end loop;
```

### 2.7.9.4 ตัวอย่างเต็ม: UART TX จาก Mini Project

`ex07_uart_scoreboard.vhd` ใช้ `uart_tx` จริงจาก `lab_code/day5/uart_tx.vhd`
โดยมี 3 ส่วน:

**① Baud tick generator (สร้าง pulse กว้าง 1 คาบนาฬิกา)**

```vhdl
baud_gen : process
    variable div : integer := 0;
    constant TICKS_PER_BIT : integer := BIT_PERIOD_NS / CLK_PERIOD_NS;
begin
    wait until rising_edge(clk);
    div := div + 1;
    if div >= TICKS_PER_BIT then
        div := 0;
        baud_tick <= '1';
    else
        baud_tick <= '0';
    end if;
end process baud_gen;
```

> ⚠️ **ห้ามทำเป็น square wave** (toggle ทุกครึ่ง bit period) เพราะ transmitter
> จะก้าวหลาย bit ใน 1 จังหวะ → ข้อมูลเพี้ยนทั้งเฟรม
> ระหว่างเขียนตัวอย่างนี้ ผู้เขียนเขียนผิดแบบนี้ก่อน แล้วพบว่า decode ได้ 0 ทุกเฟรม

**② Stimulus ที่พูดภาษาของ protocol**

```vhdl
din <= std_logic_vector(to_unsigned(b, 8));
din_vld <= '1';
wait until din_rdy = '0';     -- DUT รับข้อมูลแล้ว (ดูหัวข้อ 2.7.5.4)
din_vld <= '0';
wait for 11 * BIT_PERIOD;     -- รอให้เฟรมจบ
```

**③ Monitor ที่ถอด serial กลับเป็น byte**

```vhdl
wait until falling_edge(tx);      -- จับ start bit
wait for BIT_PERIOD / 2;          -- มาที่กลาง start bit

decoded := 0;
for b in 0 to 7 loop
    wait for BIT_PERIOD;          -- มาที่กลาง data bit ถัดไป
    -- UART ส่ง LSB-first: bit แรกคือน้ำหนัก 2^0
    if tx = '1' then
        decoded := decoded + (2 ** b);
    end if;
end loop;

sb.pop(expected);
if decoded = expected then ... else ... end if;
```

> ⚠️ **UART ส่ง LSB-first** — ถ้า decode แบบ MSB-first (`decoded := decoded*2 + bit`)
> ค่าจะเพี้ยนทุกเฟรม (ผู้เขียนเขียนผิดแบบนี้ก่อนแก้)

### 2.7.9.5 ผลจริง

```
[S1] frames decoded = 5  queue remaining = 0
ex07_uart_scoreboard  PASS=5  FAIL=0
```

เฟรมที่ทดสอบ: `0x00, 0xFF, 0x55, 0xAA, 0x3C` — ผ่านทั้ง 5 เฟรม ✅
และ `queue remaining = 0` ยืนยันว่า monitor pop ครบทุกเฟรมพอดี (ไม่มีเฟรมค้าง/หลุด)

---

## 2.7.10 File I/O ด้วย STD.TEXTIO

### 2.7.10.1 ใช้ทำอะไร

- อ่าน test vector จากไฟล์ (ไม่ต้องแก้โค้ดทุกครั้งที่เพิ่มเคส)
- เขียนรายงานผลการทดสอบลงไฟล์
- แลกเปลี่ยน golden reference กับทีม

### 2.7.10.2 ⚠️ `HREAD` ในมาตรฐานมีเฉพาะ `BIT_VECTOR`

ตรวจจาก source ของ GHDL โดยตรง
(`/usr/lib/ghdl/src/std/v08/textio.vhdl`):

```vhdl
procedure Hread (L: inout Line; Value: out Bit_Vector; Good: out Boolean);
procedure Hread (L: inout Line; Value: out Bit_Vector);
```

**ไม่มี overload สำหรับ `INTEGER` หรือ `REAL`** →

```
error: cannot resolve overloading for subprogram call
                hread(l, v);
```

**ทางแก้ที่ไม่ต้องพึ่ง vendor package:**

```vhdl
variable v_bits : bit_vector(7 downto 0);
variable v      : integer;
...
hread(l, v_bits);                     -- อ่านเป็นเลขฐาน 16
v := 0;
for i in v_bits'range loop
    v := v * 2 + bit'pos(v_bits(i));
end loop;
```

> หมายเหตุ: แพ็กเกจ `IEEE.STD_LOGIC_TEXTIO` ที่หลายเครื่องมือแจกมามี `hread`
> สำหรับ `std_logic_vector`/`integer`/`unsigned` แต่เป็นส่วนขยาย ไม่ใช่แพ็กเกจมาตรฐาน
> ถ้าใช้ต้องยืนยันว่าเครื่องมือที่ใช้มีจริง

### 2.7.10.3 ⚠️ บรรทัด comment ทำให้ `hread` ล้มเหลว

`hread` คาดหวังว่าข้อความทั้งบรรทัดเป็นเลขฐาน 16 ถ้าเจอ comment จะเกิด
assertion failure ทันที:

```
../../src/std/v08/textio-body.vhdl:1553:5:@20ns:(assertion failure): hexa bit_vector read failure
ghdl:error: assertion failed
```

**วิธีแก้:** ข้ามบรรทัดที่ไม่ใช่เลขฐาน 16 ก่อน

```vhdl
function is_hex_digit (c : character) return boolean is
begin
    return (c >= '0' and c <= '9') or
           (c >= 'A' and c <= 'F') or
           (c >= 'a' and c <= 'f');
end function is_hex_digit;

...
if l'length > 0 and is_hex_digit(l(l'low)) then
    hread(l, v_bits);
    ...
end if;
```

### 2.7.10.4 Path ของไฟล์สัมพัทธ์กับ working directory

```vhdl
file vec_file : text open read_mode  is VECTOR_FILE;   -- generic
file rep_file : text open write_mode is REPORT_FILE;    -- generic
```

- path สัมพัทธ์กับ **working directory ของ simulator** ไม่ใช่กับไฟล์ source
- โฟลเดอร์ของไฟล์ที่จะเปิด **ต้องมีอยู่ก่อน** มิฉะนั้นจะ error
- ควรใช้ **generic** เพื่อให้สลับ path ได้โดยไม่ต้อง recompile

### 2.7.10.5 ผลจริงจาก `ex08_file_io.vhd`

ไฟล์ `vectors/tb_vectors.txt` มี 12 เวกเตอร์ (มีบรรทัด comment ด้วย):

```
-- Test vectors for ex08_file_io
01
00
11
10
01
01
00
1F
A5
5A
FF
00
```

ผลรันจริง:

```
[F1] vectors read = 12  passed = 12  failed = 0
[F2] report written to reports/ex08_report.txt
ex08_file_io  PASS=12  FAIL=0
```

ไฟล์รายงานที่ได้:

```
ex08_file_io report
--------------------
vectors read : 12
passed       : 12
failed       : 0
final count  : 6
```

---

## 2.7.11 Assertion และ Severity level

### 2.7.11.1 `report` กับ `assert`

| | `report` | `assert` |
| --- | --- | --- |
| เงื่อนไข | ไม่มี | มี |
| แสดงข้อความเมื่อ | เสมอ | เมื่อเงื่อนไขเป็น FALSE |
| ใช้บังคับให้หยุด | `severity failure` | `severity failure` |

```vhdl
-- report: ลงทะเบียนข้อความเสมอ
report "INFO: starting test" severity note;

-- assert: ตรวจเงื่อนไข
assert to_integer(cnt) = expected
    report "counter mismatch" severity error;
```

### 2.7.11.2 ตาราง severity 4 ระดับ

| severity | ใช้เมื่อ | ผลต่อ simulation |
| --- | --- | --- |
| `note` | ข้อความบันทึกปกติ | พิมพ์ออกมา ไม่หยุด |
| `warning` | ผิดปกติแต่ไม่ร้ายแรง | พิมพ์ออกมา ไม่หยุด |
| `error` | พบความผิดพลาด | พิมพ์ออกมา ไม่หยุด (แต่นับเป็น error) |
| `failure` | ทดสอบล้มเหลว | **หยุด simulation** |

### 2.7.11.3 ⚠️ ผลของ severity ต่อ exit code — ต่างกันระหว่างเครื่องมือ

`ex09_assertion_severity.vhd` รันด้วย `-gLEVEL=0..3` ผลจริง:

| LEVEL | GHDL 5.0.1 | ModelSim/Questa 2026.1 |
| --- | --- | --- |
| 0 (note) | `** Note:` → exit **0** | `** Note:` → `Errors: 0` → exit **0** |
| 1 (warning) | `** Warning:` → exit **0** | `** Warning:` → `Warnings: 1` → exit **0** |
| 2 (error) | `** Error:` → exit **0** | `** Error:` → `Errors: 1` → exit **0** |
| 3 (failure) | `** Fatal:` → **exit 1** ✅ | `** Failure:` → `Errors: 1` → exit **0** ⚠️ |

ข้อสรุปที่ต้องจำ:

> **GHDL** คืน exit code 1 เมื่อ severity failure → ใช้ใน CI ได้ตรง ๆ
> **ModelSim/Questa** คืน exit code 0 **เสมอ** แม้จะ severity failure
> → ต้องตรวจข้อความ `Errors: N` ใน log แทน

ModelSim รองรับ `quit -code <integer>` แต่ `onerror`/`onbreak` **ไม่** trigger
เมื่อเจอ severity failure (ยืนยันจากการรันจริง) ทางแก้ที่ใช้ได้จริงคือ
**parse log**:

```tcl
onerror {quit -code 1}
run -all
quit -code 0
```

คู่กับ PowerShell ที่อ่าน log:

```powershell
$out = & "$msim\vsim.exe" -c work.tb_xxx -do "run -all; quit -f" 2>&1
$txt = $out | Out-String
$failed = ($txt -match '\*\* (Failure|Error):') -or ($txt -match 'Errors:\s*[1-9]')
if ($failed) { $fail++ }
```

สคริปต์ฉบับสมบูรณ์อยู่ที่ `lab_code/day2_testbench/run_modelsim_regression.ps1`
ซึ่งรันทั้งชุดและสรุปเป็น `reports/modelsim/regression_summary.txt`

### 2.7.11.4 `std.env.stop` กับ `std.env.finish`

| คำสั่ง | พฤติกรรม | เหมาะกับ |
| --- | --- | --- |
| `std.env.stop` | หยุดแล้วเข้า break mode | รันแบบ interactive เพื่อ debug ต่อ |
| `std.env.finish` | จบ simulation อย่างสะอาด | batch / regression |

ใน ModelSim `std.env.stop` จะพิมพ์ `Break in Process stim at ...` และค้างใน break mode
ต้อง `quit -f` ต่อในไฟล์ `.do` — ถ้าใช้ใน regression ควรเปลี่ยนเป็น `std.env.finish`

### 2.7.11.5 ⚠️ Simulation ที่ไม่มี `std.env.stop` จะไม่จบ

ถ้า testbench มีนาฬิกาที่วิ่งไม่หยุด (`clk <= not clk after ...`) และไม่มี
`std.env.stop` หรือ `std.env.finish` simulation จะ **วิ่งไม่จบ** ค้างจนโดน timeout

พบเจอจริงระหว่างทำตัวอย่าง: `ex09`, `ex10`, `ex11` ค้างทั้งหมดก่อนที่จะเพิ่ม
`std.env.stop;` เข้าไป

---

## 2.7.12 External name (VHDL-2008) — ดูสัญญาณภายใน DUT

### 2.7.12.1 ปัญหาที่ external name แก้ได้

บางครั้งเราอยากดูสัญญาณภายในของ DUT (เช่น state machine, counter ภายใน)
โดยไม่ต้องแก้ RTL — external name คือคำตอบ

### 2.7.12.2 รูปแบบ

```vhdl
architecture sim of ex10_external_name is
    ...
    probe : process
        alias dut_cnt is << signal .ex10_external_name.dut.cnt_i : unsigned(7 downto 0) >>;
    begin
        wait for 5 * CLK_PERIOD;
        report "[X1] output port cnt = " & integer'image(to_integer(unsigned(cnt)));
        report "[X2] internal cnt_i  = " & integer'image(to_integer(dut_cnt));
        wait;
    end process probe;
end architecture;
```

### 2.7.12.3 ⚠️ ข้อจำกัดที่พบจริง (ทดสอบทั้ง 2 เครื่องมือ)

| ข้อจำกัด | ข้อความ error | ทางแก้ |
| --- | --- | --- |
| signal ที่ประกาศ **ภายใน process** อ้างถึงไม่ได้ | `External reference to or into a VHDL process is not allowed.` (ModelSim)<br>`prefix of "event" attribute must denote a signal` (GHDL) | ย้าย signal ไปประกาศระดับ architecture |
| path ต้องเริ่มด้วย **ชื่อ entity ระดับบนสุด** | `expect "t_extname" instead of "tb" for root of absolute pathname` | ใช้ `.ex10_external_name.dut.cnt_i` ไม่ใช่ `.tb.dut.cnt_i` |
| ต้องใช้ **VHDL-2008** | — | GHDL: `--std=08` / Questa: `vcom -2008` |

### 2.7.12.4 ผลจริง — ทั้ง 2 เครื่องมือให้ผลเหมือนกัน

```
[X1] output port cnt = 5
[X2] internal cnt_i  = 5
[X3] both must be equal (external name reaches inside the DUT)
```

### 2.7.12.5 ทางเลือกที่ปลอดภัยกว่า

ถ้าเครื่องมือไม่รองรับ ให้ใช้วิธีใดวิธีหนึ่ง:

1. **เพิ่ม output port** ใน RTL (ถ้าควบคุม RTL ได้) — ชัดที่สุด
2. **bind** โมดูล probe เข้าไปใน DUT (VHDL-2008) — ไม่ต้องแก้ RTL
3. ดูจาก waveform อย่างเดียว — ช้าแต่ไม่ต้องแก้อะไรเลย

---

## 2.7.13 Configuration declaration — สลับ DUT โดยไม่ recompile

### 2.7.13.1 Configuration ทำอะไรได้

configuration จับคู่ **component** กับ **entity + architecture** ที่ต้องการ
ทำให้สลับ implementation ของ DUT ได้โดยไม่ต้องแก้ testbench และไม่ต้อง compile ใหม่

### 2.7.13.2 ต้องประกาศ component ใน TB

```vhdl
architecture sim of ex11_configuration is
    component ex11_counter
        port (
            clk : in  std_logic;
            rst : in  std_logic;
            cnt : out std_logic_vector(7 downto 0)
        );
    end component;
    ...
    dut : ex11_counter
        port map (clk => clk, rst => rst, cnt => cnt);
```

> ⚠️ ถ้าใช้ **direct entity instantiation** (`dut : entity work.ex11_counter`)
> จะไม่มีชื่อ component ให้ configuration อ้างถึง → ได้ error
> `no declaration for "ex11_counter"` / `component name expected`

### 2.7.13.3 ประกาศ configuration

```vhdl
configuration cfg_using_rtl of ex11_configuration is
    for sim
        for dut : ex11_counter use entity work.ex11_counter(rtl);
        end for;
    end for;
end configuration cfg_using_rtl;

configuration cfg_using_alt of ex11_configuration is
    for sim
        for dut : ex11_counter use entity work.ex11_counter(alt);
        end for;
    end for;
end configuration cfg_using_alt;
```

### 2.7.13.4 วิธีใช้

```bash
ghdl -e --std=08 cfg_using_rtl && ghdl -r --std=08 cfg_using_rtl
ghdl -e --std=08 cfg_using_alt && ghdl -r --std=08 cfg_using_alt
```

```powershell
vsim -c work.cfg_using_rtl -do "run -all; quit -f"
```

### 2.7.13.5 ผลจริง — ทั้ง 2 เครื่องมือเหมือนกัน

| configuration | ผลลัพธ์ |
| --- | --- |
| `cfg_using_rtl` (นับทีละ 1) | `[C1] counter value after 5 clocks = 5` |
| `cfg_using_alt` (นับทีละ 2) | `[C1] counter value after 5 clocks = 10` |

> ใน flow จริง (LibreLane, Questa regression) มักใช้ **bind** และ **generic** มากกว่า
> แต่ configuration ยังเป็นคำสั่งมาตรฐานที่ควรรู้ และเป็นคำตอบของคำถาม
> "จะทดสอบ design เวอร์ชันเก่าเทียบกับเวอร์ชันใหม่อย่างไร"

---

## 2.7.14 Debugging และ Waveform

### 2.7.14.1 เครื่องมือมาตรฐาน

| เครื่องมือ | คำสั่ง | รูปแบบไฟล์ |
| --- | --- | --- |
| GHDL | `ghdl -r --std=08 <unit> --vcd=wave.vcd` | VCD |
| Questa/ModelSim | `vsim -c work.<unit> -do "vcd file wave.vcd; log -r /*; run -all; quit -f"` | VCD / FST |
| Questa GUI | `add wave -r /*` | FST (native) |

### 2.7.14.2 ⚠️ `log -r /*` ดูทุก signal รวมถึงที่ไม่ต้องการ

ใน testbench ขนาดใหญ่ `log -r /*` จะให้ไฟล์ VCD/FST ใหญ่มาก
ควรเลือกเฉพาะ signal ที่เกี่ยวข้อง:

```tcl
log -r {tb_xxx/*}          -- เฉพาะ scope ของ testbench
log -r {tb_xxx/dut/*}      -- เฉพาะภายใน DUT
```

### 2.7.14.3 Event log แบบไม่พึ่ง simulator

เขียน timeline ลงไฟล์ข้อความด้วย `STD.TEXTIO` จะได้ log ที่อ่านได้ทุกเครื่องมือ
และ grep ได้ (ต่างจาก VCD ที่เป็น binary-ish format)

```vhdl
logger : process (cnt)
    file    logf  : text open write_mode is LOG_FILE;
    variable l    : line;
begin
    write(l, string'("time_ns"));
    write(l, string'("  count"));
    writeline(logf, l);

    write(l, integer'image(integer(now / 1 ns)));
    write(l, string'("  "));
    write(l, to_integer(cnt));
    writeline(logf, l);
end process logger;
```

ผลรันจริง (`reports/ex12_events.txt`):

```
time_ns  count
----------------------
0  0
time_ns  count
----------------------
35  1
...
```

> ⚠️ ข้อควรระวัง: โค้ดชุดนี้เขียนหัวข้อซ้ำทุกครั้งที่ cnt เปลี่ยน (เพราะ process sensitive
> ทำงานใหม่ทุกครั้ง) — ถ้าต้องการ header ครั้งเดียวให้แยกเป็น 2 process

### 2.7.14.4 ⚠️ ต้อง initialize signal ที่ monitor อ่าน

```vhdl
signal cnt : unsigned(7 downto 0);                 -- ❌ เริ่มเป็น 'U'
-- ผลรันจริง:
-- NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0   (warning)

signal cnt : unsigned(7 downto 0) := (others => '0');   -- ✅
```

### 2.7.14.5 วิธีหา race ที่พบบ่อย

1. เพิ่ม `wait for 1 ns;` หลัง `wait until rising_edge(clk);` แล้วดูว่าอาการหายไหม
   → ถ้าหาย แปลว่าเป็น race จริง
2. เปลี่ยน checker ไปอ่าน "ค่าที่ process อื่นบันทึกไว้" แทนการอ่านสัญญาณโดยตรง
3. ตรวจว่ามีใครอ่าน signal ที่ตัวเองเป็นคนขับหรือไม่

---

## 2.7.15 Batch และ Regression

### 2.7.15.1 GHDL

```bash
# วิเคราะห์ (เรียงลำดับ package -> rtl -> tb)
ghdl -a --std=08 counter_pkg.vhd tb_support_pkg.vhd rtl/*.vhd ex*.vhd

# elaborate + รัน
ghdl -e --std=08 ex04_clock_fixed
ghdl -r --std=08 ex04_clock_fixed

# แก้ generic ตอนรัน
ghdl -r --std=08 ex06_random_stimulus -gSEED_VALUE=999

# เก็บ waveform
ghdl -r --std=08 ex12_event_log --vcd=reports/ex12_wave.vcd
```

### 2.7.15.2 Questa / ModelSim

```tcl
vcom -2008 -work work tb_xxx.vhd
vsim -c work.tb_xxx -do "run -all; quit -f"
```

> ⚠️ **อย่าซ้อน `vsim` ใน `.do`** — `quit -f` ของ process ลูกจะฆ่า script พ่อก่อน
> ตัวอย่างที่ผิด:
> `vsim -c -do "vsim -c work.tb1 -do \"run -all; quit -f\"; vsim -c work.tb2 ..."`
> ให้รันแต่ละ testbench แยกเป็น process จริง ๆ (ดู `run_modelsim_regression.ps1`)

### 2.7.15.3 ⚠️ `run` ที่สั้นเกินไป = "ผ่าน" ปลอม

ถ้าใช้ `run 100 ns` แต่ testbench ต้องใช้เวลา 5555 ns (อย่าง `ex07`)
จะได้ exit code 0 ทั้งที่ยังไม่ได้ตรวจอะไรเลย

**วิธีกัน:** ให้ testbench พิมพ์ **completion marker** แล้วให้ script ตรวจว่ามีจริง

```tcl
run -all
# ตรวจว่า log มี "ex07_uart_scoreboard  PASS=" หรือไม่
```

หรือใช้ `std.env.finish` ท้าย testbench แล้วตรวจ `Errors: N` จาก log

### 2.7.15.4 Exit code คือสัญญาณ CI

| สถานการณ์ | ผลที่ต้องการ |
| --- | --- |
| ทุกเคสผ่าน | script จบด้วย exit 0 |
| มีเคส fail | script จบด้วย exit ≠ 0 |
| simulator ค้าง | timeout → exit 124 → ต้อง fail ไม่ใช่ผ่าน |

---

## 2.7.16 Checklist กับดักที่พบจริง

ตารางนี้เป็น "checklist ก่อนส่ง testbench" ที่ทุกบรรทัดมาจากบั๊กที่เจอจริงระหว่างทำตัวอย่าง

| # | ตรวจ | วิธีตรวจ | บั๊กที่พบ |
| --- | --- | --- | --- |
| 1 | นาฬิกามี initial value ไหม | `signal clk : std_logic := '0';` | นาฬิกาไม่เคยตี (0 edge) |
| 2 | นับ rising edge ที่เกิดจริง | edge counter ใน TB | ยืนยันว่านาฬิกาเดิน |
| 3 | ตัวนับ pass/fail เป็น variable ไหม | `variable pass_cnt : integer := 0;` | false PASS (FAIL=0) |
| 4 | มี `std.env.stop` / `std.env.finish` ไหม | ท้าย testbench | simulation ค้าง / timeout |
| 5 | checker ใช้ค่าที่ถูกส่งเข้ามาไหม | อ่าน body ของ procedure | ตรวจผิดตัวแปร |
| 6 | `wait until` รอ "การเปลี่ยนแปลง" หรือ "ค่า" | รอ edge / รอสัญญาณตก | deadlock |
| 7 | process ที่มี wait มี sensitivity list ไหม | ตรวจ header | compile error |
| 8 | `wait until rising_edge(c)` โดย c เป็น parameter ไหม | ประกาศ procedure ที่ architecture | compile error |
| 9 | ใช้ `unsigned` เมื่อต้องทำ arithmetic ไหม | `unsigned`/`signed` | compile error |
| 10 | `report` string เป็น ASCII หรือยัง | grep หาอักขระนอก ASCII | compile error |
| 11 | อ่านไฟล์ด้วย `hread` แล้วบรรทัดนั้นเป็นเลขฐาน 16 ไหม | กรองด้วย `is_hex_digit` | assertion failure |
| 12 | `HREAD` ใช้กับ `BIT_VECTOR` (มาตรฐาน) หรือ `STD_LOGIC_TEXTIO` | ตรวจ package ที่มี | overloading error |
| 13 | baud tick เป็น pulse 1 คาบหรือ square wave | ดู waveform | DUT ก้าวผิดจังหวะ |
| 14 | decode ตาม bit order ของ protocol หรือยัง | UART = LSB-first | ข้อมูลเพี้ยน |
| 15 | scoreboard push ค่าคาดหวังครบก่อนเริ่มส่งหรือยัง | ดูลำดับโค้ด | race → expected = -1 |
| 16 | integer ที่คูณใน checksum จะล้นไหม | ใช้ modulus เล็กพอ | overflow detected |
| 17 | external name ชี้ signal ระดับ architecture ไหม | ดูตำแหน่งประกาศ | compile/load error |
| 18 | configuration ใช้ component ไหม | ดู TB | component name expected |
| 19 | มี completion marker ให้ script ตรวจไหม | `report "... PASS="` | ผ่านปลอม |
| 20 | exit code ของ simulator สะท้อนผลจริงไหม | เทียบ GHDL vs Questa | Questa คืน 0 เสมอ |

---

## 2.7.17 Coding style สำหรับ Testbench

```vhdl
-- ✅ รูปแบบที่ใช้ใน lab_code/day2_testbench ทั้งหมด

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.tb_support_pkg.ALL;

entity tb_xxx is
    generic (
        SEED_VALUE : integer := 12345
    );
end entity tb_xxx;

architecture sim of tb_xxx is
    constant CLK_PERIOD : time := 10 ns;
    signal clk   : std_logic := '0';      -- initialize เสมอ
    signal rst   : std_logic := '1';
    signal din   : std_logic_vector(7 downto 0) := (others => '0');
    signal dout  : std_logic_vector(7 downto 0);
begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.design_under_test
        port map (clk => clk, rst => rst, din => din, dout => dout);

    stim : process
        variable result : check_result_t := EMPTY_RESULT;
    begin
        rst <= '1';
        wait for 2 * CLK_PERIOD;
        rst <= '0';

        -- ทดสอบ ...

        report_result("tb_xxx", result);
        std.env.stop;
    end process stim;
end architecture sim;
```

| กฎ | เหตุผล |
| --- | --- |
| ตั้งชื่อ signal ด้วย prefix `tb_` เมื่ออยู่ใน scope ใหญ่ | หลีกเลี่ยงชนกับ signal ของ DUT |
| แยก `stimulus` / `monitor` / `reporter` เป็น process | ไม่เกิด race |
| ใช้ `constant CLK_PERIOD` แทนตัวเลขแข็ง | เปลี่ยนความเร็วได้ทันที |
| ใช้ `variable` เก็บ state ของ TB | ไม่มี delta delay |
| ปิดท้ายด้วย `report_result` + `std.env.stop` | exit code ถูกต้อง, simulation จบ |
| คอมเมนต์อธิบาย **ทำไม** ไม่ใช่ **ทำอะไร** | คอมเมนต์ที่อธิบายกลไกคือคอมเมนต์ที่มีค่าที่สุด |

---

## 2.7.18 แผนที่ไปยังเอกสารอื่น

| ต้องการเรียนรู้เรื่อง | ไปที่ |
| --- | --- |
| RTL guideline และเกณฑ์ตัดสินว่าโค้ดดี | `Manual_2_4_2_5_RTL_Guidelines_and_Testbench_DeepDive.md` ส่วน A–B |
| เลือก stimulus strategy / coverage-driven | `Manual_4_1_Verification_Methodology_DeepDive.md` หัวข้อ 3–5 |
| เขียน assertion และ functional coverage | `Manual_4_2_Assertions_and_FunctionalCoverage_DeepDive.md` |
| ทำ GLS ด้วย SDF | `Manual_4_3_GateLevelSimulation_SDF_DeepDive.md` |
| Mini project UART TX ฉบับเต็ม | `Manual_5_3_MiniProject_RTL_Design_DeepDive.md`, `Manual_5_4_MiniProject_Verification_Synthesis_DeepDive.md` |
| สังเคราะห์และทำ layout | `Manual_3_5_Yosys_and_LibreLane_Synthesis_DeepDive.md`, `Manual_5_4_RTL_to_GDSII_LibreLane_FullChipFlow_DeepDive.md` |

---

## 2.7.19 แบบฝึกหัด

### แบบฝึกหัดที่ 1 — หาบั๊กทั้ง 4 จุด (ระดับ: ง่าย → ปานกลาง)

นำโค้ดนี้ไปรัน แล้วหาบั๊กทั้ง 4 จุด พร้อมอธิบายว่าทำไมถึงเกิด

```vhdl
entity tb_buggy is
end entity;

architecture sim of tb_buggy is
    constant CLK_PERIOD : time := 10 ns;
    signal clk, rst, din, detected : std_logic;
    signal pass_cnt, fail_cnt      : integer := 0;
begin
    dut : entity work.seq_det_moore
        port map (clk => clk, rst => rst, din => din, detected => detected);

    clk <= not clk after CLK_PERIOD / 2;

    stim : process
        procedure check(input  : in  std_logic;
                       expect : in  std_logic;
                       tag    : in  string) is
        begin
            if detected /= expect then
                report "FAIL " & tag severity error;
                fail_cnt <= fail_cnt + 1;
            else
                pass_cnt <= pass_cnt + 1;
            end if;
        end procedure;
    begin
        rst <= '1'; din <= '0';
        wait for 2 * CLK_PERIOD;
        rst <= '0';
        din <= '1'; wait for CLK_PERIOD; check(din, '0', "1");
        din <= '0'; wait for CLK_PERIOD; check(din, '0', "10");
        din <= '1'; wait for CLK_PERIOD; check(din, '1', "101");
        report "PASS=" & integer'image(pass_cnt) & " FAIL=" & integer'image(fail_cnt);
        wait;
    end process stim;
end architecture;
```

<details>
<summary>เฉลย</summary>

1. `clk` ไม่มี `:= '0'` → นาฬิกาไม่เคยตี
2. procedure ประกาศ `input` แต่ไม่ได้ใช้ — body เปรียบเทียบ `detected` กับ `expect`
3. `pass_cnt`/`fail_cnt` เป็น signal → รายงานค่าเก่า → false PASS
4. ไม่มี `std.env.stop` + ตรวจผิดจังหวะ (Moore ต้องหน่วงหลัง edge)

</details>

### แบบฝึกหัดที่ 2 — วัด delta cycle (ระดับ: ปานกลาง)

เขียน testbench ที่สร้าง chain ยาว N ชั้น (แต่ละชั้นเป็น process ที่ขับ signal ของชั้นถัดไป)
แล้วพิสูจน์ว่า **เวลาที่ใช้เป็น 0 ns** แต่จำนวน delta cycle ที่เกิดเท่ากับ N

คิดเรื่อง: ถ้าจะนับ delta cycle จริง ๆ จะใช้ `shared variable` ของ protected type
นับในแต่ละชั้นได้

### แบบฝึกหัดที่ 3 — สุ่มให้ reproducible (ระดับ: ปานกลาง)

เขียน TB ที่สุ่ม stimulus 1000 เวกเตอร์ แล้วพิมพ์ checksum
จากนั้นรันซ้ำ 3 ครั้งต้องได้ checksum เดิม แล้วลองเปลี่ยน seed
(`-gSEED_VALUE=...`) แล้ว checksum ต้องเปลี่ยน

### แบบฝึกหัดที่ 4 — เพิ่ม scoreboard ให้ UART (ระดับ: ยาก)

ต่อยอดจาก `ex07_uart_scoreboard.vhd`:
ให้ส่งเฟรม 20 ไบต์แบบ back-to-back (ไม่เว้นช่องว่างระหว่างเฟรม)
แล้วตรวจว่า monitor decode ได้ครบทุกไบต์และเรียงลำดับถูกต้อง

---

## 2.7.20 สรุป

### 2.7.20.1 สิ่งที่ต้องจำ 10 ข้อ

1. **Signal เปลี่ยนค่าท้าย delta cycle** — อ่านทันทีได้ค่าเก่า
2. **Variable เปลี่ยนค่าทันที** — ใช้นับ pass/fail ใน TB
3. **Delta cycle ไม่ใช่เวลา** — `now` ไม่เดินระหว่าง delta cycle
4. **`wait until` ต้องมี event** ไม่ใช่แค่เงื่อนไขเป็นจริง (ยืนยันตรงกัน 2 เครื่องมือ)
5. **นาฬิกาต้องมี initial value** ไม่งั้นไม่เคยตี
6. **Process ที่มี sensitivity list ห้ามมี wait statement**
7. **`'EVENT`/`rising_edge` ใช้กับ formal parameter ไม่ได้**
8. **`report` string ต้องเป็น ASCII**
9. **`HREAD` มาตรฐานรองรับแค่ `BIT_VECTOR`** และล้มเหลวถ้าบรรทัดไม่ใช่เลขฐาน 16
10. **Severity failure ≠ exit code เสมอ** — GHDL คืน 1, Questa คืน 0

### 2.7.20.2 ตารางอ้างอิงด่วน

| ต้องการ | ใช้ |
| --- | --- |
| ตรวจค่า DUT | `wait until rising_edge(clk); wait for 1 ns;` |
| เก็บผลตรวจ | `variable` + record |
| รอสัญญาณเปลี่ยน | `wait until <signal> = <ค่าใหม่>;` (รอการเปลี่ยนแปลง) |
| รอเวลา | `wait for <duration>;` |
| สุ่มแบบทำซ้ำได้ | `uniform(seed1, seed2, x)` |
| อ่าน/เขียนไฟล์ | `STD.TEXTIO` + generic สำหรับ path |
| เข้าถึง signal ภายใน DUT | external name (VHDL-2008) หรือ bind |
| สลับ implementation ของ DUT | configuration declaration |
| จบ simulation อย่างสะอาด | `std.env.finish` |
| รายงานผลให้ CI ตัดสิน | `report ... severity failure` + parse log (Questa) |

---

## อ้างอิง

1. IEEE Std 1076-2008 — *VHDL Language Reference Manual*, §4 (Elaboration), §11 (Wait statement), §16 (TEXTIO, MATH_REAL), §14.2 (External names)
2. IEEE Std 1076-1993 — *VHDL Language Reference Manual* (เปรียบเทียบพฤติกรรม `wait until` และ `hread`)
3. GHDL 5.0.1 (Dunoon) — source ของ `ieee/math_real.vhdl` (`procedure UNIFORM`) และ `std/v08/textio.vhdl` (`procedure HREAD`) ตรวจจาก `/usr/lib/ghdl/src/`
4. Siemens EDA — *ModelSim DE-64 / Questa Advanced Simulator 2026.1*, SystemVerilog & VHDL User Manual
5. `lab_code/day2_testbench/` — ชุดตัวอย่างที่รันจริงทั้งหมดในหัวข้อนี้ (GHDL 5.0.1 + ModelSim 2026.1)
6. `lab_code/day2_testbench/run_all.sh` — รันทุกตัวอย่างและพิมพ์ exit code
7. `lab_code/day2_testbench/run_modelsim_regression.ps1` — regression บน Questa พร้อมสรุปผล
8. `Manual_2_4_2_5_RTL_Guidelines_and_Testbench_DeepDive.md` — RTL guideline และแนวทาง testbench ระดับเมธอโดโลยี
9. `Manual_4_1_Verification_Methodology_DeepDive.md` — verification methodology
10. `Manual_4_2_Assertions_and_FunctionalCoverage_DeepDive.md` — assertion และ coverage

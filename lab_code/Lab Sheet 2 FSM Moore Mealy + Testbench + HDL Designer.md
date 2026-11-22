# Lab Sheet 2: FSM Moore/Mealy + Testbench + HDL Designer

Nov 22, 2026 · @Chumnarn Punyasai

เมื่อจบแลปนี้ ผู้เรียนจะมี FSM ตรวจจับลำดับ `101` แบบซ้อนทับ (overlapping) ทั้งแบบ Moore และ Mealy ที่ผ่าน self-checking testbench ครบ 39 กรณีต่อ FSM พร้อมอธิบายได้ว่าทำไม Mealy ตรวจพบเร็วกว่า Moore 1 clock

## ข้อมูลแลป

| หัวข้อ | รายละเอียด |
| --- | --- |
| เวลา | 2–2.5 ชั่วโมง |
| ระดับ | เริ่มต้น–กลาง (ต้องผ่าน Lab 1 มาก่อน) |
| เครื่องมือ | Questa หรือ ModelSim, HDL Designer (Siemens EDA), VS Code |
| มาตรฐานภาษา | VHDL-2008 (`std.env.stop`, conditional clock) |
| สิ่งที่ต้องส่ง | ไฟล์ `.vhd` ทั้งหมด, `run_lab2.do`, ภาพ waveform ที่วัด latency Moore กับ Mealy, ภาพ Transcript ที่มี `ALL TESTS PASSED`, ตารางบันทึกผลใน Part 6 |

### วัตถุประสงค์การเรียนรู้

1. แปลง state diagram เป็น VHDL แบบ 2-process (state register + combinational logic)
2. อธิบายความต่างของ Moore กับ Mealy ทั้งจำนวน state และจังหวะเวลาของ output
3. ออกแบบ transition ให้ตรวจจับแบบซ้อนทับได้ถูกต้อง
4. เขียน testbench ที่ป้อนข้อมูลตรงกับขอบ clock และตรวจ output ในจังหวะที่ถูกต้อง
5. สร้าง top-level จาก block diagram ใน HDL Designer แล้ว generate เป็น VHDL

### ลำดับงานในแลป

| Part | งาน | เวลาโดยประมาณ |
| --- | --- | --- |
| 0 | เตรียมโฟลเดอร์และไฟล์ | 5 นาที |
| 1 | Moore FSM | 20 นาที |
| 2 | Mealy FSM | 15 นาที |
| 3 | Testbench แบบ direct input สำหรับ Moore | 15 นาที |
| 4 | Self-checking testbench รวม | 25 นาที |
| 5 | Compile และ run ใน Questa (GUI + batch) | 15 นาที |
| 6 | วิเคราะห์ waveform Moore กับ Mealy | 20 นาที |
| 7 | HDL Designer: block diagram และ generate HDL | 30 นาที |

> 📝 **หมายเหตุ:** โค้ดทุกไฟล์ในเอกสารนี้ผ่านการ compile และ simulate ด้วย GHDL 4.1 (VHDL-2008) แล้ว ผลใน Questa ควรตรงกัน แต่ข้อความใน Transcript จะมีรูปแบบต่างออกไป

## Part 0: เตรียมโฟลเดอร์และไฟล์ (5 นาที)

1. เปิด PowerShell แล้วสร้างโฟลเดอร์งาน

```powershell
mkdir "E:\lab\VHDL(BOI)\lab2_work"
cd "E:\lab\VHDL(BOI)\lab2_work"
```

2. สร้างไฟล์ว่างตามตาราง

```powershell
ni seq_det_moore.vhd, seq_det_mealy.vhd, tb_seq_det_moore.vhd, tb_seq_det.vhd, tb_seq_det_full.vhd, run_lab2.do
```

| ไฟล์ | ใช้สำหรับ | ทำใน Part |
| --- | --- | --- |
| `seq_det_moore.vhd` | Moore FSM 4 states | 1 |
| `seq_det_mealy.vhd` | Mealy FSM 3 states | 2 |
| `tb_seq_det_moore.vhd` | Testbench แบบ direct input สำหรับ Moore | 3 |
| `tb_seq_det.vhd` | Self-checking testbench ทดสอบทั้งสอง FSM | 4 |
| `run_lab2.do` | Questa batch script | 5 |
| `seq_det_full.vhd` | Top-level ที่ HDL Designer generate | 7 |
| `tb_seq_det_full.vhd` | Testbench ของ top-level | 7 |

> ⚠️ **คำเตือน:** path ที่มีวงเล็บ `( )` ต้องครอบด้วยเครื่องหมายคำพูดใน PowerShell ถ้าเลือกได้ให้ใช้ path ที่ไม่มีช่องว่างและวงเล็บ โดยเฉพาะกับ HDL Designer

> ✅ **จุดตรวจสอบ:** `ls` แสดงไฟล์ 6 ไฟล์ (`seq_det_full.vhd` จะถูกสร้างโดย HDL Designer ใน Part 7)

## Part 1: Moore FSM ตรวจจับ `101` (20 นาที)

**เป้าหมาย:** เขียน FSM 4 states ที่ให้ `detected = '1'` ตลอด 1 clock หลังรับบิตที่ทำให้ 3 บิตล่าสุดเป็น `101` และตรวจแบบซ้อนทับได้ (เช่น `10101` พบ 2 ครั้ง)

### 1.1 ทำความเข้าใจ state

แต่ละ state จำว่า "ท้ายของข้อมูลที่เข้ามาตรงกับส่วนต้นของ `101` ยาวเท่าไร" Moore ต้องมี state แยกสำหรับ "พบแล้ว" (S3) เพราะ output ขึ้นกับ state อย่างเดียว

| State | ความหมาย (suffix ที่ตรง) | `detected` | `din = '0'` → | `din = '1'` → |
| --- | --- | --- | --- | --- |
| S0 | ยังไม่ตรงเลย (สถานะหลัง reset) | 0 | S0 | S1 |
| S1 | ตรง `1` | 0 | S2 | S1 |
| S2 | ตรง `10` | 0 | S0 | S3 |
| S3 | ตรง `101` (พบแล้ว) | **1** | **S2** | S1 |

&#91;embedded content: Moore FSM ตรวจจับ 101 · 4 states, overlap\]

เส้น S3 → S2 เมื่อ `din = '0'` คือส่วนที่ทำให้ตรวจแบบซ้อนทับได้

> ⚠️ **คำเตือน:** โค้ดแรกในคู่มือต้นฉบับให้ S3 + `din = '0'` → S0 ซึ่งทิ้ง `1` ตัวท้ายของ pattern เดิม ทำให้ `10101` พบแค่ครั้งเดียว Lab Sheet นี้ใช้ S3 + `din = '0'` → **S2** เพราะ `1` ท้าย + `0` ใหม่ = suffix `10`

### 1.2 ขั้นตอน

1. เปิดไฟล์ `seq_det_moore.vhd`
2. พิมพ์โค้ด

```vhdl
-- ============================================================
-- File: seq_det_moore.vhd
-- Lab 2 - Moore FSM: Sequence Detector "101" (overlapping)
-- detected = '1' เมื่ออยู่ใน S3 (ขึ้นกับ state อย่างเดียว)
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity seq_det_moore is
    port (
        clk      : in  std_logic;
        rst_n    : in  std_logic;   -- active-low synchronous reset
        din      : in  std_logic;   -- serial input 1 บิตต่อ clock
        detected : out std_logic    -- '1' เมื่อพบ "101"
    );
end entity seq_det_moore;

architecture rtl of seq_det_moore is
    type state_t is (S0, S1, S2, S3);      -- enumerated type
    signal state, next_state : state_t;
begin
    --------------------------------------------------------
    -- (1) State register: อัปเดตที่ขอบขาขึ้นเท่านั้น
    --------------------------------------------------------
    sync_proc : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= S0;
            else
                state <= next_state;
            end if;
        end if;
    end process sync_proc;

    --------------------------------------------------------
    -- (2) Output logic (Moore): ดูเฉพาะ state
    --------------------------------------------------------
    detected <= '1' when state = S3 else '0';

    --------------------------------------------------------
    -- (3) Next-state logic (combinational)
    --------------------------------------------------------
    comb_proc : process (state, din)
    begin
        next_state <= state;               -- default กัน latch
        case state is
            when S0 =>                     -- ยังไม่ตรง
                if din = '1' then next_state <= S1; else next_state <= S0; end if;
            when S1 =>                     -- ตรง "1"
                if din = '0' then next_state <= S2; else next_state <= S1; end if;
            when S2 =>                     -- ตรง "10"
                if din = '1' then next_state <= S3; else next_state <= S0; end if;
            when S3 =>                     -- ตรง "101"
                if din = '1' then
                    next_state <= S1;      -- "1011" → suffix "1"
                else
                    next_state <= S2;      -- "1010" → suffix "10" (overlap)
                end if;
        end case;
    end process comb_proc;
end architecture rtl;
```

3. บันทึกไฟล์

### 1.3 จุดที่ควรสังเกต

- โครงสร้าง 2-process: process ที่มี clock เก็บ state อีก process คำนวณ next state แบบ combinational
- `type state_t is (S0, S1, S2, S3);` ให้ tool เลือก encoding เอง (4 states = 2 FF แบบ binary) และใน Wave จะแสดงชื่อ state ให้อ่านง่าย
- Synchronous reset: `rst_n` ต้องเป็น `'0'` ค้างผ่านขอบขาขึ้นอย่างน้อย 1 ครั้ง จึงจะ reset
- `case state` ครบทุก state จึงไม่ต้องมี `when others` (enumerated type มีแค่ 4 ค่า)
- คู่มือต้นฉบับเขียน `detected <= '1'` ไว้ใน `when S3` ของ comb\_proc พร้อม default `detected <= '0'` ได้ผลเหมือนกัน แต่แยกเป็น concurrent statement ทำให้เห็นชัดว่า output ไม่ขึ้นกับ `din`

> ✅ **จุดตรวจสอบ:** บรรทัด `when S3` ไป S2 เมื่อ `din = '0'` และ `detected` ถูก assign จากที่เดียว

## Part 2: Mealy FSM ตรวจจับ `101` (15 นาที)

**เป้าหมาย:** เขียน FSM 3 states ที่ output ขึ้นกับ state **และ** input: `detected = '1'` ทันทีที่อยู่ใน S2 และ `din = '1'` โดยไม่ต้องรอขอบ clock

### 2.1 ทำความเข้าใจ state

บนเส้น transition ของ Mealy เขียนเป็น `input/output` เช่น `1/1` = เมื่อ `din = '1'` ให้ `detected = '1'` แล้วไป state ปลายทาง

| State | ความหมาย | `din = '0'` | `din = '1'` |
| --- | --- | --- | --- |
| S0 | ยังไม่ตรง | → S0, out 0 | → S1, out 0 |
| S1 | ตรง `1` | → S2, out 0 | → S1, out 0 |
| S2 | ตรง `10` | → S0, out 0 | → S1, **out 1** |

&#91;embedded content: Mealy FSM ตรวจจับ 101 · 3 states, overlap\]

เส้นสีเน้นคือเส้นเดียวที่ output เป็น 1 และกลับไป S1 (ไม่ใช่ S0) เพื่อเก็บ `1` ตัวท้ายไว้ตรวจแบบซ้อนทับ

### 2.2 ขั้นตอน

1. เปิดไฟล์ `seq_det_mealy.vhd`
2. พิมพ์โค้ด

```vhdl
-- ============================================================
-- File: seq_det_mealy.vhd
-- Lab 2 - Mealy FSM: Sequence Detector "101" (overlapping)
-- detected = '1' เมื่อ state = S2 และ din = '1' (combinational)
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity seq_det_mealy is
    port (
        clk      : in  std_logic;
        rst_n    : in  std_logic;
        din      : in  std_logic;
        detected : out std_logic
    );
end entity seq_det_mealy;

architecture rtl of seq_det_mealy is
    -- ไม่ต้องมี S3: output ออกบน transition S2 --1/1--> S1
    type state_t is (S0, S1, S2);
    signal state, next_state : state_t;
begin
    --------------------------------------------------------
    -- (1) State register
    --------------------------------------------------------
    sync_proc : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= S0;
            else
                state <= next_state;
            end if;
        end if;
    end process sync_proc;

    --------------------------------------------------------
    -- (2) Next-state + output (combinational, Mealy)
    --------------------------------------------------------
    comb_proc : process (state, din)
    begin
        next_state <= state;     -- default
        detected   <= '0';       -- default: ไม่พบ
        case state is
            when S0 =>
                if din = '1' then next_state <= S1; else next_state <= S0; end if;
            when S1 =>
                if din = '0' then next_state <= S2; else next_state <= S1; end if;
            when S2 =>
                if din = '1' then
                    next_state <= S1;   -- "101" → suffix "1" (overlap)
                    detected   <= '1';  -- พบทันที (Mealy)
                else
                    next_state <= S0;
                end if;
        end case;
    end process comb_proc;
end architecture rtl;
```

3. บันทึกไฟล์

### 2.3 เปรียบเทียบกับ Moore

| หัวข้อ | Moore | Mealy |
| --- | --- | --- |
| จำนวน state | 4 (S0–S3) | 3 (S0–S2) |
| จำนวน flip-flop (binary encoding) | 2 | 2 |
| Output ขึ้นกับ | state อย่างเดียว | state + `din` |
| `detected` ขึ้นเมื่อ | หลังขอบขาขึ้นที่รับบิต `1` ตัวสุดท้าย | ทันทีที่ `din` เป็น `1` ขณะอยู่ S2 (ก่อนขอบขาขึ้น) |
| ความกว้างพัลส์ | 1 clock เต็ม | เท่าที่ `din = '1'` ใน S2 (อาจสั้นกว่า 1 clock) |
| Glitch จาก input | ไม่มี | มีได้ ถ้า `din` สั่นก่อนขอบ clock |

> ✅ **จุดตรวจสอบ:** comb\_proc มี default ทั้ง `next_state` และ `detected` และมีจุดเดียวที่ตั้ง `detected <= '1'`

## Part 3: Testbench แบบ Direct Input สำหรับ Moore (15 นาที)

**เป้าหมาย:** ป้อน `10101` ทีละบิต แล้วยืนยันว่า Moore ให้พัลส์ `detected` 2 ครั้ง ที่ 35–45 ns และ 55–65 ns

### 3.1 หลักการจัดจังหวะเวลา

- Clock period 10 ns เริ่มที่ `'0'` จึงมีขอบขาขึ้นที่ 5, 15, 25, ... ns และขอบขาลงที่ 10, 20, 30, ... ns
- เปลี่ยน `din` ที่**ขอบขาลง** เพื่อให้ค่านิ่งครึ่ง clock ก่อน FSM รับค่าที่**ขอบขาขึ้น** ไม่เกิด race ระหว่าง testbench กับ DUT
- ตรวจ output **หลังขอบขาขึ้น 1 ns** เพื่อให้ state และ `detected` อัปเดตครบทุก delta cycle ก่อน
- คง `rst_n = '0'` ผ่านขอบขาขึ้นแรก (5 ns) เพราะ reset เป็นแบบ synchronous

### 3.2 ขั้นตอน

1. เปิดไฟล์ `tb_seq_det_moore.vhd`
2. พิมพ์โค้ด

```vhdl
-- ============================================================
-- File: tb_seq_det_moore.vhd
-- Lab 2 - Direct-input testbench: ป้อน 10101 แล้วตรวจ detected
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_seq_det_moore is
end entity tb_seq_det_moore;

architecture sim of tb_seq_det_moore is
    constant CLK_PERIOD : time := 10 ns;

    signal clk      : std_logic := '0';
    signal rst_n    : std_logic := '0';   -- เริ่มใน reset
    signal din      : std_logic := '0';
    signal detected : std_logic;
    signal done     : boolean   := false;
begin
    dut : entity work.seq_det_moore(rtl)
        port map (clk => clk, rst_n => rst_n, din => din, detected => detected);

    -- Clock 10 ns: ขอบขาขึ้นที่ 5, 15, 25, ... ns หยุดเมื่อ done = true
    clk <= not clk after CLK_PERIOD / 2 when not done;

    stimulus : process
        -- ป้อน 1 บิตที่ขอบขาลง แล้วตรวจ detected หลังขอบขาขึ้น 1 ns
        procedure send_bit(b : std_logic; exp : std_logic; msg : string) is
        begin
            wait until falling_edge(clk);
            rst_n <= '1';
            din   <= b;
            wait until rising_edge(clk);
            wait for 1 ns;
            assert detected = exp
                report msg & ": got " & std_logic'image(detected) &
                       " exp " & std_logic'image(exp)
                severity failure;
        end procedure;
    begin
        -- Reset ถูก sample ที่ขอบขาขึ้นแรก (5 ns)
        wait until rising_edge(clk);
        wait for 1 ns;
        assert detected = '0' report "Reset check failed" severity failure;

        send_bit('1', '0', "Bit 1 (15 ns)");
        send_bit('0', '0', "Bit 2 (25 ns)");
        send_bit('1', '1', "Bit 3 (35 ns): first 101");
        send_bit('0', '0', "Bit 4 (45 ns): pulse must clear");
        send_bit('1', '1', "Bit 5 (55 ns): overlapping 101");
        send_bit('0', '0', "Extra (65 ns): pulse must clear");

        report "PASS: 10101 produced two overlapping detections" severity note;
        done <= true;
        wait;
    end process stimulus;
end architecture sim;
```

3. บันทึกไฟล์
4. รันใน Transcript ของ Questa (เปลี่ยนโฟลเดอร์ก่อนด้วย **File → Change Directory**)

```tcl
vlib work
vcom -2008 seq_det_moore.vhd tb_seq_det_moore.vhd
vsim -voptargs=+acc work.tb_seq_det_moore
add wave sim:/tb_seq_det_moore/*
add wave sim:/tb_seq_det_moore/dut/state
run -all
```

### 3.3 ผลที่คาดหวัง

| ขอบขาขึ้น | `rst_n` | `din` | State หลังขอบ | `detected` |
| --- | --- | --- | --- | --- |
| 5 ns | 0 | 0 | S0 (reset) | 0 |
| 15 ns | 1 | 1 | S1 | 0 |
| 25 ns | 1 | 0 | S2 | 0 |
| 35 ns | 1 | 1 | S3 | **1** |
| 45 ns | 1 | 0 | S2 | 0 |
| 55 ns | 1 | 1 | S3 | **1** |
| 65 ns | 1 | 0 | S2 | 0 |

Transcript ต้องแสดง `PASS: 10101 produced two overlapping detections` ที่ 66 ns และ Wave ต้องเห็นพัลส์ `detected` 2 ช่วง คือ 35–45 ns และ 55–65 ns ตรงกับ `101` ที่บิต 1–3 และ 3–5 (ใช้บิตที่ 3 ร่วมกัน)

> 💡 **เคล็ดลับ:** ทดลองเปลี่ยน `when S3` ให้กลับไป S0 เมื่อ `din = '0'` (แบบในคู่มือต้นฉบับ) แล้วรันซ้ำ จะได้ `** Failure: Bit 5 (55 ns): overlapping 101: got '0' exp '1'` ที่ 56 ns เป็นตัวอย่างว่า testbench จับ bug ได้ ทดลองเสร็จแล้วให้แก้กลับ

> ✅ **จุดตรวจสอบ:** Wave เห็น state เป็น S0 → S1 → S2 → S3 → S2 → S3 → S2 ตรงกับตาราง

## Part 4: Self-Checking Testbench รวม Moore + Mealy (25 นาที)

**เป้าหมาย:** ป้อนลำดับบิตเดียวกันให้ FSM ทั้งสองตัว แล้วตรวจทุกบิตอัตโนมัติ ได้ผล `Moore: PASS=39 FAIL=0` และ `Mealy: PASS=39 FAIL=0`

### 4.1 แนวคิด: ค่าคาดหวังเดียวกัน แต่เวลาตรวจต่างกัน

ทั้งสอง FSM ตอบ `1` เมื่อ 3 บิตล่าสุดเป็น `101` ต่างกันแค่**ตอนที่ output ขึ้น** testbench จึงตรวจแต่ละบิต 2 ครั้ง

1. ขอบขาลง: ตั้ง `din`
2. หลังตั้ง `din` 1 ns: ตรวจ **Mealy** (output ตอบสนอง `din` ทันที)
3. หลังขอบขาขึ้น 1 ns: ตรวจ **Moore** (output เปลี่ยนหลัง state เปลี่ยน)

### 4.2 กรณีทดสอบ

ทุก test เริ่มจาก reset เพื่อให้ค่าคาดหวังไม่ขึ้นกับ test ก่อนหน้า คอลัมน์ "คาดหวัง" เป็น `1` ที่บิตซึ่งทำให้ 3 บิตล่าสุดเป็น `101`

| Test | บิตที่ป้อน | คาดหวัง | สิ่งที่ทดสอบ |
| --- | --- | --- | --- |
| T1 | `101` | `001` | pattern พื้นฐาน |
| T2 | `1010` | `0010` | output กลับเป็น 0 หลังพบ |
| T3 | `10101` | `00101` | overlap: บิตที่ 3 ใช้ร่วมกัน |
| T4 | `0000` | `0000` | ไม่มี pattern |
| T5 | `11010` | `00010` | `1` ซ้ำก่อน pattern (ค้าง S1) |
| T6 | `00010100` | `00000100` | pattern กลางข้อมูล |
| T7 | `1101101` | `0001001` | พบ 2 ครั้งแบบไม่ซ้อนทับ |
| T8 | `10`, reset, `1` | `00`, `0` | reset ล้าง `10` ที่รับมาแล้ว |

รวม 39 บิต = 39 การตรวจต่อ FSM ใช้เวลา simulation 486 ns

### 4.3 ขั้นตอน

1. เปิดไฟล์ `tb_seq_det.vhd`
2. พิมพ์โค้ด

```vhdl
-- ============================================================
-- File: tb_seq_det.vhd
-- Lab 2 - Self-checking testbench for Moore and Mealy "101"
-- ทุกบิต: ตรวจ Mealy ก่อนขอบขาขึ้น, ตรวจ Moore หลังขอบขาขึ้น
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_seq_det is
end entity tb_seq_det;

architecture sim of tb_seq_det is
    constant CLK_PERIOD : time := 10 ns;

    signal clk   : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal din   : std_logic := '0';
    signal detected_moore, detected_mealy : std_logic;
    signal done  : boolean := false;
begin
    -- Clock 10 ns หยุดเมื่อ done = true
    clk <= not clk after CLK_PERIOD / 2 when not done;

    -- DUT ทั้งสองตัวรับ din เส้นเดียวกัน
    u_moore : entity work.seq_det_moore(rtl)
        port map (clk => clk, rst_n => rst_n, din => din, detected => detected_moore);

    u_mealy : entity work.seq_det_mealy(rtl)
        port map (clk => clk, rst_n => rst_n, din => din, detected => detected_mealy);

    stim : process
        -- ใช้ variable (อัปเดตทันที) ไม่ใช่ signal (อัปเดตหลัง delta)
        variable pass_moore, fail_moore : integer := 0;
        variable pass_mealy, fail_mealy : integer := 0;

        -- เทียบค่าแล้วนับ pass/fail โดยไม่หยุด simulation
        procedure check(name : string; tag : string; got, exp : std_logic;
                        variable pass_cnt, fail_cnt : inout integer) is
        begin
            if got = exp then
                pass_cnt := pass_cnt + 1;
            else
                fail_cnt := fail_cnt + 1;
                report name & " FAIL [" & tag & "] got=" & std_logic'image(got) &
                       " exp=" & std_logic'image(exp) severity error;
            end if;
        end procedure;

        -- กด reset ค้าง 1 ขอบขาขึ้น แล้วปล่อยที่ขอบขาลง
        procedure do_reset is
        begin
            wait until falling_edge(clk);
            rst_n <= '0';
            din   <= '0';
            wait until rising_edge(clk);
            wait until falling_edge(clk);
            rst_n <= '1';
            assert detected_moore = '0' and detected_mealy = '0'
                report "Reset FAIL" severity failure;
        end procedure;

        -- ป้อนบิตทีละตัว: exp(i) = '1' เมื่อ 3 บิตล่าสุดเป็น "101"
        procedure run_seq(tag : string; bits : string; exp : string) is
            variable b, e : std_logic;
        begin
            for i in bits'range loop
                if bits(i) = '1' then b := '1'; else b := '0'; end if;
                if exp(i)  = '1' then e := '1'; else e := '0'; end if;
                if i /= bits'left then
                    wait until falling_edge(clk);
                end if;
                din <= b;                  -- ป้อนบิตที่ขอบขาลง
                wait for 1 ns;             -- Mealy: ดูทันทีก่อนขอบขาขึ้น
                check("MEALY", tag & " bit " & integer'image(i), detected_mealy, e,
                      pass_mealy, fail_mealy);
                wait until rising_edge(clk);
                wait for 1 ns;             -- Moore: ดูหลังขอบขาขึ้น
                check("MOORE", tag & " bit " & integer'image(i), detected_moore, e,
                      pass_moore, fail_moore);
            end loop;
        end procedure;
    begin
        do_reset; run_seq("T1 101",      "101",      "001");
        do_reset; run_seq("T2 1010",     "1010",     "0010");
        do_reset; run_seq("T3 10101",    "10101",    "00101");
        do_reset; run_seq("T4 0000",     "0000",     "0000");
        do_reset; run_seq("T5 11010",    "11010",    "00010");
        do_reset; run_seq("T6 00010100", "00010100", "00000100");
        do_reset; run_seq("T7 1101101",  "1101101",  "0001001");
        -- T8: reset กลางทาง ต้องลืม "10" ที่รับมาแล้ว
        do_reset; run_seq("T8a 10",      "10",       "00");
        do_reset; run_seq("T8b 1",       "1",        "0");

        report "============================================";
        report "Moore: PASS=" & integer'image(pass_moore) & " FAIL=" & integer'image(fail_moore);
        report "Mealy: PASS=" & integer'image(pass_mealy) & " FAIL=" & integer'image(fail_mealy);
        report "============================================";
        if fail_moore = 0 and fail_mealy = 0 then
            report "Lab 2 ALL TESTS PASSED" severity note;
        else
            report "Lab 2 SOME TESTS FAILED" severity failure;
        end if;
        done <= true;
        std.env.stop;
    end process;
end architecture sim;
```

3. บันทึกไฟล์

### 4.4 จุดที่แก้จาก testbench ในคู่มือต้นฉบับ

เมื่อรัน testbench ต้นฉบับกับ FSM ต้นฉบับ ได้ `Moore: PASS=3 FAIL=2` และ `Mealy: PASS=2 FAIL=3` ไม่ใช่ `PASS=8` ตามที่คู่มือเขียนไว้ สาเหตุมีดังนี้

| ปัญหาในต้นฉบับ | ผล | วิธีแก้ใน Lab Sheet |
| --- | --- | --- |
| ตรวจ Mealy หลังขอบขาขึ้น ซึ่ง state เปลี่ยนจาก S2 ไป S1 แล้ว | Mealy ได้ `0` ทุกครั้งที่คาดว่า `1` | ตรวจ Mealy ก่อนขอบขาขึ้น |
| ค่าคาดหวังของ `11010` เป็น `1` | บิตสุดท้าย `0` ทำให้ 3 บิตล่าสุดเป็น `010` คำตอบที่ถูกคือ `0` | ตรวจทุกบิตด้วยสตริงคาดหวัง |
| ตัวนับเป็น `signal` | ค่าอัปเดตหลัง delta cycle การนับครั้งสุดท้ายหายไปจาก report (รวมได้ 5 จาก 6 การตรวจ) | ใช้ `variable` |
| ตรวจแค่บิตสุดท้ายของแต่ละ pattern และ state ต่อเนื่องจาก test ก่อน | ค่าคาดหวังขึ้นกับบิตที่มาก่อน อ่านยาก | reset ก่อนทุก test และตรวจทุกบิต |
| ปล่อย reset ที่ 25 ns ตรงกับขอบขาขึ้น | ผลขึ้นกับลำดับ delta cycle อ่านยาก | ปล่อย reset และตั้ง `din` ที่ขอบขาลง |
| ใช้ `bit` เป็นชื่อ parameter | `bit` เป็นชื่อ type ใน `STD.STANDARD` ทำให้สับสน | ตั้งชื่อ `b` |
| ใช้ `din_moore` และ `din_mealy` แยกกัน | ไม่จำเป็น เพราะป้อนค่าเดียวกันเสมอ | ใช้ `din` เส้นเดียว |

> ✅ **จุดตรวจสอบ:** ตัวนับทั้ง 4 ตัวเป็น `variable` และสตริง `bits` กับ `exp` ของแต่ละ test ยาวเท่ากัน

## Part 5: Compile และ Run ใน Questa (15 นาที)

**เป้าหมาย:** รัน `tb_seq_det` แล้วเห็น `Lab 2 ALL TESTS PASSED` ทั้งแบบ GUI และ batch

### 5.1 แบบ GUI

1. เปิด Questa → **File → New → Project**
2. กรอก **Project Name** = `lab2_fsm`, **Project Location** = โฟลเดอร์ `lab2_work`, **Default Library Name** = `work` แล้วกด **OK**
3. เลือก **Add Existing File** แล้วเพิ่ม `seq_det_moore.vhd`, `seq_det_mealy.vhd`, `tb_seq_det_moore.vhd`, `tb_seq_det.vhd`
4. เลือกทุกไฟล์ → คลิกขวา → **Properties... → VHDL** → เลือก **Use 1076-2008** → **OK**
5. เลือก **Compile → Compile Order... → Auto Generate** แล้ว **Compile → Compile All**
6. ดู Transcript ต้องมี `4 compiles, 0 failed with no errors.`
7. พิมพ์ใน Transcript เพื่อเริ่ม simulation แบบมองเห็น signal ภายใน

```tcl
vsim -voptargs=+acc work.tb_seq_det
add wave sim:/tb_seq_det/clk sim:/tb_seq_det/rst_n sim:/tb_seq_det/din
add wave sim:/tb_seq_det/detected_mealy sim:/tb_seq_det/detected_moore
add wave sim:/tb_seq_det/u_mealy/state sim:/tb_seq_det/u_moore/state
run -all
```

8. ดู Transcript ตอนท้าย

```text
# ** Note: ============================================
# ** Note: Moore: PASS=39 FAIL=0
# ** Note: Mealy: PASS=39 FAIL=0
# ** Note: ============================================
# ** Note: Lab 2 ALL TESTS PASSED
```

> ⚠️ **คำเตือน:** คู่มือต้นฉบับใช้ `run 500 ns` แต่ใน Lab Sheet นี้ใช้ `run -all` เพราะ `std.env.stop` หยุดเองที่ 486 ns ถ้าเพิ่ม test ภายหลังก็ไม่ต้องแก้เวลาในคำสั่ง run

### 5.2 แบบ Batch

1. เปิดไฟล์ `run_lab2.do` แล้วพิมพ์

```tcl
# ============================================================
# run_lab2.do - Questa batch script for Lab 2
# PowerShell: vsim -c -do run_lab2.do
# ============================================================
onerror {quit -f -code 1}
onbreak {resume}

vlib work
vcom -2008 -work work seq_det_moore.vhd
vcom -2008 -work work seq_det_mealy.vhd
vcom -2008 -work work tb_seq_det_moore.vhd
vcom -2008 -work work tb_seq_det.vhd

puts ""
puts "============================================="
puts "Lab 2: FSM Moore/Mealy Sequence Detector"
puts "============================================="

# Test 1: direct-input testbench (Moore)
vsim -voptargs=+acc work.tb_seq_det_moore
run -all
quit -sim

# Test 2: self-checking testbench (Moore + Mealy)
vsim -voptargs=+acc work.tb_seq_det
run -all
quit -f
```

2. รันใน PowerShell

```powershell
cd "E:\lab\VHDL(BOI)\lab2_work"
vsim -c -do run_lab2.do
```

3. ตรวจว่ามีทั้ง `PASS: 10101 produced two overlapping detections` และ `Lab 2 ALL TESTS PASSED`

> 📝 **หมายเหตุ:** `onbreak {resume}` ทำให้ script ทำงานต่อหลัง `std.env.stop` ส่วน `onerror` ออกทันทีเมื่อ compile พลาด ต้นฉบับใช้ `vsim -do "run 500 ns; quit -f" ...` ซ้อนใน do file เวอร์ชันนี้แยกเป็นคำสั่งทีละบรรทัดและรันครบทั้ง 2 testbench

> ✅ **จุดตรวจสอบ:** Transcript แสดง `PASS=39 FAIL=0` ทั้ง Moore และ Mealy เก็บภาพไว้ส่ง

## Part 6: วิเคราะห์ Waveform: Moore กับ Mealy (20 นาที)

**เป้าหมาย:** วัดจาก Wave ว่า Mealy ตอบสนองทันทีที่บิตสุดท้ายของ `101` มาถึง ส่วน Moore ต้องรอขอบขาขึ้นถัดไป

### 6.1 ช่วงที่ต้องดู: Test T1 (`101`)

ใน `tb_seq_det` reset ถูก sample ที่ 15 ns ปล่อยที่ 20 ns แล้วป้อนบิตที่ขอบขาลง 20, 30, 40 ns

&#91;embedded content: Timing diagram ของ T1 · 0–60 ns\]

| เวลา | เหตุการณ์ | Mealy state / `detected_mealy` | Moore state / `detected_moore` |
| --- | --- | --- | --- |
| 20 ns | ขอบขาลง: `rst_n` = 1, `din` = 1 | S0 / 0 | S0 / 0 |
| 25 ns | ขอบขาขึ้น: รับบิต `1` | S1 / 0 | S1 / 0 |
| 30 ns | ขอบขาลง: `din` = 0 | S1 / 0 | S1 / 0 |
| 35 ns | ขอบขาขึ้น: รับบิต `0` | S2 / 0 | S2 / 0 |
| **40 ns** | ขอบขาลง: `din` = 1 | S2 / **1** | S2 / 0 |
| **45 ns** | ขอบขาขึ้น: รับบิต `1` | S1 / 0 | S3 / **1** |
| 55 ns | ขอบขาขึ้นถัดไป (reset ของ T2) | S0 / 0 | S0 / 0 |

พัลส์ Mealy อยู่ช่วง 40–45 ns (กว้างครึ่ง clock เพราะ testbench ตั้ง `din` ที่ขอบขาลง) ส่วนพัลส์ Moore อยู่ช่วง 45–55 ns (กว้าง 1 clock เต็ม) Moore จึงตอบช้ากว่า Mealy จนถึงขอบขาขึ้นที่รับบิตนั้น

> 📝 **หมายเหตุ:** ถ้าดูเป็น clock cycle: Mealy ให้ output ใน cycle เดียวกับที่บิตสุดท้ายอยู่บน `din` ส่วน Moore ให้ output ใน cycle ถัดไป นี่คือความหมายของ "Moore ช้ากว่า 1 cycle" ระยะเวลาเป็น ns ที่วัดได้ขึ้นกับว่า `din` เปลี่ยนตอนไหนใน cycle

### 6.2 วัดด้วย cursor

1. ใน Wave คลิกขวาที่ `u_mealy/state` และ `u_moore/state` แล้วดูว่าแสดงชื่อ state (S0, S1, ...)
2. กด **Zoom In** จนเห็นช่วง 0–60 ns
3. คลิกในพื้นที่ wave ที่ขอบขาขึ้นของ `detected_mealy` เพื่อวาง Cursor 1 (กดปุ่ม **Find Next Transition** ช่วยให้ cursor ไปติดขอบได้พอดี)
4. เพิ่ม cursor ที่สองด้วยปุ่ม **Insert Cursor** แล้ววางที่ขอบขาขึ้นของ `detected_moore`
5. อ่านระยะห่างระหว่าง cursor ที่แถบด้านล่างของ Wave
6. ดู internal signal เพิ่ม: คลิกขวา `u_moore` ในแท็บ **sim** → **Add Wave** จะได้ `next_state` ด้วย แล้วพิมพ์ `restart -f` และ `run -all`

### 6.3 บันทึกผล

| รายการ | ค่าที่คาดหวัง | ค่าที่วัดได้ |
| --- | --- | --- |
| เวลาที่ `detected_mealy` ขึ้น | 40 ns |  |
| เวลาที่ `detected_mealy` ลง | 45 ns |  |
| เวลาที่ `detected_moore` ขึ้น | 45 ns |  |
| เวลาที่ `detected_moore` ลง | 55 ns |  |
| ระยะห่าง Moore ขึ้น − Mealy ขึ้น | 5 ns |  |
| จำนวนพัลส์ `detected_moore` ใน T3 (`10101`) | 2 |  |
| จำนวนพัลส์ `detected_mealy` ใน T7 (`1101101`) | 2 |  |

- [ ] Mealy ขึ้นก่อน Moore ทุกครั้งที่พบ pattern
- [ ] พัลส์ Moore กว้าง 10 ns (1 clock) ทุกครั้ง
- [ ] ไม่มี `'X'` หรือ `'U'` บน `detected_moore`, `detected_mealy` หลัง reset ครั้งแรก

## Part 7: HDL Designer — Block Diagram → VHDL (30 นาที)

**เป้าหมาย:** สร้าง top-level `seq_det_full` เป็น block diagram ที่ต่อ `seq_det_moore` กับ `seq_det_mealy` เข้ากับ `clk`, `rst_n`, `din` ชุดเดียวกัน แล้ว generate เป็น VHDL ที่ simulate ผ่าน `seq_det_full PASSED: 14 checks`

> 📝 **หมายเหตุ:** คู่มือต้นฉบับให้วาง gate อย่าง `DFFRE`, `AND2`, `MUX2` จากไลบรารี `STD` แต่ HDL Designer ไม่มีไลบรารี gate ชุดนี้ให้โดยปริยาย และคู่มือไม่ได้ให้สมการ next-state ระดับ gate Lab Sheet นี้จึงใช้ block diagram แบบ hierarchical ที่นำโมดูลจาก Part 1–2 มาต่อกัน ส่วนการออกแบบระดับ gate ย้ายไปเป็น Challenge 5

> ⚠️ **คำเตือน:** ชื่อเมนูของ HDL Designer ต่างกันตามเวอร์ชัน ถ้าหาเมนูไม่พบให้ดูเมนูคลิกขวาใน Design Manager หรือถามผู้สอน ผลลัพธ์ที่ต้องได้คือ entity `seq_det_full` ตามโค้ดใน 7.6

### 7.1 สร้าง Library

1. เปิด **HDL Designer** จาก Start Menu จะเห็นหน้าต่าง **Design Manager**
2. เลือก **File → New → Library**
3. ตั้งชื่อ library = `lab2_lib`
4. กำหนดตำแหน่ง = `E:\lab\VHDL(BOI)\lab2_work\hdl_designer`
5. กด **Finish**

### 7.2 นำโมดูล VHDL เดิมเข้า library

1. เลือก library `lab2_lib` ใน Design Manager
2. เลือก **File → Add → Existing Design...** (บางเวอร์ชันเรียก **HDL Import**)
3. เลือก `seq_det_moore.vhd` และ `seq_det_mealy.vhd`
4. กด **Finish** แล้วตรวจว่ามี design unit `seq_det_moore` และ `seq_det_mealy` ใน library

### 7.3 สร้าง Block Diagram

1. เลือก **File → New → Design Content → Graphical View → Block Diagram**
2. ตั้งชื่อ design unit = `seq_det_full` และ view = `struct` แล้วกด **Finish**
3. ลาก `seq_det_moore` จาก Design Manager มาวางบน diagram (instance `U_0`)
4. ลาก `seq_det_mealy` มาวางใต้กัน (instance `U_1`)

### 7.4 เพิ่ม Port และเชื่อมสาย

1. เลือก **Add → Port** แล้ววาง input port 3 ตัว: `clk`, `rst_n`, `din`
2. วาง output port 2 ตัว: `detected_moore`, `detected_mealy`
3. ใช้ **Add → Signal** (เส้น net) เชื่อม `clk`, `rst_n`, `din` เข้าทั้ง `U_0` และ `U_1`
4. เชื่อม `U_0/detected` → `detected_moore` และ `U_1/detected` → `detected_mealy`
5. ตั้งชนิดของทุกเส้นเป็น `std_logic` (ดับเบิลคลิกเส้นเพื่อเปิด properties)
6. บันทึก diagram

&#91;Screenshot: block diagram ที่มี U\_0 และ U\_1 รับ clk/rst\_n/din ร่วมกัน และมี output 2 เส้น\]

> ⚠️ **คำเตือน:** output ของ `U_0` กับ `U_1` ต้องไปคนละเส้น ถ้าต่อเข้าเส้นเดียวกันจะได้ error multiple drivers และค่า `'X'` ใน simulation

### 7.5 Generate HDL

1. เลือก `seq_det_full` ใน Design Manager
2. กดปุ่ม **Generate** (หรือเมนู **Tasks → Generate**) เลือก **Through Components**
3. ดู Log ว่าไม่มี error
4. คัดลอกหรือ export ไฟล์ VHDL ที่ได้มาไว้ใน `lab2_work` ชื่อ `seq_det_full.vhd`

### 7.6 ตรวจโค้ดที่ generate

โค้ดจาก HDL Designer จะมี header comment และอาจใช้ component declaration แต่ต้อง**เทียบเท่า**กับโค้ดนี้ (ถ้าไม่มี HDL Designer ให้พิมพ์โค้ดนี้เองแล้วทำ 7.7 ต่อ)

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity seq_det_full is
    port (
        clk            : in  std_logic;
        rst_n          : in  std_logic;
        din            : in  std_logic;
        detected_moore : out std_logic;
        detected_mealy : out std_logic
    );
end entity seq_det_full;

architecture struct of seq_det_full is
begin
    U_0 : entity work.seq_det_moore(rtl)
        port map (clk => clk, rst_n => rst_n, din => din, detected => detected_moore);

    U_1 : entity work.seq_det_mealy(rtl)
        port map (clk => clk, rst_n => rst_n, din => din, detected => detected_mealy);
end architecture struct;
```

ตรวจ 3 จุดนี้ในไฟล์ที่ generate

- [ ] entity มี port 5 ตัว ทิศทางและชนิดตรงตามนี้
- [ ] มี instance 2 ตัว ชี้ไปที่ `seq_det_moore` และ `seq_det_mealy`
- [ ] ใน port map ขา `detected` ของแต่ละ instance ไปคนละ output

### 7.7 Simulate top-level

1. เปิดไฟล์ `tb_seq_det_full.vhd` แล้วพิมพ์

```vhdl
-- ============================================================
-- File: tb_seq_det_full.vhd
-- Lab 2 - Testbench ของ top-level ที่ HDL Designer generate
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_seq_det_full is
end entity tb_seq_det_full;

architecture sim of tb_seq_det_full is
    constant CLK_PERIOD : time := 10 ns;
    constant BITS : string := "1101101";   -- พบ 101 ที่บิต 2-4 และ 5-7
    constant EXP  : string := "0001001";

    signal clk, rst_n, din : std_logic := '0';
    signal det_moore, det_mealy : std_logic;
    signal done : boolean := false;
begin
    clk <= not clk after CLK_PERIOD / 2 when not done;

    u_dut : entity work.seq_det_full(struct)
        port map (clk => clk, rst_n => rst_n, din => din,
                  detected_moore => det_moore, detected_mealy => det_mealy);

    stim : process
        variable e : std_logic;
        variable errors : integer := 0;
    begin
        wait until rising_edge(clk);          -- reset ที่ 5 ns
        wait until falling_edge(clk);
        rst_n <= '1';
        for i in BITS'range loop
            if BITS(i) = '1' then din <= '1'; else din <= '0'; end if;
            if EXP(i)  = '1' then e := '1';   else e := '0';   end if;
            wait for 1 ns;
            if det_mealy /= e then errors := errors + 1;
                report "MEALY mismatch at bit " & integer'image(i) severity error; end if;
            wait until rising_edge(clk);
            wait for 1 ns;
            if det_moore /= e then errors := errors + 1;
                report "MOORE mismatch at bit " & integer'image(i) severity error; end if;
            wait until falling_edge(clk);
        end loop;
        assert errors = 0 report "seq_det_full FAILED" severity failure;
        report "seq_det_full PASSED: " & integer'image(2 * BITS'length) & " checks";
        done <= true;
        std.env.stop;
    end process;
end architecture sim;
```

2. รันใน Transcript ของ Questa

```tcl
vcom -2008 seq_det_moore.vhd seq_det_mealy.vhd seq_det_full.vhd tb_seq_det_full.vhd
vsim -voptargs=+acc work.tb_seq_det_full
add wave -r sim:/tb_seq_det_full/*
run -all
```

3. ตรวจว่า Transcript แสดง `seq_det_full PASSED: 14 checks` ที่ 80 ns
4. เทียบ Wave กับ Part 6: `det_mealy` ขึ้นที่ 40 ns และ 70 ns ส่วน `det_moore` ขึ้นที่ 45 ns และ 75 ns

> 📝 **หมายเหตุ:** testbench ในคู่มือต้นฉบับใช้ `std_logic'val((i mod 2) + 1)` ซึ่งให้ `'X'` และ `'0'` สลับกัน (ลำดับของ `std_logic` คือ U, X, 0, 1, ...) ไม่ใช่ `0` กับ `1` และไม่มีการตรวจผล จึงเขียนใหม่เป็น testbench ด้านบน

> ✅ **จุดตรวจสอบ:** ได้ `seq_det_full PASSED: 14 checks` และในแท็บ **sim** เห็นลำดับชั้น `tb_seq_det_full` → `u_dut` → `U_0`, `U_1`

## Troubleshooting

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| `state` แสดง `S0` ตั้งแต่ 0 ns ทั้งที่ยังไม่ reset | signal ชนิด enumerated เริ่มที่ค่าแรก (`S0`) ไม่ใช่ `'U'` | เป็นเรื่องปกติใน simulation แต่ฮาร์ดแวร์จริงต้อง reset เสมอ |
| `detected` เป็น `'X'` หรือ `'U'` | `din` หรือ `rst_n` ไม่มีค่าเริ่มต้น, port ไม่ได้ต่อ, หรือมีหลาย driver | ใส่ `:= '0'` ให้ signal ใน testbench ตรวจ port map |
| `Signal 'detected' has multiple drivers` | `detected` ถูก assign ทั้งใน process และ concurrent statement หรือหลาย process | ให้มีจุด assign เดียว (Moore: concurrent, Mealy: ใน comb\_proc) |
| Moore พบ `10101` แค่ครั้งเดียว | S3 + `din = '0'` → S0 | แก้เป็น S2 (Part 1) |
| Mealy FAIL ทุกครั้งที่คาด `1` | ตรวจหลังขอบขาขึ้น state เปลี่ยนไปแล้ว | ตรวจ Mealy ก่อนขอบขาขึ้น (Part 4) |
| PASS + FAIL รวมน้อยกว่าจำนวนการตรวจ | ตัวนับเป็น `signal` | ใช้ `variable` |
| FSM ไม่ออกจาก S0 | `rst_n` ค้าง `'0'` หรือไม่มี clock | ดู `rst_n` และ `clk` ใน Wave |
| ไม่เห็น `state` ใน Wave | optimization ซ่อน signal ภายใน | เริ่มด้วย `vsim -voptargs=+acc ...` |
| พัลส์ Mealy มี glitch หรือสั้นกว่า 1 clock | output เป็น combinational ตาม `din` | ถ้าต้องการพัลส์สะอาด ให้ register output: `det_q <= det_comb when rising_edge(clk);` (แต่ latency จะเท่า Moore) |
| HDL Designer ไม่พบ `seq_det_moore` ตอนวาง instance | ยังไม่ได้ import เข้า library หรืออยู่คนละ library | ทำ 7.2 ใหม่ และตรวจ library mapping |

> 📝 **หมายเหตุ:** คู่มือต้นฉบับแนะนำให้ใส่ `when others => next_state <= S0;` ใน `case state` ถ้าระบุครบทุก state แล้ว `when others` ไม่เปลี่ยนผลใน simulation และการทำ safe FSM ใน synthesis ต้องตั้ง attribute หรือ option ของเครื่องมือเพิ่ม (จะเรียนใน Lab 3)

## Bonus Challenges

### Challenge 1: ตรวจจับ `1101`

1. วาด state diagram แบบ Moore (5 states: S0–S4) และ Mealy (4 states)
2. เขียน transition แบบซ้อนทับโดยถามทุก state ว่า "suffix ที่ยาวที่สุดที่เป็นส่วนต้นของ `1101` คืออะไร"
3. แก้ `tb_seq_det` ให้ใช้สตริงคาดหวังใหม่ เช่น `1101101` → `0001001`

### Challenge 2: ตรวจจับแบบไม่ซ้อนทับ

- Moore: S3 → S0 เสมอเมื่อ `din = '0'` และ S3 → S1 เมื่อ `din = '1'`
- Mealy: S2 + `din = '1'` → S0 (แทน S1)
- ค่าคาดหวังของ `10101` จะเปลี่ยนจาก `00101` เป็น `00100` แก้ testbench ให้ตรงแล้วรันยืนยัน

### Challenge 3: Counter 4 บิต

เขียนตัวนับ 0–15 ที่ให้ `cout = '1'` เมื่อค่าเป็น 15 ใช้ `unsigned(3 downto 0)` จาก `NUMERIC_STD` แทนการประกาศ 16 states แล้วอธิบายว่าทำไมนี่ก็เป็น Moore FSM

### Challenge 4: Pattern Counter

ต่อ `detected_moore` เข้ากับตัวนับ 8 บิต ให้นับจำนวนครั้งที่พบ `101` ตรวจว่า T7 (`1101101`) ได้ count = 2

### Challenge 5: Moore FSM ระดับ gate ใน HDL Designer

ใช้ encoding S0 = `00`, S1 = `01`, S2 = `10`, S3 = `11` จะได้สมการของ Moore แบบซ้อนทับ

- next q1 = q0 · din' + q1 · q0' · din
- next q0 = din
- detected = q1 · q0

1. ตรวจสมการกับตาราง state ใน Part 1 ทีละแถว
2. วาด block diagram ด้วย D flip-flop 2 ตัว (มี synchronous reset) และ gate AND/OR/NOT (เขียนเป็นโมดูลเล็กเองหรือใช้จาก Lab 1)
3. Generate HDL แล้วเอาไปแทน `seq_det_moore` ใน `tb_seq_det` ต้องได้ `Moore: PASS=39 FAIL=0` เหมือนเดิม

## คำถามท้ายแลป

1. ทำไม Moore ต้องใช้ 4 states แต่ Mealy ใช้แค่ 3 states สำหรับ pattern เดียวกัน
2. ถ้า S3 + `din = '0'` ไป S0 แทน S2 จะพลาด pattern ใด ยกตัวอย่าง input หนึ่งชุด
3. จาก Part 6 Moore ขึ้นช้ากว่า Mealy กี่ ns ถ้า testbench ตั้ง `din` หลังขอบขาขึ้น 1 ns แทนขอบขาลง ตัวเลขนี้จะเป็นเท่าไร
4. ทำไม testbench ต้องตรวจ Mealy ก่อนขอบขาขึ้น แต่ตรวจ Moore หลังขอบขาขึ้น
5. ทำไมตัวนับ pass/fail ควรเป็น `variable` ไม่ใช่ `signal`
6. ถ้า output ของ FSM ต้องไปควบคุมวงจรอื่นที่ไวต่อ glitch ควรเลือก Moore หรือ Mealy เพราะอะไร

## Checklist ก่อนส่งงาน

- [ ] `seq_det_moore.vhd` (4 states, ซ้อนทับ) ผ่าน `tb_seq_det_moore` เห็น `PASS: 10101 produced two overlapping detections`
- [ ] `seq_det_mealy.vhd` (3 states) compile ผ่าน
- [ ] `tb_seq_det` ได้ `Moore: PASS=39 FAIL=0` และ `Mealy: PASS=39 FAIL=0`
- [ ] `vsim -c -do run_lab2.do` รันผ่านครบ 2 testbench
- [ ] กรอกตาราง 6.3 และแนบภาพ Wave ที่มี cursor 2 ตัว
- [ ] HDL Designer generate `seq_det_full` ได้ และ `tb_seq_det_full` ได้ `PASSED: 14 checks`
- [ ] ตอบคำถามท้ายแลปครบ 6 ข้อ

ผ่านครบทุกข้อแล้ว พร้อมไปต่อ **Lab 3: Synthesis ด้วย Precision RTL + SDC Constraints**

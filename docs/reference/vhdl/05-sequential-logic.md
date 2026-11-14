# บทที่ 05: ตรรกะ sequential

> บทนี้อธิบายการเขียนวงจรที่มีหน่วยความจำ ซึ่งเป็นหัวใจของงาน RTL
> รวมถึงรูปแบบ reset ที่แตกต่างกันและผลที่มีต่อวงจรจริง

**เครื่องมือที่เกี่ยวข้อง:** GHDL 1.0.0, `ghdl --synth`
**ตัวอย่างอ้างอิง:** `code/reference/vhdl/examples/ex02_counter_sync/`, `ex03_shift_lfsr/`

---

## สารบัญบท

- [1. นิยามและโครงสร้างพื้นฐาน](#1-นิยามและโครงสร้างพื้นฐาน)
- [2. การตรวจขอบนาฬิกา](#2-การตรวจขอบนาฬิกา)
- [3. รูปแบบของ reset](#3-รูปแบบของ-reset)
- [4. enable, load และลำดับความสำคัญ](#4-enable-load-และลำดับความสำคัญ)
- [5. กฎที่ต้องรู้เกี่ยวกับ clocked process](#5-กฎที่ต้องรู้เกี่ยวกับ-clocked-process)
- [6. รูปแบบที่ใช้บ่อย](#6-รูปแบบที่ใช้บ่อย)
- [7. ค่าเริ่มต้นของ signal](#7-ค่าเริ่มต้นของ-signal)
- [8. ตัวอย่างอ้างอิง: counter](#8-ตัวอย่างอ้างอิง-counter)

---

## 1. นิยามและโครงสร้างพื้นฐาน

วงจร sequential มีหน่วยความจำ จึงมี "สถานะ" ที่เปลี่ยนตามเวลา
สัญญาณเอาต์พุตขึ้นอยู่กับสถานะปัจจุบันและอินพุตปัจจุบัน

โครงสร้างมาตรฐานของโปรเจกต์นี้

```vhdl
architecture rtl of counter_sync is
  signal cnt_i : unsigned(WIDTH-1 downto 0) := (others => '0');
begin
  seq_p : process (clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        cnt_i <= (others => '0');
      elsif en = '1' then
        cnt_i <= cnt_i + 1;
      end if;
    end if;
  end process seq_p;
end architecture rtl;
```

องค์ประกอบของโครงสร้างนี้

| ส่วน | หน้าที่ |
|---|---|
| `process (clk)` | ระบุว่าโค้ดใน process นี้ทำงานเมื่อมี event ของนาฬิกา |
| `rising_edge(clk)` | เงื่อนไขที่ทำให้กำหนดค่าเกิดขึ้นเฉพาะที่ขอบขาขึ้น |
| `rst_n = '0'` | เงื่อนไขแรก เพราะ reset ต้องมีผลเหนือกว่าทุกอย่าง |
| `elsif en = '1'` | เงื่อนไขถัดมา คือ "ทำงานเมื่อได้รับอนุญาต" |
| `cnt_i <= cnt_i + 1` | ค่าถัดไปของ state ถูกกำหนดจาก state ปัจจุบัน |

## 2. การตรวจขอบนาฬิกา

| รูปแบบ | ความหมาย | ใช้เมื่อ |
|---|---|---|
| `rising_edge(clk)` | ขอบขาขึ้น (0 → 1) | กรณีทั่วไปของ RTL |
| `falling_edge(clk)` | ขอบขาลง (1 → 0) | กรณีเฉพาะที่ต้องการจับขอบตรงข้าม |
| `if clk = '1' then` | ทำงานตรงที่ระดับสูง | **ใช้ไม่ได้** ใน RTL ที่ต้องสังเคราะห์ เพราะสังเคราะห์ไม่ได้ |

> `if clk = '1'` เป็นความผิดพลาดที่พบบ่อยในโค้ดที่เขียนสลับจาก Verilog
> และจะทำให้เครื่องมือสังเคราะห์ประกาศ error หรือสร้างวงจรที่ผิดพฤติกรรม

## 3. รูปแบบของ reset

### 3.1 ตารางเปรียบเทียบ

| รูปแบบ | โค้ด | ทำงานเมื่อ | ข้อดี | ข้อเสีย |
|---|---|---|---|---|
| **Synchronous reset** | `process (clk)` + `if rst_n = '0'` | ที่ขอบนาฬิกา | ใช้พลังงานน้อย ไม่มี recovery/removal time ให้วิเคราะห์ | ถ้านาฬิกาหยุด reset จะไม่มีผล |
| **Asynchronous reset** | `process (clk, rst_n)` + `if rst_n = '0'` | ทันทีที่ reset ตก | ทำงานแม้นาฬิกาหยุด ปลดล็อกสถานะได้เร็ว | ต้องวิเคราะห์ recovery/removal time ของ flip-flop |
| **ไม่มี reset** | `process (clk)` | — | ใช้พลังงานน้อยที่สุด | สถานะเริ่มต้นเป็นค่าที่ไม่รู้จัก ต้องมีวิธีกู้สถานะอื่น |

### 3.2 รูปแบบที่ใช้ในโปรเจกต์นี้

**ค่าเริ่มต้นใช้ synchronous reset** เพราะ
1. ไม่มีปัญหา recovery/removal time ซึ่งเป็นเรื่องยากสำหรับผู้เรียน
2. เครื่องมือสังเคราะห์ส่วนใหญ่สามารถสังเคราะห์ได้ดีกว่า
3. ตรวจสอบพฤติกรรมได้ง่ายกว่าในการจำลอง

แต่ต้องทราบข้อจำกัด: **ระหว่างที่ reset ยังไม่ปลด ถ้านาฬิกาหยุด วงจรจะไม่ถูกรีเซ็ต**
ในระบบจริงที่นาฬิกาอาจหยุด (เช่น ในโหมดประหยัดพลังงาน) ต้องใช้ asynchronous reset
หรือมีวิธีรีเซ็ตสถานะอื่นที่ไม่พึ่งนาฬิกา

### 3.3 รูปแบบ asynchronous reset ที่ถูกต้อง

```vhdl
seq_p : process (clk, rst_n)
begin
  if rst_n = '0' then
    cnt_i <= (others => '0');
  elsif rising_edge(clk) then
    if en = '1' then
      cnt_i <= cnt_i + 1;
    end if;
  end if;
end process seq_p;
```

ข้อควรระวัง

- sensitivity list ต้องมีทั้ง `clk` และ `rst_n`
- เงื่อนไข reset ต้องอยู่ก่อน `rising_edge` เสมอ
- **ห้ามใส่เงื่อนไขอื่นก่อน reset** เช่น `if en = '1' and rst_n = '0' then`
  เพราะจะทำให้ reset ไม่มีผลเมื่อ `en` เป็น 0

### 3.4 การรีเซ็ตหลาย register

```vhdl
seq_p : process (clk, rst_n)
begin
  if rst_n = '0' then
    state_i <= S_IDLE;
    cnt_i   <= (others => '0');
    flag_i  <= '0';
  elsif rising_edge(clk) then
    ...
  end if;
end process seq_p;
```

> **อย่าใช้ loop เพื่อรีเซ็ต register หลายตัว** เพราะเครื่องมือสังเคราะห์บางตัว
> อนุมานโครงสร้างผิด และทำให้อ่านโค้ดยากกว่าการเขียนตรง ๆ

## 4. enable, load และลำดับความสำคัญ

วงจรลำดับมักมีเงื่อนไขหลายชั้น เช่น reset, load, enable
**ลำดับที่เขียนในโค้ดคือลำดับความสำคัญ** โดยเงื่อนไขแรกมีความสำคัญสูงสุด

```vhdl
seq_p : process (clk)
begin
  if rising_edge(clk) then
    if rst_n = '0' then        -- 1. reset สำคัญที่สุด
      cnt_i <= (others => '0');
    elsif load = '1' then      -- 2. load
      cnt_i <= load_value;
    elsif en = '1' then        -- 3. enable
      cnt_i <= cnt_i + 1;
    end if;
  end if;
end process seq_p;
```

| ลำดับ | เงื่อนไข | ผลเมื่อทำงานพร้อมกัน |
|---|---|---|
| 1 | `rst_n = '0'` | รีเซ็ต ค่าอื่นไม่มีผล |
| 2 | `load = '1'` | โหลดค่าใหม่ ไม่ว่า `en` จะเป็นอะไร |
| 3 | `en = '1'` | ทำงานตามปกติ |

> **ต้องเขียนลำดับความสำคัญให้ชัดเจนในคอมเมนต์** เพราะผู้อ่านโค้ดจะไม่รู้ว่า
> `load` จะมีผลเหนือ `en` หรือไม่ ตัวอย่างที่ชัดเจนในคู่มือนี้คือ
> `code/reference/vhdl/examples/ex02_counter_sync/src/counter_sync.vhd`

## 5. กฎที่ต้องรู้เกี่ยวกับ clocked process

### 5.1 ใช้ signal assignment เสมอ

```vhdl
cnt_i <= cnt_i + 1;      -- ✓
cnt_i := cnt_i + 1;      -- ✗ ผิดชนิด (signal ใช้ := ไม่ได้)
```

### 5.2 ค่าที่อ่านใน clocked process เป็น "ค่าเก่า" เสมอ

เมื่อ process ทำงานที่ขอบนาฬิกา ค่าของ signal ที่ถูก assign ใน process นั้น
ยังเป็นค่าของรอบก่อนหน้า เพราะการอัปเดตจะเกิดหลังจบการทำงานของ process

```vhdl
process (clk)
begin
  if rising_edge(clk) then
    a_i <= b_i;         -- ใช้ค่าเก่าของ b_i
    b_i <= a_i;         -- สลับค่าได้ถูกต้อง เพราะทั้งสองอ่านค่าเก่า
  end if;
end process;
```

ถ้าต้องการ "อ่านค่าใหม่ที่เพิ่งคำนวณ" ให้ใช้ `variable`

### 5.3 signal ภายในที่ถูก assign ใน clocked process จะกลายเป็น latch

ดูรายละเอียดใน [บทที่ 03](03-style-and-naming.md#44-signal-ที่ถูก-assign-ใน-clocked-process)
ทางแก้คือย้าย `q` เป็น `out` port หรือแยกเป็น combinational process

### 5.4 อย่าอ่าน output port ของตัวเองในมาตรฐาน VHDL-2002

```vhdl
-- ✗ ใช้ไม่ได้ใน VHDL-2002
if count = 0 then ...
```

ใช้ signal ภายในแทน (ดู [บทที่ 01](01-language-basics.md#42-port-mode))

### 5.5 หนึ่ง clocked process ต่อหนึ่งกลุ่ม register

แนวทางที่ใช้ในโปรเจกต์นี้คือ **หนึ่ง process ต่อหนึ่งโมดูลที่มีนาฬิกาเดียว**
แทนที่จะแยก process ตามชนิดข้อมูล

| แนวทาง | ข้อดี | ข้อเสีย |
|---|---|---|
| หนึ่ง process ต่อโมดูล (แนะนำ) | อ่านง่าย เห็นความสัมพันธ์ของ register ทั้งหมดพร้อมกัน | process ใหญ่ถ้าโมดูลใหญ่ |
| หนึ่ง process ต่อ register | เล็กและแยกส่วน | ต้องระวังการอ่านค่าเก่าและการแข่งขันเขียน signal |

## 6. รูปแบบที่ใช้บ่อย

### 6.1 ตัวนับ (counter)

```vhdl
seq_p : process (clk)
begin
  if rising_edge(clk) then
    if rst_n = '0' then
      cnt_i <= (others => '0');
    elsif en = '1' then
      if cnt_i = cnt_i'high then
        cnt_i <= (others => '0');
      else
        cnt_i <= cnt_i + 1;
      end if;
    end if;
  end if;
end process seq_p;
```

> การใช้ `cnt_i'high` แทนการเขียนค่าสูงสุดเป็นตัวเลข ทำให้แก้ความกว้างได้ทันที

### 6.2 ตัวนับขึ้น/ลง

```vhdl
      elsif en = '1' then
        if up = '1' then
          cnt_i <= cnt_i + 1;
        else
          cnt_i <= cnt_i - 1;
        end if;
```

### 6.3 ตัวเลื่อน (shift register)

```vhdl
seq_p : process (clk)
begin
  if rising_edge(clk) then
    if rst_n = '0' then
      sr_i <= (others => '0');
    else
      sr_i <= sr_i(DATA_WIDTH-2 downto 0) & shift_in;
    end if;
  end if;
end process seq_p;
```

### 6.4 ตัวหารนาฬิกา (clock divider)

```vhdl
seq_p : process (clk)
begin
  if rising_edge(clk) then
    if rst_n = '0' then
      cnt_i <= (others => '0');
    elsif en = '1' then
      if cnt_i = DIV - 1 then
        cnt_i <= (others => '0');
      else
        cnt_i <= cnt_i + 1;
      end if;
    end if;
  end if;
end process seq_p;

tick_o <= '1' when cnt_i = DIV - 1 else '0';
```

> **คำเตือนเรื่อง clock divider** — การหารนาฬิกาแบบนี้สร้างสัญญาณที่มี duty cycle
> ไม่ใช่ 50% และมี jitter จากความไม่สมบูรณ์ของเส้นทางสัญญาณ
> ในโปรเจกต์จริงที่มีข้อกำหนดด้านเวลา ให้ใช้ clock gating ICG cell
> หรือ PLL ของ PDK แทน (ดูบทที่ 10)

### 6.5 register ที่มีเงื่อนไข enable

```vhdl
      elsif en = '1' then
        q_i <= d;
```

เมื่อ `en = '0'` register คงค่าเดิม ซึ่งเป็นพฤติกรรมที่ถูกต้องของ flip-flop
ที่มี clock enable

### 6.6 LFSR

```vhdl
seq_p : process (clk)
begin
  if rising_edge(clk) then
    if rst_n = '0' then
      lfsr_i <= (others => '0');
    elsif load_seed = '1' then
      lfsr_i <= seed;
    elsif enable = '1' then
      lfsr_i <= lfsr_i(WIDTH-2 downto 0) & (lfsr_i(WIDTH-1) xor lfsr_i(WIDTH-3));
    end if;
  end if;
end process seq_p;
```

ตัวอย่างเต็มพร้อมการทดสอบอยู่ที่
`code/reference/vhdl/examples/ex03_shift_lfsr/`

## 7. ค่าเริ่มต้นของ signal

VHDL-2008 อนุญาตให้ประกาศค่าเริ่มต้นของ signal ได้

```vhdl
signal cnt_i : unsigned(3 downto 0) := (others => '0');
```

ข้อควรระวัง

- ใน VHDL-2002 ค่าเริ่มต้นของ signal คือค่า "ซ้ายสุด" ของชนิดข้อมูล
  ซึ่งสำหรับ `std_logic` คือ 'U' (uninitialized) — จึงต้องมี reset เสมอ
- การประกาศค่าเริ่มต้นทำให้ simulation เริ่มต้นได้โดยไม่ต้องรอ reset
  แต่ **ไม่ได้ทำให้ reset จำเป็นได้** ในฮาร์ดแวร์จริง register ยังต้องถูกรีเซ็ต
- เครื่องมือสังเคราะห์บางตัวไม่รองรับค่าเริ่มต้นของ signal
  จึงต้องยืนยันกับเอกสารของเครื่องมือก่อนใช้

## 8. ตัวอย่างอ้างอิง: counter

ตัวอย่างเต็มอยู่ที่ `code/reference/vhdl/examples/ex02_counter_sync/src/counter_sync.vhd`

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_sync is
  generic (
    WIDTH : positive := 4
  );
  port (
    clk        : in  std_logic;
    rst_n      : in  std_logic;
    en         : in  std_logic;
    load       : in  std_logic;
    up         : in  std_logic;
    load_value : in  std_logic_vector(WIDTH-1 downto 0);
    count      : out std_logic_vector(WIDTH-1 downto 0);
    carry_out  : out std_logic;
    zero       : out std_logic
  );
end entity counter_sync;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of counter_sync is
  signal cnt_i   : unsigned(WIDTH-1 downto 0) := (others => '0');
  signal carry_i : std_logic;
  signal zero_i  : std_logic;
begin
  seq_p : process (clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        -- 1. reset มีผลเหนือทุกเงื่อนไข
        cnt_i <= (others => '0');
      elsif load = '1' then
        -- 2. load มีผลเหนือ en
        cnt_i <= unsigned(load_value);
      elsif en = '1' then
        -- 3. ทำงานเมื่อได้รับอนุญาต
        if up = '1' then
          if cnt_i = cnt_i'high then
            cnt_i <= (others => '0');          -- wrap รอบบน
          else
            cnt_i <= cnt_i + 1;
          end if;
        else
          if cnt_i = (others => '0') then
            cnt_i <= cnt_i'high;               -- wrap รอบล่าง
          else
            cnt_i <= cnt_i - 1;
          end if;
        end if;
      end if;
    end if;
  end process seq_p;

  -- เอาต์พุตคำนวณจากค่าภายใน ไม่อ่านจากพอร์ต count ตามข้อจำกัดของ VHDL-2002
  carry_i <= '1' when (up = '1' and cnt_i = cnt_i'high) else '0';
  zero_i  <= '1' when cnt_i = (others => '0') else '0';

  count     <= std_logic_vector(cnt_i);
  carry_out <= carry_i;
  zero      <= zero_i;
end architecture rtl;
```

ข้อสังเกต

1. เงื่อนไขเรียงตามลำดับความสำคัญและมีคอมเมนต์บอกไว้ชัดเจน
2. `cnt_i` เป็น `unsigned` ภายใน แล้วแปลงเป็น `std_logic_vector` ที่พอร์ตที่จุดเดียว
3. `carry_i` และ `zero_i` คำนวณจาก `cnt_i` โดยตรง ไม่อ่านพอร์ต `count`
4. ค่าเริ่มต้นของ `cnt_i` มีไว้เพื่อให้ simulation เริ่มได้ แต่ยังมี reset เป็นหลัก

---

## แบบฝึกหัดท้ายบท

1. เขียน `counter_down_only` ที่นับลงเท่านั้น พร้อมเงื่อนไข load และ enable
   แล้วทดสอบกรณีนับถึงศูนย์และ wrap
2. แก้ `ex02_counter_sync` ให้ใช้ asynchronous reset แล้วรันซ้ำ จากนั้นอธิบายว่า
   ผลลัพธ์ต่างกันอย่างไรในช่วงที่ reset ถูกปลดกลางรอบนาฬิกา
3. สร้าง testbench ที่ปลด reset ในช่วงที่นาฬิกาไม่กระพริบ แล้วตรวจว่า
   counter เริ่มนับหรือไม่ อธิบายผลที่ได้
4. เพิ่ม `hold` เงื่อนไข (หยุดนับชั่วคราวโดยไม่รีเซ็ต) ให้ `counter_sync`
   แล้วทดสอบลำดับความสำคัญของ reset > load > en > hold
5. ค้นหาในโปรเจกต์ของคุณว่ามี signal ที่ถูก assign ใน clocked process
   และประกาศไว้นอก process หรือไม่ แล้วแก้ให้ถูกต้อง

## คำถามท้ายบท

1. synchronous reset กับ asynchronous reset ต่างกันอย่างไรในเชิงพฤติกรรม
   และในเชิงที่ต้องวิเคราะห์เวลา
2. ทำไม `if clk = '1'` จึงใช้ใน RTL ที่สังเคราะห์ไม่ได้
3. ค่าของ signal ที่ถูก assign ใน clocked process เป็นค่าเก่าเสมอ
   ความจริงข้อนี้มีผลอย่างไรต่อการสลับค่าสอง signal
4. การประกาศค่าเริ่มต้นของ signal ใน VHDL-2008 ช่วยอะไร และเหตุใดยังต้องมี reset
5. การหารนาฬิกาด้วย counter มีข้อเสียอะไรเมื่อใช้ในงานที่มีข้อกำหนดด้านเวลา

---

**อ่านต่อ:** [บทที่ 06 — เครื่องสถานะจำกัด (FSM)](06-fsm.md)

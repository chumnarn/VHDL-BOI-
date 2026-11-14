# บทที่ 06: เครื่องสถานะจำกัด (FSM)

> บทนี้อธิบายการเขียน control logic ที่มีหลายสถานะ ซึ่งเป็นส่วนที่ผู้เรียนมัก
> เขียนผิดบ่อยที่สุด โดยเฉพาะเรื่องการกู้สถานะเมื่อค่าผิดพลาด

**เครื่องมือที่เกี่ยวข้อง:** GHDL 1.0.0
**ตัวอย่างอ้างอิง:** `code/reference/vhdl/examples/ex04_fsm_enum/`, `ex10_uart_tx/`

---

## สารบัญบท

- [1. โครงสร้างของ FSM](#1-โครงสร้างของ-fsm)
- [2. Moore กับ Mealy](#2-moore-กับ-mealy)
- [3. การเขียน FSM ด้วย enum](#3-การเขียน-fsm-ด้วย-enum)
- [4. การกู้สถานะเมื่อค่าผิดพลาด](#4-การกู้สถานะเมื่อค่าผิดพลาด)
- [5. safe state และทางออกฉุกเฉิน](#5-safe-state-และทางออกฉุกเฉิน)
- [6. รูปแบบการแยก process](#6-รูปแบบการแยก-process)
- [7. รูปแบบที่ควรหลีกเลี่ยง](#7-รูปแบบที่ควรหลีกเลี่ยง)
- [8. การทดสอบ FSM](#8-การทดสอบ-fsm)
- [9. ตัวอย่างอ้างอิง: ไฟจราจร](#9-ตัวอย่างอ้างอิง-ไฟจราจร)

---

## 1. โครงสร้างของ FSM

FSM ประกอบด้วย 4 ส่วน

| ส่วน | หน้าที่ | ข้อมูล |
|---|---|---|
| ชุดสถานะ (states) | ระบุสถานะที่เป็นไปได้ | `type state_t is (...)` |
| ตารางการเปลี่ยนสถานะ (transition) | ระบุว่าจะไปสถานะใดเมื่อได้รับอินพุต | `case state_i is` ใน clocked process |
| เอาต์พุต (output) | ผลลัพธ์ที่สัมพันธ์กับสถานะ | Moore: จากสถานะ / Mealy: จากสถานะ + อินพุต |
| สถานะปัจจุบัน | register ที่เก็บสถานะ | `signal state_i : state_t` |

ประเภทของ FSM ตามจำนวน process

| แบบ | จำนวน process | ข้อดี | ข้อเสีย |
|---|---|---|---|
| หนึ่ง process | 1 | โค้ดสั้น ไม่มีปัญหา "อ่านค่าเก่า" ข้าม process | เอาต์พุต combinational ปนกับ logic ของสถานะ |
| สอง process | 2 | แยกสถานะกับเอาต์พุตชัดเจน | ต้องระวังเอาต์พุต combinational ที่ขึ้นกับสถานะรุ่นถัดไป |
| สาม process | 3 | แยกสถานะ / next state / เอาต์พุต ชัดที่สุด | โค้ดยาว และ next state ต้องคำนวณจากสถานะรุ่นถัดไปเสมอ |

> **แนวทางของคู่มือนี้** — ใช้ **สอง process** เป็นหลัก
> (หนึ่ง process เก็บสถานะและคำนวณสถานะถัดไป, อีก process คำนวณเอาต์พุต)
> เพราะอ่านง่ายและไม่มีปัญหาการอ่านค่าข้าม process

## 2. Moore กับ Mealy

| คุณสมบัติ | Moore | Mealy |
|---|---|---|
| เอาต์พุตขึ้นกับ | สถานะปัจจุบันเท่านั้น | สถานะปัจจุบัน + อินพุตปัจจุบัน |
| จำนวนสถานะ | มากกว่า | น้อยกว่า |
| เอาต์พุตเปลี่ยนทันทีเมื่ออินพุตเปลี่ยน | ไม่ | ใช่ (อาจเกิด glitch) |
| เวลาตอบสนอง | นานกว่า (รอขอบนาฬิกาถัดไป) | เร็วกว่า |
| ความเสี่ยงการออกแบบผิด | ต่ำ | สูงกว่า เพราะพฤติกรรมขึ้นกับอินพุต |

ตัวอย่างเชิงธุรกิจ — เครื่องตรวจจับบัตรที่ต้องส่งสัญญาณ "ใช้บัตรได้" ทันทีที่ผู้ใช้วางบัตร
โดยไม่ต้องรอขอบนาฬิกาถัดไป มักใช้ Mealy

## 3. การเขียน FSM ด้วย enum

```vhdl
architecture rtl of traffic_fsm is
  type state_t is (S_RED, S_GREEN, S_YELLOW);
  signal state_i : state_t := S_RED;
begin
```

### 3.1 ข้อดีของ enum เหนือ std_logic_vector

| ข้อดี | รายละเอียด |
|---|---|
| ตรวจจับสถานะที่ไม่ได้ประกาศ | `case` ที่ครบทุกสถานะจะคอมไพล์ไม่ผ่านเมื่อเพิ่มสถานะใหม่ |
| อ่านง่าย | `when S_GREEN =>` แทน `when "001" =>` |
| `when others` จับค่าที่ไม่รู้จัก | ค่า enum ที่อยู่นอกช่วงที่ประกาศจะเข้า `when others` |
| ใช้ attribute ได้ | `state_t'image(state_i)` ใน report |

### 3.2 ข้อจำกัดที่ต้องรู้

เมื่อสถานะเก็บใน signal ชนิด enum ค่าที่ "ผิด" จะไม่ใช่ 'X'
แต่จะเป็นค่า enum ที่อยู่นอกช่วงที่ประกาศไว้ ซึ่งเครื่องมือจำลองบางตัวจะ
รายงานว่าเป็น error หรือหยุดการจำลองทันที

**ข้อสรุป**: ต้องมี `when others` ใน `case` ที่แปลงสถานะ **เสมอ**
และต้องมีทางออกที่ทำให้วงจรกลับเข้าสู่สถานะที่รู้จัก

## 4. การกู้สถานะเมื่อค่าผิดพลาด

```vhdl
seq_p : process (clk)
begin
  if rising_edge(clk) then
    if rst_n = '0' then
      state_i <= S_RED;
    elsif tick = '1' then
      case state_i is
        when S_RED    => state_i <= S_GREEN;
        when S_GREEN  => state_i <= S_YELLOW;
        when S_YELLOW => state_i <= S_RED;
        -- ค่าที่ไม่รู้จัก (เช่น X จาก upset) ต้องถูกดันกลับเข้าสู่สถานะที่รู้จัก
        -- ถ้าไม่มี when others สถานะจะ "ค้าง" ที่ค่าที่ผิดพลาดไปตลอด
        when others   => state_i <= S_RED;
      end case;
    end if;
  end if;
end process seq_p;
```

> **กฎที่ไม่ต่อรอง** — ทุก `case` ที่แปลงค่าสถานะต้องมี `when others`
> และ `when others` ต้องพาไปยังสถานะที่ปลอดภัย (safe state) เสมอ

## 5. safe state และทางออกฉุกเฉิน

### 5.1 safe state คืออะไร

safe state คือสถานะที่เมื่อวงจรเข้าไปอยู่แล้วจะไม่ทำให้ระบบทำงานผิด
เช่น ไฟจราจรที่สถานะปลอดภัยคือไฟแดง เพราะปลอดภัยต่อการจราจร

### 5.2 ทางออกฉุกเฉินที่ใช้ในโปรเจกต์นี้

```vhdl
architecture rtl of traffic_fsm is
  type state_t is (S_RED, S_GREEN, S_YELLOW);
  signal state_i : state_t := S_RED;
begin
  seq_p : process (clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        state_i <= S_RED;
      elsif force_safe = '1' then
        -- ทางออกฉุกเฉิน: บังคับกลับสู่ safe state โดยไม่ต้องรอ reset
        -- ใช้เมื่อมีระบบตรวจจับความผิดปกติจากภายนอก
        state_i <= S_RED;
      elsif tick = '1' then
        case state_i is
          when S_RED    => state_i <= S_GREEN;
          when S_GREEN  => state_i <= S_YELLOW;
          when S_YELLOW => state_i <= S_RED;
          when others   => state_i <= S_RED;
        end case;
      end if;
    end if;
  end process seq_p;
```

ประโยชน์ของ `force_safe`

- ทดสอบ path กู้สถานะได้โดยไม่ต้องรอเกิดค่าผิดพลาดจริง
- ใช้เป็นจุดต่อของระบบ watchdog หรือ error monitor ในระบบจริง
- เป็นเอกสารที่ชัดเจนว่าวงจรต้องกลับสู่สถานะปลอดภัยได้อย่างไร

## 6. รูปแบบการแยก process

### 6.1 สอง process (แนวทางหลักของคู่มือนี้)

```vhdl
architecture rtl of traffic_fsm is
  type state_t is (S_RED, S_GREEN, S_YELLOW);
  signal state_i : state_t := S_RED;
begin
  -- process 1: สถานะและการเปลี่ยนสถานะ
  seq_p : process (clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        state_i <= S_RED;
      elsif tick = '1' then
        case state_i is
          when S_RED    => state_i <= S_GREEN;
          when S_GREEN  => state_i <= S_YELLOW;
          when S_YELLOW => state_i <= S_RED;
          when others   => state_i <= S_RED;
        end case;
      end if;
    end if;
  end process seq_p;

  -- process 2: เอาต์พุต (Moore) ขึ้นอยู่กับสถานะเท่านั้น
  comb_p : process (state_i)
  begin
    case state_i is
      when S_RED    => red_o <= '1'; yellow_o <= '0'; green_o <= '0';
      when S_GREEN  => red_o <= '0'; yellow_o <= '0'; green_o <= '1';
      when S_YELLOW => red_o <= '0'; yellow_o <= '1'; green_o <= '0';
      when others   => red_o <= '0'; yellow_o <= '0'; green_o <= '0';
    end case;
  end process comb_p;
end architecture rtl;
```

### 6.2 สาม process

```vhdl
  -- process 1: register สถานะ
  seq_p : process (clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        state_i <= S_RED;
      else
        state_i <= next_state_i;
      end if;
    end if;
  end process seq_p;

  -- process 2: คำนวณสถานะถัดไป
  next_p : process (state_i, tick)
  begin
    next_state_i <= S_RED;         -- ค่าเริ่มต้นกันกรณีไม่ครบทุก path
    case state_i is
      when S_RED    => if tick = '1' then next_state_i <= S_GREEN; end if;
      when S_GREEN  => if tick = '1' then next_state_i <= S_YELLOW; end if;
      when S_YELLOW => if tick = '1' then next_state_i <= S_RED; end if;
      when others   => next_state_i <= S_RED;
    end case;
  end process next_p;
```

> **ข้อควรระวังของแบบสาม process** — เอาต์พุตที่คำนวณจาก `next_state_i`
> จะเปลี่ยนไปตามสถานะถัดไป **ก่อน** ที่สถานะจะเปลี่ยนจริง
> นี่คือ "Mealy-like" artifact ที่ต้องระวัง ถ้าเอาต์พุตต้องผูกกับสถานะจริง
> ให้ใช้ `state_i` แทน `next_state_i`

### 6.3 แบบ Mealy

```vhdl
  comb_p : process (state_i, tick)
  begin
    change_req_o <= '0';             -- ค่าเริ่มต้น
    case state_i is
      when S_RED    => if tick = '1' then change_req_o <= '1'; end if;
      when S_GREEN  => null;
      when S_YELLOW => null;
      when others   => null;
    end case;
  end process comb_p;
```

## 7. รูปแบบที่ควรหลีกเลี่ยง

### 7.1 ใช้ตัวแปรนับรอบแทนการใช้สถานะ

```vhdl
-- ✗ ไม่แนะนำ: ตรรกะซ้อนกัน ยากต่อการตรวจสอบและแก้ไข
if step = 0 then
  if x = '1' then step := 1; end if;
elsif step = 1 then
  ...
end if;
```

ข้อดีของแบบ FSM: ตารางการเปลี่ยนสถานะมองเห็นได้ในหน้าจอเดียว
ตรวจสอบความครบถ้วนได้ และสร้างกราฟสถานะ (state diagram) ได้โดยตรง

### 7.2 ผสมเอาต์พุต combinational กับการเปลี่ยนสถานะใน process เดียวกัน

ถ้าเอาต์พุตถูก assign ทั้งใน clocked process และ combinational process
จะเกิด multiple drivers — ต้องแยกให้ชัดว่าเอาต์พุตใดมาจากที่ไหน

### 7.3 ใช้ `std_logic_vector` แทน enum โดยไม่มี `when others`

```vhdl
-- ✗ เสี่ยง: ถ้า state เป็น "011" ที่ไม่ได้ประกาศ วงจรจะค้าง
case state_i is
  when "000" => ...
  when "001" => ...
  when "010" => ...
end case;
```

## 8. การทดสอบ FSM

### 8.1 ตรวจลำดับสถานะ

```vhdl
-- ส่ง tick แล้วตรวจว่าสถานะเปลี่ยนตามตาราง
wait until rising_edge(clk);
tick <= '1';
wait until rising_edge(clk);
wait for 1 ns;
assert state_out = S_GREEN_V report "expected S_GREEN" severity failure;
```

### 8.2 ตรวจว่าเอาต์พุตของ Moore ไม่ขึ้นกับอินพุต

เปลี่ยน `tick` โดยไม่ให้มีขอบนาฬิกา แล้วตรวจว่าเอาต์พุตไม่เปลี่ยน
นี่คือการพิสูจน์ว่าเป็น Moore จริง ไม่ใช่ Mealy ที่เขียนผิด

### 8.3 ตรวจ path กู้สถานะ

ใช้ `force_safe` หรือช่องทางที่ออกแบบไว้ เพื่อบังคับให้วงจรกลับสู่ safe state
แล้วตรวจว่าเอาต์พุตเป็นค่าที่ปลอดภัย

### 8.4 ตรวจว่าทุกสถานะถูกเข้าถึง

ใช้ counter นับจำนวนครั้งที่เข้าสถานะแต่ละสถานะ แล้วรายงานสถานะที่ไม่เคยได้เข้า
วิธีนี้ตรวจได้ว่า testbench ไม่ได้ทดสอบเฉพาะเส้นทางเดียว

## 9. ตัวอย่างอ้างอิง: ไฟจราจร

ตัวอย่างเต็มอยู่ที่ `code/reference/vhdl/examples/ex04_fsm_enum/`

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity fsm_moore_enum is
  port (
    clk       : in  std_logic;
    rst_n     : in  std_logic;
    tick      : in  std_logic;
    force_safe: in  std_logic;
    red       : out std_logic;
    yellow    : out std_logic;
    green     : out std_logic;
    state_out : out std_logic_vector(1 downto 0)
  );
end entity fsm_moore_enum;

library ieee;
use ieee.std_logic_1164.all;

architecture rtl of fsm_moore_enum is
  type state_t is (S_RED, S_GREEN, S_YELLOW);
  signal state_i : state_t := S_RED;
begin
  seq_p : process (clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        state_i <= S_RED;
      elsif force_safe = '1' then
        state_i <= S_RED;
      elsif tick = '1' then
        case state_i is
          when S_RED    => state_i <= S_GREEN;
          when S_GREEN  => state_i <= S_YELLOW;
          when S_YELLOW => state_i <= S_RED;
          when others   => state_i <= S_RED;
        end case;
      end if;
    end if;
  end process seq_p;

  comb_p : process (state_i)
  begin
    case state_i is
      when S_RED    => red <= '1'; yellow <= '0'; green <= '0';
      when S_GREEN  => red <= '0'; yellow <= '0'; green <= '1';
      when S_YELLOW => red <= '0'; yellow <= '1'; green <= '0';
      when others   => red <= '0'; yellow <= '0'; green <= '0';
    end case;
  end process comb_p;

  -- แปลง enum เป็นสัญญาณสำหรับการแสดงผลหรือเทียบกับ Verilog
  with state_i select
    state_out <= "00" when S_RED,
                 "01" when S_GREEN,
                 "10" when S_YELLOW,
                 "11" when others;
end architecture rtl;
```

ข้อสังเกต

1. `state_t` ประกาศใน architecture ไม่ใช่ระดับ package เพราะไม่ได้ใช้ที่อื่น
   ถ้าต้องใช้ข้ามโมดูลควรย้ายไป package
2. ค่าเริ่มต้น `state_i := S_RED` ทำให้ simulation เริ่มจากสถานะที่รู้จัก
   แต่ยังมี reset เป็นกลไกหลัก
3. `force_safe` อยู่ระหว่าง reset กับเงื่อนไขปกติ จึงมีผลเหนือเงื่อนไข tick
4. `when others` ในทั้งสอง `case` พาไปยังสถานะ/ค่าที่ปลอดภัย
5. เอาต์พุต `red`, `yellow`, `green` เป็น `out` port ที่ถูก assign ใน combinational process
   โดยตรง ไม่มี signal ภายในที่จะกลายเป็น latch

---

## แบบฝึกหัดท้ายบท

1. เขียน FSM เครื่องแจ่นเงิน (state: IDLE, ACCEPT, DISPENSE, RETURN) ด้วย enum
   โดยมีเงื่อนไข reject ที่ทำให้กลับสู่ IDLE
2. เขียน FSM แบบ Mealy ที่ส่งสัญญาณ `ack` ในรอบเดียวกับที่อินพุตมา
   แล้วเปรียบเทียบจำนวนสถานะกับแบบ Moore
3. แก้ `ex04_fsm_enum` โดยลบ `when others` ออกจาก `case` ของสถานะ
   แล้วคอมไพล์ด้วย `ghdl -a --std=08` จดข้อความ error ที่ได้
4. เขียน testbench ที่นับจำนวนครั้งที่เข้าสถานะแต่ละสถานะ
   แล้วรายงานสถานะที่ไม่เคยได้เข้า
5. อธิบายว่าเหตุใด `when others` ที่พาไปยัง safe state
   จึงสำคัญกว่าการปล่อยให้สถานะค้าง

## คำถามท้ายบท

1. FSM แบบ Moore ต่างจากแบบ Mealy อย่างไรในเชิงจำนวนสถานะและเวลาตอบสนอง
2. เมื่อสถานะเก็บใน signal ชนิด enum ค่าที่ผิดพลาดแตกต่างจาก 'X' ของ `std_logic_vector`
   อย่างไร และมีผลต่อการเขียน `case` อย่างไร
3. ทำไมต้องมี `when others` ใน `case` ที่แปลงสถานะ และต้องพาไปยัง safe state
4. ในแบบสาม process เอาต์พุตที่คำนวณจาก `next_state_i` จะเปลี่ยนเมื่อใด
   และมีผลต่อพฤติกรรมแบบ Moore หรือไม่
5. `force_safe` มีประโยชน์ต่อการทดสอบและต่อการออกแบบระบบจริงอย่างไร

---

**อ่านต่อ:** [บทที่ 07 — สัญญาส่งข้อมูลและข้าม clock domain](07-interfaces-and-cdc.md)

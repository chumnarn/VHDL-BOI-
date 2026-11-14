# บทที่ 02: ชนิดข้อมูล

> บทนี้อธิบายชนิดข้อมูลของ VHDL ตั้งแต่ `std_logic` ไปจนถึง `numeric_std`
> รวมถึงกฎการเลือกชนิดข้อมูลให้เหมาะกับการสังเคราะห์และการตรวจสอบ

**เครื่องมือที่เกี่ยวข้อง:** GHDL 1.0.0, `ieee.std_logic_1164`, `ieee.numeric_std`

---

## สารบัญบท

- [1. หลักการเลือกชนิดข้อมูล](#1-หลักการเลือกชนิดข้อมูล)
- [2. std_logic และ std_logic_vector](#2-std_logic-และ-std_logic_vector)
- [3. numeric_std: unsigned และ signed](#3-numeric_std-unsigned-และ-signed)
- [4. subtype และ constrained subtype](#4-subtype-และ-constrained-subtype)
- [5. enumeration type](#5-enumeration-type)
- [6. array type](#6-array-type)
- [7. record type](#7-record-type)
- [8. access type และ physical type](#8-access-type-และ-physical-type)
- [9. attribute ที่ใช้บ่อย](#9-attribute-ที่ใช้บ่อย)
- [10. กับดักของ numeric_std](#10-กับดักของ-numeric_std)
- [11. ตารางเลือกชนิดข้อมูล](#11-ตารางเลือกชนิดข้อมูล)

---

## 1. หลักการเลือกชนิดข้อมูล

VHDL เป็นภาษาแบบ strongly typed หมายความว่า **ชนิดข้อมูลต่างกันไม่สามารถนำมา
ใช้ร่วมกันได้โดยไม่ตั้งใจและไม่มีการแปลงโดยอัตโนมัติ** ข้อดีคือจับชนิดผิดพลาด
ได้ตั้งแต่ตอนคอมไพล์ ข้อเสียคือต้องเขียนการแปลงให้ชัดเจน

กฎสามข้อที่ใช้ในคู่มือนี้

1. **ภายในโมดูล ให้ใช้ `unsigned` / `signed` เมื่อต้องคำนวณ**
   แปลงกลับเป็น `std_logic_vector` เฉพาะที่ขอบของโมดูล (ที่พอร์ต) เท่านั้น
2. **`std_logic_vector` ใช้สำหรับสัญญาณ ไม่ใช่สำหรับตัวเลข**
   เพราะมันมีค่า 'X' 'U' 'Z' 'W' 'L' 'H' ที่ตัวเลขไม่มี การคำนวณจึงไม่มีความหมาย
3. **ประกาศ `subtype` เพื่อใช้ชื่อแทนความกว้าง** เพื่อให้โค้ดอ่านง่ายและแก้จุดเดียวได้ทั้งโปรเจกต์

## 2. std_logic และ std_logic_vector

`std_logic` มี 9 ค่า

| ค่า | ความหมาย | ใช้ใน RTL จริงหรือไม่ |
|---|---|---|
| `'0'` | ตรรกะ 0 | ใช่ |
| `'1'` | ตรรกะ 1 | ใช่ |
| `'H'` | ตรรกะ 1 ที่ความต้านต่ำ (high impedance ในทางอุตสาหกรรมใช้ `'Z'`) | ไม่ |
| `'L'` | ตรรกะ 0 ที่ความต้านต่ำ | ไม่ |
| `'U'` | ไม่มีการขับ (uninitialized) | ใช้ในการตรวจสอบ |
| `'X'` | ค่าที่ขัดแย้งกัน (conflict / unknown) | ใช้ในการตรวจสอบ |
| `'Z'` | ความต้านต่ำสูง (high impedance) | ใช้ในบัสสามสถานะเท่านั้น |
| `'W'` | weak unknown | ไม่ |
| `'-'` | don't care | ไม่ใช้ใน RTL ที่ต้องตรวจสอบ |

`std_logic_vector` คือ array ของ `std_logic` ที่มีทิศทางลดลง

```vhdl
signal bus : std_logic_vector(7 downto 0);  -- 8 บิต มากไปน้อย
signal bit4 : std_logic_vector(0 to 3);    -- 4 บิต น้อยไปมาก
```

> **ทิศทางสำคัญในการสังเคราะห์** — `std_logic_vector(7 downto 0)` คือบิต 7 อยู่ซ้ายสุด
> (MSB) และบิต 0 อยู่ขวาสุด (LSB) เมื่อเขียนเป็นเลขฐานสอง `"1010_0000"` จะอ่านว่า MSB อยู่ซ้าย
> การสลับทิศทางเป็นการสลับ bit order ซึ่งเป็นบั๊กที่พบบ่อยในการต่อกับโมดูลอื่น
> คู่มือนี้ใช้ `(N-1 downto 0)` เป็นมาตรฐาน และใช้ `to_unsigned`/`to_signed`/`std_logic_vector`
> ในการแปลงเสมอ

## 3. numeric_std: unsigned และ signed

`ieee.numeric_std` เป็นแพ็กเกจมาตรฐานที่ให้การคำนวณบนเลขไบนารีที่ไม่มีค่า X

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

signal u : unsigned(7 downto 0);   -- เลขไม่มีเครื่องหมาย 0..255
signal s : signed(7 downto 0);     -- เลขมีเครื่องหมาย -128..127
```

### 3.1 การแปลงระหว่างชนิด

| ทิศทาง | คำสั่ง | หมายเหตุ |
|---|---|---|
| `std_logic_vector` → `unsigned` | `unsigned(v)` | ต้องมีความยาวเท่ากัน |
| `std_logic_vector` → `signed` | `signed(v)` | ต้องมีความยาวเท่ากัน |
| `unsigned` → `std_logic_vector` | `std_logic_vector(u)` | ไม่เปลี่ยนความยาว |
| `signed` → `std_logic_vector` | `std_logic_vector(s)` | ไม่เปลี่ยนความยาว |
| `std_logic_vector` → `integer` | `to_integer(u)` | `to_integer(signed(v))` สำหรับค่าติดลบ |
| `integer` → `std_logic_vector` | `to_unsigned(i, n)` | ต้องระบุความยาว |
| ขยายความยาว | `resize(u, n)` | `signed` ขยายจะคงค่าเครื่องหมาย |
| ตัดความยาว | `resize(u, n)` | ตัดบิตที่เกินออก |

### 3.2 ตัวดำเนินการที่ใช้บ่อย

```vhdl
u + v          -- บวก
u - v          -- ลบ
u * v          -- คูณ
u / v          -- หาร (integer division)
u mod v        -- เศษ
u mod 2**n     -- เก็บ n บิตล่าง
u sll 1        -- shift left เชิงตรรกะ
u srl 1        -- shift right เชิงตรรกะ
u sla 1        -- shift left เชิงเลขคณิต (เติม bit ที่หายไปด้วย bit เครื่องหมาย)
u sra 1        -- shift right เชิงเลขคณิต
u rol 1        -- rotate left
u ror 1        -- rotate right
not u          -- เติม 1 ทุกบิต (ทำงานกับ signed ได้)
u and v        -- ตรรกะ AND รายบิต
u or v
u xor v
u < v          -- เปรียบเทียบ (unsigned)
u = v
```

> `not` บน `signed` จะทำให้ค่าติดลบกลับเป็นบวก (เพราะ `not` คือ flip ทุกบิต)
> ถ้าต้องการลบสองส่วนของเลขมีเครื่องหมายให้ใช้ `-s` แทน `not s`

### 3.3 การขยายความยาวเพื่อจับ carry

เมื่อบวกเลข N บิต ผลลัพธ์ที่ถูกต้องอาจต้องมี N+1 บิต
**ห้ามบวกในความยาวเดิมแล้วหวังว่าจะได้ carry** เพราะการบวกเกินขอบเขต
จะหมุนกลับ (wrap around) โดยไม่แจ้งเตือน

```vhdl
-- ผิด: carry หาย
signal sum8 : unsigned(7 downto 0);
sum8 <= a + b;

-- ถูก: ขยายก่อนบวก
signal sum9 : unsigned(8 downto 0);
sum9 <= ('0' & a) + ('0' & b);        -- ต่อบิต 0 ด้านซ้าย
carry <= sum9(8);
result <= sum9(7 downto 0);
```

## 4. subtype และ constrained subtype

`subtype` สร้างชื่อแทนชนิดข้อมูลเดิม พร้อมจำกัดขอบเขตเพิ่มเติม

```vhdl
package dsp_types_pkg is
  subtype slv8_t is std_logic_vector(7 downto 0);
  subtype slv16_t is std_logic_vector(15 downto 0);
  subtype u4_t is unsigned(3 downto 0);
  subtype opcode_t is std_logic_vector(2 downto 0);
end package dsp_types_pkg;
```

ข้อดี

- เปลี่ยนความกว้างที่จุดเดียวแล้วทั้งโปรเจกต์เปลี่ยนตาม
- ใช้ `to_integer(u)` โดยไม่ต้องระบุความยาว
- ใช้กับ `signal` ได้โดยไม่ต้องเขียน `std_logic_vector(...)` ซ้ำ

> `subtype` **ไม่สร้างชนิดข้อมูลใหม่** จึงยังเข้ากันได้กับชนิดเดิมได้
> การตรวจสอบชนิดจะไม่จับกรณี `slv8_t` กับ `std_logic_vector(7 downto 0)` สลับกัน
> ถ้าต้องการความปลอดภัยระดับสูงขึ้นให้ใช้ `type` แทน `subtype` แต่ต้องแปลงให้ชัดเจน

## 5. enumeration type

ใช้สำหรับสถานะของ FSM ซึ่งเป็นจุดที่ VHDL ได้เปรียบกว่า Verilog อย่างชัดเจน

```vhdl
architecture rtl of traffic_fsm is
  type state_t is (S_RED, S_GREEN, S_YELLOW);

  constant S_RED_V : state_t := S_RED;   -- ถ้าจำเป็นต้องเทียบกับสัญญาณ
begin
  ...
end architecture rtl;
```

ข้อดีเหนือการใช้ `std_logic_vector` แทนสถานะ

| ข้อดี | อธิบาย |
|---|---|
| ตรวจจับสถานะที่ไม่ได้ประกาศ | `case` ที่ครบทุกสถานะ คอมไพล์ไม่ผ่านถ้ามีสถานะเพิ่ม |
| เขียน `case` ได้สั้นและอ่านง่าย | `when S_GREEN =>` แทน `when "001" =>` |
| `when others` จับการไม่รู้จักสถานะได้ | ค่าที่ไม่ใช่สถานะที่ประกาศ (เช่น X) จะเข้า `when others` |
| ใช้ attribute ได้ | `state_t'left`, `state_t'right`, `state_t'image(s)` |

> **ข้อควรระวัง**: เมื่อสถานะถูกเก็บใน signal ชนิด enum ค่าที่ผิดพลาดจะไม่ใช่ 'X'
> แต่จะกลายเป็นค่า enum ที่อยู่นอกช่วงที่ประกาศไว้ ซึ่งทำให้เครื่องมือจำลอง
> บางตัวรายงาน error หรือหยุดทำงาน ต้องมี `when others` เสมอใน `case` ที่แปลงสถานะ
> และควรมีทางออกสำหรับสถานะที่ผิดพลาด (ดูบทที่ 06)

## 6. array type

### 6.1 constrained array

```vhdl
type mem_t is array (0 to 15) of std_logic_vector(7 downto 0);
signal mem : mem_t;
```

### 6.2 unconstrained array

ใช้เป็นชนิดของพอร์ตที่ความยาวขึ้นกับ generic

```vhdl
entity fifo_sync is
  generic (
    DATA_WIDTH : positive := 8;
    ADDR_WIDTH : positive := 3
  );
  port (
    wr_data : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    rd_data : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end entity fifo_sync;
```

ใช้กับ generic ใน architecture เพื่อคำนวณขนาด

```vhdl
architecture rtl of fifo_sync is
  constant DEPTH : natural := 2 ** ADDR_WIDTH;
  type mem_t is array (0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
  signal mem : mem_t;
begin
  ...
end architecture rtl;
```

### 6.3 array ของ record และ array ของ enum

```vhdl
type state_t is (S_IDLE, S_RUN, S_DONE);
type state_hist_t is array (0 to 15) of state_t;
type regfile_t is array (0 to 31) of std_logic_vector(31 downto 0);
```

## 7. record type

เหมาะกับการรวมผลลัพธ์และ flag ที่ต้องส่งไปพร้อมกัน

```vhdl
type result_t is record
  value   : slv8_t;
  zero    : std_logic;
  carry   : std_logic;
  overflow: std_logic;
end record;

signal res_i : result_t;
```

วิธีใช้

```vhdl
res_i.value   := (others => '0');
res_i.zero    := '0';
res_i.carry   := '0';
res_i.overflow := '0';
-- ...
result <= res_i.value;
zero  <= res_i.zero;
```

> ต้องกำหนดค่าให้ครบ **ทุกฟิลด์** ก่อนใช้งาน ไม่เช่นนั้นฟิลด์ที่ไม่ได้กำหนด
> จะมีค่าที่ไม่นิยาม (เช่น 'U') ในการจำลอง

## 8. access type และ physical type

### 8.1 access type (pointer)

```vhdl
type node_t;
type node_ptr_t is access node_t;
type node_t is record
  value : integer;
  next  : node_ptr_t;
end record;
```

**ไม่ควรใช้ใน RTL** เพราะเครื่องมือสังเคราะห์ส่วนใหญ่ไม่รองรับ
และการจัดการหน่วยความจำแบบ dynamic ทำให้พฤติกรรมไม่คาดเดาได้
ใช้ได้เฉพาะใน testbench ที่ไม่ต้องสังเคราะห์

### 8.2 physical type

VHDL มี `time` เป็น physical type ที่ใช้ใน testbench

```vhdl
wait for 10 ns;
wait for 1.5 us;
wait for 200 ms;
```

หน่วยที่ใช้ได้: `fs`, `ps`, `ns`, `us`, `ms`, `sec`, `min`, `hr`

> ห้ามใช้ `time` ใน RTL ที่สังเคราะห์ เพราะเครื่องมือสังเคราะห์ไม่มีแนวคิดของเวลา

## 9. attribute ที่ใช้บ่อย

attribute เป็น "ข้อมูลเกี่ยวกับชนิดข้อมูลหรือวัตถุ" ที่ภาษาคำนวณให้

| attribute | คืนค่า | ใช้ทำอะไร |
|---|---|---|
| `v'left` | ขอบซ้าย (index มากที่สุด) | กำหนดค่าเริ่มต้นของ counter |
| `v'right` | ขอบขวา (index น้อยที่สุด) | ตรวจขอบเขต |
| `v'high` | ค่ามากที่สุด | `cnt <= (others => '0')` และการ wrap |
| `v'low` | ค่าน้อยที่สุด | เช่นเดียวกัน |
| `v'length` | จำนวนบิต | เทียบความยาว |
| `v'range` | ช่วงของ index | ใช้ใน loop |
| `t'pos(x)` | ตำแหน่งของ enum | แปลง enum ↔ integer |
| `t'val(n)` | สมาชิกที่ตำแหน่ง n | แปลง integer ↔ enum |
| `t'image(x)` | ข้อความของค่า | ใช้ใน report |
| `t'value(s)` | ค่าจากข้อความ | ใช้ใน testbench |
| `sig'event` | true เมื่อมี event | ตรวจ edge |
| `sig'last_value` | ค่าก่อนหน้า | ตรวจ edge ด้วยวิธีอื่น |
| `sig'stable` | true เมื่อไม่เปลี่ยน | ใช้ใน assertion |

ตัวอย่างที่ใช้บ่อยใน RTL

```vhdl
-- นับขึ้นและ wrap โดยไม่ต้องรู้ค่าสูงสุดเป็นตัวเลข
if cnt = cnt'high then
  cnt <= (others => '0');
else
  cnt <= cnt + 1;
end if;

-- สร้างค่าเริ่มต้นที่กว้างเท่ากับสัญญาณ
signal cnt : unsigned(ADDR_WIDTH downto 0) := (others => '0');
```

> `cnt'high` คือค่ามากที่สุดของชนิด **ไม่ใช่** จำนวนบิต
> ถ้าต้องการจำนวนบิตให้ใช้ `cnt'length`

## 10. กับดักของ numeric_std

### 10.1 เปรียบเทียบผิดชนิด

```vhdl
signal a : std_logic_vector(7 downto 0);
signal b : unsigned(7 downto 0);

if a < b then          -- ← ผิด: ผิดชนิด ไม่มี operator '<' ระหว่างสองชนิดนี้
```

ต้องแปลงก่อน: `if unsigned(a) < b then` หรือประกาศให้ชนิดเดียวกันตั้งแต่ต้น

### 10.2 ความยาวไม่เท่ากัน

```vhdl
signal a : unsigned(7 downto 0);
signal b : unsigned(3 downto 0);
signal c : unsigned(11 downto 0);

c <= a + b;   -- ← ผิด: ความยาวไม่เท่ากัน
```

ต้องใช้ `resize` อย่างเดียว: `c <= resize(a, 12) + resize(b, 12);`

### 10.3 overflow ที่ไม่ถูกตรวจจับ

`numeric_std` **ไม่ตรวจ overflow** ของการบวกลบ ผลลัพธ์จะหมุนกลับเงียบ ๆ
ต้องขยายความยาวเองหรือตรวจด้วยการเทียบกับผลลัพธ์ที่ขยาย (ดูบทที่ 08)

### 10.4 'X' ใน std_logic_vector ที่นำไปคำนวณ

`std_logic_vector` ที่มี 'X' เมื่อแปลงเป็น `unsigned` จะทำให้ผลลัพธ์เป็น 'X'
ทั้งหมดในหลายกรณี ซึ่งอาจทำให้ debug ยาก ให้ตรวจค่า X ก่อนแปลงใน testbench

### 10.5 การเทียบกับ integer

```vhdl
if to_integer(cnt) = 0 then   -- ชัดเจนแต่ช้า
```
```vhdl
if cnt = to_unsigned(0, cnt'length) then   -- เร็วกว่า เป็นวิธีที่แนะนำ
```

## 11. ตารางเลือกชนิดข้อมูล

| สิ่งที่ต้องเก็บ | ชนิดที่ใช้ | เหตุผล |
|---|---|---|
| สัญญาณดิจิทัลทั่วไป | `std_logic_vector` | ต้องรองรับ 'X' และ 'Z' ในการตรวจสอบ |
| ตัวเลขที่ต้องบวกลบคูณ | `unsigned` / `signed` | คำนวณถูกต้อง ตรวจ overflow ได้ง่าย |
| ตัวนับและพอร์ตเอาต์พุตที่เป็นตัวเลข | `unsigned` | เทียบกับค่าคงที่ได้ง่าย ไม่ต้องแปลง |
| สถานะของ FSM | `enum` | ตรวจจับสถานะที่ไม่ได้ประกาศได้ |
| ผลลัพธ์ที่มีหลาย flag | `record` | ส่งเป็นชุดเดียว ลดจำนวนพอร์ต |
| หน่วยความจำ | `array` ของ `std_logic_vector` | สังเคราะห์เป็น RAM ได้ |
| ความกว้างที่ใช้ซ้ำหลายที่ | `subtype` | แก้จุดเดียวได้ทั้งโปรเจกต์ |
| ตัวชี้ | `access` | **ไม่ใช้ใน RTL** |

---

## แบบฝึกหัดท้ายบท

1. แก้ `ex01_alu_comb` ให้ใช้ `unsigned` ภายในโมดูลและ `std_logic_vector` ที่พอร์ต
   แล้วรันสคริปต์ตรวจซ้ำเพื่อยืนยันว่าผลการจำลองเหมือนเดิม
2. เขียนฟังก์ชัน `clamp_u(v : unsigned; max : unsigned) return unsigned`
   ที่คืนค่า `v` ถ้า `v <= max` มิฉะนั้นคืน `max` แล้วทดสอบด้วยค่าขอบเขต
3. เขียน FSM สถานะสองสถานะด้วย `enum` แล้วเพิ่มสถานะที่สาม จากนั้นสังเกตว่า
   `case` ที่ไม่มี `when others` จะถูกจับ error ที่จุดใด
4. เปรียบเทียบเวลาที่ใช้ของ `to_integer(cnt) = 0` กับ
   `cnt = to_unsigned(0, cnt'length)` ด้วยการรันจำลองและดูเวลาที่ใช้
5. สร้าง `subtype` สำหรับความกว้าง 16 บิต แล้วใช้แทน `std_logic_vector(15 downto 0)`
   ทั้งโปรเจกต์ แล้วอธิบายว่าข้อดีของ `subtype` คืออะไรและข้อจำกัดคืออะไร

## คำถามท้ายบท

1. ทำไมการบวก `unsigned` ความยาว 8 บิตสองตัวแล้วเก็บผลใน 8 บิต จึงไม่สามารถ
   ตรวจจับ carry ได้ และต้องแก้อย่างไร
2. ข้อเสียของ `subtype` เมื่อเทียบกับ `type` คืออะไร และมีผลต่อการตรวจจับ
   ชนิดข้อมูลผิดอย่างไร
3. เมื่อสถานะ FSM เก็บใน signal ชนิด enum แล้วมีค่าที่ผิดพลาด
   พฤติกรรมของ `when others` จะเป็นอย่างไร และต้องป้องกันอย่างไร
4. การใช้ `not` กับ `signed` ต่างจากการใช้ `-` อย่างไร และกรณีใดที่ระบบจะพลาด
5. `v'high` กับ `v'length` ต่างกันอย่างไร และมีกรณีใดที่การสับสนทำให้โค้ดผิด

---

**อ่านต่อ:** [บทที่ 03 — รูปแบบการเขียนโค้ดและการตั้งชื่อ](03-style-and-naming.md)

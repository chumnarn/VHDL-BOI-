# บทที่ 01: โครงสร้างภาษาและ design unit

> บทนี้อธิบายว่าโค้ด VHDL หนึ่งไฟล์ถูกประกอบขึ้นจากอะไรบ้าง
> และเหตุผลที่ context clause ต้องประกาศซ้ำก่อนทุก design unit
> ซึ่งเป็นข้อผิดพลาดที่พบบ่อยที่สุดของผู้เรียนใหม่

**เครื่องมือที่เกี่ยวข้อง:** GHDL 1.0.0 (`ghdl -a`, `ghdl -e`, `ghdl -r`)

---

## สารบัญบท

- [1. design unit คืออะไร](#1-design-unit-คืออะไร)
- [2. library และ use clause](#2-library-และ-use-clause)
- [3. context clause มีผลกับหนึ่งหน่วยเท่านั้น](#3-context-clause-มีผลกับหนึ่งหน่วยเท่านั้น)
- [4. entity](#4-entity)
- [5. architecture](#5-architecture)
- [6. concurrent statement กับ sequential statement](#6-concurrent-statement-กับ-sequential-statement)
- [7. configuration และการผูก architecture](#7-configuration-และการผูก-architecture)
- [8. ลำดับการคอมไพล์และการอ้างอิงข้ามไฟล์](#8-ลำดับการคอมไพล์และการอ้างอิงข้ามไฟล์)
- [9. ตัวอย่างอ้างอิง: โมดูลขั้นต่ำ](#9-ตัวอย่างอ้างอิง-โมดูลขั้นต่ำ)

---

## 1. design unit คืออะไร

VHDL แบ่งโค้ดออกเป็นหน่วยที่คอมไพล์แยกกัน เรียกว่า **design unit**
แต่ละหน่วยมีหน้าที่เฉพาะ และโปรเจกต์จริงจะประกอบหน่วยเหล่านี้เข้าด้วยกัน

| ชนิด design unit | หน้าที่ | ตัวอย่างในคู่มือนี้ |
|---|---|---|
| `entity` | ประกาศ "ขอบเขตของโมดูล" คือพอร์ตและ generic | ทุกโมดูล |
| `architecture` | ประกาศ "การทำงานภายใน" ของ entity | ทุกโมดูล |
| `package declaration` | รวม type, subtype, constant, function, procedure ที่ใช้ร่วมกัน | `dsp_types_pkg`, `uart_pkg` |
| `package body` | บรรยายการทำงานของ function/procedure ใน package | `alu_ops_pkg` |
| `configuration` | ผูก entity กับ architecture ที่ต้องการใช้ | ไม่จำเป็นในโปรเจกต์ทั่วไป |
| `context declaration` | ตั้งค่า library/use ที่ใช้ร่วมกัน (VHDL-2008) | กล่าวถึงในบทที่ 9 |

> **กฎที่ใช้ในคู่มือนี้** — ในไฟล์หนึ่งไฟล์ให้มี entity และ architecture ที่เป็นของกัน
> และประกาศ context clause ซ้ำก่อนทุกหน่วย เพื่อให้ตัวอย่างใดตัวอย่างหนึ่งนำไป
> วางในโปรเจกต์อื่นได้ทันทีโดยไม่ต้องแก้แม้แต่บรรทัดเดียว

## 2. library และ use clause

- `library` คือ "กลุ่มของ design unit ที่ถูกคอมไพล์แล้ว" เช่น `work` คือไดเรกทอรี
  ที่เก็บผลการคอมไพล์ของโปรเจกต์ปัจจุบัน
- `use` คือ "ขอเข้าถึงชื่อที่ประกาศไว้ในหน่วยที่ระบุ"
- `ieee` เป็น library มาตรฐานที่มี `std_logic_1164`, `numeric_std`, `std_logic_textio`,
  `std_logic_unsigned` (ไม่แนะนำ), `math_real` เป็นต้น

```vhdl
library ieee;
use ieee.std_logic_1164.all;   -- ชนิด std_logic, std_logic_vector
use ieee.numeric_std.all;     -- ชนิด unsigned, signed และการคำนวณ
use ieee.std_logic_textio.all; -- hread, read, write สำหรับไฟล์ข้อความ
```

> **ห้ามใช้ `ieee.std_logic_arith`** เพราะมีนิยาม `+`, `-`, `*` ซ้ำกับ `numeric_std`
> เมื่อทั้งสองถูก `use` พร้อมกันจะเกิดข้อผิดพลาด "operator is ambiguous"
> และพฤติกรรมของ `std_logic_vector` จะต่างจาก `numeric_std` ในบางกรณี

## 3. context clause มีผลกับหนึ่งหน่วยเท่านั้น

นี่คือกฎที่ทำให้ผู้เรียนใหม่เสียเวลามาก กฎของภาษาระบุว่า
**context clause (บรรทัด `library`/`use`) มีผลกับ design unit ถัดไปหนึ่งหน่วยเท่านั้น**

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity counter is           -- ← ใช้ std_logic ได้
  port (
    clk : in  std_logic;
    q   : out std_logic
  );
end entity counter;

architecture rtl of counter is  -- ← ไม่มี context clause ติดมา จึงไม่รู้จัก std_logic
  signal c : std_logic;         -- ← error: Unknown identifier "std_logic"
begin
  ...
end architecture rtl;
```

วิธีแก้ที่ถูกต้องและเป็นมาตรฐานของคู่มือนี้: **ประกาศซ้ำก่อนทุก design unit**

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity counter is
  ...
end entity counter;

library ieee;                  -- ← ประกาศซ้ำ
use ieee.std_logic_1164.all;

architecture rtl of counter is
  ...
end architecture rtl;
```

ข้อควรระวังที่เกี่ยวข้อง: ถ้าไฟล์มี `package` ที่ประกาศไว้ **หลัง** entity ที่ใช้มัน
การคอมไพล์จะล้มเหลว เพราะการคอมไพล์เป็นลำดับและแต่ละหน่วยต้องเห็นหน่วยที่คอมไพล์แล้วเท่านั้น
แนวทางแก้คือแยก package ไว้ในไฟล์ของตัวเองและคอมไพล์ก่อนเสมอ

## 4. entity

```vhdl
entity <ชื่อ> is
  generic (
    <ชื่อ_generic> : <ชนิด> := <ค่าเริ่มต้น>;
    ...
  );
  port (
    <ชื่อพอร์ต> : in    <ชนิด>;
    <ชื่อพอร์ต> : out   <ชนิด>;
    <ชื่อพอร์ต> : inout <ชนิด>;
    <ชื่อพอร์ต> : buffer <ชนิด>
  );
end entity <ชื่อ>;
```

### 4.1 generic กับ port

| องค์ประกอบ | ใช้ทำอะไร | ตัวอย่าง |
|---|---|---|
| `generic` | ค่าคงที่ที่กำหนด "รูปร่าง" ของโมดูล เช่น ความกว้างบิต ความลึก FIFO ค่าที่ผู้เรียน override ได้ตอนสร้าง instance | `DATA_WIDTH : positive := 8` |
| `port` | สัญญาณที่ข้ามขอบเขตของโมดูล | `clk : in std_logic` |

> **generic ไม่ใช่สัญญาณ** จึงใช้ค่าคงที่ได้เฉพาะตอน compile
> ไม่สามารถเปลี่ยนค่าในระหว่างการทำงานได้
> ถ้าต้องการค่าที่เปลี่ยนได้ในเวลารัน ให้ใช้ port แทน

### 4.2 port mode

| mode | ทิศทาง | หมายเหตุ |
|---|---|---|
| `in` | เข้าโมดูลเท่านั้น | โมดูลอ่านได้ โมดูลเขียนไม่ได้ |
| `out` | ออกจากโมดูลเท่านั้น | โมดูลเขียนได้ |
| `inout` | เข้าและออก | ใช้กับสัญญาณสองทาง เช่น bus ของ Avalon |
| `buffer` | ออก และอ่านกลับได้ | ใช้ได้เฉพาะ VHDL-2008 ในบางเครื่องมือ |

**ข้อจำกัดที่สำคัญใน VHDL-2002** — โมดูลไม่สามารถอ่านค่า `out` port ของตัวเองได้
ในมาตรฐาน VHDL-2002 (VHDL-2008 อนุญาตให้อ่านได้ แต่เครื่องมือรุ่นเก่าอาจไม่รองรับ)
แนวทางที่ใช้ในคู่มือนี้: **สร้าง signal ภายในแล้วส่งค่าออกพอร์ตทีละจุด**

```vhdl
architecture rtl of fifo_sync is
  signal count_i : unsigned(ADDR_WIDTH downto 0);  -- คำนวณภายใน
  signal full_i  : std_logic;
begin
  full_i <= '1' when count_i = to_unsigned(DEPTH, count_i'length) else '0';
  full  <= full_i;                                  -- ส่งออกพอร์ตที่จุดเดียว
end architecture rtl;
```

## 5. architecture

architecture แบ่งเป็น 2 ส่วน

```vhdl
architecture rtl of <ชื่อ> is
  -- declarative part: ประกาศ signal, constant, type, function, procedure
begin
  -- statement part: concurrent statements
end architecture rtl;
```

- **declarative part** ประกาศสิ่งที่มีอยู่ "ถาวร" เช่น signal ภายใน, constant, type
- **statement part** บรรยาย "พฤติกรรม" ด้วย concurrent statement

ตัวเลือกของ architecture ที่ใช้ในโปรเจกต์จริง

| ชื่อ | ใช้เมื่อ |
|---|---|
| `rtl` | เป็นการทำงานหลักที่สังเคราะห์ได้ (คู่มือนี้ใช้ชื่อนี้เป็นมาตรฐาน) |
| `tb` / `testbench` | เป็นโค้ดจำลองที่ไม่สังเคราะห์ |
| `behavioral` / `gate_level` | จำลองระดับพฤติกรรมหรือระดับ gate (นอกขอบเขตของคู่มือนี้) |

> ถ้า entity มีหลาย architecture ต้องระบุว่าจะใช้ตัวไหน มิฉะนั้นเครื่องมือจะเลือก
> architecture ที่มีชื่อตรงกับชื่อ entity ก่อน แล้วจึงเลือก architecture ชื่อ `rtl`
> หรือ architecture ที่ประกาศไว้ล่าสุด ดูรายละเอียดในหัวข้อถัดไป

## 6. concurrent statement กับ sequential statement

### 6.1 concurrent statement

เป็นคำสั่งที่ "ทำงานพร้อมกัน" ทุกตัวใน architecture โดยไม่ต้องรอจบกัน
ประกอบด้วย

| ชนิด | ใช้ทำอะไร | ตัวอย่าง |
|---|---|---|
| signal assignment | ขับสัญญาณ | `q <= d;` |
| component instantiation | เรียกโมดูลอื่น | `u_alu : entity work.alu_comb port map (...);` |
| `process` | กลุ่มคำสั่งที่ทำงานตามลำดับเวลา | `process (clk) begin ... end process;` |
| `generate` | สร้างโครงสร้างซ้ำ | `g : for i in 0 to 7 generate ... end generate;` |
| `assert` (concurrent) | ตรวจเงื่อนไขต่อเนื่อง | `assert x = '1' report "..." severity failure;` |

### 6.2 sequential statement

อยู่ภายใน `process` เท่านั้น ทำงานตามลำดับ ได้แก่ `if`, `case`, `loop`, `wait`,
signal assignment (แบบ `<=`), variable assignment (แบบ `:=`)

### 6.3 กฎของ signal assignment

| อยู่ใน process | ชนิดของตัวแปรที่ถูก assign | ต้องใช้ |
|---|---|---|
| combinational process (ไม่มีนาฬิกา) | signal | `<=` |
| combinational process (ไม่มีนาฬิกา) | variable | `:=` |
| clocked process (มีนาฬิกา) | signal | `<=` |
| clocked process (มีนาฬิกา) | variable | `:=` |

**ข้อผิดพลาดที่พบบ่อยที่สุด** — ใช้ `:=` กับ signal ที่ประกาศนอก process

```vhdl
architecture rtl of bad is
  signal q : std_logic;     -- signal
begin
  process (clk)
  begin
    if rising_edge(clk) then
      q := d;               -- ← ผิด: ต้องใช้ <=
    end if;
  end process;
end architecture rtl;
```

GHDL จะรายงานว่า `q` เป็น signal และไม่สามารถใช้ `:=` ได้ แต่เครื่องมือรุ่นเก่าบางตัว
อาจรับได้แล้วสร้าง latch แทน flip-flop ซึ่งเป็นบั๊กที่หายากกว่าที่คิด

## 7. configuration และการผูก architecture

โดยปกติเครื่องมือจะเลือก architecture ให้อัตโนมัติ แต่ถ้ามีหลายตัวให้ระบุชัดเจน

```vhdl
configuration cfg_counter of counter is
  for rtl
    for counter
      work.counter(rtl)
    end for;
  end for;
end configuration cfg_counter;
```

ในโปรเจกต์ทั่วไปไม่ต้องใช้ configuration เพราะมีเพียง architecture เดียว
แต่ควรรู้ไว้เพราะเมื่อเจอ error ว่า "architecture ไม่ถูกเลือก" ต้องรู้ว่าจะแก้ที่ไหน

## 8. ลำดับการคอมไพล์และการอ้างอิงข้ามไฟล์

### 8.1 ลำดับที่ถูกต้อง

```text
1. package declaration   (ถ้ามี)
2. package body          (ถ้ามี)
3. entity ของโมดูลที่ถูกเรียกใช้
4. architecture ของโมดูลที่ถูกเรียกใช้
5. entity + architecture ของโมดูลระดับบน
6. testbench
```

### 8.2 การเรียกใช้โมดูล

```vhdl
-- แบบ direct entity instantiation (VHDL-93 เป็นต้น) — แนะนำ
u_alu : entity work.alu_comb
  generic map (
    DATA_WIDTH => 8
  )
  port map (
    a => a_i,
    b => b_i,
    result => result_o
  );

-- แบบ component instantiation — ใช้เมื่อต้องเลือก configuration
u_alu : component alu_comb
  port map (
    a => a_i,
    b => b_i,
    result => result_o
  );
```

ข้อดีของ direct entity instantiation: ตรวจจับชื่อพอร์ตผิดได้ทันทีตอนคอมไพล์
ข้อดีของ component instantiation: เลือก architecture ได้ยืดหยุ่นกว่า
คู่มือนี้แนะนำ **direct entity instantiation** เป็นหลัก

### 8.3 คำสั่งคอมไพล์แบบมาตรฐาน

```bash
# วิเคราะห์ (analyze) แยกต่อไฟล์หรือเป็นกลุ่มก็ได้
ghdl -a --std=08 --workdir=work src/dsp_types_pkg.vhd src/alu_ops_pkg.vhd
ghdl -a --std=08 --workdir=work src/alu_comb.vhd
ghdl -a --std=08 --workdir=work tb/tb_alu_comb.vhd

# สร้าง executable (elaborate)
ghdl -e --std=08 --workdir=work tb_alu_comb

# จำลอง (run)
ghdl -r --std=08 --workdir=work tb_alu_comb
```

หากคอมไพล์แล้วมี error ให้แก้ไฟล์ต้นเหตุแล้วคอมไพล์ใหม่เฉพาะไฟล์ที่แก้
GHDL จะรายงานบรรทัดและคอลัมน์ที่ผิดพร้อมข้อความอธิบาย

## 9. ตัวอย่างอ้างอิง: โมดูลขั้นต่ำ

ตัวอย่างต่อไปนี้คือโครงสร้างขั้นต่ำที่สุดที่ยังเป็น RTL ที่สังเคราะห์ได้
ไฟล์จริงอยู่ที่ `code/reference/vhdl/examples/ex00_minimal_dut/src/dff_simple.vhd`

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity dff_simple is
  port (
    clk   : in  std_logic;
    rst_n : in  std_logic;
    d     : in  std_logic;
    q     : out std_logic
  );
end entity dff_simple;

library ieee;                  -- context clause ซ้ำ เพราะมีผลกับหนึ่งหน่วยเท่านั้น
use ieee.std_logic_1164.all;

architecture rtl of dff_simple is
begin
  seq_p : process (clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        q <= '0';
      else
        q <= d;
      end if;
    end if;
  end process;
end architecture rtl;
```

ข้อสังเกต

1. `end entity dff_simple;` และ `end architecture rtl;` เขียนชื่อกำกับไว้เสมอ
   ตัวคอมไพล์จะบอกตำแหน่งที่ผิดได้แม่นยำขึ้นเมื่อไฟล์ยาว
2. `seq_p` ตั้งชื่อ process ไว้ อ่านโค้ดยาว ๆ ได้ง่ายขึ้น
3. ไม่มี signal ภายในเลย เพราะโมดูลนี้ไม่ต้องมี — การประกาศ signal ภายในที่ไม่ได้
   ใช้งานจริงเป็นสัญญาณรบกวนและทำให้เครื่องมือเตือน
4. `q` เป็น `out` port ที่ถูกกำหนดค่าใน clocked process ตรง ๆ ได้
   ถ้ามี signal ภายในที่ถูก assign ใน clocked process จะกลายเป็น latch
   ซึ่งเป็นข้อผิดพลาดที่พบบ่อยมาก (ดูบทที่ 04)

---

## แบบฝึกหัดท้ายบท

1. สร้างไฟล์ `src/one_bit.vhd` ที่มี entity `one_bit` และ architecture `rtl`
   โดยตั้งใจไม่ประกาศ context clause ก่อน architecture แล้วรัน
   `ghdl -a --std=08 --workdir=work src/one_bit.vhd` จดข้อความ error ที่ได้
   แล้วแก้จนคอมไพล์ผ่าน
2. เพิ่ม signal ภายในชื่อ `q_i` ใน architecture ของ `one_bit` แล้ว assign
   ค่าให้ `q_i` ภายใน clocked process แล้วสังเกตความต่างของผลจำลองเมื่อ
   `d` เปลี่ยนค่ากลางรอบนาฬิกา
3. เขียนโมดูล `two_bit` ที่มี 2 bit เรียงกัน โดยใช้ `generate` แทนการเขียนซ้ำ
   แล้วเทียบผลกับการเขียนแบบไม่ใช้ generate
4. ทดลองสร้าง `configuration` ที่ผูก `one_bit` เข้ากับ architecture ที่ชื่อไม่ใช่ `rtl`
   แล้วสังเกตว่าเครื่องมือเลือกอย่างไร

## คำถามท้ายบท

1. เหตุใด context clause จึงมีผลกับ design unit ถัดไปเพียงหน่วยเดียว
   และถ้าไม่ประกาศซ้ำจะเกิดอาการอย่างไร
2. generic กับ port ต่างกันอย่างไรในเชิงเวลาและความสามารถ
3. ทำไมการอ่านค่า `out` port ของตัวเองไม่ได้ใน VHDL-2002 และต้องใช้ signal ภายในแทน
4. การใช้ `:=` กับ signal ที่ประกาศนอก process ทำให้เกิดอะไรในวงจรจริง
   และทำไม GHDL จึงรายงานเป็น error
5. ข้อดีของ direct entity instantiation เหนือ component instantiation คืออะไร

---

**อ่านต่อ:** [บทที่ 02 — ชนิดข้อมูล](02-data-types.md)

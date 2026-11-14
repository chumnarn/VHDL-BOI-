# บทที่ 04: ตรรกะ combinational

> บทนี้อธิบายการเขียนวงจรที่ไม่มีหน่วยความจำ ซึ่งเป็นพื้นฐานของทุกโมดูล
> รวมถึงกฎป้องกัน latch ที่เป็นบั๊กที่พบบ่อยที่สุดของโค้ด RTL

**เครื่องมือที่เกี่ยวข้อง:** GHDL 1.0.0, `ghdl --synth`
**ตัวอย่างอ้างอิง:** `code/reference/vhdl/examples/ex01_alu_comb/`

---

## สารบัญบท

- [1. นิยามและคุณสมบัติ](#1-นิยามและคุณสมบัติ)
- [2. รูปแบบการเขียนที่ใช้ในโปรเจกต์นี้](#2-รูปแบบการเขียนที่ใช้ในโปรเจกต์นี้)
- [3. กฎกำหนดค่าให้ครบ และเหตุผลที่เรียกว่า latch](#3-กฎกำหนดค่าให้ครบ-และเหตุผลที่เรียกว่า-latch)
- [4. วิธีตรวจจับ latch](#4-วิธีตรวจจับ-latch)
- [5. เปรียบเทียบ if, case และ with-select](#5-เปรียบเทียบ-if-case-และ-with-select)
- [6. การใช้ function ในตรรกะ combinational](#6-การใช้-function-ในตรรกะ-combinational)
- [7. ข้อผิดพลาดที่พบบ่อย](#7-ข้อผิดพลาดที่พบบ่อย)
- [8. combinational loop](#8-combinational-loop)
- [9. เรื่องของเวลา: delta cycle และ glitch](#9-เรื่องของเวลา-delta-cycle-และ-glitch)

---

## 1. นิยามและคุณสมบัติ

วงจร combinational คือวงจรที่ **เอาต์พุตขึ้นอยู่กับอินพุตในขณะนี้เท่านั้น**
ไม่มีหน่วยความจำ ไม่มีนาฬิกา จึงไม่มี delay cycle แต่มี delay ทางกายภาพ

| คุณสมบัติ | ผลต่อการออกแบบ |
|---|---|
| เอาต์พุตเปลี่ยนทันทีเมื่ออินพุตเปลี่ยน | ใช้เป็นตรรกะระหว่าง register ได้ |
| ไม่มีสถานะ | สังเคราะห์เป็น gate โดยไม่ต้องมี flip-flop |
| เส้นทางของสัญญาณอาจยาวไม่เท่ากัน | เกิด **glitch** ได้เมื่ออินพุตเปลี่ยน (ดูหัวข้อ 9) |
| ถ้าเอาต์พุตขึ้นกับเอาต์พุตของตัวเอง | เกิด **combinational loop** (ดูหัวข้อ 8) |

## 2. รูปแบบการเขียนที่ใช้ในโปรเจกต์นี้

### 2.1 แบบ process (ใช้บ่อยที่สุด)

```vhdl
architecture rtl of mux4 is
  signal y_o : std_logic_vector(3 downto 0);
begin
  comb_p : process (sel, d0, d1, d2, d3)
  begin
    case sel is
      when "00"   => y_o <= d0;
      when "01"   => y_o <= d1;
      when "10"   => y_o <= d2;
      when "11"   => y_o <= d3;
      when others => y_o <= (others => '0');
    end case;
  end process comb_p;
end architecture rtl;
```

ข้อกำหนด

- sensitivity list ต้องครบทุกสัญญาณที่อ่านใน process
- ต้องมี `when others` หรือค่าเริ่มต้นครบทุก path
- ตั้งชื่อ process เสมอ

### 2.2 แบบ concurrent signal assignment

เหมาะกับตรรกะง่าย ๆ ที่ไม่ต้องมี process

```vhdl
architecture rtl of mux4 is
begin
  y_o <= d0 when sel = "00" else
         d1 when sel = "01" else
         d2 when sel = "10" else
         d3;
end architecture rtl;
```

ข้อดี: สั้น อ่านง่าย เหมาะกับ mux, priority encoder, และการเลือกค่าคงที่

### 2.3 แบบ with-select

เหมาะกับการเลือกระหว่างค่าคงที่หรือสัญญาณ ตามตัวเลือก

```vhdl
architecture rtl of mux4 is
begin
  with sel select
    y_o <= d0 when "00",
           d1 when "01",
           d2 when "10",
           d3 when others;
end architecture rtl;
```

### 2.4 แบบ if-then-else แบบ concurrent

```vhdl
architecture rtl of mux4 is
begin
  y_o <= d0 when sel = "00" else
         d1 when sel = "01" else
         d2 when sel = "10" else
         d3 when sel = "11" else
         (others => '0');
end architecture rtl;
```

> **ในโปรเจกต์นี้ใช้แบบ process เป็นหลัก** เพราะจะเขียน `when others` ได้ชัดเจน
> และรวมหลายเงื่อนไขในโมดูลเดียวได้ง่ายกว่า
> แบบ concurrent ใช้เมื่อตรรกะสั้นและอ่านง่ายกว่า

### 2.5 เรื่อง `process (all)` ของ VHDL-2008

VHDL-2008 อนุญาตให้เขียน `process (all)` ซึ่งหมายถึง "อ่านสัญญาณใดก็ได้ที่อยู่ใน scope
และทำให้ไม่ต้องพลาดการระบุ sensitivity list"

```vhdl
  comb_p : process (all)      -- ← ใช้ได้เฉพาะ VHDL-2008
  begin
    ...
  end process comb_p;
```

**ข้อจำกัดของคู่มือนี้**: โค้ดที่ส่งให้ผู้เรียนต้องคอมไพล์ด้วย `--std=02` ได้
`process (all)` ทำให้คอมไพล์ไม่ผ่านในมาตรฐาน VHDL-2002
ดังนั้น **ระบุ sensitivity list ให้ครบเสมอ**

ถ้าต้องการความปลอดภัยจากการพลาด sensitivity list ให้ใช้เครื่องมือช่วยตรวจ
แทนการใช้ `process (all)` — ดู [บทที่ 12](12-tools-and-commands.md)

## 3. กฎกำหนดค่าให้ครบ และเหตุผลที่เรียกว่า latch

**กฎ: ใน combinational process ต้องมีการกำหนดค่าให้กับทุก output ในทุก path ที่เป็นไปได้**

ถ้ามี path ที่ไม่ได้กำหนดค่า เครื่องมือจำลองจะเก็บค่าเดิมไว้
ซึ่งในวงจรจริงหมายถึง **latch** — วงจรที่จำค่าเดิมไว้และเปลี่ยนเอาต์พุตเมื่ออินพุตเปลี่ยน
ซึ่งไม่ใช่พฤติกรรมของวงจร combinational

ตัวอย่างที่ผิด

```vhdl
comb_p : process (sel, d0, d1)
begin
  case sel is
    when "00"   => y_o <= d0;
    when "01"   => y_o <= d1;
    -- ไม่มี "10", "11" และไม่มี when others
  end case;
end process comb_p;
```

เมื่อ `sel` เป็น "10" หรือ "11" เอาต์พุต `y_o` จะคงค่าเดิม → latch

### 3.1 วิธีป้องกัน 3 ชั้น

ชั้นที่ 1 — กำหนดค่าเริ่มต้นให้ครบก่อน `case`

```vhdl
comb_p : process (sel, d0, d1)
begin
  y_o <= (others => '0');          -- ← ค่าเริ่มต้นครบทุกบิต
  case sel is
    when "00"   => y_o <= d0;
    when "01"   => y_o <= d1;
    when others => y_o <= (others => '0');
  end case;
end process comb_p;
```

ชั้นที่ 2 — มี `when others` ที่กำหนดค่าครบ

ชั้นที่ 3 — ตรวจด้วยเครื่องมือ (ดูหัวข้อ 4)

> **หมายเหตุ**: การกำหนดค่าเริ่มต้นเป็น `U` หรือ `X` ไม่ใช่การป้องกัน latch
> เพราะยังคงเป็นการ "ไม่ได้กำหนดค่าในทุก path" จากมุมมองของเครื่องมือสังเคราะห์
> ให้กำหนดค่าจริงเสมอ เช่น `(others => '0')`

### 3.2 กรณีที่ latch อาจเป็นสิ่งที่ต้องการจริง

บางโครงสร้างใช้ latch โดยเจตนา เช่น ตัวเก็บข้อมูลแบบ latch
หรือ memory ที่อ่านแบบ asynchronous แต่ต้องเขียน comment และ attribute
บอกเครื่องมือสังเคราะห์อย่างชัดเจนว่าต้องการ latch

ในโปรเจกต์นี้ **ไม่มีการออกแบบให้ใช้ latch ใน RTL** เพราะทำให้เวลาในการวิเคราะห์
(STA) วิเคราะห์ได้ยากและไม่ตรวจจับบั๊กได้ดี

## 4. วิธีตรวจจับ latch

### 4.1 ด้วย GHDL และการสังเคราะห์

```bash
ghdl --synth --std=08 --workdir=work alu_comb
```

ผลลัพธ์ของ `ghdl --synth` จะเป็น netlist ระดับ gate
ถ้ามี latch จะปรากฏเป็น cell latch ในผลลัพธ์ ให้ตรวจด้วยคำสั่ง

```bash
ghdl --synth --std=08 --workdir=work alu_comb | grep -i latch
```

ถ้าไม่มีผลลัพธ์ แปลว่าไม่มี latch

### 4.2 ด้วยการอ่านรายงานของเครื่องมือสังเคราะห์อื่น

| เครื่องมือ | วิธีตรวจ |
|---|---|
| Yosys | `yosys -p "read_vhdl ...; proc; opt; check"` แล้วดูข้อความ `Warning: ... inferred latch` |
| Synopsys / Cadence | ดูรายงาน "Inferred latches" ใน Design Compiler หรือ Genus |
| Quartus | ดู warning `Inferred latch for ...` |

### 4.3 ด้วย testbench

เขียน testbench ที่เปลี่ยนอินพุตในช่วงที่ไม่มีขอบนาฬิกา แล้วตรวจว่าเอาต์พุตเปลี่ยนตาม
ถ้าเอาต์พุตไม่เปลี่ยน แปลว่ามี latch

```vhdl
-- ตรวจว่าเป็น combinational จริง: เปลี่ยนอินพุตแล้วรอ 1 ns เอาต์พุตต้องตรง
din <= x"5A";
wait for 1 ns;
assert dout = x"5A" report "output did not follow input (latch?)" severity failure;
```

ตัวอย่างนี้อยู่ใน `code/reference/vhdl/examples/ex01_alu_comb/tb/tb_alu_comb.vhd`

## 5. เปรียบเทียบ if, case และ with-select

| ประเด็น | `if ... then` | `case` | `with ... select` |
|---|---|---|---|
| เลือกจากหลายค่า | ต้องเขียน `elsif` ซ้ำ | เหมาะกับการเลือกค่าเดียวจากตัวแปร | เหมาะกับการเลือกค่าเดียวจากตัวแปร |
| ตรวจความครบถ้วน | ตรวจไม่ได้ | ตรวจได้ (ถ้า selector เป็น enum) | ตรวจได้ในบางกรณี |
| `when others` | ไม่มี | มี | มี |
| อ่านง่าย | ดีเมื่อเงื่อนไขไม่ใช่การเทียบค่า | ดีเมื่อเทียบค่าหลายค่า | ดีมากสำหรับ mux |
| ใช้ใน combinational process | ได้ | ได้ | เป็น concurrent statement |

### 5.1 ข้อควรระวังของ `case` ที่ใช้กับ `std_logic_vector`

`case` บน `std_logic_vector` จะเทียบค่าทั้งหมดแบบตรงตัว
ค่า 'X' จะไม่ match กับ "01" หรือ "10" แต่จะเข้า `when others`
ซึ่งเป็นสิ่งที่ต้องการ เพราะทำให้ค่าที่ไม่รู้จักถูกดันกลับเข้าสู่สถานะที่กำหนดไว้

### 5.2 ข้อควรระวังของ `case` บนชนิด enum

```vhdl
type state_t is (S_IDLE, S_RUN, S_DONE);

case state_i is
  when S_IDLE => ...
  when S_RUN  => ...
  when S_DONE => ...
  -- ถ้าไม่มี when others แล้วเพิ่มสถานะในภายหลัง จะคอมไพล์ไม่ผ่าน
end case;
```

การไม่มี `when others` จะทำให้คอมไพล์ไม่ผ่านเมื่อมีการเพิ่มสถานะ
ซึ่งเป็นข้อดีของการตรวจแบบ compile-time แต่ต้องเขียน `when others` สำหรับค่าที่
ผิดพลาดในการจำลอง (ดู [บทที่ 06](06-fsm.md))

## 6. การใช้ function ในตรรกะ combinational

`function` ที่ประกาศใน package สามารถเรียกใช้ใน combinational process ได้
เหมาะกับตรรกะที่ใช้ซ้ำและไม่ต้องมีสถานะ

```vhdl
package dsp_types_pkg is
  subtype slv8_t is std_logic_vector(7 downto 0);
  function all_zero (v : std_logic_vector) return boolean;
end package dsp_types_pkg;

package body dsp_types_pkg is
  function all_zero (v : std_logic_vector) return boolean is
  begin
    for i in v'range loop
      if v(i) /= '0' then
        return false;
      end if;
    end loop;
    return true;
  end function all_zero;
end package body dsp_types_pkg;
```

ใช้งาน

```vhdl
architecture rtl of alu_comb is
  use work.dsp_types_pkg.all;
begin
  comb_p : process (opcode, a, b)
    ...
  begin
    ...
    zero_i <= '1' when all_zero(result_i) else '0';
  end process comb_p;
end architecture rtl;
```

> **ข้อจำกัด**: function ที่เรียกภายใน process ต้องเป็น **pure function**
> (ไม่มี side effect และไม่อ่าน signal นอก scope)
> ฟังก์ชันที่อ่าน signal จะทำให้ simulation ไม่ตรงกับการสังเคราะห์

## 7. ข้อผิดพลาดที่พบบ่อย

### 7.1 sensitivity list ไม่ครบ

```vhdl
comb_p : process (a, b)      -- ← ลืม sel
begin
  if sel = '1' then
    y_o <= a;
  else
    y_o <= b;
  end if;
end process comb_p;
```

อาการ: เมื่อเปลี่ยน `sel` เอาต์พุตไม่เปลี่ยน → คนที่ทดสอบมักเข้าใจว่าเป็นบั๊กของ DUT
แต่จริง ๆ เป็นบั๊กของ testbench

**วิธีตรวจ**: ใน testbench ให้เปลี่ยนทุกอินพุตทีละตัวและตรวจว่าเอาต์พุตตอบสนอง

### 7.2 อ่านค่า signal ที่เพิ่งถูก assign ใน process เดียวกัน

```vhdl
comb_p : process (a, b)
  variable tmp : std_logic;
begin
  tmp <= a and b;          -- ← ใช้ <= กับ variable ไม่ได้
  y_o <= tmp;              -- ← ค่าของ tmp จะเป็นค่าเก่าเสมอ
end process comb_p;
```

**อาการ**: เอาต์พุตล้าหลังอินพุตเสมอ 1 รอบ (one cycle behind)
แก้โดยใช้ `:=` กับ variable

> ข้อผิดพลาดนี้เป็นแบบเดียวกับที่เคยพบใน Lab 01 ของคอร์สหลักสูตร
> โดยเฉพาะการนับ error ภายใน process ต้องใช้ `variable` เสมอ

### 7.3 signal มี driver มากกว่าหนึ่งตัว

```vhdl
y_o <= a when sel = '0' else '0';    -- driver ที่ 1
...
y_o <= b when sel = '1' else '0';    -- driver ที่ 2 → ขัดแย้ง
```

อาการ: ค่าเป็น 'X' เมื่อเงื่อนไขซ้อนกัน
เครื่องมือสังเคราะห์จะรายงาน "multiple drivers"

### 7.4 ใช้ `wait` ใน combinational process

```vhdl
comb_p : process (a, b)
begin
  wait for 1 ns;      -- ← ไม่อนุญาตใน process ที่มี sensitivity list
  y_o <= a;
end process comb_p;
```

### 7.5 ลืมแปลงชนิดข้อมูลก่อนเทียบ

```vhdl
if a < b then              -- ← a เป็น std_logic_vector, b เป็น unsigned
```

แก้โดยประกาศให้ชนิดเดียวกันตั้งแต่ต้น หรือแปลงก่อนเทียบ

## 8. combinational loop

เกิดเมื่อเอาต์พุตของโมดูลหนึ่งไปเป็นอินพุตของตัวเองโดยไม่มี delay
เช่น

```vhdl
y_o <= a and y_o;    -- ← วงจรที่ไม่มีทางจบ
```

- ในการจำลอง ค่าจะกลายเป็น 'X' หรือค่าที่ไม่นิ่ง
- ในการสังเคราะห์ เครื่องมือจะแจ้ง "combinational loop" และหยุดทำงาน
- แก้โดยใส่ register ระหว่างวงจร หรือออกแบบใหม่ให้เป็น feedback ที่ตั้งใจ

## 9. เรื่องของเวลา: delta cycle และ glitch

### 9.1 delta cycle

คำสั่ง `signal <= value` ใน process ไม่ได้ทำให้ค่าเปลี่ยนทันที
แต่จะเปลี่ยนใน "รอบ delta" ถัดไป ซึ่งเป็นเวลาที่สัญญาณใช้เวลาศูนย์
ในการจำลอง แต่มีผลต่อลำดับการอัปเดต

```vhdl
-- ค่า y_o จะเปลี่ยนหลังจาก a และ b เปลี่ยน 1 รอบ delta
y_o <= a and b;
```

ผลที่เห็นใน waveform: เอาต์พุตเปลี่ยน "ช้ากว่า" อินพุตเล็กน้อยในมุมมองของ delta cycle
ซึ่งเป็นพฤติกรรมที่ถูกต้อง ไม่ใช่บั๊ก

### 9.2 glitch

เนื่องจากเส้นทางของสัญญาณแต่ละเส้นมี delay ไม่เท่ากัน เมื่ออินพุตเปลี่ยน
เอาต์พุตอาจกระพริบเป็นค่าผิดก่อนจะเข้าที่ค่าจริง

```vhdl
-- a = 0, b = 1 → y_o = 0
-- a เปลี่ยนเป็น 1 → ระหว่างรอ b กระพริบเป็น 1 แล้วกลับเป็น 0
y_o <= a and b;
```

**ข้อสรุปที่ใช้ในการออกแบบ**: อย่าออกแบบให้มี logic ที่สัญญาณวิกฤต (glitch)
ส่งต่อไปยัง clock โดยไม่มี register กัน glitch
ถ้าจำเป็นต้องส่งสัญญาณ combinational ไปยังโมดูลอื่น ให้ยืนยันกับคู่มือของโมดูลปลายทาง
ว่ารองรับ glitch หรือไม่ และถ้าจำเป็นให้ใส่ register ซิงก์

---

## แบบฝึกหัดท้ายบท

1. เขียน `priority_encoder` 4 → 2 บิต ด้วยทั้งสามรูปแบบ (process, concurrent,
   with-select) แล้วเทียบผลลัพธ์ พร้อมอธิบายว่ารูปแบบใดอ่านง่ายกว่าเมื่อมี 8 อินพุต
2. สร้าง testbench ที่ตรวจว่าโมดูลเป็น combinational จริง โดยเปลี่ยนอินพุตทีละตัว
   แล้วรอ 1 ns ก่อนตรวจผล จากนั้นจงใส่ sensitivity list ผิดโดยตั้งใจ
   แล้วสังเกตว่า testbench จับปัญหาได้หรือไม่
3. เขียนโมดูล `mux4` แบบ concurrent แล้วรัน `ghdl --synth` เพื่อยืนยันว่า
   ไม่มี latch เกิดขึ้น
4. อธิบายว่าทำไมการอ่านค่า signal ที่เพิ่งถูก assign ใน process เดียวกัน
   จะได้ค่าเก่า และระบุว่าควรใช้ `signal` หรือ `variable` ในกรณีใด
5. หาตัวอย่าง combinational loop ในโค้ดของโปรเจกต์ (ถ้ามี) แล้วอธิบายว่าจะตรวจจับได้อย่างไร

## คำถามท้ายบท

1. latch เกิดขึ้นในวงจร combinational ได้อย่างไร และมีผลต่อการวิเคราะห์เวลาอย่างไร
2. `process (all)` ของ VHDL-2008 ช่วยป้องกันข้อผิดพลาดใด และเหตุใดคู่มือนี้
   จึงไม่ใช้
3. การกำหนดค่าเริ่มต้นก่อน `case` กับการมี `when others` ป้องกัน latch
   ต่างกันอย่างไร
4. การอ่านค่า signal ที่เพิ่งถูก assign ใน process เดียวกันทำให้เกิดอาการอะไร
   และต้องใช้คำสั่งใดแทน
5. glitch เกิดจากสาเหตุใด และการออกแบบจะหลีกเลี่ยงอย่างไร

---

**อ่านต่อ:** [บทที่ 05 — ตรรกะ sequential](05-sequential-logic.md)

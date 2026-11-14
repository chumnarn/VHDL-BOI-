# บทที่ 13: ข้อผิดพลาดที่พบบ่อย

> บทนี้รวบรวมข้อผิดพลาดที่เกิดขึ้นจริงในคอร์สนี้ พร้อมอาการ สาเหตุ และวิธีแก้
> แต่ละข้อมูลข้อความ error จริงจากเครื่องมือเพื่อให้ค้นหาเจอเร็ว

**เครื่องมือที่เกี่ยวข้อง:** GHDL 1.0.0

---

## สารบัญบท

- [1. ข้อผิดพลาดระดับคอมไพล์](#1-ข้อผิดพลาดระดับคอมไพล์)
- [2. ข้อผิดพลาดระดับออกแบบ](#2-ข้อผิดพลาดระดับออกแบบ)
- [3. ข้อผิดพลาดระดับการจำลอง](#3-ข้อผิดพลาดระดับการจำลอง)
- [4. ข้อผิดพลาดระดับการสังเคราะห์](#4-ข้อผิดพลาดระดับการสังเคราะห์)
- [5. ตารางค้นหาเร็ว](#5-ตารางค้นหาเร็ว)

---

## 1. ข้อผิดพลาดระดับคอมไพล์

### 1.1 Unknown identifier "std_logic"

```text
examples/ex01/src/alu_comb.vhd:35:9:error: unknown identifier "std_logic"
```

**สาเหตุ** — context clause มีผลกับ design unit ถัดไปหนึ่งหน่วยเท่านั้น
ไฟล์ที่ประกาศ `library ieee; use ieee.std_logic_1164.all;` ไว้หัวไฟล์
จะใช้ได้เฉพาะ entity แรก ส่วน architecture ต้องประกาศซ้ำ

**วิธีแก้**

```vhdl
library ieee;                  -- ← เพิ่มบรรทัดนี้
use ieee.std_logic_1164.all;  -- ← และบรรทัดนี้
```

**ป้องกัน** — ใส่ flag `-fexplicit` ในคำสั่งคอมไพล์ของ CI

```bash
ghdl -a -fexplicit --std=08 --workdir=work src/*.vhd
```

### 1.2 String literal has a character with value 0xE0

```text
tb/tb_alu_comb.vhd:88:12:error: string literal has a character with value 0xE0
```

**สาเหตุ** — string literal ของ VHDL รองรับเฉพาะอักขระ Latin-1
ภาษาไทยที่บันทึกเป็น UTF-8 จึงใช้ใน `report "..."` ไม่ได้

**วิธีแก้** — ใช้ข้อความภาษาอังกฤษใน `report` ส่วนคอมเมนต์ภาษาไทยใช้ได้ตามปกติ

### 1.3 object "x" is not a signal / is not a variable

```text
tb/tb_counter.vhd:52:5:error: object "q" is not a signal
```

**สาเหตุ** — ใช้ `:=` กับ signal หรือ `<=` กับ variable ผิด

**วิธีแก้**

| ต้องการ | ใช้ |
|---|---|
| กำหนดค่า signal | `q <= value;` |
| กำหนดค่า variable | `v := value;` |

### 1.4 operator "+" is ambiguous

```text
error: operator "+" is ambiguous
```

**สาเหตุ** — ใช้ทั้ง `ieee.std_logic_arith` และ `ieee.numeric_std` พร้อมกัน

**วิธีแก้** — ลบ `std_logic_arith` ออก ใช้ `numeric_std` เท่านั้น

### 1.5 wrong number of indexes / length of "x" is not equal to length of "y"

```text
error: length of "a" is not equal to length of "b"
```

**สาเหตุ** — คำนวณระหว่าง `unsigned`/`signed` ที่ความยาวไม่เท่ากัน

**วิธีแก้** — ใช้ `resize` ให้ความยาวเท่ากันก่อน

```vhdl
c <= resize(a, 16) + resize(b, 16);
```

### 1.6 no choice for "when others"

```text
error: no choice for "when others"
```

**สาเหตุ** — `case` ที่ไม่ครอบคลุมทุกค่าของ selector และไม่มี `when others`

**วิธีแก้** — เพิ่ม `when others`

### 1.7 cannot open file

```text
tb/tb_checksum8.vhd:64:12:error: cannot open file "tb/vectors/checksum8_vectors.txt"
```

**สาเหตุ** — พาธใน `file ... open read_mode` เป็นพาธสัมพัทธ์กับ directory ที่รัน
ไม่ใช่กับตำแหน่งไฟล์ testbench

**วิธีแก้** — รัน `ghdl -r` จาก directory ที่กำหนดไว้แน่นอน
(สคริปต์ `scripts/check_example.sh` ของโปรเจกต์นี้จัดการให้แล้ว)

### 1.8 use of synopsys package "std_logic_textio" needs the -fsynopsys option

```text
examples/ex11_tb_patterns/tb/tb_acc_file.vhd:13:10: use of synopsys package "std_logic_textio" needs the -fsynopsys option
```

**อาการ** — คอมไพล์ด้วย `--std=08` ผ่าน แต่คอมไพล์ด้วย `--std=02` ไม่ผ่าน

**สาเหตุ** — GHDL จัดการ `ieee.std_logic_textio`, `ieee.std_logic_arith`
และ `ieee.std_logic_unsigned` เป็นแพ็กเกจฝั่ง Synopsys
จึงต้องเปิดด้วย `-fsynopsys` เมื่อคอมไพล์ด้วยมาตรฐาน VHDL-93/2002

**วิธีแก้** — ใช้ `std.textio` ล้วน ๆ แทน `ieee.std_logic_textio`
`std.textio` มี `readline`, `endfile`, `file_open` และ `read`
ครบสำหรับการอ่านไฟล์ stimulus และไม่ต้องตั้งค่าเพิ่มในเครื่องมือใด ๆ

### 1.9 cannot resolve overloading for subprogram call

```text
tb/tb_acc_file.vhd:81:14: cannot resolve overloading for subprogram call
```

**สาเหตุ** — เรียก `read` ด้วยอาร์กิวเมนต์ที่ให้เลือกได้มากกว่าหนึ่งแบบ
เช่น การส่ง `string` ที่มีความยาวไม่ใช่ 1 หรือการส่งชนิดที่ไม่ตรงกับ
overload ใดเลย

**วิธีแก้** — ตรวจว่าชนิดของอาร์กิวเมนต์ตรงกับ overload ที่ต้องการ
`std.textio` มี `read` สำหรับ `CHARACTER`, `INTEGER`, `REAL`, `STRING`
และ `BIT_VECTOR` แต่ละแบบรับได้คนละชนิดเท่านั้น

### 1.10 no choice for "s_idle"

```text
examples/ex10_uart_tx/src/uart_tx.vhd:81:17: no choice for s_idle
```

**สาเหตุ** — `case` ที่อยู่ภายใน `case` อีกชั้นหนึ่ง
คอมไพล์จะยังต้องการการครอบคลุมสมาชิก **ทุกตัว** ของชนิด enum
แม้ว่า branch ภายนอกจะจำกัดขอบเขตไว้แล้วก็ตาม

**วิธีแก้** — แยก `case` ที่ซ้อนกันออกจากกัน หรือเพิ่ม `when others` ใน `case` ชั้นใน
ดูตัวอย่างที่แก้แล้วใน `code/reference/vhdl/examples/ex10_uart_tx/src/uart_tx.vhd`

## 2. ข้อผิดพลาดระดับออกแบบ

### 2.1 latch ที่ไม่ได้ตั้งใจ

**อาการ** — เอาต์พุตของวงจร combinational ไม่เปลี่ยนเมื่ออินพุตเปลี่ยน
ในการสังเคราะห์จะพบ cell ชื่อ latch

**สาเหตุ** — `case` หรือ `if` ใน combinational process ไม่ได้กำหนดค่าให้ครบทุก path

**วิธีแก้** — กำหนดค่าเริ่มต้นให้ครบก่อน `case` และมี `when others`

**ตรวจสอบ**

```bash
ghdl --synth --std=08 --workdir=work alu_comb | grep -i latch
```

### 2.2 signal ภายในที่ถูก assign ใน clocked process

**อาการ** — วงจรทำงานเหมือน latch แทน flip-flop เอาต์พุตเปลี่ยนตามอินพุตได้
แม้ไม่มีขอบนาฬิกา

**สาเหตุ** — signal ที่ประกาศนอก process แล้วถูก assign ใน clocked process

**วิธีแก้** — ย้ายเป็น `out` port หรือแยกเป็น combinational process

### 2.3 อ่านค่าเก่าใน clocked process

**อาการ** — เอาต์พุตล้าหลังอินพุต 1 รอบนาฬิกา

**สาเหตุ** — ค่าของ signal ที่ถูก assign ใน process เดียวกันเป็นค่าเก่าเสมอ

**วิธีแก้** — ใช้ `variable` เมื่อต้องการค่าใหม่ที่เพิ่งคำนวณ
ระวังว่าการนับ error ภายใน process ต้องใช้ `variable` เสมอ

### 2.4 อ่าน output port ของตัวเอง

**อาการ** — ในมาตรฐาน VHDL-2002 คอมไพล์ไม่ผ่าน แต่ใน VHDL-2008 ผ่าน
ทำให้โค้ดพังเฉพาะในห้องเรียน

**วิธีแก้** — ใช้ signal ภายในแล้วส่งออกพอร์ตที่จุดเดียว

### 2.5 combinational loop

**อาการ** — simulation ค้างหรือค่าเป็น 'X' ทั้งหมด เครื่องมือสังเคราะห์แจ้ง
"combinational loop"

**สาเหตุ** — เอาต์พุตของโมดูลหนึ่งเป็นอินพุตของตัวเองโดยไม่มี register

### 2.6 สัญญาณข้าม clock domain โดยไม่ซิงก์

**อาการ** — ทำงานผิดแบบไม่มีรูปแบบ อาจไม่เกิดในการจำลองเลย
แต่จะเกิดในฮาร์ดแวร์จริง

**วิธีแก้** — ใช้กลไกตาม [บทที่ 07](07-interfaces-and-cdc.md)

### 2.7 `if clk = '1'` แทน `rising_edge(clk)`

**อาการ** — เครื่องมือสังเคราะห์ประกาศ error หรือสร้างวงจรที่ทำงานผิด

### 2.8 ทิศทางการเลื่อน shift register ผิด

**อาการ** — เอาต์พุตของ shift register ไม่ใช่ข้อมูลที่ควรได้
เช่น ได้ค่าเดิมทั้งเฟรม หรือได้ค่าที่เติมเข้ามาแทนข้อมูลจริง

**สาเหตุ** — ใน concatenation ตัวซ้ายสุดไปอยู่ที่ index สูงสุดเสมอ
การเขียน `shreg_i <= shreg_i(9 downto 1) & '1';` จึงเป็นการ **ไม่เลื่อนเลย**
เพราะบิตที่เติมเข้ามาจะไปอยู่ที่ index 0 ซึ่งเป็นตำแหน่งของเอาต์พุต

**วิธีแก้** — สำหรับการเลื่อนบิตเข้าหา index 0 ให้เขียน

```vhdl
shreg_i <= '1' & shreg_i(9 downto 1);   -- ✓ เลื่อนเข้าหาเอาต์พุต
shreg_i <= shreg_i(8 downto 0) & '1';   -- ✓ เลื่อนออกจากเอาต์พุต (เลื่อนซ้าย)
```

ดูตัวอย่างที่แก้แล้วใน `code/reference/vhdl/examples/ex10_uart_tx/src/uart_tx.vhd`

### 2.9 handshake 4-phase ที่ไม่รอให้ ack กลับเป็น 0

**อาการ** — ฝั่งผู้ส่งส่งข้อมูลทีละคำได้เร็วเกินไปจนข้อมูลถูกส่งรัวหรือหาย
ในการจำลองจะเห็นว่าคำที่ควรส่งทีละคำกลับมาถึงผิดลำดับ

**สาเหตุ** — `ack` เป็นสัญญาณ **ระดับ** ไม่ใช่พัลส์
ถ้า `src_ready` ขึ้นเมื่อ `req = '0'` เท่านั้น โดยไม่รอให้ `ack` กลับเป็น 0
ฝั่งผู้ส่งจะเริ่มส่งคำใหม่ได้ทันทีที่ `ack` ยังเป็น 1 อยู่
handshake จะไม่ครบทั้งสี่รอบ

**วิธีแก้** — ให้เงื่อนไขรับข้อมูลใหม่รอทั้งสองเงื่อนไข

```vhdl
src_ready <= '1' when (req_i = '0' and ack_sync_i = '0') else '0';
```

ดูตัวอย่างที่แก้แล้วใน
`code/reference/vhdl/examples/ex12_cdc_handshake/src/cdc_handshake.vhd`

### 2.10 conditional signal assignment ภายใน process

**อาการ** — คอมไพล์ด้วย `--std=08` ผ่าน แต่คอมไพล์ด้วย `--std=02` ไม่ผ่าน

**สาเหตุ** — รูปแบบ `<= '1' when เงื่อนไข else '0'` **ภายใน process**
เป็นฟีเจอร์ของ VHDL-2008 (conditional signal assignment แบบ sequential)
รูปแบบเดียวกันที่อยู่ **นอก process** เป็น concurrent conditional signal assignment
ซึ่งใช้ได้ตั้งแต่ VHDL-93

**วิธีแก้** — เขียนเป็น `if/else` ภายใน process หรือย้ายไปไว้นอก process เป็นรูปแบบ concurrent
ดูตัวอย่างที่แก้แล้วใน `code/reference/vhdl/examples/ex06_async_fifo/src/async_fifo.vhd`

## 3. ข้อผิดพลาดระดับการจำลอง

### 3.1 simulation ไม่จบสิ้น

**อาการ** — คำสั่ง `ghdl -r` ทำงานไม่จบ

**สาเหตุ** — นาฬิกาใน testbench ยังยิง event ต่อไป

**วิธีแก้** — ทำให้นาฬิกาหยุดเมื่อจบ

```vhdl
clk <= not clk after 5 ns when not done else '0';
```

### 3.2 TIMEOUT แม้ทดสอบผ่านแล้ว

**อาการ** — เห็น `TIMEOUT` ทั้งที่ marker PASS ถูกพิมพ์มาแล้ว

**สาเหตุ** — watchdog ไม่ได้ตรวจ flag `done` ก่อนรายงาน error

**วิธีแก้**

```vhdl
assert done report "TIMEOUT: ..." severity failure;
```

### 3.3 ค่า X ปนอยู่ในเอาต์พุต

**สาเหตุที่พบบ่อย**

- อ่านค่าจาก memory ที่ยังไม่ได้เขียน
- signal ที่ไม่มี reset และไม่ได้กำหนดค่าเริ่มต้น
- combinational process ที่ไม่ได้กำหนดค่าในทุก path
- การตรวจผลก่อนที่ DUT มีเวลาอัปเดต

**วิธีแก้** — ใส่ reset, ตรวจค่า X ด้วยฟังก์ชัน `has_unknown`
และรอ `wait for 1 ns` หลังขอบนาฬิกาก่อนตรวจผล

### 3.4 ผลลัพธ์ตรงกันแต่ระหว่างภาษาไม่ตรงกัน

**สาเหตุ** — ชื่อ signal หรือลำดับการตรวจต่างกัน

**วิธีแก้** — ใช้ชื่อเดียวกันข้ามภาษา และเทียบผลลัพธ์แบบไฟล์ต่อไฟล์
(ดูรูปแบบใน `code/lab05/run.sh`)

### 3.5 golden model ที่เรียกฟังก์ชันของ DUT

**อาการ** — ผลการทดสอบผ่านเสมอ แม้โค้ดผิด

**สาเหตุ** — การเทียบผลเป็นการเทียบ DUT กับ DUT

**วิธีแก้** — เขียน golden model ใหม่ใน testbench ด้วยวิธีคำนวณที่ต่างจาก DUT

### 3.6 `wait until` ค้างทั้งที่เงื่อนไขเป็นจริงอยู่แล้ว

**อาการ** — การจำลองค้างที่บรรทัด `wait until` โดยไม่มีข้อความ error
และ watchdog ก็ไม่ยิง เพราะ watchdog ใช้ `wait for` ไม่ใช่ `wait until`

**สาเหตุ** — `wait until` รอจนกว่าสัญญาณในเงื่อนไขจะ **เกิด event**
แล้วจึงตรวจเงื่อนไข ถ้าค่าเป็นจริงอยู่แล้วแต่ไม่มีการเปลี่ยน จะไม่มี event เกิดขึ้น

**วิธีแก้** — ใช้ `loop` กับ `exit when` ซึ่งตรวจเงื่อนไขก่อนรอ

```vhdl
loop
  exit when full = '0';
  wait until rising_edge(wr_clk);
end loop;
```

### 3.7 process ที่ไม่มี sensitivity list ทำงานซ้ำ

**อาการ** — ข้อความที่พิมพ์ท้าย `for loop` ถูกพิมพ์ซ้ำไปเรื่อย ๆ
หรือ stimulus ถูกส่งซ้ำจน testbench ทำงานไม่จบ

**สาเหตุ** — process ที่ไม่มี sensitivity list จะกลับไปเริ่มต้นของ process ใหม่
เมื่อทำงานจนถึงท้ายสุดของ process

**วิธีแก้** — ใส่ `wait;` ท้าย process เพื่อหยุดการทำงานถาวร

```vhdl
stimulus : process
begin
  for i in 0 to TOTAL-1 loop
    ...
  end loop;
  wait;        -- ← ป้องกัน process วนซ้ำ
end process stimulus;
```

## 4. ข้อผิดพลาดระดับการสังเคราะห์

### 4.1 "no such module" หรือ module ไม่ถูกอ่าน

**สาเหตุ** — ไฟล์ HDL ที่สังเคราะห์อยู่คนละ directory หรือถูก exclude

**วิธีแก้** — ตรวจรายการไฟล์ในไฟล์ config ของ flow

### 4.2 warning เรื่อง width mismatch

**อาการ** — ความกว้างของสัญญาณไม่ตรงกันในการเชื่อมต่อ

**วิธีแก้** — แก้ที่ต้นเหตุ อย่าใช้ bit เล็ก ๆ ปิด warning
เพราะจะทำให้พฤติกรรมไม่ตรงกับที่คาด

### 4.3 latch ถูกอนุมานโดยเครื่องมือ

**อาการ** — รายงาน "inferred latch"

**วิธีแก้** — ดูหัวข้อ 2.1

### 4.4 วงจรถูก optimize ออกจนหายไป

**อาการ** — สัญญาณที่ควรอยู่ในรายงานไม่ปรากฏ

**สาเหตุ** — เครื่องมือตัดสัญญาณที่ไม่มีผลต่อเอาต์พุตออก ซึ่งถูกต้อง

**วิธีแก้** — ถ้าต้องการดู ให้ใช้ `attribute keep` แต่ต้องระวังเรื่องพื้นที่และ delay

## 5. ตารางค้นหาเร็ว

| อาการ | ข้อผิดพลาดที่เป็นไปได้ | บทที่เกี่ยวข้อง |
|---|---|---|
| `Unknown identifier "std_logic"` | ขาด context clause | [01](01-language-basics.md#3-context-clause-มีผลกับหนึ่งหน่วยเท่านั้น) |
| `string literal has a character with value 0xE0` | ภาษาไทยใน `report` | [03](03-style-and-naming.md#52-ภาษาไทยใช้ได้ในคอมเมนต์-แต่ไม่ได้ใน-string-literal) |
| `object "x" is not a signal` | ใช้ `:=` กับ signal | [03](03-style-and-naming.md#44-signal-ที่ถูก-assign-ใน-clocked-process) |
| `operator "+" is ambiguous` | ใช้ `std_logic_arith` ร่วมกับ `numeric_std` | [01](01-language-basics.md#2-library-และ-use-clause) |
| `length of "a" is not equal to length of "b"` | ความยาวไม่เท่ากัน | [02](02-data-types.md#102-ความยาวไม่เท่ากัน) |
| `no choice for "when others"` | `case` ไม่ครบ | [04](04-combinational-logic.md#5-เปรียบเทียบ-if-case-และ-with-select) |
| `cannot open file` | พาธไฟล์ stimulus | [11](11-verification-style.md#93-ข้อควรระวังเรื่องพาธของไฟล์) |
| เอาต์พุตไม่เปลี่ยนเมื่ออินพุตเปลี่ยน | latch | [04](04-combinational-logic.md#3-กฎกำหนดค่าให้ครบ-และเหตุผลที่เรียกว่า-latch) |
| เอาต์พุตล้าหลังอินพุต 1 รอบ | อ่านค่าเก่าใน process | [05](05-sequential-logic.md#52-ค่าที่อ่านใน-clocked-process-เป็น-ค่าเก่า-เสมอ) |
| simulation ไม่จบ | นาฬิกาไม่หยุด | [11](11-verification-style.md#3-นาฬิกาที่หยุดได้) |
| เห็น TIMEOUT ทั้งที่ผ่าน | watchdog ไม่ตรวจ `done` | [11](11-verification-style.md#4-watchdog) |
| ค่า X ปนในเอาต์พุต | ไม่มี reset หรือ latch | [05](05-sequential-logic.md#3-รูปแบบของ-reset) |
| ทำงานผิดแบบไม่มีรูปแบบ | ไม่ได้ซิงก์ข้าม clock domain | [07](07-interfaces-and-cdc.md#4-เหตุใดการข้าม-clock-domain-จึงอันตราย) |
| ผลทดสอบผ่านเสมอ | golden model เรียก DUT | [11](11-verification-style.md#8-golden-model) |
| คอมไพล์ผ่าน `--std=08` แต่ไม่ผ่าน `--std=02` | ใช้ฟีเจอร์เฉพาะ VHDL-2008 | [13](13-common-mistakes.md#210-conditional-signal-assignment-ภายใน-process) |
| `use of synopsys package "std_logic_textio"` | ใช้ `ieee.std_logic_textio` | [13](13-common-mistakes.md#18-use-of-synopsys-package-std_logic_textio-needs-the--fsynopsys-option) |
| `cannot resolve overloading for subprogram call` | เรียก `read` ผิด overload | [13](13-common-mistakes.md#19-cannot-resolve-overloading-for-subprogram-call) |
| `no choice for "s_idle"` | `case` ซ้อน `case` | [13](13-common-mistakes.md#110-no-choice-for-s_idle) |
| จำลองค้างที่ `wait until` | `wait until` รอ event ไม่ใช่เงื่อนไข | [11](11-verification-style.md#23-wait-until-รอ-เหตุการณ์-ไม่ใช่เงื่อนไข) |
| ข้อความท้าย `for loop` ถูกพิมพ์ซ้ำ | process ไม่มี sensitivity list วนซ้ำ | [11](11-verification-style.md#31-process-ที่ไม่มี-sensitivity-list-จะเริ่มทำงานใหม่เมื่อจบ) |
| ข้อมูลถูกส่งรัวหรือหาย | handshake ไม่รอให้ ack กลับเป็น 0 | [07](07-interfaces-and-cdc.md) |
| shift register ส่งค่าผิดลำดับ | เลื่อน shift register ผิดทิศ | [13](13-common-mistakes.md#28-ทิศทางการเลื่อน-shift-register-ผิด) |

---

## แบบฝึกหัดท้ายบท

1. สร้างตัวอย่างที่ผิดกฎทั้ง 5 ข้อในบทที่ 03 แล้วบันทึกข้อความ error จริง
   พร้อมระบุว่าข้อความใดบอกอะไรเกี่ยวกับสาเหตุ
2. ทำให้ testbench ค้างโดยตั้งใจ 3 วิธี (นาฬิกาไม่หยุด, watchdog ไม่ยกเลิก,
   รอสัญญาณที่ไม่มีวันมา) แล้วอธิบายว่าวิธีไหนอันตรายที่สุดในการทำงานจริง
3. เขียน golden model ที่เรียกฟังก์ชันของ DUT แล้วแก้โค้ด DUT ให้ผิด
   เพื่อพิสูจน์ว่าการทดสอบแบบนั้นตรวจจับบั๊กไม่ได้
4. สร้างตารางข้อผิดพลาดส่วนตัวของคุณเอง 3 ข้อ ที่เคยเจอระหว่างทำ Lab
   แล้วเพิ่มเข้าใน README ของโปรเจกต์
5. จำลองข้อผิดพลาดข้อ 3.6 และข้อ 3.7 ด้วยตัวเอง แล้วบันทึกว่า
   `wait until` และ process restart ให้อาการต่างกันอย่างไร
6. ทดลองแก้ `ex10_uart_tx` ให้เลื่อน shift register ผิดทิศตามข้อ 2.8
   แล้วเปรียบเทียบผลกับของเดิม อธิบายว่าทำไม golden model จึงจับได้

## คำถามท้ายบท

1. ทำไม context clause ที่ประกาศไว้หัวไฟล์จึงไม่ครอบคลุม architecture
2. ข้อผิดพลาดที่ทำให้วงจรทำงานผิด "แบบเงียบ" มีข้อใดบ้าง และเหตุใด
   จึงต้องตรวจด้วย `ghdl --synth` ทุกครั้ง
3. ทำไมการอ่านค่า signal ภายใน process เดียวกันต้องใช้ `variable`
4. อาการของ latch ที่ไม่ได้ตั้งใจคืออะไร และทำไมการทดสอบแบบ combinational
   จึงต้องเปลี่ยนอินพุตโดยไม่มีขอบนาฬิกา
5. ข้อผิดพลาดใดที่ตรวจจับได้ด้วยการจำลองแต่ตรวจจับไม่ได้ด้วยการสังเคราะห์
   และข้อผิดพลาดใดตรงกันข้าม

---

**อ่านต่อ:** [บทที่ 14 — เทียบกับ Verilog](14-verilog-cross-reference.md)

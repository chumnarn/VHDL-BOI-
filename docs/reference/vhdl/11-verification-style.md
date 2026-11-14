# บทที่ 11: รูปแบบการตรวจสอบ

> บทนี้เป็นแม่แบบการเขียน testbench ที่ตรวจสอบตัวเองได้ (self-checking)
> ซึ่งเป็นรูปแบบที่ทำให้ผลการทดสอบเชื่อถือได้และรันซ้ำได้อัตโนมัติ

**เครื่องมือที่เกี่ยวข้อง:** GHDL 1.0.0
**ตัวอย่างอ้างอิง:** `ex11_tb_patterns/`

---

## สารบัญบท

- [1. โครงสร้างของ testbench ที่ตรวจตัวเองได้](#1-โครงสร้างของ-testbench-ที่ตรวจตัวเองได้)
- [2. การจัดการเวลา](#2-การจัดการเวลา)
- [3. นาฬิกาที่หยุดได้](#3-นาฬิกาที่หยุดได้)
- [4. watchdog](#4-watchdog)
- [5. assertion และระดับความรุนแรง](#5-assertion-และระดับความรุนแรง)
- [6. การนับ error และสรุปผล](#6-การนับ-error-และสรุปผล)
- [7. การตรวจค่า X และ U](#7-การตรวจค่า-x-และ-u)
- [8. golden model](#8-golden-model)
- [9. stimulus จากไฟล์](#9-stimulus-จากไฟล์)
- [10. เคสที่ต้องทดสอบเสมอ](#10-เคสที่ต้องทดสอบเสมอ)
- [11. โครงสร้างไฟล์ที่แนะนำ](#11-โครงสร้างไฟล์ที่แนะนำ)

---

## 1. โครงสร้างของ testbench ที่ตรวจตัวเองได้

testbench มาตรฐานของโปรเจกต์นี้ประกอบด้วย 5 ส่วน

```text
1. ประกาศสัญญาณและ instance ของ DUT
2. ตัวสร้างนาฬิกา
3. process ที่ส่ง stimulus และตรวจผล
4. process watchdog ที่ยุติการจำลองเมื่อเกินเวลา
5. ตัวสรุปผลและ marker PASS/FAIL
```

ตัวอย่างเต็มที่ใช้เป็นแม่แบบ

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_dff_simple is
end entity tb_dff_simple;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture tb of tb_dff_simple is
  signal clk   : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal d     : std_logic := '0';
  signal q     : std_logic;
  signal done  : boolean := false;
begin
  dut : entity work.dff_simple
    port map (
      clk   => clk,
      rst_n => rst_n,
      d     => d,
      q     => q
    );

  -- นาฬิกา: หยุดเมื่อ done เป็นจริง เพื่อให้ simulation จบสิ้น
  clk <= not clk after 5 ns when not done else '0';

  stimulus : process
    variable error_count : integer := 0;
  begin
    -- เคสที่ 1: หลังปลด reset เอาต์พุตต้องตามอินพุต
    wait for 12 ns;
    rst_n <= '1';
    wait until rising_edge(clk);
    d <= '1';
    wait until rising_edge(clk);
    wait for 1 ns;
    if q /= '1' then
      error_count := error_count + 1;
      report "dff_simple: expected q='1'" severity failure;
    end if;

    -- สรุปผล
    if error_count = 0 then
      report "GOLDEN_MINIMAL_DUT_PASS" severity note;
    else
      report "GOLDEN_MINIMAL_DUT_FAIL" severity failure;
    end if;
    done <= true;
    wait;
  end process;

  watchdog : process
  begin
    wait for 1 us;
    assert done report "TIMEOUT: tb_dff_simple did not finish" severity failure;
    wait;
  end process;
end architecture tb;
```

## 2. การจัดการเวลา

| ประกอบการณ์ | รูปแบบ |
|---|---|
| รอเวลาที่กำหนด | `wait for 10 ns;` |
| รอขอบนาฬิกาถัดไป | `wait until rising_edge(clk);` |
| รอขอบนาฬิกาแล้วรอเวลาเล็กน้อย | `wait until rising_edge(clk); wait for 1 ns;` |
| รอจนกว่าเงื่อนไขเป็นจริง | `wait until condition;` |
| หยุดการจำลอง | `wait;` |

### 2.1 ทำไมต้อง `wait for 1 ns` หลังขอบนาฬิกา

หลัง `wait until rising_edge(clk)` ค่าของ signal ที่ถูก assign ใน clocked process
**ยังไม่เปลี่ยน** เพราะการอัปเดตเกิดในรอบ delta ถัดไป
ถ้าตรวจผลทันทีโดยไม่รอ จะได้ค่าเก่า

```vhdl
-- ✗ ตรวจค่าเก่า
wait until rising_edge(clk);
if q /= '1' then ... end if;

-- ✓ รอให้ค่ามีผลจริง
wait until rising_edge(clk);
wait for 1 ns;
if q /= '1' then ... end if;
```

> ทางเลือกที่ดีกว่าคือใช้ `wait until rising_edge(clk);` แล้วตรวจผลในรอบถัดไป
> แต่การ `wait for 1 ns` เข้าใจง่ายกว่าและใช้ได้กับเครื่องมือทุกตัว

### 2.2 หน่วยเวลา

ใช้หน่วยเดียวกันทั้งโปรเจกต์ แนะนำ `ns` และ `ps`
ห้ามผสมหน่วยโดยไม่ตั้งใจ เช่น `wait for 10 ns;` แล้ว `wait for 1 us;` ปนกัน
โดยไม่คิดถึงอัตราส่วนจริง

### 2.3 `wait until` รอ *เหตุการณ์* ไม่ใช่เงื่อนไข

นี่คือข้อผิดพลาดที่ทำให้ testbench ค้างโดยไม่มีข้อความ error ใด ๆ

```vhdl
-- ✗ ผิด: ถ้า full เป็น '0' อยู่แล้วและไม่มีการเปลี่ยน จะค้างตลอดไป
wait until full = '0';
```

`wait until` จะรอจนกว่าสัญญาณในเงื่อนไขจะ **เกิด event** แล้วค่อยตรวจเงื่อนไข
ถ้าค่าเป็นจริงอยู่แล้วแต่ไม่มีการเปลี่ยน จะไม่มี event เกิดขึ้น
การจำลองจึงค้างอยู่ที่บรรทัดนั้น ไม่ใช่ที่ watchdog

วิธีที่ถูกต้องคือใช้ `loop` กับ `exit when` ซึ่งตรวจเงื่อนไขก่อนรอ

```vhdl
-- ✓ ถูก: ตรวจเงื่อนไขก่อน แล้วค่อยรอขอบนาฬิกา
loop
  exit when full = '0';
  wait until rising_edge(wr_clk);
end loop;
```

> ยืนยันพฤติกรรมนี้ได้ด้วย GHDL: `wait until s = '1'` ที่ `s` เป็นจริงอยู่แล้ว
> จะไม่ผ่านในเวลาจำกัด ส่วนรูปแบบ `loop ... exit when ... end loop;` จะผ่านทันที

รูปแบบนี้ใช้ได้กับทุกกรณีที่ต้องรอสัญญาณจาก DUT เช่น
`wait until full = '0'` หรือ `wait until empty = '0'`
ดูตัวอย่างการใช้งานจริงใน
`code/reference/vhdl/examples/ex06_async_fifo/tb/tb_async_fifo.vhd`

## 3. นาฬิกาที่หยุดได้

**นี่คือกฎที่ผู้เรียนมักไม่รู้ และทำให้ simulation ไม่จบสิ้น**

```vhdl
clk <= not clk after 5 ns;
```

เป็น concurrent signal assignment ที่ตัวเองจัดเวลาไว้ตลอดไป
event queue จึงไม่มีวันว่าง และ simulation จะรันไม่สิ้น
ผู้เรียนจะเข้าใจว่า "เครื่องมือค้าง"

วิธีแก้ที่ถูกต้องคือให้นาฬิกาหยุดเมื่อการทดสอบจบ

```vhdl
signal done : boolean := false;

clk <= not clk after 5 ns when not done else '0';
```

เมื่อ `done` เป็นจริง สัญญาณนาฬิกาจะถูกขับเป็น '0' ทันทีโดยไม่จัดเวลาต่อ
event queue จึงว่างลง และ simulation จบสิ้นในตัวเอง

สำหรับ testbench ที่มีหลาย clock domain ให้ใช้วิธีเดียวกันทุกตัวสร้างนาฬิกา

```vhdl
clk_a <= not clk_a after 5 ns when not done else '0';
clk_b <= not clk_b after 7 ns when not done else '0';
```

### 3.1 process ที่ไม่มี sensitivity list จะเริ่มทำงานใหม่เมื่อจบ

อีกสาเหตุหนึ่งที่ทำให้ simulation ไม่จบ คือ process ที่ไม่มี sensitivity list
จะ **กลับไปเริ่มต้นของ process ใหม่** เมื่อทำงานจนถึงท้ายสุด

```vhdl
-- ✗ ผิด: พอ for loop จบ process จะเริ่มทำงานใหม่ แล้วส่ง stimulus ซ้ำไปเรื่อย ๆ
stimulus : process
begin
  for i in 0 to TOTAL-1 loop
    ...
  end loop;
end process stimulus;
```

วิธีแก้คือใส่ `wait;` ท้าย process เพื่อหยุดการทำงานถาวร

```vhdl
-- ✓ ถูก: wait; ท้าย process ทำให้ process ไม่เดินกลับไปเริ่มต้นใหม่
stimulus : process
begin
  for i in 0 to TOTAL-1 loop
    ...
  end loop;
  wait;
end process stimulus;
```

> ยืนยันพฤติกรรมนี้ได้ด้วย GHDL: เมื่อข้อความที่พิมพ์อยู่ท้าย `for loop`
> จะถูกพิมพ์ซ้ำไปเรื่อย ๆ จนกว่าจะใส่ `wait;`

ข้อสังเกต: process ที่มี `loop` ครอบทั้ง body จะไม่มีปัญหานี้
เพราะ process ไม่เคย "จบ" แต่ถ้าใช้ `loop` แล้วออกด้วย `exit`
ก็ยังต้องระวังว่า process จะเดินกลับไปเริ่มต้นใหม่เช่นกัน

## 4. watchdog

watchdog คือกลไกที่ยุติการจำลองเมื่อ testbench ทำงานผิด เช่น รอสัญญาณที่ไม่มีวันมา
หรือวนลูปไม่รู้จบ ทำให้ไม่ต้องรอและกด Ctrl+C ด้วยมือ

```vhdl
watchdog : process
begin
  wait for 10 us;                                    -- เวลาสูงสุดที่ยอมรับ
  assert done report "TIMEOUT: tb_xxx did not finish" severity failure;
  wait;
end process;
```

ข้อกำหนด

- ต้องตรวจ `done` ก่อนรายงาน error มิฉะนั้นจะยิง TIMEOUT แม้ทดสอบผ่านแล้ว
- เวลาต้องมากพอสำหรับเคสที่ช้าที่สุด แต่ไม่มากเกินไป
- ใช้ `severity failure` เพื่อให้การจำลองหยุดและคืนรหัสผลที่ไม่เป็นศูนย์

## 5. assertion และระดับความรุนแรง

### 5.1 ระดับความรุนแรง

| severity | ผลต่อการจำลอง | ใช้เมื่อ |
|---|---|---|
| `note` | แสดงข้อความ จำลองทำงานต่อ | ข้อความให้ข้อมูล เช่น สรุปผล |
| `warning` | แสดงข้อความ จำลองทำงานต่อ | พบความผิดปกติที่ยังไม่ถือว่าล้มเหลว |
| `error` | แสดงข้อความ จำลองทำงานต่อ แต่นับเป็นข้อผิดพลาด | ผลลัพธ์ไม่ตรงความคาดหวัง |
| `failure` | หยุดการจำลองทันที | ผลลัพธ์ผิดจนไม่มีความหมายต่อการทดสอบต่อไป |

### 5.2 รูปแบบที่ใช้ในโปรเจกต์นี้

```vhdl
-- ตรวจเงื่อนไขหนึ่ง
assert cond = '1'
  report "condition failed at cycle " & integer'image(cycle)
  severity failure;

-- ตรวจพร้อมนับ error
if result /= expected then
  error_count := error_count + 1;
  report "mismatch: got " & to_hstring(result) &
         " expected " & to_hstring(expected)
    severity error;
end if;
```

> **`to_hstring` เป็นฟังก์ชันของ VHDL-2008** ซึ่งใช้ไม่ได้ใน VHDL-2002
> ถ้าต้องให้โค้ดคอมไพล์ผ่าน `--std=02` ให้ใช้ `to_string(unsigned(v))` แทน
> หรือเขียนฟังก์ชันช่วยเฉพาะใน testbench

### 5.3 assertion แบบ concurrent

```vhdl
-- ตรวจต่อเนื่องระหว่างการจำลอง
assert not (full = '1' and wr_en = '1')
  report "write to full FIFO" severity error;
```

ข้อดี: ตรวจได้ตลอดเวลา ไม่ต้องเขียนซ้ำในหลายจุด
ข้อควรระวัง: ต้องระวังไม่ให้ assertion ทำงานในช่วงที่ค่ายังไม่นิ่ง
เช่น ตอนเริ่มต้นก่อน reset

## 6. การนับ error และสรุปผล

```vhdl
stimulus : process
  variable error_count : integer := 0;
  variable test_count  : integer := 0;
begin
  ...
  test_count := test_count + 1;
  if actual /= expected then
    error_count := error_count + 1;
    report "case " & integer'image(test_count) & " mismatch" severity error;
  end if;
  ...
  -- สรุปผล
  if error_count = 0 then
    report "GOLDEN_EXAMPLE_PASS: " & integer'image(test_count) & " case(s) passed" severity note;
  else
    report "GOLDEN_EXAMPLE_FAIL: " & integer'image(error_count) &
           " of " & integer'image(test_count) & " case(s) failed" severity failure;
  end if;
  done <= true;
  wait;
end process;
```

**ข้อสำคัญ**: ตัวแปรนับ error ต้องเป็น `variable` ไม่ใช่ `signal`
เพราะการอ่านค่า signal ภายใน process เดียวกันจะได้ค่าเก่าเสมอ
(นี่คือข้อผิดพลาดเดียวกับที่เคยพบใน Lab 01 ของคอร์สหลักสูตร)

### 6.1 marker และ exit code

marker ต้องเป็นข้อความ ASCII ที่สคริปต์ภายนอกค้นหาได้

| marker | ความหมาย |
|---|---|
| `GOLDEN_<ชื่อ>_PASS` | ผ่านทั้งหมด |
| `GOLDEN_<ชื่อ>_FAIL` | มีข้อผิดพลาด |
| `TIMEOUT` | testbench ไม่จบในเวลาที่กำหนด |

เครื่องมือจำลองหลายตัวคืนรหัสผลลัพธ์ 0 แม้ทดสอบจะไม่ผ่าน
สคริปต์ที่รันต้องตรวจ marker ใน log แล้วเป็นผู้ตัดสิน

## 7. การตรวจค่า X และ U

ค่า 'X' หรือ 'U' ที่หลุดออกจาก DUT มักบ่งบอกว่ามีบั๊ก
(เช่น อ่านค่าจาก memory ที่ยังไม่ถูกเขียน หรือ state ที่ผิดพลาด)

```vhdl
function has_unknown (v : std_logic_vector) return boolean is
begin
  for i in v'range loop
    if v(i) /= '0' and v(i) /= '1' then
      return true;
    end if;
  end loop;
  return false;
end function has_unknown;
```

ใช้ใน testbench

```vhdl
if has_unknown(dout) then
  error_count := error_count + 1;
  report "output contains X/U" severity error;
end if;
```

> **ข้อควรระวัง**: การตรวจ X ต้องทำหลังจากที่ DUT มีเวลาพอที่จะ "นิ่ง"
> ไม่เช่นนั้นจะตรวจจับค่าชั่วคราวที่ยังไม่ได้อัปเดตและรายงานเป็นบั๊กปลอม

## 8. golden model

### 8.1 หลักการ

golden model คือ implementation อีกชุดหนึ่งที่ทำหน้าที่เหมือน DUT
แต่เขียนด้วยวิธีที่ต่างกัน (เช่น เป็นโค้ดเชิงกระบวนการ) เพื่อใช้เป็นค่าอ้างอิง

### 8.2 กฎที่ต้องรักษา

> **ห้ามให้ golden model เรียกใช้ฟังก์ชันหรือโมดูลของ DUT**
> มิฉะนั้นการเทียบผลจะเป็นการเทียบ DUT กับ DUT ซึ่งจับบั๊กไม่ได้เลย

ตัวอย่างที่ถูกต้อง

```vhdl
-- golden model เขียนแยกใน testbench ด้วยวิธีคำนวณต่างจาก DUT
variable expected_v : std_logic_vector(DATA_WIDTH-1 downto 0);
expected_v := std_logic_vector(unsigned(a) + unsigned(b));
```

ตัวอย่างที่ผิด

```vhdl
-- ✗ golden model เรียก RTL ของ DUT
expected_v := alu4_ref(op, a, b);      -- ถ้า alu4_ref อยู่ใน package ที่ DUT ใช้
```

ในคอร์สนี้มีตัวอย่างของข้อควรระวังนี้ใน `code/lab03/src/alu4_pkg.vhd`
ที่มีคอมเมนต์อธิบายว่า golden model ต้องถูก "แยกออกจาก DUT"

### 8.3 ระดับของ golden model

| ระดับ | ความแม่นยำ | ใช้เมื่อ |
|---|---|---|
| คำนวณใน testbench ด้วยสูตรตรง ๆ | สูง | ตรรกะเล็ก ๆ |
| โมเดลเชิงกระบวนการทำงานแยก | สูง | วงจรลำดับ เช่น FIFO, FSM |
| อ้างอิงผลลัพธ์จากไฟล์ (golden vector) | สูงมาก แต่ต้องมีคนสร้าง | กรณีอ้างอิงภายนอก เช่น โครงการจากบริษัท |

## 9. stimulus จากไฟล์

### 9.1 การอ่านไฟล์ด้วย std_logic_textio

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;

architecture tb of tb_checksum8 is
  signal data  : std_logic_vector(7 downto 0);
  signal sum   : std_logic_vector(7 downto 0);
  signal parity : std_logic;
begin
  ...
  stimulus : process
    file vec_file : text open read_mode is "tb/vectors/checksum8_vectors.txt";
    variable l : line;
    variable v_in  : std_logic_vector(7 downto 0);
    variable v_sum : std_logic_vector(7 downto 0);
    variable v_par : std_logic;
  begin
    while not endfile(vec_file) loop
      readline(vec_file, l);
      if l'length > 0 then
        hread(l, v_in);
        hread(l, v_sum);
        hread(l, v_par);
        ...
      end if;
    end loop;
    ...
  end process;
end architecture tb;
```

### 9.2 รูปแบบไฟล์ vector

```text
8A 6F 0
01 02 1
FF 00 1
7F 81 1
```

รูปแบบ: อินพุต ค่าที่คาดหวังที่ 1 ค่าที่คาดหวังที่ 2 ต่อบรรทัด
คั่นด้วยช่องว่าง ใช้ `hread` อ่านค่าฐานสิบหก

### 9.3 ข้อควรระวังเรื่องพาธของไฟล์

`file ... open read_mode is "tb/vectors/..."` เป็นพาธ **สัมพัทธ์กับ directory ที่รัน**
ไม่ใช่พาธสัมพัทธ์กับไฟล์ testbench

ถ้ารันจาก directory อื่นจะเปิดไฟล์ไม่ได้ และจะได้ข้อความ
`cannot open file` ซึ่งมักทำให้สับสนว่าเป็นปัญหาของ DUT

**แนวทางที่ใช้ในโปรเจกต์นี้**: รัน `ghdl -r` จาก directory ที่กำหนดไว้แน่นอน
เช่น รากของ `code/reference/vhdl/` และอ้างอิงพาธจากตรงนั้น
สคริปต์ `scripts/check_example.sh` จัดการเรื่องนี้ให้แล้ว

## 10. เคสที่ต้องทดสอบเสมอ

| เคส | ทดสอบอย่างไร |
|---|---|
| reset | ตรวจว่าเอาต์พุตถูกกำหนดค่าใหม่หลัง reset และระหว่าง reset |
| ค่าขอบเขต | ทดสอบค่าสูงสุด ต่ำสุด และค่าที่ทำให้เกิด overflow |
| back-to-back | ส่ง/รับข้อมูลติดกันทุกรอบนาฬิกา |
| bubble | เว้นช่องว่างในสตรีมข้อมูล |
| ค่า X | ตรวจว่าเอาต์พุตไม่มีค่า X เมื่ออินพุตถูกต้อง |
| back-pressure | ปิด `ready` เป็น 0 แล้วตรวจว่าข้อมูลไม่หาย |
| ความถี่ต่างกัน | ใช้นาฬิกาสองตัวที่ไม่มีความสัมพันธ์กัน (สำหรับ CDC) |

### 10.1 เคสพิเศษของโมดูล combinational

ต้องพิสูจน์ด้วยว่าเอาต์พุตเปลี่ยนตามอินพุตโดยไม่ต้องมีขอบนาฬิกา

```vhdl
din <= x"5A";
wait for 1 ns;
assert dout = x"5A" report "output did not follow input" severity failure;
```

### 10.2 เคสพิเศษของโมดูลที่มีหน่วยความจำ

ต้องทดสอบการเขียนทับและการอ่านค่าที่ยังไม่เคยถูกเขียน
เพราะเป็นค่าที่มักถูกลืมในการทดสอบ

## 11. โครงสร้างไฟล์ที่แนะนำ

```text
tb/
├── tb_alu_comb.vhd
└── vectors/
    └── alu_comb_vectors.txt
```

ข้อกำหนด

- ไฟล์ vector เป็นข้อมูลจริง ไม่ใช่ไฟล์ว่าง
- แต่ละบรรทัดมีค่าครบ พร้อมคอมเมนต์อธิบายว่าเป็นกรณีอะไร
- ไฟล์ vector ควรมีจำนวนเคสพอสมควร ไม่ใช่แค่กรณีปกติ

ตัวอย่างไฟล์ vectorที่มีคอมเมนต์

```text
# รูปแบบ: อินพุต ค่าที่คาดหวัง
00 00
01 01
FF 01
7F 81
```

> คอมเมนต์ในไฟล์ vector ต้องใช้รูปแบบที่ `readline` ข้ามได้
> เพราะ `readline` จะอ่านทั้งบรรทัดรวมคอมเมนต์
> ให้ข้ามบรรทัดที่ว่างหรือขึ้นต้นด้วย `#` ด้วย `l'length = 0` หรือการตรวจอักขระแรก

---

## แบบฝึกหัดท้ายบท

1. เขียน testbench ของ `counter_sync` ที่ใช้ไฟล์ vector จาก `tb/vectors/`
   โดยแต่ละบรรทัดคือ `en load up load_value expected_count`
2. เพิ่มฟังก์ชัน `has_unknown` ใน testbench และตรวจค่า X ทุกครั้งที่เปรียบเทียบผล
3. ทำให้ testbench ทำงานผิดโดยตั้งใจ (เช่น เปลี่ยน `wait until rising_edge(clk)`
   เป็น `wait for 10 ns`) แล้วสังเกตว่า watchdog จับปัญหาได้อย่างไร
4. ลบ `wait;` ท้าย process แล้วรันด้วย `timeout 10 ghdl -r ...`
   จดข้อความที่ได้ แล้วอธิบายว่าเกิดอะไรขึ้น
5. เขียน golden model ของ `alu_comb` ใน testbench โดยไม่เรียกฟังก์ชันใดของ DUT
   แล้วเทียบผลกับ DUT ทุก opcode

## คำถามท้ายบท

1. ทำไมการตรวจผลหลัง `wait until rising_edge(clk)` ต้องรอเวลาเพิ่มอีกเล็กน้อย
2. ถ้านาฬิกาใน testbench ไม่หยุด จะเกิดอะไรขึ้นกับการจำลอง และเหตุใด
3. watchdog ต้องตรวจ `done` ก่อนรายงาน TIMEOUT ทำไม
4. ทำไม golden model จึงห้ามเรียกฟังก์ชันของ DUT
5. ตัวแปรนับ error ต้องเป็น `variable` ไม่ใช่ `signal` เพราะอะไร
6. ข้อความใน `report` ของ VHDL ต้องเป็น ASCII เท่านั้น มีผลต่อการเขียน
   `to_hstring` อย่างไร

---

**อ่านต่อ:** [บทที่ 12 — คำสั่งเครื่องมือ](12-tools-and-commands.md)

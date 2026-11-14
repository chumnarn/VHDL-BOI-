# บทที่ 14: เทียบกับ Verilog

> บทนี้เป็นสะพานสำหรับผู้ที่คุ้นเคยกับ Verilog แล้วต้องเขียน VHDL
> หรือผู้ที่ต้องดูแลโค้ดสองภาษาในโปรเจกต์เดียวกัน

**เครื่องมือที่เกี่ยวข้อง:** GHDL 1.0.0, Icarus Verilog 12.0, Yosys
**ตัวอย่างอ้างอิง:** `code/lab02/src/alu4.vhd` ↔ `code/lab02/src/alu4.v`,
`code/lab13/src/fifo_sync.vhd` ↔ `code/lab06/src/fifo_sync.v`

---

## สารบัญบท

- [1. ทำไมต้องเทียบสองภาษา](#1-ทำไมต้องเทียบสองภาษา)
- [2. ตารางคำสั่งเทียบเท่ากัน](#2-ตารางคำสั่งเทียบเท่ากัน)
- [3. ความต่างของระบบชนิดข้อมูล](#3-ความต่างของระบบชนิดข้อมูล)
- [4. ความต่างของการ assign](#4-ความต่างของการ-assign)
- [5. ความต่างของโครงสร้างวงจร](#5-ความต่างของโครงสร้างวงจร)
- [6. ตารางพอร์ตของโมดูลคู่ในคอร์ส](#6-ตารางพอร์ตของโมดูลคู่ในคอร์ส)
- [7. การตรวจว่าโค้ดสองภาษาเหมือนกัน](#7-การตรวจว่าโค้ดสองภาษาเหมือนกัน)
- [8. ข้อควรระวังเฉพาะของ VHDL](#8-ข้อควรระวังเฉพาะของ-vhdl)

---

## 1. ทำไมต้องเทียบสองภาษา

ในโปรเจกต์ที่มีทั้ง VHDL และ Verilog อยู่ร่วมกัน (เช่น โปรเจกต์ ASIC ที่ใช้
โมดูลมาตรฐานจากผู้ผลิตชิปที่ส่งมาในรูปแบบ Verilog) ผู้ออกแบบต้องอ่านโค้ดของอีกภาษาได้
แม้ไม่ได้เขียนเอง และต้องรู้ว่าจุดไหนของสองภาษาให้ผลลัพธ์ต่างกัน

บทนี้จึงเน้นสามสิ่ง

1. คำสั่งที่ "ดูเหมือนกัน" แต่ให้ผลลัพธ์ต่างกัน — อันตรายที่สุด
2. ตารางแปลชื่อพอร์ตของโมดูลจริงในคอร์ส เพื่อให้เทียบสองไฟล์ได้เร็ว
3. วิธีตรวจว่าสองเวอร์ชันให้ผลเหมือนกันจริง

---

## 2. ตารางคำสั่งเทียบเท่ากัน

| สิ่งที่ทำ | Verilog | VHDL |
|---|---|---|
| ประกาศโมดูล | `module alu4 ( ... );` | `entity alu4 is ... end entity;` |
| โครงสร้างภายใน | `always @(posedge clk)` | `process (clk)` + `if rising_edge(clk)` |
| ค่าคงที่ | `localparam W = 8;` | `constant W : positive := 8;` |
| parameter ของโมดูล | `parameter W = 8` | `generic (W : positive := 8)` |
| กำหนดค่าแบบ blocking | `x = a + b;` | `v := a + b;` (variable) |
| กำหนดค่าแบบ non-blocking | `x <= a + b;` | `q <= a + b;` (signal) |
| ที่อยู่ข้อมูลแบบต่อเนื่อง | `assign y = a & b;` | `y <= a & b;` (concurrent) |
| ตัวแปรชั่วคราว | `reg tmp;` (ใน always block) | `variable tmp_v : std_logic;` |
| เงื่อนไข | `if (a == 1'b1) begin ... end` | `if a = '1' then ... end if;` |
| หลายทาง | `case (x) ... endcase` | `case x is ... end case;` |
| ทางเลือก (สัญญาณ) | `assign y = c ? a : b;` | `y <= a when c else b;` |
| ลูปคงที่ | `for (i=0; i<8; i=i+1)` | `for i in 0 to 7 loop` |
| ลูปไม่มีจำนวนรอบครบ | `while (...)` / `forever` | `while ... loop` / `loop` |
| ออกจากลูป | `break;` / `disable` | `exit;` / `next;` |
| สร้างโมดูลย่อย | `submodule u_sub (...);` | `u_sub : entity work.submodule ...` |
| ตัวสร้างแบบซ้ำ | `generate` | `generate` |
| ฟังก์ชัน | `function f; ... endfunction` | `function f (...) return ...;` |
| โปรโซดูร์ | `task t; ... endtask` | `procedure p (...);` |
| การอ้างอิงข้ามโมดูล | `pkg::name` | `use work.pkg.all;` |

> ข้อสังเกตที่สำคัญ: ใน Verilog คำสั่ง `=` และ `<=` ถูกเลือกตาม "ชนิดของตัวแปร"
> แต่ใน VHDL การเลือกถูกกำหนดโดย **ชนิดของวัตถุที่ประกาศไว้** ไม่ใช่ตามบริบท
> การสับสนตรงนี้เป็นบั๊กที่พบบ่อยที่สุดของผู้ย้ายจาก Verilog มา VHDL

---

## 3. ความต่างของระบบชนิดข้อมูล

### 3.1 Verilog มีชนิดข้อมูลเดียวสำหรับบิต

Verilog (ทั้ง Verilog-2001 และ SystemVerilog ส่วนใหญ่ที่ใช้ในคอร์สนี้)
ใช้ `bit` กับ `logic` เป็นตัวเลข 4 สถานะ `'0`, `'1`, `'x`, `'z`

VHDL แยกเป็น

| ชนิด | ค่าที่เป็นไปได้ | ใช้ทำอะไร |
|---|---|---|
| `std_logic` | `'0'`, `'1'`, `'X'`, `'Z'`, `'U'`, `'W'`, `'L'`, `'H'`, `'-'` | สัญญาณดิจิทัลทั่วไป |
| `std_ulogic` | เหมือน `std_logic` | ฐานของ `std_logic` |
| `bit` | `'0'`, `'1'` | ค่าที่ไม่มีความกำกวม |
| `boolean` | `false`, `true` | ผลของเงื่อนไข |

ผลที่ตามมาในการเขียนโค้ด

- ใน Verilog เขียน `if (x)` ได้ แต่ใน VHDL ไม่ได้ เพราะ `std_logic` ไม่ใช่ `boolean`
  ต้องเขียน `if x = '1' then`
- ใน Verilog `!x` คือ NOT แบบตรรกะ (x เป็น '0' คือ 1) แต่ใน VHDL `not x` คือ NOT แบบ
  บิตต่อบิต (`not '0'` = `'1'`, `not '1'` = `'0'`, `not 'X'` = `'X'`)
  ถ้าต้องการพฤติกรรมแบบ Verilog ต้องเขียน `if x = '0' then` ไม่ใช่ `if not x = '1' then`
- ใน Verilog การเทียบกับ `x` ที่เป็น `'x'` ให้ผลเป็น `x` (ไม่เท่ากัน)
  ใน VHDL การเทียบด้วย `=` ก็ให้ผลเป็น `false` เช่นกัน แต่ `std_logic_1164`
  มีฟังก์ชัน `is_x` ที่ใช้ตรวจค่าที่ไม่นิยามได้โดยตรง

### 3.2 Verilog มีตัวเลขที่ไม่มีขนาด VHDL ต้องประกาศให้ชัด

Verilog ใช้ `integer` (32 บิต, signed) เป็นค่าเริ่มต้นของตัวเลขทั้งหมด
VHDL ต้องระบุขอบเขตให้ชัดเจน และ `integer` ใน VHDL เป็น **unsigned**

```vhdl
-- VHDL: integer เป็น unsigned และมีขอบเขตตาม implementation
-- ถ้าต้องการค่าที่ติดลบได้ให้ใช้ signed
variable diff_v : integer;
variable sdiff_v : signed(31 downto 0);
```

ผลที่ตามมา

- `cnt <= cnt + 1;` ใน Verilog ได้ผลตามความกว้างบิตของ `cnt` (wrap เอง)
- ใน VHDL `cnt` ที่เป็น `std_logic_vector` **บวกกันไม่ได้** ต้องแปลงเป็น `unsigned` ก่อน
  และ `unsigned` จะ wrap ตามความกว้างบิตให้เอง ซึ่งตรงกับ Verilog
  (ดูคอมเมนต์ใน `code/lab05/src/counter4.vhd`)

### 3.3 `std_logic_vector` กับ `unsigned` / `signed` เป็นคนละชนิดกัน

นี่คือบั๊กที่พบบ่อยที่สุดในการย้ายจาก Verilog

```vhdl
signal a_v : std_logic_vector(7 downto 0);
signal b_v : unsigned(7 downto 0);

-- ผิด: คนละ array type จึง assign กันไม่ได้
-- b_v <= a_v;

-- ถูก: แปลงที่ขอบของโมดูล
b_v <= unsigned(a_v);
a_v <= std_logic_vector(b_v);
```

Verilog ไม่มีปัญหานี้เพราะทุกอย่างเป็น `bit vector` ชนิดเดียว

---

## 4. ความต่างของการ assign

### 4.1 blocking กับ non-blocking

| | Verilog | VHDL |
|---|---|---|
| blocking | `=` ใช้ใน `always @(*)` | `:=` กับ variable |
| non-blocking | `<=` ใน `always @(posedge clk)` | `<=` กับ signal |

**กฎเดียวใน VHDL:** เลือกตามชนิดของวัตถุ ไม่ใช่ตามบริบท

- ประกาศไว้เป็น `signal` → ใช้ `<=` เท่านั้น
- ประกาศไว้เป็น `variable` → ใช้ `:=` เท่านั้น

การเขียน `:=` กับ signal จะได้ข้อความ error `object "x" is not a signal`
และการเขียน `<=` กับ variable จะได้ `variable "x" cannot be assigned with signal assignment`

### 4.2 การอ่านค่าที่เพิ่งถูก assign

ทั้งสองภาษามีพฤติกรรม "อ่านค่าเก่า" เหมือนกัน แต่ VHDL ทำให้เห็นชัดกว่าเพราะ
การอ่าน signal ใน process เดียวกัน **ไม่มีทางได้ค่าใหม่** เลย

```vhdl
-- ค่าที่อ่านได้คือค่าเก่าเสมอ
if cnt = 0 then
  cnt <= cnt + 1;      -- ใช้ค่า cnt เก่าในการคำนวณ
end if;
```

ถ้าต้องการ "ค่าถัดไป" ให้คำนวณใน variable ก่อน แล้ว assign ทีเดียวท้าย process
(ดูแม่แบบใน `code/reference/vhdl/examples/ex01_alu_comb/src/alu_comb.vhd`)

### 4.3 การอ่านค่า `out` ของ procedure

ข้อจำกัดเฉพาะ VHDL-2002: procedure ที่มีพารามิเตอร์โหมด `out`
**อ่านค่ากลับเข้ามาไม่ได้** ภายใน procedure

```vhdl
procedure rom_read (addr : in natural; word : out rom_word_t) is
begin
  word := rom_entry(addr);      -- ถูก คือการ assign
  -- if word = x then ... end if;   -- ผิดใน VHDL-2002
end procedure;
```

ใน VHDL-2008 อ่าน `out` parameter ได้ แต่คู่มือนี้ต้องคอมไพล์ผ่าน `--std=02` ด้วย
จึงต้องหลีกเลี่ยงรูปแบบนี้

---

## 5. ความต่างของโครงสร้างวงจร

### 5.1 reset แบบ asynchronous กับ synchronous

Verilog เขียน `always @(posedge clk or negedge rst_n)` ได้ในบล็อกเดียว
VHDL ต้องแยกเป็น sensitivity list ที่ระบุชัด

```vhdl
process (clk, rst_n)          -- asynchronous
begin
  if rst_n = '0' then
    ...
  elsif rising_edge(clk) then
    ...
  end if;
end process;
```

ข้อควรระวัง: ถ้าใส่ `rst_n` ใน sensitivity list แต่ไม่ได้เขียนสาขา `if rst_n = '0'`
จะได้ reset ที่ทำงานผิดวิธี (sensitivity ระบุว่า process ต้องตื่น แต่โค้ดไม่ได้จัดการ)

### 5.2 ค่าเริ่มต้นของ signal

| | Verilog | VHDL |
|---|---|---|
| `reg` / `logic` | ค่า `x` (ไม่ใช่ 0) | ค่า `'U'` |
| `wire` | — | ไม่มี signal ที่ driver ไม่ได้กำหนดค่า |
| กำหนดค่าเริ่มต้น | `initial` (ใช้กับ FPGA ได้ ไม่ได้กับ ASIC) | `signal x_i : std_logic := '0';` |

การประกาศ `:= '0'` ใน VHDL เป็นการกำหนดค่าเริ่มต้นซึ่งทำงานได้ทั้งในการจำลอง
และการสังเคราะห์ (สำหรับ register ที่ต้องการค่าเริ่มต้นที่กำหนดไว้)

### 5.3 การสร้างโมดูลย่อย

```vhdl
-- VHDL: ระบุชนิดของแต่ละพอร์ตให้ครบ คอมไพล์จะจับชื่อพอร์ตผิดได้
u_alu : entity work.alu4
  generic map (
    DATA_WIDTH => 8
  )
  port map (
    opcode => opcode_i,
    a      => a_i,
    b      => b_i
  );
```

```verilog
// Verilog: ชื่อพอร์ตผิดจะไม่ถูกจับในการคอมไพล์
alu4 u_alu (
  .opcode(opcode_i),
  .a(a_i),
  .b(b_i)
);
```

การใช้ `entity work.xxx` ทำให้ VHDL ตรวจชื่อพอร์ตได้ตั้งแต่ตอนคอมไพล์
ซึ่งเป็นข้อได้เปรียบเมื่อเทียบกับ Verilog

### 5.4 ชนิดของ output

Verilog ใช้ `output reg` เมื่อต้องกำหนดค่าในบล็อก `always`
VHDL ไม่แยกชนิด — `out` กำหนดค่าได้ทั้งใน process และแบบ concurrent

```vhdl
-- VHDL
dout <= mem_i(addr);       -- concurrent
-- หรือ
dout <= mem_i(addr);       -- ใน clocked process
```

---

## 6. ตารางพอร์ตของโมดูลคู่ในคอร์ส

ตารางนี้ใช้ตรวจว่าไฟล์ VHDL และ Verilog ของโมดูลเดียวกันตรงกัน
ให้เปรียบเทียบรายการในตารางกับไฟล์จริงทุกครั้งที่แก้โค้ด

### 6.1 `alu4` — `code/lab02/src/alu4.vhd` ↔ `code/lab02/src/alu4.v`

| พอร์ต | ทิศทาง | VHDL | Verilog |
|---|---|---|---|
| `opcode` | in | `in std_logic_vector(2 downto 0)` | `input wire [2:0]` |
| `a` | in | `in std_logic_vector(3 downto 0)` | `input wire [3:0]` |
| `b` | in | `in std_logic_vector(3 downto 0)` | `input wire [3:0]` |
| `result` | out | `out std_logic_vector(3 downto 0)` | `output reg [3:0]` |
| `zero` | out | `out std_logic` | `output reg` |
| `carry_out` | out | `out std_logic` | `output reg` |
| `borrow_out` | out | `out std_logic` | `output reg` |
| `overflow` | out | `out std_logic` | `output reg` |

รหัส opcode ต้องตรงกัน: `000`=ADD, `001`=SUB, `010`=AND, `011`=OR,
`100`=XOR, `101`=SHL, `110`=SHR, `111`=PASS

### 6.2 `counter4` — `code/lab05/src/counter4.vhd` ↔ `code/lab05/src/counter4.v`

| พอร์ต | ทิศทาง | VHDL | Verilog |
|---|---|---|---|
| `clk` | in | `in std_logic` | `input wire` |
| `rst_n` | in | `in std_logic` | `input wire` |
| `rst_sync_n` | in | `in std_logic` | `input wire` |
| `en` | in | `in std_logic` | `input wire` |
| `load` | in | `in std_logic` | `input wire` |
| `up` | in | `in std_logic` | `input wire` |
| `load_val` | in | `in std_logic_vector(3 downto 0)` | `input wire [3:0]` |
| `count` | out | `out std_logic_vector(3 downto 0)` | `output wire [3:0]` |
| `carry_out` | out | `out std_logic` | `output wire` |
| `borrow_out` | out | `out std_logic` | `output wire` |

ลำดับความสำคัญต้องเหมือนกันทั้งสองภาษา: `rst_n` > `rst_sync_n` > `load` > `en`

### 6.3 `traffic_fsm` — `code/lab05/src/traffic_fsm.vhd` ↔ `code/lab05/src/traffic_fsm.v`

| พอร์ต | ทิศทาง | VHDL | Verilog |
|---|---|---|---|
| `DIV` | generic | `generic (DIV : positive := 4)` | `parameter DIV = 4` |
| `clk` | in | `in std_logic` | `input wire` |
| `rst_n` | in | `in std_logic` | `input wire` |
| `enable` | in | `in std_logic` | `input wire` |
| `state` | out | `out std_logic_vector(2 downto 0)` | `output wire [2:0]` |
| `red` | out | `out std_logic` | `output reg` |
| `yellow` | out | `out std_logic` | `output reg` |
| `green` | out | `out std_logic` | `output reg` |
| `tick_out` | out | `out std_logic` | `output wire` |

### 6.4 `fifo_sync` — `code/lab13/src/fifo_sync.vhd` ↔ `code/lab06/src/fifo_sync.v`

| พอร์ต | ทิศทาง | VHDL | Verilog |
|---|---|---|---|
| `DATA_WIDTH` | generic | `generic (DATA_WIDTH : positive := 8)` | `parameter DATA_WIDTH = 8` |
| `ADDR_WIDTH` | generic | `generic (ADDR_WIDTH : positive := 3)` | `parameter ADDR_WIDTH = 3` |
| `clk` | in | `in std_logic` | `input wire` |
| `rst_n` | in | `in std_logic` | `input wire` |
| `wr_en` | in | `in std_logic` | `input wire` |
| `wr_data` | in | `in std_logic_vector(DATA_WIDTH-1 downto 0)` | `input wire [DATA_WIDTH-1:0]` |
| `rd_en` | in | `in std_logic` | `input wire` |
| `rd_data` | out | `out std_logic_vector(DATA_WIDTH-1 downto 0)` | `output reg` |
| `full` | out | `out std_logic` | `output wire` |
| `empty` | out | `out std_logic` | `output wire` |
| `count` | out | `out std_logic_vector(...)` | `output wire [...]` |

> **หมายเหตุสำคัญ:** ทั้งสองไฟล์อยู่คนละ Lab (Verilog อยู่ Lab 06, VHDL อยู่ Lab 13)
> ให้ดูด้วยว่าโจทย์และความกว้างของข้อมูลตรงกันหรือไม่ก่อนเทียบผล

### 6.5 `uart_tx` — `code/lab14/src/uart_tx.vhd` ↔ `code/lab14/src/uart_tx.v`

| พอร์ต | ทิศทาง | VHDL | Verilog |
|---|---|---|---|
| `CLKS_PER_BIT` | generic | `generic (CLKS_PER_BIT : integer := 87)` | `parameter CLKS_PER_BIT = 87` |
| `clk` | in | `in std_logic` | `input wire` |
| `rst_n` | in | `in std_logic` | `input wire` |
| `tx_data_valid` | in | `in std_logic` | `input wire` |
| `tx_data` | in | `in std_logic_vector(7 downto 0)` | `input wire [7:0]` |
| `tx_busy` | out | `out std_logic` | `output reg` |
| `tx_serial` | out | `out std_logic` | `output reg` |

> **หมายเหตุ:** ในตัวอย่างอ้างอิง `code/reference/vhdl/examples/ex10_uart_tx/`
> ชื่อพอร์ตต่างจากของ Lab 14 เล็กน้อย (`tx_start` แทน `tx_data_valid`)
> เพราะเป็นคนละชุดโค้ดกัน เมื่อนำไปใช้ร่วมกันต้องแก้ชื่อให้ตรงกันก่อน

---

## 7. การตรวจว่าโค้ดสองภาษาเหมือนกัน

### 7.1 เทียบจากสเปกตรัมของสัญญาณ ไม่ใช่จากการอ่านโค้ด

วิธีที่น่าเชื่อถือที่สุดคือให้ทั้งสองเวอร์ชันรับ stimulus เดียวกัน
แล้วเทียบ waveform ทีละสัญญาณ

1. เขียน testbench ฝั่ง Verilog และฝั่ง VHDL ให้ขับอินพุตชุดเดียวกันตามลำดับเวลาเดียวกัน
2. เขียน VCD จากทั้งสองฝั่ง
3. เทียบสัญญาณที่ตรงกันทีละจุดเวลา

คอร์สนี้มีตัวอย่างการทำงานแบบนี้อยู่ที่ `code/lab09/tb/tb_equiv.v`
ซึ่งเปรียบเทียบผลลัพธ์ของสองเวอร์ชันใน testbench เดียวกัน

### 7.2 จุดที่มักต่างกันเมื่อเทียบ

| จุดต่าง | อาการที่เห็น |
|---|---|
| ความกว้างบิตของตัวนับ | ค่า wrap ที่คนละจุด เช่น 15→0 กับ 16→1 |
| การ wrap ของ `unsigned` | Verilog ตัดทิ้งบิตเกิน ส่วน VHDL ถ้าใช้ `integer` จะไม่ wrap |
| ค่า X | Verilog ให้ `x` กระจาย ส่วน VHDL ให้ `'U'` ในบางกรณี |
| ลำดับความสำคัญของ reset | ถ้าต่างกัน ผลต่างกันเฉพาะช่วง reset |
| `x` ในสัญญาณเลือก | Verilog ทำให้เอาต์พุตเป็น `x` ทั้งหมด ส่วน VHDL ต้องระวังการเทียบ `'X'` |
| เงื่อนไขที่ใช้ `if (x)` | VHDL ต้องเขียน `if x = '1'` ซึ่งให้ผลต่างกันเมื่อ x เป็น `'X'` |

### 7.3 เกณฑ์ที่ใช้ในคอร์สนี้

การตรวจ equivalence ที่คอร์สใช้มี 3 ระดับ เรียงจากถูกไปแพง

| ระดับ | วิธี | จับอะไรได้ | ต้นทุน |
|---|---|---|---|
| 1 | คอมไพล์ทั้งสองภาษาและสังเคราะห์ | ชื่อพอร์ตผิด, ตัวเลขที่ไม่ใช่ integer | ต่ำ |
| 2 | เทียบสัญญาณระหว่างการจำลองทั้งสองฝั่ง | ตรรกะต่างกัน, จังหวะต่างกัน | กลาง |
| 3 | เทียบ netlist หลังสังเคราะห์ | ความต่างที่เกิดจากการ map เป็น gate | สูง |

ระดับ 2 คือระดับที่ให้ผลคุ้มค่าที่สุดสำหรับโค้ด RTL
เพราะจับข้อผิดพลาดที่ระดับพฤติกรรมได้ก่อนที่จะเสียเวลาไปสังเคราะห์เต็มรูปแบบ

---

## 8. ข้อควรระวังเฉพาะของ VHDL

สรุปเป็นรายการตรวจสอบก่อนส่งโค้ด VHDL

- [ ] context clause ประกาศซ้ำก่อน **ทุก** design unit
- [ ] ไม่มี `ieee.std_logic_arith`
- [ ] ใช้ `<=` กับ signal และ `:=` กับ variable เท่านั้น
- [ ] combinational process กำหนดค่าเอาต์พุตครบทุก path
- [ ] `case` ที่แปลงค่าเป็น enum มี `when others`
- [ ] ไม่มีฟีเจอร์เฉพาะ VHDL-2008 ใน RTL (เช่น `process (all)`, `std.env`,
      conditional variable assignment, `to_hstring`)
- [ ] คอมไพล์ผ่าน `--std=02` ด้วย เพราะ ModelSim ของห้องเรียนตั้ง VHDL93 = 2002
- [ ] ชื่อพอร์ตตรงกับเวอร์ชัน Verilog ของโมดูลเดียวกัน
- [ ] ข้อความใน `report "..."` เป็น ASCII เท่านั้น

---

## แบบฝึกหัดท้ายบท

1. เขียน `alu4` ใหม่ใน VHDL จากตารางพอร์ตข้อ 6.1 โดยไม่เปิดไฟล์ Verilog
   แล้วเทียบผลกับเวอร์ชันเดิมด้วย testbench ที่ขับอินพุตชุดเดียวกัน
2. แก้ `alu4.vhd` ให้ carry ของ SUB กลับด้าน แล้วเขียน testbench ที่จับได้
   โดยไม่แก้ testbench ฝั่ง Verilog แล้วอธิบายว่าทำไมเทสต์ที่ผ่านจึงยังพอใช้ได้
3. เขียนตารางพอร์ตของ `traffic_fsm` และ `fifo_sync` ในรูปแบบเดียวกับข้อ 6
   แล้วตรวจว่ารหัสสถานะของ FSM ตรงกันทั้งสองภาษา
4. เขียนตัวอย่าง VHDL ที่ใช้ `if (x)` แบบ Verilog แล้วอธิบายว่าผลต่างกันอย่างไร
   เมื่อ `x` เป็น `'1'`, `'0'` และ `'X'`
5. สร้างโฟลเดอร์ `tb/` ที่เขียน VCD จากทั้งสองฝั่ง แล้วเขียนสคริปต์เปรียบเทียบ
   ที่รายงานจุดที่ต่างกันพร้อมเวลา

## คำถามท้ายบท

1. ใน VHDL การเลือกใช้ `<=` หรือ `:=` ขึ้นอยู่กับอะไร และต่างจาก Verilog อย่างไร
2. ทำไม `std_logic_vector` บวกกันเองไม่ได้ แต่ Verilog บวกได้
3. `if x = '1'` กับ `if x` ให้ผลต่างกันเมื่อ `x` เป็น `'X'` อย่างไร
4. การอ่านค่า signal ภายใน clocked process ทำให้เกิดบั๊กอะไร
   และแก้อย่างไรโดยไม่เปลี่ยนพฤติกรรมภายนอก
5. ข้อ 7.2 ระบุจุดต่างที่มักพบ 5 ข้อ ข้อใดอันตรายที่สุด และเพราะอะไร
6. การใช้ `entity work.xxx` ช่วยตรวจจับชื่อพอร์ตผิดได้อย่างไร
   ในขณะที่ `component instantiation` ตรวจไม่ได้

---

**อ่านต่อ:** [บทที่ 15 — เช็กลิสต์ก่อนส่งงาน](15-checklists.md)

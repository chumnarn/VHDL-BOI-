# บทที่ 03: รูปแบบการเขียนโค้ดและการตั้งชื่อ

> บทนี้คือบทที่บังคับใช้จริงในโปรเจกต์ แต่ละกฎมีเหตุผลประกอบ
> เพื่อให้ผู้เรียนเข้าใจว่า "ทำไม" ไม่ใช่แค่ "ทำตาม"

**เครื่องมือที่เกี่ยวข้อง:** GHDL 1.0.0, เครื่องมือตรวจบรรทัด (editor) ใด ๆ

---

## สารบัญบท

- [1. ทำไมต้องมีรูปแบบที่เขียนไว้](#1-ทำไมต้องมีรูปแบบที่เขียนไว้)
- [2. โครงสร้างไฟล์ RTL มาตรฐาน](#2-โครงสร้างไฟล์-rtl-มาตรฐาน)
- [3. การตั้งชื่อ](#3-การตั้งชื่อ)
- [4. การเขียน process](#4-การเขียน-process)
- [5. คอมเมนต์ที่มีประโยชน์](#5-คอมเมนต์ที่มีประโยชน์)
- [6. รูปแบบไฟล์และเครื่องมือ](#6-รูปแบบไฟล์และเครื่องมือ)
- [7. ชื่อ signal ต้องตรงกันข้ามภาษา](#7-ชื่อ-signal-ต้องตรงกันข้ามภาษา)
- [8. ไฟล์มาตรฐานเต็ม](#8-ไฟล์มาตรฐานเต็ม)

---

## 1. ทำไมต้องมีรูปแบบที่เขียนไว้

เหตุผลที่รูปแบบมีความสำคัญในงาน RTL มากกว่างานซอฟต์แวร์ทั่วไป เพราะ
**ข้อผิดพลาดใน RTL มักไม่ทำให้โปรแกรมพัง แต่ทำให้วงจรทำงานผิดแบบเงียบ ๆ**

ตัวอย่างที่พบบ่อย

| ความไม่เป็นมาตรฐาน | ผลที่ตามมาในวงจรจริง |
|---|---|
| ใช้ `:=` กับ signal ภายใน clocked process | ได้ latch แทน flip-flop ทำงานผิดจังหวะ |
| ไม่ประกาศ context clause ซ้ำ | คอมไพล์ไม่ผ่านในห้องเรียน เสียเวลาแก้ |
| ชื่อ signal ต่างกันระหว่าง VHDL กับ Verilog | เทียบผลข้ามภาษาไม่ได้ จับบั๊กไม่เจอ |
| ไม่มี watchdog ใน testbench | simulation ค้างเมื่อ DUT ทำงานไม่ถูก แทนที่จะรายงานว่าล้มเหลว |
| ข้อความไทยใน `report "..."` | คอมไพล์ไม่ผ่านบน Windows ที่ใช้ encoding ต่างกัน |

กฎในบทนี้ถูกใช้จริงกับตัวอย่างทั้งหมดในชุด `code/reference/vhdl/examples/`
และสัญญารูปแบบฉบับเต็มอยู่ที่ `code/reference/vhdl/STYLE-CONTRACT.md`

## 2. โครงสร้างไฟล์ RTL มาตรฐาน

ลำดับส่วนประกอบของไฟล์ `.vhd` ที่เป็น RTL

```text
1. หัวไฟล์คอมเมนต์        ชื่อโมดูล / วัตถุประสงค์ / มาตรฐาน / สิ่งที่สอน
2. context clause         library ieee; use ieee....
3. entity                  พอร์ตและ generic
4. context clause (ซ้ำ)   library ieee; use ieee....
5. architecture rtl        declarative part → statement part
6. context clause (ซ้ำ)   ถ้ามี package declaration ต่อท้ายไฟล์
7. package declaration     (ถ้ามี)
```

เหตุผลของการสลับ context clause: ตามภาษา context clause มีผลกับ design unit
ถัดไปหนึ่งหน่วยเท่านั้น (ดู [บทที่ 01](01-language-basics.md#3-context-clause-มีผลกับหนึ่งหน่วยเท่านั้น))
การประกาศซ้ำทำให้แต่ละหน่วย "สวมตัวเอง" ได้ ทำให้ย้ายไฟล์ไปใช้ที่อื่นได้ทันที

### 2.1 หัวไฟล์คอมเมนต์

ต้องมีข้อมูล 4 ส่วน เพื่อให้คนอ่านโค้ดที่ไม่ได้เขียนเองเข้าใจโดยไม่ต้องเปิด simulator

```vhdl
-- <ชื่อโมดูล>: <วัตถุประสงค์หนึ่งบรรทัด>
--
-- <รายละเอียดว่าทำอะไร และมีข้อกำหนดอะไรที่ต้องรู้>
--
-- มาตรฐาน:      VHDL-2008 (คอมไพล์ผ่านมาตรฐาน VHDL-2002 ด้วย)
-- Synthesizable: ใช่ — <อธิบายสั้น ๆ ว่าสังเคราะห์เป็นอะไร>
--
-- สิ่งที่โมดูลนี้สอน:
--   1. ...
--   2. ...
```

เหตุผลที่ต้องเขียน "สิ่งที่โมดูลนี้สอน" — ในโปรเจกต์จริงไฟล์หนึ่งไฟล์อาจเป็นตัวอย่าง
ของรูปแบบโค้ดระดับโปรเจกต์ การระบุไว้ช่วยให้ผู้อ่านรู้ทันทีว่าไฟล์นี้เป็น
"ตัวอย่างเชิงแนวคิด" หรือ "โค้ดที่ต้องทำงานจริง"

## 3. การตั้งชื่อ

### 3.1 ตารางรวม

| สิ่ง | รูปแบบ | ตัวอย่าง | หมายเหตุ |
|---|---|---|---|
| entity | `snake_case` | `alu_comb`, `uart_tx`, `fifo_sync` | ต้องตรงกับชื่อไฟล์ |
| package | `snake_case` + `_pkg` | `dsp_types_pkg` | ปิดท้ายด้วย `_pkg` เสมอ |
| architecture | `rtl` / `tb` | `architecture rtl of alu_comb` | ใช้สองค่านี้เท่านั้นในโปรเจกต์นี้ |
| generic | `UPPER_CASE` | `DATA_WIDTH`, `ADDR_WIDTH` | ตั้งชื่อให้สื่อความหมาย ไม่ใช้ `W`, `N` เดี่ยว ๆ |
| พอร์ต / signal | `snake_case` | `din`, `dout`, `wr_en`, `cnt` | ชื่อสั้นแต่มีความหมาย |
| signal ภายใน | ต่อท้าย `_i` | `state_i`, `cnt_i`, `full_i` | แยกจากพอร์ตด้วยตาได้ |
| signal ผลลัพธ์ของ process | ต่อท้าย `_o` | `comb_o` | ใช้เมื่อ process หนึ่งขับหลายสัญญาณ |
| variable ใน process | ต่อท้าย `_v` หรือชื่อสื่อความหมาย | `next_state_v`, `tmp` | ไม่บังคับ แต่ช่วยแยกจาก signal |
| constant | `UPPER_CASE` | `S_IDLE`, `DEPTH`, `CLKS_PER_BIT` | constant ของ enum ใช้ชื่อสถานะนำหน้า |
| type | `snake_case` + `_t` | `state_t`, `mem_t` | ต่อท้าย `_t` |
| ชื่อ process | `<บทบาท>_p` | `comb_p`, `seq_p`, `fsm_p` | ชื่อบอกบทบาท ไม่ใช่ลำดับ |
| instance | `<ชื่อโมดูล>_inst` หรือ `u_<ชื่อ>` | `u_alu`, `fifo_inst` | ในโปรเจกต์นี้ใช้ `u_<ชื่อ>` |
| function / procedure | `<กริยา_>_<สิ่งที่ทำ>` | `opcode_from_slv`, `alu4_eval` | ขึ้นต้นด้วยกริยา |

### 3.2 ชื่อพอร์ตมาตรฐานของโปรเจกต์

ใช้ชื่อเหล่านี้ให้เหมือนกันทุกโมดูล จะทำให้อ่านโค้ดของคนอื่นได้เร็ว

| ชื่อ | ความหมาย | ชนิด/รูปแบบ |
|---|---|---|
| `clk` | นาฬิกาหลัก | `in std_logic` |
| `rst_n` | reset แอกทีฟโลว์ | `in std_logic` |
| `rst` | reset แอกทีฟไฮ | `in std_logic` (ใช้เมื่อต้องการระบุชัด) |
| `en` / `enable` | สัญญาณอนุญาตให้ทำงาน | `in std_logic` |
| `valid` / `in_valid` | ข้อมูลพร้อมใช้ | `in std_logic` |
| `ready` / `in_ready` | ผู้รับพร้อมรับ | `out std_logic` |
| `ack` | การตอบรับ | `in std_logic` |
| `wr_en`, `rd_en` | เขียน / อ่าน | `in std_logic` |
| `data`, `din`, `dout` | ข้อมูล | `std_logic_vector` |
| `state` | สถานะปัจจุบัน | `std_logic_vector` หรือ enum |
| `busy`, `full`, `empty` | สถานะความพร้อม | `out std_logic` |

### 3.3 ชื่อ signal ภายในกับพอร์ต

ในโปรเจกต์นี้ใช้หลัก **"พอร์ตคือสัญญา ภายในคือกลไก"**

```vhdl
architecture rtl of fifo_sync is
  signal cnt_i     : unsigned(ADDR_WIDTH downto 0);  -- กลไกภายใน
  signal full_i    : std_logic;                     -- กลไกภายใน
begin
  full_i  <= '1' when cnt_i = to_unsigned(DEPTH, cnt_i'length) else '0';
  full    <= full_i;                                -- ส่งออกพอร์ตที่จุดเดียว
end architecture rtl;
```

ข้อดี

- เห็นทันทีว่าอะไรคือขอบเขตของโมดูล (พอร์ต) และอะไรคือรายละเอียดภายใน
- เปลี่ยนกลไกภายในได้โดยไม่กระทบสัญญาภายนอก
- แก้ปัญหา "อ่าน out port ของตัวเองไม่ได้" ใน VHDL-2002 ได้อย่างเป็นระบบ

## 4. การเขียน process

### 4.1 combinational process

```vhdl
comb_p : process (a, b, sel)          -- ← ระบุ sensitivity list ให้ครบ
begin
  ...
end process comb_p;
```

**กฎ:** ระบุ sensitivity list ให้ครบทุกสัญญาณที่อ่านใน process
ถ้าใช้ VHDL-2008 สามารถใช้ `process (all)` ได้ แต่โค้ดที่ส่งให้ผู้เรียนต้องคอมไพล์ด้วย
`--std=02` จึงต้องเขียนให้ครบ

### 4.2 clocked process

```vhdl
seq_p : process (clk)                 -- ← sensitivity list มีแค่นาฬิกา
begin
  if rising_edge(clk) then
    ...
  end if;
end process seq_p;
```

หรือเมื่อใช้ asynchronous reset

```vhdl
seq_p : process (clk, rst_n)          -- ← มีทั้งนาฬิกาและ reset
begin
  if rst_n = '0' then
    ...
  elsif rising_edge(clk) then
    ...
  end if;
end process seq_p;
```

### 4.3 ตั้งชื่อ process

ตั้งชื่อ process เสมอ เพราะเมื่อเกิด error GHDL จะบอกว่า error เกิดใน process ไหน

```vhdl
comb_p : process (a, b, sel)    -- ← มีชื่อ
begin
  ...
end process comb_p;
```

ข้อความ error จะอ่านง่ายขึ้นมาก เช่น
`examples/ex01/src/alu_comb.vhd:64:5:@10ns:(assertion failure): comb_p: ...`

### 4.4 signal ที่ถูก assign ใน clocked process

**กฎที่ทำให้เสียเวลา debug มากที่สุด** — ถ้า signal ถูกประกาศนอก process
แล้วถูก assign ใน clocked process ค่านั้นจะกลายเป็น **latch**
เพราะเมื่อไม่มีเงื่อนไข `rising_edge` ที่เป็นจริง process จะไม่กำหนดค่าใหม่
เครื่องมือจึงเก็บค่าเดิมไว้

```vhdl
architecture rtl of bad is
  signal q_i : std_logic;         -- ← ถ้าประกาศนอก process แล้ว assign ใน clocked process
begin
  seq_p : process (clk)
  begin
    if rising_edge(clk) then
      q_i <= d;                    -- ← กลายเป็น latch ไม่ใช่ flip-flop
    end if;
  end process;
  q <= q_i;
end architecture rtl;
```

วิธีแก้: ย้าย `q` เป็น `out` port แล้ว assign ใน clocked process โดยตรง
หรือถ้าต้องมี logic กลาง ให้แยกเป็น combinational process หนึ่งตัว

> เครื่องมือสังเคราะห์ส่วนใหญ่จะเตือนเรื่องนี้ แต่คำเตือนมักมาตอนสังเคราะห์
> ซึ่งช้ากว่าการตรวจด้วย simulator

## 5. คอมเมนต์ที่มีประโยชน์

### 5.1 อธิบาย "เหตุผล" ไม่ใช่ "สิ่งที่โค้ดทำ"

```vhdl
-- ✗ ไม่มีประโยชน์ เพราะบอกว่าสิ่งที่โค้ดทำอยู่แล้ว
-- กำหนดค่าเริ่มต้นของตัวนับ
cnt <= (others => '0');

-- ✓ อธิบายเหตุผลที่ต้องเป็นแบบนี้
-- กำหนดค่าเริ่มต้นเป็นศูนย์ เพื่อให้ state ไม่เริ่มที่ค่าที่ไม่ได้นิยาม
-- ซึ่งจะทำให้ simulation รายงานค่า X ในรอบแรก
cnt <= (others => '0');
```

### 5.2 ภาษาไทยใช้ได้ในคอมเมนต์ แต่ไม่ได้ใน string literal

```vhdl
-- ✓ คอมเมนต์ภาษาไทยใช้ได้
if cnt = 0 then
  -- ตัวนับเป็นศูนย์ แปลว่าไม่มีข้อมูล
  empty_o <= '1';
end if;

-- ✗ string literal ต้องเป็น ASCII เท่านั้น
report "ตัวนับเป็นศูนย์" severity note;   -- ← error: String literal has a character with value 0xE0
report "counter is zero" severity note;     -- ✓
```

เหตุผลทางเทคนิค: string literal ของ VHDL ประกาศเป็นชนิด `CHARACTER`
ซึ่งในมาตรฐาน IEEE 1076 รองรับเฉพาะ Latin-1 (256 ค่า)
ไฟล์ที่บันทึกเป็น UTF-8 จะมีไบต์หลายไบต์ต่ออักขระ จึงเกิดข้อผิดพลาด
เมื่อแสดงผลหรือบันทึก log บน Windows ที่ใช้ encoding ต่างกัน

> ถ้าต้องการข้อความภาษาไทยในผลลัพธ์ ให้เขียนเป็นไฟล์ข้อความแยก
> แล้วอ้างอิงด้วย `file open` แทน หรือใช้ `to_string` ใน VHDL-2008
> ซึ่งยังมีข้อจำกัดเรื่อง encoding เช่นเดียวกัน

### 5.3 ระบุ "อะไรไม่ได้ทำ" บ้าง

คอมเมนต์ที่ดีควรบอกข้อจำกัดด้วย เช่น

```vhdl
-- ข้อจำกัด: สังเคราะห์เป็น flip-flop แยกตัว ไม่ใช่ RAM block
-- เพราะ address ไม่ได้ถูก register ก่อนใช้งาน
```

## 6. รูปแบบไฟล์และเครื่องมือ

| หัวข้อ | ข้อกำหนด | เหตุผล |
|---|---|---|
| ชื่อไฟล์ | ตรงกับชื่อ entity, ตัวพิมพ์เล็ก, มี `.vhd` | ค้นหาและอ้างอิงง่าย |
| การเข้ารหัส | UTF-8 **ไม่มี BOM** | ไฟล์ที่มี BOM ทำให้ `vcom` และ `iverilog` รายงาน syntax error ทันทีบน Windows |
| เว้นวรรค | 2 ช่อง | อ่านง่ายกว่า tab ที่ขนาดไม่แน่นอน |
| ความยาวบรรทัด | ไม่เกิน 100 อักขระ | ลดการพับบรรทัดใน diff |
| trailing whitespace | ไม่มี | ทำให้ diff แสดงความต่างที่ไม่มีความหมาย |
| ขึ้นบรรทัด | ใช้ `\n` | ให้ผลตรวจสอบเหมือนกันทุกแพลตฟอร์ม |
| ชื่อไฟล์ภาษาไทย | ไม่ใช้ | Make, Docker และเครื่องมือบน WSL จัดการชื่อไทยไม่สม่ำเสมอ |

วิธีตรวจ BOM บน Windows

```powershell
Format-Hex .\src\alu_comb.vhd | Select-Object -First 1
```

ต้องเห็นไบต์แรกเป็น `2D 2D` (คอมเมนต์ `--`) หรือ `6C` (`l` ของ `library`)
ถ้าเห็น `EF BB BF` แปลว่ามี BOM ต้องบันทึกใหม่แบบ "UTF-8 without BOM"

## 7. ชื่อ signal ต้องตรงกันข้ามภาษา

เมื่อโปรเจกต์มีทั้ง VHDL และ Verilog ของโมดูลเดียวกัน **ชื่อ entity/module และ
ชื่อพอร์ตต้องตรงกันทุกตัว** เพื่อให้เทียบผลการจำลองข้ามภาษาได้

| VHDL | Verilog | หมายเหตุ |
|---|---|---|
| `entity alu_comb` | `module alu_comb` | ชื่อโมดูลต้องตรงกัน |
| `clk`, `rst_n`, `din`, `dout` | `clk`, `rst_n`, `din`, `dout` | ชื่อพอร์ตต้องตรงกัน |
| `DATA_WIDTH` | `DATA_WIDTH` | ชื่อ generic/parameter ควรตรงกัน |
| สัญญาณภายใน `cnt_i` | สัญญาณภายใน `cnt_i` | แนะนำให้ตรงกันด้วย เพื่อให้ waveform เทียบกันได้ |

ตัวอย่างจากโปรเจกต์นี้: `code/lab05/src/traffic_fsm.vhd` และ
`code/lab05/src/traffic_fsm.v` มีชื่อโมดูลและพอร์ตตรงกันทุกตัว

## 8. ไฟล์มาตรฐานเต็ม

ตัวอย่างนี้เป็นแม่แบบที่ใช้กับโมดูล combinational ทั่วไป

```vhdl
-- alu_comb: ALU แบบ combinational ที่กำหนดค่าเอาต์พุตครบทุก path
--
-- รองรับ ADD, SUB, AND, OR, XOR, SHL, SHR และ PASS
-- ผลลัพธ์ของการบวกและการลบขยายเป็น 1 บิตเพื่อจับ carry และ overflow
--
-- มาตรฐาน:      VHDL-2008 (คอมไพล์ผ่านมาตรฐาน VHDL-2002 ด้วย)
-- Synthesizable: ใช่ — สังเคราะห์เป็นตรรกะระดับ gate และ adder/subtractor
--
-- สิ่งที่โมดูลนี้สอน:
--   1. การกำหนดค่าเอาต์พุตให้ครบทุก path เพื่อไม่ให้เกิด latch
--   2. การใช้ numeric_std กับความยาวที่ขยายเพื่อจับ carry
--   3. การตรวจ overflow จากบิตเครื่องหมาย
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_comb is
  generic (
    DATA_WIDTH : positive := 8
  );
  port (
    opcode     : in  std_logic_vector(2 downto 0);
    a          : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    b          : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    result     : out std_logic_vector(DATA_WIDTH-1 downto 0);
    zero       : out std_logic;
    carry_out  : out std_logic;
    overflow   : out std_logic
  );
end entity alu_comb;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of alu_comb is
  constant OP_ADD : std_logic_vector(2 downto 0) := "000";
  constant OP_SUB : std_logic_vector(2 downto 0) := "001";
  -- ... ค่าคงที่ของ opcode อื่น ๆ

  signal result_i   : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal zero_i     : std_logic;
  signal carry_i    : std_logic;
  signal overflow_i : std_logic;
begin
  comb_p : process (opcode, a, b)
    -- ค่ากลางภายใน process ใช้ variable เสมอ
    -- signal ที่ประกาศนอก process จะ assign ได้ด้วย <= เท่านั้น
    variable result_v   : std_logic_vector(DATA_WIDTH-1 downto 0);
    variable zero_v     : std_logic;
    variable carry_v    : std_logic;
    variable overflow_v : std_logic;

    -- ขยายความยาวขึ้น 1 บิตเพื่อจับ carry และ overflow
    -- (resize ของ signed จะคงเครื่องหมายเดิมไว้)
    variable sum_v : signed(DATA_WIDTH downto 0);
    variable dif_v : signed(DATA_WIDTH downto 0);
  begin
    -- กำหนดค่าเริ่มต้นให้ครบทุก output ก่อน
    -- ถ้าไม่ทำแบบนี้ แล้ว case ที่ไม่ครอบคลุมทุก opcode
    -- จะทำให้เกิด latch ในวงจรจริง
    result_v   := (others => '0');
    zero_v     := '0';
    carry_v    := '0';
    overflow_v := '0';

    sum_v := resize(signed(a), DATA_WIDTH + 1) + resize(signed(b), DATA_WIDTH + 1);
    dif_v := resize(signed(a), DATA_WIDTH + 1) - resize(signed(b), DATA_WIDTH + 1);

    case opcode is
      when OP_ADD =>
        result_v   := std_logic_vector(sum_v(DATA_WIDTH-1 downto 0));
        carry_v    := sum_v(DATA_WIDTH);
        overflow_v := sum_v(DATA_WIDTH) xor sum_v(DATA_WIDTH-1);

      when OP_SUB =>
        result_v   := std_logic_vector(dif_v(DATA_WIDTH-1 downto 0));
        carry_v    := dif_v(DATA_WIDTH);
        overflow_v := (a(DATA_WIDTH-1) xor b(DATA_WIDTH-1))
                      and (a(DATA_WIDTH-1) xor dif_v(DATA_WIDTH-1));

      when "010" => result_v := a and b;
      when "011" => result_v := a or  b;
      when "100" => result_v := a xor b;
      when "101" => result_v := a(DATA_WIDTH-2 downto 0) & '0';
      when "110" => result_v := '0' & a(DATA_WIDTH-1 downto 1);

      -- when others ครอบคลุมทั้ง opcode ที่ไม่ได้ใช้และค่าที่เป็น X
      when others =>
        result_v   := (others => '0');
        zero_v     := '0';
        carry_v    := '0';
        overflow_v := '0';
    end case;

    -- zero คำนวณหลัง case เพราะขึ้นกับค่าของ result
    -- ใช้ if/else แทน conditional variable assignment (แบบ '1' when ... else ...)
    -- เพราะรูปแบบย่อเป็นฟีเจอร์ของ VHDL-2008 และคู่มือนี้ต้องคอมไพล์ผ่าน --std=02 ได้ด้วย
    if result_v = (DATA_WIDTH-1 downto 0 => '0') then
      zero_v := '1';
    else
      zero_v := '0';
    end if;

    -- assign ลง signal ทีเดียวท้าย process
    result_i   <= result_v;
    zero_i     <= zero_v;
    carry_i    <= carry_v;
    overflow_i <= overflow_v;
  end process comb_p;

  result    <= result_i;
  zero      <= zero_i;
  carry_out <= carry_i;
  overflow  <= overflow_i;
end architecture rtl;
```

ข้อสังเกตในไฟล์นี้

1. ใช้ `variable` เก็บค่ากลาง (`sum_v`, `dif_v`) แล้ว assign ลง signal ภายในทีเดียว
   ทำให้ process ไม่มีการอ่านค่า signal ที่เพิ่งถูก assign
2. กำหนดค่าเริ่มต้นให้ครบทุก output ก่อน `case` เป็นการป้องกัน latch ชั้นแรก
   และมี `when others` เป็นชั้นที่สอง
3. ใช้ `variable` ที่มีชื่อสื่อความหมายแทน `tmp`, `r`, `res`
4. เอาต์พุตภายใน (`result_i` ฯลฯ) ถูกส่งออกพอร์ตที่จุดเดียวท้าย architecture

---

## แบบฝึกหัดท้ายบท

1. เขียนโมดูล `mux4` ที่มีพอร์ต `sel : in std_logic_vector(1 downto 0)` และ
   `d0`, `d1`, `d2`, `d3`, `y` โดยใช้รูปแบบไฟล์ตามบทนี้ทุกข้อ
   แล้วตรวจว่า `y` เปลี่ยนทันทีเมื่อ `sel` เปลี่ยน (ไม่ต้องรอขอบนาฬิกา)
2. ตั้งชื่อใหม่ให้ทั้งไฟล์ `alu_comb.vhd` โดยเปลี่ยน `alu_comb` เป็น `comb_alu`
   พร้อมแก้ชื่อไฟล์ แล้วอธิบายว่าต้องแก้อะไรบ้างในโปรเจกต์ที่มีการอ้างอิงข้ามไฟล์
3. สร้างตัวอย่างที่ผิดกฎ 3 ข้อ (context clause ไม่ซ้ำ, ใช้ `:=` กับ signal,
   ประกาศ signal ภายในแล้ว assign ใน clocked process) แล้วรัน GHDL เพื่อดูข้อความ
   error จริงของแต่ละกรณี บันทึกข้อความไว้
4. ตรวจไฟล์ `.vhd` ทั้งโปรเจกต์ว่ามี BOM หรือไม่ และแก้ไฟล์ที่มี
5. เขียน "หน้ากฎของทีม" 3 ข้อที่เป็นของคุณเอง พร้อมเหตุผลที่เลือกข้อนั้น

## คำถามท้ายบท

1. ทำไมการประกาศ context clause ซ้ำก่อนทุก design unit จึงเป็นแนวปฏิบัติที่ถูกต้อง
   แม้จะดูซ้ำซาก
2. signal ที่ประกาศนอก process แล้วถูก assign ใน clocked process กลายเป็น latch ได้อย่างไร
   และเครื่องมือสังเคราะห์จะเตือนเมื่อใด
3. ข้อความภาษาไทยใน `report "..."` ทำให้เกิด error อย่างไร และทางแก้ที่ใช้ได้คืออะไร
4. การใช้ชื่อ signal ภายในต่อท้าย `_i` ช่วยอะไรในการรีวิวโค้ด
5. ทำไมชื่อ entity และชื่อพอร์ตต้องตรงกันระหว่างเวอร์ชัน VHDL และ Verilog

---

**อ่านต่อ:** [บทที่ 04 — ตรรกะ combinational](04-combinational-logic.md)

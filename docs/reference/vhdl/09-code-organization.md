# บทที่ 09: โครงสร้างโค้ดของโปรเจกต์

> บทนี้อธิบายวิธีจัดโครงสร้างโค้ด VHDL ที่ใหญ่กว่าไฟล์เดียว
> ให้แต่ละทีมแย่งงานกันได้โดยไม่ชนกัน และให้ทดสอบแยกส่วนได้

**เครื่องมือที่เกี่ยวข้อง:** GHDL 1.0.0
**ตัวอย่างอ้างอิง:** `ex08_pkg_rom/`, `ex10_uart_tx/`

---

## สารบัญบท

- [1. โครงสร้างไดเรกทอรีของโปรเจกต์](#1-โครงสร้างไดเรกทอรีของโปรเจกต์)
- [2. package](#2-package)
- [3. function และ procedure](#3-function-และ-procedure)
- [4. generic](#4-generic)
- [5. generate](#5-generate)
- [6. การสร้าง hierarchy](#6-การสร้าง-hierarchy)
- [7. ไฟล์ที่ใช้ร่วมกันและการคอมไพล์](#7-ไฟล์ที่ใช้ร่วมกันและการคอมไพล์)
- [8. ข้อควรระวังด้านชื่อชนิดข้อมูล](#8-ข้อควรระวังด้านชื่อชนิดข้อมูล)

---

## 1. โครงสร้างไดเรกทอรีของโปรเจกต์

```text
project/
├── rtl/                       # โค้ดที่สังเคราะห์
│   ├── pkg/                   # package ที่ใช้ร่วมกัน
│   │   ├── dsp_types_pkg.vhd
│   │   └── uart_pkg.vhd
│   ├── core/                  # โมดูลหลัก
│   │   ├── alu_comb.vhd
│   │   └── fifo_sync.vhd
│   └── io/                    # โมดูลต่อกับขา
│       └── uart_tx.vhd
├── tb/                        # testbench
│   ├── tb_alu_comb.vhd
│   └── vectors/               # ไฟล์ stimulus
└── constraints/               # SDC และข้อกำหนดอื่น
```

กฎที่ใช้ในโปรเจกต์นี้

- **RTL อยู่ใน `rtl/` เท่านั้น** แยกจาก testbench อย่างชัดเจน
- **package อยู่ใน `rtl/pkg/`** และมีชื่อลงท้าย `_pkg`
- **หนึ่ง entity ต่อหนึ่งไฟล์** ยกเว้น entity ที่เป็นส่วนหนึ่งของกันอย่างชัดเจน
- **หนึ่ง testbench ต่อหนึ่ง DUT** ชื่อไฟล์ `tb_<ชื่อ entity>.vhd`

## 2. package

### 2.1 package คืออะไร

package เป็นกลุ่มของ design unit ที่เก็บ type, subtype, constant, function, procedure
และ component declaration ไว้ในที่เดียว เพื่อให้หลายโมดูลใช้ร่วมกันได้

ประโยชน์

- ประกาศชนิดข้อมูลและฟังก์ชันที่ใช้ร่วมกันไว้ครั้งเดียว
- เปลี่ยนแก้ไขความกว้างบิตหรือค่าคงที่ที่จุดเดียว
- แยก "ความรู้เรื่องโดเมน" (เช่น รูปแบบคำสั่งของโปรโตคอล) ออกจากโครงสร้างวงจร

### 2.2 โครงสร้างของ package

```vhdl
package dsp_types_pkg is

  -- type และ subtype
  type opcode_t is (op_add, op_sub, op_and, op_or, op_xor, op_pass);
  subtype slv8_t  is std_logic_vector(7 downto 0);
  subtype u4_t    is unsigned(3 downto 0);

  -- record
  type result_t is record
    value    : slv8_t;
    zero     : std_logic;
    carry    : std_logic;
    overflow : std_logic;
  end record;

  -- constant
  constant OP_WIDTH : positive := 3;

  -- function
  function opcode_from_slv (v : std_logic_vector(2 downto 0)) return opcode_t;

  -- procedure
  procedure alu_eval (op : in opcode_t; a : in slv8_t; b : in slv8_t; res : out result_t);

end package dsp_types_pkg;
```

และส่วนที่เป็นการทำงาน

```vhdl
package body dsp_types_pkg is

  function opcode_from_slv (v : std_logic_vector(2 downto 0)) return opcode_t is
  begin
    case v is
      when "000" => return op_add;
      when "001" => return op_sub;
      when "010" => return op_and;
      when "011" => return op_or;
      when "100" => return op_xor;
      when "101" => return op_pass;
      -- ค่าที่ไม่รู้จักหรือเป็น X ต้องมีค่าที่ปลอดภัยเสมอ
      when others => return op_pass;
    end case;
  end function opcode_from_slv;

end package body dsp_types_pkg;
```

### 2.3 การใช้งาน package

```vhdl
architecture rtl of alu_comb is
  use work.dsp_types_pkg.all;      -- ใช้ใน architecture
begin
  ...
end architecture rtl;
```

หรือใช้แบบเจาะจงรายชื่อเพื่ออ่านง่ายขึ้น

```vhdl
architecture rtl of alu_comb is
  use work.dsp_types_pkg.all;
begin
  ...
end architecture rtl;
```

### 2.4 เมื่อไหร่ควรแยกเป็น package

| สถานการณ์ | ควรแยกเป็น package ไหม |
|---|---|
| type ที่ใช้มากกว่าหนึ่งโมดูล | ใช่ |
| ฟังก์ชันที่เขียนซ้ำในหลายไฟล์ | ใช่ |
| constant ของโปรโตคอล (เช่น ความยาวเฟรม UART) | ใช่ |
| ตัวแปรภายในของโมดูลเดียว | ไม่ต้อง |
| type ที่ใช้แค่ในไฟล์เดียว | ไม่ต้อง — ประกาศใน architecture |

> **ข้อควรระวัง**: package ที่ประกาศ `type` ของ FSM จะทำให้ทุกโมดูลที่ใช้ package
> ต้องแก้เมื่อมีการเพิ่มสถานะ ซึ่งอาจเป็นสิ่งที่ต้องการ (บังคับให้ทุกคนแก้ตาม)
> แต่ก็ทำให้ dependency ระหว่างโมดูลแน่นเกินไป ให้ใช้เฉพาะกรณีที่จำเป็น

## 3. function และ procedure

### 3.1 เปรียบเทียบ

| หัวข้อ | `function` | `procedure` |
|---|---|---|
| คืนค่า | ได้ (หนึ่งค่า หรือ record) | ไม่ได้ (ต้องใช้ `out`/`inout`) |
| โหมดพารามิเตอร์ | ทั้งหมดเป็น `in` | รองรับ `in`, `out`, `inout` |
| เรียกใน expression | ได้ | ไม่ได้ (ต้องเป็น statement) |
| ใช้ใน combinational logic | ได้ (ถ้าเป็น pure function) | ได้ถ้าไม่มี side effect |

### 3.2 pure function กับ impure function

```vhdl
-- pure function: ไม่มี side effect ใช้ใน RTL ได้
function all_zero (v : std_logic_vector) return boolean;

-- impure function: มี side effect (อ่าน signal) ใช้ใน RTL ไม่ได้
impure function read_status return std_logic is
begin
  return status_i;      -- อ่าน signal ภายใน
end function;
```

**กฎ: ใน RTL ที่สังเคราะห์ ใช้ pure function เท่านั้น**
ฟังก์ชันที่อ่าน signal จะทำให้ผลการจำลองไม่ตรงกับผลการสังเคราะห์

### 3.3 การส่งผ่าน procedure

```vhdl
procedure alu_eval (
  op   : in  opcode_t;
  a    : in  slv8_t;
  b    : in  slv8_t;
  res  : out result_t          -- โมดูลผู้เรียกส่งค่าเข้ามา
);
```

กฎการใช้ `out` และ `inout` ใน procedure

| โหมด | ค่าเริ่มต้นที่ผู้เรียกเห็น | ต้องกำหนดค่าใน procedure ไหม |
|---|---|---|
| `in` | ค่าที่ผู้เรียกส่งเข้ามา | ไม่ได้ |
| `out` | ค่าเดิม (ถ้าเป็น signal จะอ่านได้) | **ต้อง** กำหนดค่าให้ครบทุก path |
| `inout` | ค่าที่ผู้เรียกส่งเข้ามา | ต้องอ่านก่อนใช้ และกำหนดค่ากลับ |

> ข้อผิดพลาดที่พบบ่อย: procedure ที่มี `out` แต่ไม่กำหนดค่าในทุก path
> จะทำให้ค่าที่ส่งกลับเป็นค่าที่ไม่นิยาม

### 3.4 การอ้างอิง package จาก testbench

testbench ที่ต้องการ golden model จาก package ของโปรเจกต์
ควรเรียกใช้ package ที่อยู่ใน `rtl/pkg/` แต่ต้องระวังว่า
**golden model ต้องไม่ใช้ฟังก์ชันของ DUT**
มิฉะนั้นการเทียบผลจะกลายเป็นการเทียบผลของตัวเองกับตัวเอง

หลักการที่ใช้ในคอร์สนี้: แยก golden model ที่อยู่ใน testbench
ออกจาก RTL ที่อยู่ใน `src/` ให้ชัดเจน
(ดูตัวอย่าง `code/lab03/src/alu_ops_pkg.vhd` ที่มีคอมเมนต์อธิบายเรื่องนี้)

## 4. generic

### 4.1 การใช้ generic

```vhdl
entity fifo_sync is
  generic (
    DATA_WIDTH : positive := 8;
    ADDR_WIDTH : positive := 3
  );
  port (
    wr_data : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    ...
  );
end entity fifo_sync;
```

### 4.2 การกำหนดค่า generic ตอนสร้าง instance

```vhdl
u_fifo : entity work.fifo_sync
  generic map (
    DATA_WIDTH => 16,
    ADDR_WIDTH => 4
  )
  port map (
    wr_data => wr_data_i,
    ...
  );
```

### 4.3 generic ที่ใช้บ่อยในโปรเจกต์นี้

| generic | ความหมาย | ตัวอย่างค่า |
|---|---|---|
| `DATA_WIDTH` | ความกว้างข้อมูล (บิต) | 8, 16, 32 |
| `ADDR_WIDTH` | ความกว้างของ address (บิต) | 3 → ความลึก 8 |
| `DEPTH` | ความลึกโดยตรง (แทน ADDR_WIDTH) | 16 |
| `WIDTH` | ความกว้างทั่วไป | 4 |
| `STAGES` | จำนวนชั้นของ pipeline | 3, 5 |
| `CLKS_PER_BIT` | จำนวนรอบนาฬิกาต่อหนึ่งบิต | 4, 87 |
| `INIT_VALUE` | ค่าเริ่มต้นของ register | ขึ้นกับการใช้งาน |

### 4.4 generic กับพารามิเตอร์แบบ "ขนาดคงที่"

ข้อควรระวัง: การใช้ generic มาก ๆ ทำให้ต้องสังเคราะห์หลายค่า
เพื่อครอบคลุมกรณีที่เป็นไปได้ ซึ่งใช้เวลาและพื้นที่มาก

แนวทางที่ใช้ในโปรเจกต์นี้: ใช้ generic เฉพาะที่จำเป็นต่อการทำงาน
และกำหนดค่าเริ่มต้นไว้ให้เป็นค่าที่ใช้จริงในผลิตภัณฑ์

## 5. generate

`generate` สร้างโครงสร้างซ้ำโดยไม่ต้องเขียนโค้ดซ้ำ

### 5.1 for-generate

```vhdl
architecture rtl of bus_replicate is
  signal data_bus : std_logic_vector(7 downto 0);
begin
  g_bits : for i in 0 to 7 generate
    buf_i : entity work.tristate_buf
      port map (
        din  => din_i(i),
        dout => data_bus(i),
        oe   => oe_i
      );
  end generate g_bits;
end architecture rtl;
```

### 5.2 if-generate

ใช้เงื่อนไขที่เป็น static (ค่าคงที่ที่ทราบตอนคอมไพล์) เท่านั้น

```vhdl
  g_sync : if (GENERIC_SYNC = '1') generate
    sync_p : entity work.two_flop_sync
      port map (
        clk => clk,
        rst_n => rst_n,
        async_in => async_in,
        sync_out => sync_out
      );
  else generate
    sync_out <= async_in;      -- ไม่ซิงก์ (ไม่ควรใช้ในงานจริง)
  end generate g_sync;
```

> **ข้อจำกัด**: เงื่อนไขใน `if-generate` ต้องเป็น static
> ถ้าใช้สัญญาณจริงจะคอมไพล์ไม่ผ่าน เพราะเครื่องมือต้องตัดสินใจตอนสังเคราะห์

### 5.3 เมื่อไหร่ควรใช้ generate

| สถานการณ์ | ใช้ generate ไหม |
|---|---|
| ตัวบัฟเฟอร์ 32 ตัว | ใช่ |
| ซิงก์ 2-flop ให้ทุกสัญญาณข้าม domain | ใช่ |
| สร้าง pipeline จำนวนชั้นตาม generic | ใช่ |
| ตรรกะที่แตกแขนงแบบ dynamic | ไม่ (ใช้ case แทน) |

## 6. การสร้าง hierarchy

### 6.1 โครงสร้างแบบแบน (flat)

โมดูลทั้งหมดอยู่ระดับเดียว เรียกกันด้วย `entity work.xxx`

ข้อดี: อ่านง่าย ไม่มีปัญหาการอ้างอิงแบบลำดับชั้น
ข้อเสีย: เมื่อโปรเจกต์ใหญ่จะมี entity จำนวนมาก

### 6.2 โครงสร้างแบบ hierarchy

โมดูลระดับบนเรียกโมดูลระดับล่าง ซึ่งอยู่ใน package ของชุดนั้น

```vhdl
-- ใน package ของชุดโมดูล
package core_pkg is
  component alu_comb is
    generic (DATA_WIDTH : positive := 8);
    port (a : in std_logic_vector(7 downto 0); ...);
  end component;
end package core_pkg;
```

ข้อเสียของ hierarchy: การอ้างอิงชื่อยาวขึ้น และเครื่องมือบางตัวจำกัดความลึก

> **แนวทางของคู่มือนี้** — โปรเจกต์ขนาดกลางใช้ **โครงสร้างแบน**
> เรียก `entity work.xxx` โดยตรง ซึ่งตรวจจับชื่อพอร์ตผิดได้ทันที
> เพราะ direct entity instantiation ตรวจชื่อพอร์ต ต่างจาก component instantiation

## 7. ไฟล์ที่ใช้ร่วมกันและการคอมไพล์

### 7.1 ลำดับการคอมไพล์

```text
1. rtl/pkg/*.vhd          (package declaration และ package body)
2. rtl/core/*.vhd         (entity + architecture)
3. rtl/io/*.vhd
4. tb/*.vhd               (testbench)
```

### 7.2 คำสั่งที่ใช้ในโปรเจกต์นี้

```bash
ghdl -a --std=08 --workdir=work rtl/pkg/*.vhd
ghdl -a --std=08 --workdir=work rtl/core/*.vhd
ghdl -a --std=08 --workdir=work tb/*.vhd
ghdl -e --std=08 --workdir=work tb_alu_comb
ghdl -r --std=08 --workdir=work tb_alu_comb
```

> **หมายเหตุเรื่อง glob**: ใน WSL2 บนไดรฟ์ `E:` (drvfs) การเรียงลำดับไฟล์
> จาก glob อาจไม่เรียงตาม dependency ที่ถูกต้อง
> ให้คอมไพล์ package แยกคำสั่งก่อนเสมอ (ดังตัวอย่างข้างต้น)
> หรือใช้ `find` แบบมีเงื่อนไข

### 7.3 การแยก library

ถ้าโปรเจกต์ใหญ่มาก ให้แยกเป็นหลาย library

```vhdl
library work;
library common;
use common.dsp_types_pkg.all;
```

วิธีนี้ช่วยแยกโค้ดของแต่ละทีมออกจากกัน แต่ต้องจัดการ `workdir` ให้ถูก

## 8. ข้อควรระวังด้านชื่อชนิดข้อมูล

### 8.1 ชื่อที่ชนกันระหว่าง package

ถ้ามี package สองชุดที่ต่างกันประกาศชนิดชื่อเดียวกัน และใช้ `use ... .all` ทั้งคู่
จะเกิดข้อผิดพลาด "ambiguous" วิธีแก้คือเรียกใช้แบบเจาะจงชื่อ

```vhdl
use work.dsp_types_pkg.all;
use work.uart_types_pkg.all;

-- เมื่อมีชื่อซ้ำ ให้ระบุชุดที่ต้องการ
variable x : work.dsp_types_pkg.slv8_t;
```

### 8.2 ชื่อที่ต้องหลีกเลี่ยง

| ชื่อ | เหตุผล |
|---|---|
| `data`, `bus`, `temp` | ชื่อกว้าง ๆ ทำให้อ่านโค้ดไม่รู้ว่าเป็นข้อมูลอะไร |
| `tmp`, `tmp1`, `tmp2` | สื่อความหมายไม่ได้ ให้ใช้ชื่อที่บอกบทบาท |
| `x`, `y`, `z` | ยกเว้นในสูตรทางคณิตศาสตร์ |
| `n`, `i`, `j` ในระดับโมดูล | เป็น loop index ที่อาจชนกับสัญญาณ |

---

## แบบฝึกหัดท้ายบท

1. สร้าง package `counter_pkg` ที่ประกาศ `subtype count_t` และ function
   `is_max(v : count_t) return boolean` แล้วใช้ในตัวนับของ Lab 02
2. แยก `alu_ops_pkg` ที่มีอยู่ใน `code/lab03/src/` ให้เป็น package ที่ใช้ร่วมกัน
   แล้วคอมไพล์ทั้งโปรเจกต์อีกครั้งเพื่อยืนยันว่าไม่มีผลกระทบ
3. เขียนโมดูล `replicate_bus` ที่ใช้ `for-generate` เพื่อสร้างตัวบัฟเฟอร์ 8 ตัว
   และเปรียบเทียบผลกับการเขียนซ้ำ 8 ครั้ง
4. เขียน procedure ที่มีพารามิเตอร์โหมด `in`, `out`, `inout` ครบทั้งสามแบบ
   แล้วทดสอบกับ golden model
5. ทดลองสร้างความขัดแย้งของชื่อชนิดข้อมูลระหว่างสอง package แล้วอธิบาย
   ข้อความ error และวิธีแก้

## คำถามท้ายบท

1. package ช่วยแก้ปัญหาอะไรในโปรเจกต์ที่มีหลายคนทำ และมีข้อเสียอะไร
2. pure function ต่างจาก impure function อย่างไร และเหตุใด RTL จึงต้องใช้
   pure function เท่านั้น
3. ใน procedure พารามิเตอร์โหมด `out` ต้องมีค่าเริ่มต้นอย่างไร และเหตุใด
5. `if-generate` สามารถใช้เงื่อนไขที่เป็น signal ได้หรือไม่ เพราะอะไร
6. direct entity instantiation ช่วยจับชนิดข้อมูลผิดได้อย่างไร
   ที่ component instantiation ทำไม่ได้

---

**อ่านต่อ:** [บทที่ 10 — ขอบเขตที่สังเคราะห์ได้](10-synthesis-subset.md)

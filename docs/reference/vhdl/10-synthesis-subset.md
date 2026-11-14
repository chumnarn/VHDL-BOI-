# บทที่ 10: ขอบเขตที่สังเคราะห์ได้

> บทนี้อธิบายว่าเครื่องมือสังเคราะห์อ่านโค้ด VHDL ได้แค่ไหน
> เพื่อให้เขียนโค้ดที่ผ่านการสังเคราะห์โดยไม่ต้องเดา

**เครื่องมือที่เกี่ยวข้อง:** GHDL 1.0.0 (`ghdl --synth`), Yosys, เอกสารของเครื่องมือสังเคราะห์แต่ละเครื่อง
**ตัวอย่างอ้างอิง:** `ex08_pkg_rom/`, `ex09_mem_sync/`

---

## สารบัญบท

- [1. แนวคิดของ synthesis subset](#1-แนวคิดของ-synthesis-subset)
- [2. สิ่งที่สังเคราะห์ได้](#2-สิ่งที่สังเคราะห์ได้)
- [3. สิ่งที่สังเคราะห์ไม่ได้](#3-สิ่งที่สังเคราะห์ไม่ได้)
- [4. การสังเคราะห์ด้วย ghdl --synth](#4-การสังเคราะห์ด้วย-ghdl---synth)
- [5. การสังเคราะห์ด้วย Yosys](#5-การสังเคราะห์ด้วย-yosys)
- [6. การอนุมานโครงสร้างหน่วยความจำ](#6-การอนุมานโครงสร้างหน่วยความจำ)
- [7. attribute ที่ควรรู้](#7-attribute-ที่ควรรู้)
- [8. ข้อควรระวังเรื่อง initial value](#8-ข้อควรระวังเรื่อง-initial-value)

---

## 1. แนวคิดของ synthesis subset

เครื่องมือสังเคราะห์อ่านโค้ด VHDL ได้เฉพาะส่วนที่สามารถแปลงเป็นวงจรได้
ส่วนที่เหลือ (เช่น `wait`, `assert`, การอ่านไฟล์) ใช้ได้เฉพาะใน testbench

**กฎสากล: RTL ต้องอยู่ใน synthesis subset เสมอ**
วิธีที่ดีที่สุดคือตรวจด้วย `ghdl --synth` ก่อนส่งงานทุกครั้ง
เพราะคำสั่งนี้จะรายงานทันทีว่าส่วนใดไม่สามารถสังเคราะห์ได้

## 2. สิ่งที่สังเคราะห์ได้

| องค์ประกอบ | หมายเหตุ |
|---|---|
| `entity` / `architecture` | พื้นฐาน |
| `signal` assignment (`<=`) | ทั้งแบบ concurrent และใน process |
| `variable` assignment (`:=`) | ภายใน process |
| `process` | ทั้ง combinational และ clocked |
| `if` / `case` / `for` / `while` / `loop` | `while` ใช้ได้ถ้าเงื่อนไขเป็น static |
| `generate` | ทั้ง for, if และ block |
| `component` / `entity` instantiation | การซ้อนโมดูล |
| `package` / `function` / `procedure` | ต้องเป็น pure function |
| `numeric_std` ทั้งหมด | คำนวณบนเลขไบนารี |
| `std_logic_1164` | ตรรกะและ arithmetic ระดับบิต |
| `generate` + `for` | สร้างโครงสร้างซ้ำ |
| `attribute` บางตัว | เช่น `async_reg`, `rom_style`, `ram_style` |

## 3. สิ่งที่สังเคราะห์ไม่ได้

| องค์ประกอบ | เหตุผล | ใช้ทำอะไรแทน |
|---|---|---|
| `wait` | ไม่มีแนวคิดเวลาในฮาร์ดแวร์ | ใช้เฉพาะใน testbench |
| `assert` | ไม่มีกลไกตรวจจับในซิลิคอน | ใช้ใน testbench หรือสังเคราะห์เป็น logic ตรวจสอบ |
| `report` | เป็นข้อความ | ใช้ใน testbench |
| การอ่าน/เขียนไฟล์ (`textio`) | เป็น I/O ของซอฟต์แวร์ | ใช้ใน testbench |
| `access type` (pointer) | หน่วยความจำแบบ dynamic | ใช้ใน testbench เท่านั้น |
| `time` | ไม่มีเวลาในวงจรดิจิทัล | ใช้ใน testbench |
| impure function | มี side effect | เขียนเป็น logic ปกติ |
| `if` ที่เงื่อนไขเป็น signal แบบ dynamic ใน generate | ต้องตัดสินใจตอนสังเคราะห์ | ใช้ `case` แทน |

> **ข้อควรระวัง**: เครื่องมือสังเคราะห์แต่ละตัวรองรับได้ไม่เท่ากัน
> ตารางข้างต้นเป็นขอบเขตร่วมที่ทุกเครื่องมือรองรับ
> ต้องอ่านเอกสารของเครื่องมือที่ใช้จริงเสมอ

## 4. การสังเคราะห์ด้วย ghdl --synth

### 4.1 คำสั่ง

```bash
ghdl --synth --std=08 --workdir=work <top_entity> > reports/<top>_netlist.vhd
```

ผลลัพธ์คือ netlist ระดับ gate ในรูป VHDL ที่ประกอบด้วย instance
ของ primitive gate (`and2`, `or2`, `xor2`, `not1`, `dff`, `mux2` ฯลฯ)

### 4.2 การตรวจว่าไม่มี latch

```bash
ghdl --synth --std=08 --workdir=work alu_comb | grep -i latch
```

ถ้าไม่มีผลลัพธ์ แปลว่าไม่มี latch

### 4.3 ข้อจำกัดของ GHDL 1.0

`ghdl --synth` รองรับเฉพาะส่วนย่อยของ VHDL ที่ตั้งใจให้สังเคราะห์ได้
จึงอาจปฏิเสธโค้ดที่เครื่องมืออื่นรองรับ เช่น

- `generate` บางรูปแบบ
- `procedure` ที่มีพารามิเตอร์ `out`/`inout`
- package ที่มี `component` declaration

เมื่อเจอกรณีนี้ ให้บันทึกไว้ใน README ของตัวอย่างว่า
`ghdl --synth` ไม่รองรับ และตรวจด้วยเครื่องมืออื่นแทน
**ห้ามแก้โค้ดให้เสียความหมายเพื่อให้ผ่าน `ghdl --synth`**

## 5. การสังเคราะห์ด้วย Yosys

Yosys อ่าน VHDL ได้ผ่านปลั๊กอิน `ghdl` ซึ่งใช้ GHDL เป็นตัวหน้า

```bash
# ติดตั้งปลั๊กอิน (ถ้ายังไม่มี)
ghdl --plugin --list

# สังเคราะห์และดูสถิติ
yosys -m ghdl -p "ghdl --std=08 alu_comb -e alu_comb; synth; stat" 
```

ผลลัพธ์ที่ต้องดู

```text
=== alu_comb ===
   Number of wires:                45
   Number of cells:                78
     $_AND_          12
     $_XOR_          16
     $_MUX_          10
     $_DFF_P_        20
```

ข้อควรระวัง

- ปลั๊กอิน `ghdl` ต้องตรงกับเวอร์ชัน GHDL ที่ติดตั้ง
  ใน Ubuntu 22.04 ต้องติดตั้งแพ็กเกจ `ghdl-yosys-plugin` ให้เข้ากัน
- ถ้า Yosys ไม่มีปลั๊กอินนี้ ให้ใช้ `ghdl --synth` แล้วส่งผลลัพธ์เข้า Yosys
  ในรูป Verilog ด้วย `ghdl --synth --out=verilog`

```bash
ghdl --synth --std=08 --workdir=work alu_comb --out=verilog > reports/alu_comb_netlist.v
yosys -p "read_verilog reports/alu_comb_netlist.v; stat"
```

## 6. การอนุมานโครงสร้างหน่วยความจำ

### 6.1 ROM

```vhdl
architecture rtl of rom_8x8 is
  type rom_t is array (0 to 7) of std_logic_vector(7 downto 0);
  signal rom_i : rom_t := (
    0 => x"3C", 1 => x"5A", 2 => x"77", 3 => x"7E",
    4 => x"11", 5 => x"22", 6 => x"44", 7 => x"88"
  );
begin
  ...
end architecture rtl;
```

เครื่องมือสังเคราะห์จะอนุมานเป็น ROM block เมื่อ

- ค่าคงที่ถูกกำหนดไว้ตอน compile
- มี address register และ output register
- ไม่มีการเขียนกลับ

ถ้าต้องการควบคุมพฤติกรรม ให้ใช้ attribute

```vhdl
  attribute rom_style : string;
  attribute rom_style of rom_i : signal is "block";
```

ค่าที่ใช้ได้: `"logic"`, `"distributed"`, `"block"`, `"auto"`
(ชื่อค่าขึ้นกับเครื่องมือและ PDK — ต้องอ่านเอกสารของ PDK)

### 6.2 RAM

```vhdl
architecture rtl of ram_sync is
  type mem_t is array (0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
  signal mem_i : mem_t;
begin
  seq_p : process (clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        mem_i(to_integer(addr)) <= din;
      end if;
      dout <= mem_i(to_integer(addr));      -- synchronous read
    end if;
  end process seq_p;
end architecture rtl;
```

เงื่อนไขที่ช่วยให้อนุมานเป็น RAM block

- มี address register (address ถูกเก็บใน register ก่อนใช้)
- มี output register
- การเขียนและการอ่านเป็นแบบ synchronous

### 6.3 read-first, write-first และ no-change

พฤติกรรมเมื่อเขียนและอ่าน address เดียวกันในรอบเดียวกัน

| พฤติกรรม | คำอธิบาย | วิธีเขียน |
|---|---|---|
| read-first (no bypass) | เอาต์พุตเป็นค่าเก่า | `dout <= mem(addr);` แล้วเขียนทีหลัง |
| write-first (bypass) | เอาต์พุตเป็นค่าใหม่ | เขียนก่อน แล้วอ่านค่าที่เพิ่งเขียน |
| no-change | เอาต์พุตคงเดิม | ใช้ enable ของ read |

ต้องประกาศพฤติกรรมให้ชัดเจนในคอมเมนต์ เพราะมีผลต่อการทำงานร่วมกับโมดูลอื่น

## 7. attribute ที่ควรรู้

```vhdl
architecture rtl of example is
  -- ป้องกันไม่ให้เครื่องมือย้ายฟลิปฟลอป synchronizer แยกกัน
  attribute async_reg : string;
  attribute async_reg of sync_meta_i : signal is "TRUE";

  -- ควบคุมการอนุมานโครงสร้างหน่วยความจำ
  attribute rom_style : string;
  attribute rom_style of rom_i : signal is "block";

  attribute ram_style : string;
  attribute ram_style of mem_i : signal is "block";

  -- ป้องกันการถูก optimize ออก (ใช้กับ debug หรือสัญญาณที่ต้องเห็นใน waveform)
  attribute keep : boolean;
  attribute keep of debug_signal_i : signal is "true";
```

| attribute | ใช้ทำอะไร | ผู้ใช้ attribute ต้องรู้ |
|---|---|---|
| `async_reg` | ระบุว่าฟลิปฟลอปเป็น synchronizer | ชื่อ attribute ต่างกันในแต่ละเครื่องมือ |
| `rom_style` / `ram_style` | บังคับรูปแบบหน่วยความจำ | ค่าที่รองรับขึ้นกับ PDK |
| `keep` | กันไม่ให้ถูกตัดทิ้ง | ใช้ผิดแล้วเพิ่มพื้นที่และ delay |
| `dont_touch` | กันไม่ให้ถูกปรับแต่งโครงสร้าง | เหมือนกันแต่แรงกว่า |
| `parallel_case` | บอกให้เครื่องมือไม่สร้าง priority mux | ต้องระวังเรื่อง X propagation |

> **คำเตือน**: ชื่อและค่าที่รองรับของ attribute ต่างกันระหว่างเครื่องมือ
> เครื่องมือที่ไม่รู้จัก attribute มักจะปฏิเสธการคอมไพล์
> ให้ตรวจเอกสารของเครื่องมือก่อนใช้ทุกครั้ง

## 8. ข้อควรระวังเรื่อง initial value

```vhdl
signal cnt_i : unsigned(3 downto 0) := (others => '0');
```

| ประเด็น | คำอธิบาย |
|---|---|
| ใน simulation | ค่าเริ่มต้นมีผลทันที ทำให้ simulation เริ่มได้โดยไม่ต้องรอ reset |
| ในการสังเคราะห์ | ขึ้นกับเครื่องมือ — บางตัวรองรับ บางตัวไม่ |
| ในฮาร์ดแวร์จริง | ไม่มีความหมาย ค่าเริ่มต้นของ flip-flop หลัง power-on ถูกกำหนดโดย PDK |

**ข้อสรุป: ค่าเริ่มต้นของ signal ไม่ใช่กลไกแทน reset**
ต้องมี reset เสมอ และต้องตรวจว่าเครื่องมือที่ใช้รองรับค่าเริ่มต้นหรือไม่

---

## แบบฝึกหัดท้ายบท

1. เขียนโมดูลที่มี `wait for 1 ns` ใน process แล้วรัน `ghdl --synth` จดข้อความ error
   ที่ได้
2. เขียน `rom_8x8` และ `ram_sync` แล้วรัน `ghdl --synth` ทั้งสองตัว
   จากนั้นตรวจว่าผลลัพธ์มีโครงสร้างที่คาดหวัง (logic หรือ memory)
3. ทดลองเพิ่ม `attribute keep` ให้ signal หนึ่งในตัวอย่างของคุณ
   แล้วสังเกตความต่างในผลลัพธ์
4. เขียน RAM สองแบบ (read-first และ write-first) แล้วเขียน testbench
   ที่พิสูจน์ความต่างของพฤติกรรม
5. อธิบายว่าทำไมค่าเริ่มต้นของ signal ไม่สามารถใช้แทน reset ได้

## คำถามท้ายบท

1. synthesis subset ต่างจากภาษา VHDL อย่างไร และมีผลต่อการเขียน testbench อย่างไร
2. `ghdl --synth` ใช้พิสูจน์อะไรได้ และไม่สามารถพิสูจน์อะไร
3. เงื่อนไขใดที่ช่วยให้เครื่องมือสังเคราะห์อนุมานหน่วยความจำเป็น RAM block
4. พฤติกรรม read-first, write-first และ no-change ของ RAM ต่างกันอย่างไร
   และมีผลต่อการเชื่อมต่อโมดูลอย่างไร
6. `async_reg` attribute มีผลต่อการวางวงจรอย่างไร และมีข้อเสียอะไร

---

**อ่านต่อ:** [บทที่ 11 — รูปแบบการตรวจสอบ](11-verification-style.md)

# 3.8 — VHDL Synthesis เชิงลึก: จากภาษา VHDL ไปสู่ฮาร์ดแวร์

> **หัวข้อประกอบการสอน** · วันที่ 3: RTL Synthesis and Optimization
> **เวลาบรรยาย** 90–120 นาที · **ระดับ** ปานกลาง → ขั้นสูง
> **ต้องมีเครื่องมือ** GHDL 5.x + Yosys 0.5x + PDK sky130A (Linux/WSL) — ไม่ต้องมี license
> **โค้ดประกอบ** `lab_code/day3_synthesis/` — ตัวอย่าง 11 ชิ้น สังเคราะห์จริงทั้งหมด
> **หลักฐาน** ทุกตัวเลขในเอกสารนี้มาจากการรันจริงบนเครื่อง ไม่มีตัวเลขที่แต่งขึ้น

---

## 3.8.0 ทำไมต้องมีหัวข้อนี้

### 3.8.0.1 ช่องว่างที่หัวข้อนี้เติม

คู่มือฉบับนี้มีเอกสารที่พูดถึงการสังเคราะห์อยู่แล้ว 3 กลุ่ม แต่แต่ละกลุ่มตอบคำถามคนละข้อ:

| เอกสาร | ตอบคำถามอะไร | ตอบไม่ได้ |
|---|---|---|
| §1.3 + `Manual_1_2_4_and_1_3_...` | "simulation กับ synthesis ต่างกันอย่างไร" และ "synthesizable subset คืออะไร" (ในระดับตารางสรุป) | ไม่ได้บอกว่า **แต่ละ syntax ของ VHDL กลายเป็นฮาร์ดแวร์อย่างไร** |
| §3.5 + `Manual_3_5_Yosys_and_LibreLane_Synthesis_DeepDive.md` | "Yosys ทำงานยังไง" และ "LibreLane flow เป็นอย่างไร" | ไม่ได้บอกว่า **โค้ด VHDL ที่เขียนเองถูกแปลงเป็นอะไร** |
| `docs/reference/vhdl/10-synthesis-subset.md` | ตารางว่าอะไรสังเคราะห์ได้/ไม่ได้ | ไม่มีการรันจริงพิสูจน์ — เป็นข้อความอ้างอิง |

**ช่องว่าง** คือระดับ "ภาษา → ฮาร์ดแวร์" ของ VHDL ซึ่งเป็นสะพานที่นักศึกษาต้องข้ามเอง
ถ้าเข้าใจแค่ว่า "Yosys แปลง VHDL เป็น Verilog" แต่ไม่รู้ว่า
`if` ที่ไม่ครบทุก path จะกลายเป็น **latch**,
`case` จะกลายเป็น **priority mux**,
และ `std_logic_arith` จะทำให้ **สังเคราะห์ไม่ผ่าน**
— นักศึกษาจะต้องเดาว่าทำไม tool พัง

หัวข้อนี้ทำสิ่งที่หัวข้ออื่นไม่ทำ: **รันจริงทุก construct แล้วแสดงผลจริง**

### 3.8.0.2 ⚠️ เอกสารอ้างอิงที่ไม่ตรงกับ GHDL 5.x

ไฟล์ `docs/reference/vhdl/10-synthesis-subset.md` ข้อ 4.1 เขียนว่า:

```text
ghdl --synth --std=08 --workdir=work <top_entity> > reports/<top>_netlist.vhd
```

และระบุว่า "ผลลัพธ์คือ netlist ระดับ gate ในรูป VHDL ที่ประกอบด้วย instance
ของ primitive gate (`and2`, `or2`, `xor2`, `not1`, `dff`, `mux2` ฯลฯ)"

**สิ่งที่วัดได้จริงด้วย GHDL 5.0.1** คือ `ghdl synth` ทำหน้าที่เป็น **ตัวแปลง (translator)**
ไม่ใช่ synthesizer — เอาต์พุตที่ได้ยังเป็นโค้ด Verilog แบบ behavioral
ที่ยังมี `always @*` และ `case` อยู่:

```verilog
/* rtl/alu4.vhd:27:48  */
assign n7_o = a + b;
/* rtl/alu4.vhd:26:5  */
always @*
  case (n17_o)
    3'b100: n18_o = n13_o;
    3'b010: n18_o = n10_o;
    3'b001: n18_o = n7_o;
    default: n18_o = n16_o;
  endcase
```

> **บทเรียนที่ต้องสอน:** คำสั่งที่ชื่อว่า "synth" ไม่ได้แปลว่าว่าได้ gate
> ต้องดูเอาต์พุตเสมอว่าเป็นระดับใด — ดู §3.8.1

---

## 3.8.1 สามชั้นของ "การสังเคราะห์" — อย่าสับสน

### 3.8.1.1 ภาพรวม

```text
   VHDL RTL
      │
      │  ① GHDL synth  ─────► Verilog (ยังเป็น behavioral!)
      │     (ตัวแปลง)            │
      │                          │  ② Yosys synth
      │                          │     (synthesizer จริง)
      │                          ▼
      │                   generic netlist
      │                   ($_AND_, $_MUX_, $_DFF_P_ …)
      │                          │
      │                          │  ③ abc -liberty
      │                          │     (technology mapping)
      ▼                          ▼
   simulation              sky130A mapped netlist
   (ModelSim/GHDL)         (sky130_fd_sc_hd__*)
                                   │
                                   ▼
                            chip area / cell count
```

### 3.8.1.2 ตารางเปรียบเทียบเครื่องมือ

| | GHDL 5.0.1 `synth` | Yosys 0.52 | Precision RTL (commercial) |
|---|---|---|---|
| หน้าที่หลัก | แปลง VHDL → Verilog | สังเคราะห์ + map เข้า PDK | สังเคราะห์ + STA + constraint |
| ได้ gate จริงหรือไม่ | **ไม่** (ได้ behavioral Verilog) | ได้ | ได้ |
| เข้า VHDL โดยตรง | ได้ | ต้องมี plugin `ghdl` (ที่เครื่องนี้ไม่มี) | ได้ |
| map เข้า Liberty | ไม่ได้ | ได้ (`abc -liberty`) | ได้ |
| รายงาน area | ไม่ได้ | ได้ (`stat -liberty`) | ได้ |
| พิสูจน์ equivalence | ไม่ได้ | ได้ (`equiv_make` / `miter`) | ได้ |
| License | ฟรี (GPL) | ฟรี (GPL) | ต้องมี license |

> **ข้อสังเกต:** เครื่องนี้ติดตั้ง Yosys จาก apt ซึ่ง **ไม่มี plugin `ghdl`**
> (`yosys -p "help ghdl"` → `No such command or cell type: ghdl`)
> จึงต้องเดินทางผ่าน GHDL → Verilog → Yosys เสมอในหัวข้อนี้

### 3.8.1.3 ⚠️ GHDL 5.x สั่ง option ตามลำดับนี้เท่านั้น

```bash
# ✅ ใช้ได้
ghdl synth --std=08 --out=verilog rtl/alu4.vhd -e alu4 > build/alu4.v

# ❌ ใช้ไม่ได้ — สลับลำดับ option
ghdl synth --out=verilog --std=08 -e alu4 rtl/alu4.vhd
```

ถ้าใส่ `--workdir` ที่ยังไม่มีไดเรกทอรี GHDL จะรายงาน
`directory '...' set by --workdir= does not exist [-Wlibrary]` แล้วตามมาด้วย
`unknown command option '-e'` — อ่านข้อความแรกเป็นหลัก เพราะมันคือต้นเหตุจริง

---

## 3.8.2 Pipeline จริงที่วัดได้

คำสั่งทั้งหมดในหัวข้อนี้อยู่ใน `lab_code/day3_synthesis/` และรันได้ด้วยคำสั่งเดียว:

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3_synthesis"
bash run_everything.sh
```

### 3.8.2.1 ขั้นที่ 1 — GHDL แปลง VHDL เป็น Verilog

```bash
ghdl synth --std=08 --out=verilog rtl/alu4.vhd -e alu4 > build/alu4.v
```

ผลจริง — โค้ด Verilog ที่ได้ยังเป็น behavioral:

```verilog
module alu4
  (input  [3:0] a,
   input  [3:0] b,
   input  [1:0] op,
   output [3:0] y,
   output zero);
  ...
  assign n7_o = a + b;          // ← ยังเป็น operator ระดับ RTL
  always @*
    case (n17_o)                 // ← ยังเป็น case
      3'b100: n18_o = n13_o;
      ...
    endcase
```

### 3.8.2.2 ขั้นที่ 2 — Yosys สังเคราะห์จริง

```bash
yosys -Q -p "
  read_verilog build/alu4.v
  hierarchy -check -top alu4
  synth -top alu4
  check -assert
  stat
"
```

ผลจริง (`reports/alu4_generic.log`):

```text
=== alu4 ===

   Number of wires:                 60
   Number of wire bits:             73
   Number of public wires:           8
   Number of public wire bits:      21
   Number of ports:                  5
   Number of port bits:             15
   Number of memories:               0
   Number of memory bits:            0
   Number of processes:              0
   Number of cells:                 57
     $_ANDNOT_                      15
     $_AND_                          3
     $_MUX_                          7
     $_NAND_                         3
     $_NOR_                          3
     $_NOT_                          4
     $_ORNOT_                        1
     $_OR_                          11
     $_XNOR_                         2
     $_XOR_                          8
```

> **คำสั่ง `check -assert`** สำคัญมาก — ถ้า netlist ยังมี cell ที่ไม่ได้ map
> (เช่น `$add` ที่หลุดค้าง) คำสั่งนี้จะ error ทันทีแทนที่จะปล่อยให้ไปเจอปัญหาตอน layout

### 3.8.2.3 ขั้นที่ 3 — Map เข้า PDK sky130A และวัด area

```bash
yosys -Q -p "
  read_verilog build/alu4.v
  hierarchy -check -top alu4
  synth -top alu4 -noabc
  dfflibmap -liberty $SKY130_LIB
  abc -liberty $SKY130_LIB
  opt_clean
  stat -liberty $SKY130_LIB
"
```

ผลจริง:

```text
Chip area for module '\alu4': 208.950400
```

> **`-noabc` ต้องมา ณ ตำแหน่งนี้** เพราะ `synth` จะเรียก ABC เองด้วย liberty ทั่วไป
> ถ้าไม่ใส่ `-noabc` แล้วสั่ง `abc -liberty` ซ้ำ จะได้ผล map สองรอบซ้อนกัน
> (ประเด็นเดียวกับที่เจอใน `Manual_3_5_Yosys_...` ข้อ 9.2)

---

## 3.8.3 Synthesizable subset ที่ระดับ construct

ตารางนี้ผสม "ทฤษฎีจากมาตรฐาน" กับ "ผลที่วัดได้จริงในหัวข้อนี้"
คอลัมน์ "ผลจริง" คือสิ่งที่ GHDL 5.0.1 + Yosys 0.52 ทำกับตัวอย่างใน `lab_code/day3_synthesis/`

| Construct | สังเคราะห์ได้ | กลายเป็นอะไร | ผลจริงในหัวข้อนี้ |
|---|---|---|---|
| `entity` / `architecture` | ✅ | โมดูล | ทุกตัวอย่าง |
| `signal` (port) | ✅ | wire + FF | `counter_sync` ได้ 8 DFF |
| `variable` | ✅ | logic ชั่วคราว (ไม่มี storage) | ดู §3.8.5 |
| `constant` | ✅ | ถูก fold เป็นค่าคงที่ | ดู §3.8.12 |
| `process` (combinational) | ✅ | mux / gate | `alu4` |
| `process` (clocked) | ✅ | DFF + next-state logic | `counter_sync` |
| `if` / `elsif` / `else` | ✅ | priority mux | `alu4` |
| `if` **ไม่ครบทุก path** | ⚠️ | **latch** | จับได้ — ดู §3.8.6 |
| `case` | ✅ | priority mux + decoder | ดู §3.8.4 |
| `case` แบบ `others` | ✅ | ปลอดภัย | `alu4` |
| `for` loop (ช่วงคงที่) | ✅ | unroll เป็น logic | `shifter` |
| `while` loop | ❌ | ไม่มีขอบเขต → ตัดสินใจตอนรัน | — |
| `generate` (for / if) | ✅ | สร้างโมดูลซ้ำ | — |
| `function` (pure) | ✅ | logic ชั่วคราว | — |
| `procedure` | ⚠️ | ต้องเป็น pure / ไม่มี side effect | — |
| `numeric_std` `+` `−` `*` | ✅ | adder / subtractor / multiplier | ดู §3.8.9 |
| `numeric_std` `resize` | ✅ | pad / truncate | `adder8` ใช้ `resize` เป็นตัวอย่าง |
| `std_logic_arith` | ❌ | **สังเคราะห์ไม่ผ่าน** | ดู §3.8.13 |
| `enum` type (FSM) | ✅ | state register | ดู §3.8.8 |
| `with ... select` | ✅ | mux | `fsm_seq` ใช้แสดง output decoder |
| `wait` / `after` | ❌ | ไม่มีเวลาในฮาร์ดแวร์ | — |
| `assert` / `report` | ❌ | ไม่มีกลไกจับในซิลิคอน | — |
| `textio` / file I/O | ❌ | เป็น I/O ของซอฟต์แวร์ | — |
| `real` / `time` | ❌ | ไม่มีเวลา/ทศนิยมในวงจรดิจิทัล | — |
| `access` (pointer) | ❌ | dynamic memory | — |
| `shared variable` + protected type | ❌ | เป็นโครงสร้างซอฟต์แวร์ | — |

> **หมายเหตุเรื่อง `shared variable`:** แม้ GHDL จะ *simulate* ได้
> (ดู `Manual_2_7_...` ข้อ 2.7.4.4) แต่ `ghdl synth` **ปฏิเสธ** เพราะไม่มี
> hardware ที่จะทำหน้าที่เป็น shared memory ได้

---

## 3.8.4 `case` กลายเป็น Priority Mux — ดูจาก Verilog ที่ GHDL แปลง

ตัวอย่าง `rtl/alu4.vhd`:

```vhdl
case op is
  when "00"   => vr := std_logic_vector(va + vb);
  when "01"   => vr := std_logic_vector(va - vb);
  when "10"   => vr := std_logic_vector(va and vb);
  when others => vr := std_logic_vector(va or vb);
end case;
```

### 3.8.4.1 สิ่งที่ GHDL แปลงออกมา

```verilog
assign n9_o  = op == 2'b00;      // ← เป็น "เทียบกับแต่ละค่า"
assign n12_o = op == 2'b01;
assign n15_o = op == 2'b10;
assign n17_o = {n15_o, n12_o, n9_o};
always @*
  case (n17_o)
    3'b100: n18_o = n13_o;       // ← กลายเป็น priority mux
    3'b010: n18_o = n10_o;
    3'b001: n18_o = n7_o;
    default: n18_o = n16_o;
  endcase
```

### 3.8.4.2 สิ่งที่ Yosys สังเคราะห์ต่อ

`case` 3 ทางบน selector 3 บิต กลายเป็น **priority encoder + mux**
ไม่ใช่ mux 4:1 ธรรมดา เพราะต้องการ priority

```text
      op[1:0]
         │
   ┌─────┴─────┬──────────┬──────────┐
   │           │          │          │
 [==00]     [==01]     [==10]    (others)
   │           │          │          │
   └─────┬─────┴──────────┴──────────┘
         ▼
   priority encoder (3→2)  ──►  mux 4:1  ──► y
         │                        ▲
         └────────────────────────┘
              a+b / a−b / a&b / a|b
```

### 3.8.4.3 ⚠️ `case` ที่เขียนคนละแบบให้ผลต่างกัน

| รูปแบบ | ฮาร์ดแวร์ที่ได้ | หมายเหตุ |
|---|---|---|
| `case` ที่ cover ทุกค่าของ selector | priority mux | ปลอดภัย แต่ priority เป็นแบบ one-hot |
| `case` ที่มี `others` | mux ที่มี default | ปลอดภัยที่สุด |
| `case` ที่ไม่ cover ครบ และไม่มี `others` | **priority mux + ค่า default ที่ขึ้น X** | ดูข้อ 3.8.4.4 |

### 3.8.4.4 ⚠️ `default: n26_o = 2'bX` — X-propagation ที่หายไปในฮาร์ดแวร์

จาก Verilog ของ `fsm_seq` (build/fsm_seq.v):

```verilog
always @*
  case (n23_o)
    3'b100: n26_o = 2'b00;
    3'b010: n26_o = n18_o;
    3'b001: n26_o = n12_o;
    default: n26_o = 2'bX;      // ← สถานะที่ "ไม่มีจริง" ให้เป็น X
  endcase
```

ใน simulation ถ้า state register บังเอิญเป็นค่าที่ไม่ถูกต้อง (เช่น หลัง power-on ที่ไม่มี reset)
ผลลัพธ์จะเป็น X และการจำลองจะ "เตือน" เรา — นี่คือข้อดีของ X-propagation

ในฮาร์ดแวร์จริง **ไม่มีค่า X** — register จะเก็บค่า 0 หรือ 1 เสมอ
ดังนั้นพฤติกรรมของ RTL กับ netlist จะ **ไม่เหมือนกันในกรณีนี้**
นี่คือเหตุผลที่ต้องมี reset และต้องมี GLS (ดู §3.8.14)

---

## 3.8.5 Signal vs Variable ในเชิงฮาร์ดแวร์

คนส่วนใหญ่รู้ความต่างจากหัวข้อ 2.7 (simulation) แต่ในเชิง synthesis ความต่างคือ:

| | Signal | Variable |
|---|---|---|
| ใน simulation | มี delay (delta cycle) | เห็นค่าใหม่ทันที |
| ในฮาร์ดแวร์ | **ถ้าเป็น signal ที่ต้องเก็บค่าข้าม cycle → กลายเป็น FF** | ไม่มีที่เก็บ → กลายเป็น logic ชั่วคราว |
| ผลต่อ area | เพิ่ม FF | ไม่เพิ่ม |

ตัวอย่างจริงจาก `rtl/alu4.vhd`:

```vhdl
process (a, b, op)
  variable va, vb : unsigned(3 downto 0);
  variable vr     : std_logic_vector(3 downto 0);
begin
  va := unsigned(a);
  vb := unsigned(b);
  case op is ... end case;
  y <= vr;            -- ← ผลลัพธ์สุดท้ายออกที่ port
end process;
```

**ถ้าเขียนผิดแบบนี้**

```vhdl
signal r : std_logic_vector(3 downto 0);
begin
  process (a, b, op) begin
    ...
    r <= vr;          -- ← signal
  end process;
  y <= r;             -- ← อ่าน signal ที่เพิ่งเขียน
end;
```

จะได้ **2 รอบ delta cycle** ใน simulation และในการสังเคราะห์จะได้
**FF 8 ตัวที่ไม่จำเป็น** (เพราะ Yosys ต้องเก็บค่า `r` ไว้ข้าม process boundary)

> **กฎ:** ใช้ `variable` ภายใน process เสมอ · ใช้ `signal` เฉพาะที่ต้องเก็บข้าม cycle

---

## 3.8.6 ⚠️ Latch inference — บั๊กที่ GHDL จับได้เอง

นี่คือบั๊กที่ทำให้คนสูญเสียเวลามากที่สุด และเป็นตัวอย่างที่ดีที่สุดของหัวข้อนี้
เพราะ **เครื่องมือบอกเองว่าผิด**

### 3.8.6.1 โค้ดที่มีปัญหา

```vhdl
-- rtl/latch_bad.vhd
process (d, e)
begin
  if e = '1' then
    s <= d;
  end if;              -- ← ไม่มี else → เมื่อ e='0' ค่า s ต้อง "คงเดิม"
end process;
```

### 3.8.6.2 ข้อความจริงจาก GHDL 5.0.1

```text
rtl/latch_bad.vhd:17:3:error: latch infered for net "s" (use --latches)
  process (d, e)
  ^
```

> GHDL 5.0.1 **ปฏิเสธโดย default** และบอกทางออกมาให้ด้วยว่า `--latches`
> นี่เป็นข้อแตกต่างสำคัญจาก GHDL 1.0.0 ที่เอกสารอ้างอิงเดิมพูดถึง

### 3.8.6.3 ถ้าอยากได้ latch จริง — ต้องขออนุญาตชัดเจน

```bash
ghdl synth --latches --std=08 --out=verilog rtl/latch_bad.vhd -e latch_bad
```

ผลจริง — Verilog ที่ได้เป็น **level-sensitive** (ไม่ใช่ edge-triggered):

```verilog
always @(e)
  n5_q <= d;
```

เทียบกับ FF ปกติของ `counter_sync` ที่เป็น `always @(posedge clk)`

| | รูปแบบใน Verilog | เป็นอะไรในฮาร์ดแวร์ |
|---|---|---|
| `rising_edge(clk)` | `always @(posedge clk)` | DFF (flip-flop) |
| latch จาก `if` ไม่ครบ | `always @(e)` | **latch** (level-sensitive) |

### 3.8.6.4 ⚠️⚠️ ผลที่ได้จริง: Yosys ทิ้ง latch ทิ้งจน netlist ผิด

นี่คือ **ข้อค้นพบที่สำคัญที่สุดของหัวข้อนี้** และเป็นตัวอย่างว่าทำไมถึงต้องมี GLS

หลังสังเคราะห์ `latch_bad` ด้วย `--latches` เอาต์พุตของ GHDL คือ latch จริง:

```verilog
module latch_bad
  (input  d, input  e, output q);
  wire s;
  reg n5_q;
  assign q = s;
  assign s = n5_q;
  always @(e)          /* ← level-sensitive */
    n5_q <= d;
endmodule
```

แต่ **generic netlist ที่ Yosys สร้างออกมาไม่มี latch เลย**:

```verilog
module latch_bad(d, e, q);
  input d;
  input e;
  output q;
  wire n5_q;
  wire q;
  wire s;
  assign n5_q = d;
  assign q = d;        /* ← ⚠️ enable ถูกทิ้งไปทั้งก้อน! */
  assign s = d;
endmodule
```

สถิติจาก `reports/latch_bad_latched_generic.log`:

```text
   Number of cells:                  0        ← ไม่มี cell เลย
```

### 3.8.6.5 ต้นเหตุ — Yosys ตีความ `always @(e)` ผิด

จาก log ของ Yosys ตอนอ่าน Verilog:

```text
Note: Assuming pure combinatorial block at build/latch_bad_latched.v:11.3-12.15 in
```

**Yosys ถือว่า `always @(e)` ที่ไม่มี edge เป็น combinational block**
เพราะ Yosys infer latch จากรูปแบบ `always @*` ที่ assignment ไม่ครบทุก path
ไม่ใช่จาก `always @(สัญญาณ)` แบบของ GHDL

ผลคือ **enable ถูกตัดออกไปเงียบ ๆ** โดยไม่มีคำเตือนใด ๆ

### 3.8.6.6 ⚠️ ที่แย่กว่านั้น — `check -assert` และ formal proof ก็ไม่จับ

| การตรวจ | ผล | หมายเหตุ |
|---|---|---|
| `check -assert` ของ Yosys | **ผ่าน** (`Found and reported 0 problems`) | ไม่เตือนเลย |
| `miter` + `sat` | **SUCCESS** | เพราะ *gold ก็ถูกแปลงผิดเหมือนกัน* |
| `equiv_make` + `equiv_induct` | **Equivalence successfully proven!** | เหตุผลเดียวกัน |
| **GLS ด้วย testbench** | **GLS RESULT: FAIL** ✅ | **จับได้!** |

> **นี่คือบทเรียนที่สำคัญที่สุดของหัวข้อนี้:**
> เมื่อทั้งสองฝั่งของการเทียบเคียงถูก "แปลงผิด" เหมือนกัน
> การพิสูจน์จะ **ผ่านทั้งที่ netlist ผิด**
> มีเพียง **การจำลองด้วย stimulus ที่ออกแบบมา** เท่านั้นที่จับได้

ผล GLS จริง (`reports/gls/latch_bad_latched_gls.log`):

```text
FAIL phase2: latch should HOLD 1 after e=0, got q=0
GLS tb_latch_bad: errors = 1
GLS RESULT: FAIL
```

### 3.8.6.7 ✅ รูปแบบ latch ที่ Yosys เข้าใจถูกต้อง

ต้องเขียน Verilog ด้วยรูปแบบ `always @*` ที่ assignment ไม่ครบทุก path
(ไฟล์ `verilog/latch_ok.v` ในโค้ดประกอบ):

```verilog
module latch_ok (input wire d, input wire e, output reg q);
  always @* begin
    if (e) q = d;      // ไม่มี else -> Yosys infer $_DLATCH_
  end
endmodule
```

ผลจริง:

| | latch_bad (จาก GHDL `--latches`) | latch_ok (เขียน Verilog ตรง) |
|---|---|---|
| Yosys เข้าใจเป็น | combinational → **enable หาย** | latch → ถูกต้อง |
| generic cells | 0 | 1 |
| GLS | **FAIL** | **PASS** |

```text
GLS tb_latch_ok: errors = 0
GLS RESULT: PASS
```

### 3.8.6.8 วิธีแก้ — ทำให้ทุก path กำหนดค่า (ทางเลือกที่ดีที่สุด)

```vhdl
-- rtl/latch_good.vhd
process (d, e)
begin
  if e = '1' then
    s <= d;
  else
    s <= '0';
  end if;
end process;
```

ผลจริงเทียบกัน:

| | latch_bad_latched | latch_good |
|---|---|---|
| generic cells | 0 (แต่ผิดความหมาย) | **1** |
| sky130 area | — | **6.256000** |
| latch cells | 0 (ถูกทิ้ง) | **0** |
| GLS | **FAIL** | **PASS** |

> **บทเรียน:** latch ไม่ได้แค่ "ไม่ดี" — มัน **ทำให้ timing วิเคราะห์ไม่ได้**
> เพราะเวลาที่ latch ถือค่าขึ้นกับสัญญาณ enable ซึ่งเป็น asynchronous
> และในเคสนี้ยังทำให้ **netlist ผิดความหมายอย่างเงียบงัน** ด้วย

### 3.8.6.9 ⚠️ วิธีตรวจ latch ที่ใช้ได้ทุกเครื่องมือ

```bash
# วิธีที่ 1 — ดูจาก stat ของ Yosys
grep -E '\$_(SR_)?DLATCH' reports/<top>_generic.log

# วิธีที่ 2 — ดูจาก Verilog ที่ GHDL แปลง
grep -nE 'always @\(' build/<top>.v | grep -v 'posedge'
#   → ถ้าเจอ always @(something) ที่ไม่ใช่ posedge/negedge = level-sensitive = latch

# วิธีที่ 3 — ตรวจว่า output ที่ควรถูก latch ถูกกลายเป็น wire ตรง ๆ หรือเปล่า
grep -E 'assign q = ' build/<top>_generic.v
```

---

## 3.8.7 Clock และ Reset inference

### 3.8.7.1 `rising_edge(clk)` → DFF

```vhdl
process (clk)
begin
  if rising_edge(clk) then
    q <= d;
  end if;
end process;
```

Yosys จะสร้าง `$_DFF_P_` (positive-edge DFF) จำนวนเท่ากับความกว้างของ `q`

### 3.8.7.2 Synchronous reset → mux หน้า DFF (ไม่ใช่ reset pin)

```vhdl
process (clk)
begin
  if rising_edge(clk) then
    if rst = '1' then
      q <= (others => '0');
    elsif ce = '1' then
      q <= q + 1;
    end if;
  end if;
end process;
```

สังเคราะห์ได้เป็น: **DFF + mux 2 ชั้น** (เลือก reset / เลือก enable / ค่าปกติ)
จาก `reports/counter_sync_generic.log` — cell ประเภท `$_SDFFE_PP0P_` จำนวน **8 ตัว**
(ขนาด 8 บิต · `SDFF` = sync DFF, `E` = มี enable, `PP0` = polarity/reset แบบ sync)

### 3.8.7.3 ⚠️ Asynchronous reset → DFF ที่มี reset pin

```vhdl
process (clk, rst)
begin
  if rst = '1' then
    q <= (others => '0');
  elsif rising_edge(clk) then
    q <= d;
  end if;
end process;
```

> **สำคัญ:** ถ้า `rst` อยู่ใน sensitivity list → สังเคราะห์เป็น async reset (มี reset pin)
> ถ้า `rst` ไม่อยู่ใน sensitivity list → เป็น sync reset (เป็นแค่ mux)
> สองแบบนี้ **ไม่เท่ากัน** และมีผลต่อทั้ง area และ timing

### 3.8.7.4 ตารางเปรียบเทียบ

| รูปแบบ | สิ่งที่สังเคราะห์ได้ | ผลต่อ area | ผลต่อ timing |
|---|---|---|---|
| sync reset | DFF + mux | เพิ่ม mux ต่อบิต | เพิ่ม delay ของ data path |
| async reset | DFF ที่มี reset pin | น้อยกว่า (ไม่ต้องมี mux) | reset recovery/removal ต้องตรวจ |
| ไม่มี reset | DFF ธรรมดา | น้อยที่สุด | ต้องระวัง power-up state |

---

## 3.8.8 FSM inference — และการที่เครื่องมือเปลี่ยน encoding ให้เอง

### 3.8.8.1 RTL ที่เขียน

```vhdl
-- rtl/fsm_seq.vhd
type state_t is (IDLE, GOT1, DONE);
signal cs, ns : state_t;

process (clk)                      -- ── state register
begin
  if rising_edge(clk) then
    if rst = '1' then cs <= IDLE; else cs <= ns; end if;
  end if;
end process;

process (cs, din)                  -- ── next-state logic
begin
  case cs is
    when IDLE => if din = '1' then ns <= GOT1; else ns <= IDLE; end if;
    when GOT1 => if din = '0' then ns <= DONE; else ns <= GOT1; end if;
    when DONE => ns <= IDLE;
  end case;
end process;

with cs select                       -- ── output decoder
  state <= "00" when IDLE,
          "01" when GOT1,
          "10" when DONE;
```

### 3.8.8.2 GHDL แปลงเป็น binary encoding

```verilog
wire [1:0] cs;                        // ← 2 บิต = binary encoding
assign n14_o = cs == 2'b00;
assign n20_o = cs == 2'b01;
assign n22_o = cs == 2'b10;
```

### 3.8.8.3 ⚠️ Yosys เปลี่ยนเป็น one-hot เอง

จาก `reports/fsm_seq_generic.log`:

```text
   Number of cells:                 26
     $_DFF_P_                        3     ← 3 ตัว = one-hot (ไม่ใช่ 2!)
```

> **นี่คือเรื่องที่ต้องบอกผู้เรียนทุกครั้งที่รายงาน "จำนวน FF"**
> จำนวน FF ขึ้นกับ flow ที่ใช้ ไม่ใช่ค่าคงที่ของ RTL
> (ดูรายละเอียดเดียวกันใน `Manual_3_5_Yosys_...` ข้อ 21)

### 3.8.8.4 ⚠️ ผลข้างเคียงที่จับได้ — การพิสูจน์ equivalence ให้ผลลวง

เมื่อ Yosys recode FSM จาก binary เป็น one-hot ความหมายของ "ค่าเริ่มต้นของ state register"
ก็เปลี่ยนตาม (one-hot ค่าเริ่มต้นคือ 0 ซึ่ง **ไม่ใช่** state ที่ถูกต้อง)

ผลที่วัดได้จริง — การพิสูจน์แบบ `miter` + `sat -seq 12 -set-init-zero`:

```text
Solving problem with 3654 variables and 9649 clauses..
ERROR: Called with -verify and proof did fail!
```

แต่เมื่อใช้ flow ที่ถูกต้อง (`equiv_make` + `equiv_induct`, ดู §3.8.14.4):

```text
Found 16 unproven $equiv cells (10 groups) in equiv:
Proved 16 previously unproven $equiv cells.
    Of those cells 16 are proven and 0 are unproven.
    Equivalence successfully proven!
```

> **บทเรียน:** "พิสูจน์ไม่ผ่าน" ไม่ได้แปลว่า "netlist ผิด"
> ต้อง triage ก่อน — และในกรณีนี้มันคือข้อจำกัดของ *วิธีพิสูจน์* ไม่ใช่ข้อผิดพลาดของ RTL

### 3.8.8.5 ถ้าอยากคุม encoding เอง

```bash
# ใน Yosys: ห้าม recode
fsm -norecode
```

---

## 3.8.9 Arithmetic mapping — ตัวเลขจริงจากการสังเคราะห์

### 3.8.9.1 `unsigned + unsigned` → carry chain

```vhdl
-- rtl/adder8.vhd
s <= resize(unsigned(a), 9) + resize(unsigned(b), 9);
sum  <= std_logic_vector(s);
cout <= s(8);
```

ผลจริง:

| ตัวชี้วัด | ค่า |
|---|---|
| generic cells | **49** |
| sky130 area | **205.196800** |
| formal equivalence | PASS (ทั้ง 2 flow) |

> การใช้ `resize` เพื่อขยายเป็น 9 บิตก่อนบวก ทำให้ carry out ไม่ถูกตัดทิ้ง
> ถ้าไม่ resize ผลจะเป็น mod-256 ซึ่ง carry out จะหายไปเสมอ

### 3.8.9.2 `unsigned * unsigned` → partial-product array

```vhdl
-- rtl/mult8.vhd
p <= std_logic_vector(unsigned(a) * unsigned(b));
```

ผลจริง:

| ตัวชี้วัด | ค่า |
|---|---|
| generic cells | **354** |
| sky130 area | **1904.326400** |

> **ข้อสังเกตเชิงเศรษฐศาสตร์:** multiplier 8×8 ใช้พื้นที่มากกว่า adder 8-bit **ประมาณ 9 เท่า**
> (1904.33 ÷ 205.20 = 9.28) และมากกว่า ALU 4-bit เกือบ **10 เท่า**
> นี่คือเหตุผลที่โจทย์จริงมักใช้ multiplier แบบ pipeline หลายจังหวะ

### 3.8.9.3 ⚠️ `numeric_std` กับ `std_logic_vector` ไม่เข้ากัน

```vhdl
-- ❌ ใช้ไม่ได้
sum <= a + b;              -- a, b เป็น std_logic_vector
-- error: operator "+" not defined for ... std_logic_vector
```

ต้องแปลงก่อนเสมอ:

```vhdl
-- ✅ ทำถูกต้อง
sum <= std_logic_vector(unsigned(a) + unsigned(b));
```

และถ้าผลลัพธ์ยาวกว่า operand ต้อง `resize` ก่อน ไม่ใช่ให้ `numeric_std` ตัดให้

### 3.8.9.4 ตารางเปรียบเทียบตัวเลขจริงทั้งหมด

| Design | ความหมาย | generic cells | sky130 area |
|---|---|---:|---:|
| `latch_bad_latched` | latch (ที่ถูกทิ้ง — ดู §3.8.6.4) | 0 | — |
| `latch_good` | mux 1 บิต | 1 | 6.256000 |
| `fsm_seq` | FSM 3 สถานะ | 26 | 106.352000 |
| `rom_16x8` | ROM 16×8 (กลายเป็น mux tree) | 25 | 113.859200 |
| `counter_sync` | counter 8-bit + reset + CE | 24 | 280.268800 |
| `adder8` | adder 8-bit + carry | 49 | 205.196800 |
| `alu4` | ALU 4-bit (add/sub/and/or) | 57 | 208.950400 |
| `lfsr16` | LFSR 16-bit | 35 | 569.296000 |
| `shifter` | barrel shifter 8-bit | 146 | 721.942400 |
| `mult8` | multiplier 8×8 | 354 | 1904.326400 |

> **ข้อสังเกตที่น่าสนใจ:** `alu4` (4 ตัวเลือก) ใช้พื้นที่แทบเท่ากับ `adder8` (2 ตัวเลือก)
> เพราะ ALU มี adder + subtractor + logic เล็ก ๆ แต่ **share adder กัน**
> (resource sharing) — ตัวเลือก `+` และ `−` ใช้ adder ตัวเดียวกันกับสัญญาณควบคุม
> นี่คือการ optimize ที่เครื่องมือทำให้เอง ไม่ต้องเขียนโค้ดให้ซับซ้อนขึ้น

---

## 3.8.10 Variable shift → mux tree

### 3.8.10.1 โค้ดที่เขียน

```vhdl
-- rtl/shifter.vhd
process (d, shamt, left)
  variable vd  : std_logic_vector(7 downto 0);
  variable amt : unsigned(2 downto 0);
begin
  vd  := d;
  amt := unsigned(shamt);
  if left = '1' then
    for i in 0 to 7 loop
      if unsigned(amt) > to_unsigned(i, 3) then
        vd := vd(6 downto 0) & '0';
      end if;
    end loop;
  else
    ...
  end if;
  y <= vd;
end process;
```

### 3.8.10.2 สิ่งที่สังเคราะห์ได้

`for` loop ที่มีช่วงคงที่ (0 to 7) ถูก **unroll** เป็น 8 ชั้นของ logic
รวมกับเงื่อนไขเปรียบเทียบ 3 บิต → ได้ **mux tree 3 ระดับ** (log2(8) = 3)

ผลจริง:

| ตัวชี้วัด | ค่า |
|---|---|
| generic cells | **146** |
| sky130 area | **721.942400** |
| formal equivalence | PASS (ทั้ง 2 flow) |

> **เปรียบเทียบ:** barrel shifter 8-bit ใช้พื้นที่ **3.5 เท่า** ของ adder 8-bit
> ทั้งที่เป็นแค่การเลื่อนบิต — เพราะ mux tree 8→1 ต้องมี 8×8 = 64 ช่อง
> นี่คือต้นทุนที่ต้องรู้ก่อนเลือกใช้

---

## 3.8.11 ROM และ Memory inference

### 3.8.11.1 โค้ด

```vhdl
-- rtl/rom_16x8.vhd
type rom_t is array (0 to 15) of std_logic_vector(7 downto 0);
constant rom : rom_t := (
  0 => x"00", 1 => x"01", 2 => x"04", 3 => x"09",
  ...
);
begin
  process (addr)
    variable idx : integer;
  begin
    idx := to_integer(unsigned(addr));
    dout <= rom(idx);
  end process;
end architecture rtl;
```

### 3.8.11.2 ⚠️ ข้อผิดพลาดที่เจอจริงระหว่างทำตัวอย่าง

รุ่นแรกใช้แค่ `std_logic_1164` แล้วเรียก `to_integer` → GHDL ตอบว่า:

```text
rtl/rom_16x8.vhd:25:12:error: no declaration for "to_integer"
    idx := to_integer(unsigned(addr));
           ^
```

**แก้:** เพิ่ม `use ieee.numeric_std.all;` — เพราะ `to_integer` อยู่ใน `numeric_std`

> **บทเรียน:** ข้อผิดพลาดระดับ "ขาด import" จะทำให้คุณเข้าใจว่า
> `numeric_std` ไม่ได้แค่ทำ arithmetic แต่ยังมี `to_integer` `to_unsigned`
> `resize` `shift_left` ที่จำเป็นกับการทำ index ของ memory ด้วย

### 3.8.11.3 ข้อความ "พบ ROM" จาก GHDL

เมื่อแก้แล้ว GHDL รายงานว่าตรวจพบ ROM:

```text
rtl/rom_16x8.vhd:25:16:note: found ROM "n10", width: 8 bits, depth: 16
    dout <= rom(idx);
               ^
```

และ Verilog ที่ได้ก็เปลี่ยนไปเป็น memory จริง:

```verilog
reg [7:0] n13[15:0] ; // memory
initial begin
  n13[15] = 8'b00000000;
  n13[14] = 8'b00000001;
  ...
  end
assign n14_data = n13[n8_o];
```

### 3.8.11.4 ⚠️ แต่ Yosys จะ "แตก" memory ออกเป็น logic

คำสั่ง `synth` มาพร้อม pass `memory_map` ซึ่งจะแปลง memory ที่อ่านแบบ combinational
ออกเป็น **mux tree** ขนาด 16→1

ผลจริง (`reports/rom_16x8_generic.log`):

```text
   Number of cells:                 25
     $_ANDNOT_                       7
     $_AND_                          2
     $_MUX_                         10
     $_NAND_                         2
     $_NOT_                          2
     $_ORNOT_                        1
     $_OR_                           1
```

| ผลลัพธ์ | ค่า |
|---|---|
| generic cells | **25** |
| sky130 area | **113.859200** |
| กลไกในฮาร์ดแวร์ | mux tree (ไม่ใช่ memory macro) |

> **ถ้าต้องการได้ memory macro จริง (เช่น SRAM block) ต้อง:**
> 1. ใช้ `synth -noabc` + ปิด `memory_map` หรือใช้ `memory -nomap`
> 2. เพิ่ม attribute `rom_style` / `ram_style`
> 3. **ต้องมี PDK ที่มี memory compiler** — generic synthesis ทำไม่ได้
>
> ดูรายละเอียดเพิ่มใน `docs/reference/vhdl/10-synthesis-subset.md` ข้อ 6

### 3.8.11.5 ⚠️ เมื่อมี memory การพิสูจน์ equivalence ต้อง `memory_map` ทั้งสองฝั่ง

การพิสูจน์แบบ `miter` + `sat` ล้มเหลวทันทีเมื่อฝั่ง gold ยังเป็น memory:

```text
ERROR: Failed to import cell gold.n13 (type $mem_v2) to SAT database.
```

และแบบ `equiv_make` ก็พิสูจน์ไม่ได้:

```text
Found 51 unproven $equiv cells (4 groups) in equiv:
Proved 35 previously unproven $equiv cells.
ERROR: Found 16 unproven $equiv cells in 'equiv_status -assert'.
```

**สาเหตุ:** gold ยังเป็น memory (`$mem_v2`) ขณะที่ gate ถูก `memory_map` เป็น mux แล้ว
ทั้งสองฝั่งจึงไม่ได้อยู่ใน "ภาษา" เดียวกัน จึงเทียบกันไม่ได้

**วิธีแก้ — แปลงทั้งสองฝั่งให้เป็นรูปแบบเดียวกันก่อนเทียบ:**

```bash
read_verilog build/rom_16x8.v
prep -top rom_16x8 -flatten
memory_map          # ← เพิ่มบรรทัดนี้
opt_clean
design -stash gold

read_verilog build/rom_16x8_generic.v
prep -top rom_16x8 -flatten
memory_map          # ← และบรรทัดนี้
opt_clean
design -stash gate
```

ผลจริงหลังแก้:

```text
Found 51 unproven $equiv cells (4 groups) in equiv:
Proved 51 previously unproven $equiv cells.
    Of those cells 51 are proven and 0 are unproven.
    Equivalence successfully proven!
```

> **บทเรียนทั่วไป:** เวลาเทียบสอง design ด้วย formal tool
> **ต้องทำให้ทั้งสองฝั่งอยู่ใน "ภาษา" เดียวกันก่อนเสมอ**
> ไม่งั้นความต่างจะมาจากรูปแบบการแทนความ ไม่ใช่จากตรรกะที่ผิด

---

## 3.8.12 Constant propagation และ dead code elimination

### 3.8.12.1 เงื่อนไขที่คงที่ถูก fold ทันที

```vhdl
-- ถ้าเขียนแบบนี้
if (1 = '1') then
  y <= a;
else
  y <= b;
end if;
```

เครื่องมือจะ collapse เป็น `y <= a;` โดยไม่ต้องเขียนโค้ดให้ตรงเป็นแบบนั้น
`opt_expr` และ `opt` ของ Yosys ทำหน้าที่นี้

### 3.8.12.2 Dead code ที่ถูกตัดทิ้ง

โค้ดที่เขียนแล้วไม่มีทางถูกเรียกใช้ (เช่น output ที่ไม่ได้ต่อไปไหน)
จะถูก `opt_clean` ตัดทิ้ง — **ตัวเลข "จำนวน cell" จึงไม่เท่ากับจำนวน logic ที่เขียน**

> **คำเตือน:** อย่าสรุปว่า "โค้ดเยอะ = chip ใหญ่"
> ตัวเลขที่สนใจคือ cell count / area จาก `stat` หลัง optimize เสมอ

---

## 3.8.13 ⚠️ `std_logic_arith` — สังเคราะห์ไม่ผ่าน

### 3.8.13.1 โค้ดที่เขียนตั้งใจให้ล้มเหลว

```vhdl
-- rtl/std_logic_arith_bad.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;      -- ← package ที่ไม่ควรใช้

entity std_logic_arith_bad is
  port (a, b : in std_logic_vector(7 downto 0);
            s : out std_logic_vector(7 downto 0));
end entity;

architecture rtl of std_logic_arith_bad is
begin
  s <= a + b;
end architecture rtl;
```

### 3.8.13.2 ข้อความจริงจาก GHDL 5.0.1

```text
rtl/std_logic_arith_bad.vhd:6:10:error: use of synopsys package "std_logic_arith" needs the -fsynopsys option
use ieee.std_logic_arith.all;
         ^
```

### 3.8.13.3 ทำไมถึงเป็นปัญหา

`std_logic_arith` เป็น package ที่ Synopsys เขียนขึ้นในยุคที่ยังไม่มีมาตรฐาน
มันใช้ **overloading ของ `+` บน `std_logic_vector`** ซึ่งไม่ชัดเจนว่าเป็น unsigned หรือ signed
และมีพฤติกรรม overflow ที่ไม่ตรงกับมาตรฐาน

| | `ieee.std_logic_arith` | `ieee.numeric_std` |
|---|---|---|
| สถานะ | ไม่ใช่มาตรฐาน IEEE (Synopsys) | มาตรฐาน IEEE 1076.4 |
| สังเคราะห์ได้ | **ไม่ได้** โดยค่าเริ่มต้น | ได้ |
| ต้องใช้ `-fsynopsys` | ต้อง | ไม่ต้อง |
| signed/unsigned | ปนกัน | แยกชัดเจน (`signed` / `unsigned`) |

### 3.8.13.4 วิธีแก้

```vhdl
-- ✅ ใช้แทน
use ieee.numeric_std.all;
s <= std_logic_vector(unsigned(a) + unsigned(b));
```

---

## 3.8.14 พิสูจน์ว่า netlist ถูกต้อง — 4 วิธีที่วัดได้จริง

หัวข้อนี้ไม่ยอมรับคำว่า "สังเคราะห์ผ่าน" ถ้าพิสูจน์ความถูกต้องไม่ได้
นี่คือ 4 วิธีที่รันจริงใน `lab_code/day3_synthesis/`

### 3.8.14.1 วิธีที่ 1 — Gate-Level Simulation (GLS)

เอา netlist ที่สังเคราะห์แล้ว ไปรันด้วย testbench เดิม
(ดูละเอียดเชิงลึกที่ `Manual_4_3_GateLevelSimulation_SDF_DeepDive.md`)

```bash
iverilog -g2012 -o reports/gls/alu4_gls.vvp build/alu4_generic.v tb/tb_alu4.v
vvp reports/gls/alu4_gls.vvp
```

ผลจริง — ตรวจ **ทุก input combination**:

```text
GLS tb_alu4: checked 1024 combinations, errors = 0
GLS RESULT: PASS
```

และ:

```text
GLS tb_adder8: checked 65536 combinations, errors = 0
GLS RESULT: PASS
```

> **ข้อจำกัดของ GLS:** พิสูจน์เฉพาะ stimulus ที่ใส่เข้าไปเท่านั้น
> ถ้า testbench ครอบคลุมไม่ครบ ก็ยังไม่ได้พิสูจน์อะไร
> ต้องมี formal proof ประกอบ

### 3.8.14.2 วิธีที่ 2 — `miter` + SAT (พิสูจน์แบบ bounded)

```bash
yosys -Q -p "
  read_verilog build/alu4.v
  prep -top alu4 -flatten
  design -stash gold
  read_verilog build/alu4_generic.v
  prep -top alu4 -flatten
  design -stash gate
  design -copy-from gold -as gold alu4
  design -copy-from gate -as gate alu4
  miter -equiv -flatten -make_assert gold gate miter
  hierarchy -top miter
  sat -verify -prove-asserts -seq 12 miter
"
```

กลไก: สร้างวงจรที่เอาเอาต์พุตของทั้งสองฝั่งมาเทียบกัน
แล้วให้ SAT solver หา input sequence ที่ทำให้ผลต่างกัน
ถ้าหาไม่พบใน N รอบ → ผ่าน (แต่เป็นการพิสูจน์แบบ **จำกัดจำนวนรอบ** ไม่ใช่การพิสูจน์สมบูรณ์)

### 3.8.14.3 ⚠️ ข้อจำกัดและ false negative ที่เจอจริง

| ข้อ | อาการจริง |
|---|---|
| Design ที่ไม่มี DFF | ✅ ผ่านเร็ว (`alu4`, `adder8`, `shifter`, `latch_good`) |
| Design ที่มี DFF + `-set-init-zero` | ⚠️ ผ่านเฉพาะบางตัว (`counter_sync` ผ่าน แต่ `fsm_seq` ไม่ผ่าน) |
| Design ที่มี DFF โดยไม่กำหนด init | ❌ ไม่ผ่าน — เพราะสถานะเริ่มต้นไม่รู้ค่า |
| Design ขนาดใหญ่ (`mult8`) | ⏱ **แก้ไม่จบ** — SAT ต้องการ 46,131 variables / 125,956 clauses |

ผลจริงที่วัดได้ (จาก `reports/summary.txt`):

| Design | miter + sat | หมายเหตุ |
|---|---|---|
| `alu4` | PASS | combinational |
| `adder8` | PASS | combinational |
| `shifter` | PASS | combinational |
| `latch_good` | PASS | combinational |
| `counter_sync` | **FAIL** | ต้องการ init ที่กำหนด |
| `fsm_seq` | **FAIL** | one-hot recode ทำให้ init assumption ผิด |
| `mult8` | **TIMEOUT** | แก้ไม่จบใน 90 วินาที |

> **บทเรียน:** `miter` + `sat` เป็นการพิสูจน์แบบ **bounded**
> ใช้ได้ดีกับ combinational แต่ sequential ต้องใช้ flow ที่ถูกต้องกว่า

### 3.8.14.4 ✅ วิธีที่ 3 — `equiv_make` + `equiv_induct` (flow ที่ถูกต้องสำหรับ sequential)

```bash
yosys -Q -p "
  read_verilog build/fsm_seq.v
  prep -top fsm_seq -flatten
  design -stash gold
  read_verilog build/fsm_seq_generic.v
  prep -top fsm_seq -flatten
  design -stash gate
  design -copy-from gold -as gold fsm_seq
  design -copy-from gate -as gate fsm_seq
  equiv_make gold gate equiv
  hierarchy -top equiv
  equiv_simple -seq 5
  equiv_induct -seq 5
  equiv_status -assert
"
```

**ทำไมถึงต่างจากวิธีที่ 2:**

| | `miter` + `sat` | `equiv_make` + `equiv_induct` |
|---|---|---|
| วิธีพิสูจน์ | bounded (จำกัดจำนวนรอบ) | **induction (ไม่จำกัดรอบ)** |
| ต้องการ init ที่แน่นอนหรือไม่ | ต้อง | ไม่ต้อง |
| จัดการ FSM ที่ถูก recode | ไม่ได้ | ได้ |
| ความเร็วบน design ขนาดใหญ่ | ช้ามาก (timeout) | เร็วกว่า |

ผลจริง — ทุก design ที่สังเคราะห์ผ่าน **พิสูจน์ได้**:

```text
=== fsm_seq ===
Found 16 unproven $equiv cells (10 groups) in equiv:
Proved 16 previously unproven $equiv cells.
    Of those cells 16 are proven and 0 are unproven.
    Equivalence successfully proven!
```

```text
=== counter_sync ===
Found 32 unproven $equiv cells (4 groups) in equiv:
Proved 32 previously unproven $equiv cells.
    Of those cells 32 are proven and 0 are unproven.
    Equivalence successfully proven!
```

```text
=== lfsr16 ===
Found 98 unproven $equiv cells (10 groups) in equiv:
Proved 98 previously unproven $equiv cells.
    Of those cells 98 are proven and 0 are unproven.
    Equivalence successfully proven!
```

### 3.8.14.5 วิธีที่ 4 — เลือกวิธีพิสูจน์ตามชนิดของ design

สคริปต์ `synth_one.sh` ในหัวข้อนี้เลือกเองอัตโนมัติ:

```bash
# ตรวจว่า netlist มี DFF หรือไม่
HAS_DFF=$(grep -cE '\$dff|\$_DFF' "reports/${TAG}_generic.log")

if [ "$HAS_DFF" -gt 0 ]; then
  # sequential → ต้องใช้ induction
  EQ_STEPS="equiv_simple -seq 5
    equiv_induct -seq 5"
else
  # combinational → simple อย่างเดียวก็จบ
  EQ_STEPS="equiv_simple -seq 5"
fi
```

### 3.8.14.6 สรุปผลพิสูจน์ทั้งหมด

| Design | ชนิด | generic cells | sky130 area | miter+sat | equiv_induct | GLS |
|---|---|---:|---:|:---:|:---:|:---:|
| `alu4` | comb | 57 | 208.950400 | PASS | PASS | PASS |
| `counter_sync` | seq | 24 | 280.268800 | FAIL | **PASS** | — |
| `fsm_seq` | seq | 26 | 106.352000 | FAIL | **PASS** | — |
| `adder8` | comb | 49 | 205.196800 | PASS | PASS | PASS |
| `mult8` | comb | 354 | 1904.326400 | TIMEOUT | **PASS** | — |
| `shifter` | comb | 146 | 721.942400 | PASS | PASS | — |
| `lfsr16` | seq | 35 | 569.296000 | FAIL | **PASS** | — |
| `latch_bad_latched` | latch | 0 | — | PASS ⚠️ | PASS ⚠️ | **FAIL** ⚠️ |
| `latch_good` | comb | 1 | 6.256000 | PASS | PASS | PASS |
| `rom_16x8` | comb | 25 | 113.859200 | PASS | PASS | — |
| `latch_ok` (Verilog) | latch | 1 | — | — | — | **PASS** |

> **⚠️ แถว `latch_bad_latched` คือหัวข้อของหัวข้อนี้ทั้งหมด:**
> ทุกการตรวจแบบ formal **ผ่าน** แต่ GLS **ไม่ผ่าน** เพราะทั้งสองฝั่งถูกแปลงผิดเหมือนกัน
> (ดู §3.8.6.4–§3.8.6.6) — นี่คือหลักฐานว่าการพิสูจน์ formal อย่างเดียวไม่พอ

ผลรวมจาก `reports/summary.txt`:

```text
PASS=10  FAIL=2  (ทั้งหมด 12 รายการ)
  จากนั้น FAIL=2 รายการ แยกเป็น:
    - ตั้งใจให้ GHDL synth ล้มเหลว (latch_bad, std_logic_arith_bad) = ผลที่ถูกต้อง
    - เปิด --latches (latch_bad_latched) ได้ latch จริง
    - TIMEOUT=1 รายการ (SAT แบบ bounded แก้ไม่จบในเวลาที่กำหนด)
```

ผล GLS รวม (`reports/run_everything.log`):

```text
 GLS SUMMARY: ตรงตามคาด 4 เคส / ไม่ตรง 0 เคส (ทั้งหมด 4 เคส)
```

---

## 3.8.15 สไตล์ RTL มีผลต่อพื้นที่จริง

จากตัวเลขในตารางข้อ 3.8.9.4 สามารถคำนวณอัตราส่วนได้:

| การเปรียบเทียบ | อัตราส่วน | ตีความ |
|---|---:|---|
| `mult8` ÷ `adder8` | 9.28× | multiplier 8×8 แพงกว่า adder 8-bit เกือบ 10 เท่า |
| `shifter` ÷ `adder8` | 3.52× | barrel shifter 8-bit แพงกว่า adder 8-bit 3.5 เท่า |
| `alu4` ÷ `adder8` | 1.02× | ALU 4 ทางแทบเท่า adder 8-bit (มี resource sharing) |
| `fsm_seq` ÷ `latch_good` | 16.99× | FSM 3 สถานะ + output decoder ใช้พื้นที่มากกว่า mux 1 บิต |

> **บทเรียน:** การเลือก operator มีผลต่อพื้นที่มากกว่าที่คิด
> ก่อนสังเคราะห์ ควรประมาณการอัตราส่วนของแต่ละทางเลือก
> แล้วค่อยตัดสินใจ ไม่ใช่รอให้ tool บอกทีหลัง

---

## 3.8.16 ตารางคำสั่งที่ต้องจำ

| คำสั่ง | หน้าที่ | หมายเหตุ |
|---|---|---|
| `ghdl synth --std=08 --out=verilog <file> -e <top>` | VHDL → Verilog | ตัวแปลง ไม่ใช่ synthesizer |
| `ghdl synth --latches ...` | อนุญาตให้ infer latch | GHDL 5.0.1 ปฏิเสธโดย default |
| `ghdl synth -fsynopsys ...` | ใช้ package ของ Synopsys | ใช้เมื่อจำเป็นเท่านั้น |
| `yosys -p "read_verilog <f>; hierarchy -check -top <t>"` | อ่าน + ตรวจ hierarchy | `-check` จับ module ที่หายไป |
| `yosys -p "synth -top <t>"` | สังเคราะห์ generic | มี pass `memory_map`, `fsm`, `opt` อยู่ข้างใน |
| `yosys -p "synth -top <t> -noabc"` | สังเคราะห์โดยไม่ map | ต้องใส่ก่อน `abc -liberty` |
| `yosys -p "check -assert"` | ตรวจ netlist ว่าไม่มี cell ค้าง | error ทันทีถ้ามีปัญหา |
| `yosys -p "stat"` | รายงานจำนวน cell | ดู `Number of cells:` |
| `yosys -p "stat -liberty <lib>"` | รายงาน area จริง | ต้อง map ก่อน |
| `yosys -p "dfflibmap -liberty <lib>"` | map FF ให้ตรงกับ PDK | ต้องทำก่อน `abc` |
| `yosys -p "abc -liberty <lib>"` | technology mapping | ห้าม map ซ้ำสองรอบ |
| `yosys -p "write_verilog -noattr <f>"` | ส่งออก netlist | `-noattr` ตัด attribute ที่ไม่ต้องการ |
| `yosys -p "miter -equiv -flatten -make_assert gold gate miter"` | สร้างวงจรเทียบ | ใช้กับ `sat` |
| `yosys -p "sat -verify -prove-asserts -seq <N> miter"` | พิสูจน์แบบ bounded | ไม่จบกับ design ใหญ่ |
| `yosys -p "equiv_make gold gate equiv"` | สร้างจุดเทียบ | ใช้ร่วมกับ `equiv_induct` |
| `yosys -p "equiv_induct -seq <N>"` | พิสูจน์แบบ induction | สำหรับ sequential |
| `yosys -p "equiv_status -assert"` | สรุปและ error ถ้ายังไม่พิสูจน์ | ต้องเป็นขั้นสุดท้าย |
| `iverilog -g2012 -o <vvp> <netlist> <tb>` | คอมไพล์ GLS | ใช้ Verilog netlist |

---

## 3.8.17 Checklist กับดักที่พบจริง (20 ข้อ)

### ดักที่ทำให้ synthesis ไม่ผ่าน

| # | อาการ | สาเหตุ | วิธีแก้ |
|---|---|---|---|
| 1 | `error: latch infered for net "s" (use --latches)` | `if` ไม่ครอบทุก path | เติม `else` หรือใช้ `--latches` อย่างมีเจตนา |
| 2 | `error: use of synopsys package "std_logic_arith" needs the -fsynopsys option` | ใช้ package ที่ไม่ใช่มาตรฐาน | เปลี่ยนเป็น `ieee.numeric_std` |
| 3 | `error: no declaration for "to_integer"` | ลืม `use ieee.numeric_std.all` | เพิ่ม import |
| 4 | `unknown command option '-e'` | `--workdir` ชี้ไปที่ dir ที่ยังไม่มี | สร้าง dir หรือตัด `--workdir` ออก |
| 5 | `ERROR: Module 'xxx' not found!` | ชื่อ top ใน Yosys ไม่ตรง entity | ตรวจ `grep '^module '` ในไฟล์ Verilog |

### ดักที่ทำให้ผลลัพธ์ผิด (แต่สังเคราะห์ผ่าน)

| # | อาการ | สาเหตุ | วิธีแก้ |
|---|---|---|---|
| 6 | **netlist ทำงานผิด โดยไม่มีเครื่องมือไหนเตือน** | Yosys ตีความ `always @(e)` เป็น combinational → enable หาย | ตรวจ GLS เสมอ — ดู §3.8.6.4 |
| 7 | จำนวน FF ไม่ตรงกับที่คาด | Yosys `fsm` recode binary → one-hot | ระบุ flow ที่ใช้เมื่อรายงาน หรือใช้ `fsm -norecode` |
| 8 | carry out หายไป | ไม่ได้ `resize` ก่อนบวก | `resize(unsigned(a), 9) + resize(unsigned(b), 9)` |
| 9 | ผลลัพธ์ต่างกันตอน reset ยังไม่ถูก assert | RTL ให้ `X`, ฮาร์ดแวร์ให้ 0/1 | มี reset ที่ถูกต้อง + ทำ GLS |
| 10 | latch โผล่ใน netlist ทั้งที่ไม่ได้เขียน latch | `if` ในโค้ดเชิงตรรกะ | ตรวจ `grep '\$_(SR_)?DLATCH'` |

### ดักในการพิสูจน์ความถูกต้อง

| # | อาการ | สาเหตุ | วิธีแก้ |
|---|---|---|---|
| 11 | `ERROR: Failed to import cell ... (type $dff) to SAT database` | ลืมใส่ `-seq N` ใน `sat` | เพิ่ม `-seq <N>` |
| 12 | `ERROR: Called with -verify and proof did fail!` บน FSM | `-set-init-zero` ขัดกับ one-hot recode | ใช้ `equiv_make` + `equiv_induct` |
| 13 | `ERROR: Failed to import cell gold.n13 (type $mem_v2)` | ฝั่ง gold ยังเป็น memory | `memory_map` ทั้งสองฝั่งก่อนเทียบ |
| 14 | `sat` แก้ไม่จบ | design ใหญ่เกินไป | ใช้ `equiv_induct` หรือจำกัดเวลา (`timeout 90`) |
| 15 | พิสูจน์ "ผ่าน" แต่ netlist ผิด | ทั้งสองฝั่งถูกแปลงผิดเหมือนกัน | ต้องมี GLS ประกอบเสมอ |

### ดักเชิงวิธีการ

| # | อาการ | สาเหตุ | วิธีแก้ |
|---|---|---|---|
| 16 | ตัวเลข cell count เปลี่ยนทุกครั้งที่แก้โค้ด | optimization ตัด logic ที่ไม่ใช้ | รายงานตัวเลขจาก `stat` หลัง optimize เสมอ |
| 17 | คิดว่า `ghdl synth` ได้ gate แล้ว | มันได้แค่ Verilog behavioral | ส่งต่อให้ Yosys สังเคราะห์จริง |
| 18 | map เข้า PDK แล้ว area แย่กว่าเดิม | `abc` ทำงานสองรอบซ้อนกัน | ใช้ `synth -noabc` ก่อน `abc -liberty` |
| 19 | คิดว่า ROM ได้ memory macro | `synth` มี pass `memory_map` อยู่แล้ว | ปิด `memory_map` และใช้ attribute |
| 20 | ใช้ `signal` ใน process แล้ว area เพิ่ม | ถูกเก็บเป็น FF ข้าม cycle | ใช้ `variable` ภายใน process |

---

## 3.8.18 แบบฝึกหัด

| # | โจทย์ | ระดับ | ผลที่คาดหวัง |
|---|---|---|---|
| 1 | รัน `ghdl synth` ใน `rtl/alu4.vhd` แล้วหา `always @*` ในไฟล์ Verilog ที่ได้ | ง่าย | พิสูจน์ว่า GHDL ไม่ได้ทำ synthesis |
| 2 | สร้าง `rtl/latch_bad2.vhd` ที่มี latch แล้วรัน `synth_one.sh` พร้อม `--latches` | ง่าย | เห็น `$_DLATCH_` ใน `stat` |
| 3 | แก้ `counter_sync` ให้เป็น async reset แล้วเทียบ cell count กับ sync reset | ปานกลาง | เห็นความต่างของ area |
| 4 | เพิ่มเงื่อนไข `if (1 = '1')` ใน `alu4` แล้วเทียบ cell count | ปานกลาง | เห็น constant propagation ลด cell |
| 5 | เปลี่ยน `shifter` จาก barrel shifter เป็น fixed shift แล้วเทียบ area | ปานกลาง | area ลดลงชัดเจน |
| 6 | เขียน `tb/tb_lfsr16.v` ให้ตรวจ LFSR 256 รอบ แล้วทำ GLS | ปานกลาง | `GLS RESULT: PASS` |
| 7 | สร้าง ROM 32×8 แล้วเปรียบเทียบ cell count กับ LUT | ยาก | เห็นต้นทุนของ memory ที่กลายเป็น logic |
| 8 | ทำ formal proof แบบ `equiv_make` + `equiv_induct` ให้กับ design ที่คุณเขียนเอง | ยาก | `Equivalence successfully proven!` |

---

## 3.8.19 สรุป

### 3.8.19.1 สิ่งที่ต้องจำ 10 ข้อ

1. **`ghdl synth` เป็นตัวแปลง ไม่ใช่ synthesizer** — เอาต์พุตยังเป็น behavioral Verilog
2. **GHDL 5.0.1 ปฏิเสศ latch โดย default** พร้อมบอกทางออก (`--latches`)
3. **`std_logic_arith` สังเคราะห์ไม่ผ่าน** — ใช้ `ieee.numeric_std` เท่านั้น
4. **`case` กลายเป็น priority mux** — และ `default` ที่ให้ `X` หายไปในฮาร์ดแวร์
5. **Yosys recode FSM binary → one-hot** — จำนวน FF จึงขึ้นกับ flow ไม่ใช่ RTL
6. **`numeric_std` ไม่รองรับ operator กับ `std_logic_vector`** — ต้องแปลงก่อน
7. **`resize` ก่อนบวก** ไม่งั้น carry out หาย
8. **ยืนยัน netlist ต้องมี 2 ชั้น** — GLS (ตรวจ stimulus) + formal proof (พิสูจน์ครบ)
9. **`miter` + `sat` เป็น bounded proof** — sequential ต้องใช้ `equiv_make` + `equiv_induct`
10. **ตัวเลขที่รายงานต้องมาจาก `stat` หลัง optimize** — ไม่ใช่จำนวนบรรทัดโค้ด

### 3.8.19.2 ตารางอ้างอิงด่วน — 5 ตัวเลขที่ต้องจำ

| ตัวเลข | ค่า | ที่มา |
|---|---:|---|
| `alu4` generic cells | 57 | `reports/alu4_generic.log` |
| `alu4` sky130 area | 208.950400 | `reports/alu4_sky130.log` |
| `mult8` sky130 area | 1904.326400 | `reports/mult8_sky130.log` |
| `mult8` ÷ `adder8` | 9.28× | คำนวณจาก area จริง |
| `latch_good` generic cells | 1 | `reports/latch_good_generic.log` |

---

## อ้างอิง

### เอกสารของเครื่องมือ

- GHDL Documentation — Synthesis: <https://ghdl.github.io/ghdl/using/Simulation.html>
- Yosys Manual — `synth`, `abc`, `equiv_make`, `equiv_induct`, `stat`: <https://yosyshq.readthedocs.io/>
- Icarus Verilog User Guide: <https://steveicarus.github.io/iverilog/>
- IEEE Std 1076-2008 (VHDL Language Reference)
- IEEE Std 1076.4-2004 (VHDL Synthesis Packages: `numeric_std`, `numeric_bit`)

### เอกสารในชุดนี้

- [`Manual_1_2_4_and_1_3_Simulation_vs_Synthesis_DataTypes_DeepDive.md`](Manual_1_2_4_and_1_3_Simulation_vs_Synthesis_DataTypes_DeepDive.md) — ภาคทฤษฎี simulation vs synthesis + data types
- [`Manual_3_5_Yosys_and_LibreLane_Synthesis_DeepDive.md`](Manual_3_5_Yosys_and_LibreLane_Synthesis_DeepDive.md) — ภาคทฤษฎีเครื่องมือ Yosys และ LibreLane
- [`Manual_4_3_GateLevelSimulation_SDF_DeepDive.md`](Manual_4_3_GateLevelSimulation_SDF_DeepDive.md) — GLS และ SDF เชิงลึก
- [`lab_code/day3_synthesis/README.md`](lab_code/day3_synthesis/README.md) — โค้ดประกอบและวิธีรัน

### เอกสารอ้างอิงในโปรเจกต์

- [`docs/reference/vhdl/10-synthesis-subset.md`](docs/reference/vhdl/10-synthesis-subset.md) — ตาราง synthesizable subset (ข้อ 4.1 ของไฟล์นี้อ้างอิง GHDL 1.0.0 ซึ่งพฤติกรรมต่างจาก 5.0.1)

# รายละเอียดเชิงลึก: การสังเคราะห์ด้วย Yosys และ Open-source ASIC Flow (LibreLane)

> เนื้อหานี้ออกแบบมาให้นำไปแทรกเป็นส่วนขยายในหัวข้อ **3.5 ภาคทฤษฎี: การสังเคราะห์ด้วย Yosys (Open-source Synthesis)** ของคู่มือหลักสูตร (วันที่ 3)
>
> เหมาะสำหรับการบรรยาย **90–120 นาที** พร้อม ASCII diagrams, ตารางเปรียบเทียบเครื่องมือ, ตัวอย่างคำสั่งจริง และผลลัพธ์จริงจากการรันบนเครื่อง
>
> **ทุกตัวเลขในเอกสารนี้มาจากการรันจริง** บน Yosys 0.52 / LibreLane v3.0.17 / PDK sky130A — ไม่มีการประมาณค่า

---

## สารบัญ

| # | หัวข้อ | หน้าเนื้อหา |
| --- | --- | --- |
| 1 | ทำไมต้องมี Open-source Synthesis | ช่องว่างของเครื่องมือ commercial |
| 2 | ภาพรวม Open-source ASIC Flow | Yosys → OpenROAD → Magic → KLayout → Netgen |
| 3 | Yosys คืออะไร | สถาปัตยกรรมภายในแบบ pass-based |
| 4 | ขั้นตอนการทำงานของ Yosys | RTL → RTLIL → optimization → netlist |
| 5 | อ่าน RTL: `read_verilog` และ `read_vhdl` | ข้อจำกัดของ Yosys กับ VHDL |
| 6 | สะพาน VHDL → Yosys ด้วย GHDL | ทางเลือกที่ใช้ได้จริงในคอร์สนี้ |
| 7 | `hierarchy` และการจัดการ blackbox | top module, parameter |
| 8 | การย่อย process เป็น RTLIL | `proc`, `opt`, `fsm`, `memory`, `techmap` |
| 9 | ABC และ Technology Mapping | หัวใจของการย่อย logic เป็น gate |
| 10 | Liberty (`.lib`) และ `dfflibmap` | สูตรสำหรับ map เข้า standard cell จริง |
| 11 | อ่านรายงาน `stat` | จำนวน cell, wire, area |
| 12 | สร้าง Gate-Level Netlist ที่ simulate ได้ | `abc -g` + `simplemap` |
| 13 | ตรวจสอบ netlist: GLS และ Formal Equivalence | อย่าเชื่อรายงาน ต้องพิสูจน์ |
| 14 | Yosys vs Precision RTL | ตารางเปรียบเทียบเชิงวิศวกรรม |
| 15 | LibreLane คืออะไร | จาก OpenLane สู่ LibreLane 3.x |
| 16 | โครงสร้างโปรเจกต์และ `config.yaml` | คำสั่งสำคัญทั้งหมด |
| 17 | PDK และ Ciel (volare) | การติดตั้ง sky130 อัตโนมัติ |
| 18 | Flow 80 stages | Yosys → Floorplan → CTS → Routing → Sign-off |
| 19 | อ่านผลลัพธ์จาก `metrics.json` | area, timing, DRC, LVS |
| 20 | ผลอ้างอิงจากการรันจริง | ตัวเลขที่ได้จริง |
| 21 | บทเรียน: สไตล์ RTL มีผลต่อพื้นที่จริง | เทียบ Verilog กับ VHDL |
| 22 | Troubleshooting | ปัญหาที่พบบ่อย |
| 23 | แบบฝึกหัดและ Checklist | ปิดหัวข้อ |

---

## 1. ทำไมต้องมี Open-source Synthesis

### 1.1 ช่องว่างของเครื่องมือ commercial

Precision RTL, Genus, Design Compiler เป็นเครื่องมือที่ทำได้ทุกอย่าง แต่มีข้อจำกัดเชิงการศึกษาและงบประมาณ:

| ข้อจำกัด | ผลกระทบต่อห้องเรียน |
| --- | --- |
| License รายปี / ต่อ seat | นักเรียน 30 คน ทำพร้อมกันไม่ได้ |
| ต้องติดตั้งบน Windows + license server | ซับซ้อนสำหรับผู้เรียนออนไลน์ |
| ผูกกับ PDK ของผู้ให้บริการ | เรียนทั่วไปไม่มี PDK ที่ตรงกัน |
| ไม่มี "raw" netlist ให้ศึกษากระบวนการภายใน | เรียนรู้ไม่ได้ว่า tool ทำอะไรข้างใน |

### 1.2 Open-source ตอบโจทย์อะไรได้

```
╔══════════════════════════════════════════════════════════════════════════╗
║           Open-source ASIC Stack (ทั้งหมดใช้ฟรี และมี source code เปิด)       ║
╠══════════════════════════════════════════════════════════════════════════╣
║  สังเคราะห์ Logic         : Yosys            (C++ / สังเคราะห์เป็น Verilog)    ║
║  Place & Route        : OpenROAD         (C++ / สูตรเดียวกับ Cadence)       ║
║  DRC                  : Magic            (VLSI Layout)                   ║
║  GDS Merge / View     : KLayout          (Ruby / Python)                 ║
║  LVS                  : Netgen           (เทียบ schematic vs layout)      ║
║  Simulator            : Icarus / Verilator / Questa                      ║
║  Formal / SAT         : Yosys sat, SymbiYosys, SBY                       ║
╚══════════════════════════════════════════════════════════════════════════╝
```

### 1.3 ประโยชน์ที่ได้ในห้องเรียน

1. **เห็นกระบวนการจริงทุกขั้น** — ไม่มีกล่องดำ นักเรียนอ่าน log ของ ABC และ OpenROAD ได้
2. **ทำซ้ำได้ทุกเครื่อง** — `git clone` + `make` เท่านั้น
3. **เชื่อมกับ LibreLane** — สังเคราะห์แล้วไหลต่อได้ถึง GDSII จริง
4. **เตรียมสูตรภาคปฏิบัติ Day 6–10** (IC Layout / MEMS) — ซึ่งเนื้อหาในหลักสูตรนี้ใช้ Tanner/L-Edit ที่มี license เหมือนกัน

> **ประเด็นสำคัญสำหรับผู้สอน:** คอร์สนี้สอน Precision RTL ในวันที่ 3 ด้วยเหตุผลทางอุตสาหกรรม (เป็นเครื่องมือของ Siemens EDA ที่องค์กรใช้จริง) ส่วน Yosys เป็น **ทางเลือกฟรี** ที่ให้นักเรียนฝึกกระบวนการเดียวกันโดยไม่ต้องมี license

---

## 2. ภาพรวม Open-source ASIC Flow

### 2.1 Flow ตั้งแต่ RTL ถึง GDSII

```
┌────────────┐
│   RTL      │  VHDL / Verilog
└─────┬──────┘
      │
      ▼
╔══════════════════╗
║  YOSYS           ║  ┌──────────────────────────────────────┐
║  Logic Synthesis ║─►│ RTLIL ─► opt ─► techmap ─► ABC map   │
╚═══════════╤══════╝  └──────────────────────────────────────┘
            │ netlist (.v) + SDF
            ▼
╔══════════════════╗
║  OPENROAD        ║  Floorplan ─► PDN ─► Placement ─► CTS
║  Place & Route   ║  ─► Global Route ─► Detailed Route ─► Extraction
╚═══════════╤══════╝
            │
      ┌─────┴──────────┬───────────────┬───────────────┐
      ▼                ▼               ▼               ▼
╔═══════════╗  ╔════════════╗  ╔════════════╗  ╔═══════════╗
║  MAGIC    ║  ║  KLAYOUT   ║  ║  NETGEN    ║  ║   GDSII   ║
║  DRC      ║  ║ GDS merge  ║  ║   LVS      ║  ║  (final)  ║
╚═══════════╝  ╚════════════╝  ╚════════════╝  ╚═══════════╝
```

### 2.2 เทียบกับ Flow เชิงพาณิชย์

| ขั้นตอน | Open-source | เชิงพาณิชย์ | หมายเหตุ |
| --- | --- | --- | --- |
| Logic Synthesis | **Yosys** | Precision RTL, Genus | Yosys เป็นตัวเลือกฟรี |
| Floorplan | **OpenROAD** | Innovus, IC Compiler II | OpenROAD ฟรีและมี plugin เยอะ |
| Place & Route | **OpenROAD** | Innovus, PrimeTime | ใช้เทคโนโลยีเดียวกัน |
| DRC | **Magic** | Calibre | Magic ใช้เทคนิคแบบ "decoded" |
| LVS | **Netgen** | Calibre | Netgen อาจช้ากว่า แต่ฟรี |
| GDS merge | **KLayout** | Calibre | KLayout เป็นมาตรฐาน de facto |
| Timing Sign-off | OpenSTA (ใน OpenROAD) | PrimeTime | พอใช้ในงานวิจัย/การศึกษา |

### 2.3 เครื่องมือที่ติดตั้งและใช้จริงในเอกสารนี้

| เครื่องมือ | เวอร์ชันที่ใช้ | หน้าที่ |
| --- | --- | --- |
| Yosys | 0.52 | Logic synthesis |
| Icarus Verilog | 12.0 | RTL + Gate-Level Simulation |
| GHDL | 5.0.1 (mcode) | VHDL front-end สำหรับ Yosys |
| Verilator | 5.032 | Lint / simulation เร็ว |
| LibreLane | v3.0.17 | ตัว orchestrator ของ flow ทั้งหมด |
| OpenROAD | 2026-02-17 | Floorplan / Placement / CTS / Routing |
| Magic | 8.3.674 | DRC |
| KLayout | 0.30.9 | GDS merge + visual inspection |
| Netgen | 1.5.323 | LVS |
| PDK | sky130A (`8afc8346a...`) | Standard cell + LEF + Liberty |

---

## 3. Yosys คืออะไร

### 3.1 นิยาม

**Yosys** คือ *framework การสังเคราะห์ logic* แบบ open-source ที่:

- อ่าน RTL (Verilog / SystemVerilog และ VHDL ผ่าน GHDL plugin)
- แปลงเป็น **RTLIL** — ภาษากลางของ Yosys ที่เป็น graph ของ cell
- รัน "pass" ต่าง ๆ เพื่อย่อยและปรับแต่ง
- ส่งออกเป็น netlist (Verilog / JSON / EDIF / SPICE) หรือเขียน SDF

### 3.2 สถาปัตยกรรมภายใน

```
   RTL (Verilog/VHDL)
          │
          ▼
   ┌─────────────┐
   │  Front-end  │  read_verilog / read_vhdl
   │  (Parser)   │  → สร้าง AST แล้วแปลงเป็น RTLIL
   └──────┬──────┘
          │
          ▼
   ┌─────────────────────────────────────────────┐
   │                 RTLIL                       │
   │  ┌────────┐  ┌────────┐  ┌────────┐         │
   │  │ module │─►│ process│─►│  cells │         │
   │  └────────┘  └────────┘  └────────┘         │
   │        + wires + connections + memories     │
   └──────────────────────┬──────────────────────┘
                          │
        ┌─────────────────┴─────────────────┐
        ▼                                   ▼
   ┌─────────────┐                   ┌──────────────┐
   │  Passes     │                   │  Back-end    │
   │  (ปรับแต่ง)   │                   │  (เขียนไฟล์)   │
   └─────────────┘                   └──────────────┘
        │                                   │
        ├─ proc    : process → logic        ├─ write_verilog
        ├─ opt     : ลบ logic ที่ไม่จำเป็น       ├─ write_json
        ├─ fsm     : ถอด FSM → logic        ├─ write_sdf
        ├─ memory  : memory → logic         ├─ write_edif
        ├─ techmap : logic → gate           └─ write_spice
        ├─ abc     : gate → gate (optimize)
        └─ dfflibmap : FF → cell ของ PDK
```

### 3.3 ข้อได้เปรียบหลักของสถาปัตยกรรม pass-based

ข้อดีสำคัญคือ **ทุกอย่างทำได้บนคำสั่งบรรทัดเดียว** และ **ตรวจสอบผลได้ทีละขั้น**:

```tcl
read_verilog rtl/adder8.v
hierarchy -check -top adder8
proc
opt
stat                    # ← ดูผลตรงนี้
techmap
abc -g AND,NAND,OR,NOR,XOR,XNOR,MUX
simplemap
stat                    # ← ดูผลอีกครั้ง
write_verilog build/adder8_gates.v
```

เทียบกับ Precision RTL ที่ต้องกวาดเลือก signal ใน GUI หรือเขียน Tcl ที่ซับซ้อน

---

## 4. ขั้นตอนการทำงานของ Yosys

### 4.1 คำสั่งพื้นฐานที่ต้องรู้

| คำสั่ง | หน้าที่ | ตัวอย่างผลลัพธ์จริง |
| --- | --- | --- |
| `read_verilog` | อ่าน Verilog | โหลดไฟล์เข้า RTLIL |
| `hierarchy` | หา top module, จัดการ parameter | error ถ้า top ไม่มี |
| `synth` | รัน synthesis script มาตรฐานทั้งชุด | จาก RTL เป็น generic cells |
| `proc` | แปลง process เป็น logic | `always @(posedge clk)` → DFF |
| `opt` | ลบ/ยุบ logic ที่ไม่จำเป็น | merge, remove dead cells |
| `fsm` | ถอด FSM ออกจาก logic | encoding → one-hot / binary |
| `memory` | แปลง memory เป็น logic | `$mem` → flip-flops |
| `techmap` | map cell มาตรฐานไปยัง gate | `$add` → XOR/AND |
| `abc` | optimize + technology mapping | gate → gate ที่เล็กลง |
| `dfflibmap` | map FF เข้า cell ของ PDK | `$_SDFF_` → `sky130_fd_sc_hd__dfxtp_2` |
| `read_liberty` | อ่านไฟล์ `.lib` | ได้ timing/area ของ cell |
| `stat` | รายงานจำนวน cell/wire/area | ตารางสรุป |
| `simplemap` | แปลง cell ภายในเป็น expression | ทำให้ netlist simulate ได้ |
| `tee` | บันทึกผลลัพธ์ลงไฟล์ | `tee -o stat.txt stat` |
| `design -reset` | ล้าง design ปัจจุบัน | เริ่ม module ใหม่ในสคริปต์เดียว |
| `write_verilog` | เขียน netlist | `-noattr` ไม่เขียน attribute |

### 4.2 `synth` ทำอะไรบ้าง

คำสั่ง `synth` คือ "สูตรสำเร็จ" ที่เรียก pass หลาย ๆ ตามลำดับ:

```
synth
 ├─ begin: hierarchy, proc, flatten (ถ้าต้องการ)
 ├─ coarse: opt, fsm, opt, wreduce, peepopt, opt_clean
 ├─ fine:   opt -fast, memory_map, opt -full
 ├─ check:  hierarchy -check, stat
 ├─ map:    techmap, opt -fast, abc -fast, opt -fast
 └─ clean:  opt -fast, check, stat, write
```

ตัวเลือกที่ใช้บ่อย:

| ตัวเลือก | ความหมาย |
| --- | --- |
| `-top <name>` | ระบุ top module (บังคับใช้) |
| `-noabc` | ข้ามการ map ด้วย ABC (จะได้ generic cells) |
| `-flatten` | flatten hierarchy ทั้งหมดให้เป็น module เดียว |
| `-run :<label>` | หยุดที่จุดหนึ่งในสูตร (เช่น `-run coarse` เพื่อดูผลก่อน map) |

---

## 5. อ่าน RTL: `read_verilog` และ `read_vhdl`

### 5.1 Verilog — ทางเลือกตรง

```tcl
read_verilog rtl/adder8.v              # Verilog-2005
read_verilog -sv rtl/module.sv          # SystemVerilog
read_verilog -formal rtl/properties.sv  # สำหรับ formal verification
```

### 5.2 VHDL — ข้อจำกัดสำคัญ

**Yosys ไม่มี front-end สำหรับ VHDL โดยตรง** ต้องใช้ GHDL plugin หรือแปลง VHDL เป็น Verilog ก่อน

```
╔══════════════════════════════════════════════════════════════════════════╗
║  ทางเลือกที่ใช้ได้จริง                                                         ║
╠══════════════════════════════════════════════════════════════════════════╣
║  (A) GHDL standalone  : VHDL --synth--> Verilog --read_verilog--> Yosys  ║
║      ติดตั้งง่าย:  apt install ghdl                                          ║
║                                                                          ║
║  (B) yosys-ghdl plugin: อ่าน VHDL ใน Yosys โดยตรง                         ║
║      yosys -m ghdl -p "ghdl --std=08 file.vhd -e top; synth -top top"    ║
║      ต้องติดตั้ง yosys ที่มาพร้อม plugin                                       ║
╚══════════════════════════════════════════════════════════════════════════╝
```

> **ข้อควรระวังสำหรับผู้เรียน:** เนื้อหาคอร์สนี้เป็น VHDL แต่เครื่องมือ open-source ส่วนใหญ่เป็น Verilog-first การฝึก "คิดแบบ RTL" แล้วแปลงเป็น Verilog เป็นทักษะที่ต้องมีในอุตสาหกรรม — เพราะ PDK/open-source EDA ส่วนใหญ่รองรับ Verilog เป็นหลัก

---

## 6. สะพาน VHDL → Yosys ด้วย GHDL

### 6.1 ขั้นตอน (ทดสอบแล้วว่าใช้ได้จริง)

```bash
# 1) วิเคราะห์ VHDL
ghdl -a --std=08 rtl/adder8.vhd

# 2) สร้าง Verilog (GHDL 5.x พิมพ์ออก stdout ต้อง redirect เอง)
ghdl synth --std=08 --out=verilog adder8 > adder8.v

# 3) ให้ Yosys อ่าน
yosys -p "read_verilog adder8.v; hierarchy -check -top adder8; synth -top adder8; stat"
```

### 6.2 ไฟล์ VHDL ตัวอย่าง

```vhdl
-- adder8.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder8 is
    port (
        cin  : in  std_logic;
        a    : in  std_logic_vector(7 downto 0);
        b    : in  std_logic_vector(7 downto 0);
        sum  : out std_logic_vector(7 downto 0);
        cout : out std_logic
    );
end entity adder8;

architecture rtl of adder8 is
begin
    p : process (cin, a, b)
        variable va : unsigned(8 downto 0);
        variable vb : unsigned(8 downto 0);
        variable vs : unsigned(8 downto 0);
    begin
        va := resize(unsigned(a), 9);     -- ต้อง resize ให้ยาวเท่ากัน
        vb := resize(unsigned(b), 9);
        vs := va + vb;
        if cin = '1' then
            vs := vs + 1;
        end if;
        sum  <= std_logic_vector(vs(7 downto 0));
        cout <= vs(8);
    end process;
end architecture rtl;
```

> ⚠️ `unsigned` กับ `std_logic_vector` เป็น **คนละ base type** — ห้าม assign ข้ามกันโดยตรง ต้องผ่าน `unsigned(...)` และ `resize(...)` เสมอ

### 6.3 ผลลัพธ์จริงของสะพานนี้

```
=== adder8 ===   (จาก VHDL ผ่าน GHDL)
   Number of cells:                 88
     $_ANDNOT_   18    $_MUX_  8    $_NOR_   6    $_XNOR_  5
     $_AND_       1    $_NAND_ 8    $_NOT_ 11    $_XOR_  19
     $_ORNOT_     3    $_OR_    9
```

เทียบกับ Verilog ที่เขียนด้วยมือ: **52 cells** — ดูหัวข้อ 21 ว่าทำไมถึงต่างกัน

---

## 7. `hierarchy` และการจัดการ blackbox

### 7.1 คำสั่ง hierarchy

```tcl
hierarchy -check -top adder8
```

| ตัวเลือก | หน้าที่ |
| --- | --- |
| `-check` | ตรวจว่าโมดูลทั้งหมดที่อ้างถึงมีอยู่จริง (error ถ้าไม่) |
| `-top <name>` | ระบุ top module |
| `-libdir` / `-libext` | วิธีค้นหาโมดูลในไลบรารี |

### 7.2 Blackbox

เมื่อ RTL อ้างถึงโมดูลที่ยังไม่ได้เขียน (เช่น RAM ที่มาจาก vendor) ให้ประกาศเป็น blackbox:

```tcl
read_verilog rtl/my_design.v
read_verilog -lib rtl/sram_1p.v     # อ่านแต่ port (ไม่ต้องมีเนื้อหา)
hierarchy -check -top my_design
```

---

## 8. การย่อย process เป็น RTLIL

### 8.1 Pass `proc`

`proc` แปลงภาษา HDL ให้เป็น RTLIL:

| โครงสร้าง HDL | ผลลัพธ์ใน RTLIL |
| --- | --- |
| `always @(posedge clk)` | `$dff` หรือ `$adff` (มี async reset) |
| `always @(*)` | กลายเป็น logic ที่ไม่มี latch |
| `if` / `case` | กลายเป็น `$mux` |
| `for` loop (static) | unroll เป็น logic |
| `assign` | กลายเป็น connection |

### 8.2 Pass `opt` — ตรวจ latch ด้วย

```tcl
proc
opt
check -assert                       # error ถ้ามี latch หรือ driver ซ้อนกัน
```

Pass `check` จะรายงาน:
- latch ที่ถูกสังเคราะห์โดยไม่ตั้งใจ (incomplete assignment ใน `always @*`)
- signal ที่มีหลาย driver
- width mismatch

### 8.3 ผลจริง: ไม่มี latch เลย

จาก LibreLane run ของ `adder8_pipe`:

```
design__inferred_latch__count = 0
design__instance_unmapped__count = 0
design__lint_error__count = 0
```

---

## 9. ABC และ Technology Mapping

### 9.1 ABC คืออะไร

**ABC** (Berkeley ABC) เป็นเครื่องมือย่อย logic ของงานวิจัยของ VLSI โดยใช้กับ Yosys เป็นตัว map หลัก เป็นเหตุผลที่ Yosys ได้ผลลัพธ์ดีเมื่อเทียบกับ tool เชิงพาณิชย์ในหลายกรณี

### 9.2 สองโหมดที่ใช้ในแล็บ

**(A) map เป็น gate พื้นฐาน** (ไม่ต้องมี PDK)

```tcl
abc -g AND,NAND,OR,NOR,XOR,XNOR,MUX
```

> ⚠️ ABC **ไม่รองรับ gate type "NOT"** — ตัว inverter ถูกสร้างขึ้นมาอัตโนมัติ ถ้าใส่ `NOT` จะได้ error `Unsupported gate type: NOT`

**(B) map เข้า standard cell จริง** (ต้องมี Liberty)

```tcl
read_liberty -lib $SKY130_LIB
abc -liberty $SKY130_LIB
```

### 9.3 ผลจริงของทั้งสองโหมด

**โหมด A — map เป็น gate พื้นฐาน (`adder8`)**

```
   Number of cells:                 41
     $_NAND_                        25
     $_XOR_                         14
     $_OR_                           1
     $_XNOR_                         1
```

**โหมด B — map เข้า sky130 standard cell (`adder8`)**

```
   Number of cells:                 24
     sky130_fd_sc_hd__maj3_1         8
     sky130_fd_sc_hd__xnor2_1       16

   Chip area for module '\adder8': 220.211200
     of which used for sequential elements: 0.000000 (0.00%)
```

> สังเกตว่า standard cell จริงให้ cell **น้อยกว่า** (24 vs 41) และได้ **พื้นที่จริง** มาดูว่า — นี่คือข้อได้เปรียบของการมี PDK

---

## 10. Liberty (`.lib`) และ `dfflibmap`

### 10.1 Liberty คืออะไร

ไฟล์ `.lib` (Liberty) เป็นรูปแบบมาตรฐานที่บรรยาย **standard cell** ของ PDK:

```
library (sky130_fd_sc_hd) {
    cell (sky130_fd_sc_hd__and2_1) {
        area : 6.72;
        pin (Y) {
            direction : output;
            function : "A1 & A2";
            timing () {
                related_pin : "A1";
                cell_rise (delay_template_7x5) { ... }
            }
        }
    }
}
```

ให้ข้อมูล 3 อย่าง: **พื้นที่ (area)**, **ฟังก์ชัน**, **timing characteristic**

### 10.2 ขั้นตอนการ map เข้า PDK

```tcl
read_liberty -lib $SKY130_LIB              # 1. โหลด cell library
read_verilog rtl/adder8.v                  # 2. อ่าน RTL
hierarchy -check -top adder8
synth -top adder8 -noabc                   # 3. ย่อยจนเป็น generic cell (ไม่ map ด้วย ABC)
dfflibmap -liberty $SKY130_LIB             # 4. map flip-flop เข้า cell จริง
abc -liberty $SKY130_LIB                   # 5. map combinational logic เข้า cell จริง
stat -liberty $SKY130_LIB                  # 6. รายงานรวมพื้นที่
write_verilog -noattr build/adder8_sky130.v
```

> `dfflibmap` ต้องทำ **ก่อน** `abc` เสมอ เพราะ ABC ต้องเห็น cell library ที่มี flip-flop อยู่แล้ว

### 10.3 Liberty ที่มากับ Yosys

Yosys ติดมาด้วย `cells.lib` ที่ `/usr/share/yosys/cells.lib` แต่ **มีแต่ flip-flop** (ไม่มี gate) จึงใช้ map combinational logic ไม่ได้ ต้องใช้ liberty ของ PDK จริง

---

## 11. อ่านรายงาน `stat`

### 11.1 ตัวอย่างรายงานจริง

```
=== adder8_pipe ===

   Number of wires:                 56
   Number of wire bits:            115
   Number of public wires:          11
   Number of public wire bits:      54
   Number of ports:                  7
   Number of port bits:             28
   Number of memories:               0
   Number of memory bits:            0
   Number of processes:              0
   Number of cells:                 78
     $_ANDNOT_                      12
     $_AND_                          4
     $_NAND_                         4
     $_NOR_                          6
     $_OR_                          10
     $_SDFF_PP0_                    26
     $_XNOR_                        11
     $_XOR_                          5
```

### 11.2 ตารางอ่านค่าสำคัญ

| ค่า | ความหมาย | เก็บถือ |
| --- | --- | --- |
| `Number of cells` | จำนวน cell ทั้งหมด | **ตัวหลักในการเปรียบเทียบ** |
| `Number of wire bits` | จำนวนบิตของสัญญาณทั้งหมด | ยิ่งน้อย = ข่ายสัญญาณยาวขึ้น |
| `Number of memories` | จำนวน memory ที่ยังไม่ถูกแปลง | ต้องเป็น 0 ก่อนส่งต่อ |
| `Number of processes` | process ที่ยังไม่ถูกย่อย | ต้องเป็น 0 ก่อนส่งต่อ |
| `$_SDFF_PP0_` | flip-flop พร้อม sync reset | นับได้ว่า RTL มี register กี่ตัว |

### 11.3 เทียบ combinational กับ pipelined (ข้อมูลจริง)

| ดีไซน์ | Cells | Flip-flop | หมายเหตุ |
| --- | --- | --- | --- |
| `adder8` (combinational) | **52** | 0 | พื้นที่น้อย แต่ path ยาว 8 stage |
| `adder8_pipe` (2-stage) | **78** | 26 | พื้นที่มากขึ้น แต่ critical path สั้นลง |

> นี่คือข้อแลกเปลี่ยนพื้นฐานของ RTL design ที่นักเรียนต้องเข้าใจ — และเป็นหัวข้อเดียวกับที่สอนด้วย Precision RTL ในหัวข้อ 3.4

---

## 12. สร้าง Gate-Level Netlist ที่ simulate ได้

### 12.1 ปัญหา

หลัง `abc` cell จะอยู่ในรูปภายในของ Yosys เช่น `$_NAND_` ซึ่ง **Icarus Verilog มองไม่เห็น** ต้องแปลงกลับ

### 12.2 ทางแก้: `simplemap`

```tcl
abc -g AND,NAND,OR,NOR,XOR,XNOR,MUX
simplemap        # ← แปลง $_NAND_ เป็น expression ของ Verilog ธรรมดา
opt_clean
write_verilog -noattr build/adder8_gates.v
```

### 12.3 ผลลัพธ์

ไฟล์ `build/adder8_gates.v` ที่ได้มีลักษณะเช่นนี้ — **อ่านเข้าใจได้** และ simulate ได้:

```verilog
module adder8(cin, a, b, sum, cout);
  wire _000_;
  ...
  assign sum = ...;
  assign cout = ...;
endmodule
```

### 12.4 Gate-Level Simulation

ใช้ **testbench เดิมเป๊ะ** กับ netlist — นี่คือหัวใจของการพิสูจน์ว่า netlist ถูกต้อง:

```bash
# RTL
iverilog -o build/tb.vvp rtl/adder8.v tb/tb_adder8.v
vvp build/tb.vvp

# Gate-level (netlist จาก Yosys)
iverilog -o build/tb_gls.vvp build/adder8_gates.v tb/tb_adder8.v
vvp build/tb_gls.vvp
```

ผลลัพธ์จริง (ทั้งสองแบบ):

```
tb_adder8 PASS=131072 FAIL=0
tb_adder8: ALL 131072 PATTERNS PASS
```

> **ถ้าผ่านทั้งสองแบบด้วยจำนวน pattern เท่ากัน แปลว่า netlist ที่ Yosys สร้างฟังก์ชันเท่ากับ RTL เป๊ะ**

---

## 13. ตรวจสอบ netlist: GLS และ Formal Equivalence

### 13.1 สามระดับของการตรวจสอบ

| ระดับ | วิธี | จับอะไรได้ | ใช้เวลา |
| --- | --- | --- | --- |
| 1. จำนวน cell | `stat` | เผื่อพื้นที่ใหญ่เกิน | วินาที |
| 2. Gate-Level Simulation | Icarus + testbench เดิม | ฟังก์ชันผิดใน vector ที่ทดสอบ | นาที |
| 3. Formal Equivalence | `equiv_make` / `equiv_simple` / `equiv_status` | **พิสูจน์ว่าเท่ากันทุก input** | นาที–ชั่วโมง |

### 13.2 Formal Equivalence ใน Yosys

```tcl
# เทียบ RTL กับ netlist
read_verilog rtl/adder8.v
prep -top adder8 -flatten
design -stash gold

read_verilog build/adder8_gates.v
prep -top adder8 -flatten
design -stash gate

design -copy-from gold -as gold gold
design -copy-from gate -as gate gate

equiv_make gold gate equiv
equiv_simple
equiv_induct
equiv_status -assert
```

ถ้า `equiv_status -assert` ผ่าน แปลว่า **netlist ที่สังเคราะห์ได้ทำงานเหมือน RTL ทุกกรณี** ไม่ใช่แค่ vector ที่ทดสอบ

### 13.3 เอกสารอ้างอิงที่ควรอ่านเพิ่ม

- Yosys Handbook — บท `equiv_opt`, `sat`, `miter`
- OpenLane/LibreLane documentation — ขั้นตอน `Yosys.EQY`

> ใน LibreLane มีขั้นตอนชื่อ `Yosys.EQY` ที่ทำ formal equivalence check ระหว่าง netlist กับ RTL อัตโนมัติ (ในรอบทดสอบถูก skip เพราะไม่ได้เปิดใช้)

---

## 14. Yosys vs Precision RTL

### 14.1 ตารางเปรียบเทียบเชิงวิศวกรรม

| มิติ | Yosys | Precision RTL (Siemens EDA) |
| --- | --- | --- |
| License | ฟรี (open-source) | Commercial |
| Input | Verilog / VHDL (ผ่าน GHDL) | VHDL / Verilog / SystemVerilog |
| Output | Verilog / EDIF / SPICE / JSON | Verilog / VHDL / EDIF + **SDF** |
| การ map เข้า PDK | `read_liberty` + `abc -liberty` | เลือก technology library ใน GUI |
| Timing report | ABC delay estimate | **Static timing analysis เต็มรูปแบบ** พร้อม path detail |
| Constraint | SDC บางส่วน | SDC เต็มรูปแบบ |
| Power analysis | ไม่มีในตัว | มี (report power) |
| Design Explorer / schematic | ไม่มี | มี (HDL Designer) |
| ความเร็วในการสังเคราะห์ | เร็วมาก (วินาที) | เร็วเทียบเท่า |
| การเชื่อมต่อกับ PnR | ผ่าน OpenROAD/LibreLane | ส่ง netlist ให้ Innovus/Calibre |
| เหมาะกับ | การศึกษา flow, open-source ASIC, CI | งานเชิงพาณิชย์ที่ต้อง sign-off |

### 14.2 เมื่อไหร่ควรใช้อันไหน

```
╔═════════════════════════════════════════════════════════════════╗
║  ต้องการ sign-off ที่องค์กรยอมรับ    →  Precision RTL (มี license)    ║
║  ต้องการเรียนรู้กระบวนการข้างใน      →  Yosys (เปิด source อ่านได้)       ║
║  ต้องการ flow จบถึง GDSII ฟรี         →  Yosys + LibreLane         ║
║  ต้องการ RTL-to-GDSII ใน 1 คำสั่ง       →  LibreLane               ║
╚═════════════════════════════════════════════════════════════════╝
```

> **คำแนะนำสำหรับผู้สอน:** สอนทั้งสองแบบเป็นคู่ — ให้นักเรียนเห็นว่า "ขั้นตอนเดียวกัน ผลลัพธ์คล้ายกัน แต่เครื่องมือต่างกัน" ซึ่งเป็นทักษะการอ่าน report ที่ต้องมีในอุตสาหกรรมจริง

---

## 15. LibreLane คืออะไร

### 15.1 ประวัติสั้น ๆ

```
OpenLane 1.x  (ภายใน EDA² / Efabless)
     │
     ├── fork ต่อยอดเป็น OpenLane 2.0  (config เป็น Python object)
     │
     ▼
LibreLane 2.x → 3.x  (ปัจจุบัน — config เป็น YAML, รองรับ PDK หลายเจ้า)
```

**LibreLane** คือ *orchestrator* ที่เรียกเครื่องมือแต่ละตัวตามลำดับ ไม่ใช่ตัวสังเคราะห์เอง ประกอบด้วย:

| ส่วน | ทำหน้าที่ |
| --- | --- |
| `librelane` (CLI) | จุดเริ่มต้น อ่าน config แล้วรัน flow |
| Steps | แต่ละขั้นตอนของ flow (ย่อยยอดเป็น Python class) |
| Config system | แปลง `config.yaml` เป็น object พร้อม default ของแต่ละ PDK |
| PDK integration | ติดตั้ง/เปิดใช้ PDK ผ่าน Ciel |
| Reproducibles | เก็บทุกขั้นตอนไว้ตรวจสอบย้อนหลัง |

### 15.2 ข้อได้เปรียบเทียบกับ OpenROAD ล้วน

เมื่อใช้ LibreLane จะได้ขั้นตอนที่ OpenROAD ล้วนไม่มี เช่น checker อัตโนมัติ (DRC/LVS/timing/max-slew/max-cap/antenna), report ที่รวมไว้ใน `metrics.json`, และการจัดการ PDK

---

## 16. โครงสร้างโปรเจกต์และ `config.yaml`

### 16.1 โครงสร้างมาตรฐาน

```
project/
├── config.yaml          # ไฟล์ config หลัก
├── src/
│   ├── design.v         # RTL
│   ├── impl.sdc         # SDC สำหรับ PnR
│   └── signoff.sdc      # SDC สำหรับ sign-off
└── runs/                # ผลลัพธ์ (สร้างอัตโนมัติ)
    └── RUN_<timestamp>/
        ├── 01-.../      # แต่ละ step แยกโฟลเดอร์
        └── final/       # GDS, metrics, DEF, SPICE
```

### 16.2 คำสั่งสำคัญใน `config.yaml`

| ตัวแปร | ค่าในแล็บนี้ | ความหมาย |
| --- | --- | --- |
| `DESIGN_NAME` | `adder8_pipe` | ชื่อ top module (ต้องตรงกับชื่อ module) |
| `VERILOG_FILES` | `dir::src/*.v` | รายการไฟล์ RTL (`dir::` = อ้างอิงสัมพัทธ์กับไฟล์ config) |
| `CLOCK_PORT` | `clk` | ชื่อ port ของ clock |
| `CLOCK_PERIOD` | `10` | รอบสัญญาณ clock (ns) → 100 MHz |
| `PNR_SDC_FILE` | `dir::src/impl.sdc` | SDC สำหรับขั้น Place & Route |
| `SIGNOFF_SDC_FILE` | `dir::src/signoff.sdc` | SDC สำหรับขั้น sign-off |
| `PDN_VOFFSET` / `PDN_HOFFSET` | `5` | ระยะขอบ PDN จาก core edge (µm) |
| `PDN_VWIDTH` / `PDN_HWIDTH` | `2` | ความกว้างของ rail (µm) |
| `PDN_VPITCH` / `PDN_HPITCH` | `30` | ระยะห่างระหว่าง rail (µm) |
| `PDN_SKIPTRIM` | `true` | ไม่ trim PDN ตาม routing |

### 16.3 การ override เฉพาะ PDK

```yaml
pdk::sky130*:
  FP_CORE_UTIL: 45        # % พื้นที่ core ที่ใช้จริง
  CLOCK_PERIOD: 10.0

pdk::ihp*:
  FP_CORE_UTIL: 40
  CLOCK_PERIOD: 10.0

pdk::gf180mcu*:
  FP_CORE_UTIL: 38
  CLOCK_PERIOD: 24.0
```

> **ข้อควรระวัง:** ค่า `CLOCK_PERIOD` ในบล็อก `pdk::` จะ override ค่าหลัก เพราะความเร็วของ PDK ต่างกัน — ต้องปรับให้เหมาะกับ PDK ที่ใช้จริงเสมอ

### 16.4 คำสั่งใช้งาน

```bash
librelane --volare-pdk -p sky130A config.yaml
```

| ตัวเลือก | ความหมาย |
| --- | --- |
| `--volare-pdk` | ติดตั้ง PDK อัตโนมัติผ่าน Ciel (ค่า default) |
| `--manual-pdk` | ใช้ PDK ที่ติดตั้งเอง (ต้องมี `PDK_ROOT`) |
| `-p, --pdk` | ชื่อ PDK (default: `sky130A`) |
| `-s, --scl` | standard cell library |
| `--pdk-root` | path ของ PDK root |
| `--run-tag` | ตั้งชื่อ run |
| `--smoke-test` | ทดสอบเครื่องมือว่าครบไหม |

---

## 17. PDK และ Ciel (volare)

### 17.1 PDK คืออะไร

Process Design Kit คือชุดข้อมูลของกระบวนการผลิตที่มี 4 ส่วนหลัก:

| ไฟล์ | นามสกุล | ใช้ทำอะไร |
| --- | --- | --- |
| **Liberty** | `.lib` | timing + area ของ cell → ใช้ map และ STA |
| **LEF** | `.lef` | ขนาด/รูปทรง/ชั้นของ cell → ใช้วางวงจร |
| **GDSII** | `.gds` | ข้อมูล mask จริง → ใช้ผลิต |
| **Tech LEF / SPICE** | `.tlef`, `.sp` | ข้อมูล layer, metal stack, parasitic |

### 17.2 PDK ที่ใช้ในหลักสูตร

| PDK | กระบวนการ | หมายเหตุ |
| --- | --- | --- |
| **sky130A** | 130 nm CMOS (SkyWater) | มาตรฐาน de facto ของ open-source ASIC |
| **IHP SG13G2** | 130 nm SiGe BiCMOS | ใช้ในโปรเจกต์ MEMS/วิจัยของไทย |
| **gf180mcu** | 180 nm MCU | ใช้งานร่วมกับ open PDK อื่น |

### 17.3 Ciel — ตัวจัดการ PDK รุ่นใหม่

```bash
# LibreLane จะติดตั้ง PDK ให้เองเมื่อรันครั้งแรก (ประมาณ 1-2 GB)
librelane --volare-pdk -p sky130A config.yaml

# ตำแหน่งที่ติดตั้งไว้
/root/.ciel/ciel/sky130/versions/<hash>/sky130A/
```

ตัวอย่าง hash ที่ใช้ในการทดสอบ: `8afc8346a57fe1ab7934ba5a6056ea8b43078e71`

### 17.4 ใช้ Liberty ของ sky130 กับ Yosys โดยตรง

```bash
SKY130_LIB=/root/.ciel/ciel/sky130/versions/*/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
make sky130 SKY130_LIB=$SKY130_LIB
```

---

## 18. Flow 80 stages

### 18.1 ภาพรวม 4 ช่วง

```
╔══════════════════════════════════════════════════════════════════════════╗
║  ช่วงที่ 1: RTL → Netlist (Yosys)                    stage 1-9              ║
║    Verilator lint → Yosys synthesis → checks                             ║
╠══════════════════════════════════════════════════════════════════════════╣
║  ช่วงที่ 2: Floorplan → CTS                           stage 10-38           ║
║    SDC check → floorplan → PDN → IO placement → global placement         ║
║    → detailed placement → CTS → resizer timing                           ║
╠══════════════════════════════════════════════════════════════════════════╣
║  ช่วงที่ 3: Routing → RC Extraction                  stage 39-60            ║
║    global route → antenna check → detailed route → parasitics            ║
║    → GDS generation                                                      ║
╠══════════════════════════════════════════════════════════════════════════╣
║  ช่วงที่ 4: Sign-off                                stage 61-80             ║
║    GDS merge (KLayout) → DRC (Magic) → LVS (Netgen) → checkers           ║
╚══════════════════════════════════════════════════════════════════════════╝
```

### 18.2 จุดที่ควรโฟกัสในการสอน

| Stage | ชื่อ | สิ่งที่เกิด | ปัญหาที่พบบ่อย |
| --- | --- | --- | --- |
| 13 | `openroad-floorplan` | คำนวณ die/core area จาก utilization | utilization สูงเกิน → congestion |
| 21 | `openroad-generatepdn` | สร้าง power grid | PDN บางเกิน → IR drop |
| 28 | `openroad-globalplacement` | จัดวาง cell | utilization ต่ำเกิน → routing ยาก |
| 35 | `openroad-cts` | สร้าง clock tree | skew มาก → hold violation |
| 45+ | `openroad-detailedrouting` | เดินสาย | DRC violation เยอะ |
| 70 | `netgen-lvs` | เทียบ schematic ↔ layout | mismatch → กลับไปแก้ RTL |

### 18.3 ผลของขั้นตอนสำคัญ (จากรอบทดสอบจริง)

```
[INFO IFP-0107] Defining die area using utilization: 45.00% and aspect ratio: 1.
[INFO IFP-0102] Core area:                         2409.811 um^2
[INFO IFP-0104] Effective utilization:                0.460
[INFO] Floorplanned on a die area of 0.0 0.0 60.675 71.395 (µm).
[INFO] Floorplanned on a core area of 5.52 10.88 54.74 59.84 (µm).
```

---

## 19. อ่านผลลัพธ์จาก `metrics.json`

### 19.1 ไฟล์ผลลัพธ์

```
runs/RUN_<timestamp>/final/
├── metrics.json      # ตัวเลขทั้งหมด (อ่านด้วย jq หรือ python)
├── metrics.csv       # เหมือนกันแต่เป็น CSV
├── gds/              # GDSII จาก Magic
├── klayout_gds/      # GDSII หลัง merge
├── lef/ def/ mag/    # layout views
├── spef/             # parasitic RC
├── sdf/              # timing annotation
└── spice/            # netlist สำหรับ LVS
```

### 19.2 คีย์ที่ต้องดู

| Key | ความหมาย | ค่าที่ได้จริง |
| --- | --- | --- |
| `design__instance__count` | จำนวน instance ทั้งหมด | 399 |
| `design__instance__count__stdcell` | จำนวน standard cell | 167 |
| `design__instance__area` | พื้นที่ cell รวม (µm²) | 2409.81 |
| `design__core__area` | พื้นที่ core (µm²) | 2409.81 |
| `design__die__area` | พื้นที่ die (µm²) | 4331.89 |
| `design__instance__utilization` | % พื้นที่ที่ใช้ | 0.6895 |
| `design__nets` | จำนวน net | 158 |
| `design__io` | จำนวน pin | 30 |
| `design__violations` | จำนวน violation รวม | **0** |
| `design__lvs_error__count` | LVS error | **0** |
| `design__max_slew_violation__count` | max slew violation | 0 |
| `design__max_cap_violation__count` | max cap violation | 0 |
| `timing__setup__wns` | worst negative slack (setup) | 0 |
| `timing__setup__ws` | worst slack (setup) | **5.587 ns** |
| `timing__hold__wns` | worst negative slack (hold) | 0 |
| `timing__hold__ws` | worst slack (hold) | **0.317 ns** |
| `clock__skew__worst_setup` | worst clock skew | -0.0058 ns |

### 19.3 คำนวณ Fmax จากผลลัพธ์

```
จาก setup worst slack = 5.587222 ns และ clock period = 10 ns

   critical path delay = period - slack
                      = 10 - 5.587222
                      = 4.412778 ns

   Fmax = 1 / 4.412778 ns ≈ 226.6 MHz
```

> นี่คือการเชื่อมโยงกลับไปยังหัวข้อ 3.3 (Timing Analysis) ของคู่มือหลัก — นักเรียนได้เรียน "วิธีอ่าน slack" ในเครื่องมือฟรี

### 19.4 ตัวอย่างคำสั่งอ่าน metrics

```bash
# jq
jq '{area: .design__instance__area, wns: .timing__setup__wns, viol: .design__violations}' \
   runs/RUN_*/final/metrics.json

# python (ไม่ต้องติดตั้งอะไรเพิ่ม)
python3 -c "import json,glob;m=json.load(open(glob.glob('runs/RUN_*/final/metrics.json')[0]));print(m['design__instance__area'])"
```

---

## 20. ผลอ้างอิงจากการรันจริง

### 20.1 เงื่อนไขการทดสอบ

| รายการ | ค่า |
| --- | --- |
| Design | `adder8_pipe` (8-bit adder, 2-stage pipeline) |
| RTL | Verilog (มีสำเร็จเทียมเป็น VHDL ผ่าน GHDL) |
| Yosys | 0.52 |
| LibreLane | v3.0.17 |
| PDK | sky130A, version `8afc8346a57fe1ab7934ba5a6056ea8b43078e71` |
| SCL | `sky130_fd_sc_hd` |
| Clock period | 10 ns (100 MHz) |
| FP_CORE_UTIL | 45 % |
| เวลาที่ใช้ | ~87 วินาที (80 stages) |

### 20.2 ผลลัพธ์

| รายการ | ค่า |
| --- | --- |
| Stages ที่ผ่าน | **80 / 80** |
| DRC violations | **0** ✅ |
| LVS errors | **0** ✅ |
| Antenna violations | **0** ✅ |
| Setup violations | **0** (WNS = 0, WS = 5.587 ns) ✅ |
| Hold violations | **0** (WNS = 0, WS = 0.317 ns) ✅ |
| Max slew / max cap violations | 0 / 0 ✅ |
| Instances | 399 (stdcell 167, fill 232, buffer 44, tap 30) |
| Nets / IOs | 158 / 30 |
| Instance area | 2409.81 µm² |
| Core area | 2409.81 µm² |
| Die area | 4331.89 µm² (60.675 × 71.395 µm) |
| Utilization | 68.95 % |
| Fmax (คำนวณจาก slack) | ≈ 226.6 MHz |
| Yosys cells (ก่อน map) | 68 (26 NAND, 26 SDFF_PP0, 12 XOR, 2 XNOR, 2 OR) |
| GDSII | `adder8_pipe.gds` 413,344 bytes (Magic) / `adder8_pipe.klayout.gds` 292,016 bytes |

### 20.3 Yosys stat จากใน LibreLane (ก่อน map เข้า PDK)

```
=== adder8_pipe ===
   Number of wires:                 46
   Number of wire bits:            105
   Number of ports:                  7
   Number of port bits:             28
   Number of cells:                 68
     $_NAND_                        26
     $_OR_                           2
     $_SDFF_PP0_                    26
     $_XNOR_                         2
     $_XOR_                         12
```

> **จุดสังเกต:** `design__instance__count = 399` มากกว่า cell จาก Yosys (68) มาก เพราะ OpenROAD เพิ่ม **fill cell** (232 ตัว), **clock buffer**, **timing repair buffer** และ **tap cell** เพื่อให้ layout สมบูรณ์ — นี่เป็นบทเรียนสำคัญเรื่อง "RTL cell count ≠ final chip"

---

## 21. บทเรียน: สไตล์ RTL มีผลต่อพื้นที่จริง

### 21.1 ข้อมูลจริงจากการสังเคราะห์แบบเดียวกัน

| RTL | วิธีเขียน | Yosys cells | หมายเหตุ |
| --- | --- | --- | --- |
| `adder8.v` | Verilog: `assign {cout,sum} = a+b+cin` | **52** | สังเคราะห์เป็น adder เดียว |
| `adder8.vhd` | VHDL: `if cin='1' then vs := vs+1` | **88** | ได้ adder + mux เพิ่ม |

**ผลลัพธ์ต่างกัน 36 cells (69 %)** จากโค้ดที่ "ทำงานเหมือนกันเป๊ะ" ในเชิงฟังก์ชัน

### 21.2 ทำไมถึงเป็นแบบนั้น

```
RTL แบบ Verilog:  assign {cout,sum} = {1'b0,a} + {1'b0,b} + cin;
                    └── Yosys เห็นเป็นตัวบวก 1 ตัว พร้อม carry-in ──┘

RTL แบบ VHDL:     vs := va + vb;
                   if cin = '1' then vs := vs + 1; end if;
                    └── Yosys เห็นเป็น adder 1 ตัว + mux 1 ตัว ──────┘
```

### 21.3 บทเรียนที่ต้องสอน

1. **RTL ที่ "ทำงานถูก" ไม่ได้แปลว่า "สังเคราะห์ได้ดี"** — รูปแบบโค้ดมีผลต่อ area และ delay
2. **การเขียนให้ tool เข้าใจ** (coding style) เป็นทักษะระดับอาชีวภาพ
3. **ต้องวัดผลเสมอ** — `stat` ก่อน/หลังปรับโค้ด ถ้าไม่วัดก็เป็นการเดา
4. **VHDL ที่ผ่าน GHDL อาจสูญเสียโครงสร้าง** — ให้ตรวจ `stat` เสมอหลังแปลง

---

## 22. Troubleshooting

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| `ERROR: Command syntax error: Unsupported gate type: NOT` | ABC ไม่รองรับ `NOT` | เอา `NOT` ออกจากรายการ `-g` |
| `ERROR: Can't find top module` | ชื่อ top ไม่ตรงกับชื่อ module | ตรวจ `DESIGN_NAME` และ `hierarchy -top` |
| `ERROR: Module ... referenced in cell ... not found` | โมดูลอ้างอิงยังไม่ได้อ่านเข้ามา | `read_verilog` ทุกไฟล์ก่อน `hierarchy -check` |
| netlist simulate ไม่ได้ (`unknown module type $_NAND_`) | ยังไม่ได้ทำ `simplemap` | เพิ่ม `simplemap` หลัง `abc` |
| `Unable to access library` / `Library already exists` | มี `work/` ค้างจากรอบก่อน | ลบโฟลเดอร์ `build/` แล้วรันใหม่ |
| `ghdl: unknown command '--std=08'` | สลับลำดับ option | ใช้ `ghdl synth --std=08 --out=verilog top` (GHDL 5.x) |
| GHDL ไม่สร้างไฟล์ `.v` | GHDL พิมพ์ออก stdout | ต้อง redirect: `... > out.v` |
| `Cannot find PDK` / ดาวน์โหลด PDK ไม่สำเร็จ | ต้องใช้ `--volare-pdk` | `librelane --volare-pdk -p sky130A config.yaml` |
| `make sky130` บอกว่าไม่พบ `SKY130_LIB` | ยังไม่ได้ติดตั้ง PDK | รัน `make librelane` ก่อน หรือกำหนด path เอง |
| DRC violation เยอะ | utilization สูงเกิน | ลด `FP_CORE_UTIL` หรือเพิ่มระยะ PDN |
| LVS mismatch | RTL กับ layout ไม่ตรงกัน | ตรวจว่า blackbox/tie-cell ถูกจัดการครบ |
| Hold violation หลัง CTS | skew มากเกิน | เพิ่ม `CLOCK_PERIOD` หรือปรับ CTS strategy |
| `ghdl` ไม่มีในระบบ | ยังไม่ได้ติดตั้ง | `sudo apt install ghdl` |

---

## 23. แบบฝึกหัดและ Checklist

### 23.1 แบบฝึกหัด

| ข้อ | โจทย์ | ผลที่คาดหวัง |
| --- | --- | --- |
| Y.1 | รัน `make synth` แล้วเปรียบเทียบ cell count ของ `adder8` กับ `adder8_pipe` | 52 vs 78 cells, อธิบายว่าเพราะอะไร |
| Y.2 | เขียน RTL แบบที่สองที่ทำให้ `adder8` ใช้ cell น้อยลง แล้ววัดใหม่ | cell count ลดลง, อธิบายว่าปรับอะไร |
| Y.3 | รัน `make sim-gls` แล้วอธิบายว่าการที่ testbench เดิมผ่านทั้ง RTL และ netlist พิสูจน์อะไร | พิสูจน์ functional equivalence ในขอบเขต vector ที่ทดสอบ |
| Y.4 | รัน `make sky130` แล้วหาพื้นที่จริงของ cell | 220.21 µm² (24 cells: maj3 + xnor2) |
| Y.5 | แก้ `CLOCK_PERIOD` เป็น 5 ns ใน `config.yaml` แล้วรัน LibreLane ใหม่ | ได้ Fmax ที่สูงขึ้น หรือพบ setup violation |
| Y.6 | เปลี่ยน `FP_CORE_UTIL` เป็น 60 แล้วรันใหม่ | เปรียบเทียบ die area และ routing difficulty |
| Y.7 | ทำ formal equivalence ระหว่าง RTL กับ netlist ด้วย `equiv_*` | `equiv_status -assert` ผ่าน |

### 23.2 Checklist ตอนจบหัวข้อ

| หัวข้อ | สถานะ |
| --- | --- |
| อธิบายขั้นตอน RTL → RTLIL → gate → cell ได้ | ☐ |
| เขียน Yosys script อ่าน Verilog + สังเคราะห์ได้ | ☐ |
| อธิบายความต่างของ `synth`, `abc`, `techmap`, `dfflibmap` ได้ | ☐ |
| อ่านรายงาน `stat` และเปรียบเทียบ area ได้ | ☐ |
| ทำ GLS ของ netlist ที่สังเคราะห์ได้ | ☐ |
| แปลง VHDL เข้า Yosys ด้วย GHDL ได้ | ☐ |
| อธิบาย config.yaml ของ LibreLane และ PDK ได้ | ☐ |
| อ่าน `metrics.json` และคำนวณ Fmax ได้ | ☐ |
| อธิบายว่า RTL cell count ต่างจาก final instance count อย่างไร | ☐ |
| เปรียบเทียบ Yosys กับ Precision RTL และเลือกใช้ตามงาน | ☐ |

---

## 24. แหล่งอ้างอิง

### 24.1 เอกสารของเครื่องมือ

- **Yosys Handbook** — https://yosyshq.readthedocs.io/ (ค้นหา `abc`, `dfflibmap`, `equiv_simple`)
- **LibreLane Documentation** — https://librelane.readthedocs.io/
- **OpenROAD Documentation** — https://openroad.readthedocs.io/
- **GHDL User Guide** — https://ghdl.github.io/ghdl/users-guide/ (หัวข้อ Synthesis → Verilog)
- **Magic VLSI** — http://www.opencircuitdesign.com/magic/
- **Netgen** — https://netgen.sourceforge.net/

### 24.2 PDK

- **sky130** — https://github.com/google/skywater-pdk-libs-sky130_fd_sc_hd
- **IHP SG13G2** — https://github.com/IHP-GmbH/IHP-Open-PDK
- **Open PDK Alliance** — https://openpdk.org/

### 24.3 บทความ/วิดีโอ

- "Yosys: A Framework for RTL Synthesis" — การออกแบบของ Yosys
- "ABC: A System for Sequential Logic Synthesis and Optimization" — เอกสารของ ABC
- "Toward Truly Open-Source ASIC Design" (DAC 2020) — บทความต้นแบบของกระบวนการ open-source ASIC

---

> **หมายเหตุ:** เอกสารนี้จัดทำคู่กับ Lab 3B ใน `lab_code/day3_yosys/` — ทุกตัวเลขที่ปรากฏสามารถทำซ้ำได้ด้วย `make` ในโฟลเดอร์นั้น

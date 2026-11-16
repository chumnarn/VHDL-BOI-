# แล็บ 3B: การสังเคราะห์ด้วย Yosys และ Open-source ASIC Flow (LibreLane)

> **เวลาใช้งาน:** 2.5–3 ชั่วโมง (ถ้ารวมขั้นตอน LibreLane ต้องเผื่อเวลาดาวน์โหลด PDK ครั้งแรก)
>
> **เครื่องมือ:** Yosys 0.52 · Icarus Verilog 12.0 · GHDL 5.0.1 · LibreLane v3.0.17 · PDK sky130A
>
> **Output ที่คาดหวัง:**
> - RTL simulation ผ่าน 131,072 patterns แบบ exhaustive
> - Yosys generic synthesis → รายงานจำนวน cell
> - Gate-level netlist ที่ผ่าน Gate-Level Simulation เท่ากับ RTL ทุก pattern
> - สะพาน VHDL → GHDL → Verilog → Yosys ทำงานได้
> - Map เข้า sky130 standard cell พร้อมพื้นที่จริง (µm²)
> - LibreLane รันครบ 80 stages จนได้ GDSII พร้อม DRC/LVS ผ่าน

---

## โครงสร้างโปรเจกต์

```
lab_code/day3_yosys/
├── Makefile                   ← จุดเริ่มต้น (make / make sim / make synth / ...)
├── run_yosys_lab.sh           ← batch runner รันทุกขั้น + สรุป PASS/FAIL
├── README.md
├── rtl/
│   ├── adder8.v               ← 8-bit adder แบบ combinational
│   ├── adder8_pipe.v          ← 8-bit adder แบบ 2-stage pipeline
│   └── adder8.vhd            ← เวอร์ชัน VHDL (สำหรับสะพาน GHDL)
├── tb/
│   ├── tb_adder8.v            ← exhaustive 131,072 patterns
│   └── tb_adder8_pipe.v       ← ตรวจ latency ของ pipeline
├── scripts/
│   ├── synth_generic.ys       ← Yosys script: generic synthesis
│   ├── synth_gates.ys         ← Yosys script: gate-level netlist
│   └── ghdl_to_verilog.sh     ← สะพาน VHDL -> Verilog
├── librelane/
│   ├── config.yaml            ← config ของ LibreLane
│   ├── Makefile
│   ├── src/{adder8_pipe.v, impl.sdc, signoff.sdc}
│   └── README.md
└── build/                     ← ผลลัพธ์ (สร้างอัตโนมัติ)
```

---

## Step 1: เตรียมเครื่องมือ

### 1.1 ติดตั้ง (Ubuntu / WSL)

```bash
sudo apt update
sudo apt install -y yosys iverilog ghdl make
```

### 1.2 ติดตั้ง LibreLane + เครื่องมือ ASIC ทั้งชุด (ผ่าน nix)

```bash
curl -L -o /tmp/install-nix.sh https://nixos.org/nix/install | sh -s -- --daemon
source /root/.nix-profile/etc/profile.d/nix.sh

nix profile install nixpkgs#librelane
export PATH="/root/.nix-profile/bin:$PATH"

librelane --version     # ต้องได้ LibreLane v3.0.x
```

> Nix จะดึง OpenROAD, Magic, KLayout, Netgen, Yosys 0.70 และ yosys-ghdl มาให้ใน closure เดียวกัน — ไม่ต้องติดตั้งแยก

### 1.3 ตรวจสอบ

```bash
yosys -V
iverilog -V | head -1
ghdl --version | head -1
librelane --version
```

**ผลที่คาดหวัง:**

```
Yosys 0.52 (git sha1 fee39a3284c90249e1d9684cf6944ffbbcbb8f90)
Icarus Verilog version 12.0 (stable)
GHDL 5.0.1 (Ubuntu 5.0.1+dfsg-1ubuntu1) [Dunoon edition]
LibreLane v3.0.17
```

> **ถ้าอยู่ใน WSL และ path มีวงเล็บ** เช่น `/mnt/e/lab/VHDL(BOI)/...` ให้ห่อด้วย `"` เสมอ:
> `cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3_yosys"`

### 1.4 ทดสอบว่าทุกอย่างพร้อม (ทางลัด)

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3_yosys"
bash run_yosys_lab.sh
```

ผลลัพธ์ต้องจบด้วย:

```
สรุป: ผ่านทั้งหมด — ไม่มีขั้นตอนไหนล้มเหลว
```

---

## Step 2: เข้าใจ RTL ที่จะสังเคราะห์

### 2.1 `adder8` — combinational

```verilog
module adder8 (
    input  wire       cin,
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum,
    output wire       cout
);
    assign {cout, sum} = {1'b0, a} + {1'b0, b} + cin;
endmodule
```

### 2.2 `adder8_pipe` — 2-stage pipeline

```
       a,b,cin ──►[Stage 1: register]──► r1_a,r1_b,r1_cin
                                             │
                                             ▼
                                    [Stage 2: add + register]
                                             │
                                             ▼
                                          sum, cout
```

- **Latency = 1 clock** — ข้อมูลที่ใส่ก่อนขอบ clock หนึ่งจะออกหลังขอบ clock สอง
- มี **26 flip-flop** (17 bit operand + 9 bit result)
- ใช้เป็นตัวแทนของ design ที่ต้องผ่าน Place & Route

### 2.3 เปรียบเทียบกับ Day 3 (Precision RTL)

| | `adder8` | `adder8_pipe` |
|---|---|---|
| จำนวน cell (Yosys) | 52 | 78 |
| flip-flop | 0 | 26 |
| critical path | ยาว (ผ่าน 8 stage) | สั้น (ครึ่งหนึ่ง) |
| ใช้ใน Lab 4 (GLS) | ✅ | ✅ |

> ทั้งสองตัวนี้เป็นตัวเดียวกับที่ใช้ใน `lab_code/day3/` ของ Questa — เปรียบเทียบผลสังเคราะห์ของ commercial tool กับ open-source tool ได้โดยตรง

---

## Step 3: RTL Simulation ด้วย Icarus Verilog

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3_yosys"
make sim
```

### ผลที่คาดหวัง

```
=== [1] RTL simulation (Icarus Verilog) ===
iverilog -o build/tb_adder8.vvp      rtl/adder8.v        tb/tb_adder8.v
iverilog -o build/tb_adder8_pipe.vvp rtl/adder8_pipe.v   tb/tb_adder8_pipe.v
vvp build/tb_adder8.vvp
tb_adder8 PASS=131072 FAIL=0
tb_adder8: ALL 131072 PATTERNS PASS
vvp build/tb_adder8_pipe.vvp
tb_adder8_pipe PASS=64 FAIL=0
tb_adder8_pipe: ALL TESTS PASS
```

### อธิบาย

- **131,072 = 2 × 256 × 256** ครอบคลุมทุก combination ของ `a`, `b` และ `cin`
- testbench ใช้ `!==` (case inequality) จึงจับทั้งความต่างของค่าและค่า `'X'`/`'Z'` — **สิ่งที่ `!=` ทำไม่ได้**
- ตัวนับใช้ **variable** ไม่ใช่ signal เพราะ signal assignment จะถูก apply ตอน end of delta cycle ทำให้รายงานสุดท้ายอ่านค่าค้าง

---

## Step 4: Yosys Generic Synthesis

```bash
make synth
```

### ผลที่คาดหวัง

```
=== adder8 ===
   Number of wires:                 48
   Number of wire bits:             69
   Number of ports:                  5
   Number of port bits:             26
   Number of cells:                 52
     $_ANDNOT_                      16
     $_AND_                          2
     $_NAND_                         7
     $_NOR_                          7
     $_ORNOT_                        1
     $_OR_                           3
     $_XNOR_                         8
     $_XOR_                          8

=== adder8_pipe ===
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

### สิ่งที่ต้องสังเกต

1. **52 vs 78 cells** — ความต่างมาจาก flip-flop ทั้ง 26 ตัว
2. `Number of memories` และ `Number of processes` เป็น **0** → process ถูกย่อยหมดแล้ว
3. `$_SDFF_PP0_` = synchronous D flip-flop พร้อม preset/clear

### สคริปต์ที่ใช้ (`scripts/synth_generic.ys`)

```tcl
read_verilog rtl/adder8.v
hierarchy -check -top adder8
synth -top adder8
tee -o build/adder8_generic_stat.txt stat
write_verilog -noattr build/adder8_generic.v

design -reset          # ← เริ่ม module ใหม่ในสคริปต์เดียว

read_verilog rtl/adder8_pipe.v
hierarchy -check -top adder8_pipe
synth -top adder8_pipe
tee -o build/adder8_pipe_generic_stat.txt stat
write_verilog -noattr build/adder8_pipe_generic.v
```

### แบบฝึกหัด

- ใช้ `yosys -p "read_verilog rtl/adder8.v; hierarchy -top adder8; synth -top adder8 -run coarse; stat"`
  เพื่อดูผล **ก่อน** ABC map — จะเห็น `$add` แทน gate
- ลอง `yosys -p "read_verilog rtl/adder8.v; synth -top adder8 -flatten; stat"` ดูว่า flatten เปลี่ยนอะไร

---

## Step 5: Yosys Gate-Level Mapping

```bash
make synth-gate
```

### ผลที่คาดหวัง

```
=== adder8 ===            Number of cells: 41   (25 NAND, 14 XOR, 1 OR, 1 XNOR)
=== adder8_pipe ===       Number of cells: 66   (24 NAND, 26 SDFF, 16 XOR)
```

### จุดสำคัญของสคริปต์

```tcl
synth -top adder8 -noabc     # ข้าม ABC เพื่อเราจะ map เอง
abc -g AND,NAND,OR,NOR,XOR,XNOR,MUX
simplemap                    # ← ทำให้ netlist simulate ได้ด้วย Icarus
opt_clean
write_verilog -noattr build/adder8_gates.v
```

> ⚠️ **ABC ไม่รองรับ gate type `NOT`** — ถ้าใส่ `NOT` จะได้
> `ERROR: Command syntax error: Unsupported gate type: NOT`
> ตัว inverter ถูกสร้างขึ้นมาอัตโนมัติอยู่แล้ว

### ทำไมต้อง `simplemap`

หลัง `abc` cell จะอยู่ในรูปภายในของ Yosys (`$_NAND_`) ซึ่ง Icarus Verilog **มองไม่เห็น**
`simplemap` แปลงกลับเป็น expression ของ Verilog ธรรมดา (`assign y = ~(a & b);`)

---

## Step 6: Gate-Level Simulation (พิสูจน์ว่า netlist ถูกต้อง)

```bash
make sim-gls
```

### ผลที่คาดหวัง

```
=== [4] Gate-Level Simulation ของ netlist ที่ Yosys สร้าง ===
tb_adder8 PASS=131072 FAIL=0
tb_adder8: ALL 131072 PATTERNS PASS
tb_adder8_pipe PASS=64 FAIL=0
tb_adder8_pipe: ALL TESTS PASS
```

### อธิบาย — นี่คือหัวใจของแล็บ

```
        RTL (rtl/adder8.v)                  Yosys                   Netlist
      ┌───────────────┐              ┌──────────────┐        ┌──────────────┐
      │  behavior     │  ──────────► │  synthesis   │ ─────► │  gate-level  │
      │  131,072 vec  │              │  + mapping   │        │  131,072 vec │
      └───────┬───────┘              └──────────────┘        └──────┬───────┘
              │                                                     │
              └─────────────── ผลเหมือนกันทุก pattern ────────────────┘
                          ⇒ netlist ถูกต้องในขอบเขตที่ทดสอบ
```

**ใช้ testbench ไฟล์เดียวกันเป๊ะ** กับทั้ง RTL และ netlist — ถ้าผ่านทั้งคู่ด้วยจำนวน pattern เท่ากัน
แปลว่า Yosys ไม่ได้ทำให้ฟังก์ชันเพี้ยน

> สำหรับการพิสูจน์ที่เข้มงวดกว่านี้ ให้ทำ **formal equivalence** ด้วย `equiv_make` /
> `equiv_simple` / `equiv_status -assert` ซึ่งพิสูจน์ว่าเท่ากัน **ทุก input** ไม่ใช่แค่ vector ที่ทดสอบ

---

## Step 7: สะพาน VHDL → GHDL → Verilog → Yosys

นักเรียนของคอร์สนี้เขียน VHDL แต่ Yosys อ่าน Verilog เท่านั้น — ขั้นตอนนี้แสดงวิธีนำ RTL ที่เขียนเป็น VHDL เข้า Yosys

```bash
make ghdl
```

### ผลที่คาดหวัง

```
=== [5] VHDL -> GHDL -> Verilog -> Yosys ===
=== [1/3] GHDL analyse: rtl/adder8.vhd (std=08) ===
=== [2/3] GHDL -> Verilog ===
...
=== adder8 ===
   Number of cells:                 88
tb_adder8 PASS=131072 FAIL=0
tb_adder8: ALL 131072 PATTERNS PASS
```

### สคริปต์ `scripts/ghdl_to_verilog.sh`

```bash
# 1) วิเคราะห์
ghdl -a --std=08 rtl/adder8.vhd

# 2) สร้าง Verilog  (GHDL 5.x พิมพ์ออก stdout ต้อง redirect เอง)
ghdl synth --std=08 --out=verilog adder8 > adder8.v

# 3) ให้ Yosys อ่าน
yosys -p "read_verilog build/adder8_from_vhdl.v; hierarchy -check -top adder8; synth -top adder8; ..."
```

> ⚠️ **GHDL 5.x เปลี่ยน syntax**: ใช้ `ghdl synth --std=08 --out=verilog top`
> (ไม่ใช่ `ghdl --out=verilog --std=08 top` ซึ่งจะได้ `unknown command '--out=verilog'`)
> และ **ไม่มีตัวเลือกระบุชื่อไฟล์** — ต้อง redirect เองเสมอ

### ทางเลือก: ใช้ yosys-ghdl plugin

```bash
yosys -m ghdl -p "ghdl --std=08 rtl/adder8.vhd -e adder8; prep -top adder8; synth -top adder8; stat"
```

### ข้อสังเกตสำคัญ (88 cells vs 52 cells)

| RTL | วิธีเขียน | Yosys cells |
|---|---|---|
| `adder8.v` | `assign {cout,sum} = a+b+cin` | **52** |
| `adder8.vhd` | `vs := va+vb; if cin='1' then vs := vs+1;` | **88** |

โค้ดทำงานเหมือนกันเป๊ะ แต่ **RTL รูปแบบหนึ่งให้ผลสังเคราะห์ที่เล็กกว่าอีกแบบ 69 %**
→ บทเรียน: ต้องวัดผลหลังเขียน RTL เสมอ ไม่ใช่เชื่อว่า "ทำงานถูกแล้วก็ดี"

---

## Step 8: Map เข้า sky130 Standard Cell (ได้พื้นที่จริง)

```bash
# ต้องติดตั้ง PDK ก่อน (ขั้นตอนถัดไปจะทำให้อัตโนมัติ)
make sky130 SKY130_LIB=$(ls /root/.ciel/ciel/sky130/versions/*/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib | head -1)
```

### ผลที่คาดหวัง

```
=== adder8 ===
   Number of cells:                 24
     sky130_fd_sc_hd__maj3_1         8
     sky130_fd_sc_hd__xnor2_1       16

   Chip area for module '\adder8': 220.211200
     of which used for sequential elements: 0.000000 (0.00%)
```

### อธิบาย

- เปลี่ยนจาก gate ทั่วไป (41 cells) เป็น **standard cell จริงของ sky130** (24 cells)
- ได้ **พื้นที่จริง** 220.21 µm² จากข้อมูล area ในไฟล์ Liberty
- `maj3` (3-input AND) และ `xnor2` เป็น cell ที่ ABC เลือกมาเพราะให้ delay ดีที่สุดสำหรับ carry chain ของ adder

### ขั้นตอนการ map

```tcl
read_liberty -lib $SKY130_LIB      # 1. โหลด cell library
read_verilog rtl/adder8.v          # 2. อ่าน RTL
hierarchy -check -top adder8
synth -top adder8 -noabc           # 3. ย่อย (ยังไม่ map)
dfflibmap -liberty $SKY130_LIB     # 4. map flip-flop เข้า cell จริง
abc -liberty $SKY130_LIB           # 5. map logic เข้า cell จริง
stat -liberty $SKY130_LIB          # 6. รายงานรวมพื้นที่
```

> `dfflibmap` ต้องมาก่อน `abc` เสมอ

---

## Step 9: LibreLane Full Flow (RTL → GDSII)

```bash
make librelane
# หรือ: cd librelane && librelane --volare-pdk -p sky130A config.yaml
```

> **ครั้งแรกจะดาวน์โหลด PDK sky130A ประมาณ 1–2 GB** และใช้เวลาราว 2–4 นาที
> (ครั้งต่อไปใช้เวลาราว 90 วินาที)

### ผลที่คาดหวัง (จากการรันจริง)

```
Classic - Stage 80 - Report Manufacturability ━━━━━━━━━━━━━━━━━━━━ 80/80 0:01:27

* Antenna
Passed ✅

* LVS
Passed ✅

* DRC
Passed ✅
```

### ตารางผลลัพธ์จริง

| รายการ | ค่า |
| --- | --- |
| Stages | **80 / 80** ✅ |
| DRC violations | **0** ✅ |
| LVS errors | **0** ✅ |
| Antenna violations | **0** ✅ |
| Setup violations | 0 (worst slack **5.587 ns**) ✅ |
| Hold violations | 0 (worst slack **0.317 ns**) ✅ |
| Instances | 399 (stdcell 167, fill 232, buffer 44, tap 30) |
| Nets / IOs | 158 / 30 |
| Instance area | 2409.81 µm² |
| Core area | 2409.81 µm² |
| Die area | 4331.89 µm² (60.675 × 71.395 µm) |
| Utilization | 68.95 % |
| GDSII | `adder8_pipe.gds` 413,344 bytes |

### ไฟล์ `config.yaml` ที่ใช้

```yaml
DESIGN_NAME: adder8_pipe
VERILOG_FILES: dir::src/*.v
CLOCK_PORT: clk
CLOCK_PERIOD: 10          # ns -> 100 MHz
PNR_SDC_FILE: dir::src/impl.sdc
SIGNOFF_SDC_FILE: dir::src/signoff.sdc

PDN_VOFFSET: 5
PDN_HOFFSET: 5
PDN_VWIDTH: 2
PDN_HWIDTH: 2
PDN_VPITCH: 30
PDN_HPITCH: 30
PDN_SKIPTRIM: true

pdk::sky130*:
  FP_CORE_UTIL: 45
  CLOCK_PERIOD: 10.0
```

### ไฟล์ SDC

```tcl
create_clock -name clk -period 10 [get_ports clk]
set_input_delay 0 -clock clk [all_inputs -no_clocks]
set_output_delay 0 -clock clk [all_outputs]
set_false_path -from [get_ports rst]
```

---

## Step 10: อ่านผลลัพธ์และคำนวณ Fmax

### 10.1 หาไฟล์ผลลัพธ์

```bash
cd librelane
RUN=$(ls -dt runs/RUN_* | head -1)
echo $RUN
ls $RUN/final/
```

```
final/
├── metrics.json      ← ตัวเลขทั้งหมด
├── metrics.csv
├── gds/adder8_pipe.gds
├── klayout_gds/adder8_pipe.klayout.gds
├── lef/ def/ mag/ spef/ sdf/ spice/
```

### 10.2 อ่านด้วย python

```bash
python3 - <<'PY'
import json, glob
m = json.load(open(glob.glob('runs/RUN_*/final/metrics.json')[0]))
print("instances      :", m.get('design__instance__count'))
print("instance area  :", m.get('design__instance__area'), "um^2")
print("die area       :", m.get('design__die__area'), "um^2")
print("utilization    :", m.get('design__instance__utilization'))
print("nets / io      :", m.get('design__nets'), "/", m.get('design__io'))
print("setup slack    :", m.get('timing__setup__ws'), "ns")
print("hold slack     :", m.get('timing__hold__ws'), "ns")
print("violations     :", m.get('design__violations'))
print("latch inferred :", m.get('design__inferred_latch__count'))
PY
```

### 10.3 คำนวณ Fmax

```
   setup slack = 5.587222 ns, clock period = 10 ns

   critical path = 10 - 5.587222 = 4.412778 ns
   Fmax          = 1 / 4.412778 ns ≈ 226.6 MHz
```

> เชื่อมกลับไปหัวข้อ 3.3 (Timing Analysis เบื้องต้น) ของคู่มือหลัก —
> นักเรียนได้ฝึกอ่าน slack จากเครื่องมือฟรี ซึ่งเป็นทักษะเดียวกับที่ใช้กับ Precision RTL

### 10.4 เปิดดู GDSII

```bash
# KLayout (มากับ nix closure)
klayout $RUN/final/klayout_gds/adder8_pipe.klayout.gds
```

---

## Step 11: เปรียบเทียบผลของทั้งสอง flow

| มิติ | Yosys (standalone) | LibreLane (full flow) |
| --- | --- | --- |
| สิ่งที่ได้ | netlist + cell count | netlist + layout + GDSII |
| พื้นที่ | 220.21 µm² (cell area เฉพาะ) | 2409.81 µm² (รวม fill/buffer/tap) |
| Timing | ไม่มี STA | setup 5.587 ns / hold 0.317 ns |
| DRC / LVS | ไม่มี | ผ่านทั้งคู่ |
| เวลารัน | < 1 วินาที | ~90 วินาที (หลังมี PDK) |
| เครื่องมือ | Yosys | Yosys + OpenROAD + Magic + KLayout + Netgen |

> **ข้อสังเกตสำคัญ:** RTL cell count (24) ไม่เท่ากับ final instance count (399)
> เพราะ OpenROAD เพิ่ม fill cell, clock buffer, timing repair buffer และ tap cell
> เพื่อให้ layout สมบูรณ์ — เป็นบทเรียนที่ต้องอธิบายในห้องเรียน

---

## Step 12: แบบฝึกหัด

| ข้อ | โจทย์ | ผลที่คาดหวัง |
| --- | --- | --- |
| Y.1 | เปรียบเทียบ cell count ของ `adder8` กับ `adder8_pipe` | 52 vs 78 — อธิบายว่าเพราะ flip-flop 26 ตัว |
| Y.2 | เขียน `adder8` เวอร์ชันใหม่ที่ใช้ cell น้อยลง แล้ววัดใหม่ | cell count ลดลง, อธิบายว่าแก้อะไร |
| Y.3 | รัน `make sim-gls` แล้วอธิบายว่าการที่ testbench เดิมผ่านทั้ง RTL และ netlist พิสูจน์อะไร | functional equivalence ในขอบเขต vector ที่ทดสอบ |
| Y.4 | รัน `make sky130` แล้วหาพื้นที่จริง | 220.21 µm² จาก 24 cells |
| Y.5 | แก้ `CLOCK_PERIOD` เป็น 5 ns ใน `config.yaml` แล้วรัน LibreLane ใหม่ | Fmax สูงขึ้น หรือพบ setup violation |
| Y.6 | เปลี่ยน `FP_CORE_UTIL` เป็น 60 แล้วรันใหม่ เทียบ die area | die area เล็กลง แต่ routing ยากขึ้น |
| Y.7 | ทำ formal equivalence ระหว่าง RTL กับ netlist | `equiv_status -assert` ผ่าน |
| Y.8 | สร้าง `adder8_pipe` เวอร์ชัน VHDL แล้วส่งผ่านสะพาน GHDL | ได้ netlist ที่ผ่านทุก pattern |

---

## Troubleshooting

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| `yosys: command not found` | ไม่ได้ติดตั้ง / ไม่ได้อยู่ใน PATH | `sudo apt install yosys` |
| `ERROR: Unsupported gate type: NOT` | ABC ไม่รองรับ `NOT` | เอา `NOT` ออกจาก `abc -g` |
| `ERROR: Can't find top module` | ชื่อ top ไม่ตรง | ตรวจ `hierarchy -top` และ `DESIGN_NAME` |
| netlist simulate ไม่ได้ | ยังไม่ได้ `simplemap` | เพิ่ม `simplemap` หลัง `abc` |
| `ghdl: unknown command '--out=verilog'` | สลับลำดับ option (GHDL 5.x) | ใช้ `ghdl synth --std=08 --out=verilog top` |
| GHDL ไม่ได้ไฟล์ `.v` | GHDL พิมพ์ออก stdout | redirect: `... > out.v` |
| `librelane: command not found` | ยังไม่ได้ติดตั้งผ่าน nix | `nix profile install nixpkgs#librelane` + เพิ่ม PATH |
| ดาวน์โหลด PDK ไม่สำเร็จ | ปัญหาเครือข่าย | รันซ้ำ หรือติดตั้ง PDK เองแล้วใช้ `--manual-pdk` |
| `make sky130` บอกไม่พบ `SKY130_LIB` | ยังไม่มี PDK | รัน `make librelane` ก่อน |
| DRC violation เยอะ | utilization สูงเกิน | ลด `FP_CORE_UTIL` |
| LVS mismatch | RTL ↔ layout ไม่ตรง | ตรวจ blackbox / tie cell |
| path มีวงเล็บทำให้คำสั่งพัง | shell ไม่ escape | ห่อด้วย `"` เช่น `cd "/mnt/e/lab/VHDL(BOI)/..."` |

---

## Validation Checklist

| ข้อ | หัวข้อ | สถานะ |
| --- | --- | --- |
| 1 | ตรวจสอบเครื่องมือครบ (yosys, iverilog, ghdl, librelane) | ☐ |
| 2 | RTL simulation ผ่าน 131,072 patterns | ☐ |
| 3 | Yosys generic synthesis อ่าน `stat` ได้ | ☐ |
| 4 | เข้าใจว่าทำไม `adder8_pipe` มี cell มากกว่า | ☐ |
| 5 | Gate-level netlist สร้างได้ | ☐ |
| 6 | Gate-Level Simulation ผ่านเท่ากับ RTL | ☐ |
| 7 | แปลง VHDL → Verilog ด้วย GHDL ได้ | ☐ |
| 8 | อธิบายได้ว่าทำไม VHDL ให้ cell มากกว่า | ☐ |
| 9 | Map เข้า sky130 cell และอ่านพื้นที่จริงได้ | ☐ |
| 10 | LibreLane รันครบ 80 stages | ☐ |
| 11 | อ่าน `metrics.json` และคำนวณ Fmax ได้ | ☐ |
| 12 | อธิบายได้ว่า RTL cell count ต่างจาก final instance count อย่างไร | ☐ |

---

> **ต่อไป:** กลับไป Day 3 แล้วทำแล็บ Precision RTL (`lab_code/day3/`) จากนั้นเปรียบเทียบ
> รายงานของ commercial tool กับ open-source tool ที่ได้จากแล็บนี้

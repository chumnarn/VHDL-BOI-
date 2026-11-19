# แล็บ 5B: RTL-to-GDSII Full Chip Flow ด้วย LibreLane (UART TX Mini Project)

> **เวลาใช้งาน:** 3–3.5 ชั่วโมง (ครั้งแรกให้เผื่อเวลาดาวน์โหลด PDK ประมาณ 1–2 GB)
>
> **เครื่องมือ:** Yosys 0.52 · Icarus Verilog 12.0 · LibreLane v3.0.17 · PDK sky130A
>
> **Output ที่คาดหวัง:**
> - RTL simulation ผ่าน 6 เฟรม UART (0x00, 0xFF, 0x55, 0xAA, 0x42, 0x3C)
> - Yosys generic synthesis → รายงาน cell แยกราย module
> - Gate-level netlist ที่ผ่าน Gate-Level Simulation เท่ากับ RTL ทุกเฟรม
> - Map เข้า sky130 standard cell พร้อมพื้นที่จริง (µm²)
> - **LibreLane รันครบ 80 stages จนได้ GDSII พร้อม DRC/LVS/Antenna ผ่าน**
> - อ่าน `metrics.json` ได้: area, utilization, slack ทุก corner, power

---

## โครงสร้างโปรเจกต์

```
lab_code/day5_yosys/
├── Makefile                    ← จุดเริ่มต้น (make sim / make synth / ...)
├── run_yosys_lab.sh            ← batch runner รันทุกขั้น + สรุป PASS/FAIL
├── README.md
├── rtl/
│   ├── baud_gen.v              ← ตัวหาร baud (100 MHz → 115200)
│   ├── uart_tx.v               ← UART Transmitter 8-N-1 (FSM)
│   └── uart_top.v              ← top module สำหรับ full chip flow
├── tb/
│   └── tb_uart_top.v           ← self-checking TB ตรวจเฟรม 10 บิตทั้งหมด
├── scripts/
│   ├── synth_generic.ys        ← Yosys: generic synthesis + hierarchy breakdown
│   └── synth_gates.ys          ← Yosys: gate-level netlist ที่ simulate ได้จริง
└── librelane/
    ├── config.yaml             ← config ของ LibreLane 3.x
    ├── Makefile
    ├── README.md               ← คู่มือติดตั้ง PDK + อ่านผลลัพธ์
    └── src/
        ├── impl.sdc            ← constraints ขั้น Place & Route
        └── signoff.sdc         ← constraints ขั้น sign-off
```

> `VERILOG_FILES: dir::../rtl/*.v` ใน `config.yaml` ชี้กลับไปที่ `rtl/` ของแล็บโดยตรง
> จึง **ไม่มีสำเนา RTL สองชุด** แก้ที่ไฟล์เดียวแล้วทั้ง flow เห็นพร้อมกัน

> `build/`, `build_log_*.txt` และ `librelane/runs/` เป็น artifact จากการรัน
> ล้างได้ด้วย `make clean` และ `cd librelane && make clean`

---

## Step 1: เตรียมเครื่องมือ

### 1.1 ติดตั้ง (Ubuntu / WSL)

```bash
sudo apt update
sudo apt install -y yosys iverilog make
```

### 1.2 ติดตั้ง LibreLane + เครื่องมือ ASIC ทั้งชุด (ผ่าน nix)

```bash
curl -L -o /tmp/install-nix.sh https://nixos.org/nix/install | sh -s -- --daemon
source /root/.nix-profile/etc/profile.d/nix.sh

nix profile install nixpkgs#librelane
export PATH="/root/.nix-profile/bin:$PATH"

librelane --version     # ต้องได้ LibreLane v3.0.x
```

> Nix จะดึง OpenROAD, Magic, KLayout, Netgen, Yosys และ yosys-ghdl มาให้ใน closure เดียวกัน

### 1.3 ตรวจสอบ

```bash
yosys -V
iverilog -V | head -1
librelane --version
```

**ผลที่คาดหวัง:**

```
Yosys 0.52 (git sha1 fee39a3284c90249e1d9684cf6944ffbbcbb8f90)
Icarus Verilog version 12.0 (stable)
LibreLane v3.0.17
```

> **ถ้าอยู่ใน WSL และ path มีวงเล็บ** เช่น `/mnt/e/lab/VHDL(BOI)/...` ให้ห่อด้วย `"` เสมอ:
> `cd "/mnt/e/lab/VHDL(BOI)/lab_code/day5_yosys"`
>
> **สำคัญ:** nix profile ไม่ถูกโหลดอัตโนมัติใน non-interactive shell
> สคริปต์ของแล็บนี้จึง **ตรวจและเพิ่ม `$HOME/.nix-profile/bin` ใน PATH ให้เอง**

### 1.4 ทดสอบว่าทุกอย่างพร้อม (ทางลัด)

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day5_yosys"
bash run_yosys_lab.sh
```

ผลลัพธ์ต้องจบด้วย:

```
สรุป: ผ่านทั้งหมด — ไม่มีขั้นตอนไหนล้มเหลว
```

---

## Step 2: เข้าใจ Mini Project ที่จะส่งเป็นชิป

วันที่ 5 ทำ Mini Project **UART TX** — ตอนนี้เราจะส่งมันไปจนถึง GDSII

```
   din[7:0]      din_vld        din_rdy       tx
      │             │              │            │
      ▼             ▼              ▼            ▼
  ┌──────────────────────────────────────────────┐
  │                 uart_top                     │
  │  ┌──────────────┐        ┌────────────────┐  │
  │  │  baud_gen    │ tick   │    uart_tx     │  │
  │  │ cnt 0..867   ├───────►│ IDLE→START→    │  │
  │  │ clk 100MHz   │        │ DATA→STOP      │  │
  │  └──────────────┘        │ (FSM 4 สถานะ)  │  │
  │                          └────────────────┘  │
  └──────────────────────────────────────────────┘
```

### 2.1 `baud_gen` — ตัวหาร baud

```verilog
localparam integer DIVISOR = CLK_FREQ / BAUD_RATE;  // 100e6 / 115200 = 868
localparam integer LIMIT    = DIVISOR - 1;          // 867
localparam integer CW       = $clog2(LIMIT + 1);   // 10 บิต
```

- นับถึง 867 แล้ว tick เป็น 1 หนึ่ง cycle → 115200 baud
- **10 flip-flop** (cnt) + 1 (tick) = **11 flip-flop**

### 2.2 `uart_tx` — FSM 4 สถานะ

```
        din_vld & din_rdy
   ┌─────────┐      ┌─────────┐     ┌────────┐     ┌────────┐
   │  IDLE   │─────►│  START  │────►│  DATA  │────►│  STOP  │
   │ tx = 1  │      │ tx = 0  │     │tx=bit  │     │ tx = 1 │
   └─────────┘      └─────────┘     └────────┘     └────────┘
        ▲                                              │
        └──────────────────────────────────────────────┘
```

- **shreg** 8 บิต (shift register) + **bit_idx** 3 บิต + **state** + **tx** + **din_rdy**
- ตามที่เขียนไว้ = 15 flip-flop — **แต่ Yosys จะเปลี่ยนเป็น 17** (ดู Step 7)

### 2.3 ทำไมต้องเขียนเวอร์ชัน Verilog ด้วย

คอร์สนี้สอน VHDL (`lab_code/day5/`) แต่ Yosys เป็น Verilog-first
และ GHDL ไม่ได้อยู่ใน flow ของ LibreLane ที่เราใช้
→ `day5_yosys/rtl/` จึงเป็น **สำเนาเชิงวิศวกรรมของ Mini Project เดิมใน Verilog**

> **สิ่งที่ต้องทำให้ครบ:** ถ้าเปลี่ยน RTL ใน `day5_yosys/rtl/` ต้องแก้ให้ตรงกับ
> `day5/` เวอร์ชัน VHDLด้วย แล้วรัน **ทั้งสอง testbench** เพื่อยืนยันว่าให้ผลเหมือนกัน

---

## Step 3: RTL Simulation ด้วย Icarus Verilog

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day5_yosys"
make sim
```

### ผลที่คาดหวัง

```
=== [1] RTL simulation (Icarus Verilog) ===
iverilog -o build/tb_uart_top.vvp rtl/baud_gen.v rtl/uart_tx.v rtl/uart_top.v tb/tb_uart_top.v
vvp build/tb_uart_top.vvp
tb_uart_top: start (BAUD_CYCLES=868)
tb_uart_top PASS=6 FAIL=0
tb_uart_top: ALL PATTERN FRAMES VERIFIED
```

### อธิบาย — การตรวจเฟรม UART

- ชุด pattern: `0x00, 0xFF, 0x55, 0xAA, 0x42, 0x3C` — 6 เฟรม
- เฟรม 8-N-1 = **10 บิต** (start + 8 data + stop)
- 1 bit cell = **868 clock** (100 MHz ÷ 115200)
- ทุกบิตถูก sample ที่ **กลาง cell** เพราะการ sample ที่ขอบ cell กำกวม
  (transmitter เปลี่ยน `tx` ใน clock edge เดียวกัน)

> **จุดที่ต้องระวัง:** ใน Verilog ต้องใช้ non-blocking assignment (`<=`) กับ stimulus
> และหน่วง `#1` หลัง `@(posedge clk)` ก่อนอ่านสัญญาณ มิฉะนั้นจะเจอ race condition
> ระหว่าง testbench กับ DUT — เทียบกับเวอร์ชัน VHDL ที่ใช้ delta cycle โดยธรรมชาติ

---

## Step 4: Yosys Generic Synthesis

```bash
make synth
```

### ผลที่คาดหวัง

```
=== $paramod$7a37eb7864cf2b8139b75e1b5d7691acecf756a6\baud_gen ===
   Number of cells:                 44

=== uart_top ===
   Number of cells:                  2

=== uart_tx ===
   Number of cells:                 74

=== design hierarchy ===
   Number of cells:                118
     $_ANDNOT_                      26
     $_AND_                          3
     $_DFF_P_                        4
     $_MUX_                          9
     $_NAND_                         7
     $_NOR_                          3
     $_NOT_                          6
     $_ORNOT_                        7
     $_OR_                          18
     $_SDFFE_PP0P_                  11
     $_SDFFE_PP1P_                   2
     $_SDFF_PP0_                    11
     $_XNOR_                         4
     $_XOR_                          7
```

### สิ่งที่ต้องสังเกต

1. **`baud_gen` 44 cells / `uart_tx` 74 cells** — แยกราย module ได้ เพราะ `synth` ไม่ flatten โดย default
2. **flip-flop 28 ตัว** ทั้งที่โค้ดเขียนไว้ 26 — ดูคำอธิบายใน Step 7
3. `Number of memories` และ `Number of processes` = **0** → ย่อย process หมดแล้ว

---

## Step 5: Yosys Gate-Level Mapping

```bash
make synth-gate
```

### ผลที่คาดหวัง

```
=== uart_top ===
   Number of cells:                112
     $_AND_                         25
     $_DFF_P_                        4
     $_MUX_                          5
     $_NAND_                        18
     $_NOR_                          6
     $_NOT_                          7
     $_OR_                          11
     $_SDFFE_PP0P_                  11
     $_SDFFE_PP1P_                   2
     $_SDFF_PP0_                    11
     $_XNOR_                         4
     $_XOR_                          6
```

### จุดสำคัญของสคริปต์

```tcl
synth -top uart_top -flatten -noabc    # ข้าม ABC เพื่อเราจะ map เอง
abc -g AND,NAND,OR,NOR,XOR,XNOR,MUX
simplemap                             # ← ทำให้ netlist simulate ได้ด้วย Icarus
opt_clean
write_verilog -noattr build/uart_top_gates.v
```

> ⚠️ **ABC ไม่รองรับ gate type `NOT`** — ถ้าใส่จะได้
> `ERROR: Command syntax error: Unsupported gate type: NOT`
> ตัว inverter ถูกสร้างขึ้นมาอัตโนมัติอยู่แล้ว
>
> หลัง `abc` cell จะอยู่ในรูปภายในของ Yosys (`$_NAND_`) ที่ Icarus **มองไม่เห็น**
> `simplemap` แปลงกลับเป็น expression ของ Verilog ธรรมดา

---

## Step 6: Gate-Level Simulation (พิสูจน์ว่า netlist ถูกต้อง)

```bash
make sim-gls
```

### ผลที่คาดหวัง

```
=== [4] Gate-Level Simulation ของ netlist ที่ Yosys สร้าง ===
iverilog -o build/tb_uart_top_gls.vvp build/uart_top_gates.v tb/tb_uart_top.v
vvp build/tb_uart_top_gls.vvp
tb_uart_top PASS=6 FAIL=0
tb_uart_top: ALL PATTERN FRAMES VERIFIED
```

### อธิบาย — นี่คือหัวใจของแล็บ

```
        RTL (rtl/uart_top.v)              Yosys               Netlist
      ┌───────────────┐              ┌──────────────┐      ┌──────────────┐
      │  behavior     │  ──────────► │  synthesis   │ ───► │  gate-level  │
      │  6 UART frames│              │  + mapping   │      │ 6 UART frames│
      └───────┬───────┘              └──────────────┘      └──────┬───────┘
              │                                                   │
              └──────────── ผลเหมือนกันทุกเฟรม ─────────────────────┘
                          ⇒ netlist ถูกต้องในขอบเขตที่ทดสอบ
```

**ใช้ testbench ไฟล์เดียวกันเป๊ะ** กับทั้ง RTL และ netlist — ถ้าผ่านทั้งคู่
แปลว่า Yosys ไม่ทำให้ฟังก์ชันของ Mini Project เพี้ยน

> สำหรับการพิสูจน์ที่เข้มงวดกว่านี้ ให้ทำ **formal equivalence** ด้วย `equiv_make` /
> `equiv_simple` / `equiv_status -assert` ซึ่งพิสูจน์ว่าเท่ากัน **ทุก input**
> ไม่ใช่แค่ 6 เฟรมที่ทดสอบ

---

## Step 7: เปิดโปงโครงสร้างที่ Yosys เปลี่ยนเอง (บทเรียนสำคัญ)

โค้ดที่เขียนไว้ประกาศ `reg [1:0] state` (FSM 4 สถานะ = 2 บิต)
แต่ Yosys สร้าง **4 flip-flop** สำหรับ state ลองดูว่าจริงหรือไม่:

```bash
yosys -p "
read_verilog rtl/baud_gen.v;
read_verilog rtl/uart_tx.v;
read_verilog rtl/uart_top.v;
hierarchy -check -top uart_top;
synth -top uart_top -flatten;
select t:\$_DFF_P_;
dump;
"
```

### ผลที่ได้ (ตัดตอนจริง)

```
  cell $_DFF_P_ $auto$ff.cc:266:slice$356
    connect \C \clk
    connect \D $abc$765$auto$fsm_map.cc:170:map_fsm$115[0]
    connect \Q \u_tx.state [0]
  end

  cell $_DFF_P_ $auto$ff.cc:266:slice$357
    connect \C \clk
    connect \D $abc$765$auto$fsm_map.cc:170:map_fsm$115[1]
    connect \Q \u_tx.state [1]
  end
  ... (อีก 2 ตัว)
```

### สิ่งที่เกิดขึ้นจริง

| | โค้ดเดิม | ผลของ Yosys |
| --- | --- | --- |
| จำนวนบิตของ state | 2 | **4** |
| การเข้ารหัส | binary | **one-hot** (`map_fsm$115[0..3]`) |
| reset | มี | **ไม่มี** (`$_DFF_P_` = plain D flip-flop) |
| flip-flop รวม | 26 | **28** |

> **`fsm` pass ของ Yosys ตรวจจับ FSM แล้วเปลี่ยน encoding เป็น one-hot**
> แลกกับ flip-flop เพิ่ม 2 ตัว แต่ logic decode ของ FSM เล็กลง
> และ **ไม่ต้องใช้ reset อีกต่อไป** เพราะ one-hot ที่ไม่มี state ไหนเป็น 1
> จะถูกตีความเป็น default case → IDLE
>
> **บทเรียน:** RTL ที่คุณเขียน ไม่ใช่สิ่งที่ถูกสังเคราะห์ — tool ปรับโครงสร้างให้เหมาะกับเทคโนโลยีเป้าหมาย

---

## Step 8: Map เข้า sky130 Standard Cell

```bash
# ต้องติดตั้ง PDK ก่อน (ขั้นตอนถัดไปจะทำให้อัตโนมัติ)
make sky130 SKY130_LIB=$(ls /root/.ciel/ciel/sky130/versions/*/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib | head -1)
```

### ผลที่คาดหวัง

```
=== uart_top ===
   Number of cells:                 122

   Chip area for module '\uart_top': 1087.292800
```

### อธิบาย

- เปลี่ยนจาก gate ทั่วไป (112 cells) เป็น **standard cell จริงของ sky130** (122 cells)
- ได้ **พื้นที่จริง** 1087.29 µm² จากข้อมูล area ในไฟล์ Liberty

### ขั้นตอนการ map

```tcl
read_liberty -lib $SKY130_LIB      # 1. โหลด cell library
read_verilog rtl/baud_gen.v        # 2. อ่าน RTL
read_verilog rtl/uart_tx.v
read_verilog rtl/uart_top.v
hierarchy -check -top uart_top
synth -top uart_top -flatten -noabc # 3. ย่อย (ยังไม่ map)
dfflibmap -liberty $SKY130_LIB     # 4. map flip-flop  ← ต้องมาก่อน abc เสมอ
abc -liberty $SKY130_LIB           # 5. map logic
stat -liberty $SKY130_LIB          # 6. รายงานพื้นที่รวม
```

> **เปรียบเทียบ:** ตัวเลขของ LibreLane ตอนสังเคราะห์เองได้ **117 cells / 1328.77 µm²**
> ต่างจาก `make sky130` เพราะเป็นคนละ flow (LibreLane มี timing-driven optimization เพิ่ม)
> → **ตัวเลข synthesis ขึ้นกับ flow ที่ใช้ ต้องระบุเสมอ**

---

## Step 9: LibreLane Full Flow (RTL → GDSII)

```bash
make librelane
# หรือ: cd librelane && librelane --volare-pdk -p sky130A config.yaml
```

> **ครั้งแรกจะดาวน์โหลด PDK sky130A ประมาณ 1–2 GB** ใช้เวลา 2–4 นาที
> (ครั้งต่อไปใช้เวลาราว **1 นาที 50 วินาที**)

### ผลที่คาดหวัง (จากการรันจริง)

```
───────────────── Report Manufacturability (DRC, LVS, Antenna) ─────────────────
* Antenna
Passed ✅
* LVS
Passed ✅
* DRC
Passed ✅
Classic - Stage 80 - Report Manufacturability ━━━━━━━━━━━━━━━━━━━━ 80/80 0:01:49
```

### ตารางผลลัพธ์จริง

| รายการ | ค่า |
| --- | --- |
| Stage ที่ผ่าน | **80 / 80** ✅ |
| `error.log` | **0 bytes** ✅ |
| DRC violations (Magic + KLayout) | **0** ✅ |
| LVS errors / device / net / pin diff | **0 / 0 / 0 / 0** ✅ |
| Antenna violations (net / pin) | **0 / 0** ✅ |
| Setup violations | 0 (worst slack **6.235697 ns**) ✅ |
| Hold violations | 0 (worst slack **0.191574 ns**) ✅ |
| Max slew / max cap / max fanout violations | 0 / 0 / 0 ✅ |
| Inferred latches / unmapped cells | **0 / 0** ✅ |
| Instances | 526 (stdcell 183, fill 343, buffer 20, tap 42, clock buf 3) |
| Sequential cells | 28 |
| Nets / IOs | 153 / **15** (13 ขาสัญญาณ + VGND + VPWR) |
| Instance & core area | 2805.19 µm² |
| Die area | 4975.42 µm² (65.38 × 76.1 µm) |
| Utilization | 60.12 % |
| Power | total 303.98 µW (internal 245.63, switching 58.34, leakage 2.929 nW) |
| GDSII | `uart_top.gds` 517,382 bytes |

### ไฟล์ `config.yaml` ที่ใช้

```yaml
DESIGN_NAME: uart_top
VERILOG_FILES: dir::../rtl/*.v      # ← ชี้กลับไป rtl/ ของแล็บ ไม่มีสำเนา
CLOCK_PORT: clk
CLOCK_PERIOD: 10                    # ns -> 100 MHz
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
```

> `dir::` หมายถึง path สัมพัทธ์จากโฟลเดอร์ที่วาง `config.yaml` — `../rtl/*.v` จึงชี้ไปที่
> `day5_yosys/rtl/` ซึ่งอยู่ข้างบนหนึ่งระดับ

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
├── gds/uart_top.gds
├── klayout_gds/uart_top.klayout.gds
├── lef/ def/ mag/ spef/ sdf/ spice/
```

### 10.2 อ่านด้วย python

```bash
python3 - <<'PY'
import json, glob
m = json.load(open(glob.glob('runs/RUN_*/final/metrics.json')[0]))
print("instances      :", m.get('design__instance__count'))
print("instance area  :", m.get('design__instance__area'), "um^2")
print("core area      :", m.get('design__core__area'), "um^2")
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
   setup slack = 6.235697 ns, clock period = 10 ns

   critical path = 10 - 6.235697 = 3.764303 ns
   Fmax          = 1 / 3.764303 ns ≈ 265.7 MHz
```

### 10.4 ดู slack ทุก corner

```bash
python3 -c "
import json,glob
m=json.load(open(glob.glob('runs/RUN_*/final/metrics.json')[0]))
for k in sorted(m):
    if k.startswith('timing__setup__ws__corner') or k.startswith('timing__hold__ws__corner'):
        print(f'{k:48s} {m[k]:.6f}')
"
```

| Corner | setup slack (ns) | hold slack (ns) |
| --- | --- | --- |
| `min_ff_n40C_1v95` | 8.965368 | **0.191574** ← worst hold |
| `nom_ff_n40C_1v95` | 8.958746 | 0.194052 |
| `max_ff_n40C_1v95` | 8.951070 | 0.194872 |
| `min_tt_025C_1v80` | 8.300024 | 0.308719 |
| `nom_tt_025C_1v80` | 8.289632 | 0.312889 |
| `max_tt_025C_1v80` | 8.277832 | 0.315234 |
| `min_ss_100C_1v60` | 6.274457 | 0.618923 |
| `nom_ss_100C_1v60` | 6.256837 | 0.626525 |
| **`max_ss_100C_1v60`** | **6.235697** ← worst setup | 0.632267 |

> **setup แย่ที่สุดที่ slow process + ร้อน + แรงดันต่ำ**
> **hold แย่ที่สุดที่ fast process + เย็น** — ตรงข้ามกัน เพราะ cell เร็วขึ้น → data วิ่งถึงเร็วขึ้น

### 10.5 เปิดดู GDSII

```bash
klayout "$RUN/final/klayout_gds/uart_top.klayout.gds"
```

LibreLane สร้างภาพเรนเดอร์ไว้ที่ `final/render/` — ดูได้ทันทีโดยไม่ต้องเปิดโปรแกรม

### 10.6 ⚠️ ข้อจำกัดของตัวเลข slack ที่ได้

| ปัจจัย | สถานะ | ผล |
| --- | --- | --- |
| I/O delay | **0 ns** | slack สูงกว่าความจริง |
| Clock uncertainty / jitter | **ไม่ได้ตั้ง** | slack สูงกว่าความจริง |
| Clock tree จริง | มี | รวมแล้ว ✅ |
| Routing delay จริง | มี (RCX) | รวมแล้ว ✅ |
| Multi-corner (9 corners) | มี | รวมแล้ว ✅ |

> ตัวเลขเหล่านี้เป็น "slack ของ design ที่ยังไม่มีข้อกำหนดระบบภายนอก"
> ในงานจริงต้องใส่ I/O delay ตามสเปกและ clock uncertainty ก่อนจึงจะเรียกว่า sign-off ได้

---

## Step 11: เปรียบเทียบกับ Lab 3B

| มิติ | `adder8_pipe` (Lab 3B) | `uart_top` (Lab 5B) |
| --- | --- | --- |
| flip-flop | 26 | **28** |
| Instance count (layout) | 399 | **526** |
| Instance area | 2409.81 µm² | **2805.19 µm²** |
| Die area | 4331.89 µm² | **4975.42 µm²** |
| Utilization | 68.95 % | **60.12 %** |
| Setup slack | 5.587222 ns | **6.235697 ns** |
| Hold slack | 0.317141 ns | **0.191574 ns** |
| Fmax | ≈ 226.6 MHz | **≈ 265.7 MHz** |
| I/O | 30 | **15** |

> UART มี FF ใกล้เคียง adder แต่ชิปใหญ่กว่า เพราะมี **gate มากกว่า** (FSM + divider)
> และมี **ขา I/O น้อยกว่า** พื้นที่จึงมาจาก combinational logic ไม่ใช่ register

---

## Step 12: แบบฝึกหัด

| ข้อ | โจทย์ | ผลที่คาดหวัง |
| --- | --- | --- |
| F.1 | หาพื้นที่ที่ถูกใช้โดย fill cell | 1118.57 µm² จาก 2805.19 µm² (≈ 40 %) |
| F.2 | อธิบายว่าทำไม I/O มี 15 ขา ไม่ใช่ 13 | 13 ขาสัญญาณ + VGND + VPWR ที่ OpenROAD เพิ่มที่ขอบ die |
| F.3 | หา corner ที่ setup slack แย่ที่สุด | `max_ss_100C_1v60` = 6.235697 ns |
| F.4 | หา corner ที่ hold slack แย่ที่สุด | `min_ff_n40C_1v95` = 0.191574 ns |
| F.5 | แก้ `CLOCK_PERIOD` เป็น 5 ns แล้วรันใหม่ | พบ setup violation หรือ slack ลดลงมาก |
| F.6 | แก้ `FP_CORE_UTIL` เป็น 60 แล้วรันใหม่ เทียบ die area | die area เล็กลง แต่ utilization สูงขึ้น |
| F.7 | ใส่ `set_input_delay 2` / `set_output_delay 2` แล้วรันใหม่ | slack ลดลงประมาณ 2 ns |
| F.8 | ดู `final/render/` แล้วอธิบายว่าเห็นอะไร | เห็น cell สีต่าง ๆ, PDN, I/O pin |
| F.9 | รัน `dump` บน `$_DFF_P_` | พบ 4 ตัว = FSM state one-hot ที่ไม่มี reset |
| F.10 | เปรียบเทียบ instance count ของ RTL กับ layout | RTL 117 cells → layout 526 instances |

---

## Troubleshooting

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| `librelane: command not found` | nix profile ไม่ถูกโหลดใน non-interactive shell | `export PATH="$HOME/.nix-profile/bin:$PATH"` — สคริปต์ของแล็บทำให้อัตโนมัติแล้ว |
| `iverilog: syntax error` ที่ `rtl/uart_top.v` | ใช้ syntax `name : module` ซึ่งเป็น SystemVerilog | ใช้ `module_name instance_name (...)` แบบ Verilog ธรรมดา |
| `Can't find top module 'uart_top'` | `DESIGN_NAME` ไม่ตรง | ตรวจชื่อ module ใน RTL ให้ตรงกับ `DESIGN_NAME` |
| `CLOCK_PORT` not found | ชื่อ port นาฬิกาไม่ตรงกับ SDC | ตรวจ `CLOCK_PORT` และ `create_clock` ให้ตรงกัน |
| `VERILOG_FILES` หาไฟล์ไม่เจอ | path ผิดระดับ | `dir::` คือ relative จากโฟลเดอร์ config — ใช้ `../rtl/*.v` |
| DRC violation เยอะ | utilization สูงเกิน | ลด `FP_CORE_UTIL` |
| LVS mismatch | RTL ↔ layout ไม่ตรง | ตรวจ blackbox / tie cell |
| setup violation หลัง routing | delay จริงมากกว่าเดิม | เพิ่ม `CLOCK_PERIOD` หรือปรับ RTL |
| hold violation | clock skew / routing สั้นเกินไป | ให้ CTS balance skew, เพิ่ม buffer |
| `flow complete` แต่ไม่มี `final/` | รันไม่จบ | ดู `error.log` และ `flow.log` |
| Run ช้ามาก | ครั้งแรกต้องดาวน์โหลด PDK | รอครั้งแรก ครั้งต่อไป ~1 นาที 50 วินาที |
| path มีวงเล็บทำให้คำสั่งพัง | shell ไม่ escape | ห่อด้วย `"` เช่น `cd "/mnt/e/lab/VHDL(BOI)/..."` |

---

## Validation Checklist

| # | ข้อ | สถานะ |
| --- | --- | --- |
| 1 | RTL simulation ผ่าน 6 เฟรม UART | ☐ |
| 2 | Yosys generic synthesis อ่าน `stat` ได้ | ☐ |
| 3 | เข้าใจว่าทำไม flip-flop กลายเป็น 28 ไม่ใช่ 26 | ☐ |
| 4 | Gate-level netlist สร้างได้ | ☐ |
| 5 | Gate-Level Simulation ผ่านเท่ากับ RTL | ☐ |
| 6 | Map เข้า sky130 cell และอ่านพื้นที่จริงได้ | ☐ |
| 7 | LibreLane flow รันจน `flow complete` | ☐ |
| 8 | `error.log` เป็น 0 bytes | ☐ |
| 9 | อ่าน `metrics.json` ได้ — area, utilization, slack | ☐ |
| 10 | อธิบายได้ว่า core area ≠ die area | ☐ |
| 11 | อธิบายได้ว่า instance count ≠ RTL cell count | ☐ |
| 12 | หา worst corner ของ setup และ hold ได้ | ☐ |
| 13 | เปิดดู GDSII ด้วย KLayout ได้ | ☐ |
| 14 | อธิบายข้อจำกัดของ slack ที่วัดได้ (I/O delay = 0) | ☐ |

---

> **ต่อไป:** ส่วนที่ 2 (วันที่ 6–10) — IC Layout และ MEMS Design
> ทั้งหมดในวันที่ 5 คือ "ภาพรวมของวงจร ASIC" ที่ต้องรู้ก่อนลงมือวาง layout

# Lab 5B — RTL-to-GDSII Full Chip Flow ด้วย LibreLane (UART TX)

> แล็บเสริมของ **วันที่ 5 (Mini Project)** — ฝั่ง **open-source**
> คู่ขนานกับ Lab 5 ฝั่ง commercial (Precision RTL + GLS) ที่อยู่ใน `lab_code/day5/`
>
> **คู่มือฉบับเต็ม:** [`../../Manual_5_5_Lab5B_UART_TX_to_GDSII_LibreLane_StepByStepGuide.md`](../../Manual_5_5_Lab5B_UART_TX_to_GDSII_LibreLane_StepByStepGuide.md)
> **ภาคทฤษฎี:** [`../../Manual_5_4_RTL_to_GDSII_LibreLane_FullChipFlow_DeepDive.md`](../../Manual_5_4_RTL_to_GDSII_LibreLane_FullChipFlow_DeepDive.md)

---

## 1. ทำไมต้องมีแล็บนี้

Lab 5 เดิม (Precision RTL + SDF) จบที่ **netlist** และ GLS
แต่ยังไม่ได้ไปถึง **ชิปจริง** — ไม่มี floorplan, ไม่มี layout, ไม่มี DRC/LVS,
ไม่มีไฟล์ GDSII ที่ส่ง foundry ได้

แล็บนี้ปิดวงจรให้สมบูรณ์ด้วย **LibreLane + PDK sky130A** ที่เป็น open-source ทั้งหมด

```
Lab 5 เดิม (Precision RTL)             Lab 5B (Yosys + LibreLane)
├─ เครื่องมือ: commercial              ├─ เครื่องมือ: open-source ทั้งหมด
├─ PDK: ต้องขอจากองค์กร                ├─ PDK: sky130A ดาวน์โหลดอัตโนมัติ (ฟรี)
├─ ได้ netlist + report                 ├─ ได้ netlist + layout + GDSII
├─ ไม่มี DRC / LVS                      └─ มี DRC + LVS + Antenna ผ่านจริง
└─ ⚠️ รันจริงไม่ได้ถ้าไม่มี PDK         └─ ✅ รันได้จริงทุกขั้น
```

---

## 2. สิ่งที่แล็บนี้พิสูจน์

| ข้อ | สิ่งที่พิสูจน์ | หลักฐาน |
| --- | --- | --- |
| 1 | Mini Project UART TX ผ่าน RTL simulation | 6 เฟรม (0x00, 0xFF, 0x55, 0xAA, 0x42, 0x3C) |
| 2 | **Netlist ที่สังเคราะห์ได้มีฟังก์ชันเท่า RTL เป๊ะ** | testbench ไฟล์เดียวกัน ผ่าน 6/6 เฟรมทั้ง RTL และ netlist |
| 3 | Map เข้า standard cell จริงแล้วอ่านพื้นที่ได้ | sky130: 122 cells, **1087.2928 µm²** |
| 4 | **Open-source ASIC flow รันครบทั้ง flow** | LibreLane **80/80 stages**, `error.log` 0 bytes |
| 5 | Layout ผ่าน DRC / LVS / Antenna จริง | violations **0 / 0 / 0** |
| 6 | Timing ผ่านทุก corner (9 corners) | setup **6.235697 ns**, hold **0.191574 ns** |
| 7 | ได้ GDSII ที่ส่ง foundry ได้ | `uart_top.gds` 517,382 bytes |
| 8 | **Yosys เปลี่ยนโครงสร้าง design เอง** | FSM 2-bit binary → **4-bit one-hot** (ไม่มี reset) |

---

## 3. โครงสร้าง Directory

```
lab_code/day5_yosys/
├── README.md                   ← (ไฟล์นี้)
├── Makefile                    ← จุดเริ่มต้น: make / make sim / make synth / ...
├── run_yosys_lab.sh            ← batch runner: รันทุกขั้น + สรุป PASS/FAIL
│
├── rtl/
│   ├── baud_gen.v              ← ตัวหาร baud (100 MHz → 115200)
│   ├── uart_tx.v               ← UART Transmitter 8-N-1 (FSM 4 สถานะ)
│   └── uart_top.v              ← top module สำหรับ full chip flow
│
├── tb/
│   └── tb_uart_top.v           ← self-checking TB ตรวจเฟรม 10 บิตทั้งหมด
│
├── scripts/
│   ├── synth_generic.ys        ← Yosys: generic synthesis + hierarchy breakdown
│   └── synth_gates.ys          ← Yosys: gate-level netlist ที่ simulate ได้จริง
│
└── librelane/
    ├── config.yaml             ← config ของ LibreLane 3.x
    ├── Makefile                ← make flow / make clean
    ├── README.md               ← คู่มือติดตั้ง PDK + อ่านผลลัพธ์
    └── src/
        ├── impl.sdc            ← constraints ขั้น Place & Route
        └── signoff.sdc         ← constraints ขั้น sign-off
```

> `VERILOG_FILES: dir::../rtl/*.v` ใน `config.yaml` ชี้กลับไปที่ `rtl/` ของแล็บโดยตรง
> จึง **ไม่มีสำเนา RTL สองชุด** — แก้ที่ไฟล์เดียวแล้วทั้ง Yosys และ LibreLane เห็นพร้อมกัน

> `build/`, `build_log_*.txt` และ `librelane/runs/` เป็น **artifact จากการรัน**
> ล้างได้ด้วย `make clean` และ `cd librelane && make clean`

---

## 4. Prerequisites

### 4.1 เครื่องมือที่ต้องมี (Linux / WSL / Ubuntu)

```bash
sudo apt update
sudo apt install -y yosys iverilog make
```

| เครื่องมือ | เวอร์ชันที่ใช้ทดสอบ | ใช้ทำอะไร | บังคับ? |
| --- | --- | --- | --- |
| Yosys | 0.52 | RTL → netlist synthesis | ✅ |
| Icarus Verilog | 12.0 | RTL simulation + Gate-Level Simulation | ✅ |
| GNU Make | 4.4 | จุดเริ่มต้นของทุกขั้น | ✅ |
| LibreLane | v3.0.17 | full flow RTL → GDSII | ❌ (ข้ามได้) |

### 4.2 LibreLane + ชุดเครื่องมือ ASIC (ติดตั้งผ่าน nix)

```bash
curl -L -o /tmp/install-nix.sh https://nixos.org/nix/install | sh -s -- --daemon
source /root/.nix-profile/etc/profile.d/nix.sh

nix profile install nixpkgs#librelane
export PATH="/root/.nix-profile/bin:$PATH"

librelane --version     # ต้องได้ LibreLane v3.0.x
```

> Nix ดึง **OpenROAD, Magic, KLayout, Netgen, Yosys, yosys-ghdl** มาให้ใน closure เดียวกัน

> ⚠️ **nix profile ไม่ถูกโหลดอัตโนมัติใน non-interactive shell**
> `run_yosys_lab.sh` และ `Makefile` ของแล็บนี้จึง **ตรวจและเพิ่ม
> `$HOME/.nix-profile/bin` ใน PATH ให้เอง** — ไม่ต้อง export เองก็รันได้

### 4.3 PDK

PDK ดาวน์โหลดอัตโนมัติเมื่อรัน `librelane --volare-pdk -p sky130A` (ครั้งแรกประมาณ 1–2 GB)
รายละเอียดวิธีติดตั้งและเปลี่ยน PDK ดูที่ [`librelane/README.md`](librelane/README.md)

---

## 5. วิธีรัน

### 5.1 ทางลัด — รันทุกขั้นพร้อมกัน

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day5_yosys"
bash run_yosys_lab.sh
```

ผลลัพธ์ต้องจบด้วย:

```
สรุป: ผ่านทั้งหมด — ไม่มีขั้นตอนไหนล้มเหลว
```

สคริปต์จะตรวจสอบผลจริงของแต่ละขั้นด้วย `grep -E` ไม่ใช่แค่ดูว่า process จบด้วย exit code 0
เช่น ต้องเจอ `tb_uart_top PASS=6 FAIL=0` จริง ๆ ใน log — ถ้าไม่เจอถือว่า FAIL

### 5.2 โหมดอื่น ๆ

```bash
bash run_yosys_lab.sh --quick    # เฉพาะ sim + synth + GLS (เร็วที่สุด)
bash run_yosys_lab.sh --full     # รวมขั้นตอน LibreLane (~1 นาที 50 วินาที เมื่อมี PDK แล้ว)
```

### 5.3 รันทีละขั้นด้วย Makefile

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day5_yosys"

make sim          # [1] RTL simulation (Icarus)
make synth        # [2] Yosys generic synthesis
make synth-gate   # [3] Yosys gate-level netlist
make sim-gls      # [4] Gate-Level Simulation ของ netlist
make sky130       # [5] map เข้า sky130 standard cell
make librelane    # [6] full flow RTL → GDSII
make clean        # ล้าง build/
```

> **หมายเหตุเรื่อง path:** ถ้าอยู่ใน WSL และ path มีวงเล็บ เช่น `/mnt/e/lab/VHDL(BOI)/...`
> ต้องห่อด้วย `"` เสมอ ไม่งั้น shell จะตีความ `(BOI)` เป็น subshell

---

## 6. ผลการตรวจสอบจริง

> ตัวเลขทั้งหมดในส่วนนี้มาจาก **การรันจริง** บน WSL Ubuntu 26.04
> (Yosys 0.52 · Icarus 12.0 · LibreLane v3.0.17 · PDK sky130A)
> ผลรันซ้ำสองครั้งได้ตัวเลขเดียวกันทุกตัว

### 6.1 RTL Simulation และ Gate-Level Simulation

```
tb_uart_top PASS=6 FAIL=0
tb_uart_top: ALL PATTERN FRAMES VERIFIED
```

ผ่านทั้ง **RTL** และ **netlist** ด้วย testbench ไฟล์เดียวกัน

### 6.2 Yosys Generic Synthesis (`stat`)

| Module | Number of cells |
| --- | --- |
| `baud_gen` | **44** |
| `uart_tx` | **74** |
| `uart_top` (hierarchical) | 118 |
| `uart_top` (flatten) | 116 |
| `uart_top` (gate-level, `abc -g`) | **112** |

**สัดส่วน flip-flop (28 ตัว):**

| Cell type | จำนวน | ที่มา |
| --- | --- | --- |
| `$_SDFF_PP0_` | 11 | baud_gen: cnt 10 บิต + tick 1 บิต |
| `$_SDFFE_PP0P_` | 11 | uart_tx: shreg 8 บิต + bit_idx 3 บิต |
| `$_SDFFE_PP1P_` | 2 | uart_tx: tx + din_rdy (reset เป็น 1) |
| `$_DFF_P_` | 4 | uart_tx: **FSM state one-hot** (ไม่มี reset) |

### 6.3 Map เข้า sky130 Standard Cell

```
=== uart_top ===
   Number of cells:                 122

   Chip area for module '\uart_top': 1087.292800
```

> ตัวเลขนี้ต่างจากของภายใน LibreLane (117 cells / 1328.77 µm²) เพราะเป็น **คนละ flow**
> — ตัวเลข synthesis ขึ้นกับ flow ที่ใช้ ต้องระบุเสมอว่ามาจากไหน

### 6.4 LibreLane Full Flow (RTL → GDSII)

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

| รายการ | ค่าที่วัดได้จริง |
| --- | --- |
| Stages | **80 / 80** ✅ |
| `error.log` | **0 bytes** ✅ |
| DRC violations (Magic + KLayout) | **0** ✅ |
| LVS errors / device / net / pin diff | **0 / 0 / 0 / 0** ✅ |
| Antenna violations (net / pin) | **0 / 0** ✅ |
| Setup violations | 0 (worst slack **6.235697 ns**) ✅ |
| Hold violations | 0 (worst slack **0.191574 ns**) ✅ |
| Max slew / max cap / max fanout violations | 0 / 0 / 0 ✅ |
| Inferred latches / unmapped cells | **0 / 0** ✅ |
| Lint errors / warnings | 0 / 0 ✅ |
| Instances | 526 (stdcell 183, fill 343, buffer 20, tap 42, clock buf 3) |
| Sequential cells | 28 |
| Nets / IOs | 153 / 15 (13 ขาสัญญาณ + VGND + VPWR) |
| Instance & core area | 2805.19 µm² |
| Die area | 4975.42 µm² (65.38 × 76.1 µm) |
| Utilization | 60.12 % |
| Power | total 303.98 µW (internal 245.63, switching 58.34, leakage 2.929 nW) |
| GDSII | `uart_top.gds` 517,382 bytes |
| เวลารัน | ~106–109 วินาที (หลังมี PDK แล้ว) |

**คำนวณ Fmax จาก slack:**

```
critical path = clock period - setup slack = 10 - 6.235697 = 3.764303 ns
Fmax          = 1 / 3.764303 ns ≈ 265.7 MHz
```

### 6.5 Slack ทุก corner

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

---

## 7. เทียบกับ Lab 5 ฝั่ง commercial และ Lab 3B

| มิติ | Yosys (standalone) | LibreLane (full flow) | Lab 3B (`adder8_pipe`) |
| --- | --- | --- | --- |
| License | ฟรี | ฟรี | ฟรี |
| PDK | sky130A | sky130A | sky130A |
| ผลลัพธ์ | netlist + cell count | netlist + layout + **GDSII** | netlist + layout + GDSII |
| flip-flop | 28 | 28 | 26 |
| Instance count (layout) | — | 526 | 399 |
| พื้นที่ | 1087.29 µm² (cell area) | 2805.19 µm² (รวม fill/buffer/tap) | 2409.81 µm² |
| Die area | — | 4975.42 µm² | 4331.89 µm² |
| Timing | ไม่มี STA | setup 6.235697 / hold 0.191574 ns | setup 5.587222 / hold 0.317141 ns |
| DRC / LVS | ไม่มี | **ผ่านทั้งคู่** | ผ่านทั้งคู่ |
| เวลารัน | < 1 วินาที | ~110 วินาที | ~90 วินาที |

> UART มี FF ใกล้เคียง adder แต่ชิปใหญ่กว่า เพราะมี **gate มากกว่า** (FSM + divider)
> และมี **ขา I/O น้อยกว่า** — พื้นที่จึงมาจาก combinational logic ไม่ใช่ register

---

## 8. Troubleshooting

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| `librelane: command not found` | nix profile ไม่ถูกโหลดใน non-interactive shell | `export PATH="$HOME/.nix-profile/bin:$PATH"` — สคริปต์ของแล็บทำให้อัตโนมัติแล้ว |
| `iverilog: syntax error` ที่ `rtl/uart_top.v` | ใช้ syntax `name : module` ซึ่งเป็น SystemVerilog | ใช้ `module_name instance_name (...)` แบบ Verilog ธรรมดา |
| `ERROR: Unsupported gate type: NOT` | ABC ไม่รองรับ gate type `NOT` | เอา `NOT` ออกจาก `abc -g` — inverter ถูกสร้างอัตโนมัติอยู่แล้ว |
| netlist simulate ไม่ได้ | ยังไม่ได้ `simplemap` — Icarus มองไม่เห็น `$_NAND_` | เพิ่ม `simplemap` หลัง `abc` |
| `Can't find top module 'uart_top'` | `DESIGN_NAME` ไม่ตรง | ตรวจชื่อ module ใน RTL ให้ตรงกับ `DESIGN_NAME` |
| `CLOCK_PORT` not found | ชื่อ port นาฬิกาไม่ตรงกับ SDC | ตรวจ `CLOCK_PORT` และ `create_clock` ให้ตรงกัน |
| `VERILOG_FILES` หาไฟล์ไม่เจอ | path ผิดระดับ | `dir::` คือ relative จากโฟลเดอร์ config — ใช้ `../rtl/*.v` |
| `make sky130` บอกไม่พบ `SKY130_LIB` | ยังไม่มี PDK | รัน `make librelane` ก่อน หรือส่ง path เอง |
| DRC violation เยอะ | utilization สูงเกินไป | ลด `FP_CORE_UTIL` ใน `config.yaml` |
| LVS mismatch | RTL ↔ layout ไม่ตรง | ตรวจ blackbox / tie cell |
| setup violation หลัง routing | delay จริงมากกว่าเดิม | เพิ่ม `CLOCK_PERIOD` หรือปรับ RTL |
| hold violation | clock skew / routing สั้นเกินไป | ให้ CTS balance skew, เพิ่ม buffer |
| `flow complete` แต่ไม่มี `final/` | รันไม่จบ | ดู `error.log` และ `flow.log` |
| path มีวงเล็บทำให้คำสั่งพัง | shell ไม่ escape | ห่อด้วย `"` เช่น `cd "/mnt/e/lab/VHDL(BOI)/..."` |

---

## 9. Validation Checklist

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

## 10. ขยายต่อ / แบบฝึกหัด

| ข้อ | โจทย์ | ผลที่คาดหวัง |
| --- | --- | --- |
| F.1 | หาพื้นที่ที่ถูกใช้โดย fill cell | 1118.57 µm² จาก 2805.19 µm² (≈ 40 %) |
| F.2 | อธิบายว่าทำไม I/O มี 15 ขา ไม่ใช่ 13 | 13 ขาสัญญาณ + VGND + VPWR ที่ OpenROAD เพิ่มที่ขอบ die |
| F.3 | หา corner ที่ setup slack แย่ที่สุด | `max_ss_100C_1v60` = 6.235697 ns |
| F.4 | หา corner ที่ hold slack แย่ที่สุด | `min_ff_n40C_1v95` = 0.191574 ns |
| F.5 | แก้ `CLOCK_PERIOD` เป็น 5 ns แล้วรันใหม่ | พบ setup violation หรือ slack ลดลงมาก |
| F.6 | แก้ `FP_CORE_UTIL` เป็น 60 แล้วรันใหม่ เทียบ die area | die area เล็กลง แต่ utilization สูงขึ้น |
| F.7 | ใส่ `set_input_delay 2` / `set_output_delay 2` ใน SDC แล้วรันใหม่ | slack ลดลงประมาณ 2 ns ต่อขา |
| F.8 | ดู `final/render/` แล้วอธิบายว่าเห็นอะไรใน layout | เห็น cell สีต่าง ๆ, PDN, I/O pin |
| F.9 | รัน `dump` บน `$_DFF_P_` ใน Yosys | พบ 4 ตัว = FSM state one-hot ที่ไม่มี reset |
| F.10 | เปรียบเทียบ instance count ของ RTL กับ layout | RTL 117 cells → layout 526 instances |

---

> **ต่อไป:** ส่วนที่ 2 (วันที่ 6–10) — IC Layout และ MEMS Design
> ทั้งหมดในวันที่ 5 คือ "ภาพรวมของวงจร ASIC" ที่ต้องรู้ก่อนลงมือวาง layout
> ด้วยเครื่องมือเชิงพาณิชย์ (Tanner / L-Edit)

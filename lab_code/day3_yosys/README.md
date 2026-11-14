# Lab 3B — การสังเคราะห์ด้วย Yosys และ Open-source ASIC Flow (LibreLane)

> แล็บเสริมของ **วันที่ 3 (RTL Synthesis and Optimization)** — ฝั่ง **open-source**
> คู่ขนานกับ Lab 3 ฝั่ง commercial (Precision RTL) ที่อยู่ใน `lab_code/day3/`
>
> **คู่มือฉบับเต็ม:** [`../../Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md`](../../Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md)
> **ภาคทฤษฎี:** [`../../Manual_3_5_Yosys_and_LibreLane_Synthesis_DeepDive.md`](../../Manual_3_5_Yosys_and_LibreLane_Synthesis_DeepDive.md)

---

## 1. ทำไมต้องมีแล็บนี้

Lab 3 เดิม (Precision RTL) ใช้เครื่องมือ commercial ที่ต้องขอ **PDK ขององค์กร**
(เช่น TSMC / GlobalFoundries / IHP SG13G2) มาใช้ ทำให้นักเรียนที่ไม่มีสิทธิ์เข้าถึง PDK
**รันสังเคราะห์จริงไม่ได้** เห็นแต่ตัวอย่างภาพหน้าจอ

แล็บนี้แก้ปัญหานั้นด้วย **Yosys + LibreLane + PDK sky130A** ที่เป็น open-source ทั้งหมด
นักเรียนจึงได้ **รัน flow ตั้งแต่ RTL → GDSII จริง** พร้อมตัวเลขจริง (cell count, area, slack, DRC/LVS)
โดยไม่ต้องขอ license ใด ๆ

```
Lab 3 เดิม (Precision RTL)          Lab 3B (Yosys + LibreLane)
├─ เครื่องมือ: commercial           ├─ เครื่องมือ: open-source ทั้งหมด
├─ PDK: ต้องขอจากองค์กร             ├─ PDK: sky130A ดาวน์โหลดอัตโนมัติ (ฟรี)
├─ ได้ netlist + report              ├─ ได้ netlist + layout + GDSII + DRC/LVS
└─ ⚠️ รันจริงไม่ได้ถ้าไม่มี PDK      └─ ✅ รันได้จริงทุกขั้น
```

---

## 2. สิ่งที่แล็บนี้พิสูจน์

| ข้อ | สิ่งที่พิสูจน์ | หลักฐาน |
| --- | --- | --- |
| 1 | Yosys ย่อย RTL → logic สามารถได้ | `stat` รายงาน cell ต่อชนิด |
| 2 | **Netlist ที่สังเคราะห์ได้มีฟังก์ชันเท่า RTL เป๊ะ** | testbench ไฟล์เดียวกัน ผ่าน 131,072 patterns ทั้ง RTL และ netlist |
| 3 | VHDL เข้า Yosys ได้ (ผ่าน GHDL) | `rtl/adder8.vhd` → netlist → ผ่าน 131,072 patterns |
| 4 | RTL รูปแบบต่างให้ผลสังเคราะห์ต่างกัน | Verilog 52 cells vs VHDL 88 cells (ต่าง 69 %) |
| 5 | Map เข้า standard cell จริงแล้วอ่านพื้นที่ได้ | sky130: 24 cells, **220.2112 µm²** |
| 6 | Open-source ASIC flow รันครบทั้ง flow | LibreLane **80/80 stages**, DRC/LVS/Antenna ผ่าน, ได้ GDSII |

---

## 3. โครงสร้าง Directory

```
lab_code/day3_yosys/
├── README.md                   ← (ไฟล์นี้)
├── Makefile                    ← จุดเริ่มต้น: make / make sim / make synth / ...
├── run_yosys_lab.sh            ← batch runner: รันทุกขั้น + สรุป PASS/FAIL
│
├── rtl/
│   ├── adder8.v                ← 8-bit adder แบบ combinational (Verilog)
│   ├── adder8_pipe.v           ← 8-bit adder แบบ 2-stage pipeline (Verilog)
│   └── adder8.vhd              ← เวอร์ชัน VHDL (ใช้ทดสอบสะพาน GHDL)
│
├── tb/
│   ├── tb_adder8.v             ← exhaustive 131,072 patterns (a × b × cin)
│   └── tb_adder8_pipe.v        ← ตรวจ latency ของ pipeline (64 checks)
│
├── scripts/
│   ├── synth_generic.ys        ← Yosys: generic synthesis (ไม่ต้องมี PDK)
│   ├── synth_gates.ys          ← Yosys: gate-level netlist ที่ simulate ได้จริง
│   └── ghdl_to_verilog.sh      ← สะพาน VHDL → Verilog (GHDL)
│
├── librelane/
│   ├── config.yaml             ← config ของ LibreLane 3.x
│   ├── Makefile                ← make flow / make clean
│   ├── README.md               ← คู่มือติดตั้ง PDK + อ่านผลลัพธ์
│   └── src/
│       ├── adder8_pipe.v       ← RTL สำหรับ full flow (สำเนาจาก rtl/)
│       ├── impl.sdc            ← constraints ขั้น Place & Route
│       └── signoff.sdc         ← constraints ขั้น sign-off
│
└── build/                      ← ผลลัพธ์ (สร้างอัตโนมัติ — ลบได้ด้วย make clean)
```

> `build/`, `build_log_*.txt` และ `librelane/runs/` เป็น **artifact จากการรัน** ไม่ต้องแนบไปกับงานส่งมอบ
> ใช้ `make clean` และ `cd librelane && make clean` เพื่อล้าง

---

## 4. Prerequisites

### 4.1 เครื่องมือที่ต้องมี (Linux / WSL / Ubuntu)

```bash
sudo apt update
sudo apt install -y yosys iverilog ghdl make
```

| เครื่องมือ | เวอร์ชันที่ใช้ทดสอบ | ใช้ทำอะไร | บังคับ? |
| --- | --- | --- | --- |
| Yosys | 0.52 | RTL → netlist synthesis | ✅ |
| Icarus Verilog | 12.0 | RTL simulation + Gate-Level Simulation | ✅ |
| GNU Make | 4.4 | จุดเริ่มต้นของทุกขั้น | ✅ |
| GHDL | 5.0.1 | สะพาน VHDL → Verilog | ❌ (ข้ามได้) |
| LibreLane | v3.0.17 | full flow RTL → GDSII | ❌ (ข้ามได้) |

### 4.2 LibreLane + ชุดเครื่องมือ ASIC (ติดตั้งผ่าน nix)

```bash
curl -L -o /tmp/install-nix.sh https://nixos.org/nix/install | sh -s -- --daemon
source /root/.nix-profile/etc/profile.d/nix.sh

nix profile install nixpkgs#librelane
export PATH="/root/.nix-profile/bin:$PATH"

librelane --version     # ต้องได้ LibreLane v3.0.x
```

> Nix ดึง **OpenROAD, Magic, KLayout, Netgen, Yosys, yosys-ghdl** มาให้ใน closure เดียวกัน — ไม่ต้องติดตั้งแยก

### 4.3 PDK

PDK ดาวน์โหลดอัตโนมัติเมื่อรัน `librelane --volare-pdk -p sky130A` (ครั้งแรกประมาณ 1–2 GB)
รายละเอียดวิธีติดตั้งและเปลี่ยน PDK ดูที่ [`librelane/README.md`](librelane/README.md)

---

## 5. วิธีรัน

### 5.1 ทางลัด — รันทุกขั้นพร้อมกัน

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3_yosys"
bash run_yosys_lab.sh
```

ผลลัพธ์ต้องจบด้วย:

```
สรุป: ผ่านทั้งหมด — ไม่มีขั้นตอนไหนล้มเหลว
```

สคริปต์จะตรวจสอบผลจริงของแต่ละขั้นด้วย `grep -E` ไม่ใช่แค่ดูว่า process จบด้วย exit code 0
เช่น ต้องเจอ `tb_adder8 PASS=131072 FAIL=0` จริง ๆ ใน log — ถ้าไม่เจอถือว่า FAIL

### 5.2 โหมดอื่น ๆ

```bash
bash run_yosys_lab.sh --quick    # เฉพาะ sim + synth + GLS (เร็วที่สุด)
bash run_yosys_lab.sh --full     # รวมขั้นตอน LibreLane (~90 วินาที เมื่อมี PDK แล้ว)
```

### 5.3 รันทีละขั้นด้วย Makefile

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3_yosys"

make sim          # [1] RTL simulation (Icarus)
make synth        # [2] Yosys generic synthesis
make synth-gate   # [3] Yosys gate-level netlist
make sim-gls      # [4] Gate-Level Simulation ของ netlist
make ghdl         # [5] VHDL → GHDL → Verilog → Yosys
make sky130       # [6] map เข้า sky130 standard cell
make librelane    # [7] full flow RTL → GDSII
make clean        # ล้าง build/
```

> **หมายเหตุเรื่อง path:** ถ้าอยู่ใน WSL และ path มีวงเล็บ เช่น `/mnt/e/lab/VHDL(BOI)/...`
> ต้องห่อด้วย `"` เสมอ ไม่งั้น shell จะตีความ `(BOI)` เป็น subshell

---

## 6. ผลการตรวจสอบจริง

> ตัวเลขทั้งหมดในส่วนนี้มาจาก **การรันจริง** บน WSL Ubuntu 26.04
> (Yosys 0.52 · Icarus 12.0 · GHDL 5.0.1 · LibreLane v3.0.17 · PDK sky130A)

### 6.1 RTL Simulation

```
tb_adder8      PASS=131072 FAIL=0
tb_adder8: ALL 131072 PATTERNS PASS
tb_adder8_pipe PASS=64     FAIL=0
tb_adder8_pipe: ALL TESTS PASS
```

### 6.2 Yosys Generic Synthesis (`stat`)

| Module | Number of cells | รายละเอียด |
| --- | --- | --- |
| `adder8` | **52** | `$_ANDNOT_` 16, `$_XNOR_` 8, `$_XOR_` 8, `$_NAND_` 7, `$_NOR_` 7, `$_OR_` 3, `$_AND_` 2, `$_ORNOT_` 1 |
| `adder8_pipe` | **78** | `$_ANDNOT_` 12, `$_XNOR_` 11, `$_OR_` 10, `$_NOR_` 6, `$_XOR_` 5, `$_AND_` 4, `$_NAND_` 4, **`$_SDFF_PP0_` 26** |

> ความต่าง 26 cell = flip-flop ของ pipeline (17 bit operand + 9 bit result)

### 6.3 Gate-Level Netlist และ Gate-Level Simulation

| Module | cells (netlist) | GLS ผ่าน? |
| --- | --- | --- |
| `adder8` | **41** | ✅ `PASS=131072 FAIL=0` |
| `adder8_pipe` | **66** | ✅ `PASS=64 FAIL=0` |

> **testbench ไฟล์เดียวกันเป๊ะ** ถูกใช้กับทั้ง RTL และ netlist
> จึงพิสูจน์ได้ว่า Yosys ไม่ทำให้ฟังก์ชันเพี้ยนในขอบเขต vector ที่ทดสอบ

### 6.4 สะพาน VHDL → GHDL → Verilog → Yosys

```
adder8 (จาก rtl/adder8.vhd)  Number of cells: 88
tb_adder8 PASS=131072 FAIL=0
```

| RTL | วิธีเขียน | Yosys cells |
| --- | --- | --- |
| `adder8.v` | `assign {cout,sum} = a+b+cin` | **52** |
| `adder8.vhd` | `vs := va+vb; if cin='1' then vs := vs+1;` | **88** |

> โค้ดทำงานเหมือนกันทุก pattern แต่ผลสังเคราะห์ต่างกัน **69 %**
> → บทเรียน: ต้องวัดผลหลังเขียน RTL เสมอ ไม่ใช่เชื่อว่า "ทำงานถูกแล้วก็ดี"

### 6.5 Map เข้า sky130 Standard Cell

```
=== adder8 ===
   Number of cells:                 24
     sky130_fd_sc_hd__maj3_1         8
     sky130_fd_sc_hd__xnor2_1       16

   Chip area for module '\adder8': 220.211200
     of which used for sequential elements: 0.000000 (0.00%)
```

### 6.6 LibreLane Full Flow (RTL → GDSII)

```
Classic - Stage 80 - Report Manufacturability ━━━━━━━━━━━━━━━━━━━━ 80/80 0:01:27

* Antenna   Passed ✅
* LVS       Passed ✅
* DRC       Passed ✅
```

| รายการ | ค่าที่วัดได้จริง |
| --- | --- |
| Stages | **80 / 80** ✅ |
| DRC violations | **0** ✅ |
| LVS errors | **0** ✅ |
| Antenna violations | **0** ✅ |
| Setup violations | 0 (worst slack **5.587 ns**) ✅ |
| Hold violations | 0 (worst slack **0.317 ns**) ✅ |
| Instances | **399** (stdcell 167, fill 232, buffer 44, tap 30) |
| Nets / IOs | 158 / 30 |
| Instance area | 2409.81 µm² |
| Core area | 2409.81 µm² |
| Die area | 4331.89 µm² (60.675 × 71.395 µm) |
| Utilization | 68.95 % |
| GDSII | `adder8_pipe.gds` 413,344 bytes |
| เวลารัน | ~87–98 วินาที (หลังมี PDK แล้ว) |

**คำนวณ Fmax จาก slack:**

```
critical path = clock period - setup slack = 10 - 5.587222 = 4.412778 ns
Fmax          = 1 / 4.412778 ns ≈ 226.6 MHz
```

> **ข้อสังเกตสำคัญ:** RTL cell count (24) ≠ final instance count (399)
> เพราะ OpenROAD เพิ่ม fill cell, clock buffer, timing-repair buffer และ tap cell
> เพื่อให้ layout สมบูรณ์ — ต้องอธิบายประเด็นนี้ในห้องเรียน

---

## 7. เทียบกับ Lab 3 ฝั่ง Precision RTL

| มิติ | Yosys (standalone) | LibreLane (full flow) | Precision RTL (Lab 3) |
| --- | --- | --- | --- |
| License | ฟรี (open-source) | ฟรี (open-source) | commercial |
| PDK | sky130A (ฟรี) | sky130A (ฟรี) | ต้องขอจากองค์กร |
| ผลลัพธ์ | netlist + cell count | netlist + layout + GDSII | netlist + report + SDF |
| พื้นที่ | 220.21 µm² (cell area) | 2409.81 µm² (รวม fill/buffer/tap) | ขึ้นกับ PDK |
| Timing | ไม่มี STA | setup 5.587 ns / hold 0.317 ns | มี STA + SDF |
| DRC / LVS | ไม่มี | ผ่านทั้งคู่ | ต้องมี Magic/IC Validator |
| เวลารัน | < 1 วินาที | ~90 วินาที | ~1–2 นาที |
| เหมาะกับ | สอนพื้นฐาน synthesis, CI, เครื่องไม่มี license | สอน full ASIC flow, layout, sign-off | สอน flow จริงของอุตสาหกรรม |

> ไม่ใช่การแข่งขันกัน แต่เป็น **สองมุมมองของงานเดียวกัน**
> นักเรียนควรรู้ว่า flow มาตรฐานเป็นแบบไหน (LibreLane) และ commercial tool
> ทำอะไรเพิ่ม (optimization, constraint, sign-off, integration กับ design house flow)

---

## 8. Troubleshooting

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| `yosys: command not found` | ไม่ได้ติดตั้ง / ไม่ได้อยู่ใน PATH | `sudo apt install yosys` |
| `ERROR: Unsupported gate type: NOT` | ABC ไม่รองรับ gate type `NOT` | เอา `NOT` ออกจาก `abc -g` — inverter ถูกสร้างอัตโนมัติอยู่แล้ว |
| `ERROR: Can't find top module` | ชื่อ top ไม่ตรงกับชื่อ module | ตรวจ `hierarchy -top` และ `DESIGN_NAME` ให้ตรงกัน |
| netlist simulate ไม่ได้ | ยังไม่ได้ `simplemap` — Icarus มองไม่เห็น `$_NAND_` | เพิ่ม `simplemap` หลัง `abc` |
| `ghdl: unknown command '--out=verilog'` | สลับลำดับ option (GHDL 5.x) | ใช้ `ghdl synth --std=08 --out=verilog top` |
| GHDL ไม่ได้ไฟล์ `.v` | GHDL พิมพ์ Verilog ออก stdout | redirect เอง: `... > out.v` |
| `librelane: command not found` | ยังไม่ได้ติดตั้งผ่าน nix | `nix profile install nixpkgs#librelane` + เพิ่ม PATH |
| ดาวน์โหลด PDK ไม่สำเร็จ | ปัญหาเครือข่าย | รันซ้ำ หรือติดตั้ง PDK เองแล้วใช้ `--manual-pdk` |
| `make sky130` บอกไม่พบ `SKY130_LIB` | ยังไม่มี PDK | รัน `make librelane` ก่อน หรือส่ง path เอง |
| DRC violation เยอะ | utilization สูงเกินไป | ลด `FP_CORE_UTIL` ใน `config.yaml` |
| LVS mismatch | RTL ↔ layout ไม่ตรง | ตรวจ blackbox / tie cell |
| path มีวงเล็บทำให้คำสั่งพัง | shell ไม่ escape | ห่อด้วย `"` เช่น `cd "/mnt/e/lab/VHDL(BOI)/..."` |
| Yosys `cells.lib` ใช้ map logic ไม่ได้ | `/usr/share/yosys/cells.lib` มีแต่ DFF ไม่มี gate | ใช้ Liberty ของ PDK จริง (ดู `make sky130`) |
| `grep` จับ pattern ไม่เจอ | BRE ไม่รองรับ `+` และ pattern ที่ขึ้นต้นด้วย `$_` ให้ผลผิด | ใช้ `grep -E` และเลี่ยง `$_` เช่น `SDFF_PP0_ +26` |

---

## 9. Validation Checklist

| # | ข้อ | สถานะ |
| --- | --- | --- |
| 1 | ตรวจสอบเครื่องมือครบ (yosys, iverilog, ghdl, librelane) | ☐ |
| 2 | RTL simulation ผ่าน 131,072 patterns | ☐ |
| 3 | Yosys generic synthesis อ่าน `stat` ได้ | ☐ |
| 4 | เข้าใจว่าทำไม `adder8_pipe` มี cell มากกว่า | ☐ |
| 5 | Gate-level netlist สร้างได้ | ☐ |
| 6 | Gate-Level Simulation ผ่านเท่ากับ RTL | ☐ |
| 7 | แปลง VHDL → Verilog ด้วย GHDL ได้ | ☐ |
| 8 | อธิบายได้ว่าทำไม VHDL ให้ cell มากกว่า (88 vs 52) | ☐ |
| 9 | Map เข้า sky130 cell และอ่านพื้นที่จริงได้ | ☐ |
| 10 | LibreLane รันครบ 80 stages | ☐ |
| 11 | อ่าน `metrics.json` และคำนวณ Fmax ได้ | ☐ |
| 12 | อธิบายได้ว่า RTL cell count ต่างจาก final instance count อย่างไร | ☐ |

---

## 10. ขยายต่อ / แบบฝึกหัด

| ข้อ | โจทย์ | ผลที่คาดหวัง |
| --- | --- | --- |
| Y.1 | เปรียบเทียบ cell count ของ `adder8` กับ `adder8_pipe` | 52 vs 78 — เพราะ flip-flop 26 ตัว |
| Y.2 | เขียน `adder8` เวอร์ชันใหม่ที่ใช้ cell น้อยลง แล้ววัดใหม่ | cell count ลดลง — อธิบายว่าแก้อะไร |
| Y.3 | อธิบายว่าการที่ testbench เดิมผ่านทั้ง RTL และ netlist พิสูจน์อะไร | functional equivalence ในขอบเขต vector ที่ทดสอบ |
| Y.4 | รัน `make sky130` แล้วหาพื้นที่จริง | 220.2112 µm² จาก 24 cells |
| Y.5 | แก้ `CLOCK_PERIOD` เป็น 5 ns ใน `config.yaml` แล้วรัน LibreLane ใหม่ | Fmax สูงขึ้น หรือพบ setup violation |
| Y.6 | เปลี่ยน `FP_CORE_UTIL` เป็น 60 แล้วรันใหม่ เทียบ die area | die area เล็กลง แต่ routing ยากขึ้น |
| Y.7 | ทำ formal equivalence ระหว่าง RTL กับ netlist | `equiv_status -assert` ผ่าน |
| Y.8 | สร้าง `adder8_pipe` เวอร์ชัน VHDL แล้วส่งผ่านสะพาน GHDL | ได้ netlist ที่ผ่านทุก pattern |

---

> **ต่อไป:** กลับไป Day 3 แล้วทำแล็บ Precision RTL (`lab_code/day3/`) จากนั้นเปรียบเทียบ
> รายงานของ commercial tool กับ open-source tool ที่ได้จากแล็บนี้

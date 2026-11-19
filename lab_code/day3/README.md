# Lab 3A — Precision RTL Synthesis (Day 3)

> คู่มือฉบับเต็ม: [`Manual_3_7_Lab3A_Precision_RTL_Synthesis_StepByStepGuide.md`](../../Manual_3_7_Lab3A_Precision_RTL_Synthesis_StepByStepGuide.md)
> หัวข้อในคู่มือหลัก: [`Manual_Part1_Day1-5.md`](../../Manual_Part1_Day1-5.md) §3.7
> แล็บคู่ขนาน (open-source): [`../day3_yosys/`](../day3_yosys/)

---

## 1. สิ่งที่ต้องรู้ก่อนเริ่ม

| | |
|---|---|
| เครื่องมือหลัก | **Siemens Precision RTL Synthesis** (ต้องมี license) |
| เครื่องมือสำรองที่รันได้จริงทุกเครื่อง | GHDL 5.0.1 + Yosys 0.52 + OpenSTA 2.7.0 + Icarus 12.0 (PDK sky130A) |
| RTL simulator | Questa / ModelSim 2026.1 (Windows) |

> **Precision RTL ไม่ได้ติดตั้งในเครื่องที่เขียนคู่มือฉบับนี้**
> ดังนั้นตัวเลขทุกตัวที่อยู่ในโฟลเดอร์นี้มาจาก **reference flow แบบ open-source** ที่รันจริง
> ไม่ใช่ตัวเลขของ Precision RTL — คู่มือจะไม่ใส่ตัวเลขที่ไม่ได้รันจริง

---

## 2. โครงสร้างโฟลเดอร์

```
day3/
├── rtl/                              ← RTL ที่จะสังเคราะห์ (5 ไฟล์)
│   ├── full_adder_struct.vhd
│   ├── adder8.vhd
│   ├── adder8_pipelined.vhd
│   ├── add_sub_shared.vhd
│   └── top.vhd
├── tb/                               ← testbench (4 VHDL + 4 Verilog สำหรับ GLS)
├── sdc/                              ← constraint แยกต่อ design (4 ไฟล์)
├── scripts/
│   ├── synth_top.tcl                 ← Precision RTL batch
│   ├── synth_adder8.tcl
│   ├── synth_adder8_pipelined.tcl
│   ├── synth_add_sub_shared.tcl
│   ├── check_sdc_ports.py            ← ตัวตรวจ SDC ↔ entity
│   ├── check_precision_tcl.py        ← ตัวตรวจสคริปต์ Tcl
│   ├── make_filtered_liberty.py      ← สร้าง Liberty ที่มี dont_use
│   ├── run_sta.tcl                   ← สคริปต์ OpenSTA
│   └── run_reference_flow.sh         ← reference flow แบบ open-source
├── run_lab3.do                       ← Questa batch ทั้งแล็บ
├── build/                            ← เอาต์พุต (สร้างอัตโนมัติ)
└── reports/                          ← หลักฐานจากการรันจริง
```

---

## 3. วิธีรัน

### 3.1 RTL simulation (Windows — Questa)

```powershell
cd "E:\lab\VHDL(BOI)\lab_code\day3"
vsim -do run_lab3.do -c
```

### 3.2 ตัวตรวจ SDC และ Tcl (ไม่ต้องมี EDA tool — ต้องมี Python 3.8+)

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3"
python3 scripts/check_sdc_ports.py             # ตรวจทุก design
python3 scripts/check_precision_tcl.py         # ตรวจทุกสคริปต์ Tcl
python3 scripts/check_sdc_ports.py --selftest  # พิสูจน์ว่าจับบั๊กเดิมได้
python3 scripts/check_precision_tcl.py --selftest
```

### 3.3 Reference flow แบบ open-source (Linux / WSL)

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3"
bash scripts/run_reference_flow.sh            # ทุก design
bash scripts/run_reference_flow.sh top        # design เดียว
```

ต้องมี: GHDL, Yosys, OpenSTA, Icarus และ PDK sky130A

### 3.4 Precision RTL (เครื่องที่มี license)

```bash
# 1) แก้ set tech_lib ใน scripts/synth_top.tcl ให้ชี้ไปที่ PDK ขององค์กร
# 2) รัน
precision -shell -file scripts/synth_top.tcl
```

---

## 4. ผลการรันจริง

> ตัวเลขทั้งหมดมาจาก reference flow แบบ open-source (GHDL 5.0.1 + Yosys 0.52 +
> OpenSTA 2.7.0 + Icarus 12.0, PDK sky130A) — **ไม่ใช่ตัวเลขของ Precision RTL**
> ดู [`reports/summary.txt`](reports/summary.txt) และ
> [`Manual_3_7_Lab3A_Precision_RTL_Synthesis_StepByStepGuide.md`](../../Manual_3_7_Lab3A_Precision_RTL_Synthesis_StepByStepGuide.md) หัวข้อ 9

| design | generic cells | sky130 cells | area (µm²) | setup slack (ns) | hold slack (ns) | formal equiv | GLS |
|---|---:|---:|---:|---:|---:|:---:|:---:|
| `adder8` | 40 | 40 | **290.278400** | **2.94** | 2.08 | PROVEN | PASS |
| `adder8_pipelined` | 98 | 95 | **954.665600** | **7.67** | 0.45 | PROVEN | PASS |
| `add_sub_shared` | 86 | 54 | **419.152000** | **3.32** | 2.08 | PROVEN | PASS |
| `top` | 224 | 189 | **1664.096000** | **2.94** | 0.45 | PROVEN | PASS |

`designs processed : 4` · `failures : 0`

**RTL simulation (Questa 2026.1):** `All Day 3 functional labs completed successfully (4/4 testbenches passed)`
— `tb_adder8` PASS · `tb_add_sub_shared` PASS=512 FAIL=0 · `tb_adder8_pipelined` PASS · `tb_top` CHECKS=80 FAIL=0

**สามข้อสรุปที่ต้องอธิบายในห้องเรียน**

1. **Pipeline แลก area กับ speed** — area 290.278400 → 954.665600 µm² (×3.29)
   แต่ slack 2.94 → 7.67 ns (×2.61) → Fmax 141.6 → 429.2 MHz
2. **Resource sharing คุ้ม** — adder แยกกัน 2 ตัว = 580.556800 µm²
   เทียบกับ shared adder = 419.152000 µm² → ประหยัด 27.8 %
3. **Path combinational เป็นตัวจำกัดของ `top`** — setup slack ของ `top` (2.94 ns)
   เท่ากับของ `adder8` พอดี แม้ `top` จะมี register ด้วย

---

## 5. บั๊กจริงที่เจอระหว่างทำแล็บนี้

ทั้งหมดนี้เป็นบั๊กที่ **พิสูจน์ได้ด้วยการรัน** ไม่ใช่การเดา

| # | อาการ | สาเหตุ | วิธีจับได้ | แก้ |
|---|---|---|---|---|
| 1 | timing report ว่างเปล่า ไม่มี error | `get_ports clk` ของ port ที่ไม่มีใน entity คืน collection ว่าง → constraint ถูกทิ้งเงียบ | `scripts/check_sdc_ports.py` | แยก SDC ต่อ design + ตัวตรวจ |
| 2 | สคริปต์ Tcl ตายที่คำสั่งแรก | `add_source` ชี้ไฟล์ที่อยู่คนละโฟลเดอร์ | `scripts/check_precision_tcl.py` | ใช้ path เต็ม `$lab_dir/...` |
| 3 | GLS ได้ X ทุกบิต ทั้งที่ netlist ถูก | PDK คอมไพล์ *timing* model (มี `specify`) ซึ่ง Icarus ไม่รองรับ → `CLK_delayed` เป็น X | ดู warning ของ iverilog | คอมไพล์ด้วย `-D FUNCTIONAL` |
| 4 | GLS compile error: `Unknown module type: ...udp_dff$...` | ไม่ได้ใส่ `primitives.v` (ไฟล์ UDP ของ PDK) | ข้อความ error ของ iverilog | เพิ่ม `primitives.v` ในคำสั่ง |
| 5 | netlist คำนวณผิด แต่ `check -assert` ผ่าน | `abc` เลือก cell `lpflow_inputiso1p_1` (isolation cell) มาแทน OR gate | GLS / formal equivalence เท่านั้น | สร้าง Liberty ที่มี `dont_use` |
| 6 | testbench อ่านค่าเก่า | อ่าน signal ที่เพิ่ง assign ใน process เดียวกัน (delta cycle) | assert fail พร้อมค่าที่ไม่ตรง | เก็บค่าไว้ใน variable |

---

## 6. ดูคู่มือที่เกี่ยวข้อง

- [`Manual_3_7_Lab3A_Precision_RTL_Synthesis_StepByStepGuide.md`](../../Manual_3_7_Lab3A_Precision_RTL_Synthesis_StepByStepGuide.md) — คู่มือ step-by-step ฉบับเต็ม
- [`Manual_3_8_VHDL_Synthesis_DeepDive.md`](../../Manual_3_8_VHDL_Synthesis_DeepDive.md) — ทฤษฎี VHDL synthesis เชิงลึก
- [`Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md`](../../Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md) — แล็บคู่ขนาน
- [`Manual_4_4_Lab4_GLS_AssertionBasedTB_StepByStepGuide.md`](../../Manual_4_4_Lab4_GLS_AssertionBasedTB_StepByStepGuide.md) — gate-level simulation

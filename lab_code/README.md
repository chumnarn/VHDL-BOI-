# Lab Code – Part 1 (วันที่ 1-5) ของหลักสูตร Advanced Digital IC Design

คู่มือฉบับเต็มอยู่ที่ `../Manual_Part1_Day1-5.md` (ดูตามที่จัดทำไว้ก่อนหน้า)
ดัชนีเอกสารทั้งหมดอยู่ที่ `../README.md`

> **Lab 3B — Yosys + LibreLane** (open-source) อยู่ใน [`day3_yosys/`](day3_yosys/)
> คู่มือ: [`../Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md`](../Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md)
> — เป็นแล็บเสริมของวันที่ 3 ที่ใช้เครื่องมือ open-source ทั้งหมด ไม่ต้องมี commercial license
> หรือ PDK ขององค์กร สังเคราะห์ได้ตั้งแต่ RTL → netlist → GDSII
>
> **Lab 5B — RTL-to-GDSII Full Chip Flow** (open-source) อยู่ใน [`day5_yosys/`](day5_yosys/)
> คู่มือ: [`../Manual_5_5_Lab5B_UART_TX_to_GDSII_LibreLane_StepByStepGuide.md`](../Manual_5_5_Lab5B_UART_TX_to_GDSII_LibreLane_StepByStepGuide.md)
> — เป็นแล็บเสริมของวันที่ 5 ที่ส่ง Mini Project UART TX ผ่าน Open-source ASIC flow
> จนได้ GDSII พร้อม DRC/LVS/Antenna ผ่าน จริง

## ผลการตรวจสอบอัตโนมัติ

### ฝั่ง Questa / ModelSim (วันที่ 1–5)

โค้ดทุกไฟล์ผ่านการตรวจสอบด้วย **ModelSim/Questa Advanced Simulator 2026.1**
(`vcom -2008` + `vsim`) — **16/16 testbench ผ่าน, 0 compile error, 0 simulation failure**

รันตรวจสอบทั้งหมด: `vsim -do run_labX.do -c` จากในโฟลเดอร์ของแต่ละวัน

### ฝั่ง Open-source (Lab 3B — Yosys + LibreLane)

โค้ดใน `day3_yosys/` ตรวจสอบด้วย **Yosys 0.52 · Icarus Verilog 12.0 · GHDL 5.0.1 ·
LibreLane v3.0.17 · PDK sky130A** บน WSL Ubuntu 26.04 — **ทุกขั้นผ่าน**

| ขั้นตอน | ผล |
| --- | --- |
| RTL simulation | ✅ `tb_adder8 PASS=131072 FAIL=0` · `tb_adder8_pipe PASS=64 FAIL=0` |
| Yosys generic synthesis | ✅ `adder8` 52 cells · `adder8_pipe` 78 cells (26 flip-flop) |
| Yosys gate-level mapping | ✅ `adder8` 41 cells · `adder8_pipe` 66 cells |
| Gate-Level Simulation | ✅ netlist ผ่าน 131,072 patterns เท่ากับ RTL |
| VHDL → GHDL → Yosys | ✅ 88 cells · ผ่าน 131,072 patterns |
| Map เข้า sky130 standard cell | ✅ 24 cells · area **220.2112 µm²** |
| LibreLane RTL → GDSII | ✅ **80/80 stages** · DRC 0 · LVS 0 · Antenna 0 |
| Timing sign-off | ✅ setup **5.587222 ns** · hold **0.317141 ns** · Fmax ≈ 226.6 MHz |

รัน: `bash run_yosys_lab.sh` (หรือ `--full` เพื่อรวมขั้นตอน LibreLane)

### ฝั่ง Open-source แล็บ 5B — RTL-to-GDSII Full Chip Flow (Lab 5B)

โค้ดใน `day5_yosys/` ตรวจสอบด้วย **Yosys 0.52 · Icarus Verilog 12.0 ·
LibreLane v3.0.17 · PDK sky130A** บน WSL Ubuntu 26.04 — **ทุกขั้นผ่าน**

| ขั้นตอน | ผล |
| --- | --- |
| RTL simulation | ✅ `tb_uart_top PASS=6 FAIL=0` |
| Yosys generic synthesis | ✅ `baud_gen` 44 · `uart_tx` 74 · รวม 118 cells |
| Yosys gate-level mapping | ✅ `uart_top` 112 cells |
| Gate-Level Simulation | ✅ netlist ผ่าน 6/6 เฟรมเท่ากับ RTL |
| Map เข้า sky130 standard cell | ✅ 122 cells · area **1087.2928 µm²** |
| LibreLane RTL → GDSII | ✅ **80/80 stages** · `error.log` 0 bytes |
| DRC / LVS / Antenna | ✅ violations **0 / 0 / 0** |
| Timing sign-off (9 corners) | ✅ setup **6.235697 ns** · hold **0.191574 ns** · Fmax ≈ 265.7 MHz |
| Layout | ✅ instances 526 · die 4975.42 µm² · utilization 60.12 % |
| GDSII | ✅ `uart_top.gds` 517,382 bytes |

รัน: `bash run_yosys_lab.sh --full`

## โครงสร้าง Directory

```
lab_code/
├── README.md              (ไฟล์นี้)
├── day1/                  # Fundamentals of VHDL and Digital IC Design
│   ├── and_gate.vhd
│   ├── or_gate.vhd
│   ├── nand4_gate.vhd
│   ├── mux2x1.vhd
│   ├── mux4x1_dataflow.vhd
│   ├── mux4x1_behavioral.vhd
│   ├── dec2x4.vhd
│   ├── dec3x8.vhd
│   ├── tb_and_or.vhd
│   ├── tb_nand4_gate.vhd
│   ├── tb_mux2x1.vhd
│   ├── tb_mux4x1.vhd
│   ├── tb_dec2x4.vhd
│   ├── tb_dec3x8.vhd
│   └── run_lab1.do        (Questa batch script)
│
├── day2/                  # Advanced RTL Design
│   ├── my_types_pkg.vhd
│   ├── counter8.vhd
│   ├── seq_det_moore.vhd
│   ├── seq_det_mealy.vhd
│   ├── full_adder_struct.vhd
│   ├── adder4_struct.vhd
│   ├── tb_counter8.vhd
│   ├── tb_seq_moore.vhd
│   ├── tb_seq_mealy.vhd
│   ├── tb_adder4.vhd
│   └── run_lab2.do
│
├── day3/                  # RTL Synthesis (Precision RTL)
│   ├── adder8.vhd
│   ├── adder8_pipelined.vhd
│   ├── add_sub_shared.vhd
│   ├── top.vhd
│   ├── tb_adder8.vhd
│   ├── tb_add_sub_shared.vhd
│   ├── tb_adder8_pipelined.vhd
│   ├── constraints.sdc
│   ├── synth.tcl          (Precision RTL synthesis)
│   └── run_lab3.do
│
├── day3_yosys/           # RTL Synthesis (Yosys + LibreLane — open-source, Lab 3B)
│   ├── README.md
│   ├── Makefile           (make sim / make synth / make synth-gate / ...)
│   ├── run_yosys_lab.sh    (batch runner + สรุป PASS/FAIL)
│   ├── rtl/
│   │   ├── adder8.v
│   │   ├── adder8_pipe.v
│   │   └── adder8.vhd
│   ├── tb/
│   │   ├── tb_adder8.v
│   │   └── tb_adder8_pipe.v
│   ├── scripts/
│   │   ├── synth_generic.ys
│   │   ├── synth_gates.ys
│   │   └── ghdl_to_verilog.sh
│   └── librelane/
│       ├── README.md
│       ├── config.yaml
│       ├── Makefile
│       └── src/{adder8_pipe.v, impl.sdc, signoff.sdc}
│
├── day4/                  # Verification
│   ├── alu8.vhd
│   ├── ref_model_alu8.vhd
│   ├── handshake_protocol.vhd
│   ├── tb_alu8_selfcheck.vhd
│   ├── tb_handshake.vhd
│   ├── covergroup_alu.sv  (SystemVerilog covergroup)
│   ├── compile_netlist.do
│   ├── run_gls.do         (Gate-Level Simulation)
│   └── run_lab4.do
│
├── day5/                  # Mini Project – UART TX
│   ├── baud_gen.vhd
│   ├── uart_tx.vhd
│   ├── uart_top.vhd
│   ├── tb_uart_top.vhd
│   ├── constraints_uart.sdc
│   ├── synth_uart.tcl
│   ├── run_gls_uart.do
│   ├── final_report.md
│   └── run_lab5.do
│
└── day5_yosys/           # RTL-to-GDSII Full Chip Flow (Yosys + LibreLane — Lab 5B)
    ├── README.md
    ├── Makefile           (make sim / make synth / make librelane / ...)
    ├── run_yosys_lab.sh    (batch runner + สรุป PASS/FAIL)
    ├── rtl/
    │   ├── baud_gen.v
    │   ├── uart_tx.v
    │   └── uart_top.v
    ├── tb/
    │   └── tb_uart_top.v
    ├── scripts/
    │   ├── synth_generic.ys
    │   └── synth_gates.ys
    └── librelane/
        ├── README.md
        ├── config.yaml
        ├── Makefile
        └── src/{impl.sdc, signoff.sdc}
```

## วิธีใช้งาน

### การเปิดด้วย Questa Advanced Simulator

1. เปิด Questa
2. **File ▸ Source** เลือกไฟล์ `run_labX.do` (เช่น `day1/run_lab1.do`)
3. ดูผลลัพธ์ใน Transcript

หรือรันจาก command line:

```bash
cd lab_code/day1
vsim -do run_lab1.do -c
```

### การเทรนแต่ละวันทีละไฟล์

ใน Questa GUI:

```
vlib work
vcom -2008 *.vhd                 # compile all VHDL files
vsim work.tb_<module_name>       # load testbench
add wave *                       # add all signals to wave window
run 1 us                         # run simulation
```

### การสังเคราะห์ด้วย Precision RTL (Day 3 และ Day 5)

```bash
cd lab_code/day3
precision -shell -file synth.tcl
```

ผลลัพธ์จะอยู่ใน `reports/` และ `netlist/`

### การสังเคราะห์ด้วย Yosys + LibreLane (Lab 3B และ Lab 5B — ไม่ต้องมี license)

```bash
# Lab 3B — Yosys synthesis + gate-level simulation
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3_yosys"
bash run_yosys_lab.sh          # ทุกขั้น (ยกเว้น LibreLane ที่ต้องมี PDK)
bash run_yosys_lab.sh --full   # รวมขั้นตอน LibreLane (~90 วินาที เมื่อมี PDK แล้ว)

# Lab 5B — RTL-to-GDSII Full Chip Flow (Mini Project UART TX)
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day5_yosys"
bash run_yosys_lab.sh --full   # รวมขั้นตอน LibreLane (~1 นาที 50 วินาที เมื่อมี PDK แล้ว)
```

ทีละขั้นด้วย Makefile:

```bash
make sim        # RTL simulation
make synth      # Yosys generic synthesis
make synth-gate # gate-level netlist
make sim-gls    # Gate-Level Simulation
make sky130     # map เข้า sky130 standard cell
make librelane  # full flow RTL -> GDSII
```

> ⚠️ ถ้าอยู่ใน WSL และ path มีวงเล็บ เช่น `/mnt/e/lab/VHDL(BOI)/...` ต้องห่อด้วย `"` เสมอ
> ดูรายละเอียดการติดตั้ง PDK ที่ [`day3_yosys/librelane/README.md`](day3_yosys/librelane/README.md)
> และ [`day5_yosys/librelane/README.md`](day5_yosys/librelane/README.md)

### การทำ Gate-Level Simulation (Day 4 และ Day 5)

หลังสังเคราะห์เสร็จ ใช้ SDF ที่ Precision export ออกมา:

```bash
cd lab_code/day4
vsim -do run_gls.do -c
```

## เครื่องมือที่ต้องการ

| เครื่องมือ | ใช้สำหรับ | License |
| --- | --- | --- |
| Questa Advanced Simulator | Simulation, Functional Coverage, Assertion | Commercial (Siemens EDA) |
| ModelSim | Simulation (basic) | Commercial |
| Precision RTL | RTL → Netlist Synthesis | Commercial |
| HDL Designer | Block Diagram / State Diagram → VHDL | Commercial |
| **Yosys** | **RTL → Netlist Synthesis (open-source)** | **Open-source (GPL)** |
| **Icarus Verilog** | **RTL / Gate-Level Simulation** | **Open-source (GPL)** |
| **GHDL** | **สะพาน VHDL → Verilog สำหรับ Yosys** | **Open-source (GPL)** |
| **LibreLane** | **Open-source ASIC flow: RTL → GDSII** | **Open-source (Apache-2.0)** |
| **PDK sky130A** | **Target library สำหรับ Yosys / LibreLane** | **Open-source (Apache-2.0)** |

ทุกเครื่องมือชุดแรกมาจาก **Siemens EDA** (เดิม Mentor Graphics) ซึ่งจัดจำหน่ายในประเทศไทยโดย **HENISWARE Co., Ltd.**

ชุด open-source ใช้เฉพาะ Lab 3B และติดตั้งบน Linux / WSL:

```bash
sudo apt install -y yosys iverilog ghdl make
nix profile install nixpkgs#librelane
export PATH="/root/.nix-profile/bin:$PATH"
```

## สถานะของแต่ละ Lab

| วัน | Lab | สถานะ | หมายเหตุ |
| --- | --- | --- | --- |
| 1 | AND/OR/NAND gate + exhaustive TB | ✅ ผ่าน | ตรวจครบทุก combination (16 patterns) |
| 1 | MUX (2-to-1, 4-to-1) | ✅ ผ่าน | ทดสอบ dataflow vs behavioral |
| 1 | Decoder (2-to-4, 3-to-8) | ✅ ผ่าน | enable low/high |
| 2 | 8-bit Counter with CE + load | ✅ ผ่าน | Synchronous reset |
| 2 | Sequence Detector (Moore + Mealy) | ✅ ผ่าน | Self-checking TB + overlapping detection (10 checks each) |
| 2 | 4-bit Adder (Structural) | ✅ ผ่าน | Exhaustive 16x16x2 |
| 3 | 8-bit Ripple Carry Adder | ✅ ผ่าน | |
| 3 | 8-bit Pipelined Adder | ✅ ผ่าน | Latency = 1 cycle |
| 3 | ADD/SUB Resource Sharing | ✅ ผ่าน | Exhaustive pattern + signed overflow |
| 3 | Precision RTL Synthesis | ⚠️ ต้องมี PDK | ปรับ tech_lib path |
| 3 | **Yosys Generic + Gate-Level Synthesis** | ✅ รันจริงผ่าน | 52 / 78 cells generic · 41 / 66 cells gate |
| 3 | **Gate-Level Simulation ของ netlist Yosys** | ✅ รันจริงผ่าน | 131,072 patterns เท่ากับ RTL |
| 3 | **VHDL → GHDL → Verilog → Yosys** | ✅ รันจริงผ่าน | 88 cells · ผ่าน 131,072 patterns |
| 3 | **Map เข้า sky130 standard cell** | ✅ รันจริงผ่าน | 24 cells · 220.2112 µm² |
| 3 | **LibreLane RTL → GDSII (80 stages)** | ✅ รันจริงผ่าน | DRC/LVS/Antenna ผ่าน · setup 5.587 ns · hold 0.317 ns |
| 4 | 8-bit ALU (ADD/SUB/AND/OR) | ✅ ผ่าน | 262,144 patterns เทียบ reference model |
| 4 | Reference Model (cycle-accurate) | ✅ ผ่าน | |
| 4 | Handshake Protocol | ✅ ผ่าน | Concurrent assertion |
| 4 | GLS with SDF | ⚠️ ต้องมี netlist | หลังสังเคราะห์ Day 3 |
| 5 | UART TX Mini Project | ✅ ผ่าน | Frame-level check 6 patterns |
| 5 | Precision RTL + SDF | ⚠️ ต้องมี PDK | ปรับ tech_lib path |
| 5 | **Yosys + GLS ของ Mini Project UART TX** | ✅ รันจริงผ่าน | netlist ผ่าน 6/6 เฟรมเท่ากับ RTL |
| 5 | **LibreLane RTL-to-GDSII Full Chip Flow** | ✅ รันจริงผ่าน | 80/80 stages · DRC/LVS/Antenna ผ่าน · GDSII ได้ |

## หมายเหตุสำคัญเรื่อง batch script

`run_labX.do` แต่ละไฟล์จะรัน testbench ทุกตัวของวันนั้น โดยแต่ละตัวถูกสั่งผ่าน `exec`
เพื่อให้ `quit -f` ของ testbench ไม่ไปจบ script ต้นทาง (ถ้าเรียก `vsim` ซ้อนแบบธรรมดา
`quit -f` ตัวแรกจะฆ่า session ทั้งหมดทิ้ง)

สคริปต์ยังตรวจสอบ "completion marker" ของแต่ละ testbench ด้วย เพื่อจับกรณี
`run` time สั้นเกินไปจน simulation หยุดกลางคันแต่ยังดูเหมือนผ่าน

## แนวทางการขยาย

1. **Day 5 extension:** เพิ่ม baud rate configurable, parity bit
2. **Coverage extension:** ใช้ SystemVerilog covergroup แทน assertion-only
3. **FPGA validation:** รันบน FPGA development board เพื่อ cross-check
4. **Physical design:** ส่ง netlist ต่อไปทำ Floorplan, P&R (Day 6+)
5. **Open-source flow:** ขยาย Lab 3B และ Lab 5B ไปสู่ design ที่ใหญ่ขึ้น แล้วเทียบผลกับ Precision RTL
   ข้อมูลการติดตั้งและการเปลี่ยน PDK อยู่ที่ [`day3_yosys/librelane/README.md`](day3_yosys/librelane/README.md)
   และ [`day5_yosys/librelane/README.md`](day5_yosys/librelane/README.md)
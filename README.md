# Advanced Digital IC and MEMS Design with EDA Verification and Simulation Tools

> **คู่มือประกอบการอบรม** — จัดโดย **HENISWARE Co., Ltd.** (ตัวแทนจำหน่าย Siemens EDA ในประเทศไทย) ร่วมกับ **BOI** และ **MUT**
>
> เอกสารชุดนี้เป็น **ส่วนที่ 1 (วันที่ 1–5): Digital IC Design & Verification ด้วย VHDL และ Siemens EDA** ครบทั้งภาคทฤษฎี ภาคปฏิบัติ Lab และข้อสอบ

---

## สารบัญ

1. [ข้อมูลหลักสูตร](#1-ข้อมูลหลักสูตร)
2. [ภาพรวมหลักสูตร 10 วัน](#2-ภาพรวมหลักสูตร-10-วัน)
3. [Quick Start](#3-quick-start-เริ่มใช้งานใน-5-นาที)
4. [โครงสร้างไฟล์](#4-โครงสร้างไฟล์)
5. [ดัชนีเอกสารทั้งหมด](#5-ดัชนีเอกสารทั้งหมด)
6. [สถานะ Lab และผลการตรวจสอบ](#6-สถานะ-lab-และผลการตรวจสอบ)
7. [เครื่องมือและ Prerequisites](#7-เครื่องมือและ-prerequisites)
8. [วิธีรัน Simulation](#8-วิธีรัน-simulation)
9. [Troubleshooting: ปัญหาที่พบบ่อย](#9-troubleshooting-ปัญหาที่พบบ่อย)
10. [สิ่งที่ยังไม่ได้ทำ / Part 2](#10-สิ่งที่ยังไม่ได้ทำ--part-2-วันที่-6-10)
11. [คู่มือเดิมใน version-01](#11-คู่มือเดิมใน-version-01)

---

## 1. ข้อมูลหลักสูตร

| รายการ | รายละเอียด |
| --- | --- |
| ชื่อหลักสูตร | Advanced Digital IC and MEMS Design with EDA Verification and Simulation Tools |
| ผู้จัด | HENISWARE Co., Ltd. ร่วมกับ BOI และ MUT |
| ระยะเวลา | 10 วัน วันละ 8 ชั่วโมง รวม 80 ชั่วโมง (ทฤษฎี 40 ชม. + ปฏิบัติ 40 ชม.) |
| **ส่วนที่ 1 (ชุดนี้)** | **วันที่ 1–5: Digital IC Design & Verification ด้วย VHDL — เอกสารครบ 100%** |
| ส่วนที่ 2 | วันที่ 6–10: IC Layout + MEMS Design & Simulation — **ยังไม่ได้จัดทำ** |
| เกณฑ์การประเมิน | Beginner 50–59% · Intermediate 60–79% · Advanced ≥ 80% (ผ่านที่ 70%) |

### เครื่องมือที่ใช้ในส่วนที่ 1

| เครื่องมือ | บทบาท | ใช้ในวันที่ |
| --- | --- | --- |
| Questa Advanced Simulator | Simulation, Functional Coverage, Assertions | 1, 2, 4, 5 |
| ModelSim | Simulation ระดับ HDL | 1, 2 |
| HDL Designer | สร้าง Block Diagram / State Diagram และ generate VHDL | 2 |
| Precision RTL | RTL Synthesis และ Optimization | 3, 5 |

**เสริม (open-source ไม่ต้องมี license):** Yosys · LibreLane · Icarus Verilog · GHDL · PDK sky130A — ใช้ในหัวข้อ 3.5–3.6 และแล็บ 3B

---

## 2. ภาพรวมหลักสูตร 10 วัน

```
╔══════════════════════════════════════════════════════════════════════════╗
║  PART 1 — Digital IC Design & Verification (วันที่ 1-5)  ✅ จัดทำครบ    ║
╠══════════════════════════════════════════════════════════════════════════╣
║  Day 1  Fundamentals of VHDL and Digital IC Design          [คู่มือหลัก] ║
║    1.1 Digital IC Design Flow                                 ✅ มี deep dive ║
║    1.2 พื้นฐานภาษา VHDL (ASIC vs FPGA + Building Blocks)     ✅ มี deep dive ║
║    1.3 Simulation vs Synthesis + Data Types                  ✅ มี deep dive ║
║    1.4 LAB 1 — AND/OR/MUX/Decoder + Simulation               ✅ มี step-by-step║
║                                                                           ║
║  Day 2  Advanced RTL Design Using VHDL                        [คู่มือหลัก] ║
║    2.1 Synchronous Design & Reset Strategy                    ✅ มี deep dive ║
║    2.2 FSM — Moore vs Mealy                                   ✅ มี deep dive ║
║    2.3 Structural vs Behavioral Modeling                      ✅ ในคู่มือหลัก ║
║    2.4 RTL Design Guidelines (Latch, CDC)                     ✅ มี deep dive ║
║    2.5 Testbench                                             ✅ มี deep dive ║
║    2.6 LAB 2 — FSM + Testbench + HDL Designer                ✅ มี step-by-step║
║                                                                           ║
║  Day 3  RTL Synthesis and Optimization (Precision RTL)       [คู่มือหลัก] ║
║    3.1 Synthesis Flow                                         ✅ ในคู่มือหลัก ║
║    3.2 Constraints (SDC)                                      ✅ ในคู่มือหลัก ║
║    3.3 Timing Analysis เบื้องต้น                                ✅ ในคู่มือหลัก ║
║    3.4 Optimization Techniques                                ✅ ในคู่มือหลัก ║
║    3.5 การสังเคราะห์ด้วย Yosys (Open-source)                  ✅ มี deep dive ║
║    3.6 LAB 3B — Yosys & LibreLane (RTL → GDSII)              ✅ มี step-by-step║
║    3.7 LAB 3 — 8-bit Adder variants + Synthesis              ✅ ในคู่มือหลัก ║
║                                                                           ║
║  Day 4  Design Verification Using Questa                      [คู่มือหลัก] ║
║    4.1 Verification Methodology                               ✅ มี deep dive ║
║    4.2 Assertions & Functional Coverage                       ✅ มี deep dive ║
║    4.3 Gate-Level Simulation & SDF                            ✅ มี deep dive ║
║    4.4 LAB 4 — ALU Verification + GLS                         ✅ มี step-by-step║
║                                                                           ║
║  Day 5  Mini Project — UART TX                                [คู่มือหลัก] ║
║    5.1 ASIC Flow Integration                                  ✅ มี deep dive ║
║    5.2 Verification Plan & Sign-off                           ✅ มี deep dive ║
║    5.3 Mini Project — RTL Design                             ✅ มี deep dive ║
║    5.4 RTL-to-GDSII Full Chip Flow (LibreLane)                ✅ มี deep dive ║
║    5.5 LAB 5B — Mini Project จนถึง GDSII                     ✅ มี step-by-step║
║    5.6 สรุปและประเด็นสำคัญ (ปิดท้าย Part 1)                    ✅ มี deep dive ║
╚══════════════════════════════════════════════════════════════════════════╝

╔══════════════════════════════════════════════════════════════════════════╗
║  PART 2 — IC Layout + MEMS Design (วันที่ 6-10)  ❌ ยังไม่ได้จัดทำ     ║
╠══════════════════════════════════════════════════════════════════════════╣
║  Day 6   Basic IC Design / Tanner Tools                        ❌            ║
║  Day 7   CMOS Layout / L-Edit                                  ❌            ║
║  Day 8   MEMS Layout / L-Edit                                   ❌            ║
║  Day 9   MEMS Design / FEM / Ansys                              ❌            ║
║  Day 10  Advanced MEMS Simulation                              ❌            ║
╚══════════════════════════════════════════════════════════════════════════╝
```

---

## 3. Quick Start (เริ่มใช้งานใน 5 นาที)

### 3.1 เปิดคู่มือหลัก

เริ่มจาก **`Manual_Part1_Day1-5.md`** — เป็นคู่มือหลักที่มีตารางเวลา วัตถุประสงค์ของวัน เกณฑ์ประเมิน และตัวอย่างโค้ดในตัว

### 3.2 รัน Lab ทั้งหมดในแต่ละวัน

```powershell
cd E:\lab\VHDL(BOI)\lab_code\day1
vsim -do run_lab1.do -c
```

เปลี่ยน `day1` → `day2` … `day5` เพื่อรันวันถัดไป สคริปต์จะ compile และรัน testbench ทุกตัวของวันนั้นและสรุปผลท้ายสุด

> ต้องมี `vsim` อยู่ใน `PATH` ดูวิธีตั้งค่าใน [ข้อ 7](#7-เครื่องมือและ-prerequisites)

### 3.3 รัน Lab 3B — Yosys + LibreLane (Linux / WSL)

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3_yosys"
bash run_yosys_lab.sh
```

ใช้เครื่องมือ open-source ทั้งหมด (ไม่ต้องมี license หรือ PDK ขององค์กร) — สังเคราะห์ได้ตั้งแต่
RTL → netlist → GDSII พร้อม DRC/LVS ดูวิธีติดตั้งใน [ข้อ 7.1.1](#711-เครื่องมือ-open-source-สำหรับ-lab-3b--5b--ไม่ต้องมี-license)

### 3.4 ทำข้อสอบ

| ไฟล์ | เมื่อไหร่ | รูปแบบ |
| --- | --- | --- |
| `test/Part1_PreTest_25_Questions.md` | **ก่อน**เริ่มเรียน | MC 10 + T/F 10 + Short 5 (100 คะแนน) |
| `test/Part1_PostTest_25_Questions.md` | **หลัง**เรียนจบ | MC 10 + Code Analysis 8 + Short 2 (100 คะแนน) |

ทั้งสองไฟล์มี **เฉลยพร้อมคำอธิบาย** อยู่ท้ายไฟล์

---

## 4. โครงสร้างไฟล์

```
E:\lab\VHDL(BOI)\
│
├── README.md                              ◀◀ คุณอยู่ที่นี่ (ดัชนีหลักสูตร)
│
├── Manual_Part1_Day1-5.md                 คู่มือหลักสูตร วันที่ 1-5 (~74 KB, ~1,740 บรรทัด)
│
├── ── เนื้อหาเชิงลึก (Deep Dive) — 17 ไฟล์ ──────────────────────────────
├── Manual_1_1_0_DigitalICDesignFlow_DeepDive.md
├── Manual_1_1_2_ASIC_vs_FPGA_and_VHDL_BuildingBlocks_DeepDive.md
├── Manual_1_2_4_and_1_3_Simulation_vs_Synthesis_DataTypes_DeepDive.md
├── Manual_2_1_SynchronousDesign_ResetStrategy_DeepDive.md
├── Manual_2_2_FSM_Moore_vs_Mealy_DeepDive.md
├── Manual_2_4_2_5_RTL_Guidelines_and_Testbench_DeepDive.md
├── Manual_3_5_Yosys_and_LibreLane_Synthesis_DeepDive.md
├── Manual_4_1_Verification_Methodology_DeepDive.md
├── Manual_4_2_Assertions_and_FunctionalCoverage_DeepDive.md
├── Manual_4_3_GateLevelSimulation_SDF_DeepDive.md
├── Manual_5_1_ASIC_Flow_and_Verification_Plan_DeepDive.md
├── Manual_5_3_MiniProject_RTL_Design_DeepDive.md
├── Manual_5_4_MiniProject_Verification_Synthesis_DeepDive.md
├── Manual_5_4_RTL_to_GDSII_LibreLane_FullChipFlow_DeepDive.md
├── Manual_Part1_Summary_and_Key_Takeaways_DeepDive.md
│
├── ── Step-by-Step Lab Guide — 6 ไฟล์ ────────────────────────────────────
├── Manual_1_4_Lab1_StepByStepGuide.md
├── Manual_2_6_Lab2_FSM_StepByStepGuide.md
├── Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md
├── Manual_4_4_Lab4_GLS_AssertionBasedTB_StepByStepGuide.md
├── Manual_5_5_Lab5_MiniProject_GLS_Debug_Report_StepByStepGuide.md
├── Manual_5_5_Lab5B_UART_TX_to_GDSII_LibreLane_StepByStepGuide.md
│
├── ── ข้อสอบ ──────────────────────────────────────────────────────────────
├── test/                                ◀ ข้อสอบ Pre-Test / Post-Test (25 ข้อ + เฉลย)
│   ├── Part1_PreTest_25_Questions.md
│   └── Part1_PostTest_25_Questions.md
│
├── lab_code/                              ◀ ซอร์สโค้ดที่ compile + simulate ผ่านแล้ว
│   ├── README.md
│   ├── day1/   8 design + 6 testbench + run_lab1.do                  (15 ไฟล์)
│   ├── day2/   6 design + 4 testbench + run_lab2.do                  (11 ไฟล์)
│   ├── day3/   4 design + 3 testbench + SDC + Tcl + 1 .do            (10 ไฟล์)
│   ├── day3_yosys/  Yosys + LibreLane (Lab 3B) + README              (18 ไฟล์)
│   ├── day4/   3 design + 2 testbench + 1 SystemVerilog + 3 .do       (9 ไฟล์)
│   ├── day5/   3 design + 1 testbench + SDC + Tcl + 2 .do + report   (10 ไฟล์)
│   └── day5_yosys/  RTL-to-GDSII Full Chip Flow (Lab 5B) + README    (14 ไฟล์)
│
├── docs/reference/                       ◀ เอกสารอ้างอิง Questa / VHDL
│   ├── questa/   (18 ไฟล์)
│   └── vhdl/     (19 ไฟล์)
│
├── tools/                                ◀ เครื่องมือช่วยตรวจงานคู่มือ + เอกสารเครื่องมือ
│   ├── check-links.sh                    ตัวตรวจลิงก์ภายในของโปรเจกต์
│   └── *.md                               เอกสาร Yosys / LibreLane / Questa / Verilator
│
└── version-01/                            คู่มือเดิมภาษาไทย 4 ไฟล์ (ดูข้อ 11)
```

---

## 5. ดัชนีเอกสารทั้งหมด

### 5.1 คู่มือหลัก

| ไฟล์ | เนื้อหา | ขนาด |
| --- | --- | --- |
| [`Manual_Part1_Day1-5.md`](Manual_Part1_Day1-5.md) | คู่มือหลักสูตร วันที่ 1–5 ครบทั้งภาคทฤษฎี/ปฏิบัติ + ภาคผนวก | ~75 KB |

### 5.2 เนื้อหาเชิงลึด (Deep Dive) — แทรกเสริมในคู่มือหลัก

| ไฟล์ | แทรกที่หัวข้อ | เวลาบรรยาย | หัวข้อย่อย |
| --- | --- | --- | --- |
| [`Manual_1_1_0_DigitalICDesignFlow_DeepDive.md`](Manual_1_1_0_DigitalICDesignFlow_DeepDive.md) | 1.1 Digital IC Design Flow | 90–120 นาที | 12 |
| [`Manual_1_1_2_ASIC_vs_FPGA_and_VHDL_BuildingBlocks_DeepDive.md`](Manual_1_1_2_ASIC_vs_FPGA_and_VHDL_BuildingBlocks_DeepDive.md) | 1.1.2 + 1.2 | 120–150 นาที | 18 |
| [`Manual_1_2_4_and_1_3_Simulation_vs_Synthesis_DataTypes_DeepDive.md`](Manual_1_2_4_and_1_3_Simulation_vs_Synthesis_DataTypes_DeepDive.md) | 1.2.4 + 1.3 | 90–120 นาที | 22 |
| [`Manual_2_1_SynchronousDesign_ResetStrategy_DeepDive.md`](Manual_2_1_SynchronousDesign_ResetStrategy_DeepDive.md) | 2.1 | 90–120 นาที | 15 |
| [`Manual_2_2_FSM_Moore_vs_Mealy_DeepDive.md`](Manual_2_2_FSM_Moore_vs_Mealy_DeepDive.md) | 2.2 | 90–120 นาที | 14 |
| [`Manual_2_4_2_5_RTL_Guidelines_and_Testbench_DeepDive.md`](Manual_2_4_2_5_RTL_Guidelines_and_Testbench_DeepDive.md) | 2.4 + 2.5 | 90–120 นาที | 26 |
| [`Manual_3_5_Yosys_and_LibreLane_Synthesis_DeepDive.md`](Manual_3_5_Yosys_and_LibreLane_Synthesis_DeepDive.md) | 3.5 การสังเคราะห์ด้วย Yosys (Open-source) | 90–120 นาที | 24 |
| [`Manual_4_1_Verification_Methodology_DeepDive.md`](Manual_4_1_Verification_Methodology_DeepDive.md) | 4.1 | 90–120 นาที | 21 |
| [`Manual_4_2_Assertions_and_FunctionalCoverage_DeepDive.md`](Manual_4_2_Assertions_and_FunctionalCoverage_DeepDive.md) | 4.2 | 90–120 นาที | 26 |
| [`Manual_4_3_GateLevelSimulation_SDF_DeepDive.md`](Manual_4_3_GateLevelSimulation_SDF_DeepDive.md) | 4.3 | 90–120 นาที | 28 |
| [`Manual_5_1_ASIC_Flow_and_Verification_Plan_DeepDive.md`](Manual_5_1_ASIC_Flow_and_Verification_Plan_DeepDive.md) | 5.1 + 5.2 | 90–120 นาที | 8 ส่วน |
| [`Manual_5_3_MiniProject_RTL_Design_DeepDive.md`](Manual_5_3_MiniProject_RTL_Design_DeepDive.md) | 5.3 | 90–120 นาที | 13 |
| [`Manual_5_4_MiniProject_Verification_Synthesis_DeepDive.md`](Manual_5_4_MiniProject_Verification_Synthesis_DeepDive.md) | 5.3 (ภาค verification + synthesis) | 90–120 นาที | 9 ส่วน |
| [`Manual_5_4_RTL_to_GDSII_LibreLane_FullChipFlow_DeepDive.md`](Manual_5_4_RTL_to_GDSII_LibreLane_FullChipFlow_DeepDive.md) | 5.4 RTL-to-GDSII Full Chip Flow | 90–120 นาที | 19 |
| [`Manual_Part1_Summary_and_Key_Takeaways_DeepDive.md`](Manual_Part1_Summary_and_Key_Takeaways_DeepDive.md) | 5.6 (ปิดท้าย Part 1) | 60–90 นาที | 18 |

> ทุกไฟล์ Deep Dive มี ASCII diagrams, ตารางเปรียบเทียบ, ตัวอย่างโค้ดจริง, checklist และ troubleshooting ครบถ้วน — ออกแบบให้แทรกเข้าคู่มือหลักได้ทันที

### 5.3 Step-by-Step Lab Guide

| ไฟล์ | Lab | เวลาใช้งาน | ขั้นตอน |
| --- | --- | --- | --- |
| [`Manual_1_4_Lab1_StepByStepGuide.md`](Manual_1_4_Lab1_StepByStepGuide.md) | Lab 1 — โมดูลตรรกะพื้นฐาน | 1.5–2 ชม. | 10 |
| [`Manual_2_6_Lab2_FSM_StepByStepGuide.md`](Manual_2_6_Lab2_FSM_StepByStepGuide.md) | Lab 2 — FSM + Testbench + HDL Designer | 2–2.5 ชม. | 10 |
| [`Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md`](Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md) | Lab 3B — Yosys + LibreLane (RTL → GDSII) | 2.5–3 ชม. | 12 |
| [`Manual_4_4_Lab4_GLS_AssertionBasedTB_StepByStepGuide.md`](Manual_4_4_Lab4_GLS_AssertionBasedTB_StepByStepGuide.md) | Lab 4 — Verification + GLS + Assertion TB | 2.5–3 ชม. | 12 |
| [`Manual_5_5_Lab5_MiniProject_GLS_Debug_Report_StepByStepGuide.md`](Manual_5_5_Lab5_MiniProject_GLS_Debug_Report_StepByStepGuide.md) | Lab 5 — Mini Project End-to-End | 2.5–3 ชม. | 12 |
| [`Manual_5_5_Lab5B_UART_TX_to_GDSII_LibreLane_StepByStepGuide.md`](Manual_5_5_Lab5B_UART_TX_to_GDSII_LibreLane_StepByStepGuide.md) | Lab 5B — RTL-to-GDSII Full Chip Flow | 3–3.5 ชม. | 12 |

### 5.4 ข้อสอบ

| ไฟล์ | รูปแบบ | คะแนน | เฉลย |
| --- | --- | --- | --- |
| [`test/Part1_PreTest_25_Questions.md`](test/Part1_PreTest_25_Questions.md) | MC 10 + T/F 10 + Short 5 | 100 | ✅ พร้อมคำอธิบาย |
| [`test/Part1_PostTest_25_Questions.md`](test/Part1_PostTest_25_Questions.md) | MC 10 + Code Analysis 8 + Short 2 | 100 | ✅ พร้อมคำอธิบาย |

---

## 6. สถานะ Lab และผลการตรวจสอบ

### 6.1 ผลการตรวจสอบอัตโนมัติ

โค้ดใน `lab_code/` ทั้งหมดถูกตรวจสอบด้วย **ModelSim/Questa Advanced Simulator 2026.1** (`vcom` + `vsim`)

| วัน | Testbench | ผลการตรวจสอบ |
| --- | --- | --- |
| 1 | `tb_and_or` — AND/OR gate | ✅ ผ่าน |
| 1 | `tb_nand4_gate` — 4-input NAND | ✅ ผ่าน (16 patterns) |
| 1 | `tb_mux2x1` — 2-to-1 MUX | ✅ ผ่าน |
| 1 | `tb_mux4x1` — 4-to-1 MUX (dataflow vs behavioral) | ✅ ผ่าน |
| 1 | `tb_dec2x4` — 2-to-4 Decoder | ✅ ผ่าน |
| 1 | `tb_dec3x8` — 3-to-8 Decoder | ✅ ผ่าน |
| 2 | `tb_counter8` — 8-bit counter (sync reset + CE + load) | ✅ ผ่าน |
| 2 | `tb_seq_moore` — Moore FSM "101" (overlapping) | ✅ ผ่าน (10 checks) |
| 2 | `tb_seq_mealy` — Mealy FSM "101" (overlapping) | ✅ ผ่าน (10 checks) |
| 2 | `tb_adder4` — 4-bit ripple carry adder | ✅ ผ่าน (512 patterns) |
| 3 | `tb_adder8` — 8-bit ripple carry adder | ✅ ผ่าน |
| 3 | `tb_add_sub_shared` — ADD/SUB resource sharing + signed overflow | ✅ ผ่าน (512 patterns) |
| 3 | `tb_adder8_pipelined` — pipelined adder (latency 1 cycle) | ✅ ผ่าน |
| 4 | `tb_alu8_selfcheck` — 8-bit ALU vs reference model | ✅ ผ่าน (262,144 patterns) |
| 4 | `tb_handshake` — handshake protocol + concurrent assertion | ✅ ผ่าน (16 handshakes) |
| 5 | `tb_uart_top` — UART TX frame verification | ✅ ผ่าน (6 frames) |

**สรุป: 16/16 testbench ผ่าน — compile 0 errors, simulation 0 failures**

> สคริปต์ `run_labX.do` ไม่ได้ตรวจแค่ "ไม่มี error" แต่ยังตรวจ **completion marker**
> ของแต่ละ testbench ด้วย จึงจับกรณี `run` time สั้นเกินไปจน simulation หยุดกลางคัน
> แต่ยังดูเหมือนผ่านได้ (กรณีนี้เคยเกิดกับ `tb_adder4` และ `tb_add_sub_shared`
> ที่รันได้แค่ 40 / 511 patterns จากทั้งหมด 512)

### 6.2 ผลการตรวจสอบ Lab 3B (Yosys + LibreLane)

ตรวจสอบด้วย **Yosys 0.52 · Icarus Verilog 12.0 · GHDL 5.0.1 · LibreLane v3.0.17 · PDK sky130A**
บน WSL Ubuntu 26.04 — ทุกตัวเลขด้านล่างมาจากการรันจริง

| ขั้นตอน | ผลการตรวจสอบ |
| --- | --- |
| RTL simulation (`tb_adder8`) | ✅ `PASS=131072 FAIL=0` |
| RTL simulation (`tb_adder8_pipe`) | ✅ `PASS=64 FAIL=0` |
| Yosys generic synthesis | ✅ `adder8` = 52 cells · `adder8_pipe` = 78 cells (26 SDFF) |
| Yosys gate-level mapping | ✅ `adder8` = 41 cells · `adder8_pipe` = 66 cells |
| Gate-Level Simulation ของ netlist | ✅ ผ่าน 131,072 patterns เท่ากับ RTL |
| VHDL → GHDL → Verilog → Yosys | ✅ 88 cells · ผ่าน 131,072 patterns |
| Map เข้า sky130 standard cell | ✅ 24 cells · **220.2112 µm²** |
| LibreLane full flow | ✅ **80/80 stages** · DRC 0 · LVS 0 · Antenna 0 |
| Timing sign-off | ✅ setup slack **5.587222 ns** · hold slack **0.317141 ns** |
| Layout | ✅ instances 399 · die 4331.89 µm² · utilization 68.95 % |
| GDSII | ✅ `adder8_pipe.gds` 413,344 bytes |

> รายละเอียดเพิ่มเติม: [`lab_code/day3_yosys/README.md`](lab_code/day3_yosys/README.md)
> และ [`lab_code/day3_yosys/librelane/README.md`](lab_code/day3_yosys/librelane/README.md)

### 6.3 ผลการตรวจสอบ Lab 5B (RTL-to-GDSII Full Chip Flow)

ตรวจสอบด้วย **Yosys 0.52 · Icarus Verilog 12.0 · LibreLane v3.0.17 · PDK sky130A**
บน WSL Ubuntu 26.04 — รันซ้ำสองครั้งได้ตัวเลขเดียวกันทุกตัว

| ขั้นตอน | ผลการตรวจสอบ |
| --- | --- |
| RTL simulation (`tb_uart_top`) | ✅ `PASS=6 FAIL=0` (0x00, 0xFF, 0x55, 0xAA, 0x42, 0x3C) |
| Yosys generic synthesis | ✅ `baud_gen` 44 · `uart_tx` 74 · รวม 118 cells |
| Yosys gate-level mapping | ✅ `uart_top` 112 cells |
| Gate-Level Simulation ของ netlist | ✅ ผ่าน 6/6 เฟรมเท่ากับ RTL |
| Map เข้า sky130 standard cell | ✅ 122 cells · area **1087.2928 µm²** |
| LibreLane full flow | ✅ **80/80 stages** · `error.log` 0 bytes |
| DRC / LVS / Antenna violations | ✅ **0 / 0 / 0** |
| Timing sign-off (9 corners) | ✅ setup **6.235697 ns** · hold **0.191574 ns** · Fmax ≈ 265.7 MHz |
| Layout | ✅ instances 526 · die 4975.42 µm² · utilization 60.12 % · power 303.98 µW |
| GDSII | ✅ `uart_top.gds` 517,382 bytes |

> รายละเอียดเพิ่มเติม: [`lab_code/day5_yosys/README.md`](lab_code/day5_yosys/README.md)
> และ [`lab_code/day5_yosys/librelane/README.md`](lab_code/day5_yosys/librelane/README.md)

### 6.4 สถานะแต่ละ Lab

| วัน | Lab | สถานะ | หมายเหตุ |
| --- | --- | --- | --- |
| 1 | AND/OR/NAND + exhaustive TB | ✅ พร้อมใช้ | ตรวจครบทุก combination |
| 1 | MUX (2-to-1, 4-to-1) | ✅ พร้อมใช้ | เทียบ dataflow vs behavioral |
| 1 | Decoder (2-to-4, 3-to-8) | ✅ พร้อมใช้ | enable low/high |
| 2 | 8-bit Counter with CE + load | ✅ พร้อมใช้ | Synchronous reset |
| 2 | Sequence Detector (Moore + Mealy) | ✅ พร้อมใช้ | Self-checking TB + overlapping |
| 2 | 4-bit Adder (Structural) | ✅ พร้อมใช้ | Exhaustive 256×256 |
| 3 | 8-bit Ripple Carry Adder | ✅ พร้อมใช้ | |
| 3 | 8-bit Pipelined Adder | ✅ พร้อมใช้ | Latency = 1 cycle |
| 3 | ADD/SUB Resource Sharing | ✅ พร้อมใช้ | Exhaustive pattern + signed overflow |
| 3 | Precision RTL Synthesis | ⚠️ ต้องมี PDK | ปรับ `tech_lib` path |
| 3 | **Yosys Generic + Gate-Level Synthesis** | ✅ รันจริงผ่าน | 52 / 78 cells generic · 41 / 66 cells gate |
| 3 | **Gate-Level Simulation ของ netlist Yosys** | ✅ รันจริงผ่าน | testbench เดิมผ่าน 131,072 patterns เท่ากับ RTL |
| 3 | **VHDL → GHDL → Verilog → Yosys** | ✅ รันจริงผ่าน | netlist จาก VHDL (88 cells) ผ่าน 131,072 patterns |
| 3 | **Map เข้า sky130 standard cell** | ✅ รันจริงผ่าน | 24 cells · area 220.2112 µm² |
| 3 | **LibreLane RTL → GDSII (80 stages)** | ✅ รันจริงผ่าน | DRC/LVS/Antenna ผ่าน · setup 5.587 ns · hold 0.317 ns |
| 4 | 8-bit ALU (ADD/SUB/AND/OR) | ✅ พร้อมใช้ | 262,144 patterns |
| 4 | Reference Model (cycle-accurate) | ✅ พร้อมใช้ | |
| 4 | Handshake Protocol | ✅ พร้อมใช้ | Concurrent assertion |
| 4 | GLS with SDF | ⚠️ ต้องมี netlist | ต้องสังเคราะห์ก่อน (Day 3) |
| 5 | UART TX Mini Project | ✅ พร้อมใช้ | Frame-level check, 6 patterns |
| 5 | Precision RTL + SDF | ⚠️ ต้องมี PDK | ปรับ `tech_lib` path |
| 5 | **Yosys + GLS ของ Mini Project UART TX** | ✅ รันจริงผ่าน | netlist ผ่าน 6/6 เฟรมเท่ากับ RTL |
| 5 | **LibreLane RTL-to-GDSII Full Chip Flow** | ✅ รันจริงผ่าน | 80/80 stages · DRC/LVS/Antenna ผ่าน · GDSII ได้ |

> ⚠️ = ต้องเตรียม PDK / netlist ขององค์กร ไม่สามารถรันได้ด้วยไฟล์ที่แนบมาเพียงอย่างเดียว

---

## 7. เครื่องมือและ Prerequisites

### 7.1 เครื่องมือที่ต้องมี

| เครื่องมือ | ใช้สำหรับ | License | จำเป็น? |
| --- | --- | --- | --- |
| Questa Advanced Simulator | Simulation, Functional Coverage, Assertion | Commercial (Siemens EDA) | แนะนำ |
| ModelSim | Simulation ระดับ HDL | Commercial | ทางเลือก (ใช้แทน Questa ได้) |
| Precision RTL | RTL → Netlist Synthesis | Commercial | สำหรับ Day 3, 5 |
| HDL Designer | Block/State Diagram → VHDL | Commercial | สำหรับ Day 2 |
| PDK (เช่น TSMC / GlobalFoundries / IHP SG13G2) | Target library สำหรับ synthesis | ต้องขอจากองค์กร | สำหรับ Day 3, 5 |

ทุกเครื่องมือมาจาก **Siemens EDA** (เดิม Mentor Graphics) ซึ่ง **HENISWARE Co., Ltd.** เป็นตัวแทนจำหน่ายในประเทศไทย

### 7.1.1 เครื่องมือ Open-source (สำหรับ Lab 3B / 5B — ไม่ต้องมี license)

Lab 3B (Yosys + LibreLane) และ Lab 5B (RTL-to-GDSII Full Chip Flow) ใช้ชุดเครื่องมือที่ **ฟรีทั้งหมด** ติดตั้งบน Linux / WSL

| เครื่องมือ | ใช้สำหรับ | วิธีติดตั้ง |
| --- | --- | --- |
| Yosys 0.52 | RTL → netlist synthesis | `sudo apt install yosys` |
| Icarus Verilog 12.0 | RTL / Gate-Level Simulation | `sudo apt install iverilog` |
| GHDL 5.0.1 | สะพาน VHDL → Verilog | `sudo apt install ghdl` |
| LibreLane v3.0.17 | Open-source ASIC flow (RTL → GDSII) | `nix profile install nixpkgs#librelane` |
| PDK sky130A | Target library (open-source) | ดาวน์โหลดอัตโนมัติผ่าน `--volare-pdk` |

> Nix ดึง **OpenROAD, Magic, KLayout, Netgen, Yosys, yosys-ghdl** มาให้ใน closure เดียวกัน
> รายละเอียดการติดตั้งและการเปลี่ยน PDK: [`lab_code/day3_yosys/librelane/README.md`](lab_code/day3_yosys/librelane/README.md)
> และ [`lab_code/day5_yosys/librelane/README.md`](lab_code/day5_yosys/librelane/README.md)

### 7.2 ตั้งค่า PATH สำหรับ ModelSim/Questa

ตรวจสอบตำแหน่งติดตั้ง:

```powershell
Get-ChildItem "C:\Siemens" -Directory
```

ตั้งค่าให้ `vsim` / `vcom` เรียกได้จาก command line:

```powershell
$env:PATH = "C:\Siemens\modelsim_dlx64_2026.1\win64pe;$env:PATH"
```

ตรวจสอบว่าใช้ได้:

```powershell
vsim -version
```

### 7.3 การตั้งค่า PDK สำหรับ Synthesis

ในไฟล์ `synth.tcl` (Day 3) และ `synth_uart.tcl` (Day 5) มีค่า placeholder ที่ต้องแก้ให้ตรงกับ PDK ขององค์กร:

```tcl
# ── TODO: เปลี่ยน path ให้ตรงกับ PDK ที่องค์กรให้ ──────────────
set tech_lib   "/tech/gscl45nm"
set target_lib "/tech/gscl45nm/stdcells.lib"
```

วิธีหา path ที่ถูกต้อง:

```powershell
# ดูรายชื่อ technology library ที่ Precision RTL มองเห็น
precision -shell -file <your_script.tcl>
> report_libs
```

### 7.4 ข้อกำหนดของสภาพแวดล้อมที่ใช้ทดสอบ

| รายการ | ค่า |
| --- | --- |
| Simulator | ModelSim/Questa Advanced Simulator **2026.1** (Windows x64) |
| VHDL Standard | `--std=2008` (ทุกไฟล์ใช้ `vcom -2008`) |
| ระบบปฏิบัติการ | Windows 10/11 x64 |
| Path ที่มีวงเล็บ | รองรับ แต่ต้องห่อด้วย `"` ในคำสั่ง `cmd` |

---

## 8. วิธีรัน Simulation

### 8.1 แบบ Batch (ทั้งวัน)

```powershell
cd E:\lab\VHDL(BOI)\lab_code\day1
vsim -do run_lab1.do -c
```

สคริปต์ `run_labX.do` จะ:
1. สร้าง work library (`vlib work`) ถ้ายังไม่มี
2. Compile design units และ testbench ด้วย `vcom -2008`
3. รัน **ทุก testbench ของวันนั้น** แยก process ผ่าน `exec` (เพื่อไม่ให้ `quit -f` ของ testbench ก่อนหยุด script)
4. ตรวจจับ `** Error` / `** Failure` / `** Fatal` และสรุปผลท้ายสุด

ผลลัพธ์ท้องเท้า:

```
All Day 1 labs completed successfully (6/6 testbenches passed).
```

### 8.2 แบบ Questa GUI

1. เปิด Questa → **File ▸ Source** → เลือก `lab_code/dayX/run_labX.do`
2. ดูผลลัพธ์ใน Transcript

> เมื่อรันจาก GUI ต้องมี `vsim` อยู่ใน `PATH` ของเครื่อง ไม่เช่นนั้น `exec` จะหาไม่พบ

### 8.3 รัน testbench เดี่ยว

```powershell
cd E:\lab\VHDL(BOI)\lab_code\day4
vlib work
vcom -2008 -work work alu8.vhd ref_model_alu8.vhd handshake_protocol.vhd
vcom -2008 -work work tb_alu8_selfcheck.vhd tb_handshake.vhd
vsim work.tb_alu8_selfcheck
add wave *
run 300 us
```

### 8.4 สังเคราะห์ด้วย Precision RTL (Day 3 / Day 5)

```powershell
cd E:\lab\VHDL(BOI)\lab_code\day3
precision -shell -file synth.tcl
```

ผลลัพธ์จะอยู่ใน `reports/` และ `netlist/` — ต้องแก้ `tech_lib` ก่อนตาม [ข้อ 7.3](#73-การตั้งค่า-pdk-สำหรับ-synthesis)

### 8.5 Gate-Level Simulation (Day 4 / Day 5)

ต้องรัน synthesis มาก่อนให้ได้ netlist และ SDF แล้วจึงรัน:

```powershell
cd E:\lab\VHDL(BOI)\lab_code\day4
vsim -do run_gls.do -c
```

### 8.6 รัน Lab 3B — Yosys + LibreLane (Linux / WSL)

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3_yosys"

bash run_yosys_lab.sh          # ทุกขั้น (ยกเว้น LibreLane ที่ต้องมี PDK)
bash run_yosys_lab.sh --full   # รวมขั้นตอน LibreLane (~90 วินาที เมื่อมี PDK แล้ว)
```

หรือรันทีละขั้นด้วย Makefile:

```bash
make sim        # RTL simulation
make synth      # Yosys generic synthesis
make synth-gate # gate-level netlist
make sim-gls    # Gate-Level Simulation
make ghdl       # VHDL -> GHDL -> Verilog -> Yosys
make sky130     # map เข้า sky130 standard cell
make librelane  # full flow RTL -> GDSII
```

> ⚠️ **ถ้าอยู่ใน WSL และ path มีวงเล็บ** เช่น `/mnt/e/lab/VHDL(BOI)/...` ต้องห่อด้วย `"` เสมอ
> ไม่งั้น shell จะตีความ `(BOI)` เป็น subshell แล้วคำสั่งพัง

### 8.7 รัน Lab 5B — RTL-to-GDSII Full Chip Flow (Linux / WSL)

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day5_yosys"

bash run_yosys_lab.sh          # ทุกขั้น (ยกเว้น LibreLane ที่ต้องมี PDK)
bash run_yosys_lab.sh --full   # รวมขั้นตอน LibreLane (~1 นาที 50 วินาที เมื่อมี PDK แล้ว)
```

หรือรันทีละขั้นด้วย Makefile:

```bash
make sim        # RTL simulation
make synth      # Yosys generic synthesis
make synth-gate # gate-level netlist
make sim-gls    # Gate-Level Simulation
make sky130     # map เข้า sky130 standard cell
make librelane  # full flow RTL -> GDSII
```

ดูผลลัพธ์ layout:

```bash
RUN=$(ls -dt librelane/runs/RUN_* | head -1)
klayout "$RUN/final/klayout_gds/uart_top.klayout.gds"
ls "$RUN/final/render/"
```

---

## 9. Troubleshooting: ปัญหาที่พบบ่อย

### 9.1 ปัญหาที่พบระหว่างจัดทำและแก้ไขแล้ว (บันทึกไว้เป็นบทเรียน)

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| `** Fatal: Array lengths do not match. Left is 9. Right is 16/17` | ผลลัพธ์ของ `&` มีความยาวไม่ตรงกับตัวแปรปลายทาง | ใช้ `resize()` ให้ความยาวเท่ากัน เช่น `resize(unsigned(a), 9)` |
| ผลลัพธ์กลับเป็น 17 บิตแทน 9 บิต | operator `&` มี precedence ต่ำกว่า `+` → `a + "0" & b` ถูกตีความเป็น `(a + "0") & (b + 1)` | ครอบวงเล็บการต่อสตริงเสมอ: `a + ("0" & b)` |
| ค่า output ค้างเป็น `'U'` ตลอด | process อ่านสัญญาณที่ตัวเองเพิ่ง assign (อ่านค่าเก่า) | ขับ output จาก **variable** ใน process ไม่ใช่จาก signal |
| นาฬิกาไม่เดินเลย | `signal clk : std_logic;` ไม่มี initial value → `not 'U'` = `'U'` | ต้องประกาศ `signal clk : std_logic := '0';` |
| ค่าที่ป้อนเป็น `'X'` แทน `'0'/'1'` | `std_logic'val(x + 1)` → enumeration ของ `std_logic` เริ่มที่ `'U'` จึงได้ `'X'` | ใช้ `std_logic_vector(to_unsigned(bit, 1))` |
| เทสต์ "ผ่าน" แต่ไม่ได้ตรวจอะไรจริง | expected value คำนวณจากสัญญาณที่ผิดค่าเหมือนกันทั้งสองฝั่ง | คำนวณ expected จากตัวแปร/ค่าคงที่ ไม่ใช่จาก signal ที่ขับเข้า |
| Assertion fail ที่ขอบ clock edge | checker อ่าน output ที่เพิ่งถูก register update ใน delta เดียวกัน | ใส่ `wait for 1 ns;` หลัง `rising_edge(clk)` ก่อนตรวจ |
| ตัวอย่าง serial bit ผิดบิต | ระยะห่างการ sample ไม่เท่ากับ 1 bit period (drift สะสม) | sample ที่ **กลาง cell** ของแต่ละบิต และใช้ `din_rdy` handshake |

### 9.1.1 ปัญหาที่พบจากการทำงานกับ Yosys / LibreLane

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| `ERROR: Unsupported gate type: NOT` | ABC ไม่รองรับ gate type `NOT` | เอา `NOT` ออกจาก `abc -g` — inverter ถูกสร้างอัตโนมัติอยู่แล้ว |
| netlist simulate ไม่ได้ (`unknown module type $_NAND_`) | ยังไม่ได้ `simplemap` | เพิ่ม `simplemap` หลัง `abc` |
| `ghdl: unknown command '--out=verilog'` | สลับลำดับ option (GHDL 5.x) | ใช้ `ghdl synth --std=08 --out=verilog <top>` และ redirect stdout เอง |
| Yosys `cells.lib` map logic ไม่ได้ | `/usr/share/yosys/cells.lib` มีแต่ DFF ไม่มี gate | ใช้ Liberty ของ PDK จริง (`make sky130`) |
| `librelane: command not found` | ยังได้ติดตั้งผ่าน nix | `nix profile install nixpkgs#librelane` + เพิ่ม PATH |
| `Unable to find PDK sky130A` | ยังไม่ได้ดาวน์โหลด | รันด้วย `--volare-pdk` หรือ `--manual-pdk` |
| `grep` จับ pattern ไม่เจอ | BRE ไม่รองรับ `+`; pattern ที่ขึ้นต้นด้วย `$_` ให้ผลผิด | ใช้ `grep -E` และเลี่ยง `$_` เช่น `SDFF_PP0_ +26` |
| `iverilog: syntax error` ที่ `rtl/uart_top.v` | ใช้ syntax `name : module` ซึ่งเป็น SystemVerilog | ใช้ `module_name instance_name (...)` แบบ Verilog ธรรมดา |
| `VERILOG_FILES` หาไฟล์ไม่เจอใน LibreLane | path ผิดระดับ | `dir::` คือ relative จากโฟลเดอร์ config — จาก `librelane/` ใช้ `../rtl/*.v` |
| `Can't find top module` (LibreLane) | `DESIGN_NAME` ไม่ตรงกับชื่อ module ใน RTL | ตรวจ `DESIGN_NAME` และ `CLOCK_PORT` ให้ตรงกัน |
| `flow complete` แต่ไม่มี `final/` | รันไม่จบ | ดู `error.log` และ `flow.log` ใน `runs/RUN_*/` |
| path มีวงเล็บทำให้คำสั่งพัง | shell ไม่ escape | ห่อด้วย `"` เช่น `cd "/mnt/e/lab/VHDL(BOI)/..."` |

### 9.2 ปัญหาที่อาจเจอระหว่างสอน

| อาการ | วิธีแก้ |
| --- | --- |
| `License request for ... feature failed` | ตรวจสอบ `LM_LICENSE_FILE` หรือ `MGLS_LICENSE_FILE` ให้ชี้ไฟล์ license ขององค์กร |
| `vsim: command not found` | เพิ่ม `C:\Siemens\modelsim_dlx64_2026.1\win64pe` เข้า `PATH` |
| `vlib: Library already exists` | ไม่เป็นไร ลบโฟลเดอร์ `work/` ในโฟลเดอร์ lab แล้วรันใหม่ |
| `Unable to access library 'work'` | ต้อง `cd` เข้าโฟลเดอร์ของวันนั้นก่อนรัน `vsim -do run_labX.do -c` |
| Synthesis หา library ไม่เจอ | ตรวจสอบ `tech_lib` / `target_lib` ในไฟล์ `.tcl` ตาม [ข้อ 7.3](#73-การตั้งค่า-pdk-สำหรับ-synthesis) |
| GLS รันแล้วเป็น `'X'` ทั้งหมด | netlist/SDF ไม่ตรงกับ RTL หรือยังไม่ได้สังเคราะห์ — รัน synthesis ใหม่แล้ว export SDF ใหม่ |

---

## 10. สิ่งที่ยังไม่ได้ทำ / Part 2 (วันที่ 6-10)

### 10.1 ช่องว่างในส่วนที่ 1

| รายการ | สถานะ | หมายเหตุ |
| --- | --- | --- |
| Lab 3 (Precision RTL) Step-by-Step Guide | ⚠️ **ยังไม่มี** | เนื้อหา Lab 3 อยู่ใน `Manual_Part1_Day1-5.md` หัวข้อ 3.7 และมีโค้ดครบใน `lab_code/day3/` แล้ว แต่ยังไม่ได้เขียนเป็นคู่มือ step-by-step แยก |
| Lab 3 runnable script | ✅ มี | `lab_code/day3/run_lab3.do` รันผ่าน 3/3 testbench |
| **Lab 3B (Yosys + LibreLane) Step-by-Step Guide** | ✅ **มี** | `Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md` — 12 ขั้นตอน พร้อมผลจากการรันจริง |
| **Lab 3B runnable script** | ✅ **มี** | `lab_code/day3_yosys/run_yosys_lab.sh` — รันผ่านครบทุกขั้น รวม LibreLane 80/80 stages |
| **Lab 5B (RTL-to-GDSII Full Chip Flow) Step-by-Step Guide** | ✅ **มี** | `Manual_5_5_Lab5B_UART_TX_to_GDSII_LibreLane_StepByStepGuide.md` — 12 ขั้นตอน จนถึง GDSII |
| **Lab 5B runnable script** | ✅ **มี** | `lab_code/day5_yosys/run_yosys_lab.sh` — รันผ่านครบทุกขั้น รวม LibreLane 80/80 stages |
| **Full chip flow RTL → GDSII** | ✅ **มี** | `lab_code/day5_yosys/librelane/` — DRC/LVS/Antenna ผ่าน ได้ GDSII จริง |
| GLS จริง (netlist + SDF) | ⚠️ ต้องมี PDK | ต้องสังเคราะห์ใน Day 3 ก่อน (หรือใช้ netlist จาก Lab 3B ที่มีอยู่แล้ว) |
| Precision RTL report จริง | ⚠️ ต้องมี PDK | ไม่มีตัวเลขที่สังเคราะห์จริงถูกระบุไว้ในเอกสาร — มีแต่ผลของ open-source flow ที่รันจริง |
| Open-source ASIC flow (RTL → GDSII) | ✅ **มี** | `lab_code/day3_yosys/librelane/` — DRC/LVS/Antenna ผ่าน ได้ GDSII จริง |

### 10.2 Part 2 — IC Layout + MEMS (วันที่ 6-10)

ยังไม่ได้จัดทำเอกสาร มีโครงสร้างตามโปรแกรมของหลักสูตร:

| วัน | หัวข้อ | เครื่องมือ |
| --- | --- | --- |
| 6 | Basic IC Design | Tanner Tools |
| 7 | CMOS Layout | L-Edit |
| 8 | MEMS Layout | L-Edit |
| 9 | MEMS Design / FEM | Ansys |
| 10 | Advanced MEMS Simulation | — |

---

## 11. คู่มือเดิมใน version-01

โฟลเดอร์ `version-01/` เก็บคู่มือภาษาไทยฉบับเดิมที่จัดทำไว้ก่อนหน้านี้ ใช้เป็น **ภาคผนวกเชิงเครื่องมือ** (วิธีใช้เมนูแบบละเอียด) ได้ดี

| ไฟล์ | เนื้อหา |
| --- | --- |
| `คู่มือฝึกอบรม การออกแบบและตรวจสอบวงจรรวมดิจิทัลขั้นสูงด้วยเครื่องมือ Siemens EDA.md` | คู่มือหลักฉบับเดิมของหลักสูตร |
| `คู่มือการใช้งาน Siemens Precision Synthesis สำหรับการสังเคราะห์วงจรดิจิทัล.md` | วิธีใช้ Precision RTL แบบละเอียด |
| `คู่มือการใช้งาน QuestaSim สำหรับการจำลองและตรวจสอบวงจร VHDL.md` | วิธีใช้ QuestaSim แบบละเอียด |
| `คู่มือการใช้งาน ModelSim สำหรับการจำลองและตรวจสอบวงจร VHDL.md` | วิธีใช้ ModelSim แบบละเอียด |
| `Siemens QuestaSim.md` | เอกสารประกอบ QuestaSim |

---

## การติดต่อ

| หัวข้อ | รายละเอียด |
| --- | --- |
| ผู้จัดหลักสูตร | HENISWARE Co., Ltd. |
| ผู้ร่วมจัด | BOI, MUT |
| ผู้ให้บริการ EDA | Siemens EDA (เดิม Mentor Graphics) |
| ตัวแทนจำหน่ายในไทย | HENISWARE Co., Ltd. |

---

*เอกสารชุดนี้จัดทำสำหรับ **ส่วนที่ 1 (วันที่ 1–5)** เท่านั้น — ส่วนที่ 2 (วันที่ 6–10) อยู่ระหว่างการจัดทำ*

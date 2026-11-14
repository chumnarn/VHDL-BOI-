# Lab Code – Part 1 (วันที่ 1-5) ของหลักสูตร Advanced Digital IC Design

คู่มือฉบับเต็มอยู่ที่ `../Manual_Part1_Day1-5.md` (ดูตามที่จัดทำไว้ก่อนหน้า)

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
├── day3/                  # RTL Synthesis
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
└── day5/                  # Mini Project – UART TX
    ├── baud_gen.vhd
    ├── uart_tx.vhd
    ├── uart_top.vhd
    ├── tb_uart_top.vhd
    ├── constraints_uart.sdc
    ├── synth_uart.tcl
    ├── run_gls_uart.do
    ├── final_report.md
    └── run_lab5.do
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

ทุกเครื่องมือมาจาก **Siemens EDA** (เดิม Mentor Graphics) ซึ่งจัดจำหน่ายในประเทศไทยโดย **HENISWARE Co., Ltd.**

## สถานะของแต่ละ Lab

| วัน | Lab | สถานะ | หมายเหตุ |
| --- | --- | --- | --- |
| 1 | AND/OR/NAND gate + exhaustive TB | พร้อมใช้ | ตรวจครบทุก combination |
| 1 | MUX (2-to-1, 4-to-1) | พร้อมใช้ | ทดสอบ dataflow vs behavioral |
| 1 | Decoder (2-to-4, 3-to-8) | พร้อมใช้ | enable low/high |
| 2 | 8-bit Counter with CE + load | พร้อมใช้ | Synchronous reset |
| 2 | Sequence Detector (Moore + Mealy) | พร้อมใช้ | Self-checking TB |
| 2 | 4-bit Adder (Structural) | พร้อมใช้ | Exhaustive 256x256 |
| 3 | 8-bit Ripple Carry Adder | พร้อมใช้ | |
| 3 | 8-bit Pipelined Adder | พร้อมใช้ | Latency = 1 cycle |
| 3 | ADD/SUB Resource Sharing | พร้อมใช้ | Exhaustive pattern |
| 3 | Precision RTL Synthesis | ต้องมี PDK | ปรับ tech_lib path |
| 4 | 8-bit ALU (ADD/SUB/AND/OR) | พร้อมใช้ | 262,144 patterns |
| 4 | Reference Model (cycle-accurate) | พร้อมใช้ | |
| 4 | Handshake Protocol | พร้อมใช้ | Concurrent assertion |
| 4 | GLS with SDF | ต้องมี netlist | หลังสังเคราะห์ Day 3 |
| 5 | UART TX Mini Project | พร้อมใช้ | Frame-level check |
| 5 | Precision RTL + SDF | ต้องมี PDK | ปรับ tech_lib path |

## แนวทางการขยาย

1. **Day 5 extension:** เพิ่ม baud rate configurable, parity bit
2. **Coverage extension:** ใช้ SystemVerilog covergroup แทน assertion-only
4. **FPGA validation:** รันบน FPGA development board เพื่อ cross-check
3. **Physical design:** ส่ง netlist ต่อไปทำ Floorplan, P&R (Day 6+)
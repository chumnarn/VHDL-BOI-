# Lab 6 — Synthesis, STA และ Timing Closure

Oct 28, 2026 · @Chumnarn Punyasai

## ภาพรวม Lab 6

**เป้าหมาย:** แปลง RTL เป็น gate-level netlist บน sky130 ด้วย Yosys ตรวจ timing ด้วย OpenSTA อ่าน timing report ให้ออกทุกบรรทัด หา Fmax ด้วยสคริปต์ พิสูจน์ว่า pipeline เพิ่ม Fmax ได้จริงและต้องแลกด้วยอะไร และยืนยันว่า netlist ทำงานเหมือน RTL ด้วย testbench เดิมใน ModelSim

**เมื่อจบ Lab ผู้เรียนจะ**

1. เขียนสคริปต์ Yosys ที่ map ทั้ง flip-flop และลอจิกไปยัง .lib จริง พร้อมรายชื่อ cell ต้องห้ามใช้ และอ่านรายงาน area/cell ได้
2. synthesize RTL ภาษา VHDL ด้วย GHDL แล้วเทียบผลกับ Verilog
3. อ่าน setup และ hold path ของ OpenSTA ได้ทุกคอลัมน์ (fanout, cap, slew, delay, time) และคำนวณ slack เอง
4. หา Fmax ด้วยการ sweep clock period อัตโนมัติ และอธิบายผลของสคริปต์ ABC แบบ area กับ speed
5. ออกแบบ pipeline ให้ Fmax สูงขึ้น บอกต้นทุนเป็น area และ latency และหา stage ที่เป็นคอขวดใหม่
6. รัน gate-level simulation ด้วย Verilog model ของ standard cell และต่อ SDF จาก OpenSTA ได้

**ความรู้ที่ต้องมีก่อน:** Lab 2 (`alu8`), Lab 4 (scoreboard, reference model), Lab 5 (ไฟล์ .lib, SDC, sky130), Module 06 (synthesis, STA, setup/hold)

| ส่วน | งาน | เวลา |
| --- | --- | --- |
| 6A | Synthesize `alu_top` (RTL Verilog และ VHDL) และตรวจรายงาน | 45 นาที |
| 6B | STA: อ่าน critical path และ hold path พร้อมอธิบายทุกบรรทัด | 45 นาที |
| 6C | Sweep clock period ด้วยสคริปต์อัตโนมัติ หา Fmax | 45 นาที |
| 6D | เทียบ `mult16` กับ `mult16_pipe` (Fmax, area, latency) | 60 นาที |
| 6E | Gate-level simulation ของ netlist ใน ModelSim | 45 นาที |

**เครื่องมือ** (เวอร์ชันที่ใช้รันผลในคู่มือนี้): Yosys 0.69, OpenSTA 3.1.0, GHDL 4.1 (สำหรับ RTL VHDL), ModelSim (gate-level sim) — บนเครื่องที่ติดตั้ง ORFS ตาม Lab 5 มี `yosys` และ `sta` ใน Docker image / pre-built อยู่แล้ว เวอร์ชันต่างจากนี้ได้ ตัวเลขจะต่างเล็กน้อยแต่แนวโน้มเหมือนกัน

**โครงสร้างโฟลเดอร์**

```text
lab06_syn/
├── rtl/          alu8.v  alu8.vhd  alu_top.v  alu_top.vhd  mult16.v  mult16_pipe.v
├── constraints/  lab06.sdc
├── scripts/      synth.tcl  sta.tcl  sweep.sh  abc_speed.script
├── tb/           tb_alu_top.sv  tb_mult.sv
├── out/          *_netlist.v  *.sdf               ← สคริปต์สร้าง
└── reports/      *_stat.txt  *_sta_*.txt  sweep_*.csv
```

`alu8.v` / `alu8.vhd` คัดลอกมาจาก Lab 2 ตรง ๆ — `alu_top` ใน Lab นี้ใช้ `alu8` แทน `alu #(.N(8))` ที่เห็นในคู่มือหลัก เพื่อให้ต่อเนื่องกับ Lab 2–4

**ตั้งค่าก่อนเริ่มทุกครั้ง** (อยู่ที่โฟลเดอร์ `lab06_syn`):

```bash
# ใช้ .lib ของ sky130 HD corner TT — เลือกบรรทัดที่ตรงกับเครื่องคุณ
export LIB=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib    # open_pdks
export LIB=~/OpenROAD-flow-scripts/flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib  # ORFS (Lab 5)
mkdir -p out reports
yosys -V ; sta -version
```

## 6A — Synthesize `alu_top` และตรวจรายงาน (45 นาที)

### ขั้นที่ 1 — ครอบ ALU ด้วย register (5 นาที)

ALU เป็น combinational ล้วน STA จะมีแต่ path จาก input port ไป output port ซึ่งขึ้นกับ I/O delay ที่เราเดา — ครอบด้วย register ทั้งขาเข้าและขาออกจึงได้ **reg → ALU → reg** ที่วัดความเร็วของลอจิกจริง (latency 2 clock)

`rtl/alu_top.v`

```verilog
// alu_top.v : ครอบ alu8 (Lab 2) ด้วย register ทั้งขาเข้าและขาออก → มี reg→reg path ให้ STA วัด
module alu_top (
  input  wire       clk, rst_n,
  input  wire [7:0] a_in, b_in,
  input  wire [2:0] op_in,
  output reg  [7:0] y_out,
  output reg        zero_out, carry_out, ovf_out
);
  reg  [7:0] a, b;
  reg  [2:0] op;
  wire [7:0] y;
  wire       zero, carry, ovf;

  always @(posedge clk)                       // stage 1: register อินพุต
    if (!rst_n) begin a <= 8'd0; b <= 8'd0; op <= 3'd0; end
    else        begin a <= a_in; b <= b_in; op <= op_in; end

  alu8 u_alu (.a(a), .b(b), .op(op), .y(y), .zero(zero), .carry(carry), .ovf(ovf));

  always @(posedge clk)                       // stage 2: register เอาต์พุต
    if (!rst_n) begin y_out <= 8'd0; zero_out <= 1'b0; carry_out <= 1'b0; ovf_out <= 1'b0; end
    else        begin y_out <= y;    zero_out <= zero; carry_out <= carry; ovf_out <= ovf; end
endmodule
```

`rtl/alu_top.vhd` เขียนแบบเดียวกัน (process เดียว + `entity work.alu8`) — พอร์ตชื่อเหมือนกันทุกตัว เพื่อใช้ SDC และ testbench ชุดเดียวกัน

### ขั้นที่ 2 — สคริปต์ synthesis (15 นาที)

`scripts/synth.tcl` — ใช้ซ้ำทุกส่วนของ Lab โดยเปลี่ยนแค่ตัวแปรแวดล้อม

```tcl
# synth.tcl — Yosys synthesis ไปยัง sky130_fd_sc_hd
# ใช้งาน:  TOP=alu_top RTL="rtl/alu8.v rtl/alu_top.v" CLK_PERIOD=10 yosys -c scripts/synth.tcl
yosys -import
set TOP    $::env(TOP)
set LIB    $::env(LIB)
set PERIOD [expr {[info exists ::env(CLK_PERIOD)] ? $::env(CLK_PERIOD) : 10.0}]
set TAG    [expr {[info exists ::env(TAG)] ? $::env(TAG) : $TOP}]

read_liberty -lib $LIB                        ;# ให้ Yosys รู้ทิศทาง pin ของ cell (check จะไม่ฟ้องผิด)
foreach f $::env(RTL) { read_verilog -sv $f }
hierarchy -check -top $TOP

synth -top $TOP -flatten                      ;# generic synthesis + flatten
set DONT_USE {-dont_use *lpflow* -dont_use *probe*}     ;# cell สำหรับงานพิเศษ ห้ามใช้ (เหมือน DONT_USE_CELLS ของ ORFS)
dfflibmap -liberty $LIB {*}$DONT_USE            ;# map flip-flop ไปยัง cell จริงใน .lib
set ABC_ARGS [list -liberty $LIB {*}$DONT_USE -D [expr {int($PERIOD * 1000)}]]   ;# เป้า delay (ps)
if {[info exists ::env(ABC_SPEED)] && $::env(ABC_SPEED)} {
  lappend ABC_ARGS -script scripts/abc_speed.script    ;# สคริปต์เน้นความเร็ว (จาก ORFS): buffer + upsize ตามเป้า
}
abc {*}$ABC_ARGS                              ;# map ลอจิกไปยัง standard cell
setundef -zero
hilomap -singleton -hicell sky130_fd_sc_hd__conb_1 HI -locell sky130_fd_sc_hd__conb_1 LO
opt_clean -purge

tee -o reports/${TAG}_stat.txt  stat -liberty $LIB
tee -o reports/${TAG}_check.txt check
write_verilog -noattr out/${TAG}_netlist.v
```

| คำสั่ง | ทำไมต้องมี |
| --- | --- |
| `read_liberty -lib` | โหลด cell เป็น blackbox ที่รู้ทิศของ pin — ถ้าไม่ใส่ `check` จะฟ้อง `Wire y_out[0] is used but has no driver` ทั้งที่ netlist ถูก (เคยเจอจริงตอนเตรียม Lab) |
| `-dont_use *lpflow* *probe*` | ไม่เช่นนั้น ABC เลือก `lpflow_isobufsrc_1` (cell สำหรับงานหลาย power domain) มาใช้เป็น AND ธรรมดา — ก่อนใส่บรรทัดนี้ netlist ของ alu\_top มี 14 ตัว |
| `dfflibmap` ก่อน `abc` | FF ต้อง map ก่อน เพราะ ABC map เฉพาะลอจิก combinational |
| `hilomap` | ค่าคงที่ 0/1 ต้องมาจาก tie cell (`conb_1`) ไม่ใช่ต่อกับ VDD/GND ตรง ๆ |
| `tee -o ... stat` / `check` | เก็บรายงานไว้เทียบกับรอบอื่น |

### ขั้นที่ 3 — รัน RTL ภาษา Verilog (5 นาที)

```bash
TOP=alu_top RTL="rtl/alu8.v rtl/alu_top.v" yosys -q -c scripts/synth.tcl
grep -E "cells$|Chip area|sequential" reports/alu_top_stat.txt
tail -1 reports/alu_top_check.txt
```

ผลจริง (Yosys 0.69, sky130 HD TT):

```text
      255  1.9E+03 cells
   Chip area for module '\alu_top': 1903.075200
     of which used for sequential elements: 600.576000 (31.56%)
Found and reported 0 problems.
```

อ่านตาราง cell ใน `reports/alu_top_stat.txt` (คอลัมน์ = จำนวน, พื้นที่รวม µm², ชื่อ cell) แล้วตอบ 3 คำถาม:

| คำถาม | หลักฐานในรายงาน | คำตอบ |
| --- | --- | --- |
| FF มีกี่ตัว ตรงกับ RTL ไหม | `30  600.576  sky130_fd_sc_hd__dfxtp_1` | a 8 + b 8 + op 3 + y\_out 8 + zero/carry/ovf 3 = 30 ตรงกัน |
| ทำไมไม่มี FF แบบมี reset (`dfrtp`) | `28  175.168  sky130_fd_sc_hd__and2_0` | RTL ใช้ synchronous reset → reset กลายเป็น AND หน้า D (`D = rst_n & d`) กับ FF ธรรมดา ส่วน async reset จะได้ `dfrtp` |
| พื้นที่ส่วนใหญ่ไปอยู่ไหน | sequential 31.6%, ที่เหลือคือกลุ่ม `a21oi`, `nand2`, `nor2`, `o21ai` | ลอจิก ALU (adder/subtractor, shifter, mux) ราว 1,300 µm² |

### ขั้นที่ 4 — รัน RTL ภาษา VHDL (10 นาที)

Yosys อ่าน VHDL เองไม่ได้ ให้ GHDL แปลงเป็น Verilog ก่อน แล้วส่งเข้าสคริปต์เดิม

```bash
mkdir -p ghdlwork
ghdl -a --std=08 --workdir=ghdlwork rtl/alu8.vhd rtl/alu_top.vhd
ghdl --synth --std=08 --workdir=ghdlwork --out=verilog alu_top > out/alu_top_from_vhdl.v
TOP=alu_top TAG=alu_top_vhdl RTL="out/alu_top_from_vhdl.v" yosys -q -c scripts/synth.tcl
```

ทางเลือก: ถ้าติดตั้ง ghdl-yosys-plugin ใช้ `yosys -m ghdl` แล้วสั่ง `ghdl --std=08 rtl/alu8.vhd rtl/alu_top.vhd -e alu_top` แทน `read_verilog` ได้เลย

| ผลจริง | RTL Verilog | RTL VHDL (ผ่าน GHDL) |
| --- | --- | --- |
| cells | 255 | 252 |
| area (µm²) | 1,903.08 | 1,900.57 |
| sequential | 600.58 (30 FF) | 600.58 (30 FF) |
| `check` | 0 problems | 0 problems |

ต่างกันไม่ถึง 0.2% — แต่**ไม่เท่ากันพอดี** เพราะ frontend สองตัวสร้าง netlist ตั้งต้นต่างกัน แล้ว ABC หาคำตอบแบบ heuristic จากจุดเริ่มต้นนั้น — ความถูกต้องต้องยืนยันด้วย simulation (6E) ไม่ใช่ด้วยตัวเลข area

✅ **Checkpoint 6A:** `check` = 0 problems ทั้งสองภาษา, นับ FF ได้ 30 ตัวตรงกับ RTL และอธิบายได้ว่า `and2_0` 28 ตัวมาจากอะไร

## 6B — STA: อ่าน critical path และ hold path (45 นาที)

### ขั้นที่ 1 — SDC และสคริปต์ STA (10 นาที)

`constraints/lab06.sdc` — ใช้ไฟล์เดียวกับทุก top ใน Lab นี้ period อ่านจากตัวแปร `CLK_PERIOD` เพื่อให้สคริปต์ sweep ใน 6C เปลี่ยนได้

```tcl
# lab06.sdc — ใช้ร่วมกันทุก top ของ Lab 6 (alu_top, mult16, mult16_pipe)
# period อ่านจากตัวแปรแวดล้อม CLK_PERIOD (ns) ถ้าไม่ตั้งใช้ 10 ns
set PERIOD [expr {[info exists ::env(CLK_PERIOD)] ? $::env(CLK_PERIOD) : 10.0}]

create_clock -name clk -period $PERIOD [get_ports clk]
set_clock_uncertainty -setup 0.10 [get_clocks clk]
set_clock_uncertainty -hold  0.05 [get_clocks clk]
set_clock_transition  0.15 [get_clocks clk]

set IN  [all_inputs -no_clocks]
set_input_delay  -max [expr {0.3 * $PERIOD}] -clock clk $IN
set_input_delay  -min 0.0                    -clock clk $IN
set_output_delay -max [expr {0.3 * $PERIOD}] -clock clk [all_outputs]
set_output_delay -min 0.0                    -clock clk [all_outputs]

set_driving_cell -lib_cell sky130_fd_sc_hd__buf_2 -pin X $IN
set_load 0.02 [all_outputs]
```

`scripts/sta.tcl`

```tcl
# sta.tcl — OpenSTA: อ่าน netlist + SDC แล้วรายงาน timing
# ใช้งาน:  TOP=alu_top CLK_PERIOD=10 sta -no_splash -exit scripts/sta.tcl
set TOP $::env(TOP)
set TAG [expr {[info exists ::env(TAG)] ? $::env(TAG) : $TOP}]

read_liberty $::env(LIB)
read_verilog out/${TAG}_netlist.v
link_design  $TOP
read_sdc     constraints/lab06.sdc

report_checks -path_delay max -fields {slew cap input_pins fanout} -digits 3   ;# setup แย่สุด
# เฉพาะ path ภายใน register → register (critical path ของลอจิกจริง)
report_checks -path_delay max -from [all_registers -clock_pins] -to [all_registers -data_pins] \
              -fields {slew cap input_pins fanout} -digits 3
report_checks -path_delay min -fields {slew cap input_pins} -digits 3          ;# hold แย่สุด
report_wns -digits 3
report_tns -digits 3
report_worst_slack -max -digits 3
report_worst_slack -min -digits 3
report_check_types -max_slew -max_capacitance -max_fanout -violators
report_clock_min_period
```

```bash
TOP=alu_top CLK_PERIOD=10 sta -no_splash -exit scripts/sta.tcl | tee reports/alu_top_sta.txt
```

สรุปท้ายรายงาน (ผลจริง OpenSTA 3.1.0):

```text
wns max 0.000
tns max 0.000
worst slack max 6.451
worst slack min 0.073
clk period_min = 3.52 fmax = 283.80
```

`wns` เป็น 0 ไม่ใช่ 6.451 เพราะ WNS นับเฉพาะ slack ติดลบ (ไม่มี violation = 0) ส่วน `worst slack` คือค่าจริงของ path ที่แย่สุด — รายงานทั้งสองค่าเสมอ

### ขั้นที่ 2 — อ่าน critical path (reg → reg) ทีละบรรทัด (20 นาที)

รายงานที่ 2 ในไฟล์ (ผลจริง ตัดมาทั้ง path):

```text
Startpoint: _456_ (rising edge-triggered flip-flop clocked by clk)
Endpoint: _451_ (rising edge-triggered flip-flop clocked by clk)
Path Group: clk
Path Type: max

Fanout      Cap     Slew    Delay     Time   Description
---------------------------------------------------------------------------------
                   0.150    0.000    0.000   clock clk (rise edge)
                            0.000    0.000   clock network delay (ideal)
                   0.150    0.000    0.000 ^ _456_/CLK (sky130_fd_sc_hd__dfxtp_1)
    32    0.080    0.740    0.831    0.831 ^ _456_/Q (sky130_fd_sc_hd__dfxtp_1)
                   0.740    0.000    0.831 ^ _255_/A (sky130_fd_sc_hd__xor2_1)
     6    0.013    0.194    0.247    1.078 v _255_/X (sky130_fd_sc_hd__xor2_1)
                   0.194    0.000    1.078 v _257_/A1 (sky130_fd_sc_hd__o21bai_1)
     3    0.007    0.181    0.239    1.317 ^ _257_/Y (sky130_fd_sc_hd__o21bai_1)
                   0.181    0.000    1.317 ^ _258_/A2 (sky130_fd_sc_hd__a21oi_1)
     3    0.006    0.110    0.113    1.430 v _258_/Y (sky130_fd_sc_hd__a21oi_1)
                   0.110    0.000    1.430 v _260_/A2 (sky130_fd_sc_hd__o21a_1)
     1    0.003    0.037    0.189    1.619 v _260_/X (sky130_fd_sc_hd__o21a_1)
                   0.037    0.000    1.619 v _263_/C (sky130_fd_sc_hd__maj3_1)
     1    0.003    0.067    0.346    1.965 v _263_/X (sky130_fd_sc_hd__maj3_1)
                   0.067    0.000    1.965 v _265_/C (sky130_fd_sc_hd__maj3_1)
     3    0.007    0.089    0.380    2.345 v _265_/X (sky130_fd_sc_hd__maj3_1)
                   0.089    0.000    2.345 v _408_/C (sky130_fd_sc_hd__maj3_1)
     1    0.004    0.076    0.371    2.716 v _408_/X (sky130_fd_sc_hd__maj3_1)
                   0.076    0.000    2.716 v _409_/B (sky130_fd_sc_hd__xnor2_1)
     3    0.008    0.214    0.210    2.926 ^ _409_/Y (sky130_fd_sc_hd__xnor2_1)
                   0.214    0.000    2.926 ^ _410_/B (sky130_fd_sc_hd__nor2_1)
     2    0.004    0.057    0.072    2.998 v _410_/Y (sky130_fd_sc_hd__nor2_1)
                   0.057    0.000    2.998 v _411_/B1 (sky130_fd_sc_hd__a211o_1)
     1    0.002    0.045    0.259    3.257 v _411_/X (sky130_fd_sc_hd__a211o_1)
                   0.045    0.000    3.257 v _412_/A2 (sky130_fd_sc_hd__a21oi_1)
     1    0.002    0.085    0.119    3.375 ^ _412_/Y (sky130_fd_sc_hd__a21oi_1)
                   0.085    0.000    3.375 ^ _451_/D (sky130_fd_sc_hd__dfxtp_1)
                                     3.375   data arrival time

                   0.150   10.000   10.000   clock clk (rise edge)
                            0.000   10.000   clock network delay (ideal)
                           -0.100    9.900   clock uncertainty
                            0.000    9.900   clock reconvergence pessimism
                                     9.900 ^ _451_/CLK (sky130_fd_sc_hd__dfxtp_1)
                           -0.048    9.852   library setup time
                                     9.852   data required time
---------------------------------------------------------------------------------
                                     9.852   data required time
                                    -3.375   data arrival time
---------------------------------------------------------------------------------
                                     6.476   slack (MET)
```

**คอลัมน์:** Fanout = จำนวน pin ที่เอาต์พุตนั้นขับ · Cap = โหลดรวม (pF) · Slew = เวลาขึ้น/ลงของสัญญาณ (ns) · Delay = เวลาที่เพิ่มในบรรทัดนั้น · Time = เวลาสะสม · `^` / `v` = ขอบขึ้น / ลง — แต่ละ cell มี 2 บรรทัด: บรรทัด input pin (delay 0 เพราะยังไม่มีสายจริง หลัง P&R จะมี wire delay) และบรรทัด output pin (cell delay)

| ส่วนของรายงาน | อ่านว่า |
| --- | --- |
| `_456_/Q` fanout 32, slew 0.740, delay 0.831 | FF `_456_` คือ `b[1]` (ดูจาก `grep -A4 "_456_ (" out/alu_top_netlist.v`) ขับ 32 pin เพราะ b ใช้ใน adder, subtractor, AND/OR/XOR และเป็นตัวเลือก shift — โหลดมากทำให้ slew ช้าและกินเวลาไป 25% ของ path ตั้งแต่ cell แรก (ขั้น place ของ Lab 5 จะแก้ด้วย buffer) |
| `maj3_1` สามตัวติดกัน (รวม \~1.1 ns) | majority-of-3 คือสมการ carry ของ full adder → นี่คือ carry chain ของตัวบวก/ลบ |
| Endpoint `_451_` | FF ของ `ovf_out` — overflow ต้องรอผลบิต 7 ของตัวลบ จึงอยู่ท้าย carry chain พอดี |
| ครึ่งล่าง (required) | 10.000 − 0.100 (uncertainty) − 0.048 (setup ของ FF ปลายทาง) = 9.852 |
| slack | 9.852 − 3.375 = **6.476 ns (MET)** |

**คำนวณเอง:** period เล็กสุดที่ path นี้ผ่าน = arrival + setup + uncertainty = 3.375 + 0.048 + 0.100 = 3.523 ns → Fmax ≈ 284 MHz ตรงกับบรรทัด `clk period_min = 3.52 fmax = 283.80` ที่ `report_clock_min_period` คำนวณให้

ทำไม path แรกในรายงาน (setup แย่สุดโดยรวม) เป็น `_450_/Q → carry_out` ที่ slack 6.451? — เพราะ output delay 30% = 3 ns ถูกหักจากเวลาที่เหลือ: required = 10 − 0.1 − 3.0 = 6.9 แต่แค่ clk-to-Q 0.449 ก็ถึง port → 6.451 ที่ 10 ns สอง path นี้ slack ใกล้เคียงกัน แต่เมื่อ period ลดลง reg→reg จะกลายเป็นตัวจำกัด (6C)

### ขั้นที่ 3 — อ่าน hold path (10 นาที)

```text
Startpoint: op_in[0] (input port clocked by clk)
Endpoint: _452_ (rising edge-triggered flip-flop clocked by clk)
Path Group: clk
Path Type: min

     Cap     Slew    Delay     Time   Description
---------------------------------------------------------------------------
            0.150    0.000    0.000   clock clk (rise edge)
                     0.000    0.000   clock network delay (ideal)
                     0.000    0.000 ^ input external delay
   0.002    0.023    0.009    0.009 ^ op_in[0] (in)
            0.023    0.000    0.009 ^ _237_/B (sky130_fd_sc_hd__and2_0)
   0.002    0.042    0.098    0.106 ^ _237_/X (sky130_fd_sc_hd__and2_0)
            0.042    0.000    0.106 ^ _452_/D (sky130_fd_sc_hd__dfxtp_1)
                              0.106   data arrival time

            0.150    0.000    0.000   clock clk (rise edge)
                     0.000    0.000   clock network delay (ideal)
                     0.050    0.050   clock uncertainty
                     0.000    0.050   clock reconvergence pessimism
                              0.050 ^ _452_/CLK (sky130_fd_sc_hd__dfxtp_1)
                    -0.017    0.033   library hold time
                              0.033   data required time
---------------------------------------------------------------------------
                              0.033   data required time
                             -0.106   data arrival time
---------------------------------------------------------------------------
                              0.073   slack (MET)
```

| สิ่งที่ต่างจาก setup | เหตุผล |
| --- | --- |
| เทียบกับขอบ clock **เดียวกัน** (0 ns) ไม่ใช่ขอบถัดไป | hold ตรวจว่าข้อมูลใหม่ไม่มาทับข้อมูลเก่าเร็วเกินไปตอน FF กำลังจับ |
| uncertainty **บวก** เข้าไปใน required (+0.05) | ฝั่ง hold ต้องการให้ data มาช้า การเผื่อจึงเลื่อน required ไปทางขวา |
| slack = arrival − required | กลับด้านกับ setup: 0.106 − 0.033 = **0.073 ns** |
| เป็น path จาก input port ผ่าน `and2_0` ตัวเดียว | AND ตัวนี้คือ sync reset (6A) — input delay -min 0 ทำให้เป็น path ที่สั้นที่สุดในดีไซน์ |

ผ่านแต่เหลือเพียง 73 ps และยังเป็น ideal clock — หลัง CTS ถ้า clock ไปถึง `_452_` ช้ากว่านี้เกิน 73 ps จะละเมิด hold ทันที เป็นตัวอย่างจริงของคำตอบข้อ 1 ใน Lab 5 ที่ว่า hold เปลี่ยนมากหลัง CTS

### ขั้นที่ 4 — ทดลองเปลี่ยนทีละค่า (5 นาที)

แก้ SDC ทีละบรรทัดแล้วรัน STA ซ้ำ จดสิ่งที่เปลี่ยน (ไม่ต้อง synthesize ใหม่):

1. `set_clock_uncertainty -hold 0.15` → hold slack ติดลบไหม เท่าไร (คาด: 0.073 − 0.10 = −0.027)
2. `set_load 0.2 [all_outputs]` → path ไป output port ช้าลงเท่าไร และ `report_check_types` เริ่มฟ้อง max\_capacitance หรือยัง
3. ลบบรรทัด `create_clock` แล้วรัน — รายงานบอกอะไร (บทเรียนเรื่อง "timing ผ่านสวยเพราะไม่มีอะไรให้ตรวจ" ใน Module 05)

✅ **Checkpoint 6B:** คำนวณ required, slack และ period\_min ด้วยมือได้ตรงกับรายงาน, บอกได้ว่า startpoint/endpoint คือสัญญาณอะไรใน RTL และทำการทดลองครบ 3 ข้อ

## 6C — Sweep clock period หา Fmax (45 นาที)

**แนวคิด:** Fmax ไม่ใช่ค่าคงที่ของ RTL แต่เป็นค่าของ **netlist + constraint** คู่หนึ่ง วิธีหาคือบีบ period ลงทีละขั้นจน worst slack ติดลบ แล้วดูจุดที่เส้นตัดศูนย์

### ขั้นที่ 1 — ทดสอบก่อน: เปลี่ยน period แล้ว netlist เปลี่ยนไหม? (10 นาที)

`synth.tcl` ส่ง period เป็นเป้า delay ให้ ABC ด้วย `-D` อยู่แล้ว (6A) ลอง synthesize สองครั้งที่ period ต่างกันมาก:

```bash
RTL="rtl/alu8.v rtl/alu_top.v"
TOP=alu_top RTL="$RTL" TAG=t10 CLK_PERIOD=10  yosys -q -c scripts/synth.tcl
TOP=alu_top RTL="$RTL" TAG=t2  CLK_PERIOD=2.5 yosys -q -c scripts/synth.tcl
md5sum out/t10_netlist.v out/t2_netlist.v
grep "Chip area" reports/t10_stat.txt reports/t2_stat.txt
```

ผลจริงใน Yosys 0.69: **md5 เท่ากันทุกไบต์** (1903.0752 µm² ทั้งคู่) — สคริปต์ประจำของคำสั่ง `abc -liberty` เน้น area และไม่ได้ใช้ `-D` ในการเลือกโครงสร้าง นี่คือเหตุผลที่ ORFS มี `ABC_AREA` / สคริปต์ speed แยก ดังนั้น Lab นี้จะเทียบ **สองโหมด** แทนการ synthesize ทุก period:

| โหมด | สคริปต์ ABC | เป้าหมาย |
| --- | --- | --- |
| `area` | ค่าประจำของ Yosys | cell น้อย พื้นที่เล็ก |
| `speed` | `scripts/abc_speed.script` (คัดลอกจาก `OpenROAD-flow-scripts/flow/scripts/abc_speed.script`) | ทำ `&syn2`/`&if`/`&synch2` หลายรอบเพื่อลดความลึกของลอจิก แล้ว buffer/upsize ตาม `-D` |

```bash
cp ~/OpenROAD-flow-scripts/flow/scripts/abc_speed.script scripts/
```

### ขั้นที่ 2 — สคริปต์ sweep (10 นาที)

`scripts/sweep.sh`

```bash
#!/usr/bin/env bash
# sweep.sh — synthesize ครั้งเดียว แล้วรัน STA ที่หลาย clock period เพื่อหา Fmax
# ใช้งาน:  ./scripts/sweep.sh <top> "<rtl files>" "<periods ns>" [area|speed]
set -e
TOP=$1; RTL=$2; PERIODS=$3; MODE=${4:-area}
TAG=${TOP}_${MODE}
[ "$MODE" = speed ] && export ABC_SPEED=1 || export ABC_SPEED=0

TOP=$TOP RTL="$RTL" TAG=$TAG CLK_PERIOD=10 yosys -q -c scripts/synth.tcl > /dev/null
AREA=$(awk -F: '/Chip area for/{gsub(/ /,"",$2); print $2}' reports/${TAG}_stat.txt)

OUT=reports/sweep_${TAG}.csv
echo "period_ns,worst_slack_ns,tns_ns,area_um2" > $OUT
for P in $PERIODS; do
  TOP=$TOP TAG=$TAG CLK_PERIOD=$P sta -no_splash -exit scripts/sta.tcl > reports/${TAG}_sta_${P}ns.txt 2>&1
  WS=$(awk  '/^worst slack max/{print $4}' reports/${TAG}_sta_${P}ns.txt)
  TNS=$(awk '/^tns max/{print $3}'         reports/${TAG}_sta_${P}ns.txt)
  echo "$P,$WS,$TNS,$AREA" | tee -a $OUT
done
grep -h "period_min" reports/${TAG}_sta_${P}ns.txt
echo "-> $OUT"
```

| บรรทัด | ทำอะไร |
| --- | --- |
| `TAG=${TOP}_${MODE}` | แยกชื่อ netlist/report ตามโหมด ไม่ให้เขียนทับกัน |
| synthesize นอก loop | netlist ไม่ขึ้นกับ period (ขั้นที่ 1) → STA ซ้ำเร็วกว่า synth ซ้ำมาก |
| `CLK_PERIOD=$P` | ส่งเข้า `lab06.sdc` — input/output delay 30% ก็หดตาม period ด้วย |
| `awk '/^worst slack max/'` | ดึงค่าจากบรรทัดสรุปที่ `sta.tcl` พิมพ์ไว้ (6B) เก็บเป็น CSV |
| `grep period_min` | คำตอบ Fmax จาก OpenSTA โดยตรง ไว้เทียบกับที่อ่านจากกราฟ |

### ขั้นที่ 3 — รันสองโหมด (10 นาที)

```bash
chmod +x scripts/sweep.sh
P="5 4.5 4 3.75 3.5 3.25 3 2.75 2.5"
./scripts/sweep.sh alu_top "rtl/alu8.v rtl/alu_top.v" "$P" area
./scripts/sweep.sh alu_top "rtl/alu8.v rtl/alu_top.v" "$P" speed
```

ผลจริง (ตัดมาบางแถว; ทั้งหมดอยู่ในกราฟด้านล่าง):

```text
# area                               # speed
3.75,0.226,0.000,1903.075200         3.25,0.217,0.000,2474.873600
3.5,-0.024,-0.024,1903.075200        3,-0.033,-0.033,2474.873600
3.25,-0.274,-0.800,1903.075200       2.75,-0.283,-0.300,2474.873600
clk period_min = 3.52 fmax = 283.80  clk period_min = 3.03 fmax = 329.71
```

### ขั้นที่ 4 — อ่านกราฟ (15 นาที)

&#91;embedded content: ผลจริง: reports/sweep\_alu\_top\_area.csv และ sweep\_alu\_top\_speed.csv · Yosys 0.69 + OpenSTA 3.1.0 · sky130\_fd\_sc\_hd TT\]

สิ่งที่ต้องเห็นจากกราฟ:

1. **เส้นตรง ความชัน 1 พอดี** — ลด period 0.5 ns slack ก็ลด 0.5 ns เพราะ netlist เดิม arrival เท่าเดิม สิ่งเดียวที่เปลี่ยนคือ required time นี่คือหลักฐานว่า "บีบ clock ใน STA ไม่ทำให้วงจรเร็วขึ้น" — ต้องเปลี่ยน netlist (โหมด speed) หรือเปลี่ยนสถาปัตยกรรม (6D)
2. **TNS โตเร็วกว่า WNS** — ที่ 2.5 ns โหมด area: WNS −1.024 แต่ TNS −5.120 แปลว่า endpoint หลายตัวพังพร้อมกัน (บิต result แต่ละบิตบน carry chain) ใช้ `report_checks -group_path_count 20 -endpoint_path_count 1` ดูรายชื่อ
3. **แลกกัน** — โหมด speed ได้ Fmax +16% (283.8 → 329.7 MHz) แต่พื้นที่ +30% (1903 → 2475 µm², 255 → 318 cell) เป็น trade-off พื้นฐานของ synthesis
4. **เทียบกับการคำนวณ 6B** — จุดตัดศูนย์ของเส้น area อยู่ระหว่าง 3.5 กับ 3.75 ns ตรงกับ period\_min 3.52 ที่คำนวณด้วยมือ

> **หมายเหตุ:** ที่ period สั้น path ไป output port ได้เวลาน้อยลงตาม (output delay = 30% ของ period) แต่ในดีไซน์นี้ reg→reg ยังเป็นตัวจำกัด — ตรวจด้วย `grep -A3 Startpoint reports/alu_top_area_sta_3ns.txt`

**ทำกราฟเอง (ทางเลือก):**

```python
# plot_sweep.py — python3 plot_sweep.py reports/sweep_alu_top_area.csv reports/sweep_alu_top_speed.csv
import csv, sys
import matplotlib.pyplot as plt
for f in sys.argv[1:]:
    rows = list(csv.DictReader(open(f)))
    plt.plot([float(r["period_ns"]) for r in rows], [float(r["worst_slack_ns"]) for r in rows],
             marker="o", label=f.split("sweep_")[1][:-4])
plt.axhline(0, color="k", lw=0.8)
plt.xlabel("clock period (ns)"); plt.ylabel("worst setup slack (ns)"); plt.legend(); plt.grid(alpha=.3)
plt.savefig("reports/sweep_alu_top.png", dpi=150)
```

✅ **Checkpoint 6C:** ได้ CSV 2 ไฟล์, อ่าน Fmax จากกราฟได้ตรงกับ `period_min` ±0.25 ns และอธิบายได้ว่าทำไมเส้นเป็นเส้นตรง

## 6D — เทียบ mult16 กับ mult16\_pipe (60 นาที)

**คำถามของส่วนนี้:** 6C แสดงว่า synthesis ดัน Fmax ได้ไม่มาก (+16%) ถ้าต้องการมากกว่านั้นต้องแก้ **สถาปัตยกรรม** — pipeline คือเครื่องมือหลัก แต่ต้องจ่ายด้วย latency และ flip-flop

### ขั้นที่ 1 — RTL สองแบบ (10 นาที)

`rtl/mult16.v` — ตัวคูณทั้งก้อนอยู่ระหว่าง register สองชั้น:

```verilog
// mult16.v : ตัวคูณ 16x16 แบบ combinational ล้วน ครอบด้วย register เข้า/ออก (latency 2 clock)
module mult16 (
  input  wire        clk, rst_n,
  input  wire [15:0] a_in, b_in,
  output reg  [31:0] p_out
);
  reg [15:0] a, b;
  always @(posedge clk)
    if (!rst_n) begin a <= 16'd0; b <= 16'd0; p_out <= 32'd0; end
    else begin
      a     <= a_in;
      b     <= b_in;
      p_out <= a * b;                 // ตัวคูณทั้งก้อนอยู่ใน path เดียว
    end
endmodule
```

`rtl/mult16_pipe.v` — แยกตามสมการ a·b = aʜ·bʜ·2¹⁶ + (aʜ·bʟ + aʟ·bʜ)·2⁸ + aʟ·bʟ โดย a = {aʜ, aʟ} แต่ละครึ่ง 8 บิต:

```verilog
// mult16_pipe.v : ตัวคูณ 16x16 แบบ pipeline 3 stage (latency 4 clock, throughput 1 ผล/clock)
//   a = {aH,aL}, b = {bH,bL}  →  a*b = aH*bH<<16 + (aH*bL + aL*bH)<<8 + aL*bL
//   stage A: คูณ 8x8 สี่ตัวพร้อมกัน
//   stage B: รวมสองพจน์กลาง (mid) ส่วน ll, hh ส่งต่อ
//   stage C: บวกทุกพจน์เป็นผลสุดท้าย
module mult16_pipe (
  input  wire        clk, rst_n,
  input  wire [15:0] a_in, b_in,
  output reg  [31:0] p_out
);
  reg [15:0] a, b;                       // register อินพุต
  reg [15:0] p_ll, p_lh, p_hl, p_hh;     // stage A
  reg [16:0] mid;                        // stage B (17 บิต กันล้น)
  reg [15:0] ll_b, hh_b;
  always @(posedge clk)
    if (!rst_n) begin
      a <= 0; b <= 0; p_ll <= 0; p_lh <= 0; p_hl <= 0; p_hh <= 0;
      mid <= 0; ll_b <= 0; hh_b <= 0; p_out <= 0;
    end else begin
      a     <= a_in;                                       // clock 1
      b     <= b_in;
      p_ll  <= a[7:0]  * b[7:0];                           // clock 2: stage A
      p_lh  <= a[7:0]  * b[15:8];
      p_hl  <= a[15:8] * b[7:0];
      p_hh  <= a[15:8] * b[15:8];
      mid   <= p_lh + p_hl;                                // clock 3: stage B
      ll_b  <= p_ll;
      hh_b  <= p_hh;
      p_out <= {hh_b, ll_b} + {7'd0, mid, 8'd0};           // clock 4: stage C
    end
endmodule
```

| จุดสำคัญ | เหตุผล |
| --- | --- |
| `ll_b`, `hh_b` | พจน์ที่ไม่ได้ใช้ใน stage B ต้องเดินทางผ่าน register ไปพร้อม `mid` — ลืมอันเดียวผลจะผสมข้อมูลคนละรอบ (บั๊ก pipeline คลาสสิก) |
| `{hh_b, ll_b}` | เอา hh เลื่อน 16 ไปต่อกับ ll ได้เลยเพราะไม่มีบิตซ้อนกัน — ประหยัดตัวบวกหนึ่งตัว |
| `mid` 17 บิต | ผลบวกของ 16+16 บิตอาจมี carry ออก (เช่น FFFF×FFFF) |
| reset ทุก register | ทำให้ gate-level sim ใน 6E ไม่มี X ค้างใน pipeline (แลกกับ and2 หน้า FF ทุกตัว) |

### ขั้นที่ 2 — พิสูจน์ RTL ก่อน synthesize (10 นาที)

`tb/tb_mult.sv` — testbench เดียวใช้ได้ทั้งสองแบบ และใช้ซ้ำกับ netlist ใน 6E:

```systemverilog
// tb_mult.sv : ใช้ได้กับ mult16 (LAT=2) และ mult16_pipe (LAT=4) ทั้ง RTL และ netlist
`timescale 1ns/1ps
module tb_mult;
  parameter int LAT = 2;                      // latency (clock) ของ DUT
  parameter int NRAND = 2000;
  logic        clk = 0, rst_n = 0;
  logic [15:0] a_in = 0, b_in = 0;
  wire  [31:0] p_out;
  int n = 0, errors = 0;
  logic [31:0] exp_q[$];

  `ifdef PIPE
    mult16_pipe dut (.*);
  `else
    mult16 dut (.*);
  `endif
  always #5 clk = ~clk;

  task automatic step(input logic [15:0] x, z);
    @(negedge clk);
    if (exp_q.size() == LAT) begin
      logic [31:0] e;  e = exp_q.pop_front();  n++;
      if (p_out !== e) begin
        errors++;
        if (errors <= 10) $display("FAIL t=%0t got %h exp %h", $time, p_out, e);
      end
    end
    a_in = x;  b_in = z;
    exp_q.push_back(x * z);                   // 32 บิตเพราะ e กว้าง 32
  endtask

  initial begin
    repeat (2) @(negedge clk);  rst_n = 1;
    step(16'hFFFF, 16'hFFFF);  step(0, 16'h1234);  step(16'h8000, 2);  step(16'h00FF, 16'hFF00);
    repeat (NRAND) step($urandom, $urandom);
    repeat (LAT) step(0, 0);
    $display("LAT=%0d checked %0d products, %0d errors", LAT, n, errors);
    if (errors == 0 && n > NRAND) $display("*** PASS ***"); else $display("*** FAIL ***");
    $finish;
  end
endmodule
```

คิว `exp_q` ยาวเท่า latency พอดี: ค่าคาดหวังที่ push เข้าไปตอนป้อน input จะถูก pop ออกมาเทียบหลังผ่านไป LAT clock — หลักเดียวกับ scoreboard ใน Lab 4

**ModelSim/Questa:**

```tcl
vlib work
vlog -sv tb/tb_mult.sv rtl/mult16.v
vsim -c tb_mult -do "run -all; quit"
vlog -sv +define+PIPE tb/tb_mult.sv rtl/mult16_pipe.v
vsim -c -gLAT=4 tb_mult -do "run -all; quit"
```

**Icarus (ทางเลือกโอเพนซอร์ส):**

```bash
iverilog -g2012 -o sim_m16 tb/tb_mult.sv rtl/mult16.v && vvp -n sim_m16
iverilog -g2012 -DPIPE -Ptb_mult.LAT=4 -o sim_m16p tb/tb_mult.sv rtl/mult16_pipe.v && vvp -n sim_m16p
```

ผลจริง:

```text
LAT=2 checked 2004 products, 0 errors
*** PASS ***
LAT=4 checked 2004 products, 0 errors
*** PASS ***
```

**ทดลองตั้งใจให้ผิด:** รัน mult16\_pipe ด้วย `-gLAT=3` (หรือ `-Ptb_mult.LAT=3`) → `LAT=3 checked 2004 products, 2004 errors` / `*** FAIL ***` — ทุกผลถูกต้องแต่มาผิดจังหวะ นี่คือเหตุผลที่การเพิ่ม pipeline stage ต้องแก้ทั้ง testbench และทุกโมดูลที่รอผล (เช่น valid signal ต้อง delay ตาม)

### ขั้นที่ 3 — Sweep ทั้งสี่ความเป็นไป (15 นาที)

```bash
P="12 10 8 7 6 5 4.5 4 3.5 3"
./scripts/sweep.sh mult16      rtl/mult16.v      "$P" area
./scripts/sweep.sh mult16      rtl/mult16.v      "$P" speed
./scripts/sweep.sh mult16_pipe rtl/mult16_pipe.v "$P" area
./scripts/sweep.sh mult16_pipe rtl/mult16_pipe.v "$P" speed
grep -h "Chip area\|sequential" reports/mult16*_stat.txt
```

ผลจริง (กรอกตารางในรายงาน):

| แบบ | โหมด | Area (µm²) | FF | period\_min (ns) | Fmax (MHz) | Latency (clock) | Latency (ns) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| mult16 | area | 9,945.8 | 64 | 8.02 | 124.7 | 2 | 16.0 |
| mult16 | speed | 12,695.9 | 64 | 6.04 | 165.6 | 2 | 12.1 |
| mult16\_pipe | area | 13,135.1 | 177 | 5.07 | 197.4 | 4 | 20.3 |
| mult16\_pipe | speed | 15,124.5 | 177 | 4.99 | 200.2 | 4 | 20.0 |

(Latency ns = clock × period\_min; FF ของ pipe = 32 input + 64 stage A + 17 mid + 32 ll\_b/hh\_b + 32 output = 177; area ของ FF เพิ่มจาก 12.9% เป็น 27.0% ของชิป)

### ขั้นที่ 4 — อ่าน critical path ของแต่ละแบบ (15 นาที)

```bash
awk '/^Startpoint/{n++} n==2' reports/mult16_area_sta_8ns.txt      | less   # reg→reg ของ mult16
awk '/^Startpoint/{n++} n==2' reports/mult16_pipe_area_sta_5ns.txt | less   # reg→reg ของ pipe
```

| แบบ | Arrival | Path แย่สุดอยู่ที่ |
| --- | --- | --- |
| mult16 (area) | 7.836 ns | register `a`/`b` → partial product array → adder tree → `p_out` — ทั้งตัวคูณใน path เดียว |
| mult16\_pipe (area) | 4.868 ns | **stage B**: `p_hl[0]` → and2 → `maj3_1` ต่อกัน **10 ตัว** (ตัวละ \~0.39 ns) → `mid[15]` — ripple-carry adder 16 บิต ไม่ใช่ตัวคูณ 8x8 |

**บทเรียนจากตาราง:**

1. **Throughput เพิ่ม 58%** (124.7 → 197.4 ล้านผล/วินาที) แลกกับพื้นที่ +32% — คุ้มกว่าโหมด speed ของ mult16 (+33% Fmax แลก +28% area)
2. **Latency เป็น ns แย่ลง** (16.0 → 20.3 ns) แม้ clock เร็วขึ้น เพราะ stage ไม่สมดุล และทุก stage ต้องจ่าย clk-to-Q + setup + uncertainty ซ้ำ — pipeline ช่วยงาน streaming (DSP, กราฟิก) ไม่ช่วยงานที่ต้องรอผลทีละตัว
3. **โหมด speed แทบไม่ช่วย pipe** (5.07 → 4.99 ns) เพราะ Yosys สร้าง `+` 16 บิตเป็น ripple carry — คอขวดใหม่คือตัวบวก ไม่ใช่ตัวคูณ นี่คือสิ่งที่ STA บอกแต่ตาราง area ไม่บอก
4. **ตำแหน่งของ register สำคัญกว่าจำนวน:** รุ่นแรกที่ผู้เขียนลอง (2 stage, คูณ 16x8 สองตัวแล้วบวก) ได้เพียง 6.73 ns / 148.6 MHz เพราะ 16x8 ยังยาว (arrival 6.535 ns) — แบ่งให้แต่ละ stage มี delay ใกล้เคียงกันคือหัวใจของ pipelining

**โจทย์ต่อยอด (ทางเลือก):** ย้ายการบวก `mid` ไปรวมกับ stage C เป็นตัวบวก 3 อินพุต (carry-save) หรือแบ่งตัวบวก 16 บิตเป็น 2 ครึ่งคนละ stage แล้ววัดว่า Fmax ขึ้นเท่าไร (อย่าลืมแก้ LAT ใน testbench)

✅ **Checkpoint 6D:** RTL ทั้งสอง PASS, ตาราง 8 คอลัมน์ครบทั้ง 4 แถว และชี้ได้ว่า critical path ของ pipe อยู่ stage ไหนพร้อมหลักฐานจากรายงาน

## 6E — Gate-level simulation ของ netlist (45 นาที)

**ทำไมต้องทำ ทั้งที่ STA ผ่านแล้ว:** STA พิสูจน์ *เวลา* แต่ไม่พิสูจน์ *ฟังก์ชัน* — gate-level sim (GLS) จับสิ่งที่ RTL sim มองไม่เห็น เช่น โค้ดที่ synthesize ต่างจากที่ simulate (`initial`, sensitivity list ไม่ครบ, `casez`/`x` ที่ RTL มองแบบมองโลกสวย), register ที่ไม่ได้ reset แล้วปล่อย X หรือบั๊กของเครื่องมือ synthesis เอง หลักสำคัญคือ **ใช้ testbench ตัวเดิมทุกบรรทัด** แค่เปลี่ยน DUT จาก RTL เป็น netlist (ชื่อ module และ port เหมือนเดิม เพราะเราไม่ได้ใช้ `splitnets -ports`)

### ขั้นที่ 1 — เตรียม Verilog model ของ cell (10 นาที)

netlist อ้างถึง cell เช่น `sky130_fd_sc_hd__dfxtp_1` ซึ่งต้องมี Verilog model ให้ simulator (ไฟล์ .lib มีแต่ timing ไม่มีพฤติกรรม):

```bash
cd ~ && git clone --depth 1 https://github.com/google/skywater-pdk-libs-sky130_fd_sc_hd.git sky130_fd_sc_hd
export SC_HD=~/sky130_fd_sc_hd
ls $SC_HD/cells/dfxtp/        # sky130_fd_sc_hd__dfxtp_1.v → ห่อ sky130_fd_sc_hd__dfxtp.v → functional/behavioral
```

> ถ้าติดตั้ง PDK ด้วย volare/open\_pdks ไว้แล้ว มีไฟล์รวมให้ใช้แทนได้: `$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v` + `sky130_fd_sc_hd.v` (compile ตรง ๆ พร้อม define เดียวกัน) — คู่มือนี้ใช้ repo ด้านบนเพราะทดสอบแล้ว

`scripts/gls_cells.sh` — ดึงเฉพาะ cell ที่ netlist ใช้จริง (compile เร็วกว่าดึงทั้ง \~430 ตัว):

```bash
#!/usr/bin/env bash
# gls_cells.sh — เตรียมไฟล์สำหรับ gate-level sim ของ netlist sky130_fd_sc_hd
#   sim/incdirs.f       : +incdir+ ทุกโฟลเดอร์ของ cell model (ใช้ได้ทั้ง vlog -f และ iverilog -c)
#   sim/cells_<tag>.v   : `include เฉพาะ cell ที่ netlist ใช้จริง
# ใช้งาน:  SC_HD=~/sky130_fd_sc_hd ./scripts/gls_cells.sh out/alu_top_area_netlist.v alu
set -e
NETLIST=$1; TAG=$2
: "${SC_HD:?ตั้ง SC_HD ให้ชี้ไปที่ skywater-pdk-libs-sky130_fd_sc_hd ก่อน}"
mkdir -p sim
for d in "$SC_HD"/cells/* "$SC_HD"/models/*; do echo "+incdir+$d"; done > sim/incdirs.f
grep -o 'sky130_fd_sc_hd__[a-z0-9_]*' "$NETLIST" | sort -u |
  while read c; do echo "\`include \"$c.v\""; done > sim/cells_${TAG}.v
echo "$(wc -l < sim/cells_${TAG}.v) cell types -> sim/cells_${TAG}.v"
```

```bash
chmod +x scripts/gls_cells.sh
./scripts/gls_cells.sh out/alu_top_area_netlist.v     alu    # → 44 cell types
./scripts/gls_cells.sh out/mult16_area_netlist.v      m16
./scripts/gls_cells.sh out/mult16_pipe_area_netlist.v mp     # → 39 cell types
```

### ขั้นที่ 2 — รัน GLS ใน ModelSim/Questa (15 นาที)

สอง define ที่ขาดไม่ได้:

| Define | ผล |
| --- | --- |
| `FUNCTIONAL` | เลือก model แบบ functional (ไม่มี power pin, ไม่มี timing check) — เหมาะกับตรวจฟังก์ชัน |
| `UNIT_DELAY=#1` | ใส่ delay 1 หน่วยที่เอาต์พุต FF กัน race ระหว่าง clock กับ data (ไม่ใส่จะมี warning "macro UNIT\_DELAY undefined") |

```tcl
# gls_alu.do — vsim -c -do gls_alu.do
# -timescale: cell model ไม่มี `timescale ของตัวเอง กำหนดให้เหมือน testbench (#1 = 1 ns)
vlib work_gls
vlog -work work_gls -sv -timescale 1ns/1ps +define+FUNCTIONAL +define+UNIT_DELAY=#1 -f sim/incdirs.f \
     sim/cells_alu.v out/alu_top_area_netlist.v tb/tb_alu_top.sv
vsim -lib work_gls -c tb_alu_top
run -all
quit
```

```tcl
# gls_mult.do — ทำซ้ำกับ mult16 (ไม่ต้อง +define+PIPE, LAT=2) และ mult16_pipe
vlib work_gls
vlog -work work_gls -sv -timescale 1ns/1ps +define+FUNCTIONAL +define+UNIT_DELAY=#1 +define+PIPE -f sim/incdirs.f \
     sim/cells_mp.v out/mult16_pipe_area_netlist.v tb/tb_mult.sv
vsim -lib work_gls -c -gLAT=4 tb_mult
run -all
quit
```

**Icarus (ผลด้านล่างมาจากทางนี้):**

```bash
DEF="-DFUNCTIONAL -DUNIT_DELAY=#1"
iverilog -g2012 $DEF -c sim/incdirs.f -o sim/gls_alu tb/tb_alu_top.sv sim/cells_alu.v out/alu_top_area_netlist.v
vvp -n sim/gls_alu
iverilog -g2012 $DEF -c sim/incdirs.f -o sim/gls_m16 tb/tb_mult.sv sim/cells_m16.v out/mult16_area_netlist.v
vvp -n sim/gls_m16
iverilog -g2012 $DEF -DPIPE -Ptb_mult.LAT=4 -c sim/incdirs.f -o sim/gls_mp \
         tb/tb_mult.sv sim/cells_mp.v out/mult16_pipe_area_netlist.v
vvp -n sim/gls_mp
```

ผลจริง (ต้องตรงกับ RTL sim ทุกตัวเลข):

```text
checked 2008 vectors, 0 errors          <- alu_top netlist
*** PASS ***
LAT=2 checked 2004 products, 0 errors   <- mult16 netlist
*** PASS ***
LAT=4 checked 2004 products, 0 errors   <- mult16_pipe netlist
*** PASS ***
```

### ขั้นที่ 3 — ดู waveform เทียบ RTL กับ netlist (10 นาที)

ใน ModelSim GUI (`vsim -lib work_gls tb_mult -gLAT=4`) สั่ง:

```tcl
add wave /tb_mult/clk /tb_mult/rst_n /tb_mult/a_in /tb_mult/b_in
add wave -radix hex /tb_mult/p_out
add wave /tb_mult/dut/*          ;# เห็น wire ชื่อ _1234_ แทน mid, p_hl
run 200 ns
```

สิ่งที่ควรสังเกต:

1. ชื่อสัญญาณภายในหายไปเกือบหมด (เหลือเฉพาะที่เป็น Q ของ FF เช่น `b[1]` ใน alu\_top) — หา FF ได้ด้วย `grep -A4 "dfxtp_1 _456_" out/alu_top_area_netlist.v`
2. `p_out` เปลี่ยนหลังขอบ clock เท่ากับ `UNIT_DELAY` ที่ตั้งเอง (#1 = 1 ns) ไม่ใช่ delay จริงของวงจร (7.8 ns ของ mult16) — GLS แบบ functional ไม่บอก timing นั่นคือหน้าที่ STA
3. ช่วง reset ทุก FF เป็น 0 ไม่ใช่ X — เพราะ RTL reset ทุก register ลองลบ reset ของ `mid` ใน RTL แล้ว synthesize + GLS ใหม่ ดูว่า X ไหลไปถึง `p_out` กี่ clock (testbench ยัง PASS ไหม? เพราะอะไร?)

### ขั้นที่ 4 — ทดลอง: ลืม define (5 นาที)

รัน alu\_top ซ้ำโดยตัด `FUNCTIONAL` ออก (ใช้ model behavioral ที่มี power-aware logic และ timing check):

```text
FAIL: outputs not 0 during reset: xxxxxxxxxxx
FAIL t=50000 got y=xx zcv=xxx exp y=80 zcv=001
...
checked 2008 vectors, 2009 errors
*** FAIL ***
```

ผลนี้ได้จาก Icarus: ทุกเอาต์พุตเป็น X ตั้งแต่ต้น **ไม่ใช่บั๊กของดีไซน์** แต่เป็น model/simulator ไม่เข้ากัน — บทเรียนคือ GLS ที่ FAIL ทุก vector ตั้งแต่ reset มักเป็นปัญหา setup การจำลอง ตรวจ define/library ก่อนไล่หาบั๊ก (ใน ModelSim ผลอาจต่างออกไป ให้บันทึกสิ่งที่เห็น)

### ต่อยอด (ทางเลือก): GLS พร้อม SDF

OpenSTA เขียน SDF จาก netlist หลัง synthesis ได้ (ทดสอบแล้ว: ได้ไฟล์ VERSION 3.1.0 มี 256 CELLTYPE สำหรับ alu\_top):

```tcl
# ต่อท้าย sta.tcl หรือรันใน sta แบบ interactive
write_sdf -digits 3 out/alu_top.sdf
```

```tcl
# ModelSim: ใช้ model behavioral (ไม่ใส่ FUNCTIONAL) เพราะต้องมี specify block ให้ SDF annotate
vlog -work work_sdf -sv -timescale 1ns/1ps +define+UNIT_DELAY=#1 -f sim/incdirs.f \
     sim/cells_alu.v out/alu_top_area_netlist.v tb/tb_alu_top.sv
vsim -lib work_sdf -c -sdfmax /tb_alu_top/dut=out/alu_top.sdf tb_alu_top -do "run -all; quit"
```

⚠️ ส่วน SDF นี้ผู้เขียนยังไม่ได้ทดสอบบน ModelSim จริง และ SDF หลัง synthesis มีเฉพาะ cell delay (ไม่มี wire, clock ideal) — timing sim ที่มีความหมายจริงต้องใช้ SDF หลัง route จาก Lab 5 ให้ถือเป็นการสาธิตกลไก ไม่ใช่การ sign-off

✅ **Checkpoint 6E:** GLS ของ netlist ทั้ง 3 ตัว PASS ด้วย testbench เดิม และอธิบายได้ว่า GLS แบบ functional พิสูจน์อะไร และไม่พิสูจน์อะไร

## แก้ปัญหา, คำถามท้าย Lab และเกณฑ์ให้คะแนน

### ตารางแก้ปัญหา

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| Yosys `check` ฟ้อง "used but has no driver" ที่ cell ทุกตัว | ไม่ได้อ่าน .lib ให้ Yosys รู้ทิศทาง pin | ใส่ `read_liberty -lib $LIB` ก่อน `read_verilog` |
| netlist มี `lpflow_isobufsrc` / `probe` | ABC เลือก cell พิเศษที่มีใน .lib | `-dont_use *lpflow* -dont_use *probe*` ทั้งใน `dfflibmap` และ `abc` |
| `link_design` ฟ้องหา module ไม่เจอ | ชื่อ TOP ไม่ตรง หรืออ่าน netlist ผิด TAG | ดู `ls out/` แล้วตั้ง `TAG` ให้ตรงกับชื่อไฟล์ |
| STA รายงาน "No paths found" / slack สวยผิดปกติ | ไม่มี clock (`create_clock` หาย หรือชื่อ port ผิด) | `report_clock_properties`; ตรวจ `get_ports clk` |
| เปลี่ยน `CLK_PERIOD` แล้ว area เท่าเดิม | พฤติกรรมปกติของ `abc` สคริปต์ประจำ (6C ขั้นที่ 1) | ใช้โหมด speed (`ABC_SPEED=1`) |
| `sweep.sh` ได้ค่าว่างใน CSV | `sta` หยุดด้วย error | เปิด `reports/<tag>_sta_<P>ns.txt` ดูบรรทัดแรกที่เป็น Error |
| GLS: `Unknown module type: sky130_fd_sc_hd__...` | ไม่ได้ include cell / ไม่มี `-f sim/incdirs.f` | รัน `gls_cells.sh` ใหม่หลัง synthesize ทุกครั้ง (cell ที่ใช้เปลี่ยนได้) |
| GLS เป็น X ทั้งหมดตั้งแต่ reset | ลืม `+define+FUNCTIONAL` (6E ขั้นที่ 4) | ใส่ define ให้ครบทั้งสองตัว |
| GLS FAIL แต่ RTL PASS | latency ต่าง (ลืม `-gLAT=4`) หรือบั๊กจริงที่ GLS จับได้ | เทียบ waveform RTL กับ netlist ที่ vector แรกที่ FAIL |
| ModelSim: "Module ... does not have a timeunit" | cell model ไม่มี \`timescale | ใส่ `-timescale 1ns/1ps` ใน vlog |

### คำถามท้าย Lab

1. จากรายงาน 6B ถ้าเพิ่ม `set_clock_uncertainty -setup` เป็น 0.3 ns period\_min จะเป็นเท่าไร (คำนวณก่อน แล้วรันยืนยัน)
2. ทำไม `wns` ที่ 10 ns เป็น 0 แต่ `worst slack` เป็น 6.451? ในทางปฏิบัติควรดูค่าไหนตอนไหน
3. FF `b[1]` มี fanout 32 — อธิบายสองวิธีแก้ (ระดับ RTL และระดับเครื่องมือ) พร้อมข้อเสีย
4. hold slack 0.073 ns ตอนนี้ผ่าน หลัง CTS อะไรทำให้มันละเมิดได้ และเครื่องมือแก้ด้วยวิธีอะไร (โยงกับ Lab 5)
5. ใน 6C เส้น slack เป็นเส้นตรงความชัน 1 — อธิบายด้วยสมการ slack = required − arrival และบอกว่าเมื่อไหร่เส้นจะไม่ตรง (คำใบ้: input/output delay เป็น % ของ period)
6. mult16\_pipe มี Fmax สูงกว่าแต่ latency (ns) แย่กว่า ยกตัวอย่างงานที่ควรเลือกแต่ละแบบอย่างละ 1 งาน
7. ถ้าต้องการ mult16\_pipe ที่ 250 MHz จะแก้ส่วนไหนก่อน อ้างอิงหลักฐานจากรายงาน STA ไม่ใช่การเดา
8. GLS แบบ functional กับ STA ต่างพิสูจน์อะไร ทำไมทำอย่างใดอย่างหนึ่งไม่พอ

### สิ่งที่ต้องส่ง

```text
lab06/
├── rtl/            alu8.v alu8.vhd alu_top.v alu_top.vhd mult16.v mult16_pipe.v
├── constraints/    lab06.sdc
├── scripts/        synth.tcl sta.tcl sweep.sh gls_cells.sh abc_speed.script
├── tb/             tb_alu_top.sv tb_mult.sv
├── reports/        *_stat.txt  alu_top_sta.txt  sweep_*.csv  sweep_alu_top.png (ถ้าทำ)
├── out/            *_netlist.v
└── report.pdf      (≤ 4 หน้า)
```

`report.pdf` ต้องมี: ตาราง area/cell จาก 6A (Verilog เทียบ VHDL), การคำนวณ slack ด้วยมือของ setup และ hold path (6B), กราฟ slack–period พร้อม Fmax สองโหมด (6C), ตาราง 8 คอลัมน์ของ 6D พร้อมชี้ critical path ของแต่ละแบบ, ผล GLS 3 ตัว (6E) และคำตอบคำถามท้าย Lab

### เกณฑ์ให้คะแนน (100 คะแนน)

| ส่วน | เกณฑ์ | คะแนน |
| --- | --- | --- |
| 6A | synthesize ได้ทั้ง Verilog และ VHDL, `check` 0 problems, อธิบายรายงาน stat ได้ | 15 |
| 6B | คำนวณ required/slack/period\_min ตรงรายงาน, ระบุ start/endpoint เป็นสัญญาณ RTL, ทดลองครบ 3 ข้อ | 25 |
| 6C | สคริปต์ทำงานอัตโนมัติ, กราฟถูกต้อง, Fmax ตรงกับ period\_min | 20 |
| 6D | ตารางครบ, RTL PASS ทั้งสองแบบ, วิเคราะห์ trade-off และ critical path ด้วยหลักฐาน | 25 |
| 6E | GLS PASS 3 netlist ด้วย testbench เดิม, ตอบคำถามในขั้นที่ 3 | 15 |

**โบนัส (+10):** ทำโจทย์ต่อยอดใน 6D ให้ Fmax ของ pipe เกิน 220 MHz โดย GLS ยัง PASS

> **หมายเหตุสำหรับผู้สอน:** ตัวเลขทุกตัวใน Lab นี้ได้จากการรันจริงด้วย Yosys 0.69, OpenSTA 3.1.0, GHDL 4.1 (`--synth`) และ Icarus Verilog 12 กับ sky130\_fd\_sc\_hd TT 25°C 1.8 V — เวอร์ชันอื่นอาจได้ cell count/Fmax ต่างได้หลายเปอร์เซ็นต์ ให้ตรวจที่ *แนวโน้มและเหตุผล* มากกว่าตัวเลขตรง ๆ คำสั่ง ModelSim เขียนตามรูปแบบมาตรฐานแต่ยังไม่ได้รันบน ModelSim จริง ควรลองก่อนสอน

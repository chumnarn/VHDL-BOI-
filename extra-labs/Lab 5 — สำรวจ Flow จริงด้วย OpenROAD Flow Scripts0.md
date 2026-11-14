# Lab 5 — สำรวจ Flow จริงด้วย OpenROAD Flow Scripts

Oct 28, 2026 · @Chumnarn Punyasai

## ภาพรวม Lab 5

**เป้าหมาย:** รัน flow RTL → GDS กับดีไซน์ตัวอย่าง `gcd` ที่มากับ OpenROAD Flow Scripts (ORFS) บน platform `sky130hd` ทีละขั้น เปิดดูผลใน GUI และเก็บตัวเลขสำคัญจากรายงาน — Lab นี้ไม่ต้องเขียน RTL เน้น "เห็น" ทุกขั้นที่เรียนใน Module 05 หัวข้อ 5.1–5.5

**เมื่อจบ Lab ผู้เรียนจะ**

1. อ่าน `config.mk` และ SDC ของดีไซน์ใน ORFS แล้วบอกได้ว่าตัวแปรแต่ละตัวควบคุมขั้นไหน
2. รัน flow ทีละ make target และบอกได้ว่าแต่ละขั้นรับไฟล์อะไร สร้างไฟล์อะไร
3. ชี้ core, row, power stripe, tap cell, filler, clock buffer และสายแต่ละชั้นใน GUI ได้
4. ดึง cell count, area, utilization, WNS/TNS, skew, DRC และ power จากรายงานด้วย `grep` / `jq`
5. เปลี่ยน utilization และ clock period แล้วอธิบายผลที่เกิดกับ PPA

**ความรู้ที่ต้องมีก่อน:** Module 05 หัวข้อ 5.1–5.5 (ลำดับ flow, ชนิดไฟล์, SDC, PDK, physical design), คำสั่ง Linux พื้นฐาน (`cd`, `ls`, `cat`, `grep`)

| ขั้น | งาน | เวลา |
| --- | --- | --- |
| 5.0 | ติดตั้งและตรวจสภาพแวดล้อม ORFS | ก่อนเข้า Lab (ผู้สอนเตรียมเครื่อง) |
| 1 | อ่าน config.mk, SDC และ RTL ของ gcd | 10 นาที |
| 2 | รันทีละขั้น พร้อมตรวจผลหลังแต่ละขั้น | 40 นาที |
| 3 | เปิดดูแต่ละขั้นใน OpenROAD GUI และ KLayout | 25 นาที |
| 4 | เก็บตัวเลขจากรายงานลงตาราง | 20 นาที |
| 5 | ทดลองเปลี่ยนพารามิเตอร์ (A, B, C) | 25 นาที (รันพร้อมกันได้) |

&#91;embedded content: ขั้นของ ORFS · make target, เครื่องมือภายใน และไฟล์ผลลัพธ์\]

ชื่อสั้นในกล่องคือเครื่องมือย่อยภายใน OpenROAD: `ifp` (initialize floorplan), `pdn` (power grid), `gpl`/`dpl` (global/detailed placement), `rsz` (resizer: ใส่ buffer และปรับขนาด cell), `grt`/`drt` (global/detailed route) — จะเห็นชื่อเหล่านี้นำหน้าข้อความใน log เช่น `[INFO GPL-0002]`

> **หมายเหตุผู้สอน:** คำสั่ง ชื่อ target และชื่อไฟล์ในคู่มือนี้ตรวจกับ source ของ ORFS ล่าสุด (ตุลาคม 2026) และผลขั้น synthesis เป็นผลรันจริงด้วยสคริปต์ของ ORFS — ขั้นหลัง synthesis ยังไม่ได้รันในสภาพแวดล้อมที่ใช้เขียนคู่มือ ตัวเลขอ้างอิงขั้นอื่นจึงมาจากเกณฑ์ CI ของ ORFS เอง ให้รันครบหนึ่งรอบบนเครื่องห้องแล็บก่อนสอนแล้วแทนค่าจริงลงในเฉลย

## 5.0 เตรียมและตรวจสภาพแวดล้อม (ก่อนเข้า Lab)

ORFS ประกอบด้วย 3 ส่วน: **สคริปต์** (Makefile + Tcl ใน repo), **เครื่องมือ** (Yosys, OpenROAD, KLayout) และ **platform** (PDK ที่ตัดมาให้พร้อมใช้ เช่น `flow/platforms/sky130hd/`) — การติดตั้งคือการหาเครื่องมือให้สคริปต์เรียกใช้ได้ มี 2 ทางที่แนะนำสำหรับห้องแล็บ (การ build จาก source ใช้เวลาหลายชั่วโมง ไม่แนะนำในคาบเรียน)

| ทางเลือก | เหมาะกับ | ข้อดี | ข้อควรระวัง |
| --- | --- | --- | --- |
| A. Docker image `openroad/orfs` | Windows (Docker Desktop + WSL2), Linux, macOS | เครื่องมือเวอร์ชันตรงกันทุกเครื่อง | image ใหญ่หลาย GB — ดาวน์โหลดล่วงหน้า, GUI ต้องตั้ง X11 |
| B. Pre-built binary | Ubuntu 22.04 / 24.04 (รวม WSL2) | GUI เปิดตรง ๆ ไม่ผ่าน container | ต้องติดตั้ง Yosys และ KLayout เองให้เวอร์ชันเข้ากัน |

### ทาง A — Docker

```bash
git clone https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git
cd OpenROAD-flow-scripts
docker pull openroad/orfs:latest

# เข้า container โดยเมาท์โฟลเดอร์ flow ของเราเข้าไป (ผลลัพธ์จะอยู่บนเครื่องเรา ไม่หายตอนปิด container)
docker run --rm -it -u $(id -u ${USER}):$(id -g ${USER}) \
  -v $(pwd)/flow:/OpenROAD-flow-scripts/flow openroad/orfs

# ภายใน container
source ./env.sh
yosys -V
openroad -version
cd flow
```

ทางลัดที่ ORFS เตรียมไว้: อยู่ในโฟลเดอร์ `flow` แล้วพิมพ์ `util/docker_shell make ...` หรือ `util/docker_shell gui_final` — สคริปต์จะสร้างคำสั่ง `docker run` พร้อม volume และ DISPLAY ให้

GUI จาก container บน Linux ต้องส่ง X11 เข้าไปด้วย (`-e DISPLAY=${DISPLAY} -v /tmp/.X11-unix:/tmp/.X11-unix -v ${HOME}/.Xauthority:/.Xauthority --network host`) บน Windows 11 ที่ใช้ WSL2 มี WSLg ให้อยู่แล้ว

### ทาง B — Pre-built binary

1. ดาวน์โหลดแพ็กเกจ `.deb` ของ OpenROAD จาก OpenROAD VaultLink (Precision Innovations) ให้ตรงกับรุ่น Ubuntu แล้ว `sudo apt install ./openroad_<version>_amd64-ubuntu-24.04.deb`
2. ติดตั้ง Yosys (เช่นจาก OSS CAD Suite) และ KLayout ตามเวอร์ชันขั้นต่ำที่เอกสาร `docs/user/BuildWithPrebuilt.md` ใน repo ระบุ
3. บอก ORFS ว่าเครื่องมืออยู่ที่ไหน:

```bash
git clone https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git
export OPENROAD_EXE=$(command -v openroad)
export YOSYS_EXE=$(command -v yosys)
cd OpenROAD-flow-scripts/flow
```

ใส่สองบรรทัด `export` ไว้ใน `~/.bashrc` ไม่เช่นนั้นต้องพิมพ์ใหม่ทุกครั้งที่เปิด terminal

### Smoke test — รันก่อนเข้าคาบทุกเครื่อง

```bash
# อยู่ที่ OpenROAD-flow-scripts/flow
make DESIGN_CONFIG=./designs/sky130hd/gcd/config.mk synth
ls results/sky130hd/gcd/base/
```

ผ่านเมื่อเห็นไฟล์ `1_synth.odb` — ขั้นนี้ใช้เวลาไม่ถึง 1 นาทีสำหรับ gcd ถ้าหยุดด้วย error ให้ดูตารางแก้ปัญหาท้าย Lab จากนั้นล้างผลด้วย `make DESIGN_CONFIG=./designs/sky130hd/gcd/config.mk clean_all` ก่อนเริ่ม Lab จริง

> **คำแนะนำผู้สอน:** รัน flow gcd ครบทุกขั้นบนเครื่องผู้สอนก่อนสอน แล้วบีบอัดโฟลเดอร์ `results/`, `reports/`, `logs/` ของ gcd เก็บไว้ — เครื่องผู้เรียนที่ติดตั้งไม่สำเร็จยังทำขั้นที่ 3–4 (ดู GUI และอ่านรายงาน) ได้จากผลชุดนี้

✅ **Checkpoint 5.0:** `yosys -V` และ `openroad -version` พิมพ์เวอร์ชันได้ และ smoke test สร้าง `1_synth.odb` สำเร็จ (จดเวอร์ชันทั้งสองไว้ในรายงาน เพราะตัวเลขทุกตัวขึ้นกับเวอร์ชัน)

## ขั้นที่ 1 — อ่านไฟล์ตั้งค่าของดีไซน์ (10 นาที)

ก่อนกด make ให้รู้ก่อนว่า flow จะทำอะไรกับดีไซน์ไหน ด้วยเงื่อนไขอะไร — ทุกอย่างอยู่ใน 3 ไฟล์

```bash
cd OpenROAD-flow-scripts/flow
cat designs/sky130hd/gcd/config.mk         # ตัวแปรของดีไซน์
cat designs/sky130hd/gcd/constraint.sdc    # timing constraint
ls  designs/src/gcd/                        # RTL ต้นฉบับ
```

### 1.1 config.mk

เนื้อหาใน ORFS เวอร์ชันปัจจุบัน (ตุลาคม 2026 — เวอร์ชันอื่นอาจมีบรรทัดต่างเล็กน้อย):

```makefile
export DESIGN_NAME = gcd
export PLATFORM    = sky130hd

export VERILOG_FILES = $(DESIGN_HOME)/src/$(DESIGN_NICKNAME)/gcd.v
export SDC_FILE      = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/constraint.sdc

# Adders degrade GCD
export ADDER_MAP_FILE :=

export CORE_UTILIZATION = 38
export TNS_END_PERCENT = 100
export SWAP_ARITH_OPERATORS = 1
export OPENROAD_HIERARCHICAL = 1
```

| ตัวแปร | ควบคุมขั้น | ความหมาย |
| --- | --- | --- |
| `DESIGN_NAME` | ทุกขั้น | ชื่อ top module ใน RTL |
| `PLATFORM` | ทุกขั้น | เลือก PDK → ดึง .lib, .lef, .gds จาก `platforms/sky130hd/` |
| `VERILOG_FILES`, `SDC_FILE` | synth (และ SDC ใช้ต่อทุกขั้น) | input หลักของ flow |
| `CORE_UTILIZATION` | floorplan | พื้นที่ cell ÷ พื้นที่ core = 38% → เครื่องมือคำนวณขนาด core เอง (สูตรเดียวกับ 5.5) |
| `SWAP_ARITH_OPERATORS` | synth → floorplan | Yosys สร้างตัวบวกหลายสถาปัตยกรรมไว้ให้ OpenROAD เลือกตาม timing (จะเห็นในขั้นที่ 2) |
| `TNS_END_PERCENT` | place, cts, route | สัดส่วน endpoint ที่ repair\_timing พยายามแก้ (100 = ทุก endpoint) |

ตัวแปรที่**ไม่ได้ตั้ง**ในไฟล์นี้จะใช้ค่าจาก platform — เปิดดู `platforms/sky130hd/config.mk` จะเจอเช่น `PLACE_DENSITY ?= 0.60`, `MIN_ROUTING_LAYER ?= met1`, `MAX_ROUTING_LAYER ?= met5`, `TAP_CELL_NAME = sky130_fd_sc_hd__tapvpwrvgnd_1`, `FILL_CELLS ?= sky130_fd_sc_hd__fill_1 ... fill_8` (เครื่องหมาย `?=` แปลว่า "ใช้ค่านี้ถ้าดีไซน์ไม่ได้ตั้ง") คำอธิบายตัวแปรทุกตัวอยู่ใน `docs/user/FlowVariables.md`

### 1.2 constraint.sdc

```tcl
current_design gcd

set clk_name core_clock
set clk_port_name clk
set clk_period 1.1
set clk_io_pct 0.2

set clk_port [get_ports $clk_port_name]

create_clock -name $clk_name -period $clk_period $clk_port
set clk_io_name vclk_$clk_name
create_clock -name $clk_io_name -period $clk_period
set_clock_latency 0.290 [get_clocks $clk_name]
set_clock_latency 0.290 [get_clocks $clk_io_name]

set non_clock_inputs [all_inputs -no_clocks]

set_input_delay [expr $clk_period * $clk_io_pct] -clock $clk_io_name $non_clock_inputs
set_output_delay [expr $clk_period * $clk_io_pct] -clock $clk_io_name [all_outputs]
```

อ่านด้วยความรู้จาก 5.3:

| บรรทัด | ความหมาย | ตัวเลข |
| --- | --- | --- |
| `create_clock -name core_clock -period 1.1` | clock จริงที่พอร์ต `clk` | 1.1 ns ≈ 909 MHz — ตั้งให้ตึงจนเกือบไม่ผ่าน เพื่อใช้ทดสอบเครื่องมือ |
| `create_clock -name vclk_core_clock` (ไม่มี port) | **virtual clock** แทน clock ของชิปภายนอก ใช้อ้างอิง I/O delay | period เท่ากัน |
| `set_clock_latency 0.290` | ประมาณ insertion delay ก่อนมี clock tree ให้ I/O path สมจริง | 0.29 ns |
| `set_input_delay` / `set_output_delay` | ภายนอกใช้เวลาไป 20% ของ period | 1.1 × 0.2 = 0.22 ns |
| `all_inputs -no_clocks` | ทุก input ยกเว้น clk | รวม `reset` (synchronous reset จึงต้องตรวจ timing) |

สิ่งที่ SDC นี้**ไม่มี**เทียบกับตัวอย่าง `uart_fifo_top.sdc` ใน 5.3: ไม่มี `set_clock_uncertainty`, `set_driving_cell`, `set_load` — เป็น SDC ขั้นต่ำสำหรับทดสอบ flow ไม่ใช่ signoff จริง

### 1.3 RTL และ PDK

`designs/src/gcd/gcd.v` (ราว 750 บรรทัด สร้างจาก PyMTL) คือตัวหา ห.ร.ม. แบบ Euclid แบบเดียวกับตัวอย่าง FSMD ใน Module 03 หัวข้อ 3.7: พอร์ต `req_msg[31:0]` (ตัวเลข 16 บิต 2 ตัว), `resp_msg[15:0]`, handshake `req_val/req_rdy` และ `resp_val/resp_rdy` ภายในแยกเป็น controller (FSM) กับ datapath (register A, B, ตัวเปรียบเทียบ และตัวลบ 16 บิต)

สำรวจ PDK ที่ ORFS ใช้ (ผลจริงจาก ORFS เวอร์ชันปัจจุบัน):

```bash
ls platforms/sky130hd/lib/
# sky130_dummy_io.lib  sky130_fd_sc_hd__tt_025C_1v80.lib     ← มี corner เดียวคือ TT
grep -c '^ *cell *(' platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
# 428
grep -c MACRO platforms/sky130hd/lef/sky130_fd_sc_hd_merged.lef
# 441
grep '^LAYER' platforms/sky130hd/lef/sky130_fd_sc_hd.tlef | tr '\n' ' '
# LAYER nwell LAYER pwell LAYER li1 LAYER mcon LAYER met1 LAYER via LAYER met2 ... LAYER met5
```

จุดที่ควรชี้ให้ผู้เรียนเห็น: (1) platform ใน ORFS มี .lib เฉพาะ TT — flow นี้จึงตรวจ timing ที่ corner เดียว ต่างจาก signoff จริงที่ต้องผ่าน SS และ FF ด้วย (5.4) (2) LEF มี macro มากกว่า cell ใน .lib 13 ตัว — เทียบรายชื่อแล้วคือ `fill_1/2/4/8`, `tap_1/2`, `tapvgnd_1`, `tapvgnd2_1`, `tapvpwrvgnd_1` และ `sky130_ef_sc_hd__decap_12`, `fill_8`, `fill_12`, `fakediode_2` ซึ่งไม่มีลอจิกให้ STA ต้องคำนวณ แต่ P&R ต้องรู้ขนาดเพื่อวางลง row — ตัวอย่างชัดของความต่างระหว่าง .lib กับ .lef ใน 5.1

**คำถามขั้นที่ 1 (ตอบลงใบงาน):** clock ชื่ออะไร period เท่าไร คิดเป็น MHz เท่าไร · utilization ที่ตั้งไว้กี่ % · input delay กี่ ns · virtual clock มีไว้ทำไม (เฉลย: `core_clock`, 1.1 ns ≈ 909 MHz, 38%, 0.22 ns, ใช้อ้างอิงเวลาของชิปภายนอกที่ไม่มี port บนชิปเรา)

## ขั้นที่ 2 — รันทีละขั้นและตรวจผลหลังทุกขั้น (40 นาที)

กติกา: รันทีละ target → ดูไฟล์ที่เกิด → ตอบคำถาม "ตรวจอะไรก่อนไปต่อ" (ตามตาราง 5.2) → ค่อยรันขั้นถัดไป — อย่ารันทั้งหมดรวดเดียว เพราะจุดประสงค์คือเห็นการเปลี่ยนแปลงทีละขั้น

```bash
cd OpenROAD-flow-scripts/flow
export CFG=./designs/sky130hd/gcd/config.mk
export R=results/sky130hd/gcd/base   L=logs/sky130hd/gcd/base   P=reports/sky130hd/gcd/base
```

ตัวแปร `R`, `L`, `P` ช่วยให้พิมพ์สั้นลง — ORFS แยกผลเป็น `results/` (ไฟล์ดีไซน์), `logs/` (ทุกสิ่งที่เครื่องมือพิมพ์) และ `reports/` (รายงานสรุป) ตาม `<platform>/<design>/<variant>` ซึ่ง variant ค่าเริ่มต้นคือ `base`

### 2.1 Synthesis — `make DESIGN_CONFIG=$CFG synth`

| ขั้นย่อย | ทำอะไร | ไฟล์ |
| --- | --- | --- |
| 1\_1\_yosys\_canonicalize | อ่าน RTL เป็น netlist กลาง | `1_1_yosys_canonicalize.rtlil` |
| 1\_2\_yosys | map เป็น standard cell ด้วย ABC ตาม .lib | `1_2_yosys.v` (gate-level netlist), `synth_stat.txt` |
| 1\_synth | OpenROAD อ่าน netlist + SDC ตัด logic ที่ไม่ได้ใช้ แล้วเก็บเป็นฐานข้อมูล | `1_synth.odb`, `1_synth.sdc` |

```bash
ls $R
sed -n '/=== design hierarchy ===/,$p' $P/synth_stat.txt | less     # สรุปทั้งดีไซน์
grep -E "cells$|Chip area for top|sequential" $P/synth_stat.txt | tail -3
cat $P/synth_check.txt | tail -1                                   # ต้องเป็น 0 problems
```

ผลจริงจากการรันสคริปต์ synthesis ของ ORFS (ตุลาคม 2026, Yosys 0.69):

```text
      222 2.31E+03      120 1.62E+03 cells
   Chip area for top module '\gcd': 2313.468800
     of which used for sequential elements: 1020.979200 (44.13%)
Found and reported 0 problems.
```

| อ่านได้ว่า | ทำไมสำคัญ |
| --- | --- |
| 222 cell, 2,313 µm² | คือขนาดตั้งต้น — floorplan จะหารด้วย 0.38 ได้ core ราว 6,100 µm² |
| FF 35 ตัว: `edfxtp_1` 32 + `dfxtp_1` 3 | `edfxtp` คือ FF ที่มี enable ในตัว = register A, B อย่างละ 16 บิต; 3 ตัวที่เหลือคือ state ของ FSM |
| sequential 44% ของพื้นที่ | FF ตัวหนึ่งใหญ่กว่า NAND2 ราว 6–8 เท่า (`edfxtp_1` ≈ 30 µm² เทียบ `nand2_1` ≈ 3.75 µm²) |
| มี module ชื่อ `ALU_..._BRENT_KUNG`, `_SKLANSKY`, `_KOGGE_STONE`, `_HAN_CARLSON` | ผลของ `SWAP_ARITH_OPERATORS=1`: Yosys เตรียมตัวบวก/ลบ 4 สถาปัตยกรรม (พื้นที่ 658–1,002 µm²) ให้ `replace_arith_modules` ในขั้น floorplan เลือกตาม timing — ตัวอย่างจริงของ PPA trade-off |

### 2.2 Floorplan — `make DESIGN_CONFIG=$CFG floorplan`

| ขั้นย่อย | ทำอะไร |
| --- | --- |
| 2\_1\_floorplan | `initialize_floorplan -utilization 38` สร้าง die/core และ row, ต่อ tie cell, `replace_arith_modules` เลือกตัวบวก |
| 2\_2\_floorplan\_macro | วาง macro (gcd ไม่มี ขั้นนี้จึงแทบไม่ทำอะไร) |
| 2\_3\_floorplan\_tapcell | ใส่ tap cell `tapvpwrvgnd_1` เป็นระยะตามกฎ PDK |
| 2\_4\_floorplan\_pdn | สร้าง power grid ตาม `platforms/sky130hd/pdn.tcl` |

ตรวจ: `$P/2_floorplan_final.rpt` (timing หลัง floorplan) และใน `$L/2_1_floorplan.log` หาบรรทัด `Design area ... utilization` — utilization ต้องใกล้ 38% ตามที่ตั้ง

### 2.3 Placement — `make DESIGN_CONFIG=$CFG place`

| ขั้นย่อย | ทำอะไร |
| --- | --- |
| 3\_1\_place\_gp\_skip\_io | global placement รอบแรกโดยไม่สนใจ I/O |
| 3\_2\_place\_iop | วาง I/O pin รอบขอบ die ให้ใกล้ cell ที่ใช้ |
| 3\_3\_place\_gp | global placement จริง (timing-driven) |
| 3\_4\_place\_resized | repair\_design: แก้ slew/cap/fanout ด้วย buffer และปรับขนาด cell |
| 3\_5\_place\_dp | detailed placement จัด cell ลง site ให้ legal |

ตรวจ: `$P/3_detailed_place.rpt` — slack หลัง placement และ violation ของ slew/cap/fanout ประกอบกับบรรทัด `report_design_area` ใน `$L/3_5_place_dp.log` (cell เพิ่มจาก synth เพราะ buffer และ tap cell)

### 2.4 CTS — `make DESIGN_CONFIG=$CFG cts`

สร้าง clock tree ด้วย TritonCTS → เปลี่ยน STA เป็น propagated clock → `repair_timing` แก้ setup และ hold (ใส่ hold buffer) ตรวจ 2 ไฟล์เทียบกัน:

```bash
grep -A3 "report_clock_skew" $P/4_cts_final.rpt
grep -iE "worst slack|tns" $P/4_cts_final.rpt
grep -iE "hold|buffer" $L/4_1_cts.log | tail -15        # จำนวน buffer ที่ใส่เพิ่ม
```

ใน `4_cts_final.rpt` มีหัวข้อ `cts final report_clock_skew` — ค่านี้เพิ่งมีความหมายหลัง CTS เพราะก่อนหน้านี้ clock เป็น ideal

### 2.5 Routing — `make DESIGN_CONFIG=$CFG route`

| ขั้นย่อย | ทำอะไร | ตรวจ |
| --- | --- | --- |
| 5\_1\_grt | global route + แก้ timing ด้วย parasitics จากเส้นทางคร่าว ๆ | `$P/congestion.rpt` (ควรว่าง), antenna ใน `$P/grt_antennas.log` |
| 5\_2\_route | detailed route ด้วย TritonRoute วนหลายรอบจน DRC ลดเหลือ 0 | `$P/5_route_drc.rpt` (ต้องว่าง), บรรทัด `Number of violations` ใน `$L/5_2_route.log` |
| 5\_3\_fillcell | เติม filler cell ให้ row ต่อเนื่อง | — |

```bash
grep -n "Number of violations" $L/5_2_route.log | tail -5     # ลดลงทุกรอบจนเป็น 0
```

### 2.6 Finish — `make DESIGN_CONFIG=$CFG finish`

เติม metal fill → ดึง parasitics จริง (เขียน `6_final.spef`) → STA รอบสุดท้าย → รวม layout ของทุก cell ด้วย KLayout เป็น `6_final.gds`

```bash
ls -la $R/6_final.*          # .gds .def .v .spef .sdc .odb
less $P/6_finish.rpt          # tns, wns, worst slack, skew, power, design area
make DESIGN_CONFIG=$CFG elapsed   # ตารางเวลาและหน่วยความจำที่แต่ละขั้นใช้
```

รันทั้งหมดในคำสั่งเดียวได้ด้วย `make DESIGN_CONFIG=$CFG` (target เริ่มต้นคือ `all` = ตรวจ yosys/openroad แล้ว synth → finish) แต่ใน Lab ให้รันทีละขั้นตามนี้

**เกณฑ์อ้างอิงสำหรับผู้สอน** — ORFS เคยเก็บเกณฑ์ CI ของ gcd/sky130hd ไว้ใน `rules-base.json` (เวอร์ชัน v3.0) ค่าเหล่านี้คือ**ขอบเขตที่ยอมรับ** (ค่าจริงควรดีกว่าหรือใกล้เคียง) ใช้เช็กว่าผลของผู้เรียนอยู่ในช่วงปกติ:

| metric | เกณฑ์ CI (v3.0) |
| --- | --- |
| synth stdcell area | ≤ 2,725 µm² (ผลจริงเวอร์ชันปัจจุบัน 2,313) |
| clock ที่นิยาม | = 1 |
| หลัง place: area / จำนวน cell | ≤ 3,032 µm² / ≤ 454 |
| detailed place violations | = 0 |
| CTS: setup buffer / hold buffer ที่ใส่ | ≤ 40 / ≤ 40 |
| detailed route wirelength | ≤ 6,849 µm |
| detailed route DRC errors | = 0 |
| finish setup worst slack | ≥ −0.05 ns |
| finish design area | ≤ 3,685 µm² |

✅ **Checkpoint 2:** ได้ `6_final.gds` และ `6_finish.rpt`, ตอบได้ว่าแต่ละขั้นสร้างไฟล์อะไร และ DRC หลัง route = 0

## ขั้นที่ 3 — เปิดดูแต่ละขั้นใน GUI (25 นาที)

ORFS มี target `gui_<ขั้น>` ที่เปิด `.odb` ของขั้นนั้นใน OpenROAD GUI พร้อม .lib และ SDC (จึงดู timing ได้ด้วย): `gui_synth`, `gui_floorplan`, `gui_place`, `gui_cts`, `gui_grt`, `gui_route`, `gui_final` — บนเครื่องที่ไม่มีจอใช้ `open_<ขั้น>` จะได้ Tcl prompt แทน (สั่ง `report_*` ได้เหมือนกัน)

**ส่วนของหน้าต่างที่ใช้บ่อย:** Display Control (ซ้าย — เปิด/ปิด layer, instance, net และ Heat Maps), Inspector (ขวา — คุณสมบัติของสิ่งที่คลิก), Timing Report, Tcl console (ล่าง) เมนูและตำแหน่งอาจต่างตามเวอร์ชัน

### 3.1 Floorplan — `make DESIGN_CONFIG=$CFG gui_floorplan`

- [ ] ชี้ die boundary กับ core boundary และวัดระยะขอบด้วย ruler (กด `k`)
- [ ] ซูมดู row ของ standard cell และ tap cell ที่เรียงเป็นแนวตั้ง
- [ ] ปิดทุก layer แล้วเปิดทีละชั้นดู power grid: rail บน met1 ตาม row และ stripe บนชั้นบน (เทียบกับคำอธิบาย PDN ใน 5.5)
- [ ] หา I/O pin รอบขอบ die (ตำแหน่งจะถูกจัดใหม่ในขั้น place)

### 3.2 Placement — `make DESIGN_CONFIG=$CFG gui_place`

- [ ] Display Control → Heat Maps → **Placement Density** ดูว่า cell กระจุกตรงไหน (เทียบกับ `PLACE_DENSITY = 0.60` ของ platform)
- [ ] เปิด **Routing Congestion** (คำนวณจากการประมาณเส้นทาง) — gcd เล็กจึงควรเกือบไม่มีจุดร้อน
- [ ] กด Find (Ctrl+F) หา instance ชื่อมี `dpath` หรือ register แล้วดู master ใน Inspector เช่น `sky130_fd_sc_hd__edfxtp_1`

### 3.3 CTS — `make DESIGN_CONFIG=$CFG gui_cts`

- [ ] เปิด Clock Tree Viewer (เมนู Windows) เลือก `core_clock` — แกนตั้งคือเวลาที่ clock ไปถึง FF แต่ละตัว ความต่างระหว่างตัวบนสุดกับล่างสุดคือ skew
- [ ] คลิก buffer ใน tree ดูชื่อ master (ควรเป็นตระกูล `clkbuf_*`)
- [ ] พิมพ์ใน Tcl console:

```tcl
report_clock_skew
report_worst_slack -max
report_worst_slack -min
```

### 3.4 Final — `make DESIGN_CONFIG=$CFG gui_final`

- [ ] เปิดทีละ layer li1, met1 … met5 — สังเกตทิศสายที่สลับแนวนอน/แนวตั้งตามชั้น
- [ ] เปิด Timing Report → Update เลือก path แย่สุด จะเห็น cell บน path ถูกเน้นบน layout — path เริ่มที่ register ตัวไหน ผ่านตัวลบ/ตัวเปรียบเทียบหรือไม่
- [ ] ซูมหา filler cell (`fill_*`) และ decap ที่เติมช่องว่างใน row

### 3.5 GDS ใน KLayout

```bash
klayout -l platforms/sky130hd/sky130hd.lyp $R/6_final.gds &
```

`-l` โหลด layer properties ของ sky130 ให้เห็นชื่อและสีของแต่ละชั้น — ต่างจาก OpenROAD GUI ตรงที่ GDS มี**รูปทรงภายใน cell** ครบ (diffusion, poly, contact) เพราะขั้น finish เอา layout จริงจาก `platforms/sky130hd/gds/` มารวม ส่วน OpenROAD เห็น cell เป็นกล่องตาม LEF

- [ ] ซูมเข้า cell `nand2_1` หนึ่งตัว ชี้ poly (gate) กับ diffusion ของทรานซิสเตอร์
- [ ] เทียบขนาดชิปทั้งหมด (เมนู Display → Full Hierarchy แล้ววัดด้วย ruler) กับขนาด die ที่คำนวณจาก utilization

**ภาพหน้าจอที่ต้องเก็บ (ตั้งชื่อตามนี้):** `s1_floorplan_pdn.png`, `s2_place_density.png`, `s3_cts_tree.png`, `s4_final_layers.png`, `s5_worst_path.png`, `s6_klayout_cell.png`

✅ **Checkpoint 3:** ภาพครบ 6 ภาพ และในแต่ละภาพชี้สิ่งที่ checklist ถามได้ (วงหรือใส่ลูกศรบนภาพ)

## ขั้นที่ 4 — เก็บตัวเลขจากรายงาน (20 นาที)

มี 2 วิธี ให้ทำทั้งสองแล้วเทียบกัน — วิธี A สอนให้อ่านรายงานดิบเป็น วิธี B คือสิ่งที่ใช้จริงเมื่อต้องเทียบหลายรอบ (เช่นขั้นที่ 5)

### วิธี A — อ่านรายงานแต่ละขั้น

รายงาน timing ของทุกขั้นสร้างจากสคริปต์เดียวกัน (`report_metrics`) จึงมีหัวข้อเหมือนกัน: `report_tns`, `report_wns`, `report_worst_slack`, `report_clock_skew` (หลัง CTS), `report_check_types` (slew/cap/fanout), `report_power` และ `report_design_area`

| ไฟล์ใน `$P` | ขั้น |
| --- | --- |
| `synth_stat.txt` | synth |
| `2_floorplan_final.rpt` | floorplan |
| `3_detailed_place.rpt` | place |
| `4_cts_final.rpt` | cts |
| `5_global_route*.rpt`, `5_route_drc.rpt` | route |
| `6_finish.rpt` | finish |

```bash
grep -A2 "report_worst_slack" $P/*.rpt                  # worst slack ทุกขั้นในคำสั่งเดียว
grep -A6 "report_power" $P/6_finish.rpt                 # internal / switching / leakage / total
grep -h "Design area" $L/*.log                          # area + utilization ต่อขั้น
```

### วิธี B — metadata.json

```bash
make DESIGN_CONFIG=$CFG metadata-generate                # สร้าง $P/metadata.json
jq 'keys | length' $P/metadata.json                      # มี metric กี่ตัว
jq -r 'to_entries[] | select(.key | test("timing__setup__ws")) | "\(.key) = \(.value)"' $P/metadata.json
```

ชื่อ metric ใช้รูปแบบ `<ขั้น>__<หมวด>__<ชื่อ>` เช่น `cts__timing__setup__ws`, `finish__timing__hold__ws`, `detailedroute__route__drc_errors`, `finish__design__instance__area`, `synth__design__instance__area__stdcell`, `placeopt__design__instance__count__stdcell` — หา metric ที่เหลือด้วย regex แทนการจำชื่อ (ชื่ออาจต่างตามเวอร์ชัน):

```bash
jq -r 'to_entries[] | select(.key | test("skew|power__total|utilization|count__stdcell"))
       | "\(.key) = \(.value)"' $P/metadata.json
```

### ตารางที่ต้องกรอก

| ตัวชี้วัด | หลัง synth | หลัง place | หลัง CTS | หลัง route / finish |
| --- | --- | --- | --- | --- |
| Cell count |  |  |  |  |
| Design area (µm²) / utilization |  |  |  |  |
| WNS setup (ns) |  |  |  |  |
| WNS hold (ns) | — |  |  |  |
| Clock skew (ns) | — | — |  |  |
| DRC violations | — | — | — |  |
| Total power (mW) | — | — | — |  |

**การอ่านค่าให้ถูก**

- slack บวก = ผ่านและยังมีเวลาเหลือ, ลบ = violation; WNS คือ slack ที่แย่สุด TNS คือผลรวม slack ติดลบ (TNS = 0 แปลว่าไม่มี violation เลย)
- ค่า hold ก่อน CTS คำนวณด้วย ideal clock จึงเชื่อถือไม่ได้ (ช่องในตารางจึงเป็น — หรือให้จดไว้เปรียบเทียบ)
- cell count หลัง place มากกว่าหลัง synth เพราะมี tap cell, tie cell และ buffer จาก repair\_design; หลัง finish มี filler เพิ่มอีก — ให้ระบุในตารางว่านับ filler ด้วยหรือไม่
- power ในรายงานเป็นหน่วยวัตต์ (เช่น `1.23e-03` = 1.23 mW) คำนวณที่ activity ค่าเริ่มต้น ไม่ใช่ activity จริงจาก simulation (Module 07 จะใช้ VCD)

✅ **Checkpoint 4:** ตารางครบทุกช่องที่ไม่ใช่ — พร้อมระบุไฟล์ที่มาของแต่ละค่า และตัวเลขอยู่ในช่วงเกณฑ์อ้างอิงในขั้นที่ 2

## ขั้นที่ 5 — ทดลองเปลี่ยนพารามิเตอร์ (25 นาที)

ใช้ `FLOW_VARIANT` แทนการคัดลอกโฟลเดอร์ design — ORFS จะเก็บผลแต่ละการทดลองแยกไว้ใน `results/sky130hd/gcd/<variant>/` โดยไม่ทับ `base` และตัวแปรที่ส่งทาง command line (เช่น `CORE_UTILIZATION=30`) จะชนะค่าใน `config.mk`

| การทดลอง | variant | เปลี่ยน |
| --- | --- | --- |
| A1 | `util30` | `CORE_UTILIZATION=30` |
| A2 | `util70` | `CORE_UTILIZATION=70` (+ `PLACE_DENSITY=0.80` ดูหมายเหตุ) |
| B | `clk0p55` | clock period 0.55 ns (ครึ่งหนึ่ง) |
| C | `clk2p2` | clock period 2.2 ns (2 เท่า) |

```bash
# A — utilization
make DESIGN_CONFIG=$CFG FLOW_VARIANT=util30 CORE_UTILIZATION=30
make DESIGN_CONFIG=$CFG FLOW_VARIANT=util70 CORE_UTILIZATION=70 PLACE_DENSITY=0.80

# B, C — clock period: สร้าง SDC ใหม่แล้วชี้ด้วย SDC_FILE
D=designs/sky130hd/gcd
sed 's/set clk_period 1.1/set clk_period 0.55/' $D/constraint.sdc > $D/constraint_0p55.sdc
sed 's/set clk_period 1.1/set clk_period 2.2/'  $D/constraint.sdc > $D/constraint_2p2.sdc
make DESIGN_CONFIG=$CFG FLOW_VARIANT=clk0p55 SDC_FILE=./$D/constraint_0p55.sdc
make DESIGN_CONFIG=$CFG FLOW_VARIANT=clk2p2  SDC_FILE=./$D/constraint_2p2.sdc
```

แต่ละคำสั่งรัน flow ครบทุกขั้น เปิด terminal หลายหน้าต่างรันพร้อมกันได้ถ้าเครื่องมี core พอ หรือแบ่งกลุ่มให้คนละการทดลองแล้วแชร์ผล

> **หมายเหตุ A2:** ถ้าตั้ง utilization 70% แต่ปล่อย `PLACE_DENSITY` เป็นค่า platform (0.60) global placement จะหยุดด้วย error เรื่อง density เพราะสั่งให้กระจาย cell บางกว่าที่พื้นที่มีอยู่จริงไม่ได้ — ให้ผู้เรียนลองรันแบบไม่ใส่ `PLACE_DENSITY` ก่อน อ่าน error ใน `logs/sky130hd/gcd/util70/3_*.log` แล้วค่อยแก้ เป็นแบบฝึกอ่าน log ที่ดี (ล้างผลเก่าของ variant นั้นก่อนรันใหม่ด้วย `make DESIGN_CONFIG=$CFG FLOW_VARIANT=util70 clean_all`)

### รวบรวมผลเป็นตารางเดียว

```bash
for v in base util30 util70 clk0p55 clk2p2; do
  make DESIGN_CONFIG=$CFG FLOW_VARIANT=$v metadata-generate > /dev/null
done
printf "%-8s %10s %8s %8s %10s\n" variant area setup_ws drc wirelen
for v in base util30 util70 clk0p55 clk2p2; do
  f=reports/sky130hd/gcd/$v/metadata.json
  printf "%-8s %10s %8s %8s %10s\n" $v \
    "$(jq '.finish__design__instance__area' $f)" \
    "$(jq '.finish__timing__setup__ws' $f)" \
    "$(jq '.detailedroute__route__drc_errors' $f)" \
    "$(jq '.detailedroute__route__wirelength' $f)"
done
```

เพิ่มคอลัมน์ power และ die area เองโดยหาชื่อ metric ด้วย `jq` ตามขั้นที่ 4

### สิ่งที่ควรเห็นและคำอธิบาย

| การทดลอง | คาดการณ์ | เหตุผล |
| --- | --- | --- |
| A1 util 30% | die ใหญ่ขึ้น, wirelength ยาวขึ้นเล็กน้อย, cell area แทบเท่าเดิม | พื้นที่ว่างมาก cell กระจายห่างกัน แต่เสีย silicon เปล่า |
| A2 util 70% | die เล็กลงราวครึ่งหนึ่ง, congestion สูงขึ้น, อาจต้องใช้รอบ detailed route มากขึ้นกว่าจะ DRC = 0 | เหลือที่ให้ buffer และสายน้อย (ดูจำนวนรอบใน `5_2_route.log`) |
| B period 0.55 ns | setup WNS ติดลบชัดเจน, area เพิ่ม (cell ใหญ่ขึ้นและ buffer มากขึ้น), runtime นานขึ้น | repair\_timing พยายามแก้ทุก endpoint (`TNS_END_PERCENT=100`) แต่เกินขีดความสามารถของ cell ที่ 130 nm — flow ยังจบได้แต่ timing ไม่ผ่าน |
| C period 2.2 ns | WNS บวกมาก, area ลดเล็กน้อย, power ลดลงใกล้ครึ่งหนึ่ง | dynamic power ∝ f และไม่ต้อง upsize/ใส่ buffer เพื่อเร่ง timing (leakage ไม่ลดตาม f) |

คำเตือน: ตารางนี้คือ**แนวโน้ม**ที่คาด ตัวเลขจริงขึ้นกับเวอร์ชันของ ORFS/OpenROAD และ seed ของ placement — ถ้าผลไม่ตรงแนวโน้ม ให้อธิบายจาก log ว่าเกิดอะไรขึ้น (คะแนนอยู่ที่เหตุผล ไม่ใช่ตัวเลขตรงเฉลย)

✅ **Checkpoint 5:** ตารางเปรียบเทียบ 5 variant พร้อมคำอธิบาย 1–2 บรรทัดต่อการทดลอง และภาพ density map ของ util30 เทียบ util70

## แก้ปัญหา, คำถามท้าย Lab และการประเมิน

**ตารางแก้ปัญหาที่พบบ่อยใน Lab 5**

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| `make: *** No rule to make target` หรือ `config.mk: No such file` | ไม่ได้อยู่ในโฟลเดอร์ `flow` หรือพิมพ์ path ผิด | `cd OpenROAD-flow-scripts/flow` แล้ว `ls $CFG` |
| `check-yosys` / `check-openroad` ฟ้องหาโปรแกรมไม่พบ | ยังไม่ได้ `source env.sh` (Docker) หรือ export `YOSYS_EXE`/`OPENROAD_EXE` | ทำตาม 5.0 แล้วเช็กด้วย `echo $OPENROAD_EXE` |
| ไฟล์ใน `results/` เป็นของ root ลบไม่ได้ | รัน Docker โดยไม่ใส่ `-u $(id -u):$(id -g)` | ใส่ `-u` ตาม 5.0 หรือใช้ `util/docker_shell` |
| `gui_*` เปิดหน้าต่างไม่ขึ้น (`could not connect to display`) | container ไม่เห็น X11 | ส่ง `DISPLAY` และ `/tmp/.X11-unix` ตาม 5.0 หรือใช้ `open_<ขั้น>` + คำสั่ง report แทน |
| flow หยุดกลางทาง | error ในขั้นนั้น | เปิด log ล่าสุด `ls -t $L \| head -1` แล้ว `grep -n ERROR` — อ่านจาก ERROR ตัวแรก |
| global placement หยุดด้วย error เรื่อง density | `PLACE_DENSITY` ต่ำกว่า utilization ที่ตั้ง | เพิ่ม `PLACE_DENSITY` หรือลด `CORE_UTILIZATION` |
| แก้ SDC แล้วผลไม่เปลี่ยน | make เห็นว่าไฟล์ผลลัพธ์เดิมยังใหม่กว่า หรือแก้ผิดไฟล์ | ใช้ `FLOW_VARIANT` ใหม่ หรือ `clean_all` ก่อน แล้วดู `$R/1_2_yosys.sdc` ว่า period เปลี่ยนจริง |
| `metadata-generate` ฟ้องหาไฟล์ไม่พบ | ยังรันไม่ถึง finish | รันให้ครบก่อน หรืออ่านรายงานแต่ละขั้นตามวิธี A |
| ตัวเลขต่างจากเพื่อน | เวอร์ชัน ORFS/OpenROAD/Yosys ต่างกัน | จดเวอร์ชันไว้ในรายงาน (`metadata.json` มี `run__flow__openroad_version` และ `run__flow__scripts_commit`) |
| เครื่องช้ามาก / หน่วยความจำไม่พอ | Docker Desktop จำกัด CPU/RAM ไว้ | ตั้ง resource ใน Docker Desktop และอย่ารันหลาย variant พร้อมกัน |

**คำถามท้าย Lab**

1. ทำไม WNS hold จึงเปลี่ยนมากที่สุดหลังขั้น CTS และเครื่องมือแก้อย่างไร (ดูจาก `4_1_cts.log`)
2. ไฟล์ไหนใน `results/` ที่ต้องใช้ทำ gate-level simulation ใน ModelSim และต้องใช้ไฟล์จาก PDK อะไรเพิ่ม และ flow นี้ยังขาดอะไรสำหรับ sim พร้อม delay จริง
3. จากการทดลอง A ถ้าต้องเลือก utilization สำหรับงานจริง จะเลือกเท่าไร เพราะอะไร
4. ชี้ตำแหน่ง tap cell, filler cell และ clock buffer ในภาพ layout และอธิบายหน้าที่ของแต่ละตัว
5. ทำไม synth\_stat.txt มีตัวบวก 4 สถาปัตยกรรม แต่ชิปจริงใช้แค่ตัวเดียว — สถาปัตยกรรมที่เล็กสุดกับใหญ่สุดต่างกันกี่เท่า และทำไมไม่เลือกตัวเล็กสุดเสมอ
6. SDC ของ gcd ไม่มี `set_clock_uncertainty` — ถ้าเพิ่ม `set_clock_uncertainty -setup 0.1` จะเกิดอะไรกับ WNS และทำไมงานจริงต้องมี

**เฉลยสำหรับผู้สอน**

| ข้อ | แนวคำตอบ |
| --- | --- |
| 1 | ก่อน CTS clock เป็น ideal (ถึงทุก FF พร้อมกัน, skew = 0) หลัง CTS STA ใช้ propagated clock ที่มี skew จริง — path สั้นที่ clock ฝั่งรับมาช้ากว่าจะละเมิด hold เครื่องมือแก้ด้วย `repair_timing` ที่แทรก delay/hold buffer บน path นั้น (จำนวน buffer ดูได้ใน log และเกณฑ์ CI จำกัดไว้ ≤ 40) |
| 2 | `6_final.v` (netlist หลัง P&R) + Verilog model ของ standard cell จาก PDK (sky130\_fd\_sc\_hd) + testbench — ส่วน delay จริงต้องมีไฟล์ SDF ซึ่ง flow นี้ไม่ได้เขียนออกมา ต้องสร้างเองจาก OpenSTA (อ่าน `6_final.spef` แล้ว `write_sdf`) — ทำจริงใน Module 08 |
| 3 | คำตอบที่ดีอยู่ราว 50–60% พร้อมหลักฐานจากตาราง: ต่ำเกินเสียพื้นที่และสายยาวขึ้น, สูงเกินเสี่ยง congestion/DRC และไม่เหลืที่ให้ ECO — ดีไซน์ที่มี macro หรือสายหนาแน่นควรต่ำกว่านี้ |
| 4 | tap cell (`tapvpwrvgnd_1`) เรียงเป็นแนวตั้งเป็นระยะ ต่อ well/substrate เข้าไฟเลี้ยงกัน latch-up; filler (`fill_*`) อุดช่องว่างให้ well และ rail ต่อเนื่อง; clock buffer (`clkbuf_*`) กระจายใกล้กลุ่ม FF เป็นต้นไม้จากพอร์ต clk |
| 5 | จาก synth\_stat: Brent-Kung 658 µm², Kogge-Stone 1,002 µm² → ต่างกัน \~1.5 เท่า ตัวเล็กมักช้ากว่า (logic ลึกกว่า) — สถาปัตยกรรมที่ดีที่สุดขึ้นกับว่าตัวบวกอยู่บน critical path หรือไม่ จึงเลือกหลังรู้ timing ใน floorplan = PPA trade-off |
| 6 | uncertainty หักเวลาออกจาก period ทุก path → WNS แย่ลง 0.1 ns (และ flow อาจใส่ buffer/upsize มากขึ้น) — งานจริงต้องมีเพราะ clock จริงมี jitter และก่อน CTS ยังไม่รู้ skew ถ้าไม่เผื่อ ชิปที่ผ่าน STA พอดีอาจพังจริง (ดู 5.3) |

**งานที่ต้องส่ง**

1. เวอร์ชันเครื่องมือ (`yosys -V`, `openroad -version`) และคำตอบขั้นที่ 1
2. ตารางขั้นที่ 4 พร้อมระบุไฟล์ที่มาของแต่ละค่า และ `reports/sky130hd/gcd/base/metadata.json`
3. ภาพหน้าจอ 6 ภาพตามขั้นที่ 3 (มีคำอธิบายใต้ภาพ)
4. ตารางเปรียบเทียบ 5 variant ของขั้นที่ 5 พร้อมคำอธิบาย และข้อความ error จาก A2 ก่อนแก้
5. คำตอบคำถาม 6 ข้อ

**เกณฑ์ให้คะแนน Lab 5 (100 คะแนน)**

| หัวข้อ | คะแนน | เต็ม | บางส่วน |
| --- | --- | --- | --- |
| สภาพแวดล้อม + อ่าน config/SDC (ขั้นที่ 1) | 10 | ตอบครบพร้อมคำนวณ MHz และ I/O delay | ตอบไม่ครบ |
| รัน flow ครบ + อธิบายไฟล์แต่ละขั้น (ขั้นที่ 2) | 20 | ได้ GDS, DRC = 0, อธิบาย synth stat ได้ | ใช้ผลของผู้สอนแทน |
| ภาพ GUI 6 ภาพ (ขั้นที่ 3) | 20 | ชี้สิ่งที่ถามได้ถูกทุกภาพ | ภาพไม่มีคำอธิบาย |
| ตารางตัวเลข (ขั้นที่ 4) | 20 | ครบ, ระบุแหล่งที่มา, อยู่ในช่วงเกณฑ์อ้างอิง | ค่าผิดหน่วยหรือไม่ระบุแหล่ง |
| การทดลอง (ขั้นที่ 5) | 15 | 5 variant + อธิบายด้วยหลักฐานจาก log | มีตัวเลขแต่ไม่อธิบาย |
| คำตอบ 6 ข้อ | 15 | ถูกต้องและอ้างอิงผลของตัวเอง | ตอบจากทฤษฎีอย่างเดียว |

**หมายเหตุสำหรับผู้สอน:** Lab นี้เสี่ยงที่สุดตรงการติดตั้ง — ให้ผู้เรียนทำ 5.0 เป็นการบ้านก่อนคาบอย่างน้อย 1 สัปดาห์ และเตรียมผลรันสำรองตามคำแนะนำใน 5.0 เมื่อรันครบบนเครื่องผู้สอนแล้วให้เติมค่าจริงลงตารางขั้นที่ 4 ในสำเนาเฉลยของตัวเอง

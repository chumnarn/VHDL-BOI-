# Lab 5: Step-by-Step Guide — Mini Project: GLS + Debug + Final Report

> **เวลาใช้งาน:** 2.5-3 ชั่วโมง
> **เครื่องมือ:** Questa Advanced Simulator + Precision RTL + ModelSim (Siemens EDA)
> **Output ที่คาดหวัง:** GLS ที่ผ่าน multi-corner, final verification report พร้อม sign-off

---

## Step 0: เตรียมโปรเจกต์ Mini Project

### 0.1 โครงสร้าง Directory

```powershell
mkdir E:\lab\VHDL(BOI)\mini_project
mkdir E:\lab\VHDL(BOI)\mini_project\rtl
mkdir E:\lab\VHDL(BOI)\mini_project\tb
mkdir E:\lab\VHDL(BOI)\mini_project\constraints
mkdir E:\lab\VHDL(BOI)\mini_project\scripts
mkdir E:\lab\VHDL(BOI)\mini_project\reports
mkdir E:\lab\VHDL(BOI)\mini_project\netlist
mkdir E:\lab\VHDL(BOI)\mini_project\docs
```

### 0.2 ไฟล์ที่ต้องมี (จาก Day 1-4 + Lab 1-4)

| File | Source | Purpose |
|------|--------|---------|
| `rtl/uart_tx_all.vhd` | Lab 1-3 | DUT ที่ verified แล้ว |
| `tb/tb_uart_tx.vhd` | Lab 1-4 | Self-checking TB |
| `constraints/uart_tx.sdc` | Lab 3 | SDC constraints |
| `scripts/synth.tcl` | Lab 3 | Precision RTL script |

### 0.3 Copy จาก Lab ก่อนหน้า (ถ้ามี)

```powershell
# ถ้ามี lab ก่อนหน้า สามารถ copy
Copy-Item E:\lab\VHDL(BOI)\lab5_work\rtl\uart_tx_all.vhd E:\lab\VHDL(BOI)\mini_project\rtl\
Copy-Item E:\lab\VHDL(BOI)\lab5_work\tb\tb_uart_tx.vhd E:\lab\VHDL(BOI)\mini_project\tb\
Copy-Item E:\lab\VHDL(BOI)\lab5_work\constraints\uart_tx.sdc E:\lab\VHDL(BOI)\mini_project\constraints\
Copy-Item E:\lab\VHDL(BOI)\lab5_work\scripts\synth.tcl E:\lab\VHDL(BOI)\mini_project\scripts\
```

---

## Step 1: Verify RTL Design ก่อน Synthesis

### 1.1 เปิด Questa และ Compile

```powershell
cd E:\lab\VHDL(BOI)\mini_project
vlib work
vcom -2008 rtl\uart_tx_all.vhd
vcom -2008 tb\tb_uart_tx.vhd
```

### 1.2 Run RTL Simulation

```tcl
# In do-file or interactively
vsim work.tb_uart_tx
add wave *
run 10 ms
```

### 1.3 ตรวจสอบผล

**ผลที่คาดหวัง:**
```
# ** Note: PASS: 9
# ** Note: FAIL: 0
# ** Note: ALL TESTS PASSED
# Errors: 0
```

### 1.4 ตรวจ Coverage

```tcl
# Save RTL coverage
coverage save -onexit rtl_cov.ucdb
vcover report -details -output rtl_report.html rtl_cov.ucdb
```

**ผลที่คาด:**
- Statement coverage: ≥ 95%
- Branch coverage: ≥ 90%
- Functional coverage: 100% (critical)

---

## Step 2: Generate Netlist + SDF ด้วย Precision RTL

### 2.1 เตรียม SDC (ถ้ายังไม่มี)

ไฟล์ `constraints/uart_tx.sdc`:

```tcl
# Clock
create_clock -name sys_clk -period 10.0 -waveform {0 5} [get_ports clk]

# Input delays
set_input_delay  -clock sys_clk 2.0 -max [get_ports {din din_vld baud_sel rst_n}]
set_input_delay  -clock sys_clk 1.0 -min [get_ports {din din_vld baud_sel rst_n}]

# Output delays
set_output_delay -clock sys_clk 2.0 -max [get_ports {tx tx_done din_rdy}]
set_output_delay -clock sys_clk 1.0 -min [get_ports {tx tx_done din_rdy}]

# Reset synchronous
set_false_path -from [get_ports rst_n]

# Drive / load
set_driving_cell -lib_cell INVX1 -pin Y [get_ports {din din_vld baud_sel rst_n}]
set_load 0.05 [get_ports {tx tx_done din_rdy}]

# Operating conditions
set_operating_conditions -process typical -voltage 1.0 -temp 25
```

### 2.2 เตรียม Precision RTL Script

ไฟล์ `scripts/synth.tcl`:

```tcl
set tech_lib "/path/to/gscl45nm"
set design_name "uart_tx_all"

# Create project
if { [file exists work_$design_name] } {
    file delete -force work_$design_name
}
new_project -name $design_name -folder work_$design_name \
            -technology "$tech_lib"

# Add sources
add_source -type vhdl -work work rtl/uart_tx_all.vhd

# Constraints
add_constraint_file constraints/uart_tx.sdc

# Set top
set_top_module uart_tx_all

# Elaborate + Compile
elaborate
compile -incremental_mapping -retiming

# Reports
file mkdir reports
report_constraints -file reports/constraints.rpt
report_area -file reports/area.rpt
report_timing -delay max -num_paths 50 -file reports/timing_max.rpt
report_timing -delay min -num_paths 50 -file reports/timing_min.rpt
report_power -file reports/power.rpt

# Export
file mkdir netlist
export_netlist -format verilog -output netlist/uart_tx_netlist.v
write_sdf -output netlist/uart_tx.sdf

exit
```

### 2.3 Run Synthesis

```powershell
cd E:\lab\VHDL(BOI)\mini_project
precision -shell -file scripts/synth.tcl
```

### 2.4 ตรวจสอบ Output

```powershell
# ตรวจ netlist
type netlist\uart_tx_netlist.v | more

# ตรวจ SDF
type netlist\uart_tx.sdf | more

# ดู reports
type reports\area.rpt
type reports\timing_max.rpt
```

### 2.5 ดู Reports แบบอ่านง่าย

```bash
# Area report
get-content reports/area.rpt | Select-String -Pattern "Total" 

# Timing report
get-content reports/timing_max.rpt | Select-String -Pattern "Slack" 
```

---

## Step 3: Compile Netlist ใน Questa

### 3.1 สร้าง Working Libraries

```bash
cd E:\lab\VHDL(BOI)\mini_project

# Cell library (vendor-specific)
vlib tech_lib
# (ถ้ามี) vlog -work tech_lib /path/to/cell_lib_45nm.v

# Gate-level working library
vlib work_gate
```

### 3.2 Compile Netlist

```bash
# Compile synthesized netlist (Verilog)
vlog -work work_gate netlist/uart_tx_netlist.v
```

### 3.3 Compile Testbench

```bash
vcom -2008 -work work_gate tb/tb_uart_tx.vhd
```

### 3.4 ตรวจสอบ Compile

**Output ที่คาด:**
```
# Loading package STANDARD
# Loading netlist uart_tx_netlist.v
# Compiling module uart_tx_all
# ...
# **Errors: 0, Warnings: 0**
```

---

## Step 4: GLS with SDF (GUI Mode)

### 4.1 เปิด Questa

### 4.2 Load Simulation with SDF

1. `Simulate → Start Simulation`
2. **แท็บ Design:** เลือก `work_gate.tb_uart_tx`
3. **แท็บ SDF:** กด **Add**
   - SDF File: `netlist/uart_tx.sdf`
   - Region: เว้นว่าง (apply ทั้ง design)
   - Apply to: `/tb_uart_tx/dut`
4. **แท็บ Options:**
   - Resolution: `ps`
5. **OK**

### 4.3 Transcript ที่คาดหวัง

```
# Loading package STANDARD
# Loading SDF sdf file
# ...
# SDF file loaded: netlist/uart_tx.sdf
# ...
# ** Note: PASS: 9
# ** Note: FAIL: 0
# ** Note: ALL TESTS PASSED
```

### 4.4 ดู Waveform

1. คลิกขวา `tb_uart_tx` ใน sim tab
2. **Add to Wave → All Signals**

### 4.5 ดู Internal Signals

1. คลิกขวา `u_dut` (instance ของ DUT) ใน sim tab
2. **Add to Wave → All Signals**
3. ตอนนี้จะเห็น internal signals เช่น:
   - `state` (FSM state)
   - `bit_count`
   - `shift_reg`
   - `baud_count`

### 4.6 Run

พิมมพ์ `run 10 ms` ใน Transcript → Enter

---

## Step 5: GLS with SDF (Batch Mode)

### 5.1 สร้างไฟล์ `run_gls.do`

### 5.2 พิมมพ์ Content

```tcl
# run_gls.do - GLS with SDF for UART TX

# Setup
vlib tech_lib
vlib work_gate

# Compile cell library (one-time)
# vlog -work tech_lib /path/to/cell_lib_45nm.v

# Compile netlist
vlog -work work_gate netlist/uart_tx_netlist.v

# Compile TB
vcom -2008 -work work_gate tb/tb_uart_tx.vhd

# Display
puts ""
puts "========================================"
puts "GLS - UART TX with SDF"
puts "========================================"

# Load SDF and simulate
vsim -t ps -sdf /tb_uart_tx/dut=netlist/uart_tx.sdf work_gate.tb_uart_tx

# Add waves
add wave -position insertpoint sim:/tb_uart_tx/*
add wave -position insertpoint sim:/tb_uart_tx/dut/*

# Run
run 10 ms

# Save coverage
coverage save -onexit gls_cov.ucdb

# Done
quit -f
```

### 5.3 รัน Script

```powershell
cd E:\lab\VHDL(BOI)\mini_project
vsim -do run_gls.do -c
```

### 5.4 ตรวจสอบ Output

**Output ที่คาด:**
```
# ** Note: PASS: 9
# ** Note: FAIL: 0
# ** Note: ALL TESTS PASSED
# Coverage saved
```

---

## Step 6: Debug X-Propagation

### 6.1 ถ้า GLS แสดง X

ถ้าเห็น X ใน waveform หรือ transcript:

```
# ** Warning: X propagation detected
```

**หาจุดที่ X เกิด:**

1. **ดู Waveform:**
   - คลิกขวาที่ signal ที่เป็น X → Add to Wave
   - ดูว่า X เกิดที่ไหน, ตอนไหน

2. **Trace ย้อนกลับ:**
   - ดู FF ที่ output X
   - ตรวจ input ของ FF นั้น
   - ดู previous stage

3. **สาเหตุที่พบบ่อย:**
   - Uninitialized FF (ต้องมี reset)
   - Setup violation (clock period สั้นเกินไป)
   - Async reset de-assert (ต้องมี synchronizer)

### 6.2 ตัวอย่าง: แก้ Uninitialized FF**

**ปัญหา:** FF ที่ไม่มี reset path

**ตรวจสอบ:**
```bash
# ดู netlist
grep -A 3 "DFFRX" netlist/uart_tx_netlist.v
```

**แก้ไข:** เพิ่ม reset ใน RTL:
```vhdl
-- BEFORE: FF without reset
process (clk)
begin
    if rising_edge(clk) then
        count <= count + 1;
    end if;
end process;

-- AFTER: FF with sync reset
process (clk)
begin
    if rising_edge(clk) then
        if rst_n = '0' then
            count <= (others => '0');
        else
            count <= count + 1;
        end if;
    end if;
end process;
```

จากนั้น **re-synthesize** และ **re-run GLS**

---

## Step 7: Debug Setup/Hold Violation

### 7.1 ดู Setup Violation Warning

```
# ** Warning: Setup violation detected
# **         Time: 8.234 ns
# **         Path: FF_A → FF_B
# **         Required setup: 0.150 ns
# **         Actual setup: 0.100 ns
# **         Slack: -0.050 ns
```

### 7.2 วิเคราะห์ Critical Path

ใน Questa transcript:
```tcl
report_timing -delay max -num_paths 5
```

Output จะแสดง:
- Source FF
- Destination FF
- Combinational delay
- Slack

### 7.3 แก้ไข Timing Violation

**Option A: เพิ่ม clock period**

แก้ไข `constraints/uart_tx.sdc`:
```tcl
# BEFORE
create_clock -name sys_clk -period 10.0 ...

# AFTER (relax timing)
create_clock -name sys_clk -period 15.0 ...
```

จากนั้น re-synthesize → re-run GLS

**Option B: Optimize RTL (Pipeline)**

```vhdl
-- BEFORE: long combinational path
process (clk)
begin
    if rising_edge(clk) then
        result <= a + b + c + d;  -- 4-stage adder
    end if;
end process;

-- AFTER: pipelined
process (clk)
begin
    if rising_edge(clk) then
        stage1 <= a + b;
        stage2 <= stage1 + c;
        result <= stage2 + d;  -- 1 stage per cycle
    end if;
end process;
```

**Option C: ใช้ Higher Drive Cell**

ใน Precision RTL:
```tcl
# Set cell preference
set_cell_routing -name high_drive_cells [get_cells ...]
```

---

## Step 8: Multi-corner GLS

### 8.1 Generate SDF สำหรับหลาย Corner

ใน Precision RTL:
```tcl
# Typical corner
report_timing -delay max
write_sdf -output netlist/uart_tx_typ.sdf

# Fast corner (for hold analysis)
report_timing -delay min
write_sdf -output netlist/uart_tx_fast.sdf

# Slow corner (for setup analysis)
report_timing -delay max  ;# worst-case timing
write_sdf -output netlist/uart_tx_slow.sdf
```

### 8.2 Multi-corner Script

สร้าง `run_multicorner.do`:

```tcl
# run_multicorner.do
foreach corner {typ fast slow} {
    puts ""
    puts "========================================"
    puts "Running corner: $corner"
    puts "========================================"

    vlib work_gate_$corner
    vlog -work work_gate_$corner netlist/uart_tx_netlist.v
    vcom -2008 -work work_gate_$corner tb/tb_uart_tx.vhd

    vsim -t ps -sdf /tb_uart_tx/dut=netlist/uart_tx_${corner}.sdf \
         work_gate_$corner.tb_uart_tx

    add wave -position insertpoint sim:/tb_uart_tx/*
    run 10 ms

    coverage save -onexit gls_${corner}.ucdb
    quit -f
}

# Merge coverage
vcover merge gls_merged.ucdb \
                 gls_typ.ucdb \
                 gls_fast.ucdb \
                 gls_slow.ucdb

puts ""
puts "All corners complete. Merged coverage: gls_merged.ucdb"
```

### 8.3 รัน

```bash
cd E:\lab\VHDL(BOI)\mini_project
vsim -do run_multicorner.do -c
```

### 8.4 ตรวจสอบทุก Corner

```
========================================
Running corner: typ
========================================
# PASS: 9

========================================
Running corner: fast
========================================
# PASS: 9

========================================
Running corner: slow
========================================
# PASS: 9
```

---

## Step 9: Generate Coverage Report

### 9.1 View Coverage ใน Questa

```tcl
# Open coverage viewer
vsim -viewcov gls_merged.ucdb

# Or generate HTML
vcover report -details -annotate -output gls_report.html gls_merged.ucdb
```

### 9.2 ดู Coverage สรุป

```tcl
vcover report -totals gls_merged.ucdb
```

Output:
```
Coverage Summary:
  Statement:    96.4%
  Branch:       91.8%
  Condition:    88.2%
  Toggle:       99.5%
  FSM:          100.0%
  Assertion:    100.0%
```

### 9.3 ถ้า Coverage ต่ำกว่าเป้า

ถ้า statement < 95% หรือ branch < 90%:
- ตรวจสอบ code ที่ไม่ถูก execute
- เพิ่ม test cases ที่ target code นั้น
- ตรวจเรื่อง exclusion

---

## Step 10: ตรวจ Glitch

### 10.1 ดู Waveform สำหรับ Glitch

ใน waveform:
1. ขยายส่วน TX line ตอน transition
2. ดูว่ามี pulse แปลก ๆ ที่ไม่ใช่ start/data/stop

**Glitch signs:**
- Pulse เล็ก ๆ ระหว่าง transitions
- Unexpected 1/0 ในช่วงข้อมูล

### 10.2 ตัวอย่าง Glitch ใน GLS

ถ้าเห็น glitch ใน tx line:
```
tx:  ━━━┐
        └──┐
           └─┐  <- glitch
             └───  <- 0 (start bit)
```

**สาเหตุ:**
- Combinational path ไม่ balance
- Glitch จาก FSM transition

**แก้:**
- เพิ่ม delay cell
- ใช้ Moore (registered output)
- เพิ่ม hysteresis

---

## Step 11: Generate Final Report

### 11.1 สร้าง `docs/final_report.md`

### 11.2 ใช้ Template

````markdown
# Mini Project: UART TX - Final Verification Report

**Date:** [Date]
**Designer:** [Name]
**Verifier:** [Name]
**Project:** [Project name]

## 1. Design Specification
[Spec from Mini Project]

## 2. RTL Design
### 2.1 Files
- rtl/uart_tx_all.vhd (~80 lines)
- tb/tb_uart_tx.vhd (self-checking)

### 2.2 Architecture
[Block diagram]

## 3. Verification Results

### 3.1 RTL Simulation
```
[OK]

### 3.2 Test Results
| Test | Status |
|------|--------|
| Reset | [OK] |
| Send 0x55 | [OK] |
| Send 0xAA | [OK] |
| Send 0x00 | [OK] |
| Send 0xFF | [OK] |
| All 256 bytes | [OK] |
| Back-to-back | [OK] |
| Different baud | [OK] |
| Reset during TX | [OK] |

**Total: 9/9 PASS**

### 3.3 Coverage
- **Statement**: [X]%
- **Branch**: [X]%
- **Toggle**: [X]%
- **FSM**: [X]%
- **Functional**: [X]%

## 4. Synthesis Results

### 4.1 Tool: Precision RTL
### 4.2 Area
[Insert area.rpt content]

### 4.3 Timing
- **Max frequency**: [X] MHz
- **Worst slack**: [X] ns (typ corner)

### 4.4 Power
[Insert power.rpt content]

## 5. Gate-Level Simulation

### 5.1 Setup
- Tool: Questa Advanced Simulator
- SDF: typ/fast/slow
- TB: tb_uart_tx.vhd

### 5.2 Results

| Corner | Status |
|--------|--------|
| Typical | [OK] |
| Fast | [OK] |
| Slow | [OK] |

### 5.3 X-Propagation
[None / Found - describe]

### 5.4 Timing Violations
[None / List]

## 7. Sign-off

All checks passed:
- [OK] RTL verification complete
- [OK] Code coverage exceeds thresholds
- [OK] Synthesis successful
- [OK] GLS passes with SDF
- [OK] Multi-corner verified

**Status: READY FOR TAPE-OUT**

## 8. Signatures

| Role | Name | Date |
|------|------|------|
| Designer | ____ | ____ |
| Verifier | ____ | ____ |
| Lead | ____ | ____ |
````

### 11.3 ใส่ Reports

Copy reports ทั้งหมดลง `docs/`:

```bash
# In PowerShell
Copy-Item reports\* docs\docs
Copy-Item netlist\uart_tx_netlist.v docs\
Copy-Item netlist\uart_tx.sdf docs\
```

### 11.4 Final Review

ก่อน submit:
- ✅ All TB pass
- ✅ All coverage goals met
- ✅ All reports generated
- ✅ All artifacts saved

---

## Step 12: Verification Checklist (Final)

### 12.1 RTL Phase

| Item | Status | Notes |
|------|--------|-------|
| Compile errors: 0 | ☐ | |
| TB pass: 9/9 | ☐ | |
| Functional coverage: 100% | ☐ | |
| Code coverage ≥ 95% | ☐ | |
| Branch coverage ≥ 90% | ☐ | |
| All assertions pass | ☐ | |
| No X in RTL output | ☐ | |

### 12.2 Synthesis Phase

| Item | Status | Notes |
|------|--------|-------|
| Compile errors: 0 | ☐ | |
| Netlist generated | ☐ | |
| SDF generated | ☐ | |
| Timing report OK | ☐ | |
| Area within budget | ☐ | |
| No latches | ☐ | |

### 12.3 GLS Phase

| Item | Status | Notes |
|------|--------|-------|
| TB passes against netlist | ☐ | |
| SDF loaded successfully | ☐ | |
| No X-propagation | ☐ | |
| No timing violations | ☐ | |
| Multi-corner verified | ☐ | |
| Coverage maintained | ☐ | |

### 12.4 Documentation

| Item | Status |
|------|--------|
| RTL code documented | ☐ |
| TB code documented | ☐ |
| Final report written | ☐ |
| Reports attached | ☐ |
| Sign-off obtained | ☐ |

---

## Troubleshooting

### Issue 1: SDF Loading Failure

```
** Error: SDF File Load Failed
```

**Fix:**
- ตรวจสอบ SDF path ถูกต้อง
- ตรวจสอบ instance path `/tb/dut` ตรงกับ hierarchy
- ตรวจสอบ permissions

### Issue 2: Time Scale Mismatch

```
** Error: Time scale error in SDF
```

**Fix:** ใช้ `-t ps` ใน vsim

### Issue 3: Cell Library Missing

```
** Error: Unknown module NAND2X1
```

**Fix:** Compile cell library ก่อน GLS:
```bash
vlog -work tech_lib /path/to/cell_lib.v
```

### Issue 4: Instance Name Mismatch

```
** Warning: No matching instance in SDF
```

**Fix:**
- Case sensitivity (`u1` ≠ `U1`)
- ตรวจสอบ hierarchy ใน waveform viewer

### Issue 5: Glitch ใน TX

**Fix:**
- เพิ่ม delay ใน FSM output
- ใช้ Moore (registered output) แทน Mealy

### Issue 6: Coverage ต่ำกว่าเป้า

**Fix:**
- เพิ่ม test cases
- ตรวจสอบ exclusions
- Random + coverage bins

---

## Checkpoint: Mini Project Done?

| Item | Status |
| --- | --- |
| RTL verified ใน Questa | ☐ |
| Synthesis ผ่าน Precision RTL | ☐ |
| SDF generated | ☐ |
| GLS ผ่าน typical corner | ☐ |
| GLS ผ่าน fast corner | ☐ |
| GLS ผ่าน slow corner | ☐ |
| Coverage goals met | ☐ |
| Final report written | ☐ |
| Sign-off obtained | ☐ |

ถ้าทุกข้อ ✅ → Mini Project สำเร็จ! พร้อมไป Part 2 (IC Layout, MEMS)

---

## สรุปสิ่งที่ได้เรียนรู้

1. **Complete ASIC Flow**: spec → RTL → TB → synth → SDF → GLS
2. **Multi-corner GLS**: typ/fast/slow
3. **Debug Skills**: X, timing, glitch
4. **Coverage**: functional + code
5. **Documentation**: final report template
6. **Sign-off**: complete checklist

---

> **จบหลักสูตร Part 1: Digital IC Design & Verification (Day 1-5)**
> **ต่อไป:** Part 2 — IC Layout & MEMS Design (Day 6-10)
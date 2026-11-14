# รายละเอียดเชิงลึก: Gate-Level Simulation (GLS) & SDF

> เนื้อหานี้ออกแบบมาให้นำไปแทรกเป็นส่วนขยายในหัวข้อ **4.3 ภาคทฤษฎี: GD&T Level Simulation (GLS)** ของคู่มือหลักสูตร (วันที่ 4)
> เหมาะสำหรับการบรรยาย 90–120 นาที

---

# ส่วนที่ A: Gate-Level Simulation (GLS) — เชิงลึก

## A.1 GLS คืออะไร

**Gate-Level Simulation (GLS)** คือการ simulate design ที่ระดับ **gate-level netlist** (หลัง synthesis) โดยใช้ **delay information** จาก SDF

```
   RTL Design     ──▶  Synthesis  ──▶  Gate-Level Netlist (.v)
   (VHDL/Verilog)                    │  + SDF (Standard Delay Format)
                                     │
                                     + ────▶ GLS (gate + timing)
```

**จุดประสงค์:**
1. ✅ Verify **functional correctness** หลัง synthesis (logic ตรงตามที่ต้องการ)
2. ✅ Verify **timing correctness** (ไม่มี setup/hold violation)
3. ✅ Catch bugs ที่ RTL sim ไม่เห็น (X-propagation, glitches)
4. ✅ Validate **timing closure** ก่อน tape-out

## A.2 RTL vs GLS — เปรียบเทียบ

| Aspect | RTL Simulation | Gate-Level Simulation (GLS) |
|---|---|---|
| **Abstraction** | Behavioral | Gate-level (NAND, NOR, FF) |
| **Delay model** | Information only | Actual (from SDF) |
| **Speed** | Fast (10K-100K cycles/sec) | Slow (1-100× slower) |
| **Accuracy** | Functional only | Functional + Timing |
| **Tool** | Questa, ModelSim | Questa + SDF |
| **Setup** | Easy | Complex (SDF + libraries) |
| **Use case** | Early verification, TB development | Sign-off, silicon pre-check |
| **Cost** | License + time | License + lots of compute time |

## A.3 ประเภทของ GLS

### A.3.1 Zero-delay GLS

ใช้ netlist + SDF แต่ delay = 0 (เหมือน RTL sim แต่มี netlist)

**จุดประสงค์:** ตรวจสอบว่า netlist ที่ synthesis ออกมามี functional behavior เหมือน RTL

**ปัญหา:** ไม่จับ timing issue

### A.3.2 Unit-delay GLS

ใช้ netlist + SDF แต่ delay = 1 ns ทุก gate (uniform)

**จุดประสงค์:** จับบาง timing issues เช่น glitches, race conditions

### A.3.3 Full-timing GLS (real SDF)

ใช้ netlist + SDF ที่มี delay จริงจาก cell library

**Pro:** Most accurate, catches setup/hold violations, X-propagation

**Con:** Slowest

### A.3.4 Power-aware GLS

ใช้ netlist + SDF + UPF (Unified Power Format) เพื่อ simulate power state transitions

**ใช้กับ:** Low-power designs ที่มี multiple power domains

## A.4 GLS Setup Flow

```
   ┌────────────────────────────────────────┐
   │  Step 1: Generate netlist               │
   │  - Precision RTL → Verilog netlist     │
   │  - Save as top_netlist.v               │
   └─────────────┬──────────────────────────┘
                 │
                 ▼
   ┌────────────────────────────────────────┐
   │  Step 2: Generate SDF                   │
   │  - Precision RTL → SDF file           │
   │  - Save as top.sdf                     │
   └─────────────┬──────────────────────────┘
                 │
                 ▼
   ┌────────────────────────────────────────┐
   │  Step 3: Prepare testbench              │
   │  - Same TB as RTL sim                  │
   │  - May need different instance names   │
   └─────────────┬──────────────────────────┘
                 │
                 ▼
   ┌────────────────────────────────────────┐
   │  Step 4: Compile libraries + netlist    │
   │  vlog cell_lib.v                       │
   │  vlog top_netlist.v                    │
   └─────────────┬──────────────────────────┘
                 │
                 ▼
   ┌────────────────────────────────────────┐
   │  Step 5: Load SDF                       │
   │  vsim -sdf /tb/dut=top.sdf top         │
   └─────────────┬──────────────────────────┘
                 │
                 ▼
   ┌────────────────────────────────────────┐
   │  Step 6: Run simulation                 │
   │  - Same testbench patterns              │
   │  - Watch for X, timing warnings        │
   └────────────────────────────────────────┘
```

## A.5 GLS Setup ใน Questa

### A.5.1 Library Preparation

```bash
# Compile cell library first (one-time)
vlib tech_lib
vlog -work tech_lib cell_lib_45nm.v
```

### A.5.2 Compile Netlist

```bash
# Compile synthesised netlist
vlib work_gate
vlog -work work_gate top_netlist.v
```

### A.5.3 Compile Testbench (same as RTL TB)

```bash
vcom -work work_gate tb_top.vhd
```

### A.5.4 Load with SDF

```bash
# Start simulation with SDF back-annotation
vsim -t ps -sdf /tb_top/dut=top.sdf work_gate.tb_top

# Time precision = 1ps (GLS ต้องการ ps ไม่ใช่ ns)
# /tb_top/dut = instance path
# top.sdf = SDF file
```

### A.5.5 Batch Mode Script

```tcl
# run_gls.do
vlib work_gate
vlog -work work_gate top_netlist.v
vcom -work work_gate tb_top.vhd

vsim -t ps -sdf /tb_top/dut=top.sdf work_gate.tb_top

add wave /tb_top/*
add wave /tb_top/dut/*

run 1 ms
quit -f
```

### A.5.6 Multi-corner Simulation

```tcl
# Corner 1: typical PVT
vsim -t ps -sdf /tb_top/dut=top_typ.sdf work_gate.tb_top
coverage save typ_cov.ucdb

# Corner 2: fast PVT
vsim -t ps -sdf /tb_top/dut=top_fast.sdf work_gate.tb_top
coverage save fast_cov.ucdb

# Corner 3: slow PVT
vsim -t ps -sdf /tb_top/dut=top_slow.sdf work_gate.tb_top
coverage save slow_cov.ucdb

# Merge all
vcover merge merged.ucdb typ_cov.ucdb fast_cov.ucdb slow_cov.ucdb
```

## A.6 X-Propagation ใน GLS

### A.6.1 X คืออะไรใน GLS

ใน GLS, signal `X` (unknown) เกิดได้หลายทาง:
1. **Uninitialized FF** (ไม่มี reset)
2. **Setup/hold violation** → FF output = 'X'
3. **Bus contention** (multi-driver)
4. **Initial condition** ก่อน simulation เริ่ม

### A.6.2 X-Propagation ใน GLS vs RTL

| Aspect | RTL | GLS |
|---|---|---|
| **X visibility** | Rare (user-supplied) | Common (timing violations) |
| **X causes** | Uninitialized | Setup/hold + uninitialized |
| **Detection** | Real | Manual + Assertion |

### A.6.3 จัดการ X ใน GLS

```systemverilog
// Assertion: No X in output
property no_x_output;
    @(posedge clk) disable iff (!rst_n)
    $isunknown(out) == 0;
endproperty
assert property (no_x_output);

// In TB
initial begin
    forever @(posedge clk) begin
        if (^out_signal === 1'bx) begin
            $error("X in out_signal at %t", $time);
        end
    end
end
```

## A.7 Setup และ Hold Violations ใน GLS

### A.7.1 Setup Violation

**Setup violation** เกิดเมื่อ data มาถึง FF ไม่ทันก่อน clock edge

```
   clk:       ─┐          ┌──
                └─────────┘
                          ↑
                          clock edge
   data:    ──┐
               └────────────────────
                    ↑
                    data transition (too close to edge)

   → Setup violation → FF output = 'X' ใน GLS
```

### A.7.2 Hold Violation

**Hold violation** เกิดเมื่อ data เปลี่ยนเร็วเกินไปหลัง clock edge

```
   clk:       ─┐          ┌──
                └─────────┘
                ↑
                clock edge (data latch)
   data:    ──┐       ┌──
               └───────┘
                    ↑
                    data changes too soon (hold violation)
```

### A.7.3 ตรวจ FFT ใน GLS

ใน GLS transcript จะเห็น:

```
# ** Warning: Setup violation detected at time 15234.5 ns
#     Path: FF_A (launch) -> FF_B (capture)
#     Required setup time: 100 ps
#     Actual setup time: 50 ps
#     Slack: -50 ps (VIOLATED)
```

### A.7.4 Debug Setup/Hold Violations

```tcl
# In Questa transcript
report_timing -delay max -num_paths 100  # setup
report_timing -delay min -num_paths 100  # hold

# Save waveform around violation time
write wave -window 15200.0ns 15250.0ns wave.glg
```

## A.8 Glitches ใน GLS

### A.8.1 Glitch คืออะไร

**Glitch** = transient pulse สั้น ๆ ที่เกิดจาก delay mismatch ระหว่าง paths

```
   a:      ─┐    ┌──
            └────┘
   b:    ─┐
          └────────────

   expected: a AND b
   actual:  glitch (สั้น pulse ก่อน settle)
                ┌──
   y:    ──┐   │  │
           └───┘  └─────
            ↑ glitch (2 ms)
```

### A.8.2 ผลกระทบของ Glitch

- ⚠️ FF latch ค่า glitch (race condition)
- ⚠️ Counter นับผิด
- ⚠️ Combinational logic produce wrong output
- ⚠️ Power glitch (extra switching)

### A.8.3 การจัดการ Glitch

1. **Add delay** — ensure signal meets pulse width constraint
2. **Synchronize input** — register input ก่อนใช้
3. **Use glitch-aware cells** — delayed FF
4. **Set max pulse width constraint** ใน SDC

### A.8.4 ตัวอย่าง: Async Reset De-assertion

```vhdl
-- BAD: Async reset de-asserted ใกล้ clk edge → may violate recovery/removal
process (clk, rst_n)
begin
    if rst_n = '0' then
        q <= (others => '0');
    elsif rising_edge(clk) then
        q <= d;
    end if;
end process;

-- ใน RTL sim: ทำงานปกติ
-- ใน GLS: rst_n de-assert ใกล้ clk edge → recovery violation → q = 'X'
```

**Fix:** ใช้ reset synchronizer

```vhdl
process (clk)
begin
    if rising_edge(clk) then
        sync1 <= async_rst_n;
        sync2 <= sync1;
    end if;
end process;

-- ใช้ sync_rst_n (delayed by 2 cycles) → synchronous de-assertion
```

## A.9 Async Reset Issues ใน GLS

### A.9.1 Recovery และ Removal Time

```
   clock edge: ─┐    ┌──
                 └────┘
                          ↑
                          must de-assert async reset BEFORE this edge (≥ recovery)

   async reset: ─┐          ┌──
                   └────────┘
                              ↑
                              must remain asserted AFTER this edge (≥ removal)
```

### A.9.2 ปัญหาใน GLS

ถ้า async reset de-assert ใกล้ clock edge → **recovery/removal violation** → FF output = 'X'

```
   Simulation transcript:
   # ** Warning: Recovery violation at time 15234.5 ns
```

### A.9.3 วิธีป้องกัน

1. **Reset synchronizer** (ดูบทที่ 2)
2. **Synchronous reset** แทน async reset
3. **Padding delay** ระหว่าง reset de-assertion กับ clock edge

## A.10 Power-aware GLS

### A.10.1 Concept

ใน low-power designs:
- Multiple **power domains** (VDD_CORE, VDD_IO, ...)
- **Power gating** — ปิด power บางส่วน
- **Voltage scaling** — ลด VDD บางส่วน

Power-aware GLS ต้อง:
- ใช้ UPF (Unified Power Format) หรือ CPF (Common Power Format)
- Model power state transitions
- Verify isolation cells, level shifters, retention FF

### A.10.2 Power States

```
   Power State Table:
   ┌────────┬─────────┬──────────┐
   │ State  │ Domain1 │ Domain2  │
   ├────────┼─────────┼──────────┤
   │ FULL   │ ON      │ ON         │
   │ IDLE   │ ON      │ Clock-Gate│
   │ SLEEP  │ Retention│ OFF      │
   │ OFF    │ GND       │ GND      │
   └────────┴─────────┴──────────┘
```

### A.10.3 Tools

| Tool | Vendor |
|------|--------|
| Questa Power Aware | Siemens EDA |
| Genus + Joules | Cadence |
| Power Compiler | Synopsys |

---

# ส่วนที่ B: SDF (Standard Delay Format) — เชิงลึก

## B.1 SDF คืออะไร

**SDF** (IEEE Std 1497) คือ **text format** สำหรับเก็บ delay information ของ cells และ interconnect ใช้ร่วมกับ GLS

```
   SDF file ────▶ Simulator (load SDF)
                       │
                       ▼
                  Apply delays
                  to gate-level
                  netlist
```

## B.2 SDF Structure (Top-Level)

```tcl
(SDF
    (CELL                ← top-level cell (netlist)
        (CELLTYPE "module_name")
        (INSTANCE ...)
        (DELAY ...)
    )
    (CELL                ← instance
        (CELLTYPE "NAND2X1")
        (INSTANCE path.to.u1)
        (DELAY
            (ABSOLUTE
                (IOPATH A Y (...))      ← input-to-output path
                (IOPATH B Y (...))
            )
            (PATHPULSE ... )            ← pulse propagation
        )
    )
    ...
)
```

## B.3 IOPATH — Cell Delay

### B.3.1 Format

```tcl
(IOPATH <input_pin> <output_pin> (rise_delay) (fall_delay))
```

**ตัวอย่าง:**

```tcl
(IOPATH A Y (0.15) (0.20))
-- rise (A 0→1 → Y 0→1): 150 ps
-- fall (A 1→0 → Y 1→0): 200 ps
```

### B.3.2 Delay Values

- Triples: 2 values (rise, fall)
- Triples: 3 values (rise, fall, **Z → X transition**) — rare

### B.3.3 Conditional IOPATH

```tcl
(COND <condition>
    (IOPATH A Y (...))
)
```

**ตัวอย่าง:**

```tcl
(COND B==1'b1
    (IOPATH A Y (0.12) (0.18))   ;; when B=1
)
(COND B==1'b0
    (IOPATH A Y (0.20) (0.25))   ;; when B=0
)
```

## B.4 Net Delay (Interconnect)

### B.4.1 Net Delay Format

```tcl
(NETDELAY <net>
    (DELAY
        (ABSOLUTE
            (PATHPULSE ...)
        )
    )
)
```

**ตัวอย่าง:**

```tcl
(NETDELAY data_in
    (DELAY
        (ABSOLUTE
            (PATHPULSE (0.050) (0.080))   ;; min, max
        )
    )
)
```

### B.4.2 Wire Load Model (WLM)

ใน pre-layout SDF, interconnect delay คำนวณจาก **Wire Load Model** (WLM) ที่อ้างอิงจาก fan-out

```tcl
(WIRELOAD "typ_wlm"
    (RESISTANCE 0.05)        ;; per unit length
    (CAPACITANCE 0.10)
    (SLOPE 0.20)
)
```

หลัง layout, delay จะมาจาก **RC extraction** (เช่นจาก Calibre xACT)

## B.5 PATHPULSE

### B.5.1 Concept

PATHPULSE defines **pulse propagation behavior** — ว่า pulse ขนาด หนึ่ง จะถูก propagate หรือ filter

```
   Input:  ───┐
               └─────────────  pulse width = T1

   Output (narrow):
              ┌──┐
              │  │           pulse width (L) = limit
              └──┘
```

### B.5.2 Format

```tcl
(PATHPULSE <input_pin> <output_pin> (limit) (Xlimit))
```

**ตัวอย่าง:**

```tcl
(PATHPULSE A Y (0.10) (0.15))
-- Pulse width < 100 ps: filtered (not propagated)
-- 100 ps ≤ Pulse < 150 ps: propagated as X (unknown)
-- Pulse ≥ 150 ps: propagated normally
```

**Goal:** prevent glitches (short pulses) from latching wrong values

## B.6 Complete SDF Example

```tcl
(SDF
    ;; ============ Interconnect ============
    (CELL
        (CELLTYPE "module")
        (INSTANCE)
        (DELAY
            (ABSOLUTE
                (INTERCONNECT a feed_in (0.05) (0.07))
                (INTERCONNECT b feed_in (0.05) (0.07))
                (INTERCONNECT clk feed_clk (0.10) (0.12))
            )
        )
    )

    ;; ============ NAND2X1 gate ============
    (CELL
        (CELLTYPE "NAND2X1")
        (INSTANCE u1)
        (DELAY
            (ABSOLUTE
                (IOPATH A Y (0.15) (0.20))
                (IOPATH B Y (0.15) (0.20))
                (PATHPULSE A Y (0.10) (0.15))
            )
        )
    )

    ;; ============ DFFRX1 gate ============
    (CELL
        (CELLTYPE "DFFRX1")
        (INSTANCE u2)
        (DELAY
            (ABSOLUTE
                (IOPATH CK Q (0.20) (0.22))
                (IOPATH D Q (0.30) (0.35))
                (IOPATH RN Q (0.10) (0.12))   ;; recovery/removal
            )
        )
    )
)
```

## B.7 SDF Generation

### B.7.1 Tools ที่ Generate SDF

| Tool | Output |
|---|---|
| Precision RTL | SDF (pre-layout, uses WLM) |
| Synopsys DC | SDF |
| Cadence Genus | SDF |
| Calibre xACT | SDF (post-layout, RC-based) |
| Innovus / ICC2 | SDF (post-layout) |

### B.7.2 Precision RTL SDF Output

```tcl
# In synth.tcl
report_timing -delay max -num_paths 50 -file timing_max.rpt
report_timing -delay min -num_paths 50 -file timing_min.rpt

# SDF output (with -sdf_write option)
write_sdf -output top.sdf
```

### B.7.3 Multi-corner SDF

```
   top_typ.sdf      ;# typical process, voltage, temp
   top_fast.sdf     ;# fast PVT (best case)
   top_slow.sdf     ;# slow PVT (worst case)
```

Run GLS สำหรับทุก corner เพื่อ verify silicon behavior

## B.8 SDF Loading ใน Questa

### B.8.1 คำสั่ง vsim

```bash
# Single SDF
vsim -sdf /tb/dut=top.sdf work.tb_top

# Specify SDF timing mode
vsim -sdf min 0 -sdf typ 1 -sdf max 2 /tb/dut=top.sdf

# Time precision (need ps for GLS)
vsim -t ps -sdf /tb/dut=top.sdf work.tb_top
```

### B.8.2 SDF Checking

```bash
# Check if SDF loaded correctly
vsim> show -sdf
```

Output:
```
   SDF file: top.sdf
   Loaded to: /tb_top/dut
   Cells processed: 1234
   Paths annotated: 5678
```

## B.9 SDF Pitfalls

### B.9.1 Pitfall 1: Mismatched Instance Names

ถ้า netlist มี instance ชื่อ `u1` แต่ SDF มี `U1` → simulator ไม่ apply delay

**Solution:** ตรวจสอบ case sensitivity

### B.9.2 Pitfall 2: Missing Cell Types

ถ้า netlist มี cell `MY_CELL` แต่ SDF ไม่มี delay สำหรับ `MY_CELL` → delay = 0 (อาจทำให้ race)

### B.9.3 Pitfall 3: Wrong SDF Version

SDF 4.0 vs 5.0 vs 5.1 มี syntax ต่างกันเล็กน้อย

### B.9.4 Pitfall 4: Time Scale Mismatch

ถ้า SDF delay = ns แต่ simulator precision = ps → delay interpreted wrong

## B.10 SDF Best Practices

| Rule | Reason |
|---|---|
| ✅ SDF precision = simulator precision | Match units |
| ✅ ทุก cell มี delay (ไม่มี missing) | Avoid races |
| ✅ Test ทุก corner (typ, fast, slow) | Verify across PVT |
| ✅ Verify instance names match | Apply correctly |
| ✅ Check PATHPULSE for glitches | Prevent races |
| ⚠️ Conditional delays for tristate | Correct behavior |

---

# ส่วนที่ C: Practical GLS Workflow

## C.1 End-to-End Synthesis → GLS

```
   ┌────────────────────────────────────┐
   │  RTL Design (VHDL)                 │
   └────────────┬───────────────────────┘
                │
                ▼
   ┌────────────────────────────────────┐
   │  Synthesis (Precision RTL)         │
   │  - Netlist (Verilog)               │
   │  - SDF (typ/fast/slow)              │
   │  - Reports (area, timing, power)   │
   └────────────┬───────────────────────┘
                │
                ▼
   ┌────────────────────────────────────┐
   │  GLS Setup                         │
   │  - Compile netlist + SDF           │
   │  - Load TB                         │
   │  - Run simulation                 │
   └────────────┬───────────────────────┘
                │
                ▼
   ┌────────────────────────────────────┐
   │  Analysis                          │
   │  - Setup/Hold violations           │
   │  - X-propagation                   │
   │  - Glitches                       │
   │  - Functional mismatch                  │
   └────────────────────────────────────┘
```

## C.2 Questa Command Sequence

### C.2.1 Synthesis (Precision RTL)

```tcl
# synth.tcl
new_project -name top -technology "/tech/gscl45nm"
add_source -type vhdl -work work top.vhd tb_top.vhd
add_constraint_file top.sdc
set_top_module top
compile -incremental_mapping
report_timing -delay max -num_paths 50 -file timing.rpt
report_array -file area.rpt
write_sdf -output top.sdf
export_netlist -format verilog -output top_netlist.v
exit
```

### C.2.2 GLS

```tcl
# run_gls.do
vlib work_gate
vlog -work work_gate /tech_lib/gscl45nm.v          ;# cell library
vlog -work work_gate top_netlist.v                ;# synthesized netlist
vcom -work work_gate tb_top.vhd                  ;# testbench (VHDL)

# Load SDF and run
vsim -t ps -sdf /tb_top/dut=top.sdf work_gate.tb_top
add wave -position insertpoint sim:/tb_top/*
add wave -position insertpoint sim:/tb_top/dut/*

# Run
run 1 ms

# Save results
coverage save -onexit gls_cov.ucdb
quit -f
```

## C.3 Multi-Corner GLS

### C.3.1 Strategy

- **Typical corner** (nominal PVT): main functional verification
- **Fast corner** (fast process, low voltage, high temp): hold violations
- **Slow corner** (slow process, high voltage, low temp): setup violations

### C.3.2 Script

```tcl
# run_multicorner.do
foreach corner {typ fast slow} {
    puts "Running corner: $corner"

    vlib work_gate_$corner
    vlog -work work_gate_$corner /tech_lib/gscl45nm.v
    vlog -work work_gate_$corner top_netlist.v
    vcom -work work_gate_$corner tb_top.vhd

    vsim -t ps -sdf /tb_top/dut=top_${corner}.sdf work_gate_$corner.tb_top

    add wave -position insertpoint sim:/tb_top/*

    run 1 ms
    coverage save -onexit gls_${corner}.ucdb

    quit -f
}

# Merge coverage
vcover merge gls_merged.ucdb gls_typ.ucdb gls_fast.ucdb gls_slow.ucdb
```

## C.4 Debug เมื่อ GLS Fail

### C.4.1 Setup Violation ที่ Specific Path

```tcl
# 1. Get path info
report_timing -delay max -num_paths 1 -path_type full_clock

# 2. Save waveform รอบ ๆ violation time
add wave /tb_top/dut/u_FF_*
set-name cf_violation_wave wave_violation

# 3. เปลี่ยน clock period (relax)
vsim -t ps -G sys_clk_period=15.0

# 4. Optimize RTL และ re-synth
```

### C.4.2 X-Propagation

```tcl
# Trace X กลับไปยัง source
add wave /tb_top/dut/*

# ดู FF ที่ produce X ก่อน
identify_x_sources -scope /tb_top/dut
```

### C.4.3 Glitch

```tcl
# Save glitch waveform
write wave -window 15200.0ns 15210.0ns glitch.glg

# Optimize: add delay, register output, etc.
```

## C.5 Tools รายละเอียด

### C.5.1 Siemens EDA

- **Questa Advanced Simulator**: GLS with timing
- **Precision RTL**: Synthesis + SDF generation
- **Calibre xACT**: RC extraction for post-layout SDF

### C.5.2 Cadence

- **Genus**: Synthesis
- **Innovus**: P&R + SDF
- **Tempus**: STA
- **Voltus**: Power-aware GLS

### C.5.3 Synopsys

- **Design Compiler**: Synthesis
- **ICC2**: P&R
- **PrimeTime**: STA
- **VCS**: GLS

### C.5.4 Open-Source

- **Yosys**: Synthesis (limited)
- **Verilator**: Fast sim (no SDF)
- **OpenSTA**: STA

## C.6 GLS Best Practices

### C.6.1 Setup

| Rule | Reason |
|---|---|
| ✅ Use `-t ps` time precision | GLS needs ps |
| ✅ Compile cell library first | Avoid missing models |
| ✅ Use proper SDF mode (typ/fast/slow) | Verify all corners |
| ✅ Match instance names | Apply SDF correctly |
| ⚠️ Use same TB as RTL | Consistency |

### C.6.2 Analysis

| Rule | Reason |
|---|---|
| ✅ Check for X in output | Sign of timing issue |
| ✅ Watch for setup/hold warnings | Critical bugs |
| ✅ Verify glitches | Functional issue |
| ⚠️ Use assertion to flag X | Automated detection |

### C.6.3 Coverage

| Rule | Reason |
|---|---|
| ✅ Functional coverage on GLS | Same as RTL |
| ⚠️ Code coverage same as RTL | Should match (if synth-clean) |

## C.7 Common GLS Issues และ Solutions

### C.7.1 Issue: RTL Pass, GLS Fail

| Symptom | Possible Cause | Solution |
|---|---|---|
| X in output | Setup/hold violation | Increase clock period, fix RTL |
| Functional mismatch | Synthesis bug | Re-check synthesis options |
| Output wrong | Glitch | Register output, add delay |
| Reset not working | Recovery/removal violation | Use reset synchronizer |

### C.7.2 Issue: GLS too slow

| Cause | Solution |
|---|---|
| Many corners | Run only critical corner first |
| Long simulation | Reduce TB size, use event-driven sim |
| Large SDF | Use SDF reduce tool |

### C.7.3 Issue: SDF doesn't load

| Symptom | Cause | Solution |
|---|---|---|
| "No matching instance" | Instance name mismatch | Check case, naming |
| "Cell type not found" | Library not compiled | Compile cell library first |
| "Time scale error" | SDF in ns, sim in ps | Use `-t ps` |

## C.8 Real-World GLS Strategy

### C.8.1 When to Run GLS

```
   RTL sign-off (functional):
      ├─ Functional coverage ≥ 95%
      ├─ Code coverage ≥ 95%
      ├─ All assertions pass
      └─ All corner cases tested
                    │
                    ▼
   Synthesis sign-off (timing):
      ├─ Synthesis clean (no latches)
      ├─ All clocks propagated
      ├─ Timing report: all paths meet
                    │
                    ▼
   GLS sign-off (gate-level):
      ├─ RTL TB runs against netlist
      ├─ No X propagation
      ├─ No setup/hold violations
      ├─ Multi-corner verified
      └─ Power-aware (if applicable)
```

### C.8.2 Resource Allocation

| Activity | Time | Notes |
|---|---|---|
| RTL sim | Most | Many test cases |
| Synthesis | Hours | Quick iterations |
| GLS | Days to weeks | Run fewer cases |
| Post-layout GLS | Days | Final sign-off |

### C.8.3 Tape-out Criteria

- ✅ All RTL coverage met
- ✅ Synthesis report OK
- ✅ GLS passes for typ/fast/slow
- ✅ STA passes (PrimeTime, Tempus)
- ✅ DRC/LVS clean (Calibre)
- ✅ Power analysis clean (Voltus)
- ✅ DFT coverage met

---

# ส่วนที่ D: Examples

## D.1 Example: 4-bit Counter GLS

```vhdl
-- RTL (counter4.vhd)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter4 is
    port (
        clk : in std_logic;
        rst_n : in std_logic;
        cnt : out unsigned(3 downto 0)
    );
end entity;

architecture rtl of counter4 is
    signal cnt_i : unsigned(3 downto 0);
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                cnt_i <= (others => '0');
            else
                cnt_i <= cnt_i + 1;
            end if;
        end if;
    end process;
    cnt <= cnt_i;
end architecture;
```

```tcl
# synth.tcl
new_project -top counter4
add_source counter4.vhd
add_constraint_file counter.sdc
set_top_module counter4
compile
write_sdf counter4.sdf
export_netlist -format verilog counter4_netlist.v
```

```tcl
# run_gls.do
vlib work_gate
vlog -work work_gate /tech_lib/gscl45nm.v
vlog -work work_gate counter4_netlist.v
vcom -work work_gate tb_counter4.vhd

vsim -t ps -sdf /tb_counter4/dut=counter4.sdf work_gate.tb_counter4
add wave /tb_counter4/*
run 1 us
```

**ผลที่คาดหวัง:**
- Counter นับ 0 → 15 ตาม clock
- Reset → 0
- ไม่มี X หาก setup/hold ผ่าน
- ถ้า clock period < propagation delay → X เกิด

## D.2 Example: Pipeline Design

```vhdl
-- Multi-stage pipeline
process (clk)
begin
    if rising_edge(clk) then
        if rst_n = '0' then
            stage1 <= (others => '0');
            stage2 <= (others => '0');
            stage3 <= (others => '0');
        else
            stage1 <= input_data;
            stage2 <= stage1;
            stage3 <= stage2;
        end if;
    end if;
end process;
```

**ใน GLS ที่ corner ต่าง ๆ:**

| Corner | Behavior |
|---|---|
| Typical | Data ผ่าน 3 stages, output = input (delayed 3 cycles) |
| Fast (low voltage) | Setup violation อาจเกิด → output X |
| Slow (high temp) | Hold violation อาจเกิด → output X |

## D.3 Example: Async Reset (Sensitive)

```vhdl
-- DANGER: Async reset, RTL passes, GLS may fail
process (clk, rst_n)
begin
    if rst_n = '0' then
        q <= '0';
    elsif rising_edge(clk) then
        q <= d;
    end if;
end process;
```

```tcl
# Test TB: rst_n de-asserted ใกล้ clock edge
vsim> force rst_n 0
vsim> run 10ns
vsim> force rst_n 1  -- de-assert 5 ns before clk edge
vsim> run 1 ns        -- clk edge!
```

**GLS Output:**

```
   ** Warning: Recovery violation at time 14.999 ns
   **         FF q may be metastable (output = X)
```

---

# ส่วนที่ E: Summary

## E.1 Key Concepts

1. **GLS** = gate-level simulation with timing
2. **SDF** = delay format for GLS
3. **X-propagation** = sign of timing issue
5. **Multi-corner** = verify across PVT
6. **Reset recovery/removal** = timing violation ที่ critical
7. **Glitch** = short pulses that may latch wrong

## E.2 Workflow Summary

| Step | Tool | Output |
|---|---|---|
| 1. RTL design | Editor | VHDL file |
| 2. RTL verification | Questa | Verified RTL |
| 3. Synthesis | Precision | Netlist + SDF |
| 4. GLS | Questa + SDF | Verified gate-level |

## E.3 Tools Summary

| Phase | Siemens EDA | Cadence | Synopsys |
|---|---|---|---|
| RTL sim | Questa | Xcelium | VCS |
| Synthesis | Precision | Genus | DC |
| GLS | Questa + SDF | Xcelium + SDF | VCS + SDF |
| STA | Tempus | Tempus | PrimeTime |
| P&R | — | Innovus | ICC2 |

## E.4 Key Takeaways

1. **GLS** = final check before tape-out
2. **SDF** = critical for timing accuracy
3. **X in output** = bug to investigate
4. **Multi-corner** = essential
5. **Reset synchronizer** = prevent recovery violation
6. **Power-aware GLS** = for low-power designs

## E.5 อ้างอิง

- IEEE Std 1497-2009, "Standard for Standard Delay Format (SDF)."
- "Siemens EDA Precision RTL Synthesis User Manual" — SDF Generation.
- "Questa Advanced Simulator User Manual" — GLS, SDF.
- "Cadence Genus Synthesis User Manual" — SDF.
- "Synopsys VCS User Manual" — GLS.
- "Calibre xACT Manual" — RC Extraction for SDF.

---

> **หมายเหตุ:** เนื้อหานี้ออกแบบให้บรรยายได้ประมาณ 90-120 นาที รวม SDF format examples, Questa commands, GLS workflow, common issues + solutions พร้อมใช้ประกอบการสอนภาคทฤษฎี Day 4 บ่าย หรือแบ่งเป็น 2 mini-lectures (GLS 60 นาที + SDF 60 นาที)
# Lab 4: Step-by-Step Guide — GLS + Assertion-based Testbench

> **เวลาใช้งาน:** 2.5-3 ชั่วโมง
> **เครื่องมือ:** Questa Advanced Simulator + Precision RTL (Siemens EDA)
> **Output ที่คาดหวัง:** Gate-level simulation ที่ใช้ SDF, assertion-based testbench ที่ตรวจ X และ timing violations

---

## Step 0: เตรียมโปรเจกต์และไฟล์

### 0.1 โครงสร้าง Directory

สร้าง directory:

```powershell
mkdir E:\lab\VHDL(BOI)\lab4_work
mkdir E:\lab\VHDL(BOI)\lab4_work\rtl
mkdir E:\lab\VHDL(BOI)\lab4_work\gate
mkdir E:\lab\VHDL(BOI)\lab4_work\tb
mkdir E:\lab\VHDL(BOI)\lab4_work\reports
```

### 0.2 ไฟล์ที่ต้องมี

| ไฟล์ | ที่อยู่ |
| --- | --- |
| `rtl/adder8_assert.vhd` | DUT (RTL พร้อม assertions) |
| `tb/tb_adder8_assert.vhd` | Testbench (ใช้ assertions) |
| `constraints/adder8.sdc` | SDC สำหรับ synthesis |
| `synth.tcl` | Precision RTL script |
| `run_gls.do` | GLS batch script |
| `cell_lib_path` | Path ของ cell library (ต้องปรับ) |

### 0.3 ตรวจสอบ Library

```powershell
# ต้องรู้ path ของ technology library
# ตัวอย่าง: C:\Siemens\tech_lib\gscl45nm.v
# ถ้าไม่มี ใช้ vendor อื่น:
# - Cadence: tsmc45nm.v
# - Skywater: sky130_fd_sc_hd.v
# - ใช้ fake cell library สำหรับ demo
```

**สำหรับ Lab นี้ จะใช้ fake library** (สมมติว่ามี) เพื่อ demo GLS — ในงานจริงจะใช้ vendor-specific library

---

## Step 1: เขียน RTL Design พร้อม Assertions

### 1.1 สร้างไฟล์ `rtl/adder8_assert.vhd`

### 1.2 พิมพ์ Code

```vhdl
-- ============================================================
-- File: adder8_assert.vhd
-- Lab 4 - 8-bit Counter with Built-in Assertions
-- Demonstrates: RTL + PSL assertions + GLS
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder8_assert is
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;            -- active-low sync reset
        din_a   : in  unsigned(7 downto 0);
        din_b   : in  unsigned(7 downto 0);
        cin     : in  std_logic;
        sum     : out unsigned(7 downto 0);
        cout    : out std_logic
    );
end entity adder8_assert;

architecture rtl of adder8_assert is
    signal sum_i : unsigned(7 downto 0);
    signal cout_i : std_logic;
begin
    -----------------------------------------------------------
    -- Functional Logic: 8-bit Adder
    -----------------------------------------------------------
    p_adder : process (din_a, din_b, cin)
        variable vsum : unsigned(8 downto 0);
    begin
        vsum := "0" & din_a + "0" & din_b + (0 => cin, others => '0');
        sum_i  <= vsum(7 downto 0);
        cout_i <= vsum(8);
    end process;

    sum <= sum_i;
    cout <= cout_i;

    -----------------------------------------------------------
    -- PSL Default Clock Declaration
    -----------------------------------------------------------
    -- Place after architecture declaration
end architecture rtl;

-----------------------------------------------------------
-- PSL Assertions (ใส่ไว้ที่ end of file หรือในไฟล์แยก)
-- =========================================================
PSL default clock is rising_edge(clk);

PSL assert always
    (sum_i /= X"00" or cout_i = '1' or din_a = (din_a'range => '0') or din_b = (din_b'range => '0') or cin = '0')
    report "Adder should never output 0 with carry 0 from non-zero inputs"
    severity warning;

-- Cout must equal 1 if a + b + cin > 255
PSL assert always
    ((("0" & din_a) + ("0" & din_b) + (0 => cin, others => '0'))(8) = cout_i)
    report "Carry-out mismatch"
    severity failure;

-- No X in sum when inputs valid
PSL assert never
    (din_a /= X"00" and din_b /= X"00" and sum_i = "XXXXXXXX")
    report "Sum is X with non-X inputs"
    severity failure;
```

**หมายเหตุ:** ใน VHDL PSL assertions มีหลาย syntax — ดู documentation ของ tool ที่ใช้ (Questa) สำหรับ syntax ที่ถูกต้อง

### 1.3 บันทึก

---

## Step 2: เขียน Assertion-based Testbench

### 2.1 สร้างไฟล์ `tb/tb_adder8_assert.vhd`

### 2.2 พิมพ์ Code

```vhdl
-- ============================================================
-- File: tb_adder8_assert.vhd
-- Lab 4 - Assertion-based Testbench
-- Pattern: Self-checking with concurrent + immediate assertions
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_adder8_assert is
end entity tb_adder8_assert;

architecture sim of tb_adder8_assert is
    constant CLK_PERIOD : time := 10 ns;
    signal clk     : std_logic := '0';
    signal rst_n   : std_logic := '0';
    signal din_a   : unsigned(7 downto 0) := (others => '0');
    signal din_b   : unsigned(7 downto 0) := (others => '0');
    signal cin     : std_logic := '0';
    signal sum     : unsigned(7 downto 0);
    signal cout    : std_logic;

    -- Scoreboard
    signal pass_cnt, fail_cnt : integer := 0;
begin
    clk <= not clk after CLK_PERIOD / 2;

    -- DUT
    dut : entity work.adder8_assert
        port map (
            clk => clk, rst_n => rst_n,
            din_a => din_a, din_b => din_b, cin => cin,
            sum => sum, cout => cout
        );

    -----------------------------------------------------------
    -- IMMEDIATE Assertions (ใน process)
    -----------------------------------------------------------
    p_immediate : process (clk)
        procedure check(expected_sum : unsigned(7 downto 0);
                       expected_cout : std_logic;
                       tag           : string) is
        begin
            if sum = expected_sum and cout = expected_cout then
                pass_cnt <= pass_cnt + 1;
            else
                fail_cnt <= fail_cnt + 1;
                assert false
                    report "FAIL " & tag &
                           ": got sum=" & integer'image(to_integer(sum)) &
                           " cout=" & std_logic'image(cout) &
                           " exp sum=" & integer'image(to_integer(expected_sum)) &
                           " cout=" & std_logic'image(expected_cout)
                    severity error;
            end if;
        end procedure;
    begin
        if rising_edge(clk) then
            if rst_n = '1' then
                -- Sample on every clock
                check(din_a + din_b + (0 => cin, others => '0')(7 downto 0),
                      (din_a + din_b + (0 => cin, others => '0'))(8),
                      "immediate check");
            end if;
        end if;
    end process p_immediate;

    -----------------------------------------------------------
    -- CONCURRENT Assertions (PSL-style — ตัวอย่าง)
    -----------------------------------------------------------
    -- (ใส่ไว้ในไฟล์ design เพื่อให้ synthesis + simulation ใช้ร่วม)

    -----------------------------------------------------------
    -- STIMULUS
    -----------------------------------------------------------
    stim : process
    begin
        -- Reset
        rst_n <= '0';
        wait for 5 * CLK_PERIOD;
        rst_n <= '1';

        -- Test 1: 0 + 0
        din_a <= x"00"; din_b <= x"00"; cin <= '0';
        wait for 2 * CLK_PERIOD;

        -- Test 2: 1 + 1
        din_a <= x"01"; din_b <= x"01"; cin <= '0';
        wait for 2 * CLK_PERIOD;

        -- Test 3: 0xFF + 0x01
        din_a <= x"FF"; din_b <= x"01"; cin <= '0';
        wait for 2 * CLK_PERIOD;
        -- Expected: sum=0x00, cout=1

        -- Test 4: 0x80 + 0x80
        din_a <= x"80"; din_b <= x"80"; cin <= '0';
        wait for 2 * CLK_PERIOD;
        -- Expected: sum=0x00, cout=1

        -- Test 5: 0xFF + 0xFF + 1
        din_a <= x"FF"; din_b <= x"FF"; cin <= '1';
        wait for 2 * CLK_PERIOD;
        -- Expected: sum=0xFF, cout=1

        -- Random tests
        for trial in 0 to 99 loop
            din_a <= std_logic_vector(to_unsigned(
                integer'(integer'(now) mod 256), 8));
            din_b <= std_logic_vector(to_unsigned(
                integer'(integer'(now) mod 256 + trial) mod 256, 8));
            cin   <= std_logic'val(((trial / 2) mod 2) + 1);
            wait for 2 * CLK_PERIOD;
        end loop;

        report "====================================";
        report "PASS: " & integer'image(pass_cnt);
        report "FAIL: " & integer'image(fail_cnt);
        report "====================================";

        if fail_cnt = 0 then
            report "Lab 4 ALL TESTS PASSED" severity note;
        end if;

        std.env.stop;
    end process;
end architecture sim;
```

### 2.3 บันทึก

---

## Step 3: เขียน SDC Constraints

### 3.1 สร้างไฟล์ `constraints/adder8.sdc`

### 3.2 พิมพ์ SDC

```tcl
# adder8.sdc - SDC for 8-bit adder synthesis
# Target: 100 MHz, typical PVT

# Clock definition
create_clock -name sys_clk -period 10.0 -waveform {0 5} [get_ports clk]

# Input delays
set_input_delay  -clock sys_clk 2.0 -max [get_ports {din_a din_b cin rst_n}]
set_input_delay  -clock sys_clk 1.0 -min [get_ports {din_a din_b cin rst_n}]

# Output delays
set_output_delay -clock sys_clk 2.0 -max [get_ports {sum cout}]
set_output_delay -clock sys_clk 1.0 -min [get_ports {sum cout}]

# Reset is synchronous - ignore
set_false_path -from [get_ports rst_n]

# Drive strength and load
set_driving_cell -lib_cell INVX1 -pin Y [get_ports {din_a din_b cin rst_n}]
set_load 0.05 [get_ports {sum cout}]

# Operating conditions
set_operating_conditions -process typical -voltage 1.0 -temp 25
```

### 3.3 บันทึก

---

## Step 4: Generate Netlist + SDF ด้วย Precision RTL

### 4.1 สร้างไฟล์ `synth.tcl`

### 4.2 พิมพ์ SDL

```tcl
# synth.tcl - Precision RTL Synthesis Script
# Usage: precision -shell -file synth.tcl

set tech_lib    "/path/to/gscl45nm"        ;# ⚠️ แก้ path ตามจริง
set design_name "adder8_assert"
set rtl_dir     "rtl"

# Create project
new_project -name $design_name -folder work_$design_name \
            -technology "$tech_lib"

# Add source files
add_source -type vhdl -work work -library work "$rtl_dir/adder8_assert.vhd"

# Add constraints
add_constraint_file "constraints/adder8.sdc"

# Set top
set_top_module adder8_assert

# Elaborate
elaborate

# Synthesize
compile -incremental_mapping -retiming

# Reports
report_area   -file reports/area.rpt -append
report_timing -delay max -num_paths 50 -file reports/timing_max.rpt -append
report_timing -delay min -num_paths 50 -file reports/timing_min.rpt -append
report_power  -file reports/power.rpt -append

# Export netlist
export_netlist -format verilog -output gate/adder8_netlist.v

# Write SDF
write_sdf -output gate/adder8.sdf

puts "Synthesis complete!"
puts "Netlist: gate/adder8_netlist.v"
puts "SDF: gate/adder8.sdf"
puts "Reports: reports/"

exit
```

### 4.3 รัน Precision RTL

```bash
precision -shell -file synth.tcl
```

**Output ที่คาดหวัง:**

```
   adder8_assert compiled successfully
   Created file: gate/adder8_netlist.v
   Created file: gate/adder8.sdf
```

### 4.4 ตรวจสอบ Netlist

```bash
# ดู Verilog netlist
type gate\adder8_netlist.v | more
```

ตัวอย่าง netlist:
```verilog
module adder8_assert (clk, rst_n, din_a, din_b, cin, sum, cout);
    input clk, rst_n, cin;
    input [7:0] din_a, din_b;
    output [7:0] sum;
    output cout;

    wire n0, n1, ... ;
    ADDX1 U1 (.A(din_a[0]), .B(din_b[0]), .CI(cin), .S(sum[0]), .CO(n1));
    ...
endmodule
```

### 4.5 ตรวจสอบ SDF

```bash
type gate\adder8.sdf | more
```

ตัวอย่าง SDF:
```tcl
(SDF
    (CELL
        (CELLTYPE "module")
        (INSTANCE)
        (DELAY
            (ABSOLUTE
                (INTERCONNECT clk din_a (0.05) (0.05))
                ...
            )
        )
    )
    (CELL
        (CELLTYPE "ADDX1")
        (INSTANCE U1)
        (DELAY
            (ABSOLUTE
                (IOPATH A S (0.150) (0.180))
                ...
            )
        )
    )
    ...
)
```

---

## Step 5: Setup GLS ใน Questa (GUI Mode)

### 5.1 เปิด Questa

### 5.2 สร้าง Project ใหม่

1. `File → New → Project`
2. **Project Name:** `lab4_gls`
3. **Location:** `E:\lab\VHDL(BOI)\lab4_work`
4. **OK**

### 5.3 Compile Libraries และ Netlist

1. `File → New → Library` → สร้าง library `tech_lib`
2. `Compile → Compile…`:
   - เลือก cell library: `C:\path\to\gscl45nm.v` (cell library)
3. สร้าง working library `work`:
   - `File → New → Library` → `work`
4. Compile netlist:
   - `Project → Add to Project → Existing File`
   - เพิ่ม `gate\adder8_netlist.v`
   - Compile All

### 5.4 Compile Testbench

1. `Project → Add to Project`
2. เพิ่ม `tb\tb_adder8_assert.vhd`
3. Compile All

**Output ที่คาด:**
```
# Errors: 0, Warnings: 0
```

### 5.5 Load SDF

1. `Simulate → Start Simulation`
2. เลือก `tb_adder8_assert` ใน `work` library
3. **แท็บ SDF:** เพิ่ม SDF
   - **SDF File:** `gate/adder8.sdf`
   - **Instance:** `/tb_adder8_assert/dut`
4. **แท็บ Options:** ตั้ง `timestep` = `ps`
5. **OK**

**Transcript ที่คาด:**
```
# Loading package... -- Loading netlist...
# SDF file loaded successfully
# Time precision = 1 ps
```

### 5.6 Run

- `run 1 us`
- ดู waveform + transcript

---

## Step 6: GLS Verification Checklist

### 6.1 Transcript ที่คาดหวัง

```
# **Note: PASS: 250 (or similar)
# **Note: FAIL: 0
# **Note: Lab 4 ALL TESTS PASSED
```

### 6.2 สิ่งที่ต้องดู

| Item | Expected | Notes |
| --- | --- | --- |
| RTL pass | ✅ | TB ผ่านใน RTL sim |
| GLS pass | ✅ | TB ผ่านใน GLS (with SDF) |
| `assert cout` | No violation | PSL assertion pass |
| `assert sum is X` | No violation | No X propagation |
| Setup violation | 0 warnings | SDF delay OK |
| Hold violation | 0 warnings | Recovery/removal OK |
| Cout mismatch | 0 | Adder logic correct |
| Output transitions | All bit changes | No short pulses (glitches) |

### 6.3 Verification Steps

1. ✅ **Compile errors**: 0
2. ✅ **Netlist loaded**: Yes
3. ✅ **SDF applied**: Yes
4. ✅ **TB pass count > 0**: Yes
5. ✅ **No assertion fail**: Yes
6. ✅ **No X in output**: Yes (ตรวจดูใน waveform)
7. ✅ **No timing violation**: Yes (ใน transcript)

---

## Step 7: Batch Mode Script (สำหรับ CI/CD)

### 7.1 สร้างไฟล์ `run_gls.do`

### 7.2 พิมพ์ Content

```tcl
# run_gls.do - GLS batch script
# Usage: vsim -do run_gls.do -c

# === Setup ===
vlib tech_lib
vlib work_gate

# Compile cell library (one-time, vendor-specific)
# vlog -work tech_lib /path/to/gscl45nm.v

# Compile synthesized netlist
vlog -work work_gate gate/adder8_netlist.v

# Compile testbench
vcom -2008 -work work_gate tb/tb_adder8_assert.vhd

# === Load SDF and Run ===
puts ""
puts "============================================"
puts "Lab 4: GLS with SDF Back-annotation"
puts "============================================"

vsim -t ps -sdf /tb_adder8_assert/dut=gate/adder8.sdf work_gate.tb_adder8_assert

# Add waves
add wave -position insertpoint sim:/tb_adder8_assert/*
add wave -position insertpoint sim:/tb_adder8_assert/dut/*

# Run with sufficient time
run 1 us

# Save coverage
coverage save -onexit gls_cov.ucdb

# Done
quit -f
```

### 7.3 รัน Script

```bash
cd E:\lab\VHDL(BOI)\lab4_work
vsim -do run_gls.do -c
```

### 7.4 Output ที่คาดหวัง

```
# Reading pref.tcl...
# vlib tech_lib
# vlib work_gate
# vlog -work work_gate gate/adder8_netlist.v
# vcom -2008 -work work_gate tb/tb_adder8_assert.vhd
# vsim -t ps -sdf /tb_adder8_assert/dut=gate/adder8.sdf ...
# ** Note: PASS: 250
# ** Note: FAIL: 0
# ** Note: Lab 4 ALL TESTS PASSED
# Coverage: Saved to gls_cov.ucdb
```

---

## Step 8: ตรวจจับ X ใน GLS

### 8.1 เพิ่ม X-detection ใน TB

แก้ไข testbench เพื่อตรวจ X ใน output:

```vhdl
-- Add to tb_adder8_assert.vhd
p_x_detect : process (clk)
begin
    if rising_edge(clk) then
        if sum = "XXXXXXXX" or cout = 'X' then
            assert false
                report "X detected in DUT output!"
                severity error;
        end if;
    end if;
end process;
```

### 8.2 Run และดู X propagation:
- ถ้า output เป็น 'X' → SDF timing violation หรือ uninitialized FF
- Debug ดู waveform หุจรอบ ๆ จุดที่ X เกิด

---

## Step 9: Multi-corner GLS

### 9.1 Generate SDF สำหรับหลาย Corner

ใน Precision RTL:
```tcl
# Typical
report_timing -delay max
write_sdf -output gate/adder8_typ.sdf

# Fast corner
report_timing -delay min  ;# for hold checks
write_sdf -output gate/adder8_fast.sdf

# Slow corner  
report_timing -delay max  ;# for setup checks
write_sdf -output gate/adder8_slow.sdf
```

### 9.2 Multi-corner Script

```tcl
# run_multicorner.do
foreach corner {typ fast slow} {
    puts ""
    puts "========================================"
    puts "Running corner: $corner"
    puts "========================================"

    vlib work_gate_$corner
    vlog -work work_gate_$corner gate/adder8_netlist.v
    vcom -work work_gate_$corner tb/tb_adder8_assert.vhd

    vsim -t ps -sdf /tb_adder8_assert/dut=gate/adder8_${corner}.sdf \
         work_gate_$corner.tb_adder8_assert

    add wave -position insertpoint sim:/tb_adder8_assert/*
    run 1 us

    coverage save -onexit gls_${corner}.ucdb
    quit -f
}

# Merge coverage
vcover merge gls_merged.ucdb gls_typ.ucdb gls_fast.ucdb gls_slow.ucdb
```

### 9.3 Run

```bash
vsim -do run_multicorner.do -c
```

---

## Step 10: Debug Setup/Hold Violation

### 10.1 เมื่อมี Violation

Transcript จะแสดง:

```
# ** Warning: Setup violation detected
#    Time: 12.345 ns  Iteration: 50
#    Required setup time: 0.150 ns
#    Actual setup time: 0.100 ns
#    Path: dut.U1 → dut.U2
```

### 10.2 Debug Steps

1. **ดู Critical Path**:
   ```tcl
   report_timing -delay max -num_paths 1 -path_type full_clock
   ```

2. **Identify FF source และ destination**:
   - FF_A → combinational → FF_B

3. **เช็ค Combinational Delay**:
   - ถ้า delay > clock period - setup → violation

4. **แก้ไข**:
   - เพิ่ม clock period (`create_clock -period 15`)
   - Pipeline insertion: add FF ระหว่าง
   - Logic optimization: refactor expression
   - Use higher drive cells

### 10.3 Save waveform

```tcl
# Save waveform รอบ violation time
add wave /tb_top/dut/*
run 2.0 ns
write wave -window 12.0ns 14.0ns violation.glg
```

---

## Step 11: Debug X-Propagation

### 11.1 เมื่อเห็น X

Transcript:
```
# ** Warning: X propagated through FF
```

### 11.2 Trace X กลับที่มา

1. **เปิด Wave** → ดู signal ที่ X
2. **Trace ย้อนกลับ** → upstream signal
3. **ตรวจสอบ**:
   - Uninitialized FF? (ต้องมี reset)
   - Setup violation ที่ input FF?

### 11.3 Common X Sources

| Source | Solution |
|---|---|
| Uninitialized FF | Add reset |
| Setup violation | Increase clock period |
| Async reset de-assert | Use reset synchronizer |
| Bus contention | Drive only one driver at a time |
| X propagation from input | Constrain input timing |

---

## Step 12: Verification Report

### 12.1 สร้าง Coverage Report

```tcl
# ใน Questa
vcover report -details -output gls_report.html gls_cov.ucdb
```

**ผลที่คาด:**
- Functional coverage: 100% (basic tests)
- Code coverage: 95%+ (depends on TB)

### 12.2 Create Final Report

สร้าง `report_gls.md`:

```
## GLS Report - adder8_assert

### Synthesis
- Tool: Precision RTL
- Cell library: gscl45nm
- Date: <date>

### GLS Status
- ✅ Compile errors: 0
- ✅ SDF applied: yes
- ✅ Test pass: all
- ✅ No X propagation
- ✅ No timing violations

### Coverage
- Functional: 100%
- Code: 95%+
- Toggle: 100%

### Multi-corner Results
- Typical: PASS
- Fast: PASS
- Slow: PASS

### Sign-off
All checks passed, ready for tape-out.
```

---

## Troubleshooting

### Error 1: SDF Loading Failure

```
** Error: SDF File Load Failed
```

**สาเหตุ:** SDF file path ไม่ถูกต้อง หรือ format ผิด

**Fix:**
- ตรวจสอบ SDF file path
- ตรวจสอบ instance name (`/tb/dut` ต้องตรงกับ TB hierarchy)

### Error 2: Time Scale Mismatch

```
** Error: Time scale error in SDF
```

**Fix:**
- ใช้ `-t ps` ใน vsim (GLS ต้องการ ps ไม่ใช่ ns)
- SDF time scale ต้องตรงกัน

### Error 3: Instance Name Mismatch

```
** Warning: No matching instance in SDF
```

**สาเหตุ:** Instance ใน netlist ไม่ตรงกับ SDF

**Fix:**
- ตรวจสอบ case sensitivity (`u1` vs `U1`)
- ดู netlist เทียบกับ SDF

### Error 4: Cell Library Not Found

```
** Error: Unknown module NAND2X1
```

**Fix:**
- Compile cell library ก่อน
- ตรวจสอบ path ของ vendor library

### Error 5: Simulation Too Slow

**Fix:**
- ลด TB size (run fewer cycles)
- ใช้ `-novopt` (no waveform accumulator)
- ใช้ event-driven simulation (default)

---

## Bonus Challenges

### Challenge 1: Add Reset Timing Check

```vhdl
-- Reset must be held for ≥ 3 cycles
assert rst_period : assert always
    (rst_n = '0') -> rst_n = '0' for 3 cycles
    report "Reset must be held ≥ 3 cycles"
    severity failure;
```

### Challenge 2: Functional Coverage ใน VHDL

```vhdl
-- Track all 256 values of din_a
architecture sim of tb_adder8_cov is
    signal covered : bit_vector(0 to 255) := (others => '0');
begin
    p_cov : process (clk)
    begin
        if rising_edge(clk) then
            covered(to_integer(din_a)) <= '1';
        end if;
    end process;
end architecture;
```

### Challenge 3: Multi-clock GLS

ถ้า design มี 2 clocks, ต้อง:
- 2 separate SDF files
- 2 separate timing paths
- CDC check (with Questa CDC)

### Challenge 4: Power-aware GLS

ใช้ UPF (Unified Power Format):
```tcl
# upf.tcl
create_power_domain PD_TOP
create_power_domain PD_CORE
connect_logic_net ...
```

### Challenge 5: Equivalence Check

ใช้ Questa Formal:
- RTL vs Netlist equivalence
- ทุก node must be provable

---

## Checkpoint

| Item | Status |
| --- | --- |
| เขียน RTL พร้อม PSL assertions | ☐ |
| เขียน TB แบบ assertion-based | ☐ |
| สร้าง SDC | ☐ |
| Run Precision RTL → netlist + SDF | ☐ |
| Compile netlist ใน Questa | ☐ |
| Load SDF สำเร็จ | ☐ |
| Run GLS ผ่าน | ☐ |
| ตรวจ X propagation | ☐ |
| ตรวจ timing violations | ☐ |
| Multi-corner verified | ☐ |
| Generate coverage report | ☐ |

ถ้าทุกข้อ ✅ → พร้อมไป Day 5 (Mini Project)

---

## สรุปสิ่งที่ได้เรียนรู้

1. **GLS** = simulate gate-level netlist with SDF
2. **SDF** = delay annotation from synthesis
3. **Assertions** = catch X, timing, protocol violations
4. **Multi-corner** = typ/fast/slow PVT
5. **X-propagation** = critical GLS issue
6. **Setup/hold** = timing violations
7. **Recovery/removal** = async reset timing
8. **Coverage** = functional + code + toggle
9. **Tools**: Precision RTL (synth) + Questa (GLS)

---

> **ต่อไป:** Day 5 — Mini Project (UART TX) ที่รวมทุกขั้นตอน
>   RTL → TB → Synthesis → SDF → GLS → Verification Report
# รายละเอียดเชิงลึก: ASIC Flow + Verification Plan

> เนื้อหานี้ออกแบบมาให้นำไปแทรกเป็นส่วนขยายในหัวข้อ **5.1 ภาคทฤษฎี: ASIC Flow Integration** และ **5.2 Verification Plan & Sign-off** ของคู่มือหลักสูตร (วันที่ 5)
> เหมาะสำหรับการบรรยาย 90–120 นาที

---

# ส่วนที่ A: ASIC Flow Integration — เชิงลึก

## A.1 Front-End Flow Recap

```
┌───────────────────────────────────────────────────────────────┐
│ 1. SPEC     : Requirements, feature, success criteria        │
│ 2. RTL      : VHDL/Verilog design (Day 1-2)                   │
│ 3. VERIFY   : Self-checking TB + assertions + coverage (Day 2-4)│
│ 4. SYNTH    : RTL → netlist + constraints (Day 3)             │
│ 5. GLS      : Gate-Level Sim with SDF (Day 4)                  │
└───────────────────────────────────────────────────────────────┘
```

**Phase 1: Specification**

- Functional spec
- Interface spec
- Architecture spec
- Verification plan
- Coverage model

**Phase 2: RTL Design**

- Code style ที่ consistent
- Hierarchical blocks
- Testbenches for each block

**Phase 3: Verification**

- Self-checking TB
- Reference model
- Assertions (PSL/SVA)
- Functional coverage
- Code coverage

**Phase 4: Synthesis**

- SDC constraints
- Logic optimization
- Technology mapping
- Area + timing + power reports

**Phase 5: Gate-Level Sim**

- Netlist + SDF
- X-detection
- Timing violation check
- Multi-corner

## A.2 Back-End Flow Preview (สำหรับ ASIC)

```
┌───────────────────────────────────────────────────────────────┐
│ 6. FLOORPLAN   : Macro placement, power grid                 │
│ 7. PLACEMENT   : Standard cells placement                     │
│ 8. CTS         : Clock Tree Synthesis                         │
│ 9. ROUTING     : Wire routing                                  │
│ 10. SIGN-OFF   : STA, DRC, LVS, power, ESD                    │
│ 11. GDSII      : Layout database                                │
│ 12. FAB        : TSMC, Samsung, etc.                          │
└───────────────────────────────────────────────────────────────┘
```

**ใน Day 5 หลักสูตร** เราเน้น Front-end จนถึง GLS — Back-end เป็นเนื้อหาของ Part 2 (Day 6-10) หรือหลักสูตรอื่น

## A.3 Verification & Synthesis Integration

```
   ┌─────────────────────────────────────────────┐
   │ RTL Design + Verification                       │
   │ - TB pass                                    │
   │ - Coverage ≥ 95%                           │
   │ - Assertions pass                          │
   └─────────────┬───────────────────────────────┘
                 │
                 ▼
   ┌─────────────────────────────────────────────┐
   │ Synthesis                                   │
   │ - Timing report OK                         │
   │ - No latches                               │
   │ - All clocks propagated                    │
   └─────────────┬───────────────────────────────┘
                 │
                 ▼
   ┌─────────────────────────────────────────────┐
   │ Gate-Level Simulation                       │
   │ - Same TB passes                           │
   │ - No X in output                            │
   │ - No timing violation                       │
   └─────────────┬───────────────────────────────┘
                 │
                 ▼
   ┌─────────────────────────────────────────────┐
   │ Sign-Off                                     │
   │ - All checks pass                          │
   │ - Ready for back-end or tape-out            │
   └─────────────────────────────────────────────┘
```

**Critical Questions:**

1. ✅ Did TB pass on RTL? → proceed
2. ✅ Did synthesis complete? → proceed
3. ✅ Did TB pass on netlist? → proceed
4. ❌ Fail? → debug, fix RTL, restart

## A.4 Common Failures และ Solutions

| Failure | Likely Cause | Solution |
|---|---|---|
| RTL pass, synth fail | Latch, bad clock, async logic | Fix RTL |
| RTL pass, GLS fail | Setup violation, X propagation | Optimize RTL, increase clock period |
| RTL fail, GLS pass | Synthesis hides bug | Use full-timing GLS |
| Coverage < 95% | Missing test cases | Add targeted tests |
| Assertion fail | RTL bug | Fix RTL |

---

# ส่วนที่ B: Verification Plan — เชิงลึก

## B.1 Verification Plan Purpose

**Verification Plan** คือเอกสารที่ระบุ:
1. **สิ่งที่จะ verify** — feature list, specification
3. **วิธี verify** — methodology, tools, coverage
4. **เกณฑ์ผ่าน** — pass criteria

**ทำไมต้องมี:**
- ✅ ลด rework
- ✅ Track progress
- ✅ Stakeholder alignment
- ✅ Risk management
- ✅ Sign-off evidence

## B.2 Verification Plan Components

### B.2.1 Feature List

```markdown
## Feature List: UART TX

| ID | Feature | Description | Priority | Verification Method |
|----|---------|-------------|----------|---------------------|
| F01 | Reset | Sync reset clears state | Critical | Directed |
| F02 | Frame Format | 8-N-1 | Critical | Directed + Random |
| F03 | Baud Rate | 115200 | High | Constrained random |
| F04 | Back-to-back | Continuous frames | High | Directed |
| F05 | All data values | 0x00-0xFF | Medium | Exhaustive |
| F06 | MSB/LSB | Bit order | Medium | Directed |
| F07 | Interrupt | tx_done signal | Low | Directed |
```

### B.2.2 Verification Strategy

```markdown
## Verification Strategy

### Module-Level (Day 1-2)
- Directed tests for: Reset, Frame, Baud, MSB/LSB
- Reference model: Python-based or behavior VHDL
- Self-checking TB with scoreboard

### Sub-System (Day 2)
- TX integration tests
- Interrupt propagation
- Bus protocol (APB/AXI/AHB)

### Full Chip (Day 3+)
- Multi-clock domain
- Multi-power domain
- Performance counters

### Post-Silicon (Future)
- Validation on silicon
- Performance characterization
```

### B.2.3 Coverage Goals

```markdown
## Coverage Goals

### Code Coverage
- Statement: ≥ 95%
- Branch: ≥ 90%
- Condition: ≥ 85%
- Toggle: 100% (with justification for excludes)

### Functional Coverage
- All critical features: 100%
- Major features: ≥ 95%
- Edge cases: 100%

### Assertion Coverage
- All assertions pass: 100%
- All properties checked

### Exclusions (with justification)
- Reset logic: usually excluded from toggle
- Scan chains: usually excluded
- DFT logic: usually excluded
```

### B.2.4 Tools

```markdown
## Tools

### Simulation
- Questa Advanced Simulator (Siemens EDA)
- ModelSim (basic)

### Synthesis
- Precision RTL (Siemens EDA)

### Coverage
- Questa Cover
- IMCS (Integrated Metrics)

### Formal Verification
- Questa Formal (Siemens EDA)

### Assertion
- PSL (IEEE 1850)
- SystemVerilog Assertions (IEEE 1800)
```

### B.2.5 Timeline

```markdown
## Timeline (5-day course)

### Day 1: Fundamentals
- Spec review
- RTL design (basic)
- TB scaffold

### Day 2: Advanced RTL
- FSM (Moore/Mealy)
- Self-checking TB
- HDL Designer

### Day 3: Synthesis
- SDC constraints
- Precision RTL synthesis
- Area + timing analysis

### Day 4: Verification
- Coverage-driven TB
- Assertions (PSL/SVA)
- GLS with SDF
- Multi-corner

### Day 5: Mini Project
- End-to-end UART TX
- Full verification report
- Sign-off
```

### B.2.6 Pass Criteria

```markdown
## Pass Criteria

### RTL Verification
- ✅ All tests pass
- ✅ Functional coverage ≥ 95%
- ✅ Code coverage ≥ 95%
- ✅ All assertions pass
- ✅ No warnings (or documented)

### Synthesis
- ✅ Compiles without errors
- ✅ Timing constraints met
- ✅ All clocks propagated
- ✅ No latches

### Gate-Level Sim
- ✅ RTL TB passes against netlist
- ✅ No X propagation
- ✅ No timing violations
- ✅ Multi-corner verified

### Documentation
- ✅ Final report
- ✅ Coverage report
- ✅ Sign-off approval
```

## B.3 Spec → Verification Plan Mapping

### B.3.1 Step 1: Spec Analysis

```markdown
## Spec Document

### Functional Requirements
1. UART TX shall transmit 8-bit data
2. Baud rate: 115200
3. Frame format: 1 start, 8 data, 1 stop
4. Reset: synchronous, active-low

### Performance Requirements
1. Throughput: 115200 bps
3. Latency: ≤ 1 frame time

### Interface Requirements
1. 8-bit data input
2. din_vld/din_rdy handshake
3. tx_done interrupt
```

### B.3.2 Step 2: Extract Verification Features

จาก spec → feature list:

```
   Spec Requirement  ─►  Verification Feature
   ──────────────────────────────────────────
   "8-bit data"       ─► F05: All data values
   "Baud 115200"     ─► F03: Baud rate
   "1 start bit"     ─► F02: Frame format
   "Sync reset"       ─► F01: Reset
   "din_vld/rdy"     ─► F08: Handshake protocol
```

### B.3.3 Step 3: Create Test Plan

```markdown
## Test Plan

| Test ID | Feature | Stimulus | Method | Pass Criteria |
|---------|---------|----------|--------|---------------|
| TX_001 | F01 | rst_n pulse | Directed | q cleared |
| TX_002 | F02 | 0x55 | Directed | start=0, data=01010101, stop=1 |
| TX_003 | F03 | All 3 baud | Random | Frame timing matches |
| TX_004 | F04 | 0x55, 0xAA | Directed | 2 frames back-to-back |
| TX_005 | F05 | 0x00-0xFF | Exhaustive | All bytes correct |
| TX_006 | F06 | 0x55 with MSB first | Directed | LSB first fails test |
```

### B.3.4 Step 4: Coverage Model

```systemverilog
covergroup cg_uart_tx @(posedge clk);
    cp_data : coverpoint tx_data {
        bins zero  = {8'h00};
        bins ff    = {8'hFF};
        bins alt1  = {8'h55, 8'hAA};
        bins corner = {[8'h01:8'h0F], [8'hF0:8'hFE]};
        bins default = default;
    }
    cp_baud : coverpoint baud_sel { ... };
    cp_state : coverpoint state { ... };
    cx_data_baud : cross cp_data, cp_baud;
endgroup
```

### B.3.5 Step 5: Sign-off

```markdown
## Sign-off Report

### Coverage Achieved
- Functional: 98%
- Branch: 92%
- All assertions: 100% pass

### Bugs Found
- Total: 5
- Fixed: 5
- Waived: 0

### Status: PASS
- All checks passed
- Ready for tape-out
```

---

# ส่วนที่ C: Verification Methodology ใน ASIC Flow

## C.1 Verification Pyramid

```
                  ┌─────────────────────────────────────┐
                  │   Chip-Level (SoC)                  │
                  │   - Full system                    │
                  │   - Emulation                       │
                  │   - Software bring-up                │
                  └─────────────────────────────────────┘
                  ┌─────────────────────────────────────┐
                  │   Subsystem / Block                 │
                  │   - Multi-IP integration              │
                  │   - Constrained random               │
                  │   - Scoreboard                       │
                  └─────────────────────────────────────┘
                  ┌─────────────────────────────────────┐
                  │   Module / IP                       │
                  │   - Single block                    │
                  │   - Directed + assertions         │
                  │   - Functional coverage         │
                  └─────────────────────────────────────┘
```

**ใน Day 5 Mini Project** เราเน้น Module-Level เป็นหลัก

## C.2 Verification Strategy Selection

| Feature Type | Strategy |
|---|---|
| **Known behavior** (FSM states) | Directed Tests |
| **Combinational logic** (ALU) | Exhaustive |
| **Sequential logic** (counter) | Directed + Coverage |
| **Protocol** (UART, SPI) | Directed + Assertions |
| **Corner cases** | Constrained random |
| **Critical properties** | Formal verification |

## C.3 Coverage Strategy

```
   ┌──────────────────────────────────────────┐
   │  Spec → Features (Functional Coverage)     │
   └────────────┬─────────────────────────────┘
                │
                ▼
   ┌──────────────────────────────────────────┐
   │  Code Coverage (Statement, Rigidify)         │
   └────────────┬─────────────────────────────┘
                │
                ▼
   ┌──────────────────────────────────────────┐
   │  Toggle Coverage (Coverage)                    │
   └────────────┬─────────────────────────────┘
                │
                ▼
   ┌──────────────────────────────────────────┐
   │  Assertion Coverage (Coverage)                 │
   └────────────┬─────────────────────────────┘
                │
                ▼
   ┌──────────────────────────────────────────┐
   │  Combined Coverage ≥ Goals → DONE           │
   └──────────────────────────────────────────┘
```

## C.4 Sign-off Criteria

### C.4.1 Coverage Goals

| Type | Goal | Method |
|------|------|--------|
| Statement | ≥ 95% | Questa Cover |
| Branch | ≥ 90% | Questa Cover |
| Condition | ≥ 85% | Questa Cover |
| Toggle | 100% (with justification) | Questa Cover |
| Functional | ≥ 95% (100% critical) | SystemVerilog or VHDL workaround |
| Assertion | 100% pass | PSL/SVA |

### C.4.2 Bug Status

- ✅ All critical bugs fixed
- ⚠️ Known bugs documented with workaround
- ❌ No open bugs at sign-off

### C.4.3 Test Status

- ✅ All directed tests pass
- ✅ All random tests pass (within statistical confidence)
- ✅ All corner cases tested

### C.4.4 Synthesis Status

- ✅ Compiles without errors
- ✅ All clocks propagated
- ✅ Timing constraints met
- ✅ Area within budget

### C.4.5 GLS Status

- ✅ TB passes against netlist
- ✅ No timing violations
- ✅ Multi-corner verified
- ✅ No X propagation

---

# ส่วนที่ D: Risk Management

## D.1 Risk Categories

### D.1.1 Design Risk

- Incomplete spec
- Missed corner cases
- Late RTL changes
- Interface mismatches

### D.1.2 Verification Risk

- Incomplete coverage
- Missed assertions
- TB bugs (TB may not detect DUT bugs)
- Tool issues

### D.1.3 Schedule Risk

- Underestimated TB time
- Late synthesis
- Late sign-off

### D.1.4 Tool Risk

- License issues
- Tool bugs
- Vendor library issues

## D.2 Risk Mitigation

| Risk | Mitigation |
|---|---|
| Incomplete spec | Spec review + clarification meetings |
| Missed corner cases | Spec → feature list → cross-coverage |
| Late RTL changes | Modular design + regression testing |
| Interface mismatches | Early integration testing |
| Incomplete coverage | Coverage-driven + iterative closure |
| Schedule overrun | Plan buffer + parallel work |
| Tool issues | Backup tools, vendor support |

## D.3 Risk Sign-off

```markdown
## Risk Register (Example)

| Risk | Probability | Impact | Mitigation | Owner | Status |
|---|---|---|---|---|---|
| Late RTL change | High | High | Modular design, regression | Designer | Open |
| Missing assertion | Medium | High | Spec-driven, formal | Verifier | Open |
| Timing violation | Medium | Critical | STA + GLS + corners | Verifier | Closed |
| Tool license | Low | High | Backup vendor | Manager | Closed |
```

---

# ส่วนที่ E: Mini Project Walkthrough — UART TX

## E.1 Project Spec

```markdown
## UART TX Specification

### Function
8-bit UART Transmitter

### Interface
- Clock: 100 MHz
- Data input: 8-bit parallel
- Handshake: din_vld/din_rdy
- Status: tx line output, tx_done flag

### Frame Format
- 1 start bit (0)
- 8 data bits (LSB first)
- 1 stop bit (1)

### Baud Rate
- Default: 115200
- Configurable: 9600, 19200, 115200

### Performance
- Throughput: 115200 bps
- Latency: 10 bit-times per frame
```

## E.2 Architecture

```
   ┌─────────────────────────────────────────────┐
   │  UART TX Top                                 │
   │                                              │
   │  ┌────────────┐      ┌─────────────┐      │
   │  │ Baud Gen   │─────►│ FSM         │      │
   │  │            │      │             │      │
   │  └────────────┘      └──────┬──────┘      │
   │                             │             │
   │  ┌────────────┐            ▼             │
   │  │ Register   │      ┌─────────────┐      │
   │  │ File       │◄─────│ Shift Reg   │      │
   │  └────────────┘      └──────┬──────┘      │
   │                             │             │
   │                             ▼             │
   │                       ┌──────────┐        │
   │                       │ TX line  │        │
   │                       └──────────┘        │
   └─────────────────────────────────────────────┘
```

## E.3 Verification Plan

### E.3.1 Feature List

```markdown
| ID | Feature | Description |
|----|---------|-------------|
| F01 | Reset | Sync reset, tx=1 |
| F02 | Baud Rate | 9600, 19200, 115200 |
| F03 | Frame Format | 1S + 8D + 1T (8-N-1) |
| F04 | Data 0x00 | 8 zeros + frame |
| F05 | Data 0xFF | 8 ones + frame |
| F06 | Data 0x55 | 01010101 |
| F07 | Data 0xAA | 10101010 |
| F08 | Back-to-back | 2 frames continuous |
| F09 | din_rdy | Asserted when ready |
| F10 | tx_done | Pulse after frame |
```

### E.3.2 Test Plan

```markdown
| Test ID | Description | Stimulus |
|---------|-------------|----------|
| U_TX_01 | Reset | rst=1 for 5 cycles |
| U_TX_02 | Send 0x55 | din=0x55, din_vld=1 |
| U_TX_03 | Send 0xAA | din=0xAA, din_vld=1 |
| U_TX_04 | Send all 256 | din=0..255 random |
| U_TX_05 | Back-to-back | 0x55 then 0xAA |
| U_TX_06 | Different baud | Switch baud mid-test |
| U_TX_07 | din_rdy behavior | Don't send when din_ready=0 |
| U_TX_08 | tx_done behavior | Verify pulse width |
| U_TX_09 | Reset during TX | Reset mid-frame |
```

### E.3.3 Coverage Goals

```markdown
| Metric | Goal |
|--------|------|
| Statement | 95% |
| Branch | 90% |
| Functional | 100% (critical) |
| State (FSM) | 100% |
| All data values | 100% |
```

## E.4 RTL Implementation

```vhdl
-- ============================================================
-- UART TX Top Level
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx_top is
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        baud_sel  : in  std_logic_vector(1 downto 0);  -- 00=9600, 01=19200, 10=115200
        din       : in  std_logic_vector(7 downto 0);
        din_vld   : in  std_logic;
        din_rdy   : out std_logic;
        tx        : out std_logic;
        tx_done   : out std_logic
    );
end entity uart_tx_top;

architecture rtl of uart_tx_top is
    constant CLK_FREQ : integer := 100_000_000;
    type baud_t is (B9600, B19200, B115200);
    signal baud_code : constant baud_selected : integer;

    signal baud_tick : std_logic;
    signal tx_busy : std_logic;
    signal shreg : std_logic_vector(7 downto 0);
    signal bit_idx : integer range 0 to 7;
    signal baud_count : integer range 0 to 868;
begin
    -- Baud rate generator
    baud_gen : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                baud_count <= 0;
                baud_tick <= '0';
            elsif baud_count = baud_divisor(baud_sel) - 1 then
                baud_count <= 0;
                baud_tick <= '1';
            else
                baud_count <= baud_count + 1;
                baud_tick <= '0';
            end if;
        end if;
    end process;

    -- FSM
    fsm : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                tx_sh <= '0';
                bit_idx <= 0;
                tx_busy <= '0';
                din_rdy <= '1';
                tx_done <= '0';
            else
                -- IDLE state
                if not tx_busy then
                    din_rdy <= '1';
                    if din_vld = '1' then
                        shreg <= din;
                        tx_busy <= '1';
                        din_rdy <= '0';
                        bit_idx <= 0;
                    end if;
                -- TX state
                elsif baud_tick = '1' then
                    if bit_idx = 0 then
                        tx_sh <= '0';  -- start bit
                    elsif bit_idx <= 8 then
                        tx_sh <= shreg(bit_idx - 1);
                    else
                        tx_sh <= '1';  -- stop bit
                    end if;
                    if bit_idx = 9 then
                        tx_busy <= '0';
                        tx_done <= '1';
                    else
                        bit_idx <= bit_idx + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    tx <= tx_sh;
end architecture;
```

## E.5 Testbench

```vhdl
-- ============================================================
-- UART TX Testbench with Scoreboard
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_uart_tx is
end entity tb_uart_tx;

architecture sim of tb_uart_tx is
    constant CLK_PERIOD : time := 10 ns;
    constant BAUD_TICKS_115200 : integer := 868;
    constant BIT_TIME_115200 : time := 8680 ns;

    signal clk, rst_n : std_logic := '0';
    signal baud_sel : std_logic_vector(1 downto 0) := "10";  -- 115200
    signal din : std_logic_vector(7 downto 0) := (others => '0');
    signal din_vld, din_rdy : std_logic;
    signal tx : std_logic;
    signal tx_done : std_logic;
    signal baud_tick : std_logic;

    signal pass_cnt, fail_cnt : integer := 0;
    signal expected_bits : std_logic_vector(9 downto 0);
begin
    clk <= not clk after CLK_PERIOD / 2;

    -- DUT
    dut : entity work.uart_tx_top
        port map (
            clk, rst_n, baud_sel, din, din_vld, din_rdy, tx, tx_done
        );

    -- Scoreboard checker (samples tx line)
    checker : process
        variable bit_idx : integer := 0;
        variable cx : cy : constant integer := 0;
        variable collected : std_logic_vector(9 downto 0) := (others => '0');
    begin
        -- Wait for transmission
        wait until tx_done = '1';

        -- Collect 10 bits
        for bit_i in 0 to 9 loop
            wait for BIT_TIME_115200;
            collected(bit_i) := tx;
        end loop;

        -- Compare
        if collected = expected_bits then
            pass_cnt <= pass_cnt + 1;
        else
            fail_cnt <= fail_cnt + 1;
            assert false
                report "Frame mismatch"
                severity error;
        end if;

        wait for BIT_TIME_115200;
    end process;

    -- Stimulus
    stim : process
    begin
        -- Reset
        rst_n <= '0';
        wait for 5 * CLK_PERIOD;
        rst_n <= '1';

        -- Test 1: 0x55
        expected_bits <= "0" & "10101010" & "1";  -- 0x55 LSB first
        din <= x"55"; din_vld <= '1';
        wait until rising_edge(clk);
        din_vld <= '0';
        wait until tx_done = '1';
        wait for 2 * BIT_TIME_115200;

        -- Test 2: 0xAA
        expected_bits <= "0" & "01010101" & "1";  -- 0xAA LSB first
        din <= x"AA"; din_vld <= '1';
        wait until rising_edge(clk);
        din_vld <= '0';
        wait until tx_done = '1';
        wait for 2 * BIT_TIME_115200;

        -- ...

        report "UART TX Tests Complete";
        report "PASS=" & integer'image(pass_cnt) & " FAIL=" & integer'image(fail_cnt);
        if fail_cnt = 0 then
            report "ALL TESTS PASSED" severity note;
        end if;
        std.env.stop;
    end process;
end architecture;
```

## E.6 Synthesis

```tcl
# synth_uart.tcl
new_project -name uart_tx_top -folder work_uart \
            -technology "/tech/gscl45nm"
add_source -type vhdl -work work uart_tx_top.vhd
add_constraint_file uart_constraints.sdc
set_top_module uart_tx_top
elaborate
compile -incremental_mapping
report_area -file reports/area.rpt
report_timing -delay max -num_paths 50 -file reports/timing.rpt
export_netlist -format verilog -output gate/uart_tx_netlist.v
write_sdf -output gate/uart_tx.sdf
exit
```

## E.7 Gate-Level Simulation

```tcl
# run_gls_uart.do
vlib work_gate
vlog -work work_gate /tech_lib/gscl45nm.v
vlog -work work_gate gate/uart_tx_netlist.v
vcom -2008 -work work_gate tb_uart_tx.vhd

vsim -t ps -sdf /tb_uart_tx/dut=gate/uart_tx.sdf work_gate.tb_uart_tx
add wave -position insertpoint sim:/tb_uart_tx/*
run 10 ms
```

## E.9 Final Report

```markdown
# UART TX Verification Report

## 1. Design Specification
[Spec from above]

## 3. RTL Design
- uart_tx_top.vhd
- Architecture: FSM + Baud Gen + Shift Reg

## 4. Verification
### 4.1 Test Plan
- 9 tests covering all functions

### 4.2 Test Results
- Total tests: 9
- Pass: 9
- Fail: 0

### 4.3 Coverage
- Functional: 98%
- Statement: 96%
- Branch: 92%
- Toggle: 100% (with exclusions)

## 5. Synthesis
- Tool: Precision RTL
- Cell library: gscl45nm
- Area: 1.5K gates (approx)
- Max clock: 250 MHz
- Slack: +1.2 ns (positive)

## 6. Gate-Level Simulation
- SDF loaded: yes
- No X propagation
- No timing violations
- Multi-corner verified

## 7. Conclusion
All checks passed. Ready for tape-out.
```

---

# ส่วนที่ F: Templates

## F.1 Verification Plan Template

```markdown
# Verification Plan: [Design Name]

## 1. Design Overview
[Brief description]

## 2. Verification Goals
- Functional coverage: ≥ X%
- Code coverage: ≥ Y%
- All assertions pass: X%
- Sign-off date: [Date]

## 3. Feature List
| ID | Feature | Priority | Verification Method |
|----|---------|----------|---------------------|
| F01 | ... | Critical | Directed |
| F02 | ... | High | Random + Coverage |

## 4. Test Plan
| Test ID | Stimulus | Expected | Pass Criteria |
|----------|----------|----------|---------------|
| T01 | ... | ... | ... |

## 5. Coverage Model
[Coverage points + cross coverage]

## 6. Tools
- Simulator: Questa
- Coverage: Questa Cover
- Synthesis: ...

## 7. Timeline
[Day | Task | Status]

## 8. Pass Criteria
- All functional tests pass
- Coverage ≥ X%
- No open critical bugs
- Documentation complete

## 9. Risk Register
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|

## 10. Sign-off
- Verifier: ____
- Designer: ____
- Date: ____
```

## F.2 Final Report Template

```markdown
# Verification Report: [Design Name]

## 1. Spec
## 2. RTL Design
## 3. Verification
### 3.1 Test Plan
### 3.2 Test Results
### 3.3 Coverage
## 4. Synthesis
## 5. Gate-Level Sim
## 6. Bugs Found
## 7. Bugs Fixed
## 8. Conclusion
## 9. Deliverables
```

## F.3 Risk Register Template

```markdown
# Risk Register: [Design Name]

| ID | Risk | Probability | Impact | Mitigation | Owner | Status |
|----|------|-------------|--------|------------|-------|--------|
| R001 | ... | High | Critical | ... | ... | Open |
| R002 | ... | Medium | High | ... | ... | Closed |
```

---

# ส่วนที่ G: Key Takeaways

## G.1 ASIC Flow

1. **Front-end**: spec, RTL, verification, synthesis, GLS
2. **Back-end**: floorplan, P&R, STA, sign-off
3. **Mini Project ครอบคลุม**: spec → RTL → TB → synth → SDF → GLS

## G.2 Verification Plan

1. **Plan before code** — ลด rework
2. **Spec-driven** — extract features from spec
3. **Coverage goals** — ชัดเจน, measurable
4. **Timeline + Resources** — realistic
5. **Sign-off criteria** — agreed ก่อนเริ่ม

## G.3 Verification Methodology

1. **Mix methods**: directed + random + formal + assertions
2. **Coverage-driven**: วัดผลโดย coverage
4. **Continuous** verification: regression tests

## G.4 Mini Project Lessons

1. **Real-world workflow**: spec → RTL → verify → synth → GLS
2. **Tool integration**: Questa + Precision
3. **Multi-corner**: typ/fast/slow
4. **Sign-off**: clear criteria, documentation

---

# ส่วนที่ H: อ้างอิง

- Bergeron, J. "Writing Testbenches: Functional Verification of HDL Models," Springer, 2003.
- Spear, P. "SystemVerilog for Verification," Springer, 2006.
- IEEE 1800-2017 SystemVerilog LRM.
- Accellera, "Universal Verification Methodology (UVM) 1.2 User's Guide," 2015.
- "Siemens EDA Questa Advanced Simulator User Manual."
- "Precision RTL Synthesis User Manual."
- "Verification Methodology Manual for SystemVerilog," Cadence Design Systems.

---

> **หมายเหตุ:** เนื้อหานี้ออกแบบให้บรรยายได้ประมาณ 90-120 นาที รวม ASCII diagrams, code examples, verification plan examples, sign-off criteria พร้อมใช้ประกอบการสอนภาคทฤษฎี Day 5 เช้า หรือแบ่งเป็น 2 mini-lectures (ASIC Flow 60 นาที + Verification Plan 60 นาที)
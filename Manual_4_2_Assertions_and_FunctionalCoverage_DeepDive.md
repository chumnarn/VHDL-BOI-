# รายละเอียดเชิงลึก: Assertions & Functional Coverage

> เนื้อหานี้ออกแบบมาให้นำไปแทรกเป็นส่วนขยายในหัวข้อ **4.2 ภาคทฤษฎี: Assertions** และ **Functional Coverage** ของคู่มือหลักสูตร (วันที่ 4)
> เหมาะสำหรับการบรรยาย 90–120 นาที

---

# ส่วนที่ A: Assertions — เชิงลึก

## A.1 Assertion คืออะไร

**Assertion** คือ **property check** ที่ฝังอยู่ใน design หรือ testbench เพื่อตรวจสอบว่า design ทำงานตามที่ spec กำหนด ถ้า property ไม่เป็นจริง simulator จะ **fire** (พิมพ์ error message)

### A.1.1 ข้อดีของ Assertion

1. **Catch bugs ใกล้จุดเกิด** — ไม่ต้อง debug ย้อนหลัง
2. **Self-documenting** — assertion = executable specification
3. **Live documentation** — always up-to-date
4. **Reduce debug time** — 50%+ เทียบกับ print-based debug
5. **Formal verification** — ใช้กับ formal tool ได้

### A.1.2 Assertion vs Testbench Check

| | Testbench Check | Assertion |
|---|---|---|
| **Location** | Testbench file | Design file |
| **Audience** | Verifier | Designer + Verifier |
| **Function** | Verify test runs | Always active |
| **Formal** | ❌ | ✅ |
| **Reuse** | Test-specific | Across all tests |
| **Examples** | `if (dout /= exp) report error;` | `assert req => ack` |

## A.2 ประเภทของ Assertion

### A.2.1 Immediate Assertion (ทันที)

ตรวจสอบ **เมื่อ statement รัน** (ใน process)

```vhdl
-- VHDL
process (a, b, sum)
begin
    assert sum <= a + b
        report "Overflow: a + b > max"
        severity failure;
end process;
```

### A.2.2 Concurrent Assertion (ต่อเนื่อง)

ตรวจสอบ **ทุก clock cycle** ในช่วงเวลาที่กำหนด

```vhdl
-- VHDL PSL
assert always
    (req = '1') -> next (ack = '1')
    report "REQ must be followed by ACK"
    severity failure;
```

```systemverilog
// SVA
property handshake;
    @(posedge clk) req |=> ##2 ack;
endproperty
assert property (handshake);
```

### A.2.3 Severity Levels

| Severity | Behavior | Use |
|---|---|---|
| `NOTE` | Information only | Debug info |
| `WARNING` | Print warning, continue | Suspicious but not error |
| `ERROR` | Print error, continue | Bug (TB should not fail sim) |
| `FAILURE` | Print error, stop sim | Critical bug |

```vhdl
assert condition
    report "message"
    severity failure;          -- or note/warning/error
```

## A.3 VHDL Immediate Assertion (รายละเอียด)

### A.3.1 ใน Process

```vhdl
process (a, b)
begin
    -- Check after assignment
    assert y = a + b
        report "Wrong sum"
        severity failure;
end process;
```

### A.3.2 Concurrent

```vhdl
-- Concurrent assertion (ตรวจอัตโนมัติ)
assert_overflow : assert not (a = '1' and b = '1' and cin = '1' and cout = '0')
                   report "Adder overflow"
                   severity failure;
```

### A.3.3 With Custom Message

```vhdl
assert req = '1' or state = IDLE
    report "REQ must be high in active state, state = " &
           state_t'image(state)
    severity failure;
```

### A.3.4 In TB with Counter

```vhdl
process
    variable pass, fail : integer := 0;
begin
    -- Test 1
    if y = '1' then
        pass := pass + 1;
    else
        fail := fail + 1;
        assert false report "y should be 1, got 0" severity note;
    end if;

    -- ...

    report "PASS=" & integer'image(pass) & " FAIL=" & integer'image(fail);
end process;
```

## A.4 PSL (Property Specification Language) — เชิงลึก

### A.4.1 PSL คืออะไร

**PSL** เป็นมาตรฐาน IEEE 1850 สำหรับ assertion ใช้ได้ทั้ง VHDL, Verilog, SystemVerilog

### A.4.2 PSL Operators

| Operator | Meaning | Example |
|---|---|---|
| `always` | Property must hold for all time | `always p` |
| `never` | Property must never hold | `never p` |
| `next` | Next cycle | `next p` |
| `next [n]` | After n cycles | `next [3] p` |
| `next [a:b]` | After a to b cycles | `next [2:5] p` |
| `->` | Implication (if-then) | `req -> ack` |
| `<->` | Equivalence | `req <-> ack` |
| `and`, `or`, `not` | Logic | `p1 and p2` |
| `until` | Until | `p until q` |
| `before` | Eventually | `req before ack` |

### A.4.3 PSL Examples

**1. Handshake (req → ack):**

```vhdl
-- Concurrent
assert_handshake : assert always
    (req = '1') -> (ack = '1')
    report "REQ must be followed by ACK in next cycle"
    severity failure;
```

**2. Handshake with delay (req → ##2 ack):**

```vhdl
assert_handshake_delayed : assert always
    (req = '1') -> next[2] (ack = '1')
    report "REQ must be followed by ACK within 2 cycles"
    severity failure;
```

**3. Range delay:**

```vhdl
-- ack must arrive between 1 and 5 cycles after req
assert_handshake_range : assert always
    (req = '1') -> next[1:5] (ack = '1')
    report "ACK must follow REQ within 1-5 cycles"
    severity failure;
```

**4. Never: เงื่อนไขที่ไม่ควรเกิด:**

```vhdl
assert_no_x : assert never (dout = 'X')
               report "Output contains X"
               severity failure;

assert_no_overflow : assert never (fifo_count > FIFO_DEPTH)
                     report "FIFO overflow"
                     severity failure;
```

**5. Until: เงื่อนไขคงอยู่:**

```vhdl
-- req must remain high until ack
assert_req_held : assert always
    (req = '1') -> (req = '1') until (ack = '1')
    report "REQ must remain high until ACK"
    severity failure;
```

### A.4.4 PSL Clock Declaration

```vhdl
-- Default clock
default clock is rising_edge(clk);

-- Or specific clock
assert property
    @(posedge clk)
    req |-> ##2 ack;
```

### A.4.5 PSL in Design (binding)

```vhdl
-- สามารถแยก assertion ออกเป็นไฟล์ bind ได้
-- File: assertions.vhd
entity my_assertions is
end entity;

architecture rtl of my_assertions is
begin
    -- ... assertions
end architecture;
```

## A.5 SVA (SystemVerilog Assertions) — เชิงลึก

### A.5.1 SVA คืออะไร

SVA เป็นส่วนหนึ่งของ SystemVerilog (IEEE 1800) ใช้เขียน assertion ได้ powerful กว่า PSL ในหลายด้าน

### A.5.2 SVA Basic Syntax

```systemverilog
// Sequence
sequence handshake_seq;
    req ##1 ack;
endsequence

// Property
property handshake_prop;
    @(posedge clk) disable iff (!rst_n)
    req |-> handshake_seq;
endproperty

// Assertion
assert property (handshake_prop)
    else $error("Handshake failed");
```

### A.5.3 Operators

| Operator | Meaning | Example |
|---|---|---|
| `##n` | Cycle delay | `req ##2 ack` (ack 2 cycles later) |
| `##[a:b]` | Range delay | `req ##[1:5] ack` |
| `|->` | Implication (overlapping) | `req \|-> ack` |
| `|=>` | Implication (non-overlapping) | `req \|=> ack` |
| `$past(expr, n)` | Value n cycles ago | `$past(data, 2) == data_now` |
| `and` | Sequence AND | `seq1 and seq2` |
| `or` | Sequence OR | `seq1 or seq2` |
| `intersect` | Common match | `seq1 intersect seq2` |
| `within` | Within window | `seq1 within seq2` |
| `throughout` | Throughout | `req throughout seq` |
| `first_match` | First match only | `first_match(seq)` |
| `[*n]` | Repetition n times | `req[*3]` (req for 3 cycles) |
| `[->n]` | Goto (n occurrences) | `req[->3] ##1 ack` (3 req before ack) |

### A.5.4 Common SVA Patterns

**1. Request-Acknowledge Handshake:**

```systemverilog
property req_ack;
    @(posedge clk) disable iff (!rst_n)
    req |=> ##[1:5] ack;
endproperty
assert property (req_ack)
    else $error("Handshake timeout");
```

**2. Data Integrity through Pipeline:**

```systemverilog
property data_integrity;
    @(posedge clk) disable iff (!rst_n)
    (valid_in) |=> ##N (valid_out && data_out == $past(data_in, N));
endproperty
```

**3. FIFO Never Full When Writing:**

```systemverilog
always @(posedge clk) begin
    if (wr_en && full)
        $error("FIFO full when wr_en asserted at %t", $time);
end
```

**4. No X in Output:**

```systemverilog
always @(posedge clk) begin
    if (|out_x_check)  // OR reduction
        $error("X detected in output");
end
```

**5. Counter Range:**

```systemverilog
property counter_range;
    @(posedge clk) disable iff (!rst_n)
    counter <= MAX_VALUE;
endproperty
assert property (counter_range);
```

**6. Mutual Exclusion:**

```systemverilog
property mutex;
    @(posedge clk) disable iff (!rst_n)
    not (req_a && req_b);  // a and b never both asserted
endproperty
```

**7. Eventually: สักวันจะเกิด:**

```systemverilog
// ตรวจว่า eventually ack จะเกิด หลังจาก req
property eventually_ack;
    @(posedge clk) disable iff (!rst_n)
    req |-> s_eventually ack;
endproperty
```

## A.6 Common Assertion Patterns (Library)

### A.6.1 FIFO Assertions

```systemverilog
// FIFO never full when wr_en
always @(posedge clk) begin
    assert (!wr_en || !full)
        else $error("FIFO full but wr_en asserted");
end

// FIFO never empty when rd_en
always @(posedge clk) begin
    assert (!rd_en || !empty)
        else $error("FIFO empty but rd_en asserted");
end

// FIFO count consistency
property count_consistency;
    @(posedge clk) disable iff (!rst_n)
    (count == $past(count) + (wr_en && !full) - (rd_en && !empty));
endproperty
assert property (count_consistency);
```

### A.6.2 Handshake Assertions

```systemverilog
// Single request → single ack
property one_ack_per_req;
    @(posedge clk) disable iff (!rst_n)
    req |-> ##1 (ack [*1:$]) ##1 !ack;
endproperty

// No request without eventual ack
property no_lost_req;
    @(posedge clk) disable iff (!rst_n)
    $rose(req) |-> s_eventually $rose(ack);
endproperty
```

### A.6.3 Reset Assertions

```systemverilog
// Reset must be high for N cycles
sequence reset_pulse;
    !rst_n[*8];  // reset low for 8 cycles
endsequence

// After reset, known state
property after_reset_known_state;
    @(posedge clk)
    $fell(rst_n) |=> !read_out && !write_out;
endproperty
```

### A.6.4 FIFO Overflow/Underflow

```systemverilog
// Overflow: write to full
always @(posedge clk) begin
    if (wr_en && count == FIFO_DEPTH)
        $error("FIFO overflow at %t", $time);
end

// Underflow: read from empty
always @(posedge clk) begin
    if (rd_en && count == 0)
        $error("FIFO underflow at %t", $time);
end
```

## A.7 Assertion Library — ตัวอย่าง

### A.7.1 VHDL Assertion Package

```vhdl
-- File: assertion_pkg.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package assertion_pkg is
    -- FIFO assertions
    procedure check_fifo_overflow(
        signal clk    : in std_logic;
        signal wr_en  : in std_logic;
        signal count  : in integer;
        constant DEPTH: in integer
    );

    -- X-detection
    procedure check_no_x(
        signal clk : in std_logic;
        signal data : in std_logic_vector
    );

    -- Handshake timeout
    procedure check_handshake(
        signal clk   : in std_logic;
        signal req   : in std_logic;
        signal ack   : in std_logic;
        constant MAX_CYCLES : in integer
    );
end package;
```

### A.7.2 Reusable Bind

```vhdl
-- File: fifo_assertions.vhd
entity fifo_assertions is
    generic (
        DEPTH : integer := 16
    );
    port (
        clk   : in std_logic;
        wr_en : in std_logic;
        rd_en : in std_logic;
        full  : in std_logic;
        empty : in std_logic;
        count : in integer
    );
end entity;

architecture rtl of fifo_assertions is
begin
    -- Bind to FIFO instance
    assert_no_underflow : assert never (rd_en = '1' and empty = '1')
                          report "FIFO underflow"
                          severity failure;

    assert_no_overflow : assert never (wr_en = '1' and full = '1')
                         report "FIFO overflow"
                         severity failure;
end architecture;
```

## A.8 Tools สำหรับ Assertion

### A.8.1 Questa

```tcl
# Enable PSL assertions
vsim -psl work.design

# Coverage report
vcover report -details cov.ucdb

# Assertion in Questa SVA/PSL
```

### A.8.2 Static + Dynamic Checking

- **Compile-time**: lint (verible, SpyGlass)
- **Runtime**: simulation (Questa)
- **Formal**: proof (JasperGold, Questa Formal)

### A.8.3 Open-Source

- **Verible**: VHDL/Verilog lint
- **SymbiYosys**: Open-source formal

## A.9 Assertion Best Practices

### A.9.1 Design Level

| Pattern | Why |
|---|---|
| ✅ ทุก FIFO มี overflow/underflow check | Bug detection |
| ✅ ทุก handshake มี timeout | Catch deadlocks |
| ✅ ทุก output ไม่มี X | Synthesis check |
| ✅ ทุก state machine มี valid state check | Catch illegal states |
| ✅ ทุก counter มี range check | Overflow |
| ✅ ทุก mutual exclusion (mutex) | Race conditions |

### A.9.2 Severity ที่เหมาะสม

| Use | Severity |
|---|---|
| Bug ที่ทำให้ design fail | `failure` |
| Bug ที่อาจเกิดใน corner case | `error` |
| Suspicious แต่ไม่ผิด | `warning` |
| Debug info | `note` |

### A.9.3 Naming Convention

```vhdl
-- ใช้ชื่อที่บอกได้ว่า property อะไร
assert_req_ack_handshake : assert ...
assert_no_x_output : assert ...
assert_fifo_overflow : assert ...
```

---

# ส่วนที่ B: Functional Coverage — เชิงลึก

## B.1 Functional Coverage คืออะไร

**Functional coverage** วัดว่า **functional scenarios** ตาม spec ได้รับการทดสอบครบหรือไม่ — ต่างจาก code coverage ที่วัดว่า code รัน

### B.1.1 Code Coverage vs Functional Coverage

| Aspect | Code Coverage | Functional Coverage |
|---|---|---|
| **What** | Lines, branches executed | Features tested |
| **Defined by** | Tool (auto) | User (manual) |
| **Goal** | ≥ 95% line | 100% features |
| **Examples** | if-then executed | Pattern "101" tested |

### B.1.2 ตัวอย่าง

```vhdl
-- Code coverage: 100% (if-then-else executed)
-- Functional coverage: 50% (เฉพาะ "ADD" tested, "SUB" ไม่ได้ test)
process (a, b, op)
begin
    if op = "00" then
        result <= a + b;       -- branch 1
    else
        result <= a - b;       -- branch 2
    end if;
end process;
```

### B.1.3 ทำไม Functional Coverage สำคัญ

1. **High code coverage ≠ correct design** — code อาจ run ครบ แต่ logic ผิด
2. **Spec compliance** — ตรวจว่า test ครอบคลุม functional requirements
3. **Bug detection** — corner case ที่ test ไม่ครอบคลุม = potential bug

## B.2 Functional Coverage ใน SystemVerilog

### B.2.1 Covergroup

```systemverilog
covergroup cg_alu @(posedge clk);
    // Coverpoint: ค่า ALU operation
    cp_op : coverpoint op {
        bins add = {2'b00};
        bins sub = {2'b01};
        bins and_op = {2'b10};
        bins or_op  = {2'b11};
    }

    // Coverpoint: ขอบเขตของ input
    cp_a : coverpoint a {
        bins zero  = {8'h00};
        bins max   = {8'hFF};
        bins mid   = {[8'h01:8'hFE]};
    }

    // Cross: ทุก combination
    cx_op_a : cross cp_op, cp_a;
endgroup
```

### B.2.2 Coverpoint Bins

```systemverilog
cp_data : coverpoint data {
    // Explicit bins
    bins low  = {8'h00};
    bins med  = {8'h55};
    bins high = {8'hFF};

    // Range bins
    bins lower    = {[8'h00:8'h3F]};
    bins middle   = {[8'h40:8'h7F]};
    bins higher   = {[8'h80:8'hBF]};
    bins highest  = {[8'hC0:8'hFF]};

    // Default bin
    bins others = default;

    // Transition bins
    bins trans = (0 => 1), (1 => 2), (2 => 0);

    // Illegal bins (ต้องไม่เกิด)
    illegal_bins bad = {8'h13};

    // Ignore bins (ไม่นับ)
    ignore_bins dontcare = {8'h00, 8'hFF};
}
```

### B.2.3 Cross Coverage

```systemverilog
// Cross: ทุก combination ของ 2 coverpoints
cx : cross cp_op, cp_a {
    // Bin cross
    bins add_zero = binsof(cp_op.add) && binsof(cp_a.zero);
    bins sub_zero = binsof(cp_op.sub) && binsof(cp_a.zero);

    // Ignore cross
    ignore_bins others = binsof(cp_a) intersect {[8'h00:8'h0F]};
}
```

### B.2.4 Transition Coverage

```systemverilog
// FSM state transition
cp_state : coverpoint state {
    bins idle_to_run  = (IDLE => RUN);
    bins run_to_done  = (RUN => DONE);
    bins done_to_idle = (DONE => IDLE);
    bins idle_to_idle = (IDLE => IDLE);
    bins run_to_run   = (RUN => RUN);
}
```

### B.2.5 Sampling Event

```systemverilog
covergroup cg_x @(posedge clk);  // sample ทุก clock
    cp_x : coverpoint x;
endgroup

// หรือเรียก sample() manually
covergroup cg_y;
    cp_y : coverpoint y;
endgroup

cg_y_inst = new();
always @(posedge clk) begin
    cg_y_inst.sample();
end
```

## B.3 Functional Coverage ใน VHDL (Workaround)

VHDL ไม่มี covergroup ในตัว ต้อง implement เอง

### B.3.1 Pattern 1: Bit Vector Tracking

```vhdl
architecture sim of tb_with_coverage is
    -- Coverage array (1 bit per scenario)
    constant NUM_SCENARIOS : integer := 16;
    signal covered : bit_vector(NUM_SCENARIOS-1 downto 0) := (others => '0');

    signal cov_pct : integer := 0;
begin
    ----------------------------------------------------------
    -- Coverage tracking process
    ----------------------------------------------------------
    coverage : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                covered <= (others => '0');
            else
                -- Mark scenarios
                if state = IDLE then
                    covered(0) <= '1';
                elsif state = RUN then
                    covered(1) <= '1';
                elsif state = DONE then
                    covered(2) <= '1';
                end if;

                -- State transitions
                if state_prev = IDLE and state = RUN then
                    covered(8) <= '1';
                elsif state_prev = RUN and state = DONE then
                    covered(9) <= '1';
                end if;
            end if;
        end if;
    end process;

    -- Calculate coverage percentage
    process (covered)
        variable cnt : integer := 0;
    begin
        for i in covered'range loop
            if covered(i) = '1' then
                cnt := cnt + 1;
            end if;
        end loop;
        cov_pct <= (cnt * 100) / covered'length;
    end process;
end architecture;
```

### B.3.2 Pattern 2: Counter-based

```vhdl
architecture sim of tb_counter_cov is
    signal cnt_add  : integer := 0;
    signal cnt_sub  : integer := 0;
    signal cnt_and_op : integer := 0;
    signal cnt_or_op  : integer := 0;
    signal total_tests : integer := 0;
    signal cov_pct : integer := 0;
begin
    coverage : process
    begin
        -- Wait for test to complete
        wait until done = '1';

        -- Mark which op was tested
        if op = "00" then
            cnt_add <= cnt_add + 1;
        elsif op = "01" then
            cnt_sub <= cnt_sub + 1;
        elsif op = "10" then
            cnt_and_op <= cnt_and_op + 1;
        elsif op = "11" then
            cnt_or_op <= cnt_or_op + 1;
        end if;

        total_tests <= total_tests + 1;
    end process;
end architecture;
```

### B.3.3 Pattern 3: SystemVerilog Covergroup (mixed-language)

ใช้ SystemVerilog covergroup ในไฟล์แยก แล้วเชื่อมกับ VHDL DUT ผ่าน module instantiation:

```systemverilog
// File: tb_cover.sv
module tb_cover (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [1:0]  op,
    input  logic [7:0]  a, b
);

    covergroup cg_alu @(posedge clk);
        cp_op : coverpoint op {
            bins add = {2'b00};
            bins sub = {2'b01};
            bins and_op = {2'b10};
            bins or_op  = {2'b11};
        }
        cp_a : coverpoint a {
            bins zero  = {8'h00};
            bins ff    = {8'hFF};
            bins mid   = {[8'h01:8'hFE]};
        }
        cx_op_a : cross cp_op, cp_a;
    endgroup

    cg_alu cg_inst = new();
endmodule
```

ใน VHDL testbench:
```vhdl
-- Instantiate SystemVerilog covergroup
u_cover : entity work.tb_cover
    port map (clk, rst_n, op, a, b);
```

### B.3.4 Pattern 4: Questa Coverage API

ใช้ built-in coverage functions:

```tcl
# In do-file
coverage save -onexit cov.ucdb
coverage attribute -name TEST_STATUS -value PASS
```

## B.4 Coverage Models Best Practices

### B.4.1 Covergroup Design

| Rule | Example |
|---|---|
| ✅ One covergroup per module | `cg_alu`, `cg_uart`, `cg_memory` |
| ✅ Coverpoint per important signal | op, addr, data, enable |
| ✅ Cross for important interactions | op × data, addr × op |
| ✅ Bins ที่มีความหมาย | "Baud rate 115200", "Reset active" |
| ✅ Illegal bins for spec violations | "Both fifo_full and wr_en" |
| ✅ Ignore bins for irrelevant values | "Reserved codes" |

### B.4.2 Bins Strategy

```systemverilog
// ❌ BAD: Auto-bins
cp_data : coverpoint data;  // 256 bins

// ✅ GOOD: Manual bins
cp_data : coverpoint data {
    bins zero  = {8'h00};
    bins low   = {[8'h01:8'h3F]};
    bins med   = {[8'h40:8'h7F]};
    bins high  = {[8'h80:8'hBF]};
    bins max   = {8'hFF};
}
```

**Auto-bins = 256 bins** แต่ manual = 5-10 bins → cover faster, focused

### B.4.3 Coverage Goals

| Category | Goal |
|---|---|
| Critical features | 100% |
| Major features | ≥ 95% |
| Minor features | ≥ 80% (or justify) |
| Edge cases | 100% |

## B.5 Coverage-Driven Verification Flow

```
   1. Spec → Feature List
                │
                ▼
   2. Feature List → Coverage Model
                │
                ▼
   3. Coverage Model → Test Plan
                │
                ▼
   4. Test Plan → Testbench + Tests
                │
                ▼
   5. Run → Coverage Report
                │
                ▼
   6. Coverage Gaps → New Tests
                │
                ▼ (iterate)
   7. Coverage Goals Met → Sign-off
```

### B.5.1 Practical Workflow

```tcl
# 1. Compile
vcom -2008 dut.vhd
vlog dut_tb.sv

# 2. Enable coverage
vsim -coverage work.tb_dut

# 3. Run test
run 1 ms

# 4. Save coverage
coverage save -onexit cov.ucdb

# 5. Generate report
vcover report -details -output cov.html cov.ucdb

# 6. View in GUI
# Tools → Coverage Report
```

## B.6 Functional Coverage ใน Questa

### B.6.1 Questa Cover Flow

```
   ┌──────────────────────────────────┐
   │  Compile with coverage           │
   │  vsim -coverage                  │
   └────────────┬─────────────────────┘
                │
                ▼
   ┌──────────────────────────────────┐
   │  Run test                        │
   │  run 1 ms                        │
   └────────────┬─────────────────────┘
                │
                ▼
   ┌──────────────────────────────────┐
   │  Save UCDB                       │
   │  coverage save -onexit cov.ucdb  │
   └────────────┬─────────────────────┘
                │
                ▼
   ┌──────────────────────────────────┐
   │  Generate HTML report            │
   │  vcover report cov.ucdb          │
   └──────────────────────────────────┘
```

### B.6.2 Common Commands

```tcl
# Save coverage
coverage save -onexit cov.ucdb

# Load for analysis
vsim -viewcov cov.ucdb

# Generate report
vcover report -details -annotate -output cov.html cov.ucdb

# Merge multiple runs
vcover merge -output merged.ucdb run1.ucdb run2.ucdb
```

### B.6.3 GUI: Coverage Window

- `View → Coverage` → Browse
- Shows: % covered, uncovered bins, hierarchy

## B.7 Coverage Closure Strategies

### B.7.1 Strategy 1: Random + Constraints

```systemverilog
// Tighten constraints to hit specific bins
constraint hit_baud_115200 {
    baud_rate dist {115_200 := 80, 9600 := 10, 19200 := 10};
}
```

### B.7.2 Strategy 2: Directed Tests

```systemverilog
// Hand-written tests for hard-to-reach cases
task test_reset_during_tx();
    // Force reset while UART is transmitting
    send_byte(0x55);
    assert(rst_n == '1');
    // Verify back to IDLE cleanly
endtask
```

### B.7.3 Strategy 3: Force/Poke

```systemverilog
// Force internal state to reach specific scenario
force dut.fifo_count = 15;  // 1 slot from full
run 1 cycle;
release dut.fifo_count;
```

### B.7.4 Strategy 4: Cross-bin Targeting

```systemverilog
// Direct generator for specific cross
task gen_add_zero();
    op = 2'b00;  // ADD
    a = 8'h00;
    b = 8'h00;
endtask
```

## B.8 Coverage Analysis Tools

### B.8.1 Questa

```tcl
# Open coverage viewer
vsim -viewcov cov.ucdb

# Generate HTML
vcover report -details -output cov_report.html cov.ucdb
```

### B.8.2 IMCS (Integrated Metrics)

- Excluding bins (e.g., reset logic)
- Cross-coverage analysis
- Hierarchical view

### B.8.3 Verdi (Synopsys)

- Coverage-driven debug
- Tied to assertion failures

## B.9 Real-World Coverage Example

### B.9.1 UART TX Coverage Model

```systemverilog
covergroup cg_uart_tx @(posedge clk);
    // Baud rate coverage
    cp_baud : coverpoint baud_sel {
        bins b9600   = {0};
        bins b19200  = {1};
        bins b115200 = {2};
    }

    // Data value coverage
    cp_data : coverpoint tx_data {
        bins zero  = {8'h00};
        bins ff    = {8'hFF};
        bins alt1  = {8'h55, 8'hAA};
        bins corner = {[8'h01:8'h0F]};
        bins other  = default;
    }

    // Frame-related state coverage
    cp_state : coverpoint state {
        bins idle  = {IDLE};
        bins start = {START};
        bins data  = {DATA};
        bins stop  = {STOP};
    }

    // Transitions
    cp_state_trans : coverpoint state {
        bins idle_start = (IDLE => START);
        bins start_data = (START => DATA);
        bins data_stop  = (DATA => STOP);
        bins stop_idle  = (STOP => IDLE);
    }

    // Cross
    cx_baud_data : cross cp_baud, cp_data;
    cx_state_baud : cross cp_state, cp_baud;
endgroup
```

### B.9.2 Coverage Goals (UART TX)

| Coverage | Target | Method |
|---|---|---|
| All baud rates | 100% | Constrained random |
| All data values | 100% | Random |
| All states | 100% | Random + reset during |
| All transitions | 100% | Random |
| Cross (baud × data) | ≥ 90% | Random |
| Edge case (back-to-back) | 100% | Directed |

## B.10 Coverage vs Functional Coverage vs Formal

| | Code Coverage | Functional Coverage | Formal |
|---|---|---|---|
| **Tool** | Simulator | Simulator (or SV) | Formal tool |
| **What** | Lines, branches | Features | Properties |
| **Proves** | Code executed | Feature tested | Property holds |
| **Speed** | Fast (per sim) | Fast | Slow (exponential) |
| **Coverage Goal** | 95%+ | 100% critical | All proven |
| **Excludes** | Reset, debug code | Irrelevant features | Environment assumptions |

## B.11 Coverage Best Practices Summary

### B.11.1 Model Design

| Rule | Reason |
|---|---|
| ✅ Covergroups per module | Modular |
| ✅ Coverpoint per important signal | Coverage |
| ✅ Cross for interactions | Combined coverage |
| ✅ Meaningful bins | Don't over-binning |
| ✅ Illegal bins for spec violations | Catch bad behavior |
| ✅ Ignore bins for irrelevant | Don't waste effort |

### B.11.2 Workflow

| Rule | Reason |
|---|---|
| ✅ Define coverage before TB | Plan-driven |
| ✅ Aim for 100% functional coverage | Completeness |
| ✅ Don't rely on code coverage alone | Doesn't catch logic bugs |
| ✅ Close coverage gaps iteratively | Systematic |
| ✅ Use multiple methods (random + directed + formal) | Coverage |

## B.12 Tools

### B.12.1 Siemens EDA

- **Questa Cover**: Code + functional coverage
- **Questa Formal**: Formal verification

### B.12.2 Cadence

- **Xcelium + IMC**: Coverage analysis
- **JasperGold**: Formal

### B.12.3 Synopsys

- **VCS + Verdi**: Coverage
- **Formality**: Equivalence

### B.12.4 Open-Source

- **Verilator + gcov**: Code coverage
- **SymbiYosys**: Formal

---

# ส่วนที่ C: Combined Flow

## C.1 Modern Verification Stack

```
   ┌─────────────────────────────────────┐
   │   Spec                              │
   └────────────┬────────────────────────┘
                │
                ▼
   ┌─────────────────────────────────────┐
   │   Verification Plan                 │
   │   - Features                        │
   │   - Coverage Model                  │
   │   - Test Plan                       │
   └────────────┬────────────────────────┘
                │
                ▼
   ┌─────────────────────────────────────┐
   │   Testbench:                        │
   │   - Stimulus (random + directed)    │
   │   - Scoreboard                      │
   │   - Reference Model                 │
   │   - Assertions (PSL/SVA)            │
   │   - Functional Coverage             │
   └────────────┬────────────────────────┘
                │
                ▼
   ┌─────────────────────────────────────┐
   │   Run → Coverage Analysis          │
   └────────────┬────────────────────────┘
                │
                ▼
   ┌─────────────────────────────────────┐
   │   Iterate until goals met           │
   └─────────────────────────────────────┘
```

## C.2 Combined Example: UART TX

```systemverilog
// 1. Assertions
property req_ack_handshake;
    @(posedge clk) disable iff (!rst_n)
    din_vld && din_rdy |=> !din_rdy until tx_done;
endproperty

// 2. Functional coverage
covergroup cg_uart_tx @(posedge clk);
    cp_baud : coverpoint baud_sel { ... };
    cp_data : coverpoint tx_data { ... };
    cx_baud_data : cross cp_baud, cp_data;
endgroup

// 3. Testbench
class uart_tx_tb;
    // Generator
    // Driver
    // Monitor
    // Scoreboard
    // Coverage
endclass
```

## C.3 Key Takeaways

1. **Assertions** = property checks for design
2. **PSL/SVA** = powerful property languages
3. **Functional coverage** = measure of spec compliance
4. **Coverage-driven** = systematic verification
5. **Mix methods**: directed + random + formal + assertions
6. **Sign-off criteria**: 100% functional coverage of critical features
7. **Iterate** until coverage goals met

## C.4 Summary Comparison

| Methodology | Strength | When |
|---|---|---|
| **Immediate assert** | Simple checks | TB sanity |
| **PSL assert** | VHDL-native | Concurrent checks |
| **SVA assert** | Powerful, complex properties | Comprehensive |
| **Functional coverage** | Spec compliance | Modern TB |
| **Code coverage** | Bug detection (low-hanging) | Default measure |
| **Formal** | Exhaustive proof | Critical blocks |

## C.5 อ้างอิง

- IEEE 1850-2010, "Standard for Property Specification Language (PSL)."
- IEEE 1800-2017 SystemVerilog LRM, Section 16 (Assertions), 19 (Coverage).
- "Siemens EDA Questa Advanced Simulator User Manual" — Assertions, Coverage.
- "Cadence JasperGold User Manual" — Formal Verification.
- Bergeron, J. "Verification Methodology Manual for SystemVerilog," Springer, 2005.
- Spear, P. "SystemVerilog for Verification," Springer, 2006.

---

> **หมายเหตุ:** เนื้อหานี้ออกแบบให้บรรยายได้ประมาณ 90-120 นาที รวม ASCII diagrams, code examples (PSL, SVA, VHDL workaround, SystemVerilog covergroup) พร้อมใช้ประกอบการสอนภาคทฤษฎี Day 4 เย็น หรือแบ่งเป็น 2 mini-lectures (Assertions 60 นาที + Functional Coverage 60 นาที)
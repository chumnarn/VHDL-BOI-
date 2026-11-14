# รายละเอียดเชิงลึก: Verification Methodology

> เนื้อหานี้ออกแบบมาให้นำไปแทรกเป็นส่วนขยายในหัวข้อ **4.1 ภาคทฤษฎี: Verification Methodology** ของคู่มือหลักสูตร (วันที่ 4)
> เหมาะสำหรับการบรรยาย 90–120 นาที

---

## 1. ทำไม Verification ถึง Hard?

### 1.1 ความท้าทายของ Verification

ในการออกแบบ IC สมัยใหม่:
- **Design size**: 1 billion transistors ขึ้นไป (Apple M2 Ultra = 134 billion!)
- **Verification complexity**: exponential ตาม state space

```
   State space = 2^(# state bits)
   
   Example: 16-bit counter → 2^16 = 65,536 states
            32-bit register → 2^32 = 4.29 × 10^9 states
            CPU with 2M FF  → 2^2,000,000 (ไม่สามารถ exhaustive verify!)
```

**สาเหตุที่ verification ยาก:**

1. **State space explosion** — จำนวน state เพิ่มขึ้นแบบ exponential
2. **Corner cases** — rare combination ที่อาจทำให้ bug
3. **Protocol compliance** — ต้องตรงตามมาตรฐาน (AXI, PCIe, USB, ...)
4. **Race conditions** — bugs ที่เกิดเฉพาะ timing เฉพาะ
5. **Power-aware** — bugs ที่เกิดใน specific power state
6. **Clock interactions** — CDC, glitch

### 1.2 Verification Cost

| Phase | Cost | % of Total Project |
|---|---|---|
| Design | $$ | 30-40% |
| **Verification** | $$$ | **50-70%** |
| Physical Design | $$ | 15-20% |
| Software | $$ | 10-15% |

**Tape-out without verification = recall / failure in silicon**

ตัวอย่าง:
- Intel Pentium FDIV bug (1994): $475M recall
- Samsung Galaxy Note 7 (2016): $5.3B recall
- Apple iPhone 4 antenna (2010): $1.5B settlement

---

## 2. Verification Levels — เชิงลึก

### 2.1 Verification Pyramid

```
              ┌──────────────────────────┐
              │   Chip-Level (SoC)       │  ← Highest coverage requirement
              ├──────────────────────────┤
              │   Subsystem / Block      │  ← Pre-defined specs
              ├──────────────────────────┤
              │   Module / Unit (IP)     │  ← Designers verify own work
              └──────────────────────────┘
              
              ⏬
              
              ┌──────────────────────────┐
              │  Post-Silicon Validation │  ← Real silicon
              └──────────────────────────┘
```

### 2.2 Module/Unit Level

**Objective:** ตรวจสอบ IP block เดี่ยวทำงานถูกต้องตาม IP-level spec

**เทคนิค:**
- Directed testing (specific patterns)
- Self-checking testbench
- Reference model comparison
- Functional coverage ของ features

**Tools:**
- Questa Advanced Simulator
- ModelSim
- GHDL (open-source)

**Typical coverage:**
- Code coverage: 100% (line/branch/condition)
- Functional coverage: > 95%
- Assertion coverage: 100% pass

### 2.3 Subsystem/Block Level

**Objective:** ตรวจสอบการ integrate ระหว่าง IP blocks

**สิ่งที่ตรวจ:**
- Interface protocol (e.g., AXI handshakes)
- Data flow ระหว่าง blocks
- Timing relationships
- Interrupt propagation
- Reset propagation

**เทคนิค:**
- Constrained random stimulus
- Scoreboard (transaction-level)
- Assertions (SVA/PSL)
- Formal verification สำหรับ specific properties

### 2.4 Chip-Level (SoC)

**Objective:** ตรวจสอบการ integrate ทุก IP, boot sequence, power management

**Challenges:**
- Long simulation runtime (days to weeks)
- Complex reset/power sequences
- Multiple clock domains
- Software bring-up

**เทคนิค:**
- Emulation (Cadence Palladium, Synopsys ZeBu)
- FPGA prototyping (S2C, Synopsys HAPS)
- Acceleration (HW + SW co-simulation)
- Post-silicon validation

### 2.5 Post-Silicon Validation

**Objective:** Verify chip จริงบน board/board-bring-up

**Challenges:**
- Late bugs (post-tapeout)
- Limited observability (internal signals)
- Speed (real-time)
- Manufacturing variation

**Techniques:**
- Built-in Self-Test (BIST)
- Scan chains
- Trace macros (Intel Processor Trace, ARM CoreSight)
- Performance counters

---

## 3. Verification Methodology — เชิงลึก

### 3.1 Directed Testing

**Concept:** เขียน test เฉพาะสำหรับแต่ละ scenario

```vhdl
-- Direct test: "after reset, write 0x55 to register, verify read back 0x55"
stim : process
begin
    -- Reset
    rst_n <= '0'; wait for 100 ns;
    rst_n <= '1';

    -- Write
    wr_en <= '1'; wr_data <= x"55"; wait for 10 ns;
    wr_en <= '0';

    -- Read
    wait for 10 ns;
    rd_en <= '1'; wait for 10 ns;
    assert rd_data = x"55"
        report "Direct test fail"
        severity error;
end process;
```

**ข้อดี:**
- ✅ Deterministic
- ✅ Debug ง่าย
- ✅ เหมาะ corner case

**ข้อเสีย:**
- ⚠️ ใช้เวลาเขียนมาก
- ⚠️ ไม่ scale สำหรับ design ใหญ่
- ⚠️ อาจ miss unexpected scenarios

### 3.2 Random Testing

**Concept:** สุ่มค่า input โดยไม่มี constraint

```vhdl
stim : process
    variable seed : integer := 42;
begin
    for trial in 0 to 9999 loop
        uniform(seed, real_val);
        din <= std_logic_vector(to_unsigned(integer(real_val * 1024.0), 10));
        wait until rising_edge(clk);
    end loop;
end process;
```

**ข้อดี:**
- ✅ ค้นหา unexpected bugs
- ✅ เขียนง่าย
- ✅ Coverage improvement

**ข้อเสีย:**
- ⚠️ Coverage inefficient (อาจสุ่มซ้ำ)
- ⚠️ Debug ยาก
- ⚠️ ต้องมี checker ที่ดี

### 3.3 Constrained Random Testing

**Concept:** สุ่มแต่มี constraint ตาม spec

```systemverilog
class transaction;
    rand bit [7:0] addr;
    rand bit [31:0] data;
    rand bit we;

    constraint valid_addr {
        addr inside {[8'h16:24], [8'h40:48]};  // valid addresses
    }

    constraint reasonable_data {
        data dist {0 := 20, [1:255] := 60, [256:16'hFFFFFFFF] := 20};
    }
endclass
```

**ข้อดี:**
- ✅ ครอบคลุม valid scenarios
- ✅ เขียน constraint แค่ครั้งเดียว
- ✅ Coverage-driven

**ข้อเสีย:**
- ⚠️ ต้องมี reference model/checker
- ⚠️ Learning curve

### 3.4 Coverage-Driven Verification (CDV)

**Concept:** ใช้ coverage metric เป็นตัวนำทาง testbench

```
   ┌─────────────────────────────────────────────────┐
   │ Spec → Features → Coverage Model → Test Plan    │
   └─────────────────────────────────────────────────┘
                          │
                          ▼
   ┌─────────────────────────────────────────────────┐
   │ Testbench: random + checker + coverage sampler  │
   └─────────────────────────────────────────────────┘
                          │
                          ▼
   ┌─────────────────────────────────────────────────┐
   │ Run → Coverage Report → Identify Gaps           │
   └─────────────────────────────────────────────────┘
                          │
                          ▼
   ┌─────────────────────────────────────────────────┐
   │ Add constraints/tests to cover gaps → Re-run    │
   └─────────────────────────────────────────────────┘
                          │
                          ▼ (iterate)
   ┌─────────────────────────────────────────────────┐
   │ Coverage goals achieved → DONE                  │
   └─────────────────────────────────────────────────┘
```

**Verification flow ตัด:**

1. **Define coverage goals** (เช่น 95% line coverage, 100% functional coverage ของ critical features)
2. **Build testbench** with random stimulus + checker
3. **Run simulation** with coverage collection
4. **Analyze coverage gaps**
5. **Add targeted tests** or refine constraints
6. **Repeat** until goals met

### 3.5 UVM (Universal Verification Methodology)

**Concept:** Standard verification methodology ใช้ SystemVerilog classes

**Key components:**
- **Driver**: ส่ง transaction ไป DUT
- **Monitor**: สังเกต DUT output
- **Scoreboard**: ตรวจสอบ transactions
- **Coverage collector**: รวบรวม functional coverage
- **Sequencer**: จัดลำดับ stimulus

**Architecture:**

```
   ┌──────────┐
   │ Sequence │
   └────┬─────┘
        ▼
   ┌──────────┐
   │Sequencer │
   └────┬─────┘
        ▼
   ┌──────────┐    ┌─────────┐    ┌──────────┐
   │ Driver   │───►│   DUT   │───►│ Monitor  │
   └──────────┘    └─────────┘    └────┬─────┘
                                       ▼
                                   ┌──────────┐
                                   │Scoreboard│
                                   └──────────┘
                                        ▲
                                        │
                                   ┌──────────┐
                                   │Reference │
                                   │  Model   │
                                   └──────────┘
```

**Note:** UVM ใช้ SystemVerilog ไม่ใช่ VHDL — แต่สามารถผสมได้ (VHDL DUT + SV testbench)

---

## 4. Verification Plan

### 4.1 Verification Plan Components

**1. Feature List**

```markdown
| Feature | Description | Priority | Owner |
|---|---|---|---|
| Reset | Active-low sync reset | High | Alice |
| | | | |
| TX Frame | 8-N-1 UART | High | Bob |
| Baud rate | 115200 | Medium | Bob |
| FIFO buffer | 16 bytes | Medium | Charlie |
| Interrupt | TX done | Low | Alice |
```

**2. Test Plan**

| Test | Description | Stimulus Type |
|---|---|---|
| Reset test | Assert reset, check defaults | Directed |
| Frame test | Send known byte, verify | Directed |
| Back-to-back | Send 2 bytes back-to-back | Directed |
| Corner: all 0 | Send 0x00 | Directed |
| Corner: all 1 | Send 0xFF | Directed |
| Random | Send 1000 random bytes | Random |
| Stress | Send continuously for 1 sec | Constrained random |

**3. Coverage Goals**

| Metric | Goal |
|---|---|
| Line coverage | ≥ 95% |
| Branch coverage | ≥ 90% |
| Toggle coverage | 100% (every FF flips) |
| Functional coverage | ≥ 95% |
| Assertion coverage | 100% pass |

**4. Tools**

- Simulator: Questa Advanced Simulator
- Coverage tool: Questa Cover
- Formal: JasperGold or Questa Formal
- Assertion: SVA / PSL

**5. Timeline**

| Week | Tasks |
|---|---|
| 1 | TB architecture, basic directed tests |
| 2 | Random tests, basic functional coverage |
| 3 | Coverage refinement, regression setup |
| 4 | Formal verification, corner cases |
| 5 | Final sign-off, freeze TB |

---

## 6. Testbench Architecture — เชิงลึก

### 6.1 Modern Testbench (Layered Architecture)

```
   ┌─────────────────────────────────────────────┐
   │  Test Layer (stimulus generation)           │
   │  - Test cases                               │
   │  - Scenarios                                │
   └────────────┬────────────────────────────────┘
                │
                ▼
   ┌─────────────────────────────────────────────┐
   │  Stimulus Layer (transactions)              │
   │  - Transactions (packets, frames)           │
   │  - Random generators                        │
   └────────────┬────────────────────────────────┘
                │
                ▼
   ┌─────────────────────────────────────────────┐
   │  Driver Layer                               │
   │  - Convert transaction → pin-level          │
   │  - Protocol-aware                           │
   └────────────┬────────────────────────────────┘
                │
                ▼
   ┌─────────────────────────────────────────────┐
   │  DUT (Design Under Test)                    │
   └────────────┬────────────────────────────────┘
                │
                ▼
   ┌─────────────────────────────────────────────┐
   │  Monitor Layer                              │
   │  - Capture pin-level events                 │
   │  - Convert → transactions                   │
   └────────────┬────────────────────────────────┘
                │
                ▼
   ┌─────────────────────────────────────────────┐
   │  Checker Layer                              │
   │  - Compare expected vs actual               │
   │  - Reference model                          │
   │  - Scoreboard                               │
   └────────────┬────────────────────────────────┘
                │
                ▼
   ┌─────────────────────────────────────────────┐
   │  Coverage Layer                             │
   │  - Functional coverage                      │
   │  - Code coverage                            │
   └─────────────────────────────────────────────┘
```

### 6.2 VHDL Testbench Implementation

```vhdl
-- Modern VHDL testbench architecture
entity tb_modern is
end entity;

architecture sim of tb_modern is
    -- DUT interface signals
    signal clk, rst_n : std_logic;
    signal ... : ...;

    -- Transaction record
    type transaction_t is record
        addr : unsigned(15 downto 0);
        data : unsigned(31 downto 0);
        we :  integer;
    end record;

    -- Scoreboard
    type scoreboard_t is record
        expected_q : transaction_array(0 to 255);
        head, tail : integer;
        pass_cnt, fail_cnt : integer;
    end record;
    variable scoreboard : scoreboard_t;

    -- Coverage
    type coverage_t is array (0 to 15) of std_logic;
    variable cov_state : coverage_t := (others => '0');

begin
    -- DUT
    dut : entity work.design port map (...);

    -- ============================================================
    -- Monitor Process: collect transactions
    -- ============================================================
    monitor : process (clk)
        variable trans : transaction_t;
    begin
        if rising_edge(clk) then
            -- Sample DUT output
            if dout_ready = '1' then
                trans.addr := monitored_addr;
                trans.data := monitored_data;
                -- Push to scoreboard
                push_scoreboard(trans);
            end if;
        end if;
    end process;

    -- ============================================================
    -- Checker Process: compare expected vs actual
    -- ============================================================
    checker : process (clk)
        variable actual_trans : transaction_t;
    begin
        if rising_edge(clk) then
            if actual_ready = '1' then
                actual_trans := get_next_actual();
                check_transaction(actual_trans);
            end if;
        end if;
    end process;

    -- ============================================================
    -- Coverage Process
    -- ============================================================
    coverage : process (clk)
    begin
        if rising_edge(clk) then
            -- Mark coverage
            case state is
                when S0 => cov_state(0) := '1';
                when S1 => cov_state(1) := '1';
                -- ...
            end case;
        end if;
    end process;

    -- Stimulus
    stim : process
    begin
        -- Reset
        ...
        -- Directed tests
        ...
        -- Random tests
        ...
    end process;
end architecture;
```

---

## 7. Scoreboard — เชิงลึก

### 7.1 Concept

Scoreboard เก็บ **expected transactions** และ **actual transactions** แล้วเปรียบเทียบ

```
   ┌──────────────────────────────────────────────┐
   │  Stimulus ──► Expected Queue ──┐             │
   │                                │             │
   │                                ▼             │
   │                          ┌──────────┐        │
   │                          │ Score-   │        │
   │                          │  board   │        │
   │                          └────┬─────┘        │
   │                               │              │
   │  DUT ─► Monitor ─► Actual Queue ─┐           │
   │                                  │           │
   │                                  ▼           │
   │                             Match / Mismatch │
   │                             Pass / Fail      │
   └──────────────────────────────────────────────┘
```

### 7.2 Scoreboard Categories

**1. In-order Scoreboard**
- Transaction ต้องออกมา same order กับ input
- Implementation: FIFO queue

**2. Out-of-order Scoreboard**
- Transaction อาจ reorder (เช่น out-of-order execution)
- Implementation: lookup table

**3. Reorder Buffer**
- Track pending transactions, match when complete

### 7.3 VHDL In-order Scoreboard Example

```vhdl
-- ============================================================
-- In-order scoreboard for FIFO-like DUT
-- ============================================================
architecture sim of tb_fifo_scoreboard is
    constant QSIZE : integer := 16;
    type data_array is array (0 to QSIZE-1) of unsigned(7 downto 0);

    signal expected_q : data_array := (others => (others => '0'));
    signal expected_head, expected_tail : integer := 0;

    signal actual_q : data_array := (others => (others => '0'));
    signal actual_head, actual_tail : integer := 0;

    signal match_cnt, mismatch_cnt : integer := 0;

    -- Expected queue overflow/underflow flags
    signal expected_full, expected_empty : std_logic;
    signal actual_full, actual_empty : std_logic;
begin
    ----------------------------------------------------------
    -- Push expected data to queue (when input accepted)
    ----------------------------------------------------------
    push_expected : process (clk)
    begin
        if rising_edge(clk) then
            if wr_en = '1' and fifo_full = '0' then
                expected_q(expected_tail) <= wr_data;
                expected_tail <= (expected_tail + 1) mod QSIZE;
            end if;
        end if;
    end process;

    ----------------------------------------------------------
    -- Capture actual data (when output appears)
    ----------------------------------------------------------
    capture_actual : process (clk)
    begin
        if rising_edge(clk) then
            if rd_en = '1' and fifo_empty = '0' then
                actual_q(actual_tail) <= rd_data;
                actual_tail <= actual_rd + 1) mod QSIZE;
            end if;
        end if;
    end process;

    ----------------------------------------------------------
    -- Compare: when both queues have data
    ----------------------------------------------------------
    compare : process (clk)
        variable exp, act : unsigned(7 downto 0);
    begin
        if rising_edge(clk) then
            -- Pop when both have data and we want to compare
            if expected_head /= expected_tail and
               actual_head /= actual_tail and
               (do_compare = '1') then

                exp := expected_q(expected_head);
                act := actual_q(actual_head);

                if exp = act then
                    match_cnt <= match_cnt + 1;
                else
                    mismatch_cnt <= mismatch_cnt + 1;
                    report "MISMATCH: expected=0x" &
                           integer'image(to_integer(exp)) &
                           " actual=0x" &
                           integer'image(to_integer(act))
                        severity error;
                end if;

                expected_head <= (expected_head + 1) mod QSIZE;
                actual_head   <= (actual_head + 1) mod QSIZE;
            end if;
        end if;
    end process;
end architecture;
```

---

## 8. Functional Coverage — เชิงลึก

### 8.1 Coverage Types

| Type | What | Tools |
|---|---|---|
| **Code coverage** | Lines, branches, conditions | Questa Cover |
| **Toggle coverage** | Every FF flips at least once | Questa Cover |
| **FSM coverage** | Every state reached | Questa Cover |
| **Functional coverage** | User-defined features/cross | SystemVerilog covergroup, Questa |
| **Assertion coverage** | Every assertion checked | Questa |
| **Path coverage** | Every code path executed | Advanced tools |

### 8.2 Code Coverage

```
   Statement coverage:    ████████████ 95%
   Branch coverage:       ████████████ 90%
   Condition coverage:    ████████████ 88%
   Toggle coverage:       ████████████ 100%
```

**บรรลุเป้า:** ≥95% statement, ≥90% branch

### 8.3 FSM Coverage

```
   State S0:      ████ visited
   State S1:      ████ visited
   State S2:      ████ visited
   State S3:      ░░░░ NOT visited!
   Transition S0→S1:  ████ covered
   Transition S1→S2:  ████ covered
   Transition S2→S3:  ░░░░ NOT covered!
```

### 8.4 Functional Coverage (SystemVerilog)

```systemverilog
covergroup cg_uart @(posedge clk);
    cp_baud : coverpoint baud_sel {
        bins b9600   = {0};
        bins b19200  = {1};
        bins b115200 = {2};
    }

    cp_data : coverpoint tx_data {
        bins zero  = {8'h00};
        bins ff    = {8'hFF};
        bins alt   = {8'h55, 8'hAA};
        bins middle = default;
    }

    cp_parity : coverpoint parity_en {
        bins off = {0};
        bins on  = {1};
    }

    cx_baud_data : cross cp_baud, cp_data;
endgroup
```

### 8.5 Functional Coverage ใน VHDL (workaround)

VHDL ไม่มี covergroup ในตัว ต้อง implement เอง:

```vhdl
-- Coverage tracking process
coverage : process (clk)
    variable covered : bit_vector(0 to 1023) := (others => '0');
    variable cov_pct : integer;
begin
    if rising_edge(clk) then
        -- Mark specific scenarios
        if state = S_INIT then
            covered(0) := '1';
        elsif state = S_RUN then
            covered(1) := '1';
        elsif state = S_DONE then
            covered(2) := '1';
        end if;

        if data = x"00" then
            covered(3) := '1';
        elsif data = x"FF" then
            covered(4) := '1';
        end if;

        -- Report coverage periodically
        if now = SIM_END_TIME then
            cov_pct := count_ones(covered) * 100 / covered'length;
            report "Coverage: " & integer'image(cov_pct) & "%";
        end if;
    end if;
end process;
```

---

## 9. Assertion-Based Verification

### 9.1 Immediate Assertions (VHDL)

```vhdl
-- Concurrent
assert req = '1' or not gnt = '1'
    report "REQ must be asserted when GNT is high"
    severity failure;

-- In process
process (clk)
begin
    if rising_edge(clk) then
        if state = ACTIVE then
            assert counter <= MAX_COUNT
                report "Counter overflow"
                severity failure;
        end if;
    end if;
end process;
```

### 9.2 PSL (Property Specification Language)

```vhdl
-- Concurrent assertion
assert always
    (state = IDLE) -> next_event
        (state = ACTIVE)
    report "After IDLE, must transition to ACTIVE"
    severity failure;

assert never
    (fifo_count > FIFO_DEPTH)
    report "FIFO overflow"
    severity failure;
```

### 9.3 SVA (SystemVerilog Assertions)

```systemverilog
// Sequence
sequence req_ack_handshake;
    req ##1 gnt;
endsequence

// Property
property handshake_ok;
    @(posedge clk) disable iff (!rst_n)
    req |=> ##[1:3] gnt;
endproperty

assert property (handshake_ok)
    else $error("REQ must be followed by GNT within 3 cycles");
```

### 9.4 Common Assertions

```systemverilog
// No X in output
always @(posedge clk) begin
    if (out !== '0 && out !== '1)
        $error("Output contains X!");
end

// FIFO never full when wr_en asserted
always @(posedge clk) begin
    if (wr_en && full)
        $error("FIFO full when wr_en asserted");
end

// Data integrity through pipeline
property data_integrity;
    @(posedge clk) disable iff (!rst_n)
    (valid_in) |=> ##N (valid_out && data_out == $past(data_in, N));
endproperty
```

---

## 10. Formal Verification

### 10.1 Concept

**Formal verification** = mathematical proof ว่า design เหมือน spec ทุก input combination **โดยไม่ต้อง simulate**

```
   ┌──────────────┐         ┌──────────────┐
   │ Spec         │         │Implementation│
   │ (properties) │   ────► │(RTL)         │
   └──────────────┘         └──────────────┘
                                     │
                                     ▼
                            ┌──────────────┐
                            │ Formal Tool  │
                            │ (JasperGold, │
                            │Questa Formal)│
                            └──────────────┘
                                     │
                                     ▼
                            ┌──────────────┐
                            │  PROOF /     │
                            │Counter-example│
                            └──────────────┘
```

### 10.2 When to use Formal

- **Small blocks** (< 100K gates) — exhaustively provable
- **Critical properties** — security, safety
- **Corner cases** — formal ค้นหา scenarios ที่ test อาจ miss
- **Equivalence** — RTL ↔ netlist

### 10.3 Tools

| Vendor | Tool | Purpose |
|---|---|---|
| Cadence | JasperGold | Full formal platform |
| Synopsys | Formality | Equivalence checking |
| Siemens EDA | Questa Formal | Formal + property checking |
| Open source | SymbiYosys | Open-source formal |

### 10.4 Limitations

- ⚠️ **State space explosion** — formal ไม่ scale กับ large designs (>1M gates)
- ⚠️ **Complex properties** — ต้องเขียน properties ให้ถูก
- ⚠️ **Initial conditions** — ต้องระบุ initial state
- ⚠️ **Long runtime** — อาจใช้เวลาหลายชั่วโมงถึงหลายวัน

---

## 11. HW/SW Co-Verification

### 11.1 Concept

ทำ simulation ของ hardware **together** กับ software (firmware)

```
   ┌─────────────────┐     ┌─────────────────┐
   │   Hardware      │     │   Software      │
   │   (RTL/Netlist) │◄───►│   (C/Firmware)  │
   │                 │     │                 │
   │  Simulator      │     │  ISS or Native  │
   └─────────────────┘     └─────────────────┘
```

### 11.2 Co-Simulation Approaches

**1. Instruction Set Simulator (ISS)**

- ใช้ ISS (e.g., Spike for RISC-V) แทน CPU RTL
- เร็วกว่า full RTL simulation
- เหมาะสำหรับ driver/firmware development**

**3. Emulation**

- Run RTL บน emulator (Palladium, ZeBu)
- เร็วกว่า simulation 100-1000×
- เหมาะสำหรับ system-level test

**4. FPGA Prototyping**

- Map design ไป FPGA
- Speed: real-time หรือใกล้เคียง
- เหมาะสำหรับ software bring-up

---

## 12. Acceleration: Emulation และ Prototyping

### 12.1 Emulation

**Concept:** ใช้ hardware emulator รัน RTL ที่ MHz speed (1000× faster than sim)

| Tool | Vendor | Use Case |
|---|---|---|
| Palladium | Cadence | Enterprise SoC |
| ZeBu | Synopsys | High-speed emulation |
| Protium | Synopsys | Low-cost emulation |

**Pros:**
- เร็วมาก (MHz range)
- Run real software

**Cons:**
- ราคาสูง ($1-10M)
- Compile time นาน

### 12.2 FPGA Prototyping

**Concept:** Map design ไป FPGA development board

| Platform | FPGA | Cost | Use Case |
|---|---|---|---|
| Xilinx Virtex | VU440 | $5K-$50K | Large SoC |
| Intel Stratix | SX660 | $5K-$50K | High-performance |
| S2C | Multiple | $5K-$50K | Quick prototype |

**Pros:**
- Real-time execution
- เร็วที่สุด
- ราคาต่ำกว่า emulator

**Cons:**
- Visibility จำกัด (ใช้ JTAG/ILA)
- Debug ยากกว่า simulation

---

## 13. Verification IP (VIP)

### 13.1 Concept

**VIP** = pre-verified verification component สำหรับ industry-standard protocols

```
   ┌──────────────────────────────────────┐
   │  VIP for AXI4                        │
   │  ┌──────────┐   ┌─────────────┐      │
   │  │  Driver  │   │  Monitor    │      │
   │  └──────────┘   └─────────────┘      │
   │  ┌──────────┐   ┌─────────────┐      │
   │  │Sequencer │   │ Scoreboard  │      │
   │  └──────────┘   └─────────────┘      │
   └──────────────────────────────────────┘
            │                     │
            ▼                     ▼
      AW/AR channel           R/B channel
```

### 13.2 Common VIP

| Protocol | Vendor VIP Available |
|---|---|
| AXI4 / AXI4-Lite | Yes (Synopsys, Cadence, Siemens) |
| PCIe Gen4/5 | Yes |
| USB 3.0 | Yes |
| Ethernet (10G/100G) | Yes |
| DDR4/DDR5 | Yes |
| I2C, SPI, UART | Open-source + commercial |

### 13.3 Benefits of VIP

- ✅ Pre-verified (ลด risk)
- ✅ Standard compliance guaranteed
- ✅ Faster TB development
- ✅ Coverage included
- ⚠️ Cost (commercial VIP มี license fee)

---

## 14. Coverage Closure — เชิ้ม Closing the Gap

### 14.1 Coverage-driven Flow (ต่อ)

```
   Iteration 1: Coverage 60% → add random tests → 70%
   Iteration 2: 70% → analyze gaps → add constraints → 80%
   Iteration 3: 80% → manual tests for corners → 90%
   Iteration 4: 90% → formal for hard-to-reach states → 95%
   Iteration 5: 95% → close remaining gaps → 100% (or acceptable)
```

### 14.2 Techniques to Close Coverage

| Technique | Description |
|---|---|
| **Random with constraints** | Cover specific scenarios |
| **Targeted manual tests** | Hand-written for specific cases |
| **Formal verification** | Exhaustive for small blocks |
| **Constrained corners** | Tight constraints for hard cases |
| **Force values** | Force internal signals to reach state |
| **Back-door access** | Direct poke DUT internal state |

### 14.3 Sign-off Criteria

| Metric | Target | Status |
|---|---|---|
| Functional coverage | ≥ 95% | ☐ |
| Code coverage | ≥ 95% (statement), ≥ 90% (branch) | ☐ |
| Toggle coverage | 100% (or justification for exclude) | ☐ |
| Assertion coverage | 100% pass | ☐ |
| Formal proofs | All critical properties proven | ☐ |
| Known bugs | All closed or waived | ☐ |

---

## 15. Tools ของ Siemens EDA (รายละเอียด)

### 15.1 Questa Advanced Simulator

**Capabilities:**
- VHDL/SystemVerilog mixed simulation
- Functional coverage
- Code coverage
- Assertion-based verification
- Power-aware simulation
- Mixed-signal co-simulation
- HW/SW co-simulation

**Key commands:**

```tcl
# Coverage commands
vcover set -file cov.ucdb
vcover report -details cov.ucdb

# Assertion commands
assertion add ...

# Random/constraint
randomize ...
```

### 15.1.3 Questa Cover

- รายงาน coverage แบบ HTML
- Excluding bins (e.g., reset logic)
- Cross-coverage analysis

### 15.2 HDL Designer

- Block diagram / State diagram → VHDL
- Used for design entry (not verification)

### 15.3 Tessent (DFT)

- Scan chain insertion
- ATPG
- Memory BIST
- Logic BIST

---

## 16. Industry Trends

### 16.1 AI-Assisted Verification

- **Cadence**: AI-driven testbench generation
- **Synopsys**: AI-driven formal property generation
- **Google**: ML-based test prioritization
- **Coverage analysis**: ML identifies high-value tests

### 16.2 Portable Stimulus

**Concept:** Stimulus ที่สามารถ reuse ระหว่าง simulation, emulation, post-silicon

```
   ┌─────────────────────────────────────────────┐
   │  Portable Stimulus (Accellera standard)     │
   │  - Abstract scenario description            │
   │  - Platform-independent                     │
   │  - Generate for sim, emul, post-silicon     │
   └─────────────────────────────────────────────┘
```

### 16.3 Verification IP Ecosystem

- Standardized VIP interface
- Easier integration
- Lower cost

### 16.4 Shift-Left Testing

- Verification ย้ายไปทำ ณ design phase
- Static checks, lint, formal early
- ลด rework, time-to-market

---

## 17. Verification Plan Example — UART TX

### 17.1 Feature List

```markdown
## UART TX Features

### Reset
- [ ] Power-on reset → idle state (TX = 1)
- [ ] Sync reset clears internal state

### Frame Format
- [ ] 8-N-1 (no parity, 1 stop bit)
- [ ] Configurable baud rate: 9600, 19200, 115200
- [ ] TX line idle = 1

### Data Transmission
- [ ] Send byte → start bit (0) + 8 data bits + stop bit (1)
- [ ] MSB first or LSB first (configurable)
- [ ] Back-to-back frames

### Handshake
- [ ] din_vld/din_rdy protocol
- [ ] din_rdy de-asserted during transmission

### Interrupts
- [ ] tx_done flag when frame complete
- [ ] Error detection: frame error, overrun
```

### 17.2 Test Plan

| Test ID | Description | Stimulus | Expected |
|---|---|---|---|
| TX_001 | Reset then send 0x55 | Directed | Start=0, data=01010101, stop=1 |
| TX_002 | Reset then send 0xAA | Directed | Start=0, data=10101010, stop=1 |
| TX_003 | Back-to-back 0x55, 0xAA | Directed | Two correct frames |
| TX_004 | Send all 256 byte values | Random | All frames correct |
| TX_005 | Send 10000 random bytes | Random | All correct, latency OK |
| TX_006 | Reset during transmission | Directed | TX back to idle, no glitch |
| TX_007 | din_vld valid for 1 cycle | Directed | Byte accepted |

### 17.3 Coverage Goals

| Metric | Goal | Method |
|---|---|---|
| Statement | ≥ 95% | Questa Cover |
| Branch | ≥ 90% | Questa Cover |
| State (FSM) | 100% | Functional coverage |
| All 256 byte values | 100% | Functional coverage |
| All baud rates | 100% | Functional coverage |
| All transitions | 100% | Functional coverage |

### 17.4 Resources & Timeline

| Week | Tasks | Owner |
|---|---|---|
| 1 | TB architecture | Alice |
| 1 | Basic directed tests | Bob |
| 2 | Random stimulus | Charlie |
| 2 | Reference model | Alice |
| 3 | Coverage analysis | Bob |
| 3 | Add corner cases | Charlie |
| 4 | Formal verification | Alice |
| 4 | Regression | Bob |
| 5 | Sign-off | All |

---

## 18. Best Practices Summary

### 18.1 Testbench

| Rule | Reason |
|---|---|
| ✅ Self-checking TB | Automation |
| ✅ Reference model | Catch RTL bugs |
| ✅ Scoreboard | Transaction-level |
| ✅ Functional coverage | Measure completeness |
| ✅ Assertions (PSL/SVA) | Catch protocol violations |
| ✅ Modular structure | Reusability |

### 18.2 Verification Methodology

| Rule | Reason |
|---|---|
| ✅ Plan before coding | Avoid rework |
| ✅ Coverage-driven | Systematic |
| ✅ Reuse TB across revisions | Regression |
| ✅ Mix random + directed | Best coverage |
| ✅ Formal for critical blocks | Exhaustive proof |

### 18.3 Coverage

| Rule | Target |
|---|---|
| ✅ Statement | 95% |
| ✅ Branch | 90% |
| ✅ Toggle | 100% |
| ✅ Functional | 95%+ per feature |
| ✅ Assertion | 100% pass |

---

## 19. Summary

| Methodology | When | Pros | Cons |
|---|---|---|---|
| **Directed** | Small, well-understood | Deterministic | Doesn't scale |
| **Random** | Initial coverage | Finds unexpected bugs | Coverage inefficient |
| **Constrained Random** | Complex designs | Coverage + flexibility | Need checker |
| **Coverage-Driven** | Modern ASIC | Systematic | Setup overhead |
| **Formal** | Critical blocks | Exhaustive proof | Doesn't scale |
| **Assertion-based** | Protocols | Catch timing violations | Steep learning |
| **UVM** | Enterprise SoC | Standard, reusable | Complex |

**Best approach:** Combine methodologies:
- Directed for known corner cases
- Random + functional coverage for general coverage
- Formal for critical properties
- Assertions for protocol compliance

---

## 20. Key Takeaways

1. **Verification** = 50-70% ของ project cost
2. **State space** explosion ต้องการ systematic methodology
3. **Coverage-driven verification** เป็นมาตรฐานอุตสาหกรรม
4. **Mix methods**: directed + random + formal + assertions
5. **Self-checking TB** + reference model = automation
6. **Functional coverage** มากกว่า code coverage
7. **Plan before code** ลด rework
8. **Sign-off criteria** ต้องชัดเจน

---

## 21. อ้างอิง

- Bergeron, J. "Writing Testbenches: Functional Verification of HDL Models," Springer, 2003.
- Spear, P. "SystemVerilog for Verification," Springer, 2006.
- IEEE 1800-2017 SystemVerilog LRM, Section 18 (Assertions).
- Accellera, "Universal Verification Methodology (UVM) 1.2 User's Guide," 2015.
- "Siemens EDA Questa Advanced Simulator User Manual" — Coverage, Assertions.
- "Cadence JasperGold User Manual" — Formal Verification.
- "Synopsys Verification Methodology Manual" — UVM Best Practices.

---

> **หมายเหตุ:** เนื้อหานี้ออกแบบให้บรรยายได้ประมาณ 90-120 นาที รวม ASCII diagrams, coverage examples, scoreboard code, methodology comparison tables พร้อมใช้ประกอบการสอนภาคทฤษฎี Day 4 เช้า หรือแบ่งเป็น 2 mini-lectures (Methodology 60 นาที + Coverage-Driven 60 นาที)
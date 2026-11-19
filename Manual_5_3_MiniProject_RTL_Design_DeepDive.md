# รายละเอียดเชิงลึก: Mini Project — ออกแบบ RTL

> เนื้อหานี้ออกแบบมาให้นำไปแทรกเป็นส่วนขยายในหัวข้อ **5.3 ภาคปฏิบัติ: Mini Project — ออกแบบ RTL** ของคู่มือหลักสูตร (วันที่ 5)
> เหมาะสำหรับการบรรยาย 90–120 นาที พร้อม RTL code เต็มที่ compile ผ่านได้

---

## 1. Mini Project: UART TX — รายละเอียด Spec

### 1.1 Functional Spec

**UART Transmitter (TX) ส่งข้อมูล 8 บิต แบบ asynchronous serial** โดยมีคุณสมบัติดังนี้:

| Parameter | Value |
| --- | --- |
| Function | UART Transmitter |
| Data width | 8 bits |
| Frame format | 1 Start bit + 8 Data bits + 1 Stop bit (8-N-1) |
| Bit order | LSB first |
| Baud rates | 9600, 19200, 115200 (configurable) |
| Default baud | 115200 |
| System clock | 100 MHz |
| Throughput | Up to 115200 bps |
| Latency | 10 bit-times per frame (≈ 87 μs @ 115200) |

### 1.2 Interface Spec

**Top-level ports:**

| Port | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | in | 1 | System clock (100 MHz) |
| `rst_n` | in | 1 | Active-low synchronous reset |
| `baud_sel` | in | 2 | Baud rate select (00=9600, 01=19200, 10=115200) |
| `din` | in | 8 | Data input (parallel) |
| `din_vld` | in | 1 | Data valid (handshake) |
| `din_rdy` | out | 1 | Data ready (handshake) |
| `tx` | out | 1 | UART TX line (asynchronous) |
| `tx_done` | out | 1 | Pulse when frame transmission complete |

### 1.3 Protocol Behavior

**Frame format (1S + 8D + 1T):**

```
   IDLE                START  D0 D1 D2 D3 D4 D5 D6 D7  STOP  IDLE
   tx line:  ━━━━━┯          ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐          ━━━━━
                  └──────────┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └──────────
                  ^         ^                 ^                     ^
                  start=0   data (LSB first)  data[7] (MSB)          stop=1
```

**Handshake protocol (din_vld/din_rdy):**

```
   din_vld:     ─────┐                          ┌──
                     └──────────────────────────┘
   din_rdy:    ───┐              ┌──
                  └──────────────┘
                  ^  can accept  ^  busy sending
```

---

## 2. Architecture Design

### 2.1 Block Diagram

```
   ┌──────────────────────────────────────────────────────────────┐
   │                     UART TX Top-Level                        │
   │                                                              │
   │  ┌──────────────────────┐                                    │
   │  │   Baud Generator     │                                    │
   │  │                      │                                    │
   │  │  CLK_FREQ ────►      │                                    │
   │  │                      │  baud_tick                         │
   │  │  BAUD_RATE  ────►    ├────────────────────┐               │
   │  │                      │                    │               │
   │  └──────────────────────┘                    │               │
   │                                              │               │
   │  ┌──────────────────────┐                    │               │
   │  │  UART TX FSM         │                    │               │
   │  │  + Shift Register    │                    │               │
   │  │                      │ ◄──────────────────┘               │
   │  │  din/din_vld ────────┼────►                               │
   │  │                      │   din_rdy                          │
   │  │                      ├────►                               │
   │  │                      │   tx (output)                      │
   │  │                      ├────►                               │
   │  │                      │   tx_done                          │
   │  │                      ├────►                               │
   │  └──────────────────────┘                                    │
   │                                                              │
   └──────────────────────────────────────────────────────────────┘
```

### 2.2 Module Hierarchy

```
   uart_tx_top (top)
   ├── baud_gen (Baud Rate Generator)
   ├── uart_tx_fsm (FSM + Data Path)
   │   ├── tx_fsm (control FSM)
   │   └── tx_shift_reg (shift register for serial output)
   └── (configurable baud divider)
```

### 2.3 Design Decisions

| Decision | Rationale |
| --- | --- |
| Single clock domain | Simpler, deterministic timing |
| Synchronous reset | Predictable, saves area |
| Modular design | Easier verification, reuse |
| FSM with explicit states | Clear control flow |
| Baud generator as separate module | Configurable baud rate |
| LSB first | UART standard |

### 2.4 Resource Estimation

- **FF count**: ~30-50 (state, counters, shift register)
- **Combinational gates**: ~100-200
- **Block RAM**: 0
- **DSP**: 0
- **Max frequency**: ~250 MHz (45nm process)

---

## 3. Block-Level Design — รายละเอียด

### 3.1 Block 1: Baud Rate Generator

**Purpose:** สร้าง baud_tick pulse ที่ความถี่ baud rate

**Inputs:**
- `clk`: 100 MHz
- `rst_n`: active-low sync reset
- `baud_sel`: 2-bit select (00=9600, 01=19200, 10=115200)

**Outputs:**
- `baud_tick`: pulse (1 cycle) ที่ baud rate

**Architecture:**

```
   CLK (100 MHz) ──► Counter ──► Compare ──► baud_tick
                       │              │
                       │              │  baud_divisor
                       │              │
                       └─── Baud Select ◄── baud_sel
```

**Baud Divisor Calculation:**

```
   Baud Divisor = CLK_FREQ / Baud Rate
   
   9600    → 100_000_000 / 9600     = 10417
   19200   → 100_000_000 / 19200    = 5208
   115200  → 100_000_000 / 115200   = 868
```

**Implementation:**

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity baud_gen is
    generic (
        CLK_FREQ : integer := 100_000_000
    );
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        baud_sel  : in  std_logic_vector(1 downto 0);
        baud_tick : out std_logic
    );
end entity baud_gen;

architecture rtl of baud_gen is
    -- Baud divisor lookup
    function get_divisor(sel : std_logic_vector(1 downto 0)) return integer is
    begin
        case sel is
            when "00"   => return CLK_FREQ / 9600;      -- 10417
            when "01"   => return CLK_FREQ / 19200;     -- 5208
            when "10"   => return CLK_FREQ / 115200;    -- 868
            when others => return CLK_FREQ / 115200;    -- default
        end case;
    end function;

    signal divisor : integer range 0 to CLK_FREQ;
    signal count   : integer range 0 to CLK_FREQ;
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                count <= 0;
                baud_tick <= '0';
            else
                if count = divisor - 1 then
                    count <= 0;
                    baud_tick <= '1';
                else
                    count <= count + 1;
                    baud_tick <= '0';
                end if;
            end if;
        end if;
    end process;
end architecture;
```

**หมายเหตุ:** Function ใน VHDL ต้องเป็น pure (no side effects)

### 3.2 Block 2: UART TX FSM

**Purpose:** ควบคุมลำดับการส่งข้อมูล (start bit → 8 data bits → stop bit)

**State Diagram:**

```
   ┌─────────┐
   │  IDLE   │◄──────────────────────────────┐
   └────┬────┘                               │
        │ din_vld & din_rdy                  │
        ▼                                    │
   ┌─────────┐                               │
   │ LOAD    │ (latch data into shift reg)   │
   └────┬────┘                               │
        │                                    │
        ▼                                    │
   ┌─────────┐                               │
   │ START   │ (send start bit '0')          │
   └────┬────┘                               │
        │ baud_tick × 1                      │
        ▼                                    │
   ┌─────────┐                               │
   │  DATA   │ (send 8 data bits)            │
   └────┬────┘                               │
        │ baud_tick × 8                      │
        ▼                                    │
   ┌─────────┐                               │
   │  STOP   │ (send stop bit '1')           │
   └────┬────┘                               │
        │ baud_tick × 1                      │
        └────────────────────────────────────┘
```

**State Encoding (Binary):**

| State | Encoding | Description |
| --- | --- | --- |
| IDLE | 00 | Wait for data |
| LOAD | 01 | Latch data |
| START | 10 | Send start bit |
| DATA | 11 | Send data bits |
| STOP | 100 | Send stop bit |

**Implementation:**

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx_fsm is
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        din       : in  std_logic_vector(7 downto 0);
        din_vld   : in  std_logic;
        din_rdy   : out std_logic;
        baud_tick : in  std_logic;
        tx        : out std_logic;
        tx_done   : out std_logic
    );
end entity uart_tx_fsm;

architecture rtl of uart_tx_fsm is
    type state_t is (S_IDLE, S_LOAD, S_START, S_DATA, S_STOP);
    signal state, next_state : state_t;
    signal bit_count : integer range 0 to 7;
    signal shift_reg : std_logic_vector(7 downto 0);
    signal tx_reg : std_logic;
begin
    -- State register
    sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= S_IDLE;
                bit_count <= 0;
                shift_reg <= (others => '0');
                tx_reg <= '1';        -- idle line = high
                din_rdy <= '1';
                tx_done <= '0';
            else
                state <= next_state;
                tx_done <= '0';
            end if;
        end if;
    end process;

    -- Next state + output logic
    comb : process (state, din_vld, baud_tick, bit_count)
    begin
        next_state <= state;  -- default
        case state is
            when S_IDLE =>
                din_rdy <= '1';
                tx <= '1';
                if din_vld = '1' then
                    next_state <= S_LOAD;
                end if;

            when S_LOAD =>
                din_rdy <= '0';
                shift_reg <= din;
                next_state <= S_START;

            when S_START =>
                if baud_tick = '1' then
                    tx <= '0';  -- start bit
                    next_state <= S_DATA;
                end if;

            when S_DATA =>
                if baud_tick = '1' then
                    if bit_count = 7 then
                        next_state <= S_STOP;
                    else
                        bit_count <= bit_count + 1;
                    end if;
                end if;

            when S_STOP =>
                if baud_tick = '1' then
                    next_state <= S_IDLE;
                    bit_count <= 0;
                    tx_done <= '1';
                end if;
        end case;
    end process;

    -- Shift register (LSB first)
    p_shift : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                shift_reg <= (others => '0');
            elsif state = S_LOAD then
                shift_reg <= din;
            elsif state = S_DATA and baud_tick = '1' then
                shift_reg <= shift_reg(6 downto 0) & '0';  -- shift left
            end if;
        end if;
    end process;

    -- TX output multiplexer
    p_tx_mux : process (state, tx_reg, shift_reg, bit_count)
    begin
        case state is
            when S_IDLE | S_LOAD =>
                tx <= '1';       -- idle
            when S_START =>
                tx <= '0';       -- start bit
            when S_DATA =>
                tx <= shift_reg(0);  -- LSB first
            when S_STOP =>
                tx <= '1';       -- stop bit
        end case;
    end process;
end architecture;
```

### 3.3 Block 3: Top-Level Integration

**Purpose:** รวม Baud Generator และ UART TX FSM

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_tx_top is
    generic (
        CLK_FREQ : integer := 100_000_000
    );
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        baud_sel  : in  std_logic_vector(1 downto 0);
        din       : in  std_logic_vector(7 downto 0);
        din_vld   : in  std_logic;
        din_rdy   : out std_logic;
        tx        : out std_logic;
        tx_done   : out std_logic
    );
end entity uart_tx_top;

architecture struct of uart_tx_top is
    signal baud_tick : std_logic;
begin
    -- Baud rate generator
    u_baud : entity work.baud_gen
        generic map (CLK_FREQ => CLK_FREQ)
        port map (
            clk       => clk,
            rst_n     => rst_n,
            baud_sel  => baud_sel,
            baud_tick => baud_tick
        );

    -- UART TX FSM
    u_tx : entity work.uart_tx_fsm
        port map (
            clk       => clk,
            rst_n     => rst_n,
            din       => din,
            din_vld   => din_vld,
            din_rdy   => din_rdy,
            baud_tick => baud_tick,
            tx        => tx,
            tx_done   => tx_done
        );
end architecture;
```

---

## 4. FSM Design — เชิงลึก

### 4.1 State Transition Table

| Current State | Condition | Next State | Actions |
| --- | --- | --- | --- |
| IDLE | din_vld='1' | LOAD | shift_reg = din; din_rdy=0 |
| IDLE | din_vld='0' | IDLE | tx=1, din_rdy=1 |
| LOAD | (always) | START | - |
| START | baud_tick='1' | DATA | tx=0 |
| DATA | baud_tick='1', bit_count<7 | DATA | tx=shift_reg[0]; bit_count++ |
| DATA | baud_tick='1', bit_count=7 | STOP | bit_count=0 |
| STOP | baud_tick='1' | IDLE | tx=1; tx_done=1 |

### 4.2 Timing Diagram

```
    clk:        ─┐    ┌──┐    ┌──┐    ┌──┐    ┌──┐    ┌──┐    ┌──┐
                 └────┘  └────┘  └────┘  └────┘  └────┘  └────┘  └────

    rst_n:   ─────┐
                  └──────────────────────────────────────────

   baud_tick:      ┌─┐       ┌─┐       ┌─┐       ┌─┐       ┌─┐
                   └─┘       └─┘       └─┘       └─┘       └─┘
                   ↑         ↑         ↑         ↑         ↑
                   every 868 cycles (115200 baud)

   state:    [IDLE] [LOAD] [START] [DATA] [DATA] [DATA] [DATA] [STOP] [IDLE]

   tx:       ━━━┯          ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐        ━━━
              start         0  1  0  1  0  1  0  1  stop
              ^            ^     ^     ^     ^     ^     ^     ^      ^
              IDLE         START data[0]-data[7]            STOP  IDLE
   (8 bits sent + start + stop)
```

### 4.3 State Encoding Trade-off

**Option 1: Binary (used above)**
- 3 bits for 5 states
- 2 bits transition between adjacent states
- Pro: minimum FF, small area

**Option 2: One-Hot**
- 5 bits (1 per state)
- 1 bit transition
- Pro: fast, simple FSM logic
- Con: more FFs

**Option 3: Gray**
- Minimize bit changes
- Pro: low power
- Con: complex decoding

**สำหรับ UART TX:** Binary ดีที่สุด (compact + simple)

### 4.4 FSM Optimization

**ทำไมเป็น Moore:** Output (tx) ขึ้นกับ state เท่านั้น → glitch-free, ใช้ MUX ตาม state

**Alternative (Mealy):**
```vhdl
-- Mealy: output depends on state + baud_tick
-- (ตัวอย่างเช่น: ใน DATA state, tx ขึ้นกับ shift_reg[0] และ baud_tick)
```

ข้อดีของ Mealy: latency 0 (output ทันที)
ข้อเสีย: ต้องระวัง glitch จาก baud_tick timing

---

## 5. Coding Style — Best Practices

### 5.1 Naming Convention

| Element | Convention | Example |
| --- | --- | --- |
| Entity | PascalCase | `UartTx`, `BaudGen` |
| Signal | snake_case | `baud_tick`, `tx_done` |
| Variable | snake_case or camelCase | `bit_count`, `curByte` |
| Constant | UPPER_CASE | `CLK_FREQ`, `BAUD_RATE` |
| Process label | `p_` prefix | `p_sync`, `p_comb` |
| Component instance | `u_` prefix | `u_baud`, `u_tx` |
| State names | UPPER_CASE | `S_IDLE`, `S_START` |

### 5.2 Comments

```vhdl
-- ============================================================
-- File: uart_tx.vhd
-- Module: UART Transmitter
-- Author: [Your Name]
-- Date: [Date]
-- Description:
--   8-bit UART Transmitter with configurable baud rate.
--   Frame format: 1 start + 8 data + 1 stop (8-N-1)
-- ============================================================
```

### 5.3 Header Template

```vhdl
-- 1. Library + Use clauses
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- 2. Entity
entity name is
    generic (
        -- parameters
    );
    port (
        -- signals
    );
end entity;

-- 3. Architecture declaration
architecture rtl of name is
    -- internal signals, types, constants
begin
    -- concurrent statements
    -- processes
end architecture;
```

### 5.4 Signal Type Consistency

```vhdl
-- ✅ GOOD: ใช้ unsigned สำหรับ arithmetic
signal counter : unsigned(7 downto 0);
signal data    : std_logic_vector(7 downto 0);

-- ❌ BAD: ผสมชนิด
signal counter : integer range 0 to 255;  -- ใช้ได้ แต่ไม่ consistent
```

### 5.5 Process Naming

```vhdl
-- Synchronous process
sync_proc : process (clk)
begin
    if rising_edge(clk) then
        ...
    end if;
end process;

-- Combinational process
comb_proc : process (state, din)
begin
    ...
end process;
```

### 5.6 Default Assignment

```vhdl
-- ✅ GOOD: default assignment ใน process
comb : process (state, din_vld)
begin
    next_state <= state;  -- default
    din_rdy <= '0';
    case state is
        when S_IDLE =>
            din_rdy <= '1';
            ...
    end case;
end process;
```

### 5.7 Sensitivity List

```vhdl
-- ✅ GOOD: explicit sensitivity list
process (state, din_vld, baud_tick)
begin
    ...
end process;

-- ✅ ALSO GOOD (VHDL-2008): use "all"
process (all)
begin
    ...
end process;
```

---

## 6. Common Pitfalls และ Solutions

### 6.1 Pitfall 1: ไม่ reset baud_tick

```vhdl
-- BAD: baud_tick ไม่ initialized
process (clk)
begin
    if rising_edge(clk) then
        if count = divisor - 1 then
            count <= 0;
            baud_tick <= '1';  -- ⚠️ ไม่ reset ใน if rst_n
        else
            count <= count + 1;
            baud_tick <= '0';
        end if;
    end if;
end process;
```

**Fix:**
```vhdl
-- GOOD: explicit reset
process (clk)
begin
    if rising_edge(clk) then
        if rst_n = '0' then
            count <= 0;
            baud_tick <= '0';
        elsif count = divisor - 1 then
            count <= 0;
            baud_tick <= '1';
        else
            count <= count + 1;
            baud_tick <= '0';
        end if;
    end if;
end process;
```

### 6.2 Pitfall 2: Glitch ใน TX output

ถ้าใช้ Mealy FSM และ baud_tick เปลี่ยนใกล้ state change → glitch

**Fix:**
- ใช้ registered output (Moore)
- หรือ register baud_tick 2 cycles

### 6.3 Pitfall 3: State Machine Hang

ถ้า state transition condition ไม่ครบ → state ค้าง

**Fix:** ใส่ default condition, ใช้ `when others` clause

```vhdl
case state is
    when S_IDLE => ...
    when S_LOAD => ...
    when S_START => ...
    when S_DATA => ...
    when S_STOP => ...
    when others => next_state <= S_IDLE;  -- safe default
end case;
```

### 6.4 Pitfall 4: Off-by-one ใน bit_count

```vhdl
-- BAD: bit_count เริ่มที่ 0, ลืม reset
if baud_tick = '1' then
    tx <= shift_reg(bit_count);  -- bit_count = 0, 1, ..., 7
    bit_count <= bit_count + 1;
end if;
-- bug: bit_count = 8 → shift_reg(8) = out of range!
```

**Fix:**
```vhdl
-- GOOD: limit and reset
if baud_tick = '1' then
    if bit_count = 7 then
        next_state <= S_STOP;
        bit_count <= 0;
    else
        tx <= shift_reg(bit_count);
        bit_count <= bit_count + 1;
    end if;
end if;
```

### 6.5 Pitfall 5: Baud Divisor = 0

ถ้า baud_sel เปลี่ยนและ divisor = 0 → divide by zero (in some tools)

**Fix:** ตรวจสอบ divisor minimum:
```vhdl
-- Add minimum limit
if divisor < 2 then
    divisor <= 2;  -- safety
end if;
```

---

## 7. Modular Design Pattern

### 7.1 File Structure

```
   project/
   ├── rtl/
   │   ├── baud_gen.vhd           (Block 1)
   │   ├── uart_tx_fsm.vhd        (Block 2)
   │   ├── uart_tx_top.vhd        (Top-level)
   │   └── uart_tx_pkg.vhd        (Package)
   ├── tb/
   │   ├── tb_baud_gen.vhd
   │   ├── tb_uart_tx_fsm.vhd
   │   └── tb_uart_tx_top.vhd
   ├── constraints/
   │   └── uart_tx.sdc
   ├── scripts/
   │   ├── synth.tcl
   │   └── run_gls.do
   └── reports/
       └── final_report.md
```

### 7.2 Package

```vhdl
-- File: uart_tx_pkg.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package uart_tx_pkg is
    -- Constants
    constant DEFAULT_CLK_FREQ : integer := 100_000_000;

    -- Types
    type baud_rate_t is (B9600, B19200, B115200);

    -- Function: convert baud_rate_t to divisor
    function baud_to_divisor(baud : baud_rate_t) return integer;

    -- Function: convert std_logic_vector to baud_rate_t
    function sel_to_baud(sel : std_logic_vector(1 downto 0)) return baud_rate_t;
end package;

package body uart_tx_pkg is
    function baud_to_divisor(baud : baud_rate_t) return integer is
    begin
        case baud is
            when B9600   => return 10417;
            when B19200  => return 5208;
            when B115200 => return 868;
        end case;
    end function;

    function sel_to_baud(sel : std_logic_vector(1 downto 0)) return baud_rate_t is
    begin
        case sel is
            when "00"   => return B9600;
            when "01"   => return B19200;
            when "10"   => return B115200;
            when others => return B115200;
        end case;
    end function;
end package body;
```

### 7.3 Configuration (Optional)

```vhdl
-- File: config.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.uart_tx_pkg.ALL;

entity config is
end entity;

architecture rtl of config is
begin
    -- Could include vendor-specific configurations
end architecture;
```

---

## 8. Verification Plan ที่ Aligned กับ Design

### 8.1 Coverage Plan

| Block | Coverage Focus | Method |
| --- | --- | --- |
| Baud Gen | All baud rates | Constrained random |
| TX FSM | All states, all transitions | Directed + Random |
| TX Top | All data values, all baud | Random + Scoreboard |
| TX Output | Frame structure | Bit-by-bit check |

### 8.2 Feature Mapping

```markdown
| Feature | RTL Implementation | Test Plan |
|---|---|---|
| F01: Reset | sync reset | Directed |
| F02: Frame | IDLE/LOAD/START/DATA/STOP FSM | Directed + Random |
| F03: Baud | baud_gen | Random |
| F04: Data | shift_reg | Exhaustive (256 values) |
| F05: Back-to-back | din_vld when ready | Directed |
```

### 8.3 Assertions

```vhdl
-- Idle line = '1' when not transmitting
assert_idle : assert never
    (state = S_IDLE and tx = '0')
    report "TX line should be 1 in IDLE"
    severity failure;

-- Start bit = '0'
assert_start : assert always
    (state = S_START) -> (tx = '0')
    report "Start bit must be 0"
    severity failure;

-- Stop bit = '1'
assert_stop : assert always
    (state = S_STOP) -> (tx = '1')
    report "Stop bit must be 1"
    severity failure;
```

---

## 9. Complete UART TX Project (Final Version)

### 9.1 Top-Level (All-in-One)

```vhdl
-- ============================================================
-- File: uart_tx_all.vhd
-- Complete UART TX with all features
-- Ready for synthesis + GLS
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx_all is
    generic (
        CLK_FREQ : integer := 100_000_000
    );
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        baud_sel  : in  std_logic_vector(1 downto 0);
        din       : in  std_logic_vector(7 downto 0);
        din_vld   : in  std_logic;
        din_rdy   : out std_logic;
        tx        : out std_logic;
        tx_done   : out std_logic
    );
end entity uart_tx_all;

architecture rtl of uart_tx_all is
    -- State encoding
    type state_t is (S_IDLE, S_LOAD, S_START, S_DATA, S_STOP);
    signal state, next_state : state_t;

    -- Baud generator
    function get_divisor(sel : std_logic_vector(1 downto 0)) return integer is
    begin
        case sel is
            when "00"   => return CLK_FREQ / 9600;       -- 10417
            when "01"   => return CLK_FREQ / 19200;      -- 5208
            when "10"   => return CLK_FREQ / 115200;     -- 868
            when others => return CLK_FREQ / 115200;
        end case;
    end function;

    signal divisor : integer range 0 to CLK_FREQ;
    signal baud_count : integer range 0 to CLK_FREQ;
    signal baud_tick : std_logic;

    -- TX FSM
    signal bit_count : integer range 0 to 7 := 0;
    signal shift_reg : std_logic_vector(7 downto 0);
begin

    -- ============================================================
    -- 1. Baud Rate Generator
    -- ============================================================
    p_baud : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                baud_count <= 0;
                baud_tick <= '0';
            else
                divisor <= get_divisor(baud_sel);  -- update divisor (1 cycle latency)
                if baud_count = divisor - 1 then
                    baud_count <= 0;
                    baud_tick <= '1';
                else
                    baud_count <= baud_count + 1;
                    baud_tick <= '0';
                end if;
            end if;
        end if;
    end process;

    -- ============================================================
    -- 2. TX FSM
    -- ============================================================
    p_sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= S_IDLE;
                bit_count <= 0;
                shift_reg <= (others => '0');
                din_rdy <= '1';
                tx_done <= '0';
            else
                state <= next_state;
                tx_done <= '0';
            end if;
        end if;
    end process;

    p_comb : process (state, din_vld, baud_tick, bit_count)
    begin
        next_state <= state;
        case state is
            when S_IDLE =>
                din_rdy <= '1';
                if din_vld = '1' then
                    next_state <= S_LOAD;
                end if;

            when S_LOAD =>
                din_rdy <= '0';
                shift_reg <= din;
                next_state <= S_START;

            when S_START =>
                if baud_tick = '1' then
                    next_state <= S_DATA;
                end if;

            when S_DATA =>
                if baud_tick = '1' then
                    if bit_count = 7 then
                        next_state <= S_STOP;
                    else
                        bit_count <= bit_count + 1;
                    end if;
                end if;

            when S_STOP =>
                if baud_tick = '1' then
                    next_state <= S_IDLE;
                    bit_count <= 0;
                    tx_done <= '1';
                end if;
        end case;
    end process;

    -- ============================================================
    -- 3. TX Output (Moore-style: depends only on state)
    -- ============================================================
    tx <= '0' when state = S_START else
          shift_reg(0) when state = S_DATA else
          '1';

end architecture;
```

### 9.2 ทดสอบ Compile (Quick)

```bash
# ใน directory ของไฟล์
vlib work
vcom -2008 uart_tx_all.vhd
# ควร compile ผ่าน
```

### 9.3 คาดหวัง Resource

| Resource | Estimated Count |
| --- | --- |
| LUTs/Combinational | ~150-300 |
| FFs | ~30-50 |
| Block RAM | 0 |
| DSP | 0 |
| Max frequency (45nm) | ~250 MHz |

---

## 10. Synthesis Settings ที่เหมาะสม

### 10.1 SDC for UART TX

```tcl
# uart_tx.sdc

# Clock
create_clock -name sys_clk -period 10.0 -waveform {0 5} [get_ports clk]

# Input delays
set_input_delay  -clock sys_clk 2.0 -max [get_ports {din din_vld baud_sel rst_n}]
set_input_delay  -clock sys_clk 1.0 -min [get_ports {din din_vld baud_sel rst_n}]

# Output delays
set_output_delay -clock sys_clk 2.0 -max [get_ports {tx tx_done din_rdy}]
set_output_delay -clock sys_clk 1.0 -min [get_ports {tx tx_done din_rdy}]

# Reset is synchronous
set_false_path -from [get_ports rst_n]

# Operating conditions
set_operating_conditions -process typical -voltage 1.0 -temp 25

# Don't optimize baud_tick generation
set_dont_touch [get_cells u_baud_gen] false
```

### 10.2 Precision RTL Tcl

```tcl
# synth.tcl
new_project -name uart_tx -folder work_uart
add_source -type vhdl -work work uart_tx_all.vhd
add_constraint_file uart_tx.sdc
set_top_module uart_tx_all
elaborate
compile -incremental_mapping
report_area -file reports/area.rpt
report_timing -delay max -num_paths 50 -file reports/timing.rpt
export_netlist -format verilog -output gate/uart_tx.v
write_sdf -output gate/uart_tx.sdf
exit
```

---

## 11. Verification Strategy (Mini Project)

### 11.1 Test Cases

| ID | Description | Stimulus | Expected |
| --- | --- | --- | --- |
| T01 | Reset | rst_n=0 for 5 cycles | tx=1, din_rdy=1 |
| T02 | Send 0x55 | din=0x55, din_vld=1 | start=0, data=01010101, stop=1 |
| T03 | Send 0xAA | din=0xAA, din_vld=1 | start=0, data=10101010, stop=1 |
| T04 | Send 0x00 | din=0x00, din_vld=1 | start=0, data=00000000, stop=1 |
| T05 | Send 0xFF | din=0xFF, din_vld=1 | start=0, data=11111111, stop=1 |
| T06 | All 256 bytes | random din | All frames correct |
| T07 | Back-to-back | 0x55, 0xAA | 2 frames back-to-back |
| T08 | Different baud | 115200 → 9600 | Frame timing changes |
| T09 | Reset during TX | rst_n mid-frame | tx=1, back to IDLE |

### 11.2 Coverage Goals

```markdown
- Statement: ≥ 95%
- Branch: ≥ 90%
- Functional: 100% (all features)
- FSM State: 100% (all states)
- All data values: 100% (256 patterns)
```

### 11.3 Self-Checking TB Structure

```vhdl
-- Structure
1. Reset phase
2. Directed tests (T01-T05)
3. Back-to-back test
4. Different baud test
5. Reset during TX
6. Random tests (1000 patterns)
7. Final report
```

---

## 12. Summary และ Key Takeaways

### 12.1 Design Principles

1. **Modular design** — แยก block ชัดเจน
2. **Synchronous reset** — predictable timing
3. **Single clock** — ลด CDC issues
4. **FSM with clear states** — readable
5. **Default assignments** — ป้องกัน latch
6. **Registered outputs** — glitch-free

### 12.2 Common Design Patterns

1. **Counter + Comparator** = Baud Generator
2. **FSM + Shift Register** = UART TX
3. **Moore output** = Glitch-free
4. **Handshake protocol** = din_vld/din_rdy

### 12.3 Resource vs Performance Trade-off

| Option | Area | Speed | Use Case |
| --- | --- | --- | --- |
| Binary state encoding | Small | OK | Default |
| One-hot state encoding | Large | Fast | High-speed |
| Combinational TX | Smallest | Fastest | Risk glitch |
| Registered TX | Medium | Safe | Production |
| Pipeline (multi-cycle) | Largest | Fastest | Ultra-high speed |

### 12.4 Next Steps

1. **Verify** with TB (see Lab 5)
2. **Synthesize** with Precision RTL
3. **GLS** with SDF
4. **Sign-off** documentation

---

## 13. อ้างอิง

- "Siemens EDA Questa Advanced Simulator User Manual."
- "Precision RTL Synthesis User Manual."
- "UART Protocol Specification" (Texas Instruments, Maxim).
- Cummings, C. E. "Coding and Scripting Techniques for FSM Design," SNUG 2000.
- Ashenden, P. J. "The Designer's Guide to VHDL," Morgan Kaufmann, 2008.

---


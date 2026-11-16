# รายละเอียดเชิงลึก: FSM Moore vs Mealy

> เนื้อหานี้ออกแบบมาให้นำไปแทรกเป็นส่วนขยายในหัวข้อ **2.2 ภาคทฤษฎี: FSM – Moore vs Mealy** ของคู่มือหลักสูตร (วันที่ 2)
> เหมาะสำหรับการบรรยาย 90–120 นาที

---

## 1. Finite State Machine (FSM) — พื้นฐานที่แท้จริง

### 1.1 FSM คืออะไร

**FSM** คือ computational model ที่ประกอบด้วย:
- **Finite set of states** — จำนวน state จำกัด
- **Input(s)** — สัญญาณภายนอกที่ trigger state transition
- **Output(s)** — สัญญาณที่ปล่อยออกมา
- **Transition function** — เงื่อนไขในการเปลี่ยน state
- **Output function** — เงื่อนไขในการกำหนด output

ใน digital IC design, FSM ใช้เป็น **control logic** เช่น:
- UART transmitter/receiver
- CPU instruction decoder
- Memory controller
- Traffic light controller
- Network protocol (AXI, PCIe, Ethernet)

### 1.2 FSM Anatomy

```
   ┌──────────────────────────────────────────────────┐
   │                                                  │
   │    ┌─────────┐                                   │
   │    │         │      ┌─────────┐                  │
   │    │ Current ├─────►│ Next    │                  │
   │    │ State   │      │ State   │──► FF register   │
   │    │         │◄─────┤ (combinational)            │
   │    └────┬────┘      └─────────┘                  │
   │         │                                        │
   │         ▼                                        │
   │    ┌─────────┐                                   │
   │    │ Output  │ (Moore: function of state only)   │
   │    │ Logic   │ (Mealy: function of state+input)  │
   │    └─────────┘                                   │
   │                                                  │
   │    ┌─────────┐                                   │
   │    │ Input   │─────► Determines transition       │
   │    └─────────┘                                   │
   │                                                  │
   └──────────────────────────────────────────────────┘
```

### 1.3 ประเภทของ FSM

| Type | Output ขึ้นกับ | ใช้เมื่อ |
| --- | --- | --- |
| **Moore** | State ปัจจุบัน เท่านั้น | Output ต้อง stable, glitch-free |
| **Mealy** | State ปัจจุบัน + Input | Output ตอบสนองเร็ว, latency ต่ำ |
| **Mixed** | State + Input (มีทั้ง 2 ประเภท output) | ระบบซับซ้อน |
| **Huffman** | | | ทั่วไปในระบบ digital |

---

## 2. Moore Machine — เชิงลึก

### 2.1 คำจำกัดความ

**Moore Machine:** Output ขึ้นกับ **state ปัจจุบันเท่านั้น** ไม่ขึ้นกับ input โดยตรง

```
   Output = f(state)
```

### 2.2 โครงสร้าง

```
   Inputs        Current         Next         Output
    ─────►  ┌──────────┐   ┌──────────┐  ┌──────────┐
          │ │ next     │   │  State   │  │  Output  │────►
          │ │ state    ├──►│  Register├──┤  Logic   │ (combinational)
          │ │ logic    │   └──────┬───┘  └──────────┘
          │ └──────┬───┘          │
          │        │             clk
          │        │              │
   ───────┘        └──────────────┘
                (feedback)
```

### 2.3 คุณสมบัติ

| ข้อดี | ข้อเสีย |
| --- | --- |
| ✅ Output **glitch-free** (ขึ้นกับ register) | ⚠️ จำนวน state มากกว่า (Mealy ใช้ state น้อยกว่า) |
| ✅ Timing analysis deterministic | ⚠️ Output latency ≥ 1 clock cycle |
| ✅ Synthesis ตรงไปตรงมา | ⚠️ ตอบสนอง input ช้า |
| ✅ เหมาะกับการเขียน self-checking TB | |
| ✅ เหมาะกับ formal verification | |

### 2.4 ASCII State Diagram (Moore)

```
                  din='1'
                  ┌────┐
   ┌────────────┐ │    │  din='1'
   │            ▼ │    ▼
  (S0)────din='0'────►(S1)
   │                  │
   │                  │ din='0'
   │                  ▼
   │                 (S2)
   │                  │
   │                  │ din='1
   │                  ▼
   └────din='X───►(S3)──►  output=1 (เมื่อใน S3)
   (loop back)      │
                    │ din='X
                    └───────► S1 or S0
```

State transition:
- S0: din=0 → S0; din=1 → S1
- S1: din=0 → S2; din=1 → S1
- S2: din=0 → S0; din=1 → S3
- S3: output=1; din=X → กลับไป S1 หรือ S0

---

## 3. Mealy Machine — เชิงลึก

### 3.1 คำจำกัดความ

**Mealy Machine:** Output ขึ้นกับ **state ปัจจุบัน + input ปัจจุบัน**

```
   Output = f(state, input)
```

### 3.2 โครงสร้าง

```
   Inputs        Current         Next         Output
    ─────►  ┌──────────┐   ┌──────────┐  ┌──────────┐
          │ │ next     │   │  State   │  │  Output  │────►
   ──────►│ │ state    ├──►│  Register├──┤  Logic   │ (combinational,
          │ │ logic    │   └──────┬───┘  └──────────┘  depends on state
          │ └──────┬───┘          │              ▲       + input)
          │        │             clk             │
          │        │              │              │
          │        └──────────────┘              │
          │                                      │
          └──────────────────────────────────────┘
                (input also affects output)
```

### 3.3 คุณสมบัติ

| ข้อดี | ข้อเสีย |
| --- | --- |
| ✅ จำนวน state น้อยกว่า (Moore) | ⚠️ Output อาจมี **glitch** ถ้า input ไม่ sync |
| ✅ Output latency ต่ำ (combinational) | ⚠️ Timing analysis ยากกว่า |
| ✅ ตอบสนอง input เร็ว | ⚠️ Verify ยาก (state space ผูกกับ input) |
| ✅ ใช้ FF น้อยกว่า | ⚠️ Glitch propagation ใน GLS |

### 3.4 ASCII State Diagram (Mealy)

```
                    din='1'/out=0
                  ┌────┐
   ┌────────────┐ │    │  din='1'/out=0
   │            ▼ │    ▼
  (S0)────din='0'/out=0────►(S1)
   │                           │
   │                           │ din='0'/out=0
   │                           ▼
   │                          (S2)
   │                           │
   │                           │ din='1'/out=1  (output ออกทันที!)
   │                           │
   └────din='X'─◄──(S2 กลับ S0)─┘
   (loop back)
```

State transition (Mealy):
- S0: din=0/out=0 → S0; din=1/out=0 → S1
- S1: din=0/out=0 → S2; din=1/out=0 → S1
- S2: din=0/out=0 → S0; din=1/out=1 → S1 (output ที่นี่)

สังเกต: ใน Mealy, "101" detected ที่ edge ของ 2 → S1 transition (state เปลี่ยนทันที, output เปลี่ยนทันที)

---

## 4. เปรียบเทียบ Moore vs Mealy — แบบละเอียด

### 4.1 กรณี Sequence Detector "101"

**Moore:** ต้องการ 4 states (S0, S1, S2, S3 ที่ detect)
**Mealy:** ต้องการ 3 states (S0, S1, S2 ที่ detect)

| Aspect | Moore | Mealy |
|---|---|---|
| Number of states | 4 | 3 |
| Detection timing | 1 cycle หลัง pattern สมบูรณ์ | ทันทีที่ pattern สมบูรณ์ |
| Output latency | +1 clock (เพราะผ่าน FF) | 0 (combinational) |
| Power consumption | สูงกว่าเล็กน้อย (state มากกว่า) | ต่ำกว่า |
| FF usage | 4 × FFs (2 bits) | 3 × FFs (2 bits) |

### 4.2 Output Timing เปรียบเทียบ

```
   din:           1     0     1
   time:  ───────────────────────►
                    ↑
                  pattern "101"

   Moore output:                ─┐
                                1│ (1 cycle delay)
                                ─┘
   ↑
   detect ที่ cycle ถัดไป

   Mealy output:               ─┐
   (delayed reg)               1│
                               ─┘
   ↑
   detect ทันทีที่ pattern ครบ (combinational)

   ※ ถ้า output ผ่าน FF (registered output):
   Mealy output:                   ─┐
                                    1│ (1 cycle delay เหมือน Moore)
                                    ─┘
```

### 4.3 Timing Diagram เปรียบเทียบ (concrete)

**Moore:** pattern "101" detected

```
   clk:      ─┐    ┌──┐    ┌──┐    ┌──┐    ┌──┐
              └────┘  └────┘  └────┘  └────┘

    din:    ──┐       ┌─┐        ┌─┐        ┌──
              └───────┘ └────────┘ └────────┘
              ↑ '1'    ↑ '0'      ↑ '1'
                        (pattern 101 detected)

   state:    [S0]  [S1]  [S2]  [S3]  [S1]
                          ↑ enters S3 after detecting

   out:                         ─┐
                                1│   (registered output, 1 cycle)
                                ─┘
```

**Mealy:** pattern "101" detected

```
   clk:      ─┐    ┌──┐    ┌──┐    ┌──┐    ┌──┐
              └────┘  └────┘  └────┘  └────┘

    din:    ──┐       ┌─┐        ┌─┐        ┌──
              └───────┘ └────────┘ └────────┘
                        ↑ '0'      ↑ '1'

   state:    [S0]  [S1]  [S2]  [S1]  [S1]
                                  ↑ (combinational out=1 ทันที)
   out:                       ─┐
                             (combinational, "glitchy" without register)
                             ─┘
```

### 4.4 Trade-off Matrix

| ต้องการ | เลือก | เหตุผล |
|---|---|---|
| Output glitch-free | **Moore** | Output ผ่าน FF → stable |
| Low latency | **Mealy** | Output เป็น combinational |
| Low area | **Mealy** | State น้อยกว่า |
| Easy verification | **Moore** | State space ไม่ขึ้นกับ input |
| Formal verification | **Moore** | Verifier-friendly |
| Simple specification | **Mealy** | ง่ายกว่าในบางกรณี |

---

## 5. State Encoding — เชิงลึก

### 5.1 Encoding Types

**1. Binary (Sequential)**

```
   State Index  | Encoding
   -------------|-------------
   S0          | 00
   S1          | 01
   S2          | 10
   S3          | 11
```

**ข้อดี**: ใช้ FF น้อยที่สุด (N states = ⌈log₂ N⌉ bits)
**ข้อเสีย**: เมื่อเปลี่ยน state อาจเปลี่ยนหลาย bits → transient glitch

**2. One-Hot**

```
   State Index  | Encoding
   -------------|-------------
   S0          | 0001
   S1          | 0010
   S2          | 0100
   S3          | 1000
```

**ข้อดี**: เปลี่ยน state ครั้งละ 1 bit → minimal glitch
**ข้อดี**: Synthesis simple → timing ดี, fast
**ข้อเสีย**: ใช้ FF มาก (N states = N bits)

**3. Gray Code**

```
   State Index  | Encoding
   -------------|-------------
   S0          | 00
   S1          | 01
   S2          | 11
   S3          | 10
```

**ข้อดี**: เปลี่ยน state ครั้งละ 1 bit (เหมือน one-hot)
**ข้อดี**: ใช้ FF น้อยกว่า one-hot

**4. Johnson Code**

```
   State Index  | Encoding
   -------------|-------------
   S0          | 000
   S1          | 100
   S2          | 110
   S3          | 111
   S4          | 011
   S5          | 001
```

### 5.2 Comparison Table

| Encoding | FFs | Glitch | Speed | Area | Use Case |
|---|---|---|---|---|---|
| **Binary** | ⌈log₂N⌉ | Multiple-bit transitions | Medium | Best area | Default, low-power |
| **One-Hot** | N | Single-bit | Fastest | Largest area | High-speed FSM, FPGA |
| **Gray** | ⌈log₂N⌉ | Single-bit | Fast | Medium | Counter, FSM with safe transitions |
| **Johnson** | ⌈N/2⌉ | Multiple-bit | Medium | Small | Counter, simple sequencing |

### 5.3 Encoding in VHDL

**Binary (tool default):**

```vhdl
type state_t is (S0, S1, S2, S3);
-- tool encodes: S0=00, S1=01, S2=10, S3=11
```

**One-Hot (manual encoding via attribute):**

```vhdl
type state_t is (S0, S1, S2, S3);
attribute enum_encoding : string;
attribute enum_encoding of state_t : encoding type is "one_hot 0001 0010 0100 1000";
-- สั่งให้ tool encode เป็น one-hot
```

**Manual encoding (full control):**

```vhdl
constant S0_CODE : std_logic_vector(1 downto 0) := "00";
constant S1_CODE : std_logic_vector(1 downto 0) := "01";
constant S2_CODE : std_logic_vector(1 downto 0) := "10";
constant S3_CODE : std_logic_vector(1 downto 0) := "11";

signal state : std_logic_vector(1 downto 0);
```

---

## 6. Coding Templates

### 6.1 Moore Template (Single Process)

```vhdl
architecture moore_single of moore_fsm is
    type state_t is (S0, S1, S2, S3);
    signal state : state_t;
begin
    -- Single process: state register + next state + output
    sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= S0;
            else
                case state is
                    when S0 => state <= S1 when din = '1' else S0;
                    when S1 => state <= S2 when din = '0' else S1;
                    when S2 => state <= S3 when din = '1' else S0;
                    when S3 => state <= S1 when din = '1' else S0;
                end case;
            end if;
        end if;
    end process;

    -- Output (combinational)
    output <= '1' when state = S3 else '0';
end architecture;
```

**ข้อดี**: สั้นกระชับ
**ข้อเสีย**: combinational process ไม่มี — output latency สูง

### 6.2 Moore Template (Two Processes) — แนะนำ

```vhdl
architecture moore_two of moore_fsm is
    type state_t is (S0, S1, S2, S3);
    signal state, next_state : state_t;
begin
    -- Process 1: state register
    sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= S0;
            else
                state <= next_state;
            end if;
        end if;
    end process;

    -- Process 2: next-state + output logic (combinational)
    comb : process (state, din)
    begin
        -- Default values
        next_state <= state;
        output <= '0';

        case state is
            when S0 =>
                next_state <= S1 when din = '1' else S0;
            when S1 =>
                next_state <= S2 when din = '0' else S1;
            when S2 =>
                next_state <= S3 when din = '1' else S0;
            when S3 =>
                output <= '1';
                next_state <= S1 when din = '1' else S0;
        end case;
    end process;
end architecture;
```

**ข้อดี**: timing analysis deterministic, output ผ่าน FF (ใน process sync ไม่ได้ แต่ process comb มี next_state เป็น register)

### 6.3 Moore Template (Three Processes) — แยก Output logic

```vhdl
architecture moore_three of moore_fsm is
    type state_t is (S0, S1, S2, S3);
    signal state, next_state : state_t;
begin
    -- Process 1: state register
    sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= S0;
            else
                state <= next_state;
            end if;
        end if;
    end process;

    -- Process 2: next-state logic
    ns_logic : process (state, din)
    begin
        case state is
            when S0 =>
                next_state <= S1 when din = '1' else S0;
            when S1 =>
                next_state <= S2 when din = '0' else S1;
            when S2 =>
                next_state <= S3 when din = '1' else S0;
            when S3 =>
                next_state <= S1 when din = '1' else S0;
        end case;
    end process;

    -- Process 3: output logic
    out_logic : process (state)
    begin
        output <= '0';
        case state is
            when S3 => output <= '1';
            when others => output <= '0';
        end case;
    end process;
end architecture;
```

**ข้อดี**: ชัดเจน, debug ง่าย, formal verification-friendly

### 6.4 Mealy Template

```vhdl
architecture mealy of mealy_fsm is
    type state_t is (S0, S1, S2);
    signal state, next_state : state_t;
begin
    sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= S0;
            else
                state <= next_state;
            end if;
        end if;
    end process;

    comb : process (state, din)
    begin
        -- Default
        next_state <= state;
        output <= '0';

        case state is
            when S0 =>
                next_state <= S1 when din = '1' else S0;
            when S1 =>
                next_state <= S2 when din = '0' else S1;
            when S2 =>
                if din = '1' then
                    next_state <= S1;
                    output <= '1';        -- Mealy output: combinational
                else
                    next_state <= S0;
                end if;
        end case;
    end process;
end architecture;
```

### 6.5 Mealy with Registered Output (แก้ Glitch)

```vhdl
architecture mealy_reg of mealy_fsm is
    type state_t is (S0, S1, S2);
    signal state, next_state : state_t;
    signal output_comb : std_logic;
    signal output_reg  : std_logic;
begin
    sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= S0;
                output_reg <= '0';
            else
                state <= next_state;
                output_reg <= output_comb;     -- register output
            end if;
        end if;
    end process;

    comb : process (state, din)
    begin
        output_comb <= '0';
        case state is
            when S0 =>
                next_state <= S1 when din = '1' else S0;
            when S1 =>
                next_state <= S2 when din = '0' else S1;
            when S2 =>
                if din = '1' then
                    next_state <= S1;
                    output_comb <= '1';
                else
                    next_state <= S0;
                end if;
        end case;
    end process;

    output <= output_reg;        -- registered output → glitch-free
end architecture;
```

---

## 7. ตัวอย่างเชิงสึก: Traffic Light Controller

### 7.1 Spec

- รถ 3 ทิศทาง (N, S, E, W — ใช้แค่ 3 เนื่องจาก N=S)
- ลำดับ: NS-Green → NS-Red+E/W-Green → E/W-Red → NS-Green (loop)
- แต่ละ state ใช้เวลา 5 วินาที

### 7.2 Moore Implementation

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity traffic_light_moore is
    port (
        clk      : in  std_logic;
        rst_n    : in  std_logic;
        -- Outputs: G/R/Y for NS and EW
        ns_lights : out std_logic_vector(2 downto 0);  -- G/R/Y
        ew_lights : out std_logic_vector(2 downto 0)
    );
end entity;

architecture rtl of traffic_light_moore is
    type state_t is (NS_GREEN, NS_YELLOW, EW_GREEN, EW_YELLOW);
    signal state, next_state : state_t;
    constant CYCLE_COUNT : integer := 5_000_000; -- 5s @ 1 MHz
    signal counter : unsigned(22 downto 0);
begin
    sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= NS_GREEN;
                counter <= (others => '0');
            else
                if counter = CYCLE_COUNT then
                    state <= next_state;
                    counter <= (others => '0');
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;
    end process;

    comb : process (state)
    begin
        ns_lights <= "001";    -- Red
        ew_lights <= "001";    -- Red

        case state is
            when NS_GREEN =>
                ns_lights <= "100";  -- Green
            when NS_YELLOW =>
                ns_lights <= "010";  -- Yellow
            when EW_GREEN =>
                ew_lights <= "100";
            when EW_YELLOW =>
                ew_lights <= "010";
        end case;
    end process;

    comb2 : process (state)
    begin
        next_state <= NS_GREEN;
        case state is
            when NS_GREEN  => next_state <= NS_YELLOW;
            when NS_YELLOW => next_state <= EW_GREEN;
            when EW_GREEN  => next_state <= EW_YELLOW;
            when EW_YELLOW => next_state <= NS_GREEN;
        end case;
    end process;
end architecture;
```

### 7.3 Mealy Implementation (นับ counter เป็น input)

```vhdl
architecture mealy_rtl of traffic_light_mealy is
    type state_t is (NS_ACTIVE, EW_ACTIVE, TRANSITION);
    signal state : state_t;
    constant COUNT_MAX : integer := 5_000_000;
    signal counter : unsigned(22 downto 0);
    signal done    : std_logic;
begin
    -- Counter logic
    sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                counter <= (others => '0');
                state <= NS_ACTIVE;
            elsif counter = COUNT_MAX then
                counter <= (others => '0');
                done <= '1';
            else
                counter <= counter + 1;
                done <= '0';
            end if;
        end if;
    end process;

    -- NS/EW light control (Mealy)
    proc : process (state, done)
    begin
        ns_lights <= "001";    -- default Red
        ew_lights <= "001";    -- default Red

        case state is
            when NS_ACTIVE =>
                ns_lights <= "100";  -- Green
            when EW_ACTIVE =>
                ew_lights <= "100";
            when TRANSITION =>
                ns_lights <= "010";  -- Yellow both
                ew_lights <= "010";
        end case;

        if done = '1' then
            case state is
                when NS_ACTIVE => state <= TRANSITION;
                when TRANSITION => state <= EW_ACTIVE;
                when EW_ACTIVE => state <= TRANSITION;
            end case;
        end if;
    end process;
end architecture;
```

---

## 8. Advanced FSM Patterns

### 8.1 FSM with Timeout

```vhdl
-- FSM ที่ต้อง complete ภายในเวลาที่กำหนด
process (clk)
begin
    if rising_edge(clk) then
        if rst_n = '0' then
            state <= IDLE;
            timer <= (others => '0');
        else
            -- state register
            state <= next_state;

            -- timer
            if state /= IDLE and state /= DONE then
                if timer = TIMEOUT_LIMIT then
                    timer <= (others => '0');
                    error_state <= '1';   -- flag error
                else
                    timer <= timer + 1;
                end if;
            else
                timer <= (others => '0');
                error_state <= '0';
            end if;
        end if;
    end if;
end process;
```

### 8.2 Multi-FSM (Hierarchical)

```
   Top_FSM (IDLE, CONFIG, RUN, SHUTDOWN)
      ├── Config_FSM (subordinate: register access)
      ├── Run_FSM (subordinate: data processing)
      └── Shutdown_FSM (subordinate: power-off)
```

**Implementation:**

```vhdl
architecture hierarchical of top is
    type top_state_t is (S_IDLE, S_CONFIG, S_RUN, S_SHUTDOWN);
    signal top_state : top_state_t;

    type config_state_t is (C_IDLE, C_READ, C_WRITE, C_DONE);
    signal config_state : config_state_t;
    signal config_done : std_logic;
begin
    -- Top FSM
    top_sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                top_state <= S_IDLE;
            else
                case top_state is
                    when S_IDLE =>
                        if start_config = '1' then
                            top_state <= S_CONFIG;
                        end if;
                    when S_CONFIG =>
                        if config_done = '1' then
                            top_state <= S_RUN;
                        end if;
                    when S_RUN =>
                        if shutdown_req = '1' then
                            top_state <= S_SHUTDOWN;
                        end if;
                    when S_SHUTDOWN =>
                        top_state <= S_IDLE;
                end case;
            end if;
        end if;
    end process;

    -- Config FSM (active when top_state = S_CONFIG)
    config_sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' or top_state /= S_CONFIG then
                config_state <= C_IDLE;
                config_done <= '0';
            else
                case config_state is
                    when C_IDLE =>
                        config_state <= C_READ;
                    when C_READ =>
                        if read_complete = '1' then
                            config_state <= C_WRITE;
                        end if;
                    when C_WRITE =>
                        if write_complete = '1' then
                            config_state <= C_DONE;
                        end if;
                    when C_DONE =>
                        config_done <= '1';
                end case;
            end if;
        end if;
    end process;
end architecture;
```

### 8.3 FSM with Counter Integration

```vhdl
-- FSM ที่ต้องนับ event ภายใน state
process (clk)
    variable evt_count : integer := 0;
begin
    if rising_edge(clk) then
        if rst_n = '0' then
            state <= IDLE;
            event_counter <= (others => '0');
        else
            -- FSM transition
            case state is
                when IDLE =>
                    if start = '1' then
                        state <= WAIT_FOR_EVENTS;
                        event_counter <= (others => '0');
                    end if;
                when WAIT_FOR_EVENTS =>
                    if event_signal = '1' then
                        event_counter <= event_counter + 1;
                    elsif event_counter = TARGET_COUNT then
                        state <= DONE;
                    end if;
                when DONE =>
                    state <= IDLE;
            end case;
        end if;
    end if;
end process;
```

---

## 9. Common Pitfalls

### 9.1 Pitfall 1: Latch ใน FSM

```vhdl
-- BAD: ไม่มี default assignment → inferred latch
process (state, din)
begin
    case state is
        when S0 =>
            next_state <= S1;       -- ไม่ handle din='1'
        when S1 =>                -- ไม่ handle S0/S2/S3
            ...
    end case;
end process;
```

**Fix:** ใส่ default assignment

```vhdl
process (state, din)
begin
    next_state <= state;    -- default
    output <= '0';
    case state is
        when S0 => ... end case;
    end case;
end process;
```

### 9.2 Pitfall 2: Unreachable State

ถ้า state machine มี N states แต่จริง ๆ ใช้แค่ M states (M < N), synthesis tool จะ optimize แต่ lint check อาจเตือน

```vhdl
type state_t is (S0, S1, S2, S3, S4, S5);  -- 6 states
-- แต่ transition logic ไม่ครอบคลุม S4, S5
```

**Fix:** กำหนด state เท่าที่ใช้

### 9.3 Pitfall 3: Combinational Loop

ถ้า output logic ส่งผลต่อ state register โดยตรง เกิด combinational loop

```vhdl
-- BAD
process (state, output)     -- output มี effect บน state
begin
    ...
    state <= output;        -- ❌ combinational loop
end process;
```

**Fix:** ใช้ next_state รับ output

```vhdl
process (state)
begin
    next_state <= state;
    case state is
        when S0 =>
            output <= '1';
            next_state <= S1;   -- next_state ขึ้นกับ state เท่านั้น
    end case;
end process;
```

### 9.4 Pitfall 4: Race ใน Asynchronous Reset

```vhdl
-- BAD: ใช้ async reset + state เปลี่ยนแบบ race
process (clk, rst_n)
begin
    if rst_n = '0' then
        state <= S0;
    elsif rising_edge(clk) then
        state <= next_state;
    end if;
end process;

-- ถ้า rst_n de-asserts ใกล้ clk edge → metastability
```

**Fix:** ใช้ reset synchronizer (ดูบทเรียน Synchronous Design)

### 9.5 Pitfall 5: Missing Default in Case

```vhdl
case state is
    when S0 => next_state <= S1;
    when S1 => next_state <= S2;
    when S2 => next_state <= S3;
    -- ไม่มี when S3 => ...
end case;
```

**Fix:** ใส่ `when others => ...`

---

## 10. Best Practices

### 10.1 State Encoding Selection

| Condition | Recommended Encoding |
|---|---|
| Many states (N > 16), low-power | Binary |
| Few states (N ≤ 4), high-speed | One-Hot |
| Safe transitions, low-power | Gray |
| FSM with timeouts, small area | Binary |
| FPGA implementation | One-Hot (FPGA has FF-rich) |

### 10.2 Style Guidelines

| Rule | Reason |
|---|---|
| ใช้ 2-process หรือ 3-process (ไม่ใช่ 1-process) | Timing analysis ง่าย |
| ใส่ default assignment ในทุก case | ป้องกัน latch |
| ใส่ `when others => ...` ใน case | Safety |
| ใช้ enumerated type สำหรับ state | Readable, refactorable |
| แยก next_state และ output | Debug-friendly |
| ใช้ synchronous reset | Predictable timing |

### 10.3 Verification Tips

```vhdl
-- ใน testbench, traverse ทุก state
process
begin
    -- Force state transitions
    for trial in 0 to MAX_TRIAL loop
        wait until rising_edge(clk);
        din <= ...;
    end loop;

    -- Cover all states
    assert state_visited(S0) report "S0 not visited";
    assert state_visited(S1) report "S1 not visited";
    -- ...
end process;
```

### 10.4 Naming Convention

```vhdl
-- State names: uppercase + descriptive
type state_t is (IDLE, FETCH, DECODE, EXECUTE, WRITEBACK, HALT);

-- Internal signals:
signal state        : state_t;       -- current state
signal next_state   : state_t;       -- next state
signal state_done   : std_logic;      -- state exit signal
```

---

## 11. เปรียบเทียบใน Real-world

### 11.1 UART Transmitter (ใน Day 5 Mini Project)

```
   Moore:    IDLE → START → DATA (8 bits, one state each) → STOP → IDLE
             → 11 states total
             → glitch-free output, 1 cycle latency

   Mealy:    IDLE → START → DATA (8 bits in 1 state) → STOP → IDLE
             → 4 states total
             → faster response
```

### 11.2 AXI Handshake (used in SoC)

```
   State machine ใช้ Moore:
   - IDLE: drive WVALID = 0
   - SETUP: drive WVALID = 1
   - ACK: wait for WREADY

   Output คงที่ต่อ state → safe สำหรับ async crossing
```

### 11.3 CPU Instruction Decoder

```
   Mealy: output ขึ้นกับ opcode → micro-op ออกทันที
   Moore: ทุก instruction เป็น "state" → micro-op delay 1 cycle
```

---

## 12. Summary Comparison Table

| Property | Moore | Mealy |
|---|---|---|
| **Output Function** | f(state) | f(state, input) |
| **States needed** | More | Fewer |
| **FF count** | More | Less |
| **Output latency** | ≥ 1 cycle | 0 (combinational) |
| **Glitch risk** | None (registered) | Yes (combinational) |
| **Timing analysis** | Easy | Complex |
| **Verification** | Easier | Harder |
| **Formal verification** | Easy | Difficult |
| **Coding style** | 2-3 process | 1-2 process |
| **Use case** | Output stable | Low latency |
| **Example** | UART, AXI | SPI, I2C |

---

## 13. Key Takeaways

1. **Moore**: Output glitch-free, ใช้ state มากกว่า, latency ≥ 1
2. **Mealy**: Output ทันสัญญาณ, ใช้ state น้อยกว่า, latency 0
3. **State encoding** มีผลต่อ area + speed — เลือกให้เหมาะ
4. **Coding style** แนะนำ: 2-process (sync + combinational) หรือ 3-process
5. **Default assignment** + `when others` = ป้องกัน latch
6. **Reset**: synchronous preferred, asynchronous ต้องมี synchronizer
7. **Mealy registered output**: combine low latency + glitch-free
8. **Hierarchical FSM**: แตก large FSM เป็น multi-level FSM

---

## 14. อ้างอิง

- Cummings, C. E. "Verilog Nonblocking Assignments Demystified," SNUG 2002.
- Cummings, C. E. "FSM Design Techniques," SNUG 2000.
- "IEEE Standard VHDL Language Reference Manual (1076-2008)," Section on Sequential Statements.
- Pedroni, V. A. "Circuit Design with VHDL," MIT Press, 2004.
- "Questa Advanced Simulator User Manual," Section on State Machines.

---

> **หมายเหตุ:** เนื้อหานี้ออกแบบให้บรรยายได้ประมาณ 90-120 นาที รวม ASCII state diagrams, timing diagrams, code templates 7 แบบ (Moore 3 + Mealy 2 + Registered + Hierarchical) พร้อมใช้ประกอบการสอนภาคทฤษฎี Day 2 เช้า-บ่าย หรือแบ่งเป็น 2 mini-lectures (Moore 1 ชม + Mealy + Encoding 1 ชม.)

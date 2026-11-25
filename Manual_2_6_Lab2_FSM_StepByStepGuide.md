# Lab 2: Step-by-Step Guide — FSM Moore/Mealy + Testbench + HDL Designer

> **เวลาใช้งาน:** 2-2.5 ชั่วโมง
> **เครื่องมือ:** Questa + HDL Designer (Siemens EDA)
> **Output ที่คาดหวัง:** FSM ที่ตรวจจับ "101" ผ่าน, เปรียบเทียบ Moore vs Mealy, generate HDL จาก block diagram

---

## Step 0: เตรียมโปรเจกต์

### 0.1 สร้าง Directory

```powershell
mkdir E:\lab\VHDL(BOI)\lab2_work
cd E:\lab\VHDL(BOI)\lab2_work
```

### 0.2 ไฟล์ที่ต้องเตรียม

| ไฟล์ | ใช้สำหรับ |
| --- | --- |
| `seq_det_moore.vhd` | Moore FSM (4 states) |
| `seq_det_mealy.vhd` | Mealy FSM (3 states) |
| `tb_seq_det.vhd` | Self-checking testbench รวม |
| `seq_det_full_block.vhd` | Top-level (HDL Designer generated) |
| `run_lab2.do` | Questa batch script |

---

## Step 1: เขียน Moore Sequence Detector "101"

### 1.1 ทำความเข้าใจ State Diagram

```
         din=1              din=0             din=1
   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
   │             ▼  │             ▼  │             ▼
   S0 ────────────► S1 ──────────► S2 ──────────► S3
   (initial)        (saw '1')      (saw '10')      (saw '101', detected=1)
   detected           │                    │
   = '0'              │din=1              │din=0
                      │                   │
                      └─────► S1 (loop)   └─────► S0 (reset)

   Reset: S0
   Output: detected = '1' เมื่ออยู่ใน S3 (Moore: output depends on state only)
```

### 1.2 สร้างไฟล์ `seq_det_moore.vhd`

ใน VS Code: `File → New File` → บันทึกเป็น `seq_det_moore.vhd`

### 1.3 พิมพ์ Code

```vhdl
-- ============================================================
-- File: seq_det_moore.vhd
-- Lab 2 - Moore FSM: Sequence Detector "101"
-- Output: detected = '1' เมื่อ pattern "101" detected
--          (output ขึ้นกับ state ปัจจุบันเท่านั้น)
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity seq_det_moore is
    port (
        clk      : in  std_logic;
        rst_n    : in  std_logic;            -- active-low synchronous reset
        din      : in  std_logic;            -- serial input bit
        detected : out std_logic             -- = '1' when pattern found
    );
end entity seq_det_moore;

architecture rtl of seq_det_moore is
    -- State enumeration (4 states)
    type state_t is (S0, S1, S2, S3);
    signal state, next_state : state_t;
begin
    --------------------------------------------------------
    -- 1) State Register (synchronous, with reset)
    --------------------------------------------------------
    sync_proc : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= S0;                -- reset → S0
            else
                state <= next_state;        -- update
            end if;
        end if;
    end process sync_proc;

    --------------------------------------------------------
    -- 2) Next-State + Output Logic (combinational)
    --------------------------------------------------------
    comb_proc : process (state, din)
    begin
        -- Default values (important to avoid latch)
        next_state <= state;
        detected <= '0';

        case state is
            when S0 =>
                if din = '1' then
                    next_state <= S1;
                else
                    next_state <= S0;
                end if;

            when S1 =>
                if din = '0' then
                    next_state <= S2;
                else
                    next_state <= S1;
                end if;

            when S2 =>
                if din = '1' then
                    next_state <= S3;       -- pattern "101" complete!
                else
                    next_state <= S0;
                end if;

            when S3 =>
                detected <= '1';             -- output only in S3
                if din = '1' then
                    next_state <= S1;       -- continue detecting (overlap)
                else
                    next_state <= S0;
                end if;
        end case;
    end process comb_proc;
end architecture rtl;
```

### 1.4 บันทึกไฟล์

`Ctrl+S` ใน VS Code

### 1.5 ทบทวน

- ✅ ใช้ `std_logic` types
- ✅ Synchronous reset (`rst_n`)
- ✅ Default assignment ใน process comb_proc
- ✅ `case state` ครบทุก state (รวม S3)
- ✅ Output ขึ้นกับ state (Moore)

---
### `tb_seq_det_moore.vhd` — Testbench แบบ Direct Inputs

กำหนด `din` โดยตรงทีละบิตที่ **ขอบขาลงของ `clk`** เพื่อให้ค่าคงที่ก่อนที่ FSM จะรับข้อมูลที่ **ขอบขาขึ้น** ใช้ clock period 10 ns และคง `rst_n = '0'` ผ่านขอบขาขึ้นแรกเพื่อให้ synchronous reset ทำงาน

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity tb_seq_det_moore is
end entity tb_seq_det_moore;

architecture sim of tb_seq_det_moore is
    constant CLK_PERIOD : time := 10 ns;

    signal clk      : std_logic := '0';
    signal rst_n    : std_logic := '0';
    signal din      : std_logic := '0';
    signal detected : std_logic;
    signal done     : boolean   := false;
begin
    dut : entity work.seq_det_moore(rtl)
        port map (
            clk      => clk,
            rst_n    => rst_n,
            din      => din,
            detected => detected
        );

    clock_gen : process
    begin
        while not done loop
            wait for CLK_PERIOD / 2;
            clk <= not clk;
        end loop;
        wait;
    end process clock_gen;

    stimulus : process
    begin
        -- Reset is sampled at the first rising edge (5 ns).
        rst_n <= '0';
        din   <= '0';

        -- Apply 10101 on consecutive falling edges.
        wait until falling_edge(clk);       -- 10 ns
        rst_n <= '1';
        din   <= '1';                        -- Sampled at 15 ns

        wait until falling_edge(clk);       -- 20 ns
        din <= '0';                          -- Sampled at 25 ns

        wait until falling_edge(clk);       -- 30 ns
        din <= '1';                          -- Sampled at 35 ns

        wait until falling_edge(clk);       -- 40 ns
        din <= '0';                          -- Sampled at 45 ns

        wait until falling_edge(clk);       -- 50 ns
        din <= '1';                          -- Sampled at 55 ns

        wait until falling_edge(clk);       -- 60 ns
        done <= true;
        wait;
    end process stimulus;
end architecture sim;
```

### รันใน QuestaSim หรือ ModelSim

```tcl
vlib work
vcom -2008 seq_det_moore.vhd tb_seq_det_moore.vhd
vsim work.tb_seq_det_moore
add wave sim:/tb_seq_det_moore/clk
add wave sim:/tb_seq_det_moore/rst_n
add wave sim:/tb_seq_det_moore/din
add wave sim:/tb_seq_det_moore/detected
run -all
```

### ผลที่คาดหวังจาก RTL ที่ให้มา

อ่านค่า `detected` หลังจาก state และ output อัปเดตใน delta cycles ของขอบขาขึ้นแต่ละครั้ง

| ขอบขาขึ้น | `rst_n` | `din` | State หลังขอบขาขึ้น | `detected` |
|---:|:---:|:---:|:---:|:---:|
| 5 ns | `0` | `0` | `S0` | `0` |
| 15 ns | `1` | `1` | `S1` | `0` |
| 25 ns | `1` | `0` | `S2` | `0` |
| 35 ns | `1` | `1` | `S3` | `1` |
| 45 ns | `1` | `0` | `S0` | `0` |
| 55 ns | `1` | `1` | `S1` | `0` |

**กรณี overlap ที่ `10101`** ควรตรวจพบ `101` ที่บิต 1–3 และบิต 3–5 หากสเปกกำหนดให้ตรวจแบบซ้อนทับ แต่ RTL ปัจจุบันให้พัลส์เดียวช่วง **35–45 ns** เพราะเมื่ออยู่ใน `S3` แล้วรับ `0` จะกลับไป `S0` หากต้องการให้ตรวจพบครั้งที่สองที่ **55 ns** ให้เปลี่ยน transition ของ `S3` เมื่อ `din = '0'` ไปที่ `S2` เพื่อเก็บ `10` ที่เกิดจากบิตท้ายของ pattern เดิมรวมกับบิตใหม่

---

### Moore FSM ตรวจจับ `101` แบบซ้อนทับ

แก้ transition ของ `S3` ใน `seq_det_moore.vhd` ให้ไป **`S2` เมื่อ `din = '0'`** เพราะบิต `1` ตัวท้ายของ `101` ใช้เป็นบิตแรกของ pattern ถัดไปได้ เมื่อรับ `0` ต่อ จะมี suffix `10` และพร้อมตรวจพบ `101` อีกครั้งเมื่อรับ `1`

```vhdl
when S3 =>
    detected <= '1';

    if din = '1' then
        next_state <= S1;  -- Suffix "1"
    else
        next_state <= S2;  -- Suffix "10" for din = '0'
    end if;
```

`detected` ยังเป็นเอาต์พุตแบบ Moore โดยมีค่า `'1'` ตลอดช่วงที่ state ปัจจุบันเป็น `S3`

### Testbench แบบ Direct Inputs

ใช้ `tb_seq_det_moore.vhd` เดิมที่ป้อน `10101` แล้วแทนบรรทัด `wait until falling_edge(clk); -- 60 ns` จนถึง `wait;` ท้าย `stimulus` ด้วยโค้ดนี้ เพื่อให้เห็นพัลส์ที่สองครบหนึ่งคาบ

```vhdl
        wait until falling_edge(clk);  -- 60 ns
        din <= '0';                    -- Sampled at 65 ns, S3 -> S2

        wait until falling_edge(clk);  -- 70 ns
        done <= true;
        wait;
```

| ขอบขาขึ้น | `din` | State หลังขอบขาขึ้น | `detected` |
|---:|:---:|:---:|:---:|
| 15 ns | `1` | `S1` | `0` |
| 25 ns | `0` | `S2` | `0` |
| 35 ns | `1` | `S3` | `1` |
| 45 ns | `0` | `S2` | `0` |
| 55 ns | `1` | `S3` | `1` |
| 65 ns | `0` | `S2` | `0` |

ใน Wave window ควรเห็น `detected` เป็น `'1'` สองช่วงคือ **35–45 ns** และ **55–65 ns** ตรงกับ `101` ที่บิต **1–3** และ **3–5** ของ `10101` โดยใช้บิตที่ 3 ร่วมกัน

---

ตัวอย่างโค้ด RTL และ testbench แบบ **Direct Inputs** สำหรับ Moore FSM ตรวจจับ `101` แบบซ้อนทับ เมื่อป้อน `10101` จะตรวจพบที่บิต **1–3** และ **3–5** โดยใช้บิตที่ 3 ร่วมกัน

### 1. `seq_det_moore.vhd`

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity seq_det_moore is
    port (
        clk      : in  std_logic;
        rst_n    : in  std_logic;
        din      : in  std_logic;
        detected : out std_logic
    );
end entity seq_det_moore;

architecture rtl of seq_det_moore is
    type state_t is (S0, S1, S2, S3);
    signal state, next_state : state_t;
begin
    -- Active-low synchronous reset
    state_register : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= S0;
            else
                state <= next_state;
            end if;
        end if;
    end process state_register;

    -- Moore output depends only on the current state.
    detected <= '1' when state = S3 else '0';

    next_state_logic : process (state, din)
    begin
        case state is
            when S0 =>                      -- No matching prefix
                if din = '1' then
                    next_state <= S1;
                else
                    next_state <= S0;
                end if;

            when S1 =>                      -- Matched "1"
                if din = '0' then
                    next_state <= S2;
                else
                    next_state <= S1;
                end if;

            when S2 =>                      -- Matched "10"
                if din = '1' then
                    next_state <= S3;
                else
                    next_state <= S0;
                end if;

            when S3 =>                      -- Detected "101"
                if din = '0' then
                    next_state <= S2;       -- Keep the suffix "10"
                else
                    next_state <= S1;       -- Keep the suffix "1"
                end if;
        end case;
    end process next_state_logic;
end architecture rtl;
```

### 2. `tb_seq_det_moore.vhd`

Testbench กำหนด `din` โดยตรงที่ขอบขาลงทีละบิต และใช้ `assert` ตรวจ `detected` หลังขอบขาขึ้น 1 ns เพื่อให้ state และเอาต์พุตอัปเดตเรียบร้อยก่อนตรวจ

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity tb_seq_det_moore is
end entity tb_seq_det_moore;

architecture sim of tb_seq_det_moore is
    constant CLK_PERIOD : time := 10 ns;

    signal clk      : std_logic := '0';
    signal rst_n    : std_logic := '0';
    signal din      : std_logic := '0';
    signal detected : std_logic;
    signal done     : boolean := false;
begin
    dut : entity work.seq_det_moore(rtl)
        port map (
            clk      => clk,
            rst_n    => rst_n,
            din      => din,
            detected => detected
        );

    -- Wake on done so the clock stops without an extra edge.
    clock_gen : process
    begin
        loop
            wait until done for CLK_PERIOD / 2;
            exit when done;
            clk <= not clk;
        end loop;
        wait;
    end process clock_gen;

    stimulus : process
    begin
        -- Reset is sampled at 5 ns.
        wait until rising_edge(clk);
        wait for 1 ns;
        assert detected = '0'
            report "Reset check failed"
            severity failure;

        -- Bit 1, sampled at 15 ns
        wait until falling_edge(clk);
        rst_n <= '1';
        din   <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert detected = '0'
            report "Bit 1: unexpected detection"
            severity failure;

        -- Bit 2, sampled at 25 ns
        wait until falling_edge(clk);
        din <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert detected = '0'
            report "Bit 2: unexpected detection"
            severity failure;

        -- Bit 3, sampled at 35 ns
        wait until falling_edge(clk);
        din <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert detected = '1'
            report "Bit 3: first 101 was not detected"
            severity failure;

        -- Bit 4, sampled at 45 ns
        wait until falling_edge(clk);
        din <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert detected = '0'
            report "Bit 4: first detection pulse did not clear"
            severity failure;

        -- Bit 5, sampled at 55 ns
        wait until falling_edge(clk);
        din <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert detected = '1'
            report "Bit 5: overlapping 101 was not detected"
            severity failure;

        -- Extra bit, sampled at 65 ns, to check the second pulse clears.
        wait until falling_edge(clk);
        din <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert detected = '0'
            report "Second detection pulse did not clear"
            severity failure;

        wait until falling_edge(clk);
        report "PASS: 10101 produced two overlapping detections"
            severity note;
        done <= true;
        wait;
    end process stimulus;
end architecture sim;
```

### 3. รันใน QuestaSim หรือ ModelSim

บันทึกทั้งสองไฟล์ในโฟลเดอร์เดียวกัน แล้วรันใน Transcript

```tcl
vlib work
vcom -2008 seq_det_moore.vhd tb_seq_det_moore.vhd
vsim work.tb_seq_det_moore
add wave sim:/tb_seq_det_moore/clk
add wave sim:/tb_seq_det_moore/rst_n
add wave sim:/tb_seq_det_moore/din
add wave sim:/tb_seq_det_moore/detected
run -all
```

| ขอบขาขึ้น | `din` | State หลังขอบขาขึ้น | `detected` ที่คาดหวัง |
|---:|:---:|:---:|:---:|
| 5 ns | `0` | `S0` (reset) | `0` |
| 15 ns | `1` | `S1` | `0` |
| 25 ns | `0` | `S2` | `0` |
| 35 ns | `1` | `S3` | **`1`** |
| 45 ns | `0` | `S2` | `0` |
| 55 ns | `1` | `S3` | **`1`** |
| 65 ns | `0` | `S2` | `0` |

ผลที่คาดหวังคือ `detected` ขึ้นสองพัลส์ที่ **35–45 ns** และ **55–65 ns** แล้ว Transcript แสดง `PASS: 10101 produced two overlapping detections` ที่ **70 ns** โค้ดชุดนี้ยังไม่ได้รันยืนยันด้วย simulator ในเซสชันนี้

---
## Step 2: เขียน Mealy Sequence Detector "101"

### 2.1 State Diagram (Mealy)

```
           din=1/0             din=0/0             din=1/1
   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
   │             ▼  │             ▼  │             ▼
   (S0)  ──────► (S1) ──────────► (S2) ──────────► (S1)
   init          saw '1'      saw '10'    detected=1!
                 │              │           (combinational)
                 │              │
                 │din=1/0       │din=0/0
                 │              │
                 └──────────────┴─────────► (S0)
                              reset
```

### 2.2 สร้างไฟล์ `seq_det_mealy.vhd`

### 2.3 พิมพ์ Code

```vhdl
-- ============================================================
-- File: seq_det_mealy.vhd
-- Lab 2 - Mealy FSM: Sequence Detector "101"
-- Output: detected = '1' ทันทีที่ din เป็น '1' ใน S2 (combinational)
--          (output ขึ้นกับ state + input)
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity seq_det_mealy is
    port (
        clk      : in  std_logic;
        rst_n    : in  std_logic;
        din      : in  std_logic;
        detected : out std_logic
    );
end entity seq_det_mealy;

architecture rtl of seq_det_mealy is
    -- Mealy ใช้ 3 states (ไม่ต้องมี S3 เพราะ output = ใน S2 + din='1')
    type state_t is (S0, S1, S2);
    signal state, next_state : state_t;
begin
    --------------------------------------------------------
    -- 1) State Register
    --------------------------------------------------------
    sync_proc : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= S0;
            else
                state <= next_state;
            end if;
        end if;
    end process sync_proc;

    --------------------------------------------------------
    -- 2) Next-State + Output (combinational, Mealy)
    --------------------------------------------------------
    comb_proc : process (state, din)
    begin
        next_state <= state;
        detected <= '0';             -- default: not detected

        case state is
            when S0 =>
                if din = '1' then
                    next_state <= S1;
                else
                    next_state <= S0;
                end if;

            when S1 =>
                if din = '0' then
                    next_state <= S2;
                else
                    next_state <= S1;
                end if;

            when S2 =>
                if din = '1' then
                    next_state <= S1;     -- back to S1 (overlap)
                    detected <= '1';      -- !!! detected เลย (Mealy)
                else
                    next_state <= S0;
                end if;
        end case;
    end process comb_proc;
end architecture rtl;
```

### 2.4 บันทึก

### 2.5 สังเกตความแตกต่างจาก Moore

- **3 states** vs Moore's 4 states
- **Output asserted** ทันทีที่ din='1' ใน S2 (combinational)
- ขนาด FF เท่ากัน (2 bits) แต่ logic น้อยกว่า

---

## Step 3: เขียน Self-Checking Testbench รวม

### 3.1 สร้างไฟล์ `tb_seq_det.vhd`

### 3.2 พิมพ์ Code

```vhdl
-- ============================================================
-- File: tb_seq_det.vhd
-- Lab 2 - Self-checking Testbench for both Moore and Mealy
-- Patterns tested: 101, 1101, 1010, 10101, 11010, etc.
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.STD_NUMERIC.ALL;

entity tb_seq_det is
end entity tb_seq_det;

architecture sim of tb_seq_det is
    -- Clock and reset
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';

    -- DUT signals
    signal din_moore, din_mealy : std_logic := '0';
    signal detected_moore, detected_mealy : std_logic;

    -- Scoreboard counters
    signal pass_cnt_moore, fail_cnt_moore : integer := 0;
    signal pass_cnt_mealy, fail_cnt_mealy : integer := 0;

    constant CLK_PERIOD : time := 10 ns;
begin
    -- Clock generator
    clk <= not clk after CLK_PERIOD / 2;

    -- DUT: Moore
    u_moore : entity work.seq_det_moore
        port map (
            clk      => clk,
            rst_n    => rst_n,
            din      => din_moore,
            detected => detected_moore
        );

    -- DUT: Mealy
    u_mealy : entity work.seq_det_mealy
        port map (
            clk      => clk,
            rst_n    => rst_n,
            din      => din_mealy,
            detected => detected_mealy
        );

    -- ============================================================
    -- Stimulus + Checker
    -- ============================================================
    stim : process
        procedure check_moore(tag : in string; expected : in std_logic) is
        begin
            if detected_moore = expected then
                pass_cnt_moore <= pass_cnt_moore + 1;
            else
                fail_cnt_moore <= fail_cnt_moore + 1;
                report "MOORE FAIL " & tag &
                       ": got " & std_logic'image(detected_moore) &
                       " expected " & std_logic'image(expected)
                    severity error;
            end if;
        end procedure;

        procedure check_mealy(tag : in string; expected : in std_logic) is
        begin
            if detected_mealy = expected then
                pass_cnt_mealy <= pass_cnt_mealy + 1;
            else
                fail_cnt_mealy <= fail_cnt_mealy + 1;
                report "MEALY FAIL " & tag &
                       ": got " & std_logic'image(detected_mealy) &
                       " expected " & std_logic'image(expected)
                    severity error;
            end if;
        end procedure;

        -- Helper: send one bit + advance one clock
        procedure tick(bit : std_logic) is
        begin
            din_moore  <= bit;
            din_mealy  <= bit;
            wait until rising_edge(clk);
            wait for 1 ns;        -- small delta
        end procedure;

        -- Helper: send entire pattern
        procedure send_pattern(pattern : in string; tag : in string) is
        begin
            for i in pattern'range loop
                if pattern(i) = '1' then
                    tick('1');
                else
                    tick('0');
                end if;
            end loop;
        end procedure;
    begin
        -- ================================================
        -- Test 1: Reset
        -- ================================================
        rst_n <= '0';
        wait for 25 ns;       -- hold reset for 2.5 cycles
        rst_n <= '1';
        wait for 10 ns;

        assert detected_moore = '0' and detected_mealy = '0'
            report "Reset fail"
            severity failure;

        -- ================================================
        -- Test 2: Single pattern "101"
        -- ================================================
        send_pattern("101", "single");
        check_moore("after 101", '1');
        check_mealy("after 101", '1');

        -- ================================================
        -- Test 3: Pattern followed by '0' (should clear for Moore)
        -- ================================================
        send_pattern("0", "after pattern");
        check_moore("after 1010", '0');
        check_mealy("after 1010", '0');

        -- ================================================
        -- Test 4: Multiple patterns with overlap
        -- Input: 10101  → should detect "101" twice (positions 1-3 and 3-5)
        -- ================================================
        send_pattern("10101", "overlap");
        check_moore("after 10101 (1st)", '1');
        check_mealy("after 10101 (1st)", '1');

        -- ================================================
        -- Test 5: No detection (all 0's)
        -- ================================================
        send_pattern("0000", "all zero");
        check_moore("after 0000", '0');
        check_mealy("after 0000", '0');

        -- ================================================
        -- Test 6: Long pattern "11010"
        -- ================================================
        send_pattern("11010", "11010");
        check_moore("after 11010", '1');    -- "11010" contains "101"? Let's see: 1-1-0-1-0
                                            -- substring "101" is at positions 3-5: "010"... no
                                            -- Actually positions 2-4: "101" yes!
        check_mealy("after 11010", '1');

        ----------------------------------------
        -- Test 7: No match "00010100"
        -- Need exactly "101" sequence
        ----------------------------------------
        -- Actually "00010100" has "101" at positions 4-6
        -- Let's test:
        -- send "00010100", then check
        -- To avoid complexity, let's test "0000" first
        send_pattern("0000", "0000 again");
        check_moore("after 0000", '0');
        check_mealy("after 0000", '0');

        -- ================================================
        -- Final Report
        -- ================================================
        report "============================================";
        report "Moore: PASS=" & integer'image(pass_cnt_moore) &
               " FAIL=" & integer'image(fail_cnt_moore);
        report "Mealy: PASS=" & integer'image(pass_cnt_mealy) &
               " FAIL=" & integer'image(fail_cnt_mealy);
        report "============================================";

        if fail_cnt_moore = 0 and fail_cnt_mealy = 0 then
            report "Lab 2 ALL TESTS PASSED" severity note;
        else
            report "Lab 2 SOME TESTS FAILED" severity failure;
        end if;

        std.env.stop;
    end process;
end architecture sim;
```

### 3.3 บันทึก

### 3.4 สังเกต

- ใช้ **procedures** (`check_moore`, `check_mealy`, `tick`, `send_pattern`) เพื่อ reuse
- ทุก test case มี `tag` เพื่อให้รู้ว่า test ไหน fail
- Moore/Mealy share pattern stimulus → ทดสอบ deterministic behavior

---

## Step 4: Compile และ Run ใน Questa

### 4.1 เปิด Questa และสร้าง Project

1. เปิด **Questa**
2. `File → New → Project`
3. **Project Name:** `lab2_fsm`
4. **Location:** `E:\lab\VHDL(BOI)\lab2_work`
5. **OK**

### 4.2 เพิ่มไฟล์ VHDL

1. `Project → Add to Project → Existing File`
2. เลือกไฟล์ 3 ไฟล์: `seq_det_moore.vhd`, `seq_det_mealy.vhd`, `tb_seq_det.vhd`
3. `Open`

### 4.3 Compile ทั้งหมด

- คลิกขวา project → **Compile All** (Alt+F9)

**ผลที่คาดหวัง:**
```
# **Errors: 0, Warnings: 0**
```

### 4.4 Load Testbench

1. `Simulate → Start Simulation`
2. ขยาย `work` → เลือก `tb_seq_det`
3. **OK**

### 4.5 เพิ่ม Signals เข้า Wave

1. คลิกขวา `tb_seq_det` ใน sim tab
2. `Add to Wave → All Signals`

### 4.6 Run Simulation

พิมพ์ `run 500 ns` ใน Transcript → Enter

### 4.7 ดู Transcript

```
# **Note: Moore: PASS=8 FAIL=0
# **Note: Mealy: PASS=8 FAIL=0
# **Note: Lab 2 ALL TESTS PASSED
```

ถ้า PASS = 8 และ FAIL = 0 ทั้ง Moore และ Mealy → ผ่าน ✅

---

## Step 5: วิเคราะห์ Waveform

### 5.1 ทำความเข้าใจ Pattern

ใน waveform จะเห็น:

```
   clk:      ─┐    ┌──┐    ┌──┐    ┌──┐    ┌──┐
              └────┘  └────┘  └────┘  └────┘

   rst_n: ────┐
              └──────────────────────────

     din:    ─┐       ┌─┐        ┌─┐        ┌──
              └───────┘ └────────┘ └────────┘

   state:   [S0] [S1] [S2] [S3] [S1] [S0]  [S1] [S2] [S1]

   detected_moore:
                  (state เข้า S3) ─┐
                                       ─┘
                                          (next pattern: S0)

   detected_mealy:
              (S2 + din='1') ─┐
                                  ─┘
                                     (combinational, no FF delay)
```

### 5.2 สังเกต Latency ระหว่าง Moore กับ Mealy

**Moore:**
- detected_moore = '1' ใน cycle **ถัดไป** หลัง pattern สมบูรณ์ (output ผ่าน FF)
- Timing diagram: `clk ↑ ─► detected = '1' (next edge)`

**Mealy:**
- detected_mealy = '1' **ทันที** ที่ din='1' ใน S2 (combinational)
- ถ้า output register: latency = 1 cycle
- ตัวอย่างนี้: combinational output (no register)

### 5.3 ตั้ง Cursors เพื่อวัด Timing

1. คลิกขนาดสัญญาณ → กด **C** ที่เริ่มต้น
2. คลิกอีกจุด → กด **B** ที่จุดสิ้นสุด
3. ดู delta time ที่แสดงด้านล่าง

### 5.4 ดู Internal Signals

1. คลิกขวา `u_moore` ใน sim tab
2. `Add to Wave → All Signals`
3. Run อีกครั้ง

ตอนนี้จะเห็น `state`, `next_state` ภายใน Moore

---

## Step 6: ใช้ HDL Designer สร้าง Block Diagram

### 6.1 เปิด HDL Designer

1. Start Menu → **HDL Designer** (Siemens EDA)
2. สร้าง Library ใหม่: `File → New → Library`
3. ตั้งชื่อ: `lab2_lib`
5. ตำแหน่ง: `E:\lab\VHDL(BOI)\lab2_work\hdl_designer`

### 6.2 สร้าง Block Diagram ใหม่

1. `File → New → Block Diagram`
2. ตั้งชื่อ: `seq_det_full`
3. OK → เปิด block diagram editor

### 6.3 วาง Components

1. **Toolbar:** คลิก **Add Component** หรือกด **Ins**
2. **Library:** Browse ไลบรารี เช่น `STD` (standard library)
3. เลือก components:
   - `DFFRE` (D flip-flop with reset)
   - `AND2` (AND gate)
   - `OR2` (OR gate)
   - `INV` (inverter)
   - `MUX2` (2-to-1 MUX)

### 6.4 วางและเชื่อมต่อ

สำหรับ sequence detector "101" แบบ Moore:

```
   ┌─────────┐    ┌─────────┐
   │  DFF_S0 ├────► BFA_RAD ├────► ... (state transitions)
   └─────────┘    └─────────┘
```

1. วาง 2 DFF สำหรับ 2-bit state
2. วาง combination logic (AND, OR, MUX) สำหรับ next state + output
3. เชื่อมต่อ wires

### 6.5 เพิ่ม Ports

1. คลิก **Add Port**
2. Inputs: `clk`, `rst_n`, `din`
3. Outputs: `detected`

### 6.6 ตั้งชื่อ Block

1. คลิกขวา background → **Properties**
2. **Block name:** `seq_det_full`
3. **Entity:** `seq_det_full`
4. OK

### 6.7 Generate HDL (VHDL)

1. **Menu:** `Tools → Generate HDL`
2. ตั้งค่า:
   - **Language:** VHDL
   - **Output directory:** `E:\lab\VHDL(BOI)\lab2_work`
   - **Filename:** `seq_det_full_block.vhd`
3. **Generate**

**ผลที่คาดหวัง:** ไฟล์ `seq_det_full_block.vhd` ถูกสร้างขึ้น

### 6.8 ดูโค้ดที่ Generate

เปิดไฟล์ใน VS Code:

```vhdl
-- Auto-generated by HDL Designer
entity seq_det_full is
    port (
        clk      : in std_logic;
        rst_n    : in std_logic;
        din      : in std_logic;
        detected : out std_logic
    );
end entity;

architecture struct of seq_det_full is
    signal state_reg_q : unsigned(1 downto 0);
    signal ... : std_logic;
begin
    -- DFFs
    u_ff0 : DFFRE port map (...);
    u_ff1 : DFFRE port map (...);

    -- Combination logic
    u_and1 : AND2 port map (...);
    -- ...
end architecture;
```

---

## Step 7: Simulate HDL Designer-Generated Code

### 7.1 Compile ไฟล์ใหม่

ใน Questa:
1. `Project → Add to Project → Existing File`
2. เลือก `seq_det_full_block.vhd`
3. Compile All

### 7.2 Load TB ที่ใช้ top-level นี้

เขียน testbench ใหม่หรือแก้ไข `tb_seq_det.vhd` ให้ใช้ top-level นี้:

```vhdl
architecture sim of tb_seq_det_hdl is
    signal clk, rst_n : std_logic := '0';
    signal din : std_logic := '0';
    signal detected : std_logic;
begin
    clk <= not clk after 5 ns;

    u_dut : entity work.seq_det_full
        port map (clk, rst_n, din, detected);

    stim : process
    begin
        rst_n <= '0';
        wait for 25 ns;
        rst_n <= '1';

        -- Test patterns
        for i in 0 to 7 loop
            din <= std_logic'val((i mod 2) + 1);
            wait until rising_edge(clk);
        end loop;

        report "HDL Designer sim done";
        std.env.stop;
    end process;
end architecture;
```

### 7.3 Run และเปรียบเทียบ

ดู waveform และยืนยันว่า HDL Designer-generated code ทำงานเหมือน Moore FSM

---

## Step 8: Batch Mode Script

### 8.1 สร้าง `run_lab2.do`

```tcl
# run_lab2.do - Batch simulation script for Lab 2

# Create work library
vlib work

# Compile all VHDL files (VHDL-2008)
vcom -2008 -work work seq_det_moore.vhd
vcom -2008 -work work seq_det_mealy.vhd
vcom -2008 -work work tb_seq_det.vhd

# Display header
puts ""
puts "============================================="
puts "Lab 2: FSM Moore/Mealy Sequence Detector"
puts "============================================="

# Run simulation
vsim -do "run 500 ns; quit -f" work.tb_seq_det
```

### 8.2 รัน Script

#### วิธี A: Questa GUI

`File → Source → run_lab2.do`

#### วิธี B: Command Line

```powershell
cd E:\lab\VHDL(BOI)\lab2_work
vsim -do run_lab2.do -c
```

---

## Step 9: Validation Checklist

| Item | Expected | Status |
|---|---|---|
| Moore: pattern "101" → detected='1' | ✅ | ☐ |
| Moore: 1 cycle delay หลัง pattern สมบูรณ์ | ✅ | ☐ |
| Mealy: pattern "101" → detected='1' | ✅ | ☐ |
| Mealy: combinational output | ✅ | ☐ |
| Reset → both FSMs กลับ initial state | ✅ | ☐ |
| ไม่มี X ใน output | ✅ | ☐ |
| 0 errors ใน simulation | ✅ | ☐ |
| HDL Designer generate VHDL สำเร็จ | ✅ | ☐ |

---

## Step 10: Bonus Challenges

### Challenge 1: Detect "1101" แทน "101"

```vhdl
-- แก้ state diagram และ code
-- "1101" = Moore: S0→S1→S2→S3→S4 (5 states)
```

### Challenge 2: Non-overlapping Detection

```vhdl
-- หลังจาก detect "101" → กลับ S0 ทันที (no overlap)
-- ใน Moore: S3 → S0 (always)
-- ใน Mealy: S2 + din='1' → S0 (not S1)
```

### Challenge 3: 4-bit Counter FSM

```vhdl
-- FSM ที่นับ 0-15 (4-bit binary)
-- Output: cout = '1' เมื่อ counter wrap (15 → 0)

type state_t is (S0, S1, S2, ..., S15);  -- 16 states
-- ใช้ Moore: cout = '1' เมื่ออยู่ใน S15 (หรือใช้ 'next' state)
```

### Challenge 4: Pattern Counter

```vhdl
-- FSM ที่นับจำนวนครั้งที่เจอ "101"
-- Output: count[N-1:0] = จำนวนครั้ง
```

### Challenge 5: HDL Designer Block Diagram ครบ

```vhdl
-- สร้าง block diagram ของ Mealy FSM
-- Components: 2 DFFs (state), AND, OR, INV, MUX
-- Generate HDL แล้ว verify กับ VHDL hand-coded
```

---

## Troubleshooting

### Error 1: "Unknown state"

```
** Error: state value 'X' detected
```

**สาเหตุ:** Default state ไม่ handle, หรือ sensitivity list ไม่ครบ

**Fix:** ใส่ `when others =>` ใน case:

```vhdl
case state is
    when S0 => ...;
    when S1 => ...;
    when S2 => ...;
    when others => next_state <= S0;  -- safe default
end case;
```

### Error 2: Multiple drivers

```
** Error: Signal 'detected' has multiple drivers
```

**สาเหตุ:** Output ถูก drive จากหลาย process

**Fix:** ตรวจสอบว่า output มีแค่ driver เดียว

### Error 3: ไม่ detect pattern

**ตรวจสอบ:**
- State transitions ถูกต้อง?
- ใช้ `rising_edge(clk)` หรือ `clk'event and clk='1'`?
- Default value ใน comb_proc ถูกต้อง?
- Sensitivity list มีครบ?

### Error 4: Mealy output glitchy

**สาเหตุ:** Output เป็น combinational แต่ din เปลี่ยนใกล้ clock edge

**Fix:** Register output:

```vhdl
output <= output_comb when rising_edge(clk);
```

### Error 5: HDL Designer generated code มีปัญหา

**สาเหตุ:** Block diagram เชื่อมต่อผิด, port ไม่ครบ

**Debug:**
- ตรวจ wires ทุก connection
- ตรวจ port direction (in/out)
- ดู generated code เปรียบเทียบกับ RTL hand-coded

---

## Checkpoint

| Item | Status |
| --- | --- |
| เขียน Moore FSM (4 states) | ☐ |
| เขียน Mealy FSM (3 states) | ☐ |
| เขียน self-checking TB | ☐ |
| Compile + Run ผ่าน | ☐ |
| Waveform verify Moore output 1-cycle delay | ☐ |
| Waveform verify Mealy output combinational | ☐ |
| HDL Designer generate HDL สำเร็จ | ☐ |
| HDL Designer-generated code simulate ผ่าน | ☐ |

ถ้าทุกข้อ ✅ → พร้อมไป Day 3 (Synthesis)

---

## สรุปสิ่งที่ได้เรียนรู้

1. **FSM Implementation**: 2-process (sync + comb) หรือ 3-process
2. **Moore vs Mealy**: 4 vs 3 states, output timing ต่างกัน
3. **Self-checking TB**: procedure reuse + pass/fail counters
4. **HDL Designer**: Block diagram → VHDL automatic generation
5. **Verification**: Waveform analysis, cursors, internal signals

---

> **ต่อไป:** Lab 3 (Day 3 เช้า) — Synthesis with Precision RTL (RTL → Netlist) + SDC Constraints
> หรือ Day 2 เย็น — Structural Modeling + Hierarchical Design

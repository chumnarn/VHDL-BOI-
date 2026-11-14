# รายละเอียดเชิงลึก: RTL Coding Guidelines (Latch, CDC) & Testbench

> เนื้อหานี้ออกแบบมาให้นำไปแทรกเป็นส่วนขยายในหัวข้อ **2.4 RTL Design Guidelines** และ **2.5 Testbench** ของคู่มือหลักสูตร (วันที่ 2)
> เหมาะสำหรับการบรรยาย 90–120 นาที

---

# ส่วนที่ A: Latch Prevention — เชิงลึก

## A.1 Latch คืออะไร

**Latch** คือ memory element ที่ **เก็บค่าเมื่อ enable signal ไม่ active** ต่างจาก flip-flop ที่ใช้ clock edge ในการ latch

```
   ┌─────────────────┐
   │    Latch        │
   │                 │
   d ──┐   ┌───────┐ │  q
       ├──►│memory ├──┤─────
   e ──┘   └───────┘    │
        (transparent    │
         when e='1')    │
                          q คงค่าเมื่อ e='0'
```

### A.1.1 Flip-Flop vs Latch

| Property | Flip-Flop (FF) | Latch |
|---|---|---|
| Control signal | clk (edge) | enable (level) |
| Timing | Edge-triggered (synchronous) | Level-sensitive (transparent) |
| Timing analysis | Easy | Hard |
| Synthesis | Standard cell (DFFRX1) | Special cell (DLATCHX1) |
| Use in modern ASIC | ✅ Default | ⚠️ Rare, special only |

### A.1.2 ทำไม latch ถึงเป็นปัญหา

1. **Timing analysis ยาก**
   - Latch transparent ในช่วง enable → signal propagation ขึ้นกับ hold/setup ของทั้ง 2 phases
   - Static timing analysis ไม่สามารถ catch ได้ทุก case

2. **Race condition**
   - ถ้า enable glitches → latch อาจ latch ค่าๆ ผิด
   - ในระบบ asynchronous, race ระหว่าง data และ enable

3. **Power issue**
   - Latch transparent ทำให้ internal node switching activity สูง
   - Dynamic power สูงกว่า FF

4. **Verification issue**
   - ใน simulation, latch behavior ขึ้นกับ enable timing
   - Simulation coverage ไม่ guarantee silicon behavior

5. **DFT (Design for Test) ยาก**
   - Scan chain ใช้ FF → latch scan ไม่ตรง pattern
   - Stuck-at fault coverage ตก

## A.2 Latch เกิดขึ้นได้อย่างไร

Latch inferred เมื่อ **output ไม่ถูก assign ในทุก code path**

### A.2.1 Case 1: incomplete `if`

```vhdl
process (a, sel)
begin
    if sel = '1' then
        y <= a;
    end if;        -- ❌ no else!
end process;
-- เมื่อ sel='0': y ยังไม่ถูก assign → latch
```

### A.2.2 Case 2: incomplete `case`

```vhdl
process (sel)
begin
    case sel is
        when "00" => y <= '0';
        when "01" => y <= '1';
        when "10" => y <= a;
        -- ❌ when "11" ไม่มี!
    end case;
end process;
-- เมื่อ sel="11": latch
```

### A.2.3 Case 3: `case` ไม่มี `when others`

```vhdl
process (state)
begin
    case state is
        when S0 => y <= '0';
        when S1 => y <= '1';
        when S2 => y <= a;
    end case;
    -- ถ้า state='X' หรือ state outside → latch
end process;
```

## A.3 วิธีป้องกัน Latch

### A.3.1 Pattern 1: Default Assignment

```vhdl
process (a, sel)
begin
    y <= '0';        -- default (สำคัญ!)
    if sel = '1' then
        y <= a;
    end if;
end process;
```

### A.3.2 Pattern 2: Full `else`

```vhdl
process (a, b, sel)
begin
    if sel = '1' then
        y <= a;
    else                  -- ✅ full else
        y <= b;
    end if;
end process;
```

### A.3.3 Pattern 3: `when others`

```vhdl
process (state)
begin
    case state is
        when S0 => y <= '0';
        when S1 => y <= '1';
        when S2 => y <= a;
        when others => y <= '0';    -- ✅ safety
    end case;
end process;
```

### A.3.4 Pattern 4: Default for ports, Concat

```vhdl
process (a, b, c, sel)
begin
    case sel is
        when "00" => y <= a;
        when "01" => y <= b;
        when "10" => y <= c;
        when others => y <= (others => '0');   -- all zeros
    end case;
end process;
```

### A.3.5 Pattern 5: Synchronous Process (FF-based)

```vhdl
process (clk)
begin
    if rising_edge(clk) then
        if sel = '1' then
            y <= a;
        else
            y <= b;        -- ✅ FF with full mux, no latch
        end if;
    end if;
end process;
```

## A.4 Tool Detection

### A.4.1 Precision RTL Warning

```
** Warning: Inferred latch for signal 'y' (dataflow view)
   Source: mux.vhd, line 25
   Reason: output 'y' not assigned in all paths of process
```

### A.4.2 Questa Warning

```
** Warning: LATCH inferred for signal 'y' from process
```

### A.4.3 Lint Tools (เร็วกว่า)

- **Verible**: detect latch at lint level
- **SpyGlass**: comprehensive lint
- **HAL**: ASIC-level lint

## A.5 ตัวอย่างจริง: MUX with AND-conditional

### A.5.1 BAD: `if` with `and`

```vhdl
-- BAD
process (a, b, sel)
begin
    if sel = '1' and b = '1' then
        y <= a;
    end if;        -- ❌ latch when condition false
end process;
```

### A.5.2 GOOD

```vhdl
-- GOOD (Option 1: full else)
process (a, b, sel)
begin
    if sel = '1' and b = '1' then
        y <= a;
    else
        y <= '0';
    end if;
end process;

-- GOOD (Option 2: split into nested if)
process (a, b, sel)
begin
    y <= '0';
    if sel = '1' then
        if b = '1' then
            y <= a;
        end if;
    end if;
end process;

-- GOOD (Option 3: synchronous FF-based)
process (clk)
begin
    if rising_edge(clk) then
        if sel = '1' and b = '1' then
            y <= a;
        else
            y <= '0';
        end if;
    end if;
end process;
```

## A.6 Edge Cases ที่อาจเกิด Latch

### A.6.1 Tri-state buffer

```vhdl
process (en, din)
begin
    if en = '1' then
        dout <= din;
    end if;        -- ❌ ไม่มี else: dout จะ latch
end process;

-- GOOD
process (en, din)
begin
    if en = '1' then
        dout <= din;
    else
        dout <= 'Z';
    end if;
end process;
```

### A.6.2 Conditional Signal Initialization

```vhdl
-- BAD
process (rst_n, data)
begin
    if rst_n = '0' then
        output <= '0';
    elsif data_valid = '1' then
        output <= data;
    end if;        -- ❌ latch
end process;
```

### A.6.3 Read from inout port

```vhdl
-- ⚠️ ถ้าอ่าน inout โดยไม่ drive → latch
process (oe, data_in, io_pin)
begin
    if oe = '1' then
        io_pin <= data_in;       -- drive
    end if;
    -- ตอน oe='0', ถ้าไม่ assign ค่าใด → latch
end process;

-- GOOD
process (oe, data_in, io_pin)
begin
    if oe = '1' then
        io_pin <= data_in;
    else
        io_pin <= 'Z';
    end if;
end process;
```

---

# ส่วนที่ B: Clock Domain Crossing (CDC) — เชิงลึก

## B.1 ปัญหา CDC

เมื่อ signal ข้าม clock domain, มีความเสี่ยง 2 อย่าง:

### B.1.1 Metastability

เมื่อ data เปลี่ยนใกล้ clock edge มาก, FF อาจค้างที่ intermediate voltage

```
                    ┌──────┐
   data:    ────────┘      └──────────
                    ↑      ↑
                    ↑      data_transition_time
                    ↑
                 clock_edge (FF samples data)
                 
   Output FF:    ?  →  may be metastable for τ seconds
                  (oscillation)
```

**Probability ต่ำแต่ไม่ใช่ 0** สามารถเกิดได้

### B.1.2 Data Corruption

แม้ไม่ metastable, **sample time ไม่แน่นอน** → data ที่ sample ผิด

```
   clk_fast: ─┐    ┌──┐    ┌──┐    ┌──┐
              └────┘  └────┘  └────┘  └────
   
   data:  ──┐                ┌──
             └────────────────┘
                       ↑
                       FF_A latches 0
              flips → FF_A latches 1
              
   clk_slow: ───┐         ┌──
                   └───────┘
                       ↑
                       FF_B samples — which value?
                       
   If FF_B samples between changes → data corruption!
```

## B.2 CDC Categories

### B.2.1 Single-Bit CDC

- 1-bit signal (e.g., flag, enable)
- ใช้ **2-FF synchronizer**

```
   src_domain         dst_domain
   ───────────        ───────────
   flag ──► FF1 ──► FF2 ──► synced_flag
   (async) (clk_dst) (clk_dst)
```

### B.2.2 Multi-Bit CDC

- Multi-bit signal (e.g., counter value, address)
- ต้องใช้ **Gray code** หรือ **handshake**

**❌ ผิด:**

```vhdl
-- BAD: ส่ง 8-bit counter ข้าม domain ตรง ๆ
counter_fast (8 bits) ──► [2-FF each bit] ──► counter_slow
                              ↑ problem: 8 bits เปลี่ยนพร้อมกัน
                              bits แต่ละ bit sync คนละ cycle
                              → counter_slow อาจเป็นค่าผิด
```

**✅ ถูก: ใช้ Gray code**

```vhdl
-- GOOD
gray_code = counter XOR (counter >> 1)
gray_code (8 bits) ──► [2-FF each bit] ──► counter_slow (after reverse)
                                  ↑ only 1 bit changes per count
```

### B.2.3 Burst CDC (FIFO)

- ส่งข้อมูลหลาย byte พร้อมกัน
- ใช้ **asynchronous FIFO**

```
   wr_clk domain         rd_clk domain
   ─────────────         ─────────────
   write_data ─►  ┌──┐  ──► read_data
   write_ptr ──►  │FIFO │   ◄── read_ptr
                 └──┘
```

## B.3 2-FF Synchronizer — Implementation

### B.3.1 Code Template

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cdc_sync is
    generic (
        WIDTH : integer := 1
    );
    port (
        clk_dst : in  std_logic;
        rst_n   : in  std_logic;
        async_in : in  std_logic_vector(WIDTH-1 downto 0);
        sync_out : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity;

architecture rtl of cdc_sync is
    signal sync1, sync2 : std_logic_vector(WIDTH-1 downto 0);
begin
    sync : process (clk_dst)
    begin
        if rising_edge(clk_dst) then
            if rst_n = '0' then
                sync1 <= (others => '0');
                sync2 <= (others => '0');
            else
                sync1 <= async_in;
                sync2 <= sync1;
            end if;
        end if;
    end process;

    sync_out <= sync2;
end architecture;
```

### B.3.2 Multi-Stage (3-FF) Synchronizer (สำหรับ high-speed)

```vhdl
-- 3 stages for high-speed data crossing
sync : process (clk_dst)
begin
    if rising_edge(clk_dst) then
        sync1 <= async_in;
        sync2 <= sync1;
        sync3 <= sync2;
    end if;
end process;

sync_out <= sync3;
```

## B.4 Gray Code Converter

### B.4.1 Theory

Gray code เป็น binary encoding ที่ **เปลี่ยนครั้งละ 1 bit** ระหว่างค่าที่ติดกัน

```
   Binary | Gray
   -------|-------
   000    | 000
   001    | 001
   010    | 011
   011    | 010
   100    | 110
   101    | 111
   110    | 101
   111    | 100
```

**Conversion:**
```
   Gray → Binary: b[i] = b[i+1] XOR g[i]
   Binary → Gray: g[i] = b[i] XOR b[i+1]
```

### B.4.2 Counter with Gray Code

```vhdl
architecture rtl of gray_counter is
    signal bin_cnt : unsigned(3 downto 0) := (others => '0');
    signal gray_cnt : std_logic_vector(3 downto 0);
begin
    sync : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                bin_cnt <= (others => '0');
            else
                bin_cnt <= bin_cnt + 1;
            end if;
        end if;
    end process;

    -- Binary to Gray: g[i] = b[i] XOR b[i+1]
    gray_cnt <= std_logic_vector(bin_cnt xor ('0' & bin_cnt(3 downto 1)));

    -- 2-FF synchronize gray_cnt
    u_sync : entity work.cdc_sync
        generic map (WIDTH => 4)
        port map (
            clk_dst  => clk_slow,
            rst_n    => rst_n,
            async_in => gray_cnt,
            sync_out => gray_synced
        );

    -- Gray to Binary: b[i] = b[i+1] XOR g[i]
    bin_synced(3) <= gray_synced(3);
    for i in 2 downto 0 loop
        bin_synced(i) <= bin_synced(i+1) xor gray_synced(i);
    end loop;
end architecture;
```

## B.5 Handshake CDC

### B.5.1 Theory

ใช้ request-acknowledgment protocol เพื่อส่ง multi-bit data อย่างปลอดภัย

```
   src_domain                 dst_domain
   ──────────                 ──────────
   data (bus) ─────┬──req──► FF1 ──► FF2 ──► ack_in
                   │              │
                   │     ack_out ──┴──
                   │     
   data ──────────►│ (ack รับ → อัปเดต data ใหม่)
```

### B.5.2 Implementation

```vhdl
architecture rtl of handshake_cdc is
    type state_t is (IDLE, SEND, WAIT_ACK);
    signal state : state_t;
    signal req, ack_src, ack_dst : std_logic;
    signal ack_synced : std_logic;
begin
    -- Sync ack from dst to src domain
    u_ack_sync : entity work.cdc_sync
        port map (clk_dst => clk_src, async_in => ack_dst, sync_out => ack_synced);

    -- Source FSM
    sync_src : process (clk_src)
    begin
        if rising_edge(clk_src) then
            if rst_n = '0' then
                state <= IDLE;
                req <= '0';
            else
                case state is
                    when IDLE =>
                        if data_valid = '1' then
                            req <= '1';
                            state <= WAIT_ACK;
                        end if;
                    when WAIT_ACK =>
                        if ack_synced = '1' then
                            req <= '0';
                            state <= IDLE;
                        end if;
                    when others => state <= IDLE;
                end case;
            end if;
        end if;
    end process;

    -- Destination FSM
    sync_dst : process (clk_dst)
    begin
        if rising_edge(clk_dst) then
            if rst_n = '0' then
                ack_dst <= '0';
                data_captured <= (others => '0');
            elsif req_synced = '1' then
                data_captured <= data;       -- capture data
                ack_dst <= '1';
            else
                ack_dst <= '0';
            end if;
        end if;
    end process;

    -- Sync req
    u_req_sync : entity work.cdc_sync
        port map (clk_dst => clk_dst, async_in => req, sync_out => req_synced);
end architecture;
```

## B.6 Asynchronous FIFO

### B.6.1 Concept

ใช้สำหรับ burst data transfer:

```
   wr_clk domain              rd_clk domain
   ─────────────              ─────────────
   wr_data ──►┌─────┐         ┌─────┐
   wr_en  ──► │FIFO │ rd_data ──►
              │     │ rd_en  ──►
   wr_ptr ────►│     │ ◄─── rd_ptr
              │     │
              └─────┘
   full  ◄───────────────► empty
```

### B.6.2 Implementation Overview

```vhdl
architecture rtl of async_fifo is
    constant DEPTH : integer := 16;
    constant WIDTH : integer := 8;
    constant ADDR_WIDTH : integer := 4;

    signal mem : array (0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);

    signal wr_ptr, rd_ptr : unsigned(ADDR_WIDTH downto 0);   -- 1 extra for wrap
    signal wr_ptr_gray, rd_ptr_gray : std_logic_vector(ADDR_WIDTH downto 0);
    signal wr_ptr_synced, rd_ptr_synced : std_logic_vector(ADDR_WIDTH downto 0);

    signal full, empty : std_logic;
begin
    -- Write port (wr_clk domain)
    wr_proc : process (wr_clk)
    begin
        if rising_edge(wr_clk) then
            if wr_en = '1' and full = '0' then
                mem(to_integer(wr_ptr(ADDR_WIDTH-1 downto 0))) <= wr_data;
                wr_ptr <= wr_ptr + 1;
            end if;
        end if;
    end process;

    wr_ptr_gray <= std_logic_vector(wr_ptr xor ('0' & wr_ptr(ADDR_WIDTH-1 downto 1)));

    -- Sync wr_ptr to rd_clk domain
    u_sync_wr : entity work.cdc_sync
        generic map (WIDTH => ADDR_WIDTH+1)
        port map (clk_dst => rd_clk, async_in => wr_ptr_gray, sync_out => wr_ptr_synced);

    -- Read port (rd_clk domain)
    rd_proc : process (rd_clk)
    begin
        if rising_edge(rd_clk) then
            if rd_en = '1' and empty = '0' then
                rd_data <= mem(to_integer(rd_ptr(ADDR_WIDTH-1 downto 0)));
                rd_ptr <= rd_ptr + 1;
            end if;
        end if;
    end process;

    rd_ptr_gray <= std_logic_vector(rd_ptr xor ('0' & rd_ptr(ADDR_WIDTH-1 downto 1)));

    -- Sync rd_ptr to wr_clk domain
    u_sync_rd : entity work.cdc_sync
        generic map (WIDTH => ADDR_WIDTH+1)
        port map (clk_dst => wr_clk, async_in => rd_ptr_gray, sync_out => rd_ptr_synced);

    -- Full/Empty detection
    -- full: wr_ptr is 1 cycle wrapping a depth/2 ahead of rd_ptr
    -- empty: pointers match exactly
    process (wr_clk)
    begin
        if rising_edge(wr_clk) then
            -- Compare rd_ptr_synced (gray) with wr_ptr (gray)
            full <= '1' when (rd_ptr_synced = not std_logic_vector(wr_ptr) and
                              wr_ptr(ADDR_WIDTH) /= rd_ptr_synced(ADDR_WIDTH))
                    else '0';
        end if;
    end process;

    process (rd_clk)
    begin
        if rising_edge(rd_clk) then
            empty <= '1' when wr_ptr_synced = rd_ptr_gray else '0';
        end if;
    end process;
end architecture;
```

## B.7 CDC Verification

### B.7.1 Static Checks (Lint)

- **CDC Tool**: Questa CDC, SpyGlass CDC, Real Intent
- **Detect**: missing synchronizer, multi-bit crossing without Gray, async reset CDC

### B.7.2 Dynamic Checks (Simulation)

```systemverilog
// SVA-style assertion (in SystemVerilog TB)
property p_cdc_single;
    @(posedge clk_dst) disable iff (!rst_n)
    $stable(async_in) |-> ##2 sync_out;
endproperty
```

### B.7.3 SDC Constraints for CDC

```tcl
# False path ที่ async boundary
set_false_path -from [get_pins {cdc_sync_inst/sync1_reg[*]/C}] \
                -to   [get_pins {cdc_sync_inst/sync2_reg[*]/D}]

# Max delay สำหรับ synchronized signal
set_max_delay -from [get_pins {cdc_sync_inst/sync2_reg[*]/C}] \
              -to   [get_pins {consumer_inst/data_in_reg[*]/D}] 4.0
```

## B.8 CDC Best Practices

| Rule | Reason |
|---|---|
| ✅ Single-bit ใช้ 2-FF synchronizer | ลด MTBF < 1 year |
| ✅ Multi-bit ใช้ Gray code + 2-FF | Single-bit transition |
| ✅ Burst data ใช้ async FIFO | Built-in pointer sync |
| ✅ Acknowledge signal ต้อง sync กลับ | Round-trip handshake |
| ❌ ห้ามส่ง data > 1 bit ตรง ๆ | Multiple bit transitions |
| ❌ ห้ามใช้ combinational clock (clock divider โดยตรง) | Glitch |
| ❌ ห้ามมี combinational loop ใน CDC path | Oscillation |

---

# ส่วนที่ C: Testbench — เชิงลึก

## C.1 Testbench Anatomy

### C.1.1 โครงสร้าง

```vhdl
entity tb_design is
end entity;

architecture sim of tb_design is
    -- 1) Signals ต่อกับ DUT
    signal clk, rst_n : std_logic;
    signal din, dout  : std_logic_vector(...);
begin
    -- 2) DUT instantiation
    dut : entity work.design port map (...);

    -- 3) Clock generator
    clk <= not clk after CLK_PERIOD / 2;

    -- 4) Stimulus generator
    stim : process
    begin
        -- generate inputs
        wait;
    end process;

    -- 5) Checker / monitor
    checker : process
    begin
        -- verify outputs
        wait;
    end process;
end architecture;
```

### C.1.2 ทำไมต้องมี Testbench

1. **Verify functional correctness** — design ทำงานตาม spec หรือไม่
2. **Coverage** — ทุก case ได้รับการทดสอบ?
3. **Regression** — เมื่อ design เปลี่ยน testbench เก่ายัง valid
4. **Documentation** — testbench เป็น executable spec

## C.2 Stimulus Generation

### C.2.1 Pattern 1: Directed Testing

ใช้ค่าเฉพาะเจาะจง:

```vhdl
stim : process
begin
    -- Reset
    rst_n <= '0';
    wait for 100 ns;
    rst_n <= '1';

    -- Test 1
    din <= "0000";
    wait for 100 ns;
    assert dout = "0000";

    -- Test 2
    din <= "0001";
    wait for 100 ns;
    assert dout = "0001";

    -- ...
    report "Done";
    std.env.stop;
end process;
```

**ข้อดี:** deterministic, debug ง่าย
**ข้อเสีย:** ไม่ครอบคลุม corner case

### C.2.2 Pattern 2: Exhaustive Testing

ทดสอบ **ทุก combination**:

```vhdl
stim : process
begin
    for i in 0 to 255 loop
        for j in 0 to 255 loop
            din_a <= std_logic_vector(to_unsigned(i, 8));
            din_b <= std_logic_vector(to_unsigned(j, 8));
            wait until rising_edge(clk);
            wait for 5 ns;
            -- check result
        end loop;
    end loop;
    report "Exhaustive complete";
end process;
```

**ใช้กับ:** small designs, critical correctness

### C.2.3 Pattern 3: Random Testing (Constrained Random)

สุ่มค่า input แต่มี constraint:

```vhdl
-- VHDL-2008 pseudo-random
stim : process
    variable seed : integer := 42;
    function rand_int(min, max : integer) return integer is
        variable r : real;
    begin
        uniform(seed, r);
        return min + integer(r * real(max - min + 1));
    end function;
begin
    for trial in 0 to 999 loop
        din <= std_logic_vector(to_unsigned(rand_int(0, 255), 8));
        wait until rising_edge(clk);
    end loop;
end process;
```

**ใช้กับ:** larger designs, หา unexpected bugs

### C.2.4 Pattern 4: Protocol-aware Stimulus

สร้าง input ตาม protocol spec:

```vhdl
stim : process
    procedure send_iot(...) is ...
begin
    -- 1. Wait until idle
    while busy = '1' loop
        wait until rising_edge(clk);
    end loop;

    -- 2. Drive data
    data_valid <= '1';
    data_in <= ...;

    -- 3. Wait for ready
    wait until rising_edge(clk);
    while ready = '0' loop
        wait until rising_edge(clk);
    end loop;

    -- 4. End
    data_valid <= '0';
end process;
```

## C.3 Self-Checking Testbench

### C.3.1 Concept

Testbench ที่ **ตรวจสอบผลอัตโนมัติ** แล้วรายงาน pass/fail — ไม่ต้อง inspect waveform ทุกครั้ง

```vhdl
-- Self-checking พื้นฐาน
stim : process
    variable pass_cnt : integer := 0;
    variable fail_cnt : integer := 0;
begin
    -- Test 1
    a <= '0'; b <= '1'; wait for 10 ns;
    if y /= '1' then
        report "FAIL: expected 1, got " & std_logic'image(y) severity error;
        fail_cnt := fail_cnt + 1;
    else
        pass_cnt := pass_cnt + 1;
    end if;

    -- Test 2
    ...

    report "PASS=" & integer'image(pass_cnt) & " FAIL=" & integer'image(fail_cnt);
    std.env.stop;
end process;
```

### C.3.2 Procedure-Based Checker

```vhdl
-- Procedure สำหรับ reuse
procedure check_and(a, b : std_logic; expected : std_logic) is
begin
    assert y = expected
        report "AND fail: a=" & std_logic'image(a) &
               " b=" & std_logic'image(b) &
               " got=" & std_logic'image(y)
        severity failure;
end procedure;

-- เรียกใช้
check_and('0', '0', '0');
check_and('1', '1', '1');
```

### C.3.3 Assertion-Based (Immediate)

```vhdl
-- Concurrent assertions
assert_y_zero : assert y = '0' report "y should be 0" severity error;

-- In process
process (clk)
begin
    if rising_edge(clk) then
        if ready = '1' and data_valid = '1' then
            assert transaction_count <= MAX_TRANSACTIONS
                report "Too many transactions"
                severity failure;
        end if;
    end if;
end process;
```

## C.4 Reference Model

### C.4.1 Concept

ใช้ **high-level model** (เช่น C-like, behavioral) ที่ทำงานเหมือน DUT แต่เขียนง่าย — เปรียบเทียบผล

```
   ┌─────────────┐         ┌─────────────┐
   │  DUT (RTL)  │         │ Reference   │
   │             │         │ Model       │
   │  inputs ────┼────┬────►             │
   │             │    │   │             │
   │  outputs ───┼────┼─┐ │             │
   │             │  │ │ │ │ outputs     │
   └─────────────┘  ▼ ▼ ▼ └─────────────┘
                    │
                    ▼
              Compare results
```

### C.4.2 Implementation: 8-bit Adder

```vhdl
-- DUT
entity adder8_dut is
    port (
        a, b : in  unsigned(7 downto 0);
        cin  : in  std_logic;
        sum  : out unsigned(7 downto 0);
        cout : out std_logic
    );
end entity;

architecture rtl of adder8_dut is
begin
    process (a, b, cin)
        variable va, vb, vs : unsigned(8 downto 0);
    begin
        va := "0" & a;
        vb := "0" & b;
        vs := va + vb + (0 => cin, others => '0');
        sum <= vs(7 downto 0);
        cout <= vs(8);
    end process;
end architecture;

-- Reference model
entity adder8_ref is
    port (
        a, b : in  unsigned(7 downto 0);
        cin  : in  std_logic;
        sum  : out unsigned(7 downto 0);
        cout : out std_logic
    );
end entity;

architecture behavioral of adder8_ref is
begin
    process (a, b, cin)
        variable vsum : integer;
    begin
        vsum := to_integer(a) + to_integer(b) + cin;
        vsum := ((vsum mod 256) + 256) mod 256;
        sum <= to_unsigned(vsum, 8);
        cout <= '1' when (to_integer(a) + to_integer(b) + cin) > 255 else '0';
    end process;
end architecture;
```

### C.4.3 TB Comparing DUT vs Reference

```vhdl
entity tb_adder8_compare is
end entity;

architecture sim of tb_adder8_compare is
    signal a, b       : unsigned(7 downto 0);
    signal cin         : std_logic;
    signal sum_dut, sum_ref : unsigned(7 downto 0);
    signal cout_dut, cout_ref : std_logic;
    signal pass_cnt, fail_cnt : integer := 0;
begin
    u_dut : entity work.adder8_dut
        port map (a, b, cin, sum_dut, cout_dut);

    u_ref : entity work.adder8_ref
        port map (a, b, cin, sum_ref, cout_ref);

    stim : process
    begin
        -- ทุก combination เปรียบเทียบ
        for av in 0 to 255 loop
            for bv in 0 to 255 loop
                for c in 0 to 1 loop
                    a <= to_unsigned(av, 8);
                    b <= to_unsigned(bv, 8);
                    cin <= std_logic'val(c + 1);
                    wait for 5 ns;

                    if sum_dut /= sum_ref or cout_dut /= cout_ref then
                        fail_cnt <= fail_cnt + 1;
                        report "FAIL: a=" & integer'image(av) &
                               " b=" & integer'image(bv) &
                               " cin=" & integer'image(c) &
                               " dut=" & integer'image(to_integer(sum_dut)) &
                               " ref=" & integer'image(to_integer(sum_ref))
                            severity error;
                    else
                        pass_cnt <= pass_cnt + 1;
                    end if;
                end loop;
            end loop;
        end loop;

        report "PASS=" & integer'image(pass_cnt) & " FAIL=" & integer'image(fail_cnt);
        if fail_cnt = 0 then
            report "ALL EXHAUSTIVE TESTS PASSED" severity note;
        end if;
        std.env.stop;
    end process;
end architecture;
```

## C.5 Scoreboard

### C.5.1 Concept

Scoreboard เป็น **transaction-level verifier** — รับ transaction ทั้งหมด, ตรวจสอบลำดับ/ค่า

```
   ┌────────────┐
   │ Stimulus   │
   └────────────┘
        │
        ▼
   ┌────────────┐         ┌────────────┐
   │   DUT      │────────▶│ Scoreboard │
   └────────────┘ outputs│            │
                          │ Expected:  │
                          │ tx_data =  │
                          │ [0x55, ...] │
                          └────────────┘
                                │
                                ▼
                          Match or fail
```

### C.5.2 Implementation: UART TX Scoreboard

```vhdl
architecture sim of tb_uart_scoreboard is
    signal clk : std_logic := '0';
    signal tx : std_logic;
    signal baud_tick : std_logic;
    -- Scoreboard queue
    type byte_array is array (natural range <>) of std_logic_vector(7 downto 0);
    constant QUEUE_SIZE : integer := 16;
    signal expected_q : byte_array(0 to QUEUE_SIZE-1);
    signal q_head, q_tail : integer := 0;

    signal collected_bit : std_logic;
    signal bit_count : integer range 0 to 10 := 0;
    signal last_tx : std_logic;
    signal current_byte : std_logic_vector(7 downto 0) := (others => '0');
begin
    clk <= not clk after 5 ns;

    -- Baud tick generation
    process (clk)
        variable cnt : integer := 0;
    begin
        if rising_edge(clk) then
            cnt := cnt + 1;
            if cnt = 868 then
                cnt := 0;
                baud_tick <= '1';
            else
                baud_tick <= '0';
            end if;
        end if;
    end process;

    -- DUT
    dut : entity work.uart_tx
        port map (clk, rst_n, din, din_vld, din_rdy, baud_tick, tx);

    -- Bit collector (samples tx at baud rate)
    collector : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                bit_count <= 0;
                last_tx <= '1';
                current_byte <= (others => '0');
            else
                last_tx <= tx;

                -- Detect start bit
                if last_tx = '1' and tx = '0' and bit_count = 0 then
                    bit_count <= 1;        -- start bit detected
                elsif bit_count > 0 and bit_count < 9 then
                    -- Collect data bit
                    current_byte(bit_count - 1) <= tx;
                    bit_count <= bit_count + 1;
                elsif bit_count = 9 then
                    -- Stop bit received → check scoreboard
                    if current_byte = expected_q(q_head) then
                        report "Match: 0x" &
                               integer'image(to_integer(unsigned(current_byte)))
                            severity note;
                        q_head <= (q_head + 1) mod QUEUE_SIZE;
                    else
                        report "MISMATCH: got 0x" &
                               integer'image(to_integer(unsigned(current_byte))) &
                               " expected 0x" &
                               integer'image(to_integer(unsigned(expected_q(q_head))))
                            severity error;
                    end if;
                    bit_count <= 0;
                end if;
            end if;
        end if;
    end process;

    -- Stimulus + scoreboard queue loading
    stim : process
    begin
        -- Load expected queue
        expected_q(0) <= x"55";
        expected_q(1) <= x"AA";
        expected_q(2) <= x"42";
        expected_q(3) <= x"3C";
        q_tail <= 4;

        -- Send bytes
        din <= x"55"; din_vld <= '1';
        wait until rising_edge(clk);
        din_vld <= '0';
        wait until q_head = 1;

        din <= x"AA"; din_vld <= '1';
        wait until rising_edge(clk);
        din_vld <= '0';
        wait until q_head = 2;

        -- ...
        wait until q_head = q_tail;
        report "All UART bytes transmitted and scored";
        std.env.stop;
    end process;
end architecture;
```

## C.6 Functional Coverage

### C.6.1 Concept

Functional coverage วัดว่า testbench ทดสอบ **ทุก scenario** ที่สำคัญ (ตาม spec) หรือยัง

### C.6.2 VHDL Implementation (limited)

VHDL ไม่มี `covergroup` ในตัว (ต่างจาก SystemVerilog) แต่สามารถ implement ได้:

```vhdl
-- Coverage tracker
process (clk)
    variable covered_states : std_logic_vector(15 downto 0) := (others => '0');
    variable covered_inputs : std_logic_vector(255 downto 0) := (others => '0');
begin
    if rising_edge(clk) then
        -- Mark state coverage
        case state is
            when S0 => covered_states(0) := '1';
            when S1 => covered_states(1) := '1';
            when S2 => covered_states(2) := '1';
            when S3 => covered_states(3) := '1';
            when others => null;
        end case;

        -- Mark input coverage
        if din = '1' then
            covered_inputs(0) := '1';
        else
            covered_inputs(1) := '1';
        end if;

        -- Report coverage
        if now = SIM_END_TIME then
            report "State coverage = " &
                   integer'image(popcount(covered_states)) & "/16";
        end if;
    end if;
end process;
```

### C.6.3 SystemVerilog Cover System (ทางไวกว่า)

```systemverilog
covergroup cg_alu @(posedge clk);
    cp_op : coverpoint op {
        bins add = {2'b00};
        bins sub = {2'b01};
        bins and_op = {2'b10};
        bins or_op  = {2'b11};
    }
    cp_a : coverpoint a {
        bins zero = {8'h00};
        bins max  = {8'hFF};
        bins others = default;
    }
    cx_op_a : cross cp_op, cp_a;
endgroup
```

## C.7 File I/O ใน Testbench

### C.7.1 อ่าน/เขียนไฟล์ (test vector)

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use std.textio.all;

process
        variable l : line;
        variable v_line : integer;
    begin
        -- อ่านจากไฟล์
        file_open(f, "input.txt", read_mode);
        while not endfile(f) loop
            readline(f, l);
            read(l, v_line);
            -- apply v_line to design
        end loop;
        file_close(f);

        -- เขียนลงไฟล์
        file_open(f, "output.txt", write_mode);
        write(l, string'("Result: "));
        write(l, result);
        writeline(f, l);
        file_close(f);
    end process;
```

## C.8 Waveform Dumping (สำหรับ debug)

```tcl
# In Questa do-file
vcd file my_waveform.vcd
vcd add /tb_top/*
run 1 us
vcd flush
```

หรือใน VHDL testbench:

```vhdl
-- ใช้ vendor-specific library (e.g., Questa VCD API)
use std.textio.all;

process
    variable l : line;
begin
    -- log events
    write(l, string'("Time="));
    write(l, now);
    write(l, string'(" din="));
    write(l, din);
    writeline(output, l);
    wait for 10 ns;
end process;
```

## C.9 Advanced Techniques

### C.9.1 Transaction-Level Modeling (TLM)

```vhdl
-- Define transaction record
type transaction_t is record
    addr : unsigned(7 downto 0);
    data : unsigned(7 downto 0);
    we   : std_logic;
end record;

-- Mailbox between blocks
shared variable mailbox_h : mailbox;

-- Producer
proc1 : process
begin
    for i in 0 to 99 loop
        mailbox_h.put(new_tx(i));
    end loop;
end process;

-- Consumer
proc2 : process
    variable t : transaction;
begin
    for i in 0 to 99 loop
        mailbox_h.get(t);
        -- process transaction
    end loop;
end process;
```

### C.9.2 Constrained Random (VHDL-2008)

```vhdl
-- VHDL-2008 มี IEEE.MATH_REAL.UNIFORM
function uniform_random(min, max : integer) return integer is
    variable seed : integer := 42;
    variable r : real;
begin
    uniform(seed, r);
    return min + integer(r * real(max - min));
end function;
```

## C.10 Coverage-Driven Verification Flow

```
   ┌─────────────────────────────────────────────────────┐
   │ Spec → Feature List → Verification Plan            │
   └─────────────────────────────────────────────────────┘
                          │
                          ▼
   ┌─────────────────────────────────────────────────────┐
   │ TB: stimulus + checker + coverage                   │
   └─────────────────────────────────────────────────────┘
                          │
                          ▼
   ┌─────────────────────────────────────────────────────┐
   │ Run → Coverage Report → Identify Gaps              │
   └─────────────────────────────────────────────────────┘
                          │
                          ▼
   ┌─────────────────────────────────────────────────────┐
   │ Add tests for gaps → Re-run → Coverage Increases   │
   └─────────────────────────────────────────────────────┘
                          │
                          ▼ (repeat)
   ┌─────────────────────────────────────────────────────┐
   │ Coverage ≥ 95% → Sign-off                          │
   └─────────────────────────────────────────────────────┘
```

## C.11 Best Practices

| Rule | Reason |
|---|---|
| ✅ ใช้ self-checking TB | Automation, regression |
| ✅ ใช้ reference model | Catch RTL bugs |
| ✅ ใช้ scoreboard | Transaction-level verification |
| ✅ ใช้ functional coverage | Measure completeness |
| ✅ แยก TB, REF, DUT เป็นไฟล์ต่างหาก | Reusability |
| ✅ ใช้ consistent naming | Readability |
| ❌ ห้าม hard-code timing (`wait for X ns`) ใน checker | Fragile |
| ❌ ห้ามมี TB logic ที่ synthesize ไม่ได้ใน design | Synthesis issues |

## C.12 Common Pitfalls

### C.12.1 Pitfall 1: Race Condition

```vhdl
-- BAD
process
begin
    rst_n <= '0';
    wait for 5 ns;
    rst_n <= '1';
    -- ❌ clk อาจสร้าง race
end process;

-- GOOD
process
begin
    rst_n <= '0';
    wait for 100 ns;       -- ให้แน่ใจว่า reset active ก่อน clk เริ่มต้น
    wait until rising_edge(clk);
    rst_n <= '1';
end process;
```

### C.12.2 Pitfall 2: Stimulus ขัดจังหวะ clk

```vhdl
-- BAD
process
begin
    din <= "1010";
    wait for 1 ns;          -- แย่! ไม่ align กับ clock
end process;

-- GOOD
process
begin
    wait until rising_edge(clk);    -- align กับ clock edge
    din <= "1010";
end process;
```

### C.12.3 Pitfall 3: TB ขึ้นกับ internal signal

```vhdl
-- BAD: TB ขึ้นกับ internal FF ของ DUT
stim : process
begin
    wait until rising_edge(clk);
    wait until internal_counter = X; -- ผูกกับ implementation
end process;

-- GOOD: TB ขึ้นกับ I/O เท่านั้น
stim : process
begin
    wait until rising_edge(clk);
    send_request;
    wait until response_received = '1';
end process;
```

### C.12.4 Pitfall 4: ไม่ handle X ใน TB

```vhdl
-- BAD: ตรวจ dout = "0000" โดยไม่สนใจ X
assert dout = "0000";

-- GOOD: ตรวจ dout = X แยก
if dout = "XXXX" then
    report "DOUT contains X (uninitialized)!" severity error;
elsif dout /= "0000" then
    report "DOUT mismatch" severity error;
end if;
```

---

## ส่วนที่ D: Summary

### D.1 Latch Prevention — Key Rules

1. ✅ Default assignment ทุก combinational process
2. ✅ Full `else` clause ทุก `if`
3. ✅ `when others` clause ทุก `case`
4. ✅ Tri-state: explicit `'Z'` ใน else branch
5. ✅ ใช้ FF-based design แทน transparent latch

### D.2 CDC — Key Rules

1. ✅ Single-bit: 2-FF synchronizer (3-FF สำหรับ high-speed)
2. ✅ Multi-bit: Gray code + 2-FF sync
3. ✅ Burst data: Async FIFO
4. ❌ ห้ามส่ง data > 1 bit ตรง ๆ
5. ❌ ห้ามใช้ combinational clock

### D.3 Testbench — Key Rules

1. ✅ Self-checking TB (procedures + assert)
3. ✅ Reference model (high-level + DUT comparison)
4. ✅ Scoreboard (transaction-level)
5. ✅ Functional coverage (ตรวจว่าครอบคลุมทุก case)
6. ❌ ห้าม hard-code timing
7. ❌ ห้าม depend อาจารย์ internal signal

---

## อ้างอิง

- Cummings, "Verilog Nonblocking Assignments Demystified," SNUG 2002.
- "IEEE Standard VHDL Language Reference Manual (1076-2008)," Section on Sequential Statements.
- "Questa Advanced Simulator User Manual" — Coverage, Reference Models.
- Bergeron, J. "Writing Testbenches: Functional Verification of HDL Models," Springer, 2003.
- Spear, P. "SystemVerilog for Verification," Springer, 2006.
- "IEEE 1800-2017 SystemVerilog LRM" — covergroup, assertion class.

---

> **หมายเหตุ:** เนื้อหานี้ออกแบบให้บรรยายได้ประมาณ 90-120 นาที รวม ASCII diagrams, code examples ครบถ้วน พร้อมใช้ประกอบการสอนภาคทฤษฎี Day 2 เย็น หรือแบ่งเป็น 3 mini-lectures (Latch 30 นาที + CDC 30 นาที + Testbench 60 นาที)
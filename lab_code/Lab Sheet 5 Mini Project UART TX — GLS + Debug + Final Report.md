# Lab Sheet 5: Mini Project UART TX — GLS + Debug + Final Report

Nov 22, 2026 · @Chumnarn Punyasai

เมื่อจบแลปนี้ ผู้เรียนจะพา UART transmitter ผ่าน flow ครบทุกขั้น คือ RTL → testbench → synthesis → netlist + SDF → GLS หลาย corner → debug → รายงาน โดยใช้ทักษะจาก Lab 1–4 ทั้งหมด

## ข้อมูลแลป

| หัวข้อ | รายละเอียด |
| --- | --- |
| เวลา | 2.5–3 ชั่วโมง |
| ระดับ | สูง (รวมทุก Lab) |
| ดีไซน์ | `uart_tx_all`: UART TX แบบ 8N1, 2 baud rate (115200 และประมาณ 921600 ที่ clock 100 MHz), handshake แบบ ready/valid |
| เครื่องมือ | Questa (GLS), GHDL + Yosys + LibreLane (synthesis, P&R, SDF), Precision RTL (ทางเลือกสำหรับ FPGA) |
| สิ่งที่ต้องส่ง | โฟลเดอร์ `mini_project/` ทั้งหมด โดยเฉพาะ `docs/final_report.md` ที่ทุกตัวเลขมี log อ้างอิง |

### วัตถุประสงค์การเรียนรู้

1. ออกแบบ FSM ที่ output เป็น register ทั้งหมด (ไม่มี glitch)
2. เขียน testbench ที่มี receiver model, scoreboard, PSL assertion และ watchdog
3. สังเคราะห์ VHDL ด้วย GHDL + Yosys และสร้าง netlist + SDF ด้วย LibreLane
4. รัน GLS ทุก corner และ debug X, timing violation, glitch
5. เขียนรายงาน verification ที่อ้างอิงหลักฐานได้

### สิ่งที่เปลี่ยนจากคู่มือต้นฉบับ

| ปัญหาในต้นฉบับ | ใน Lab Sheet นี้ |
| --- | --- |
| ให้คัดลอก `uart_tx_all.vhd` และ `tb_uart_tx.vhd` "จาก Lab 1–4" แต่ไม่มี Lab ไหนสร้าง UART TX | เขียนทั้งสองไฟล์ใหม่ตามสเปกที่คู่มือบอก (port จาก SDC, test 9 ข้อจากตาราง) ผ่าน GHDL แล้ว |
| Precision + library สมมติ `gscl45nm` + `write_sdf` | Yosys → LibreLane ได้ netlist + SDF จริงของ sky130 (เหมือน Lab 4) ส่วน Precision ใช้สำหรับ FPGA |
| SDC มี `set_false_path` กับ synchronous reset, cell `INVX1` ที่ไม่มีใน sky130 | SDC ใหม่ที่ใช้กับ LibreLane ได้ |
| `report_timing` "ใน Questa transcript" | Questa ไม่มีคำสั่งนี้ ใช้รายงาน STA จาก LibreLane |
| แก้ glitch ด้วย "เพิ่ม delay cell / hysteresis" | แก้ที่ต้นเหตุ: ให้ output ออกจาก flip-flop โดยตรง |
| ตัวเลข coverage (96.4%, 91.8% ฯลฯ) และผล `PASS: 9` ทุก corner เป็นตัวอย่างสมมติ | ให้ผู้เรียนกรอกจาก log จริง |
| สคริปต์ multi-corner มี `quit -f` ใน loop, `vsim -sdf` | ใช้ `quit -sim` และ `-sdfmin`/`-sdfmax` (ตาม Lab 4) |
| สรุป "READY FOR TAPE-OUT" | สรุปตามหลักฐาน และระบุ signoff ที่ยังขาด |

> 📝 **หมายเหตุ:** RTL, testbench, การใส่ bug, synthesis ด้วย Yosys และ post-synthesis simulation ผ่านการรันจริงด้วย GHDL 4.1 + Yosys 0.33 แล้ว ส่วน LibreLane และ GLS ใน Questa ยังไม่ได้รัน ให้ตรวจชื่อไฟล์และ option กับเครื่องในห้องแลบ

## Part 0: เตรียมโปรเจกต์ (10 นาที)

1. สร้างโฟลเดอร์ (PowerShell)

```powershell
$P = "E:\lab\VHDL(BOI)\mini_project"
mkdir "$P\rtl", "$P\tb", "$P\constraints", "$P\scripts", "$P\reports", "$P\netlist", "$P\docs", "$P\librelane\src"
cd $P
```

2. เตรียมไฟล์ตามตาราง

| ไฟล์ | หน้าที่ | ทำใน Part |
| --- | --- | --- |
| `rtl/uart_tx_all.vhd` | DUT | 1 |
| `tb/tb_uart_tx.vhd` | testbench | 2 |
| `scripts/run_rtl.do` | RTL sim + coverage | 3 |
| `librelane/config.yaml`, `librelane/src/uart_tx.sdc` | P&R + SDF | 4 |
| `netlist/` | netlist, SDF, cell model จาก LibreLane | 4 |
| `scripts/run_gls.do`, `scripts/run_multicorner.do` | GLS | 5, 6 |
| `docs/final_report.md` | รายงาน | 8 |

> ✅ **จุดตรวจสอบ:** มีโฟลเดอร์ครบ และมีเครื่องมือจาก Lab 3B (Yosys, GHDL, LibreLane) และ Lab 4 (Questa + sky130 cell model)

## Part 1: สเปกและ RTL (20 นาที)

**เป้าหมาย:** เข้าใจสเปกและเขียน UART TX ที่ compile ผ่าน

### 1.1 สเปก

| Port | ทิศทาง | ความกว้าง | หน้าที่ |
| --- | --- | --- | --- |
| `clk` | in | 1 | 100 MHz |
| `rst_n` | in | 1 | synchronous reset, active-low |
| `din` | in | 8 | byte ที่จะส่ง |
| `din_vld` | in | 1 | '1' = มี byte ให้ส่ง |
| `baud_sel` | in | 1 | '0' = 115200 baud (868 clock/bit), '1' = ประมาณ 921600 baud (109 clock/bit) |
| `din_rdy` | out | 1 | '1' = พร้อมรับ byte |
| `tx` | out | 1 | serial line, ว่าง = '1' |
| `tx_done` | out | 1 | pulse 1 clock หลัง stop bit |

- **Frame 8N1:** start bit '0' → data 8 บิต (LSB ก่อน) → stop bit '1' รวม 10 บิต
- **Handshake:** byte ถูกรับเมื่อ `din_rdy = '1'` และ `din_vld = '1'` ที่ขอบขาขึ้นเดียวกัน `baud_sel` ถูกอ่านตอนนั้นและใช้ตลอด frame
- **Back-to-back:** ถ้า `din_vld` ค้างอยู่ตอนจบ stop bit byte ถัดไปเริ่ม start bit ทันที
- **Output ทุกตัวเป็น register** (`tx`, `din_rdy`, `tx_done` ออกจาก flip-flop โดยตรง)

&#91;embedded content: FSM ของ uart\_tx\_all · 4 states\]

ทุก state นับ `cnt` ลงถึง 0 ก่อนเปลี่ยน ถ้า `din_vld` ค้างอยู่ตอนออกจาก STOP byte ถัดไปจะเริ่มทันทีในรอบถัดไป (กรณี back-to-back ใน T7)

### 1.2 ขั้นตอน

1. สร้าง `rtl/uart_tx_all.vhd`

```vhdl
-- ============================================================
-- File: rtl/uart_tx_all.vhd
-- Lab 5 - UART transmitter, 8N1, 2 baud rates, ready/valid input
--   baud_sel = '0' : DIV_SLOW clocks per bit (100 MHz / 868 = 115200 baud)
--   baud_sel = '1' : DIV_FAST clocks per bit (100 MHz / 109 ~ 921600 baud)
-- All outputs are registered (no combinational glitches on tx)
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx_all is
    generic (
        DIV_SLOW : positive := 868;
        DIV_FAST : positive := 109
    );
    port (
        clk      : in  std_logic;
        rst_n    : in  std_logic;                     -- synchronous, active-low
        din      : in  std_logic_vector(7 downto 0);
        din_vld  : in  std_logic;                     -- byte valid
        baud_sel : in  std_logic;                     -- sampled when byte accepted
        din_rdy  : out std_logic;                     -- '1' = ready for a byte
        tx       : out std_logic;                     -- serial line, idle '1'
        tx_done  : out std_logic                      -- 1-clock pulse after stop bit
    );
end entity uart_tx_all;

architecture rtl of uart_tx_all is
    type state_t is (IDLE, START, DATA, STOP);
    signal state   : state_t;
    signal cnt     : unsigned(9 downto 0);            -- baud counter (counts down)
    signal div_m1  : unsigned(9 downto 0);            -- bit length - 1 for this frame
    signal shreg   : std_logic_vector(7 downto 0);
    signal bit_idx : unsigned(2 downto 0);
begin
    process (clk)
    begin
        if rising_edge(clk) then
            tx_done <= '0';                            -- default: pulse lasts 1 clock
            if rst_n = '0' then
                state   <= IDLE;
                cnt     <= (others => '0');
                div_m1  <= to_unsigned(DIV_SLOW - 1, 10);
                shreg   <= (others => '0');
                bit_idx <= (others => '0');
                tx      <= '1';
                din_rdy <= '1';
            else
                case state is
                    when IDLE =>
                        if din_vld = '1' then           -- handshake: din_rdy = '1' here
                            shreg <= din;
                            if baud_sel = '1' then
                                div_m1 <= to_unsigned(DIV_FAST - 1, 10);
                                cnt    <= to_unsigned(DIV_FAST - 1, 10);
                            else
                                div_m1 <= to_unsigned(DIV_SLOW - 1, 10);
                                cnt    <= to_unsigned(DIV_SLOW - 1, 10);
                            end if;
                            tx      <= '0';             -- start bit
                            din_rdy <= '0';
                            state   <= START;
                        end if;

                    when START =>
                        if cnt = 0 then
                            cnt     <= div_m1;
                            tx      <= shreg(0);        -- LSB first
                            bit_idx <= (others => '0');
                            state   <= DATA;
                        else
                            cnt <= cnt - 1;
                        end if;

                    when DATA =>
                        if cnt = 0 then
                            cnt <= div_m1;
                            if bit_idx = 7 then
                                tx    <= '1';           -- stop bit
                                state <= STOP;
                            else
                                shreg   <= '0' & shreg(7 downto 1);
                                tx      <= shreg(1);
                                bit_idx <= bit_idx + 1;
                            end if;
                        else
                            cnt <= cnt - 1;
                        end if;

                    when STOP =>
                        if cnt = 0 then
                            tx_done <= '1';
                            din_rdy <= '1';
                            state   <= IDLE;
                        else
                            cnt <= cnt - 1;
                        end if;
                end case;
            end if;
        end if;
    end process;
end architecture rtl;
```

2. Compile ตรวจ syntax: `vcom -2008 rtl/uart_tx_all.vhd` (หรือ `ghdl -a --std=08 rtl/uart_tx_all.vhd`)

### 1.3 จุดที่ควรสังเกต

- ความยาวบิตคือ `cnt` นับลงจาก `div_m1` ถึง 0 รวม `div_m1 + 1` clock (868 หรือ 109)
- `cnt` 10 บิตนับได้ถึง 1023 พอสำหรับ 867
- generic `DIV_SLOW`/`DIV_FAST` ใช้ได้เฉพาะตอน synthesis netlist จะมีค่าตายตัว testbench จึงต้องใช้ค่าเดียวกัน
- ทุก register มี reset เพื่อไม่ให้เกิด X ใน GLS (บทเรียนจาก Lab 4)

> ✅ **จุดตรวจสอบ:** RTL compile ผ่าน และอธิบายได้ว่า 1 frame ที่ 115200 baud ใช้กี่ clock (10 × 868 = 8680 clock = 86.8 µs)

## Part 2: Self-checking Testbench (25 นาที)

**เป้าหมาย:** testbench ที่ตรวจ UART TX ครบ 9 กรณีโดยไม่ต้องดู waveform และใช้ได้ทั้งกับ RTL และ netlist

### 2.1 ส่วนประกอบ

| ส่วน | หน้าที่ |
| --- | --- |
| `send` (procedure) | รอ `din_rdy` แล้วส่ง byte ที่ขอบขาลง พร้อมเก็บค่าคาดหวังลง `exp_fifo` |
| `rx_model` (process) | receiver จำลอง: เริ่มที่ขอบขาลงของ `tx` สุ่มตรงกลางบิตทุกบิต ตรวจ start/stop และเทียบ byte กับ `exp_fifo` |
| `bit_meter` (process) | วัดว่า `tx` เป็น '0' กี่ clock ใช้ตรวจ baud rate (T8) |
| PSL A1–A4, C1–C2 | ตรวจ line ว่าง = '1', handshake, `tx_done` ยาว 1 clock, ไม่มี X และ cover การส่งต่อเนื่อง |
| `watchdog` | หยุด simulation ที่ 20 ms ถ้าค้าง (เช่นรอ `tx_done` ที่ไม่มา) |

| Test | สิ่งที่ทำ | ผ่านเมื่อ |
| --- | --- | --- |
| T1 | reset | `tx = '1'`, `din_rdy = '1'`, `tx_done = '0'` |
| T2–T5 | ส่ง 0x55, 0xAA, 0x00, 0xFF ที่ 115200 baud | receiver ได้ byte ตรง 1 frame ต่อ test |
| T6 | ส่งครบ 256 ค่าที่ baud เร็ว | ได้ตรงทั้ง 256 frame |
| T7 | ส่ง 2 byte ติดกัน | ได้ตรงทั้ง 2 frame |
| T8 | ส่งที่ baud เร็วแล้วช้า | start bit ยาว 109 และ 868 clock |
| T9 | reset กลาง frame แล้วส่งใหม่ | line กลับมาว่าง และ byte ใหม่ถูกต้อง |

### 2.2 ขั้นตอน

1. สร้าง `tb/tb_uart_tx.vhd`

```vhdl
-- ============================================================
-- File: tb/tb_uart_tx.vhd
-- Lab 5 - Self-checking testbench for uart_tx_all (RTL and GLS)
--   * UART receiver model checks every frame (start, 8 data, stop)
--   * 9 test cases, PSL assertions on the handshake and the tx line
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_tx is
end entity tb_uart_tx;

architecture sim of tb_uart_tx is
    constant CLK_PERIOD : time    := 10 ns;      -- 100 MHz
    constant DIV_SLOW   : natural := 868;        -- must match the DUT
    constant DIV_FAST   : natural := 109;

    signal clk      : std_logic := '0';
    signal rst_n    : std_logic := '0';
    signal din      : std_logic_vector(7 downto 0) := (others => '0');
    signal din_vld  : std_logic := '0';
    signal baud_sel : std_logic := '0';
    signal din_rdy, tx, tx_done : std_logic;
    signal done     : boolean := false;

    -- scoreboard shared between sender and receiver model
    type byte_array is array (0 to 511) of std_logic_vector(7 downto 0);
    signal exp_fifo  : byte_array;
    signal wr_ptr    : natural := 0;
    signal rx_count  : natural := 0;              -- frames received correctly
    signal rx_errors : natural := 0;              -- frames with an error
    signal cur_div   : natural := DIV_SLOW;       -- bit length used by the model
    signal mon_en    : std_logic := '1';          -- '0' = ignore the line (reset test)
    signal last_bit_len : natural := 0;           -- measured low time of tx

    component uart_tx_all is
        port (clk, rst_n : in std_logic;
              din        : in std_logic_vector(7 downto 0);
              din_vld, baud_sel : in std_logic;
              din_rdy, tx, tx_done : out std_logic);
    end component;
begin
    clk <= not clk after CLK_PERIOD / 2 when not done;

    dut : uart_tx_all
        port map (clk => clk, rst_n => rst_n, din => din, din_vld => din_vld,
                  baud_sel => baud_sel, din_rdy => din_rdy, tx => tx, tx_done => tx_done);

    ------------------------------------------------------------
    -- Receiver model: sample each bit in its middle
    ------------------------------------------------------------
    rx_model : process
        variable rd_ptr : natural := 0;
        variable data   : std_logic_vector(7 downto 0);
        variable ok     : boolean;
    begin
        wait until falling_edge(tx) and mon_en = '1' and rst_n = '1';
        ok := true;
        -- tx changed just after a rising edge; sample on falling edges (mid-cycle)
        for k in 1 to cur_div / 2 loop wait until falling_edge(clk); end loop;
        if tx /= '0' then ok := false; end if;     -- middle of start bit
        for i in 0 to 7 loop                       -- middle of each data bit
            for k in 1 to cur_div loop wait until falling_edge(clk); end loop;
            data(i) := tx;
        end loop;
        for k in 1 to cur_div loop wait until falling_edge(clk); end loop;
        if tx /= '1' then ok := false; end if;     -- stop bit
        if mon_en = '1' then
            if ok and data = exp_fifo(rd_ptr) then
                rx_count <= rx_count + 1;
            else
                rx_errors <= rx_errors + 1;
                report "RX error: got 0x" & to_hstring(data) & " exp 0x" &
                       to_hstring(exp_fifo(rd_ptr)) severity error;
            end if;
            rd_ptr := rd_ptr + 1;
        end if;
    end process;

    -- measures how long tx stays '0' after each falling edge of tx
    -- (equals the start-bit length when data bit 0 is '1')
    bit_meter : process
        variable n : natural;
    begin
        wait until falling_edge(tx);
        n := 0;
        loop
            wait until falling_edge(clk);
            exit when tx /= '0';
            n := n + 1;
        end loop;
        last_bit_len <= n;
    end process;

    ------------------------------------------------------------
    -- Assertions (VHDL-2008 PSL, sampled at rising edge)
    ------------------------------------------------------------
    default clock is rising_edge(clk);

    a1_idle_high : assert always (rst_n = '1' and din_rdy = '1') -> (tx = '1')
        report "A1: tx not high while idle";
    a2_accept    : assert always (rst_n = '1' and din_rdy = '1' and din_vld = '1')
                         -> next (din_rdy = '0' and tx = '0')
        report "A2: byte accepted but no start bit";
    a3_done_1clk : assert always (tx_done = '1') -> next (tx_done = '0')
        report "A3: tx_done longer than 1 clock";
    a4_no_x      : assert always (rst_n = '1') -> (not is_x(std_logic_vector'(tx & din_rdy & tx_done)))
        report "A4: X on DUT outputs";
    c1_done      : cover {tx_done = '1'};
    c2_b2b       : cover {tx_done = '1' and din_vld = '1'};   -- next byte in the same clock

    -- watchdog: stop a hung simulation
    watchdog : process
    begin
        wait for 20 ms;
        assert done report "TIMEOUT: simulation did not finish" severity failure;
        wait;
    end process;

    ------------------------------------------------------------
    -- Stimulus: 9 tests
    ------------------------------------------------------------
    stim : process
        variable pass_cnt, fail_cnt : natural := 0;
        variable good0, bad0 : natural;

        procedure send(b : std_logic_vector(7 downto 0); sel : std_logic) is
        begin
            wait until falling_edge(clk);
            while din_rdy /= '1' loop wait until falling_edge(clk); end loop;
            if mon_en = '1' then                  -- only frames the model will check
                exp_fifo(wr_ptr) <= b;
                wr_ptr <= wr_ptr + 1;
            end if;
            din      <= b;
            baud_sel <= sel;
            if sel = '1' then cur_div <= DIV_FAST; else cur_div <= DIV_SLOW; end if;
            din_vld  <= '1';
            wait until falling_edge(clk);
            din_vld  <= '0';
        end procedure;

        procedure wait_done is
        begin
            wait until rising_edge(clk) and tx_done = '1';
            for k in 1 to 4 loop wait until rising_edge(clk); end loop;   -- let the model finish
        end procedure;

        procedure start_test is
        begin
            good0 := rx_count; bad0 := rx_errors;
        end procedure;

        procedure end_test(name : string; n_expected : natural; extra_ok : boolean) is
        begin
            if rx_count - good0 = n_expected and rx_errors = bad0 and extra_ok then
                pass_cnt := pass_cnt + 1;
                report "PASS  " & name;
            else
                fail_cnt := fail_cnt + 1;
                report "FAIL  " & name & " (frames ok=" & integer'image(rx_count - good0) &
                       " errors=" & integer'image(rx_errors - bad0) & ")" severity error;
            end if;
        end procedure;

        variable gap     : natural;
        variable idle_ok : boolean;
    begin
        -- T1: reset values
        rst_n <= '0';
        for k in 1 to 4 loop wait until falling_edge(clk); end loop;
        rst_n <= '1';
        wait until falling_edge(clk);
        start_test;
        end_test("T1 reset", 0, tx = '1' and din_rdy = '1' and tx_done = '0');

        -- T2..T5: corner bytes at 115200 baud
        start_test; send(x"55", '0'); wait_done; end_test("T2 send 0x55", 1, true);
        start_test; send(x"AA", '0'); wait_done; end_test("T3 send 0xAA", 1, true);
        start_test; send(x"00", '0'); wait_done; end_test("T4 send 0x00", 1, true);
        start_test; send(x"FF", '0'); wait_done; end_test("T5 send 0xFF", 1, true);

        -- T6: all 256 byte values at the fast baud rate
        start_test;
        for v in 0 to 255 loop
            send(std_logic_vector(to_unsigned(v, 8)), '1');
            wait_done;
        end loop;
        end_test("T6 all 256 bytes", 256, true);

        -- T7: back-to-back (second byte waits on din_rdy, no idle gap)
        start_test;
        send(x"3C", '1');
        send(x"C3", '1');                          -- accepted as soon as din_rdy rises
        wait_done;                                 -- tx_done of the 2nd frame
        end_test("T7 back-to-back", 2, true);

        -- T8: start-bit length follows baud_sel
        start_test;
        send(x"A5", '1'); wait_done;
        gap := last_bit_len;
        send(x"5B", '0'); wait_done;               -- bit 0 = '1' in both bytes
        end_test("T8 baud select", 2, gap = DIV_FAST and last_bit_len = DIV_SLOW);

        -- T9: reset in the middle of a frame, then send again
        start_test;
        mon_en <= '0';
        send(x"81", '0');
        for k in 1 to 3 * DIV_SLOW loop wait until falling_edge(clk); end loop;  -- ~3 bits
        rst_n <= '0';
        wait until falling_edge(clk); wait until falling_edge(clk);
        rst_n <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        mon_en <= '1';
        idle_ok := (tx = '1' and din_rdy = '1');   -- line idle again after reset
        send(x"7E", '0'); wait_done;
        end_test("T9 reset during TX", 1, idle_ok);

        report "========================================";
        report "PASS: " & integer'image(pass_cnt);
        report "FAIL: " & integer'image(fail_cnt);
        report "========================================";
        if fail_cnt = 0 then
            report "ALL TESTS PASSED" severity note;
        else
            report "SOME TESTS FAILED" severity failure;
        end if;
        done <= true;
        std.env.stop;
    end process;
end architecture sim;
```

### 2.3 จุดที่ควรสังเกต

- receiver model สุ่มที่**ขอบขาลง**ของ clock เพราะ `tx` เปลี่ยนหลังขอบขาขึ้น (ใน GLS จะช้ากว่านั้นอีกตาม SDF) การสุ่มกลางรอบ clock จึงไม่ติด delta cycle
- อย่าวัดความยาว start bit ด้วยการนับจน `tx` เปลี่ยน ถ้า bit 0 ของ data เป็น '0' จะนับรวมเป็น 2 บิต (เจอจริงตอนเขียนแลบนี้) T8 จึงใช้ byte ที่ bit 0 = '1'
- `wait_done` ที่ไม่มี `tx_done` มาจะรอตลอดไป `watchdog` จะหยุด simulation ให้พร้อมข้อความ `TIMEOUT` แทนการค้าง
- T9 ปิด receiver model (`mon_en = '0'`) ระหว่าง frame ที่ถูก reset เพราะ frame นั้นไม่ครบอยู่แล้ว

## Part 3: RTL Simulation และ Coverage (20 นาที)

**เป้าหมาย:** `PASS: 9 FAIL: 0` พร้อม code coverage ของ RTL และยืนยันว่า testbench จับ bug ได้

### 3.1 รันใน Questa

1. สร้าง `scripts/run_rtl.do`

```tcl
# run_rtl.do - RTL simulation + code coverage (vsim -c -do scripts/run_rtl.do)
onerror {quit -f -code 1}
onbreak {resume}
vlib work
vcom -2008 +cover=bcst rtl/uart_tx_all.vhd
vcom -2008 tb/tb_uart_tx.vhd
vsim -coverage -assertdebug work.tb_uart_tx
coverage save -onexit reports/rtl_cov.ucdb
run -all
quit -sim
vcover report -details reports/rtl_cov.ucdb > reports/rtl_cov.txt
quit -f
```

2. รัน

```powershell
vsim -c -do scripts/run_rtl.do | Tee-Object reports/rtl_sim.log
```

3. ตรวจผล (จากการรันจริง: simulation จบที่ 3,385,905 ns)

```text
# ** Note: PASS  T1 reset
# ** Note: PASS  T2 send 0x55
...
# ** Note: PASS  T9 reset during TX
# ** Note: PASS: 9
# ** Note: FAIL: 0
# ** Note: ALL TESTS PASSED
```

4. เปิด `reports/rtl_cov.txt` แล้วบันทึก

| Coverage | เป้าหมาย | ค่าของคุณ |
| --- | --- | --- |
| Statement | ≥ 95% |  |
| Branch | ≥ 90% |  |
| Condition | (ดูผล) |  |
| Toggle | (ดูผล) |  |
| Assertion A1–A4 ผ่าน / cover C1–C2 | 4/4, 2/2 |  |

> 📝 **หมายเหตุ:** simulation จบเองที่ประมาณ 3.39 ms ด้วย `std.env.stop` จึงใช้ `run -all` ได้ (คู่มือต้นฉบับใช้ `run 10 ms`) ส่วนที่นานที่สุดคือ T6 (256 frame)

### 3.2 ทางเลือก: GHDL

```bash
ghdl -a --std=08 rtl/uart_tx_all.vhd tb/tb_uart_tx.vhd
ghdl -e --std=08 tb_uart_tx
ghdl -r --std=08 tb_uart_tx --psl-report=reports/psl.json
```

ผลจริง: `PASS: 9`, `FAIL: 0` และใน `psl.json` มี `assert-pass: 4`, `cover-pass: 2` (รันประมาณ 2 วินาที)

### 3.3 ทดสอบว่า testbench จับ bug ได้

คัดลอก RTL ไปแก้ทีละแบบ แล้วรันซ้ำ ผลในตารางมาจากการรันจริง

| Bug | แก้อะไร | ผล |
| --- | --- | --- |
| B1: ส่งแค่ 7 บิต | `if bit_idx = 7` → `if bit_idx = 6` | `PASS: 1 FAIL: 8` (จับได้ด้วย receiver model อย่างเดียว ไม่มี assertion แจ้ง) |
| B2: `tx_done` ไม่กลับเป็น 0 | ลบบรรทัด `tx_done <= '0';` (default) | A3 แจ้งต่อเนื่อง, `PASS: 5 FAIL: 4` |
| B3: reset ไม่ตั้ง `tx` | ลบ `tx <= '1';` ในส่วน reset | A1 และ A4 แจ้ง, `PASS: 0 FAIL: 9` |

> 💡 **เคล็ดลับ:** B1 แสดงว่า assertion กับ scoreboard ตรวจคนละเรื่อง assertion ดูกติกา (handshake, ความยาว pulse) ส่วนความถูกต้องของข้อมูลต้องใช้ receiver model

> ✅ **จุดตรวจสอบ:** RTL ได้ `PASS: 9 FAIL: 0`, มี `reports/rtl_cov.txt` และทดสอบ B1–B3 แล้วได้ผลตรงตามตาราง

## Part 4: Synthesis (40 นาที)

**เป้าหมาย:** ได้ gate-level netlist ของ sky130 และไฟล์ SDF สำหรับ GLS พร้อมตัวเลขพื้นที่และจำนวน cell ที่ตรวจสอบได้

> ⚠️ **คำเตือน:** คู่มือต้นฉบับให้ใช้ Precision กับ library `gscl45nm` แล้ว `write_sdf` แต่ Precision RTL เป็น **FPGA synthesis** (ดู Lab 3A) ไม่มี ASIC library แบบนั้น และไม่ได้ให้ SDF ของ standard cell แลปนี้จึงใช้ Yosys (ดูผลเร็ว) และ LibreLane (netlist หลัง P&R + SDF) แทน

### 4.1 แปลง VHDL เป็น Verilog ด้วย GHDL

1. รันใน WSL/Linux ที่โฟลเดอร์โปรเจกต์

```bash
mkdir -p build reports netlist
ghdl -a --std=08 --workdir=build rtl/uart_tx_all.vhd
ghdl synth --std=08 --workdir=build --out=verilog uart_tx_all > build/uart_tx_all_rtl.v
```

> 💡 **เคล็ดลับ:** ถ้าเห็น warning ว่า entity `uart_tx_all` ถูกนิยามซ้ำจากไฟล์อื่น ให้ลบ `build/*.cf` แล้วรันใหม่ เพราะ library เก่าที่ค้างอยู่ทำให้ได้ Verilog จากโค้ดผิดเวอร์ชันได้

### 4.2 Synthesis ด้วย Yosys

1. สร้าง `scripts/synth_sky130.ys` (ใช้ liberty ที่ตั้ง `dont_use` ให้ cell `lpflow_*` แล้วจาก Lab 3B)

```tcl
# synth_sky130.ys - Yosys synthesis of the GHDL-converted UART TX to sky130_fd_sc_hd
read_liberty -lib pdk/hd_tt_dontuse.lib
read_verilog build/uart_tx_all_rtl.v
hierarchy -check -top uart_tx_all
synth -top uart_tx_all
tee -o reports/generic_stat.txt stat
dfflibmap -liberty pdk/hd_tt_dontuse.lib
abc -liberty pdk/hd_tt_dontuse.lib
opt_clean -purge
tee -o reports/sky130_stat.txt stat -liberty pdk/hd_tt_dontuse.lib
check -assert
write_verilog -noattr netlist/uart_tx_all_sky130.v
```

2. รัน: `yosys -q scripts/synth_sky130.ys` (warning `unsupported expression ... sdfxtp` เป็นเรื่องปกติ คือ Yosys ข้าม scan flip-flop ที่อ่าน function ไม่ได้)
3. บันทึกผลจาก `reports/generic_stat.txt` และ `reports/sky130_stat.txt`

| รายการ | ผลจริงจากการรัน | ค่าของคุณ |
| --- | --- | --- |
| Generic cells (หลัง `synth`) | 198 |  |
| Flip-flop | 30 (`$_DFF_P_` 4, `$_SDFFE_PN0P_` 22, `$_SDFFE_PN1P_` 3, `$_SDFF_PP0_` 1) |  |
| Latch | 0 |  |
| sky130 cells | 187 |  |
| `sky130_fd_sc_hd__dfxtp_1` | 30 |  |
| Chip area | 1463.904 µm² |  |
| cell `lpflow_*` ใน netlist | 0 |  |

> 📝 **หมายเหตุ:** ลองนับ flip-flop เอง: `state` แบบ one-hot 4 + `cnt` 10 + `shreg` 8 + `bit_idx` 3 + output 3 = 28 ถ้าเก็บ `div_m1` ครบ 10 บิตจะได้ 38 แต่ `div_m1` มีได้แค่ 2 ค่า (867 หรือ 108) Yosys จึงลดบิตที่ไม่จำเป็นลงได้ ให้นักศึกษาเปิด netlist เพื่อตรวจว่าเหลือ 30 ตัวเพราะอะไร (ตัวเลขอาจต่างเล็กน้อยตามเวอร์ชัน Yosys ที่รันคือ 0.33)

> ⚠️ **คำเตือน:** ถ้าไม่มีบรรทัด `read_liberty -lib` คำสั่ง `check -assert` จะฟ้องว่า `tx`, `din_rdy`, `tx_done` ไม่มี driver เพราะ Yosys ไม่รู้ว่าขา `Q` ของ `dfxtp_1` เป็น output (เจอจริงตอนเขียนแลปนี้)

### 4.3 ตรวจ netlist ด้วย simulation

1. สร้าง netlist แบบ VHDL จาก GHDL แล้วรัน testbench เดิม

```bash
ghdl synth --std=08 --workdir=build --out=vhdl uart_tx_all > build/uart_tx_all_synth.vhd
rm -f work-obj08.cf
ghdl -a --std=08 build/uart_tx_all_synth.vhd tb/tb_uart_tx.vhd
ghdl -e --std=08 tb_uart_tx
ghdl -r --std=08 tb_uart_tx
```

2. ผลจริง: `PASS: 9 FAIL: 0`

> 📝 **หมายเหตุ:** การลอง formal equivalence (`equiv_make` / `equiv_induct`) ระหว่าง RTL กับ netlist sky130 แบบใน Lab 3B **พิสูจน์ไม่ผ่าน** (เหลือ 31 จุดที่ยังไม่ได้พิสูจน์) เพราะ Yosys เข้ารหัส FSM ใหม่เป็น one-hot และย้าย register ทำให้จับคู่ state ทีละตัวไม่ได้ ไม่ได้แปลว่า design ผิด การยืนยันในแลปนี้จึงใช้ simulation (4.3) และ GLS (Part 5)

### 4.4 LibreLane: netlist หลัง P&R และ SDF

1. คัดลอก Verilog จาก 4.1 ไปไว้ที่ `librelane/src/uart_tx_all_rtl.v`
2. สร้าง `librelane/src/uart_tx.sdc`

```tcl
# uart_tx.sdc - 100 MHz, synchronous reset is a normal timed input
create_clock -name sys_clk -period 10.0 [get_ports clk]
set_input_delay  2.0 -clock sys_clk [get_ports {din[*] din_vld baud_sel rst_n}]
set_output_delay 2.0 -clock sys_clk [get_ports {tx tx_done din_rdy}]
set_load 0.05 [all_outputs]
```

3. สร้าง `librelane/config.yaml`

```yaml
DESIGN_NAME: uart_tx_all
VERILOG_FILES: dir::src/uart_tx_all_rtl.v
CLOCK_PORT: clk
CLOCK_PERIOD: 10
FP_CORE_UTIL: 45
PNR_SDC_FILE: dir::src/uart_tx.sdc
SIGNOFF_SDC_FILE: dir::src/uart_tx.sdc
```

4. รันใน `nix-shell` ตาม Lab 3B

```bash
cd librelane
librelane --pdk sky130A config.yaml
```

5. คัดลอกผลลัพธ์จาก `runs/<tag>/final/` ไปที่ `netlist/`

| ไฟล์ใน `final/` | ใช้ทำอะไร |
| --- | --- |
| `nl/uart_tx_all.nl.v` | netlist ไม่มีขา power ใช้กับ GLS |
| `sdf/<corner>/uart_tx_all__<corner>.sdf` | delay ของแต่ละ corner |
| `metrics.json` | ตัวเลข timing, area, จำนวน cell |

> ⚠️ **คำเตือน:** คู่มือต้นฉบับใส่ `set_false_path` ให้ `rst_n` แต่ reset ของ design นี้เป็น **synchronous** วิ่งผ่าน logic เข้า D ของ flip-flop จึงต้องถูก time เหมือน input ปกติ ห้าม false path นอกจากนี้ `INVX1` และ `set_operating_conditions` แบบในต้นฉบับไม่มีใน sky130 (LibreLane เลือก corner ให้เอง)

> 📝 **หมายเหตุ:** ชื่อโฟลเดอร์ corner (เช่น `nom_tt_025C_1v80`) และ path ภายใน `final/` ขึ้นกับเวอร์ชัน LibreLane ให้เปิดดูโฟลเดอร์จริง ส่วนนี้**ยังไม่ได้รัน**ในขั้นตอนตรวจแลป

### 4.5 ถ้าต้องใช้ Precision

- ใช้ได้กับ **FPGA device** ตามขั้นตอนใน Lab 3A (Add Input Files → Setup Design → Compile → Synthesize) เพื่อดู resource และ timing ของ FPGA
- netlist ที่ได้ใช้ primitive ของ FPGA vendor นั้น ถ้าจะทำ GLS ต้องใช้ simulation library ของ vendor แทน sky130 และ SDF ได้จากเครื่องมือ place & route ของ vendor ไม่ใช่จาก Precision

> ✅ **จุดตรวจสอบ:** มี `reports/sky130_stat.txt` (ไม่มี latch, ไม่มี `lpflow_*`), netlist sim ได้ `PASS: 9` และมี netlist + SDF จาก LibreLane ใน `netlist/`

## Part 5: Gate-Level Simulation ใน Questa (30 นาที)

**เป้าหมาย:** รัน testbench เดิมกับ netlist จาก LibreLane พร้อม SDF แล้วได้ `PASS: 9 FAIL: 0`

### 5.1 เตรียมไฟล์

| ไฟล์ | มาจาก |
| --- | --- |
| `netlist/uart_tx_all.nl.v` | LibreLane `final/nl/` |
| `netlist/uart_tx_all_tt.sdf`, `_ss.sdf`, `_ff.sdf` | LibreLane `final/sdf/<corner>/` (เปลี่ยนชื่อให้สั้นลง) |
| `primitives.v`, `sky130_fd_sc_hd.v` | PDK: `sky130A/libs.ref/sky130_fd_sc_hd/verilog/` (เหมือน Lab 4) |

### 5.2 ขั้นตอน

1. สร้าง `scripts/run_gls.do`

```tcl
# run_gls.do - GLS of uart_tx_all with typical SDF (vsim -c -do scripts/run_gls.do)
onerror {quit -f -code 1}
onbreak {resume}
set CELLS "C:/pdk/sky130A/libs.ref/sky130_fd_sc_hd/verilog"   ;# edit to your PDK path

# 1) cell library (same as Lab 4; compile once)
if {![file exists sky130]} {
    vlib sky130
    vlog -work sky130 "$CELLS/primitives.v" "$CELLS/sky130_fd_sc_hd.v"
}

# 2) netlist + the unchanged testbench
vlib work_gls
vlog -work work_gls netlist/uart_tx_all.nl.v
vcom -2008 -work work_gls tb/tb_uart_tx.vhd

# 3) simulate with SDF annotated on the DUT instance
vsim -t ps -L sky130 -lib work_gls \
     -sdftyp /tb_uart_tx/dut=netlist/uart_tx_all_tt.sdf +sdf_verbose \
     work_gls.tb_uart_tx
run -all
quit -f
```

2. รัน

```powershell
vsim -c -do scripts/run_gls.do | Tee-Object reports/gls_tt.log
```

3. ตรวจ log ตามลำดับ
   1. ส่วน SDF: ไม่มี error และจำนวน instance ที่ annotate ไม่เป็น 0
   2. ไม่มีข้อความ `$setup` / `$hold` violation
   3. มี `PASS: 9`, `FAIL: 0` และไม่มี A1–A4 แจ้ง

> 📝 **หมายเหตุ:** testbench ใช้ `component` จึง bind กับ module Verilog ชื่อ `uart_tx_all` ได้โดยไม่ต้องแก้ และเพราะส่ง input ที่ขอบขาลง และสุ่ม `tx` ที่ขอบขาลง delay ของ cell (ระดับร้อย ps ถึงไม่กี่ ns) จึงไม่ทำให้ผลเพี้ยนที่ clock 10 ns

> ⚠️ **คำเตือน:** คู่มือต้นฉบับใช้ `vsim -sdf ...` ซึ่งไม่มีใน Questa ต้องเลือก `-sdfmin`, `-sdftyp` หรือ `-sdfmax` และระบุ instance path (`/tb_uart_tx/dut`) หน้าชื่อไฟล์ ถ้า path ผิด delay จะไม่ถูก annotate แต่ simulation ยังผ่าน จึงต้องอ่าน log ข้อ 3.1 ทุกครั้ง

> ✅ **จุดตรวจสอบ:** `reports/gls_tt.log` มี `PASS: 9 FAIL: 0` และ SDF ถูก annotate

## Part 6: Multi-corner GLS (20 นาที)

**เป้าหมาย:** รัน GLS ครบ 3 corner ในสคริปต์เดียวแล้วเก็บผลแยกไฟล์

1. สร้าง `scripts/run_multicorner.do` (ต้อง compile จาก Part 5 ไว้แล้ว)

```tcl
# run_multicorner.do - same TB, one SDF file per corner
onbreak {resume}
foreach corner {tt ss ff} {
    transcript file reports/gls_$corner.log
    vsim -t ps -L sky130 -lib work_gls \
         -sdftyp /tb_uart_tx/dut=netlist/uart_tx_all_$corner.sdf \
         work_gls.tb_uart_tx
    run -all
    quit -sim                    ;# end this run, keep Questa open for the next corner
}
transcript file transcript
quit -f
```

2. รัน `vsim -c -do scripts/run_multicorner.do`
3. ดึงผลสรุป

```powershell
Select-String -Path reports/gls_*.log -Pattern "PASS: |FAIL: |Error"
```

4. บันทึกผล (เติมจาก log จริง อย่าเดา)

| Corner | ไฟล์ SDF | PASS / FAIL | Timing violation | Setup WNS จาก STA (ns) |
| --- | --- | --- | --- | --- |
| tt (ปกติ) |  |  |  |  |
| ss (ช้าสุด) |  |  |  |  |
| ff (เร็วสุด) |  |  |  |  |

> ⚠️ **คำเตือน:** คู่มือต้นฉบับใช้ `quit -f` ใน loop ซึ่งปิด Questa ตั้งแต่ corner แรก ต้องใช้ `quit -sim` และตารางผล "PASS ทุก corner" ในต้นฉบับเป็นตัวเลขตัวอย่าง ไม่ได้มาจากการรัน

> 📝 **หมายเหตุ:** LibreLane ออก SDF แยกไฟล์ต่อ corner จึงใช้ `-sdftyp` กับทุกไฟล์ ส่วน `-sdfmin`/`-sdfmax` ใช้เมื่อ SDF ไฟล์เดียวมีค่า (min:typ:max) ต่างกัน ให้เปิด SDF ดูว่าเป็นแบบไหน

> ✅ **จุดตรวจสอบ:** มี log 3 ไฟล์ และตารางข้างบนเติมครบจากผลจริง

## Part 7: Debug ปัญหาที่พบบ่อยใน GLS (40 นาที)

**เป้าหมาย:** ทำให้เกิดปัญหา 3 แบบโดยตั้งใจ แล้วหาสาเหตุจาก log และ waveform ทำทีละแบบแล้วคืนไฟล์เดิมก่อนทำแบบถัดไป

### 7.1 X propagation

1. คัดลอก RTL แล้วลบ `tx <= '1';` ในส่วน reset (bug B3 จาก Part 3)
2. รัน RTL sim ก่อน: A1 และ A4 แจ้ง และได้ `PASS: 0 FAIL: 9` (ผลจริง)
3. ถ้ามีเวลา synthesize และรัน GLS ซ้ำ แล้วเปิด waveform

```tcl
add wave /tb_uart_tx/rst_n /tb_uart_tx/tx /tb_uart_tx/din_rdy /tb_uart_tx/tx_done
```

4. หาเวลาแรกที่ `tx` เป็น X แล้วไล่ย้อนไปที่ flip-flop ต้นทาง (ใช้ **Dataflow** window หรือ `drivers /tb_uart_tx/dut/tx`)

> 📝 **หมายเหตุ:** ใน RTL สัญญาณที่ไม่ได้ reset เริ่มเป็น `'U'` ใน GLS flip-flop ของ cell model เริ่มเป็น X ทั้งคู่ถูก A4 จับได้ สิ่งที่ต่างกันคือใน GLS X อาจไม่หายแม้ logic จะทำให้ RTL หาย (X-pessimism)

**วิธีแก้:** ให้ทุก register ที่มีผลต่อ output มีค่า reset ไม่ใช่ใส่ค่าเริ่มต้นตอนประกาศ signal (synthesis ไม่นำค่านั้นไปใช้กับ ASIC)

### 7.2 Timing violation

1. เปิดผล STA จาก LibreLane เช่นค่า setup worst slack ใน `final/metrics.json` (ชื่อ key เช่น `timing__setup__ws`) และ report ของ step STA ใน `runs/<tag>/`
2. คำนวณคาบต่ำสุดที่ควรผ่าน: `T_min ≈ 10 ns − WNS`
3. คัดลอก testbench เป็น `tb/tb_uart_tx_fast.vhd` แล้วแก้บรรทัดเดียว

```vhdl
constant CLK_PERIOD : time := 3 ns;   -- try a period shorter than T_min
```

4. รัน GLS ด้วย SDF ของ corner `ss` แล้วดูข้อความ `$setup` / `$hold` และ "RX error" ใน log
5. ลดหรือเพิ่ม `CLK_PERIOD` ทีละนิดจนหาคาบที่เริ่มผิด แล้วเทียบกับ `T_min` จาก STA

| CLK\_PERIOD | Corner | PASS / FAIL | มี timing violation? |
| --- | --- | --- | --- |
| 10 ns | ss |  |  |
| \_\_\_\_ ns | ss |  |  |
| \_\_\_\_ ns | ss |  |  |

> 💡 **เคล็ดลับ:** testbench นับความยาวบิตเป็นจำนวน clock (868/109) ไม่ใช่เวลา จึงเปลี่ยน `CLK_PERIOD` ได้โดยไม่ต้องแก้อย่างอื่น ถ้าผิดจึงมาจาก timing ของ netlist เท่านั้น

> ⚠️ **คำเตือน:** คู่มือต้นฉบับให้ดู `report_timing` "ใน Questa transcript" แต่ Questa เป็น simulator ไม่มีคำสั่ง STA ตัวเลข slack มาจาก OpenSTA ใน LibreLane ส่วน `set_cell_routing` ไม่ใช่คำสั่งที่มีจริง ถ้า timing ไม่ผ่านให้แก้ที่ RTL (ตัด logic ยาว เพิ่ม pipeline) หรือผ่อน `CLOCK_PERIOD` แล้วรัน LibreLane ใหม่

### 7.3 Glitch บน `tx`

1. อ่าน RTL แบบที่มักเกิด glitch: คำนวณ `tx` จาก state แบบ combinational

```vhdl
-- glitch-prone: tx is a function of several flip-flops through logic
tx <= '0'             when state = START else
      shreg(0)        when state = DATA  else
      '1';
```

2. อธิบายว่าทำไมจึง glitch: เมื่อ `state` (one-hot หลายบิต) และ `shreg` เปลี่ยนพร้อมกันแต่มี delay ต่างกัน สัญญาณผ่าน logic คนละเส้นทาง ทำให้ `tx` อาจเกิด pulse สั้นๆ ช่วงเปลี่ยน state ใน GLS ที่มี SDF (ใน RTL เห็นไม่ได้เพราะไม่มี delay)
3. เทียบกับ RTL ของแลปนี้: `tx` ถูก assign ใน `rising_edge(clk)` จึงออกจาก flip-flop ตัวเดียว ไม่มี glitch
4. ตรวจใน netlist: หาว่า port `tx` ต่อกับขา `Q` ของ `dfxtp` ตรงหรือผ่าน buffer เท่านั้น

> ⚠️ **คำเตือน:** คู่มือต้นฉบับแนะนำให้แก้ glitch ด้วย "delay cell" หรือ "hysteresis" ซึ่งไม่ถูก delay cell แค่เลื่อนเวลา glitch และขึ้นกับ corner ส่วน hysteresis (Schmitt trigger) เป็นเรื่องของ I/O pad วิธีมาตรฐานคือ **register output** แบบที่ RTL นี้ทำ

> ✅ **จุดตรวจสอบ:** บันทึกสาเหตุและวิธีแก้ของ 7.1–7.3 ไว้ใส่ในรายงาน Part 8

## Part 8: รายงานบทสรุป (30 นาที)

**เป้าหมาย:** รายงานที่ทุกตัวเลขมาจาก log หรือ report จริง และบอกชัดว่าอะไรยังไม่ได้ตรวจ

1. สร้าง `docs/final_report.md` ตามแม่แบบ

```markdown
# Lab 5 Final Report: UART TX (uart_tx_all)
ชื่อ / รหัส: ________   วันที่: ________

## 1. Design
- สเปก: 8N1, 115200 / ~921600 baud @ 100 MHz, ready/valid, registered outputs
- FSM: IDLE -> START -> DATA -> STOP

## 2. Verification (RTL)
| รายการ | ผล | หลักฐาน (ไฟล์) |
|---|---|---|
| Tests | PASS __ / FAIL __ | reports/rtl_sim.log |
| Assertions A1-A4 / covers C1-C2 | __ / __ | reports/rtl_sim.log |
| Statement / Branch coverage | __% / __% | reports/rtl_cov.txt |
| Negative tests B1-B3 caught | __ / 3 | |

## 3. Synthesis
| รายการ | Yosys | LibreLane |
|---|---|---|
| Cells | | |
| Flip-flops / latches | | |
| Area (um^2) | | |
| Setup WNS @ 10 ns (ns) | - | |

## 4. GLS
| Corner | PASS/FAIL | Timing violations |
|---|---|---|
| tt | | |
| ss | | |
| ff | | |

## 5. Debug log (Part 7)
| ปัญหา | อาการ | สาเหตุ | วิธีแก้ |
|---|---|---|---|
| X | | | |
| Timing | | | |
| Glitch | | | |

## 6. Not verified / limitations
- (เช่น formal equivalence ไม่ผ่านเพราะ FSM recoding, ไม่ได้ทำ DRC/LVS signoff, ไม่ได้ทดสอบกับ receiver จริง)

## 7. Conclusion
- สถานะ: ผ่าน GLS ทุก corner ที่ทดสอบ ใช่ / ไม่ใช่
```

2. เติมทุกช่องจากไฟล์ใน `reports/` และ `netlist/` เท่านั้น
3. แนบ log และ report ที่อ้างถึงไปกับรายงาน

> ⚠️ **คำเตือน:** คู่มือต้นฉบับให้ตัวเลข coverage และผล PASS ทุก corner ไว้ล่วงหน้า และจบด้วย "READY FOR TAPE-OUT" ตัวเลขเหล่านั้นไม่ได้มาจากการรัน ห้ามคัดลอก ส่วน tape-out ต้องผ่าน DRC, LVS, antenna และ STA signoff ครบทุก corner ซึ่งแลปนี้ไม่ได้ครอบคลุม บทสรุปที่ถูกคือ "ผ่าน GLS ที่ corner ที่ทดสอบ"

## Checklist ก่อนส่งงาน

- [ ] RTL compile ผ่านด้วย `-2008`
- [ ] RTL sim: `PASS: 9 FAIL: 0` และ assertion ไม่แจ้ง
- [ ] มี `reports/rtl_cov.txt`
- [ ] ทดสอบ B1–B3 แล้ว testbench จับได้ครบ และคืน RTL เดิมแล้ว
- [ ] Yosys: ไม่มี latch, ไม่มี `lpflow_*`, `check -assert` ผ่าน
- [ ] Netlist sim (GHDL `--out=vhdl`) ได้ `PASS: 9`
- [ ] LibreLane รันจบ มี netlist + SDF ใน `netlist/` และจด setup WNS
- [ ] GLS tt: `PASS: 9`, SDF annotate ไม่มี error
- [ ] GLS 3 corner มี log ครบ
- [ ] Part 7 บันทึกครบ 3 เรื่อง
- [ ] `docs/final_report.md` ทุกตัวเลขอ้างอิงไฟล์จริง

## Troubleshooting

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| Simulation ไม่จบ / เจอ `TIMEOUT` | `wait_done` รอ `tx_done` ที่ผ่านไปแล้ว หรือ DUT ไม่ส่ง `tx_done` | เรียก `wait_done` หนึ่งครั้งต่อ frame สุดท้าย ตรวจ state STOP |
| `is_x` ambiguous ตอน compile | `numeric_std` กับ `std_logic_1164` มี `is_x` ทั้งคู่ | เขียน `is_x(std_logic_vector'(...))` |
| RX error เฉพาะ byte ที่ LSB = 0 | นับความยาว start bit จน `tx` เปลี่ยน | สุ่มที่ตำแหน่งคงที่ตาม `cur_div` แบบ `rx_model` |
| T9 fail แต่ byte อื่นผ่าน | byte ที่ถูก reset ค้างใน `exp_fifo` | `send` เก็บเข้า FIFO เฉพาะตอน `mon_en = '1'` |
| GHDL ฟ้อง PSL ตรง comment | ใช้ `-fpsl` ทำให้ comment `-- psl` ถูกแปล | ไม่ต้องใส่ `-fpsl` เพราะใช้ PSL ใน VHDL-2008 โดยตรง |
| Yosys `check -assert` ฟ้อง output ไม่มี driver | ไม่ได้ `read_liberty -lib` | เพิ่มบรรทัดนั้นก่อน `read_verilog` |
| มี cell `lpflow_*` ใน netlist | liberty ไม่ได้ตั้ง `dont_use` | ใช้ `hd_tt_dontuse.lib` จาก Lab 3B |
| GLS: SDF ไม่ annotate / หา instance ไม่เจอ | instance path ผิด หรือใช้ `-sdf` | ใช้ `-sdftyp /tb_uart_tx/dut=<file>` และ `-t ps` |
| GLS: หา module `sky130_fd_sc_hd__*` ไม่เจอ | ไม่ได้ใส่ `-L sky130` หรือยังไม่ compile cell model | compile `primitives.v` + `sky130_fd_sc_hd.v` ตาม Lab 4 |
| GLS: output เป็น X ตลอด | register ไม่มี reset หรือ reset สั้นเกิน | ดู 7.1 และให้ `rst_n = '0'` อย่างน้อย 2–4 clock |
| Multi-corner รันแค่ corner แรก | ใช้ `quit -f` ใน loop | ใช้ `quit -sim` |

## คำถามท้ายแลป

1. 1 frame ที่ 921600 baud (109 clock/bit) ใช้เวลากี่ µs และ baud rate จริงคลาดจาก 921600 กี่ %
2. ทำไม bug B1 (7 บิต) ไม่ทำให้ assertion ตัวไหนแจ้ง จงเขียน assertion ใหม่ที่จับ bug นี้ได้
3. ทำไม receiver model ต้องสุ่มที่ขอบขาลงของ clock ถ้าสุ่มที่ขอบขาขึ้นจะเกิดอะไรใน RTL และใน GLS
4. ทำไม formal equivalence ระหว่าง RTL กับ netlist จึงพิสูจน์ไม่ผ่านทั้งที่ simulation ผ่าน และต้องทำอะไรเพิ่มจึงจะพิสูจน์ได้
5. จากผล 7.2 clock ที่เร็วที่สุดที่ GLS ผ่านที่ corner `ss` คือเท่าไร ตรงกับ STA หรือไม่ ถ้าไม่ตรงเพราะอะไร
6. ถ้าต้องเพิ่ม parity bit (8E1) จะต้องแก้ FSM, testbench และ assertion ตรงไหนบ้าง

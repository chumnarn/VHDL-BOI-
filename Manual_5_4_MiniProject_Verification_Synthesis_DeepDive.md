# รายละเอียดเชิงลึก: Mini Project – Verification + Synthesis

> เนื้อหานี้ออกแบบมาให้นำไปแทรกเป็นส่วนขยายในหัวข้อ **5.4 Mini Project – Verification และ 5.5 Mini Project – Synthesis** ของคู่มือหลักสูตร (วันที่ 5)
> เหมาะสำหรับการบรรยาย 90–120 นาที

---

# ส่วนที่ A: Verification Strategy — เชิงลึก

## A.1 Verification Approach

สำหรับ Mini Project UART TX ใช้ **Layered Verification**:

```
   ┌──────────────────────────────────────┐
   │  Layer 1: Block-level TB            │  ← Day 1-2 style
   │  - Each module tested separately      │
   └──────────────────────────────────────┘
   ┌──────────────────────────────────────┐
   │  Layer 2: Self-checking TB          │  ← Day 4 style
   │  - Reference model                    │
   │  - Scoreboard                         │
   │  - Assertions                         │
   └──────────────────────────────────────┘
   ┌──────────────────────────────────────┐
   │  Layer 3: Gate-Level Sim            │  ← Day 4 GLS
   │  - With SDF back-annotation          │
   │  - Multi-corner                       │
   └──────────────────────────────────────┘
```

## A.2 Verification Goals

| Goal | Target | Reason |
| --- | --- | --- |
| Functional Coverage | 100% (all features) | Spec compliance |
| Code Coverage (Statement) | ≥ 95% | Bug detection |
| Code Coverage (Branch) | ≥ 90% | Decision coverage |
| Toggle Coverage | 100% (with exclusions) | Every FF flips |
| Assertion Coverage | 100% pass | Protocol compliance |
| Bugs Found | 0 (at sign-off) | Quality |

## A.3 Test Plan

```markdown
| Test ID | Description | Stimulus | Expected | Method |
|-----------|-------------|----------|----------|--------|
| U_TX_01 | Reset | rst=1 for 5 cycles | tx=1, din_rdy=1 | Directed |
| U_TX_02 | Send 0x55 | din=0x55 | start=0, 01010101, stop=1 | Directed |
| U_TX_03 | Send 0xAA | din=0xAA | start=0, 10101010, stop=1 | Directed |
| U_TX_04 | Send 0x00 | din=0x00 | start=0, 00000000, stop=1 | Directed |
| U_TX_05 | Send 0xFF | din=0xFF | start=0, 11111111, stop=1 | Directed |
| U_TX_06 | All 256 bytes | random | All frames correct | Random |
| U_TX_07 | Back-to-back | 0x55, 0xAA | 2 correct frames | Directed |
| U_TX_08 | Different baud | 115200 → 9600 | Frame timing changes | Directed |
| U_TX_09 | Reset during TX | rst mid-frame | Clean back to IDLE | Directed |
| U_TX_10 | Edge cases | din=0xFF | Verify LSB first | Directed |
```

---

# ส่วนที่ B: Self-Checking Testbench — เต็มสมบูรณ์

## B.1 Testbench Architecture

```
   ┌──────────────────────────────────────┐
   │  Stimulus Generator                  │
   │  - Directed tests                    │
   │  - Random patterns                   │
   └────────────┬────────────────────────┘
                │
                ▼
   ┌──────────────────────────────────────┐
   │  DUT (uart_tx)                        │
   └────────────┬────────────────────────┘
                │
                ▼
   ┌──────────────────────────────────────┐
   │  Bit Collector                        │
   │  - Captures tx line                  │
   │  - Reconstructs frame                │
   └────────────┬────────────────────────┘
                │
                ▼
   ┌──────────────────────────────────────┐
   │  Reference Model + Checker            │
   │  - Computes expected frame           │
   │  - Compares with actual              │
   └────────────┬────────────────────────┘
                │
                ▼
   ┌──────────────────────────────────────┐
   │  Coverage Tracker                     │
   │  - Functional + Code coverage        │
   └──────────────────────────────────────┘
```

## B.2 Reference Model

Reference Model ทำงานเหมือน DUT แต่เขียนง่าย (behavioral) ใช้สำหรับ verify DUT

```vhdl
-- ============================================================
-- File: ref_model_uart_tx.vhd
-- Reference Model for UART TX
-- Behaviorally equivalent to DUT
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ref_model_uart_tx is
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        din       : in  std_logic_vector(7 downto 0);
        din_vld   : in  std_logic;
        tx        : out std_logic;
        tx_done   : out std_logic
    );
end entity;

architecture behavioral of ref_model_uart_tx is
    type state_t is (IDLE, START, STOP);
    signal state : state_t;
    signal bit_count : integer range 0 to 7 := 0;
    signal shift_reg : std_logic_vector(7 downto 0);
    signal tx_reg : std_logic;
    constant BIT_PERIOD : time := 8680 ns;  -- 115200 baud @ 100 MHz
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= IDLE;
                bit_count <= 0;
                shift_reg <= (others => '0');
                tx_reg <= '1';
                tx_done <= '0';
            else
                tx_done <= '0';
                case state is
                    when IDLE =>
                        if din_vld = '1' then
                            shift_reg <= din;
                            state <= START;
                            bit_count <= 0;
                        else
                            tx_reg <= '1';
                        end if;

                    when START =>
                        tx_reg <= '0';
                        if bit_count = 8 then
                            state <= STOP;
                            bit_count <= 0;
                        else
                            bit_count <= bit_count + 1;
                            shift_reg <= shift_reg(6 downto 0) & '0';
                        end if;

                    when STOP =>
                        tx_reg <= '1';
                        state <= IDLE;
                        tx_done <= '1';
                end case;
            end if;
        end if;
    end process;

    tx <= tx_reg;
end architecture;
```

## B.3 Bit Collector + Scoreboard

```vhdl
-- ============================================================
-- Bit Collector: Captures tx line at baud rate
-- Builds complete frame for comparison
-- ============================================================

architecture sim of tb_uart_tx is
    constant CLK_PERIOD : time := 10 ns;
    constant BIT_PERIOD_115200 : time := 8680 ns;

    signal clk, rst_n : std_logic := '0';
    signal baud_sel : std_logic_vector(1 downto 0) := "10";
    signal din : std_logic_vector(7 downto 0) := (others => '0');
    signal din_vld, din_rdy : std_logic;
    signal tx : std_logic;
    signal tx_done : std_logic;

    signal pass_cnt, fail_cnt : integer := 0;

    -- Bit collector
    signal collect_active : boolean := false;
    signal collected_bits : std_logic_vector(9 downto 0);  -- start + 8 data + stop
    signal bit_idx : integer range 0 to 10 := 0;
    signal last_tx : std_logic := '1';

    -- Expected frame queue
    type frame_array is array (natural range <>) of std_logic_vector(7 downto 0);
    signal expected_q : frame_array(0 to 31) := (others => (others => '0'));
    signal q_head, q_tail : integer := 0;
begin
    clk <= not clk after CLK_PERIOD / 2;

    -- DUT
    dut : entity work.uart_tx_all
        port map (clk, rst_n, baud_sel, din, din_vld, din_rdy, tx, tx_done);

    -- ============================================================
    -- Bit Collector: Sample tx at baud rate
    -- ============================================================
    collector : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                collect_active <= false;
                bit_idx <= 0;
                collected_bits <= (others => '0');
                last_tx <= '1';
            else
                last_tx <= tx;

                -- Detect start bit (falling edge)
                if not collect_active and last_tx = '1' and tx = '0' then
                    collect_active <= true;
                    bit_idx <= 1;
                    collected_bits(0) <= '0';  -- start bit
                elsif collect_active then
                    if bit_idx < 9 then
                        -- Wait for half bit time + n*bit time
                        if ... then
                            collected_bits(bit_idx) <= tx;
                            bit_idx <= bit_idx + 1;
                        end if;
                    elsif bit_idx = 9 then
                        collected_bits(9) <= tx;  -- stop bit
                        collect_active <= false;
                        bit_idx <= 0;
                        -- Trigger scoreboard check
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- ============================================================
    -- Checker: Compare collected frame with expected
    -- ============================================================
    checker : process (clk)
        variable   collected_reg : std_logic_vector(9 downto 0);
        variable   expected_reg : std_logic_vector(9 downto 0);
        variable   exp_data : std_logic_vector(7 downto 0);
    begin
        if rising_edge(clk) then
            if collect_active = false and bit_idx = 0 and q_head /= q_tail then
                -- Frame received, check
                collected_reg := collected_bits;
                exp_data := expected_q(q_head);
                expected_reg := "0" & exp_data & "1";  -- start + data + stop

                if collected_reg = expected_reg then
                    pass_cnt <= pass_cnt + 1;
                    report "PASS: Frame match (0x" &
                           integer'image(to_integer(unsigned(exp_data))) & ")"
                        severity note;
                else
                    fail_cnt <= fail_cnt + 1;
                    assert false
                        report "FAIL: Got " &
                               integer'image(to_integer(unsigned(collected_reg(8 downto 1)))) &
                               " Expected " &
                               integer'image(to_integer(unsigned(exp_data)))
                        severity error;
                end if;

                q_head <= (q_head + 1) mod 32;
            end if;
        end if;
    end process;

    -- ============================================================
    -- Stimulus + Scoreboard queue
    -- ============================================================
    stim : process
        procedure send_byte(b : std_logic_vector(7 downto 0)) is
        begin
            -- Wait for ready
            while din_rdy = '0' loop
                wait until rising_edge(clk);
            end loop;

            -- Send byte
            din <= b;
            din_vld <= '1';
            wait until rising_edge(clk);
            din_vld <= '0';

            -- Enqueue expected
            expected_q(q_tail) <= b;
            q_tail <= (q_tail + 1) mod 32;
        end procedure;
    begin
        -- Reset
        rst_n <= '0';
        wait for 5 * CLK_PERIOD;
        rst_n <= '1';

        -- Test patterns
        send_byte(x"55");
        send_byte(x"AA");
        send_byte(x"00");
        send_byte(x"FF");
        send_byte(x"42");
        send_byte(x"3C");

        -- Wait for all frames to be scored
        wait until q_head >= 6;
        wait for 10 * BIT_PERIOD_115200;

        report "================================";
        report "UART TX Tests Complete";
        report "PASS=" & integer'image(pass_cnt);
        report "FAIL=" & integer'image(fail_cnt);
        report "================================";

        if fail_cnt = 0 then
            report "ALL TESTS PASSED" severity note;
        end if;

        std.env.stop;
    end process;
end architecture;
```

## B.4 Self-Checking TB (Simpler Approach)

```vhdl
-- ============================================================
-- Simplified Self-Checking TB
-- Uses core baud-rate sampling for verification
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_uart_tx_simple is
end entity;

architecture sim of tb_uart_tx_simple is
    constant CLK_PERIOD : time := 10 ns;
    constant BIT_PERIOD : time := 8680 ns;

    signal clk, rst_n : std_logic := '0';
    signal baud_sel : std_logic_vector(1 downto 0) := "10";
    signal din : std_logic_vector(7 downto 0);
    signal din_vld, din_rdy : std_logic;
    signal tx : std_logic;
    signal tx_done : std_logic;
    signal pass_cnt, fail_cnt : integer := 0;
begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.uart_tx_all
        port map (clk, rst_n, baud_sel, din, din_vld, din_rdy, tx, tx_done);

    stim : process
        procedure check_frame(expected : std_logic_vector(7 downto 0); tag : string) is
            variable collected : std_logic_vector(7 downto 0);
        begin
            -- Sample start bit (1.5 bit periods in to skip start)
            wait for BIT_PERIOD + (BIT_PERIOD / 2);

            -- Sample 8 data bits
            for i in 0 to 7 loop
                collected(i) := tx;
                wait for BIT_PERIOD;
            end loop;

            -- Compare
            if collected = expected then
                pass_cnt <= pass_cnt + 1;
                report "PASS " & tag & ": got 0x" &
                       integer'image(to_integer(unsigned(collected)))
                    severity note;
            else
                fail_cnt <= fail_cnt + 1;
                assert false
                    report "FAIL " & tag &
                           ": got 0x" & integer'image(to_integer(unsigned(collected))) &
                           " expected 0x" & integer'image(to_integer(unsigned(expected)))
                    severity error;
            end if;

            -- Wait for stop bit
            wait for BIT_PERIOD;
        end procedure;
    begin
        rst_n <= '0';
        wait for 5 * CLK_PERIOD;
        rst_n <= '1';
        wait for CLK_PERIOD;

        -- Test patterns
        din_vld <= '0';
        wait until din_rdy = '1';

        for trial in 0 to 7 loop
            case trial is
                when 0 => din <= x"55";
                when 1 => din <= x"AA";
                when 2 => din <= x"00";
                when 3 => din <= x"FF";
                when 4 => din <= x"42";
                when 5 => din <= x"3C";
                when 6 => din <= x"A5";
                when others => din <= x"5A";
            end case;

            din_vld <= '1';
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            din_vld <= '0';

            -- Wait for tx_done
            wait until tx_done = '1';
            wait for CLK_PERIOD;

            check_frame(din, "trial " & integer'image(trial));
            wait for CLK_PERIOD;
        end loop;

        report "================================";
        report "PASS=" & integer'image(pass_cnt) & " FAIL=" & integer'image(fail_cnt);
        report "================================";
        if fail_cnt = 0 then
            report "ALL TESTS PASSED" severity note;
        end if;
        std.env.stop;
    end process;
end architecture;
```

## B.5 Assertions (PSL)

```vhdl
-- File: uart_tx_assertions.vhd
-- Concurrent assertions for UART TX

architecture behavioural of tb_uart_with_assertions is
begin
    ----------------------------------------------------------
    -- PSL Default Clock
    ----------------------------------------------------------
    PSL default clock is rising_edge(clk);

    ----------------------------------------------------------
    -- Idle line = 1 when not transmitting
    ----------------------------------------------------------
    PSL assert always
        ((state = S_IDLE) -> (tx = '1'))
        report "TX line must be high in IDLE"
        severity failure;

    ----------------------------------------------------------
    -- Start bit must be 0
    ----------------------------------------------------------
    PSL assert always
        ((state = S_START) -> (tx = '0'))
        report "Start bit must be 0"
        severity failure;

    ----------------------------------------------------------
    -- Stop bit must be 1
    ----------------------------------------------------------
    PSL assert always
        ((state = S_STOP) -> (tx = '1'))
        report "Stop bit must be 1"
        severity failure;

    ----------------------------------------------------------
    -- din_rdy only low during transmission
    ----------------------------------------------------------
    PSL assert always
        ((state = S_LOAD or state = S_START or state = S_DATA or state = S_STOP) -> (din_rdy = '0'))
        report "din_rdy must be low during transmission"
        severity failure;

    ----------------------------------------------------------
    -- tx_done only pulses once per frame
    ----------------------------------------------------------
    PSL assert always
        ((tx_done = '1') -> next (tx_done = '0'))
        report "tx_done must pulse only 1 cycle"
        severity failure;

    ----------------------------------------------------------
    -- No X in output
    ----------------------------------------------------------
    PSL assert never
        (tx = 'X')
        report "X in TX output"
        severity failure;
end architecture;
```

---

# ส่วนที่ C: Coverage Modeling — เชิงลึก

## C.1 Functional Coverage ใน VHDL

เนื่องจาก VHDL ไม่มี covergroup ในตัว ต้อง implement เอง:

```vhdl
-- ============================================================
-- Functional Coverage Tracker for UART TX
-- ============================================================
architecture sim of tb_uart_tx_coverage is
    -- Coverage: Data values
    signal data_covered : bit_vector(0 to 255) := (others => '0');

    -- Coverage: Baud rates
    signal baud_covered : bit_vector(0 to 2) := (others => '0');

    -- Coverage: FSM states
    signal state_covered : bit_vector(0 to 4) := (others => '0');

    -- Coverage: bit_idx range (data back to 8)
    signal bit_idx_covered : bit_vector(0 to 7) := (others => '0');

    signal coverage_pct : integer := 0;
begin
    ----------------------------------------------------------
    -- Coverage Tracker
    ----------------------------------------------------------
    cov_proc : process (clk)
        variable count : integer := 0;
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                data_covered <= (others => '0');
                baud_covered <= (others => '0');
                state_covered <= (others => '0');
                bit_idx_covered <= (others => '0');
            else
                -- Track data values
                data_covered(to_integer(din)) <= '1';

                -- Track baud rates
                case baud_sel is
                    when "00"   => baud_covered(0) <= '1';
                    when "01"   => baud_covered(1) <= '1';
                    when "10"   => baud_covered(2) <= '1';
                    when others => null;
                end case;

                -- Track states
                case state is
                    when S_IDLE  => state_covered(0) <= '1';
                    when S_LOAD  => state_covered(1) <= '1';
                    when S_START => state_covered(2) <= '1';
                    when S_DATA  => state_covered(3) <= '1';
                    when S_STOP  => state_covered(4) <= '1';
                end case;

                -- Track bit_idx
                bit_idx_covered(bit_idx) <= '1';
            end if;
        end if;
    end process;

    ----------------------------------------------------------
    -- Coverage Report
    ----------------------------------------------------------
    report_proc : process
        variable total_covered : integer := 0;
        variable total_bins : integer := 256 + 3 + 5 + 4;
    begin
        wait for 5 ms;  -- end of sim

        -- Count data
        for i in data_covered'range loop
            if data_covered(i) = '1' then
                total_covered := total_covered + 1;
            end if;
        end loop;

        -- Count baud
        for i in baud_covered'range loop
            if baud_covered(i) = '1' then
                total_covered := total_covered + 1;
            end if;
        end loop;

        -- Count state
        for i in state_covered'range loop
            if state_covered(i) = '1' then
                total_covered := total_covered + 1;
            end if;
        end loop;

        -- Count bit_idx
        for i in bit_idx_covered'range loop
            if bit_idx_covered(i) = '1' then
                total_covered := total_covered + 1;
            end if;
        end loop;

        coverage_pct <= (total_covered * 100) / total_bins;

        report "================================";
        report "Functional Coverage Report";
        report "================================";
        report "Data covered: " & integer'image(total_covered) & "/" & integer'image(total_bins);
        report "Coverage: " & integer'image(coverage_pct) & "%";

        if coverage_pct >= 95 then
            report "COVERAGE GOAL MET" severity note;
        else
            report "COVERAGE GOAL NOT MET" severity failure;
        end if;

        wait;
    end process;
end architecture;
```

## C.2 SystemVerilog Covergroup (Alternative)

```systemverilog
// File: uart_tx_cover.sv
// Covergroup for UART TX (SystemVerilog)
module uart_tx_cover (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [1:0]  baud_sel,
    input  logic [7:0]  din,
    input  logic        din_vld,
    input  logic        din_rdy,
    input  logic        tx,
    input  logic        tx_done
);
    covergroup cg_uart_tx @(posedge clk);
        // Data coverage
        cp_data : coverpoint din {
            bins zero   = {8'h00};
            bins ff     = {8'hFF};
            bins alt1   = {8'h55, 8'hAA};
            bins alt2   = {8'h33, 8'hCC};
            bins middle = {[8'h01:8'h0F], [8'hF0:8'hFE]};
            bins rest   = default;
        }

        // Baud rate coverage
        cp_baud : coverpoint baud_sel {
            bins b9600   = {2'b00};
            bins b19200  = {2'b01};
            bins b115200 = {2'b10};
        }

        // Handshake coverage
        cp_handshake : coverpoint (din_vld && din_rdy) {
            bins bothready = 1;
            bins not_ready = 1;
        }

        // tx_done coverage
        cp_tx_done : coverpoint tx_done {
            bins pulse = 1;
            bins zero  = 0;
        }

        // Cross coverage
        cx_data_baud : cross cp_data, cp_baud;
        cx_data_hs    : cross cp_data, cp_handshake;
    endgroup

    cg_uart_tx cg_inst = new();
endmodule
```

## C.3 Questa Coverage Commands

```tcl
# In Questa do-file
vlib work
vcom -2008 uart_tx_all.vhd
vcom -2008 tb_uart_tx.vhd

vsim -coverage work.tb_uart_tx
add wave *
run 10 ms

# Save coverage database
coverage save -onexit cov.ucdb

# Generate HTML report
vcover report -details -annotate -output cov_report.html cov.ucdb

# Open GUI coverage viewer
vsim -viewcov cov.ucdb
```

---

# ส่วนที่ D: Synthesis Flow — เชิงลึก

## D.1 Synthesis Steps (Precision RTL)

```
   ┌─────────────────────────────────────────────┐
   │  1. Project Setup                              │
   │     - Library setup                           │
   │     - Work directory                          │
   └─────────────┬───────────────────────────────┘
                 │
                 ▼
   ┌─────────────────────────────────────────────┐
   │  2. Source File Loading                        │
   │     - VHDL/Verilog files                      │
   │     - Package files                            │
   │     - Library modules                          │
   └─────────────┬───────────────────────────────┘
                 │
                 ▼
   ┌─────────────────────────────────────────────┐
   │  3. Constraints Application                    │
   │     - SDC constraints                          │
   │     - Operating conditions                    │
   └─────────────┬───────────────────────────────┘
                 │
                 ▼
   ┌─────────────────────────────────────────────┐
   │  4. Top Module Setting                        │
   │     - Design hierarchy                        │
   │     - Generic parameters                      │
   └─────────────┬───────────────────────────────┘
                 │
                 ▼
   ┌─────────────────────────────────────────────┐
   │  5. Elaboration                                │
   │     - Build design hierarchy                   │
   │     - Apply generics                          │
   │     - Resolve instantiations                    │
   └─────────────┬───────────────────────────────┘
                 │
                 ▼
   ┌─────────────────────────────────────────────┐
   │  6. Compilation                                │
   │     - Generic synthesis                       │
   │     - Technology mapping                      │
   │     - Optimization                             │
   └─────────────┬───────────────────────────────┘
                 │
                 ▼
   ┌─────────────────────────────────────────────┐
   │  7. Report Generation                          │
   │     - Area report                              │
   │     - Timing report                            │
   │     - Power report                            │
   └─────────────┬───────────────────────────────┘
                 │
                 ▼
   ┌─────────────────────────────────────────────┐
   │  8. Output Generation                          │
   │     - Netlist (Verilog)                      │
   │     - SDF file                                  │
   │     - Constraints report                       │
   └─────────────────────────────────────────────┘
```

## D.2 Precision RTL Synthesis Script

```tcl
# ============================================================
# synth.tcl - Precision RTL Synthesis for UART TX
# Usage: precision -shell -file synth.tcl
# ============================================================

# === Setup ===
set tech_lib    "/path/to/gscl45nm"           ;# ⚠️ Adjust to actual library
set design_name "uart_tx_all"
set rtl_dir     "rtl"

# === Create project ===
if { [file exists work_$design_name] } {
    file delete -force work_$design_name
}
new_project -name $design_name \
            -folder work_$design_name \
            -technology "$tech_lib"

# === Add source files ===
add_source -type vhdl -work work -library work "$rtl_dir/uart_tx_all.vhd"

# === Add constraints ===
add_constraint_file "constraints/uart_tx.sdc"

# === Set top module ===
set_top_module uart_tx_all

# === Set generics ===
# (if any, set via set_parameter)

# === Elaborate ===
elaborate

# === Compile ===
# -incremental_mapping : avoid full re-elaboration
# -retiming : enable FF retiming
compile -incremental_mapping -retiming

# === Reports ===
file mkdir reports
report_constraints -file reports/constraints.rpt

report_area -file reports/area.rpt -append

report_timing -delay max -num_paths 100 -file reports/timing_max.rpt -append
report_timing -delay min -num_paths 100 -file reports/timing_min.rpt -append

report_power -file reports/power.rpt -append

# === Export ===
file mkdir netlist
export_netlist -format verilog -output netlist/uart_tx_netlist.v

write_sdf -output netlist/uart_tx.sdf

# === Done ===
puts ""
puts "========================================"
puts "Synthesis Complete!"
puts "Netlist:   netlist/uart_tx_netlist.v"
puts "SDF:       netlist/uart_tx.sdf"
puts "Reports:   reports/"
puts "========================================"

exit
```

## D.3 SDC Constraints for UART TX

```tcl
# ============================================================
# uart_tx.sdc - SDC for UART TX
# Target: 100 MHz system clock
# ============================================================

# Clock definition
create_clock -name sys_clk -period 10.0 -waveform {0 5} [get_ports clk]

# Input delays (relative to clock edge)
set_input_delay  -clock sys_clk 2.0 -max [get_ports {din din_vld baud_sel rst_n}]
set_input_delay  -clock sys_clk 1.0 -min [get_ports {din din_vld baud_sel rst_n}]

# Output delays
set_output_delay -clock sys_clk 2.0 -max [get_ports {tx tx_done din_rdy}]
set_output_delay -clock sys_clk 1.0 -min [get_ports {tx tx_done din_rdy}]

# Reset is synchronous - ignore
set_false_path -from [get_ports rst_n]

# Drive strength and load
set_driving_cell -lib_cell INVX1 -pin Y [get_ports {din din_vld baud_sel rst_n}]
set_load 0.05 [get_ports {tx tx_done din_rdy}]

# Operating conditions (PVT corner)
set_operating_conditions -process typical -voltage 1.0 -temp 25

# Don't touch critical sequential blocks (optional)
# set_dont_touch [get_cells u_baud_gen/u_baud_gen_core]
```

## D.4 Synthesis Reports

### D.4.1 Area Report (ตัวอย่าง)

```
============================================================
  Area Report
============================================================
Design: uart_tx_all
Library: gscl45nm

Cell Counts:
  INVX1: 42
  NAND2X1: 28
  NAND3X1: 8
  DFFRX1: 45
  MUX2X1: 12
  OAI21X1: 6
  Total: ~141 cells

Equivalent Gate Count: 580 gates
Area Utilization: 2.5% (of 1mm² die)

============================================================
```

### D.4.2 Timing Report (ตัวอย่าง)

```
============================================================
  Timing Report (Worst-Case Setup)
============================================================
Design: uart_tx_all
Clock: sys_clk (period 10 ns)

Path 1: VIOLATED -0.3 ns
  Start: baud_count_reg[7]
  Combinational delay: 4.2 ns
  Required: 8.0 ns
  Slack: -0.3 ns

Path 2: MET +0.5 ns
  Start: shift_reg_reg[3]
  Combinational delay: 3.5 ns
  Required: 8.0 ns
  Slack: +0.5 ns

...

============================================================
```

### D.4.3 Power Report (ตัวอย่าง)

```
============================================================
  Power Report
============================================================
Design: uart_tx_all
Process: Typical
Frequency: 100 MHz

Dynamic: 250 μW
Static: 15 μW
Total: 265 μW

Breakdown:
  Sequential: 60%
  Combinational: 30%
  Clock: 10%

============================================================
```

## D.5 Synthesis Optimization

### D.5.1 Common Optimization Knobs

```tcl
# Enable retiming
set_optimization_option -retiming true

# Set timing vs area trade-off
set_optimization_option -timing_driven true
set_optimization_option -area_driven true

# Clock gating inference
set_optimization_option -clock_gating_inference true

# Resource sharing
set_optimization_option -resource_sharing true
```

### D.5.2 Multi-Vt Optimization

```tcl
# Use low-Vt cells for critical paths
set_cell_routing -name low_vt_list [get_cells ...]

# Use high-Vt cells for non-critical paths (saves power)
set_cell_routing -name high_vt_list [get_cells ...]
```

---

# ส่วนที่ E: Gate-Level Simulation (GLS) — เชิงลึก

## E.1 GLS Setup Flow

```
   ┌─────────────────────────────────────────────┐
   │  1. Compile cell library                      │
   │     vlog -work tech_lib cell_lib.v            │
   └─────────────┬───────────────────────────────┘
                 │
                 ▼
   ┌─────────────────────────────────────────────┐
   │  2. Compile netlist                            │
   │     vlog -work work_gate uart_tx_netlist.v    │
   └─────────────┬───────────────────────────────┘
                 │
                 ▼
   ┌─────────────────────────────────────────────┐
   │  3. Compile testbench                          │
   │     vcom -2008 -work work_gate tb_uart_tx.vhd │
   └─────────────┬───────────────────────────────┘
                 │
                 ▼
   ┌─────────────────────────────────────────────┐
   │  4. Load simulation with SDF                  │
   │     vsim -t ps -sdf /tb/dut=top.sdf          │
   │          work_gate.tb_uart_tx                 │
   └─────────────┬───────────────────────────────┘
                 │
                 ▼
   ┌─────────────────────────────────────────────┐
   │  5. Add waves and run                          │
   └─────────────────────────────────────────────┘
```

## E.2 Questa Commands (Questa Batch Mode)

```tcl
# run_gls.do - GLS with SDF
vlib tech_lib
vlib work_gate

# Compile cell library (one-time)
vlog -work tech_lib /tech_lib/gscl45nm.v

# Compile synthesized netlist
vlog -work work_gate netlist/uart_tx_netlist.v

# Compile testbench
vcom -2008 -work work_gate tb_uart_tx.vhd

# Start simulation with SDF
vsim -t ps \
     -sdf /tb_uart_tx/dut=netlist/uart_tx.sdf \
     work_gate.tb_uart_tx

# Add waves
add wave -position insertpoint sim:/tb_uart_tx/*
add wave -position insertpoint sim:/tb_uart_tx/dut/*

# Run
run 10 ms

# Save coverage
coverage save -onexit gls_cov.ucdb

# Done
quit -f
```

## E.3 Multi-corner GLS

```tcl
# run_gls_multicorner.do
foreach corner {typ fast slow} {
    puts ""
    puts "========================================"
    puts "Running corner: $corner"
    puts "========================================"

    vlib work_gate_$corner

    # Compile netlist
    vlog -work work_gate_$corner /tech_lib/gscl45nm.v
    vlog -work work_gate_$corner netlist/uart_tx_netlist.v

    # Compile TB
    vcom -2008 -work work_gate_$corner tb_uart_tx.vhd

    # Load SDF (different file per corner)
    vsim -t ps \
         -sdf /tb_uart_tx/dut=netlist/uart_tx_${corner}.sdf \
         work_gate_$corner.tb_uart_tx

    # Run
    add wave -position insertpoint sim:/tb_uart_tx/*
    run 10 ms

    # Save coverage per corner
    coverage save -onexit gls_${corner}.ucdb
    quit -f
}

# Merge coverage from all corners
vcover merge gls_merged.ucdb \
                 gls_typ.ucdb \
                 gls_fast.ucdb \
                 gls_slow.ucdb
```

## E.4 GLS Debug

### E.4.1 ตรวจ Setup/Hold Violations

```tcl
# In Questa transcript after GLS
report_timing -delay max -num_paths 10

# Expected output:
# Path 1: MET +0.5 ns
# Path 2: MET +0.3 ns
# ...
```

### E.4.2 ตรวจ X-Propagation

```tcl
# Add to TB
p_x_check : process (clk)
begin
    if rising_edge(clk) then
        if tx = 'X' or din_rdy = 'X' or tx_done = 'X' then
            assert false
                report "X propagation detected at " & time'image(now)
                severity error;
        end if;
    end if;
end process;
```

### E.4.3 ตรวจ Timing Violation

```tcl
# In transcript
# ** Warning: Setup violation detected
# **         Time: 12.345 ns  Iteration: 50
# **         Path: dut.U1 → dut.U2
# **         Required setup time: 0.150 ns
# **         Actual setup time: 0.100 ns

# Save waveform รอบ violation
write wave -window 12.0ns 14.0ns violation.glg
```

---

# ส่วนที่ F: Sign-off Report Template

## F.1 Final Verification Report

```markdown
# UART TX Verification Report

## 1. Design Specification
[Spec from Mini Project]

## 2. RTL Design
- File: rtl/uart_tx_all.vhd
- Architecture: FSM + Baud Generator + Shift Register
- Lines of code: ~80

## 3. Verification

### 3.1 Test Plan
- 9 test cases covering all functions
- 8-N-1 frame format
- All 256 byte values
- All 3 baud rates

### 3.2 Test Results
| Test | Status |
|------|--------|
| Reset | ✅ PASS |
| Send 0x55 | ✅ PASS |
| Send 0xAA | ✅ PASS |
| Send 0x00 | ✅ PASS |
| Send 0xFF | ✅ PASS |
| All 256 bytes | ✅ PASS |
| Back-to-back | ✅ PASS |
| Different baud | ✅ PASS |
| Reset during TX | ✅ PASS |

**Total: 9/9 PASS**

### 3.3 Coverage
- **Functional Coverage**: 100%
- **Statement Coverage**: 96%
- **Branch Coverage**: 92%
- **Toggle Coverage**: 100% (with exclusions)
- **Assertion Coverage**: 100%

## 4. Synthesis Results

| Metric | Value |
| --- | --- |
| Tool | Precision RTL |
| Cell library | gscl45nm |
| Area (gates) | 580 |
| Max frequency | 200 MHz |
| Worst slack | +0.5 ns (typ corner) |
| Dynamic power | 250 μW @ 100 MHz |
| Static power | 15 μW |

See reports/area.rpt, timing.rpt, power.rpt

## 5. Gate-Level Simulation

| Item | Status |
| --- | --- |
| RTL TB runs against netlist | ✅ PASS |
| SDF loaded successfully | ✅ Yes |
| Setup violations | 0 |
| Hold violations | 0 |
| X-propagation | 0 |
| Multi-corner verified | ✅ typ, fast, slow |

## 7. Conclusion

All checks passed:
- ✅ Functional verification complete
- ✅ Code coverage exceeds thresholds
- ✅ Synthesis successful
- ✅ GLS passes with SDF
- ✅ Multi-corner verification successful
- ✅ All assertions pass

**Status: READY FOR TAPE-OUT**

## 8. Sign-off

| Role | Name | Date | Signature |
| --- | --- | --- | --- |
| Designer | ____ | ____ | ____ |
| Verifier | ____ | ____ | ____ |
| Lead Engineer | ____ | ____ | ____ |
```

## F.2 Bugs Found and Fixed

```markdown
## Bug Report

### Bug #1: TX output not idle after reset
- **Severity**: High
- **Found by**: GLS
- **Description**: After reset, TX line was 'X' instead of '1'
- **Root cause**: Missing tx_reg initialization
- **Fix**: Added tx_reg <= '1' in reset path

### Bug #2: din_rdy glitch during LOAD state
- **Severity**: Medium
- **Found by**: Assertion
- **Description**: din_rdy was '1' briefly during LOAD state
- **Root cause**: Race condition between sync and logic
- **Fix**: Added default din_rdy='0' in LOAD case
```

## F.3 Verification Coverage Summary

```markdown
## Coverage Summary

### Functional Coverage
| Feature | Bins | Covered | % |
|---------|------|---------|---|
| Data values | 256 | 256 | 100% |
| Baud rates | 3 | 3 | 100% |
| States | 5 | 5 | 100% |
| Handshake | 2 | 2 | 100% |
| Bit indices | 8 | 8 | 100% |

### Code Coverage
- Statement: 96%
- Branch: 92%
- Condition: 88%
- Toggle: 100% (with exclusions)

### Assertion Coverage
- Total assertions: 5
- Passing: 5
- Coverage: 100%
```

---

# ส่วนที่ G: Key Takeaways

## G.1 Verification Strategy

1. **Layered approach** — block → sub-system → chip
2. **Reference model** — catch RTL bugs
3. **Scoreboard** — transaction-level verification
4. **Assertions** — protocol + spec compliance
5. **Coverage-driven** — systematic verification

## G.2 Synthesis Best Practices

1. **Set top module** ก่อน elaborate
2. **Use SDC constraints** — clock, IO delays
3. **Check timing report** — slack, critical paths
4. **Use -retiming** option for sequential logic
6. **Generate SDF** — for GLS
7. **Export netlist** — Verilog for back-end

## G.3 GLS Strategy

1. **Same TB** — reuse RTL TB
2. **SDF back-annotation** — accurate timing
3. **Multi-corner** — typ/fast/slow
4. **Watch for X** — sign of timing issues
5. **Glitch detection** — race conditions

## G.4 Sign-off Checklist

| Item | Status |
| --- | --- |
| RTL verification | ☐ |
| Functional coverage ≥ 95% | ☐ |
| Code coverage ≥ 95% | ☐ |
| All assertions pass | ☐ |
| Synthesis successful | ☐ |
| Timing constraints met | ☐ |
| Area within budget | ☐ |
| GLS passes | ☐ |
| Multi-corner verified | ☐ |
| No X propagation | ☐ |
| Documentation complete | ☐ |

---

# ส่วนที่ H: Practical Flow Examples

## H.1 Complete Mini Project Workflow

```bash
# === Day 5 Workflow ===

# 1. RTL Design
mkdir rtl tb constraints scripts reports netlist
# Edit rtl/uart_tx_all.vhd (design)

# 2. RTL Verification (Questa)
vlib work
vcom -2008 rtl/uart_tx_all.vhd
vcom -2008 tb/tb_uart_tx.vhd
vsim work.tb_uart_tx
# Run, debug, iterate until PASS

# 3. Synthesis (Precision RTL)
precision -shell -file scripts/synth.tcl

# 4. Review reports
cat reports/area.rpt
cat reports/timing_max.rpt
cat reports/power.rpt

# 5. GLS (Questa)
vlib work_gate
vlog -work work_gate netlist/uart_tx_netlist.v
vcom -2008 -work work_gate tb/tb_uart_tx.vhd
vsim -t ps -sdf /tb_uart_tx/dut=netlist/uart_tx.sdf \
     work_gate.tb_uart_tx

# 6. Multi-corner GLS
vsim -do run_gls_multicorner.do -c

# 7. Coverage
coverage save -onexit cov.ucdb
vcover report -details cov_report.html cov.ucdb

# 8. Final report
# Edit reports/final_report.md

# 9. Sign-off
# All approvals collected
```

## H.2 Common Issues and Solutions

| Issue | Diagnosis | Solution |
| --- | --- | --- |
| RTL pass, synth fail | Latch, clock issue | Fix RTL, eliminate latches |
| RTL pass, GLS fail | Timing violation | Optimize RTL, increase clock period |
| Coverage < 95% | Missing tests | Add targeted tests |
| SDF load fail | Path typo | Check file location |
| X in output | Uninitialized FF | Add reset |
| Glitch on TX | Asynchronous logic | Use synchronous design |
| din_rdy glitch | Race condition | Add default assignment |

---

# ส่วนที่ I: อ้างอิง

- "Siemens EDA Questa Advanced Simulator User Manual."
- "Precision RTL Synthesis User Manual."
- "UART Protocol Specification," Texas Instruments.
- Cummings, C. E. "FSM Design Techniques," SNUG 2000.
- IEEE 1850-2010, "Standard for PSL."
- IEEE 1800-2017, "Standard for SystemVerilog."
- "Verification Methodology Manual for SystemVerilog," Cadence Design Systems.

---

> **หมายเหตุ:** เนื้อหานี้ออกแบบให้บรรยายได้ประมาณ 90-120 นาที รวม code เต็ม (Reference Model, Self-checking TB, Assertions, Synthesis Tcl), Questa batch scripts, multi-corner GLS, final report template พร้อมใช้ประกอบการสอนภาคปฏิบัติ Day 5 บ่าย หรือแบ่งเป็น 2 mini-lectures (Verification 60 นาที + Synthesis + GLS 60 นาที)
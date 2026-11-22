# Lab Sheet 4: GLS + Assertion-based Testbench

Nov 22, 2026 · @Chumnarn Punyasai

เมื่อจบแลปนี้ ผู้เรียนจะมี testbench ที่ตรวจด้วย PSL assertion 4 ตัว และ cover 2 จุด ใช้ได้ทั้งกับ RTL และ gate-level netlist พร้อม SDF และอธิบายได้ว่าทำไม GLS จับปัญหาที่ RTL simulation มองไม่เห็น

## ข้อมูลแลป

| หัวข้อ | รายละเอียด |
| --- | --- |
| เวลา | 2.5–3 ชั่วโมง |
| ระดับ | กลาง–สูง (ต้องทำ Lab 3B Part 8 มาแล้ว เพื่อมี netlist และ SDF) |
| เครื่องมือ | Questa (mixed VHDL + Verilog), PDK sky130A จาก LibreLane · ทางเลือก: GHDL สำหรับ RTL simulation |
| ดีไซน์ | `adder8_pipe` เหมือน Lab 3B (adder 8 บิต, register 2 ชั้น, synchronous reset) |
| สิ่งที่ต้องส่ง | log RTL sim, log GLS ทุก corner, ภาพ waveform ที่เห็น delay จาก SDF, log การทดลอง timing violation, coverage report, `report_gls.md` |

### วัตถุประสงค์การเรียนรู้

1. เขียน PSL assertion และ cover directive ใน VHDL-2008
2. ออกแบบ testbench ที่ใช้ได้ทั้งกับ RTL และ netlist ที่มี delay จริง
3. รัน gate-level simulation พร้อม SDF back-annotation ใน Questa
4. อ่าน timing violation และตามหาต้นตอของ X
5. สรุปผลเป็นรายงาน GLS พร้อม coverage

### สิ่งที่เปลี่ยนจากคู่มือต้นฉบับ

| ปัญหาในต้นฉบับ | ใน Lab Sheet นี้ |
| --- | --- |
| RTL และ testbench compile ไม่ผ่าน (PSL อยู่นอก architecture, index ผลของ expression, กำหนด `std_logic_vector` ให้ signal ชนิด `unsigned`, `integer'(now)`) | เขียนใหม่ทั้งสองไฟล์ ผ่าน GHDL 4.1 (VHDL-2008) แล้ว |
| DUT เป็น combinational ล้วน (`clk`, `rst_n` ไม่ได้ใช้) จึงไม่มี setup/hold ให้ตรวจ | ใช้ `adder8_pipe` ที่มี flip-flop 26 ตัว |
| สุ่ม `cin` ด้วย `std_logic'val(...)` ซึ่งได้ `'X'` กับ `'0'` | ใช้ `ieee.math_real.uniform` |
| ใช้ Precision RTL กับ library สมมติ (`gscl45nm`) เพื่อสร้าง SDF | ใช้ netlist + SDF จริงจาก LibreLane (Lab 3B) ส่วน FPGA ให้เอา SDF จากเครื่องมือ P&R ของผู้ผลิต |
| `set_false_path` กับ synchronous reset | ไม่ใช้ (เหตุผลเดียวกับ Lab 3A) |
| ตัวนับ pass/fail เป็น signal | ใช้ variable |
| สคริปต์ multi-corner เรียก `quit -f` ใน loop (ปิด Questa ตั้งแต่ corner แรก) | ใช้ `quit -sim` ใน loop |
| สรุปผลว่า "ready for tape-out" | GLS เป็นหลักฐานหนึ่งเท่านั้น signoff จริงต้องมี STA, DRC/LVS และ formal ด้วย |

> 📝 **หมายเหตุ:** Part 1–3 (RTL, testbench, assertion) ผ่านการรันจริงด้วย GHDL 4.1 แล้ว ส่วนคำสั่ง Questa สำหรับ GLS (Part 4–7) ยังไม่ได้รันจริง ให้ตรวจชื่อไฟล์และ option กับเวอร์ชันที่ติดตั้งในห้องแลบ

## Part 0: เตรียมโฟลเดอร์และไฟล์ (10 นาที)

**เป้าหมาย:** มีโฟลเดอร์ `lab4_work` ที่มี RTL, testbench, netlist และ SDF ครบ

1. สร้างโฟลเดอร์ (PowerShell)

```powershell
$L = "E:\lab\VHDL(BOI)\lab4_work"
mkdir "$L\rtl", "$L\tb", "$L\gate", "$L\reports"
cd $L
```

2. เตรียมไฟล์ตามตาราง

| ไฟล์ | มาจาก | ใช้ใน Part |
| --- | --- | --- |
| `rtl/adder8_pipe.vhd` | พิมพ์เอง (Part 1) | 1, 3 |
| `tb/tb_adder8_pipe.vhd` | พิมพ์เอง (Part 2) | 2, 3, 5 |
| `gate/adder8_pipe.nl.v` | netlist หลัง P&R จาก LibreLane (Lab 3B) | 5 |
| `gate/*.sdf` | SDF จาก LibreLane (Lab 3B) | 5, 6 |
| `primitives.v`, `sky130_fd_sc_hd.v` | Verilog model ของ cell ใน PDK sky130A | 5 |
| `run_rtl.do`, `run_gls.do`, `run_multicorner.do` | พิมพ์เอง (Part 3, 5, 6) | 3, 5, 6 |

> 📝 **หมายเหตุ:** ไม่ต้องใช้ SDC แยกในแลบนี้ เพราะ SDF สร้างจาก SDC ของ Lab 3B แล้ว (clock 10 ns)

> ✅ **จุดตรวจสอบ:** มีโฟลเดอร์ `rtl`, `tb`, `gate`, `reports` และรู้ว่าผล LibreLane ของ Lab 3B อยู่ที่ไหน (Part 4 จะคัดลอกมา)

## Part 1: RTL Design — `adder8_pipe` (10 นาที)

**เป้าหมาย:** เขียน DUT เป็น VHDL ที่มี port ตรงกับ netlist จาก Lab 3B ทุกตัว เพื่อให้ testbench เดียวใช้ได้ทั้งสองแบบ

| Port | ทิศทาง | ความกว้าง | หน้าที่ |
| --- | --- | --- | --- |
| `clk` | in | 1 | clock 100 MHz |
| `rst` | in | 1 | synchronous reset, active-high |
| `cin`, `a`, `b` | in | 1, 8, 8 | operand |
| `sum`, `cout` | out | 8, 1 | ผลบวก ออกหลัง 2 ขอบขาขึ้น |

1. สร้าง `rtl/adder8_pipe.vhd`

```vhdl
-- ============================================================
-- File: rtl/adder8_pipe.vhd
-- Lab 4 - 8-bit adder, 2 register stages (same ports as Lab 3B)
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder8_pipe is
    port (
        clk  : in  std_logic;
        rst  : in  std_logic;                     -- synchronous, active-high
        cin  : in  std_logic;
        a    : in  std_logic_vector(7 downto 0);
        b    : in  std_logic_vector(7 downto 0);
        sum  : out std_logic_vector(7 downto 0);
        cout : out std_logic
    );
end entity adder8_pipe;

architecture rtl of adder8_pipe is
    signal r1_a, r1_b : unsigned(7 downto 0);
    signal r1_cin     : std_logic;
begin
    process (clk)
        variable vs : unsigned(8 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r1_a <= (others => '0'); r1_b <= (others => '0'); r1_cin <= '0';
                sum  <= (others => '0'); cout <= '0';
            else
                -- stage 1: register inputs
                r1_a <= unsigned(a); r1_b <= unsigned(b); r1_cin <= cin;
                -- stage 2: add + register
                vs := ('0' & r1_a) + ('0' & r1_b) + unsigned'("" & r1_cin);
                sum  <= std_logic_vector(vs(7 downto 0));
                cout <= vs(8);
            end if;
        end if;
    end process;
end architecture rtl;
```

### 1.1 จุดที่ควรสังเกต

- ใส่วงเล็บให้ `('0' & r1_a)` เสมอ เพราะใน VHDL `&` กับ `+` มีลำดับความสำคัญเท่ากันและทำจากซ้ายไปขวา โค้ดต้นฉบับ `"0" & din_a + "0" & din_b` จึงคำนวณผิดลำดับ
- `unsigned'("" & r1_cin)` แปลง `std_logic` 1 บิตเป็น `unsigned` ความกว้าง 1 ให้บวกได้ใน expression เดียว (ได้ cell น้อยที่สุด ตาม Lab 3B Part 6)
- port เป็น `std_logic_vector` ไม่ใช่ `unsigned` เพราะ netlist Verilog มีแต่ wire ธรรมดา ถ้าชนิดไม่ตรง testbench จะต่อกับ netlist ไม่ได้
- assertion อยู่ใน testbench ทั้งหมด เพราะ netlist จะไม่มี assertion ที่เขียนไว้ใน RTL ติดไปด้วย

> ✅ **จุดตรวจสอบ:** `vcom -2008 rtl/adder8_pipe.vhd` ผ่านโดยไม่มี error

## Part 2: Assertion-based Testbench (30 นาที)

**เป้าหมาย:** เขียน testbench ที่ตรวจ DUT ด้วย 2 ชั้น คือ PSL assertion ที่เฝ้าดูตลอดเวลา และ immediate check ที่นับ pass/fail และใช้ได้ทั้งกับ RTL และ netlist ที่มี delay

&#91;embedded content: โครงสร้าง testbench · 5 ส่วน\]

### 2.1 หลักการจัดจังหวะเวลา (สำคัญมากสำหรับ GLS)

- **เปลี่ยน input ที่ขอบขาลง** ให้ input นิ่งครึ่ง clock ก่อนขอบขาขึ้น setup/hold ของ flip-flop ใน netlist จะไม่ถูกละเมิดจากตัว testbench เอง
- **ตรวจ output ที่ขอบขาลง** (ก่อนเปลี่ยน input) คือครึ่ง clock หลังขอบขาขึ้น ใน GLS output เปลี่ยนหลังขอบขาขึ้นตาม clock-to-Q และ delay ของสาย ถ้าตรวจที่ขอบขาขึ้น + 1 ns แบบ Lab 2 อาจเร็วเกินไป
- **PSL สุ่มค่าที่ขอบขาขึ้น** (`default clock is rising_edge(clk)`) ค่าที่เห็นคือค่าก่อน flip-flop เปลี่ยน ซึ่งนิ่งมาตลอด cycle ก่อน
- **Reference model** (`exp_q1` → `exp_q2`) เป็น pipeline 2 ชั้นเหมือน DUT จึงเทียบกันได้ทุก cycle ส่วน `v_q2` บอกว่า output ต้อง valid แล้ว (ผ่านไป 2 ขอบหลังปล่อย reset)

### 2.2 Assertion และ cover ที่ใช้

| ชื่อ | ประเภท | ตรวจอะไร | จับ bug แบบไหน |
| --- | --- | --- | --- |
| `a1_reset` | assert | `rst = '1'` แล้ว clock ถัดไป output ต้องเป็น 0 | reset ไม่ครบทุก register |
| `a2_result` | assert | เมื่อ valid ผลต้องเท่า reference model | logic ผิด, latency ผิด |
| `a3_no_x` | assert | เมื่อ valid output ต้องไม่มี `X`/`U` (ใช้ `is_x` ตรวจทุกบิต) | timing violation ใน GLS, FF ไม่ได้ reset |
| `a4_inputs` | assert | นอก reset input ต้องไม่มี `X` | stimulus ของ testbench ผิดเอง |
| `c1_carry` | cover | เคยเกิด `cout = '1'` หรือยัง | stimulus ไม่ครอบคลุม carry |
| `c2_allone` | cover | เคยเกิด `sum = x"FF"` หรือยัง | ไม่ได้ทดสอบค่าสุดขอบ |

> 📝 **หมายเหตุ:** คู่มือต้นฉบับตรวจ X ด้วย `sum = "XXXXXXXX"` ซึ่งจะจริงเฉพาะตอนทุกบิตเป็น `X` พร้อมกัน ถ้า X อยู่บิตเดียวหรือเป็น `U` จะหลุด `is_x()` ของ VHDL-2008 ตรวจได้ครบทุกกรณี

### 2.3 ขั้นตอน

1. สร้าง `tb/tb_adder8_pipe.vhd`

```vhdl
-- ============================================================
-- File: tb/tb_adder8_pipe.vhd
-- Lab 4 - Assertion-based testbench (RTL and gate-level)
--   * PSL concurrent assertions + cover (sampled at rising edge)
--   * immediate checks with pass/fail counters
--   * X detection on outputs
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_adder8_pipe is
    generic (
        N_RANDOM   : natural := 200;
        CLK_PERIOD : time    := 10 ns    -- override: vsim -gCLK_PERIOD=4ns
    );
end entity tb_adder8_pipe;

architecture sim of tb_adder8_pipe is
    signal clk  : std_logic := '0';
    signal rst  : std_logic := '1';
    signal cin  : std_logic := '0';
    signal a, b : std_logic_vector(7 downto 0) := (others => '0');
    signal sum  : std_logic_vector(7 downto 0);
    signal cout : std_logic;
    signal done : boolean := false;

    -- reference model: expected result delayed by 2 rising edges
    signal exp_q1, exp_q2 : unsigned(8 downto 0) := (others => '0');
    signal v_q1, v_q2     : std_logic := '0';    -- '1' = output must be valid
    signal res            : unsigned(8 downto 0);

    component adder8_pipe is
        port (clk, rst, cin : in std_logic;
              a, b : in std_logic_vector(7 downto 0);
              sum  : out std_logic_vector(7 downto 0);
              cout : out std_logic);
    end component;
begin
    clk <= not clk after CLK_PERIOD / 2 when not done;
    res <= unsigned(cout & sum);

    dut : adder8_pipe
        port map (clk => clk, rst => rst, cin => cin, a => a, b => b,
                  sum => sum, cout => cout);

    -- reference pipeline (same timing as DUT)
    ref_model : process (clk)
    begin
        if rising_edge(clk) then
            exp_q1 <= ('0' & unsigned(a)) + ('0' & unsigned(b)) + unsigned'("" & cin);
            exp_q2 <= exp_q1;
            v_q1   <= not rst;
            v_q2   <= v_q1 and not rst;
        end if;
    end process;

    ------------------------------------------------------------
    -- Concurrent assertions in VHDL-2008 PSL syntax
    ------------------------------------------------------------
    default clock is rising_edge(clk);

    -- A1: reset clears outputs on the next clock
    a1_reset : assert always (rst = '1') -> next (res = 0)
        report "A1: outputs not cleared after reset";

    -- A2: result equals reference model when valid
    a2_result : assert always (v_q2 = '1') -> (res = exp_q2)
        report "A2: sum/cout mismatch with reference model";

    -- A3: no X/U on outputs once out of reset
    a3_no_x : assert always (v_q2 = '1') -> (not is_x(cout & sum))
        report "A3: X or U on DUT outputs";

    -- A4: stimulus sanity - inputs never X while not in reset
    a4_inputs : assert always (rst = '0') -> (not is_x(cin & a & b))
        report "A4: X on DUT inputs";

    -- coverage points
    c1_carry : cover {v_q2 = '1' and cout = '1'};
    c2_allone : cover {v_q2 = '1' and sum = x"FF"};

    ------------------------------------------------------------
    -- Stimulus + immediate checks (inputs change on falling edge)
    ------------------------------------------------------------
    stim : process
        variable seed1, seed2 : positive := 42;
        variable r1, r2, r3   : real;
        variable pass_cnt, fail_cnt, x_cnt, carry_cnt : natural := 0;

        procedure drive(va, vb : natural; vc : std_logic) is
        begin
            wait until falling_edge(clk);
            -- immediate check of the value that is already at the output
            if v_q2 = '1' then
                if is_x(cout & sum) then
                    x_cnt := x_cnt + 1;
                    report "X detected on outputs at " & time'image(now) severity error;
                elsif res = exp_q2 then
                    pass_cnt := pass_cnt + 1;
                    if cout = '1' then carry_cnt := carry_cnt + 1; end if;
                else
                    fail_cnt := fail_cnt + 1;
                    report "FAIL got=" & integer'image(to_integer(res)) &
                           " exp=" & integer'image(to_integer(exp_q2)) severity error;
                end if;
            end if;
            a   <= std_logic_vector(to_unsigned(va, 8));
            b   <= std_logic_vector(to_unsigned(vb, 8));
            cin <= vc;
        end procedure;

        function rnd(x : real; n : natural) return natural is
        begin
            return natural(floor(x * real(n)));
        end function;
    begin
        -- reset for 3 rising edges
        rst <= '1';
        for i in 1 to 3 loop wait until falling_edge(clk); end loop;
        rst <= '0';

        -- directed corner cases
        drive(0,   0,   '0');
        drive(1,   1,   '0');
        drive(255, 1,   '0');   -- 256 -> sum 00, cout 1
        drive(128, 128, '0');   -- 256
        drive(255, 255, '1');   -- 511 -> sum FF, cout 1
        drive(170, 85,  '0');   -- 255 -> sum FF, cout 0

        -- random
        for i in 1 to N_RANDOM loop
            uniform(seed1, seed2, r1);
            uniform(seed1, seed2, r2);
            uniform(seed1, seed2, r3);
            if r3 > 0.5 then drive(rnd(r1, 256), rnd(r2, 256), '1');
            else             drive(rnd(r1, 256), rnd(r2, 256), '0');
            end if;
        end loop;

        -- flush the pipeline (3 more checks)
        drive(0, 0, '0');
        drive(0, 0, '0');
        drive(0, 0, '0');

        report "====================================";
        report "PASS=" & integer'image(pass_cnt) & " FAIL=" & integer'image(fail_cnt) &
               " X=" & integer'image(x_cnt) & " carry_seen=" & integer'image(carry_cnt);
        report "====================================";
        if fail_cnt = 0 and x_cnt = 0 and carry_cnt > 0 then
            report "Lab 4 ALL TESTS PASSED" severity note;
        else
            report "Lab 4 TESTS FAILED" severity failure;
        end if;
        done <= true;
        std.env.stop;
    end process;
end architecture sim;
```

2. บันทึกไฟล์

### 2.4 จุดที่ควรสังเกต

- DUT ถูกเรียกผ่าน **component** (ไม่ใช่ `entity work.xxx`) เพราะใน GLS DUT คือ module Verilog Questa จะผูก component กับ RTL หรือ netlist ตามที่ compile ไว้ใน library
- `CLK_PERIOD` เป็น generic เพื่อเร่ง clock ใน Part 6 โดยไม่ต้องแก้โค้ด
- ตัวนับทุกตัวเป็น `variable` (บทเรียนจาก Lab 2)
- ผลสุดท้าย PASS ต้องมี `carry_cnt > 0` ด้วย ถ้าไม่เคยทดสอบ carry เลยถือว่าไม่ผ่าน

> ✅ **จุดตรวจสอบ:** อธิบายได้ว่าทำไม testbench ตรวจ output ที่ขอบขาลง แต่ PSL สุ่มที่ขอบขาขึ้น และทำไมจึงใช้ได้ทั้งกับ RTL และ GLS

## Part 3: RTL Simulation และทดสอบว่า Assertion จับ Bug ได้ (20 นาที)

**เป้าหมาย:** testbench ผ่านกับ RTL (`PASS=208`, assertion ผ่าน 4/4, cover ครบ 2/2) และเห็น assertion ทำงานเมื่อใส่ bug

### 3.1 รันใน Questa

1. สร้าง `run_rtl.do`

```tcl
# run_rtl.do - RTL simulation (vsim -c -do run_rtl.do)
onerror {quit -f -code 1}
onbreak {resume}
vlib work_rtl
vcom -2008 -work work_rtl rtl/adder8_pipe.vhd
vcom -2008 -work work_rtl tb/tb_adder8_pipe.vhd
vsim -voptargs=+acc -assertdebug work_rtl.tb_adder8_pipe
run -all
quit -f
```

2. รัน

```powershell
vsim -c -do run_rtl.do
```

3. ตรวจ Transcript ต้องมี

```text
# ** Note: PASS=208 FAIL=0 X=0 carry_seen=103
# ** Note: Lab 4 ALL TESTS PASSED
```

4. เปิดแบบ GUI (ไม่ใส่ `-c` และตัด `quit -f`) แล้วเปิดหน้าต่าง Assertions และ Cover Directives (เมนู View) ตรวจว่า `a1_reset`–`a4_inputs` ไม่มี failure และ `c1_carry`, `c2_allone` ถูก cover แล้ว

> 📝 **หมายเหตุ:** ตอนเริ่ม simulation อาจมี warning `NUMERIC_STD."=": metavalue detected` 1 ครั้งที่ 5 ns เพราะตอนนั้น output ยังเป็น `U` เป็นเรื่องปกติ

### 3.2 ทางเลือก: รันด้วย GHDL (ไม่ต้องมี license)

```bash
ghdl -a --std=08 rtl/adder8_pipe.vhd tb/tb_adder8_pipe.vhd
ghdl -e --std=08 tb_adder8_pipe
ghdl -r --std=08 tb_adder8_pipe --psl-report=reports/psl.json
```

ผลสรุปใน `reports/psl.json` ต้องมี `assert-pass: 4`, `assert-failure: 0`, `cover-pass: 2`

### 3.3 ทดสอบว่า assertion จับ bug ได้จริง

คัดลอก `rtl/adder8_pipe.vhd` ไปแก้ทีละแบบ แล้วรันซ้ำ (เสร็จแล้วคืนไฟล์เดิม)

| Bug ที่ใส่ | วิธีแก้ไฟล์ | ผลที่ได้จากการรันจริง |
| --- | --- | --- |
| B1: ลืมบวก carry-in | ลบ `  + unsigned'("" & r1_cin) ` ออก | `a2_result` แจ้ง 93 ครั้ง และสรุป `PASS=115 FAIL=93` |
| B2: reset ไม่ล้าง output | แทน `sum <= (others => '0'); cout <= '0';` ด้วย `null;` | `a1_reset` แจ้ง 3 ครั้ง (15, 25, 35 ns) แต่ scoreboard ยังสรุป `PASS=208 FAIL=0` |

ผลของ B2 คือเหตุผลของ assertion-based verification: scoreboard ตรวจเฉพาะตอนที่ output valid จึงมองไม่เห็น bug ช่วง reset ส่วน `a1_reset` เฝ้าดูพฤติกรรมเฉพาะจุดนั้นตลอดเวลา

> 💡 **เคล็ดลับ:** ใน Questa ดับเบิลคลิก assertion ที่ fail ในหน้าต่าง Assertions จะกระโดดไปเวลาที่ fail ใน Wave (ต้องเปิด `-assertdebug`)

> ✅ **จุดตรวจสอบ:** RTL ได้ `PASS=208 FAIL=0 X=0`, assertion ผ่านครบ, cover ครบ และทำ B1/B2 แล้วเห็น assertion ที่คาดไว้แจ้ง

## Part 4: เตรียม Netlist และ SDF (15 นาที)

**เป้าหมาย:** มี gate-level netlist, SDF และ Verilog model ของ cell ที่ตรงกัน สำหรับ GLS

### 4.1 GLS ต้องใช้อะไรบ้าง

| ส่วนประกอบ | หน้าที่ | มาจาก |
| --- | --- | --- |
| Netlist (`.v`) | วงจรที่ประกอบด้วย cell จริง | เครื่องมือ P&R หรือ synthesis |
| Cell model (`.v`) | พฤติกรรมของแต่ละ cell + `specify` block (timing check) | PDK หรือผู้ผลิต FPGA |
| SDF (`.sdf`) | delay จริงของทุก cell และสาย ค่า setup/hold | STA หลัง P&R |

ทั้งสามส่วนต้องมาจาก flow เดียวกัน ถ้าชื่อ instance หรือชื่อ cell ไม่ตรง SDF จะ annotate ไม่ได้

### 4.2 เส้นทาง A (หลัก): จาก LibreLane ใน Lab 3B

1. หา run ล่าสุด (WSL)

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3_yosys/librelane"
RUN=$(ls -dt runs/RUN_* | head -1)
```

2. หา netlist และ SDF (ชื่อโฟลเดอร์ corner ต่างกันตามเวอร์ชัน ใช้ `find` ดู)

```bash
find $RUN/final -name '*.nl.v'
find $RUN/final -name '*.sdf'
```

3. คัดลอก netlist และ SDF ทุก corner ไปที่ `lab4_work/gate/`

```bash
G="/mnt/e/lab/VHDL(BOI)/lab4_work/gate"
cp $(find $RUN/final -name '*.nl.v' | head -1) "$G/adder8_pipe.nl.v"
for f in $(find $RUN/final -name '*.sdf'); do cp "$f" "$G/"; done
ls "$G"
```

4. คัดลอก Verilog model ของ cell จาก PDK

```bash
V=$(dirname $(find ~/.ciel -path '*sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v' | head -1))
cp "$V/primitives.v" "$V/sky130_fd_sc_hd.v" "$G/"
```

5. เปิด `adder8_pipe.nl.v` และ SDF อย่างละไฟล์ แล้วตรวจว่า (ก) module ชื่อ `adder8_pipe` มี port ตรงกับ Part 1 (ข) ชื่อ instance ใน `(INSTANCE ...)` ของ SDF ตรงกับ netlist (ค) บรรทัด `(TIMESCALE ...)` ใน SDF

> 📝 **หมายเหตุ:** netlist หลัง P&R มี buffer, clock tree และ fill/tap cell ด้วย (ดู Lab 3B Part 9) จึงใหญ่กว่า netlist จาก Yosys มาก

### 4.3 เส้นทาง B: FPGA (Precision + เครื่องมือผู้ผลิต)

Precision RTL เป็น FPGA synthesis (Lab 3A) delay ที่ใช้ GLS ได้จริงมาหลัง place & route ด้วยเครื่องมือของผู้ผลิต เช่น Vivado (`write_verilog -mode timesim` และ `write_sdf`) หรือ Quartus (EDA Netlist Writer) พร้อม simulation library ของผู้ผลิต ขั้นตอนที่เหลือใน Part 5 เหมือนกัน เปลี่ยนแค่ไฟล์และ library ให้ตรงตามเอกสารของผู้ผลิต

> ⚠️ **คำเตือน:** สคริปต์ `synth.tcl` ในคู่มือต้นฉบับ (`new_project -technology gscl45nm`, `export_netlist`, `write_sdf`) ใช้ library สมมติและคำสั่งที่ไม่ได้ทดสอบกับ Precision จริง ตัวอย่าง netlist (`ADDX1`) และ SDF ในต้นฉบับก็เป็นตัวอย่างสมมติ อย่าใช้เทียบผล

> ✅ **จุดตรวจสอบ:** ใน `gate/` มี `adder8_pipe.nl.v`, SDF อย่างน้อย 1 ไฟล์, `primitives.v` และ `sky130_fd_sc_hd.v`

## Part 5: Gate-Level Simulation พร้อม SDF ใน Questa (20 นาที)

**เป้าหมาย:** testbench เดิมผ่านกับ netlist ที่ใส่ delay จาก SDF แล้ว (`PASS=208 FAIL=0 X=0`) และไม่มี timing violation

### 5.1 สคริปต์

1. ตั้งชื่อ SDF ที่จะใช้ (เลือกไฟล์ corner typical เช่นที่มี `tt_025C_1v80` ในชื่อ)
2. สร้าง `run_gls.do`

```tcl
# run_gls.do - gate-level simulation with SDF (vsim -c -do run_gls.do)
onerror {quit -f -code 1}
onbreak {resume}

# >>> แก้ให้ตรงชื่อไฟล์จริงใน gate/ <<<
set SDF gate/adder8_pipe__nom_tt_025C_1v80.sdf

# 1) cell library (compile ครั้งเดียว)
vlib sky130
vlog -work sky130 gate/primitives.v gate/sky130_fd_sc_hd.v

# 2) netlist + testbench
vlib work_gls
vlog -work work_gls gate/adder8_pipe.nl.v
vcom -2008 -work work_gls tb/tb_adder8_pipe.vhd

# 3) simulate with SDF on the DUT instance
vsim -t ps -L sky130 -sdftyp /tb_adder8_pipe/dut=$SDF +sdf_verbose \
     -voptargs=+acc -assertdebug work_gls.tb_adder8_pipe
run -all
quit -f
```

3. รัน

```powershell
vsim -c -do run_gls.do | Tee-Object reports/gls_typ.log
```

### 5.2 ตรวจผล

| รายการ | หาใน log | ค่าที่ต้องได้ |
| --- | --- | --- |
| SDF ถูกโหลด | บรรทัด SDF ที่ `+sdf_verbose` พิมพ์ (จำนวนค่าที่ annotate) | ไม่มี error และไม่มี warning เรื่อง instance หาไม่เจอ |
| ผลการตรวจ | `PASS=` | `PASS=208 FAIL=0 X=0` (เท่ากับ RTL) |
| Assertion | `A1:` ถึง `A4:` | ไม่มี |
| Timing check | `$setup`, `$hold`, `$setuphold`, `$width` | ไม่มี |

4. เปิดแบบ GUI แล้ว zoom ที่ขอบขาขึ้นหนึ่งของ `clk` วัดด้วย cursor 2 ตัวว่า `sum` เปลี่ยนหลังขอบกี่ ps (ใน RTL จะเปลี่ยนทันที) บันทึก: clock-to-output = \_\_\_\_\_\_ ps

### 5.3 ความต่างที่ควรเห็นระหว่าง RTL กับ GLS

- ก่อน reset ครั้งแรก output ของ netlist เป็น `x` เพราะ flip-flop จริงไม่มีค่าเริ่มต้น (ใน RTL เป็น `U`) หลัง reset ต้องหายหมด นี่คือเหตุผลที่ `a3_no_x` ตรวจเฉพาะตอน `v_q2 = '1'`
- output เปลี่ยนหลังขอบขาขึ้นตาม delay ใน SDF บางบิตอาจเปลี่ยนไม่พร้อมกัน (skew) แต่นิ่งก่อนขอบขาลงที่ testbench ตรวจ

> ✅ **จุดตรวจสอบ:** GLS ได้ `PASS=208 FAIL=0 X=0`, SDF โหลดสำเร็จโดยไม่มี warning เรื่อง instance และไม่มี timing violation เก็บภาพ waveform ที่เห็น delay ไว้ส่ง

## Part 6: Multi-corner และ Timing Violation (25 นาที)

**เป้าหมาย:** รัน GLS ทุก corner ที่ LibreLane สร้าง SDF ให้ และทำให้เกิด timing violation โดยตั้งใจ เพื่อเห็นสิ่งที่ RTL simulation มองไม่เห็น

### 6.1 SDF กับ corner

- ไฟล์ SDF แต่ละไฟล์มาจาก corner หนึ่ง (เช่น `ss` = ช้า อุณหภูมิสูง แรงดันต่ำ, `ff` = เร็ว, `tt` = ปกติ)
- ค่า delay ใน SDF เขียนเป็น `(min:typ:max)` เลือกด้วย `-sdfmin`, `-sdftyp` หรือ `-sdfmax` ของ vsim
- ตรวจ setup ให้ใช้ corner ช้า + `-sdfmax` ตรวจ hold ให้ใช้ corner เร็ว + `-sdfmin`

### 6.2 รันทุก corner

1. สร้าง `run_multicorner.do` (ใช้หลัง compile ใน `run_gls.do` แล้ว)

```tcl
# run_multicorner.do - one simulation per SDF file
onbreak {resume}
foreach sdf [lsort [glob gate/*.sdf]] {
    foreach mode {sdfmin sdfmax} {
        echo "===== $sdf ($mode) ====="
        vsim -t ps -L sky130 -$mode /tb_adder8_pipe/dut=$sdf \
             work_gls.tb_adder8_pipe
        run -all
        quit -sim          ;# ปิดเฉพาะ simulation แล้ววน corner ถัดไป
    }
}
quit -f
```

2. รันและเก็บ log

```powershell
vsim -c -do run_multicorner.do | Tee-Object reports/gls_multicorner.log
```

3. กรอกตาราง

| SDF / mode | PASS | FAIL | X | timing check warning |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |

> ⚠️ **คำเตือน:** สคริปต์ในคู่มือต้นฉบับใส่ `quit -f` ไว้ใน `foreach` ทำให้ Questa ปิดตั้งแต่ corner แรก และใช้ netlist เดิมกับ SDF คนละชื่อโดยไม่ได้สร้าง SDF ต่าง corner จริง

### 6.3 ทำให้เกิด timing violation โดยตั้งใจ

Lab 3B พบ critical path ประมาณ 4.4 ns (setup slack 5.587 ns ที่ clock 10 ns) ถ้าเร่ง clock ใน testbench เป็น 4 ns วงจรจะทำงานไม่ทัน

1. รัน RTL ที่ 4 ns

```tcl
vsim -gCLK_PERIOD=4ns work_rtl.tb_adder8_pipe
run -all
```

ผลที่ได้จากการรันจริง: `PASS=208 FAIL=0 X=0` เพราะ RTL ไม่มี delay

2. รัน GLS ที่ 4 ns ด้วย SDF corner ช้าและ `-sdfmax`

```tcl
vsim -t ps -L sky130 -sdfmax /tb_adder8_pipe/dut=<SDF corner ss> -gCLK_PERIOD=4ns work_gls.tb_adder8_pipe
run -all
```

3. คาดว่าจะเห็นอย่างใดอย่างหนึ่ง: warning จาก timing check (`$setuphold`) ของ flip-flop, `FAIL` จาก scoreboard, `A2:` หรือ `A3:` จาก assertion บันทึกผลที่ได้จริง: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
4. หา clock period ต่ำสุดที่ GLS ยังผ่าน (ลอง 5, 6, 7 ns) แล้วเทียบกับ Fmax ที่คำนวณใน Lab 3B Part 9.4: \_\_\_\_\_\_ ns

### 6.4 ตามหาต้นตอของ violation และ X

1. อ่าน warning ของ timing check: บอกเวลา, ชื่อ instance ของ flip-flop และชนิด check
2. เปิด Wave ที่เวลานั้น เพิ่มขา `D`, `CLK`, `Q` ของ flip-flop ตัวนั้น
3. ดูว่า `D` เปลี่ยนใกล้ขอบ `CLK` เกินไปหรือไม่ และ `Q` เป็น `x` หลังจากนั้นหรือไม่
4. ตาม `x` ย้อนกลับไปหา flip-flop ตัวแรกที่เป็น `x` (Questa: คลิกขวา signal → Dataflow/Trace)

| ต้นตอของ X ที่พบบ่อย | วิธีแก้ |
| --- | --- |
| flip-flop ไม่มี reset หรือยังไม่ reset | ใส่ reset หรือตรวจเฉพาะหลัง reset (`v_q2`) |
| setup/hold violation | เพิ่ม clock period, ใส่ pipeline, แก้ constraint แล้ว P&R ใหม่ |
| async reset ปล่อยใกล้ขอบ clock | ใช้ reset synchronizer (ตรวจ recovery/removal) |
| มีหลาย driver บนสายเดียว | ให้มี driver เดียว |
| input จาก testbench เปลี่ยนที่ขอบขาขึ้น | เปลี่ยน input ที่ขอบขาลง (Part 2.1) |

> ✅ **จุดตรวจสอบ:** ตาราง 6.2 ครบทุก corner, มี log ที่ RTL ผ่านแต่ GLS ไม่ผ่านที่ 4 ns และอธิบายได้ว่า flip-flop ตัวไหนเกิด violation ก่อน

## Part 7: Coverage และรายงาน GLS (15 นาที)

**เป้าหมาย:** มี code coverage ของ RTL, ผล cover directive และรายงานสรุปที่ตรงกับสิ่งที่ทดสอบจริง

### 7.1 Code coverage (ทำกับ RTL)

```tcl
vlib work_cov
vcom -2008 +cover=bcst -work work_cov rtl/adder8_pipe.vhd
vcom -2008 -work work_cov tb/tb_adder8_pipe.vhd
vsim -coverage work_cov.tb_adder8_pipe
coverage save -onexit reports/rtl_cov.ucdb
run -all
quit -sim
vcover report -details reports/rtl_cov.ucdb > reports/rtl_cov.txt
```

- `+cover=bcst` = branch, condition, statement, toggle coverage ใส่เฉพาะไฟล์ DUT
- ดู cover directive (`c1_carry`, `c2_allone`) ได้ในหน้าต่าง Cover Directives หรือในรายงานของ `vcover`
- code coverage ของ netlist ไม่ค่อยมีความหมาย เพราะเป็น cell ของ PDK ไม่ใช่โค้ดที่เราเขียน

> 📝 **หมายเหตุ:** คู่มือต้นฉบับใช้ `coverage save` โดยไม่ได้ compile ด้วย `+cover` และไม่ได้ใส่ `-coverage` ใน vsim จะได้ไฟล์ที่ไม่มี code coverage และตัวเลข "Functional 100%, Code 95%+" ในต้นฉบับไม่ได้มาจากการรันจริง ให้ใส่ตัวเลขจากรายงานของคุณเอง

### 7.2 เขียน `reports/report_gls.md`

ใช้แม่แบบนี้ และกรอกเฉพาะสิ่งที่มีหลักฐานใน log

```markdown
# GLS Report - adder8_pipe

## Setup
- Netlist / SDF source: LibreLane run <RUN_...>, PDK sky130A
- Simulator: Questa <version>

## RTL
- PASS / FAIL / X: ___ / ___ / ___
- Assertions: ___ pass, ___ fail; covers: ___ / 2
- Code coverage (statement / branch / toggle): ___ / ___ / ___ %

## GLS (10 ns)
| SDF corner | mode | PASS | FAIL | X | timing warnings |
|---|---|---|---|---|---|

## Timing violation experiment (4 ns)
- RTL result: ___
- GLS result: ___ (first violation at ___ ns, instance ___)
- Minimum passing period in GLS: ___ ns (Lab 3B STA: ~4.4 ns)

## Conclusion
- GLS agrees with RTL at 10 ns: yes / no
- Remaining sign-off checks not covered by this lab: STA all corners, DRC/LVS, formal equivalence
```

> ✅ **จุดตรวจสอบ:** มี `reports/rtl_cov.txt` และ `reports/report_gls.md` ที่ทุกตัวเลขมาจาก log จริง

## Troubleshooting

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| PSL compile ไม่ผ่าน | เขียน PSL นอก architecture หรือไม่ได้ compile แบบ VHDL-2008 | ใส่ `default clock` และ `assert` ในส่วน statement ของ architecture และใช้ `vcom -2008` |
| GHDL แจ้ง error ที่บรรทัด comment | ใช้ `-fpsl` และ comment ขึ้นต้นด้วย `-- PSL` (ถูกตีความเป็นโค้ด PSL) | ไม่ต้องใช้ `-fpsl` กับ PSL แบบ VHDL-2008 หรือเปลี่ยนคำใน comment |
| `** Error: ... SDF ...` หรือโหลด SDF ไม่ได้ | path ของไฟล์ผิด หรือชื่อ instance ใน `-sdftyp` ไม่ตรง | ตรวจว่าใช้ `/tb_adder8_pipe/dut` ตรงกับ label ใน testbench |
| warning ว่าหา instance ใน SDF ไม่เจอ | SDF กับ netlist มาจากคนละ run | คัดลอกทั้งคู่จาก `$RUN/final` เดียวกัน |
| `Unknown module sky130_fd_sc_hd__...` / `Instantiation of ... failed` | ไม่ได้ compile cell library หรือไม่ได้ใส่ `-L sky130` | compile `primitives.v` + `sky130_fd_sc_hd.v` แล้วใส่ `-L sky130` |
| vlog แจ้ง macro ที่ไม่ได้กำหนด (เช่น `UNIT_DELAY`) ตอน compile model | ไฟล์ model ของ PDK ใช้ macro | เพิ่ม `+define+UNIT_DELAY=#0` หรือดู README ของ PDK อย่าใส่ `+define+FUNCTIONAL` เพราะจะตัด timing check ออก |
| component ผูกกับ module ไม่ได้ | ชื่อหรือชนิด port ไม่ตรง | port ต้องเป็น `std_logic` / `std_logic_vector` และชื่อเหมือน netlist |
| GLS มี `X` ตลอด | ไม่ได้กด reset หรือมี timing violation | ดู Part 6.4 |
| GLS FAIL แต่ RTL ผ่าน ที่ 10 ns | testbench ตรวจหรือเปลี่ยน input ใกล้ขอบขาขึ้นเกินไป | ใช้ testbench ใน Part 2 ที่ทำงานที่ขอบขาลง |
| simulation ช้า | เก็บ waveform ทุก signal ของ netlist | ตัด `-voptargs=+acc` ตอนรัน batch และลด `N_RANDOM` (`-gN_RANDOM=50`) คู่มือต้นฉบับแนะนำ `-novopt` ซึ่ง Questa รุ่นใหม่ไม่รองรับแล้ว |

## Bonus Challenges

### Challenge 1: Reset ต้องค้างอย่างน้อย 3 clock

1. เพิ่ม assertion นี้ใน testbench (ผ่าน GHDL แล้ว)

```vhdl
a5_rst_len : assert always ({rst = '0'; rst = '1'} |=> {rst = '1'[*2]})
    report "A5: reset shorter than 3 cycles";
```

2. เพิ่ม reset กลาง simulation 1 ครั้ง ค้าง 3 clock แล้วต้องผ่าน จากนั้นลดเหลือ 1 clock แล้วต้องเห็น `A5:`
3. อธิบายว่าทำไม assertion นี้ไม่ทำงานกับ reset ตอนเริ่ม simulation (ไม่มีช่วง `rst = '0'` ก่อนหน้า)

### Challenge 2: Functional coverage ของ operand

เพิ่ม process ใน testbench ที่บันทึกว่าค่า `a` แต่ละค่า (0–255) ถูกป้อนแล้วหรือยัง แล้วรายงานเปอร์เซ็นต์ตอนจบ ลองเพิ่ม `N_RANDOM` จนได้ 100%

```vhdl
p_cov : process (clk)
    variable seen : bit_vector(0 to 255) := (others => '0');
begin
    if rising_edge(clk) and rst = '0' then
        seen(to_integer(unsigned(a))) := '1';
    end if;
end process;
```

### Challenge 3: เทียบ GLS ก่อนและหลัง P&R

ใช้ netlist จาก Yosys (Lab 3B Part 7) ซึ่งไม่มี SDF รัน testbench เดิม (zero-delay GLS) แล้วอธิบายว่าตรวจอะไรได้และอะไรไม่ได้เทียบกับ GLS ที่มี SDF

### Challenge 4: Formal equivalence แทน GLS แบบ zero-delay

ใช้สคริปต์ `equiv_*.ys` จาก Lab 3B Part 5 พิสูจน์ว่า netlist เท่ากับ RTL ทุก input แล้วอธิบายว่าทำไมยังต้องทำ GLS พร้อม SDF อยู่ (formal ไม่ดู timing)

## คำถามท้ายแลป

1. ทำไม B2 (reset ไม่ล้าง output) ผ่าน scoreboard แต่ไม่ผ่าน `a1_reset`
2. ทำไมต้องตรวจ output ที่ขอบขาลงใน GLS ถ้าตรวจที่ขอบขาขึ้น + 100 ps จะเกิดอะไร
3. RTL ผ่านที่ clock 4 ns แต่ GLS ไม่ผ่าน แปลว่า RTL simulation พิสูจน์อะไรและไม่พิสูจน์อะไร
4. ทำไมตรวจ setup ด้วย corner ช้า + `-sdfmax` แต่ตรวจ hold ด้วย corner เร็ว + `-sdfmin`
5. GLS ผ่านทุก corner เพียงพอสำหรับ tape-out หรือไม่ ต้องมีอะไรเพิ่ม

## Checklist ก่อนส่งงาน

- [ ] RTL + testbench compile ผ่านแบบ VHDL-2008
- [ ] RTL sim: `PASS=208 FAIL=0 X=0`, assertion ผ่าน 4/4, cover 2/2
- [ ] ทดสอบ bug B1 และ B2 แล้ว assertion แจ้งตามตาราง 3.3
- [ ] มี netlist, SDF และ cell model จาก LibreLane run เดียวกัน
- [ ] GLS ที่ 10 ns ผ่าน และ SDF โหลดโดยไม่มี warning เรื่อง instance
- [ ] วัด clock-to-output จาก waveform แล้ว
- [ ] รันครบทุก corner (`sdfmin` และ `sdfmax`) และกรอกตาราง 6.2
- [ ] ทดลอง clock 4 ns: RTL ผ่าน, GLS ไม่ผ่าน และหา flip-flop ต้นตอเจอ
- [ ] มี `reports/rtl_cov.txt` และ `reports/report_gls.md`
- [ ] ตอบคำถามท้ายแลปครบ 5 ข้อ

ต่อไป: Day 5 Mini Project (UART TX) ที่รวม RTL → testbench → synthesis → SDF → GLS → รายงาน

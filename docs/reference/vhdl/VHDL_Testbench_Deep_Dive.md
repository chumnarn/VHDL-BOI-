# VHDL Testbench — รายละเอียดเชิงลึก

เนื้อหาส่วนนี้สำหรับคู่มือการออกแบบและตรวจสอบ VHDL ครอบคลุมตั้งแต่โครงสร้างพื้นฐานจนถึงเทคนิคขั้นสูงสำหรับ Self-Checking Testbench

---

## 1. วัตถุประสงค์ของ Testbench

Testbench คือสภาพแวดล้อมจำลอง (simulation environment) ที่ใช้สำหรับ:

- ส่งสัญญาณกระตุ้น (stimulus) เข้าไปยัง DUT (Design Under Test)
- สังเกตและตรวจสอบผลลัพธ์ (response)
- ยืนยันว่า DUT ทำงานถูกต้องตามสเปก
- ตรวจจับ corner case และ error condition

**หลักการสำคัญ:**  
Testbench ที่ดีไม่ใช่แค่ “รันได้” แต่ต้อง **ตรวจสอบตัวเองได้** (self-checking) และให้ผลที่เชื่อถือได้

---

## 2. โครงสร้างพื้นฐานของ Testbench

### 2.1 องค์ประกอบหลัก

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity tb_my_module is
end entity tb_my_module;

architecture sim of tb_my_module is
    -- 1. Constant และ Generic
    constant C_CLK_PERIOD : time := 10 ns;
    constant C_DATA_WIDTH : positive := 8;

    -- 2. สัญญาณเชื่อมต่อกับ DUT
    signal clk     : std_logic := '0';
    signal rst     : std_logic := '1';
    signal i_data  : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal i_valid : std_logic;
    signal o_data  : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal o_valid : std_logic;

    -- 3. สัญญาณควบคุมภายใน Testbench
    signal sim_done : boolean := false;

begin
    -- 4. Clock Generation
    clk <= not clk after C_CLK_PERIOD/2 when not sim_done else '0';

    -- 5. DUT Instantiation
    DUT : entity work.my_module
        generic map (
            G_DATA_WIDTH => C_DATA_WIDTH
        )
        port map (
            clk     => clk,
            rst     => rst,
            i_data  => i_data,
            i_valid => i_valid,
            o_data  => o_data,
            o_valid => o_valid
        );

    -- 6. Stimulus และ Checker Process
    P_STIM : process
    begin
        -- Reset sequence
        rst <= '1';
        wait for 5 * C_CLK_PERIOD;
        rst <= '0';
        wait until rising_edge(clk);

        -- Test cases...
        
        sim_done <= true;
        wait;
    end process;
end architecture sim;
```

### 2.2 หลักการจัดโครงสร้าง

| ส่วน | หน้าที่ | คำแนะนำ |
|------|---------|---------|
| Constants | กำหนดพารามิเตอร์ | ใช้ `constant` แทน magic number |
| Signals | เชื่อมต่อ DUT | ตั้งชื่อให้สอดคล้องกับ DUT |
| Clock process | สร้าง clock | ใช้ conditional เพื่อหยุดได้ |
| DUT instance | ตัวออกแบบ | ใช้ `entity work.xxx` |
| Stimulus process | ส่งข้อมูลทดสอบ | แยกจาก checker ถ้าซับซ้อน |
| Checker process | ตรวจสอบผล | ใช้ assertion หรือ report |

---

## 3. การสร้าง Clock และ Reset

### 3.1 Clock Generation ที่ถูกต้อง

**วิธีที่แนะนำ (หยุดได้เมื่อจบ simulation):**

```vhdl
clk <= not clk after C_CLK_PERIOD/2 when not sim_done else '0';
```

**วิธีแบบ Process (ยืดหยุ่นกว่า):**

```vhdl
P_CLK : process
begin
    while not sim_done loop
        clk <= '0';
        wait for C_CLK_PERIOD/2;
        clk <= '1';
        wait for C_CLK_PERIOD/2;
    end loop;
    wait;
end process;
```

### 3.2 Reset Sequence มาตรฐาน

```vhdl
-- Active-high synchronous reset
rst <= '1';
wait for 10 * C_CLK_PERIOD;   -- ถือ reset นานพอ
wait until rising_edge(clk);
rst <= '0';
wait until rising_edge(clk);  -- รอให้ reset ปล่อยอย่างสมบูรณ์
```

**ข้อควรระวัง:**
- Reset ต้องปล่อยหลัง clock edge อย่างน้อย 1 cycle
- สำหรับ asynchronous reset ต้องระวัง timing ของการปล่อย reset

---

## 4. การสร้าง Stimulus

### 4.1 Stimulus แบบง่าย (Hard-coded)

```vhdl
P_STIM : process
begin
    -- รอ reset เสร็จ
    wait until rst = '0';
    wait until rising_edge(clk);

    -- Test case 1
    i_data  <= x"A5";
    i_valid <= '1';
    wait until rising_edge(clk);
    i_valid <= '0';

    -- Test case 2
    i_data  <= x"3C";
    i_valid <= '1';
    wait until rising_edge(clk);
    i_valid <= '0';

    wait for 100 ns;
    sim_done <= true;
    wait;
end process;
```

### 4.2 ใช้ Procedure เพื่อลดความซ้ำซ้อน

```vhdl
procedure send_data(
    signal data  : out std_logic_vector;
    signal valid : out std_logic;
    constant val : in  std_logic_vector
) is
begin
    data  <= val;
    valid <= '1';
    wait until rising_edge(clk);
    valid <= '0';
end procedure;

-- ใช้งาน
send_data(i_data, i_valid, x"A5");
send_data(i_data, i_valid, x"3C");
```

### 4.3 Stimulus จากไฟล์ (File I/O)

```vhdl
P_FILE_STIM : process
    file stim_file : text open read_mode is "stimulus.txt";
    variable line_in : line;
    variable data_val : std_logic_vector(7 downto 0);
begin
    wait until rst = '0';
    
    while not endfile(stim_file) loop
        readline(stim_file, line_in);
        read(line_in, data_val);
        
        i_data  <= data_val;
        i_valid <= '1';
        wait until rising_edge(clk);
        i_valid <= '0';
        wait until rising_edge(clk);
    end loop;
    
    file_close(stim_file);
    sim_done <= true;
    wait;
end process;
```

---

## 5. การตรวจสอบผลลัพธ์ (Checking)

### 5.1 ใช้ Assertion

```vhdl
-- ตรวจสอบทันที
assert o_data = expected_data
    report "Data mismatch! Expected: " & to_hstring(expected_data) &
           " Got: " & to_hstring(o_data)
    severity error;

-- ตรวจสอบเงื่อนไข
assert o_valid = '1'
    report "Valid should be asserted"
    severity warning;
```

### 5.2 Self-Checking ด้วย Process

```vhdl
P_CHECKER : process
    variable error_count : integer := 0;
begin
    wait until rising_edge(clk);
    
    if o_valid = '1' then
        if o_data /= expected then
            report "ERROR: Mismatch at time " & time'image(now)
                severity error;
            error_count := error_count + 1;
        end if;
    end if;
    
    if sim_done then
        if error_count = 0 then
            report "TEST PASSED" severity note;
        else
            report "TEST FAILED with " & integer'image(error_count) & " errors"
                severity failure;
        end if;
        wait;
    end if;
end process;
```

### 5.3 Scoreboard Pattern (ขั้นสูง)

```vhdl
type t_queue is array (natural range <>) of std_logic_vector(7 downto 0);
signal expected_queue : t_queue(0 to 15);
signal wr_ptr, rd_ptr : integer := 0;

-- เมื่อส่ง stimulus
expected_queue(wr_ptr) <= sent_data;
wr_ptr <= wr_ptr + 1;

-- เมื่อรับ output
if o_valid = '1' then
    assert o_data = expected_queue(rd_ptr)
        report "Scoreboard mismatch" severity error;
    rd_ptr <= rd_ptr + 1;
end if;
```

---

## 6. Timing และ Wait Statement

### 6.1 รูปแบบ Wait ที่ใช้บ่อย

| คำสั่ง | การใช้งาน | ตัวอย่าง |
|--------|-----------|----------|
| `wait for` | รอเวลาแน่นอน | `wait for 100 ns;` |
| `wait until` | รอเงื่อนไข | `wait until rising_edge(clk);` |
| `wait on` | รอ signal เปลี่ยน | `wait on data_ready;` |
| `wait` | รอตลอดไป | `wait;` (จบ process) |

### 6.2 เทคนิค Timing ที่สำคัญ

```vhdl
-- รอจน signal เปลี่ยนค่า
wait until o_valid = '1';

-- รอพร้อม timeout (ป้องกัน hang)
wait until o_valid = '1' for 1 us;
assert o_valid = '1'
    report "Timeout waiting for valid" severity error;

-- รอหลาย clock
for i in 1 to 10 loop
    wait until rising_edge(clk);
end loop;
```

---

## 7. การใช้ Procedure และ Function ใน Testbench

### 7.1 Procedure สำหรับ Stimulus

```vhdl
procedure apply_reset(signal rst : out std_logic) is
begin
    rst <= '1';
    wait for 5 * C_CLK_PERIOD;
    wait until rising_edge(clk);
    rst <= '0';
    wait until rising_edge(clk);
end procedure;
```

### 7.2 Function สำหรับการคำนวณ Expected Value

```vhdl
function calculate_expected(
    a : std_logic_vector;
    b : std_logic_vector
) return std_logic_vector is
begin
    return std_logic_vector(unsigned(a) + unsigned(b));
end function;
```

### 7.3 Package สำหรับ Testbench Utilities

สร้างไฟล์ `tb_pkg.vhd`:

```vhdl
package tb_pkg is
    procedure wait_clocks(signal clk : in std_logic; n : in positive);
    procedure check_equal(
        actual   : in std_logic_vector;
        expected : in std_logic_vector;
        msg      : in string := ""
    );
end package;

package body tb_pkg is
    procedure wait_clocks(signal clk : in std_logic; n : in positive) is
    begin
        for i in 1 to n loop
            wait until rising_edge(clk);
        end loop;
    end procedure;
    
    -- implementation อื่นๆ
end package body;
```

---

## 8. รูปแบบ Testbench ที่แนะนำ

### 8.1 Directed Test (ทดสอบตามกรณีที่กำหนด)

เหมาะสำหรับ:
- ฟังก์ชันพื้นฐาน
- Corner case ที่รู้ชัด
- Regression test

### 8.2 Constrained Random (ขั้นสูง)

```vhdl
-- ใช้ uniform จาก math_real หรือเขียนเอง
variable seed1, seed2 : positive := 1;
variable rand_val : real;

uniform(seed1, seed2, rand_val);
i_data <= std_logic_vector(to_unsigned(
    integer(rand_val * 255.0), 8));
```

### 8.3 File-Based Test

- Stimulus อยู่ในไฟล์ข้อความ
- Expected result อยู่ในไฟล์อีกไฟล์
- เหมาะสำหรับ test case จำนวนมาก

---

## 9. การจัดการ Error และ Logging

### 9.1 ระดับ Severity

| Severity | ความหมาย | การใช้งาน |
|----------|----------|-----------|
| `note` | ข้อมูลทั่วไป | แจ้งสถานะ |
| `warning` | ผิดปกติแต่ไม่ร้ายแรง | ค่าที่ไม่คาดคิด |
| `error` | ข้อผิดพลาด | ผลลัพธ์ไม่ตรง |
| `failure` | ล้มเหลวร้ายแรง | หยุด simulation |

### 9.2 สรุปผลเมื่อจบ

```vhdl
P_SUMMARY : process
begin
    wait until sim_done;
    wait for 1 ns;  -- ให้ process อื่นทำงานเสร็จ
    
    report "========================================";
    report "Simulation completed at " & time'image(now);
    report "Total errors: " & integer'image(error_count);
    if error_count = 0 then
        report "*** TEST PASSED ***" severity note;
    else
        report "*** TEST FAILED ***" severity failure;
    end if;
    report "========================================";
    wait;
end process;
```

---

## 10. Best Practices สำหรับ Testbench

### สิ่งที่ควรทำ

1. **แยก Clock, Reset, Stimulus, Checker** ออกจากกัน
2. **ใช้ constant** สำหรับ period, width, timeout
3. **เขียน Self-checking** เสมอ ไม่พึ่งการดู waveform ด้วยตา
4. **ใส่ timeout** ในทุกการรอ เพื่อป้องกัน simulation hang
5. **ใช้ procedure** สำหรับลำดับที่ซ้ำกัน
6. **บันทึก log** ที่ชัดเจนเมื่อเกิด error (เวลา, ค่าที่คาด, ค่าจริง)
7. **ทดสอบ reset behavior** และ corner case
8. **ใช้ `report`** แทนการดู waveform เป็นหลัก

### สิ่งที่ควรหลีกเลี่ยง

- ใช้ delay แบบ hard-code โดยไม่สัมพันธ์กับ clock
- ไม่มี mechanism หยุด simulation
- Checker ที่ไม่ครอบคลุมทุก output
- Stimulus ที่ไม่สามารถ reproduce ได้
- พึ่งพา initial value ของ signal โดยไม่ reset

---

## 11. ตัวอย่าง Testbench ครบวงจร

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_adder is
end entity;

architecture sim of tb_adder is
    constant C_CLK_PERIOD : time := 10 ns;
    constant C_WIDTH      : positive := 8;

    signal clk    : std_logic := '0';
    signal rst    : std_logic := '1';
    signal a, b   : std_logic_vector(C_WIDTH-1 downto 0);
    signal sum    : std_logic_vector(C_WIDTH-1 downto 0);
    signal sim_done : boolean := false;
    signal error_cnt : integer := 0;

begin
    -- Clock
    clk <= not clk after C_CLK_PERIOD/2 when not sim_done else '0';

    -- DUT
    DUT : entity work.adder
        generic map (G_WIDTH => C_WIDTH)
        port map (clk => clk, rst => rst, a => a, b => b, sum => sum);

    -- Stimulus + Check
    P_TEST : process
        procedure check(aval, bval : std_logic_vector) is
            variable expected : std_logic_vector(C_WIDTH-1 downto 0);
        begin
            a <= aval;
            b <= bval;
            wait until rising_edge(clk);
            wait until rising_edge(clk);  -- pipeline delay
            
            expected := std_logic_vector(unsigned(aval) + unsigned(bval));
            if sum /= expected then
                report "FAIL: " & to_hstring(aval) & " + " & to_hstring(bval) &
                       " = " & to_hstring(sum) & " (expected " & to_hstring(expected) & ")"
                    severity error;
                error_cnt <= error_cnt + 1;
            end if;
        end procedure;
    begin
        -- Reset
        rst <= '1';
        wait for 5 * C_CLK_PERIOD;
        wait until rising_edge(clk);
        rst <= '0';
        wait until rising_edge(clk);

        -- Test cases
        check(x"01", x"02");
        check(x"FF", x"01");
        check(x"7F", x"01");
        check(x"00", x"00");
        check(x"AA", x"55");

        -- สรุป
        wait for 10 * C_CLK_PERIOD;
        if error_cnt = 0 then
            report "*** ALL TESTS PASSED ***" severity note;
        else
            report "*** TESTS FAILED: " & integer'image(error_cnt) & " errors ***"
                severity failure;
        end if;
        
        sim_done <= true;
        wait;
    end process;
end architecture;
```

---

## 12. Checklist สำหรับ Testbench

- [ ] มี clock generation ที่หยุดได้
- [ ] มี reset sequence ที่ถูกต้อง
- [ ] Stimulus ครอบคลุมกรณีปกติและ corner case
- [ ] มีการตรวจสอบผลลัพธ์ (self-checking)
- [ ] มี timeout ป้องกัน hang
- [ ] มีสรุปผล PASSED/FAILED เมื่อจบ
- [ ] ใช้ procedure/function ลดความซ้ำซ้อน
- [ ] ไม่มี magic number
- [ ] สามารถรันซ้ำได้ผลเดิม (reproducible)
- [ ] Log ชัดเจนเมื่อเกิด error

---

## สรุป

Testbench ที่ดีคือเครื่องมือที่ช่วยให้มั่นใจในความถูกต้องของ RTL  
ลงทุนเขียน Testbench ให้ดีตั้งแต่ต้นจะช่วยประหยัดเวลา debug ในระยะยาวอย่างมาก

**หลัก 3 ข้อที่ต้องจำ:**
1. **Self-checking** — อย่าพึ่งตาดู waveform
2. **Reproducible** — รันซ้ำได้ผลเดิม
3. **Complete** — ครอบคลุมทั้งกรณีปกติและผิดปกติ

---

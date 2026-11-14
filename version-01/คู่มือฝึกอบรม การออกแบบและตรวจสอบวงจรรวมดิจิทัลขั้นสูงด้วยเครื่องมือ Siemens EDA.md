# คู่มือฝึกอบรม: การออกแบบและตรวจสอบวงจรรวมดิจิทัลขั้นสูงด้วยเครื่องมือ Siemens EDA

**(Advanced Digital IC Design with Siemens EDA Verification and Simulation Tools)**

---

## ภาพรวมหลักสูตร (Workshop Overview)

หลักสูตร 5 วันนี้มุ่งเน้นการสร้างเสริมทักษะวิศวกรออกแบบวงจรรวมดิจิทัล (Digital IC Design & Verification Engineer) ครอบคลุมวงจรการพัฒนาตั้งแต่ระดับแนวคิด (Specification), การเขียนแบบจำลองฮาร์ดแวร์ด้วยภาษา VHDL, การจำลองการทำงานเชิงฟังก์ชัน (RTL Functional Simulation), การสังเคราะห์วงจรตรรกะ (Logic Synthesis), การวิเคราะห์สัญญาณนาฬิกาเชิงสถิต (Static Timing Analysis: STA) ไปจนถึงการตรวจสอบความถูกต้องขั้นสูง (Advanced Verification) และการจำลองในระดับเกตพร้อมเวลาหน่วงจริง (Gate-Level Simulation with SDF) โดยมุ่งเน้นกระบวนการทำงานแบบ ASIC/FPGA มาตรฐานอุตสาหกรรม

```
+---------------------------------------------------------------------------------------------------+
|                                  Digital IC Frontend-to-Backend Flow                              |
+---------------------------------------------------------------------------------------------------+
|  [Day 1-2] RTL Modeling (VHDL)   -->  Functional Sim (Questa/ModelSim)                            |
|                                                     |                                             |
|  [Day 3]   Constraints (SDC)     -->  Logic Synthesis (Precision RTL) --> Gate-Level Netlist      |
|                                                     |                               |             |
|  [Day 4]   Assertions & Coverage -->  STA & Timing Sign-off           --> Gate-Level Sim (SDF)    |
|                                                     |                                             |
|  [Day 5]   Mini-Project (Integration) -> Full RTL-to-GDSII Flow Perspective                       |
+---------------------------------------------------------------------------------------------------+

```

### โครงสร้างเวลาและการจัดสรรการเรียนรู้ (8 ชั่วโมง/วัน, รวม 40 ชั่วโมง)

* **ภาคทฤษฎี (Lecture - 50%):** ปูรากฐานทางสถาปัตยกรรมฮาร์ดแวร์, การแปลงพฤติกรรมเป็นวงจรเกต, คณิตศาสตร์และทฤษฎี Timing Analysis
* **ภาคปฏิบัติ (Hands-on Lab - 50%):** เน้นการใช้คำสั่งระดับสคริปต์ (TCL Scripting), การวิเคราะห์โครงสร้าง Schematic, การตรวจแก้ Waveform และการประเมิน Timing Slack

---

## ความรู้พื้นฐานที่ต้องมี (Prerequisites)

1. **Digital Logic & Circuit Fundamentals:**
* ตรรกศาสตร์บูลีน (Boolean Algebra), ตรรกะเชิงผสม (Combinational Logic: Multiplexer, Decoder, ALU)
* ตรรกะเชิงลำดับ (Sequential Logic: D Flip-Flop, Latches, Counters, Registers)
* สถานะการทำงานของวงจรและการเปลี่ยนสถานะ (Finite State Machines: FSM)


2. **Computer Architecture Basics:**
* สถาปัตยกรรมบัส, หน่วยความจำ (SRAM/Register File), ปลายป์ไลน์ (Pipelining Concept)


3. **Basic Programming/Scripting Literacy:**
* พื้นฐานไวยากรณ์ภาษา C/C++ หรือ Python
* พื้นฐานการใช้งาน Linux Command Line Interface (CLI) และการเขียนสคริปต์ Bash เบื้องต้น



---

## การเตรียมสภาพแวดล้อม (Environment Setup)

### 1. ความต้องการของระบบ (System Requirements)

* **ระบบปฏิบัติการ:** Red Hat Enterprise Linux (RHEL) 7/8/9, Rocky Linux 8/9 หรือ Ubuntu LTS (64-bit)
* **หน่วยประมวลผล:** x86_64 Multi-core CPU (แนะนำ 4 Cores ขึ้นไป)
* **หน่วยความจำ (RAM):** ขั้นต่ำ 8 GB (แนะนำ 16 GB ขึ้นไปสำหรับจำลอง Gate-Level ขนาดใหญ่)
* **พื้นที่จัดเก็บข้อมูล:** พื้นที่ว่างอย่างน้อย 20 GB (SSD แนะนำ)

### 2. การกำหนดค่าตัวแปรระบบ (Environment Variables & Licensing)

สร้างหรือแก้ไขไฟล์ `~/.bashrc` หรือไฟล์สำหรับโหลดสภาพแวดล้อมเฉพาะ เช่น `setup_eda.sh`:

```bash
#!/bin/bash
# Siemens EDA Licensing
export MGLS_LICENSE_FILE=17171@license-server.local.domain
export LM_LICENSE_FILE=$MGLS_LICENSE_FILE

# Siemens QuestaSim / ModelSim
export QUESTA_HOME=/opt/Siemens_EDA/questasim_2023.2
export PATH=$QUESTA_HOME/bin:$PATH

# Siemens Precision RTL Synthesis
export PRECISION_HOME=/opt/Siemens_EDA/precision_2023.1
export PATH=$PRECISION_HOME/bin:$PATH

# Siemens HDL Designer (Optional/Integrated)
export HDS_HOME=/opt/Siemens_EDA/HDS_2023.1
export PATH=$HDS_HOME/bin:$PATH

```

คำสั่งโหลดและทดสอบสิทธิ์การใช้งาน:

```bash
source setup_eda.sh
vsim -version
precision -version

```

### 3. โครงสร้างโฟลเดอร์โครงงาน (Directory Structure)

เพื่อให้การทำงานเป็นระบบตามมาตรฐานสากล กำหนดโครงสร้างโฟลเดอร์ดังนี้:

```text
project_root/
├── rtl/            # ซอร์สโค้ด VHDL (.vhd)
├── tb/             # Testbench, Verification files, Test vector
├── sim/            # ไดเรกทอรีรัน Simulation, สคริปต์ TCL, Waveform (.do, .wlf)
├── syn/            # ไดเรกทอรีรัน Precision Synthesis, Constraints (.sdc), Script (.tcl)
├── netlist/        # เกตเน็ตลิสต์หลังสังเคราะห์ (.vhd / .v) และ Timing Delay (.sdf)
└── doc/            # เอกสารสเปกและรายงานสรุปผล

```

---

## วันที่ 1: Fundamentals of VHDL and Digital IC Design

### ภาคทฤษฎีเชิงลึก (Theory)

#### 1. วงจรการออกแบบดิจิทัลไอซี (Digital IC Design Flow)

* **System Specification:** กำหนดคุณสมบัติ สถาปัตยกรรม ความถี่เป้าหมาย และงบประมาณพลังงาน
* **Architectural & Behavioral Modeling:** อธิบายการทำงานในระดับขั้นตอนวิธี (Algorithm)
* **Register-Transfer Level (RTL):** ถ่ายทอดการประมวลผลและส่งถ่ายข้อมูลระหว่างรีจิสเตอร์ด้วยภาษา VHDL
* **Functional Verification:** ตรวจสอบความถูกต้องของลอจิกโดยไม่คิดเวลาหน่วงจริง
* **Logic Synthesis:** แปลง RTL เป็นวงจรเกตลอจิก (Gate-Level Netlist) โดยจับคู่เข้ากับเทคโนโลยีเป้าหมาย (Standard Cell Library หรือ FPGA Logic Blocks)
* **Timing & Equivalence Checking:** พิสูจน์ความถูกต้องของฟังก์ชันและเวลาการทำงาน
* **Physical Design (Place & Route):** จัดวางเกตและเดินสายสัญญาณบนผังจริง จนได้ข้อมูลเลย์เอาต์ระดับ GDSII / OASIS

#### 2. การเปรียบเทียบ ASIC และ FPGA

| คุณลักษณะ | FPGA | ASIC (Standard Cell / Full Custom) |
| --- | --- | --- |
| **ความยืดหยุ่นในการปรับแต่ง** | กำหนดค่าใหม่ได้ตลอดเวลา (Re-programmable) | เปลี่ยนแปลงฮาร์ดแวร์ไม่ได้หลัง Tape-out |
| **ต้นทุนเริ่มต้น (NRE Cost)** | ต่ำ (ซื้อชิปสำเร็จรูปมาโปรแกรม) | สูงมาก (ค่า Mask และเครื่องมือ EDA ระดับสูง) |
| **ต้นทุนต่อชิ้น (Unit Cost)** | สูง หากผลิตในปริมาณมาก | ต่ำมาก เมื่อผลิตปริมาณมาก (Mass Production) |
| **ประสิทธิภาพและความเร็ว** | ปานกลาง (จำกัดด้วยสถาปัตยกรรม Routing) | สูงสุด (ออกแบบทรานซิสเตอร์และสายสัญญาณได้เฉพาะเจาะจง) |
| **อัตราการกินพลังงาน** | ปานกลาง - สูง | ต่ำมาก (ปรับแต่ง Power Island และ Cell Sizing ได้) |

#### 3. สถาปัตยกรรม VHDL และการประเมินระหว่าง Simulation กับ Synthesis

* **Entity:** อินเตอร์เฟซอินพุต/เอาต์พุต (`in`, `out`, `inout`, `buffer`)
* **Architecture:** พฤติกรรมและโครงสร้างวงจร
* **Data Types:** `std_logic`, `std_logic_vector` (จากแพ็กเกจ `ieee.std_logic_1164`), `signed`, `unsigned` (จาก `ieee.numeric_std`), หลีกเลี่ยงการใช้ `std_logic_arith`
* **Signals vs. Variables:**
* `Signal (<=)`: เป็นตัวแทนของสายสัญญาณทางกายภาพ มีการประเมินค่าแบบ Delta Delay หรือตามขอบสัญญาณ
* `Variable (:=)`: ใช้งานเฉพาะภายใน `process` หรือ `subprogram` ค่าเปลี่ยนทันทีตามลำดับบรรทัด (Sequential execution)


* **Simulation vs. Synthesis Semantics:** โค้ดบางรูปแบบจำลองการทำงานได้ แต่ไม่สามารถสังเคราะห์เป็นฮาร์ดแวร์ได้ เช่น การใช้ `wait for 10 ns`, `time`, หรือการกำหนดค่าเริ่มต้นในตัวแปรที่ไม่รองรับวงจร Reset

---

### ปฏิบัติการ (Hands-on Lab): โมดูลตรรกะพื้นฐานและการจำลองด้วย QuestaSim

#### โค้ด RTL: มัลติเพล็กเซอร์ 4-to-1 (`rtl/mux4_1.vhd`)

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity mux4_1 is
    port (
        d_in : in  std_logic_vector(3 downto 0);
        sel  : in  std_logic_vector(1 downto 0);
        y    : out std_logic
    );
end entity mux4_1;

architecture rtl of mux4_1 is
begin
    process(d_in, sel)
    begin
        case sel is
            when "00"   => y <= d_in(0);
            when "01"   => y <= d_in(1);
            when "10"   => y <= d_in(2);
            when "11"   => y <= d_in(3);
            when others => y <= '0';
        end case;
    end process;
end architecture rtl;

```

#### โค้ด Testbench: (`tb/tb_mux4_1.vhd`)

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity tb_mux4_1 is
end entity tb_mux4_1;

architecture sim of tb_mux4_1 is
    signal d_in : std_logic_vector(3 downto 0) := "0000";
    signal sel  : std_logic_vector(1 downto 0) := "00";
    signal y    : std_logic;
begin
    dut: entity work.mux4_1(rtl)
        port map (
            d_in => d_in,
            sel  => sel,
            y    => y
        );

    stim_proc: process
    begin
        d_in <= "1010"; sel <= "00"; wait for 20 ns;
        assert (y = '0') report "Mismatch at sel=00" severity error;

        sel <= "01"; wait for 20 ns;
        assert (y = '1') report "Mismatch at sel=01" severity error;

        sel <= "10"; wait for 20 ns;
        assert (y = '0') report "Mismatch at sel=10" severity error;

        sel <= "11"; wait for 20 ns;
        assert (y = '1') report "Mismatch at sel=11" severity error;

        report "--- All tests completed successfully! ---" severity note;
        wait;
    end process;
end architecture sim;

```

#### การใช้คำสั่ง QuestaSim/ModelSim ผ่านสคริปต์ TCL (`sim/run_day1.do`)

```tcl
# สร้างและแมปไดเรกทอรีไลบรารี
vlib work
vmap work work

# คอมไพล์ซอร์สโค้ด
vcom -93 -work work ../rtl/mux4_1.vhd
vcom -93 -work work ../tb/tb_mux4_1.vhd

# เรียกจำลองการทำงาน
vsim -t 1ps -lib work tb_mux4_1

# จัดรูปแบบหน้าต่างสัญญาณ Waveform
add wave -divider "Inputs"
add wave -format literal -radix bin /tb_mux4_1/d_in
add wave -format literal -radix bin /tb_mux4_1/sel
add wave -divider "Output"
add wave -format logic /tb_mux4_1/y

# สั่งรันการจำลองและเปิดหน้าต่าง Waveform
run 100 ns
wave zoom full

```

---

## วันที่ 2: RTL Design Using VHDL, Design Verification

### ภาคทฤษฎีเชิงลึก (Theory)

#### 1. สถาปัตยกรรมระบบ Synchronous

* **Clocking & Resets:**
* **Asynchronous Reset:** ขารีเซตทำงานทันทีโดยไม่ต้องรอขอบสัญญาณนาฬิกา ข้อดีคือรีเซตได้แม้คล็อกไม่มา แต่เสี่ยงต่อความไม่แน่นอนตอนปล่อยรีเซต (Reset Recovery/Removal Violations)
* **Synchronous Reset:** ขารีเซตได้รับการแซมเปิลที่ขอบคล็อก วงจรมีความทนทานต่อสัญญาณรบกวน (Noise Glitches) สูงกว่า


* **Clock Enable:** การควบคุมการอัปเดตสถานะของฟลิปฟล็อปโดยไม่ตัดต่อสายสัญญาณคล็อกโดยตรง (หลีกเลี่ยง Clock Gating ด้วยเกตลอจิกทั่วไปซึ่งก่อให้เกิด Skew และ Glitch)

#### 2. Finite State Machine (FSM): สถาปัตยกรรม Moore vs. Mealy

* **Moore Machine:** เอาต์พุตขึ้นอยู่กับ *สถานะปัจจุบัน (Current State)* เท่านั้น สัญญาณเอาต์พุตมีความเสถียร ไม่เปลี่ยนตามสัญญาณอินพุตระหว่างรอบสัญญาณนาฬิกา
* **Mealy Machine:** เอาต์พุตขึ้นอยู่กับ *ทั้งสถานะปัจจุบันและอินพุตปัจจุบัน* ตอบสนองเร็วกว่า แต่อาจส่งผ่าน Glitch จากอินพุตไปยังเอาต์พุต และลดทอน Timing Budget ของสเตจถัดไป
* **Safe FSM Coding Style:** การเขียนแยกกระบวนการ State Register และ Next-State/Output Logic ชัดเจน พร้อมระบุ `when others` ป้องกัน FSM ตกค้างใน Illegal State

#### 3. หลีกเลี่ยง Unintentional Latches และปัญหา Clock Domain Crossing (CDC)

* **Unintentional Latches:** เกิดขึ้นเมื่อออกแบบวงจร Combinational ด้วย Process แล้วกำหนดเงื่อนไขในคำสั่ง `if` หรือ `case` ไม่ครบถ้วน ซอฟต์แวร์สังเคราะห์จะสร้าง Latch เพื่อจำลองพฤติกรรมเก็บค่าเดิม ซึ่งส่งผลเสียต่อความเร็วและการทำ Static Timing Analysis
* **Clock Domain Crossing (CDC):** การส่งสัญญาณข้ามระหว่างโดเมนสัญญาณนาฬิกาที่ไม่สัมพันธ์กัน (Asynchronous Clocks) ทำให้เกิดสภาวะกึ่งเสถียร (Metastability) แนวทางแก้ไขคือการใช้ Two-Stage Flip-Flop Synchronizer สำหรับสัญญาณบิตเดี่ยว หรือการใช้ Asynchronous FIFO (พร้อม Gray-coded pointer) สำหรับสัญญาณบัส

---

### ปฏิบัติการ (Hands-on Lab): โมเดล FSM ตรวจจับลำดับ "1011" และ Self-Checking Testbench

#### โค้ด RTL: ตัวตรวจจับลำดับแบบ Moore FSM (`rtl/seq_detector_moore.vhd`)

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity seq_detector_moore is
    port (
        clk      : in  std_logic;
        rst_n    : in  std_logic;
        din      : in  std_logic;
        detected : out std_logic
    );
end entity seq_detector_moore;

architecture rtl of seq_detector_moore is
    type state_type is (S_IDLE, S_1, S_10, S_101, S_1011);
    signal current_state, next_state : state_type;
begin
    -- กระบวนการ State Register (Synchronous Clock, Asynchronous Reset)
    reg_proc: process(clk, rst_n)
    begin
        if rst_n = '0' then
            current_state <= S_IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process reg_proc;

    -- กระบวนการ Next-State Combinational Logic
    comb_proc: process(current_state, din)
    begin
        next_state <= current_state;
        case current_state is
            when S_IDLE =>
                if din = '1' then next_state <= S_1; end if;
            when S_1 =>
                if din = '0' then next_state <= S_10; end if;
            when S_10 =>
                if din = '1' then next_state <= S_101;
                else              next_state <= S_IDLE; end if;
            when S_101 =>
                if din = '1' then next_state <= S_1011;
                else              next_state <= S_10;   end if;
            when S_1011 =>
                if din = '1' then next_state <= S_1;
                else              next_state <= S_10;   end if;
            when others =>
                next_state <= S_IDLE;
        end case;
    end process comb_proc;

    -- เอาต์พุตลอจิกแบบ Moore
    detected <= '1' when current_state = S_1011 else '0';

end architecture rtl;

```

#### โค้ด Self-Checking Testbench (`tb/tb_seq_detector.vhd`)

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity tb_seq_detector is
end entity tb_seq_detector;

architecture test of tb_seq_detector is
    signal clk      : std_logic := '0';
    signal rst_n    : std_logic := '0';
    signal din      : std_logic := '0';
    signal detected : std_logic;

    constant CLK_PERIOD : time := 10 ns;
begin
    -- กำเนิดสัญญาณนาฬิกา 100 MHz
    clk_gen: process
    begin
        clk <= '0'; wait for CLK_PERIOD / 2;
        clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    -- ติดตั้ง DUT
    dut: entity work.seq_detector_moore(rtl)
        port map (
            clk      => clk,
            rst_n    => rst_n,
            din      => din,
            detected => detected
        );

    -- ป้อน Stimulus และตรวจสอบผลอัตโนมัติ
    stim_proc: process
        procedure send_bit(constant b : in std_logic) is
        begin
            din <= b;
            wait until rising_edge(clk);
            wait for 1 ns; -- เลื่อนตรวจหลังขอบคล็อก
        end procedure;
    begin
        -- Phase 1: Reset System
        rst_n <= '0';
        wait for 25 ns;
        rst_n <= '1';
        wait until rising_edge(clk);

        -- Phase 2: ส่งข้อมูล "1011"
        send_bit('1');
        send_bit('0');
        send_bit('1');
        send_bit('1');

        -- ตรวจสอบสัญญาณ detected
        assert (detected = '1')
            report "VERIFICATION FAILURE: Sequence '1011' not detected!"
            severity failure;

        -- Phase 3: ส่งข้อมูลเพิ่มเติมเพื่อทดสอบ Overlap Sequence "011" -> "1011"
        send_bit('0');
        send_bit('1');
        send_bit('1');
        assert (detected = '1')
            report "VERIFICATION FAILURE: Overlapping '1011' not detected!"
            severity failure;

        report "SUCCESS: FSM Verification Passed." severity note;
        wait;
    end process;
end architecture test;

```

#### การใช้งาน Siemens HDL Designer ในการออกแบบระดับภาพรวม

* นำเข้าบล็อกไดอะแกรมเชิงภาพ (State Diagram / Block Diagram Entry)
* เชื่อมต่อสายสัญญาณและสร้าง Bus Mapping
* ใช้ฟีเจอร์ Generate VHDL เพื่อแปลงผังวงจรเป็นโค้ด VHDL อัตโนมัติที่มีโครงสร้างเป็นมาตรฐาน

---

## วันที่ 3: Logic Synthesis and Optimization, Static Timing Analysis

### ภาคทฤษฎีเชิงลึก (Theory)

#### 1. กระบวนการ Logic Synthesis จาก RTL สู่ Netlist

Logic Synthesis คือการนำไฟล์คำสั่งเชิงพฤติกรรม (RTL) มาผ่านกระบวนการหลัก 3 ขั้นตอน:

1. **Translation:** วิเคราะห์ไวยากรณ์และแปลงโครงสร้างภาษาเป็น Generic Logic Elements (เช่น แอดเดอร์, ตัวคูณ, ลอจิกบูลีนพื้นฐาน)
2. **Logic Optimization:** ลดรูปสมการบูลีน ขจัดลอจิกที่ไม่ได้ใช้งาน (Dead Logic Elimination) และจัดโครงสร้างใหม่ตามเกณฑ์พื้นที่หรือความเร็ว
3. **Technology Mapping:** แปลงลอจิกทั่วไปเป็นเซลล์มาตรฐาน (Standard Cells) ที่มีอยู่ใน Library ทางกายภาพ เช่น Inverter, NAND, DFF พร้อมระบุ Drive Strength

#### 2. ทฤษฎี Static Timing Analysis (STA): Setup Time และ Hold Time

การส่งสัญญาณระหว่างรีจิสเตอร์คู่หนึ่ง (Launch Flip-Flop ถึง Capture Flip-Flop):

```
       +------------+                         +------------+
       | Launch DFF |      Combinational      | Capture DFF|
clk -->|> Q --------+----->[ Logic Path ]---->| D        <|-- clk
       +------------+           Tdata         +------------+

```

* **Setup Time ($T_{setup}$):** ข้อมูลที่ส่งมาต้องนิ่งเสถียรก่อนที่ขอบสัญญาณนาฬิกาของ Capture Flip-Flop จะมาถึง

$$T_{clk} + T_{skew} \ge T_{cq} + T_{data\_max} + T_{setup}$$


$$\text{Setup Slack} = (T_{clk} + T_{skew} - T_{setup}) - (T_{cq} + T_{data\_max})$$



*(Slack ต้อง $\ge 0$ หากติดลบ วงจรจะไม่สามารถทำงานที่ความถี่เป้าหมายได้)*
* **Hold Time ($T_{hold}$):** ข้อมูลต้องคงสถานะเดิมหลังจากขอบสัญญาณนาฬิกามาถึงเป็นเวลาอย่างน้อย $T_{hold}$ เพื่อป้องกันไม่ให้ข้อมูลใหม่วิ่งผ่านเร็วเกินไปจนเขียนทับข้อมูลเดิม

$$T_{cq} + T_{data\_min} \ge T_{hold} + T_{skew}$$


$$\text{Hold Slack} = (T_{cq} + T_{data\_min}) - (T_{hold} + T_{skew})$$



*(การแก้ไข Hold Violation ต้องทำโดยการแทรก Delay Buffer ในดาต้าพาท ไม่สามารถแก้ได้ด้วยการลดความถี่คล็อก)*

#### 3. เทคนิคการเพิ่มประสิทธิภาพ RTL (Hardware Optimization Techniques)

* **Pipelining:** การแทรก Register คั่นกลาง Combinational Logic Path ที่ยาว ช่วยตัดทอนค่า $T_{data\_max}$ ทำให้ระบบทำงานที่ความถี่สัญญาณนาฬิกา ($F_{max}$) สูงขึ้น
* **Register Retiming:** การย้ายตำแหน่งของ Flip-Flop ข้ามลอจิกเกตโดยไม่เปลี่ยนพฤติกรรมของวงจร เพื่อกระจายค่าหน่วงเวลาให้สมดุล
* **Resource Sharing:** การใช้ฮาร์ดแวร์หน่วยคำนวณที่ใช้ทรัพยากรสูงร่วมกัน (เช่น ตัวคูณหรือตัวหาร) ผ่านการควบคุมด้วย MUX เพื่อประหยัดพื้นที่ชิป

---

### ปฏิบัติการ (Hands-on Lab): การใช้งาน Precision RTL และการกำหนด Constraints

#### การสร้างไฟล์ SDC Constraints (`syn/constraints.sdc`)

```tcl
# กำหนดหน่วยเวลาและความถี่สัญญาณนาฬิกา
set_time_unit -nanoseconds

# สร้าง Clock หลัก ความถี่ 100 MHz (คาบเวลา 10 ns)
create_clock -name sys_clk -period 10.000 [get_ports {clk}]

# กำหนด Clock Skew / Uncertainty
set_clock_uncertainty 0.200 [get_clocks {sys_clk}]

# กำหนด Input Delay (อิงอุปกรณ์ต้นทางภายนอก)
set_input_delay -clock sys_clk -max 2.000 [get_ports {din}]
set_input_delay -clock sys_clk -min 0.500 [get_ports {din}]

# กำหนด Output Delay (อิงอุปกรณ์ปลายทางภายนอก)
set_output_delay -clock sys_clk -max 2.500 [get_ports {detected}]
set_output_delay -clock sys_clk -min 0.500 [get_ports {detected}]

# กำหนดภาระโหลดทางไฟฟ้าที่ขาออก (Capacitance load)
set_load 0.05 [get_ports {detected}]

```

#### สคริปต์สังเคราะห์วงจรบน Precision RTL (`syn/run_synth.tcl`)

```tcl
# โหลดโครงงานและการตั้งค่าอุปกรณ์เป้าหมาย
new_project -name "SequenceDetectorSynth" -folder "./work_synth"
setup_design -manufacturer "Siemens_Generic" -family "Standard_Cell" -part "generic_045nm"

# นำเข้าไฟล์ RTL
add_input_file -format vhdl ../rtl/seq_detector_moore.vhd

# นำเข้าไฟล์ Constraints
read_sdc ../syn/constraints.sdc

# ตั้งค่าการ Optimize (เปิดใช้งาน Retiming และ Resource Sharing)
set_attribute -name PIPELINE -value TRUE
set_attribute -name RETIMING -value TRUE
set_attribute -name RESOURCE_SHARING -value TRUE

# ดำเนินการสังเคราะห์วงจร
compile
synthesize

# สร้างรายงานสรุปผล
report_timing -num_paths 10 -file ../doc/timing_report.rpt
report_area -file ../doc/area_report.rpt

# บันทึก Gate-level Netlist และ SDF
write_output_file -format vhdl ../netlist/seq_detector_netlist.vhd
write_output_file -format sdf  ../netlist/seq_detector.sdf

```

#### การวิเคราะห์และแก้ไข Timing Violations

* **ตรวจ Timing Slack ติดลบ (Negative Setup Slack):**
1. ค้นหา Worst Negative Slack (WNS) และ Critical Data Path
2. หากสาเหตุเกิดจาก Logic Depth ลึก: พิจารณาทำ Pipelining
3. หากเกิดจาก Fan-out สูง: สั่งให้ Precision สังเคราะห์ Buffer เพิ่ม (Fanout Replication)


* **ตรวจ Hold Time Violation:** ตรวจสอบ Clock Tree Skew หรือแทรก Delay Cell ในพาทข้อมูลที่สั้นเกินไป

---

## วันที่ 4: Verification Techniques Using QuestaSim

### ภาคทฤษฎีเชิงลึก (Theory)

#### 1. วิวัฒนาการและกระบวนการ Verification

* **Directed Testing:** การป้อน Stimulus ที่กำหนดไว้ล่วงหน้าทีละกรณี เหมาะสำหรับตรวจฟังก์ชันพื้นฐาน แต่ไม่ครอบคลุม Corner Cases ซับซ้อน
* **Constrained-Random Verification (CRV):** การสุ่มค่าอินพุตภายใต้กรอบข้อจำกัด (Constraints) ทำให้สามารถค้นพบข้อผิดพลาดที่คาดไม่ถึง
* **Coverage-Driven Verification (CDV):** ใช้ตัวชี้วัดความครอบคลุมเพื่อวัดความคืบหน้าและประเมินว่ากระบวนการทดสอบเสร็จสิ้น (Closure) แล้วหรือไม่

#### 2. ฟังก์ชันตรวจสอบใน QuestaSim

* **SystemVerilog Assertions (SVA) / PSL:** ตรวจสอบข้อกำหนดเชิงเวลาและพฤติกรรมของสัญญาณ ณ จุดที่เกิดเหตุการณ์ทันที (Immediate and Concurrent Assertions) โดยไม่ต้องเขียนโค้ดตรวจสอบยาวใน Testbench
* **Functional Coverage:**
* **Covergroup & Coverpoint:** ติดตามว่าตัวแปรหรือสัญญาณเปลี่ยนไปอยู่ในสถานะที่ต้องการครบหรือไม่
* **Cross Coverage:** ติดตามชุดผสมผสานของสถานะสัญญาณต่างคู่


* **Code Coverage:** วัดผลความครอบคลุมในระดับโค้ด (Line, Branch, Condition, Expression, FSM State/Transition)

#### 3. การจำลองในระดับเกต (Gate-Level Simulation: GLS) และ SDF Back-Annotation

* **วัตถุประสงค์ของ GLS:** ตรวจสอบผลกระทบทางกายภาพจริงหลังการสังเคราะห์ เช่น Glitch, Reset Race Conditions และการทำงานตามเวลาจริง
* **Standard Delay Format (SDF):** ไฟล์มาตรฐานที่บันทึกค่าเวลาหน่วงของเกต (Cell Delay) และสายเชื่อมต่อ (Interconnect Delay) ในระดับ Min/Typ/Max
* การจำลองจะทำการ Back-annotate ค่าจากไฟล์ `.sdf` เข้าสู่เน็ตลิสต์ และใช้ QuestaSim ตรวจจับ `$setup` และ `$hold` Timing Violations

---

### ปฏิบัติการ (Hands-on Lab): Advanced Verification และ Gate-Level Simulation บน QuestaSim

#### การประยุกต์ใช้ Concurrent Assertions ในการตรวจสอบโปรโตคอล (`tb/sva_seq_checker.sv`)

```systemverilog
module sva_seq_checker (
    input logic clk,
    input logic rst_n,
    input logic din,
    input logic detected
);

    // ทรัพย์สิน (Property): หากตรวจพบ '1011' สัญญาณ detected ต้องขึ้นสูงในขอบถัดไป
    property p_detect_1011;
        @(posedge clk) disable iff (!rst_n)
        (din ##1 !din ##1 din ##1 din) |=> (detected == 1'b1);
    endproperty

    // บังคับตรวจสอบ Assert
    a_detect_check: assert property (p_detect_1011)
        else $error("SVA ERROR: Pattern 1011 passed, but detected signal was LOW!");

    // ดักจับ Cover เพื่อยืนยันว่าเกิดเหตุการณ์นี้ขึ้นจริงในการทดสอบ
    c_detect_hit: cover property (p_detect_1011);

endmodule

```

#### สคริปต์รัน Code Coverage และ Functional Coverage บน QuestaSim (`sim/run_coverage.do`)

```tcl
# สร้างไลบรารี
vlib work
vmap work work

# คอมไพล์พร้อมเปิดแฟล็กดักจับ Coverage ทุกประเภท (+cover=bcestf)
vcom -93 -cover bcestf ../rtl/seq_detector_moore.vhd
vlog -sv ../tb/sva_seq_checker.sv
vcom -93 ../tb/tb_seq_detector.vhd

# จำลองการทำงานและเปิดโหมดบันทึก Coverage
vsim -coverage -voptargs="+cover=bcestf" -assertdebug work.tb_seq_detector

# ดำเนินการรัน
run -all

# บันทึกฐานข้อมูล Coverage (.ucdb)
coverage save -onexit my_coverage.ucdb

# สร้างรายงานสรุปผลเชิงตัวเลขและเว็บเพจ HTML
vcover report -html -output cov_html_report my_coverage.ucdb
vcover report -summary my_coverage.ucdb

```

#### การทำ Gate-Level Simulation (GLS) พร้อมระบุไฟล์ SDF (`sim/run_gls.do`)

```tcl
# เตรียมไลบรารีเซลล์มาตรฐาน
vlib work
vmap work work

# คอมไพล์ Gate-Level Netlist ที่ได้จาก Precision
vcom -93 -work work ../netlist/seq_detector_netlist.vhd
vcom -93 -work work ../tb/tb_seq_detector.vhd

# รัน Simulation พร้อมโหลดไฟล์ SDF เพื่อแทรกเวลาหน่วงจริง
vsim -t 1ps -sdftyp /tb_seq_detector/dut=../netlist/seq_detector.sdf \
     +nowarnTFMPC -lib work tb_seq_detector

# ตรวจจับข้อผิดพลาด Timing Check ($setup/$hold)
onbreak {resume}
run 200 ns

```

---

## วันที่ 5: Mini Project – Digital IC Design and Verification (RTL-to-GDSII Perspective)

### ภาคทฤษฎีเชิงลึก (Theory)

#### 1. วงจรการออกแบบระดับชิปสมบูรณ์ (ASIC Flow: RTL-to-GDSII)

```
+--------------+       +---------------+       +------------------+
| Spec & Arch  | ----> |  VHDL Coding  | ----> | Functional Sim   |
+--------------+       +---------------+       +------------------+
                                                        |
+--------------+       +---------------+       +------------------+
|  Placement   | <---- | Gate Netlist  | <---- | Synthesis & STA  |
+--------------+       +---------------+       +------------------+
       |
+--------------+       +---------------+       +------------------+
| Clock Tree   | ----> |    Routing    | ----> | DRC/LVS & Tapeout|
|  Synthesis   |       |               |       |   (GDSII/OASIS)  |
+--------------+       +---------------+       +------------------+

```

* **Floorplanning:** กำหนดขนาดของ Core Area, ตำแหน่ง IO Pads และวางโครงข่ายสายส่งกำลังไฟฟ้า (Power Mesh: VDD/VSS)
* **Placement:** จัดวางตำแหน่ง Standard Cells ทั้งหมดให้อยู่ในแถววงจรอย่างเหมาะสม
* **Clock Tree Synthesis (CTS):** สร้างโครงข่ายการจ่ายสัญญาณนาฬิกา (เช่น H-Tree หรือ Mesh) เพื่อลด Clock Skew และ Insertion Delay ให้เหลือน้อยที่สุด
* **Routing:** ลากเส้นสายสัญญาณโลหะเชื่อมต่อระหว่างขาพินของเซลล์ทั้งหมด
* **Physical Verification:** ตรวจสอบกฎการผลิตของโรงหล่อ (DRC: Design Rule Check) และตรวจสอบความตรงกันระหว่างเลย์เอาต์กับเน็ตลิสต์ (LVS: Layout Versus Schematic)

#### 2. เกณฑ์การ Sign-off และปิดงาน Verification

* **Functional Coverage:** บรรลุ 100% ตาม Verification Plan
* **Code Coverage:** Line, Condition, และ FSM State Coverage ผ่านเกณฑ์ที่กำหนด (>95%)
* **Timing Sign-off:** ไม่พบ Setup Violation (Worst Negative Slack $\ge 0$) และ Hold Violation ได้รับการแก้ไขครบถ้วนในทุกเงื่อนไขการทำงาน (PVT Corners: Process, Voltage, Temperature)
* **Gate-Level Simulation Sign-off:** ผ่านการทดสอบบนเน็ตลิสต์จริงพร้อม SDF Delay ทั้งโหมด Min (Fast Corner) และ Max (Slow Corner)

---

### ปฏิบัติการ Mini-Project: ระบบประมวลผลข้อมูลและสื่อสารแบบบัส (UART TX/RX System)

#### โจทย์ Mini Project:

ให้ออกแบบโมดูลสื่อสารข้อมูล UART Transmitter (VHDL) พร้อม FSM, Parity Generator, บัฟเฟอร์ Register และ Baud Rate Generator สังเคราะห์ด้วย Precision RTL และปิดงานการทดสอบด้วย QuestaSim

#### โค้ด RTL: UART Transmitter Core (`rtl/uart_tx.vhd`)

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    generic (
        CLKS_PER_BIT : integer := 868 -- 100MHz คล็อก / 115200 Baud
    );
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        tx_start  : in  std_logic;
        tx_data   : in  std_logic_vector(7 downto 0);
        tx_active : out std_logic;
        tx_serial : out std_logic;
        tx_done   : out std_logic
    );
end entity uart_tx;

architecture rtl of uart_tx is
    type state_type is (s_idle, s_start_bit, s_data_bits, s_stop_bit, s_cleanup);
    signal state : state_type := s_idle;

    signal clk_count : integer range 0 to CLKS_PER_BIT - 1 := 0;
    signal bit_index : integer range 0 to 7 := 0;
    signal tx_data_reg : std_logic_vector(7 downto 0) := (others => '0');
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state       <= s_idle;
            tx_serial   <= '1';
            tx_active   <= '0';
            tx_done     <= '0';
            clk_count   <= 0;
            bit_index   <= 0;
            tx_data_reg <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when s_idle =>
                    tx_done   <= '0';
                    clk_count <= 0;
                    bit_index <= 0;
                    if tx_start = '1' then
                        tx_data_reg <= tx_data;
                        tx_active   <= '1';
                        tx_serial   <= '0'; -- Start bit
                        state       <= s_start_bit;
                    else
                        tx_serial   <= '1';
                        tx_active   <= '0';
                    end if;

                when s_start_bit =>
                    if clk_count < CLKS_PER_BIT - 1 then
                        clk_count <= clk_count + 1;
                    else
                        clk_count <= 0;
                        tx_serial <= tx_data_reg(0);
                        state     <= s_data_bits;
                    end if;

                when s_data_bits =>
                    if clk_count < CLKS_PER_BIT - 1 then
                        clk_count <= clk_count + 1;
                    else
                        clk_count <= 0;
                        if bit_index < 7 then
                            bit_index <= bit_index + 1;
                            tx_serial <= tx_data_reg(bit_index + 1);
                        else
                            bit_index <= 0;
                            tx_serial <= '1'; -- Stop bit
                            state     <= s_stop_bit;
                        end if;
                    end if;

                when s_stop_bit =>
                    if clk_count < CLKS_PER_BIT - 1 then
                        clk_count <= clk_count + 1;
                    else
                        tx_done   <= '1';
                        clk_count <= 0;
                        state     <= s_cleanup;
                    end if;

                when s_cleanup =>
                    tx_done   <= '1';
                    tx_active <= '0';
                    state     <= s_idle;

                when others =>
                    state <= s_idle;
            end case;
        end if;
    end process;
end architecture rtl;

```

#### กระบวนการประเมินและจัดทำรายงาน Final Verification & Synthesis Report

ผู้เข้าอบรมต้องดำเนินการตามลำดับขั้นตอนและรวบรวมหลักฐานส่งประเมินดังนี้:

1. ผลการรัน Functional Simulation พร้อมบันทึกภาพ Waveform บ่งชี้การส่งข้อมูลตามเฟรมสื่อสารได้สมบูรณ์
2. รายงาน Code Coverage จาก QuestaSim ที่แสดงตัวเลขความครอบคลุมทั้งระบบ
3. รายงานการสังเคราะห์จาก Precision RTL ระบุค่า Frequency ($F_{max}$), Total Cell Area, Dynamic Power และ Timing Slack
4. ผลการรัน Gate-Level Simulation ร่วมกับ SDF หน่วงเวลาจริง โดยปราศจากข้อผิดพลาด Timing Violation

---

## สรุปและประเด็นสำคัญ (Summary & Key Takeaways)

### 1. ความเชื่อมโยงของ Flow การออกแบบดิจิทัลไอซี

* การเขียน VHDL ไม่ใช่การเขียนโปรแกรมทั่วไป แต่เป็นการพรรณนาโครงสร้างฮาร์ดแวร์จริง จึงต้องตระหนักถึงสัญญาณนาฬิกา การทำงานพร้อมกัน (Concurrency) และทรัพยากรลอจิกเสมอ
* การเขียนโค้ดต้องรัดกุมเพื่อป้องกันการเกิด Unintentional Latches และลดความซับซ้อนของเส้นทาง Combinational Logic เพื่อผลลัพธ์ Timing ที่ดีที่สุด

### 2. บทบาทสำคัญของชุดเครื่องมือ Siemens EDA

* **QuestaSim / ModelSim:** เครื่องมือหลักในการจำลองการทำงานทั้งระดับ RTL, SVA Assertions, Coverage Metrics ไปจนถึง Gate-Level Sign-off
* **Precision RTL:** โซลูชันสังเคราะห์ลอจิกขั้นสูงที่รองรับการกำหนด SDC Constraints, การทำ Retiming, Pipelining และการสร้างเน็ตลิสต์ที่สอดคล้องกับ Timing Budget
* **HDL Designer:** ช่วยยกระดับการจัดการโปรเจกต์ขนาดใหญ่ การสร้างโมดูลภาพรวม และการสร้างโค้ดอัตโนมัติ

---

## ภาคผนวก (Appendix)

### ก. ตัวอย่างไฟล์แม่แบบ SDC Constraints มาตรฐาน (`template_constraints.sdc`)

```tcl
# -------------------------------------------------------------
# SDC Reference Template for Digital IC Design
# -------------------------------------------------------------
set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA

# 1. Clock Specifications
create_clock -name core_clk -period 10.0 [get_ports {clk}]
set_clock_uncertainty -setup 0.200 [get_clocks {core_clk}]
set_clock_uncertainty -hold  0.080 [get_clocks {core_clk}]
set_clock_transition 0.150 [get_clocks {core_clk}]

# 2. IO Timing Constraints
set_input_delay -clock core_clk -max 3.0 [get_ports {data_in[*]}]
set_input_delay -clock core_clk -min 0.8 [get_ports {data_in[*]}]
set_output_delay -clock core_clk -max 2.5 [get_ports {data_out[*]}]
set_output_delay -clock core_clk -min 0.5 [get_ports {data_out[*]}]

# 3. Environment & Operating Conditions
set_load 0.030 [all_outputs]
set_driving_cell -lib_cell BUFX4 [all_inputs]

# 4. Timing Exceptions (ถ้ามี)
# set_false_path -from [get_ports {rst_n}]
# set_multicycle_path -setup 2 -from [get_pins {path_reg/CP}] -to [get_pins {dest_reg/D}]

```

### ข. กฎเหล็กการเขียนโค้ด VHDL สำหรับการสังเคราะห์ (Synthesis Best Practices)

1. **หลีกเลี่ยง Latch:** กำหนดค่าเริ่มต้นของสัญญาณใน Process เสมอ หรือเขียนเงื่อนไข `if ... else ...` และ `case ... when others` ให้ครบทุกกรณี
2. **ไม่ใช้ Hardcoded Delays:** ห้ามใส่คำสั่ง `wait for ... ns` ในสถาปัตยกรรมระดับ RTL ที่ต้องการสังเคราะห์
3. **จัดระเบียบ Clock Edges:** ใช้เฉพาะ `rising_edge(clk)` หรือ `falling_edge(clk)` อย่างเป็นเอกภาพ ห้ามผสมกันในฟลิปฟล็อปตัวเดียวกันโดยไม่มีเหตุผลทางสถาปัตยกรรม
4. **แยกสัญญาณ Reset:** ใช้ Reset แบบ Asynchronous Active-Low (`rst_n`) ที่เชื่อมโยงเข้าสู่ขา Clear ของ DFF โดยตรง

### ค. ตารางเทียบคำสั่งทั่วไปบน QuestaSim CLI / TCL Script

| คำสั่ง QuestaSim | หน้าที่และลักษณะการใช้งาน |
| --- | --- |
| `vlib <dir>` / `vmap <name> <dir>` | สร้างและเชื่อมโยงไดเรกทอรีไลบรารีการทำงาน |
| `vcom -93 -work <lib> <file.vhd>` | คอมไพล์ไฟล์ภาษา VHDL ตามมาตรฐาน 1993 |
| `vlog -sv -work <lib> <file.sv>` | คอมไพล์ไฟล์ภาษา SystemVerilog / Assertions |
| `vsim -t 1ps <lib>.<top_entity>` | เรียกเอนจินจำลองการทำงานที่ระดับความละเอียดเวลา 1 ps |
| `add wave -r /*` | เพิ่มสัญญาณทั้งหมดเข้าสู่หน้าต่าง Waveform แบบ Recursive |
| `run -all` / `run <time>` | สั่งรันการจำลองจนจบ หรือรันตามระยะเวลาที่กำหนด |
| `coverage save <filename.ucdb>` | บันทึกข้อมูลผลการทดสอบ Coverage ลงในไฟล์ฐานข้อมูล |
| `quit -sim` | จบเซสชันการจำลองปัจจุบันเพื่อเตรียมคอมไพล์หรือรันงานใหม่ |
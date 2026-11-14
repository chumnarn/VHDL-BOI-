# คู่มือการใช้งาน Siemens Precision Synthesis สำหรับการสังเคราะห์วงจรดิจิทัล

**(Siemens Precision RTL Synthesis Tutorial)**

คู่มือฉบับนี้สรุปขั้นตอนการทำงานบน **Siemens Precision RTL Synthesis** (เดิม Mentor Graphics Precision) ซึ่งเป็นเครื่องมือสังเคราะห์วงจรตรรกะระดับมืออาชีพสำหรับ FPGA และ ASIC/Structured ASIC ครอบคลุมการตั้งค่าโครงการ การวิเคราะห์ RTL การกำหนด SDC Constraints การปรับแต่งโครงสร้างระดับสูง (Optimization) ตลอดจนการวิเคราะห์ Timing และ Resource Utilization

---

### 1. สถาปัตยกรรมและกระบวนการทำงานหลัก (Synthesis Flow)

Precision RTL แปลงคำสั่งระดับพฤติกรรม (RTL) ให้กลายเป็นวงจรเกตลอจิก (Gate-Level Netlist) โดยคำนึงถึงข้อกำหนดด้านเวลา (Timing Constraints) และสถาปัตยกรรมของชิปเป้าหมาย:

```
[VHDL / Verilog / SystemVerilog RTL] + [SDC Constraints]
                          │
                          ▼
 1. Analysis & Compile    ──> ตรวจสอบ Syntax, ตีความพฤติกรรม, สร้าง RTL View
                          │
                          ▼
 2. Logic Optimization    ──> ลดรูปบูลีน, Resource Sharing, FSM Extraction, Pipelining/Retiming
                          │
                          ▼
 3. Technology Mapping    ──> จับคู่ลอจิกเข้ากับ LUTs, DSP Blocks, BRAMs หรือ Standard Cells
                          │
                          ▼
 4. Timing Analysis (STA) ──> ตรวจสอบ Setup/Hold Slack, ระบุ Critical Data Path
                          │
                          ▼
 [Gate-Level Netlist (.vhd/.v)] + [SDF File] + [Reports (Area & Timing)]

```

---

### 2. ตารางคำสั่ง TCL หลักบน Precision Synthesis CLI

| คำสั่ง TCL | ตัวอย่างและพารามิเตอร์ | การทำงาน |
| --- | --- | --- |
| `new_project` | `new_project -name "my_core" -folder ./syn_out` | สร้างโฟลเดอร์และไฟล์โครงงานใหม่ |
| `setup_design` | `setup_design -manufacturer Xilinx -family Artix-7 -part 7a100t` | กำหนดผู้ผลิต ตระกูลชิป เบอร์อุปกรณ์ และเกรดความเร็ว |
| `add_input_file` | `add_input_file -format vhdl ../rtl/mac_unit.vhd` | นำเข้าไฟล์ซอร์สโค้ดระดับ RTL |
| `read_sdc` | `read_sdc ../syn/timing.sdc` | โหลดข้อกำหนดด้านเวลาตามมาตรฐาน SDC |
| `compile` | `compile` | ตรวจสอบไวยากรณ์และแปลงโค้ดเป็น Generic Logic Elements |
| `synthesize` | `synthesize` | ทำ Technology Mapping และ Optimization |
| `report_timing` | `report_timing -num_paths 5 -file timing.rpt` | สร้างรายงานวิเคราะห์เวลาตามเส้นทางวิกฤต (Critical Path) |
| `report_area` | `report_area -file area.rpt` | สร้างรายงานสรุปการใช้ทรัพยากรลอจิก |
| `write_output_file` | `write_output_file -format vhdl netlist.vhd` | สกัดวงจรหลังสังเคราะห์ในรูป Gate-Level Netlist |

---

### 3. ตัวอย่างการทดลอง: หน่วยคูณสะสม (Multiply-Accumulate: MAC Unit)

ตัวอย่างนี้ใช้โมดูลคำนวณทางคณิตศาสตร์ความเร็วสูงที่ต้องอาศัยการ Optimize เพื่อให้ได้ความถี่สัญญาณนาฬิกาเป้าหมาย

#### โค้ด RTL: `rtl/mac_unit.vhd`

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mac_unit is
    generic (
        DATA_WIDTH : integer := 16;
        ACC_WIDTH  : integer := 36
    );
    port (
        clk    : in  std_logic;
        rst_n  : in  std_logic;
        clr    : in  std_logic;
        valid  : in  std_logic;
        a_in   : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        b_in   : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        accum  : out std_logic_vector(ACC_WIDTH - 1 downto 0)
    );
end entity mac_unit;

architecture rtl of mac_unit is
    signal mult_reg : signed(2 * DATA_WIDTH - 1 downto 0) := (others => '0');
    signal acc_reg  : signed(ACC_WIDTH - 1 downto 0)       := (others => '0');
begin

    process(clk, rst_n)
        variable p : signed(2 * DATA_WIDTH - 1 downto 0);
    begin
        if rst_n = '0' then
            mult_reg <= (others => '0');
            acc_reg  <= (others => '0');
        elsif rising_edge(clk) then
            if clr = '1' then
                acc_reg  <= (others => '0');
                mult_reg <= (others => '0');
            elsif valid = '1' then
                p := signed(a_in) * signed(b_in);
                mult_reg <= p;
                acc_reg  <= acc_reg + resize(mult_reg, ACC_WIDTH);
            end if;
        end if;
    end process;

    accum <= std_logic_vector(acc_reg);

end architecture rtl;

```

---

### 4. การกำหนด SDC Constraints

สร้างไฟล์ `syn/mac_constraints.sdc` สำหรับกำหนดความถี่เป้าหมาย 150 MHz และความล่าช้าของพอร์ตภายนอก:

```tcl
# 1. กำหนดหน่วยเวลา
set_time_unit -nanoseconds

# 2. สร้างสัญญาณนาฬิกาหลัก (150 MHz -> Period 6.666 ns)
create_clock -name core_clk -period 6.666 [get_ports {clk}]

# 3. กำหนดความไม่แน่นอนของสัญญาณนาฬิกา (Jitter & Skew)
set_clock_uncertainty -setup 0.250 [get_clocks {core_clk}]
set_clock_uncertainty -hold  0.100 [get_clocks {core_clk}]

# 4. กำหนดเวลาหน่วงขาเข้า (Input Delay อิงรอบสัญญาณภายนอก)
set_input_delay -clock core_clk -max 1.800 [get_ports {a_in[*] b_in[*] valid clr}]
set_input_delay -clock core_clk -min 0.300 [get_ports {a_in[*] b_in[*] valid clr}]

# 5. กำหนดเวลาหน่วงขาออก (Output Delay)
set_output_delay -clock core_clk -max 1.500 [get_ports {accum[*]}]
set_output_delay -clock core_clk -min 0.200 [get_ports {accum[*]}]

# 6. กำหนดพาร์ทที่ไม่คิดความเร็ว (False Path สำหรับ Asynchronous Reset)
set_false_path -from [get_ports {rst_n}]

```

---

### 5. สคริปต์รันการสังเคราะห์อัตโนมัติ (Batch Synthesis Script)

สร้างไฟล์ `syn/run_synth.tcl` เพื่อประมวลผลผ่าน Command Line:

```tcl
# 1. สร้างโฟลเดอร์โปรเจกต์
new_project -name "MAC_Synthesis" -folder "./build"

# 2. เลือกระบบเป้าหมาย (ตัวอย่าง: ชิป FPGA ตระกูล Artix-7 หรือสามารถเลือก Generic Standard Cell)
setup_design -manufacturer Xilinx \
             -family Artix-7 \
             -part 7a100tcsg324 \
             -speed -1

# 3. นำเข้าซอร์สโค้ดและข้อจำกัดเวลา
add_input_file -format vhdl ../rtl/mac_unit.vhd
read_sdc ../syn/mac_constraints.sdc

# 4. ตั้งค่าการเพิ่มประสิทธิภาพขั้นสูง
set_attribute -name PIPELINE         -value TRUE
set_attribute -name RETIMING         -value TRUE
set_attribute -name RESOURCE_SHARING -value TRUE
set_attribute -name MAX_FANOUT       -value 32

# 5. คอมไพล์และวิเคราะห์โครงสร้าง RTL
compile

# 6. สังเคราะห์วงจร (Technology Mapping)
synthesize

# 7. สร้างรายงานผล
report_timing -num_paths 10 -file ./reports/timing_report.rpt
report_area   -file ./reports/area_report.rpt

# 8. ส่งออก Gate-Level Netlist และ SDF สำหรับ Gate-Level Sim ใน QuestaSim
write_output_file -format vhdl ./netlist/mac_unit_netlist.vhd
write_output_file -format sdf  ./netlist/mac_unit.sdf

puts ">>> Precision RTL Synthesis Completed Successfully! <<<"

```

คำสั่งรันจาก Terminal:

```bash
precision -file run_synth.tcl

```

*(หากต้องการเปิดตรวจสอบผลผ่านหน้าต่างกราฟิก ให้ใช้คำสั่ง `precision` แล้วเปิดไฟล์โปรเจกต์ `.psp` ที่สร้างขึ้น)*

---

### 6. การใช้งาน Precision GUI เพื่อวิเคราะห์วงจร

1. **RTL Schematic Viewer:**
* ดับเบิลคลิกที่โมดูลหลังคำสั่ง `compile` หน้าต่างจะแสดงภาพโครงสร้างระดับสถาปัตยกรรม (บล็อกบวก, ตัวคูณ, มัลติเพล็กเซอร์) ใช้ตรวจสอบความถูกต้องของการแปลงโค้ด VHDL เป็นฮาร์ดแวร์ก่อนทำ Mapping


2. **Technology Schematic Viewer:**
* เปิดดูหลังคำสั่ง `synthesize` หน้าต่างจะแสดงเซลล์จริงของอุปกรณ์ เช่น DSP48E1 Blocks, LUT6, FDRE Flip-Flops พร้อมสายเชื่อมต่อ


3. **Critical Path Browser:**
* ไปที่แท็บ **Timing Analysis** คลิกขวาที่พาร์ทที่มี Slack ต่ำสุด เลือก **Cross-Probe to Schematic** ซอฟต์แวร์จะไฮไลต์เส้นทางวิกฤตบนแผนผังวงจรทันที ช่วยให้ชี้ชัดได้ว่าความหน่วงเวลาเกิดจาก Logic Depth หรือ Interconnect Routing



---

### 7. เทคนิคการแก้ไข Timing Violations (Optimization Strategies)

| ปัญหาที่พบ | สาเหตุหลัก | วิธีแก้ปัญหาใน Precision |
| --- | --- | --- |
| **Negative Setup Slack (WNS < 0)** | เส้นทาง Combinational Logic ยาวเกินไป (Logic Depth สูง) | เปิดใช้งาน `RETIMING` เพื่อให้เครื่องมือเกลี่ยตำแหน่ง Flip-Flop ข้ามลอจิกเกตอัตโนมัติ |
| **DSP / Multiplier Delay** | สัญญาณเข้า-ออกตัวคูณไม่มีการกั้นสเตจ | เปิดใช้งาน `PIPELINE` เพื่อแทรก Register เข้าไปในตัวคูณหรือเปิดฟังก์ชัน Register Packed ของ DSP Block |
| **High Fan-out Net Delay** | สัญญาณตัวเดียวจ่ายไปยังโหลดจำนวนมาก | กำหนด `set_attribute -name MAX_FANOUT -value 24` เพื่อสั่งให้ Precision โคลน Buffer หรือ Flip-Flop กระจายสัญญาณ |
| **FSM State Transition Delay** | การเข้ารหัส FSM ใช้จำนวนบิตน้อยเกินไป ทำให้ลอจิกถอดรหัสหนาแน่น | เปลี่ยน FSM Encoding จาก Binary/Gray เป็น **One-Hot** โดยใช้คำสั่ง `set_attribute -name ENCODING -value ONEHOT` |

---

### 8. การส่งต่องานไปยังขั้นตอนถัดไป (Handoff)

* **ไปยัง Place & Route (P&R Tools):**
Precision จะสร้างไฟล์ Netlist ในรูปแบบ EDIF (`.edf`) หรือ Structural Verilog/VHDL (`.v` / `.vhd`) พร้อมไฟล์ Constraints (`.sdc`) ที่ได้รับการ Translate ให้ตรงกับซอฟต์แวร์ Backend (เช่น Vivado, Quartus หรือ Libero)
* **ไปยัง Gate-Level Simulation (QuestaSim / ModelSim):**
นำไฟล์ `mac_unit_netlist.vhd` และ `mac_unit.sdf` ที่ได้จากคำสั่ง `write_output_file` ไปรันร่วมกับ Testbench เดิมใน QuestaSim เพื่อยืนยันว่าวงจรหลังสังเคราะห์ยังคงทำงานถูกต้องตามเวลาจริงโดยไม่มีสัญญาณกลิตช์ (Glitch) หรือ Setup/Hold Violations
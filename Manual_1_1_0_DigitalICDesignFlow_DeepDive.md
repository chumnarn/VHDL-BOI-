# รายละเอียดเชิงลึก: Digital IC Design Flow (Behavioral → Physical)

> เนื้อหานี้ออกแบบมาให้นำไปแทรกเป็นส่วนขยายในหัวข้อ **1.1 ภาคทฤษฎี: Digital IC Design Flow** ของคู่มือหลักสูตร (วันที่ 1)
> เหมาะสำหรับการบรรยาย 90–120 นาที พร้อมตัวอย่างจริงจากกระบวนการของ TSMC/Samsung/OpenROAD

---

## 1. ภาพรวมของกระบวนการออกแบบวงจรดิจิทัล (Big Picture)

การออกแบบวงจรดิจิทัลในปัจจุบันเป็นกระบวนการที่ประกอบด้วยหลายขั้นตอน เรียงตั้งแต่ระดับแนวคิด (concept) ไปจนถึงชิ้นส่วนซิลิคอนจริง (silicon die) ที่ผลิตได้ เราแบ่งขั้นตอนออกเป็น **3 ระดับหลัก** ในเชิง abstraction:

                                                   
                                                    ┌──────────────────────────────────────────────────┐
                                                    │  System / Behavioral ─── อัลกอริทึม/สถาปัตยกรรม     │
                                                    │  Register-Transfer ───── การไหลข้อมูลระหว่าง FF     │
                                                    │  Logic Gate ───────────── เกตมาตรฐาน             │
                                                    │  Transistor/Circuit ──── MOSFET, RC netlist      │
                                                    │  Physical (Layout) ───── GDSII shapes on silicon │
                                                    └──────────────────────────────────────────────────┘
                                                  

ทุกขั้นตอนจะมี **tool, format, verification** ของตัวเอง และผลผลิตของขั้นตอนหนึ่งจะเป็น input ของอีกขั้นตอนถัดไป ทำให้เกิด "tool chain" หรือ "flow" ที่ชัดเจน

---

## 2. Design Abstraction Levels – รายละเอียดเชิงลึก

### 2.1 System/Behavioral Level (ระดับระบบ)

**คำจำกัดความ:** อธิบาย *ฟังก์ชัน* ของระบบในมุมมองของอัลกอริทึม โดยไม่สนใจวิธีการ implement เป็นฮาร์ดแวร์

**สิ่งที่อยู่ในระดับนี้:**
- Algorithm specification (เช่น FFT, MPEG decoder)
- Mathematical model ของ data path
- Functional partitioning (CPU + Memory + DSP block + IO)
- การวิเคราะห์ throughput/latency requirement
- Power/area budget ระดับบน (top-down estimation)

**ภาษา/Format ที่ใช้:**
- C / C++ / SystemC (transaction-level modeling)
- MATLAB / Python (สำหรับ algorithmic exploration)
- บางทีใช้ UML/SysML ในงาน enterprise SoC

**ตัวอย่าง:**

```cpp
// SystemC model of FIR filter
SC_MODULE(fir_filter) {
    sc_in<double>  x_in;
    sc_out<double> y_out;
    void process() {
        double acc = 0;
        for (int k = 0; k < N; k++) acc += h[k] * x_buffer[k];
        y_out.write(acc);
    }
};
```

**เครื่องมือ:**
- SystemC simulator (Accellera)
- MATLAB/Simulink
- High-Level Synthesis (HLS): Catapult, Vivado HLS, Cadence Stratus
- Architectural exploration: gem5 (CPU simulation), ONNX (ML workload)

**จุดเด่น:**
- รันได้เร็วมาก (10⁴–10⁶ เท่าของ RTL sim)
- เปลี่ยน algorithm ได้ง่าย
- ใช้สำหรับ early-stage trade-off analysis

**ข้อจำกัด:**
- ไม่สามารถประเมิน timing/area ได้แม่นยำ
- ต้องแปลงเป็น RTL หรือ gate-level จึงจะผลิตได้

---

### 2.2 Register-Transfer Level (RTL) — ระดับที่ใช้เขียน VHDL/Verilog

**คำจำกัดความ:** อธิบาย *การไหลของข้อมูลระหว่างเรจิสเตอร์* (FFs) และ *ตรรกะเชิงผสม* (combinational logic) ระหว่างเรจิสเตอร์เหล่านั้น โดยมีสัญญาณนาฬิกาเป็นตัวกำหนดจังหวะ

**โครงสร้างพื้นฐาน:**

```
   ┌───────────┐    combinational     ┌───────────┐
   │ REG (FFs) │ ───────logic────────►│ REG (FFs) │
   └───────────┘     (no clk)         └───────────┘
        ▲                                   │
        │           clk (period = T)        │
        └───────────────────────────────────┘
```

**องค์ประกอบ:**
- **Register/Flip-flop**: เก็บ state ระหว่าง cycle
- **Combinational logic**: AND/OR/XOR/MUX/Adder/Multiplier
- **Clock & Reset**: กำหนด timing และ state เริ่มต้น
- **Interface**: I/O ports ระหว่างบล็อก

**ภาษา/Format:**
- **VHDL** (IEEE 1076) — มาตรฐานยุโรป/อเมริกา
- **Verilog** (IEEE 1364) — มาตรฐาน US/Cadence
- **SystemVerilog** (IEEE 1800) — Verilog + verification features

**ตัวอย่าง VHDL:**

```vhdl
-- 8-bit signed adder with overflow detect
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity add8_signed is
    port (
        a, b  : in  signed(7 downto 0);
        sum   : out signed(7 downto 0);
        ovf   : out std_logic
    );
end entity;

architecture rtl of add8_signed is
begin
    process (a, b)
        variable va, vb, vs : signed(8 downto 0);
    begin
        va := "0" & a;
        vb := "0" & b;
        vs := va + vb;
        sum <= vs(7 downto 0);
        -- signed overflow: signs agree before, but disagree after
        ovf <= '1' when (a(7) = b(7)) and (sum(7) /= a(7)) else '0';
    end process;
end architecture;
```

**คุณสมบัติของ RTL ที่ดี:**
1. **Synthesizable subset** — ใช้เฉพาะ syntax ที่ tool รู้จัก
2. **Single-clock domain** หรือมี CDC convention ที่ชัดเจน
3. **Synchronous reset** (แนะนำ) — ไม่ใช้ asynchronous reset นอกจากมีเหตุผลเฉพาะ
4. **No latches** — ใส่ default assignment ทุก combinational block
5. **Parameterized** — ใช้ `generic`/`parameter` เพื่อ reuse

**เครื่องมือ:**
- HDL Designer (block/state diagram → VHDL) — Siemens EDA
- Editor: VS Code + VHDL extension, Sigasi, Emacs + vhdl-mode
- Linter: ghdl-yosim VHDL-ls

---

### 2.3 Logic Gate-Level (Netlist)

**คำจำกัดความ:** วงจรถูกแทนด้วย **เกตมาตรฐาน** (NAND, NOR, INV, AND, OR, DFF, MUX, Adder) ที่อยู่ใน cell library ของเทคโนโลยีเป้าหมาย พร้อมการเชื่อมต่อระหว่างเกต (netlist)

**โครงสร้าง:**

```verilog
// Example gate-level netlist (Verilog format from synthesizer)
module top (a, b, cin, sum, cout);
    input  [7:0] a, b;
    input        cin;
    output [7:0] sum;
    output       cout;

    wire n0, n1, n2, n3, n4, n5, n6, n7;
    wire c0, c1, c2, c3, c4, c5, c6, c7;

    // Cell A1: NAND2X1 (typical cell from 45nm library)
    NAND2X1 U1 (.A(a[0]), .B(b[0]), .Y(n0));
    ...
end module
```

**Format ที่ใช้:**
- **Verilog netlist** (`.v`) — มาตรฐานอุตสาหกรรม
- **VHDL netlist** (`.vhd`) — มีใช้แต่น้อยกว่า
- **EDIF** (Electronic Design Interchange Format) — เก่ากว่า
- **SDF** (Standard Delay Format) — เก็บ delay annotation

**Cell Library Characteristics:**
- **Standard cells**: NAND, NOR, INV, AND, OR, DFF, latch, MUX, adder, etc.
- **Cells มีหลาย drive strength**: X1, X2, X4, X8 (เพื่อเลือกตาม fan-out)
- **Cells มีหลาย threshold voltage**: LVT (เร็ว/กินไฟ), SVT (สมดุล), HVT (ช้า/ประหยัดไฟ)
- **Cell footprint**: ขนาดพื้นที่, pin location ตายตัว

**ตัวอย่าง Cell Library (45nm):**

| Cell | Area (μm²) | Delay (ps) | Power (μW/MHz) |
| --- | --- | --- | --- |
| INVX1 | 0.5 | 25 | 0.5 |
| NAND2X1 | 0.9 | 35 | 0.8 |
| DFFRX1 | 2.4 | 80 | 1.2 |
| ADDFHX1 | 14 | 350 | 8.0 |

**เครื่องมือ:**
- **Precision RTL** (Siemens EDA) — Logic synthesis
- **Genus** (Cadence) — Logic synthesis
- **Design Compiler** (Synopsys) — มาตรฐานอุตสาหกรรม
- **Yosys** (open-source) — synthesis สำหรับ FPGA และ ASIC

---

### 2.4 Transistor / Circuit Level

**คำจำกัดความ:** วงจรถูกแทนด้วย **MOSFET** (nMOS, pMOS) พร้อมขนาด W/L และ parasitic (R, C)

**ใช้เมื่อ:**
- ออกแบบ custom block เช่น SRAM, PLL, SerDes, I/O pad
- ต้อง optimize ที่ระดับ transistor เพื่อ performance/power
- วิเคราะห์ analog/mixed-signal behavior

**ภาษา/Format:**
- **SPICE netlist** (.sp, .spi) — มาตรฐานสำหรับ circuit simulation
- **Spectre/HSPICE/FineSim** — simulators

**ตัวอย่าง CMOS Inverter SPICE:**

```spice
* 45nm CMOS Inverter
.subckt INV in out vdd vss
M_p out in vdd vdd pmos W=90n L=45n
M_n out in vss vss nmos W=45n L=45n
.ends
```

**เครื่องมือ:**
- SPICE simulator: Spectre (Cadence), HSPICE (Synopsys), FineSim
- Custom layout: Virtuoso (Cadence), Tanner L-edit

**หมายเหตุ:** หลักสูตรนี้เน้น digital design ที่ระดับ RTL/Logic ส่วน transistor level จะกล่าวถึงในส่วนที่ 2 (Day 6-7) เรื่อง CMOS Layout

---

### 2.5 Physical Layout Level

**คำจำกัดความ:** วงจรถูกแทนด้วย **รูปทรงเรขาณĐ (geometric shapes)** บน layer ต่าง ๆ ของซิลิคอน — Metal, Poly, Diffusion, Via

**Format:** **GDSII** (Graphic Database System II) — binary file ที่อธิบาย polygon บนแต่ละ layer

**โครงสร้าง Layout:**

```
Layer    Description          Example Shape
─────────────────     ────────
Metal 1  Interconnect         ──────► (horizontal wires)
Via 1    Connect M1↔M2         □ (square contact)
Metal 2  Interconnect         ──────► (vertical wires)
Active   Transistor area      ▓▓▓▓▓▓
N+       n-type diffusion     ▒▒▒▒▒
P+       p-type diffusion     ░░░░░
Poly     Gate electrode     ────►
```

**ตัวอย่าง Inverter Layout:**

```
    VDD
     │
    ─┴─    ← Metal1
     │ p+
    ─┬─    ← Poly (gate)
     │ n+
    ─┴─    ← Metal1
     │
    GND
```

**ข้อมูลที่บรรจุใน GDSII:**
- Layer number (45nm: ~30 layers, 7nm: ~80+ layers)
- Polygon coordinates
- Cell references (hierarchical placement)
- Labels/text

**เครื่องมือ:**
- **Place & Route**: Innovus (Cadence), ICC2 (Synopsys), OpenROAD (open-source)
- **Layout editor**: Virtuoso, Tanner L-edit, KLayout
- **DRC/LVS**: Calibre (Mentor/Siemens), Pegasus (Cadence), Magic (open-source)

---

## 3. Gajski's Y-Chart — แบบจำลองการออกแบบ 3 มิติ

**Daniel Gajski** ได้เสนอ **Y-Chart** เพื่ออธิบายการออกแบบวงจรใน 3 มิติ: **Behavioral / Structural / Geometric** โดยในแต่ละมิติสามารถอยู่ใน abstraction level ต่าง ๆ ได้

```
                    ┌─────────────────────┐
                    │   BEHAVIORAL DOMAIN │
                    │  Algorithm/Function │
                    └─────────┬───────────┘
                              │
                              │ (radii = abstraction levels)
                              ▼
   STRUCTURAL DOMAIN ◄─────   ●  ─────► GEOMETRIC DOMAIN
   Components/Blocks         (axis)       Layout/Shapes
                              ▲
                              │
                              │
                    ┌─────────┴────────────┐
                    │  GEOMETRIC DOMAIN    │
                    │  Layout/Shapes       │
                    └──────────────────────┘
```

**ความหมาย:**
- แกนบน-ล่าง: **Behavioral** (อัลกอริทึม) → **Structural** (โครงสร้าง) → **Geometric** (รูปทรง)
- แต่ละ "วง" ที่อยู่ห่างจากศูนย์กลางคือ abstraction level (System → RTL → Gate → Transistor → Layout)

**ประโยชน์ของ Y-Chart:**
- ช่วยให้เข้าใจว่าเมื่อเราออกแบบที่ระดับหนึ่ง กำลัง "อยู่ที่วงใด"
- เครื่องมือ EDA แต่ละตัวทำงานใน "quadrant" เฉพาะ เช่น:
  - **Synthesis tool** (Precision, Genus): RTL → Gate (Behavioral → Structural)
  - **Place & Route tool** (Innovus, OpenROAD): Gate → Physical (Structural → Geometric)
  - **Layout editor** (Virtuoso, L-edit): ทำงานใน Geometric domain

---

## 4. ASIC Design Flow – Front-End (Logic Design)

Front-End คือขั้นตอนตั้งแต่ **Specification จนถึง Gate-Level Netlist** ที่ยังไม่ขึ้นกับ layout ทางกายภาพ

### 4.1 ลำดับขั้น Front-End

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ 1. SPEC     │───►│2. RTL DESIGN│───►│ 3. RTL      │───►│ 4. SYNTH    │
│             │    │             │    │ VERIFICATION│    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
   Functional       │ Behavioral     │ Functional       │ RTL → Netlist
   requirements     │ + Structural   │ correctness      │ (gate-level)
                    │ modeling       │                  │
                    └─► HDL Designer └─► Questa         └─► Precision RTL
                        • Block diag     • Unit test
                        • State diag     • Self-check TB
                                         • Coverage
```

### 4.2 Stage 1: Specification (Spec)

**เอกสารที่ต้องผลิต:**
- **Functional specification**: อธิบายการทำงานเชิงฟังก์ชัน
- **Interface specification**: สัญญาณ I/O, protocol, timing requirement
- **Architecture specification**: block diagram, data path, control
- **Performance spec**: throughput, latency, power budget, area target
- **Verification spec**: feature list, test plan

**ตัวอย่าง Specification:**

| Item | Value |
| --- | --- |
| Function | 32-bit RISC-V CPU core |
| Clock | 1 GHz |
| IPC (instruction/cycle) | ≥ 0.8 |
| Power | ≤ 50 mW @ 1 GHz |
| Process | TSMC N7 |
| Area | ≤ 0.3 mm² |
| Verification | 100% functional coverage |

### 4.3 Stage 2: RTL Design

**สิ่งที่ Engineer ทำ:**
1. แบ่งระบบออกเป็น **block hierarchy** (top, sub-block, leaf)
2. เขียน **FSM** สำหรับ control logic
3. เขียน **datapath** สำหรับ data processing (adder, multiplier, FIFO, etc.)
4. กำหนด **interface protocol** (handshake, FIFO, AMBA AXI, etc.)
5. ใช้ **coding style** ที่ consistent (e.g., 1-stage FSM, synchronous reset, CE everywhere)

**Coding Style ที่ดี:**

```vhdl
-- Template: Module with standard interfaces
entity block_iwt is
    generic (
            WIDTH : integer := 8
        );
        port (
            clk      : in  std_logic;
            rst_n    : in  std_logic;           -- active-low reset (convention)
            din      : in  std_logic_vector(WIDTH-1 downto 0);
            din_vld  : in  std_logic;
            din_rdy  : out std_logic;
            dout     : out std_logic_vector(WIDTH-1 downto 0);
            dout_vld : out std_logic;
            dout_rdy : in  std_logic
        );
end entity;
```

### 4.4 Stage 3: RTL Verification (Functional Verification)

**Goal:** พิสูจน์ว่า RTL ทำงานถูกต้องตาม spec

**ระดับของ Verification:**

| Level | สิ่งที่ตรวจ | เทคนิค |
| --- | --- | --- |
| Unit test | แต่ละโมดูลทำงานถูก | Directed testbench, self-checking |
| Integration | บล็อกเชื่อมต่อกันถูก | Constrained random, scoreboard |
| Protocol | Protocol rules ถูกต้อง | Assertions (SVA/PSL) |
| Performance | Throughput/latency ตรงตาม spec | Performance counters |

**Coverage-Driven Verification (CDV):**

```
   ┌──────────────────────────────────────────────────┐
   │                                                  │
   │    Testbench ──► Simulator ──► Coverage Analyzer │
   │         ▲                              │         │
   │         │                              ▼         │
   │         └── Coverage Holes ◄── Coverage Report   │
   │              (gaps to fill)                      │
   │                                                  │
   └──────────────────────────────────────────────────┘
```

### 4.5 Stage 4: Logic Synthesis

**Input:** RTL + Constraints (SDC)
**Output:** Gate-Level Netlist + Reports (area, timing, power)

**ขั้นตอนภายใน Synthesis:**

```
   RTL (VHDL/Verilog)
          │
          ▼
   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
   │ 1. HDL      │    │ 2. GTECH    │    │ 3. Mapping  │
   │    Parse    │───►│    (generic │───►│ (to library │───► Netlist
   │  Elaboration│
   │  (build     │    │   gates)    │    │   cells)    │
   │   hierarchy)│
   └─────────────┘    └─────────────┘    └─────────────┘
                                                 │
                                                 ▼
                                         ┌─────────────┐
                                         │ . Optimiza- │
                                         │   tion      │
                                         │ (area/time) │
                                         └─────────────┘
```

**Optimization Techniques:**
- **Combinational optimization**: constant propagation, dead code elimination, factoring
- **Sequential optimization**: retiming, register merging
- **Technology mapping**: เลือก cell ที่ดีที่สุดจาก library
- **Area optimization**: resource sharing, width reduction
- **Timing optimization**: buffer insertion, gate sizing

**Reports:**
- **Area report**: จำนวน cell, gate count, utilization
- **Timing report**: slack ต่อ path (setup/hold)
- **Power report**: dynamic + static power
- **Constraint report**: constraint ที่ยังไม่ถูก satisfy

---

## 5. ASIC Design Flow – Back-End (Physical Design)

Back-End คือการแปลง netlist → layout จริงบนซิลิคอน

```
┌───────────┐    ┌───────────┐    ┌───────────┐    ┌───────────┐
│ 1. Floor- │───►│ 2. Place- │───►│ 3. CTS    │───►│ 4. Routing│
│   plan    │    │   ment    │    │           │    │           │
└───────────┘    └───────────┘    └───────────┘    └───────────┘
                                                       ▼
                                              ┌────────────────┐
                                              │ 5. Verification│
                                              │    + Sign-off  │
                                              │  STA/DRC/LVS/  │
                                              │  Power/IR drop │
                                              └────────────────┘
```

### 5.1 Stage 1: Floorplanning

**Objective:** กำหนด macro placement, IO pad placement, power grid

**Inputs:** Netlist + die size constraint + pin constraints
**Outputs:** Floorplan view, power plan

**สิ่งที่ต้องตัดสินใจ:**
- **Die size**: ขนาด chip (area budget)
- **Aspect ratio**: เช่น 1:1, 2:1
- **Core area**: ส่วน logic
- **Pad ring**: I/O pads รอบ die
- **Macro placement**: SRAM, PLL, Analog block ตำแหน่งไหน
- **Power grid**: stripe ของ VDD/VSS

**Visualization:**

```
    ┌─────────────────────────────────────┐
    │  P P P P P P P P P P P P P P P P P  │   ← Pad ring (top)
    │  P  ┌─────────────────────────┐  P  |
    │  P  │  SRAM    │     SRAM     │  P  |
    │  P  ├──────────┼──────────────┤  P  |   ← Core area
    │  P  │  Logic   │   Analog/PLL │  P  |
    │  P  │          │              │  P  |
    │  P  │  Logic   │   Logic      │  P  |
    │  P  └─────────────────────────┘  P  |
    │  P P P P P P P P P P P P P P P P P  │   ← Pad ring (bottom)
    └─────────────────────────────────────┘
```

### 5.2 Stage 2: Placement

**Objective:** วางตำแหน่ง cell ทุกตัวบน row ของ core area

**Algorithm:** 
- Global placement: optimization หาตำแหน่งคร่าว ๆ
- Legalization: ย้าย cell ให้อยู่บน row, ไม่ overlap
- Detailed placement: refine ตำแหน่งเพื่อลด congestion

**Optimization Goals:**
- Minimize wire length
- Balance density (ไม่ให้ส่วนใดแน่น/ว่างเกินไป)
- Respect macro blockages
- Consider timing (critical path อยู่ใกล้กัน)

**Reports:**
- Placement density heatmap
- Wire length estimate
- Timing (post-placement)
- Congestion map

### 5.3 Stage 3: Clock Tree Synthesis (CTS)

**Objective:** สร้าง clock distribution network เพื่อให้ clock ถึงทุก FF ในเวลาใกล้เคียงกัน

**ปัญหาที่ต้องแก้:**
- **Clock skew**: clock มาถึง FF แต่ละตัวไม่พร้อมกัน
- **Clock latency**: delay จาก clock source ถึง FF
- **Clock power**: clock buffer กินไฟสูง (15-30% ของ total power)
- **DRC**: clock ต้อง satisfy min/max wire length

**โครงสร้าง Clock Tree (H-tree):**

```
                    Root
                   /    \
                  /      \
                 /        \
                B          B       (clock buffers)
               / \        / \
              B   B      B   B
             /\  /\     /\  /\
            F  F F F   F F  F F   (FF leaves)
```

**Metrics:**
- **Skew**: max - min clock latency ระหว่าง FF
- **Insertion delay**: clock latency จาก source ถึง FF
- **Duty cycle**: high/low pulse width
- **Power**: clock power ต้อง ≤ budget

### 5.4 Stage 4: Routing

**Objective:** เชื่อมต่อ pin ทุกตัวด้วย metal wire

**Algorithm:**
- **Global routing**: หาเส้นทางคร่าว ๆ บน routing grid
- **Track assignment**: กำหนด track ที่ใช้
- **Detailed routing**: วาด wire จริงบน metal layer

**Layers:**
- **Metal 1**: horizontal, สั้น, ใช้เชื่อมภายใน cell
- **Metal 2**: vertical
- **Metal 3-8**: สลับทิศทาง, ใช้เชื่อมข้าม chip
- **Higher metal (M9-M15)**: power grid, clock, long-distance signal

**DRC (Design Rule Check):**
- Min wire width/spacing
- Min via size/enclosure
- Antenna rule
- Metal density

**Optimization:**
- Reduce wire length
- Reduce via count
- Satisfy timing (hold in particular)
- Minimize congestion

### 5.5 Stage 5: Verification & Sign-off

**5.5.1 STA (Static Timing Analysis)**

วิเคราะห์ timing ของ *ทุก path* โดยไม่ต้อง simulate

- **Setup check**: data ต้องมาถึงก่อน clock edge
- **Hold check**: data ต้องคงที่หลัง clock edge
- **Path types**: reg-to-reg, in-to-out, in-to-reg, reg-to-out, clock-to-out

```
   Launch edge (T=0)        Capture edge (T=clk_period)
        │                            │
        ▼                            ▼
   FF_A latch data              FF_B capture data
        │      ─── delay ───►      │
        │      (data arrival)      │
        │                          │
        └────── slack = T - delay - T_setup ≥ 0  ──────┘
```

**เครื่องมือ:** PrimeTime (Synopsys), Tempus (Cadence), OpenSTA (open-source)

**5.5.2 DRC (Design Rule Check)**

ตรวจว่า layout ทุก polygon เป็นไปตามกฎของ fab

- Min width/spacing
- Enclosure rules
- Antenna rules
- Density rules

**5.5.3 LVS (Layout vs. Schematic)**

ตรวจว่า layout (GDSII) ตรงกับ schematic (netlist) หรือไม่

- Cell connectivity
- Transistor sizing
- Pin matching

**5.5.4 Power Analysis**

- **Dynamic power**: switching activity × capacitance × V² × freq
- **Static power**: leakage current × V
- **IR drop**: voltage drop บน power grid
- **Electromigration**: current density ต้องไม่เกิน

**5.5.5 Formal Verification (EC)**

เปรียบเทียบ RTL กับ netlist ว่าเทียบเท่ากันเชิงฟังก์ชัน (ไม่ต้อง simulate)

---

## 6. ASIC vs FPGA Implementation Flow – เปรียบเทียบ

| ขั้นตอน | ASIC | FPGA |
| --- | --- | --- |
| **Specification** | ✓ เหมือนกัน | ✓ เหมือนกัน |
| **RTL Design** | ✓ เหมือนกัน | ✓ เหมือนกัน |
| **RTL Verification** | ✓ เหมือนกัน | ✓ เหมือนกัน |
| **Synthesis** | Precision/Genus/DC → mapped to standard cell | Vivado/Quartus → mapped to LUT/FF |
| **Technology mapping** | Standard cell library | LUT (LookUp Table) + FF + Block RAM + DSP |
| **Place & Route** | Physical layout on silicon die | Route on programmable interconnect |
| **Bitstream** | ❌ ไม่มี | ✓ Generate .bit/.sof จาก P&R result |
| **Fabrication** | ✓ Send GDSII to fab (TSMC, Samsung) | ❌ ไม่ต้องผลิต (ใช้ chip สำเร็จรูป) |
| **NRE cost** | $1M – $100M+ (mask + design) | $0 |
| **Unit cost** | ต่ำ (volume > 100K) | สูงกว่า |
| **Performance** | สูงกว่า | ต่ำกว่า (~2-5×) |
| **Power** | ต่ำกว่า | สูงกว่า |
| **Time to market** | นาน (6-18 เดือน) | เร็ว (วัน-สัปดาห์) |

**FPGA Internal Structure:**

```
   ┌───────────────────────────────────────────────────┐
   │  I/O │ Config │ Block │ Switch    │ Config  │ I/O │
   │      │ Logic  │ RAM   │ Matrix    │ Logic   │     │
   ├──────┴────────┴───────┴───────────┴─────────┴─────┤
   │                                                   │
   │  CLB/Logic Block = LUT + FF + MUX + Carry Chain   │
   │                                                   │
   │  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐               │
   │  │ LUT │  │ LUT │  │ LUT │  │ LUT │   ← 4-LUT     │
   │  │ FF  │  │ FF  │  │ FF  │  │ FF  │               │
   │  └──┬──┘  └──┬──┘  └──┬──┘  └──┬──┘               │
   │     │        │        │        │                  │
   │  Switch Matrix (programmable interconnect)        │
   │                                                   │
   └───────────────────────────────────────────────────┘
```

**ข้อสังเกต:** ภาษา VHDL ที่เรียนในหลักสูตรนี้ ใช้ได้ทั้ง ASIC และ FPGA เพราะเป็นภาษาระดับ RTL เหมือนกัน — ต่างกันที่ backend tool เท่านั้น

---

## 7. เครื่องมือ EDA ที่เกี่ยวข้อง (Siemens EDA / Mentor Graphics + Industry)

### 7.1 Front-End Tools

| Tool | บทบาท | ผู้ผลิต |
| --- | --- | --- |
| **HDL Designer** | Block diagram, State diagram → VHDL/Verilog | Siemens EDA |
| **Questa Advanced Simulator** | Simulation, Functional Coverage, Formal | Siemens EDA |
| **ModelSim** | Simulation (ระดับเริ่มต้น) | Siemens EDA |
| **Precision RTL** | Logic Synthesis | Siemens EDA |
| **Catapult** | High-Level Synthesis | Siemens EDA |
| **Verification IP** | Protocol VIP (AXI, PCIe, USB) | หลายเจ้า |
| **SystemVerilog UVM** | Verification methodology | Accellera |

### 7.2 Back-End Tools

| Tool | บทบาท | ผู้ผลิต |
| --- | --- | --- |
| **Calibre nmDRC** | DRC | Siemens EDA |
| **Calibre nmLVS** | LVS, ERC | Siemens EDA |
| **Calibre xACT** | Parasitic Extraction (PEX) | Siemens EDA |
| **Calibre PERC** | Reliability Check (ESD, ERC) | Siemens EDA |
| **Calibre nmMod** | Power integrity (IR drop, EM) | Siemens EDA |
| **Tessent** | DFT (Scan, BIST, ATPG) | Siemens EDA |

### 7.3 Open-Source Alternatives

| Tool | บทบาท |
| --- | --- |
| **Yosys** | Synthesis |
| **OpenROAD** | Place & Route |
| **Icarus Verilog** | Verilog simulation |
| **GHDL** | VHDL simulation |
| **KLayout** | Layout viewer/editor + DRC |
| **OpenSTA** | Static timing analysis |
| **Magic** | Layout editor |
| **COCOTB** | Verification framework (Python) |

---

## 8. ตัวอย่าง End-to-End: 8-bit Counter

เพื่อให้เห็นภาพชัดเจน ลองดู 8-bit counter ผ่านทุก abstraction level

### 8.1 Behavioral (SystemC)

```cpp
SC_MODULE(counter8_sysc) {
    sc_in<bool> clk;
    sc_out<int> cnt;
    void proc() {
        int c = 0;
        while (true) {
            wait(clk.posedge_event());
            c = (c + 1) % 256;
            cnt.write(c);
        }
    }
    SC_CTOR(counter8_sysc) { SC_THREAD(proc, clk.posedge_event()); }
};
```

### 8.2 RTL (VHDL)

```vhdl
entity counter8 is
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        ce  : in  std_logic;
        cnt : out unsigned(7 downto 0)
    );
end entity;

architecture rtl of counter8 is
    signal cnt_i : unsigned(7 downto 0);
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                cnt_i <= (others => '0');
            elsif ce = '1' then
                cnt_i <= cnt_i + 1;
            end if;
        end if;
    end process;
    cnt <= cnt_i;
end architecture;
```

### 8.3 Gate-Level (Synthesized, Verilog)

```verilog
module counter8 (clk, rst, ce, cnt);
    input clk, rst, ce;
    output [7:0] cnt;

    DFFRX1 cnt_reg_0 (.CK(clk), .D(_00_), .Q(cnt[0]), .RN(rst));
    DFFRX1 cnt_reg_1 (.CK(clk), .D(_01_), .Q(cnt[1]), .RN(rst));
    ...
    AND2X1 u_and0 (.A(cnt[7]), .B(cnt[6]), .Y(_n7_));
    ...
endmodule
```

### 8.4 Physical Layout

```
  ┌─────────────────────────────────────────────────┐
  │  row 0 │ ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●│   │  ← standard cells placed
  │  row 1 │ ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●│   │
  │  row 2 │ ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●│   │
  │  ...   │ ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●│   │
  │  row N │ ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●│   │
  ├────────┴───────────────────────────────────────┴┤
  │  M1 ────── M1 ────── M1 ────── M1 ────── M1     │
  │  M2  │    │ M2  │    │    │    │ M2  │    │     │
  │  M3  ────── M3 ────── M3 ────── M3 ────── M3    │
  │   ...    (interconnect layers routing ...)      │
  └─────────────────────────────────────────────────┘
```

**สังเกต:** ทุก cell เป็น **standard cell** ที่มีความสูกึ่งกัน (row height) วางบน row ที่กำหนด wire เชื่อมต่อบน metal layer ต่าง ๆ ตามทิศทางที่ optimize แล้ว

---

## 9. ข้อควรระวังและ Common Pitfalls

### 9.1 ในชั้น RTL

- **ใช้ asynchronous reset แบบ careless** → ทำให้ recovery/removal violation
- **มี clock domain ปะปนกันโดยไม่มี synchronizer** → metastability
- **มี latch ที่ไม่ตั้งใจ** → timing analysis ยาก
- **ใช้ initial blocks ใน design** (ไม่ใช่ testbench) → ไม่ synthesize
- **ใช้ delay (#)** ใน design → ไม่ synthesize, ทำลาย portability

### 9.2 ในชั้น Synthesis

- **ไม่ใส่ constraints** → tool optimize area แทนที่จะ optimize timing
- **ใช้ '*` (don't care)** มากเกินไป → synthesis อาจเลือก implement ที่ simulation ไม่ match
- **ไม่ตรวจ generated netlist กับ RTL** → functional mismatch
- **ไม่ optimize clock gating** → power สูงเกิน budget

### 9.3 ในชั้น Physical Design

- **Macro placement ไม่ดี** → congestion, timing fail
- **Power grid ไม่พอ** → IR drop, electromigration
- **ไม่ทำ DFT** → test coverage ต่ำ, yield ต่ำ
- **ไม่ใส่ filler cell/decap** → DRC fail, IR drop

### 9.4 ในชั้น Sign-off

- **ไม่ทำ STA ทุก corner** (PVT) → silicon ไม่ทำงานในบางสภาวะ
- **ไม่ check antenna** → plasma damage ระหว่าง fab
- **ไม่ทำ power-aware STA** → false paths ระหว่าง power domain
- **ไม่ check ESD** → chip เสียง่ายต่อ static discharge

---

## 10. แนวโน้มในอนาคต

### 10.1 AI/ML-driven EDA

- **Google**: ใช้ ML หา floorplan (Nature 2021)
- **Cadence Cerebrus**: ML-driven P&R
- **Synopsys DSO.ai**: ML-driven synthesis

### 10.2 Open-Source EDA

- **OpenROAD**: full RTL-to-GDSII flow
- **Yosys + OpenROAD**: open-source ASIC flow (Skywater Shield)
- **OpenLane**: complete wrapper รอบ OpenROAD

### 10.3 Chiplet / Advanced Packaging

- **Chiplets** กลายเป็นทางเลือกแทน monolithic SoC
- **3D-IC**, **2.5D** (CoWoS, InFO)
- **UCIe**: standard สำหรับ chiplet interconnect

### 10.4 Higher-Level Design

- **High-Level Synthesis (HLS)**: C++ → RTL อัตโนมัติ
- **ML-based accelerator** design
- **Domain-Specific Architecture** (DSA): RISC-V + custom accelerator

---

## 11. สรุป Key Takeaways

1. **Digital IC Design** มีหลาย abstraction level ตั้งแต่ Algorithm จนถึง Silicon Layout
2. **RTL** คือจุดสมดุลระหว่าง productivity กับ hardware accuracy — เป็นระดับที่ใช้เขียน VHDL/Verilog
3. **Front-End (Logic Design)** เน้นฟังก์ชันและ timing — ใช้ Questa, Precision RTL
4. **Back-End (Physical Design)** เน้น placement และ routing จริง — ใช้ Innovus, OpenROAD
5. **Sign-off** ตรวจ DRC/LVS/STA/Power ก่อนส่ง fab — ใช้ Calibre, PrimeTime
6. **ASIC vs FPGA** ต่างกันที่ backend เท่านั้น — RTL เดียวกันใช้ได้ทั้งคู่
7. **Verification** สำคัญเท่ากับ design — ใช้ self-checking TB + assertions + coverage

---

## 12. อ้างอิง

- Gajski, D. D., et al. "High-Level Synthesis: Introduction to Chip and System Design." Springer, 1992.
- Smith, M. J. S. "Application-Specific Integrated Circuits." Addison-Wesley, 1997.
- Rabaey, J. M., et al. "Digital Integrated Circuits: A Design Perspective." Pearson, 2003.
- Weste, N. H. E., & Harris, D. M. "CMOS VLSI Design: A Circuits and Systems Perspective." Pearson, 2010.
- "Siemens EDA Documentation Portal" — documentation.sw.siemens.com
- TSMC, Samsung, Intel Foundry process design kits (PDKs) — สำหรับ production silicon

---

> **หมายเหตุ:** เนื้อหานี้ออกแบบให้บรรยายได้ประมาณ 90-120 นาที รวม ASCII art, table, code example ครบถ้วน พร้อมใช้ประกอบการสอนภาคทฤษฎี Day 1 หรือแทรกเป็น special topic lecture แยกต่างหาก

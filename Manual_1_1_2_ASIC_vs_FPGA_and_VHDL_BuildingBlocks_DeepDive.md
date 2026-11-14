# รายละเอียดเชิงลึก: ASIC vs FPGA และ VHDL Building Blocks

> เนื้อหานี้ออกแบบมาให้นำไปแทรกเป็นส่วนขยายในหัวข้อ **1.1.2 ASIC vs FPGA** และ **1.2 พื้นฐานภาษา VHDL** ของคู่มือหลักสูตร (วันที่ 1)
> เหมาะสำหรับการบรรยาย 120–150 นาที

---

# ส่วนที่ A: ASIC vs FPGA — เปรียบเทียบเชิงลึก

## A.1 แนวคิดพื้นฐาน

**ASIC (Application-Specific Integrated Circuit)** คือชิปที่ออกแบบมาเพื่องานเฉพาะ ผลิตจริงในโรงงานเซมิคอนดักเตอร์ (เช่น TSMC, Samsung, Intel Foundry) — เมื่อผลิตแล้ว เปลี่ยนฟังก์ชันไม่ได้

**FPGA (Field-Programmable Gate Array)** คือชิปที่ผู้ใช้สามารถ **โปรแกรมฟังก์ชันใหม่ได้เอง** หลังจากผลิตเสร็จแล้ว โดยใช้ **bitstream** ที่ generate จากเครื่องมือ EDA

ความแตกต่างที่สำคัญที่สุดคือ **"ความยืดหยุ่น"** vs **"ประสิทธิภาพ"**:

| คุณสมบัติ | ASIC | FPGA |
| --- | --- | --- |
| ความยืดหยุ่น | ต่ำ (แก้ไขไม่ได้หลังผลิต) | สูง (reprogram ได้) |
| ประสิทธิภาพ | สูง | ต่ำกว่า |
| ต้นทุนต่อหน่วย (volume) | ต่ำมาก (เมื่อผลิตจำนวนมาก) | สูงกว่า |
| Time-to-market | นาน (6-18 เดือน) | เร็ว (วัน-สัปดาห์) |

---

## A.2 สถาปัตยกรรมภายใน (Internal Architecture)

### A.2.1 ASIC – Standard Cell Based

ASIC สร้างจาก **standard cells** (เกตมาตรฐาน เช่น NAND, NOR, FF, MUX) ที่ผู้ออกแบบเลือกใช้และจัดวางเอง

```
┌──────────────────────────────────────────────────────────────┐
│  I/O Pad Ring                                                │
│  ┌────────────────────────────────────────────────────────┐  │
│  │   ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐      │  │
│  │   │ NAND│ │ NAND│ │ DFF │ │ INV │ │ INV │ │ DFF │      │  │
│  │   └─────┘ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘      │  │
│  │   ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐      │  │
│  │   │ DFF │ │ NAND│ │ NAND│ │ MUX │ │ FF  │ │ MUX │      │  │
│  │   └─────┘ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘      │  │
│  │   ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐      │  │
│  │   │SRAM │ │ ADD │ │ DFF │ │ XOR │ │ DFF │ │ FF  │      │  │
│  │   └─────┘ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘      │  │
│  │  Metal1-MetalN: Routing wires (auto-routed)            │  │
│  └────────────────────────────────────────────────────────┘  │
│  Power Grid (VDD/VSS stripes)                                │
└──────────────────────────────────────────────────────────────┘
```

**ลักษณะเด่น:**
- Cell มีความสูงคงที่ (e.g., 7-track high) — วางเรียงบน row
- Routing ใช้ metal layers หลายชั้น (5nm: ~15 layers)
- Power grid ออกแบบเอง
- Custom macro (SRAM, PLL) วางแยก

### A.2.2 FPGA – LUT-based Architecture

FPGA ใช้ **LUT (Look-Up Table)** + **FF** + **programmable interconnect** + **hard block** (BRAM, DSP, PLL)

```
┌─────────────────────────────────────────────────────────────┐
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Configuration Memory (SRAM/Flash)                   │   │
│  │  → ควบคุม LUT content และ Switch state                │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌────────┐ │
│  │ CLB     │ │ CLB     │ │ CLB     │ │ CLB     │ │ CLB    │ │ ← Configurable
│  │ ┌──┐FF  │ │ ┌──┐FF  │ │ ┌──┐FF  │ │ ┌──┐FF  │ │ ┌──┐FF │ │   Logic Block
│  │ │L │    │ │ │L │    │ │ │L │    │ │ │L │    │ │ │L │   │ │
│  │ │U │    │ │ │U │    │ │ │U │    │ │ │U │    │ │ │U │   │ │
│  │ │T │    │ │ │T │    │ │ │T │    │ │ │T │    │ │ │T │   │ │
│  │ └──┘    │ │ └──┘    │ │ └──┘    │ │ └──┘    │ │ └──┘   │ │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬───┘ │
│       └──────────┴───────────┴───────────┴────────────┘     │
│       ┌──────────────────────────────────────────┐          │
│       │ Switch Matrix (programmable interconnect)│          │
│       └──────────────────────────────────────────┘          │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐            │
│  │ BRAM 36K│ │ DSP48   │ │ BRAM 36K│ │ PLL/MMCM│            │ ← Hard blocks
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘            │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐            │
│  │ PHY     │ │ PCIe    │ │ SerDes  │ │ DDR Ctrl│            │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘            │
└─────────────────────────────────────────────────────────────┘
```

**ลักษณะเด่น:**
- LUT 4-6 inputs เก็บ truth table ใน SRAM
- FF (flip-flop) ทุก output ของ LUT
- Switch matrix ควบคุมด้วย SRAM/Flash bit
- Hard blocks (BRAM/DSP/PLL/SerDes) — silicon die-optimized, ไม่ผ่าน LUT

### A.2.3 ความแตกต่างเชิงสถาปัตยกรรม

| มิติ | ASIC | FPGA |
| --- | --- | --- |
| **Basic element** | Standard cell (NAND, NOR, FF, …) | 4-6 input LUT + FF |
| **Connection** | Metal wire (optimized) | Programmable interconnect (เสียเวลา) |
| **Logic density** | สูง (1 ASIC cell ≈ 10-15 FPGA LUTs) | ต่ำ |
| **Clock distribution** | Custom tree (low skew) | Global clock network (fixed) |
| **Memory** | Custom SRAM, register file | BRAM (Block RAM, 18Kb/36Kb) |
| **Special blocks** | Custom analog/pipelined, macros | Hard IP (DSP, PCIe, SerDes) |

---

## A.3 ต้นทุน (Cost Analysis)

### A.3.1 ต้นทุน ASIC

```
Total Cost = NRE + (Unit_Cost × Volume)
NRE = Design_Cost + Mask_Cost + Test_Cost
Unit_Cost = Wafer_Cost / (Wafer_Size × Die_per_Wafer × Yield)
```

**ตัวอย่าง Mask Cost (TSMC):**

| Process | Mask Set Cost (USD) |
| --- | --- |
| 180 nm | $0.5 – 1M |
| 65 nm | $1 – 2M |
| 28 nm | $3 – 5M |
| 16 nm | $5 – 10M |
| 7 nm | $15 – 30M |
| 5 nm | $25 – 50M |
| 3 nm | $50 – 100M+ |

**Break-Even Point:**

```
   Cost ($)
   │       ────── ASIC (declining with volume)
   │     ╱
   │    ╱
   │   ╱
   │  ╱───────── FPGA (constant)
   │ ╱
   │╱
   └────────────────────────► Volume
                ▲
              Break-even
              (typically 1K – 100K units)
```

**ข้อสังเกต:**
- ASIC คุ้มเมื่อ volume ≥ 10K–100K units (ขึ้นกับ node)
- FPGA เหมาะกับ volume ต่ำ (< 1K), prototype, หรืองานที่ต้อง update บ่อย
- บางครั้งใช้ **ASIC conversion** — ออกแบบด้วย FPGA แล้วแปลงเป็น ASIC เมื่อผลิตจริง

### A.3.2 ต้นทุน FPGA

| รายการ | ต้นทุน |
| --- | --- |
| FPGA chip | $10 – $10,000+ ขึ้นกับขนาด/performance |
| Development board | $100 – $5,000 |
| Tool license | $0 – $10,000+ (free for Vivado WebPack) |
| **Total per unit** | คงที่, ไม่ขึ้นกับ volume |

---

## A.4 ประสิทธิภาพ (Performance)

### A.4.1 ความเร็ว (Clock Frequency)

| Process | ASIC fmax | FPGA fmax (LUT6) | Ratio |
| --- | --- | --- | --- |
| 28 nm | 1.0 – 1.5 GHz | 200 – 400 MHz | ~3-5× |
| 16 nm | 1.5 – 2.0 GHz | 300 – 500 MHz | ~4× |
| 7 nm | 2.5 – 4.0 GHz | 400 – 600 MHz | ~5-6× |

### A.4.2 เหตุผลที่ ASIC เร็วกว่า

1. **Direct connection** — metal wire มี delay ต่ำกว่า programmable interconnect
2. **No LUT overhead** — ไม่ต้องผ่าน truth table
3. **Custom cell sizing** — เลือก drive strength เหมาะสมกับ load
4. **Better placement** — P&R tool ย้าย cell ได้อิสระ
5. **No switch matrix delay** — signal เดินทางตรง

### A.4.3 พลังงาน (Power)

| Metric | ASIC | FPGA |
| --- | --- | --- |
| Static power | ต่ำมาก (few mW) | สูง (hundreds of mW – W) |
| Dynamic power | ต่ำ (no unused gates) | สูง (programmable fabric มี switching activity สูง) |
| Total power @ same workload | 1× | 5-15× |

**ตัวอย่าง:** Edge AI inference:
- ASIC (e.g., Google Edge TPU): 2 W, 4 TOPS/W
- FPGA (e.g., Xilinx Zynq): 5-15 W, 0.5-1.5 TOPS/W

### A.4.4 Latency

| Metric | ASIC | FPGA |
| --- | --- | --- |
| Determinism | สูง (delay ทุก path รู้แน่ชัด) | ปานกลาง (depends on routing) |
| Pipeline latency | ต่ำกว่า (custom pipeline) | สูงกว่า (LUT + interconnect delay) |
| Tail latency | ดี | แย่กว่า |

---

## A.5 Use Cases & Application Examples

### A.5.1 เมื่อควรใช้ ASIC

| Application | เหตุผล |
| --- | --- |
| **CPU/GPU** (Intel, AMD, NVIDIA) | Volume สูงมาก, performance สำคัญ |
| **Mobile SoC** (Apple A-series, Qualcomm Snapdragon) | Power budget เข้มงวด, performance/W สำคัญ |
| **AI Accelerators** (Google TPU, Apple Neural Engine) | Throughput สูง, power efficiency |
| **Networking ASIC** (Broadcom Tomahawk) | Throughput สูง 100+ Gbps |
| **Crypto ASIC** (Bitcoin miners) | Performance ต่อ W สำคัญมาก |
| **PMIC, RF** (Power management, WiFi/BT) | Analog integration, ultra-low power |
| **Automotive ECU** (Critical functions) | Reliability, deterministic |

### A.5.2 เมื่อควรใช้ FPGA

| Application | เหตุผล |
| --- | --- |
| **Prototype** ของ ASIC | Validate ก่อน tape-out |
| **Low-volume production** (< 1K/year) | Mask cost ไม่คุ้ม |
| **Evolving standards** (5G, WiFi 7) | Update ได้หลัง deploy |
| **DSP/Image processing** | Custom datapath, parallel processing |
| **Aerospace/Defense** | ต้อง update บ่อย, ปริมาณน้อย |
| **Test equipment** (oscilloscope, logic analyzer) | ต้อง reconfigure |
| **HPC/Research** | algorithm เปลี่ยนบ่อย |

### A.5.3 ตัวอย่างจริง

| Product | Type | Volume/Year | Reason |
|---|---|---|---|
| Apple M2 Ultra | ASIC (TSMC 5nm) | ~50M units | Performance + cost |
| Samsung Galaxy SoC | ASIC | ~100M units | Power + perf |
| Bitcoin miner (Antminer) | ASIC | 100K-1M units | Energy efficiency |
| DeepMind TPU | ASIC | Google internal | Custom acceleration |
| 5G base station prototype | FPGA | < 1K | Iterate standard |
| Autonomous vehicle prototype | FPGA + GPU | Low volume | Validation |
| Car ECU (production) | ASIC | >10M | Safety + cost |
| Aerospace controller | FPGA (rad-hard) | 1K | Radiation + ITAR |

---

## A.6 ASIC vs FPGA: Decision Matrix

**คำถามเพื่อตัดสินใจ:**

| คำถาม | ถ้า ASIC | ถ้า FPGA |
| --- | --- | --- |
| Volume > 100K units/year? | ✓ เหมาะ | |
| Power budget ≤ 5 W? | ✓ | |
| Performance ต้อง > 500 MHz? | ✓ | |
| Time-to-market ≤ 3 months? | | ✓ |
| ต้อง update algorithm หลัง deploy? | | ✓ |
| Standard ยังเปลี่ยนแปลง? | | ✓ |
| Volume < 1K units/year? | | ✓ |
| Budget ต้นแบบ < $100K? | | ✓ |

**คำตอบที่แนะนำ:**
- **Prototype Phase**: FPGA (เร็ว, ถูก, แก้ไขง่าย)
- **Production Phase**: ASIC ถ้า volume ≥ 10K, FPGA ถ้า volume ต่ำหรือต้อง update
- **Hybrid**: FPGA + Soft IP ของ Integration (เช่น embedded RISC-V core)

---

## A.7 Hybrid: FPGA + ASIC + Chiplet

ในปัจจุบันมีทางเลือกที่ 3 — **Chiplets**:

```
┌─────────────────────────────────┐
│  Package / Interposer           │
│  ┌──────────┐ ┌──────────────┐  │
│  │ Chiplet  │ │  Chiplet     │  │
│  │ (CPU)    │ │  (AI accel)  │  │
│  │ ASIC 5nm │ │  ASIC 5nm    │  │
│  └──────────┘ └──────────────┘  │
│  ┌──────────┐ ┌──────────────┐  │
│  │ Chiplet  │ │  FPGA        │  │
│  │ (I/O)    │ │(programmable)│
│  │ ASIC     │ │  Xilinx      │  │
│  └──────────┘ └──────────────┘  │
│  UCIe / BoW / AIB interconnect  │
└─────────────────────────────────┘
```

**ข้อดี**: ใช้ ASIC สำหรับ performance-critical part, FPGA สำหรับ flexibility-critical part

---

## A.8 ตารางเปรียบเทียบแบบ Summary

| เกณฑ์ | ASIC | FPGA | Winner |
|---|---|---|---|
| **Performance** | สูง | ปานกลาง | ASIC |
| **Power efficiency** | สูง | ต่ำ | ASIC |
| **Cost (low volume)** | ต่ำ (NRE สูง) | สูง (unit สูง) | FPGA |
| **Cost (high volume)** | ต่ำมาก | สูง | ASIC |
| **Time-to-market** | นาน | เร็ว | FPGA |
| **Flexibility** | ต่ำ | สูง | FPGA |
| **Integration** | สูง (mixed-signal, RF) | จำกัด (digital) | ASIC |
| **NRE Cost** | $1M - $100M | $0 | ESP |
| **Risk** | สูง (mask) | ต่ำ | FPGA |

---

# ส่วนที่ B: VHDL Building Blocks — รายละเอียดเชิงลึก

## B.1 โครงสร้างไฟล์ VHDL (File Structure)

ไฟล์ VHDL ที่ถูกต้องตามมาตรฐาน IEEE 1076 ประกอบด้วย **5 ส่วนหลัก** (บางส่วน optional):

```
┌──────────────────────────────────────────────────────┐
│ 1. Library Clause (use clause)                       │  ← เรียกใช้ไลบรารี
│    use IEEE.STD_LOGIC_1164.ALL;                      │
├──────────────────────────────────────────────────────┤
│ 2. Entity Declaration                                │  ← "หน้าต่าง" ของโมดูล
│    entity name is                                    │
│        port ( ... );                                 │
│    end entity;                                       │
├──────────────────────────────────────────────────────┤
│ 3. Architecture Body                                 │  ← "ตัวถัง" ภายใน
│    architecture rtl of name is                       │
│           -- declarations                            │
│        begin                                         │
│            -- concurrent statements                  │
│        end architecture;                             │
├──────────────────────────────────────────────────────┤
│ 4. Configuration (optional)                          │  ← เลือก architecture
│    for <inst> : <entity> use <arch>;                 │
├──────────────────────────────────────────────────────┤
│ 5. Package (optional, มักแยกไฟล์)                     │  ← เก็บ types/constants
│    package pkg_name is                               │
│        ...                                           │
│    end package;                                      │
└──────────────────────────────────────────────────────┘
```

---

## B.2 Entity (รายละเอียดเชิงลึก)

### B.2.1 Entity Declaration Syntax

```vhdl
entity entity_name is
    [generic ( ... );]  -- parameters
    [port ( ... );]     -- I/O ports
end [entity] [entity_name];
```

### B.2.2 Port Modes

| Mode | ทิศทาง | ใช้ใน | ตัวอย่าง |
| --- | --- | --- | --- |
| `in` | เข้ามา | Top-level input | `clk`, `rst`, `data_in` |
| `out` | ออกไป | Top-level output, internal FF out (ไม่อ่านกลับ) | `data_out`, `flag` |
| `inout` | เข้า-ออกได้ | Tri-state bus, bidirectional pin | `data_bus`, `sda` (I2C) |
| `buffer` | ออก + อ่านกลับได้ภายใน | Output ที่ต้อง feedback ภายใน | Internal FF output (rare) |

**ข้อสังเกต:**
- `out` mode ไม่สามารถอ่านภายในได้ — ใช้ `buffer` หรือสร้าง internal signal
- `inout` ใช้กับ bus ภายนอก — ต้องระวังเรื่อง driver contention

### B.2.3 Port Types

| Type | Range | ใช้เมื่อ |
| --- | --- | --- |
| `std_logic` | 9 values (U, X, 0, 1, Z, W, L, H, -) | 1-bit signal |
| `std_logic_vector(N downto 0)` | Vector | Multi-bit bus |
| `std_ulogic` | ไม่มี resolution function (unresolved) | Internal signal (no bus) |
| `unsigned`, `signed` | ตัวเลข | Arithmetic operations |
| `integer` | 32-bit default | Loop counter, parameter |
| `boolean` | TRUE/FALSE | Conditional |
| `time` | ps, ns, us, ms, sec, min, hr | Wait statements (testbench) |

### B.2.4 Generic (Parameters)

```vhdl
entity mux2x1_param is
    generic (
        WIDTH : integer := 4;        -- default value
        INIT  : std_logic := '0'
    );
    port (
        a, b : in  std_logic_vector(WIDTH-1 downto 0);
        sel  : in  std_logic;
        y    : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity;
```

**ใช้เมื่อต้องการ reusable IP**:
```vhdl
u_mux : entity work.mux2x1_param
    generic map (WIDTH => 8, INIT => '1')
    port map (a, b, sel, y);
```

---

## B.3 Architecture (รายละเอียดเชิงลึก)

Architecture มี **3 styles** หลัก บางครั้งผสมกัน:

### B.3.1 Behavioral Style

อธิบาย *พฤติกรรม* ด้วย process, if, case, loop

```vhdl
architecture behavioral of mux2x1 is
begin
    process (a, b, sel)
    begin
        case sel is
            when '0'   => y <= a;
            when '1'   => y <= b;
            when others => y <= 'X';   -- default ป้องกัน latch
        end case;
    end process;
end architecture;
```

**ข้อดี:**
- อ่านง่าย, เขียนเร็ว
- เหมาะกับ FSM, algorithm

**ข้อเสีย:**
- อาจเกิด latch ถ้าไม่ใส่ default
- ควบคุม timing ยาก

### B.3.2 Dataflow Style

อธิบายด้วย *concurrent expression* ใช้ boolean operator

```vhdl
architecture dataflow of mux2x1 is
begin
    y <= a when sel = '0' else
         b when sel = '1' else
         'X';
end architecture;
```

**ข้อดี:**
- ไม่มี latch (มี else clause ครบ)
- ควบคุม timing ได้ดี (tool รู้ว่าเป็น MUX)

**ข้อเสีย:**
- เขียนยากสำหรับ logic ซับซ้อน

### B.3.3 Structural Style

ประกอบ component ย่อย ๆ

```vhdl
architecture struct of adder4 is
    component full_adder is
        port (a, b, cin : in std_logic; sum, cout : out std_logic);
    end component;
    signal c : std_logic_vector(4 downto 0);
begin
    c(0) <= cin;
    u0 : full_adder port map (a(0), b(0), c(0), sum(0), c(1));
    u1 : full_adder port map (a(1), b(1), c(1), sum(1), c(2));
    u2 : full_adder port map (a(2), b(2), c(2), sum(2), c(3));
    u3 : full_adder port map (a(3), b(3), c(3), sum(3), c(4));
    cout <= c(4);
end architecture;
```

**ข้อดี:**
- Hierarchy ชัดเจน
- เหมาะกับ reusable IP

**ข้อเสีย:**
- ต้อง declare component (VHDL-93) หรือใช้ entity instantiation (VHDL-2008)

### B.3.4 Mixed Style

```vhdl
architecture mixed of top is
    -- Behavioral
    process (clk) ... end process;

    -- Dataflow
    sum <= a + b when sel = '0' else a - b;

    -- Structural
    u_mem : entity work.memory port map (...);
end architecture;
```

---

## B.4 Process (พื้นฐานสำคัญที่สุด)

### B.4.1 Process Syntax

```vhdl
process_label : process (sensitivity_list)
    -- declarations (variable only)
    variable var1 : type;
begin
    -- sequential statements
    wait_statement;
    if_statement;
    case_statement;
    loop_statement;
end process;
```

### B.4.2 Sensitivity List

**กฎ**: ทุกสัญญาณที่ process อ่านในเงื่อนไขต้องอยู่ใน sensitivity list (ยกเว้าใช้ `wait until`)

```vhdl
-- ถูก: มี a, b, sel ใน list
process (a, b, sel)
begin
    if sel = '1' then y <= a;
    else             y <= b;
    end if;
end process;

-- VHDL-2008: ใช้ all แทนได้
process (all)
begin
    if sel = '1' then y <= a;
    else             y <= b;
    end if;
end process;
```

### B.4.3 Process ประเภทต่าง ๆ

**1. Combinational Process** — ใช้ sensitivity list ครบ

```vhdl
process (a, b, sel)
begin
    if sel = '1' then y <= a;
    else             y <= b;
    end if;
end process;
```

**2. Sequential (Clocked) Process** — ใช้ rising_edge / falling_edge

```vhdl
process (clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            q <= '0';
        else
            q <= d;
        end if;
    end if;
end process;
```

**3. Latch Process** — ใช้ wait until

```vhdl
process
begin
    wait until rising_edge(clk);
    q <= d;
end process;
```

---

## B.5 Signal vs Variable

### B.5.1 ความแตกต่างเชิงลึก

| คุณสมบัติ | Signal | Variable |
| --- | --- | --- |
| **ที่ประกาศ** | Architecture (outside process) หรือ Package | Process, Function, Procedure |
| **Update timing** | End of process (delta cycle) | ทันที (same line) |
| **Synthesizable?** | ✓ Yes (กลายเป็น wire/FF) | ✗ No (เป็น local scratch) |
| **Scope** | ทั่วทั้ง architecture | ภายใน process/subprogram เท่านั้น |
| **Default initial** | ไม่มี | ไม่มี |

### B.5.2 ตัวอย่างความแตกต่าง

```vhdl
architecture demo of sig_var_demo is
    signal sig_x : std_logic := '0';
begin
    process (a, b)
        variable var_y : std_logic := '0';
    begin
        -- Variable: update ทันที
        var_y := a and b;
        -- Signal: update ที่ end of process
        sig_x <= a or b;

        -- ตัวอย่าง: variable อ่านได้ทันที, signal อ่านได้รอบถัดไป
        z1 <= var_y;     -- = a and b รอบนี้
        z2 <= sig_x;      -- = a or b จากรอบก่อน
    end process;
end architecture;
```

### B.5.3 เมื่อใดใช้ Variable vs Signal

| ใช้ Variable เมื่อ | ใช้ Signal เมื่อ |
| --- | --- |
| ต้องการ scratch variable ใน process | ต้องการ output ไปยัง port หรือ architecture |
| คำนวณ intermediate value | สื่อสารระหว่าง process |
| Loop counter ภายใน | FF state, registered output |

---

## B.6 Data Types (รายละเอียดเชิงลึก)

### B.6.1 Predefined Types

**Scalar types:**

| Type | Values | ใช้ |
| --- | --- | --- |
| `bit` | `'0'`, `'1'` | Simple boolean |
| `boolean` | `FALSE`, `TRUE` | Conditional, function return |
| `integer` | -2^63 to 2^63-1 | Counter, parameter |
| `real` | Floating-point | Delay specification |
| `time` | ps/fs/ms/... | Wait statement (testbench) |
| `character` | ASCII | String |
| `severity_level` | NOTE/WARNING/ERROR/FAILURE | Report severity |

**Composite types:**

| Type | ใช้ |
| --- | --- |
| `bit_vector(N downto 0)` | Vector of bit |
| `string` | Array of character |
| `std_logic_vector` (IEEE) | Standard vector |
| `unsigned`, `signed` (IEEE) | Arithmetic |

### B.6.2 IEEE Standard Types (ใช้บ่อยที่สุด)

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;  -- std_logic, std_logic_vector
use IEEE.NUMERIC_STD.ALL;      -- unsigned, signed, conversion
use IEEE.NUMERIC_BIT.ALL;       -- bit-based numeric (rare)
use IEEE.STD_LOGIC_TEXTIO.ALL;  -- text I/O (testbench)
use IEEE.STD_LOGIC_UNSIGNED.ALL; -- เก่า, ห้ามใช้
```

**std_logic values:**

| Value | ความหมาย |
| --- | --- |
| `'U'` | Uninitialized (simulation only) |
| `'X'` | Unknown (driving multiple values) |
| `'0'` | Logic 0 |
| `'1'` | Logic 1 |
| `'Z'` | High-impedance (tri-state) |
| `'W'` | Weak unknown |
| `'L'` | Weak 0 |
| `'H'` | Weak 1 |
| `'-'` | Don't care (synthesis optimization) |

### B.6.3 User-Defined Types

```vhdl
-- Enumeration type (ใช้สำหรับ FSM state)
type state_t is (IDLE, RUN, DONE, ERROR);
signal state : state_t;

-- Array type
type memory_t is array (0 to 255) of unsigned(7 downto 0);
signal mem : memory_t;

-- Record type (ใช้จัดกลุ่ม)
type packet_t is data(struct
    header : byte
    data : bit_vector(7 downto 0);
    crc  : unsigned(15 downto 0)
);
```

### B.6.4 Subtypes

```vhdl
subtype byte_t is unsigned(7 downto 0);  -- 8-bit unsigned
subtype word_t is unsigned(15 downto 0); -- 16-bit unsigned

signal data_byte : byte_t;
signal data_word : word_t;
```

### B.6.5 Type Conversion

```vhdl
-- unsigned ↔ std_logic_vector
signal u : unsigned(7 downto 0);
signal s : std_logic_vector(7 downto 0);
s <= std_logic_vector(u);
u <= unsigned(s);

-- unsigned ↔ integer
u <= to_unsigned(255, 8);
assert(u) = to_integer(u);
```

---

## B.7 Concurrent vs Sequential Statements

### B.7.1 Concurrent Statements (รันพร้อมกัน)

- `concurrent_signal_assignment`
- `process`
- `component instantiation`
- `generate`
- `block`

### B.7.2 Sequential Statements (รันตามลำดับภายใน process)

- `if`, `elsif`, `else`
- `case`, `when`
- `for`, `while`, `loop`
- `next`, `exit`
- `assert`, `report`
- `wait`
- `return` (ใน function)

---

## B.8 Component Instantiation

### B.8.1 Component Declaration (VHDL-1993 style)

```vhdl
architecture struct of top is
    component my_submodule is
        port (
            clk : in  std_logic;
            din : in  std_logic_vector(7 downto 0);
            dout : out std_logic_vector(7 downto 0)
        );
    end component;
begin
    u1 : my_submodule port map (
        clk  => clk,
        din  => data_in,
        dout => sub_out
    );
end architecture;
```

### B.8.2 Entity Instantiation (VHDL-2008 style — แนะนำ)

```vhdl
u1 : entity work.my_submodule
    port map (
        clk  => clk,
        din  => data_in,
        dout => sub_out
    );
```

**ข้อดีของ entity instantiation:**
- ไม่ต้องประกาศ component
- รู้ entity ทันที (compiler check)
- สนับสนุน generic map โดยตรง

### B.8.3 Port Map Styles

**Positional:**
```vhdl
u1 : my_sub port map (clk, din, dout);  -- ตามลำดับ entity port
```

**Named:**
```vhdl
u1 : my_sub port map (clk => clk, din => data_in, dout => sub_out);
```

**Mixed:**
```vhdl
u1 : my_sub port map (clk, din, dout => sub_out);
```

**คำแนะนำ:** ใช้ named map เสมอ ป้องกันการสับเปลี่ยน port

---

## B.9 Generate Statement (สำหรับ Structural Repetition)

```vhdl
-- For-generate (static)
gen_n : for i in 0 to 7 generate
    u : full_adder port map (a(i), b(i), c(i), sum(i), c(i+1));
end generate;

-- If-generate (conditional)
gen_optional : if WIDTH > 8 generate
    u_extra : entity work.extra_logic port map (...);
end generate;
```

**ตัวอย่าง: 8-bit Ripple Carry Adder**

```vhdl
architecture struct of adder8 is
    signal c : std_logic_vector(8 downto 0);
begin
    c(0) <= cin;
    gen_fa : for i in 0 to 7 generate
        u_fa : entity work.full_adder_struct
            port map (
                a    => a(i),
                b    => b(i),
                cin  => c(i),
                sum  => sum(i),
                cout => c(i+1)
            );
    end generate;
    cout <= c(8);
end architecture;
```

---

## B.10 Package

ใช้เก็บ types, constants, functions, components ที่ reuse ได้

```vhdl
-- File: my_pkg.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package my_pkg is
    -- Constants
    constant DATA_WIDTH : integer := 8;
    constant FIFO_DEPTH : integer := 16;

    -- Types
    type fifo_state_t is (EMPTY, PARTIAL, FULL);

    -- Function declarations
    function to_gray(x : unsigned) return unsigned;

    -- Component declarations
    component fifo_module is
        generic (DEPTH : integer := 16);
        port (clk, rst : in std_logic; ...);
    end component;
end package;
```

**เรียกใช้:**

```vhdl
library work;
use work.my_pkg.ALL;

architecture rtl of design is
    signal state : fifo_state_t;  -- ใช้ type จาก package
    signal data  : std_logic_vector(DATA_WIDTH-1 downto 0);  -- ใช้ constant
begin
    -- ...
end architecture;
```

---

## B.11 Function และ Procedure

### B.11.1 Function (return value)

```vhdl
function parity(x : unsigned) return std_logic is
    variable p : std_logic := '0';
begin
    for i in x'range loop
        p := p xor x(i);
    end loop;
    return p;
end function;

-- ใช้
y <= parity(data);
```

### B.11.2 Procedure (ไม่ return, side-effect ได้)

```vhdl
procedure check_data(
    signal data : in  std_logic_vector;
    signal flag  : out std_logic
) is
begin
    flag <= '1' when data = (data'range => '1') else '0';
end procedure;

-- ใช้
check_data(my_signal, ready_flag);
```

**ข้อแตกต่าง:**

| Function | Procedure |
| --- | --- |
| Return single value  | 否 return, multiple out |
| ใช้ใน expression | ใช้เป็น statement |
| No side effect (pure)  | มี side effect ได้ |

---

## B.12 Configuration (เลือก Architecture)

หนึ่ง entity สามารถมีหลาย architecture ได้:

```vhdl
entity alu is
    port (a, b : in  ...; y : out ...);
end entity;

architecture fast of alu is ...;  -- optimized for speed
architecture low_pwr of alu is ...; -- optimized for power
```

**เลือก architecture:**

```vhdl
configuration fast_cfg of top is
    for u_alu : alu
        use entity alu(fast);  -- เลือก 'fast'
    end for;
end configuration;
```

---

## B.13 Attributes (ข้อมูลเพิ่มเติมของ Signal/Type)

| Attribute | ความหมาย | ตัวอย่าง |
| --- | --- | --- |
| `T'low` | ค่าต่ำสุด | `bit'low = '0'` |
| `T'high` | ค่าสูงสุด | `bit'high = '1'` |
| `T'left` | left index | `s'left = 7` (for 7 downto 0) |
| `T'right` | right index | `s'right = 0` |
| `T'range` | full range | `s'range = 7 downto 0` |
| `T'reverse_range` | reversed | `s'reverse_range = 0 to 7` |
| `T'length` | จำนวน element | `s'length = 8` |

**ตัวอย่างการใช้:**

```vhdl
signal s : std_logic_vector(7 downto 0);
-- s'low = 0, s'high = 7, s'left = 7, s'right = 0, s'length = 8

-- Loop ที่ใช้ attribute (parameterized)
process (s)
begin
    for i in s'range loop
        if s(i) = '1' then
            count <= count + 1;
        end if;
    end loop;
end process;
```

---

## B.14 ตัวอย่างรวม: Reusable Shift Register

```vhdl
-- Generic N-bit shift register with synchronous reset
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity shift_reg is
    generic (
        WIDTH : integer := 8
    );
    port (
        clk    : in  std_logic;
        rst    : in  std_logic;
        load   : in  std_logic;
        din    : in  std_logic_vector(WIDTH-1 downto 0);
        shift  : in  std_logic;
        sin     : in  std_logic;                   -- serial in
        dout   : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity shift_reg;

architecture rtl of shift_reg is
    signal reg : std_logic_vector(WIDTH-1 downto 0);
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                reg <= (others => '0');
            elsif load = '1' then
                reg <= din;
            elsif shift = '1' then
                reg <= reg(WIDTH-2 downto 0) & sin;
            end if;
        end if;
    end process;

    dout <= reg;
end architecture;
```

---

## B.15 Best Practices สำหรับ VHDL

### B.15.1 Coding Style ที่ดี

✅ **DO:**
- ใช้ synchronous reset ทุกบล็อก
- ใส่ default assignment ทุก combinational process
- ใช้ named port map
- ใช้ generic สำหรับ parameter (WIDTH, DEPTH)
- แยก package สำหรับ shared types/constants
- ใช้ IEEE.STD_LOGIC_1164 และ IEEE.NUMERIC_STD เท่านั้น

❌ **DON'T:**
- ห้ามใช้ `initial` ใน design (เฉพาะ testbench)
- ห้ามใช้ `wait for` ใน design (ใช้ได้เฉพาะ testbench)
- ห้ามมี latch ที่ไม่ตั้งใจ
- ห้ามใช้ std_logic_arith, std_logic_unsigned (deprecated)
- ห้ามใช้ `wait until X` ที่ไม่ใช่ rising_edge/falling_edge

### B.15.2 Naming Convention (แนะนำ)

| ประเภท | Convention | ตัวอย่าง |
| --- | --- | --- |
| Signal | snake_case | `data_in`, `clk_div`, `valid_flag` |
| Variable | `_` prefix หรือ camelCase | `_temp`, `tempValue` |
| Constant | UPPER_CASE | `FIFO_DEPTH`, `CLK_FREQ` |
| Entity/Architecture | ขึ้นต้นตัวใหญ่ | `UartTx`, `MemoryController` |
| Component instance | `u_` prefix | `u_counter`, `u_alu` |
| Process label | `p_` prefix | `p_sync`, `p_combinational` |

### B.15.3 Lint Checks ที่ควรทำ

1. **Latch check**: ทุก process ต้องมี default
2. **Sensitivity list**: ครบถ้วน (VHDL-2008 ใช้ `process(all)` ได้)
3. **Clock domain**: ทุก FF ต้องระบุ clock domain
4. **Reset strategy**: synchronous ทุก FF
5. **Unused signal**: lint warning

---

## B.16 สรุปเปรียบเทียบ ASIC vs FPGA ในเชิง VHDL

| มิติ | ASIC | FPGA |
| --- | --- | --- |
| **VHDL code** | เหมือนกัน | เหมือนกัน |
| **Synthesizable subset** | Strict | More lenient (มี inferred primitives เช่น BRAM, DSP) |
| **Vendor-specific attributes** | Standard SDC | Xilinx/Intel/Achronix-specific (e.g., `(* ram_style = "block" *)`) |
| **Resource utilization** | Standard cell count | LUT, FF, BRAM, DSP count |
| **Timing constraint** | SDC file | XDC/UCF file |

**ตัวอย่าง FPGA-specific attribute (Xilinx):**

```vhdl
-- บอก synthesizer ว่าให้ใช้ BlockRAM แทน LUT
(* ram_style = "block" *) signal mem : std_logic_vector(15 downto 0);
(* ram_style = "distributed" *) signal mem : std_logic_vector(15 downto 0);  -- use LUT

-- Pipeline attribute
(* dont_touch = "true" *) signal my_reg : std_logic;
```

---

## B.17 สรุป Key Takeaways

1. **ASIC vs FPGA**: ต่างกันที่ backend, RTL/VHDL เดียวกันใช้ได้ทั้งคู่
2. **ASIC**: ประสิทธิภาพสูง, ต้นทุนต่ำ (volume สูง), แต่ NRE สูงและไม่ยืดหยุ่น
3. **FPGA**: ยืดหยุ่น, time-to-market เร็ว, เหมาะ prototype และ volume ต่ำ
4. **VHDL Building Blocks**: Entity (I/O), Architecture (behavior), Process (sequential), Package (reuse)
5. **Coding Style**: synchronous, default assignments, named port maps, IEEE-standard libraries
6. **Signal vs Variable**: Signal = hardware wire, Variable = simulation scratch

---

## B.18 อ้างอิง

- Ashenden, P. J. "The Designer's Guide to VHDL." Morgan Kaufmann, 2008.
- IEEE Std 1076-2008, "VHDL Language Reference Manual."
- IEEE Std 1076.4-2000, "VHDL Synthesis Package."
- Pedroni, V. A. "Circuit Design with VHDL." MIT Press, 2004.
- Xilinx UG8855352, "Vivado Design Suite User Guide."
- "Siemens EDA HDL Designer User Manual."

---

> **หมายเหตุ:** เนื้อหานี้ออกแบบให้บรรยายได้ประมาณ 120-150 นาที รวมตัวอย่างโค้ดครบถ้วน พร้อมใช้ประกอบการสอนภาคทฤษฎี Day 1 หรือแทรกเป็น 2 lectures แยก (ASIC vs FPGA 1 ชม., VHDL Building Blocks 1 ชม.)

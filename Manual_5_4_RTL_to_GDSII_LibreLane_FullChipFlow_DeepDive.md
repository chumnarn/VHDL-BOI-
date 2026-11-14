# รายละเอียดเชิงลึก: RTL-to-GDSII Full Chip Flow ด้วย LibreLane

> เนื้อหานี้ออกแบบมาให้นำไปแทรกเป็นส่วนขยายในหัวข้อ **5.4 ภาคทฤษฎี: RTL-to-GDSII Full Chip Flow (Open-source)** ของคู่มือหลักสูตร (วันที่ 5)
>
> เหมาะสำหรับการบรรยาย **90–120 นาที** พร้อม ASCII diagrams, ตารางเปรียบเทียบ, ตัวอย่างคำสั่งจริง และผลลัพธ์จริงจากการรันบนเครื่อง
>
> **ทุกตัวเลขในเอกสารนี้มาจากการรันจริง** บน Yosys 0.52 / LibreLane v3.0.17 / PDK sky130A — ไม่มีการประมาณค่า

---

## สารบัญ

| # | หัวข้อ | หน้าเนื้อหา |
| --- | --- | --- |
| 1 | ทำไมวันที่ 5 ต้องมี Full Chip Flow | จาก netlist สู่ชิปที่ส่ง foundry ได้ |
| 2 | ภาพรวม RTL-to-GDSII | เส้นทางจาก RTL ถึง GDSII ผ่านเครื่องมืออะไรบ้าง |
| 3 | LibreLane คืออะไร | จาก OpenLane สู่ LibreLane 3.x + โครงสร้าง flow |
| 4 | 80 stages แบ่งเป็นอะไรบ้าง | เห็นกระบวนการทั้งหมดแบบมีชื่อ |
| 5 | Floorplan | core area, die area, utilization คำนวณอย่างไร |
| 6 | Placement | global placement → detailed placement → legalisation |
| 7 | Clock Tree Synthesis (CTS) | ทำไม clock ต้องมี buffer tree |
| 8 | Routing | global → detailed, DRC ของ routing |
| 9 | Power Distribution Network | M1/M2 ซ้อนกัน, VDD/VSS |
| 10 | Sign-off: DRC / LVS / Antenna | สามเรื่องที่ foundry จะตรวจก่อนรับงาน |
| 11 | Static Timing Analysis | setup / hold, ทุก corner, Fmax |
| 12 | อ่านผลลัพธ์จาก `metrics.json` | key ที่ต้องรู้ทั้งหมด |
| 13 | ไฟล์ผลลัพธ์ทั้งหมด | GDS, LEF, DEF, MAG, SPICE, SPEF, SDF |
| 14 | Multi-corner analysis | 9 corners, 3 SPEF |
| 15 | Yosys เปลี่ยนโครงสร้าง design เอง | one-hot FSM — บทเรียนจากการรันจริง |
| 16 | จาก RTL เดียวกันสู่ชิป 2 ขนาด | เปรียบเทียบ adder กับ UART |
| 17 | ผลอ้างอิงจากการรันจริง | ตัวเลขทั้งหมดของ UART TX |
| 18 | Troubleshooting | ปัญหาที่พบบ่อย |
| 19 | แบบฝึกหัดและ Checklist | ปิดหัวข้อ |

---

## 1. ทำไมวันที่ 5 ต้องมี Full Chip Flow

วันที่ 3 สอถึง **netlist** — ผลลัพธ์ของการสังเคราะห์ ซึ่งยังไม่ใช่ "ชิป"
วันที่ 5 เป็น Mini Project ที่ต้องส่งงานได้จริง จึงต้องต่อจาก netlist ไปจนถึง **GDSII**

```
    Day 3                          Day 5
    ────                          ────
    RTL ──► netlist               RTL ──► netlist ──► layout ──► GDSII
         (Precision RTL / Yosys)                  ▲
                                                  │
                                    ┌─────────────┴─────────────┐
                                    │  Floorplan → P&R → DRC/LVS │
                                    │  OpenROAD · Magic · KLayout │
                                    │  Netgen                    │
                                    └───────────────────────────┘
```

### 1.1 ช่องว่างของการสังเคราะห์อย่างเดียว

| สิ่งที่ได้จาก RTL Synthesis | สิ่งที่ยังขาดก่อนส่ง foundry |
| --- | --- |
| netlist ของ standard cell | ตำแหน่งจริงของ cell บนซิลิกอน (placement) |
| พื้นที่โดยประมาณ (cell area) | การเชื่อมต่อด้วยโลหะ (routing) |
| ความเร็วโดยประมาณ (combinational delay) | delay จริงหลัง routing (wire delay, parasitic) |
| จำนวน flip-flop | power grid, tap cell, fill cell |
| — | **DRC** — ข้อบังคับด้านการผลิต |
| — | **LVS** — ยืนยันว่า layout ตรงกับ schematic |
| — | **GDSII** — ไฟล์ที่ foundry รับ |

> **ประเด็นสำหรับผู้สอน:** วันที่ 5 ในหลักสูตรเดิมใช้ Precision RTL + SDF จบที่ netlist
> แล้วปิดท้ายด้วยรายงาน เนื้อหาชุดนี้เพิ่ม **ขั้นสุดท้ายของวงจร ASIC จริง**
> ซึ่งเป็นสิ่งที่นักเรียนต้องรู้ก่อนไปทำ IC Layout ในวันที่ 6–10

### 1.2 ทำไมต้องเป็น Open-source

| ข้อจำกัดของชุด commercial | ผลต่อห้องเรียน |
| --- | --- |
| Place & Route ต้องมี license แยกอีกชุด | นักเรียน 30 คนใช้พร้อมกันไม่ได้ |
| ต้องมี PDK ขององค์กร | เรียนทั่วไปไม่มี PDK ที่ตรงกับเครื่องมือ |
| Magic / Calibre ต้องขอ license แยก | ไม่มีเครื่องมือ DRC/LVS ให้ลอง |
| ใช้เวลาติดตั้งหลายวัน | เสียเวลาบรรยายในห้อง |

**LibreLane + sky130A** แก้ทั้งสองปัญหา: ติดตั้งคำสั่งเดียว และ PDK ฟรีที่ดาวน์โหลดได้เอง

---

## 2. ภาพรวม RTL-to-GDSII

```
        ┌─────────────────────┐
        │  RTL (Verilog)      │  uart_top.v
        └──────────┬──────────┘
                   │
    ┌──────────────▼───────────────┐
    │ Verilator lint               │  syntax, width, undriven
    │ Yosys synthesis               │  RTL → RTLIL → netlist
    └──────────────┬───────────────┘
                   │  netlist (standard cell)
    ┌──────────────▼───────────────┐
    │ OpenROAD                     │
    │   ├ floorplan                │  core/die, PDN, rows
    │   ├ global placement          │  กระจาย cell ให้ครบทั้ง die
    │   ├ detailed placement        │  จัดวางจริงตาม row
    │   ├ CTS                       │  สร้าง clock tree + balance skew
    │   ├ global routing            │  coarse routing
    │   ├ detailed routing          │  fine routing + DRC
    │   └ fill insertion            │  เติม dummy cell
    └──────────────┬───────────────┘
                   │
    ┌──────────────▼───────────────┐
    │ Magic / KLayout               │  DRC, GDSII stream-out, render
    │ Netgen                        │  LVS (netlist ↔ layout)
    │ OpenSTA                       │  multi-corner timing
    └──────────────┬───────────────┘
                   │
        ┌──────────▼──────────┐
        │  uart_top.gds       │  ← ส่ง foundry
        └─────────────────────┘
```

### 2.1 ไฟล์ข้างต้นและปลายทาง

| ไฟล์ | คืออะไร | ใช้ต่อ |
| --- | --- | --- |
| `*.v` | RTL ที่ออกแบบไว้ | Yosys |
| `*.json` / `*.edf` | netlist กลางของ Yosys | OpenROAD |
| `*.gds` | GDSII — geometry จริงของชิป | foundry |
| `*.lef` | abstract layout (ขอบ cell, layer) | place & route |
| `*.def` | design exchange — ตำแหน่ง cell + net + pin | layout database |
| `*.mag` | Magic layout (มนุษย์อ่านได้) | DRC, LVS |
| `*.spice` | netlist สำหรับ LVS | Netgen |
| `*.spef` | parasitic (R, C ของเส้นทาง) | STA ระดับ sign-off |
| `*.sdf` | delay ของ cell ทุก corner | Gate-Level Simulation |

---

## 3. LibreLane คืออะไร

LibreLane เป็น **open-source ASIC design flow** ที่รวมเครื่องมือทั้งชุดไว้ใน "orchestrator" เดียว
(ต่อยอดจาก OpenLane 2.0 ของ Efabless)

### 3.1 เครื่องมือที่ถูกเรียกใช้

| ขั้นตอน | เครื่องมือ | หน้าที่ |
| --- | --- | --- |
| lint | Verilator | ตรวจ syntax, width mismatch, undriven signal |
| synthesis | Yosys (มี `yosys-ghdl`) | RTL → netlist |
| floorplan / P&R / CTS | OpenROAD + OpenSTA | วางและเชื่อมต่อวงจร |
| DRC | Magic + KLayout | ตรวจข้อบังคับด้านการผลิต (สองเครื่องมือตรวจซ้ำกัน) |
| GDSII | Magic + KLayout | stream-out |
| LVS | Netgen | เทียบ schematic ↔ layout |
| render | KLayout | สร้างภาพ 2D ของ layout |

### 3.2 ติดตั้งแบบคำสั่งเดียว

```bash
nix profile install nixpkgs#librelane
export PATH="$HOME/.nix-profile/bin:$PATH"
librelane --version
# → LibreLane v3.0.17
```

> nix ดึง OpenROAD, Magic, KLayout, Netgen, Yosys และ yosys-ghdl มาใน closure เดียวกัน
> ไม่ต้องติดตั้งแยกทีละตัว — ซึ่งเป็นข้อได้เปรียบหลักของ open-source ในเชิงการสอน

### 3.3 โครงสร้าง flow

```
librelane/
├── config.yaml        ← คำสั่งเดียวที่ต้องแก้
└── runs/
    └── RUN_<วันที่>_<เวลา>/
        ├── 01-.../ 02-.../ ... 76-.../   ← stage แต่ละขั้น
        ├── final/                        ← ผลลัพธ์ทั้งหมด
        ├── flow.log / error.log / warning.log
        └── resolved.json                 ← config ที่ถูก resolve แล้ว
```

> `resolved.json` มีค่าทุกตัวของ config หลังผ่านการ default และ PDK override
> ใช้ตรวจว่า "ทำไมค่าที่ฉันตั้งไม่ถูกใช้" ได้ทันที

---

## 4. 80 stages แบ่งเป็นอะไรบ้าง

LibreLane รายงานผลเป็น **80/80 stages** โดยแบ่งเป็น 76 โฟลเดอร์ตัวเลข (`01-` ถึง `76-`)
แล้วสรุปเป็น `final/` — จากการรันจริงของ `uart_top`

```
กลุ่มงาน                        ตัวอย่าง stage
─────────────────────────────   ─────────────────────────────────────
ตรวจคุณภาพ RTL         01-04   verilator lint, lint checker
สังเคราะห์              05-09   yosys json, yosys synthesis, unmapped cells check
ตรวจ SDC / macro        10-12   openroad check SDC, check macro instances, sta prep
วาง floorplan           13-23   floorplan, die area, cut rows, tap, PDN, routing obstruction
วางตำแหน่ง             24-34   IO placement, global placement, detailed placement
สร้าง clock tree        35-38   CTS, resizer, STA
เชื่อมต่อ                39-51   global routing, antenna, detailed routing, wirelength
เติมและสกัด            52-56   fill insertion, RCX (parasitic), STA post-PnR
ส่งออก GDSII            57-63   magic stream-out, klayout stream-out, magic LEF, XOR check
ตรวจ DRC                64-67   magic DRC, klayout DRC, checker ทั้งสองฝั่ง
สกัดและ LVS            68-71   magic spice extraction, illegal overlap, netgen LVS
ตรวจ timing & sign-off  72-76   setup/hold/maxslew/maxcap checker, report manufacturability
```

### 4.1 Stage ที่มักพลาดบ่อยที่สุด

| Stage | อาการที่พบ | สาเหตุ |
| --- | --- | --- |
| `05-yosys-jsonheader` | `Can't find top module` | `DESIGN_NAME` ไม่ตรงกับชื่อ module ใน RTL |
| `10-openroad-checksdcfiles` | `CLOCK_PORT` not found | ชื่อ port นาฬิกาไม่ตรงกับ SDC |
| `12-openroad-staprepnr` | clock period เป็น 0 | ไม่ได้ตั้ง `CLOCK_PERIOD` |
| `24-...-globalplacementskipio` | pin ไม่มีที่วาง | die เล็กเกินไปเมื่อมี IO เยอะ |
| `47-checker-trdrc` | DRC violation | routing congestion → ลด `FP_CORE_UTIL` |
| `70-netgen-lvs` | LVS mismatch | blackbox / tie cell / ชื่อ net ไม่ตรง |

---

## 5. Floorplan

Floorplan ตัดสินใจ **"ชิปจะหน้าตาแบบไหน"** ก่อนที่จะวางวงจร

### 5.1 แนวคิด Core vs Die

```
    ┌─────────────────────────────────────────────┐
    │                 DIE (ทั้งหมด)                │  ← รวมรอบขอบ + power ring
    │  ┌───────────────────────────────────────┐  │
    │  │                                       │  │
    │  │              CORE                     │  │  ← พื้นที่ที่วาง cell ได้จริง
    │  │        (วงจร + routing)               │  │
    │  │                                       │  │
    │  └───────────────────────────────────────┘  │
    │   ↑ power ring (M1/M2) รอบ core             │
    └─────────────────────────────────────────────┘
```

| ปริมาณ | ความหมาย |
| --- | --- |
| **Core area** | พื้นที่ที่ใช้วางวงจรได้ (µm²) |
| **Die area** | พื้นที่ทั้งหมดรวมรอบขอบและ power ring (µm²) |
| **Utilization** | instance area ÷ core area |
| **Core bbox** | กรอบสี่เหลี่ยมของ core (µm) |

### 5.2 ค่าที่วัดได้จริง (UART TX)

| รายการ | ค่า |
| --- | --- |
| Core area | 2805.19 µm² |
| Core bbox | `5.52 10.88 59.8 62.56` µm |
| Die area | **4975.42 µm²** |
| Die bbox | `0.0 0.0 65.38 76.1` µm |
| Utilization | **60.12 %** |
| Rows / Sites | 19 / 2242 |

> สังเกตว่า die area (4975.42) **มากกว่า** core area (2805.19) ถึง 1.77 เท่า
> เพราะมีรอบ power ring และพื้นที่ว่างรอบ core
> การคิด "พื้นที่ชิป = พื้นที่วงจร" จึงผิด — ต้องดูทั้งสองค่า

### 5.3 FP_CORE_UTIL มีผลอย่างไร

```yaml
pdk::sky130*:
  FP_CORE_UTIL: 45    # % ของ core area ที่จะใช้วาง cell จริง
```

- ค่า **สูง** → core เล็ก → die เล็ก → ถนัดมาก แต่ routing ยาก → DRC violation ง่าย
- ค่า **ต่ำ** → core ใหญ่ → routing สบาย → แต่พื้นที่ชิปเปลือง

กับ `uart_top` ที่ใช้ `FP_CORE_UTIL: 45` ได้ utilization จริง **60.12 %**
(สูงกว่า 45 เพราะ OpenROAD เติม buffer/fill/tap เพิ่มในขั้น CTS และ routing repair)

---

## 6. Placement

### 6.1 สามขั้นตอน

| ขั้น | สิ่งที่ทำ | เครื่องมือ |
| --- | --- | --- |
| Global placement | กระจาย cell ให้กระจายทั่ว die ตามความหนาแน่น | OpenROAD (RePlAce) |
| Detailed placement | จัดตำแหน่งจริงภายใน standard cell row | OpenROAD |
| Legalisation | ดัน cell ให้ผ่าน DRC โดยไม่ทับกัน | OpenROAD |

### 6.2 ตัวชี้วัดคุณภาพ

| Key | ความหมาย | ค่าที่วัดได้ (uart_top) |
| --- | --- | --- |
| `design__instance__displacement__max` | ระยะที่ cell ถูกดันมากที่สุด (µm) | — |
| `design__instance__displacement__mean` | ระยะเฉลี่ย (µm) | — |
| `design__instance__displacement__total` | ระยะรวม (µm) | — |

> cell ที่ถูกดันไกลแปลว่า placement ไม่ดี → routing จะยาว → delay มาก → timing แย่
> นี่คือเหตุผลที่ต้องดูค่านี้ควบคู่กับ slack เสมอ

---

## 7. Clock Tree Synthesis (CTS)

### 7.1 ทำไมต้องมี clock tree

```
ก่อน CTS (ideal clock):            หลัง CTS (real clock):
    clk ──┬── FF1                       clk
          ├── FF2                       │
          └── FF3                       ├── buf ── buf ── FF1
                                         ├── buf ── FF2
   ทุก FF เห็นขอบ clock พร้อมกัน       └── buf ── FF3
   (ใช้ไม่ได้จริง เพราะโลหะมีความต้านทาน)   แต่ FF ที่ปลายสายได้รับ clock ช้ากว่า
                                       → เกิด clock skew
```

| ปริมาณ | ความหมาย | ค่าที่วัดได้ (uart_top) |
| --- | --- | --- |
| `clock__skew__worst_setup` | skew ที่กระทบ setup (ns) | **0.002564** |
| `clock__skew__worst_hold` | skew ที่กระทบ hold (ns) | **0.006135** |
| `design__instance__count__class:clock_buffer` | buffer ใน clock tree | 3 |
| `design__instance__area__class:clock_inverter` | พื้นที่ clock inverter | 30.03 µm² |

> ยิ่ง skew เล็ก → ยิ่งดี → ยิ่งมี headroom สำหรับ setup/hold
> **skew ที่เป็นบวก** หมายถึง clock ปลายทางมาช้ากว่า ซึ่งช่วย hold แต่กิน setup margin

---

## 8. Routing

### 8.1 สองระดับ

| ระดับ | ลักษณะ | จุดประสงค์ |
| --- | --- | --- |
| Global routing | ลงเส้นคร่าว ไม่สนรายละเอียด layer | ตัดสินใจเส้นทางระดับภาพรวม |
| Detailed routing | ลงจริงตาม layer/via ที่กฎ DRC กำหนด | ได้ layout ที่ผ่าน DRC |

### 8.2 ผลของ routing ที่วัดได้

| รายการ | ค่า |
| --- | --- |
| Timing repair buffer ที่ OpenROAD เพิ่ม | **20 ตัว** (พื้นที่ 200.19 µm²) |
| `design__max_slew_violation__count` | 0 |
| `design__max_cap_violation__count` | 0 |
| `design__max_fanout_violation__count` | 0 |
| `design__wirelength` (จาก `50-odb-reportwirelength`) | อ่านได้จาก log ของ stage นั้น |

> **buffer 20 ตัวที่ OpenROAD เพิ่มเอง** คือหลักฐานว่า timing ถูก "ซ่อม" ระหว่าง routing
> ถ้าไม่มี buffer เหล่านี้ slack จะติดลบ — นี่คือเหตุผลที่ RTL cell count
> ไม่เท่ากับ instance count ใน layout

---

## 9. Power Distribution Network (PDN)

### 9.1 โครงสร้าง

```
   ┌───────────────────────────────────────────┐
   │ ══════════════════════════════════════════ │ ← M2 horizontal (VDD)
   │ ───────────────────────────────────────── │ ← M1 vertical  (VSS)
   │ ══════════════════════════════════════════ │ ← M2 horizontal (VDD)
   │ ───────────────────────────────────────── │ ← M1 vertical  (VSS)
   │ ══════════════════════════════════════════ │
   │ ───────────────────────────────────────── │
   └───────────────────────────────────────────┘
        power ring รอบ core
```

### 9.2 ค่าใน config.yaml

```yaml
PDN_VOFFSET: 5     # ระยะจากขอบ core ถึงแนว V
PDN_HOFFSET: 5     # ระยะจากขอบ core ถึงแนว H
PDN_VWIDTH: 2      # ความกว้างแนว V (µm)
PDN_HWIDTH: 2      # ความกว้างแนว H (µm)
PDN_VPITCH: 30     # ระยะห่างระหว่างแนว V (µm)
PDN_HPITCH: 30     # ระยะห่างระหว่างแนว H (µm)
PDN_SKIPTRIM: true # ข้ามการ trim PDN (เร็วขึ้น เหมาะกับการเรียน)
```

### 9.3 ตรวจสอบผล

| Key | ค่าที่วัดได้ (uart_top) |
| --- | --- |
| `design__power_grid_violation__count` | **0** |
| `design__instance__count__class:tap_cell` | 42 |
| `design__instance__area__class:tap_cell` | 52.55 µm² |

> **tap cell** คือ cell ที่ยึง substrate / well tie ให้กับราง VSS
> ถ้าไม่มี tap cell จะเกิด latch-up — เป็นเหตุผลที่ layout จริงต้องมีมากกว่า cell ใน RTL

---

## 10. Sign-off: DRC / LVS / Antenna

สามเรื่องนี้คือ **เกณฑ์ขั้นต่ำที่ foundry จะตรวจก่อนรับงาน** — ถ้าไม่ผ่านก็ไม่จัดทำผลิต

### 10.1 DRC — Design Rule Check

ตรวจว่า layout ผลิตได้จริง: ระยะห่างระหว่างโลหะ, ขนาดต่ำสุดของ wire, via ที่ถูกต้อง

LibreLane ตรวจ **สองครั้งด้วยสองเครื่องมือ**:

| เครื่องมือ | Stage | ข้อได้เปรียบ |
| --- | --- | --- |
| Magic | `64-magic-drc` | เก่าแก่ ตรวจเครื่องมือ layout แบบเดิม |
| KLayout | `65-klayout-drc` | ใหม่ ตรวจด้วย Ruby DSL ยืดหยุ่นกว่า |

ถ้าผลต่างกันจะมี `design__xor_difference__count` บอก — ค่าที่วัดได้คือ **0**
แปลว่าสองเครื่องมือเห็นผลตรงกัน

### 10.2 LVS — Layout Versus Schematic

เทียบว่า layout ที่วางได้ **ต่อกับวงจรตรงกันหรือไม่** โดยเทียบ netlist กับ schematic

```
   RTL/netlist ──► Magic Spice Extraction ──► layout netlist
                            │
                            ▼
                    ┌───────────────┐
                    │    Netgen     │  เทียบ device / net / pin
                    └───────────────┘
                            │
              ┌─────────────┴─────────────┐
         mismatch                       match
              │                             │
   LVS ไม่ผ่าน → ต้องแก้       LVS ผ่าน → layout เชื่อถือได้
```

| Key | ความหมาย | ค่าที่วัดได้ |
| --- | --- | --- |
| `design__lvs_error__count` | error ของ LVS | **0** |
| `design__lvs_device_difference__count` | จำนวนอุปกรณ์ต่างกัน | **0** |
| `design__lvs_net_difference__count` | จำนวน net ต่างกัน | **0** |
| `design__lvs_unmatched_device__count` | อุปกรณ์ที่จับคู่ไม่ได้ | **0** |
| `design__lvs_unmatched_net__count` | net ที่จับคู่ไม่ได้ | **0** |
| `design__lvs_unmatched_pin__count` | pin ที่จับคู่ไม่ได้ | **0** |
| `design__lvs_property_fail__count` | property ไม่ตรง | **0** |

### 10.3 Antenna — ปัญหาที่พบเฉพาะขั้น layout

Antenna effect เกิดจากการที่ **net มีขาเชื่อมต่อกับโลหะ (poly) มากเกินไป**
ตัวอย่างเช่น net ที่ต่อกับ gate ของทรานซิสเตอร์หลายตัว — เมื่อไฟกระแสไหลเข้า gate
ประจุสะสมทำให้ voltage ของ poly สูงขึ้นจน gate หลุด (ในเทคโนโลยีสมัยใหม่ต้องใช้
antenna-aware หรือ diode insertion)

| Key | ความหมาย | ค่าที่วัดได้ |
| --- | --- | --- |
| `antenna__violating__nets` | จำนวน net ที่มีปัญหา | **0** |
| `antenna__violating__pins` | จำนวน pin ที่มีปัญหา | **0** |

> stage `40-openroad-checkantennas` และ `46-openroad-checkantennas-1` ตรวจสองรอบ
> (ก่อนและหลัง repair) — ถ้าค่าที่รอบหลังยังไม่เป็น 0 ต้องใช้วิธีแก้เพิ่ม

---

## 11. Static Timing Analysis (STA)

### 11.1 Setup / Hold บน layout จริง

```
   launch FF                capture FF
   ┌────┐                   ┌────┐
   │    │──[ combinational + routing delay ]──▶│    │
   └────┘                   └────┘
        ▲                                            ▲
   clk edge t=0                                 clk edge t=T

   setup: ข้อมูลต้องมาถึงก่อน t=T - t_setup
   hold : ข้อมูลต้องคงอยู่อย่างน้อย t_hold หลัง t=T
```

### 11.2 Slack คืออะไร

```
   slack = data arrival time - data required time
```

- slack > 0 → ผ่าน (ยิ่งมากยิ่งดี)
- slack < 0 → violation (ต้องแก้)
- **WNS** = Worst Negative Slack = slack ที่แย่ที่สุด
- **TNS** = Total Negative Slack = ผลรวมของ slack ที่ติดลบทั้งหมด

### 11.3 ค่าที่วัดได้ (uart_top, sky130A, clock 100 MHz)

| รายการ | ค่า |
| --- | --- |
| `timing__setup__ws` (worst setup slack) | **6.235697** ns |
| `timing__setup__wns` | 0 |
| `timing__setup__tns` | 0 |
| `timing__setup_vio__count` | **0** |
| `timing__hold__ws` (worst hold slack) | **0.191574** ns |
| `timing__hold__wns` | 0 |
| `timing__hold__tns` | 0 |
| `timing__hold_vio__count` | **0** |

### 11.4 คำนวณ Fmax

```
   critical path = clock period - setup slack
                = 10 - 6.235697
                = 3.764303 ns

   Fmax          = 1 / 3.764303 ns ≈ 265.7 MHz
```

> setup slack ขนาด 6.24 ns บนคาบเวลา 10 ns แปลว่า design นี้ยังมีขอบเขตมาก
> สามารถเพิ่มความถี่ได้จนถึงประมาณ 265 MHz **ถ้าไม่ต้องเพิ่ม I/O delay**
> (ในตอนนี้ตั้ง `set_input_delay`/`set_output_delay` เป็น 0 เพราะไม่มีสเปกระบบภายนอก)

### 11.5 ⚠️ ข้อควรระวัง — slack ที่ได้ไม่ได้แปลว่า "ผ่านจริงเสมอ"

| ปัจจัย | สถานะในแล็บนี้ | ผลต่อตัวเลข |
| --- | --- | --- |
| I/O delay | ตั้งเป็น **0 ns** | slack สูงกว่าความจริง |
| Clock uncertainty / jitter | **ไม่ได้ตั้ง** | slack สูงกว่าความจริง |
| Clock tree จริง | มี (OpenROAD สร้าง) | รวมแล้ว ✅ |
| Routing delay จริง | มี (จาก detailed routing + RCX) | รวมแล้ว ✅ |
| Multi-corner | 9 corners | รวมแล้ว ✅ |
| Derate | ไม่มี | slack สูงกว่าความจริงเล็กน้อย |

> **ต้องบอกผู้เรียนเสมอ:** ตัวเลข slack เหล่านี้เป็น "slack ของ design ที่ยังไม่มีข้อกำหนดระบบภายนอก"
> ในงานจริงต้องใส่ I/O delay ตามสเปก และ clock uncertainty ก่อนจึงจะเรียกว่า sign-off ได้

---

## 12. อ่านผลลัพธ์จาก `metrics.json`

### 12.1 วิธีดึงตัวเลขหลัก

```bash
cd librelane
RUN=$(ls -dt runs/RUN_* | head -1)

python3 -c "
import json
m = json.load(open('$RUN/final/metrics.json'))
print('instances    :', m.get('design__instance__count'))
print('instance area:', m.get('design__instance__area'), 'um^2')
print('core area    :', m.get('design__core__area'), 'um^2')
print('die area     :', m.get('design__die__area'), 'um^2')
print('utilization  :', m.get('design__instance__utilization'))
print('nets / io    :', m.get('design__nets'), '/', m.get('design__io'))
print('setup slack  :', m.get('timing__setup__ws'), 'ns')
print('hold slack   :', m.get('timing__hold__ws'), 'ns')
print('violations   :', m.get('design__violations'))
print('latches      :', m.get('design__inferred_latch__count'))
"
```

### 12.2 Key ที่ต้องรู้ทั้งหมด (พร้อมค่าที่วัดได้จริง)

| Key | ความหมาย | ค่า (uart_top) |
| --- | --- | --- |
| `design__instance__count` | instance ทั้งหมด | **526** |
| `design__instance__count__stdcell` | เฉพาะ standard cell | 183 |
| `design__instance__count__class:fill_cell` | เซลล์เติมพื้นที่ว่าง | 343 |
| `design__instance__count__class:timing_repair_buffer` | buffer ที่เพิ่มเพื่อแก้ timing | 20 |
| `design__instance__count__class:tap_cell` | tap cell (ยึง well) | 42 |
| `design__instance__count__class:clock_buffer` | buffer clock tree | 3 |
| `design__instance__count__class:sequential_cell` | flip-flop | 28 |
| `design__instance__count__class:multi_input_combinational_cell` | gate หลายอินพุต | 84 |
| `design__instance__area` | พื้นที่ instance (µm²) | **2805.19** |
| `design__instance__area__class:fill_cell` | พื้นที่ fill cell | 1118.57 |
| `design__instance__area__class:multi_input_combinational_cell` | พื้นที่ gate | 714.44 |
| `design__instance__area__class:sequential_cell` | พื้นที่ flip-flop | 595.57 |
| `design__instance__area__class:timing_repair_buffer` | พื้นที่ timing buffer | 200.19 |
| `design__instance__area__class:clock_buffer` | พื้นที่ clock buffer | 75.07 |
| `design__instance__area__class:tap_cell` | พื้นที่ tap cell | 52.55 |
| `design__core__area` | พื้นที่ core (µm²) | 2805.19 |
| `design__core__bbox` | กรอบ core | `5.52 10.88 59.8 62.56` |
| `design__die__area` | พื้นที่ die (µm²) | **4975.42** |
| `design__die__bbox` | กรอบ die | `0.0 0.0 65.38 76.1` |
| `design__instance__utilization` | สัดส่วนที่ใช้ | 0.601249 |
| `design__nets` / `design__io` | net / ขา | 153 / 15 |
| `design__rows` / `design__sites` | แถว / site | 19 / 2242 |
| `design__violations` | violation รวม | **0** |
| `design__inferred_latch__count` | latch ที่ถูกอนุมาน | **0** |
| `design__instance_unmapped__count` | cell ที่ map ไม่ลง | **0** |
| `design__max_slew_violation__count` | slew violation | 0 |
| `design__max_cap_violation__count` | cap violation | 0 |
| `design__max_fanout_violation__count` | fanout violation | 0 |
| `design__power_grid_violation__count` | power grid violation | 0 |
| `design__lint_error__count` / `__warning__count` | lint | 0 / 0 |
| `timing__setup__ws` | worst setup slack (ns) | **6.235697** |
| `timing__setup__wns` / `__tns` | worst / total negative slack | 0 / 0 |
| `timing__hold__ws` | worst hold slack (ns) | **0.191574** |
| `timing__hold__wns` / `__tns` | worst / total negative slack | 0 / 0 |
| `clock__skew__worst_setup` / `__worst_hold` | clock skew (ns) | 0.002564 / 0.006135 |
| `antenna__violating__nets` / `__pins` | antenna violation | 0 / 0 |
| `design__lvs_error__count` | LVS error | 0 |
| `design__lvs_device_difference__count` | อุปกรณ์ต่างกัน | 0 |
| `design__lvs_net_difference__count` | net ต่างกัน | 0 |
| `design__xor_difference__count` | Magic vs KLayout ต่างกัน | 0 |
| `power__total` | กำลังรวม (W) | 0.00030398 (303.98 µW) |
| `power__internal__total` | switching + leakage (W) | 0.00024563 |
| `power__switching__total` | switching power (W) | 0.00005834 |
| `power__leakage__total` | leakage power (W) | 2.929e−09 |

---

## 13. ไฟล์ผลลัพธ์ทั้งหมด

```
final/
├── metrics.json           ← ตัวเลขทั้งหมด
├── metrics.csv            ← เหมือนกันแต่เป็น CSV
├── gds/
│   └── uart_top.gds                  517,382 bytes
├── klayout_gds/
│   └── uart_top.klayout.gds          374,124 bytes
├── mag_gds/
├── lef/   uart_top.lef      4,273 bytes
├── def/   uart_top.def    150,629 bytes
├── mag/   uart_top.mag    317,921 bytes
├── spice/ uart_top.spice   39,980 bytes
├── spef/  {min,nom,max}/
├── sdf/   9 corners/
├── nl/  pnl/  odb/  vh/  json_h/  lib/  render/  sdc/
```

### 13.1 เปิดดู GDSII

```bash
klayout "$RUN/final/klayout_gds/uart_top.klayout.gds"
```

LibreLane สร้างภาพเรนเดอร์ไว้ที่ `final/render/` ดูได้ทันทีโดยไม่ต้องเปิดโปรแกรม

### 13.2 ตรวจ LVS ซ้ำด้วยตัวเอง

```bash
netgen -batch lvs \
  "$RUN/final/spice/uart_top.spice" "$RUN/final/spice/uart_top.spice" \
  "$RUN/final/mag/uart_top.mag" report.lvs
```

---

## 14. Multi-corner Analysis

ชิปจริงทำงานที่ PVT ต่างกัน — flow จึงต้องผ่านทุก corner

### 14.1 9 corners

| มิติ | ค่า |
| --- | --- |
| Process | slow (ss) / typical (tt) / fast (ff) |
| Voltage | 1.60 V (ss) / 1.80 V (tt) / 1.95 V (ff) |
| Temperature | 100 °C (ss) / 25 °C (tt) / −40 °C (ff) |

ชื่อ corner ที่ได้: `{min,nom,max}_{ff,tt,ss}_{n40C,025C,100C}_{1v95,1v80,1v60}`

### 14.2 Setup slack ต่อ corner ที่วัดได้

| Corner | setup slack (ns) |
| --- | --- |
| `min_ff_n40C_1v95` | 8.965368 |
| `nom_ff_n40C_1v95` | 8.958746 |
| `max_ff_n40C_1v95` | 8.951070 |
| `min_tt_025C_1v80` | 8.300024 |
| `nom_tt_025C_1v80` | 8.289632 |
| `max_tt_025C_1v80` | 8.277832 |
| `min_ss_100C_1v60` | 6.274457 |
| `nom_ss_100C_1v60` | 6.256837 |
| **`max_ss_100C_1v60`** | **6.235697** ← worst case |

> **corner ที่แย่ที่สุดคือ slow process + อุณหภูมิสูง + แรงดันต่ำ** (`max_ss_100C_1v60`)
> เพราะ cell ช้าลงและ hold/สัญญาณอ่อนลง — นี่คือ corner ที่ foundry ให้ความสำคัญที่สุด

### 14.3 Hold slack ต่อ corner

| Corner | hold slack (ns) |
| --- | --- |
| **`min_ff_n40C_1v60`** | **0.191574** ← worst case |
| `nom_ff_n40C_1v95` | 0.194052 |
| `max_ff_n40C_1v95` | 0.194872 |
| `min_tt_025C_1v80` | 0.308719 |
| `nom_tt_025C_1v80` | 0.312889 |
| `max_tt_025C_1v80` | 0.315234 |
| `min_ss_100C_1v60` | 0.618923 |
| `nom_ss_100C_1v60` | 0.626525 |
| `max_ss_100C_1v60` | 0.632267 |

> **hold สำคัญที่สุดที่ corner เร็ว (ff) และเย็น (n40C)** — ตรงข้ามกับ setup
> เพราะ cell เร็วขึ้น → data วิ่งถึงเร็วขึ้น → ต้อง hold มากขึ้น

### 14.4 SPEF

`final/spef/` มี 3 ชุด (`min`, `nom`, `max`) คือค่า parasitic (R, C) ของเส้นทางจริงหลัง routing
ใช้ทำ STA ระดับ sign-off ที่แม่นยำกว่าการประมาณจาก cell delay อย่างเดียว

---

## 15. บทเรียน: Yosys เปลี่ยนโครงสร้าง design เอง

นี่คือข้อค้นพบจากการรันจริงที่ควรสอนในห้องเรียน

### 15.1 สิ่งที่เขียนไว้

```verilog
reg [1:0] state;     // FSM 4 สถานะ IDLE/START/DATA/STOP -> 2 บิต
```

### 15.2 สิ่งที่ Yosys สร้างจริง

```
   cell $_DFF_P_ $auto$ff.cc:266:slice$356
     connect \C \clk
     connect \D $abc$765$auto$fsm_map.cc:170:map_fsm$115[0]
     connect \Q \u_tx.state [0]
   end
   cell $_DFF_P_ $auto$ff.cc:266:slice$357
     connect \C \clk
     connect \D $abc$765$auto$fsm_map.cc:170:map_fsm$115[1]
     connect \Q \u_tx.state [1]
   end
   cell $_DFF_P_ $auto$ff.cc:266:slice$358
     ...
   cell $_DFF_P_ $auto$ff.cc:266:slice$359
     ...
   end
```

### 15.3 สิ่งที่เกิดขึ้นจริง

| | โค้ดเดิม | ผลของ Yosys |
| --- | --- | --- |
| จำนวนบิตของ state | 2 | **4** |
| การเข้ารหัส | binary | **one-hot** (`map_fsm$115[0..3]`) |
| reset | มี (sync reset) | **ไม่มี** (`$_DFF_P_` ไม่มี reset) |
| จำนวน flip-flop รวม | 26 (ตามที่เขียน) | **28** |

> **`fsm` pass ของ Yosys ตรวจจับ FSM แล้วเปลี่ยน encoding เป็น one-hot**
> แลกกับ flip-flop เพิ่ม 2 ตัว แต่ logic decode ของ FSM กลายเป็นตรรกะขนาดเล็ก
> และ **ไม่ต้องใช้ reset อีกต่อไป** เพราะ one-hot แปลว่าสถานะ "ไม่มี state ไหนเป็น 1"
> จะถูกตีความเป็น default case → IDLE

### 15.4 บทเรียน 4 ข้อ

1. **RTL ที่คุณเขียน ไม่ใช่สิ่งที่ถูกสังเคราะห์** — tool ปรับโครงสร้างให้เหมาะกับเทคโนโลยีเป้าหมาย
2. **ต้องอ่าน output ของ tool ไม่ใช่แค่เชื่อรายงาน** — `dump` ดู connection จริงได้ว่า flip-flop ตัวไหนมี reset
3. **พื้นที่เพิ่มไม่ได้แปลว่าแย่** — one-hot ใช้ FF เพิ่มแต่ delay ลดลง และไม่ต้องมี reset distribution
4. **การนับ flip-flop ด้วยสายตาอาจผิด** — ต้องนับจาก `stat` ของ tool เสมอ

---

## 16. จาก RTL เดียวกันสู่ชิป 2 ขนาด

ผลจากการรันจริงทั้งสอง flow ด้วย design ที่ต่างกัน แต่ใช้ขั้นตอนเดียวกัน

| มิติ | `adder8_pipe` (Lab 3B) | `uart_top` (Lab 5B) |
| --- | --- | --- |
| จำนวน flip-flop | 26 | **28** |
| Instance count (layout) | 399 | **526** |
| stdcell | 167 | **183** |
| fill cell | 232 | **343** |
| timing repair buffer | 44 | **20** |
| tap cell | 30 | **42** |
| Instance area | 2409.81 µm² | **2805.19 µm²** |
| Core area | 2409.81 µm² | **2805.19 µm²** |
| Die area | 4331.89 µm² | **4975.42 µm²** |
| Die ขนาด | 60.675 × 71.395 µm | **65.38 × 76.1 µm** |
| Utilization | 68.95 % | **60.12 %** |
| Setup slack | 5.587222 ns | **6.235697 ns** |
| Hold slack | 0.317141 ns | **0.191574 ns** |
| Fmax (คำนวณ) | ≈ 226.6 MHz | **≈ 265.7 MHz** |
| Nets / IOs | 158 / 30 | **153 / 15** |

### 16.1 ข้อสังเกตที่ต้องอธิบาย

1. **flip-flop ใกล้เคียงกัน (26 vs 28) แต่ชิปใหญ่กว่ามาก**
   เพราะ `uart_top` มี **ขา I/O น้อยกว่า** (15 vs 30) แต่มี **gate มากกว่า**
   (FSM + baud divider) — พื้นที่จึงมาจาก combinational logic ไม่ใช่ register
2. **UART มี timing repair buffer น้อยกว่า (20 vs 44)** เพราะ critical path สั้นกว่า
   (divider 10 บิต + FSM) จึงต้องซ่อมน้อยกว่า
3. **UART มี hold slack น้อยกว่า (0.19 vs 0.32 ns)** — ค่าที่ต้องระวังมากกว่า
   เพราะ hold เกิดจาก skew และ routing ที่สั้นลง
4. **utilization ต่ำกว่าไม่ได้แปลว่าไม่ดี** — กำหนดจาก die ที่เล็กลงจริง
   เพราะ core utilization สูงเกินไปจะ routing ยากและ DRC พัง

---

## 17. ผลอ้างอิงจากการรันจริง

### 17.1 เงื่อนไขการทดสอบ

| รายการ | ค่า |
| --- | --- |
| Design | `uart_top` (UART TX 115200 bps, 100 MHz clock) |
| RTL | Verilog (port จาก `lab_code/day5/` เวอร์ชัน VHDL) |
| Yosys | 0.52 |
| LibreLane | v3.0.17 |
| PDK | sky130A, version `8afc8346a57fe1ab7934ba5a6056ea8b43078e71` |
| SCL | `sky130_fd_sc_hd` |
| Clock period | 10 ns (100 MHz) |
| FP_CORE_UTIL | 45 % |
| I/O delay | 0 ns (ยังไม่มีสเปกระบบภายนอก) |
| เวลาที่ใช้ | ~106–109 วินาที (76 stage dirs, flow complete, Stage 80/80) |

### 17.2 ผลลัพธ์ Yosys

| Module | Generic cells | Gate cells (abc -g) |
| --- | --- | --- |
| `baud_gen` | 44 | — |
| `uart_tx` | 74 | — |
| `uart_top` (แบบ hierarchical) | 118 | — |
| `uart_top` (แบบ flatten) | 116 | **112** |

**สัดส่วน flip-flop (28 ตัว):**

| Cell type | จำนวน | ที่มา |
| --- | --- | --- |
| `$_SDFF_PP0_` | 11 | baud_gen: cnt 10 บิต + tick 1 บิต |
| `$_SDFFE_PP0P_` | 11 | uart_tx: shreg 8 บิต + bit_idx 3 บิต |
| `$_SDFFE_PP1P_` | 2 | uart_tx: tx + din_rdy (reset เป็น 1) |
| `$_DFF_P_` | 4 | uart_tx: FSM state **one-hot** (ไม่มี reset) |

### 17.3 ผลลัพธ์ Yosys ภายใน LibreLane และการ map เข้า sky130

**ภายใน LibreLane (ก่อน map เข้า PDK):**

```
=== uart_top ===
   Number of cells:                 117
   Chip area for module 'uart_top': 1328.774400
     of which used for sequential elements: 595.571200
```

**Yosys standalone → map เข้า sky130 (`make sky130`):**

```
=== uart_top ===
   Number of cells:                 122
   Chip area for module '\uart_top': 1087.292800
```

> **ทำไมสองตัวเลขนี้ต่างกัน (117 cells / 1328.77 µm² กับ 122 cells / 1087.29 µm²)?**
> เพราะเป็น **คนละ flow**: LibreLane ใช้ script สังเคราะห์ของตัวเอง (มีการ optimize
> กับ timing ก่อน map) ส่วน `make sky130` เรียก Yosys ตรง ๆ ด้วย
> `synth -noabc; dfflibmap; abc -liberty` — จำนวน cell ต่างกันเล็กน้อย
> และพื้นที่ต่างกันเพราะ **set ของ cell ที่ ABC เลือกใช้ต่างกัน**
>
> บทเรียน: ตัวเลข synthesis ขึ้นกับ **flow ที่ใช้** ไม่ใช่แค่ RTL
> ต้องระบุเสมอว่าตัวเลขมาจาก flow ใด

### 17.4 ผลลัพธ์ Layout และ Sign-off

| รายการ | ค่า |
| --- | --- |
| Stage ที่ผ่าน | **76 stage dirs · flow complete · error.log = 0 bytes** |
| DRC violations (Magic + KLayout) | **0** ✅ |
| LVS errors / device diff / net diff / pin diff | **0 / 0 / 0 / 0** ✅ |
| Antenna violations (net / pin) | **0 / 0** ✅ |
| Setup violations | **0** (WS = 6.235697 ns) ✅ |
| Hold violations | **0** (WS = 0.191574 ns) ✅ |
| Max slew / max cap / max fanout violations | 0 / 0 / 0 ✅ |
| Power grid violations | 0 ✅ |
| Inferred latches | **0** ✅ |
| Unmapped cells | 0 ✅ |
| Lint errors / warnings | 0 / 0 ✅ |
| Instances | 526 (stdcell 183, fill 343, buffer 20, tap 42, clock buf 3) |
| Nets / IOs | 153 / **15** (13 ขาสัญญาณ + VGND + VPWR) |
| Instance & core area | 2805.19 µm² |
| Die area | 4975.42 µm² (65.38 × 76.1 µm) |
| Utilization | 60.12 % |
| Fmax (คำนวณจาก slack) | ≈ 265.7 MHz |
| Power | total 303.98 µW (internal 245.63, switching 58.34, leakage 2.929 nW) |
| GDSII | `uart_top.gds` 517,382 bytes (Magic) / `uart_top.klayout.gds` 374,124 bytes |

### 17.5 Warning ที่พบ (ทั้งหมดไม่เป็นอันตราย)

```
[PDN-1051] No instances found for grid (macro).
[STA-1140] ... library sky130_fd_sc_hd__tt_025C_1v80 already exists.
[DRT-0349] LEF58_ENCLOSURE with no CUTCLASS is not supported. Skipping for layer mcon
```

- **PDN-1051** — ไม่มี macro instance ในดีไซน์นี้ จึงไม่มี PDN grid สำหรับ macro
- **STA-1140** — OpenSTA โหลด liberty ซ้ำหลาย corner (ข้อความซ้ำ ไม่มีผลกับผลลัพธ์)
- **DRT-0349** — KLayout ไม่รองรับ LEF58_ENCLOSURE ที่ไม่มี CUTCLASS (ข้อจำกัดของ PDK)

> `error.log` เป็น **0 bytes** — ไม่มี error จริงเลย

---

## 18. Troubleshooting

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| `librelane: command not found` | nix profile ไม่ถูกโหลดใน non-interactive shell | `export PATH="$HOME/.nix-profile/bin:$PATH"` |
| `Unable to find PDK sky130A` | ยังไม่ได้ดาวน์โหลด | รันด้วย `--volare-pdk` หรือ `--manual-pdk` |
| `Can't find top module 'uart_top'` | `DESIGN_NAME` ไม่ตรง | ตรวจชื่อ module ใน RTL ให้ตรงกับ `DESIGN_NAME` |
| `CLOCK_PORT` not found | ชื่อ port นาฬิกาไม่ตรงกับ SDC | ตรวจ `CLOCK_PORT` และ `create_clock` ให้ตรงกัน |
| `VERILOG_FILES` หาไฟล์ไม่เจอ | path ผิดระดับ | `dir::` คือ relative จากโฟลเดอร์ config — ใช้ `../rtl/*.v` ถ้า RTL อยู่ข้างบน |
| DRC violation เยอะ | utilization สูงเกิน / routing ยาก | ลด `FP_CORE_UTIL` |
| LVS mismatch | RTL ↔ layout ไม่ตรง | ตรวจ blackbox / tie cell / ชื่อ net |
| setup violation หลัง routing | delay จริงมากกว่าเดิม | เพิ่ม `CLOCK_PERIOD` หรือปรับ RTL |
| hold violation | clock skew มากเกินไป / routing สั้นเกินไป | ให้ CTS balance skew, เพิ่ม buffer, หรือใส่ delay cell |
| Antenna violation | net ต่อกับ poly เยอะ | เปิด antenna repair ใน OpenROAD |
| `flow complete` แต่ไม่มี `final/` | รันไม่จบ | ดู `error.log` และ `flow.log` |
| Run ช้ามาก | ครั้งแรกต้องดาวน์โหลด PDK (~1–2 GB) | รอครั้งแรก ครั้งต่อไป ~106 วินาที |

---

## 19. แบบฝึกหัดและ Checklist

### 19.1 แบบฝึกหัด

| ข้อ | โจทย์ | ผลที่คาดหวัง |
| --- | --- | --- |
| F.1 | อ่าน `metrics.json` แล้วหาพื้นที่ที่ถูกใช้โดย fill cell | 1118.57 µm² จากทั้งหมด 2805.19 µm² (≈ 40 %) |
| F.2 | อธิบายว่าทำไม I/O มี 15 ขา ไม่ใช่ 13 | 13 ขาสัญญาณ + VGND + VPWR ที่ OpenROAD เพิ่มที่ขอบ die |
| F.3 | หา corner ที่ setup slack แย่ที่สุด | `max_ss_100C_1v60` = 6.235697 ns |
| F.4 | หา corner ที่ hold slack แย่ที่สุด | `min_ff_n40C_1v95` = 0.191574 ns |
| F.5 | แก้ `CLOCK_PERIOD` เป็น 5 ns แล้วรันใหม่ | พบ setup violation หรือ slack ลดลงมาก |
| F.6 | แก้ `FP_CORE_UTIL` เป็น 60 แล้วรันใหม่ เทียบ die area | die area เล็กลง แต่ utilization สูงขึ้น |
| F.7 | เพิ่ม `set_input_delay 2` / `set_output_delay 2` ใน SDC แล้วรันใหม่ | slack ลดลงประมาณ 2 ns ต่อขา |
| F.8 | ดู `final/render/` แล้วอธิบายว่าเห็นอะไรใน layout | เห็น cell สีต่าง ๆ, PDN, I/O pin |
| F.9 | รัน `dump` บน `$_DFF_P_` ใน Yosys | พบ 4 ตัว = FSM state one-hot ที่ไม่มี reset |
| F.10 | เปรียบเทียบ instance count ของ RTL กับ layout | RTL 117 cells → layout 526 instances |

### 19.2 Validation Checklist

| # | ข้อ | สถานะ |
| --- | --- | --- |
| 1 | RTL simulation ผ่าน 6 เฟรม UART | ☐ |
| 2 | Yosys generic synthesis อ่าน `stat` ได้ | ☐ |
| 3 | เข้าใจว่าทำไม flip-flop กลายเป็น 28 ไม่ใช่ 26 | ☐ |
| 4 | Gate-level netlist สร้างได้ | ☐ |
| 5 | Gate-Level Simulation ผ่านเท่ากับ RTL | ☐ |
| 6 | Map เข้า sky130 cell และอ่านพื้นที่จริงได้ | ☐ |
| 7 | LibreLane flow รันจน `flow complete` | ☐ |
| 8 | `error.log` เป็น 0 bytes | ☐ |
| 9 | อ่าน `metrics.json` ได้ — area, utilization, slack | ☐ |
| 10 | อธิบายได้ว่า core area ≠ die area | ☐ |
| 11 | อธิบายได้ว่า instance count ≠ RTL cell count | ☐ |
| 12 | หา worst corner ของ setup และ hold ได้ | ☐ |
| 13 | เปิดดู GDSII ด้วย KLayout ได้ | ☐ |
| 14 | อธิบายข้อจำกัดของ slack ที่วัดได้ (I/O delay = 0) | ☐ |

---

> **ต่อไป:** เข้าสู่ **ส่วนที่ 2 (วันที่ 6–10)** — IC Layout และ MEMS Design
> เนื้อหาที่ได้ในวันที่ 5 คือ "ภาพรวมของทั้งวงจร ASIC" ที่นักเรียนต้องรู้ก่อน
> ลงมือวาง layout ด้วยเครื่องมือเชิงพาณิชย์ (Tanner / L-Edit)

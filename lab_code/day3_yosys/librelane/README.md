# LibreLane — Open-source ASIC Flow (RTL → GDSII) สำหรับ Lab 3B

> เอกสารประกอบ `config.yaml` ของ **Lab 3B** — แล็บเสริมของวันที่ 3 ในหลักสูตร
> Advanced Digital IC and MEMS Design with EDA Verification and Simulation Tools
>
> **คู่มือฉบับเต็ม:** [`../../../Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md`](../../../Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md)
> **README ของทั้งแล็บ:** [`../README.md`](../README.md)

---

## 1. LibreLane คืออะไร

LibreLane คือ **open-source ASIC design flow** ที่รวมเครื่องมือสังเคราะห์และ layout
ทั้งชุดเข้าด้วยกันในรูปแบบที่ "ย่อยกว่าการต้องเรียกแต่ละเครื่องมือเอง"

```
        RTL (Verilog)
            │
            ▼
    ┌───────────────────────┐
    │  Yosys                │  synthesis → netlist
    │  + Verilator lint     │
    └───────────┬───────────┘
                ▼
    ┌───────────────────────┐
    │  OpenROAD             │  floorplan → placement → CTS → routing
    │  (OpenSTA, TritonRoute)│
    └───────────┬───────────┘
                ▼
    ┌───────────────────────┐
    │  Magic / KLayout      │  DRC, GDSII stream-out
    │  Netgen               │  LVS
    └───────────┬───────────┘
                ▼
          adder8_pipe.gds
```

**จุดขายหลักของ LibreLane:** ทุกอย่างเป็น open-source, ติดตั้งผ่าน `nix` ได้ในคำสั่งเดียว,
มี PDK ฟรี (sky130) และผลลัพธ์เป็น GDSII จริงที่นำไปส่ง foundry ได้

> **ความสัมพันธ์กับ Day 3 ฝั่ง commercial:** Precision RTL ทำหน้าที่เดียวกับ Yosys
> (synthesis) แต่ LibreLane ทำ **ทั้ง flow** — synthesis + P&R + DRC + LVS + GDSII
> ซึ่งเป็นสิ่งที่ commercial suite แต่ละตัวทำแค่ส่วนเดียว

---

## 2. ติดตั้ง

### 2.1 LibreLane + ชุดเครื่องมือ ASIC ทั้งชุด (ผ่าน nix)

```bash
curl -L -o /tmp/install-nix.sh https://nixos.org/nix/install | sh -s -- --daemon
source /root/.nix-profile/etc/profile.d/nix.sh

nix profile install nixpkgs#librelane
export PATH="/root/.nix-profile/bin:$PATH"

librelane --version
```

> Nix ดึง **OpenROAD, Magic, KLayout, Netgen, Yosys, yosys-ghdl** มาให้ใน closure เดียวกัน
> ไม่ต้องติดตั้งแยกทีละตัว — นี่คือเหตุผลที่ LibreLane เข้าใจง่ายกว่าการตั้งค่า
> OpenROAD + Magic + KLayout + Netgen เอง

### 2.2 ตรวจสอบว่าติดตั้งสำเร็จ

```bash
librelane --version
# → LibreLane v3.0.17

klayout -v
mag -version
netgen -batch quit
```

### 2.3 PDK — ติดตั้งอัตโนมัติ

PDK ไม่ต้องติดตั้งเอง — ใช้ flag `--volare-pdk` แล้ว LibreLane จะดาวน์โหลดมาให้เอง:

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3_yosys/librelane"
librelane --volare-pdk -p sky130A config.yaml
```

- ครั้งแรก: ดาวน์โหลด PDK **ประมาณ 1–2 GB** ใช้เวลา 2–4 นาที (ขึ้นกับความเร็วเน็ต)
- ครั้งต่อไป: ใช้ PDK ที่ cache ไว้ ใช้เวลา **~87–98 วินาที**

PDK จะถูกเก็บที่:

```
/root/.ciel/ciel/sky130/versions/<commit-hash>/sky130A/
```

> **PDK sky130A เป็น open-source (Apache-2.0)** — ดาวน์โหลดฟรี ใช้เชิงพาณิชย์ได้
> และเป็น PDK ที่ใช้กันอย่างแพร่หลายในงาน open silicon

### 2.4 กรณีติดตั้ง PDK เอง (ไม่มีเน็ต หรือใช้ PDK ขององค์กร)

```bash
librelane --manual-pdk -p sky130A config.yaml
```

ต้องเตรียมโครงสร้างไดเรกทอรีตามที่ Ciel/Volare กำหนด และตั้งค่า path ใน
`~/.volare/` หรือผ่าน `PDK_ROOT` — ดูเอกสารของ Volare ประกอบ

---

## 3. การรัน

### 3.1 คำสั่งหลัก

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3_yosys/librelane"

# แบบเต็ม (ดาวน์โหลด PDK อัตโนมัติ)
librelane --volare-pdk -p sky130A config.yaml

# ถ้ามี PDK อยู่แล้ว
librelane -p sky130A config.yaml
```

### 3.2 ผ่าน Makefile (ทางลัด)

```bash
make flow     # = librelane --volare-pdk -p $(PDK) config.yaml
make clean    # = rm -rf runs
```

เปลี่ยน PDK ได้ด้วย `make flow PDK=ihp-sg13g2`

### 3.3 รันจากระดับแล็บ

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3_yosys"
make librelane
# หรือ
bash run_yosys_lab.sh --full
```

> **หมายเหตุเรื่อง path:** ถ้าอยู่ใน WSL และ path มีวงเล็บ เช่น `/mnt/e/lab/VHDL(BOI)/...`
> ต้องห่อด้วย `"` เสมอ ไม่งั้น shell จะตีความ `(BOI)` เป็น subshell แล้วคำสั่งพัง

---

## 4. ไฟล์ `config.yaml`

```yaml
DESIGN_NAME: adder8_pipe
VERILOG_FILES: dir::src/*.v
CLOCK_PORT: clk
CLOCK_PERIOD: 10          # ns -> 100 MHz

PNR_SDC_FILE: dir::src/impl.sdc
SIGNOFF_SDC_FILE: dir::src/signoff.sdc

PDN_VOFFSET: 5
PDN_HOFFSET: 5
PDN_VWIDTH: 2
PDN_HWIDTH: 2
PDN_VPITCH: 30
PDN_HPITCH: 30
PDN_SKIPTRIM: true

pdk::sky130*:
  FP_CORE_UTIL: 45
  CLOCK_PERIOD: 10.0

pdk::ihp*:
  FP_CORE_UTIL: 40
  CLOCK_PERIOD: 10.0

pdk::gf180mcu*:
  FP_CORE_UTIL: 38
  CLOCK_PERIOD: 24.0
```

### 4.1 คำสั่งที่ต้องรู้

| Key | ความหมาย | ค่าในแล็บนี้ |
| --- | --- | --- |
| `DESIGN_NAME` | ชื่อ design (ต้องตรงกับชื่อ module ใน RTL) | `adder8_pipe` |
| `VERILOG_FILES` | ไฟล์ RTL — `dir::` หมายถึง path สัมพัทธ์จากโฟลเดอร์ config | `dir::src/*.v` |
| `CLOCK_PORT` | ชื่อ port ของนาฬิกา | `clk` |
| `CLOCK_PERIOD` | คาบเวลานาฬิกา (ns) → 10 ns = 100 MHz | 10 |
| `PNR_SDC_FILE` | SDC สำหรับขั้น Place & Route | `dir::src/impl.sdc` |
| `SIGNOFF_SDC_FILE` | SDC สำหรับขั้น sign-off | `dir::src/signoff.sdc` |
| `PDN_*` | ขอบเขตและความกว้างของ Power Distribution Network | V/H width 2 µm, pitch 30 µm |
| `FP_CORE_UTIL` | เปอร์เซ็นต์พื้นที่ core ที่ใช้วางวงจร | 45 % (sky130) |

### 4.2 บล็อก `pdk::<ชื่อ>:` — ค่าเฉพาะตาม PDK

LibreLane จะเลือกใช้บล็อกที่ตรงกับ PDK ที่กำลังรัน **เท่านั้น** ตัวอื่นถูกข้าม
จึงใส่ทั้งสาม PDK ไว้ในไฟล์เดียวได้ โดยไม่ต้องแก้ไฟล์ทุกครั้งที่เปลี่ยน PDK

> `FP_CORE_UTIL` ต่างกันตาม PDK เพราะแต่ละ PDK มีระดับความแน่นของ metal
> และขนาด cell ต่างกัน — ค่าเดียวกันทุก PDK จะทำให้ routing ยากหรือ DRC เพี้ยน

### 4.3 ไฟล์ SDC

`src/impl.sdc` (ใช้ตอน P&R):

```tcl
create_clock -name clk -period 10 [get_ports clk]
set_input_delay 0 -clock clk [all_inputs -no_clocks]
set_output_delay 0 -clock clk [all_outputs]
set_false_path -from [get_ports rst]
```

- `set_input_delay` / `set_output_delay` = 0 เพราะยังไม่มีข้อมูลระบบภายนอกจริง
  ในงานจริงต้องใส่ค่าตามสเปกของระบบที่ design ไปอยู่
- `set_false_path -from [get_ports rst]` = reset เป็น asynchronous control
  จึงไม่ต้องตรวจ timing ทางเข้า reset

---

## 5. โครงสร้างผลลัพธ์

เมื่อรันเสร็จ จะได้โฟลเดอร์ `runs/RUN_<วันที่>_<เวลา>/` เช่น

```
runs/RUN_2026-11-14_09-30-48/
├── 01-verilator-lint/               ┐
├── 02-checker-linttimingconstructs/ │
├── 03-checker-linterrors/           │
├── 04-checker-lintwarnings/         │
├── 05-yosys-jsonheader/             │
├── 06-yosys-synthesis/              │  ← ผังเป็น "stage" ของ flow
├── 07-checker-yosysunmappedcells/   │
├── 08-checker-yosyssynthchecks/     │
│   ...                              │
├── 13-openroad-floorplan/           │
├── 28-openroad-globalplacement/     │
├── 35-openroad-cts/                 │  ← Clock Tree Synthesis
├── 44-openroad-detailedrouting/     │
├── 57-magic-streamout/              │
├── 60-magic-writelef/               │
├── 64-magic-drc/                    │  ← DRC ด้วย Magic
├── 65-klayout-drc/                  │  ← DRC ด้วย KLayout (ตรวจซ้ำ)
├── 68-magic-spiceextraction/        │
├── 70-netgen-lvs/                   │  ← LVS
├── 72-checker-setupviolations/      │
├── 73-checker-holdviolations/       │
├── 76-misc-reportmanufacturability/ │  ← รายงานสรุป
├── final/                           │  ← ผลลัพธ์ทั้งหมด
├── flow.log
├── error.log
├── warning.log
└── resolved.json                    ← config ที่ถูก resolve แล้ว (ตรวจสอบย้อนหลังได้)
```

> LibreLane รายงานว่ารันครบ **80/80 stages**

### 5.1 โฟลเดอร์ `final/`

```
final/
├── metrics.json       ← ตัวเลขทั้งหมด (สำคัญที่สุด)
├── metrics.csv        ← เหมือน metrics.json แต่เป็น CSV
├── gds/
│   └── adder8_pipe.gds              ← GDSII สำหรับส่ง foundry
├── klayout_gds/
│   └── adder8_pipe.klayout.gds      ← GDSII ที่ผ่านการตรวจจาก KLayout
├── mag_gds/                         ← GDSII จาก Magic
├── lef/  adder8_pipe.lef            ← abstract layout
├── def/  adder8_pipe.def            ← design exchange format
├── mag/  adder8_pipe.mag            ← Magic layout
├── spice/ adder8_pipe.spice         ← netlist สำหรับ LVS
├── spef/ {min,nom,max}/             ← parasitic extraction
├── sdf/  {min,nom,max}_{ss,tt,ff}_{100C,025C,1v80,1v60,1v95}/
│                                       ← 9 corners ของ delay
├── nl/  pnl/  odb/  vh/  json_h/  lib/  render/  sdc/
```

> **SDF มี 9 corners** ครอบคลุมทั้ง process (slow/typical/fast), voltage
> (1.60 / 1.80 / 1.95 V) และอุณหภูมิ (100 / 25 / −40 °C) — ใช้ทำ multi-corner STA และ
> เป็นข้อมูลสำหรับ Gate-Level Simulation ใน Day 4

---

## 6. อ่าน `metrics.json`

### 6.1 วิธีดึงตัวเลขหลัก

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3_yosys/librelane"
RUN=$(ls -dt runs/RUN_* | head -1)

python3 - "$RUN/final/metrics.json" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
def g(k, d="n/a"): return m.get(k, d)

print(f"instances        : {g('design__instance__count')}")
print(f"instance area    : {g('design__instance__area')} um^2")
print(f"core area        : {g('design__core__area')} um^2")
print(f"die area         : {g('design__die__area')} um^2")
print(f"utilization      : {g('design__instance__utilization')}")
print(f"nets / io        : {g('design__nets')} / {g('design__io')}")
print(f"setup slack      : {g('timing__setup__ws')} ns")
print(f"hold slack       : {g('timing__hold__ws')} ns")
print(f"violations       : {g('design__violations')}")
print(f"latch inferred   : {g('design__inferred_latch__count')}")
PY
```

### 6.2 ผลลัพธ์จริงของแล็บนี้

```
instances        : 399
instance area    : 2409.81 um^2
core area        : 2409.81 um^2
die area         : 4331.89 um^2
utilization      : 0.689512
nets / io        : 158 / 30
setup slack      : 5.587221510260848 ns
hold slack       : 0.31714126666902775 ns
violations       : 0
latch inferred   : 0
```

### 6.3 ตาราง key ที่ควรรู้

| Key | ความหมาย | ค่าที่วัดได้ |
| --- | --- | --- |
| `design__instance__count` | จำนวน instance ทั้งหมด | **399** |
| `design__instance__count__stdcell` | เฉพาะ standard cell | 167 |
| `design__instance__count__class:fill_cell` | เซลล์เติมพื้นที่ว่าง | 232 |
| `design__instance__count__class:timing_repair_buffer` | buffer ที่ OpenROADเพิ่มเพื่อแก้ timing | 44 |
| `design__instance__count__class:tap_cell` | tap cell (ยึง substrate / well tie) | 30 |
| `design__instance__count__class:clock_buffer` | buffer ของ clock tree | 3 |
| `design__instance__count__class:sequential_cell` | flip-flop ทั้งหมด | 26 |
| `design__instance__count__class:multi_input_combinational_cell` | gate แบบหลายอินพุต | 64 |
| `design__instance__area` | พื้นที่ instance ทั้งหมด (µm²) | **2409.81** |
| `design__core__area` | พื้นที่ core (µm²) | 2409.81 |
| `design__core__bbox` | กรอบ core (µm) | `5.52 10.88 54.74 59.84` |
| `design__die__area` | พื้นที่ die ทั้งหมด (µm²) | **4331.89** |
| `design__die__bbox` | กรอบ die (µm) | `0.0 0.0 60.675 71.395` |
| `design__instance__utilization` | สัดส่วนที่ใช้จริง | 0.6895 (68.95 %) |
| `design__nets` / `design__io` | จำนวน net / ขา I/O | 158 / 30 |
| `design__rows` / `design__sites` | แถวและ site ของ standard cell row | 18 / 1926 |
| `design__violations` | violation รวมทุกชนิด | **0** |
| `design__inferred_latch__count` | latch ที่ถูกอนุมานมา (ควรเป็น 0) | 0 |
| `design__instance_unmapped__count` | cell ที่ map ไม่ลง (ควรเป็น 0) | 0 |
| `design__max_slew_violation__count` | violation ของ slew limit | 0 |
| `design__max_cap_violation__count` | violation ของ capacitance limit | 0 |
| `design__max_fanout_violation__count` | violation ของ fanout limit | 0 |
| `design__power_grid_violation__count` | violation ของ power grid | 0 |
| `design__lint_error__count` | error จาก lint | 0 |
| `design__lint_warning__count` | warning จาก lint | 446 |
| `timing__setup__ws` | worst setup slack (ns) | **5.587222** |
| `timing__setup__wns` / `timing__setup__tns` | worst/total negative slack | 0 / 0 |
| `timing__hold__ws` | worst hold slack (ns) | **0.317141** |
| `timing__hold__wns` / `timing__hold__tns` | worst/total negative slack | 0 / 0 |
| `timing__hold_vio__count` | จำนวน hold violation | 0 |
| `clock__skew__worst_setup` / `__worst_hold` | clock skew (ns) | −0.005835 / −0.002058 |
| `antenna__violating__nets` / `__pins` | antenna violation | 0 / 0 |
| `design__lvs_error__count` | error ของ LVS | 0 |
| `design__lvs_device_difference__count` | อุปกรณ์ต่างกันใน LVS | 0 |
| `design__lvs_net_difference__count` | net ต่างกันใน LVS | 0 |
| `design__xor_difference__count` | XOR difference ระหว่าง Magic/KLayout | 0 |
| `power__total` | กำลังรวม (W) | 0.0002719 (271.9 µW) |
| `power__internal__total` | switching + leakage (W) | 0.0002177 |
| `power__switching__total` | switching power (W) | 0.00005427 |
| `power__leakage__total` | leakage power (W) | 2.477e−09 |
| `design__instance__displacement__max` / `__mean` | ระยะเลื่อน cell สูงสุด / เฉลี่ย (µm) | 14.14 / 1.035 |

### 6.4 ดูค่าที่เจาะจง corner

```bash
python3 -c "import json; m=json.load(open('$RUN/final/metrics.json')); \
[print(k,'=',v) for k,v in sorted(m.items()) if 'corner:min_tt' in k]"
```

ตัวอย่าง setup slack ต่อ corner:

| Corner | setup slack (ns) |
| --- | --- |
| `min_tt_025C_1v80` | 8.640904 |
| `nom_tt_025C_1v80` | 7.826130 |
| `max_tt_025C_1v80` | 5.587222 |
| `max_ss_100C_1v60` | 5.587222 (ค่าต่ำสุด) |

> `timing__setup__ws` ที่รายงานคือ **ค่าต่ำสุดของทุก corner** (worst case) = 5.587222 ns

---

## 7. คำนวณ Fmax

```
setup slack        = 5.587222 ns
clock period       = 10 ns

critical path      = 10 - 5.587222 = 4.412778 ns
Fmax               = 1 / 4.412778 ns ≈ 226.6 MHz
```

> เชื่อมกลับไปหัวข้อ **3.3 Timing Analysis เบื้องต้น** ของคู่มือหลัก
> นักเรียนได้ฝึกอ่าน slack จากเครื่องมือฟรี ซึ่งเป็นทักษะเดียวกับที่ใช้กับ Precision RTL

**ข้อควรระวัง:** ค่านี้เป็น slack ของ **worst corner** หลัง CTS และรวมผลของ
routing delay แล้ว ไม่ใช่ delay ของ combinational logic อย่างเดียว
ตัวเลข Fmax จริงต้องมาจากการวิเคราะห์ทุก corner ร่วมกัน

---

## 8. เปลี่ยน PDK

### 8.1 รองรับ PDK อะไรได้บ้าง

| PDK | สถานะ | หมายเหตุ |
| --- | --- | --- |
| `sky130A` | ✅ ใช้จริงในแล็บนี้ | open-source, ดาวน์โหลดอัตโนมัติ |
| `sky130B` | ✅ | ชุดเดียวกัน เป็น PDK ของ Google ใช้ production ได้ |
| `ihp-sg13g2` | ⚠️ ต้องติดตั้งเอง | PDK ของ IHP — ใกล้เคียงกับที่ใช้ในคอร์ส |
| `gf180mcu` | ⚠️ ต้องติดตั้งเอง | open-source PDK ของ GlobalFoundries |
| `asap7` | ✅ | PDK สมมติสำหรับงานวิจัย |

### 8.2 วิธีเปลี่ยน

แก้บล็อก `pdk::` ใน `config.yaml` ให้ตรงกับ PDK ที่ใช้ แล้วรัน:

```bash
# sky130A (ค่าเริ่มต้น)
librelane --volare-pdk -p sky130A config.yaml

# IHP SG13G2
librelane --volare-pdk -p ihp-sg13g2 config.yaml

# ผ่าน Makefile
make flow PDK=ihp-sg13g2
```

### 8.3 สิ่งที่ต้องตรวจเมื่อเปลี่ยน PDK

| รายการ | ต้องทำอะไร |
| --- | --- |
| `CLOCK_PERIOD` | ตั้งใหม่ตาม speed grade ของ PDK (sky130 10 ns, gf180 24 ns) |
| `FP_CORE_UTIL` | ค่าเริ่มต้นต่างกันตาม PDK — ใช้ค่าในบล็อก `pdk::` ที่เตรียมไว้ |
| PDN | ความกว้าง/pitch ของ metal อาจต้องปรับตาม metal stack ของ PDK |
| SDC | ตรวจชื่อ port ของ clock/reset ให้ตรงกับ RTL ที่เปลี่ยนไป |
| Timing | ตัวเลข slack ของ PDK ใหม่จะต่างจากเดิมทั้งหมด — ห้ามยกตัวเลขเดิมไปใช้ |

---

## 9. เปิดดูผลลัพธ์

### 9.1 เปิด GDSII ด้วย KLayout

```bash
klayout "$RUN/final/klayout_gds/adder8_pipe.klayout.gds"
```

### 9.2 ดูภาพเรนเดอร์ที่ LibreLane สร้างไว้

```bash
ls "$RUN/final/render/"
```

LibreLane สร้างภาพ PNG ของ layout ไว้ให้ดูในเว็บแดชบอร์ด และเขียนไว้ใน `final/render/`

### 9.3 ตรวจ DRC / LVS ซ้ำด้วยตัวเอง

```bash
# DRC ด้วย Magic
magic -dnull -noconsole -rcfile /path/to/sky130.magicrc "$RUN/final/mag/adder8_pipe.mag"

# LVS ด้วย Netgen
netgen -batch lvs "$RUN/final/spice/adder8_pipe.spice" "$RUN/final/spice/adder8_pipe.spice" \
       "$RUN/final/mag/adder8_pipe.mag" report.lvs
```

---

## 10. Troubleshooting

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| `librelane: command not found` | ยังไม่ได้ติดตั้งผ่าน nix | `nix profile install nixpkgs#librelane` แล้วเพิ่ม `/root/.nix-profile/bin` ใน PATH |
| `Unable to find PDK sky130A` | ยังไม่ได้ดาวน์โหลด | รันด้วย `--volare-pdk` หรือใช้ `--manual-pdk` |
| ดาวน์โหลด PDK ไม่สำเร็จ | ปัญหาเครือข่าย / proxy | รันซ้ำ หรือติดตั้ง PDK เองแล้วใช้ `--manual-pdk` |
| `Can't find top module 'X'` | `DESIGN_NAME` ไม่ตรงกับชื่อ module ใน RTL | ตรวจชื่อ module ใน `src/*.v` ให้ตรงกับ `DESIGN_NAME` |
| `Can't find clock port 'clk'` | `CLOCK_PORT` ไม่ตรง | ตรวจชื่อ port ใน RTL |
| DRC violation เยอะ | utilization สูงเกิน | ลด `FP_CORE_UTIL` ใน `config.yaml` |
| LVS mismatch | RTL ↔ layout ไม่ตรง | ตรวจ blackbox / tie cell / ชื่อสัญญาณ |
| setup violation | clock period สั้นเกินไป | เพิ่ม `CLOCK_PERIOD` หรือปรับ optimization |
| `runs/` ใหญ่ขึ้นเรื่อย ๆ | เก็บทุกรอบ | `cd librelane && make clean` (รันครั้งละ ~58 MB) |
| path มีวงเล็บทำให้คำสั่งพัง | shell ไม่ escape | ห่อด้วย `"` เช่น `cd "/mnt/e/lab/VHDL(BOI)/..."` |

---

## 11. ข้อควรระวังเรื่องตัวเลข

> ⚠️ **ตัวเลขทุกตัวในเอกสารชุดนี้มาจากการรันจริง**
> เมื่อเปลี่ยน PDK, `CLOCK_PERIOD`, `FP_CORE_UTIL` หรือแก้ RTL
> **ตัวเลขทุกตัวจะเปลี่ยนตามไปด้วย**
> ห้ามนำตัวเลขจาก PDK/ค่าคอนฟิกอื่นมาอ้างว่าเป็นผลของแล็บนี้
>
> วิธีตรวจสอบว่าตัวเลขในเอกสารยังตรงกับเครื่อง:
> ```bash
> cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3_yosys/librelane"
> RUN=$(ls -dt runs/RUN_* | head -1)
> python3 -c "import json; m=json.load(open('$RUN/final/metrics.json')); \
>   print('instances', m['design__instance__count']); \
>   print('setup ws ', m['timing__setup__ws']); \
>   print('hold ws  ', m['timing__hold__ws'])"
> ```

---

> **ต่อไป:** กลับไป [`../README.md`](../README.md) เพื่อดูผลรวมของ Lab 3B ทั้งหมด
> หรือ [`../../../Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md`](../../../Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md) สำหรับขั้นตอนละเอียด

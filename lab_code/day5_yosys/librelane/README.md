# LibreLane — RTL-to-GDSII Full Chip Flow สำหรับ Lab 5B

> เอกสารประกอบ `config.yaml` ของ **Lab 5B** — แล็บเสริมของวันที่ 5 ในหลักสูตร
> Advanced Digital IC and MEMS Design with EDA Verification and Simulation Tools
>
> **คู่มือฉบับเต็ม:** [`../../../Manual_5_5_Lab5B_UART_TX_to_GDSII_LibreLane_StepByStepGuide.md`](../../../Manual_5_5_Lab5B_UART_TX_to_GDSII_LibreLane_StepByStepGuide.md)
> **ภาคทฤษฎี:** [`../../../Manual_5_4_RTL_to_GDSII_LibreLane_FullChipFlow_DeepDive.md`](../../../Manual_5_4_RTL_to_GDSII_LibreLane_FullChipFlow_DeepDive.md)
> **README ของทั้งแล็บ:** [`../README.md`](../README.md)

---

## 1. LibreLane คืออะไร

LibreLane คือ **open-source ASIC design flow** ที่รวมเครื่องมือสังเคราะห์และ layout
ทั้งชุดเข้าด้วยกันในรูปแบบที่ "ย่อยกว่าการต้องเรียกแต่ละเครื่องมือเอง"

```
        RTL (Verilog) — uart_top.v
            │
            ▼
    ┌───────────────────────┐
    │  Yosys + Verilator    │  lint + synthesis → netlist
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
          uart_top.gds
```

**จุดขายหลัก:** ทุกอย่างเป็น open-source, ติดตั้งผ่าน `nix` ได้ในคำสั่งเดียว,
มี PDK ฟรี (sky130) และผลลัพธ์เป็น GDSII จริงที่นำไปส่ง foundry ได้

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

### 2.2 ⚠️ nix profile ใน non-interactive shell

`nix profile` **ไม่ถูกโหลดอัตโนมัติ** เมื่อเปิด WSL หรือรันสคริปต์แบบ non-interactive
จึงได้ `librelane: command not found` แม้ติดตั้งไว้เรียบร้อยแล้ว

```bash
# ตรวจว่ามีจริงไหม
ls -l /root/.nix-profile/bin/librelane

# แก้ชั่วคราว
export PATH="/root/.nix-profile/bin:$PATH"
```

> `Makefile` และ `run_yosys_lab.sh` ของแล็บนี้ **ตรวจและเพิ่ม path ให้เอง**
> จึงไม่ต้อง export เองก็รันได้

### 2.3 ตรวจสอบว่าติดตั้งสำเร็จ

```bash
librelane --version
# → LibreLane v3.0.17

klayout -v
mag -version
netgen -batch quit
```

### 2.4 PDK — ติดตั้งอัตโนมัติ

PDK ไม่ต้องติดตั้งเอง — ใช้ flag `--volare-pdk` แล้ว LibreLane จะดาวน์โหลดมาให้เอง:

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day5_yosys/librelane"
librelane --volare-pdk -p sky130A config.yaml
```

- ครั้งแรก: ดาวน์โหลด PDK **ประมาณ 1–2 GB** ใช้เวลา 2–4 นาที (ขึ้นกับความเร็วเน็ต)
- ครั้งต่อไป: ใช้ PDK ที่ cache ไว้ ใช้เวลา **~106–109 วินาที**

PDK จะถูกเก็บที่:

```
/root/.ciel/ciel/sky130/versions/<commit-hash>/sky130A/
```

> **PDK sky130A เป็น open-source (Apache-2.0)** — ดาวน์โหลดฟรี ใช้เชิงพาณิชย์ได้
> และเป็น PDK ที่ใช้กันอย่างแพร่หลายในงาน open silicon

### 2.5 กรณีติดตั้ง PDK เอง (ไม่มีเน็ต หรือใช้ PDK ขององค์กร)

```bash
librelane --manual-pdk -p sky130A config.yaml
```

ต้องเตรียมโครงสร้างไดเรกทอรีตามที่ Ciel/Volare กำหนด และตั้งค่า path ใน
`~/.volare/` หรือผ่าน `PDK_ROOT` — ดูเอกสารของ Volare ประกอบ

---

## 3. การรัน

### 3.1 คำสั่งหลัก

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day5_yosys/librelane"

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
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day5_yosys"
make librelane
# หรือ
bash run_yosys_lab.sh --full
```

> **หมายเหตุเรื่อง path:** ถ้าอยู่ใน WSL และ path มีวงเล็บ เช่น `/mnt/e/lab/VHDL(BOI)/...`
> ต้องห่อด้วย `"` เสมอ ไม่งั้น shell จะตีความ `(BOI)` เป็น subshell แล้วคำสั่งพัง

---

## 4. ไฟล์ `config.yaml`

```yaml
DESIGN_NAME: uart_top
VERILOG_FILES: dir::../rtl/*.v
CLOCK_PORT: clk
CLOCK_PERIOD: 10

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
| `DESIGN_NAME` | ชื่อ design (ต้องตรงกับชื่อ module ใน RTL) | `uart_top` |
| `VERILOG_FILES` | ไฟล์ RTL — `dir::` หมายถึง path สัมพัทธ์จากโฟลเดอร์ config | `dir::../rtl/*.v` |
| `CLOCK_PORT` | ชื่อ port ของนาฬิกา | `clk` |
| `CLOCK_PERIOD` | คาบเวลานาฬิกา (ns) → 10 ns = 100 MHz | 10 |
| `PNR_SDC_FILE` | SDC สำหรับขั้น Place & Route | `dir::src/impl.sdc` |
| `SIGNOFF_SDC_FILE` | SDC สำหรับขั้น sign-off | `dir::src/signoff.sdc` |
| `PDN_*` | ขอบเขตและความกว้างของ Power Distribution Network | V/H width 2 µm, pitch 30 µm |
| `FP_CORE_UTIL` | เปอร์เซ็นต์พื้นที่ core ที่ใช้วางวงจร | 45 % (sky130) |

> **`dir::../rtl/*.v`** คือ path สัมพัทธ์จากโฟลเดอร์ที่วาง `config.yaml`
> เนื่องจาก `config.yaml` อยู่ใน `day5_yosys/librelane/` จึงต้องขึ้นหนึ่งระดับ
> เพื่อไปถึง `day5_yosys/rtl/` — จึง **ไม่มีสำเนา RTL สองชุด** ที่ต้องแก้พร้อมกัน

### 4.2 บล็อก `pdk::<ชื่อ>:` — ค่าเฉพาะตาม PDK

LibreLane จะเลือกใช้บล็อกที่ตรงกับ PDK ที่กำลังรัน **เท่านั้น** ตัวอื่นถูกข้าม
จึงใส่ทั้งสาม PDK ไว้ในไฟล์เดียวได้ โดยไม่ต้องแก้ไฟล์ทุกครั้งที่เปลี่ยน PDK

> `FP_CORE_UTIL` ต่างกันตาม PDK เพราะแต่ละ PDK มีระดับความแน่นของ metal
> และขนาด cell ต่างกัน — ค่าเดียวกันทุก PDK จะทำให้ routing ยากหรือ DRC เพี้ยน

### 4.3 ไฟล์ SDC

`src/impl.sdc` (ใช้ตอน P&R) และ `src/signoff.sdc` (ใช้ตอน sign-off):

```tcl
create_clock -name clk -period 10 [get_ports clk]
set_input_delay 0 -clock clk [all_inputs -no_clocks]
set_output_delay 0 -clock clk [all_outputs]
set_false_path -from [get_ports rst]
```

- `set_input_delay` / `set_output_delay` = 0 เพราะยังไม่มีข้อมูลระบบภายนอกจริง
  ในงานจริงต้องใส่ค่าตามสเปกของระบบที่ design ไปอยู่
- `set_false_path -from [get_ports rst]` = reset เป็น synchronous control
  จึงไม่ต้องตรวจ timing ทางเข้า reset

---

## 5. โครงสร้างผลลัพธ์

เมื่อรันเสร็จ จะได้โฟลเดอร์ `runs/RUN_<วันที่>_<เวลา>/` เช่น

```
runs/RUN_2026-11-14_10-08-39/
├── 01-verilator-lint/               ┐
├── 02-checker-linttimingconstructs/ │
├── 03-checker-linterrors/           │
├── 05-yosys-jsonheader/             │
├── 06-yosys-synthesis/              │  ← ผังเป็น "stage" ของ flow
├── 10-openroad-checksdcfiles/       │
├── 13-openroad-floorplan/           │
├── 24-openroad-globalplacementskipio/│
├── 28-openroad-globalplacement/     │
├── 35-openroad-cts/                 │  ← Clock Tree Synthesis
├── 39-openroad-globalrouting/       │
├── 44-openroad-detailedrouting/     │
├── 52-openroad-fillinsertion/       │
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
├── error.log                        │  ← ต้องเป็น 0 bytes
├── warning.log
└── resolved.json                    ← config ที่ถูก resolve แล้ว (ตรวจย้อนหลังได้)
```

> LibreLane รายงานว่ารันครบ **80/80 stages** (มี 76 โฟลเดอร์ตัวเลข + สรุป)

### 5.1 โฟลเดอร์ `final/`

```
final/
├── metrics.json       ← ตัวเลขทั้งหมด (สำคัญที่สุด)
├── metrics.csv        ← เหมือน metrics.json แต่เป็น CSV
├── gds/
│   └── uart_top.gds                 517,382 bytes
├── klayout_gds/
│   └── uart_top.klayout.gds         374,124 bytes
├── mag_gds/
├── lef/  uart_top.lef      4,273 bytes
├── def/  uart_top.def    150,629 bytes
├── mag/  uart_top.mag    317,921 bytes
├── spice/ uart_top.spice   39,980 bytes
├── spef/ {min,nom,max}/             ← parasitic 3 ชุด
├── sdf/  9 corners/                 ← delay ทุก corner
├── nl/  pnl/  odb/  vh/  json_h/  lib/  render/  sdc/
```

> **SDF มี 9 corners** ครอบคลุมทั้ง process (slow/typical/fast), voltage
> (1.60 / 1.80 / 1.95 V) และอุณหภูมิ (100 / 25 / −40 °C) — ใช้ทำ multi-corner STA และ
> เป็นข้อมูลสำหรับ Gate-Level Simulation ใน Day 4

---

## 6. อ่าน `metrics.json`

### 6.1 วิธีดึงตัวเลขหลัก

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day5_yosys/librelane"
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
instances        : 526
instance area    : 2805.19 um^2
core area        : 2805.19 um^2
die area         : 4975.42 um^2
utilization      : 0.601249
nets / io        : 153 / 15
setup slack      : 6.235697024124814 ns
hold slack       : 0.19157449779892727 ns
violations       : 0
latch inferred   : 0
```

### 6.3 ตาราง key ที่ควรรู้

| Key | ความหมาย | ค่าที่วัดได้ |
| --- | --- | --- |
| `design__instance__count` | instance ทั้งหมด | **526** |
| `design__instance__count__stdcell` | เฉพาะ standard cell | 183 |
| `design__instance__count__class:fill_cell` | เซลล์เติมพื้นที่ว่าง | 343 |
| `design__instance__count__class:timing_repair_buffer` | buffer ที่ OpenROAD เพิ่มเพื่อแก้ timing | 20 |
| `design__instance__count__class:tap_cell` | tap cell (ยึง substrate / well tie) | 42 |
| `design__instance__count__class:clock_buffer` | buffer ของ clock tree | 3 |
| `design__instance__count__class:sequential_cell` | flip-flop ทั้งหมด | 28 |
| `design__instance__count__class:multi_input_combinational_cell` | gate แบบหลายอินพุต | 84 |
| `design__instance__area` | พื้นที่ instance ทั้งหมด (µm²) | **2805.19** |
| `design__instance__area__class:fill_cell` | พื้นที่ fill cell | 1118.57 |
| `design__instance__area__class:multi_input_combinational_cell` | พื้นที่ gate | 714.44 |
| `design__instance__area__class:sequential_cell` | พื้นที่ flip-flop | 595.57 |
| `design__instance__area__class:timing_repair_buffer` | พื้นที่ timing buffer | 200.19 |
| `design__instance__area__class:clock_buffer` | พื้นที่ clock buffer | 75.07 |
| `design__instance__area__class:tap_cell` | พื้นที่ tap cell | 52.55 |
| `design__core__area` | พื้นที่ core (µm²) | 2805.19 |
| `design__core__bbox` | กรอบ core (µm) | `5.52 10.88 59.8 62.56` |
| `design__die__area` | พื้นที่ die ทั้งหมด (µm²) | **4975.42** |
| `design__die__bbox` | กรอบ die (µm) | `0.0 0.0 65.38 76.1` |
| `design__instance__utilization` | สัดส่วนที่ใช้จริง | 0.601249 (60.12 %) |
| `design__nets` / `design__io` | จำนวน net / ขา I/O | 153 / 15 |
| `design__rows` / `design__sites` | แถวและ site ของ standard cell row | 19 / 2242 |
| `design__violations` | violation รวมทุกชนิด | **0** |
| `design__inferred_latch__count` | latch ที่ถูกอนุมานมา (ควรเป็น 0) | 0 |
| `design__instance_unmapped__count` | cell ที่ map ไม่ลง (ควรเป็น 0) | 0 |
| `design__max_slew_violation__count` | violation ของ slew limit | 0 |
| `design__max_cap_violation__count` | violation ของ capacitance limit | 0 |
| `design__max_fanout_violation__count` | violation ของ fanout limit | 0 |
| `design__power_grid_violation__count` | violation ของ power grid | 0 |
| `design__lint_error__count` / `__warning__count` | error / warning จาก lint | 0 / 0 |
| `timing__setup__ws` | worst setup slack (ns) | **6.235697** |
| `timing__setup__wns` / `timing__setup__tns` | worst/total negative slack | 0 / 0 |
| `timing__hold__ws` | worst hold slack (ns) | **0.191574** |
| `timing__hold__wns` / `timing__hold__tns` | worst/total negative slack | 0 / 0 |
| `timing__hold_vio__count` / `timing__setup_vio__count` | จำนวน violation | 0 / 0 |
| `clock__skew__worst_setup` / `__worst_hold` | clock skew (ns) | 0.002564 / 0.006135 |
| `antenna__violating__nets` / `__pins` | antenna violation | 0 / 0 |
| `design__lvs_error__count` | error ของ LVS | 0 |
| `design__lvs_device_difference__count` | อุปกรณ์ต่างกันใน LVS | 0 |
| `design__lvs_net_difference__count` | net ต่างกันใน LVS | 0 |
| `design__lvs_unmatched_device__count` | อุปกรณ์ที่จับคู่ไม่ได้ | 0 |
| `design__lvs_unmatched_net__count` | net ที่จับคู่ไม่ได้ | 0 |
| `design__lvs_unmatched_pin__count` | pin ที่จับคู่ไม่ได้ | 0 |
| `design__lvs_property_fail__count` | property ไม่ตรง | 0 |
| `design__xor_difference__count` | XOR difference ระหว่าง Magic/KLayout | 0 |
| `power__total` | กำลังรวม (W) | 0.00030398 (303.98 µW) |
| `power__internal__total` | switching + leakage (W) | 0.00024563 |
| `power__switching__total` | switching power (W) | 0.00005834 |
| `power__leakage__total` | leakage power (W) | 2.929e−09 |

### 6.4 ดูค่าที่เจาะจง corner

```bash
python3 -c "import json; m=json.load(open('$RUN/final/metrics.json')); \
[print(f'{k:48s} {m[k]:.6f}') for k in sorted(m) if 'corner:' in k]"
```

| Corner | setup slack (ns) | hold slack (ns) |
| --- | --- | --- |
| `min_ff_n40C_1v95` | 8.965368 | **0.191574** ← worst hold |
| `nom_ff_n40C_1v95` | 8.958746 | 0.194052 |
| `max_ff_n40C_1v95` | 8.951070 | 0.194872 |
| `min_tt_025C_1v80` | 8.300024 | 0.308719 |
| `nom_tt_025C_1v80` | 8.289632 | 0.312889 |
| `max_tt_025C_1v80` | 8.277832 | 0.315234 |
| `min_ss_100C_1v60` | 6.274457 | 0.618923 |
| `nom_ss_100C_1v60` | 6.256837 | 0.626525 |
| **`max_ss_100C_1v60`** | **6.235697** ← worst setup | 0.632267 |

> `timing__setup__ws` / `timing__hold__ws` ที่รายงานคือ **ค่าต่ำสุดของทุก corner** (worst case)

---

## 7. คำนวณ Fmax

```
setup slack        = 6.235697 ns
clock period       = 10 ns

critical path      = 10 - 6.235697 = 3.764303 ns
Fmax               = 1 / 3.764303 ns ≈ 265.7 MHz
```

> **ข้อควรระวัง:** ค่านี้เป็น slack ของ **worst corner** หลัง CTS และรวมผลของ
> routing delay แล้ว ไม่ใช่ delay ของ combinational logic อย่างเดียว
> และ **ยังไม่รวม I/O delay และ clock uncertainty** (ตั้งไว้เป็น 0 ในแล็บนี้)
> ตัวเลข Fmax จริงต้องมาจากการวิเคราะห์ทุก corner ร่วมกับข้อกำหนดระบบภายนอก

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
klayout "$RUN/final/klayout_gds/uart_top.klayout.gds"
```

### 9.2 ดูภาพเรนเดอร์ที่ LibreLane สร้างไว้

```bash
ls "$RUN/final/render/"
```

LibreLane สร้างภาพ PNG ของ layout ไว้ให้ดูในเว็บแดชบอร์ด และเขียนไว้ใน `final/render/`

### 9.3 ตรวจ DRC / LVS ซ้ำด้วยตัวเอง

```bash
# DRC ด้วย Magic
magic -dnull -noconsole -rcfile /path/to/sky130.magicrc "$RUN/final/mag/uart_top.mag"

# LVS ด้วย Netgen
netgen -batch lvs "$RUN/final/spice/uart_top.spice" "$RUN/final/spice/uart_top.spice" \
       "$RUN/final/mag/uart_top.mag" report.lvs
```

### 9.4 ตรวจ log

```bash
wc -c "$RUN/error.log" "$RUN/warning.log"    # error.log ต้องเป็น 0 bytes
tail -30 "$RUN/flow.log"                     # ต้องจบด้วย "Flow complete."
```

> `warning.log` ที่พบในแล็บนี้เป็นข้อความ **ไม่เป็นอันตราย**:
> `[PDN-1051]` ไม่มี macro instance, `[STA-1140]` liberty ซ้ำ (หลาย corner),
> `[DRT-0349]` KLayout ไม่รองรับ LEF58_ENCLOSURE ที่ไม่มี CUTCLASS

---

## 10. Troubleshooting

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| `librelane: command not found` | nix profile ไม่ถูกโหลดใน non-interactive shell | `export PATH="$HOME/.nix-profile/bin:$PATH"` — Makefile/script ของแล็บทำให้อัตโนมัติแล้ว |
| `Unable to find PDK sky130A` | ยังไม่ได้ดาวน์โหลด | รันด้วย `--volare-pdk` หรือ `--manual-pdk` |
| ดาวน์โหลด PDK ไม่สำเร็จ | ปัญหาเครือข่าย / proxy | รันซ้ำ หรือติดตั้ง PDK เองแล้วใช้ `--manual-pdk` |
| `Can't find top module 'uart_top'` | `DESIGN_NAME` ไม่ตรงกับชื่อ module ใน RTL | ตรวจชื่อ module ใน `../rtl/*.v` ให้ตรงกับ `DESIGN_NAME` |
| `CLOCK_PORT` not found | `CLOCK_PORT` ไม่ตรง | ตรวจชื่อ port ใน RTL และใน `create_clock` |
| `VERILOG_FILES` หาไฟล์ไม่เจอ | path ผิดระดับ | `dir::` คือ relative จากโฟลเดอร์ config — ต้องใช้ `../rtl/*.v` |
| DRC violation เยอะ | utilization สูงเกิน | ลด `FP_CORE_UTIL` ใน `config.yaml` |
| LVS mismatch | RTL ↔ layout ไม่ตรง | ตรวจ blackbox / tie cell / ชื่อสัญญาณ |
| setup violation | clock period สั้นเกินไป | เพิ่ม `CLOCK_PERIOD` หรือปรับ optimization |
| hold violation | clock skew มากเกินไป / routing สั้นเกินไป | ให้ CTS balance skew, เพิ่ม buffer, ใส่ delay cell |
| Antenna violation | net ต่อกับ poly เยอะ | เปิด antenna repair ใน OpenROAD |
| `flow complete` แต่ไม่มี `final/` | รันไม่จบ | ดู `error.log` และ `flow.log` |
| `runs/` ใหญ่ขึ้นเรื่อย ๆ | เก็บทุกรอบ | `cd librelane && make clean` |
| path มีวงเล็บทำให้คำสั่งพัง | shell ไม่ escape | ห่อด้วย `"` เช่น `cd "/mnt/e/lab/VHDL(BOI)/..."` |

---

## 11. ข้อควรระวังเรื่องตัวเลข

> ⚠️ **ตัวเลขทุกตัวในเอกสารชุดนี้มาจากการรันจริง**
> เมื่อเปลี่ยน PDK, `CLOCK_PERIOD`, `FP_CORE_UTIL`, I/O delay หรือแก้ RTL
> **ตัวเลขทุกตัวจะเปลี่ยนตามไปด้วย**
> ห้ามนำตัวเลขจาก PDK/ค่าคอนฟิกอื่นมาอ้างว่าเป็นผลของแล็บนี้
>
> วิธีตรวจสอบว่าตัวเลขในเอกสารยังตรงกับเครื่อง:
> ```bash
> cd "/mnt/e/lab/VHDL(BOI)/lab_code/day5_yosys/librelane"
> RUN=$(ls -dt runs/RUN_* | head -1)
> python3 -c "import json; m=json.load(open('$RUN/final/metrics.json')); \
>   print('instances', m['design__instance__count']); \
>   print('die area  ', m['design__die__area']); \
>   print('setup ws ', m['timing__setup__ws']); \
>   print('hold ws  ', m['timing__hold__ws'])"
> ```

---

> **ต่อไป:** กลับไป [`../README.md`](../README.md) เพื่อดูผลรวมของ Lab 5B ทั้งหมด
> หรือ [`../../../Manual_5_5_Lab5B_UART_TX_to_GDSII_LibreLane_StepByStepGuide.md`](../../../Manual_5_5_Lab5B_UART_TX_to_GDSII_LibreLane_StepByStepGuide.md) สำหรับขั้นตอนละเอียด

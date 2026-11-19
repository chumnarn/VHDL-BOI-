# lab_code/day3_synthesis — ชุดตัวอย่าง VHDL Synthesis สำหรับหัวข้อ 3.8

> โค้ดประกอบของ [`Manual_3_8_VHDL_Synthesis_DeepDive.md`](../../Manual_3_8_VHDL_Synthesis_DeepDive.md)
> ทุกตัวอย่างในคู่มือสังเคราะห์จริงได้ และทุกตัวเลขในคู่มือมาจากการรันจริงบนเครื่อง

---

## 1. ต้องมีเครื่องมืออะไร

| เครื่องมือ | เวอร์ชันที่ใช้จริง | หมายเหตุ |
|---|---|---|
| GHDL | **5.0.1** (Ubuntu 26.04, mcode) | ใช้ `ghdl synth` แปลง VHDL → Verilog |
| Yosys | **0.52** (git fee39a328) | ใช้สังเคราะห์จริง + map เข้า PDK |
| Icarus Verilog | **12.0** | ใช้ทำ Gate-Level Simulation |
| PDK sky130A | `sky130_fd_sc_hd__tt_025C_1v80.lib` | ใช้วัด chip area จริง |
| LibreLane | v3.0.17 | มีในรอบวันที่ 3/5 (ไม่จำเป็นสำหรับหัวข้อนี้) |

> **ไม่ต้องมี license** — ทั้งหมดเป็น open-source
> ตรวจสอบสภาพแวดล้อมด้วย `bash check_tools.sh`

---

## 2. โครงสร้างไฟล์

```text
lab_code/day3_synthesis/
├── README.md                    ◀ ไฟล์นี้
├── check_tools.sh               ◀ ตรวจเครื่องมือในเครื่อง
├── run_everything.sh            ◀ รันทุกอย่าง (synthesis + proof + GLS)
├── run_all.sh                   ◀ รัน synthesis ทุกตัวอย่าง
├── synth_one.sh                 ◀ สังเคราะห์ 1 ตัว + พิสูจน์ความถูกต้อง
├── run_gls.sh                   ◀ รัน gate-level simulation
├── extract_stats.sh             ◀ ดึงตัวเลขสรุปจาก reports/
├── dump_logs.sh                 ◀ ดู log ของตัวอย่างที่ระบุ
├── rtl/                         ◀ 11 ไฟล์ VHDL (ตัวอย่างสังเคราะห์)
│   ├── alu4.vhd                 ◀ ALU 4-bit combinational (case + numeric_std)
│   ├── counter_sync.vhd         ◀ Counter 8-bit sync reset + clock enable
│   ├── fsm_seq.vhd              ◀ FSM 3 สถานะแบบ Moore
│   ├── adder8.vhd               ◀ Adder 8-bit unsigned + carry out
│   ├── mult8.vhd                ◀ Multiplier 8x8 unsigned
│   ├── shifter.vhd              ◀ Barrel shifter 8-bit
│   ├── lfsr16.vhd               ◀ LFSR 16-bit Galois form
│   ├── latch_bad.vhd            ◀ ❌ ตั้งใจสร้าง LATCH
│   ├── latch_good.vhd           ◀ ✅ เวอร์ชันที่แก้แล้ว (ไม่มี latch)
│   ├── rom_16x8.vhd             ◀ ROM 16x8 จาก constant array
│   └── std_logic_arith_bad.vhd  ◀ ❌ ใช้ std_logic_arith (สังเคราะห์ไม่ผ่าน)
├── verilog/
│   └── latch_ok.v               ◀ รูปแบบ latch ที่ YOSYS เข้าใจถูกต้อง
├── tb/                          ◀ testbench สำหรับ GLS
│   ├── tb_alu4.v                ◀ ตรวจ 1,024 input combinations
│   ├── tb_adder8.v              ◀ ตรวจ 65,536 input combinations
│   ├── tb_latch_bad.v           ◀ คาดหวัง FAIL (พิสูจน์ว่า netlist ผิด)
│   └── tb_latch_ok.v            ◀ คาดหวัง PASS
├── build/                       ◀ เอาต์พุต (สร้างอัตโนมัติ)
│   ├── <tag>.v                  ◀ Verilog จาก GHDL synth
│   ├── <tag>_generic.v          ◀ generic netlist จาก Yosys
│   └── <tag>_sky130.v           ◀ netlist ที่ map เข้า sky130A แล้ว
└── reports/                     ◀ หลักฐานจากการรันจริง
    ├── summary.txt              ◀ ตารางตัวเลขรวมทั้งหมด
    ├── <tag>_ghdl.log           ◀ log ของ GHDL synth
    ├── <tag>_generic.log        ◀ log ของ Yosys generic synthesis
    ├── <tag>_sky130.log         ◀ log ของการ map เข้า PDK
    ├── <tag>_miter.log          ◀ พิสูจน์แบบ miter + SAT
    ├── <tag>_equiv.log          ◀ พิสูจน์แบบ equiv_make + equiv_induct
    ├── gls/                     ◀ log ของ gate-level simulation
    └── run_everything.log       ◀ log รวมของทุกอย่าง
```

---

## 3. วิธีรัน

### 3.1 รันทุกอย่าง (แนะนำ)

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3_synthesis"
bash run_everything.sh
```

ใช้เวลาประมาณ **6–8 นาที** (เครื่องที่มี multi-core)
ผลลัพธ์ทั้งหมดอยู่ใน `reports/` และ `reports/summary.txt`

### 3.2 รันเฉพาะ synthesis

```bash
bash run_all.sh
```

### 3.3 รันเฉพาะ gate-level simulation

```bash
bash run_gls.sh
```

### 3.4 สังเคราะห์ตัวเดียว

```bash
bash synth_one.sh alu4 alu4 "" rtl/alu4.vhd
#              tag   top  flags  ไฟล์ต้นฉบับ

# ตัวที่ต้องใช้ flag เพิ่ม
bash synth_one.sh latch_bad_latched latch_bad "--latches" rtl/latch_bad.vhd
```

### 3.5 ดู log

```bash
bash dump_logs.sh alu4 rom_16x8
```

---

## 4. ผลการรันจริง

### 4.1 ตารางสรุป (จาก `reports/summary.txt`)

| TAG | GHDL | generic cells | sky130 area | miter+sat | equiv_induct | หมายเหตุ |
|---|:---:|---:|---:|:---:|:---:|---|
| `alu4` | 0 | 57 | 208.950400 | PASS | PASS | ALU 4-bit combinational |
| `counter_sync` | 0 | 24 | 280.268800 | FAIL | **PASS** | Counter 8-bit + reset + CE |
| `fsm_seq` | 0 | 26 | 106.352000 | FAIL | **PASS** | FSM 3 สถานะแบบ Moore |
| `adder8` | 0 | 49 | 205.196800 | PASS | PASS | Adder 8-bit + carry |
| `mult8` | 0 | 354 | 1904.326400 | TIMEOUT | **PASS** | Multiplier 8×8 |
| `shifter` | 0 | 146 | 721.942400 | PASS | PASS | Barrel shifter 8-bit |
| `lfsr16` | 0 | 35 | 569.296000 | FAIL | **PASS** | LFSR 16-bit |
| `latch_bad` | **1** | – | – | n/a | FAIL | ❌ ตั้งใจให้ GHDL ปฏิเสศ |
| `latch_bad_latched` | 0 | 0 | – | PASS ⚠️ | PASS ⚠️ | ⚠️ netlist ผิด — จับได้ด้วย GLS |
| `latch_good` | 0 | 1 | 6.256000 | PASS | PASS | เวอร์ชันที่แก้แล้ว |
| `rom_16x8` | 0 | 25 | 113.859200 | PASS | PASS | ROM กลายเป็น mux tree |
| `std_logic_arith_bad` | **1** | – | – | n/a | FAIL | ❌ ตั้งใจให้ GHDL ปฏิเสศ |

```text
PASS=10  FAIL=2  (ทั้งหมด 12 รายการ)
```

> `FAIL=2` คือเคสที่ **ตั้งใจให้ล้มเหลว** เพื่อสาธิต error message จริงของเครื่องมือ
> ดูคู่มือข้อ 3.8.6 (latch) และ 3.8.13 (std_logic_arith)

### 4.2 ผล Gate-Level Simulation

```text
GLS tb_alu4:     checked 1024 combinations, errors = 0   → PASS
GLS tb_adder8:   checked 65536 combinations, errors = 0  → PASS
GLS tb_latch_bad: errors = 1                            → FAIL (คาดหวัง)
GLS tb_latch_ok: errors = 0                            → PASS

GLS SUMMARY: ตรงตามคาด 4 เคส / ไม่ตรง 0 เคส (ทั้งหมด 4 เคส)
```

### 4.3 ข้อความ error จริงที่เก็บไว้

```text
# latch_bad
rtl/latch_bad.vhd:17:3:error: latch infered for net "s" (use --latches)

# std_logic_arith_bad
rtl/std_logic_arith_bad.vhd:6:10:error: use of synopsys package "std_logic_arith" needs the -fsynopsys option
```

---

## 5. สิ่งที่พบระหว่างทำ (บทเรียน)

| # | อาการ | สาเหตุ | วิธีแก้ |
|---|---|---|---|
| 1 | GHDL ไม่ยอมสังเคราะห์ ROM | ขาด `use ieee.numeric_std.all` (ขาด `to_integer`) | เพิ่ม import |
| 2 | Yosys ไม่เตือนแต่ netlist ผิด | ตีความ `always @(e)` เป็น combinational → enable หาย | ต้องมี GLS |
| 3 | formal proof ผ่านทั้งที่ netlist ผิด | ทั้งสองฝั่งถูกแปลงผิดเหมือนกัน | ต้องมี GLS ประกอบ |
| 4 | `sat` ไม่จบ (multiplier 8×8) | bounded SAT แก้ไม่จบ | ใช้ `equiv_induct` + จำกัดเวลา |
| 5 | พิสูจน์ ROM ไม่ได้ | gold ยังเป็น `$mem_v2` | `memory_map` ทั้งสองฝั่ง |
| 6 | พิสูจน์ FSM ไม่ผ่าน | `-set-init-zero` ขัดกับ one-hot recode | ใช้ `equiv_induct` |

---

## 6. ดูคู่มือ

- [`Manual_3_8_VHDL_Synthesis_DeepDive.md`](../../Manual_3_8_VHDL_Synthesis_DeepDive.md) — คู่มือเชิงลึกฉบับเต็ม
- [`Manual_3_5_Yosys_and_LibreLane_Synthesis_DeepDive.md`](../../Manual_3_5_Yosys_and_LibreLane_Synthesis_DeepDive.md) — ภาคทฤษฎีเครื่องมือ Yosys / LibreLane
- [`Manual_4_3_GateLevelSimulation_SDF_DeepDive.md`](../../Manual_4_3_GateLevelSimulation_SDF_DeepDive.md) — GLS และ SDF เชิงลึก

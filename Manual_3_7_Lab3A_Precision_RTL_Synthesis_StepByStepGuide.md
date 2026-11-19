# แล็บ 3A: การสังเคราะห์วงจรดิจิทัลด้วย Siemens Precision RTL Synthesis

> **หัวข้อ:** §3.7 — ภาคปฏิบัติของวันที่ 3
> **เวลาใช้งาน:** 100–120 นาที (ถ้ามี license + PDK พร้อมใช้) · 60 นาที (ถ้าใช้เฉพาะ reference flow)
> **ตำแหน่งในคู่มือหลัก:** [`Manual_Part1_Day1-5.md`](Manual_Part1_Day1-5.md) หัวข้อ 3.7
> **โค้ดประกอบ:** [`lab_code/day3/`](lab_code/day3/)
> **แล็บคู่ขนาน:** [`Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md`](Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md) (Lab 3B — Yosys + LibreLane, open-source)

---

## 0. ภาพรวมและขอบเขตของแล็บนี้

แล็บนี้สอน **การสังเคราะห์วงจรดิจิทัลด้วยเครื่องมือ commercial** คือ Siemens Precision RTL Synthesis
โดยใช้ RTL ชุดเดียวกับ Lab 3B เพื่อให้เปรียบเทียบผลได้ตรง ๆ

| | Lab 3A (แล็บนี้) | Lab 3B (คู่ขนาน) |
|---|---|---|
| เครื่องมือสังเคราะห์ | Siemens Precision RTL Synthesis | Yosys 0.52 |
| License | ต้องมี license ขององค์กร | ฟรี |
| Technology library | PDK ขององค์กร | sky130A (PDK สาธารณะ) |
| STA | มีในตัว | ต้องต่อ OpenSTA / LibreLane |
| รายงาน | area / timing / power / constraints | area (จาก `stat -liberty`) |
| ใครทำต่อได้ | คนที่มี license | ทุกคน |

### ⚠️ อ่านก่อนทำ — สถานะของเครื่องมือในคู่มือฉบับนี้

> **Precision RTL Synthesis ไม่ได้ติดตั้งอยู่ในเครื่องที่ใช้เขียนคู่มือฉบับนี้**
> (ตรวจแล้ว: ไม่มี `precision.exe` ใน `C:\Siemens\Custom IC\Custom IC 2025.4\x64`,
> ไม่มีใน `PATH`, ไม่มีใน `C:\Program Files\Siemens` / `C:\MentorGraphics`;
> มีไฟล์ license ที่ `C:\MentorGraphics\License_Files\license.txt` ซึ่งมี feature
> `znsynthnl` / `znsim` / `znqlint` แต่ไม่มีตัวโปรแกรม)
>
> ดังนั้น **ตัวเลขทุกตัวในคู่มือฉบับนี้มาจาก reference flow แบบ open-source ที่รันจริง** ไม่ใช่ตัวเลข
> จาก Precision RTL และคู่มือจะไม่ใส่ตัวเลขของ Precision ที่ไม่ได้รันจริง
>
> สิ่งที่คุณต้องทำเองบนเครื่องที่มี license:
> 1. แก้ `set tech_lib` ใน `scripts/synth_*.tcl` ให้ชี้ไปที่ PDK ขององค์กร
> 2. รัน `precision -shell -file scripts/synth_top.tcl`
> 3. เทียบตัวเลขของคุณกับตารางใน [หัวข้อ 9](#9-ผลการรันจริงทั้งหมด) — **ตัวเลขจะไม่เท่ากัน**
>    เพราะ technology library ต่างกัน แต่ **รูปแบบ** ของผลลัพธ์ต้องเหมือนกัน

---

## 1. โครงสร้างโปรเจกต์

```
lab_code/day3/
├── README.md                              ← คู่มือย่อของแล็บ + ผลจริง
├── rtl/                                   ← RTL ที่จะสังเคราะห์
│   ├── full_adder_struct.vhd              ← dependency (xor / and / or / full adder)
│   ├── adder8.vhd                         ← combinational ripple carry adder
│   ├── adder8_pipelined.vhd               ← 2-stage pipeline, latency 1
│   ├── add_sub_shared.vhd                 ← ADD/SUB ใช้ adder ตัวเดียวกัน
│   └── top.vhd                            ← chip top (clk + rst + 3 DUT)
├── tb/                                    ← testbench
│   ├── tb_adder8.vhd                      ← RTL simulation (Questa)
│   ├── tb_add_sub_shared.vhd
│   ├── tb_adder8_pipelined.vhd
│   ├── tb_top.vhd                         ← chip-level TB
│   ├── tb_gls_adder8.v                    ← GLS (Verilog — netlist เป็น Verilog)
│   ├── tb_gls_add_sub_shared.v
│   └── tb_gls_adder8_pipelined.v
├── sdc/                                   ← constraint แยกต่อ design
│   ├── top.sdc
│   ├── adder8.sdc
│   ├── adder8_pipelined.sdc
│   └── add_sub_shared.sdc
├── scripts/
│   ├── synth_top.tcl                      ← Precision RTL batch (main)
│   ├── synth_adder8.tcl                   ← Precision RTL batch (combinational)
│   ├── synth_adder8_pipelined.tcl
│   ├── synth_add_sub_shared.tcl
│   ├── check_sdc_ports.py                 ← ตัวตรวจ SDC ↔ entity (ไม่ต้องมี tool)
│   ├── check_precision_tcl.py             ← ตัวตรวจสคริปต์ Tcl (ไม่ต้องมี tool)
│   ├── make_filtered_liberty.py           ← สร้าง Liberty ที่ใส่ dont_use
│   ├── run_sta.tcl                        ← สคริปต์ OpenSTA
│   └── run_reference_flow.sh              ← reference flow แบบ open-source
├── run_lab3.do                            ← Questa batch ทั้งแล็บ
├── build/                                 ← เอาต์พุต (สร้างอัตโนมัติ)
└── reports/                               ← หลักฐานจากการรันจริง
```

> **ทำไมต้องแยก SDC เป็นไฟล์ต่อ design?** เพราะแต่ละ design มี port ต่างกัน
> `adder8` ไม่มี clock เลย ส่วน `top` มี `clk` และ `rst`
> ถ้าใช้ SDC ไฟล์เดียวกันทั้ง flow การตรวจ port จะพังทันที — ดู [หัวข้อ 4](#4-ตรวจ-sdc-ก่อนสังเคราะห์)

---

## 2. RTL ที่จะสังเคราะห์ — อ่านก่อนสังเคราะห์

### 2.1 `adder8` — combinational ripple carry

```vhdl
entity adder8 is
    port (a, b : in std_logic_vector(7 downto 0);
          cin  : in std_logic;
          sum  : out std_logic_vector(7 downto 0);
          cout : out std_logic);
end entity;
```

สร้างจาก `full_adder_struct` 8 ตัวต่อกันแบบ ripple — carry วิ่งจากบิต 0 ไปบิท 7

* **ข้อดี:** เข้าใจง่าย เห็นชัดว่า carry chain ยาวแค่ไหน
* **ข้อเสีย:** critical path ยาวมาก (8 ชั้ง carry) → Fmax ต่ำ
* นี่คือดีไซน์ "แย่แต่ตรงไปตรงมา" ที่ใช้เป็น baseline เทียบกับ `adder8_pipelined`

### 2.2 `adder8_pipelined` — 2-stage pipeline

แบ่ง adder เป็น 2 กลุ่ม 4 บิต แล้วใส่ register ตรงกลาง

* latency = 1 clock cycle
* ทั้ง 2 stage ใช้ **synchronous reset**
* จุดที่ต้องระวัง: ตัว carry ออกจากนิบเบิลต่ำต้องถูกใช้ **ก่อน** ที่ตัวแปร `vs` ถูกเขียนทับ
  เวอร์ชันแรกของไฟล์นี้เก็บ carry ไว้ในสัญญาณ `low_cout` ที่ไม่มีใครอ่าน
  → เป็น dead code ที่ตัวสังเคราะห์จะลบทิ้งเงียบ ๆ

### 2.3 `add_sub_shared` — resource sharing

`a - b` ทำได้ด้วย `a + (~b + 1)` จึงใช้ **adder ตัวเดียว** ทำได้ทั้งบวกและลบ

* `op = '0'` → ADD, `op = '1'` → SUB
* output `ovf` เป็น **signed overflow** ไม่ใช่ carry-out
  (เช่น `0xFF + 0x01 = 0x00` → carry-out = 1 แต่ ovf = 0 เพราะ `-1 + 1 = 0` ไม่ล้น)
* จุดที่ต้องระวัง: ตัว operand ที่ถูก invert ต้องเป็น **variable** ไม่ใช่ signal
  ถ้าเป็น signal แล้วอ่านค่าจะได้ค่าเก่าใน delta cycle ที่ `op` เปลี่ยน

### 2.4 `top` — chip top

รวมทั้ง 3 ตัวเข้าด้วยกันเพื่อให้มี clock จริงให้ SDC มีอะไรให้ constrain

```
      a, b, cin ──► u_adder   (combinational) ──► sum,  cout
      a, b, cin ──► u_pipe    (registered, latency 1) ──► psum, pcout
      a, b, op  ──► u_addsub  (combinational) ──► sy,   ovf
      clk, rst  ─────────────► ทั้ง 3 ตัว
```

### 2.5 ตัวเลขที่ควรจำไว้ก่อนสังเคราะห์

| design | clock | reset | latency | ประเภท |
|---|---|---|:---:|---|
| `adder8` | ไม่มี | ไม่มี | 0 | combinational |
| `adder8_pipelined` | `sys_clk` 100 MHz | synchronous | 1 | sequential |
| `add_sub_shared` | ไม่มี | ไม่มี | 0 | combinational |
| `top` | `sys_clk` 100 MHz | synchronous | ผสม | sequential + combinational |

---

## 3. Step 1–2: เตรียมเครื่องมือ และ RTL simulation

### 3.1 ตรวจว่ามีอะไรอยู่บ้าง

```powershell
# Windows
Get-Command precision, vsim -ErrorAction SilentlyContinue
Get-Command ghdl, yosys, iverilog -ErrorAction SilentlyContinue   # ถ้าใช้ WSL
```

### 3.2 รัน RTL simulation ก่อนเสมอ

> **กฎเหล๊กของแล็บนี้: RTL simulation ต้องผ่านก่อนสังเคราะห์เสมอ**
> ถ้า RTL ยังผิดอยู่แล้ว การวิเคราะห์ area/timing ของมันไม่มีความหมายเลย

```powershell
cd "E:\lab\VHDL(BOI)\lab_code\day3"
vsim -do run_lab3.do -c
```

ผลที่ต้องได้ (จากการรันจริงบนเครื่องนี้ — Questa 2026.1):

```
1/4 Running testbench: tb_adder8 (8-bit Ripple Carry Adder)
# ** Note: tb_adder8: ALL TESTS PASSED
2/4 Running testbench: tb_add_sub_shared (ADD/SUB Resource Sharing)
# ** Note: tb_add_sub_shared PASS=512 FAIL=0
3/4 Running testbench: tb_adder8_pipelined (Pipelined 8-bit Adder)
# ** Note: tb_adder8_pipelined: ALL TESTS PASSED
4/4 Running testbench: tb_top (Chip top (clk/rst + 3 DUTs))
# ** Note: tb_top: CHECKS=80 FAIL=0
# ** Note: tb_top: ALL TESTS PASSED
All Day 3 functional labs completed successfully (4/4 testbenches passed).
```

### 3.3 ⚠️ บั๊กที่เจอตอนเขียน `tb_top.vhd` — อ่านสัญญาณที่เพิ่ง assign

เวอร์ชันแรกของ `tb_top.vhd` เขียนแบบนี้:

```vhdl
op <= '1' when (k mod 3) = 0 else '0';
...
if op = '1' then          -- ❌ อ่านค่าเก่า!
    res_int := (ia - ib) mod 256;
```

`op` เป็น **signal** → ค่าใหม่มีผลเมื่อสิ้นสุด delta cycle ปัจจุบัน
ตอนที่ process อ่าน `op` ได้ค่าของ iteration ก่อนหน้า

ผลคือรันแล้วได้

```
** Failure: tb_top: u_addsub y fail k=0 got=6 exp=16
```

(ได้ 6 = ค่า SUB จริง แต่คาด 16 = ค่า ADD ที่คำนวณจาก `op` เก่า)

**วิธีแก้ที่ถูกต้อง** — เก็บโหมดไว้ใน variable แล้ว assign signal จาก variable:

```vhdl
variable op_i : std_logic;
...
op_i := '1' when (k mod 3) = 0 else '0';
op   <= op_i;
...
if op_i = '1' then      -- ✅ ใช้ variable
```

> **บทเรียน:** ใน testbench ให้ใช้ **variable** เก็บค่าที่คำนวณล่วงหน้าเสมอ
> แล้วค่อย assign ให้ signal — จะได้ไม่มีปัญหา delta cycle และโค้ดอ่านง่ายขึ้นด้วย

---

## 4. ตรวจ SDC ก่อนสังเคราะห์

### 4.1 ปัญหาที่พบจริงในแล็บเดิม

`lab_code/day3/constraints.sdc` (เวอร์ชันเดิมของแล็บ) เขียนไว้ว่า:

```tcl
create_clock -name sys_clk -period 10.0 -waveform {0 5} [get_ports clk]
set_false_path -from [get_ports rst]
```

แต่ entity `top` เวอร์ชันเดิม **ไม่มี port `clk` และ `rst` เลย** — มีแค่ `a, b, cin, sum, cout`

**ทำไมถึงไม่พัง?** เพราะใน SDC `get_ports clk` ของ port ที่ไม่มีอยู่จะคืน **collection ว่าง**
ไม่ใช่ error → constraint ถูกทิ้งไปเงียบ ๆ → timing report ออกมา "ปกติ"
แต่ไม่มี path ที่ถูก constrain เลย

> นี่คือ **การล้มเหลวแบบเงียบ (silent failure) ที่แพงที่สุด** ในงาน synthesis
> เครื่องมือไม่เตือน แต่ผลลัพธ์ทั้งหมดไม่มีความหมาย

### 4.2 ตัวตรวจที่แก้ปัญหานี้: `scripts/check_sdc_ports.py`

ตัวตรวจนี้เป็น Python 3 ล้วน ๆ (ไม่ต้องมี EDA tool) อ่าน entity จาก VHDL
แล้วเทียบกับชื่อ port ที่ SDC อ้างถึง

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3"

python3 scripts/check_sdc_ports.py --design top
python3 scripts/check_sdc_ports.py --design adder8
python3 scripts/check_sdc_ports.py --design adder8_pipelined
python3 scripts/check_sdc_ports.py --design add_sub_shared
```

ผลจากการรันจริง (ทั้ง 4 design):

```
==========================================================================
SDC / VHDL port cross-check
  VHDL : rtl/top.vhd   (entity 'top', 12 ports)
  SDC  : sdc/top.sdc   (12 distinct get_ports names)
==========================================================================
OK     : every get_ports name in the SDC exists in the entity
OK     : create_clock is attached to port 'clk' (exists)
OK     : every port of the entity is constrained by the SDC
--------------------------------------------------------------------------
RESULT : 0 error(s), 0 warning(s)
==========================================================================
```

สำหรับ `adder8` (combinational) ตัวตรวจจะรายงานว่าเป็น **virtual clock** ซึ่งถูกต้อง:

```
OK     : 1 virtual clock(s) in the SDC (no port target) - legal for a combinational block
```

### 4.3 พิสูจน์ว่าตัวตรวจจับบั๊กเดิมได้จริง

ตัวตรวจมีโหมดทดสอบย้อนหลัง ที่สร้าง entity + SDC เวอร์ชันเดิมของแล็บขึ้นมาใหม่แล้วตรวจ:

```bash
python3 scripts/check_sdc_ports.py --selftest
```

ผลจากการรันจริง:

```
### SELFTEST: reproduce the historical Lab 3A SDC bug ###
--------------------------------------------------------------------------
ERROR  : SDC references port 'clk' but entity 'top' has no such port
ERROR  : SDC references port 'rst' but entity 'top' has no such port
ERROR  : create_clock is attached to port 'clk' which does not exist in entity 'top'
OK     : every port of the entity is constrained by the SDC
--------------------------------------------------------------------------
RESULT : 3 error(s), 0 warning(s)
--------------------------------------------------------------------------
SELFTEST PASSED : the checker rejected the buggy SDC (exit code 1, errors reported above)
```

### 4.4 เกณฑ์ที่ต้องผ่านก่อนไป Step ต่อไป

* `RESULT : 0 error(s)` ทุก design
* ไม่มี `WARN : port ... is not constrained by the SDC` (แปลว่า SDC ครอบคลุมทุก port)

---

## 5. ตรวจสคริปต์ Tcl ก่อนสังเคราะห์

### 5.1 ปัญหาที่พบจริงในแล็บเดิม

`synth.tcl` เวอร์ชันเดิม:

```tcl
set rtl_dir "."
add_source -type vhdl -work work -library work "$rtl_dir/full_adder_struct.vhd"
```

แต่ `full_adder_struct.vhd` อยู่ใน `lab_code/day2/` **ไม่ใช่** `lab_code/day3/`
→ `add_source` หาไฟล์ไม่เจอ → สคริปต์ตายที่คำสั่งแรก ๆ ทันที

### 5.2 ตัวตรวจ `scripts/check_precision_tcl.py`

ตรวจ 4 อย่างโดยไม่ต้องมี Precision:

1. วงเล็บปีกกา `{` `}` และ `[` `]` สมดุลไหม
2. ไฟล์ที่ `add_source` / `add_constraint_file` อ้างถึง มีอยู่จริงไหม
3. `set_top_module` ตรงกับ entity ใน `rtl/` ไหม
4. port ใน SDC มีอยู่จริงใน entity ไหม

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3"
python3 scripts/check_precision_tcl.py
```

ผลจากการรันจริง (ตัดมาเฉพาะ `synth_top.tcl`):

```
==========================================================================
Precision Tcl checker : scripts/synth_top.tcl
==========================================================================
OK     : braces, brackets and quotes are balanced
OK     : add_source         -> rtl/full_adder_struct.vhd
OK     : add_source         -> rtl/adder8.vhd
OK     : add_source         -> rtl/adder8_pipelined.vhd
OK     : add_source         -> rtl/add_sub_shared.vhd
OK     : add_source         -> rtl/top.vhd
OK     : add_constraint_file -> sdc/top.sdc
OK     : set_top_module 'top' exists in rtl/ (rtl/top.vhd)
OK     : every port in sdc/top.sdc exists in entity 'top'
WARN   : tech_lib is still the placeholder 'gscl45nm' - replace it with the
         technology library of your organisation
--------------------------------------------------------------------------
RESULT : 0 error(s), 1 warning(s)
==========================================================================
```

### 5.3 โหมดทดสอบย้อนหลัง

```bash
python3 scripts/check_precision_tcl.py --selftest
```

ผลจากการรันจริง — ตัวตรวจจับไฟล์ที่หายไปได้ 1 error:

```
ERROR  : add_source refers to a file that does not exist:
          $rtl_dir/full_adder_struct.vhd
          (resolved to /mnt/e/lab/VHDL(BOI)/lab_code/day3/full_adder_struct.vhd)
ERROR  : add_source refers to a file that does not exist:
          $rtl_dir/adder8.vhd
          (resolved to /mnt/e/lab/VHDL(BOI)/lab_code/day3/adder8.vhd)
ERROR  : add_constraint_file refers to a file that does not exist:
          $rtl_dir/constraints.sdc
          (resolved to /mnt/e/lab/VHDL(BOI)/lab_code/day3/constraints.sdc)
RESULT : 3 error(s), 0 warning(s)
SELFTEST PASSED : the checker rejected the buggy script (3 error(s) reported above)
```

---

## 6. Step 6: Precision RTL — GUI

> ส่วนนี้ต้องทำบนเครื่องที่มี Precision RTL + license

1. `File ▸ New Project` → ตั้งชื่อ `top` และระบุ technology library
   (ค่าที่ใช้ต้องตรงกับ `set tech_lib` ใน `scripts/synth_top.tcl`)
2. `File ▸ Add Source…` → เพิ่มไฟล์ใน `rtl/` **ตามลำดับนี้**
   (`full_adder_struct.vhd` ก่อน `adder8.vhd` เพราะ `adder8.vhd` bind component ไปหา entity นี้)
3. `File ▸ Add Source… ▸ Add Constraints` → เพิ่ม `sdc/top.sdc`
4. คลิกขวาที่ `rtl/top.vhd` → **Set as Top**
5. กดปุ่ม **Compile** (หรือ `Compile ▸ Compile`)
6. เปิดรายงาน:
   * **Area** — จำนวน cell, พื้นที่รวม, utilization
   * **Timing** — slack ต่อ path (setup / hold)
   * **Power** — dynamic / static / leakage
   * **Constraints** — constraint ที่ tool รับได้ / ข้าม / error
   * **Netlist** — ไฟล์ Verilog ที่ export ออกมา

### 6.1 จุดที่ต้องดูใน report

| รายการ | ต้องดูอะไร |
|---|---|
| Area | จำนวน cell ต่อชนิด, `Total area`, `Cell utilization` |
| Timing (max) | `slack` ของ path ที่แย่ที่สุด — ถ้าติดลบ = violation |
| Timing (min) | hold slack — ติดลบ = data ไม่นิ่งพอ |
| Constraints | มี constraint ไหนถูก **ข้าม** หรือ **error** |
| Power | `Total power` + สัดส่วน leakage ยิ่งสัดส่วน leakage สูง ยิ่งต้องระวัง |

---

## 7. Step 7: Precision RTL — Batch (Tcl)

### 7.1 สคริปต์ที่ใช้

`scripts/synth_top.tcl` (ตัวหลัก) มีโครงสร้างแบบนี้:

```tcl
# ---- 0. หาโฟลเดอร์ของแล็บจากตำแหน่งไฟล์สคริปต์ ----
set script_dir [file dirname [file normalize [info script]]]
set lab_dir    [file dirname $script_dir]

# ---- 1. Technology library ----
set tech_lib "gscl45nm"          ;# >>> แก้เป็น PDK ขององค์กร <<<

# ---- 3. สร้างโปรเจกต์ ----
new_project -name $design_name -folder $project_dir -technology $tech_lib

# ---- 4. เพิ่ม RTL ----
add_source -type vhdl -work work -library work "$lab_dir/rtl/full_adder_struct.vhd"
add_source -type vhdl -work work -library work "$lab_dir/rtl/adder8.vhd"
...
add_source -type vhdl -work work -library work "$lab_dir/rtl/top.vhd"

# ---- 5. Constraints ----
add_constraint_file "$lab_dir/sdc/top.sdc"

# ---- 6. Top ----
set_top_module $design_name

# ---- 7-8. Elaborate + Compile ----
elaborate
compile -incremental_mapping -retiming

# ---- 9. Reports ----
report_area        -file "$lab_dir/reports/area.rpt"
report_timing      -delay max -num_paths 50 -file "$lab_dir/reports/timing_max.rpt"
report_timing      -delay min -num_paths 50 -file "$lab_dir/reports/timing_min.rpt"
report_power       -file "$lab_dir/reports/power.rpt"
report_constraints -file "$lab_dir/reports/constraints.rpt"

# ---- 10-11. Netlist + SDF ----
export_netlist -format verilog -output "$lab_dir/netlist/${design_name}_netlist.v"
write_sdf -output "$lab_dir/netlist/${design_name}.sdf"

exit
```

### 7.2 รัน

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3"
precision -shell -file scripts/synth_top.tcl
```

### 7.3 ⚠️ อย่าสับสนกับคู่มืออีกเล่มหนึ่งใน repository นี้

ไฟล์ [`version-01/คู่มือการใช้งาน Siemens Precision Synthesis...md`](version-01/) ใช้ชุดคำสั่งอีกแบบหนึ่ง:

```tcl
setup_design -manufacturer Xilinx ...
add_input_file ...
read_sdc ...
write_output_file ...
```

นั่นคือ **flow สาย Xilinx** ไม่ใช่ชุดคำสั่งของ Precision RTL Synthesis ที่คู่มือหลักใช้
ให้ยึดชุด `new_project` / `add_source` / `add_constraint_file` / `set_top_module` / `compile` /
`export_netlist` / `exit` ตามที่คู่มือหลักกำหนด และถ้าคำสั่งไหนของเวอร์ชันที่ติดตั้งไม่เหมือนกัน
ให้ตรวจด้วย `help <ชื่อคำสั่ง>` ใน Precision shell

### 7.4 สคริปต์ที่เหลือ

| สคริปต์ | design | จุดประสงค์ |
|---|---|---|
| `synth_top.tcl` | `top` | chip top ที่มี clock จริง — ตัวหลักของแล็บ |
| `synth_adder8.tcl` | `adder8` | combinational — เทียบ area กับตัวอื่น |
| `synth_adder8_pipelined.tcl` | `adder8_pipelined` | มี clock — ใช้แก้ timing violation |
| `synth_add_sub_shared.tcl` | `add_sub_shared` | resource sharing — เทียบ area |

---

## 8. Step 8–9: อ่านรายงาน และแก้ timing violation

### 8.1 วิธีอ่าน slack

```
slack = required time - arrival time
```

* `slack >= 0` → ผ่าน
* `slack < 0` → violation ขนาดเท่ากับ |slack|
* setup slack ดู path ที่ช้าที่สุด (max delay)
* hold slack ดู path ที่เร็วที่สุด (min delay)

### 8.2 ลำดับการแก้ (จากที่ถูกที่สุดไปหายากที่สุด)

1. **ตรวจ constraint ก่อนเสมอ** — ถ้า SDC ผิด slack ก็คือข้อมูลเท็จ
   (ดู [หัวข้อ 4](#4-ตรวจ-sdc-ก่อนสังเคราะห์))
2. **Pipelining** — ใส่ register ตรงกลาง path
   ดู `adder8` → `adder8_pipelined`: carry chain สั้นลงครึ่งหนึ่ง
3. **Retiming** — ย้าย register ไปตำแหน่งที่ balance path
   ใน Precision ใช้ `compile -retiming`
   ⚠️ **retiming เปลี่ยน latency ของ pipeline ด้วย** — testbench ที่ตรวจ latency ต้องแก้ตาม
4. **Resource sharing** — ใช้ logic ชุดเดียวทำงานหลายโหมด
   ดู `add_sub_shared`: adder ตัวเดียวทำได้ทั้งบวกและลบ
5. **Logic optimization** — เขียนโค้ดใหม่ให้ tool map ง่ายขึ้น
6. **Relax constraint** — ตรวจว่า constraint สมเหตุสมผลจริงไหม
   (เช่น input delay 2 ns แต่ระบบจริงให้ 5 ns)
7. **Floorplan-aware** — ต้องไปถึงขั้น Place & Route ซึ่งอยู่นอกขอบเขตของแล็บนี้

### 8.3 ⚠️ ข้อควรระวังเรื่อง reset

ในแล็บนี้ reset เป็น **synchronous** ทุก design
ดังนั้น `rst` ต้องถูก constrain เหมือน data input ปกติ
การใส่ `set_false_path -from [get_ports rst]` จะ**เอา path ของ reset ออกจากการวิเคราะห์**
ซึ่งถ้า fan-out ของ reset ใหญ่จริง ๆ อาจมี violation จริงที่ถูกซ่อนไว้

`set_false_path` มีที่ไว้สำหรับ **asynchronous reset** เท่านั้น

---

## 9. ผลการรันจริงทั้งหมด

> **ตัวเลขทั้งหมดในตารางนี้มาจาก reference flow แบบ open-source ที่รันจริงบนเครื่องนี้**
> (GHDL 5.0.1 + Yosys 0.52 + OpenSTA 2.7.0 + Icarus 12.0, PDK sky130A)
> **ไม่ใช่ตัวเลขจาก Precision RTL** — เพราะเครื่องนี้ไม่มี Precision
> ตัวเลขของคุณจาก Precision จะต่างออกไปตาม PDK ขององค์กร แต่ **รูปแบบ** ต้องเหมือนกัน
>
> แหล่งข้อมูลดิบ: [`lab_code/day3/reports/summary.txt`](lab_code/day3/reports/summary.txt)

### 9.1 ตารางสรุป

| design | generic cells | sky130 cells | area (µm²) | setup slack (ns) | hold slack (ns) | formal equiv | GLS |
|---|---:|---:|---:|---:|---:|:---:|:---:|
| `adder8` | 40 | 40 | **290.278400** | **2.94** | 2.08 | PROVEN | PASS |
| `adder8_pipelined` | 98 | 95 | **954.665600** | **7.67** | 0.45 | PROVEN | PASS |
| `add_sub_shared` | 86 | 54 | **419.152000** | **3.32** | 2.08 | PROVEN | PASS |
| `top` | 224 | 189 | **1664.096000** | **2.94** | 0.45 | PROVEN | PASS |

จาก `reports/summary.txt`: `designs processed : 4` · `failures : 0`

### 9.2 RTL simulation (Questa / ModelSim 2026.1)

```
All Day 3 functional labs completed successfully (4/4 testbenches passed).
```

| testbench | ผลจากการรันจริง |
|---|---|
| `tb_adder8` | ALL TESTS PASSED |
| `tb_add_sub_shared` | PASS=512 FAIL=0 |
| `tb_adder8_pipelined` | ALL TESTS PASSED |
| `tb_top` | CHECKS=80 FAIL=0 → ALL TESTS PASSED |

### 9.3 อ่านตัวเลข — สิ่งที่ต้องอธิบายในห้องเรียน

#### (ก) Pipeline แลก area กับ speed

| | ripple (`adder8`) | pipelined (`adder8_pipelined`) |
|---|---:|---:|
| area | 290.278400 µm² | 954.665600 µm² (**×3.29**) |
| setup slack | 2.94 ns | **7.67 ns** (**×2.61**) |
| Fmax (จาก slack) | 1/(10 − 2.94) ≈ **141.6 MHz** | 1/(10 − 7.67) ≈ **429.2 MHz** |

* พื้นที่เพิ่มขึ้น **3.29 เท่า** เพราะมี flip-flop เพิ่ม (40 → 95 cells)
* slack ดีขึ้น **2.61 เท่า** เพราะ carry chain สั้นลงครึ่งหนึ่ง
* **นี่คือ trade-off พื้นฐานของการออกแบบดิจิทัล** — เอา area ไปแลกกับ speed
* ให้นักศึกษาลองตัด FF ออกจาก `adder8_pipelined` แล้วรันใหม่ → slack จะกลับไปประมาณเดิม

#### (ข) Resource sharing

`add_sub_shared` ทำได้ทั้งบวกและลบด้วย adder ตัวเดียว (a + ~b + 1)

| | adder แยกกัน 2 ตัว | shared adder |
|---|---:|---:|
| area | 2 × 290.278400 = **580.556800 µm²** | **419.152000 µm²** |
| sky130 cells | 2 × 40 = 80 | **54** |

ประหยัดได้ **161.404800 µm² (27.8 %)** และ **26 cells (32.5 %)**

> อย่าลืมว่า `add_sub_shared` ยังต้องมี logic ตรวจ signed overflow เพิ่ม
> ถ้าตัด logic นั้นออก ตัวเลขจะยิ่งดีกว่านี้ — ให้นักศึกษาลองแล้ววัดใหม่

#### (ค) Combinational path ของ `top` เป็นตัวกำหนด Fmax

`top` มีทั้ง path combinational (`a → sum`) และ path register-to-register

* setup slack ของ `top` = **2.94 ns** เท่ากับของ `adder8` พอดี
  → **path combinational คือตัวจำกัด ไม่ใช่ path ที่มี register**
* hold slack ของ `top` = **0.45 ns** (register-to-register)
  ต่างจาก `adder8` ที่เป็น 2.08 ns เพราะ `adder8` ไม่มี register เลย
  → hold path ของ `top` คือ FF → FF ซึ่งสั้นกว่า path ผ่านตัว logic มาก

> **บทเรียน:** ถ้าอยากรู้ว่าจะเพิ่มความเร็วได้แค่ไหน ให้ดู path ที่ **แย่ที่สุด**
> ไม่ใช่ดูจำนวน register หรือดูความซับซ้อนของวงจร

### 9.4 หลักฐานการรัน

| ไฟล์ | เนื้อหา |
|---|---|
| `reports/summary.txt` | ตารางสรุปทั้งหมด |
| `reports/modelsim_rtl_sim.log` | log ของ Questa RTL simulation |
| `reports/<design>_yosys_generic.rpt` | Yosys generic synthesis + cell count |
| `reports/<design>_yosys_sky130.rpt` | Yosys → sky130A + area |
| `reports/<design>_sta.rpt` | OpenSTA timing report (setup + hold + TNS) |
| `reports/<design>_equivalence.rpt` | formal equivalence RTL ↔ netlist |
| `reports/<design>_gls.rpt` | gate-level simulation กับ cell model ของ PDK |
| `reports/liberty_filter.log` | รายการ cell ที่ถูกทำ `dont_use` (46 cell) |

## 10. Step 10: Reference flow แบบ open-source (ไม่ต้องมี license)

### 10.1 ทำไมต้องมี

* Precision RTL ต้องมี license และ PDK ขององค์กร → **ไม่ทุกคนทำได้**
* ตัวเลขจากคนละ PDK เทียบกันตรง ๆ ไม่ได้
* reference flow ให้ **ค่ามาตรฐานเดียวกันทุกคน** เพื่อใช้เทียบว่า "Precision ของฉันอยู่ตรงไหน"

### 10.2 สถาปัตยกรรมของ flow

```
   VHDL (rtl/*.vhd)
        │
        │  GHDL 5.0.1  :  ghdl synth --std=08 --out=verilog
        ▼
   Verilog เชิงพฤติกรรม  ──────────────────────────────┐
        │                                               │
        │  Yosys 0.52 :  synth                          │  Yosys formal
        ▼                                               │  equiv_make +
   generic netlist ($_AND_, $_XOR_, ...)  ───► formal equivalence
        │                                               │
        │  Yosys :  dfflibmap + abc -liberty            │
        ▼                                               │
   sky130A netlist (sky130_fd_sc_hd__*)                 │
        │                                               │
        ├──► OpenSTA 2.7.0 + sdc/<design>.sdc ──► slack │
        │                                               │
        └──► Icarus 12.0 + sky130A cell models ──► GLS  │
                                                        ▼
                                                  PROVEN
```

### 10.3 รัน

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3"
bash scripts/run_reference_flow.sh              # ทุก design
bash scripts/run_reference_flow.sh top          # design เดียว
```

### 10.4 ⚠️ จุดที่ต้องระวัง: `dont_use` ใน Liberty

**นี่คือบั๊กจริงที่เจอตอนทำแล็บนี้ และเป็นบั๊กที่ทำให้ netlist ผิดแบบเงียบ**

คำสั่ง `abc -liberty` จะเลือก cell ที่ "ดีที่สุด" จาก Liberty โดยมองแค่ area/delay
แต่ sky130A มี cell ที่ **ดูเหมือน gate 2-input ธรรมดา** แต่ไม่ใช่:

```
sky130_fd_sc_hd__lpflow_inputiso1p_1    area 6.256
    is_isolation_cell : "true"
    function: X = A & !SLEEP              ← เป็น isolation cell ไม่ใช่ OR gate
```

ผลที่ได้ครั้งแรก (จากการรันจริง):

```
or_gate:
  sky130_fd_sc_hd__lpflow_inputiso1p_1 _0_ (
    .A(a),
    .SLEEP(b),
    .X(y)
  );
```

กล่าวคือ **OR gate ของ ripple-carry adder กลายเป็น "a AND NOT b"**

สิ่งที่ทำให้มันอันตรายคือ:

* `check -assert` ผ่าน ✅
* จำนวน cell ดูสมเหตุสมผล ✅
* area report ดูสมเหตุสมผล ✅
* **แต่วงจรคำนวณผิด** ❌

จับได้ด้วย 2 วิธีเท่านั้น: **formal equivalence** หรือ **gate-level simulation**

**วิธีแก้** คือสร้าง Liberty ที่มี `dont_use : true ;` ประกอบไว้ใน cell ที่ใช้เป็น logic ไม่ได้
ซึ่งเป็นวิธีเดียวกับที่ production open-source flow ทุกตัวใช้

`scripts/make_filtered_liberty.py` ทำหน้าที่นี้:

```bash
python3 scripts/make_filtered_liberty.py <input.lib> <output.lib>
```

ผลจากการรันจริงกับ sky130A `tt_025C_1v80`:

```
cells in the source      : 428
cells marked dont_use    : 46
```

46 cell ที่ถูกกรองออก แบ่งเป็น:

* low-power flow cell (`lpflow_*`) — isolation / retention / level shifter
* cell ที่ไม่มี timing function เลย (decap, tap, diode, dlclkp)

> ⚠️ **ระวังตอนเขียนสคริปต์แก้ Liberty:** ตอนแทรก `dont_use` ต้องเขียน
> **cell block ทั้งก้อน** กลับไป ถ้าเขียนแค่บรรทัดหัว cell แล้วทิ้ง body ทิ้ง
> ไฟล์ Liberty จะเสียโครงสร้าง (วงเล็บไม่สมดุล) และ ABC จะ crash
> สคริปต์นี้มีการตรวจสมดุลวงเล็บให้อยู่แล้ว

### 10.5 ข้อควรระวังเรื่อง OpenSTA

* OpenSTA 2.7.0 **ไม่มีคำสั่ง `set_operating_conditions`** — ใช้ค่าเริ่มต้นจาก Liberty
* คำสั่ง report ของ OpenSTA พิมพ์ออกทาง stdout ไม่ได้คืนค่าเป็น string กลับมาใน Tcl
  → ต้องใช้ `sta::redirect_file_begin` / `sta::redirect_file_end` ถึงจะเขียนลงไฟล์ได้
  (ถ้าใช้ `puts $fh [report_worst_slack -max]` ไฟล์จะ **ว่างเปล่า**)
* OpenSTA 2.7.0 **ไม่มีคำสั่ง `report_clocks`** — ใช้ `report_checks` แทน

### 10.6 ⚠️ ข้อควรระวังเรื่อง Icarus + sky130 cell models

นี่คือบั๊กที่ทำให้เสียเวลามากที่สุดในการทำ GLS กับ PDK sky130A และเป็นบั๊กที่ **จับได้เฉพาะตอน
รันจริง** — ถ้าไม่รัน จะไม่มีทางรู้

#### บั๊กที่ 1 — ลืมไฟล์ `primitives.v`

ไฟล์ `sky130_fd_sc_hd.v` เรียก User Defined Primitives (udp_dff, udp_mux, ...)
ซึ่งอยู่ในไฟล์ **`primitives.v`** ของ PDK

ถ้าไม่ใส่ `primitives.v` เข้าไปด้วย iverilog จะหยุดด้วย:

```
error: Unknown module type: sky130_fd_sc_hd__udp_dff$NSR_pp$PG$N
```

#### บั๊กที่ 2 — ต้องคอมไพล์ด้วย `-D FUNCTIONAL` (สำคัญที่สุด)

ไฟล์โมเดลของ PDK มีโครงสร้าง `ifdef` ซับซ้อน สรุปได้ว่า:

```
`ifdef USE_POWER_PINS
    `ifdef FUNCTIONAL
        <โมเดลแบบ FUNCTIONAL_PP>      ← ต้องต่อขา VPWR/VGND/VPB/VNB
    `else
        <โมเดลแบบ TIMING_PP>
    `endif
`else                                ← ค่าเริ่มต้นของเราอยู่ตรงนี้
    `ifdef FUNCTIONAL
        <โมเดลแบบ FUNCTIONAL>         ← ต้องกำหนด -D FUNCTIONAL
    `else
        <โมเดลแบบ TIMING>              ← ⚠️ ค่าเริ่มต้นที่ได้ถ้าไม่ใส่ -D FUNCTIONAL
    `endif
`endif
```

**ค่าเริ่มต้น (ไม่ใส่ `-D FUNCTIONAL`) จะได้โมเดลแบบ TIMING** ซึ่งมี `specify` block:

```verilog
module sky130_fd_sc_hd__dfxtp_1 (Q, CLK, D);
    sky130_fd_sc_hd__udp_dff$P_pp$PG$N dff0
        (buf_Q, D_delayed, CLK_delayed, notifier, VPWR, VGND);
    specify
      ( posedge CLK => ( Q : CLK ) ) = ( 0:0:0 , 0:0:0 ) ;
      $setuphold ( posedge CLK , posedge D , ... ) ;
    endspecify
endmodule
```

`D_delayed` และ `CLK_delayed` **ถูกขับเคลื่อนด้วย timing check เท่านั้น**
Icarus ไม่รองรับ timing check และบอกไว้ชัดเจน:

```
warning: Timing checks are not supported and delayed signal
          "CLK_delayed" will not be driven.
```

→ `CLK_delayed` ค้างที่ X → **output ของ flip-flop ทุกตัวเป็น X**
→ gate-level simulation รายงานว่าวงจรพังทั้งวงจร
→ ทั้งที่ netlist ถูกต้องสมบูรณ์

อาการที่เห็น:

```
GLS adder8_pipelined FAIL k=0 a=0b b=05 sum=xx exp=10
GLS adder8_pipelined FAIL cout k=0 a=0b b=05 cout=x
```

**วิธีแก้** — คอมไพล์โมเดลด้วย `-D FUNCTIONAL`:

```bash
iverilog -g2012 -D FUNCTIONAL -o build/adder8_pipelined_gls.vvp \
         build/adder8_pipelined_sky130.v \
         $SKY130_PRIMITIVES \
         $SKY130_VERILOG \
         tb/tb_gls_adder8_pipelined.v
vvp build/adder8_pipelined_gls.vvp
```

ผลจากการรันจริงหลังแก้:

```
GLS adder8: PASS (65536 patterns)
GLS adder8_pipelined: PASS (16 vectors)
GLS add_sub_shared: PASS (131072 checks)
GLS top: PASS (16 vectors, 4 checks each)
```

> **หมายเหตุ:** simulator ที่รองรับ `specify` block (Questa, VCS, Xcelium)
> ไม่มีปัญหานี้ — ถ้าใช้ Questa ให้ compile โมเดลตามปกติได้เลย
> ปัญหานี้มีเฉพาะกับ Icarus (และ simulator ที่ไม่ implement timing check)

#### บั๊กที่ 3 — ระวังเรื่อง `abc` เลือก cell ผิด

อ่านรายละเอียดในหัวข้อ 10.4 — เป็นอีกเรื่องที่ต้อง GLS หรือ formal จึงจะจับได้

## 11. แบบฝึกหัดประจำแล็บ 3A

| # | โจทย์ | ผลที่คาดหวัง |
|---|---|---|
| A.1 | รัน `check_sdc_ports.py` ทั้ง 4 design | `0 error(s)` ทุกตัว |
| A.2 | จงใส่ `create_clock ... [get_ports clk]` ลงใน `sdc/adder8.sdc` แล้วรันตัวตรวจซ้ำ | ตัวตรวจจับ error ให้ เพราะ `adder8` ไม่มี port `clk` |
| A.3 | รัน `check_precision_tcl.py --selftest` | `SELFTEST PASSED` |
| A.4 | แก้ `set tech_lib` ใน `scripts/synth_top.tcl` ให้เป็น PDK ขององค์กร แล้วรัน Precision | ได้ `reports/area.rpt`, `timing_max.rpt`, `power.rpt` |
| A.5 | รัน `bash scripts/run_reference_flow.sh` | ได้ `reports/summary.txt` พร้อมตัวเลขทั้ง 4 design |
| A.6 | เปรียบเทียบ area ของ `adder8` กับ `add_sub_shared` | adder แยกกัน = 580.556800 µm² vs shared = 419.152000 µm² → ประหยัด 27.8 % |
| A.7 | เปรียบเทียบ area ของ `adder8` กับ `adder8_pipelined` | area 290.278400 → 954.665600 µm² (×3.29) แต่ slack 2.94 → 7.67 ns (×2.61) |
| A.8 | ลด `CLK_PERIOD` ใน `sdc/top.sdc` จาก 10.0 เป็น 5.0 แล้วรัน STA ใหม่ | setup slack ลดลงหรือกลายเป็นค่าติดลบ |
| A.9 | เอา `dont_use` ออกจาก Liberty (ใช้ตัวเดิม) แล้วรัน GLS | **GLS ต้อง FAIL** — นี่คือบั๊ก isolation cell ที่จับได้ (ดูหัวข้อ 10.4) |
| A.10 | อธิบายว่าทำไม `check -assert` ของ Yosys ถึงผ่านทั้งที่ netlist ผิด | มันตรวจโครงสร้าง ไม่ได้ตรวจฟังก์ชัน — ต้องใช้ GLS หรือ formal |

---

## 12. Troubleshooting

| อาการ | สาเหตุ | วิธีแก้ |
|---|---|---|
| `add_source` หาไฟล์ไม่เจอ | path ผิด (กรณีของเดิม: `full_adder_struct.vhd` อยู่ day2/) | ใช้ path เต็ม `$lab_dir/rtl/...` + รัน `check_precision_tcl.py` |
| timing report ว่างเปล่า | `get_ports` อ้าง port ที่ไม่มี → constraint ถูกทิ้งเงียบ | รัน `check_sdc_ports.py` |
| `create_clock` error ว่าไม่มี port | entity ไม่มี clock (เช่น `adder8`) | ใช้ virtual clock (create_clock ไม่ต้องมี `[get_ports]`) |
| netlist คำนวณผิดแต่ report ปกติ | abc เลือก cell ผิด (isolation cell) | ใส่ `dont_use` ใน Liberty + ตรวจด้วย GLS / formal |
| slack เป็นค่าติดลบหลังเพิ่ม pipeline | latency เปลี่ยน → testbench เดิมใช้ไม่ได้ | แก้ TB ตาม latency ใหม่ |
| ABC crash (return code 134) | Liberty เสียโครงสร้าง (วงเล็บไม่สมดุล) | ตรวจ `grep -o '{' \| wc -l` เทียบกับ `}` |
| OpenSTA เขียนไฟล์ report ออกมาแล้วว่าง | report พิมพ์ลง stdout ไม่ได้คืนเป็น string | ใช้ `sta::redirect_file_begin/end` |
| iverilog: `Unknown module type: ...udp_dff$...` | ลืมใส่ `primitives.v` | เพิ่มไฟล์ UDP ของ PDK ในคำสั่ง iverilog |

---

## 13. Validation Checklist

ก่อนส่งงาน ต้องผ่านทุกข้อ:

- [ ] `vsim -do run_lab3.do -c` → `4/4 testbenches passed`
- [ ] `python3 scripts/check_sdc_ports.py` → `0 error(s)` ทุก design
- [ ] `python3 scripts/check_precision_tcl.py` → `0 error(s)`
- [ ] `python3 scripts/check_sdc_ports.py --selftest` → `SELFTEST PASSED`
- [ ] `python3 scripts/check_precision_tcl.py --selftest` → `SELFTEST PASSED`
- [ ] `bash scripts/run_reference_flow.sh` → `failures: 0`
- [ ] `reports/summary.txt` มีครบทั้ง 4 design พร้อมตัวเลข
- [ ] (ถ้ามี Precision) `precision -shell -file scripts/synth_top.tcl` สำเร็จ
- [ ] (ถ้ามี Precision) `reports/area.rpt`, `timing_max.rpt`, `timing_min.rpt`, `power.rpt` ครบ
- [ ] เขียนสรุปเปรียบเทียบตัวเลขของคุณกับตารางในหัวข้อ 10 พร้อมอธิบายความต่าง

---

## 14. ดูคู่มือที่เกี่ยวข้อง

- [`Manual_3_8_VHDL_Synthesis_DeepDive.md`](Manual_3_8_VHDL_Synthesis_DeepDive.md) — ทฤษฎี VHDL synthesis เชิงลึก (latch inference, FSM recode, formal)
- [`Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md`](Manual_3_6_Lab3B_Yosys_LibreLane_StepByStepGuide.md) — แล็บคู่ขนานแบบ open-source
- [`Manual_3_5_Yosys_and_LibreLane_Synthesis_DeepDive.md`](Manual_3_5_Yosys_and_LibreLane_Synthesis_DeepDive.md) — เจาะลึกเครื่องมือ Yosys
- [`Manual_4_4_Lab4_GLS_AssertionBasedTB_StepByStepGuide.md`](Manual_4_4_Lab4_GLS_AssertionBasedTB_StepByStepGuide.md) — gate-level simulation เชิงลึก
- [`Manual_3_1_...`](Manual_Part1_Day1-5.md#วันที่-3-rtl-synthesis-and-optimization--precision-rtl-และ-yosys-8-ชั่วโมง) — วันที่ 3 ในคู่มือหลัก

# Lab Sheet 3A: Synthesis ด้วย Siemens Precision RTL

Nov 22, 2026 · @Chumnarn Punyasai

เมื่อจบแลปนี้ ผู้เรียนจะสังเคราะห์ RTL 4 ดีไซน์ (adder แบบ ripple, pipeline, resource sharing และ chip top) ได้ ตรวจ constraint ก่อนสังเคราะห์เป็น และอธิบาย trade-off ระหว่าง area กับ speed จากรายงานจริง

## ข้อมูลแลป

| หัวข้อ | รายละเอียด |
| --- | --- |
| เวลา | 100–120 นาที (มี Precision + license) · ประมาณ 60 นาที (ทำเฉพาะ reference flow) |
| ระดับ | กลาง (ต้องผ่าน Lab 1–2) |
| ตำแหน่งในหลักสูตร | หัวข้อ 3.7 ภาคปฏิบัติวันที่ 3 · แลบคู่ขนาน: Lab 3B (Yosys + LibreLane) |
| ไฟล์ประกอบ | โฟลเดอร์ `lab_code/day3/` ของหลักสูตร (RTL, testbench, SDC, สคริปต์) |
| เครื่องมือ | Questa/ModelSim, Python 3, Siemens Precision RTL (ถ้ามี license), WSL ที่มี GHDL + Yosys + OpenSTA + Icarus สำหรับ reference flow |
| สิ่งที่ต้องส่ง | ภาพ/ไฟล์ log ของทุกจุดตรวจสอบ, `reports/summary.txt`, ตารางบันทึกผลใน Part 8, คำตอบแบบฝึกหัด |

### วัตถุประสงค์การเรียนรู้

1. อธิบาย flow การสังเคราะห์: RTL sim → ตรวจ constraint → synthesis → อ่านรายงาน → ยืนยัน netlist
2. ตรวจว่า SDC อ้าง port ที่มีอยู่จริง และอธิบายได้ว่าทำไม constraint ที่หายเงียบๆ อันตราย
3. สังเคราะห์ด้วย Precision RTL ทั้งแบบ GUI และ batch
4. อ่าน slack และ area แล้วเทียบ pipelining กับ resource sharing
5. อธิบายว่าทำไมต้องยืนยัน netlist ด้วย formal equivalence หรือ gate-level simulation

### ⚠️ อ่านก่อนทำ: Precision RTL เป็น FPGA synthesis

Siemens ระบุว่า [Precision RTL](https://www.siemens.com/en-us/products/ic/precision/rtl/) เป็นเครื่องมือสังเคราะห์สำหรับ **FPGA** ที่ใช้ได้กับหลายผู้ผลิต (AMD Xilinx, Intel/Altera, Lattice, Microchip) ไม่ใช่เครื่องมือ ASIC ที่รับ standard-cell library หรือ PDK ขององค์กร ผลต่อแลปนี้มี 3 ข้อ

1. ใน Precision ให้เลือก **ผู้ผลิต / family / device** ของ FPGA ที่ห้องแลบใช้ ไม่ใช่ `tech_lib` แบบ `gscl45nm` ตามคู่มือต้นฉบับ
2. Area จะรายงานเป็นจำนวน **LUT / register / carry cell** ไม่ใช่ µm² ตัวเลขจึงเทียบกับตาราง sky130 ใน Part 8 ตรงๆ ไม่ได้ ให้เทียบ**แนวโน้ม** (อะไรใหญ่กว่า อะไรเร็วกว่า) แทน
3. คู่มือต้นฉบับเขียนโดยไม่มี Precision ติดตั้ง ตัวเลขทุกตัวในแลปนี้มาจาก reference flow แบบ open-source (GHDL + Yosys + OpenSTA + Icarus, PDK sky130A) ไม่ใช่จาก Precision

### ลำดับงานในแลป

| Part | งาน | ต้องมี license? | เวลาโดยประมาณ |
| --- | --- | --- | --- |
| 0 | เตรียมไฟล์และตรวจเครื่องมือ | ไม่ | 5 นาที |
| 1 | อ่าน RTL 4 ดีไซน์ | ไม่ | 10 นาที |
| 2 | RTL simulation | Questa | 10 นาที |
| 3–4 | ตรวจ SDC และสคริปต์ Tcl | ไม่ | 15 นาที |
| 5–6 | Precision RTL: GUI และ batch | **ต้องมี** | 30 นาที |
| 7 | Reference flow open-source | ไม่ | 15 นาที |
| 8 | อ่านผลและวิเคราะห์ | ไม่ | 20 นาที |

> 📝 **หมายเหตุ:** ถ้าไม่มี license ให้ข้าม Part 5–6 แล้วทำ Part 7 แทน ส่วนอื่นทำเหมือนกัน

## Part 0: เตรียมไฟล์และเครื่องมือ (5 นาที)

**เป้าหมาย:** มีโฟลเดอร์ `lab_code/day3/` ครบ และรู้ว่าเครื่องมีเครื่องมืออะไรบ้าง

### 0.1 ตรวจโครงสร้างโฟลเดอร์

1. คัดลอกโฟลเดอร์ `lab_code/day3/` จากชุดไฟล์ของหลักสูตรไปที่ `E:\lab\VHDL(BOI)\lab_code\day3`
2. ตรวจว่ามีโฟลเดอร์ย่อยครบตามตาราง

| โฟลเดอร์ | ไฟล์สำคัญ | ใช้ใน Part |
| --- | --- | --- |
| `rtl/` | `full_adder_struct.vhd`, `adder8.vhd`, `adder8_pipelined.vhd`, `add_sub_shared.vhd`, `top.vhd` | 1, 2, 5–7 |
| `tb/` | `tb_*.vhd` (RTL sim), `tb_gls_*.v` (gate-level sim) | 2, 7 |
| `sdc/` | `top.sdc`, `adder8.sdc`, `adder8_pipelined.sdc`, `add_sub_shared.sdc` (1 ไฟล์ต่อ 1 ดีไซน์) | 3, 5–7 |
| `scripts/` | `synth_*.tcl`, `check_sdc_ports.py`, `check_precision_tcl.py`, `make_filtered_liberty.py`, `run_sta.tcl`, `run_reference_flow.sh` | 3–7 |
| (ราก) | `run_lab3.do` | 2 |
| `build/`, `reports/` | สร้างอัตโนมัติ / เก็บรายงาน | 6–8 |

> 📝 **หมายเหตุ:** SDC แยกไฟล์ต่อดีไซน์เพราะแต่ละตัวมี port ต่างกัน เช่น `adder8` ไม่มี clock ส่วน `top` มี `clk` และ `rst` ถ้าใช้ SDC ไฟล์เดียวกันทุกดีไซน์ จะมี constraint ที่อ้าง port ที่ไม่มีอยู่ (ดู Part 3)

### 0.2 ตรวจเครื่องมือ

1. เปิด PowerShell แล้วพิมพ์

```powershell
Get-Command precision, vsim -ErrorAction SilentlyContinue
```

2. เปิด WSL (Ubuntu) แล้วพิมพ์

```bash
which python3 ghdl yosys sta iverilog
```

3. บันทึกผลลงตาราง แล้วเลือกเส้นทางทำแลป

| เครื่องมือ | มีหรือไม่ | ใช้ทำ |
| --- | --- | --- |
| `vsim` (Questa) |  | Part 2 |
| `python3` |  | Part 3–4 |
| `precision` |  | Part 5–6 |
| `ghdl`, `yosys`, `sta`, `iverilog` |  | Part 7 |

> ✅ **จุดตรวจสอบ:** อย่างน้อยต้องมี `vsim` และ `python3` และมี `precision` หรือชุด open-source ชุดใดชุดหนึ่ง

## Part 1: อ่าน RTL ก่อนสังเคราะห์ (10 นาที)

**เป้าหมาย:** รู้ว่าแต่ละดีไซน์มี clock, reset และ latency เท่าไร ก่อนดูรายงาน synthesis

| ดีไซน์ | หน้าที่ | clock | reset | latency | ประเภท |
| --- | --- | --- | --- | --- | --- |
| `adder8` | บวก 8 บิตแบบ ripple carry จาก `full_adder_struct` 8 ตัว | ไม่มี | ไม่มี | 0 | combinational |
| `adder8_pipelined` | แบ่งเป็น 2 กลุ่ม 4 บิต ใส่ register ตรงกลาง | `clk` (100 MHz) | synchronous | 1 | sequential |
| `add_sub_shared` | ADD/SUB ด้วย adder ตัวเดียว (`op = '1'` → ลบ) | ไม่มี | ไม่มี | 0 | combinational |
| `top` | รวมทั้ง 3 ตัว ให้มี clock จริงให้ SDC constrain | `clk` (100 MHz) | synchronous | ผสม | ผสม |

### 1.1 ขั้นตอน

1. เปิด `rtl/adder8.vhd` แล้วหาเส้นทาง carry จากบิต 0 ไปบิต 7 (นี่คือ critical path ที่ยาวที่สุด 8 ชั้น)
2. เปิด `rtl/adder8_pipelined.vhd` แล้วหาว่า carry จากนิบเบิลต่ำถูกเก็บใน register ก่อนส่งต่อให้นิบเบิลสูง
3. เปิด `rtl/add_sub_shared.vhd` แล้วหาบรรทัดที่กลับบิต `b` และใส่ carry-in = 1 เมื่อลบ (`a - b = a + not b + 1`)
4. เปิด `rtl/top.vhd` แล้วดูว่า output ทั้ง 6 ชุด (`sum`, `cout`, `psum`, `pcout`, `sy`, `ovf`) มาจาก instance ไหน

### 1.2 จุดที่ควรสังเกต

- **สัญญาณที่ไม่มีใครอ่านจะหายไป:** `adder8_pipelined` เวอร์ชันแรกเก็บ carry ไว้ใน `low_cout` ที่ไม่มีใครอ่าน เครื่องมือสังเคราะห์จะลบ logic นั้นทิ้งโดยไม่บอก และผลบวกจะผิด
- **`ovf` ไม่ใช่ carry-out:** `ovf` ของ `add_sub_shared` คือ signed overflow เช่น `0xFF + 0x01` ให้ carry-out = 1 แต่ `ovf` = 0 เพราะ −1 + 1 = 0 ไม่ล้น
- **ใช้ variable ใน process:** operand ที่ถูกกลับบิตเป็น variable ถ้าเป็น signal จะอ่านได้ค่าเก่าใน delta cycle ที่ `op` เปลี่ยน
- **ลำดับไฟล์:** ต้อง compile `full_adder_struct.vhd` ก่อน `adder8.vhd` เสมอ เพราะ `adder8` ใช้ entity จากไฟล์นั้น

> ✅ **จุดตรวจสอบ:** ตอบได้ว่าดีไซน์ไหนไม่มี clock (จะต้องใช้ virtual clock ใน SDC) และดีไซน์ไหนมี latency 1 clock

## Part 2: RTL Simulation (10 นาที)

**เป้าหมาย:** testbench ทั้ง 4 ตัวผ่านก่อนสังเคราะห์ ถ้า RTL ยังผิด ตัวเลข area และ timing ก็ไม่มีความหมาย

### 2.1 ขั้นตอน

1. เปิด PowerShell แล้วเข้าโฟลเดอร์แลบ

```powershell
cd "E:\lab\VHDL(BOI)\lab_code\day3"
```

2. รัน testbench ทั้งหมดแบบ batch

```powershell
vsim -c -do run_lab3.do
```

3. ตรวจว่ามีข้อความครบตามนี้ (ผลจากคู่มือต้นฉบับ รันด้วย Questa 2026.1)

```text
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

### 2.2 บทเรียนจาก bug จริงใน `tb_top.vhd`

เวอร์ชันแรกของ `tb_top.vhd` กำหนด `op` แล้วอ่านค่าทันทีใน process เดียวกัน จึงได้ค่าเก่าจากรอบก่อน ผลคือ `** Failure: tb_top: u_addsub y fail k=0 got=6 exp=16` (วงจรลบถูก แต่ testbench คำนวณค่าคาดหวังเป็นบวก)

```vhdl
-- ผิด: op เป็น signal ค่าใหม่มีผลหลัง process หยุดรอ
op <= '1' when (k mod 3) = 0 else '0';
if op = '1' then                         -- อ่านได้ค่าเก่า
    res_int := (ia - ib) mod 256;

-- ถูก: คำนวณใน variable แล้วค่อย assign ให้ signal
op_i := '1' when (k mod 3) = 0 else '0';  -- VHDL-2008
op   <= op_i;
if op_i = '1' then
    res_int := (ia - ib) mod 256;
```

> 💡 **เคล็ดลับ:** อยากเห็นกับตา ให้ใส่ `report "op_i=" & std_logic'image(op_i) & " op=" & std_logic'image(op);` หลัง `op <= op_i;` จะเห็นว่าที่ k = 0 ได้ `op_i='1' op='0'` และที่ k = 1 ได้ `op_i='0' op='1'` คือ `op` ตามหลังอยู่ 1 รอบเสมอ

> ✅ **จุดตรวจสอบ:** Transcript จบด้วย `4/4 testbenches passed` ถ้าไม่ผ่าน ห้ามไป Part ต่อไป

## Part 3: ตรวจ SDC ก่อนสังเคราะห์ (10 นาที)

**เป้าหมาย:** ยืนยันว่าทุกชื่อ port ใน SDC มีอยู่จริงใน entity และทุก port ถูก constrain

### 3.1 ทำไมต้องตรวจ: silent failure

SDC เวอร์ชันเดิมของแลปเขียนไว้แบบนี้ แต่ entity `top` ตอนนั้นไม่มี port `clk` และ `rst` เลย

```tcl
create_clock -name sys_clk -period 10.0 -waveform {0 5} [get_ports clk]
set_false_path -from [get_ports rst]
```

เครื่องมือหลายตัวคืน `get_ports clk` เป็น collection ว่างพร้อม warning เล็กๆ แทน error constraint จึงถูกทิ้ง รายงาน timing ดูปกติ แต่ไม่มี path ใดถูก constrain เลย

### 3.2 ขั้นตอน

1. เปิด WSL แล้วเข้าโฟลเดอร์แลบ

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3"
```

2. รันตัวตรวจทีละดีไซน์ (เป็น Python ล้วน ไม่ต้องมี EDA tool)

```bash
python3 scripts/check_sdc_ports.py --design top
python3 scripts/check_sdc_ports.py --design adder8
python3 scripts/check_sdc_ports.py --design adder8_pipelined
python3 scripts/check_sdc_ports.py --design add_sub_shared
```

3. ตรวจผลของ `top` ต้องเป็นแบบนี้

```text
OK     : every get_ports name in the SDC exists in the entity
OK     : create_clock is attached to port 'clk' (exists)
OK     : every port of the entity is constrained by the SDC
RESULT : 0 error(s), 0 warning(s)
```

4. ตรวจผลของ `adder8` ต้องมีบรรทัด virtual clock (ถูกต้อง เพราะดีไซน์ combinational ไม่มี port clock)

```text
OK     : 1 virtual clock(s) in the SDC (no port target) - legal for a combinational block
```

5. รันโหมดทดสอบย้อนหลัง ซึ่งสร้าง entity และ SDC เวอร์ชันเดิมขึ้นมาตรวจ

```bash
python3 scripts/check_sdc_ports.py --selftest
```

6. ตรวจว่าตัวตรวจจับได้ 3 error และจบด้วย `SELFTEST PASSED`

```text
ERROR  : SDC references port 'clk' but entity 'top' has no such port
ERROR  : SDC references port 'rst' but entity 'top' has no such port
ERROR  : create_clock is attached to port 'clk' which does not exist in entity 'top'
RESULT : 3 error(s), 0 warning(s)
SELFTEST PASSED : the checker rejected the buggy SDC (exit code 1, errors reported above)
```

> ✅ **จุดตรวจสอบ:** ทั้ง 4 ดีไซน์ได้ `RESULT : 0 error(s)` และไม่มี `WARN : port ... is not constrained by the SDC`

## Part 4: ตรวจสคริปต์ Tcl ก่อนสังเคราะห์ (5 นาที)

**เป้าหมาย:** จับไฟล์หายหรือชื่อ top ผิดในสคริปต์ก่อนเสีย license รัน Precision

สคริปต์เวอร์ชันเดิมใช้ `set rtl_dir "."` แต่ `full_adder_struct.vhd` อยู่ใน `lab_code/day2/` สคริปต์จึงหยุดตั้งแต่คำสั่งแรกๆ ตัวตรวจ `check_precision_tcl.py` ตรวจ 4 อย่าง ได้แก่ วงเล็บสมดุล, ไฟล์ที่อ้างถึงมีจริง, ชื่อ top ตรงกับ entity, และ port ใน SDC มีจริง

1. รันตัวตรวจ

```bash
python3 scripts/check_precision_tcl.py
```

2. ตรวจว่า `synth_top.tcl` ได้ `RESULT : 0 error(s)` (อาจมี 1 warning เรื่อง `tech_lib` ที่ยังเป็นค่า placeholder)
3. รันโหมดทดสอบย้อนหลัง

```bash
python3 scripts/check_precision_tcl.py --selftest
```

4. ตรวจว่าจับไฟล์หายได้ 3 error และจบด้วย `SELFTEST PASSED : the checker rejected the buggy script`

> ⚠️ **คำเตือน:** `check_precision_tcl.py` ตรวจได้แค่ path, วงเล็บ และชื่อ ไม่ได้ตรวจว่าชื่อคำสั่ง Tcl มีอยู่จริงใน Precision คำสั่งต้องตรวจใน Part 6 ด้วย `help` ของ Precision shell

> ✅ **จุดตรวจสอบ:** `check_precision_tcl.py` ได้ 0 error และ selftest ทั้งสองตัวขึ้น `SELFTEST PASSED`

## Part 5: Precision RTL — GUI (20 นาที, ต้องมี license)

**เป้าหมาย:** สังเคราะห์ `top` ลง FPGA ของห้องแลบ แล้วได้รายงาน area และ timing

> 📝 **หมายเหตุ:** ขั้นตอนนี้อิงตาม flow ที่ [Intel](https://resources.altera.com/quartushelp/25.3/eda/synthesis/precision/eda_pro_prec_setup_proj.htm) และ [Microchip](https://onlinedocs.microchip.com/oxy/GUID-6BACC19D-0959-4B51-87AC-AD97B0E07E35-en-US-1/GUID-2F3B3165-F402-4639-A23E-EF441E5D8B3D.html) เผยแพร่ ชื่อปุ่มอาจต่างกันเล็กน้อยตามเวอร์ชัน

### 5.1 สร้างโปรเจกต์และเพิ่มไฟล์

1. เปิด Precision RTL
2. กด **New Project** (หรือ **Set Working Directory**) แล้วเลือกโฟลเดอร์ `lab_code/day3/build/precision_top`
3. กด **Add Input Files** แล้วเพิ่มไฟล์ใน `rtl/` ตามลำดับนี้: `full_adder_struct.vhd` → `adder8.vhd` → `adder8_pipelined.vhd` → `add_sub_shared.vhd` → `top.vhd`
4. เพิ่ม `sdc/top.sdc` เข้าส่วน **Constraint Files** ของ Project Files
5. ตรวจว่า top เป็น `top` (Precision ตรวจหา top เอง ถ้าไม่ตรงให้ตั้งใหม่ใน **Setup Design**)

### 5.2 Setup Design

1. กด **Setup Design**
2. ใน **Technology** เลือกผู้ผลิต → family → device → speed grade ตามบอร์ดของห้องแลบ (ถามผู้สอน)
3. ตั้ง **Design Frequency** = 100 MHz ให้ตรงกับ `create_clock -period 10.0` ใน `sdc/top.sdc`
4. กด **OK**

บันทึก device ที่เลือก: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

### 5.3 Compile และ Synthesize

1. กด **Compile** แล้วดูหน้าต่าง Log ว่าไม่มี error (ขั้นนี้แปลง RTL เป็น netlist กลางที่ไม่ขึ้นกับเทคโนโลยี)
2. กด **Synthesize** (ขั้นนี้ map ลง LUT, register, carry ของ device ที่เลือก)
3. ดูว่ามีโฟลเดอร์ `<project>_impl_1` ที่มี netlist (EDIF หรือรูปแบบที่ผู้ผลิตใช้) และรายงาน

### 5.4 อ่านรายงาน

| รายงาน | ดูอะไร | บันทึกค่า |
| --- | --- | --- |
| Area | จำนวน LUT, register (FF), carry cell และ % การใช้ device |  |
| Timing (setup) | slack ของ path ที่แย่ที่สุด ติดลบ = violation |  |
| Timing (critical path) | จุดเริ่มและจุดสิ้นสุดของ path นั้น (คาดว่าเป็น `a`/`b` → `sum`/`cout` ของ `u_adder`) |  |
| Log / constraint | constraint ที่ถูก **ข้าม** หรือ warning เรื่อง port หาไม่เจอ ต้องเป็น 0 |  |

> ⚠️ **คำเตือน:** timing หลัง synthesis เป็นค่าประมาณ เพราะยังไม่ได้ place & route ค่า timing จริงต้องดูจากเครื่องมือของผู้ผลิต (Vivado, Quartus, Libero) หลัง P&R

> ✅ **จุดตรวจสอบ:** Synthesize สำเร็จ ไม่มี constraint ที่ถูกข้าม และกรอกตาราง 5.4 ครบ

## Part 6: Precision RTL — Batch (10 นาที, ต้องมี license)

**เป้าหมาย:** รัน flow เดียวกับ Part 5 ด้วยสคริปต์ Tcl เพื่อรันซ้ำได้

> ⚠️ **คำเตือน:** `scripts/synth_*.tcl` ในชุดไฟล์เดิมใช้คำสั่งแบบ ASIC (`set tech_lib "gscl45nm"`, `new_project -technology`, `add_source`, `set_top_module`, `export_netlist`, `write_sdf`) ซึ่งเขียนโดยไม่มี Precision ให้ทดสอบ และไม่ตรงกับ flow ของ FPGA อย่าใช้ตรงๆ ให้สร้างสคริปต์จากคำสั่งที่ Precision บันทึกไว้ตามขั้นตอนด้านล่าง

### 6.1 เก็บคำสั่งจาก GUI

1. หลังทำ Part 5 เสร็จ เปิดหน้าต่าง Transcript/Log ของ Precision ซึ่งแสดงคำสั่ง Tcl ของทุกปุ่มที่กด
2. คัดลอกคำสั่งตั้งแต่สร้างโปรเจกต์จนถึง synthesize ไปไว้ในไฟล์ใหม่ `scripts/synth_top_fpga.tcl`
3. เทียบกับโครงด้านล่าง และตรวจทุกคำสั่งด้วย `help <ชื่อคำสั่ง>` ใน Precision shell

```tcl
# synth_top_fpga.tcl - โครงสคริปต์ (ตรวจชื่อคำสั่งและ option ด้วย help ก่อนใช้)
set lab_dir [file dirname [file dirname [file normalize [info script]]]]

new_project -name top -folder "$lab_dir/build/precision_top"

add_input_file "$lab_dir/rtl/full_adder_struct.vhd"
add_input_file "$lab_dir/rtl/adder8.vhd"
add_input_file "$lab_dir/rtl/adder8_pipelined.vhd"
add_input_file "$lab_dir/rtl/add_sub_shared.vhd"
add_input_file "$lab_dir/rtl/top.vhd"
add_input_file "$lab_dir/sdc/top.sdc"

# >>> แก้ให้ตรงกับ FPGA ของห้องแลบ (คัดจาก Transcript ของ Part 5) <<<
setup_design -manufacturer <vendor> -family <family> -part <part> -speed <speed>
setup_design -frequency 100

compile
synthesize

report_area   -all_leafs "$lab_dir/reports/precision_area.rpt"
report_timing -all_clocks "$lab_dir/reports/precision_timing.rpt"

save_impl
close_project
exit
```

4. รันจาก command line (ตรวจวิธีเรียกแบบ shell ด้วย `precision -help`)

```powershell
cd "E:\lab\VHDL(BOI)\lab_code\day3"
precision -shell -file scripts/synth_top_fpga.tcl
```

5. เทียบจำนวน LUT/FF และ slack กับที่ได้จาก GUI ต้องเท่ากัน
6. ทำซ้ำกับ `adder8`, `adder8_pipelined`, `add_sub_shared` โดยเปลี่ยนไฟล์ที่เพิ่มและ SDC ให้ตรงกับดีไซน์

> 💡 **เคล็ดลับ:** คู่มือต้นฉบับบอกว่าชุดคำสั่ง `setup_design -manufacturer ...` / `add_input_file` ในคู่มืออีกเล่มเป็น "flow สาย Xilinx" ที่จริงแล้วนั่นคือรูปแบบปกติของ Precision ทุกผู้ผลิต FPGA เพราะ Precision ต้องระบุผู้ผลิตและ device เสมอ เปลี่ยนแค่ค่า `-manufacturer` และ `-family`

> ✅ **จุดตรวจสอบ:** สคริปต์รันจบโดยไม่มี error และได้ไฟล์รายงาน area และ timing ครบ 4 ดีไซน์

## Part 7: Reference Flow แบบ Open-Source (15 นาที)

**เป้าหมาย:** ได้ `reports/summary.txt` ที่มีตัวเลขของทั้ง 4 ดีไซน์และ `failures : 0` เพื่อใช้เป็นค่ามาตรฐานเดียวกันของทุกคน ไม่ว่าจะมี license หรือไม่

&#91;embedded content: Reference flow open-source · GHDL → Yosys → sky130A → STA + GLS + formal\]

### 7.1 ขั้นตอน

1. เปิด WSL แล้วเข้าโฟลเดอร์แลบ

```bash
cd "/mnt/e/lab/VHDL(BOI)/lab_code/day3"
```

2. รัน flow ทั้ง 4 ดีไซน์ (หรือใส่ชื่อดีไซน์เดียว เช่น `top`)

```bash
bash scripts/run_reference_flow.sh
bash scripts/run_reference_flow.sh top
```

3. เปิด `reports/summary.txt` แล้วตรวจว่ามี `designs processed : 4` และ `failures : 0`
4. เปิด `reports/top_sta.rpt`, `reports/top_equivalence.rpt` และ `reports/top_gls.rpt` แล้วหาบรรทัด slack, `PROVEN` และ `PASS`

### 7.2 จุดที่ทำให้ netlist ผิดแบบเงียบ: `dont_use`

คำสั่ง `abc -liberty` เลือก cell จาก area/delay อย่างเดียว ใน sky130A มี cell ที่ดูเหมือน gate 2 ขาธรรมดาแต่เป็น isolation cell เช่น `sky130_fd_sc_hd__lpflow_inputiso1p_1` (ฟังก์ชัน `X = A & !SLEEP`) ครั้งแรกที่รัน OR gate ของ adder จึงถูกแทนด้วย cell นี้และคำนวณผิด ทั้งที่ `check -assert` ผ่าน จำนวน cell และ area ก็ดูปกติ

1. ดูว่าสคริปต์สร้าง Liberty ที่กรองแล้วด้วยคำสั่งนี้

```bash
python3 scripts/make_filtered_liberty.py <input.lib> <output.lib>
```

2. เปิด `reports/liberty_filter.log` แล้วตรวจว่ามี `cells in the source : 428` และ `cells marked dont_use : 46` (กลุ่ม `lpflow_*` และ cell ที่ไม่มี logic function เช่น decap, tap, diode)

> ⚠️ **คำเตือน:** ถ้าเขียนสคริปต์แก้ Liberty เอง ต้องเขียน cell block กลับไปทั้งก้อน ถ้าวงเล็บไม่สมดุล ABC จะ crash (return code 134)

### 7.3 Gate-level simulation กับ Icarus

| ปัญหา | อาการ | วิธีแก้ |
| --- | --- | --- |
| ไม่ได้ใส่ `primitives.v` ของ PDK | `Unknown module type: sky130_fd_sc_hd__udp_dff$NSR_pp$PG$N` | ใส่ไฟล์ UDP ของ PDK ในคำสั่ง iverilog |
| compile โมเดลแบบ TIMING (ค่าเริ่มต้น) | Icarus ไม่ขับ `CLK_delayed` เพราะไม่รองรับ timing check, FF ทุกตัวออก `x` เช่น `GLS adder8_pipelined FAIL k=0 a=0b b=05 sum=xx exp=10` | compile ด้วย `-D FUNCTIONAL` |

```bash
iverilog -g2012 -D FUNCTIONAL -o build/adder8_pipelined_gls.vvp \
         build/adder8_pipelined_sky130.v \
         $SKY130_PRIMITIVES $SKY130_VERILOG \
         tb/tb_gls_adder8_pipelined.v
vvp build/adder8_pipelined_gls.vvp
```

ผลที่ต้องได้:

```text
GLS adder8: PASS (65536 patterns)
GLS adder8_pipelined: PASS (16 vectors)
GLS add_sub_shared: PASS (131072 checks)
GLS top: PASS (16 vectors, 4 checks each)
```

> 📝 **หมายเหตุ:** Questa รองรับ `specify` block จึงไม่มีปัญหา `CLK_delayed` ปัญหานี้เกิดกับ Icarus เท่านั้น

> 📝 **หมายเหตุ:** OpenSTA 2.7.0 ไม่มี `set_operating_conditions` และ `report_clocks` และคำสั่ง report พิมพ์ออก stdout ถ้าจะเขียนลงไฟล์ต้องใช้ `sta::redirect_file_begin` / `sta::redirect_file_end`

> ✅ **จุดตรวจสอบ:** `summary.txt` มี `failures : 0` ทุกดีไซน์ได้ `PROVEN` และ GLS `PASS`

## Part 8: อ่านผลและวิเคราะห์ Trade-off (20 นาที)

**เป้าหมาย:** อธิบายด้วยตัวเลขว่า pipelining แลก area กับ speed, resource sharing ประหยัด area และ path แบบ combinational เป็นตัวกำหนด Fmax ของ `top`

### 8.1 อ่าน slack

- `slack = required time − arrival time`
- slack ≥ 0 ผ่าน, slack < 0 คือ violation ขนาด |slack|
- setup slack ดู path ที่ช้าที่สุด (max delay) ส่วน hold slack ดู path ที่เร็วที่สุด (min delay)

### 8.2 ตัวเลขอ้างอิงจาก reference flow

ตัวเลขชุดนี้มาจากคู่มือต้นฉบับ (GHDL 5.0.1 + Yosys 0.52 + OpenSTA 2.7.0 + Icarus 12.0, sky130A, clock 10 ns) ผลที่ผู้เรียนรันใน Part 7 ควรตรงกันถ้าใช้เวอร์ชันเดียวกัน

| ดีไซน์ | sky130 cells | area (µm²) | setup slack (ns) | hold slack (ns) | formal | GLS |
| --- | --- | --- | --- | --- | --- | --- |
| `adder8` | 40 | 290.2784 | 2.94 | 2.08 | PROVEN | PASS |
| `adder8_pipelined` | 95 | 954.6656 | 7.67 | 0.45 | PROVEN | PASS |
| `add_sub_shared` | 54 | 419.1520 | 3.32 | 2.08 | PROVEN | PASS |
| `top` | 189 | 1664.0960 | 2.94 | 0.45 | PROVEN | PASS |

### 8.3 วิเคราะห์ 3 เรื่อง

**(ก) Pipeline แลก area กับ speed**

|  | `adder8` | `adder8_pipelined` | อัตราส่วน |
| --- | --- | --- | --- |
| area (µm²) | 290.28 | 954.67 | ×3.29 |
| cells | 40 | 95 | ×2.38 |
| setup slack (ns) | 2.94 | 7.67 | ×2.61 |
| เวลาที่ใช้จาก clock 10 ns (= 10 − slack) | 7.06 ns | 2.33 ns | — |
| Fmax โดยประมาณ (1 / เวลาที่ใช้) | ≈141.6 MHz | ≈429.2 MHz | — |

Area เพิ่มเพราะ flip-flop ที่เพิ่มเข้ามา ส่วน slack ดีขึ้นเพราะ carry chain สั้นลงครึ่งหนึ่ง

> 📝 **หมายเหตุ:** สูตร Fmax นี้เป็นค่าประมาณ เพราะ "10 − slack" รวม input/output delay ที่ตั้งไว้ใน SDC ด้วย โดยเฉพาะ `adder8` ที่ใช้ virtual clock ถ้าเปลี่ยน I/O delay ตัวเลขนี้เปลี่ยนตาม

**(ข) Resource sharing**

|  | adder แยก 2 ตัว (ประมาณจาก 2 × `adder8`) | `add_sub_shared` | ประหยัด |
| --- | --- | --- | --- |
| area (µm²) | 580.5568 | 419.1520 | 161.4048 (27.8%) |
| cells | 80 | 54 | 26 (32.5%) |

`add_sub_shared` ยังมี logic กลับบิต `b` และ logic ตรวจ signed overflow อยู่ด้วย ถ้าตัด `ovf` ออกจะประหยัดได้มากกว่านี้

**(ค) Path combinational กำหนด Fmax ของ `top`**

- setup slack ของ `top` = 2.94 ns เท่ากับ `adder8` พอดี แปลว่า path `a → sum` ของ `u_adder` เป็นตัวจำกัด ไม่ใช่ path ที่มี register
- hold slack ของ `top` = 0.45 ns เท่ากับ `adder8_pipelined` เพราะ path ที่สั้นที่สุดคือ FF → FF ใน `u_pipe`
- บทเรียน: จะรู้ว่าเร็วได้แค่ไหน ให้ดู path ที่แย่ที่สุด ไม่ใช่จำนวน register

### 8.4 บันทึกผลของคุณ

กรอกค่าจาก Precision (Part 5–6) และจาก reference flow (Part 7) ตัวเลขสองชุดใช้หน่วยต่างกัน ให้เทียบที่แนวโน้ม

| ดีไซน์ | Precision LUT | Precision FF | Precision setup slack (ns) | ref. area (µm²) | ref. setup slack (ns) |
| --- | --- | --- | --- | --- | --- |
| `adder8` |  |  |  |  |  |
| `adder8_pipelined` |  |  |  |  |  |
| `add_sub_shared` |  |  |  |  |  |
| `top` |  |  |  |  |  |

- [ ] `adder8_pipelined` มี FF มากกว่า `adder8` ทั้งสอง flow
- [ ] `adder8_pipelined` มี setup slack ดีกว่า `adder8` ทั้งสอง flow
- [ ] `add_sub_shared` ใช้ resource น้อยกว่า 2 × `adder8`
- [ ] Critical path ของ `top` อยู่ใน `u_adder`

> 📝 **หมายเหตุ:** FPGA มี carry chain เฉพาะ ทำให้ adder 8 บิตเร็วมากอยู่แล้ว ความต่างของ slack ระหว่าง ripple กับ pipelined ใน Precision อาจน้อยกว่าใน sky130 มาก และ Precision อาจ map `full_adder_struct` ทั้ง 8 ตัวลง LUT ไม่กี่ตัว ให้อธิบายสิ่งที่เห็นจริงแทนการบังคับให้ตรงกับตารางอ้างอิง

### 8.5 ลำดับการแก้ timing violation

1. **ตรวจ constraint ก่อน** ถ้า SDC ผิด slack ก็ไม่มีความหมาย (Part 3)
2. **Pipelining:** ใส่ register กลาง path ทำให้ path สั้นลง แต่ **latency เพิ่ม** ต้องแก้ testbench ตาม
3. **Retiming:** ย้าย register ที่มีอยู่แล้วไปตำแหน่งที่ balance path กว่า จำนวน clock จาก input ถึง output เท่าเดิม แต่ชื่อและตำแหน่ง register เปลี่ยน ส่งผลต่อ GLS และ formal ที่เทียบ register ต่อ register
4. **Resource sharing:** ใช้ logic ชุดเดียวหลายโหมด (ช่วย area มากกว่า speed บางครั้งทำให้ช้าลงเพราะมี mux เพิ่ม)
5. **Logic optimization:** เขียนโค้ดใหม่ให้ tool map ง่ายขึ้น เช่นใช้ `+` ของ `numeric_std` ให้ FPGA ใช้ carry chain
6. **ตรวจว่า constraint สมเหตุสมผล:** เช่น input delay ตั้งไว้เกินกว่าระบบจริงหรือไม่
7. **Placement:** ต้องทำในขั้น place & route ซึ่งอยู่นอกแลบนี้

> ⚠️ **คำเตือน:** คู่มือต้นฉบับเขียนว่า "retiming เปลี่ยน latency" ซึ่งไม่ถูก retiming รักษาจำนวน clock จาก input ถึง output สิ่งที่เพิ่ม latency คือการเพิ่ม pipeline stage

### 8.6 เรื่อง reset และ `set_false_path`

ทุกดีไซน์ในแลบนี้ใช้ synchronous reset ดังนั้น `rst` เป็น data input ตัวหนึ่งที่ต้องผ่าน setup/hold ทุก FF การใส่ `set_false_path -from [get_ports rst]` จะตัด path เหล่านั้นออกจากการวิเคราะห์ และอาจซ่อน violation จริงเมื่อ reset มี fan-out สูง จึงไม่ควรใช้กับ synchronous reset (การตัด path ของ asynchronous reset ก็ต้องมั่นใจว่ามี reset synchronizer และตรวจ recovery/removal แทน)

> ✅ **จุดตรวจสอบ:** กรอกตาราง 8.4 ครบ และอธิบายได้ว่าตัวเลขจาก Precision ต่างจาก reference flow เพราะอะไร

## แบบฝึกหัดประจำแลบ

| # | โจทย์ | ผลที่คาดหวัง |
| --- | --- | --- |
| A.1 | รัน `check_sdc_ports.py` ทั้ง 4 ดีไซน์ | `0 error(s)` ทุกตัว |
| A.2 | ใส่ `create_clock -period 10 [get_ports clk]` ลงใน `sdc/adder8.sdc` แล้วรันตัวตรวจซ้ำ (ทำเสร็จแล้วคืนค่าเดิม) | ตัวตรวจรายงาน error เพราะ `adder8` ไม่มี port `clk` |
| A.3 | รัน `check_precision_tcl.py --selftest` | `SELFTEST PASSED` |
| A.4 | สังเคราะห์ `top` ด้วย Precision ลง FPGA ของห้องแลบ (Part 5–6) | ได้รายงาน area (LUT/FF) และ timing |
| A.5 | รัน `bash scripts/run_reference_flow.sh` | `reports/summary.txt` มีครบ 4 ดีไซน์, `failures : 0` |
| A.6 | เทียบ area ของ 2 × `adder8` กับ `add_sub_shared` | 580.5568 กับ 419.1520 µm² ประหยัด 27.8% (reference flow) |
| A.7 | เทียบ `adder8` กับ `adder8_pipelined` | area ×3.29 แต่ slack จาก 2.94 เป็น 7.67 ns |
| A.8 | ลด period ใน `sdc/top.sdc` จาก 10.0 เป็น 5.0 แล้วรัน STA ใหม่ | setup slack ลดลงประมาณ 5 ns ต่อดีไซน์ ตัวที่มี path combinational ยาวอาจติดลบ |
| A.9 | ใช้ Liberty ตัวเดิม (ไม่มี `dont_use`) แล้วรัน GLS | GLS ต้อง FAIL เพราะ isolation cell (Part 7.2) |
| A.10 | อธิบายว่าทำไม `check -assert` ของ Yosys ผ่านทั้งที่ netlist ผิด | ตรวจโครงสร้าง ไม่ได้ตรวจฟังก์ชัน ต้องใช้ GLS หรือ formal |
| A.11 | อธิบายความต่างระหว่าง pipelining กับ retiming เรื่อง latency | pipelining เพิ่ม latency, retiming ไม่เปลี่ยน latency |
| A.12 | เทียบผล Precision กับ reference flow ในตาราง 8.4 | แนวโน้มเหมือนกัน พร้อมอธิบายส่วนที่ต่าง |

## Troubleshooting

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| สคริปต์หาไฟล์ RTL ไม่เจอ | path ผิด เช่น `full_adder_struct.vhd` อยู่ day2 | ใช้ path เต็มจาก `$lab_dir/rtl/...` และรัน `check_precision_tcl.py` |
| Precision ไม่รู้จักคำสั่งในสคริปต์ (`add_source`, `set_top_module`, `export_netlist`) | สคริปต์เดิมเขียนแบบ ASIC โดยไม่มี Precision ทดสอบ | สร้างสคริปต์จาก Transcript ของ GUI (Part 6.1) และตรวจด้วย `help` |
| รายงาน timing ไม่มี path ที่ constrain | `get_ports` อ้าง port ที่ไม่มี constraint จึงถูกทิ้ง | รัน `check_sdc_ports.py` และดู warning ใน log |
| `create_clock` หา port ไม่เจอ | ดีไซน์ไม่มี clock (เช่น `adder8`) | ใช้ virtual clock (`create_clock -name vclk -period 10` ไม่มี `get_ports`) |
| netlist คำนวณผิดแต่รายงานปกติ | `abc` เลือก isolation cell | ใส่ `dont_use` ใน Liberty และตรวจด้วย GLS/formal |
| testbench FAIL หลังเพิ่ม pipeline stage | latency เพิ่ม ค่าคาดหวังมาเร็วกว่า output | เลื่อนเวลาตรวจใน testbench ตาม latency ใหม่ |
| ABC crash (return code 134) | Liberty เสียโครงสร้าง (วงเล็บไม่สมดุล) | นับ `{` กับ `}` ด้วย `grep -o '{' file.lib \| wc -l` |
| ไฟล์รายงาน OpenSTA ว่าง | คำสั่ง report พิมพ์ลง stdout | ใช้ `sta::redirect_file_begin` / `sta::redirect_file_end` |
| iverilog: `Unknown module type: ...udp_dff$...` | ไม่ได้ใส่ `primitives.v` | เพิ่มไฟล์ UDP ของ PDK |
| GLS: output ของ FF เป็น `x` ทั้งหมด | Icarus ใช้โมเดลแบบ TIMING | compile ด้วย `-D FUNCTIONAL` |

## Checklist ก่อนส่งงาน

- [ ] `vsim -c -do run_lab3.do` → `4/4 testbenches passed`
- [ ] `check_sdc_ports.py` → `0 error(s)` ทุกดีไซน์ และ `--selftest` → `SELFTEST PASSED`
- [ ] `check_precision_tcl.py` → `0 error(s)` และ `--selftest` → `SELFTEST PASSED`
- [ ] `bash scripts/run_reference_flow.sh` → `failures : 0`
- [ ] `reports/summary.txt` มีครบ 4 ดีไซน์
- [ ] (ถ้ามี Precision) synthesize ครบ 4 ดีไซน์ และมีรายงาน area/timing
- [ ] กรอกตาราง 8.4 และเขียนสรุปเปรียบเทียบตัวเลขกับตาราง 8.2 พร้อมอธิบายความต่าง
- [ ] ตอบแบบฝึกหัด A.1–A.12

อ่านต่อ: Lab 3B (Yosys + LibreLane) สำหรับ flow ASIC แบบ open-source เต็มรูปแบบ และ Lab 4 สำหรับ gate-level simulation เชิงลึก

## Sources

- [Siemens: Precision RTL (FPGA synthesis)](https://www.siemens.com/en-us/products/ic/precision/rtl/)
- [Altera: Setting Up a Project with the Precision RTL Synthesis Software](https://resources.altera.com/quartushelp/25.3/eda/synthesis/precision/eda_pro_prec_setup_proj.htm)
- [Microchip: Starting Precision RTL](https://onlinedocs.microchip.com/oxy/GUID-6BACC19D-0959-4B51-87AC-AD97B0E07E35-en-US-1/GUID-2F3B3165-F402-4639-A23E-EF441E5D8B3D.html)
- [Intel: Mapping the Design with Precision RTL](https://www.intel.com/content/www/us/en/docs/programmable/683122/25-1/mapping-the-design-with-precision-rtl.html)

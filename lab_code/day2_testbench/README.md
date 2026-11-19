# lab_code/day2_testbench — ชุดตัวอย่าง VHDL Testbench เชิงลึก

คู่โค้ดประกอบหัวข้อ **2.7 VHDL Testbench เชิงลึก** (`Manual_2_7_VHDL_Testbench_DeepDive.md`)

ทุกตัวอย่างในโฟลเดอร์นี้ **รันได้จริง** และผลลัพธ์ทุกบรรทัดในเอกสารมาจากการรันจริง
(ตรวจแล้วทั้งบน **GHDL 5.0.1** และ **ModelSim/Questa 2026.1**)

---

## 1. โครงสร้างโฟลเดอร์

```
lab_code/day2_testbench/
├── README.md                    ◀ ไฟล์นี้
├── run_all.sh                   ◀ รันทุกตัวอย่างด้วย GHDL (WSL)
├── run_one.do                   ◀ ใช้กับ ModelSim/Questa
├── counter_pkg.vhd              ◀ protected type (ตัวนับข้าม process)
├── tb_support_pkg.vhd           ◀ เครื่องมือร่วม: report_result / check_vector
├── uart_sb_pkg.vhd              ◀ scoreboard queue (protected type)
├── rtl/
│   ├── seq_det_moore.vhd        ◀ DUT: FSM ตรวจจับ "101"
│   ├── counter8.vhd             ◀ DUT: ตัวนับ 8-bit + clock enable
│   └── uart_tx.vhd              ◀ DUT: UART transmitter 8-N-1
├── ex01_delta_cycle.vhd         ◀ simulation cycle / delta cycle
├── ex02_signal_vs_variable.vhd  ◀ signal vs variable + shared variable
├── ex03_wait_statements.vhd     ◀ wait for / until / on / wait
├── ex04_clock_bug.vhd           ◀ BAD: นาฬิกาไม่เคยตี (พิสูจน์บั๊ก)
├── ex04_clock_fixed.vhd         ◀ GOOD: แก้แล้ว
├── ex05_procedure_checker.vhd   ◀ procedure / function / TB package
├── ex06_random_stimulus.vhd     ◀ random stimulus ที่ reproducible
├── ex07_uart_scoreboard.vhd     ◀ protocol-driven stimulus + scoreboard
├── ex08_file_io.vhd             ◀ อ่าน/เขียนไฟล์ด้วย STD.TEXTIO
├── ex09_assertion_severity.vhd  ◀ severity level → exit code
├── ex10_external_name.vhd       ◀ external name (VHDL-2008)
├── ex11_configuration.vhd       ◀ configuration declaration
├── ex12_event_log.vhd           ◀ event log แบบไม่พึ่ง simulator
├── vectors/
│   └── tb_vectors.txt           ◀ test vector สำหรับ ex08
└── reports/                     ◀ ผลลัพธ์จากการรันจริง (สร้างอัตโนมัติ)
    ├── ex08_report.txt          ◀ รายงานจาก ex08
    ├── ex12_events.txt          ◀ event log จาก ex12
    ├── ex12_wave.vcd            ◀ waveform จาก ex12
    ├── ghdl_final.log           ◀ log รวมของการรัน GHDL ทั้งชุด
    └── modelsim/                ◀ log ของแต่ละเคส + regression_summary.txt
```

> ไฟล์ต้นฉบับมี **24 ไฟล์** (ไม่นับ `reports/` ที่ได้จากการรัน)

---

## 2. วิธีรัน

### 2.1 GHDL (WSL Ubuntu) — ครั้งเดียวได้ทั้งชุด

```bash
wsl -d Ubuntu -u root --cd '/mnt/e/lab/VHDL(BOI)/lab_code/day2_testbench' -- bash run_all.sh
```

สคริปต์จะ:

1. วิเคราะห์ไฟล์ทั้งหมด (เรียงลำดับ package → rtl → testbench)
2. รันทีละตัวอย่าง พร้อมพิมพ์ **exit code** ของแต่ละเคส
3. รัน `ex09` ทั้ง 4 ระดับ severity เพื่อเทียบ exit code
4. รัน `ex11` ทั้ง 2 configuration (`cfg_using_rtl` / `cfg_using_alt`)
5. สร้าง `reports/` (รายงานของ ex08, event log + VCD ของ ex12)

### 2.2 ModelSim / Questa (Windows)

```powershell
cd "E:\lab\VHDL(BOI)\lab_code\day2_testbench"

vcom -2008 -work work counter_pkg.vhd tb_support_pkg.vhd uart_sb_pkg.vhd
vcom -2008 -work work rtl\seq_det_moore.vhd rtl\counter8.vhd rtl\uart_tx.vhd
vcom -2008 -work work ex*.vhd

vsim -c work.ex04_clock_fixed -do "run -all; quit -f"
```

หรือใช้สคริปต์ชุดเดียวกัน:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\_scratch\run_modelsim.ps1
```

> ต้องใช้ `-2008` เพราะตัวอย่างบางตัวใช้ `std.env.stop` และ external name

---

## 3. ผลการรันจริง (ย่อ)

| ตัวอย่าง | สิ่งที่พิสูจน์ | ผลจริง |
| --- | --- | --- |
| `ex01_delta_cycle` | อ่าน signal ที่เพิ่ง assign ได้ค่าเก่า | `sig_a='0'` ทันทีหลัง assign, `'1'` หลัง `wait for 0 ns` |
| `ex02_signal_vs_variable` | ตัวนับ signal รายงานค่าเก่า | `var_cnt=10` / `sig_cnt=0` (หลัง `wait for 0 ns` เป็น `1`) |
| `ex03_wait_statements` | wait ทั้ง 4 แบบ | ทำงานครบ ตัวอย่าง handshake `[B1]`→`[B2]` |
| `ex04_clock_bug` | นาฬิกาไม่ init → ไม่มี edge | **rising edges = 0**, `clk = 'U'` |
| `ex04_clock_fixed` | แก้แล้ว | **rising edges = 20** ใน 200 ns (คาบ 10 ns) |
| `ex05_procedure_checker` | procedure/function/pack | `PASS=3 FAIL=0` |
| `ex06_random_stimulus` | seed เดิม → ลำดับเดิม | `seed=12345, vectors=200, checksum=365623, count=98`, `PASS=200` |
| `ex07_uart_scoreboard` | decode UART + เทียบ queue | 5 เฟรม, `PASS=5 FAIL=0`, queue หมด |
| `ex08_file_io` | อ่าน vector + เขียนรายงาน | `vectors read = 12`, `PASS=12 FAIL=0` |
| `ex09_assertion_severity` | severity → exit code | note/warning/error → **0**, failure → **1** |
| `ex10_external_name` | อ่าน signal ภายใน DUT | `output port cnt = 5` = `internal cnt_i = 5` |
| `ex11_configuration` | สลับ architecture ของ DUT | `cfg_using_rtl` → **5**, `cfg_using_alt` → **10** |
| `ex12_event_log` | เขียน timeline ลงไฟล์ | `final count = 3`, ได้ทั้ง `.txt` และ `.vcd` |

---

## 4. บั๊กจริงที่ตัวอย่างเหล่านี้ช่วยจับได้

ตัวอย่างในโฟลเดอร์นี้ไม่ได้เขียนเพื่อ "ให้ผ่าน" แต่เขียนเพื่อ **พิสูจน์พฤติกรรม**
ของ VHDL ด้วยการรันจริง ระหว่างทำพบบั๊กจริงหลายจุด (ดูรายละเอียดในเอกสารหลัก):

1. `clk` ที่ไม่มี initial value → `not clk` = `'U'` → นาฬิกาไม่เคยตี
2. การอ่าน signal ที่ตัวเองเพิ่ง assign → ได้ค่าเก่า
3. ตัวนับ pass/fail ที่เป็น signal → รายงาน `FAIL=0` ทั้งที่มี FAIL จริง (false PASS)
4. `wait until` ที่เงื่อนไขเป็นจริงอยู่แล้ว → **ไม่ทำงานทันที** ต้องมี event ก่อน
   (ยืนยันตรงกันทั้ง GHDL 5.0.1 และ ModelSim 2026.1)
5. `baud_tick` ที่ทำเป็น square wave → DUT ก้าวหลาย bit ใน 1 จังหวะ
6. UART ส่ง LSB-first แต่ monitor decode แบบ MSB-first
7. `hread` ล้มเหลว (assertion failure) เมื่อบรรทัดนั้นเป็น comment
8. `IEEE.TEXTIO` มี `HREAD` เฉพาะ `BIT_VECTOR` — ไม่มี overload สำหรับ `INTEGER`
9. `numeric_std` ไม่รองรับ `+` บน `std_logic_vector` (ต้องเป็น `unsigned`)
10. ไม่มี `std.env.stop` → นาฬิกาวิ่งไม่จบ simulation ค้างจน timeout
11. external name อ้างถึง signal ที่ประกาศภายใน process ไม่ได้
12. `report` string ใส่ภาษาไทยไม่ได้ (VHDL string literal เป็น Latin-1)

---

## 5. ดูรายละเอียดเพิ่มเติม

- `Manual_2_7_VHDL_Testbench_DeepDive.md` — เอกสารทฤษฎีเชิงลึก (หัวข้อ 2.7)
- `Manual_2_4_2_5_RTL_Guidelines_and_Testbench_DeepDive.md` — แนวทาง RTL + testbench ระดับเมธอโดโลยี
- `Manual_4_1_Verification_Methodology_DeepDive.md` — verification methodology
- `Manual_4_2_Assertions_and_FunctionalCoverage_DeepDive.md` — assertion และ coverage
- `Manual_4_3_GateLevelSimulation_SDF_DeepDive.md` — GLS และ SDF

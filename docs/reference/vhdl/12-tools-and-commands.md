# บทที่ 12: คำสั่งเครื่องมือ

> บทนี้เป็นคลังคำสั่งที่ใช้จริงในโปรเจกต์ พร้อมคำอธิบาย flag ที่สำคัญ
> ทุกคำสั่งในบทนี้ทดสอบแล้วบนเครื่องมือที่ระบุในหัวข้อ 3

**เครื่องมือที่เกี่ยวข้อง:** GHDL 1.0.0, ModelSim/Questa, Yosys, OpenSTA, LibreLane

---

## สารบัญบท

- [1. ติดตั้งเครื่องมือ](#1-ติดตั้งเครื่องมือ)
- [2. GHDL](#2-ghdl)
- [3. ModelSim / Questa](#3-modelsim--questa)
- [4. Yosys](#4-yosys)
- [5. สคริปต์ตรวจสอบของโปรเจกต์](#5-สคริปต์ตรวจสอบของโปรเจกต์)
- [6. การรันซ้ำอัตโนมัติใน CI](#6-การรันซ้ำอัตโนมัติใน-ci)
- [7. การดู waveform](#7-การดู-waveform)

---

## 1. ติดตั้งเครื่องมือ

### 1.1 GHDL ใน WSL2 (Ubuntu 22.04)

```bash
sudo apt-get update
sudo apt-get install -y ghdl
ghdl --version
```

ผลที่คาดหวัง

```text
GHDL 1.0.0 (Ubuntu 1.0.0+dfsg-6) [Dunoon edition]
 Compiled with GNAT Version: 10.3.1 20211117
 mcode code generator
```

> ถ้ารันใน WSL2 แล้ว `sudo` ถามรหัสผ่าน แต่ต้องรันแบบไม่โต้ตอบ
> ให้ใช้ `wsl -d Ubuntu-22.04 -u root -- bash -lc "apt-get install -y ghdl"` แทน

### 1.2 Yosys และปลั๊กอิน GHDL

```bash
sudo apt-get install -y yosys ghdl-yosys-plugin
ghdl --plugin --list
```

ผลที่คาดหวังจาก `ghdl --plugin --list`

```text
/usr/lib/ghdl/plugins/ghdl.so
```

### 1.3 ModelSim / Questa

ติดตั้งจากช่องทางของผู้ให้บริการ แล้วตรวจเวอร์ชันด้วย

```powershell
vcom -version
vsim -version
```

> ห้องเรียนตั้งค่า `VHDL93 = 2002` จึงต้องคอมไพล์ด้วย `vcom -2002`
> ถ้าเปลี่ยนเป็น VHDL-2008 ให้ใช้ `vcom -2008` และตรวจว่าโค้ดใช้เฉพาะฟีเจอร์ที่รองรับ

## 2. GHDL

### 2.1 คำสั่งหลัก

| คำสั่ง | หน้าที่ |
|---|---|
| `ghdl -a` | วิเคราะห์ (analyze) ไฟล์ต้นทาง |
| `ghdl -e` | สร้าง executable (elaborate) |
| `ghdl -r` | จำลอง (run) |
| `ghdl --synth` | สังเคราะห์เป็น netlist |
| `ghdl -c` | แปลงเป็น object code เพื่อเร่งความเร็ว |
| `ghdl --clean` | ลบไฟล์ผลลัพธ์ |

### 2.2 flag ที่ใช้บ่อย

| flag | ความหมาย |
|---|---|
| `--std=08` / `--std=02` | มาตรฐานภาษาที่ใช้ |
| `--workdir=<dir>` | ไดเรกทอรีเก็บผลการวิเคราะห์ |
| `--work=<lib>` | ชื่อ library (ปกติคือ `work`) |
| `-fexplicit` | บังคับให้ประกาศ library/use ก่อนทุก design unit |
| `--assert-level=level` | ระดับความรุนแรงที่ทำให้ simulation หยุด |
| `--ieee=synopsys` | ใช้แพ็กเกจ IEEE แบบ Synopsys |
| `--syn-binding` | เปลี่ยนพฤติกรรมของ `binding` ให้ตรงกับมาตรฐาน |

> **flag `-fexplicit` ควรใส่ใน CI** เพราะจะบังคับให้ประกาศ context clause
> ก่อนทุก design unit ซึ่งเป็นกฎของโปรเจกต์นี้

### 2.3 ตัวอย่างคำสั่งที่ใช้จริง

```bash
# วิเคราะห์ทีเดียวหลายไฟล์
ghdl -a --std=08 --workdir=work src/dsp_types_pkg.vhd src/alu_ops_pkg.vhd
ghdl -a --std=08 --workdir=work src/alu_comb.vhd
ghdl -a --std=08 --workdir=work tb/tb_alu_comb.vhd

# สร้าง executable และจำลอง
ghdl -e --std=08 --workdir=work tb_alu_comb
ghdl -r --std=08 --workdir=work tb_alu_comb

# สังเคราะห์และตรวจ latch
ghdl --synth --std=08 --workdir=work alu_comb > reports/alu_comb_netlist.vhd
ghdl --synth --std=08 --workdir=work alu_comb | grep -i latch

# สร้าง netlist เป็น Verilog สำหรับส่งต่อให้ Yosys
ghdl --synth --std=08 --workdir=work alu_comb --out=verilog > reports/alu_comb_netlist.v
```

### 2.4 การหยุด simulation เมื่อเกิด error

```bash
ghdl -r --std=08 --workdir=work tb_alu_comb --assert-level=error
```

เมื่อ assertion ระดับ `error` หรือ `failure` เกิดขึ้น simulation จะหยุดทันที
และคืนรหัสผลที่ไม่เป็นศูนย์

### 2.5 ข้อผิดพลาดที่พบบ่อย

| ข้อความ | สาเหตุ | วิธีแก้ |
|---|---|---|
| `Unknown identifier "std_logic"` | ขาด context clause | ประกาศ `library`/`use` ซ้ำก่อนทุก design unit |
| `String literal has a character with value 0xE0` | มีภาษาไทยใน `report "..."` | ใช้ ASCII เท่านั้น |
| `cannot open file` | พาธของไฟล์ stimulus ไม่ถูกต้อง | รันจาก directory ที่กำหนดไว้ |
| `no such file or directory` | workdir ไม่มี | `mkdir -p work` ก่อน |
| `assertion failure` แล้วค้าง | watchdog ไม่ได้ยกเลิก | ตรวจ flag `done` ใน watchdog |

## 3. ModelSim / Questa

### 3.1 คำสั่ง

```powershell
# สร้าง library
vlib work

# คอมไพล์
vcom -2002 -work work src/counter4.vhd src/traffic_fsm.vhd
vcom -2002 -work work tb/tb_traffic_fsm.vhd

# จำลอง
vsim -c -work work -do "run -all; quit -f" tb_traffic_fsm
```

### 3.2 ข้อควรระวัง

- **ใบอนุญาต nodelocked**: ModelSim DE-64 อนุญาตเพียง 1 session ต่อเครื่อง
  ถ้ามี session อื่นใช้อยู่จะได้ข้อความ `License checkout has been disallowed`
  ให้รอสักครู่แล้วลองใหม่ (สคริปต์ `code/lab05/run.sh` มีตรรกะนี้แล้ว)
- **ไฟล์ transcript** ที่โผล่ขึ้นมาเป็นไฟล์ byproduct ของเครื่องมือ ไม่ต้องส่ง
- **มาตรฐาน**: ห้องเรียนตั้ง `VHDL93 = 2002` ต้องใช้ `vcom -2002`

### 3.3 ทำไมต้องผ่าน GHDL ก่อน

GHDL ใช้เวลาคอมไพล์และจำลองเร็วกว่า และทำงานเป็นสคริปต์ได้
ทำให้ตรวจสอบอัตโนมัติได้ใน CI
ส่วน ModelSim ใช้เมื่อต้องการ waveform ที่ละเอียดกว่า หรือทดสอบโค้ดเฉพาะที่
เขียนด้วย VHDL-2008

## 4. Yosys

### 4.1 คำสั่งพื้นฐาน

```bash
yosys -p "ghdl --std=08 alu_comb -e alu_comb; synth; stat"
```

ผลลัพธ์ที่ต้องดู

```text
=== alu_comb ===
   Number of wires:                45
   Number of cells:                78
     $_AND_          12
     $_DFF_P_        20
```

### 4.2 คำสั่งตรวจปัญหาที่พบบ่อย

```bash
# ตรวจ latch และ multiple drivers
yosys -m ghdl -p "ghdl --std=08 alu_comb -e alu_comb; proc; opt; check -assert"

# ดูรายงานเต็ม
yosys -m ghdl -p "ghdl --std=08 alu_comb -e alu_comb; synth; tee -o reports/stat.txt stat"
```

### 4.3 ข้อควรระวัง

- ปลั๊กอิน `ghdl` ต้องตรงกับเวอร์ชัน GHDL
- เมื่อ Yosys รันบนไฟล์ที่อยู่ใน `E:` (drvfs) ให้ใช้ path แบบ WSL
  เช่น `/mnt/e/lab/DICD/...`
- ผลลัพธ์ของ Yosys เป็นการประเมินเบื้องต้น ไม่ใช่ผล sign-off ของเครื่องมือเชิงพาณิชย์

## 5. สคริปต์ตรวจสอบของโปรเจกต์

### 5.1 ตรวจตัวอย่างหนึ่งตัว

```bash
cd code/reference/vhdl
bash scripts/check_example.sh ex01_alu_comb alu_comb tb_alu_comb
```

สคริปต์นี้รัน 6 เกณฑ์ต่อ testbench

| เกณฑ์ | คำสั่ง | เกณฑ์ผ่าน |
|---|---|---|
| `GHDL_ANALYZE_08` | `ghdl -a --std=08` | ไม่มี error |
| `GHDL_ELABORATE_08` | `ghdl -e --std=08` | สร้าง executable ได้ |
| `GHDL_RUN` | `ghdl -r --std=08` | ไม่มี assertion failure และเจอ marker PASS |
| `GHDL_ANALYZE_02` | `ghdl -a --std=02` | ไม่มี error |
| `GHDL_ELABORATE_02` | `ghdl -e --std=02` | สร้าง executable ได้ |
| `GHDL_SYNTH` | `ghdl --synth` | สร้าง netlist ได้ |

### 5.2 ตรวจทุกตัวอย่าง

```bash
cd code/reference/vhdl
./run.sh
```

ผลสรุปอยู่ที่ `reports/summary.txt` และสคริปต์คืน exit code 0 เมื่อผ่านทั้งหมด

### 5.3 ใช้กับ CI

```yaml
# .github/workflows/vhdl-reference.yml (ตัวอย่าง)
name: vhdl-reference
on: [push, pull_request]
jobs:
  check:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - name: Install GHDL
        run: sudo apt-get update && sudo apt-get install -y ghdl
      - name: Run checks
        run: cd code/reference/vhdl && ./run.sh
```

## 6. การรันซ้ำอัตโนมัติใน CI

### 6.1 หลักการ

- **รันทุกครั้งที่โค้ดเปลี่ยน** ไม่ใช่เฉพาะตอน release
- **เก็บ log เป็น artifact** เพื่อให้ตรวจย้อนหลังได้
- **ให้ CI เป็นผู้ตัดสินผลผ่าน** โดยตรวจ marker ใน log ไม่ใช่แค่ดูรหัสผลลัพธ์

### 6.2 ตัวอย่างสคริปต์ตรวจแบบเรียบง่าย

```bash
#!/usr/bin/env bash
set -euo pipefail

ghdl -a --std=08 --workdir=work src/*.vhd tb/*.vhd
ghdl -e --std=08 --workdir=work tb_alu_comb
ghdl -r --std=08 --workdir=work tb_alu_comb --assert-level=error | tee reports/run.log

if ! grep -q "GOLDEN_ALU_COMB_PASS" reports/run.log; then
  echo "FAIL: ไม่พบ marker PASS"
  exit 1
fi
echo "PASS"
```

## 7. การดู waveform

### 7.1 GHDL กับ GTKWave

```bash
ghdl -r --std=08 --workdir=work tb_alu_comb --vcd=reports/wave.vcd
gtkwave reports/wave.vcd
```

หรือให้ GHDL หยุดรอให้เปิด GTKWave พร้อมกัน

```bash
ghdl -r --std=08 --workdir=work tb_alu_comb --vcd=reports/wave.vcd --stop-time=500ns &
gtkwave reports/wave.vcd &
```

### 7.2 ModelSim

```powershell
vsim -work work tb_alu_comb
# ในหน้าต่าง transcript: add wave ... ; run -all
```

### 7.3 สิ่งที่ควรดูใน waveform

| สัญญาณ | ต้องเห็นอะไร |
|---|---|
| `clk` | ขอบนาฬิกาที่สม่ำเสมอ |
| `rst_n` | ช่วง reset ที่ชัดเจน |
| สัญญาณอินพุต | เปลี่ยนตาม testcase |
| สัญญาณภายใน | การเปลี่ยนแปลงตรงตามตรรกะ ไม่มี glitch แปลกปลอม |
| สัญญาณเอาต์พุต | เปลี่ยนหลังขอบนาฬิกา ไม่ก่อน |

> ถ้าเห็นเอาต์พุตของโมดูล combinational เปลี่ยน "ก่อน" ขอบนาฬิกา
> แปลว่าโมดูลนั้นไม่ได้ถูก register ไว้ หรือมีบั๊กเรื่อง combinational loop

---

## แบบฝึกหัดท้ายบท

1. ติดตั้ง GHDL ใน WSL2 แล้วรัน `bash code/reference/vhdl/scripts/check_example.sh`
   กับตัวอย่างทุกตัว บันทึกผลลัพธ์
2. เปรียบเทียบเวลาที่ใช้ของ `ghdl -a` แบบแยกคำสั่งกับแบบรวมไฟล์
   แล้วอธิบายว่าเหตุใดการแยกคำสั่งจึงปลอดภัยกว่าเมื่อมี package
3. รัน `ghdl --synth` กับตัวอย่างที่มี latch โดยตั้งใจ แล้วตรวจจับ latch
   ด้วย `grep -i latch`
4. สร้าง waveform ด้วย GHDL และ GTKWave จาก testbench ตัวใดก็ได้
   แล้วบันทึกภาพหน้าจอพร้อมคำอธิบาย
5. เขียน CI workflow ที่รัน `run.sh` และเก็บ log เป็น artifact

## คำถามท้ายบท

1. ทำไมต้องคอมไพล์ทั้ง `--std=08` และ `--std=02` และ flag ใดของ GHDL
   ที่ช่วยบังคับให้ประกาศ context clause ก่อนทุก design unit
2. ข้อผิดพลาด "Unknown identifier" เกิดจากสาเหตุใด และแก้อย่างไร
3. ทำไม simulator หลายตัวคืนรหัสผลลัพธ์ 0 แม้ทดสอบไม่ผ่าน และมีผลต่อ
   การออกแบบสคริปต์ CI อย่างไร
4. `ghdl --synth` พิสูจน์เรื่องใดได้ และไม่พิสูจน์เรื่องใด
5. ข้อจำกัดของใบอนุญาต ModelSim nodelocked มีผลต่อการทดสอบในห้องเรียนอย่างไร

---

**อ่านต่อ:** [บทที่ 13 — ข้อผิดพลาดที่พบบ่อย](13-common-mistakes.md)

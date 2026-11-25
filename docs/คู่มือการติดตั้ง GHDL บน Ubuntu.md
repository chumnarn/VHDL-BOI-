# **คู่มือการติดตั้ง GHDL บน Ubuntu**

## **GHDL Installation & VHDL Simulation – Step-by-Step Guide**

คู่มือการติดตั้ง GHDL สำหรับการออกแบบและจำลองการทำงานของวงจรดิจิทัลด้วยภาษา VHDL โดยครอบคลุมทั้งการติดตั้งเครื่องมือ การเขียน RTL Design การสร้าง Testbench การทำ Functional Simulation และการตรวจสอบ Waveform ด้วย GTKWave

เหมาะสำหรับการอบรม Digital IC Design, VHDL Programming, FPGA Design และ ASIC Design โดยสามารถใช้งานได้ทั้ง Ubuntu Native และ Ubuntu บน WSL2 ภายใต้ Windows 11

## **1. ทำความรู้จัก GHDL**

**GHDL (VHDL Simulator)** เป็นเครื่องมือ Open-source สำหรับการวิเคราะห์ คอมไพล์ และจำลองการทำงานของวงจรที่เขียนด้วยภาษา VHDL

รองรับมาตรฐาน VHDL หลายรุ่น เช่น VHDL-87, VHDL-93, VHDL-2002 และ VHDL-2008 รวมถึงการรองรับ VHDL-2019 บางส่วนในรุ่นใหม่

ความสามารถหลักประกอบด้วย

- VHDL Analysis and Compilation
- Design Elaboration
- RTL Functional Simulation
- Self-checking Testbench
- Assertion-based Verification
- Waveform Generation (VCD, GHW, FST)
- Integration with GTKWave
- Integration with Python/cocotb
- VHDL Synthesis ผ่าน GHDL และ Yosys ในสภาพแวดล้อมที่รองรับ

### **1.1 GHDL Simulation Flow**

### **1.2 เครื่องมือที่ใช้**

| เครื่องมือ | หน้าที่                     |
| ---------- | --------------------------- |
| Ubuntu     | Operating System            |
| GHDL       | VHDL Compiler และ Simulator |
| GTKWave    | Waveform Viewer             |
| VS Code    | RTL Code Editor             |
| GNU Make   | Simulation Automation       |
| Git        | Version Control             |
| Yosys      | Logic Synthesis (เพิ่มเติม) |

## **2. ความต้องการของระบบ**

| รายการ              | ข้อแนะนำ                                        |
| ------------------- | ----------------------------------------------- |
| Operating System    | Ubuntu 22.04 / 24.04 LTS                        |
| Windows Environment | Windows 11 + WSL2                               |
| Architecture        | x86-64                                          |
| RAM                 | 4 GB ขึ้นไป                                     |
| Disk Space          | พื้นที่ว่างอย่างน้อย 2 GB สำหรับสภาพแวดล้อม Lab |
| VHDL Standard       | VHDL-2008                                       |
| Internet            | สำหรับดาวน์โหลด Package                         |

คู่มือนี้เลือกใช้ VHDL-2008 เป็นมาตรฐานหลัก เพื่อให้สอดคล้องกับการออกแบบ RTL และ Testbench สำหรับงาน FPGA และ ASIC

## **3. ติดตั้ง GHDL บน Ubuntu**

### **Step 1: ตรวจสอบ Ubuntu Version**

เปิด Ubuntu Terminal แล้วใช้คำสั่ง

```
lsb_release -a
```

ตรวจสอบ CPU Architecture

```
uname -m
```

ตัวอย่างผลลัพธ์

```
Distributor ID: Ubuntu
Description:    Ubuntu 24.04 LTS
Release:        24.04
Codename:       noble
```

สำหรับเครื่องที่ใช้งาน WSL2 สามารถตรวจสอบจาก Windows PowerShell ด้วยคำสั่ง

```
wsl -l -v
```

ควรตรวจสอบว่า Ubuntu ได้รับการติดตั้งและลงทะเบียนเรียบร้อยแล้วก่อนดำเนินการต่อ

### **Step 2: Update Ubuntu Packages**

```
sudo apt update
sudo apt upgrade -y
```

เปิดใช้งาน Universe Repository

```
sudo apt install -y software-properties-common
sudo add-apt-repository -y universe
sudo apt update
```

### **Step 3: ติดตั้ง GHDL**

วิธีที่ง่ายที่สุดและเหมาะสำหรับการอบรมคือการติดตั้งผ่าน APT Package Manager

```
sudo apt install -y ghdl
```

ตรวจสอบการติดตั้ง

```
ghdl --version
```

ตรวจสอบตำแหน่งโปรแกรม

```
which ghdl
```

ผลลัพธ์โดยทั่วไป

```
/usr/bin/ghdl
```

ตรวจสอบคำสั่งที่ GHDL รองรับ

```
ghdl --help
```

ตรวจสอบเวอร์ชันที่มีอยู่ใน Ubuntu Repository

```
apt-cache policy ghdl
```

เวอร์ชันที่ได้รับจะขึ้นอยู่กับ Ubuntu Release และ Repository ที่ใช้งาน

### **Step 4: ติดตั้ง GTKWave**

GTKWave เป็นโปรแกรมสำหรับแสดงและวิเคราะห์ Digital Signal Waveform

```
sudo apt install -y gtkwave
```

ตรวจสอบเวอร์ชัน

```
gtkwave --version
```

ทดสอบเปิดโปรแกรม

```
gtkwave
```

[gtkwave screen shot](https://images.openai.com/static-rsc-4/RG5cAg5QMgsH_xaZkPdPL6iVO9A4n0QCLAGwopZeLSHOQzlWy17vOW1Eo6On5H3kOgbFAny2RCukH72w4iJX7rzqPTBzqdMXA5RIy1pKPC4jHJ_pdZD5yIBzm6UUTRWix69-U8i_Z0R-BEYBTDRxodqu-fp1vlimNngH1TQyKB8?purpose=inline)

[cs.colby.edu](https://cs.colby.edu/courses/F16/cs232-labs/labs/lab03/index.php?utm_source=chatgpt.com)

### **Step 5: ติดตั้งเครื่องมือเพิ่มเติม**

```
sudo apt install -y \
    git \
    make \
    gcc \
    g++ \
    build-essential \
    python3 \
    python3-pip \
    python3-venv
```

เครื่องมือเหล่านี้จะช่วยให้สามารถพัฒนา RTL Design, Simulation Automation และ Verification Environment ได้ครบถ้วนยิ่งขึ้น

## **4. การเลือก GHDL Backend**

GHDL มี Backend หลัก ได้แก่ mcode, LLVM และ GCC ซึ่งมีวิธีการประมวลผลแตกต่างกัน&#x20;

[image](https://www.google.com/s2/favicons?domain=https://github.com\&sz=32)

GitHub+1



**mcode**

เหมาะกับการอบรม

ติดตั้งง่าย วิเคราะห์ RTL ได้รวดเร็ว ไม่ต้องสร้าง executable แยก

**LLVM**

Advanced simulation

สร้าง native executable และเหมาะกับงานที่ต้องการเครื่องมือขั้นสูง

**GCC**

Advanced compilation

ใช้ GCC Backend รองรับงานบางประเภท เช่น Code Coverage

| คุณสมบัติ             | mcode    | LLVM        | GCC     |
| --------------------- | -------- | ----------- | ------- |
| RTL Simulation        | รองรับ   | รองรับ      | รองรับ  |
| VHDL-2008             | รองรับ   | รองรับ      | รองรับ  |
| Native executable แยก | ไม่สร้าง | สร้าง       | สร้าง   |
| ความง่ายในการติดตั้ง  | สูง      | สูงผ่าน APT | ปานกลาง |
| Basic VHDL Lab        | เหมาะมาก | เหมาะ       | เหมาะ   |
| Advanced Verification | ได้      | เหมาะ       | เหมาะ   |

ติดตั้ง mcode Backend โดยตรง

```
sudo apt install -y ghdl-mcode
```

หรือติดตั้ง LLVM Backend

```
sudo apt install -y ghdl-llvm
```

หรือติดตั้ง GCC Backend

```
sudo apt install -y ghdl-gcc
```

ตรวจสอบ Backend ที่กำลังใช้งาน

```
ghdl --version
```

หากติดตั้งหลาย Backend สามารถเรียกชื่อโปรแกรมโดยตรง เช่น

```
ghdl-mcode --version
ghdl-llvm --version
```

**ข้อแนะนำ:** สำหรับ VHDL และ Digital IC Design Workshop ให้เริ่มต้นด้วย `ghdl-mcode` ก่อน เนื่องจากตั้งค่าง่ายและเพียงพอสำหรับ RTL Functional Simulation

## **5. Lab 1: ทดสอบการติดตั้งด้วยวงจร AND Gate**

### **5.1 สร้าง Project Directory**

```
mkdir -p ~/vhdl_labs/lab01_and_gate
cd ~/vhdl_labs/lab01_and_gate
```

โครงสร้าง Project ที่ต้องการ

```
lab01_and_gate/
├── and_gate.vhd
├── tb_and_gate.vhd
├── Makefile
├── run.sh
└── wave.vcd
```

### **5.2 ออกแบบ AND Gate**

\\[ Y=A\cdot B \\]

Truth Table

| A | B | Y |
| - | - | - |
| 0 | 0 | 0 |
| 0 | 1 | 0 |
| 1 | 0 | 0 |
| 1 | 1 | 1 |

สร้างไฟล์

```
nano and_gate.vhd
```

เขียน VHDL RTL Code ดังนี้

```
-- File: and_gate.vhd

library ieee;
use ieee.std_logic_1164.all;

entity and_gate is
    port (
        a : in  std_logic;
        b : in  std_logic;
        y : out std_logic
    );
end entity and_gate;

architecture rtl of and_gate is
begin

    y <= a and b;

end architecture rtl;
```

บันทึกไฟล์ใน nano ด้วย `Ctrl+O` ตามด้วย Enter และ `Ctrl+X`

### **5.3 สร้าง Self-checking Testbench**

```
nano tb_and_gate.vhd
```

```
-- File: tb_and_gate.vhd
-- VHDL-2008 Self-checking Testbench

library ieee;
use ieee.std_logic_1164.all;

library std;
use std.env.all;

entity tb_and_gate is
end entity tb_and_gate;

architecture sim of tb_and_gate is

    signal a : std_logic := '0';
    signal b : std_logic := '0';
    signal y : std_logic;

begin

    -- Device Under Test
    dut : entity work.and_gate(rtl)
        port map (
            a => a,
            b => b,
            y => y
        );

    -- Stimulus Process
    stimulus : process
    begin

        -- Test Case 1
        a <= '0';
        b <= '0';
        wait for 10 ns;

        assert y = '0'
            report "Test Case 1 FAILED"
            severity failure;

        -- Test Case 2
        a <= '0';
        b <= '1';
        wait for 10 ns;

        assert y = '0'
            report "Test Case 2 FAILED"
            severity failure;

        -- Test Case 3
        a <= '1';
        b <= '0';
        wait for 10 ns;

        assert y = '0'
            report "Test Case 3 FAILED"
            severity failure;

        -- Test Case 4
        a <= '1';
        b <= '1';
        wait for 10 ns;

        assert y = '1'
            report "Test Case 4 FAILED"
            severity failure;

        report "ALL TEST CASES PASSED"
            severity note;

        finish;
        wait;

    end process stimulus;

end architecture sim;
```

Testbench นี้เป็นแบบ Direct Input และ Self-checking สามารถตรวจสอบผลลัพธ์ครบทั้ง 4 Test Cases โดยอัตโนมัติ

## **6. ขั้นตอนการทำ VHDL Simulation**

GHDL Simulation Flow แบ่งเป็น 3 ขั้นตอนหลัก ได้แก่ Analysis, Elaboration และ Simulation

### **Step 1: Analysis – Compile RTL Design**

```
ghdl -a --std=08 and_gate.vhd
```

Compile Testbench

```
ghdl -a --std=08 tb_and_gate.vhd
```

หรือ Compile พร้อมกัน

```
ghdl -a --std=08 and_gate.vhd tb_and_gate.vhd
```

ตรวจสอบ Working Library

```
ls -l
```

จะพบไฟล์

```
work-obj08.cf
```

ไฟล์นี้เก็บข้อมูลเกี่ยวกับ Design Units ที่ผ่านการ Analysis แล้วใน Working Library

### **Step 2: Elaboration**

```
ghdl -e --std=08 tb_and_gate
```

ขั้นตอนนี้ใช้สำหรับตรวจสอบและสร้าง Design Hierarchy ของ Top-level Testbench

### **Step 3: Run Simulation**

```
ghdl -r --std=08 tb_and_gate
```

ผลลัพธ์ที่คาดหวัง

```
@40ns:(report note): ALL TEST CASES PASSED
simulation finished @40ns
```

### **Step 4: Generate Waveform**

สร้าง VCD Waveform

```
ghdl -r --std=08 tb_and_gate --vcd=wave.vcd
```

หรือสร้าง GHW Waveform

```
ghdl -r --std=08 tb_and_gate --wave=wave.ghw
```

หรือสร้าง FST Waveform

```
ghdl -r --std=08 tb_and_gate --fst=wave.fst
```

| Waveform Format | คุณสมบัติ                                            |
| --------------- | ---------------------------------------------------- |
| VCD             | รูปแบบมาตรฐาน อ่านเป็น Text ได้                      |
| GHW             | รองรับ VHDL Data Types ได้หลากหลาย                   |
| FST             | ขนาดไฟล์มักเล็กกว่า VCD เหมาะกับ Simulation ขนาดใหญ่ |

สำหรับ VHDL FSM และ Enumerated State แนะนำให้ใช้ GHW

## **7. ตรวจสอบ Waveform ด้วย GTKWave**

เปิด Waveform

```
gtkwave wave.vcd
```

หรือ

```
gtkwave wave.ghw
```

ในหน้าต่าง GTKWave ให้เลือก Design Hierarchy `tb_and_gate` จากนั้นเลือกสัญญาณ `a`, `b` และ `y` แล้วกด Append หรือ Insert และเลือก Zoom Full

### **Expected Simulation Waveform**

Expected Waveform: ไม่แสดง delta cycle โดย Output y เป็น 1 เฉพาะช่วงที่ a และ b เป็น 1 พร้อมกัน

| Simulation Time | A | B | Y | Expected |
| --------------- | - | - | - | -------- |
| 0–10 ns         | 0 | 0 | 0 | PASS     |
| 10–20 ns        | 0 | 1 | 0 | PASS     |
| 20–30 ns        | 1 | 0 | 0 | PASS     |
| 30–40 ns        | 1 | 1 | 1 | PASS     |

### **Interactive AND Gate Simulation**

สามารถทดลองเปลี่ยนค่า Input เพื่อศึกษาการทำงานของ AND Gate ได้จากตัวอย่างด้านล่าง

Input A

01

Input B

01

Output Y

# **0**

## **8. สร้าง Bash Script สำหรับ Simulation Automation**

แทนที่จะพิมพ์คำสั่ง GHDL ทีละคำสั่ง สามารถสร้าง Script เพื่อรัน Simulation ทั้งหมดได้

สร้างไฟล์

```
nano run.sh
```

```
#!/usr/bin/env bash

set -euo pipefail

echo "===================================="
echo " GHDL VHDL SIMULATION"
echo "===================================="

echo "[1] Clean previous simulation"
ghdl --clean --std=08

echo "[2] Analyze RTL"
ghdl -a --std=08 and_gate.vhd

echo "[3] Analyze Testbench"
ghdl -a --std=08 tb_and_gate.vhd

echo "[4] Elaborate Design"
ghdl -e --std=08 tb_and_gate

echo "[5] Run Simulation"
ghdl -r --std=08 tb_and_gate \
    --assert-level=error \
    --vcd=wave.vcd \
    --wave=wave.ghw

echo "===================================="
echo " SIMULATION PASSED"
echo "===================================="
```

กำหนด Permission

```
chmod +x run.sh
```

รัน Simulation

```
./run.sh
```

เปิด Waveform

```
gtkwave wave.ghw
```

หาก Testbench ตรวจพบ Error ตัว Script จะหยุดทำงานทันที เนื่องจากกำหนด `set -e` ไว้

## **9. สร้าง Makefile สำหรับ VHDL Project**

สร้างไฟล์

```
nano Makefile
```

```
GHDL      = ghdl
GHDLFLAGS = --std=08
TOP       = tb_and_gate

RTL       = and_gate.vhd
TB        = tb_and_gate.vhd

.PHONY: all analyze elaborate sim wave clean

all: sim

analyze:
	$(GHDL) -a $(GHDLFLAGS) $(RTL)
	$(GHDL) -a $(GHDLFLAGS) $(TB)

elaborate: analyze
	$(GHDL) -e $(GHDLFLAGS) $(TOP)

sim: elaborate
	$(GHDL) -r $(GHDLFLAGS) $(TOP) \
	    --assert-level=error \
	    --vcd=wave.vcd \
	    --wave=wave.ghw

wave: sim
	gtkwave wave.ghw

clean:
	$(GHDL) --clean $(GHDLFLAGS)
	rm -f wave.vcd wave.ghw
	rm -f work-obj08.cf
```

**หมายเหตุ:** คำสั่งภายใต้ Makefile Target ต้องขึ้นต้นด้วย Tab ไม่ใช่ Space

คำสั่งใช้งาน

| คำสั่ง           | การทำงาน                   |
| ---------------- | -------------------------- |
| `make`           | รัน Simulation ทั้งหมด     |
| `make analyze`   | Compile RTL และ Testbench  |
| `make elaborate` | Elaborate Design           |
| `make sim`       | Run Functional Simulation  |
| `make wave`      | Simulation และเปิด GTKWave |
| `make clean`     | ลบ Simulation Results      |

ทดสอบ

```
make clean
make
make wave
```

## **10. ติดตั้ง GHDL จาก Source Code**

กรณีที่ GHDL จาก Ubuntu Repository มีเวอร์ชันเก่าเกินไป หรือจำเป็นต้องใช้ Feature ใหม่ สามารถ Compile จาก Source Code ได้

### **Step 1: Install Dependencies**

```
sudo apt update

sudo apt install -y \
    git \
    gcc \
    g++ \
    gnat \
    make \
    build-essential \
    zlib1g-dev
```

### **Step 2: Clone GHDL Repository**

```
mkdir -p ~/eda
cd ~/eda

git clone https://github.com/ghdl/ghdl.git

cd ghdl
```

### **Step 3: เลือก Release Version**

```
git tag --sort=-version:refname | head -20
```

ตัวอย่างเลือก GHDL v6.0.0 ซึ่งมีการเผยแพร่ Release อย่างเป็นทางการแล้ว&#x20;

[image](https://www.google.com/s2/favicons?domain=https://github.com\&sz=32)

GitHub+1



```
git checkout v6.0.0
```

### **Step 4: Configure**

ตัวอย่างการ Build ด้วย mcode Backend

```
mkdir -p build
cd build

../configure --prefix="$HOME/.local"
```

### **Step 5: Compile**

```
make -j"$(nproc)"
```

### **Step 6: Install**

```
make install
```

### **Step 7: กำหนด PATH**

```
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

source ~/.bashrc
```

ตรวจสอบการติดตั้ง

```
which ghdl
ghdl --version
```

ควรพบ GHDL ภายใต้ `$HOME/.local/bin`

กระบวนการ Build ด้วย mcode ใช้ GCC และ GNAT เป็นเครื่องมือหลัก และเป็น Backend ที่มีขั้นตอน Build ค่อนข้างเรียบง่าย&#x20;

[image](https://www.google.com/s2/favicons?domain=https://ghdl.github.io\&sz=32)

7.0.0-dev+1



## **11. การใช้งาน GHDL ร่วมกับ WSL2**

สำหรับ Ubuntu บน Windows 11 แนะนำให้ใช้ WSL2 และ WSLg เพื่อเปิด GTKWave ในรูปแบบ GUI

### **11.1 ตรวจสอบ WSL**

เปิด Windows PowerShell

```
wsl --version
wsl --status
wsl -l -v
```

อัปเดต WSL

```
wsl --update
wsl --shutdown
```

จากนั้นเปิด Ubuntu ใหม่

### **11.2 ตรวจสอบ WSLg**

ใน Ubuntu Terminal

```
echo "$DISPLAY"
echo "$WAYLAND_DISPLAY"
```

ทดสอบ GTKWave

```
gtkwave wave.vcd
```

หาก WSLg ทำงานปกติ GTKWave จะเปิดเป็นหน้าต่าง GUI บน Windows ได้โดยไม่จำเป็นต้องติดตั้ง X Server เพิ่มเติม

### **11.3 การเข้าถึงไฟล์ Ubuntu จาก Windows**

```
explorer.exe .
```

คำสั่งนี้จะเปิด Windows File Explorer ณ ตำแหน่ง Project Directory ปัจจุบัน

แนะนำให้เก็บ VHDL Project ไว้ใน Linux Filesystem เช่น

```
/home/username/vhdl_labs/
```

แทนการเก็บไว้ใน `/mnt/c/` สำหรับงาน Compile และ Simulation ที่ต้องอ่านเขียนไฟล์จำนวนมาก

## **12. การใช้งานร่วมกับ Visual Studio Code**

ติดตั้ง VS Code บน Windows แล้วติดตั้ง Extension ที่เกี่ยวข้อง

| Extension      | หน้าที่                    |
| -------------- | -------------------------- |
| WSL            | เชื่อม VS Code กับ Ubuntu  |
| VHDL by Mshr-h | VHDL Syntax Highlighting   |
| VHDL LS        | VHDL Language Server       |
| Makefile Tools | จัดการ Makefile            |
| Python         | รองรับ Python Verification |

เปิด Project จาก Ubuntu

```
cd ~/vhdl_labs/lab01_and_gate

code .
```

จากนั้นสามารถแก้ไข VHDL Source Code และเปิด Terminal เพื่อสั่ง Simulation ภายใน VS Code ได้โดยตรง

```
make sim
```

## **13. สรุปคำสั่งพื้นฐานของ GHDL**

### **GHDL Command Cheat Sheet**

| คำสั่ง                      | หน้าที่                                                 |
| --------------------------- | ------------------------------------------------------- |
| `ghdl --version`            | ตรวจสอบ Version                                         |
| `ghdl --help`               | แสดงคำสั่งทั้งหมด                                       |
| `ghdl -a --std=08 file.vhd` | Analysis                                                |
| `ghdl -e --std=08 top`      | Elaboration                                             |
| `ghdl -r --std=08 top`      | Simulation                                              |
| `ghdl -s --std=08 file.vhd` | Syntax Check                                            |
| `ghdl --dir --std=08`       | แสดง Design Units                                       |
| `ghdl --clean --std=08`     | Clean Generated Files                                   |
| `ghdl --remove --std=08`    | Remove Library และ Generated Files                      |
| `--stop-time=100ns`         | กำหนดเวลาสิ้นสุด Simulation                             |
| `--vcd=wave.vcd`            | สร้าง VCD Waveform                                      |
| `--wave=wave.ghw`           | สร้าง GHW Waveform                                      |
| `--fst=wave.fst`            | สร้าง FST Waveform                                      |
| `--assert-level=error`      | หยุด Simulation เมื่อ Assertion ระดับ error หรือสูงกว่า |
| `--work=libname`            | กำหนดชื่อ Library                                       |
| `--workdir=directory`       | กำหนด Library Directory                                 |

## **14. เปรียบเทียบคำสั่ง GHDL กับ QuestaSim/ModelSim**

สำหรับผู้ที่เคยใช้งาน QuestaSim หรือ ModelSim สามารถเปลี่ยนมาใช้ GHDL ได้ตามตารางนี้

| ขั้นตอน           | QuestaSim / ModelSim | GHDL                                       |
| ----------------- | -------------------- | ------------------------------------------ |
| Create Library    | `vlib work`          | สร้างข้อมูล Library อัตโนมัติเมื่อ Analyze |
| Compile VHDL      | `vcom -2008 rtl.vhd` | `ghdl -a --std=08 rtl.vhd`                 |
| Compile Testbench | `vcom -2008 tb.vhd`  | `ghdl -a --std=08 tb.vhd`                  |
| Elaborate         | `vsim work.tb`       | `ghdl -e --std=08 tb`                      |
| Run Simulation    | `run -all`           | `ghdl -r --std=08 tb`                      |
| Run 100 ns        | `run 100 ns`         | `--stop-time=100ns`                        |
| Waveform          | `add wave -r /*`     | `--wave=wave.ghw`                          |
| Waveform Viewer   | Questa Wave Window   | GTKWave                                    |
| Automation        | Tcl / DO File        | Bash / Makefile                            |
| License           | ขึ้นอยู่กับ Edition  | Open-source                                |

GHDL เหมาะสำหรับ VHDL RTL Simulation และ Automated Regression Testing แต่ไม่ได้ทดแทนความสามารถทั้งหมดของ QuestaSim โดยเฉพาะ Mixed-language Simulation, SystemVerilog/UVM และ Advanced Verification

## **15. การแก้ไขปัญหาที่พบบ่อย**

| Error Message                         | สาเหตุ / วิธีแก้ไข                             |
| ------------------------------------- | ---------------------------------------------- |
| `ghdl: command not found`             | ติดตั้ง GHDL หรือตรวจสอบ PATH                  |
| `Unable to locate package ghdl`       | เปิด Universe Repository และ `sudo apt update` |
| `cannot find entity or configuration` | ตรวจสอบชื่อ Top-level และ Compile Order        |
| `unit ... not found in library work`  | Compile Design Unit ที่เกี่ยวข้องก่อน          |
| `unit env not found in library std`   | ใช้ `--std=08` ทุกขั้นตอน                      |
| `cannot open display`                 | ตรวจสอบ WSLg หรือ Linux Display                |
| `assertion failure`                   | ตรวจสอบ RTL และ Expected Output                |
| `missing separator`                   | ใช้ Tab ใน Makefile                            |
| `Permission denied`                   | ใช้ `chmod +x run.sh`                          |
| Simulation ไม่หยุด                    | ใช้ `finish` หรือ `--stop-time`                |

### **15.1 ตรวจสอบ GHDL PATH ซ้ำซ้อน**

```
type -a ghdl
which ghdl
ghdl --version
```

อาจพบทั้ง

```
/usr/bin/ghdl
/home/username/.local/bin/ghdl
```

ให้ตรวจสอบว่าเรียกใช้งานเวอร์ชันที่ต้องการจริง

### **15.2 ล้าง Working Library แล้ว Compile ใหม่**

```
ghdl --remove --std=08

ghdl -a --std=08 and_gate.vhd
ghdl -a --std=08 tb_and_gate.vhd
ghdl -e --std=08 tb_and_gate

ghdl -r --std=08 tb_and_gate --wave=wave.ghw
```

### **15.3 ตรวจสอบ Exit Status**

```
ghdl -r --std=08 tb_and_gate --assert-level=error

echo $?
```

| Exit Code | ความหมาย                           |
| --------- | ---------------------------------- |
| 0         | Simulation สำเร็จ                  |
| Non-zero  | เกิด Error หรือ Simulation Failure |

## **16. All-in-One Installation Script**

สามารถคัดลอก Script ด้านล่างไปติดตั้งเครื่องมือทั้งหมดสำหรับ VHDL Simulation Workshop ได้

สร้างไฟล์

```
nano install_ghdl.sh
```

```
#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo " GHDL VHDL DEVELOPMENT ENVIRONMENT"
echo " Ubuntu Installation Script"
echo "========================================"

echo "[1/5] Update package lists"

sudo apt update

echo "[2/5] Enable Universe repository"

sudo apt install -y software-properties-common
sudo add-apt-repository -y universe
sudo apt update

echo "[3/5] Install GHDL and GTKWave"

sudo apt install -y \
    ghdl \
    ghdl-mcode \
    gtkwave

echo "[4/5] Install development tools"

sudo apt install -y \
    git \
    make \
    gcc \
    g++ \
    build-essential \
    python3 \
    python3-pip \
    python3-venv

echo "[5/5] Verify installation"

echo ""
echo "GHDL Version:"
ghdl --version

echo ""
echo "GTKWave Version:"
gtkwave --version

echo ""
echo "GNU Make Version:"
make --version

mkdir -p "$HOME/vhdl_labs"

echo ""
echo "========================================"
echo " INSTALLATION COMPLETED"
echo "========================================"
echo "Workspace: $HOME/vhdl_labs"
```

รัน Script

```
chmod +x install_ghdl.sh

./install_ghdl.sh
```

## **17. แนวทางการนำไปใช้ในหลักสูตร Digital IC Design**

สำหรับการพัฒนาหลักสูตร VHDL, FPGA และ RTL-to-GDSII สามารถจัดลำดับ Lab จากพื้นฐานไปจนถึง ASIC Implementation ได้ดังนี้

| Lab    | หัวข้อ                      | เครื่องมือ             |
| ------ | --------------------------- | ---------------------- |
| Lab 01 | Logic Gates                 | GHDL + GTKWave         |
| Lab 02 | Multiplexer / Decoder       | GHDL                   |
| Lab 03 | Adder / Subtractor          | GHDL                   |
| Lab 04 | Latch / Flip-Flop           | GHDL                   |
| Lab 05 | Counter / Register          | GHDL                   |
| Lab 06 | Moore / Mealy FSM           | GHDL + GTKWave         |
| Lab 07 | Sequence Detector           | GHDL                   |
| Lab 08 | UART Transmitter / Receiver | GHDL                   |
| Lab 09 | FIFO Design                 | GHDL                   |
| Lab 10 | Self-checking Testbench     | GHDL                   |
| Lab 11 | Python-based Verification   | GHDL + cocotb          |
| Lab 12 | VHDL Logic Synthesis        | GHDL + Yosys           |
| Lab 13 | FPGA Implementation         | Vivado + Nexys A7-100T |
| Lab 14 | ASIC RTL-to-GDSII           | LibreLane + IHP SG13G2 |

### **Integrated Open-source ASIC Design Flow**

การเชื่อมต่อ GHDL กับ LibreLane จำเป็นต้องกำหนดขั้นตอน VHDL-to-Verilog หรือใช้ Synthesis Flow ที่รองรับ VHDL อย่างเหมาะสม รวมทั้งตรวจสอบความเข้ากันได้ของ GHDL-Yosys Plugin ก่อนนำไปใช้งานจริง

## **18. Installation Verification Checklist**

**GHDL Lab Readiness**

0 / 12

Ubuntu และ WSL2 ทำงานปกติ

ติดตั้ง GHDL สำเร็จ

ตรวจสอบ GHDL Version และ Backend

ติดตั้ง GTKWave สำเร็จ

Compile VHDL-2008 RTL สำเร็จ

Compile Testbench สำเร็จ

Elaboration สำเร็จ

Simulation ผ่านทุก Test Case

เปิด Waveform ด้วย GTKWave ได้

Bash Script ทำงานได้

Makefile ทำงานได้

VS Code เชื่อมต่อ Ubuntu ได้

อยู่ระหว่างตรวจสอบความพร้อม

Reset

## **19. แหล่งอ้างอิง**

- [GHDL Official Documentation](https://ghdl.github.io/ghdl/?utm_source=chatgpt.com)
- [GHDL GitHub Repository](https://github.com/ghdl/ghdl?utm_source=chatgpt.com)
- [GHDL Releases](https://github.com/ghdl/ghdl/releases?utm_source=chatgpt.com)
- [GTKWave](https://gtkwave.sourceforge.net/?utm_source=chatgpt.com)
- [GHDL-Yosys Plugin](https://github.com/ghdl/ghdl-yosys-plugin?utm_source=chatgpt.com)
- [Microsoft WSL Documentation](https://learn.microsoft.com/en-us/windows/wsl/?utm_source=chatgpt.com)

**สรุป:** สำหรับการจัดอบรม แนะนำให้ใช้ Ubuntu 22.04 หรือ 24.04 LTS ร่วมกับ GHDL mcode, GTKWave, VS Code และ GNU Make เป็นสภาพแวดล้อมมาตรฐาน เนื่องจากติดตั้งง่าย ไม่ต้องจัดการ License และสามารถต่อยอดไปสู่งาน FPGA และ Open-source ASIC Design ได้

คู่มือนี้กำหนดให้ใช้ VHDL-2008 และ mcode Backend เป็นค่าเริ่มต้น โดยตัวอย่างผล Simulation เป็นผลที่คาดหวังจากการวิเคราะห์โค้ด ยังไม่ได้ทดสอบ Execute บน Ubuntu จริงในครั้งนี้ จึงควรดำเนินการตาม Installation Verification Checklist ก่อนนำไปใช้เป็น Lab สำหรับผู้เข้าอบรม
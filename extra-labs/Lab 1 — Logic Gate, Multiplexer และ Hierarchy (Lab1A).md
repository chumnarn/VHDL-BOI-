# Lab 1 — Logic Gate, Multiplexer และ Hierarchy

Oct 28, 2026 · @Chumnarn Punyasai

## ภาพรวม Lab 1 (4 ชั่วโมง)

Lab ประกอบ Module 02 — Learn HDL ใน คู่มือหลักสูตร Learn Digital IC Design from Scratch!

**เป้าหมาย:** เขียนบล็อก combinational 3 ตัวทั้ง VHDL และ Verilog, ต่อเป็น hierarchy, เขียน self-checking testbench และรันทุกอย่างด้วย do-file และ `qrun` ใน **QuestaSim** (simulator ของ Siemens EDA ที่สืบทอดจาก ModelSim — คำสั่งพื้นฐานเหมือนเดิม แต่มี optimizer `vopt`, คำสั่ง `qrun` และฟีเจอร์ verification เพิ่ม)

| ส่วน | งาน | เวลา |
| --- | --- | --- |
| 1.0 | ติดตั้ง QuestaSim + license (ทำล่วงหน้า) และเตรียมโฟลเดอร์ในคาบ | 15 นาที (รวมในเวลา 1A) |
| 1A | Logic gate 7 ชนิด + truth table จาก testbench | 45 นาที |
| 1B | Mux 4:1 แบบ generic + self-checking testbench | 75 นาที |
| 1C | Mux 8:1 สร้างจาก mux4 2 ตัว (hierarchy) | 60 นาที |
| 1D | do-file, regression และตอบคำถาม | 60 นาที |
| 1A+ | (VHDL) Testbench อ่านเวกเตอร์จากไฟล์ + เขียนผลเป็นไฟล์ สำหรับ gates/mux4/mux8, regression และสร้างเวกเตอร์อัตโนมัติ | 60–90 นาที (เสริม) |

**ความรู้ที่ต้องมีก่อนเริ่ม:** ลอจิกเกตพื้นฐานและ multiplexer (Module 01), โครงสร้าง entity/architecture และ module, การประกาศ generic/parameter (Module 02)

**รูปแบบของทุกส่วน:** เป้าหมายย่อย → ขั้นตอนที่มีเลขกำกับ → ผลที่ควรเห็นใน Transcript → bug injection (พิสูจน์ว่า testbench จับบั๊กได้จริง) → ✅ Checkpoint ที่ผู้สอนใช้เดินตรวจได้

## Lab 1.0 — เตรียมสภาพแวดล้อม QuestaSim (ติดตั้งล่วงหน้า + 15 นาทีในคาบ)

**ขั้นที่ 1 — สร้างโครงโฟลเดอร์** (ชื่อโฟลเดอร์และไฟล์ต้องตรงทุกตัวอักษร เพราะ do-file ใน 1D อ้างถึงตามชื่อนี้ และห้ามมีช่องว่างหรือภาษาไทยใน path)

```text
lab01_gates/
├── vhdl/
│   ├── gates.vhd   mux4.vhd   mux8.vhd
│   └── tb_gates.vhd   tb_mux4.vhd   tb_mux8.vhd
├── verilog/
│   ├── gates.v   mux4.v   mux8.v
│   └── tb_gates.sv   tb_mux4.sv   tb_mux8.sv
├── run.do          # 1D
└── regress.sh      # 1D (ทางเลือก)
```

```bash
# Linux / macOS / Git Bash / WSL
mkdir -p lab01_gates/vhdl lab01_gates/verilog
cd lab01_gates
```

บน Windows สร้างด้วย File Explorer ได้เช่นกัน แนะนำ path สั้น ๆ เช่น `C:\labs\lab01_gates` — สร้างไฟล์โค้ดด้วย text editor ที่บันทึกเป็น UTF-8 ได้ (VS Code พร้อม extension VHDL/Verilog ช่วยได้มาก) อย่าใช้ Word/Notepad ที่อาจเติมนามสกุล .txt

**ขั้นที่ 2 — เลือกรุ่น QuestaSim ที่จะใช้**

QuestaSim ใช้ simulation kernel ตระกูลเดียวกับ ModelSim คำสั่ง `vlib` / `vmap` / `vcom` / `vlog` / `vsim`, do-file และหน้าต่าง GUI เกือบทั้งหมดจึงเหมือนเดิม สิ่งที่ต่างและผู้เรียนต้องรู้ตั้งแต่ Lab แรกมี 3 ข้อ: (1) optimizer `vopt` ทำงานทุกครั้ง ต้องสั่งเปิด visibility เองถ้าจะดูสัญญาณใน Wave (2) มีคำสั่ง `qrun` ที่ compile + optimize + simulate ในคำสั่งเดียว (3) ฟีเจอร์ verification ขั้นสูง (SystemVerilog class/randomize, coverage, UVM, Visualizer) เปิดใช้ได้ตาม license ที่มี

| รุ่น | ได้มาอย่างไร | ข้อจำกัดที่เกี่ยวกับหลักสูตร |
| --- | --- | --- |
| Questa-Altera FPGA Starter Edition (เดิมชื่อ Questa-Intel FPGA Starter Edition) | ฟรี ติดตั้งมากับ Quartus Prime Lite/Standard + ขอ license ฟรีที่ผูกกับเครื่อง | พอสำหรับ Lab 1–6 ทั้งหมด; ความเร็วถูกจำกัด และฟีเจอร์ verification ขั้นสูง (class/randomize/covergroup, code coverage, Visualizer) อาจ checkout license ไม่ได้ |
| Questa-Altera FPGA Edition | license แบบเสียเงิน | ความเร็วเต็ม ฟีเจอร์มากกว่า Starter |
| Questa Sim / Questa One Sim (Siemens EDA) | โครงการ academic ของสถาบัน หรือ license server ของบริษัท | ครบทุกฟีเจอร์ รวม coverage, UVM, Visualizer |

ทุกขั้นในคู่มือนี้ทำได้ด้วยรุ่น Starter ยกเว้นส่วนที่ติดป้าย **(ต้องใช้ license เต็ม)** ซึ่งเป็นงานเสริม ไม่หักคะแนนถ้าทำไม่ได้

**ขั้นที่ 3 — ติดตั้งรุ่น Starter (ทำล่วงหน้าก่อนวันเรียน ประมาณ 30–60 นาที)**

1. ดาวน์โหลดชุดติดตั้ง Quartus Prime Lite จากศูนย์ดาวน์โหลด FPGA ของ Altera แล้วเลือก component **Questa-Altera FPGA Starter Edition** (ไม่ต้องติดตั้ง device family ที่ไม่ใช้ เพื่อประหยัดพื้นที่)
2. ติดตั้งลง path ที่ไม่มีช่องว่างและไม่มีภาษาไทย เช่น `C:\altera_lite\25.1std` หรือ `~/altera_lite/25.1std` — ตัวโปรแกรม Questa จะอยู่ใต้โฟลเดอร์ `questa_fse/`
3. ขอ license ฟรีจาก Self-Service Licensing Center (สมัครบัญชีก่อน) → เลือก Questa Starter Edition (no cost) → ใส่ **NIC ID** = MAC address ของการ์ดเครือข่ายที่ติดกับเครื่อง (ดูด้วย `ipconfig /all` บน Windows หรือ `ip link` บน Linux, ใส่แบบไม่มีขีด) → ได้ไฟล์ `.dat` ทางอีเมล
4. เก็บไฟล์ license ไว้ที่ path ถาวร เช่น `C:\licenses\questa_license.dat` หรือ `~/licenses/questa_license.dat` (license ผูกกับ MAC address — เปลี่ยนเครื่องต้องขอใหม่)

ชื่อเมนูและหน้าเว็บอาจเปลี่ยนตามรุ่น — ยึดตามเอกสาร Getting Started ของ Questa รุ่นที่ดาวน์โหลด สถาบันที่มี license Questa เต็มให้ผู้ดูแลระบบแจกค่า license server (รูปแบบ `port@host`) แทนขั้นที่ 3–4

**ขั้นที่ 4 — ตั้งตัวแปร license และ PATH**

```bash
# Linux / WSL — ใส่ท้าย ~/.bashrc แล้วเปิด terminal ใหม่
export PATH=$HOME/altera_lite/25.1std/questa_fse/bin:$PATH
export LM_LICENSE_FILE=$HOME/licenses/questa_license.dat
# ถ้าสถาบันมี license server ของ Questa เต็ม ใช้ port@host แทนไฟล์ เช่น
# export SALT_LICENSE_SERVER=1717@lic.example.ac.th
```

```bat
:: Windows — ตั้งครั้งเดียวใน Command Prompt แล้วเปิดหน้าต่างใหม่
setx LM_LICENSE_FILE "C:\licenses\questa_license.dat"
:: PATH: เพิ่ม C:\altera_lite\25.1std\questa_fse\win64 ผ่าน
::       System Properties → Environment Variables → Path → New (อย่าใช้ setx PATH จะตัด PATH เดิม)
```

Questa อ่าน license ได้จากตัวแปร `SALT_LICENSE_SERVER` (รุ่นใหม่), `MGLS_LICENSE_FILE` และ `LM_LICENSE_FILE` — ให้ตั้งตัวเดียวตามที่เอกสารของรุ่นที่ติดตั้งระบุ ถ้าตั้งหลายตัวแล้วชี้คนละที่ การ checkout license จะช้าหรือล้มเหลวได้ (ตรวจค่าที่ตั้งไว้ด้วย `echo $LM_LICENSE_FILE` หรือ `echo %LM_LICENSE_FILE%`)

**ขั้นที่ 5 — ตรวจว่าติดตั้งและ license ใช้ได้**

```bash
vsim -version                 # ต้องขึ้นชื่อ Questa เช่น "Questa Altera Starter FPGA Edition-64 vsim 20xx.x ..."
which vsim vopt qrun          # Windows: where vsim
vsim -c -do "quit -f"         # เปิด simulator แบบไม่มี GUI แล้วปิด — ถ้า license มีปัญหาจะ error ตรงนี้
```

**ผลที่ควรเห็น:** บรรทัดแรกขึ้นชื่อ Questa (ไม่ใช่ ModelSim) และคำสั่งที่สามจบเงียบ ๆ โดยไม่มีข้อความเรื่อง license — ถ้าขึ้น `command not found` แปลว่า PATH ยังไม่ชี้ไปที่ `questa_fse/bin` (Windows: `questa_fse\win64`); ถ้าขึ้นข้อความทำนอง *Unable to checkout a license* หรือ *Invalid license environment* ให้ดูตารางแก้ปัญหาท้าย Lab; ถ้า `which qrun` ไม่พบ (Questa บางรุ่น) ให้ใช้วิธี A/B ในขั้นที่ 8 แทน — บน Windows เปิด Questa จาก Start menu ได้เช่นกันแล้วพิมพ์ทุกคำสั่งในหน้าต่าง Transcript

**ขั้นที่ 6 — เปิด QuestaSim และย้ายไปที่โฟลเดอร์ Lab**

1. เปิด QuestaSim (คำสั่ง `vsim` หรือจาก Start menu) — หน้าต่างที่ใช้บ่อยคือ Library (ซ้ายบน), Transcript (ล่าง — พิมพ์คำสั่งที่นี่) และหลังเริ่ม simulation จะมี Wave, Objects, sim/Structure (หน้าตาและตำแหน่งเหมือน ModelSim เกือบทุกจุด)
2. เมนู **File → Change Directory...** เลือก `lab01_gates` หรือพิมพ์ใน Transcript:

```tcl
cd C:/labs/lab01_gates      ;# Windows: ใช้ / แทน \ ได้ใน Tcl
pwd                         ;# ต้องแสดง path ของ lab01_gates
ls                          ;# ต้องเห็น vhdl verilog
```

**ขั้นที่ 7 — สร้าง library work**

```tcl
vlib work          ;# สร้างโฟลเดอร์ work/ เก็บผล compile
vmap work work     ;# ผูกชื่อ logical "work" กับโฟลเดอร์ (Questa ยังเขียนลงไฟล์ชื่อ modelsim.ini เหมือนเดิม)
```

**ผลที่ควรเห็น:** ในหน้าต่าง Library มี work (ยังว่าง) — แนวคิดสำคัญ: Questa ไม่ได้ simulate ไฟล์โค้ดตรง ๆ แต่ทำ 3 ขั้น คือ **compile** (`vcom`/`vlog`) แต่ละ design unit (entity/architecture/module) เก็บไว้ใน library → **optimize** (`vopt`) รวม design ทั้งลำดับชั้นเป็นภาพที่จำลองได้เร็ว → **simulate** (`vsim`) — แก้โค้ดแล้วต้อง compile ใหม่ทุกครั้ง

**กฎสำคัญของ Lab นี้:** ไฟล์ VHDL และ Verilog มี design unit ชื่อเดียวกัน (gates, mux4, mux8, tb\_\*) ถ้า compile ทั้งสองภาษาลง work พร้อมกัน ตัวที่ compile ทีหลังจะทับตัวแรก — ในส่วน 1A–1C ให้ทำทีละภาษา และล้าง library ก่อนสลับภาษาด้วย `vdel -lib work -all` แล้ว `vlib work` (do-file ใน 1D ทำให้อัตโนมัติ)

**ขั้นที่ 8 — รู้จัก 3 วิธีรัน simulation ใน Questa** (อ่านให้เข้าใจตอนนี้ ลงมือจริงใน 1A)

| วิธี | คำสั่ง | ใช้เมื่อ |
| --- | --- | --- |
| A. 2 ขั้น (หลักของ Lab นี้) | `vcom`/`vlog` → `vsim -voptargs=+acc=npr work.tb_gates` | งานประจำวันและ do-file — vsim เรียก vopt ให้เองเบื้องหลัง |
| B. 3 ขั้น | `vcom`/`vlog` → `vopt +acc=npr tb_gates -o tb_gates_opt` → `vsim tb_gates_opt` | อยากคุมการ optimize เอง หรือ optimize ครั้งเดียวแล้วรันหลาย test/หลาย seed |
| C. `qrun` | `qrun -2008 vhdl/gates.vhd vhdl/tb_gates.vhd -top tb_gates` | รันจาก shell/regression ในบรรทัดเดียว — เลือก compiler ตามนามสกุล (.vhd → vcom, .v → vlog, .sv → vlog แบบ SystemVerilog) แล้ว vopt + vsim ให้ เก็บผลใน `qrun.out/` แยกจาก `work/` |

**ทำไมต้องมี `+acc=npr`:** Questa optimize ทุกครั้ง (ตัวเลือก `-novopt` ของ ModelSim รุ่นเก่าไม่รองรับแล้ว) optimizer จะตัดหรือรวมสัญญาณภายในจนไม่ปรากฏใน Objects/Wave — `+acc` เปิด visibility กลับมา และ `=npr` เลือกเปิดเฉพาะ **n**ets, **p**orts และ **r**egisters ซึ่งพอสำหรับดู waveform แต่ยังเร็วกว่า `+acc` เปล่า ๆ ที่เปิดทุกอย่าง ส่วนการรัน regression ที่ไม่ดู wave ให้ตัด `+acc` ออกเพื่อความเร็วสูงสุด (ทำใน run.do ของ 1D)

✅ **Checkpoint 1.0:** `vsim -version` ขึ้นชื่อ Questa และ `vsim -c -do "quit -f"` ไม่มี error เรื่อง license, `pwd` ชี้ที่ lab01\_gates, มีโฟลเดอร์ `work/` และไฟล์ `modelsim.ini` เกิดขึ้น และอธิบายได้ว่าวิธี A/B/C ต่างกันอย่างไร

## Lab 1A — Logic Gate 7 ชนิด (45 นาที)

**เป้าหมายย่อย:** เขียนโมดูล combinational ที่ง่ายที่สุด, compile, simulate และให้ testbench ตัดสิน PASS/FAIL เองจาก **truth table อ้างอิง (golden)** ที่เขียนไว้ล่วงหน้า

**ขั้นที่ 1 — เขียน truth table ด้วยมือก่อนเขียนโค้ด** (ตารางนี้คือ "คำตอบที่ถูก" ที่ testbench จะใช้เทียบ)

| a | b | and | or | nand | nor | xor | xnor | not a | เวกเตอร์ 7 บิต (and→not) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | 0 | 0 | 0 | 1 | 1 | 0 | 1 | 1 | `0011011` |
| 0 | 1 | 0 | 1 | 1 | 0 | 1 | 0 | 1 | `0110101` |
| 1 | 0 | 0 | 1 | 1 | 0 | 1 | 0 | 0 | `0110100` |
| 1 | 1 | 1 | 1 | 0 | 0 | 0 | 1 | 0 | `1100010` |

**ขั้นที่ 2 — เขียน RTL** บันทึกเป็น `vhdl/gates.vhd` และ `verilog/gates.v`

```
```

```
library ieee;
use ieee.std_logic_1164.all;

entity gates is
  port (
    a, b : in  std_logic;
    y_and, y_or, y_nand, y_nor, y_xor, y_xnor, y_not : out std_logic
  );
end entity;

architecture rtl of gates is
begin
  -- concurrent signal assignment: ทุกบรรทัดทำงานพร้อมกัน ลำดับไม่มีผล
  y_and  <= a and b;
  y_or   <= a or b;
  y_nand <= a nand b;
  y_nor  <= a nor b;
  y_xor  <= a xor b;
  y_xnor <= a xnor b;
  y_not  <= not a;
end architecture;
```

```verilog
module gates (
  input  wire a, b,
  output wire y_and, y_or, y_nand, y_nor, y_xor, y_xnor, y_not
);
  // continuous assignment — เทียบเท่า concurrent assignment ของ VHDL
  assign y_and  = a & b;
  assign y_or   = a | b;
  assign y_nand = ~(a & b);
  assign y_nor  = ~(a | b);
  assign y_xor  = a ^ b;
  assign y_xnor = ~(a ^ b);
  assign y_not  = ~a;
endmodule
```

**ขั้นที่ 3 — Compile RTL และอ่าน Transcript**

```tcl
vcom -2008 vhdl/gates.vhd
```

```text
# -- Loading package STANDARD
# -- Loading package std_logic_1164
# -- Compiling entity gates
# -- Compiling architecture rtl of gates
# Errors: 0, Warnings: 0
```

ในหน้าต่าง Library กด + หน้า work จะเห็น gates (entity) และ rtl (architecture) — ถ้ามี error ให้ **ดับเบิลคลิกที่บรรทัด error สีแดง** Questa จะเปิดไฟล์ไปที่บรรทัดนั้น **แก้ทีละ error จากตัวแรกเสมอ** (error ตัวหลังมักเป็นผลต่อเนื่อง) — ข้อความของ Questa มีรหัสในวงเล็บ เช่น `** Error: (vcom-1136)` พิมพ์ `verror 1136` ใน Transcript เพื่ออ่านคำอธิบายเต็มของรหัสนั้นได้

สาย Verilog (หลังล้าง library ตามกฎใน 1.0):

```tcl
vlog verilog/gates.v
# -- Compiling module gates
# Top level modules:
#     gates
```

**ขั้นที่ 4 — เขียน testbench** — หลักการ: (1) ไม่มี port (2) สร้าง DUT (3) ป้อนอินพุตทุกค่า (4) รอให้สัญญาณนิ่ง (5) เทียบกับ golden table (6) สรุป PASS/FAIL (7) หยุด simulation

ทำไมใช้ golden table แทนการคำนวณ `a & b` ซ้ำใน testbench: ถ้าเขียนสูตรเดียวกับ DUT แล้วเข้าใจผิดเหมือนกัน ผลจะ "ผ่าน" ทั้งที่ผิด — reference ควรมาจากแหล่งที่เป็นอิสระจาก RTL

`vhdl/tb_gates.vhd`:

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_gates is                       -- (1) testbench ไม่มี port
end entity;

architecture sim of tb_gates is
  signal a, b : std_logic := '0';
  signal y_and, y_or, y_nand, y_nor, y_xor, y_xnor, y_not : std_logic;
  signal y_vec : std_logic_vector(6 downto 0);

  -- (5) golden truth table: ลำดับบิต and,or,nand,nor,xor,xnor,not
  type exp_t is array (0 to 3) of std_logic_vector(6 downto 0);
  constant EXP : exp_t := ("0011011", "0110101", "0110100", "1100010");
begin
  dut : entity work.gates                -- (2) entity instantiation แบบ named mapping
    port map (a => a, b => b, y_and => y_and, y_or => y_or, y_nand => y_nand,
              y_nor => y_nor, y_xor => y_xor, y_xnor => y_xnor, y_not => y_not);

  y_vec <= y_and & y_or & y_nand & y_nor & y_xor & y_xnor & y_not;

  stim : process
    variable v   : unsigned(1 downto 0);
    variable err : natural := 0;
  begin
    report " a b | and or nand nor xor xnor not";
    for i in 0 to 3 loop                 -- (3) ทุก combination
      v := to_unsigned(i, 2);
      a <= v(1);  b <= v(0);
      wait for 10 ns;                    -- (4) รอให้สัญญาณอัปเดต
      report " " & to_string(a) & " " & to_string(b) & " |  " &
             to_string(y_and) & "   " & to_string(y_or) & "   " & to_string(y_nand) & "    " &
             to_string(y_nor) & "   " & to_string(y_xor) & "   " & to_string(y_xnor) & "    " &
             to_string(y_not);
      if y_vec /= EXP(i) then
        err := err + 1;
        report "FAIL a=" & to_string(a) & " b=" & to_string(b) &
               " got " & to_string(y_vec) & " exp " & to_string(EXP(i)) severity error;
      end if;
    end loop;
    if err = 0 then                      -- (6) สรุป
      report "*** PASS ***";
    else
      report "*** FAIL: " & integer'image(err) & " ***" severity error;
    end if;
    std.env.stop;                        -- (7) หยุด simulation (VHDL-2008)
    wait;
  end process;
end architecture;
```

`verilog/tb_gates.sv`:

```verilog
`timescale 1ns/1ps
module tb_gates;
  reg  a, b;
  wire y_and, y_or, y_nand, y_nor, y_xor, y_xnor, y_not;
  wire [6:0] y_vec = {y_and, y_or, y_nand, y_nor, y_xor, y_xnor, y_not};
  reg  [6:0] exp_tbl [0:3];                 // golden truth table
  integer i, err;

  gates dut (.a(a), .b(b), .y_and(y_and), .y_or(y_or), .y_nand(y_nand),
             .y_nor(y_nor), .y_xor(y_xor), .y_xnor(y_xnor), .y_not(y_not));

  initial begin
    exp_tbl[0] = 7'b0011011;  exp_tbl[1] = 7'b0110101;
    exp_tbl[2] = 7'b0110100;  exp_tbl[3] = 7'b1100010;
    err = 0;
    $display(" a b | and or nand nor xor xnor not");
    for (i = 0; i < 4; i = i + 1) begin
      {a, b} = i[1:0];
      #10;
      $display(" %b %b |  %b   %b   %b    %b   %b   %b    %b",
               a, b, y_and, y_or, y_nand, y_nor, y_xor, y_xnor, y_not);
      if (y_vec !== exp_tbl[i]) begin                 // !== ตรวจ X/Z ด้วย
        err = err + 1;
        $display("FAIL a=%b b=%b got %b exp %b", a, b, y_vec, exp_tbl[i]);
      end
    end
    if (err == 0) $display("*** PASS ***");
    else          $display("*** FAIL: %0d ***", err);
    $stop;     // ใช้ $stop แทน $finish: ใน GUI $finish จะถามว่าจะปิด Questa ไหม
  end
endmodule
```

**ขั้นที่ 5 — Compile testbench และ simulate (สาย VHDL เป็นตัวอย่าง)**

```tcl
vcom -2008 vhdl/tb_gates.vhd
vsim -voptargs=+acc=npr work.tb_gates   ;# วิธี A: vsim เรียก vopt ให้; +acc=npr เก็บ net/port/register ไว้ดูใน Wave
add wave /tb_gates/*
run -all
```

ใน Transcript หลังคำสั่ง vsim จะเห็นข้อความทำนอง `** Note: (vsim-3812) Design is being optimized...` ตามด้วยผลของ vopt — ยืนยันว่ามีการ optimize เกิดขึ้นเบื้องหลัง (ถ้อยคำอาจต่างตามรุ่น)

**ขั้นที่ 5.1 — ทำซ้ำด้วยวิธี B และ C ให้ได้ผลเดียวกัน** (ทำครั้งเดียวใน 1A — Lab ถัดไปใช้วิธี A เป็นหลัก)

```tcl
# วิธี B — พิมพ์ใน Transcript
quit -sim
vopt +acc=npr tb_gates -o tb_gates_opt   ;# สร้าง design ที่ optimize แล้วชื่อ tb_gates_opt ใน work
vsim tb_gates_opt
add wave /tb_gates/*
run -all
```

```bash
# วิธี C — พิมพ์ใน shell ที่โฟลเดอร์ lab01_gates (qrun สร้าง library เองใน qrun.out/)
qrun -2008 vhdl/gates.vhd vhdl/tb_gates.vhd -top tb_gates -do "run -all; quit -f"

# แบบเปิด GUI พร้อม waveform
qrun -2008 vhdl/gates.vhd vhdl/tb_gates.vhd -top tb_gates -gui \
     -voptargs=+acc=npr -do "add wave /tb_gates/*; run -all"

# สาย Verilog (.sv ถูก compile แบบ SystemVerilog อัตโนมัติ)
qrun verilog/gates.v verilog/tb_gates.sv -top tb_gates -do "run -all; quit -f"

qrun -clean        # ลบ qrun.out/ เมื่อสลับภาษา (เหตุผลเดียวกับ vdel ในกฎของ 1.0)
```

ทั้งสามวิธีต้องได้ `*** PASS ***` เหมือนกัน — สิ่งที่ต้องเข้าใจคือ qrun ไม่ใช่ simulator ตัวใหม่ แต่เป็นตัวครอบที่เรียก vcom/vlog → vopt → vsim ตามลำดับ (ดูได้จากบรรทัดแรก ๆ ที่ qrun พิมพ์ออกมา) และอย่าใช้ qrun ปนกับ `work/` ที่สร้างด้วยมือในคำสั่งเดียวกัน

หรือทำผ่าน GUI: Library → ดับเบิลคลิก `tb_gates` → ในหน้าต่าง Objects เลือกสัญญาณทั้งหมด → คลิกขวา Add Wave → ปุ่ม **Run -All** (ไอคอนลูกศรแบบมีเส้นตั้ง)

**ขั้นที่ 6 — อ่านผล** — Transcript ต้องแสดง (สาย VHDL จะมี `** Note:` และเวลานำหน้า):

```text
 a b | and or nand nor xor xnor not
 0 0 |  0   0   1    1   0   1    1
 0 1 |  0   1   1    0   1   0    1
 1 0 |  0   1   1    0   1   0    0
 1 1 |  1   1   0    0   0   1    0
*** PASS ***
```

ใน Wave ให้กด **Zoom Full** (หรือพิมพ์ `wave zoom full`) แล้ววาง cursor ที่ 5, 15, 25, 35 ns อ่านค่าเทียบกับตารางในขั้นที่ 1 — สังเกตว่าเอาต์พุตเปลี่ยนทันทีที่อินพุตเปลี่ยน (delay 0) เพราะเป็น RTL ไม่มี gate delay จริง

**ขั้นที่ 7 — พิสูจน์ว่า testbench จับบั๊กได้จริง (bug injection)**

1. แก้ `gates` ให้ `y_xnor` ผิดโดยตั้งใจ — VHDL: `y_xnor <= a xor b;` / Verilog: `assign y_xnor = a ^ b;`
2. compile ใหม่และรีสตาร์ท simulation โดยไม่ต้องปิด GUI:

```tcl
vcom -2008 vhdl/gates.vhd     ;# หรือ vlog verilog/gates.v
restart -f                    ;# โหลด design ใหม่ เก็บรายการ wave ไว้
run -all
```

3. ผลที่ต้องเห็น: FAIL ทั้ง 4 แถว (เพราะ xor กับ xnor ต่างกันทุก combination) และ `*** FAIL: 4 ***`
4. แก้กลับให้ถูกแล้วรันซ้ำจน PASS

ทำซ้ำขั้นที่ 5–7 ด้วยสาย Verilog (`vdel -lib work -all; vlib work; vlog verilog/gates.v; vlog -sv verilog/tb_gates.sv; vsim -voptargs=+acc=npr work.tb_gates`)

✅ **Checkpoint 1A:** PASS ทั้งสองภาษา + เห็น FAIL 4 แถวตอนฉีดบั๊ก + บันทึก screenshot waveform

## Lab 1B — Mux 4:1 แบบ Generic (75 นาที)

**เป้าหมายย่อย:** เขียนบล็อกที่ความกว้างบิตปรับได้ (generic/parameter), เขียน testbench ที่ปรับตามได้เอง, อ่าน waveform แบบ bus และทดลองพฤติกรรมเมื่ออินพุตเป็น X

**ขั้นที่ 1 — กำหนด spec**

| sel | y |
| --- | --- |
| 00 | d0 |
| 01 | d1 |
| 10 | d2 |
| 11 | d3 |

ทุก data port กว้าง N บิต (default 8) — เป็น combinational ล้วน ไม่มี clock

**ขั้นที่ 2 — เขียน RTL** (`vhdl/mux4.vhd`, `verilog/mux4.v`)

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity mux4 is
  generic (N : positive := 8);                     -- ความกว้างข้อมูล
  port (
    d0, d1, d2, d3 : in  std_logic_vector(N-1 downto 0);
    sel            : in  std_logic_vector(1 downto 0);
    y              : out std_logic_vector(N-1 downto 0)
  );
end entity;

architecture rtl of mux4 is
begin
  -- selected signal assignment: อ่านง่ายและครอบคลุมทุกค่าด้วย others
  with sel select
    y <= d0 when "00",
         d1 when "01",
         d2 when "10",
         d3 when others;                         -- รวม "11" และค่า X/U/Z
end architecture;
```

```verilog
module mux4 #(parameter N = 8) (
  input  wire [N-1:0] d0, d1, d2, d3,
  input  wire [1:0]   sel,
  output reg  [N-1:0] y            // reg เพราะกำหนดค่าใน always (ไม่ได้แปลว่าเป็น flip-flop)
);
  always @(*) begin                // @(*) = sensitivity ครบทุกอินพุตอัตโนมัติ
    case (sel)
      2'b00:   y = d0;             // combinational ใช้ blocking (=)
      2'b01:   y = d1;
      2'b10:   y = d2;
      default: y = d3;             // มี default → ไม่เกิด latch
    endcase
  end
endmodule
```

**ขั้นที่ 3 — Compile และตรวจ warning** — `vcom -2008 vhdl/mux4.vhd` หรือ `vlog verilog/mux4.v` ต้องได้ `Errors: 0, Warnings: 0` ถ้ามี warning เรื่องความกว้างบิตไม่ตรงกัน ห้ามข้าม — แก้ก่อนไปต่อ

**ขั้นที่ 4 — เขียน testbench ที่มี generic ของตัวเอง** — ให้ N เป็น generic ของ testbench (top) ด้วย จะได้เปลี่ยนความกว้างตอน `vsim` ได้โดยไม่แก้ไฟล์ (ขั้นที่ 7) ข้อมูลทดสอบ 4 ช่องต้อง**ต่างกันทุกค่า** ไม่เช่นนั้นถ้า mux เลือกผิดช่อง testbench จะมองไม่เห็น

`vhdl/tb_mux4.vhd`:

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mux4 is
  generic (N : positive := 8);                       -- เปลี่ยนได้ด้วย vsim -gN=16 (N ≥ 8)
end entity;

architecture sim of tb_mux4 is
  type arr_t is array (0 to 3) of std_logic_vector(N-1 downto 0);

  -- สร้างข้อมูล 0x11, 0x22, 0x33, 0x44 ตามความกว้าง N
  function make_data return arr_t is
    variable r : arr_t;
  begin
    for i in 0 to 3 loop
      r(i) := std_logic_vector(to_unsigned(17 * (i + 1), N));
    end loop;
    return r;
  end function;

  constant D : arr_t := make_data;
  signal d0, d1, d2, d3, y : std_logic_vector(N-1 downto 0);
  signal sel : std_logic_vector(1 downto 0) := "00";
begin
  d0 <= D(0);  d1 <= D(1);  d2 <= D(2);  d3 <= D(3);

  dut : entity work.mux4
    generic map (N => N)
    port map (d0 => d0, d1 => d1, d2 => d2, d3 => d3, sel => sel, y => y);

  stim : process
    variable err : natural := 0;
  begin
    for i in 0 to 3 loop
      sel <= std_logic_vector(to_unsigned(i, 2));
      wait for 10 ns;
      report "sel=" & integer'image(i) & " y=" & to_hstring(y) & " exp=" & to_hstring(D(i));
      if y /= D(i) then
        err := err + 1;
        report "FAIL at sel=" & integer'image(i) severity error;
      end if;
    end loop;

    sel <= "XX";                                       -- กรณีพิเศษสำหรับขั้นที่ 8
    wait for 10 ns;
    report "sel=XX y=" & to_hstring(y);

    if err = 0 then report "*** PASS ***";
    else report "*** FAIL: " & integer'image(err) & " ***" severity error;
    end if;
    std.env.stop;
    wait;
  end process;
end architecture;
```

`verilog/tb_mux4.sv`:

```verilog
`timescale 1ns/1ps
module tb_mux4 #(parameter N = 8);                  // เปลี่ยนได้ด้วย vsim -gN=16
  reg  [N-1:0] d0, d1, d2, d3;
  reg  [1:0]   sel;
  wire [N-1:0] y;
  reg  [N-1:0] exp_y;
  integer i, err;

  mux4 #(.N(N)) dut (.d0(d0), .d1(d1), .d2(d2), .d3(d3), .sel(sel), .y(y));

  initial begin
    d0 = 'h11;  d1 = 'h22;  d2 = 'h33;  d3 = 'h44;   // ต่างกันทุกช่อง
    err = 0;
    for (i = 0; i < 4; i = i + 1) begin
      sel = i;
      #10;
      case (i)
        0: exp_y = d0;   1: exp_y = d1;   2: exp_y = d2;   default: exp_y = d3;
      endcase
      $display("sel=%0d y=%h exp=%h", sel, y, exp_y);
      if (y !== exp_y) begin
        err = err + 1;
        $display("FAIL at sel=%0d", i);
      end
    end

    sel = 2'bxx;                                      // กรณีพิเศษสำหรับขั้นที่ 8
    #10;
    $display("sel=xx y=%h", y);

    if (err == 0) $display("*** PASS ***");
    else          $display("*** FAIL: %0d ***", err);
    $stop;
  end
endmodule
```

**ขั้นที่ 5 — Simulate และจัด waveform ให้อ่านง่าย**

```tcl
vcom -2008 vhdl/mux4.vhd vhdl/tb_mux4.vhd      ;# หรือ vlog verilog/mux4.v; vlog -sv verilog/tb_mux4.sv
vsim -voptargs=+acc=npr work.tb_mux4
add wave -divider "Inputs"
add wave -radix hex      /tb_mux4/d0 /tb_mux4/d1 /tb_mux4/d2 /tb_mux4/d3
add wave -radix unsigned /tb_mux4/sel
add wave -divider "Output"
add wave -radix hex      /tb_mux4/y
run -all
wave zoom full
```

ผลใน Transcript:

```text
sel=0 y=11 exp=11
sel=1 y=22 exp=22
sel=2 y=33 exp=33
sel=3 y=44 exp=44
sel=xx y=44
*** PASS ***
```

**ขั้นที่ 6 — ฝึกใช้ Wave window** (ทักษะที่จะใช้ตลอดหลักสูตร)

1. คลิกขวาที่ชื่อสัญญาณ `y` → **Radix** → ลองสลับ Binary / Hexadecimal / Unsigned ดูความต่าง
2. กด `+` หน้า `y` เพื่อกาง bus เป็นรายบิต
3. คลิกใน waveform เพื่อวาง cursor, เมนู **Add → Cursor** เพิ่มตัวที่สอง แล้วอ่านระยะห่างเวลาใต้แกน (ต้องได้ 10 ns ต่อหนึ่งค่า sel)
4. เลือก `sel` แล้วกดปุ่ม **Find Next Transition** กระโดดไปที่จุดเปลี่ยนค่าถัดไป
5. บันทึกการจัดหน้า wave: **File → Save Format...** เป็น `wave_mux4.do` ครั้งต่อไปใช้ `do wave_mux4.do` แทนการ add wave ทีละตัว

**ขั้นที่ 7 — เปลี่ยนความกว้างโดยไม่แก้ไฟล์**

```tcl
quit -sim
vsim -voptargs=+acc=npr -gN=16 work.tb_mux4   ;# วิธี A: vsim ส่ง -gN=16 ต่อให้ vopt เอง
add wave -radix hex /tb_mux4/*
run -all

# วิธี B: generic ถูกฝังตอน optimize จึงต้องใส่ -g ที่ vopt ไม่ใช่ vsim
# vopt +acc=npr -gN=16 tb_mux4 -o tb_mux4_n16;  vsim tb_mux4_n16
# วิธี C: qrun -2008 vhdl/mux4.vhd vhdl/tb_mux4.vhd -top tb_mux4 -gN=16 -do "run -all; quit -f"
```

ผลที่ต้องเห็น: `y=0011`, `0022`, `0033`, `0044` (16 บิต) และยัง PASS — `-g` กำหนด generic/parameter ของ top ที่ไม่ได้ถูกกำหนดค่าไว้ใน generic map ส่วน `-G` บังคับทับแม้จะถูก map ไว้แล้ว — นี่คือเหตุผลที่ testbench ควรส่งต่อ N เข้า DUT แทนการเขียนเลข 8 คงที่

**ขั้นที่ 8 — ทดลองเมื่อ sel เป็น X** — ดูบรรทัด `sel=xx` ใน Transcript และช่วง 40–50 ns ใน waveform: ทั้งสองภาษาให้ `y = 44` (ไม่ใช่ X) บันทึกผลไว้ตอบคำถามท้าย Lab ข้อ 1

**ขั้นที่ 9 — Bug injection** — สลับ `d1` กับ `d2` ใน RTL (VHDL: `d2 when "01"`, `d1 when "10"`) compile แล้ว `restart -f; run -all` ต้องเห็น FAIL ที่ sel=1 และ sel=2 จากนั้นแก้กลับ

✅ **Checkpoint 1B:** PASS ทั้งสองภาษาที่ N = 8 และ N = 16, มีไฟล์ `wave_mux4.do`, บันทึกผล sel = X

## Lab 1C — Mux 8:1 แบบ Hierarchy (60 นาที)

**เป้าหมายย่อย:** นำ mux4 ที่ผ่านการทดสอบแล้วมาต่อเป็นบล็อกที่ใหญ่ขึ้น (structural design), ใช้ slice ของ vector และดูลำดับชั้น instance ใน QuestaSim

**ขั้นที่ 1 — วาดโครงสร้างก่อนเขียนโค้ด** (ให้ผู้เรียนวาดลงกระดาษและแนบในรายงาน)

```text
                 sel[1:0]
                    │
  d0..d3 ─────►┌────┴────┐ y_lo
 (d[4N-1:0])   │  u_lo   ├───────┐
               │  mux4   │       │   ┌────────┐
               └─────────┘       └──►│ 0      │
                                     │  mux2  ├──► y
  d4..d7 ─────►┌─────────┐ y_hi  ┌──►│ 1      │
 (d[8N-1:4N])  │  u_hi   ├───────┘   └────┬───┘
               │  mux4   │                │
               └────┬────┘               sel[2]
                    │
                 sel[1:0]
```

การจัดวางข้อมูลใน vector `d` (กว้าง 8×N): ช่อง k อยู่ที่บิต `(k+1)·N−1` ลงมาถึง `k·N` — ตัวอย่าง N = 8: d0 = `d[7:0]`, d1 = `d[15:8]`, …, d7 = `d[63:56]`

**ขั้นที่ 2 — เขียน RTL** (`vhdl/mux8.vhd`, `verilog/mux8.v`)

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity mux8 is
  generic (N : positive := 8);
  port (
    d   : in  std_logic_vector(8*N-1 downto 0);   -- d0 อยู่บิตล่างสุด
    sel : in  std_logic_vector(2 downto 0);
    y   : out std_logic_vector(N-1 downto 0)
  );
end entity;

architecture struct of mux8 is
  signal y_lo, y_hi : std_logic_vector(N-1 downto 0);
begin
  u_lo : entity work.mux4 generic map (N => N)
    port map (d0 => d(  N-1 downto 0),   d1 => d(2*N-1 downto N),
              d2 => d(3*N-1 downto 2*N), d3 => d(4*N-1 downto 3*N),
              sel => sel(1 downto 0), y => y_lo);

  u_hi : entity work.mux4 generic map (N => N)
    port map (d0 => d(5*N-1 downto 4*N), d1 => d(6*N-1 downto 5*N),
              d2 => d(7*N-1 downto 6*N), d3 => d(8*N-1 downto 7*N),
              sel => sel(1 downto 0), y => y_hi);

  y <= y_hi when sel(2) = '1' else y_lo;            -- mux 2:1 ชั้นสุดท้าย
end architecture;
```

```verilog
module mux8 #(parameter N = 8) (
  input  wire [8*N-1:0] d,              // d0 อยู่บิตล่างสุด
  input  wire [2:0]     sel,
  output wire [N-1:0]   y
);
  wire [N-1:0] y_lo, y_hi;

  // d[k*N +: N] = เริ่มที่บิต k*N นับขึ้นไป N บิต (indexed part-select)
  mux4 #(.N(N)) u_lo (.d0(d[0*N +: N]), .d1(d[1*N +: N]), .d2(d[2*N +: N]),
                      .d3(d[3*N +: N]), .sel(sel[1:0]), .y(y_lo));
  mux4 #(.N(N)) u_hi (.d0(d[4*N +: N]), .d1(d[5*N +: N]), .d2(d[6*N +: N]),
                      .d3(d[7*N +: N]), .sel(sel[1:0]), .y(y_hi));

  assign y = sel[2] ? y_hi : y_lo;
endmodule
```

จุดที่ผู้เรียนมักพลาด: ใน VHDL ต้อง compile `mux4.vhd` **ก่อน** `mux8.vhd` เพราะ `entity work.mux4` ต้องมีอยู่ใน library แล้ว (ส่วน Verilog ลำดับไม่สำคัญ เพราะ link ตอน `vsim`)

**ขั้นที่ 3 — เขียน testbench** — ตั้งค่า 8 ช่องให้ต่างกันและอ่านง่าย (0x10, 0x21, 0x32, …, 0x87 — หลักสิบหกบอกหมายเลขช่อง+1 หลักหน่วยบอกหมายเลขช่อง) แล้ววน sel 0–7

`vhdl/tb_mux8.vhd`:

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mux8 is
  generic (N : positive := 8);
end entity;

architecture sim of tb_mux8 is
  signal d   : std_logic_vector(8*N-1 downto 0);
  signal sel : std_logic_vector(2 downto 0) := "000";
  signal y   : std_logic_vector(N-1 downto 0);
begin
  dut : entity work.mux8
    generic map (N => N)
    port map (d => d, sel => sel, y => y);

  stim : process
    variable err   : natural := 0;
    variable exp_y : std_logic_vector(N-1 downto 0);
  begin
    for k in 0 to 7 loop                                   -- ช่อง k = 0x10*(k+1) + k
      d((k+1)*N-1 downto k*N) <= std_logic_vector(to_unsigned(16*(k+1) + k, N));
    end loop;

    for i in 0 to 7 loop
      sel <= std_logic_vector(to_unsigned(i, 3));
      wait for 10 ns;
      exp_y := d((i+1)*N-1 downto i*N);
      report "sel=" & integer'image(i) & " y=" & to_hstring(y) & " exp=" & to_hstring(exp_y);
      if y /= exp_y then
        err := err + 1;
        report "FAIL at sel=" & integer'image(i) severity error;
      end if;
    end loop;

    if err = 0 then report "*** PASS ***";
    else report "*** FAIL: " & integer'image(err) & " ***" severity error;
    end if;
    std.env.stop;
    wait;
  end process;
end architecture;
```

`verilog/tb_mux8.sv`:

```verilog
`timescale 1ns/1ps
module tb_mux8 #(parameter N = 8);
  reg  [8*N-1:0] d;
  reg  [2:0]     sel;
  wire [N-1:0]   y;
  integer i, k, err;

  mux8 #(.N(N)) dut (.d(d), .sel(sel), .y(y));

  initial begin
    for (k = 0; k < 8; k = k + 1)
      d[k*N +: N] = 16*(k+1) + k;                     // 0x10, 0x21, ..., 0x87
    err = 0;
    for (i = 0; i < 8; i = i + 1) begin
      sel = i;
      #10;
      $display("sel=%0d y=%h exp=%h", sel, y, d[i*N +: N]);
      if (y !== d[i*N +: N]) begin
        err = err + 1;
        $display("FAIL at sel=%0d", i);
      end
    end
    if (err == 0) $display("*** PASS ***");
    else          $display("*** FAIL: %0d ***", err);
    $stop;
  end
endmodule
```

**ขั้นที่ 4 — Compile ตามลำดับและ simulate**

```tcl
# VHDL: ลำดับสำคัญ — บล็อกย่อยก่อน บล็อกแม่ แล้ว testbench
vcom -2008 vhdl/mux4.vhd vhdl/mux8.vhd vhdl/tb_mux8.vhd
# Verilog: vlog verilog/mux4.v verilog/mux8.v; vlog -sv verilog/tb_mux8.sv

vsim -voptargs=+acc=npr work.tb_mux8
add wave -radix unsigned /tb_mux8/sel
add wave -radix hex      /tb_mux8/y
add wave -radix hex      /tb_mux8/dut/y_lo /tb_mux8/dut/y_hi    ;# สัญญาณภายใน DUT (ต้องมี +acc ไม่เช่นนั้นอาจถูก optimize หาย)
run -all
wave zoom full
```

ผลที่คาดหวัง:

```text
sel=0 y=10 exp=10
sel=1 y=21 exp=21
sel=2 y=32 exp=32
sel=3 y=43 exp=43
sel=4 y=54 exp=54
sel=5 y=65 exp=65
sel=6 y=76 exp=76
sel=7 y=87 exp=87
*** PASS ***
```

**ขั้นที่ 5 — สำรวจ hierarchy ใน QuestaSim**

1. เปิดแท็บ **sim** (หน้าต่าง Structure) — ต้องเห็น `tb_mux8 → dut (mux8) → u_lo (mux4), u_hi (mux4)`
2. คลิก `u_hi` → หน้าต่าง Objects จะแสดง port ของ instance นั้น — ลาก `d0..d3` ของ `u_hi` ไปใส่ Wave แล้วตรวจว่าเป็น 54, 65, 76, 87
3. คลิกขวาที่ `dut` → **View Declaration** เพื่อเปิดซอร์สโค้ด — ใช้ได้เมื่อดีไซน์มีหลายชั้นและหาไฟล์ไม่เจอ
4. เปิด Dataflow (Tools/View → Dataflow) หรือ Schematic ใน Questa รุ่นใหม่ แล้วลาก y เข้าไป ดับเบิลคลิกเพื่อไล่ย้อนหาต้นทางของสัญญาณ (driver tracing) — ทักษะ debug ที่จะใช้บ่อยใน Module 03–04 (คำสั่งทางเลือกใน Transcript: `drivers /tb_mux8/y`)
5. รันซ้ำที่ N = 16: `quit -sim; vsim -voptargs=+acc=npr -gN=16 work.tb_mux8; run -all` → PASS

**ขั้นที่ 6 — Bug injection** — ใน mux8 สลับ `y_hi` กับ `y_lo` (VHDL: `y <= y_lo when sel(2) = '1' else y_hi;`) → ต้อง FAIL 8 จุด จากนั้นให้อธิบายว่าดูจาก waveform อย่างเดียวจะรู้ได้อย่างไรว่าผิดที่ชั้นไหน (คำใบ้: ดู `y_lo`, `y_hi` ที่ยังถูกต้อง)

✅ **Checkpoint 1C:** PASS ทั้งสองภาษา, screenshot หน้าต่าง Structure ที่เห็น `u_lo`/`u_hi`, screenshot waveform ที่มี `y_lo`, `y_hi`, `y` แบบ radix hex

## Lab 1D — Do-file และ Regression (60 นาที รวมตอบคำถาม)

**เป้าหมายย่อย:** เปลี่ยนทุกคำสั่งที่พิมพ์มือใน 1A–1C ให้เป็นสคริปต์ที่รันซ้ำได้ด้วยคำสั่งเดียว ทั้งแบบ GUI (ดู waveform), แบบ batch (ไม่เปิดหน้าต่าง ใช้ตรวจทุก testbench รวดเดียว) และแบบ `qrun` — นี่คือพื้นฐานของ regression ที่จะใช้ตลอดหลักสูตร

**ขั้นที่ 1 — เขียน `run.do`** วางที่ root ของ `lab01_gates/`

```tcl
# run.do — compile + simulate หนึ่ง testbench (QuestaSim)
#   GUI   : set LANG verilog; set TOP tb_mux8; do run.do
#   Batch : vsim -c -do "set LANG vhdl; set TOP tb_gates; set BATCH 1; do run.do; quit -f"

# (1) ค่า default ของตัวแปร — ถ้าผู้ใช้ตั้งไว้ก่อนแล้วจะไม่ถูกทับ
if {![info exists LANG]}  { set LANG  vhdl }
if {![info exists TOP]}   { set TOP   tb_mux4 }
if {![info exists BATCH]} { set BATCH 0 }
if {[info exists N]} { set GOPT "-gN=$N" } else { set GOPT "" }
# GUI ต้องเห็นสัญญาณใน Wave → +acc=npr ; batch ไม่ดู wave → ปล่อยให้ vopt optimize เต็มที่ (เร็วกว่า)
if {$BATCH} { set ACC "" } else { set ACC "-voptargs=+acc=npr" }

# batch: ถ้ามี error (เช่น compile พัง) ให้ปิด vsim ทันที ไม่ค้างรอคำสั่งที่ prompt
if {$BATCH} { onerror {quit -f -code 1} }

# (2) ปิด simulation เดิม (GUI) แล้วล้าง library — กันชื่อซ้ำระหว่าง VHDL/Verilog
if {!$BATCH} { catch {quit -sim} }
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

# (3) compile: บล็อกย่อย → บล็อกแม่ → testbench
if {$LANG eq "vhdl"} {
  vcom -2008 -quiet vhdl/gates.vhd vhdl/mux4.vhd vhdl/mux8.vhd
  vcom -2008 -quiet vhdl/tb_gates.vhd vhdl/tb_mux4.vhd vhdl/tb_mux8.vhd
} elseif {$LANG eq "verilog"} {
  vlog -quiet verilog/gates.v verilog/mux4.v verilog/mux8.v
  vlog -sv -quiet verilog/tb_gates.sv verilog/tb_mux4.sv verilog/tb_mux8.sv
} else {
  echo "LANG must be vhdl or verilog"
  abort
}

# (4) โหลด design — vsim เรียก vopt ให้อัตโนมัติ (eval เพราะ ACC/GOPT อาจว่าง)
eval vsim $ACC $GOPT work.$TOP

# (5) waveform เฉพาะโหมด GUI
if {!$BATCH} {
  add wave -radix hex /$TOP/*
}

# (6) รันจน testbench สั่งหยุด ($stop / std.env.stop)
run -all
if {!$BATCH} { wave zoom full }
```

**ขั้นที่ 2 — ทำความเข้าใจทีละส่วน**

| ส่วน | ทำอะไร | ทำไมต้องมี |
| --- | --- | --- |
| (1) `info exists` | ตั้งค่าเริ่มต้นเฉพาะตัวแปรที่ยังไม่มี | สคริปต์เดียวใช้ได้ทุกภาษา/ทุก testbench โดยส่งค่าเข้ามา |
| `onerror` (batch) | ออกจาก vsim ทันทีเมื่อมี error | ไม่ให้ regression ค้างรอคำสั่งตอน compile พัง |
| (2) `vdel` + `vlib` | ล้างและสร้าง library ใหม่ทุกครั้ง | ผลไม่ปนกับการ compile ครั้งก่อน (clean build) |
| (3) `-quiet` | ตัดข้อความ Loading/Compiling | อ่าน warning/error ง่ายขึ้น — ถ้า compile error สคริปต์จะหยุดทันที |
| (4) eval vsim $ACC $GOPT | ใส่ `-voptargs=+acc=npr` เฉพาะโหมด GUI และ `-gN=...` เมื่อผู้ใช้ตั้ง N | debug ใน GUI เห็นสัญญาณครบ แต่ batch เร็วที่สุด; ทดสอบหลายความกว้างโดยไม่แก้ไฟล์ (tb\_gates ไม่มี N จะได้ warning เท่านั้น) |
| (5) `add wave` เฉพาะ GUI | batch ไม่ต้องเก็บ waveform | รันเร็วกว่าและไม่เปลืองพื้นที่ |
| (6) `run -all` | รันจนไม่มี event หรือถูกสั่งหยุด | testbench ต้องหยุดตัวเอง ไม่เช่นนั้นถ้ามี clock จะรันไม่จบ |

**ขั้นที่ 3 — ใช้งานแบบ GUI** (พิมพ์ใน Transcript ทีละบรรทัด)

```tcl
do run.do                                    ;# default: vhdl + tb_mux4
set TOP tb_mux8; do run.do                   ;# เปลี่ยน testbench
set LANG verilog; set TOP tb_gates; do run.do
set N 16; set TOP tb_mux8; do run.do         ;# ทดสอบ N = 16
unset N                                      ;# ตัวแปรค้างอยู่ตลอด session — ลบเมื่อไม่ใช้แล้ว
```

เคล็ดลับ: กดลูกศรขึ้นใน Transcript เรียกคำสั่งเดิมได้ — รอบการทำงานจริงคือ **แก้โค้ด → `do run.do` → ดู Transcript/Wave** ซ้ำไปเรื่อย ๆ

**ขั้นที่ 4 — ใช้งานแบบ batch** (จาก shell ที่มี `vsim` ใน PATH)

```bash
vsim -c -do "set LANG vhdl; set TOP tb_mux8; set BATCH 1; do run.do; quit -f"
```

`-c` = command-line mode ไม่เปิด GUI และ `quit -f` ปิด vsim หลัง testbench หยุด — ผลพิมพ์ออก terminal ตรง ๆ

**ขั้นที่ 5 — สคริปต์ regression `regress.sh`** (Linux/macOS/Git Bash/WSL)

```bash
#!/usr/bin/env bash
# regress.sh — รันทุก testbench ทั้งสองภาษาแบบ batch แล้วสรุปผล
cd "$(dirname "$0")"
pass=0; fail=0
for L in vhdl verilog; do
  for T in tb_gates tb_mux4 tb_mux8; do
    log="log_${L}_${T}.txt"
    vsim -c -do "set LANG $L; set TOP $T; set BATCH 1; do run.do; quit -f" < /dev/null > "$log" 2>&1
    if grep -q '\*\*\* PASS \*\*\*' "$log" && ! grep -qE 'FAIL|\*\* Error|\*\* Fatal' "$log"; then
      echo "PASS  $L  $T";  pass=$((pass+1))
    else
      echo "FAIL  $L  $T  (ดู $log)";  fail=$((fail+1))
    fi
  done
done
echo "Summary: $pass pass, $fail fail"
[ "$fail" -eq 0 ]          # exit code ≠ 0 เมื่อมีตัวไหน FAIL (ใช้กับ CI ได้ในอนาคต)
```

```bash
chmod +x regress.sh
./regress.sh
```

ผลที่คาดหวัง:

```text
PASS  vhdl  tb_gates
PASS  vhdl  tb_mux4
PASS  vhdl  tb_mux8
PASS  verilog  tb_gates
PASS  verilog  tb_mux4
PASS  verilog  tb_mux8
Summary: 6 pass, 0 fail
```

เกณฑ์ตัดสินในสคริปต์ต้องมี **ทั้งสองเงื่อนไข**: เจอคำว่า PASS และไม่เจอ FAIL/Error — ถ้าตรวจแค่ไม่มี FAIL การที่ compile พังจน testbench ไม่ได้รันเลยก็จะถูกนับเป็นผ่าน (ทดลอง: ลบ `;` ใน gates.vhd หนึ่งตัวแล้วรัน regress.sh ดูว่าได้ FAIL จริง)

ผู้ใช้ Windows ที่ไม่มี Git Bash: รันทีละคำสั่งจากขั้นที่ 4 ใน Command Prompt (เปลี่ยน `LANG`/`TOP` 6 ครั้ง) แล้วดูผลด้วยตา — ได้ผลเท่ากันแต่ไม่อัตโนมัติ

**ขั้นที่ 6 — regression ด้วย qrun (regress\_qrun.sh)**

ทำงานเดียวกับ regress.sh แต่ไม่ต้องใช้ run.do — qrun compile + optimize + simulate ให้ในคำสั่งเดียว และ `-outdir` แยกผลของแต่ละ test ไว้คนละโฟลเดอร์ จึงไม่มีปัญหาชื่อ design unit ซ้ำระหว่างสองภาษาและไม่ต้อง vdel

```bash
#!/usr/bin/env bash
# regress_qrun.sh — รุ่น qrun: ไม่ต้องใช้ vlib/run.do แต่ละ test มีโฟลเดอร์ผลของตัวเอง
cd "$(dirname "$0")"
pass=0; fail=0
for L in vhdl verilog; do
  for T in tb_gates tb_mux4 tb_mux8; do
    if [ "$L" = vhdl ]; then
      SRC="-2008 vhdl/gates.vhd vhdl/mux4.vhd vhdl/mux8.vhd vhdl/$T.vhd"
    else
      SRC="verilog/gates.v verilog/mux4.v verilog/mux8.v verilog/$T.sv"
    fi
    log="log_qrun_${L}_${T}.txt"
    qrun $SRC -top "$T" -outdir "qrun_${L}_${T}" -do "run -all; quit -f" < /dev/null > "$log" 2>&1
    if grep -q '\*\*\* PASS \*\*\*' "$log" && ! grep -qE 'FAIL|\*\* Error|\*\* Fatal' "$log"; then
      echo "PASS  $L  $T";  pass=$((pass+1))
    else
      echo "FAIL  $L  $T  (ดู $log)";  fail=$((fail+1))
    fi
  done
done
echo "Summary: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
```

```bash
chmod +x regress_qrun.sh
./regress_qrun.sh          # ผลที่คาดหวังเหมือนขั้นที่ 5: Summary: 6 pass, 0 fail
```

เปรียบเทียบ: run.do เหมาะกับการ debug ทีละ test ใน GUI ส่วน qrun เหมาะกับ regression และ CI — งานจริงมักใช้ qrun (หรือ Makefile ที่เรียก qrun) คู่กับ do-file สำหรับจัด waveform ทดลองให้ FAIL แบบเดียวกับขั้นที่ 5 เพื่อยืนยันว่าสคริปต์จับได้จริง

**ขั้นที่ 7 (เสริม — ต้องใช้ license เต็ม) — Code coverage ใน Questa**

Code coverage วัดว่า testbench ทำให้โค้ด RTL ถูกใช้งานครบแค่ไหน — PASS บอกว่าสิ่งที่ทดสอบถูก แต่ coverage บอกว่า **ทดสอบครบหรือยัง** (ลงลึกใน Module 04)

```tcl
# พิมพ์ใน Transcript — +cover: s=statement b=branch c=condition e=expression t=toggle
quit -sim
vdel -lib work -all; vlib work
vlog +cover=sbcet -quiet verilog/mux4.v verilog/mux8.v   ;# VHDL: vcom -2008 +cover=sbcet vhdl/mux4.vhd vhdl/mux8.vhd
vlog -sv -quiet verilog/tb_mux8.sv                       ;# testbench ไม่ต้องเก็บ coverage
vsim -coverage work.tb_mux8
run -all
coverage save mux8.ucdb
coverage report -details                                 ;# สรุปใน Transcript
```

```bash
# จาก shell: รายงาน HTML แล้วเปิด cov_html/index.html ใน browser
vcover report -html -output cov_html mux8.ucdb
# หรือแบบ qrun บรรทัดเดียว
qrun verilog/mux4.v verilog/mux8.v verilog/tb_mux8.sv -top tb_mux8 -coverage \
     -do "run -all; coverage save mux8.ucdb; quit -f"
```

**สิ่งที่ต้องสังเกตและบันทึก:** statement/branch coverage ของ mux4 และ mux8 ควรได้ 100% เพราะ tb\_mux8 วน sel ครบ 8 ค่า แต่ **toggle coverage ของ d ต่ำมาก** เพราะ testbench ตั้งค่า d ครั้งเดียวตอนเริ่มแล้วไม่เปลี่ยนอีก บิตส่วนใหญ่จึงไม่เคยสลับ 0→1→0 — ตัวอย่างชัดเจนว่า PASS ไม่ได้แปลว่าทดสอบครบ ให้ผู้เรียนเสนอวิธีแก้ testbench (เช่น วนข้อมูลหลายชุด หรือกลับบิตทุกบิต) แล้วรันวัดใหม่

ถ้าใช้รุ่น Starter แล้วขึ้นข้อความว่า checkout license feature ไม่ได้ ให้ข้ามขั้นนี้ — ไม่หักคะแนน

✅ **Checkpoint 1D:** `./regress.sh` และ `./regress_qrun.sh` ได้ Summary: 6 pass, 0 fail ทั้งคู่ และทดลองให้ FAIL ได้อย่างน้อย 1 ครั้ง (ขั้นที่ 7 เป็นงานเสริม)

## Lab 1A+ — Testbench ที่อ่านเวกเตอร์จากไฟล์และเขียนผลเป็นไฟล์ (VHDL, 60–90 นาที)

**เป้าหมายย่อย:** ทดสอบ gates, mux4 และ mux8 ชุดเดิมจาก 1A–1C ด้วย testbench ที่ **แยกข้อมูลทดสอบออกจากโค้ด** — อ่านอินพุตและค่าคาดหวังจากไฟล์ข้อความ แล้วเขียนผลทุกเวกเตอร์พร้อมสรุป PASS/FAIL ลงไฟล์ผลลัพธ์ รันได้ทั้ง Questa และ ModelSim (คำสั่งเหมือนกันทุกตัวในส่วนนี้) — ทำเฉพาะภาษา VHDL

**ทำไมต้องใช้ไฟล์:** เพิ่ม/แก้เวกเตอร์ได้โดยไม่ต้อง compile ใหม่, ใช้ testbench ตัวเดียวกับเวกเตอร์หลายชุด (ปกติ, กรณีขอบ, สุ่ม), รับเวกเตอร์ที่ทีมอื่นสร้างจาก spec หรือโมเดลในภาษาอื่น (Tcl/Python/MATLAB) และเก็บไฟล์ผลไว้เป็นหลักฐานหรือเทียบกับรอบก่อนด้วย `diff` — เป็นพื้นฐานของ testbench แบบ data-driven ที่ใช้ใน Module 03–04

**ความรู้ที่ต้องมีก่อน:** ทำ 1A–1C สาย VHDL ผ่านแล้ว (ใช้ `gates.vhd`, `mux4.vhd`, `mux8.vhd` ตัวเดิมโดยไม่แก้) และรู้จัก `run.do` จาก 1D

### แนวคิด TEXTIO ที่ใช้ใน Lab นี้

VHDL อ่าน/เขียนไฟล์ข้อความผ่าน package `std.textio` แบบ **ทีละบรรทัดสองจังหวะ**: อ่านทั้งบรรทัดจากไฟล์เข้าตัวแปร `line` ก่อน แล้วค่อยดึงทีละ field ออกจาก `line` — ฝั่งเขียนก็กลับกัน (เติม field ลง `line` แล้ว `writeline` ทั้งบรรทัด)

```text
 vectors/gates_vec.txt                         testbench (process stim)                      results/gates_out.txt
 ┌────────────────┐  readline   ┌─────────────────────────────┐  writeline  ┌─────────────────────────────────┐
 │ # comment      │  ─────────► │ lin  : line                 │  ─────────► │ # header                        │
 │ 0 0 0011011    │             │ read(lin, va, ok) → a <= va │             │      4   10 ns  0 0 ... PASS    │
 │ 0 1 0110101    │             │ wait for 10 ns              │             │      5   20 ns  0 1 ... PASS    │
 │ ...            │             │ เทียบ y_vec กับ vexp          │             │ # SUMMARY ... => PASS           │
 └────────────────┘             │ write(lout, ...) → lout     │             └─────────────────────────────────┘
                                └─────────────────────────────┘
```

| สิ่งที่ใช้ | มาจาก | ทำอะไร |
| --- | --- | --- |
| `file fin : text;` | std.textio | ประกาศตัวแทนไฟล์ข้อความ (ประกาศใน process เพื่อเปิดเองด้วย `file_open`) |
| `file_open(st, fin, name, read_mode)` | VHDL มาตรฐาน | เปิดไฟล์และคืนสถานะ `open_ok` / `name_error` / `status_error` / `mode_error` — **ต้องตรวจสถานะเสมอ** ไม่เช่นนั้น path ผิดจะกลายเป็น error ที่อ่านยาก |
| `readline(fin, lin)` / `endfile(fin)` | std.textio | อ่านทั้งบรรทัดเข้า `lin` (ชนิด `line` = pointer ไปยัง string) / ตรวจว่าหมดไฟล์หรือยัง |
| `read(lin, v, ok)` | std.textio + ieee.std\_logic\_1164 (VHDL-2008) | ดึง 1 field ออกจาก `lin` ข้ามช่องว่างนำหน้า — `ok = false` เมื่ออ่านไม่ได้ (ใช้แบบมี `ok` เสมอ จะได้รายงานเลขบรรทัดที่ผิดเองได้) |
| `hread(lin, v, ok)` / `hwrite(lout, v)` | ieee.std\_logic\_1164 (VHDL-2008) | อ่าน/เขียน `std_logic_vector` เป็นฐานสิบหก (ความกว้างต้องหาร 4 ลงตัว) |
| `write(lout, x)` / `writeline(fout, lout)` | std.textio | ต่อข้อความ/ค่า (รวม `now` ชนิด time) เข้า `lout` แล้วเขียนทั้งบรรทัด — เขียนข้อความคงที่ต้องบอกชนิด `string'("...")` |
| `file_close(f)` | VHDL มาตรฐาน | ปิดไฟล์ **ก่อน** `std.env.stop` เพื่อให้ข้อมูลที่ค้างใน buffer ถูกเขียนลงดิสก์แน่นอน และ do-file อ่านไฟล์ผลต่อได้ครบ |

### กติกาไฟล์เวกเตอร์ (ใช้เหมือนกันทุกไฟล์)

- 1 บรรทัด = 1 เวกเตอร์, field คั่นด้วยช่องว่างหรือ tab เรียงตามลำดับที่เขียนไว้ใน comment หัวไฟล์
- บรรทัดที่ขึ้นต้นด้วย `#` (หลังช่องว่างได้) และบรรทัดว่างถูกข้าม; ข้อความหลัง field สุดท้ายถูกละเว้น (ใช้เป็น comment ท้ายบรรทัดได้)
- ค่า std\_logic ต้องเป็นอักษรตามมาตรฐาน **พิมพ์ใหญ่**: `0 1 X Z U W L H -` — `x` ตัวเล็กอ่านไม่ได้และจะกลายเป็น format error
- ค่าฐานสิบหกต้องมีจำนวนหลัก = N/4 พอดี (N = 8 → 2 หลัก, N = 16 → 4 หลัก)
- ไฟล์เป็น text ธรรมดา บันทึกเป็น UTF-8 ได้ (comment ภาษาไทยในไฟล์เวกเตอร์ไม่มีปัญหาเพราะถูกข้าม)

### ขั้นที่ 0 — เตรียมโฟลเดอร์

```text
lab01_gates/
├── vhdl/
│   ├── gates.vhd  mux4.vhd  mux8.vhd                         # จาก 1A–1C (ไม่แก้)
│   ├── tb_file_pkg.vhd                                      # ใหม่: ฟังก์ชันช่วยอ่านไฟล์
│   └── tb_gates_file.vhd  tb_mux4_file.vhd  tb_mux8_file.vhd  # ใหม่
├── vectors/          # ไฟล์เวกเตอร์ขาเข้า (เขียนเองหรือสร้างด้วย gen_vectors.tcl)
├── results/          # ไฟล์ผลลัพธ์ (run_file.do สร้างให้)
├── run_file.do  regress_file.sh  gen_vectors.tcl
└── run.do  regress.sh    # ของเดิมจาก 1D
```

```bash
cd lab01_gates && mkdir -p vectors results
```

**กฎเรื่อง path:** ชื่อไฟล์ใน testbench (`"vectors/gates_vec.txt"`) เป็น path สัมพัทธ์กับ **โฟลเดอร์ปัจจุบันของ simulator** (คำสั่ง `pwd` ใน Transcript) ไม่ใช่โฟลเดอร์ของไฟล์ .vhd — ก่อนรันทุกครั้งต้อง `cd` ไปที่ `lab01_gates` และ VHDL สร้างโฟลเดอร์เองไม่ได้ (`results/` ต้องมีอยู่ก่อน)

### ขั้นที่ 1 — package ช่วยอ่านไฟล์ `vhdl/tb_file_pkg.vhd`

ทุก testbench ต้อง "ข้าม comment/บรรทัดว่าง" และ "เปิดไฟล์แบบตรวจสถานะ" เหมือนกัน จึงแยกไว้ใน package เดียว (หลักการเดียวกับการแยก mux4 ออกมาใช้ซ้ำใน 1C)

```vhdl
-- tb_file_pkg.vhd — ฟังก์ชันช่วยอ่านไฟล์เวกเตอร์ ใช้ร่วมกันทุก testbench ของ Lab 1A+
library std;
use std.textio.all;

package tb_file_pkg is
  -- true เมื่อบรรทัดว่าง มีแต่ช่องว่าง หรือขึ้นต้นด้วย '#' (comment)
  function is_skip_line(s : string) return boolean;   -- เรียกด้วย is_skip_line(lin.all)
  -- เปิดไฟล์และหยุด simulation พร้อมข้อความชัดเจนถ้าเปิดไม่ได้
  procedure open_or_die(file f : text; name : in string; mode : in file_open_kind);
end package;

package body tb_file_pkg is
  function is_skip_line(s : string) return boolean is
  begin
    for i in s'range loop                     -- สตริงว่าง (length 0) จะไม่เข้า loop → return true
      if s(i) = '#' then
        return true;                          -- เจอ # ก่อนตัวอักษรอื่น = comment
      elsif s(i) /= ' ' and s(i) /= HT and s(i) /= CR then   -- CR: ไฟล์ที่บันทึกจาก Windows (CRLF)
        return false;                         -- เจอข้อมูลจริง
      end if;
    end loop;
    return true;                              -- มีแต่ช่องว่าง/tab/CR
  end function;

  procedure open_or_die(file f : text; name : in string; mode : in file_open_kind) is
    variable st : file_open_status;
  begin
    file_open(st, f, name, mode);
    assert st = open_ok
      report "cannot open file '" & name & "' (status = " & file_open_status'image(st) &
             ") - check pwd and that the folder exists"
      severity failure;
  end procedure;
end package body;
```

จุดที่ต้องเข้าใจ (เป็น error จริงที่เจอตอนเตรียม Lab นี้):

- **ฟังก์ชันรับพารามิเตอร์ชนิด `line` ไม่ได้** เพราะ `line` เป็น access type (pointer) — จึงรับ `string` แล้วเรียกด้วย `lin.all` (ค่าที่ pointer ชี้) ถ้าเขียน `function is_skip_line(l : line)` จะได้ error ทำนอง *type of constant interface cannot be access type*
- **ห้ามใช้ภาษาไทยใน string literal** (ใน `report "..."`) — สตริงของ VHDL รับเฉพาะอักขระ Latin-1 ตัวอักษรไทย UTF-8 จะทำให้ compile ไม่ผ่าน (comment ภาษาไทยหลัง `--` ใช้ได้)
- `severity failure` ทำให้ simulation หยุดทันที — เหมาะกับความผิดพลาดที่ทำต่อไม่ได้ (เปิดไฟล์ไม่ได้) ส่วนเวกเตอร์ที่ FAIL ใช้ `severity error` เพื่อทดสอบต่อจนครบไฟล์

### ส่วนที่ 1 — Logic Gate: `tb_gates_file`

**ขั้นที่ 2 — เขียนไฟล์เวกเตอร์ `vectors/gates_vec.txt`** (ค่า expected คือ truth table จากขั้นที่ 1 ของ 1A — มีบรรทัดว่างอยู่กลางไฟล์โดยตั้งใจเพื่อทดสอบการข้ามบรรทัด)

```text
# gates_vec.txt — เวกเตอร์ทดสอบ gates
# คอลัมน์: a b expected   (expected 7 บิต เรียงเป็น and or nand nor xor xnor not)
# บรรทัดที่ขึ้นต้นด้วย # และบรรทัดว่างจะถูกข้าม
0 0 0011011
0 1 0110101

1 0 0110100
1 1 1100010
```

**ขั้นที่ 3 — เขียน testbench `vhdl/tb_gates_file.vhd`**

```vhdl
-- tb_gates_file.vhd — อ่านเวกเตอร์ (a b expected) จากไฟล์ เขียนผลลง results/
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.tb_file_pkg.all;

entity tb_gates_file is
  generic (
    IN_FILE  : string := "vectors/gates_vec.txt";
    OUT_FILE : string := "results/gates_out.txt"
  );
end entity;

architecture sim of tb_gates_file is
  signal a, b  : std_logic := '0';
  signal y_and, y_or, y_nand, y_nor, y_xor, y_xnor, y_not : std_logic;
  signal y_vec : std_logic_vector(6 downto 0);
begin
  dut : entity work.gates
    port map (a => a, b => b, y_and => y_and, y_or => y_or, y_nand => y_nand,
              y_nor => y_nor, y_xor => y_xor, y_xnor => y_xnor, y_not => y_not);

  y_vec <= y_and & y_or & y_nand & y_nor & y_xor & y_xnor & y_not;   -- ลำดับเดียวกับคอลัมน์ expected

  stim : process
    file     fin, fout : text;
    variable lin, lout : line;
    variable va, vb    : std_logic;
    variable vexp      : std_logic_vector(6 downto 0);
    variable ok        : boolean;
    variable lineno, nvec, nerr, nfmt : natural := 0;
  begin
    open_or_die(fin,  IN_FILE,  read_mode);
    open_or_die(fout, OUT_FILE, write_mode);
    write(lout, string'("# tb_gates_file  input=" & IN_FILE));
    writeline(fout, lout);
    write(lout, string'("# bit order of got/exp: and or nand nor xor xnor not"));
    writeline(fout, lout);
    write(lout, string'("# line    time  a b  got      exp      result"));
    writeline(fout, lout);

    while not endfile(fin) loop
      readline(fin, lin);
      lineno := lineno + 1;
      next when is_skip_line(lin.all);

      -- อ่าน 3 field ตามลำดับ หยุดทันทีที่ field ใดอ่านไม่ได้
      read(lin, va, ok);
      if ok then read(lin, vb,   ok); end if;
      if ok then read(lin, vexp, ok); end if;
      if not ok then
        nfmt := nfmt + 1;
        report "format error in " & IN_FILE & " line " & integer'image(lineno) severity error;
        write(lout, lineno, right, 6);
        write(lout, string'("  FORMAT-ERROR"));
        writeline(fout, lout);
        next;
      end if;

      a <= va;  b <= vb;
      wait for 10 ns;                               -- ให้ DUT ตอบสนองก่อนอ่านเอาต์พุต
      nvec := nvec + 1;

      write(lout, lineno, right, 6);
      write(lout, now, right, 8);
      write(lout, string'("  "));  write(lout, a);
      write(lout, string'(" "));   write(lout, b);
      write(lout, string'("  "));  write(lout, y_vec);
      write(lout, string'("  "));  write(lout, vexp);
      if y_vec /= vexp then
        nerr := nerr + 1;
        write(lout, string'("  FAIL"));
        report "FAIL line " & integer'image(lineno) & ": a=" & to_string(va) & " b=" & to_string(vb) &
               " got " & to_string(y_vec) & " exp " & to_string(vexp) severity error;
      else
        write(lout, string'("  PASS"));
      end if;
      writeline(fout, lout);
    end loop;

    -- สรุปท้ายไฟล์ (บรรทัดนี้ใช้ตัดสินใน regression)
    write(lout, string'("# SUMMARY vectors=" & integer'image(nvec) & " errors=" & integer'image(nerr) &
                        " format_errors=" & integer'image(nfmt)));
    if nerr = 0 and nfmt = 0 and nvec > 0 then
      write(lout, string'(" => PASS"));
    else
      write(lout, string'(" => FAIL"));
    end if;
    writeline(fout, lout);

    file_close(fin);
    file_close(fout);                              -- ต้องปิดก่อน stop ไม่เช่นนั้นข้อมูลอาจค้างใน buffer
    report "tb_gates_file done: vectors=" & integer'image(nvec) & " errors=" & integer'image(nerr) &
           " format_errors=" & integer'image(nfmt) & " (see " & OUT_FILE & ")";
    std.env.stop;
    wait;
  end process;
end architecture;
```

| จุดสำคัญ | เหตุผล |
| --- | --- |
| ชื่อไฟล์เป็น generic `IN_FILE` / `OUT_FILE` | เปลี่ยนไฟล์ตอน `vsim -gIN_FILE=...` ได้โดยไม่แก้โค้ด (เหมือน `-gN=16` ใน 1B) |
| `file fin, fout : text;` ประกาศใน process ไม่ใส่ชื่อไฟล์ | เปิดเองด้วย `open_or_die` จะได้ตรวจสถานะ และปิดเองด้วย `file_close` ได้ |
| `next when is_skip_line(lin.all);` | ข้าม comment/บรรทัดว่าง — `lineno` ยังนับทุกบรรทัด จึงรายงานเลขบรรทัดตรงกับที่เห็นใน editor |
| อ่านทีละ field แบบ `if ok then read(...)` | field แรกที่ผิดจะหยุดการอ่านทั้งบรรทัด → นับเป็น format error 1 ครั้ง ไม่ป้อนค่าครึ่ง ๆ เข้า DUT |
| อ่านเข้า variable ก่อน แล้วค่อย `a <= va` | ตรวจรูปแบบครบทุก field ก่อนส่งเข้าสัญญาณ |
| `wait for 10 ns` ก่อนเทียบ | สัญญาณที่ assign จะเปลี่ยนหลัง process หยุดรอเท่านั้น — ถ้าเทียบทันทีจะได้ค่าเก่า |
| `write(lout, now, right, 8)` | ใส่เวลา simulation ในไฟล์ผล เพื่อกระโดดไปดูจุดนั้นใน Wave ได้ทันที |
| บรรทัด `# SUMMARY ... => PASS/FAIL` | เครื่องมืออื่น (shell, CI) ตัดสินผลจากไฟล์ได้ด้วย `grep` — ถ้าไม่มีเวกเตอร์เลย (`nvec = 0`) ต้องนับเป็น FAIL |

**ขั้นที่ 4 — รันใน Questa/ModelSim ทีละคำสั่ง** (พิมพ์ในหน้าต่าง Transcript)

```tcl
cd C:/labs/lab01_gates                  ;# หรือ path ของคุณ — สำคัญที่สุดใน Lab นี้
pwd                                     ;# ต้องเป็นโฟลเดอร์ที่มี vectors/ และ results/
file mkdir results                      ;# Tcl: สร้างโฟลเดอร์ผลลัพธ์ (ถ้ามีแล้วก็ไม่ error)
vdel -lib work -all; vlib work; vmap work work
vcom -2008 vhdl/tb_file_pkg.vhd         ;# package ก่อน เพราะ testbench use work.tb_file_pkg
vcom -2008 vhdl/gates.vhd vhdl/tb_gates_file.vhd
vsim -voptargs=+acc=npr work.tb_gates_file
add wave /tb_gates_file/*
run -all
```

ผลใน Transcript (รูปแบบของ Questa/ModelSim):

```text
# ** Note: tb_gates_file done: vectors=4 errors=0 format_errors=0 (see results/gates_out.txt)
#    Time: 40 ns  Iteration: 0  Instance: /tb_gates_file
# Break in Process stim at vhdl/tb_gates_file.vhd line ...
```

ดูไฟล์ผลลัพธ์โดยไม่ต้องออกจาก Questa — เลือกวิธีใดก็ได้:

```tcl
notepad results/gates_out.txt                                        ;# เปิดใน text editor ของ Questa/ModelSim
set fh [open results/gates_out.txt r]; echo [read $fh]; close $fh    ;# พิมพ์ลง Transcript ด้วย Tcl
```

**ผลที่ต้องได้ใน `results/gates_out.txt`** (ผลจริงจากการทดสอบโค้ดชุดนี้ — เลข line คือบรรทัดในไฟล์เวกเตอร์ สังเกตว่ากระโดดจาก 5 ไป 7 เพราะบรรทัดว่าง):

```text
# tb_gates_file  input=vectors/gates_vec.txt
# bit order of got/exp: and or nand nor xor xnor not
# line    time  a b  got      exp      result
     4   10 ns  0 0  0011011  0011011  PASS
     5   20 ns  0 1  0110101  0110101  PASS
     7   30 ns  1 0  0110100  0110100  PASS
     8   40 ns  1 1  1100010  1100010  PASS
# SUMMARY vectors=4 errors=0 format_errors=0 => PASS
```

ใน Wave ให้วาง cursor ที่เวลาตามคอลัมน์ `time` (เช่น 20 ns) แล้วตรวจว่าค่าที่เห็นตรงกับบรรทัดนั้นในไฟล์

**ขั้นที่ 5 — พิสูจน์ว่าแก้เวกเตอร์ได้โดยไม่ต้อง compile:** เปิด `vectors/gates_vec.txt` ใน editor แล้วคัดลอกบรรทัด `1 1 1100010` เพิ่มท้ายไฟล์ 1 บรรทัด บันทึก แล้ว

```tcl
restart -f        ;# เริ่ม simulation ใหม่ → testbench เปิดไฟล์เวกเตอร์ใหม่ (ไม่ต้อง vcom)
run -all          ;# ต้องได้ vectors=5 และเวลาสิ้นสุด 50 ns
```

นี่คือข้อดีหลักของ testbench แบบไฟล์: เปลี่ยนข้อมูลทดสอบได้ทันที — ลบบรรทัดที่เพิ่มออกก่อนทำขั้นต่อไป

**ขั้นที่ 6 — ไฟล์เวกเตอร์ผิดโดยตั้งใจ (ห้ามแก้ RTL)** — สร้าง `vectors/gates_bad.txt`:

```text
# gates_bad.txt — ไฟล์ทดสอบว่า testbench จับปัญหาได้ (ห้ามแก้ RTL)
0 0 0011011
0 1 0110111     # expected ผิดโดยตั้งใจ (บิต xnor)
1 0 011010      # ขาดบิต → format error
1 X 0110100     # อินพุต X (ต้องพิมพ์ใหญ่ — x เล็กอ่านไม่ได้)
1 1 1100010
```

เปลี่ยนไฟล์ด้วย generic ตอน vsim (ต้อง `quit -sim` ก่อน เพราะ generic ถูกกำหนดตอนโหลด design — `restart` ใช้ค่าเดิม):

```tcl
quit -sim
vsim -voptargs=+acc=npr -gIN_FILE=vectors/gates_bad.txt -gOUT_FILE=results/gates_bad_out.txt work.tb_gates_file
run -all
notepad results/gates_bad_out.txt
```

ผลที่ต้องได้ (ผลจริงจากการทดสอบ):

```text
# tb_gates_file  input=vectors/gates_bad.txt
# bit order of got/exp: and or nand nor xor xnor not
# line    time  a b  got      exp      result
     2   10 ns  0 0  0011011  0011011  PASS
     3   20 ns  0 1  0110101  0110111  FAIL
     4  FORMAT-ERROR
     5   30 ns  1 X  X1X0XX0  0110100  FAIL
     6   40 ns  1 1  1100010  1100010  PASS
# SUMMARY vectors=4 errors=2 format_errors=1 => FAIL
```

พร้อม `** Error: FAIL line 3: ...`, `** Error: format error in vectors/gates_bad.txt line 4` และ `** Error: FAIL line 5: ...` ใน Transcript

อ่านบรรทัด 5 ให้เข้าใจ: เมื่อ b = X → `1 and X = X`, `1 or X = 1`, `nand = X`, `nor = 0`, `xor/xnor = X`, `not a = 0` จึงได้ `X1X0XX0` — การเทียบ `/=` ของ VHDL เทียบทุกอักขระตรงตัว ('X' ≠ '0') จึงจับได้เสมอ (ต่างจาก `!=` ใน Verilog ที่ให้ผล x — เทียบคำถามข้อ 5 ท้าย Lab)

**ขั้นที่ 7 — ทดสอบกรณีเปิดไฟล์ไม่ได้**

```tcl
quit -sim
vsim -gIN_FILE=vectors/no_such_file.txt work.tb_gates_file
run -all
```

ต้องเห็น `** Failure: cannot open file 'vectors/no_such_file.txt' (status = name_error) - check pwd and that the folder exists` และ simulation หยุดที่ 0 ns — เทียบกับถ้าไม่ตรวจสถานะ จะได้ error ระดับ simulator ที่ไม่บอกว่าไฟล์ไหน ลองซ้ำด้วย `-gOUT_FILE=no_dir/out.txt` จะได้ข้อความแบบเดียวกันสำหรับฝั่งเขียน (เพราะไม่มีโฟลเดอร์ `no_dir`)

✅ **Checkpoint 1A+.1:** `results/gates_out.txt` ได้ `=> PASS` 4 เวกเตอร์, `results/gates_bad_out.txt` ตรงกับที่แสดงข้างบน (errors=2, format\_errors=1) และอธิบายที่มาของ `X1X0XX0` ได้

### ส่วนที่ 2 — Multiplexer: `tb_mux4_file` (ฐานสิบหก + generic N)

**ขั้นที่ 8 — ไฟล์เวกเตอร์ 2 ไฟล์** — `sel` เป็นเลขฐานสอง 2 หลัก ส่วนข้อมูลเป็นฐานสิบหก (N = 8 → 2 หลัก) ชุดที่สองใช้ค่า A5/5A/FF/00 ที่ทุกบิตต่างกัน เพื่อจับบิตที่ต่อสลับกัน และบรรทัดสุดท้ายป้อน `sel = XX` จากไฟล์ตรง ๆ (แทนการเขียนไว้ในโค้ดแบบขั้นที่ 8 ของ 1B)

```text
# mux4_vec.txt — N = 8 (ข้อมูลฐานสิบหก 2 หลัก)
# คอลัมน์: sel d0 d1 d2 d3 expected
00 11 22 33 44 11
01 11 22 33 44 22
10 11 22 33 44 33
11 11 22 33 44 44
# ข้อมูลชุดที่สอง: ค่าที่ทุกบิตต่างกัน ใช้จับบิตที่ต่อสลับ
00 A5 5A FF 00 A5
01 A5 5A FF 00 5A
10 A5 5A FF 00 FF
11 A5 5A FF 00 00
# sel เป็น X: VHDL ตกที่ when others → ได้ d3
XX 11 22 33 44 44
```

```text
# mux4_vec_n16.txt — N = 16 (ฐานสิบหก 4 หลัก) ใช้กับ -gN=16
00 1111 2222 3333 4444 1111
01 1111 2222 3333 4444 2222
10 1111 2222 3333 4444 3333
11 1111 2222 3333 4444 4444
```

**ขั้นที่ 9 — เขียน `vhdl/tb_mux4_file.vhd`** — โครงเดียวกับ tb\_gates\_file ต่างที่ generic N, `hread`/`hwrite` และ assert ตรวจ N

```vhdl
-- tb_mux4_file.vhd — เวกเตอร์: sel(binary 2 บิต) d0 d1 d2 d3 expected (ฐานสิบหก, N บิต)
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.tb_file_pkg.all;

entity tb_mux4_file is
  generic (
    N        : positive := 8;                          -- ต้องเป็นผลคูณของ 4 (เพราะอ่านแบบ hex)
    IN_FILE  : string   := "vectors/mux4_vec.txt";
    OUT_FILE : string   := "results/mux4_out.txt"
  );
end entity;

architecture sim of tb_mux4_file is
  signal d0, d1, d2, d3, y : std_logic_vector(N-1 downto 0) := (others => '0');
  signal sel               : std_logic_vector(1 downto 0)   := "00";
begin
  assert N mod 4 = 0 report "N must be a multiple of 4 for hread/hwrite" severity failure;

  dut : entity work.mux4
    generic map (N => N)
    port map (d0 => d0, d1 => d1, d2 => d2, d3 => d3, sel => sel, y => y);

  stim : process
    file     fin, fout : text;
    variable lin, lout : line;
    variable vsel      : std_logic_vector(1 downto 0);
    variable v0, v1, v2, v3, vexp : std_logic_vector(N-1 downto 0);
    variable ok        : boolean;
    variable lineno, nvec, nerr, nfmt : natural := 0;
  begin
    open_or_die(fin,  IN_FILE,  read_mode);
    open_or_die(fout, OUT_FILE, write_mode);
    write(lout, string'("# tb_mux4_file  N=" & integer'image(N) & "  input=" & IN_FILE));
    writeline(fout, lout);
    write(lout, string'("# line    time  sel  y(hex)  exp(hex)  result"));
    writeline(fout, lout);

    while not endfile(fin) loop
      readline(fin, lin);
      lineno := lineno + 1;
      next when is_skip_line(lin.all);

      read(lin, vsel, ok);                              -- binary: 00 01 10 11 XX
      if ok then hread(lin, v0, ok); end if;            -- hex: ต้องมีจำนวนหลัก = N/4 พอดี
      if ok then hread(lin, v1, ok); end if;
      if ok then hread(lin, v2, ok); end if;
      if ok then hread(lin, v3, ok); end if;
      if ok then hread(lin, vexp, ok); end if;
      if not ok then
        nfmt := nfmt + 1;
        report "format error in " & IN_FILE & " line " & integer'image(lineno) severity error;
        write(lout, lineno, right, 6);
        write(lout, string'("  FORMAT-ERROR"));
        writeline(fout, lout);
        next;
      end if;

      d0 <= v0;  d1 <= v1;  d2 <= v2;  d3 <= v3;  sel <= vsel;
      wait for 10 ns;
      nvec := nvec + 1;

      write(lout, lineno, right, 6);
      write(lout, now, right, 8);
      write(lout, string'("  "));  write(lout, sel);
      write(lout, string'("   ")); hwrite(lout, y, right, 6);
      write(lout, string'("  "));  hwrite(lout, vexp, right, 8);
      if y /= vexp then
        nerr := nerr + 1;
        write(lout, string'("  FAIL"));
        report "FAIL line " & integer'image(lineno) & ": sel=" & to_string(vsel) &
               " got " & to_hstring(y) & " exp " & to_hstring(vexp) severity error;
      else
        write(lout, string'("  PASS"));
      end if;
      writeline(fout, lout);
    end loop;

    write(lout, string'("# SUMMARY vectors=" & integer'image(nvec) & " errors=" & integer'image(nerr) &
                        " format_errors=" & integer'image(nfmt)));
    if nerr = 0 and nfmt = 0 and nvec > 0 then
      write(lout, string'(" => PASS"));
    else
      write(lout, string'(" => FAIL"));
    end if;
    writeline(fout, lout);
    file_close(fin);
    file_close(fout);
    report "tb_mux4_file done: vectors=" & integer'image(nvec) & " errors=" & integer'image(nerr) &
           " format_errors=" & integer'image(nfmt) & " (see " & OUT_FILE & ")";
    std.env.stop;
    wait;
  end process;
end architecture;
```

| จุดสำคัญ | คำอธิบาย |
| --- | --- |
| `hread(lin, v0, ok)` | อ่านฐานสิบหกเข้า vector ความกว้าง N — 1 หลัก = 4 บิต จึงต้องมี N/4 หลักพอดี (เป็นของ `ieee.std_logic_1164` ใน VHDL-2008 — ต้อง compile ด้วย `-2008`) |
| `hwrite(lout, y, right, 6)` | เขียนฐานสิบหกชิดขวาในช่องกว้าง 6 ตัว ให้คอลัมน์ตรงกันทุกบรรทัด |
| `assert N mod 4 = 0 ... severity failure` | หยุดตั้งแต่เริ่ม ถ้าผู้ใช้สั่ง `-gN=10` ซึ่งอ่าน/เขียน hex ไม่ได้ |
| อ่าน `sel` ด้วย `read` ธรรมดา | ทำให้ป้อน `XX`, `ZZ`, `0X` จากไฟล์ได้ (อักษรพิมพ์ใหญ่) |

**ขั้นที่ 10 — รันที่ N = 8 และ N = 16**

```tcl
quit -sim
vcom -2008 vhdl/mux4.vhd vhdl/tb_mux4_file.vhd
vsim -voptargs=+acc=npr work.tb_mux4_file
add wave -radix hex /tb_mux4_file/*
run -all
notepad results/mux4_out.txt

quit -sim
vsim -voptargs=+acc=npr -gN=16 -gIN_FILE=vectors/mux4_vec_n16.txt -gOUT_FILE=results/mux4_n16_out.txt work.tb_mux4_file
run -all
notepad results/mux4_n16_out.txt
```

ผลที่ต้องได้ (ผลจริงจากการทดสอบ):

```text
# tb_mux4_file  N=8  input=vectors/mux4_vec.txt
# line    time  sel  y(hex)  exp(hex)  result
     3   10 ns  00       11        11  PASS
     4   20 ns  01       22        22  PASS
     5   30 ns  10       33        33  PASS
     6   40 ns  11       44        44  PASS
     8   50 ns  00       A5        A5  PASS
     9   60 ns  01       5A        5A  PASS
    10   70 ns  10       FF        FF  PASS
    11   80 ns  11       00        00  PASS
    13   90 ns  XX       44        44  PASS
# SUMMARY vectors=9 errors=0 format_errors=0 => PASS
```

```text
# tb_mux4_file  N=16  input=vectors/mux4_vec_n16.txt
# line    time  sel  y(hex)  exp(hex)  result
     2   10 ns  00     1111      1111  PASS
     3   20 ns  01     2222      2222  PASS
     4   30 ns  10     3333      3333  PASS
     5   40 ns  11     4444      4444  PASS
# SUMMARY vectors=4 errors=0 format_errors=0 => PASS
```

**ขั้นที่ 11 — ความกว้างในไฟล์ไม่ตรงกับ N (ปัญหาที่พบบ่อยที่สุดของ testbench แบบไฟล์)** — ทดลองทั้งสองทิศแล้วบันทึกผล:

```tcl
quit -sim
vsim -gIN_FILE=vectors/mux4_vec_n16.txt -gOUT_FILE=results/mis_a.txt work.tb_mux4_file   ;# ไฟล์ 4 หลัก แต่ N = 8
run -all
quit -sim
vsim -gN=16 -gOUT_FILE=results/mis_b.txt work.tb_mux4_file                                 ;# ไฟล์ 2 หลัก แต่ N = 16
run -all
```

| กรณี | ผลที่ได้จากการทดสอบ (GHDL 4.1) | บทเรียน |
| --- | --- | --- |
| ไฟล์กว้างกว่า N (4 หลัก, N = 8) | **ไม่มี format error** — `hread` อ่าน 2 หลักแรกแล้วเหลืออีก 2 หลักให้ field ถัดไป ค่าจึงเลื่อนผิดตำแหน่ง → FAIL 4/4 พร้อมค่าที่ดูไม่มีความหมาย | FAIL ไม่ได้แปลว่า DUT ผิดเสมอ — ตรวจไฟล์เวกเตอร์ก่อน debug RTL |
| ไฟล์แคบกว่า N (2 หลัก, N = 16) | FORMAT-ERROR ทุกบรรทัด, `vectors=0` → `=> FAIL` | ดีที่ SUMMARY นับ `vectors=0` เป็น FAIL ไม่เช่นนั้นจะ "ผ่าน" ทั้งที่ไม่ได้ทดสอบอะไรเลย |

การตอบสนองต่อกรณีแรกอาจต่างกันระหว่าง simulator — ให้บันทึกว่า Questa/ModelSim ที่ใช้ให้ผลแบบใด แนวป้องกันจริงคือใส่ N ไว้ในหัวไฟล์เวกเตอร์แล้วให้ testbench ตรวจ (งานท้าทายในส่วนที่ 4)

**ขั้นที่ 12 — Bug injection:** สลับ d1 กับ d2 ใน `mux4.vhd` (`d2 when "01", d1 when "10",`) → `vcom -2008 vhdl/mux4.vhd` → `restart -f; run -all` — ต้องได้ FAIL ที่บรรทัด 4, 5, 9, 10 (sel = 01 และ 10 ทั้งสองชุดข้อมูล) และ `# SUMMARY vectors=9 errors=4 format_errors=0 => FAIL` จากนั้นแก้กลับ

✅ **Checkpoint 1A+.2:** `mux4_out.txt` และ `mux4_n16_out.txt` ได้ `=> PASS`, ตารางผลขั้นที่ 11 จาก simulator ของตัวเอง และผล bug injection 4 บรรทัด

### ส่วนที่ 3 — Hierarchy: `tb_mux8_file` (เขียนสัญญาณภายในลงไฟล์)

ใน 1C ผู้เรียนดู `y_lo`/`y_hi` ใน Wave เพื่อหาว่าบั๊กอยู่ชั้นไหน — ส่วนนี้ให้ testbench เขียนสัญญาณภายในทั้งสองลงไฟล์ผลด้วย **external name** ของ VHDL-2008 โดยไม่ต้องเพิ่มพอร์ตให้ mux8 — ได้หลักฐาน debug ตามลำดับชั้นแม้ไม่เปิด GUI

**ขั้นที่ 13 — ไฟล์เวกเตอร์ `vectors/mux8_vec.txt`** (ค่าเดียวกับ 1C เพื่อเทียบผลได้ตรง ๆ)

```text
# mux8_vec.txt — N = 8   คอลัมน์: sel d0 d1 d2 d3 d4 d5 d6 d7 expected
# ค่า 0xKk: หลักสิบหก = หมายเลขช่อง+1, หลักหน่วย = หมายเลขช่อง (ดูง่ายว่าเลือกช่องไหน)
000 10 21 32 43 54 65 76 87 10
001 10 21 32 43 54 65 76 87 21
010 10 21 32 43 54 65 76 87 32
011 10 21 32 43 54 65 76 87 43
100 10 21 32 43 54 65 76 87 54
101 10 21 32 43 54 65 76 87 65
110 10 21 32 43 54 65 76 87 76
111 10 21 32 43 54 65 76 87 87
```

**ขั้นที่ 14 — เขียน `vhdl/tb_mux8_file.vhd`**

```vhdl
-- tb_mux8_file.vhd — เวกเตอร์: sel(binary 3 บิต) d0 .. d7 expected (hex, N บิต)
-- เขียนสัญญาณภายใน dut/y_lo, dut/y_hi ลงไฟล์ด้วย external name ของ VHDL-2008
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.tb_file_pkg.all;

entity tb_mux8_file is
  generic (
    N        : positive := 8;
    IN_FILE  : string   := "vectors/mux8_vec.txt";
    OUT_FILE : string   := "results/mux8_out.txt"
  );
end entity;

architecture sim of tb_mux8_file is
  type data_arr is array (0 to 7) of std_logic_vector(N-1 downto 0);
  signal d   : std_logic_vector(8*N-1 downto 0) := (others => '0');
  signal sel : std_logic_vector(2 downto 0)     := "000";
  signal y   : std_logic_vector(N-1 downto 0);
begin
  assert N mod 4 = 0 report "N must be a multiple of 4 for hread/hwrite" severity failure;

  dut : entity work.mux8
    generic map (N => N)
    port map (d => d, sel => sel, y => y);

  stim : process
    -- external name: อ้างถึงสัญญาณภายใน instance dut โดยไม่ต้องเพิ่มพอร์ต
    alias y_lo is << signal .tb_mux8_file.dut.y_lo : std_logic_vector >>;   -- ไม่ระบุช่วง = ใช้ความกว้างของสัญญาณจริง
    alias y_hi is << signal .tb_mux8_file.dut.y_hi : std_logic_vector >>;   -- ไม่ระบุช่วง = ใช้ความกว้างของสัญญาณจริง
    file     fin, fout : text;
    variable lin, lout : line;
    variable vsel      : std_logic_vector(2 downto 0);
    variable vd        : data_arr;
    variable vexp      : std_logic_vector(N-1 downto 0);
    variable ok        : boolean;
    variable lineno, nvec, nerr, nfmt : natural := 0;
  begin
    open_or_die(fin,  IN_FILE,  read_mode);
    open_or_die(fout, OUT_FILE, write_mode);
    write(lout, string'("# tb_mux8_file  N=" & integer'image(N) & "  input=" & IN_FILE));
    writeline(fout, lout);
    write(lout, string'("# line    time  sel  y_lo  y_hi     y   exp  result"));
    writeline(fout, lout);

    while not endfile(fin) loop
      readline(fin, lin);
      lineno := lineno + 1;
      next when is_skip_line(lin.all);

      read(lin, vsel, ok);
      for k in 0 to 7 loop                              -- อ่าน d0..d7 ด้วย loop
        exit when not ok;
        hread(lin, vd(k), ok);
      end loop;
      if ok then hread(lin, vexp, ok); end if;
      if not ok then
        nfmt := nfmt + 1;
        report "format error in " & IN_FILE & " line " & integer'image(lineno) severity error;
        write(lout, lineno, right, 6);
        write(lout, string'("  FORMAT-ERROR"));
        writeline(fout, lout);
        next;
      end if;

      for k in 0 to 7 loop                              -- ช่อง k อยู่ที่บิต (k+1)*N-1 downto k*N
        d((k+1)*N-1 downto k*N) <= vd(k);
      end loop;
      sel <= vsel;
      wait for 10 ns;
      nvec := nvec + 1;

      write(lout, lineno, right, 6);
      write(lout, now, right, 8);
      write(lout, string'("  "));  write(lout, sel);
      hwrite(lout, y_lo, right, 6);
      hwrite(lout, y_hi, right, 6);
      hwrite(lout, y,    right, 6);
      hwrite(lout, vexp, right, 6);
      if y /= vexp then
        nerr := nerr + 1;
        write(lout, string'("  FAIL"));
        report "FAIL line " & integer'image(lineno) & ": sel=" & to_string(vsel) &
               " got " & to_hstring(y) & " exp " & to_hstring(vexp) severity error;
      else
        write(lout, string'("  PASS"));
      end if;
      writeline(fout, lout);
    end loop;

    write(lout, string'("# SUMMARY vectors=" & integer'image(nvec) & " errors=" & integer'image(nerr) &
                        " format_errors=" & integer'image(nfmt)));
    if nerr = 0 and nfmt = 0 and nvec > 0 then
      write(lout, string'(" => PASS"));
    else
      write(lout, string'(" => FAIL"));
    end if;
    writeline(fout, lout);
    file_close(fin);
    file_close(fout);
    report "tb_mux8_file done: vectors=" & integer'image(nvec) & " errors=" & integer'image(nerr) &
           " format_errors=" & integer'image(nfmt) & " (see " & OUT_FILE & ")";
    std.env.stop;
    wait;
  end process;
end architecture;
```

| จุดสำคัญ | คำอธิบาย |
| --- | --- |
| `<< signal .tb_mux8_file.dut.y_lo : std_logic_vector >>` | external name: path เริ่มด้วย `.` = เริ่มจาก top แล้วไล่ตามชื่อ instance (`dut`) ไปถึงสัญญาณ — ตรงกับที่เห็นในหน้าต่าง sim/Structure (`/tb_mux8_file/dut/y_lo`) |
| ประกาศ alias ใน process ซึ่งอยู่ **หลัง** `dut` | external name ต้องอ้างถึงสิ่งที่ elaborate แล้ว — ถ้าย้ายไปประกาศใน architecture (ก่อน `begin`) หรือวาง process ไว้ก่อน `dut` จะได้ error ตอน elaboration |
| ชนิด `std_logic_vector` แบบไม่ระบุช่วง | รับความกว้างจากสัญญาณจริง — ตอนเตรียม Lab ระบุ `std_logic_vector(N-1 downto 0)` แล้ว GHDL 4.1 elaborate ไม่ผ่าน (too large object) แต่แบบไม่ระบุช่วงผ่าน; ถ้า Questa/ModelSim รุ่นที่ใช้ไม่ยอมแบบไม่ระบุช่วง ให้เปลี่ยนกลับเป็น `(N-1 downto 0)` |
| `for k ... exit when not ok; hread(lin, vd(k), ok);` | อ่าน 8 field ด้วย loop แทนการเขียน 8 บรรทัด และหยุดทันทีที่ field ใดผิด |
| `d((k+1)*N-1 downto k*N) <= vd(k)` | ประกอบ 8 ช่องเป็น vector กว้าง 8×N ตามการจัดวางที่กำหนดใน 1C (d0 อยู่บิตล่างสุด) |

**ขั้นที่ 15 — รัน**

```tcl
quit -sim
vcom -2008 vhdl/mux4.vhd vhdl/mux8.vhd vhdl/tb_mux8_file.vhd    ;# ลำดับ: บล็อกย่อย → บล็อกแม่ → testbench
vsim -voptargs=+acc=npr work.tb_mux8_file
add wave -radix hex /tb_mux8_file/sel /tb_mux8_file/y /tb_mux8_file/dut/y_lo /tb_mux8_file/dut/y_hi
run -all
notepad results/mux8_out.txt
```

ผลที่ต้องได้ (ผลจริงจากการทดสอบ):

```text
# tb_mux8_file  N=8  input=vectors/mux8_vec.txt
# line    time  sel  y_lo  y_hi     y   exp  result
     3   10 ns  000    10    54    10    10  PASS
     4   20 ns  001    21    65    21    21  PASS
     5   30 ns  010    32    76    32    32  PASS
     6   40 ns  011    43    87    43    43  PASS
     7   50 ns  100    10    54    54    54  PASS
     8   60 ns  101    21    65    65    65  PASS
     9   70 ns  110    32    76    76    76  PASS
    10   80 ns  111    43    87    87    87  PASS
# SUMMARY vectors=8 errors=0 format_errors=0 => PASS
```

อ่านคอลัมน์ `y_lo`/`y_hi`: mux4 ทั้งสองตัวทำงานพร้อมกันตลอดเวลาตาม `sel[1:0]` และ `sel(2)` เป็นตัวเลือกว่าจะส่งตัวไหนออก `y` — เห็นได้จากไฟล์โดยไม่ต้องเปิด Wave

**ขั้นที่ 16 — Bug injection ที่ชั้นบน:** ใน `mux8.vhd` สลับเป็น `y <= y_lo when sel(2) = '1' else y_hi;` → คอมไพล์ `mux8.vhd` **และ `tb_mux8_file.vhd` ใหม่** (หน่วยที่พึ่งพาอาศัยหน่วยที่เปลี่ยนจะถูกทำเครื่องหมายว่าล้าสมัย — `run_file.do` ในส่วนที่ 4 compile ใหม่ทั้งหมดให้เอง) → รันใหม่ ผลจริงจากการทดสอบ:

```text
# line    time  sel  y_lo  y_hi     y   exp  result
     3   10 ns  000    10    54    54    10  FAIL
     4   20 ns  001    21    65    65    21  FAIL
     5   30 ns  010    32    76    76    32  FAIL
     6   40 ns  011    43    87    87    43  FAIL
     7   50 ns  100    10    54    10    54  FAIL
     8   60 ns  101    21    65    21    65  FAIL
     9   70 ns  110    32    76    32    76  FAIL
    10   80 ns  111    43    87    43    87  FAIL
# SUMMARY vectors=8 errors=8 format_errors=0 => FAIL
```

การวินิจฉัยจากไฟล์อย่างเดียว: `y_lo` และ `y_hi` ยังถูกต้องทุกแถว (เทียบกับไฟล์ผลปกติ) แต่ `y` เท่ากับ **อีกตัว** ทุกแถว → mux4 ทั้งสองตัวถูก บั๊กอยู่ที่ mux 2:1 ชั้นบนของ mux8 — คำตอบเดียวกับขั้นที่ 6 ของ 1C แต่ได้มาจากหลักฐานที่เก็บไว้และส่งต่อได้ จากนั้นแก้กลับ

✅ **Checkpoint 1A+.3:** `mux8_out.txt` ได้ `=> PASS` พร้อมคอลัมน์ `y_lo`/`y_hi`, ไฟล์ผลตอนฉีดบั๊ก 8 FAIL และคำอธิบายว่าสรุปตำแหน่งบั๊กจากคอลัมน์ใด

### ส่วนที่ 4 — do-file, Regression และการสร้างเวกเตอร์อัตโนมัติ

**ขั้นที่ 17 — `run_file.do`** (วางที่ root ของ `lab01_gates/` — หลักการเดียวกับ `run.do` ของ 1D เพิ่มการส่งชื่อไฟล์เข้า generic และพิมพ์ไฟล์ผลลง Transcript)

```tcl
# run_file.do — Lab 1A+ : compile + simulate testbench แบบอ่าน/เขียนไฟล์ (VHDL)
#   GUI   : set TOP tb_mux4_file; do run_file.do
#           set TOP tb_gates_file; set IN vectors/gates_bad.txt; set OUT results/gates_bad_out.txt; do run_file.do
#   Batch : vsim -c -do "set TOP tb_mux8_file; set BATCH 1; do run_file.do; quit -f"
# ตัวแปร (ไม่บังคับ): TOP, IN, OUT, N, BATCH — IN/OUT/N ถูกลบทิ้งท้ายสคริปต์ จะได้ไม่ค้างไปรอบถัดไป

if {![info exists TOP]}   { set TOP tb_gates_file }
if {![info exists BATCH]} { set BATCH 0 }
array set DEF_OUT {tb_gates_file results/gates_out.txt tb_mux4_file results/mux4_out.txt tb_mux8_file results/mux8_out.txt}
if {![info exists OUT]}   { set OUT $DEF_OUT($TOP) }

# generic ที่ส่งเข้า testbench: OUT_FILE เสมอ, IN_FILE และ N เมื่อผู้ใช้ตั้ง
set GOPT "-gOUT_FILE=$OUT"
if {[info exists IN]} { append GOPT " -gIN_FILE=$IN" }
if {[info exists N]}  { append GOPT " -gN=$N" }

if {$BATCH} { onerror {quit -f -code 1} }
if {!$BATCH} { catch {quit -sim} }

# (1) VHDL สร้างโฟลเดอร์เองไม่ได้ → สร้างโฟลเดอร์ผลลัพธ์ด้วย Tcl ก่อน simulate
file mkdir [file dirname $OUT]

# (2) clean build — package ก่อน, RTL ล่างขึ้นบน, testbench ท้ายสุด
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work
vcom -2008 -quiet vhdl/tb_file_pkg.vhd
vcom -2008 -quiet vhdl/gates.vhd vhdl/mux4.vhd vhdl/mux8.vhd
vcom -2008 -quiet vhdl/tb_gates_file.vhd vhdl/tb_mux4_file.vhd vhdl/tb_mux8_file.vhd

# (3) simulate — GUI ใส่ +acc=npr เพื่อดู wave, batch ไม่ใส่เพื่อความเร็ว
if {$BATCH} { set ACC "" } else { set ACC "-voptargs=+acc=npr" }
eval vsim $ACC $GOPT work.$TOP
if {!$BATCH} { add wave -radix hex /$TOP/* }
run -all
if {!$BATCH} { wave zoom full }

# (4) พิมพ์ไฟล์ผลลัพธ์ลง Transcript (testbench ปิดไฟล์ด้วย file_close แล้ว จึงอ่านได้ครบ)
if {[file exists $OUT]} {
  set fh [open $OUT r]; echo [read $fh]; close $fh
} else {
  echo "ERROR: $OUT was not created"
}
unset -nocomplain IN OUT N
```

ใช้งานแบบ GUI (พิมพ์ใน Transcript):

```tcl
do run_file.do                                                        ;# default: tb_gates_file
set TOP tb_mux4_file; do run_file.do
set TOP tb_mux4_file; set N 16; set IN vectors/mux4_vec_n16.txt; set OUT results/mux4_n16_out.txt; do run_file.do
set TOP tb_mux8_file; do run_file.do
```

**ขั้นที่ 18 — regression แบบ batch `regress_file.sh`** — ตัดสินจากบรรทัด `# SUMMARY ... => PASS/FAIL` ใน **ไฟล์ผลลัพธ์** (ไม่ใช่ log) และมีกรณี *expected-fail* ที่ต้องได้ FAIL จึงนับว่าถูก — พิสูจน์ว่า testbench ยังจับบั๊กได้ทุกครั้งที่รัน

```bash
#!/usr/bin/env bash
# regress_file.sh — รัน testbench แบบไฟล์ทุกกรณีใน batch แล้วตัดสินจากบรรทัด SUMMARY ในไฟล์ผลลัพธ์
# กรณีสุดท้ายเป็น "expected-fail": ไฟล์เวกเตอร์ผิดโดยตั้งใจ ต้องได้ FAIL จึงนับว่าถูก
cd "$(dirname "$0")"
pass=0; fail=0
run() {   # $1=TOP  $2=IN  $3=OUT  $4=ผลที่ต้องได้ (PASS|FAIL)  $5=คำสั่ง Tcl เพิ่ม (เช่น "set N 16;")
  local log="log_$(basename "$3" .txt).txt"
  vsim -c -do "set TOP $1; set IN $2; set OUT $3; $5 set BATCH 1; do run_file.do; quit -f" \
       < /dev/null > "$log" 2>&1
  local got
  got=$(grep -o '=> [A-Z]*' "$3" 2>/dev/null | tail -1 | cut -c4-)
  if [ "$got" = "$4" ]; then
    echo "OK   $1  $2  (expect $4)";  pass=$((pass+1))
  else
    echo "BAD  $1  $2  (expect $4, got ${got:-NO-OUTPUT} — ดู $log)";  fail=$((fail+1))
  fi
}
rm -rf results                                   # กันไม่ให้ไฟล์เก่าทำให้ผ่านโดยไม่ได้รันจริง
run tb_gates_file vectors/gates_vec.txt     results/gates_out.txt     PASS
run tb_mux4_file  vectors/mux4_vec.txt      results/mux4_out.txt      PASS
run tb_mux4_file  vectors/mux4_vec_n16.txt  results/mux4_n16_out.txt  PASS "set N 16;"
run tb_mux8_file  vectors/mux8_vec.txt      results/mux8_out.txt      PASS
run tb_gates_file vectors/gates_bad.txt     results/gates_bad_out.txt FAIL
echo "Summary: $pass ok, $fail bad"
[ "$fail" -eq 0 ]
```

```bash
chmod +x regress_file.sh && ./regress_file.sh
```

ผลที่ต้องได้:

```text
OK   tb_gates_file  vectors/gates_vec.txt  (expect PASS)
OK   tb_mux4_file  vectors/mux4_vec.txt  (expect PASS)
OK   tb_mux4_file  vectors/mux4_vec_n16.txt  (expect PASS)
OK   tb_mux8_file  vectors/mux8_vec.txt  (expect PASS)
OK   tb_gates_file  vectors/gates_bad.txt  (expect FAIL)
Summary: 5 ok, 0 bad
```

ผู้ใช้ Windows ที่ไม่มี Git Bash/WSL: รันคำสั่ง `vsim -c -do "..."` 5 บรรทัดใน Command Prompt แล้วเปิดดูบรรทัด SUMMARY ของแต่ละไฟล์เอง

**ขั้นที่ 19 — เก็บผลที่ตรวจแล้วเป็น golden แล้วเทียบด้วย `diff`** — ไฟล์ผลเป็น deterministic (เวลา simulation คงที่ ไม่มีเวลาจริงของเครื่อง) จึงใช้ตรวจ regression หลังแก้ RTL ได้ละเอียดกว่าบรรทัด PASS/FAIL

```bash
mkdir -p golden && cp results/*_out.txt golden/     # ทำครั้งเดียว หลังตรวจด้วยตาว่าถูกต้อง
./regress_file.sh && diff -r golden results && echo "MATCH GOLDEN"
```

**ขั้นที่ 20 — สร้างเวกเตอร์จำนวนมากด้วย `gen_vectors.tcl`** — reference model เขียนด้วย Tcl (ภาษาคนละตัวกับ RTL) สร้างค่าสุ่มแบบกำหนด seed ได้ รันได้ทั้งใน Questa และ `tclsh`

```tcl
# gen_vectors.tcl — สร้างไฟล์เวกเตอร์พร้อมค่า expected จาก reference model ที่เขียนด้วย Tcl
#   ใช้ใน Questa : do gen_vectors.tcl          (หรือ source gen_vectors.tcl)
#   ใช้ใน shell  : tclsh gen_vectors.tcl
# ตัวแปรที่ตั้งก่อนเรียกได้: NVEC (จำนวนเวกเตอร์สุ่มของ mux4/mux8), SEED, N (ความกว้างบิต, ต้องหาร 4 ลงตัว)
if {![info exists NVEC]} { set NVEC 50 }
if {![info exists SEED]} { set SEED 1 }
if {![info exists N]}    { set N 8 }
if {$N % 4 != 0} { error "N must be a multiple of 4" }
expr {srand($SEED)}
file mkdir vectors
set HEXW [expr {$N / 4}]
proc rnd {n} { return [expr {int(rand() * (2 ** $n))}] }

# ---- gates: ครบทุก combination, expected = and or nand nor xor xnor not ----
set f [open vectors/gates_gen.txt w]
puts $f "# generated by gen_vectors.tcl — a b expected(and or nand nor xor xnor not)"
foreach a {0 1} {
  foreach b {0 1} {
    set e [format "%d%d%d%d%d%d%d" [expr {$a & $b}] [expr {$a | $b}] [expr {!($a & $b)}] \
           [expr {!($a | $b)}] [expr {$a ^ $b}] [expr {!($a ^ $b)}] [expr {!$a}]]
    puts $f "$a $b $e"
  }
}
close $f

# ---- mux4: สุ่มข้อมูล + sel ----
set f [open vectors/mux4_gen_n$N.txt w]
puts $f "# generated by gen_vectors.tcl — N=$N SEED=$SEED : sel d0 d1 d2 d3 expected"
for {set i 0} {$i < $NVEC} {incr i} {
  set d {}
  for {set k 0} {$k < 4} {incr k} { lappend d [rnd $N] }
  set s [rnd 2]
  set line [format "%d%d" [expr {($s >> 1) & 1}] [expr {$s & 1}]]
  foreach v $d { append line [format " %0${HEXW}X" $v] }
  append line [format " %0${HEXW}X" [lindex $d $s]]
  puts $f $line
}
close $f

# ---- mux8: สุ่มข้อมูล + sel ----
set f [open vectors/mux8_gen_n$N.txt w]
puts $f "# generated by gen_vectors.tcl — N=$N SEED=$SEED : sel d0..d7 expected"
for {set i 0} {$i < $NVEC} {incr i} {
  set d {}
  for {set k 0} {$k < 8} {incr k} { lappend d [rnd $N] }
  set s [rnd 3]
  set line [format "%d%d%d" [expr {($s >> 2) & 1}] [expr {($s >> 1) & 1}] [expr {$s & 1}]]
  foreach v $d { append line [format " %0${HEXW}X" $v] }
  append line [format " %0${HEXW}X" [lindex $d $s]]
  puts $f $line
}
close $f
puts "gen_vectors: wrote gates_gen.txt, mux4_gen_n$N.txt, mux8_gen_n$N.txt (NVEC=$NVEC SEED=$SEED)"
```

```tcl
# ใน Transcript ของ Questa/ModelSim
do gen_vectors.tcl                                        ;# N = 8 → vectors/mux4_gen_n8.txt, mux8_gen_n8.txt
set N 16; do gen_vectors.tcl; unset N                     ;# N = 16
set TOP tb_mux8_file; set N 16; set IN vectors/mux8_gen_n16.txt; set OUT results/mux8_gen_n16_out.txt; do run_file.do
```

ตัวอย่างบรรทัดที่สร้าง (SEED = 1): `00 21 C1 75 88 21` (mux4, N = 8) และ `110 0039 C5FA BA32 51B5 6AEF AEB7 AE39 348C AE39` (mux8, N = 16) — ทดสอบแล้วทุกไฟล์ที่สร้าง (gates 4, mux4 N = 8/16 และ mux8 N = 8/16 ชุดละ 50 เวกเตอร์) ได้ `=> PASS` — ลำดับเลขสุ่มของ Tcl คงที่ตาม seed แต่อาจต่างกันได้ระหว่างรุ่น Tcl จึงตัดสินจาก PASS/FAIL ไม่ใช่ตัวเลขสุ่ม

**งานท้าทาย (เสริม):** ให้ `gen_vectors.tcl` เขียนบรรทัด `# N=8` ไว้บนสุด แล้วแก้ `tb_mux4_file` ให้อ่านค่านี้ (คำใบ้: ตรวจ `lin.all` ว่าขึ้นต้นด้วย `"# N="` แล้ว `read` เป็น integer) และหยุดด้วย `severity failure` เมื่อไม่เท่ากับ generic N — ปิดช่องโหว่ในขั้นที่ 11

### ปัญหาที่พบบ่อยใน Lab 1A+

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| `** Failure: cannot open file ... (status = name_error)` | ไม่ได้อยู่ที่ `lab01_gates`, ชื่อไฟล์ผิด (เช่น `.txt.txt`) หรือไม่มีโฟลเดอร์ `results/` | `pwd`, `ls vectors results`, ใช้ `run_file.do` ที่สร้างโฟลเดอร์ให้ |
| ไฟล์ผลว่างหรือขาดบรรทัดท้าย | ไม่ได้ `file_close` ก่อน `std.env.stop` หรือเปิดไฟล์ดูขณะ simulation ยังทำงาน | ใส่ `file_close` ทุกไฟล์; ดูผลหลัง Transcript ขึ้น `... done:` แล้ว |
| compile ไม่ผ่านที่บรรทัด `report "..."` (invalid character) | มีภาษาไทยหรืออักขระ UTF-8 อื่นใน string literal | ใช้ภาษาอังกฤษในสตริง, ภาษาไทยเฉพาะ comment |
| ไม่รู้จัก `hread`, `to_hstring`, `std.env.stop` หรือ external name | compile เป็น VHDL-93 | ใส่ `-2008` ทุก `vcom` |
| `type of constant interface ... cannot be access type` | ส่ง `line` เข้าฟังก์ชัน | รับ `string` แล้วเรียกด้วย `lin.all` (หรือใช้ procedure แทน) |
| FORMAT-ERROR ทุกบรรทัด | จำนวนหลัก hex ไม่เท่า N/4, ใช้ `x` ตัวเล็ก, จำนวน field ไม่ครบ | ดูเลขบรรทัดในไฟล์ผลแล้วเทียบกับกติกาไฟล์เวกเตอร์ |
| FAIL ทุกบรรทัดด้วยค่าที่ดูไม่มีความหมาย | ไฟล์กว้างกว่า N (ขั้นที่ 11) | ตรวจไฟล์เวกเตอร์ก่อน debug RTL |
| แก้ไฟล์เวกเตอร์แล้วผลไม่เปลี่ยน | ยังใช้ simulation รอบเดิม หรือชี้ไฟล์ผิดตัวด้วย generic ค้าง | `restart -f; run -all`; ดูบรรทัดแรกของไฟล์ผล (`input=...`) ว่าอ่านไฟล์ไหน |
| `set IN ...` ค้างจากรอบก่อนทำให้ testbench อ่านไฟล์ผิด | ตัวแปร Tcl อยู่ตลอด session | `run_file.do` ลบ IN/OUT/N ให้แล้ว ถ้าพิมพ์คำสั่งเองให้ `unset -nocomplain IN OUT N` |
| error ตอน elaboration ที่ external name | ประกาศ alias ก่อน instance ถูก elaborate, ชื่อ path ผิด หรือ simulator ไม่รับชนิดแบบไม่ระบุช่วง | ประกาศใน process หลัง `dut`, เทียบ path กับหน้าต่าง sim, ลอง `std_logic_vector(N-1 downto 0)` |

✅ **Checkpoint 1A+ (รวม):** `./regress_file.sh` ได้ `Summary: 5 ok, 0 bad`, มีโฟลเดอร์ `golden/` และ `diff -r golden results` ไม่มีความต่าง, เวกเตอร์จาก `gen_vectors.tcl` ผ่านอย่างน้อย 1 ไฟล์ต่อ testbench

**คำถามประจำ Lab 1A+**

1. ทำไมบรรทัด SUMMARY ต้องนับ `vectors=0` เป็น FAIL ยกตัวอย่างเหตุการณ์จริงที่ทำให้ได้ 0 เวกเตอร์
2. ถ้าลบ `file_close(fout)` ออก จะเกิดอะไรได้บ้าง และทำไม `run_file.do` ขั้น (4) จึงพึ่งพาคำสั่งนี้
3. เทียบ testbench แบบ golden table ในโค้ด (1A) กับแบบไฟล์ (1A+) อย่างละ 2 ข้อดีและข้อเสีย
4. `gen_vectors.tcl` คำนวณ expected เอง — อะไรทำให้ยังนับเป็น reference ที่เชื่อถือได้ และกรณีไหนที่จะไม่ช่วยจับบั๊ก
5. external name ต่างจากการเพิ่มพอร์ต debug (`y_lo_dbg`) ให้ mux8 อย่างไร และมีข้อจำกัดอะไร

| ข้อ | แนวคำตอบสำหรับผู้สอน |
| --- | --- |
| 1 | ไฟล์ว่าง/มีแต่ comment, ชี้ไฟล์ผิดตัว, ความกว้างไม่ตรง N จนทุกบรรทัดเป็น format error (ขั้นที่ 11) — ถ้านับเป็น PASS regression จะผ่านทั้งที่ไม่ได้ทดสอบอะไร (หลักการเดียวกับการต้องเจอคำว่า PASS ใน `regress.sh` ของ 1D) |
| 2 | ข้อมูลท้ายไฟล์อาจค้างใน buffer จน simulator ปิดหรือโหลด design ใหม่ (พฤติกรรมขึ้นกับเครื่องมือ) — do-file อ่านไฟล์ทันทีหลัง `run -all` ขณะ simulation ยังโหลดอยู่ จึงอาจไม่เห็นบรรทัด SUMMARY และ regression รายงาน NO-OUTPUT |
| 3 | แบบไฟล์: เพิ่มเวกเตอร์ได้ไม่ต้อง compile, คนอื่น/เครื่องมืออื่นสร้างได้, ได้ไฟล์ผลเก็บเป็นหลักฐาน / ข้อเสีย: โค้ดยาวกว่า, ต้องจัดการไฟล์และ path, มีความผิดพลาดประเภทใหม่ (รูปแบบไฟล์, ความกว้าง) ที่ต้องเขียนโค้ดตรวจ |
| 4 | เขียนด้วยภาษาและตรรกะคนละชุดกับ RTL (เลือกค่าจาก list ด้วย index ไม่ใช่ mux) จึงไม่น่าจะผิดแบบเดียวกัน — แต่ถ้าเข้าใจ spec ผิดตั้งแต่ต้น (เช่นลำดับช่องของ d) ทั้งสองอาจผิดตรงกัน; การสุ่มอาจไม่ครอบคลุมกรณีขอบ (เช่น sel = X) จึงต้องมีเวกเตอร์เขียนมือคู่กันเสมอ |
| 5 | external name ไม่แก้ RTL ที่จะสังเคราะห์ (ไม่เพิ่มพอร์ตที่ต้องต่อออกไปทุกชั้น) — ข้อจำกัด: ผูก testbench กับชื่อ instance/สัญญาณภายใน (เปลี่ยนชื่อใน RTL แล้ว testbench พัง), ใช้ได้เฉพาะ VHDL-2008, ใช้กับ netlist หลัง synthesis ไม่ได้เพราะสัญญาณภายในอาจถูกเปลี่ยนชื่อหรือหายไป |

**งานที่ต้องส่งเพิ่ม (ถ้าใช้ 1A+):** ไฟล์ `vhdl/tb_*_file.vhd` + `tb_file_pkg.vhd`, โฟลเดอร์ `vectors/`, `results/`, `golden/`, `run_file.do`, `regress_file.sh`, `gen_vectors.tcl`, ผลขั้นที่ 11 และคำตอบ 5 ข้อ — ไม่ต้องส่ง `work/` และ `log_*.txt`

## แก้ปัญหา, คำถามท้าย Lab และการประเมิน

**ตารางแก้ปัญหาที่พบบ่อยใน Lab 1** (ข้อความจริงอาจต่างเล็กน้อยตามรุ่น Questa — ใช้ `verror <รหัส>` อ่านคำอธิบายเต็ม; 5 แถวสุดท้ายเป็นปัญหาเฉพาะของ Questa)

| อาการ / ข้อความ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| `Cannot open file "vhdl/gates.vhd"` | ไม่ได้อยู่ในโฟลเดอร์ Lab หรือชื่อไฟล์ผิด (เช่น `.vhd.txt`) | `pwd`, `cd`, `ls` ตาม Lab 1.0 |
| `Could not find work.mux4` ตอน compile mux8 (VHDL) | compile ผิดลำดับ | compile `mux4.vhd` ก่อน `mux8.vhd` |
| `to_hstring` / `to_string` ไม่รู้จัก, `std.env.stop` ไม่พบ | compile เป็น VHDL-93 | ใส่ `-2008` ใน `vcom` ทุกครั้ง |
| `Unknown identifier "std_logic"` | ลืม `library ieee; use ieee.std_logic_1164.all;` | ใส่ทุก entity — context clause มีผลเฉพาะ design unit ถัดไป |
| `Illegal reference to net "y"` (vlog) | กำหนดค่า `wire` ใน `always` | ประกาศ `output reg` หรือใช้ `assign` |
| `Could not find 'work.tb_mux4'` (vsim) | ยังไม่ compile testbench, พิมพ์ชื่อผิด หรือเพิ่งล้าง library | ดูใน Library window แล้ว compile ใหม่ |
| เตือน port size does not match | ความกว้างสัญญาณใน TB ไม่ตรงกับ N ของ DUT | ใช้ N ตัวเดียวกันทั้ง TB และ DUT (ห้ามข้าม warning นี้) |
| Wave ไม่มีสัญญาณภายใน DUT หรือ Objects ว่าง | vopt optimize สัญญาณออก | `vsim -voptargs=+acc=npr` (วิธี B: `vopt +acc=npr`) |
| GUI ถาม "Are you sure you want to finish?" | testbench ใช้ `$finish` | ใช้ `$stop` (หรือตอบ No) |
| แก้โค้ดแล้วผลไม่เปลี่ยน | ลืม compile ใหม่ หรือลืม `restart -f` | ใช้ `do run.do` ทุกครั้ง |
| `vdel` ล้มเหลว (library in use) | ยังมี simulation เปิดอยู่ | `quit -sim` ก่อน (run.do ทำให้แล้ว) |
| ผลเป็น `U` (VHDL) หรือ `x` (Verilog) ตลอด | อินพุตไม่ได้ถูกตั้งค่า หรือ port map ผิดชื่อ | ตรวจใน Wave ว่าอินพุตของ DUT มีค่าหรือยัง |
| Unable to checkout a license / Invalid license environment | ไม่ได้ตั้งตัวแปร license, path ผิด หรือ MAC address ในไฟล์ .dat ไม่ตรงกับเครื่อง (เปลี่ยนเครื่อง หรือขอด้วยการ์ดเครือข่ายคนละตัว) | echo $LM\_LICENSE\_FILE, เทียบ HOSTID ในไฟล์ .dat กับ ip link / ipconfig /all, ถ้าไม่ตรงให้ขอ license ใหม่ |
| Failure to checkout ... license feature (เช่น svverification) | ใช้ฟีเจอร์ที่ license ไม่ครอบคลุม (class/randomize/covergroup, coverage) ในรุ่น Starter | Lab 1 ภาคบังคับไม่ใช้ฟีเจอร์เหล่านี้ — ตรวจว่าโค้ดเกินที่กำหนดหรือไม่; ขั้นที่ 7 ของ 1D ให้ข้ามหรือใช้เครื่องที่มี license เต็ม |
| -novopt ถูกปฏิเสธหรือมีคำเตือนว่าไม่รองรับ | คัดลอกคำสั่งจาก tutorial ModelSim รุ่นเก่า | ใช้ -voptargs=+acc=npr แทน |
| -gN=16 ไม่มีผล (ยังได้ 8 บิต) | ใช้วิธี B ซึ่ง generic ถูกฝังไว้ตอน vopt แล้ว | ใส่ -gN=16 ที่คำสั่ง vopt (หรือใช้วิธี A/qrun) |
| qrun: command not found หรือผลจาก qrun ไม่ตรงกับ do-file | PATH ไม่รวมโฟลเดอร์ Questa / qrun เก็บ library ใน qrun.out/ แยกจาก work/ | ตรวจ PATH; อย่าผสมสองแบบ — qrun -clean แล้วรันใหม่ หรือใช้ run.do/regress.sh แทน |

**คำถามท้าย Lab** (ตอบสั้น ๆ พร้อมหลักฐานจาก Transcript/waveform)

1. เมื่อ `sel` เป็น X (ขั้นที่ 8 ของ 1B) mux4 ทั้งสองภาษาให้ผลอะไร เพราะอะไร และในวงจรจริงจะเป็นแบบเดียวกันหรือไม่
2. ถ้าลบบรรทัด `default` ใน mux4 แบบ Verilog (และไม่มีค่า default ก่อน `case`) จะเกิดอะไรตอน synthesis
3. เปลี่ยน N เป็น 16 ตอน `vsim` โดยไม่แก้ไฟล์ได้อย่างไร และถ้า testbench เขียน `generic map (N => 8)` คงที่จะเกิดอะไร
4. mux8 แบบ hierarchy กับการเขียน `case` 8 ทางตรง ๆ ต่างกันอย่างไรหลัง synthesis
5. ใน Verilog testbench ทำไมใช้ `!==` แทน `!=` — ยกตัวอย่างกรณีที่ `!=` ทำให้บั๊กหลุด
6. ทำไม testbench ใน 1A ใช้ golden truth table แทนการคำนวณ `a & b` ซ้ำ
7. Questa optimize design ทุกครั้ง — +acc=npr แก้ปัญหาอะไร, ทำไม run.do จึงไม่ใส่ในโหมด batch และทำไมวิธี B ต้องใส่ -gN=16 ที่ vopt แทน vsim

**เฉลยสำหรับผู้สอน**

| ข้อ | แนวคำตอบ |
| --- | --- |
| 1 | ทั้งสองให้ `y = d3` (0x44) — VHDL: "XX" ไม่ตรง "00"/"01"/"10" จึงตก `when others`; Verilog: `case` เทียบแบบ 4-state ตรงตัว "xx" ไม่ตรง item ใดจึงตก `default` — เรียกว่า **X-optimism**: วงจรจริงที่ sel ไม่แน่นอนอาจเลือกช่องใดก็ได้ simulation จึงซ่อนบั๊กประเภท "ลืม reset/ลืมตั้งค่า" ทางแก้: assertion ตรวจว่า sel ไม่เป็น X หรือให้ default ส่ง X ออก (`y = {N{1'bx}}` — synthesis ถือเป็น don't care) |
| 2 | `case` ไม่ครบทุกค่า (ขาด `2'b11`) → ตอน sel = 11 ต้อง "จำค่าเดิม" → synthesis สร้าง **latch** พร้อม warning (เช่น Yosys รายงาน latch ที่ y) — แก้ด้วย `default` หรือกำหนด `y = d0;` ก่อน `case` |
| 3 | `vsim -gN=16 work.tb_mux4` ใช้ได้เพราะ TB ส่ง N ต่อให้ DUT; ถ้า TB เขียน `N => 8` คงที่ `-g` จะไม่มีผลกับ DUT (ต้องใช้ `-G` หรือแก้ไฟล์) และสัญญาณใน TB ที่กว้าง 8 บิตจะ port ไม่ตรง — บทเรียน: testbench ต้องคำนวณทุกอย่างจาก N |
| 4 | พฤติกรรมเหมือนกัน หลัง synthesis มักได้ mux tree 3 ชั้นขนาดใกล้เคียงกัน เพราะเครื่องมือ flatten และ optimize ข้ามขอบเขตได้ ถ้าคง hierarchy ไว้ (ไม่ flatten) การ optimize ข้าม instance จะจำกัด — ข้อดีของ hierarchy คือนำกลับมาใช้และทดสอบทีละชิ้น (พิสูจน์ด้วย Yosys `stat` ใน Module 05–06) |
| 5 | ถ้า `y` เป็น X, `y != exp` ให้ผล X ซึ่ง `if` ถือเป็นเท็จ → ไม่นับ error → รายงาน PASS ทั้งที่ DUT ไม่มีเอาต์พุต (เช่นลืมต่อ port) ส่วน `!==` เทียบ 4-state ให้ผล 1 เสมอ |
| 6 | ถ้าเขียนสูตรเดียวกับ RTL และเข้าใจผิดเหมือนกัน ผลจะตรงกันแม้จะผิด — reference ต้องมาจาก spec แยกอิสระ (หลักการเดียวกับ scoreboard/reference model ใน Module 04) |
| 7 | vopt ตัดหรือรวมสัญญาณภายในเพื่อความเร็ว ทำให้ไม่เห็นใน Wave/Objects — +acc=npr คงการมองเห็น nets/ports/registers ไว้แลกกับความเร็วที่ลดลง batch ไม่ดู wave จึงไม่ต้องจ่ายราคานี้; generic/parameter ถูก elaborate และแทนค่าเป็นค่าคงที่ตอน vopt (เช่นความกว้าง bus) design ที่ optimize แล้วจึงเปลี่ยน N ไม่ได้ — ในวิธี A vsim ส่ง -g ต่อให้ vopt เอง จึงดูเหมือนใส่ที่ vsim ได้ |

**งานที่ต้องส่ง** (บีบอัดทั้งโฟลเดอร์ lab01\_gates/ โดยลบ `work/`, `qrun.out/`, `qrun_*/`, `*.wlf`, `*.ucdb`, `cov_html/`, `transcript` ออก)

1. ไฟล์ RTL + testbench ครบ 12 ไฟล์, run.do, regress.sh, regress\_qrun.sh, wave\_mux4.do
2. log จาก `./regress.sh` ที่แสดง `Summary: 6 pass, 0 fail` (หรือ Transcript 6 ครั้งสำหรับ Windows)
3. screenshot: waveform 1A, waveform mux4 radix hex, Structure window ของ mux8, waveform mux8 ที่มี `y_lo`/`y_hi`
4. บันทึก bug injection 3 ครั้ง (1A, 1B, 1C): แก้อะไร, FAIL กี่จุด, แก้กลับแล้วผ่าน
5. คำตอบคำถาม 7 ข้อ (+ ค่า coverage ถ้าทำขั้นที่ 7 ของ 1D)

**เกณฑ์ให้คะแนน Lab 1 (100 คะแนน)**

| หัวข้อ | คะแนน | เต็ม | บางส่วน |
| --- | --- | --- | --- |
| 1A gates + TB golden table | 15 | PASS สองภาษา + bug injection ถูกต้อง | PASS ภาษาเดียว หรือไม่ทำ bug injection |
| 1B mux4 generic | 20 | PASS ที่ N = 8 และ 16 ทั้งสองภาษา + wave format | PASS เฉพาะ N = 8 |
| 1C mux8 hierarchy | 25 | RTL + TB สองภาษา PASS + screenshot Structure/สัญญาณภายใน | TB ไม่ self-checking |
| 1D do-file + regression | 20 | run.do ครบทุกส่วน + regress 6/6 ทั้งแบบ run.do และ qrun + ทดลอง FAIL | รันได้เฉพาะ GUI |
| คำตอบ 7 ข้อ | 15 | ถูกต้องพร้อมหลักฐานจาก simulation | ตอบถูกแต่ไม่มีหลักฐาน |
| คุณภาพโค้ด | 5 | ไม่มี warning, คอมเมนต์ชัด, ชื่อสื่อความหมาย | มี warning ที่ไม่ได้อธิบาย |



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

```vhdl
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
               │  mux4   │                 │
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

**หมายเหตุสำหรับผู้สอน:** ส่ง Lab 1.0 ขั้นที่ 2–5 (ติดตั้ง Questa + license) ให้ผู้เรียนทำก่อนวันเรียนอย่างน้อย 1 สัปดาห์ เพราะ license ที่ผูก MAC address แก้ในคาบไม่ทัน ถ้าเวลาไม่พอ ให้ผู้เรียนทำภาษาหลักครบทุกส่วนก่อน แล้วทำอีกภาษาเป็นการบ้าน — จุดที่ควรเดินตรวจทุกโต๊ะคือต้นคาบ (`vsim -version` และ license), ท้าย 1A (ทุกคนต้อง compile/simulate ได้แล้ว) และต้น 1D (path และ PATH ของ vsim/qrun) — สถาบันที่มี license server ควรตั้ง `SALT_LICENSE_SERVER` ใน image ของเครื่อง lab ไว้ล่วงหน้า

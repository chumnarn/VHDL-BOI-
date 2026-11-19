
### การใช้ ModelSim เชิงลึก

**ขั้นตอนทำงาน:** สร้าง library → compile → elaborate/load (`vsim`) → เพิ่ม wave → run → ดูผล/แก้โค้ด → compile ใหม่ → `restart -f` → run ใหม่ (ไม่ต้องปิดโปรแกรม)

ใช้ได้ 2 แบบ: **GUI Project** (File → New → Project, Add Existing File, Compile All, Simulate) เหมาะกับการเริ่มต้น และ **คำสั่ง / do-file** ที่หลักสูตรนี้ใช้เป็นหลักเพราะรันซ้ำได้และใช้ในงานจริง

**คำสั่งสำคัญ**

| คำสั่ง | ตัวอย่าง | ใช้ทำอะไร |
| --- | --- | --- |
| `vlib` / `vmap` | `vlib work` | สร้าง / map library |
| `vcom` | `vcom -2008 -check_synthesis rtl.vhd` | compile VHDL พร้อมตรวจไวยากรณ์ที่สังเคราะห์ไม่ได้ |
| `vlog` | `vlog -sv -lint +incdir+inc +define+SIM rtl.sv` | compile Verilog/SV, เปิด lint, กำหนด macro |
| `vsim` | `vsim -voptargs=+acc -gN=16 -t ps work.tb_top` | โหลด design, override generic/parameter, ตั้งความละเอียดเวลา |
| `add wave` | `add wave -radix unsigned /tb_top/dut/*` | เพิ่มสัญญาณใน Wave เลือกฐานการแสดงผล |
| `log` | `log -r /*` | บันทึกทุกสัญญาณ เพิ่มลง wave ทีหลังได้ไม่ต้อง run ใหม่ |
| `run` | `run 200 ns`, `run -all`, `run -continue` | จำลอง |
| `restart` | `restart -f` | เริ่มใหม่หลัง compile โดยคง wave ไว้ |
| `force` / `noforce` | `force /tb/dut/en 0 0, 1 50ns` | บังคับค่าสัญญาณชั่วคราว |
| `examine` | `examine -radix hex /tb/dut/q` | ดูค่าปัจจุบันใน Transcript |
| `bp` | `bp counter.v 15` | ตั้ง breakpoint ที่บรรทัด แล้ว `step` ทีละบรรทัด |
| `when` | `when {/tb/dut/q == 4'hF} {echo "full"; stop}` | หยุดเมื่อเงื่อนไขเป็นจริง |
| `quit -sim` | `quit -sim` | ปิด simulation แต่ไม่ปิดโปรแกรม |

เทคนิค Wave window: จัด wave ให้เรียบร้อยแล้ว File → Save Format เก็บเป็น `wave.do` ครั้งต่อไปแค่ `do wave.do` · ใช้ cursor สองตัววัดระยะเวลา · คลิกขวาสัญญาณ → Radix เปลี่ยน hex/unsigned/signed · Format → Analog ดูสัญญาณเชิงตัวเลข · ดับเบิลคลิกสัญญาณเพื่อกระโดดไปบรรทัดที่ขับสัญญาณนั้น (Dataflow)

**Error ที่พบบ่อยใน ModelSim**

| ข้อความ (ย่อ) | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| `(vcom-1136) Unknown identifier` | ลืม `use` หรือ compile ผิดลำดับ | เพิ่ม `use ieee.numeric_std.all;`, compile package ก่อน |
| `(vsim-3170) Could not find 'work.tb_x'` | ยังไม่ compile หรือชื่อ top ผิด | ตรวจชื่อ entity/module และ library |
| `(vsim-3033) Instantiation of 'x' failed` | ไม่ได้ compile บล็อกย่อย | compile ไฟล์ที่ขาด |
| `(vsim-3015) Port size does not match connection size` | ความกว้างสายไม่เท่าพอร์ต (Verilog) | แก้ width — warning นี้คือ bug เกือบทุกครั้ง |
| `Nonresolved signal has multiple sources` | สัญญาณถูกขับจาก 2 ที่ (VHDL) | รวมการกำหนดค่าไว้ process เดียว |
| `(vsim-3601) Iteration limit reached` | combinational loop หรือ clock ที่ไม่มี delay | หา loop ด้วย Dataflow window, ใส่ delay ให้ clock |
| สัญญาณภายในหายจาก Objects/Wave | vopt optimize ออก | ใช้ `vsim -voptargs=+acc` |
| ค่าเป็น U / X ตลอด | ไม่ได้ reset หรือมี 2 driver | ตรวจ reset และใช้ `drivers /tb/dut/sig` ดูว่าใครขับ |

### Lab 1 — Logic Gate, Multiplexer และ Hierarchy (4 ชั่วโมง)

**เป้าหมาย:** เขียนบล็อก combinational 3 ตัวทั้ง VHDL และ Verilog, ต่อเป็น hierarchy, เขียน self-checking testbench และรันทุกอย่างด้วย do-file ใน ModelSim

| ส่วน | งาน | เวลา |
| --- | --- | --- |
| 1A | Logic gate 7 ชนิด + truth table จาก testbench | 45 นาที |
| 1B | Mux 4:1 แบบ generic + self-checking testbench | 75 นาที |
| 1C | Mux 8:1 สร้างจาก mux4 2 ตัว (hierarchy) | 60 นาที |
| 1D | do-file และตอบคำถาม | 60 นาที |

#### Lab 1.0 — เตรียมสภาพแวดล้อม (ก่อนเริ่ม 1A, ประมาณ 10 นาที)

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

**ขั้นที่ 2 — ตรวจเวอร์ชัน ModelSim**

```bash
vsim -version
# ตัวอย่างผล: Model Technology ModelSim ... vsim 20xx.x Simulator ...
#  (หรือ Questa Intel FPGA Starter Edition — คำสั่งใน Lab นี้ใช้ได้เหมือนกัน)
```

ถ้าขึ้น `command not found` แปลว่าโฟลเดอร์ bin ของ ModelSim (เช่น `.../modelsim_ase/linuxaloem` หรือ `...\win64`) ยังไม่อยู่ใน PATH — บน Windows ให้เปิด ModelSim จาก Start menu แทนและทำทุกอย่างในหน้าต่าง Transcript

**ขั้นที่ 3 — เปิด ModelSim และย้ายไปที่โฟลเดอร์ Lab**

1. เปิด ModelSim (คำสั่ง `vsim` หรือจาก Start menu) — หน้าต่างที่ใช้บ่อยคือ **Library** (ซ้ายบน), **Transcript** (ล่าง — พิมพ์คำสั่งที่นี่), และหลังเริ่ม simulation จะมี **Wave**, **Objects**, **sim/Structure**
2. เมนู **File → Change Directory...** เลือก `lab01_gates` หรือพิมพ์ใน Transcript:

```tcl
cd C:/labs/lab01_gates      ;# Windows: ใช้ / แทน \ ได้ใน Tcl
pwd                         ;# ต้องแสดง path ของ lab01_gates
ls                          ;# ต้องเห็น vhdl verilog
```

**ขั้นที่ 4 — สร้าง library `work`**

```tcl
vlib work          ;# สร้างโฟลเดอร์ work/ เก็บผล compile
vmap work work     ;# ผูกชื่อ logical "work" กับโฟลเดอร์ (เขียนลง modelsim.ini ในโฟลเดอร์นี้)
```

ผลที่ควรเห็น: ในหน้าต่าง Library มี `work` (ยังว่าง) — **แนวคิดสำคัญ:** ModelSim ไม่ได้ simulate ไฟล์โค้ดตรง ๆ แต่ compile แต่ละ design unit (entity/architecture/module) เก็บไว้ใน library ก่อน แล้ว `vsim` โหลดจาก library — แก้โค้ดแล้วต้อง compile ใหม่ทุกครั้ง

**กฎสำคัญของ Lab นี้:** ไฟล์ VHDL และ Verilog มี design unit ชื่อเดียวกัน (`gates`, `mux4`, `mux8`, `tb_*`) ถ้า compile ทั้งสองภาษาลง `work` พร้อมกัน ตัวที่ compile ทีหลังจะทับตัวแรก — ในส่วน 1A–1C ให้ทำทีละภาษา และล้าง library ก่อนสลับภาษาด้วย `vdel -lib work -all` แล้ว `vlib work` (do-file ใน 1D ทำให้อัตโนมัติ)

✅ **Checkpoint 1.0:** `pwd` ชี้ที่ lab01\_gates, มีโฟลเดอร์ `work/` และไฟล์ `modelsim.ini` เกิดขึ้น

#### Lab 1A — Logic Gate 7 ชนิด (45 นาที)

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

ในหน้าต่าง Library กด `+` หน้า `work` จะเห็น `gates` (entity) และ `rtl` (architecture) — ถ้ามี error ให้ **ดับเบิลคลิกที่บรรทัด error สีแดง** ModelSim จะเปิดไฟล์ไปที่บรรทัดนั้น แก้ทีละ error จาก**ตัวแรก** เสมอ (error ตัวหลังมักเป็นผลต่อเนื่อง)

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
    $stop;     // ใช้ $stop แทน $finish: ใน GUI $finish จะถามว่าจะปิด ModelSim ไหม
  end
endmodule
```

**ขั้นที่ 5 — Compile testbench และ simulate (สาย VHDL เป็นตัวอย่าง)**

```tcl
vcom -2008 vhdl/tb_gates.vhd
vsim -voptargs=+acc work.tb_gates   ;# +acc เก็บสัญญาณไว้ให้ดูใน Wave ได้ครบ
add wave /tb_gates/*
run -all
```

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

ทำซ้ำขั้นที่ 5–7 ด้วยสาย Verilog (`vdel -lib work -all; vlib work; vlog verilog/gates.v; vlog -sv verilog/tb_gates.sv; vsim -voptargs=+acc work.tb_gates`)

✅ **Checkpoint 1A:** PASS ทั้งสองภาษา + เห็น FAIL 4 แถวตอนฉีดบั๊ก + บันทึก screenshot waveform

#### Lab 1B — Mux 4:1 แบบ Generic (75 นาที)

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
vsim -voptargs=+acc work.tb_mux4
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
vsim -voptargs=+acc -gN=16 work.tb_mux4
add wave -radix hex /tb_mux4/*
run -all
```

ผลที่ต้องเห็น: `y=0011`, `0022`, `0033`, `0044` (16 บิต) และยัง PASS — `-g` กำหนด generic/parameter ของ top ที่ไม่ได้ถูกกำหนดค่าไว้ใน generic map ส่วน `-G` บังคับทับแม้จะถูก map ไว้แล้ว — นี่คือเหตุผลที่ testbench ควรส่งต่อ N เข้า DUT แทนการเขียนเลข 8 คงที่

**ขั้นที่ 8 — ทดลองเมื่อ sel เป็น X** — ดูบรรทัด `sel=xx` ใน Transcript และช่วง 40–50 ns ใน waveform: ทั้งสองภาษาให้ `y = 44` (ไม่ใช่ X) บันทึกผลไว้ตอบคำถามท้าย Lab ข้อ 1

**ขั้นที่ 9 — Bug injection** — สลับ `d1` กับ `d2` ใน RTL (VHDL: `d2 when "01"`, `d1 when "10"`) compile แล้ว `restart -f; run -all` ต้องเห็น FAIL ที่ sel=1 และ sel=2 จากนั้นแก้กลับ

✅ **Checkpoint 1B:** PASS ทั้งสองภาษาที่ N = 8 และ N = 16, มีไฟล์ `wave_mux4.do`, บันทึกผล sel = X

#### Lab 1C — Mux 8:1 แบบ Hierarchy (60 นาที)

**เป้าหมายย่อย:** นำ mux4 ที่ผ่านการทดสอบแล้วมาต่อเป็นบล็อกที่ใหญ่ขึ้น (structural design), ใช้ slice ของ vector และดูลำดับชั้น instance ใน ModelSim

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

vsim -voptargs=+acc work.tb_mux8
add wave -radix unsigned /tb_mux8/sel
add wave -radix hex      /tb_mux8/y
add wave -radix hex      /tb_mux8/dut/y_lo /tb_mux8/dut/y_hi    ;# สัญญาณภายใน DUT
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

**ขั้นที่ 5 — สำรวจ hierarchy ใน ModelSim**

1. เปิดแท็บ **sim** (หน้าต่าง Structure) — ต้องเห็น `tb_mux8 → dut (mux8) → u_lo (mux4), u_hi (mux4)`
2. คลิก `u_hi` → หน้าต่าง Objects จะแสดง port ของ instance นั้น — ลาก `d0..d3` ของ `u_hi` ไปใส่ Wave แล้วตรวจว่าเป็น 54, 65, 76, 87
3. คลิกขวาที่ `dut` → **View Declaration** เพื่อเปิดซอร์สโค้ด — ใช้ได้เมื่อดีไซน์มีหลายชั้นและหาไฟล์ไม่เจอ
4. (ถ้ามีเมนู) **Tools → Dataflow** แล้วลาก `y` เข้าไป ดับเบิลคลิกเพื่อไล่ย้อนหาต้นทางของสัญญาณ (driver tracing) — ทักษะ debug ที่จะใช้บ่อยใน Module 03–04
5. รันซ้ำที่ N = 16: `quit -sim; vsim -voptargs=+acc -gN=16 work.tb_mux8; run -all` → PASS

**ขั้นที่ 6 — Bug injection** — ใน mux8 สลับ `y_hi` กับ `y_lo` (VHDL: `y <= y_lo when sel(2) = '1' else y_hi;`) → ต้อง FAIL 8 จุด จากนั้นให้อธิบายว่าดูจาก waveform อย่างเดียวจะรู้ได้อย่างไรว่าผิดที่ชั้นไหน (คำใบ้: ดู `y_lo`, `y_hi` ที่ยังถูกต้อง)

✅ **Checkpoint 1C:** PASS ทั้งสองภาษา, screenshot หน้าต่าง Structure ที่เห็น `u_lo`/`u_hi`, screenshot waveform ที่มี `y_lo`, `y_hi`, `y` แบบ radix hex

#### Lab 1D — Do-file และ Regression (60 นาที รวมตอบคำถาม)

**เป้าหมายย่อย:** เปลี่ยนทุกคำสั่งที่พิมพ์มือใน 1A–1C ให้เป็นสคริปต์ที่รันซ้ำได้ด้วยคำสั่งเดียว ทั้งแบบ GUI (ดู waveform) และแบบ batch (ไม่เปิดหน้าต่าง ใช้ตรวจทุก testbench รวดเดียว) — นี่คือพื้นฐานของ regression ที่จะใช้ตลอดหลักสูตร

**ขั้นที่ 1 — เขียน `run.do`** วางที่ root ของ `lab01_gates/`

```tcl
# run.do — compile + simulate หนึ่ง testbench
#   GUI   : set LANG verilog; set TOP tb_mux8; do run.do
#   Batch : vsim -c -do "set LANG vhdl; set TOP tb_gates; set BATCH 1; do run.do; quit -f"

# (1) ค่า default ของตัวแปร — ถ้าผู้ใช้ตั้งไว้ก่อนแล้วจะไม่ถูกทับ
if {![info exists LANG]}  { set LANG  vhdl }
if {![info exists TOP]}   { set TOP   tb_mux4 }
if {![info exists BATCH]} { set BATCH 0 }
if {[info exists N]} { set GOPT "-gN=$N" } else { set GOPT "" }

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

# (4) โหลด design (eval เพราะ GOPT อาจว่าง)
eval vsim -voptargs=+acc $GOPT work.$TOP

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
| (2) `vdel` + `vlib` | ล้างและสร้าง library ใหม่ทุกครั้ง | ผลไม่ปนกับการ compile ครั้งก่อน (clean build) |
| (3) `-quiet` | ตัดข้อความ Loading/Compiling | อ่าน warning/error ง่ายขึ้น — ถ้า compile error สคริปต์จะหยุดทันที |
| (4) `eval vsim ... $GOPT` | ใส่ `-gN=...` เมื่อผู้ใช้ตั้ง N | ทดสอบหลายความกว้างโดยไม่แก้ไฟล์ (tb\_gates ไม่มี N จะได้ warning เท่านั้น) |
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

✅ **Checkpoint 1D:** `./regress.sh` ได้ `Summary: 6 pass, 0 fail` และทดลองให้ FAIL ได้อย่างน้อย 1 ครั้ง

#### Lab 1 — แก้ปัญหา, คำถามท้าย Lab และการประเมิน

**ตารางแก้ปัญหาที่พบบ่อยใน Lab 1** (ข้อความจริงอาจต่างเล็กน้อยตามรุ่น ModelSim)

| อาการ / ข้อความ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| `Cannot open file "vhdl/gates.vhd"` | ไม่ได้อยู่ในโฟลเดอร์ Lab หรือชื่อไฟล์ผิด (เช่น `.vhd.txt`) | `pwd`, `cd`, `ls` ตาม Lab 1.0 |
| `Could not find work.mux4` ตอน compile mux8 (VHDL) | compile ผิดลำดับ | compile `mux4.vhd` ก่อน `mux8.vhd` |
| `to_hstring` / `to_string` ไม่รู้จัก, `std.env.stop` ไม่พบ | compile เป็น VHDL-93 | ใส่ `-2008` ใน `vcom` ทุกครั้ง |
| `Unknown identifier "std_logic"` | ลืม `library ieee; use ieee.std_logic_1164.all;` | ใส่ทุก entity — context clause มีผลเฉพาะ design unit ถัดไป |
| `Illegal reference to net "y"` (vlog) | กำหนดค่า `wire` ใน `always` | ประกาศ `output reg` หรือใช้ `assign` |
| `Could not find 'work.tb_mux4'` (vsim) | ยังไม่ compile testbench, พิมพ์ชื่อผิด หรือเพิ่งล้าง library | ดูใน Library window แล้ว compile ใหม่ |
| เตือน port size does not match | ความกว้างสัญญาณใน TB ไม่ตรงกับ N ของ DUT | ใช้ N ตัวเดียวกันทั้ง TB และ DUT (ห้ามข้าม warning นี้) |
| Wave ไม่มีสัญญาณภายใน DUT หรือ Objects ว่าง | optimizer ตัดสัญญาณออก | ใช้ `vsim -voptargs=+acc` |
| GUI ถาม "Are you sure you want to finish?" | testbench ใช้ `$finish` | ใช้ `$stop` (หรือตอบ No) |
| แก้โค้ดแล้วผลไม่เปลี่ยน | ลืม compile ใหม่ หรือลืม `restart -f` | ใช้ `do run.do` ทุกครั้ง |
| `vdel` ล้มเหลว (library in use) | ยังมี simulation เปิดอยู่ | `quit -sim` ก่อน (run.do ทำให้แล้ว) |
| ผลเป็น `U` (VHDL) หรือ `x` (Verilog) ตลอด | อินพุตไม่ได้ถูกตั้งค่า หรือ port map ผิดชื่อ | ตรวจใน Wave ว่าอินพุตของ DUT มีค่าหรือยัง |

**คำถามท้าย Lab** (ตอบสั้น ๆ พร้อมหลักฐานจาก Transcript/waveform)

1. เมื่อ `sel` เป็น X (ขั้นที่ 8 ของ 1B) mux4 ทั้งสองภาษาให้ผลอะไร เพราะอะไร และในวงจรจริงจะเป็นแบบเดียวกันหรือไม่
2. ถ้าลบบรรทัด `default` ใน mux4 แบบ Verilog (และไม่มีค่า default ก่อน `case`) จะเกิดอะไรตอน synthesis
3. เปลี่ยน N เป็น 16 ตอน `vsim` โดยไม่แก้ไฟล์ได้อย่างไร และถ้า testbench เขียน `generic map (N => 8)` คงที่จะเกิดอะไร
4. mux8 แบบ hierarchy กับการเขียน `case` 8 ทางตรง ๆ ต่างกันอย่างไรหลัง synthesis
5. ใน Verilog testbench ทำไมใช้ `!==` แทน `!=` — ยกตัวอย่างกรณีที่ `!=` ทำให้บั๊กหลุด
6. ทำไม testbench ใน 1A ใช้ golden truth table แทนการคำนวณ `a & b` ซ้ำ

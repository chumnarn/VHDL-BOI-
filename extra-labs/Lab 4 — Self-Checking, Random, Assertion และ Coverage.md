# Lab 4 — Self-Checking, Random, Assertion และ Coverage

Oct 28, 2026 · @Chumnarn Punyasai

## ภาพรวม Lab 4

**เป้าหมาย:** ยกระดับ testbench ของ Lab 2–3 ให้เป็นแบบที่ใช้ในงานจริง — คำตอบที่ถูกมาจากแหล่งอิสระ (golden vector จาก Python), สุ่มแบบมีเงื่อนไข, วัดได้ว่า "ทดสอบครบหรือยัง" ด้วย coverage และตรวจกฎเชิงเวลาด้วย assertion จากนั้นพิสูจน์ว่า testbench แต่ละแบบจับ bug ได้ต่างกันอย่างไรใน bug hunt

**เมื่อจบ Lab ผู้เรียนจะ**

1. สร้าง golden vector ด้วย Python ที่ตรวจตัวเองก่อน และใช้ไฟล์เดียวกันทดสอบ RTL ทั้ง VHDL และ Verilog
2. อ่านไฟล์ใน VHDL ด้วย `std.textio` และใน Verilog ด้วย `$fgets` / `$sscanf` แบบทนต่อบรรทัดผิดรูปแบบ
3. เขียน transaction class ที่มี constraint, covergroup ที่แปลงมาจาก verification plan และสุ่มจน coverage ครบ 100%
4. เขียน SVA แยกจาก RTL แล้ว `bind` เข้า DUT พร้อม `cover property` กัน vacuous pass
5. อ่านรายงาน code coverage, functional coverage และ assertion แล้วอธิบาย hole ที่เหลือได้
6. เทียบพลังของ testbench 4 แบบด้วย bug จริง

**ความรู้ที่ต้องมีก่อน:** Lab 2 (`alu8`, testbench directed/exhaustive, reference model), Lab 3 (`seq_det_1011`, `traffic`, testbench self-checking), Module 04 หัวข้อ 4.1–4.5 และ Python 3 เบื้องต้น

| ส่วน | งาน | เครื่องมือ | เกณฑ์ผ่าน | เวลา |
| --- | --- | --- | --- | --- |
| 4.0 | Verification plan ของ alu8 (การบ้านก่อนเข้า Lab) | — | ครบทุก feature พร้อมวิธีตรวจ | 20 นาที (ก่อนเรียน) |
| 4A | Golden vector จาก Python + TB VHDL อ่านไฟล์ | ModelSim | 5,000 vectors, errors = 0 | 60 นาที |
| 4B | TB SystemVerilog แบบ class + covergroup + SVA | Questa | errors = 0, functional coverage 100%, assertion fail = 0 | 120 นาที |
| 4C | Bug hunt: หา bug ที่ฝังไว้ใน ALU 3 ตัว | ModelSim / Questa | ระบุ bug และ TB ที่จับได้ครบ 3 ตัว | 60 นาที |

**เครื่องมือที่ต้องใช้:** ModelSim ทุกรุ่นทำ 4A และ 4C (ส่วน directed / exhaustive / golden) ได้ ส่วน 4B ต้องใช้ Questa (เช่น Questa-Intel FPGA Starter) เพราะ class + `randomize()`, covergroup, SVA concurrent และ code coverage ไม่มีใน ModelSim รุ่น Starter — ก่อนสอนให้คอมไพล์ `sv/tb_alu8_cls.sv` บนเครื่องในห้องแล็บดูก่อนว่า license รองรับ

**โครงสร้างโฟลเดอร์** (วางคู่กับ `lab02_alu/` และ `lab03_seq/` เพราะใช้ RTL จากสอง Lab นั้น)

```text
labs/
├── lab02_alu/     vhdl/alu8.vhd  verilog/alu8.v  verilog/tb_alu8_dir.sv ...
├── lab03_seq/     verilog/seq_det_1011.v  verilog/traffic.v  verilog/tb_*_v.sv ...
└── lab04_verif/
    ├── gen_vectors.py
    ├── vectors/   alu_vectors.txt                 ← สร้างจาก gen_vectors.py
    ├── vhdl/      tb_alu8_file.vhd                ← 4A
    ├── sv/        tb_alu8_file_v.sv               ← 4A (ฝั่ง Verilog)
    │              tb_alu8_cls.sv                  ← 4B class + coverage
    │              seq_det_sva.sv  traffic_sva.sv  bind_sva.sv   ← 4B SVA
    ├── bugs/      alu8_bug1.v  alu8_bug2.v  alu8_bug3.v         ← 4C (ผู้สอนแจก)
    ├── run_4a.do  run_4b.do  run_4c.do
    └── reports/   log, ucdb, รายงาน coverage/assertion
```

**ชื่อที่ใช้ใน Lab นี้:** DUT คือ `alu8` จาก Lab 2 (พอร์ต `a, b, op, y, zero, carry, ovf`) และ testbench ภาษา SV ของ Lab 3 ชื่อ `tb_seq_det_v` / `tb_traffic_v` — ตัวอย่างใน Module 04 ที่ใช้ `alu` แบบมี generic N ให้เทียบเป็นชื่อเหล่านี้

### 4.0 — Verification plan ของ alu8 (การบ้านก่อนเข้า Lab)

เขียนตารางนี้เองก่อนเปิดดูเฉลย — ทุกแถวต้องตอบว่า "ตรวจอะไร ด้วยอะไร จบเมื่อไหร่" และคอลัมน์สุดท้ายบอกว่าส่วนไหนของ Lab ทำแถวนั้น

| # | Feature | วิธีตรวจ | เกณฑ์ผ่าน | ส่วน |
| --- | --- | --- | --- | --- |
| F1 | ผล y ทุก op | reference model อิสระ (Python / SV integer) | mismatch = 0 | 4A, 4B |
| F2 | flag carry, ovf (ADD/SUB) และ zero (ทุก op) | เทียบกับ model ทุกครั้ง | mismatch = 0 | 4A, 4B |
| F3 | `zero = 1` ก็ต่อเมื่อ `y = 0` | immediate assertion | assertion fail = 0 | 4B |
| F4 | เอาต์พุตไม่มี X/Z | immediate assertion `$isunknown` | assertion fail = 0 | 4B |
| F5 | ค่าขอบ 00, 7F, 80, FF ของ a และ b กับทุก op | cross coverage op × a, op × b | 100% | 4B |
| F6 | shift ทุกจำนวน 0–7 ทั้ง SLL/SRL และ b\[7:3\] ≠ 0 ต้องถูกเพิกเฉย | cross coverage + model | 100%, mismatch = 0 | 4B |
| F7 | carry × ovf ทุกคู่ของ ADD และ SUB | cross coverage | 8/8 bins | 4B |
| F8 | โค้ด RTL ถูกรันครบ | code coverage (statement, branch, condition, expression) | ≥ 95% หรืออธิบาย hole ทุกจุด | 4B |
| F9 | ผลเหมือนกันทั้ง RTL สองภาษา | golden vector ไฟล์เดียว | errors = 0 ทั้งคู่ | 4A |
| F10 | FSM ของ Lab 3 ทำตามกฎเชิงเวลา | SVA + cover property | fail = 0 และ cover ทุกตัว > 0 | 4B |

สังเกตว่าทุกแถวมี **เกณฑ์เป็นตัวเลข** ที่เครื่องมือวัดได้ — "ทดสอบให้ครบ" ไม่ใช่เกณฑ์ที่ใช้ได้ ตารางนี้คือสิ่งที่จะกลายเป็น coverpoint และ assertion ใน 4B แทบแถวต่อแถว

## 4A — Golden vector จาก Python + testbench อ่านไฟล์ (60 นาที, ModelSim)

แนวคิด: ย้าย "คำตอบที่ถูก" ออกจาก testbench ไปไว้ในไฟล์ที่สร้างด้วยภาษาอื่น — คนเขียน model คิดคนละวิธีกับคนเขียน RTL และไฟล์เดียวใช้ทดสอบ RTL ได้ทุกภาษา ทุก simulator และส่งต่อให้ทีมอื่นได้ (ในงานจริงไฟล์แบบนี้มักมาจาก model ของทีม algorithm ใน Python/MATLAB)

### ขั้นที่ 1 — กำหนดรูปแบบไฟล์ (5 นาที)

| field | ฐาน | ตัวอย่าง | หมายเหตุ |
| --- | --- | --- | --- |
| op | 10 | `1` | 0 = ADD … 7 = SLT ตามสเปก Lab 2 |
| a, b, y | 16 (2 หลัก) | `7F FF 80` |  |
| z c v | 2 (0/1) | `0 1 1` | ลำดับเดียวกับตาราง corner case ของ Lab 2 (zero, carry, ovf) |
| `#` นำหน้า | — | `# op a b y z c v` | คอมเมนต์ ข้ามได้ |

ตัวอย่าง 3 บรรทัดแรกของไฟล์ (คือแถว 1–3 ของตาราง Lab 2):

```text
# alu8 golden vectors  n=5000 seed=1
# op a  b  y  z c v
0 01 01 02 0 0 0
0 7F 01 80 0 0 1
0 FF 01 00 1 1 0
```

### ขั้นที่ 2 — เขียน `gen_vectors.py` ที่ตรวจตัวเองก่อน (20 นาที)

หลักสำคัญ 3 ข้อ: (1) model คำนวณด้วยจำนวนเต็มตามนิยาม ไม่ใช้สูตรบิตแบบ RTL (2) ก่อนเขียนไฟล์ model ต้องผ่านตาราง 19 แถวที่คำนวณด้วยมือใน Lab 2 ก่อน — golden ที่ผิดอันตรายกว่าไม่มี (3) กำหนด seed เสมอ ไฟล์เดิมต้องสร้างซ้ำได้ทุกครั้ง

`lab04_verif/gen_vectors.py`

```python
#!/usr/bin/env python3
"""gen_vectors.py — สร้าง golden vector ของ alu8 (Lab 2) สำหรับ Lab 4A

รูปแบบแต่ละบรรทัด:  op a b y z c v
  op = ฐาน 10 (0..7), a b y = ฐาน 16 สองหลัก, z c v = 0/1
บรรทัดที่ขึ้นต้นด้วย # คือคอมเมนต์
"""
import argparse
import random

OPS = ["ADD", "SUB", "AND", "OR", "XOR", "SLL", "SRL", "SLT"]


def to_signed(x):
    """0..255 -> -128..127"""
    return x - 256 if x >= 128 else x


def alu_ref(op, a, b):
    """คำนวณตามนิยามในสเปก ด้วยจำนวนเต็มของ Python (ไม่ใช้สูตรบิตแบบ RTL)"""
    sa, sb = to_signed(a), to_signed(b)
    c = v = 0
    if op == 0:                                   # ADD
        r = a + b
        y, c = r % 256, int(r > 255)
        v = int(not -128 <= sa + sb <= 127)
    elif op == 1:                                 # SUB: c = 1 เมื่อยืม (a < b)
        y, c = (a - b) % 256, int(a < b)
        v = int(not -128 <= sa - sb <= 127)
    elif op == 2:
        y = a & b
    elif op == 3:
        y = a | b
    elif op == 4:
        y = a ^ b
    elif op == 5:                                 # SLL ใช้ b[2:0]
        y = (a * 2 ** (b % 8)) % 256
    elif op == 6:                                 # SRL ใช้ b[2:0]
        y = a // 2 ** (b % 8)
    else:                                         # SLT แบบ signed
        y = int(sa < sb)
    return y, int(y == 0), c, v


# 19 แถวจากตาราง corner case ของ Lab 2 (op, a, b, y, z, c, v) — ใช้ตรวจตัว model เองด้วย
CORNER = [
    (0, 0x01, 0x01, 0x02, 0, 0, 0), (0, 0x7F, 0x01, 0x80, 0, 0, 1),
    (0, 0xFF, 0x01, 0x00, 1, 1, 0), (0, 0x80, 0x80, 0x00, 1, 1, 1),
    (1, 0x55, 0x55, 0x00, 1, 0, 0), (1, 0x00, 0x01, 0xFF, 0, 1, 0),
    (1, 0x80, 0x01, 0x7F, 0, 0, 1), (1, 0x7F, 0xFF, 0x80, 0, 1, 1),
    (2, 0xF0, 0x0F, 0x00, 1, 0, 0), (3, 0xF0, 0x0F, 0xFF, 0, 0, 0),
    (4, 0xAA, 0xFF, 0x55, 0, 0, 0), (5, 0x81, 0x01, 0x02, 0, 0, 0),
    (5, 0x01, 0x0F, 0x80, 0, 0, 0), (6, 0x80, 0x07, 0x01, 0, 0, 0),
    (6, 0x80, 0x08, 0x80, 0, 0, 0), (7, 0x80, 0x7F, 0x01, 0, 0, 0),
    (7, 0x7F, 0x80, 0x00, 1, 0, 0), (7, 0xFF, 0x00, 0x01, 0, 0, 0),
    (7, 0x05, 0x05, 0x00, 1, 0, 0),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-n", type=int, default=5000, help="จำนวน vector ทั้งหมด")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("-o", default="vectors/alu_vectors.txt")
    args = ap.parse_args()

    # 1) self-test: model ต้องตรงกับตารางที่คำนวณด้วยมือ
    for row in CORNER:
        op, a, b, *exp = row
        got = alu_ref(op, a, b)
        assert got == tuple(exp), f"model ผิดที่ {OPS[op]} {a:02X} {b:02X}: {got} != {exp}"

    # 2) corner ก่อน แล้วตามด้วยค่าสุ่ม (ค่าขอบ 30%)
    rng = random.Random(args.seed)
    edge = [0x00, 0x01, 0x7F, 0x80, 0xFE, 0xFF]
    def rand_byte():
        return rng.choice(edge) if rng.random() < 0.3 else rng.randrange(256)

    vecs = [row[:3] for row in CORNER]
    while len(vecs) < args.n:
        vecs.append((rng.randrange(8), rand_byte(), rand_byte()))

    with open(args.o, "w") as f:
        f.write(f"# alu8 golden vectors  n={args.n} seed={args.seed}\n")
        f.write("# op a  b  y  z c v\n")
        for op, a, b in vecs:
            y, z, c, v = alu_ref(op, a, b)
            f.write(f"{op} {a:02X} {b:02X} {y:02X} {z} {c} {v}\n")
    print(f"wrote {len(vecs)} vectors to {args.o} (seed={args.seed})")


if __name__ == "__main__":
    main()
```

รันในโฟลเดอร์ `lab04_verif/`:

```bash
mkdir -p vectors reports
python gen_vectors.py            # Windows: py gen_vectors.py
# wrote 5000 vectors to vectors/alu_vectors.txt (seed=1)
```

ไฟล์มี 5,002 บรรทัด (คอมเมนต์ 2 + vector 5,000) — 19 vector แรกคือตาราง Lab 2 ที่เหลือสุ่ม แต่ละ op ได้ประมาณ 600–640 ครั้ง ตรวจด้วยตาเปล่าสัก 2–3 บรรทัดก่อนใช้งาน (ตัวอย่าง: `7 80 01 01 0 0 0` → −128 < 1 จริง → y = 1)

> **ทำไมต้อง self-test:** ถ้า Python model ผิด เช่นเขียน SLT เป็น `a < b` (unsigned) ไฟล์จะ "สอน" ให้ RTL ผิดตาม — `assert` ทำให้สคริปต์หยุดทันทีพร้อมบอกแถวที่ผิด ลองแก้ SLT ให้ผิดดูแล้วรันอีกครั้ง

### ขั้นที่ 3 — เขียน testbench VHDL อ่านไฟล์ (20 นาที)

โครงของ loop: อ่าน 1 บรรทัด → ข้ามคอมเมนต์ → แยก 7 field พร้อมตรวจว่าอ่านได้ → ป้อน DUT → รอ 1 ns → เทียบทุกเอาต์พุต จบด้วยสรุปที่ตรวจว่า **อ่านครบ 5,000 vector จริง** (ไฟล์ว่างหรือถูกตัดก็ "ไม่มี error" เหมือนกัน)

`lab04_verif/vhdl/tb_alu8_file.vhd`

```vhdl
-- tb_alu8_file.vhd : อ่าน golden vector จากไฟล์ แล้วเทียบกับ alu8 ทุกเอาต์พุต
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_alu8_file is
  generic (
    VEC_FILE : string  := "vectors/alu_vectors.txt";
    N_EXP    : natural := 5000                 -- จำนวน vector ที่ต้องอ่านได้
  );
end entity;

architecture sim of tb_alu8_file is
  signal a, b, y          : std_logic_vector(7 downto 0) := (others => '0');
  signal op               : std_logic_vector(2 downto 0) := "000";
  signal zero, carry, ovf : std_logic;
  type int_arr_t is array (0 to 7) of natural;
begin
  dut : entity work.alu8
    port map (a => a, b => b, op => op, y => y, zero => zero, carry => carry, ovf => ovf);

  stim : process
    file     f                   : text;
    variable st                  : file_open_status;
    variable l                   : line;
    variable ok                  : boolean;
    variable line_no             : natural := 0;
    variable op_i                : integer;
    variable a_v, b_v, y_v       : std_logic_vector(7 downto 0);
    variable z_v, c_v, v_v       : std_logic;
    variable n, errors, bad_line : natural := 0;
    variable err_op              : int_arr_t := (others => 0);
  begin
    file_open(st, f, VEC_FILE, read_mode);
    assert st = open_ok
      report "cannot open " & VEC_FILE & " (check the working directory with pwd)"
      severity failure;

    while not endfile(f) loop
      readline(f, l);
      line_no := line_no + 1;
      next when l'length = 0;                      -- บรรทัดว่าง
      next when l(l'low) = '#';                    -- คอมเมนต์

      -- (1) อ่าน 7 field: op a b y z c v
      read(l, op_i, ok);
      if ok then hread(l, a_v, ok); end if;
      if ok then hread(l, b_v, ok); end if;
      if ok then hread(l, y_v, ok); end if;
      if ok then read(l, z_v, ok);  end if;
      if ok then read(l, c_v, ok);  end if;
      if ok then read(l, v_v, ok);  end if;
      if not ok or op_i < 0 or op_i > 7 then
        bad_line := bad_line + 1;
        report "bad format at line " & integer'image(line_no) severity error;
        next;
      end if;

      -- (2) ป้อนค่าให้ DUT แล้วรอให้ combinational logic นิ่ง
      op <= std_logic_vector(to_unsigned(op_i, 3));
      a  <= a_v;
      b  <= b_v;
      wait for 1 ns;
      n := n + 1;

      -- (3) เทียบทุกเอาต์พุต
      if y /= y_v or zero /= z_v or carry /= c_v or ovf /= v_v then
        errors := errors + 1;
        err_op(op_i) := err_op(op_i) + 1;
        if errors <= 10 then
          report "FAIL line " & integer'image(line_no) &
                 ": op=" & integer'image(op_i) & " a=" & to_hstring(a_v) & " b=" & to_hstring(b_v) &
                 "  got y=" & to_hstring(y) & " zcv=" & to_string(zero) & to_string(carry) & to_string(ovf) &
                 "  exp y=" & to_hstring(y_v) & " zcv=" & to_string(z_v) & to_string(c_v) & to_string(v_v)
            severity error;
        end if;
      end if;
    end loop;
    file_close(f);

    -- (4) สรุป
    report integer'image(n) & " vectors, " & integer'image(errors) & " errors, " &
           integer'image(bad_line) & " bad lines";
    for o in 0 to 7 loop
      if err_op(o) /= 0 then
        report "  op " & integer'image(o) & " : " & integer'image(err_op(o)) & " errors";
      end if;
    end loop;
    if errors = 0 and bad_line = 0 and n = N_EXP then
      report "*** PASS ***";
    else
      report "*** FAIL ***" severity error;
    end if;
    std.env.stop;
    wait;
  end process;
end architecture;
```

| จุดในโค้ด | ทำไม |
| --- | --- |
| `file_open(st, ...)` + `assert ... severity failure` | เปิดไฟล์ไม่ได้ = ทำต่อไม่ได้ → หยุดทันทีพร้อมบอกวิธีแก้ (แทนการประกาศ `file ... open read_mode` ที่ล้มเงียบ ๆ) |
| `read(l, x, ok)` แบบมี `ok` | บรรทัดผิดรูปแบบไม่ทำให้ simulator ล้ม แต่นับเป็น `bad_line` |
| `hread` กับ `std_logic_vector` | มีใน `ieee.std_logic_1164` ตั้งแต่ VHDL-2008 — ต้องคอมไพล์ด้วย `-2008` |
| `n = N_EXP` ในเงื่อนไข PASS | coverage แบบง่ายที่สุด: พิสูจน์ว่าตรวจครบจริง |
| นับ error แยกตาม op | บอกทิศการ debug ทันที (ใช้มากใน 4C) |

ถ้า RTL เป็น Verilog แต่ license ไม่รองรับ mixed-language ให้ใช้ testbench ภาษา SV ที่อ่าน**ไฟล์เดียวกัน** — ใช้ `$fgets` อ่านทีละบรรทัดแล้ว `$sscanf` แยก field (บรรทัดที่อ่านเลขตัวแรกไม่ได้ เช่นคอมเมนต์ จะถูกข้าม):

`lab04_verif/sv/tb_alu8_file_v.sv`

```systemverilog
// tb_alu8_file_v.sv : อ่าน golden vector ไฟล์เดียวกับ 4A (ใช้ได้กับ ModelSim ทุกรุ่น)
`timescale 1ns/1ps
module tb_alu8_file_v;
  parameter string VEC_FILE = "vectors/alu_vectors.txt";
  parameter int    N_EXP    = 5000;

  logic [7:0] a = '0, b = '0;
  logic [2:0] op = '0;
  wire  [7:0] y;
  wire        zero, carry, ovf;

  alu8 dut (.a, .b, .op, .y, .zero, .carry, .ovf);

  int fd, cnt, line_no = 0, n = 0, errors = 0, bad_line = 0;
  int op_i, a_i, b_i, y_i, z_i, c_i, v_i;
  reg [8*128:1] l;                                  // บัฟเฟอร์ 1 บรรทัด

  initial begin
    fd = $fopen(VEC_FILE, "r");
    if (fd == 0) $fatal(1, "cannot open %s (check the working directory with pwd)", VEC_FILE);

    while ($fgets(l, fd)) begin                       // อ่านทีละบรรทัด
      line_no++;
      cnt = $sscanf(l, "%d %h %h %h %d %d %d", op_i, a_i, b_i, y_i, z_i, c_i, v_i);
      if (cnt <= 0) begin
        // บรรทัดว่างหรือคอมเมนต์ (อ่านเลขตัวแรกไม่ได้) → ข้าม
      end else if (cnt != 7) begin
        bad_line++;
        $display("bad format at line %0d", line_no);
      end else begin
        op = op_i;  a = a_i;  b = b_i;
        #1;
        n++;
        if (y !== y_i[7:0] || zero !== z_i[0] || carry !== c_i[0] || ovf !== v_i[0]) begin
          errors++;
          if (errors <= 10)
            $display("FAIL line %0d: op=%0d a=%h b=%h  got y=%h zcv=%b%b%b  exp y=%h zcv=%0d%0d%0d",
                     line_no, op_i, a, b, y, zero, carry, ovf, y_i[7:0], z_i, c_i, v_i);
        end
      end
    end
    $fclose(fd);

    $display("%0d vectors, %0d errors, %0d bad lines", n, errors, bad_line);
    if (errors == 0 && bad_line == 0 && n == N_EXP) $display("*** PASS ***");
    else                                            $display("*** FAIL ***");
    $finish;
  end
endmodule
```

### ขั้นที่ 4 — รันกับ RTL ทั้งสองภาษา (10 นาที)

`lab04_verif/run_4a.do`

```tcl
# run_4a.do — ใช้งาน (อยู่ที่โฟลเดอร์ lab04_verif):
#   vsim -c -do "set RTL vhdl; do run_4a.do"                  ;# VHDL RTL + VHDL TB
#   vsim -c -do "set RTL verilog; do run_4a.do"               ;# Verilog RTL + SV TB
#   vsim -c -do "set RTL verilog; set TBL vhdl; do run_4a.do" ;# ข้ามภาษา (ต้องมี license)
onerror {quit -f -code 1}
if {![info exists RTL]} { set RTL vhdl }
if {![info exists TBL]} { if {$RTL eq "vhdl"} { set TBL vhdl } else { set TBL sv } }
file mkdir reports
if {[file exists work]} { vdel -lib work -all }
vlib work

if {$RTL eq "vhdl"} { vcom -2008 ../lab02_alu/vhdl/alu8.vhd } else { vlog ../lab02_alu/verilog/alu8.v }
if {$TBL eq "vhdl"} {
  vcom -2008 vhdl/tb_alu8_file.vhd;  set TOP tb_alu8_file
} else {
  vlog -sv sv/tb_alu8_file_v.sv;     set TOP tb_alu8_file_v
}
vsim -onfinish stop -l reports/4a_${RTL}_${TBL}.log work.$TOP
run -all
quit -f
```

ผลที่คาด (ทั้งสองภาษา):

```text
# ** Note: 5000 vectors, 0 errors, 0 bad lines
# ** Note: *** PASS ***
```

ไฟล์ vector อยู่ที่อื่นให้ override ตอน vsim: `vsim -gVEC_FILE=C:/labs/lab04_verif/vectors/alu_vectors.txt work.tb_alu8_file` (path เทียบกับโฟลเดอร์ที่รัน vsim เสมอ — ดูด้วย `pwd` ใน Transcript)

### ขั้นที่ 5 — พิสูจน์ว่า testbench "จับได้จริง" (5 นาที)

PASS ที่ไม่เคยเห็น FAIL เชื่อถือไม่ได้ ให้ทำ 2 การทดลองแล้วบันทึกผล:

1. **แก้คำตอบในไฟล์ 1 ค่า** — คัดลอกไฟล์เป็น `vectors/bad.txt` แก้บรรทัดที่ 100 จาก `2 77 5A 52 0 0 0` เป็น `2 77 5A 53 0 0 0` แล้วรันด้วย `-gVEC_FILE=vectors/bad.txt` ต้องเห็น:

```text
# ** Error: FAIL line 100: op=2 a=77 b=5A  got y=52 zcv=000  exp y=53 zcv=000
# ** Note: 5000 vectors, 1 errors, 0 bad lines
# ** Note:   op 2 : 1 errors
# ** Error: *** FAIL ***
```

2. **ชี้ไฟล์ผิด path** — `-gVEC_FILE=nofile.txt` ต้องหยุดทันทีด้วย `** Failure: cannot open nofile.txt (check the working directory with pwd)` ไม่ใช่ "0 vectors, 0 errors" — ถ้าเห็นแบบหลัง testbench มีช่องโหว่

✅ **Checkpoint 4A:** `gen_vectors.py` ผ่าน self-test, log `reports/4a_vhdl_vhdl.log` และ `reports/4a_verilog_sv.log` ขึ้น `5000 vectors, 0 errors` และทดลองทั้ง 2 ข้อในขั้นที่ 5 ได้ผลตามที่คาด

## 4B (ส่วนที่ 1) — Class-based testbench + functional coverage + code coverage (70 นาที, Questa)

### ขั้นที่ 1 — แปลง verification plan เป็น coverpoint (10 นาที)

ทุก coverpoint ต้องตอบได้ว่ามาจากแถวไหนของ plan — coverpoint ที่ไม่มีเจ้าของคืองานที่ไม่มีใครอ่าน และแถวใน plan ที่ไม่มี coverpoint คือสิ่งที่ไม่มีทางรู้ว่าทดสอบแล้ว

| plan | coverpoint / cross | bins | ความหมาย |
| --- | --- | --- | --- |
| F1, F5 | `cp_op` | 8 | ADD, SUB, AND/OR/XOR (แยก 3), SLL, SRL, SLT |
| F5 | `cp_a`, `cp_b` | 6 + 6 | 00, 7F, 80, FF, บวกอื่น ๆ, ลบอื่น ๆ |
| F5 | `x_op_a`, `x_op_b` | 48 + 48 | ทุก op กับทุกกลุ่มค่าของ a และ b |
| F6 | `x_shift` = `cp_shop` × `cp_shamt` | 16 | SLL/SRL × shift 0–7 |
| F6 | `cp_hib` | 2 | shift ที่ b\[7:3\] = 0 และ ≠ 0 (บิตบนต้องถูกเพิกเฉย) |
| F7 | `x_flags` = `cp_arith` × `cp_c` × `cp_v` | 8 | ADD/SUB × carry × ovf ทุกคู่ |
| F2 | `cp_z` | 2 | ผลเป็น 0 และไม่เป็น 0 |

ตัวเลข functional coverage รวม = ค่าเฉลี่ยของทุก coverpoint และ cross (น้ำหนักเท่ากันโดยค่าเริ่มต้น) จะเป็น 100% เมื่อทุก bin ถูกชนอย่างน้อย 1 ครั้ง

### ขั้นที่ 2 — เขียน `tb_alu8_cls.sv` (30 นาที)

Testbench มี 4 ส่วนตามสถาปัตยกรรมใน Module 04 หัวข้อ 4.1: (1) transaction class (2) covergroup (3) reference model (4) driver + checker + coverage ใน task เดียว

`lab04_verif/sv/tb_alu8_cls.sv`

```systemverilog
// tb_alu8_cls.sv : class-based constrained-random TB + functional coverage (Questa)
`timescale 1ns/1ps
module tb_alu8_cls;
  logic [7:0] a = '0, b = '0;
  logic [2:0] op = '0;
  wire  [7:0] y;
  wire        zero, carry, ovf;
  int n = 0, errors = 0, max_n = 20000;

  alu8 dut (.a, .b, .op, .y, .zero, .carry, .ovf);

  // ---------- (1) transaction: สิ่งที่สุ่ม + กฎการสุ่ม ----------
  class alu_txn;
    rand  bit [7:0] a, b;
    randc bit [2:0] op;                     // randc: ครบทั้ง 8 op ก่อนจะซ้ำ
    // ค่าขอบ 4 ค่า น้ำหนักค่าละ 5 (รวม 20%), ที่เหลือแบ่งเท่า ๆ กันในช่วงบวก/ลบ
    constraint c_edge_a { a dist { 8'h00 := 5, 8'h7F := 5, 8'h80 := 5, 8'hFF := 5,
                                   [8'h01:8'h7E] :/ 40, [8'h81:8'hFE] :/ 40 }; }
    constraint c_edge_b { b dist { 8'h00 := 5, 8'h7F := 5, 8'h80 := 5, 8'hFF := 5,
                                   [8'h01:8'h7E] :/ 40, [8'h81:8'hFE] :/ 40 }; }
    function string str();
      return $sformatf("op=%0d a=%h b=%h", op, a, b);
    endfunction
  endclass

  // ---------- (2) functional coverage: แปลงจาก verification plan ----------
  covergroup cg_alu with function sample(bit [2:0] s_op, bit [7:0] s_a, s_b,
                                         bit s_z, s_c, s_v);
    option.per_instance = 1;
    cp_op    : coverpoint s_op { bins add = {0}; bins sub = {1}; bins logic_ops[] = {[2:4]};
                                 bins sll = {5}; bins srl = {6}; bins slt = {7}; }
    cp_a     : coverpoint s_a  { bins x00 = {8'h00}; bins x7F = {8'h7F}; bins x80 = {8'h80};
                                 bins xFF = {8'hFF}; bins pos = {[8'h01:8'h7E]};
                                 bins neg = {[8'h81:8'hFE]}; }
    cp_b     : coverpoint s_b  { bins x00 = {8'h00}; bins x7F = {8'h7F}; bins x80 = {8'h80};
                                 bins xFF = {8'hFF}; bins pos = {[8'h01:8'h7E]};
                                 bins neg = {[8'h81:8'hFE]}; }
    // shift: ทุกจำนวนบิต 0..7 ของทั้ง SLL และ SRL และกรณีที่ b[7:3] ไม่เป็น 0
    cp_shop  : coverpoint s_op iff (s_op inside {5, 6}) { bins sll = {5}; bins srl = {6}; }
    cp_shamt : coverpoint s_b[2:0] iff (s_op inside {5, 6}) { bins sh[] = {[0:7]}; }
    cp_hib   : coverpoint (s_b[7:3] != 0) iff (s_op inside {5, 6})
                                { bins lo_only = {0}; bins hi_set = {1}; }
    // flag: ทุกคู่ carry × ovf ของ ADD และ SUB
    cp_arith : coverpoint s_op iff (s_op inside {0, 1}) { bins add = {0}; bins sub = {1}; }
    cp_c     : coverpoint s_c  iff (s_op inside {0, 1});
    cp_v     : coverpoint s_v  iff (s_op inside {0, 1});
    cp_z     : coverpoint s_z;
    x_op_a   : cross cp_op, cp_a;               // 8 × 6 = 48 bins
    x_op_b   : cross cp_op, cp_b;               // 8 × 6 = 48 bins
    x_shift  : cross cp_shop, cp_shamt;         // 2 × 8 = 16 bins
    x_flags  : cross cp_arith, cp_c, cp_v;      // 2 × 2 × 2 = 8 bins
  endgroup

  // ---------- (3) reference model: integer ตามนิยาม (เหมือน Lab 2D) ----------
  function automatic logic [10:0] ref_alu(input logic [2:0] f_op, input logic [7:0] f_a, f_b);
    int ua, ub, sa, sb, r;
    logic [7:0] ry;
    logic rc, rv;
    ua = f_a;  ub = f_b;  sa = $signed(f_a);  sb = $signed(f_b);
    rc = 1'b0; rv = 1'b0;
    case (f_op)
      3'd0: begin r = ua + ub; ry = r[7:0]; rc = (r > 255);
                  rv = (sa + sb > 127) || (sa + sb < -128); end
      3'd1: begin r = ua - ub; ry = r[7:0]; rc = (ua < ub);
                  rv = (sa - sb > 127) || (sa - sb < -128); end
      3'd2: ry = f_a & f_b;
      3'd3: ry = f_a | f_b;
      3'd4: ry = f_a ^ f_b;
      3'd5: ry = f_a << f_b[2:0];
      3'd6: ry = f_a >> f_b[2:0];
      default: ry = (sa < sb) ? 8'd1 : 8'd0;
    endcase
    return {ry, (ry == 8'd0), rc, rv};
  endfunction

  cg_alu  cov = new();
  alu_txn t   = new();

  // ---------- (4) driver + checker (scoreboard) + coverage ----------
  task automatic apply(input logic [2:0] t_op, input logic [7:0] t_a, t_b);
    logic [10:0] exp_v, got_v;
    op = t_op;  a = t_a;  b = t_b;
    #1;
    exp_v = ref_alu(t_op, t_a, t_b);
    got_v = {y, zero, carry, ovf};
    n++;
    // immediate assertion: ตรวจกฎภายในที่ไม่ต้องพึ่ง model
    a_known: assert (!$isunknown(got_v)) else $error("X/Z on outputs: %b", got_v);
    a_zero:  assert (zero == (y == 8'h00)) else $error("zero flag inconsistent: y=%h zero=%b", y, zero);
    if (got_v !== exp_v) begin
      errors++;
      if (errors <= 10)
        $error("op=%0d a=%h b=%h : got y=%h zcv=%b  exp y=%h zcv=%b",
               t_op, t_a, t_b, got_v[10:3], got_v[2:0], exp_v[10:3], exp_v[2:0]);
    end
    // เก็บ coverage จากค่าที่ "ควรเป็น" (model) ไม่ใช่จาก DUT ที่อาจมี bug
    cov.sample(t_op, t_a, t_b, exp_v[2], exp_v[1], exp_v[0]);
  endtask

  initial begin
    void'($value$plusargs("MAX=%d", max_n));
    if ($test$plusargs("NOEDGE")) begin                 // ทดลอง: ปิดการเน้นค่าขอบ
      t.c_edge_a.constraint_mode(0);
      t.c_edge_b.constraint_mode(0);
      $display("edge constraints OFF");
    end

    // phase 1: directed — กรณีที่ต้องเห็นแน่ ๆ ตั้งแต่ต้น
    apply(3'd0, 8'h7F, 8'h01);  apply(3'd0, 8'h80, 8'h80);
    apply(3'd1, 8'h00, 8'h01);  apply(3'd1, 8'h7F, 8'hFF);
    apply(3'd7, 8'h7F, 8'h80);  apply(3'd6, 8'h80, 8'h08);

    // phase 2: constrained random จน functional coverage = 100% (หรือครบ max_n)
    while (cov.get_inst_coverage() < 100.0 && n < max_n) begin
      if (!t.randomize()) $fatal(1, "randomize failed");
      apply(t.op, t.a, t.b);
    end

    $display("tests=%0d errors=%0d functional coverage=%0.2f%%",
             n, errors, cov.get_inst_coverage());
    $display("  x_op_a=%0.1f%% x_op_b=%0.1f%% x_shift=%0.1f%% x_flags=%0.1f%%",
             cov.x_op_a.get_inst_coverage(), cov.x_op_b.get_inst_coverage(),
             cov.x_shift.get_inst_coverage(), cov.x_flags.get_inst_coverage());
    if (errors == 0 && cov.get_inst_coverage() == 100.0) $display("*** PASS ***");
    else                                                  $display("*** FAIL ***");
    $finish;
  end
endmodule
```

**การตัดสินใจออกแบบที่ควรอธิบายในชั้นเรียน**

| จุด | เหตุผล |
| --- | --- |
| ไม่มี constraint `b < 8` สำหรับ shift (ต่างจากตัวอย่างใน 4.3) | สเปกบอกว่าใช้ b\[2:0\] แปลว่า b ≥ 8 เป็นอินพุตที่ถูกต้อง ต้องทดสอบ (แถว 15 ของ Lab 2) — constraint ที่แคบเกินสเปกคือการซ่อน bug ด้วยมือเราเอง จึงมี `cp_hib` พิสูจน์แทน |
| `randc` กับ op | ทุก 8 transaction ได้ op ครบ 8 ค่า — ไม่มี op ไหนถูกทิ้งนาน |
| `dist` เน้นค่าขอบ 20% | ถ้าสุ่มเท่า ๆ กัน ค่า 7F มีโอกาส 1/256 — ดูผลในขั้นที่ 5 |
| `sample()` ใช้ค่า flag จาก model | coverage วัด "สถานการณ์ที่เกิด" — ถ้าใช้ค่าจาก DUT ที่มี bug bin อาจถูกนับผิด |
| immediate assertion `a_zero` | ตรวจความสอดคล้องภายใน DUT โดยไม่พึ่ง model — ยังทำงานแม้ model ผิด |
| หยุดเมื่อ coverage = 100% หรือครบ `max_n` | เป็น coverage-driven loop แทนการเดาจำนวน และ `max_n` กัน loop ไม่รู้จบเมื่อมี bin ที่เกิดไม่ได้ |

### ขั้นที่ 3 — คอมไพล์พร้อม code coverage และรันหลาย seed (15 นาที)

```tcl
# ส่วนแรกของ run_4b.do — อยู่ที่ lab04_verif/
onerror {quit -f -code 1}
file mkdir reports
if {[file exists work]} { vdel -lib work -all }
vlib work
vlog +cover=bcesf ../lab02_alu/verilog/alu8.v      ;# เก็บ code coverage เฉพาะ RTL
vlog -sv sv/tb_alu8_cls.sv                         ;# testbench ไม่ต้องเก็บ

foreach s {1 2 3} {
  vsim -coverage -onfinish stop -sv_seed $s work.tb_alu8_cls
  run -all
  coverage save reports/alu_s$s.ucdb
  quit -sim
}
vcover merge reports/alu_merged.ucdb reports/alu_s1.ucdb reports/alu_s2.ucdb reports/alu_s3.ucdb
vcover report -details -output reports/cov_alu.txt reports/alu_merged.ucdb
vcover report -html -output reports/covhtml reports/alu_merged.ucdb
```

ผลที่คาดต่อ 1 seed (จำนวน tests ต่างกันตาม seed และ solver ของ simulator):

```text
# tests=... errors=0 functional coverage=100.00%
#   x_op_a=100.0% x_op_b=100.0% x_shift=100.0% x_flags=100.0%
# *** PASS ***
```

ผู้สอนประมาณจำนวน tests ได้จากการจำลองการสุ่มแบบเดียวกัน 200 seed: มัธยฐานราว 700 ครั้ง (ช่วง \~400–1,600) — bin ที่ปิดช้าสุดมักเป็น cross ของ op กับค่าขอบ เช่น `<slt, x7F>`

### ขั้นที่ 4 — อ่านรายงาน coverage และจัดการ hole (10 นาที)

เปิด `reports/covhtml/index.html` หรือใน GUI: View → Coverage → Code Coverage Analysis / Covergroups

| สิ่งที่น่าจะเห็น | สาเหตุ | ทำอย่างไร |
| --- | --- | --- |
| Branch `default: ;` ของ `case (op)` ไม่เคยถูกเลือก | op มี 3 บิต ครบทุกค่า จะเข้า default ได้เฉพาะเมื่อ op เป็น X ซึ่ง testbench ไม่ป้อน | exclude พร้อมเหตุผล "unreachable: op fully decoded" |
| condition/expression บางตัวไม่ครบ 100% | เงื่อนไขย่อยบางคู่ไม่เคยเป็นตัวตัดสินผล | อ่านตารางในรายงานว่าขาดกรณีไหน แล้วเพิ่ม directed test หรืออธิบาย |
| covergroup ครบ 100% แต่ code coverage ไม่ครบ (หรือกลับกัน) | สองตัววัดคนละมุม: สเปก vs โค้ด | ต้องผ่านทั้งคู่ — ดูคำถามท้าย Lab ข้อ 3 |

วิธี exclude ที่เห็นชัดที่สุดคือ pragma ใน RTL (อยู่ติดกับโค้ด คนอ่านเห็นเหตุผล):

```verilog
      // coverage off
      default: ;                    // unreachable: op 3 บิตถูก decode ครบทุกค่า
      // coverage on
```

หรือใน GUI คลิกขวาที่ item ใน Code Coverage Analysis → Exclude แล้วบันทึกคำอธิบาย — **ทุก exclusion ต้องมีเหตุผลเขียนไว้** ไม่เช่นนั้น exclude กลายเป็นทางลัดให้ตัวเลขสวย

### ขั้นที่ 5 — ทดลอง: ปิดการเน้นค่าขอบ (5 นาที)

```tcl
vsim -c -sv_seed 1 work.tb_alu8_cls +NOEDGE +MAX=50000 -do "run -all; quit -f"
```

จดจำนวน tests เทียบกับขั้นที่ 3 สำหรับ seed เดียวกัน — การจำลองของผู้สอนได้มัธยฐานราว 9,000 ครั้ง (บาง seed เกิน 20,000 ซึ่งจะ FAIL ถ้าใช้ `max_n` เดิม) คือช้ากว่าราว 10 เท่า เพราะค่าเดี่ยว เช่น 7F มีโอกาสเพียง 1/256 — นี่คือเหตุผลที่ constrained random ต้องเน้นค่าขอบ

✅ **Checkpoint 4B-1:** 3 seed PASS, `reports/cov_alu.txt` แสดง functional coverage 100% และ code coverage ≥ 95% (หรือมี exclusion พร้อมเหตุผล) และบันทึกผลการทดลอง +NOEDGE

## 4B (ส่วนที่ 2) — SVA และ bind กับวงจรของ Lab 3 (50 นาที, Questa)

ใน Lab 3 กฎเชิงเวลาอยู่ใน testbench — ใช้ได้เฉพาะ testbench ตัวนั้น ส่วนนี้ย้ายกฎไปเป็น SVA ที่ **ติดอยู่กับ DUT** ด้วย `bind` จึงตรวจทุกครั้งที่ DUT ถูกจำลอง ไม่ว่าจะใช้ testbench ไหน หรือเอาไปใส่ในระบบใหญ่ก็ตาม และไม่ต้องแก้ RTL แม้บรรทัดเดียว

### ขั้นที่ 1 — แปลงกฎเป็น property (10 นาที)

| กฎ (จาก Lab 3) | property | ชนิด |
| --- | --- | --- |
| เห็น 1011 → ต้อง detected | `din ##1 !din ##1 din ##1 din \|=> detected` | ลำดับหลาย clock |
| detected → ต้องเคยเห็น 1011 จริง | `detected \|-> $past(din,4) && !$past(din,3) && $past(din,2) && $past(din,1)` | มองย้อนหลัง |
| detected กว้าง 1 clock | `detected \|=> !detected` | clock ถัดไป |
| ไม่เขียวพร้อมกัน / มีไฟแดง / one-hot | `!(ns[0] && ew[0])`, `ns[2] \|\| ew[2]`, `$onehot(...)` | invariant ทุก clock |
| เขียว → เหลือง → แดง | `$fell(ns[0]) \|-> ns[1]` ฯลฯ | ตอนเปลี่ยนสี |
| เขียวนาน T\_GREEN tick | `$fell(ns[0]) \|-> ns_g_t == T_GREEN` + ตัวนับช่วย | เวลา |

**อ่านเวลาใน SVA ให้ถูก:** ทุกค่าใน property คือค่าที่ *sample ที่ขอบขาขึ้น* (ก่อน DUT อัปเดตในขอบนั้น) ตัวอย่างลำดับ 1011 ที่เริ่มที่ขอบ t:

| ขอบ | din ที่ sample | state หลังขอบ | detected ที่ sample | ในมุมของ a\_no\_false ที่ขอบ t+4 |
| --- | --- | --- | --- | --- |
| t | 1 | S1 | 0 | `$past(din,4)` |
| t+1 | 0 | S10 | 0 | `$past(din,3)` |
| t+2 | 1 | S101 | 0 | `$past(din,2)` |
| t+3 | 1 | S1011 | 0 | `$past(din,1)` |
| t+4 | — | — | **1** | detected = 1 → ตรวจ 4 ค่าด้านบน |

`a_detect` เริ่มที่ขอบ t, จบลำดับที่ t+3 แล้ว `|=>` ตรวจ detected ที่ t+4 — ตรงกับ Moore ที่ detected สูงหลังรับบิตสุดท้าย 1 clock

### ขั้นที่ 2 — เขียน checker ของ sequence detector (10 นาที)

`lab04_verif/sv/seq_det_sva.sv`

```systemverilog
// seq_det_sva.sv : กฎของ seq_det_1011 (Lab 3B) เขียนเป็น SVA — ไม่แตะ RTL
module seq_det_sva (input logic clk, rst_n, din, detected);
  default clocking cb @(posedge clk); endclocking
  default disable iff (!rst_n);                 // ไม่ตรวจระหว่าง reset

  // A1 ไม่พลาด: เห็น 1-0-1-1 ติดกัน → clock ถัดไป detected ต้องเป็น 1
  a_detect : assert property (din ##1 !din ##1 din ##1 din |=> detected)
    else $error("missed 1011");

  // A2 ไม่ตรวจเกิน: detected = 1 → 4 บิตก่อนหน้าต้องเป็น 1,0,1,1
  a_no_false : assert property (detected |-> $past(din, 4) && !$past(din, 3) &&
                                             $past(din, 2) &&  $past(din, 1))
    else $error("detected without 1011");

  // A3 detected เป็นพัลส์ 1 clock (1011 สองชุดใกล้ที่สุดห่างกัน 3 clock)
  a_pulse : assert property (detected |=> !detected)
    else $error("detected longer than 1 clock");

  // A4 ไม่มี X/Z หลัง reset
  a_known : assert property (!$isunknown(detected))
    else $error("detected is X/Z");

  // A5 reset ต้องล้าง: ไม่ใช้ default disable (เขียน disable iff เองให้ไม่ปิดตอน reset)
  a_reset : assert property (disable iff (1'b0) !rst_n |=> !detected)
    else $error("detected not cleared by reset");

  // cover: พิสูจน์ว่า antecedent เกิดจริง (กัน vacuous pass)
  c_detect  : cover property (detected);
  c_overlap : cover property (detected ##3 detected);   // 1011011
endmodule
```

| จุด | คำอธิบาย |
| --- | --- |
| `default clocking` / `default disable iff` | ไม่ต้องเขียน `@(posedge clk) disable iff (!rst_n)` ซ้ำทุก property |
| A1 กับ A2 คู่กัน | A1 จับ "พลาด" A2 จับ "ตรวจเกิน" — สองทิศรวมกัน = detected ตรงสเปกพอดี |
| A5 ใช้ `disable iff (1'b0)` | ต้องตรวจ**ตอน** reset จึง override default ที่ปิดการตรวจระหว่าง reset |
| `c_overlap` | พิสูจน์ว่า testbench สร้างกรณี overlap จริง ถ้าเป็น 0 แปลว่ากฎ overlap ไม่เคยถูกทดสอบ |

### ขั้นที่ 3 — เขียน checker ของไฟจราจร (15 นาที)

กฎเรื่องเวลา "เขียวนาน T\_GREEN tick" เขียนเป็น sequence ล้วนได้ยากเพราะ tick ไม่ได้มาทุก clock จึงใช้เทคนิคมาตรฐาน: **ตัวนับช่วย (auxiliary logic)** ใน checker นับ tick ระหว่างไฟสีนั้น แล้ว assertion เทียบค่าตอนไฟดับ

`lab04_verif/sv/traffic_sva.sv`

```systemverilog
// traffic_sva.sv : กฎความปลอดภัยและเวลาของไฟจราจร (Lab 3C) เป็น SVA
module traffic_sva #(parameter int T_GREEN = 5, parameter int T_YELLOW = 2) (
  input logic       clk, rst_n, tick,
  input logic [2:0] ns_light, ew_light           // {R, Y, G}
);
  default clocking cb @(posedge clk); endclocking
  default disable iff (!rst_n);

  // ---- ความปลอดภัย: ตรวจทุก clock ----
  a_no_two_green : assert property (!(ns_light[0] && ew_light[0]))
    else $error("both directions green");
  a_one_red      : assert property (ns_light[2] || ew_light[2])
    else $error("no red light");
  a_onehot       : assert property ($onehot(ns_light) && $onehot(ew_light))
    else $error("light not one-hot: ns=%b ew=%b", ns_light, ew_light);

  // ---- ลำดับสี: เขียว → เหลือง → แดง ----
  a_ns_g2y : assert property ($fell(ns_light[0]) |-> ns_light[1]) else $error("NS green -> not yellow");
  a_ns_y2r : assert property ($fell(ns_light[1]) |-> ns_light[2]) else $error("NS yellow -> not red");
  a_ew_g2y : assert property ($fell(ew_light[0]) |-> ew_light[1]) else $error("EW green -> not yellow");
  a_ew_y2r : assert property ($fell(ew_light[1]) |-> ew_light[2]) else $error("EW yellow -> not red");

  // ---- เวลา: นับ tick ระหว่างไฟสีนั้นด้วยตัวนับช่วย (auxiliary logic) ----
  int ns_g_t, ns_y_t, ew_g_t, ew_y_t;
  always @(posedge clk) begin
    ns_g_t <= (!rst_n || !ns_light[0]) ? 0 : ns_g_t + tick;
    ns_y_t <= (!rst_n || !ns_light[1]) ? 0 : ns_y_t + tick;
    ew_g_t <= (!rst_n || !ew_light[0]) ? 0 : ew_g_t + tick;
    ew_y_t <= (!rst_n || !ew_light[1]) ? 0 : ew_y_t + tick;
  end
  a_ns_g_len : assert property ($fell(ns_light[0]) |-> ns_g_t == T_GREEN)
    else $error("NS green lasted %0d ticks (expect %0d)", $sampled(ns_g_t), T_GREEN);
  a_ns_y_len : assert property ($fell(ns_light[1]) |-> ns_y_t == T_YELLOW)
    else $error("NS yellow lasted %0d ticks (expect %0d)", $sampled(ns_y_t), T_YELLOW);
  a_ew_g_len : assert property ($fell(ew_light[0]) |-> ew_g_t == T_GREEN)
    else $error("EW green lasted %0d ticks (expect %0d)", $sampled(ew_g_t), T_GREEN);
  a_ew_y_len : assert property ($fell(ew_light[1]) |-> ew_y_t == T_YELLOW)
    else $error("EW yellow lasted %0d ticks (expect %0d)", $sampled(ew_y_t), T_YELLOW);

  // ---- cover ----
  c_ns_green_end : cover property ($fell(ns_light[0]));
  c_ew_green_end : cover property ($fell(ew_light[0]));
  c_full_cycle   : cover property ($rose(ns_light[0]));   // ครบรอบ EW_Y → NS_G
endmodule
```

จังหวะของตัวนับช่วย: ที่ขอบสุดท้ายของไฟเขียว (tick ที่ T\_GREEN) `ns_g_t` ถูกบวกเป็น T\_GREEN ขอบถัดมา `$fell(ns_light[0])` เป็นจริงและ property อ่าน `ns_g_t` ค่าที่ sample ก่อนตัวนับถูกล้าง = T\_GREEN พอดี — ใช้ได้ทุกค่า K เพราะนับ tick ไม่ใช่ clock (ในข้อความ error ใช้ `$sampled()` ให้พิมพ์ค่าเดียวกับที่ property ใช้ตัดสิน)

### ขั้นที่ 4 — bind และรัน (10 นาที)

`lab04_verif/sv/bind_sva.sv`

```systemverilog
// bind_sva.sv : ผูก checker เข้ากับ "ทุก instance" ของ DUT โดยไม่แก้ RTL และไม่แก้ testbench
// โหลดเป็น top ตัวที่สองตอน vsim:  vsim work.tb_xxx work.bind_sva
module bind_sva;
  bind seq_det_1011 seq_det_sva u_sva (
    .clk(clk), .rst_n(rst_n), .din(din), .detected(detected));

  bind traffic traffic_sva #(.T_GREEN(T_GREEN), .T_YELLOW(T_YELLOW)) u_sva (
    .clk(clk), .rst_n(rst_n), .tick(tick), .ns_light(ns_light), .ew_light(ew_light));
endmodule
```

ชื่อในวงเล็บ (`clk`, `T_GREEN`, …) คือชื่อ**ภายใน DUT** — bind ส่ง parameter ของ DUT ต่อให้ checker ได้ จึงรัน `-gT_GREEN=3` แล้ว checker ปรับตามเอง ใน Lab นี้ใช้ RTL ภาษา Verilog (bind เข้า entity VHDL ก็ทำได้ใน Questa แต่มีเงื่อนไขเรื่องชนิดสัญญาณ ให้ดูคู่มือ Questa)

```tcl
# ส่วนที่สองของ run_4b.do — SVA กับวงจร Lab 3 (Verilog RTL + SV testbench เดิม)
vlog ../lab03_seq/verilog/seq_det_1011.v ../lab03_seq/verilog/traffic.v
vlog -sv sv/seq_det_sva.sv sv/traffic_sva.sv sv/bind_sva.sv
vlog -sv ../lab03_seq/verilog/tb_seq_det_v.sv ../lab03_seq/verilog/tb_traffic_v.sv

foreach top {tb_seq_det_v tb_traffic_v} {
  vsim -assertdebug -onfinish stop -l reports/4b_sva_$top.log work.$top work.bind_sva
  run -all
  assertion report -recursive /*                 ;# pass/fail ของทุก assertion
  quit -sim
}
# ซ้ำกับ tick ทุก 3 clock: checker ต้องยังผ่าน
vsim -assertdebug -onfinish stop -gK=3 work.tb_traffic_v work.bind_sva
run -all
assertion report -recursive /*
quit -sim
```

ผลที่คาด: testbench เดิมยังพิมพ์ `*** PASS ***` ไม่มี `** Error` จาก assertion และใน `assertion report` ทุกตัว Failure Count = 0 จากนั้นเปิด GUI ดู View → Coverage → Cover Directives: `c_detect`, `c_overlap`, `c_ns_green_end`, `c_ew_green_end`, `c_full_cycle` ต้องมีจำนวนครั้ง > 0 ทุกตัว — ถ้าตัวไหนเป็น 0 assertion ที่เกี่ยวข้องผ่านแบบ vacuous (ไม่เคยถูกตรวจจริง)

### ขั้นที่ 5 — พิสูจน์ว่า assertion จับได้จริง (5 นาที)

ใส่บั๊กจาก Lab 3 ทีละตัวใน RTL Verilog แล้วรันส่วนที่สองซ้ำ:

| บั๊ก (Lab 3) | assertion ที่ควร fail ก่อน | ข้อความ |
| --- | --- | --- |
| B3 detected จาก `next_state` | `a_no_false` (และ `a_detect`) | `detected without 1011` |
| C1 เหลืองใช้เวลาเขียว | `a_ns_y_len` | `NS yellow lasted 5 ticks (expect 2)` |
| C4 ข้ามไฟเหลือง (EW\_G → NS\_G) | `a_ew_g2y` | `EW green -> not yellow` |

สังเกตว่า assertion บอก**ชื่อกฎและเวลา**ที่ผิดทันที ใน Wave จะเห็นสามเหลี่ยมสีแดงตรงจุดนั้น และ `-assertdebug` ให้ดับเบิลคลิกดูว่า sub-expression ไหนเป็นเท็จ — เทียบกับ testbench ที่บอกแค่ `FAIL` ตอนจบ แล้วต้องไล่ย้อนหาสาเหตุเอง

✅ **Checkpoint 4B-2:** ทั้ง 3 การรัน (seq\_det, traffic, traffic K = 3) ไม่มี assertion fail, cover ทุกตัว > 0 และบั๊ก 3 ตัวในตารางทำให้ assertion ที่คาดไว้ fail จริง

## 4C — Bug hunt: ALU 3 ตัวที่ฝัง bug (60 นาที, ModelSim / Questa)

**กติกา:** ผู้สอนแจก `bugs/alu8_bug1.v` – `alu8_bug3.v` (ชื่อ module ยังเป็น `alu8` แต่ละไฟล์มี bug 1 จุด) ผู้เรียน**ห้ามเปิดอ่านโค้ดก่อน** — ต้องระบุ bug จากอาการที่ testbench รายงานก่อน แล้วค่อยเปิดโค้ดยืนยัน เหมือนงานจริงที่ verification engineer ได้รับ RTL ใหม่ทุกสัปดาห์

### ขั้นที่ 1 — รัน testbench ทุกตัวกับทุกไฟล์ (15 นาที)

ใช้ testbench ภาษา SV ทั้งหมดเพราะ bug เป็น Verilog (ไม่ต้องใช้ license mixed-language) ตัว class + coverage รันเฉพาะเมื่อใช้ Questa

`lab04_verif/run_4c.do`

```tcl
# run_4c.do — ใช้งาน: vsim -c -do "do run_4c.do"   (Questa: set CLS 1 ก่อน do)
onerror {quit -f -code 1}
if {![info exists CLS]} { set CLS 0 }
file mkdir reports
set TBS {../lab02_alu/verilog/tb_alu8_dir.sv ../lab02_alu/verilog/tb_alu8_exh.sv sv/tb_alu8_file_v.sv}
set TOPS {tb_alu8_dir tb_alu8_exh tb_alu8_file_v}
if {$CLS} { lappend TBS sv/tb_alu8_cls.sv;  lappend TOPS tb_alu8_cls }

foreach dut {../lab02_alu/verilog/alu8.v bugs/alu8_bug1.v bugs/alu8_bug2.v bugs/alu8_bug3.v} {
  set tag [file rootname [file tail $dut]]
  if {[file exists work]} { vdel -lib work -all }
  vlib work
  vlog $dut
  foreach tb $TBS { vlog -sv $tb }
  foreach top $TOPS {
    vsim -onfinish stop -sv_seed 1 -l reports/4c_${tag}_${top}.log work.$top
    run -all
    quit -sim
  }
}
quit -f
```

สรุปผลจาก log ด้วยคำสั่งเดียว (Git Bash / WSL / Linux):

```bash
for f in reports/4c_*.log; do
  printf "%-42s %s\n" "$(basename $f .log)" "$(grep -oE '\*\*\* (PASS|FAIL)[^*]*\*\*\*' $f | tail -1)"
done
```

แถวของ `alu8` ตัวจริงต้อง PASS ทุก testbench — เป็นการยืนยันว่าผล FAIL มาจาก bug ไม่ใช่จาก testbench เอง

### ขั้นที่ 2 — กรอกตารางอาการ (10 นาที)

| ไฟล์ | Directed (19 แถว) | Exhaustive (524,288) | Golden file (5,000) | Class + coverage | op ที่ผิด / อาการ |
| --- | --- | --- | --- | --- | --- |
| alu8\_bug1.v |  |  |  |  |  |
| alu8\_bug2.v |  |  |  |  |  |
| alu8\_bug3.v |  |  |  |  |  |

### ขั้นที่ 3 — สืบจากอาการไปหาต้นตอ (25 นาที)

ใช้คำถามนำทางตามลำดับ และจดคำตอบทุกข้อก่อนเปิดโค้ด:

1. **op ไหนผิด?** — ดูบรรทัด `op N : x errors` ของ exhaustive ถ้าผิดหลาย op พร้อมกัน ให้หาสัญญาณที่ op เหล่านั้นใช้ร่วมกันใน block diagram ของ Lab 2
2. **เอาต์พุตไหนผิด?** — เทียบ `got` กับ `exp` ทีละ field: y ผิด หรือแค่ flag ผิด
3. **ผิดเมื่อไหร่?** — หารูปแบบของอินพุตที่ผิด เช่น เครื่องหมายของ a กับ b, ค่า b\[2:0\] — ถ้า 10 บรรทัดแรกไม่พอ แก้ `errors <= 10` ใน testbench เป็น 100 แล้วจัดกลุ่ม
4. **ทำไม testbench บางตัวไม่เห็น?** — เทียบกรณีที่ผิดกับกรณีที่ testbench นั้นทดสอบจริง (ตาราง 19 แถว, รายงาน covergroup)
5. เปิดโค้ด ชี้บรรทัดที่ผิด แก้ แล้วรัน `run_4c.do` ซ้ำจนทุก testbench PASS

### ขั้นที่ 4 — เขียนบทสรุป (10 นาที)

ต่อ bug 1 ย่อหน้า: อาการ → สมมติฐาน → บรรทัดที่ผิด → ทำไม testbench ที่ผ่านจึงมองไม่เห็น → เพิ่ม test อะไรให้ testbench ที่อ่อนที่สุดจับได้ (เช่น เพิ่มแถวใหม่ในตาราง directed)

**เฉลยสำหรับผู้สอน (ไม่แจกผู้เรียน)**

สร้างไฟล์ bug จาก `lab02_alu/verilog/alu8.v` โดยแก้จุดเดียวต่อไฟล์:

```verilog
// alu8_bug1.v — ovf ของ SUB ใช้เงื่อนไขเครื่องหมายแบบ ADD
wire       ovf_sub = (a[7] == b[7]) && (dif9[7] != a[7]);   // ถูก: (a[7] != b[7])

// alu8_bug2.v — SLT เปรียบเทียบแบบ unsigned
wire       slt     = (a < b);                              // ถูก: dif9[7] ^ ovf_sub

// alu8_bug3.v — SRL เขียนเป็น barrel shifter 3 ชั้น ชั้นที่ 3 เลือกด้วยบิตผิด
reg  [7:0] s1, s2;                                       // ประกาศเพิ่ม และให้ default = 0 ต้น always
      OP_SRL : begin
        s1 = b[0] ? {1'b0,  a[7:1]}  : a;                 // ชั้น 1
        s2 = b[1] ? {2'b00, s1[7:2]} : s1;                // ชั้น 2
        y  = b[1] ? {4'h0,  s2[7:4]} : s2;                // ชั้น 4   ถูก: b[2]
      end
```

ผลที่ผู้สอนได้จากการจำลองจริง (golden file seed = 1):

| ไฟล์ | Directed (19 แถว) | Exhaustive | Golden 5,000 | Class + coverage | Bug |
| --- | --- | --- | --- | --- | --- |
| bug1 | FAIL 5 แถว (#6, 7, 8 ผิดแค่ ovf; #16, 17 ผิดที่ SLT) | FAIL op 1 = 32,768, op 7 = 32,768 | FAIL 550 | FAIL | ovf\_sub ใช้ `a[7] == b[7]` |
| bug2 | FAIL 3 แถว (#16–18) | FAIL op 7 = 32,768 | FAIL 316 | FAIL | SLT แบบ unsigned |
| bug3 | **PASS** | FAIL op 6 = 32,288 | FAIL 200 (ตัวแรกที่บรรทัด 107: SRL a = 7F, b = 1A) | FAIL | SRL ชั้น 4 ใช้ `b[1]` |

| บทเรียน | หลักฐานจากตาราง |
| --- | --- |
| bug ที่ flag ลามไปคำสั่งอื่น | bug1 ทำให้ SLT ผิดด้วย เพราะ `slt = dif9[7] ^ ovf_sub` — เบาะแสที่ดีคือ "op 1 และ op 7 ผิดเท่ากันพอดี" = สัญญาณที่ใช้ร่วมกัน |
| ต้องตรวจทุกเอาต์พุต | แถว 6–8 ของ bug1 มี y ถูก ผิดแค่ ovf — testbench ที่ตรวจแค่ y จะเห็นเฉพาะผลข้างเคียงใน SLT |
| directed เจอเฉพาะสิ่งที่คิดไว้ | แถว SRL ในตารางใช้ shift 7 และ 0 ซึ่ง b\[1\] = b\[2\] → bug3 ผิดเฉพาะ shift 2–5 จึงหลุด — ในรายงาน coverage ของ directed จะเห็น `x_shift` ชนแค่ 4 จาก 16 bins |
| ต่อยอดจาก Lab 2 | bug3 คือบั๊กตระกูลเดียวกับ B3 ใน Lab 2D แต่ย้ายไป SRL — คนที่เคยทำ Lab 2 จริงจะจำรูปแบบ "ผิดเฉพาะ shift บางค่า" ได้ |

> **ทำไมไม่ใช้ bug "SRL ใช้ b\[1:0\]" ตามตัวอย่างใน Module 04:** ตาราง directed ของ Lab 2 มีแถว 14 (SRL 80 ด้วย b = 07) ซึ่ง b\[1:0\] = 3 จะได้ 10 แทน 01 → directed จับได้ทันที จึงเปลี่ยนเป็น bug ที่ directed มองไม่เห็นจริง ตามเจตนาของแบบฝึก

**โจทย์เสริม (คะแนนพิเศษ):** ให้ผู้เรียนสร้าง `alu8_bug4.v` ที่**ผ่าน** golden file 5,000 vector แต่ exhaustive จับได้ (เช่นผิดเฉพาะ SUB ที่ a = 0x3C และ b = 0xC3) แล้วอธิบายด้วยความน่าจะเป็นว่าทำไม random จึงพลาด — คำตอบที่ดีควรคำนวณได้ว่าโอกาสที่ vector สุ่ม 1 ตัวจะชนกรณีนั้นคือประมาณ 1/8 × (โอกาสได้ a) × (โอกาสได้ b) และคำนวณว่า 5,000 vector มีโอกาสพลาดกี่เปอร์เซ็นต์

✅ **Checkpoint 4C:** ตารางอาการครบ 3 แถว, ระบุบรรทัดที่ผิดได้ครบ 3 ตัว และหลังแก้แล้ว `run_4c.do` PASS ทุก testbench

## แก้ปัญหา, คำถามท้าย Lab และการประเมิน

**ตารางแก้ปัญหาที่พบบ่อยใน Lab 4** (ข้อความจริงอาจต่างตามรุ่น ModelSim / Questa)

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| `vcom` ฟ้องหา `hread` / `to_hstring` ไม่พบ | คอมไพล์แบบ VHDL-93 | `vcom -2008` |
| `** Failure: cannot open vectors/alu_vectors.txt` | vsim รันจากโฟลเดอร์อื่น (path เทียบกับที่รัน) หรือยังไม่รัน Python | `pwd` ใน Transcript → `cd` ไป `lab04_verif` หรือใช้ `-gVEC_FILE=<path เต็ม>` |
| `0 errors` แต่ FAIL เพราะ n ≠ 5000 | สร้างไฟล์ด้วย `-n` ค่าอื่น หรือไฟล์ถูกตัด | สร้างใหม่ หรือส่ง `-gN_EXP=<จำนวน>` — อย่าลบเงื่อนไขนี้ |
| `gen_vectors.py` หยุดด้วย `AssertionError: model ผิดที่ ...` | Python model ไม่ตรงตาราง Lab 2 | แก้ model — ห้ามแก้ตาราง CORNER ให้ตรง model |
| คอมไพล์ `class` / `covergroup` / `assert property` ไม่ผ่าน | ใช้ ModelSim ที่ไม่มี license SV verification | ใช้ Questa; ถ้าไม่มี ให้ทำ 4A + 4C (ไม่รวม class) และสาธิต 4B หน้าห้อง |
| coverage ค้างต่ำกว่า 100% จนครบ `max_n` | มี bin ที่ constraint ปิดทาง หรือเกิดไม่ได้ | `coverage report -cvg -details` หา bin ที่เป็น ZERO → แก้ constraint, เพิ่ม directed หรือ `ignore_bins` พร้อมเหตุผล |
| `randomize failed` | constraint ขัดกันเอง (เช่น inline `with` ที่สวน dist) | ปิด constraint ทีละตัวด้วย `constraint_mode(0)` หาตัวที่ขัด |
| รันสองครั้งได้จำนวน tests ไม่เท่ากัน | ไม่ได้กำหนด seed | `-sv_seed <n>` และจด seed ทุกครั้งที่ FAIL |
| assertion fail ที่เวลา 0 หรือระหว่าง reset | ไม่มี `disable iff` / `default disable iff` | ใส่ `default disable iff (!rst_n)` |
| Questa ฟ้อง unresolved reference ตอน bind | ชื่อ port/parameter ใน bind ไม่ตรงกับ DUT หรือ bind เข้า entity VHDL | ชื่อในวงเล็บต้องเป็นชื่อใน DUT; ใช้ RTL Verilog ตาม Lab |
| assertion ไม่เคย fail แม้ใส่บั๊ก | ลืมโหลด `work.bind_sva` เป็น top ตัวที่สอง หรือ cover = 0 (vacuous) | ดูหน้าต่าง Structure ว่ามี `u_sva` ใต้ dut และดู cover count |
| `$sampled` ใช้ไม่ได้ในข้อความ `$error` | simulator รุ่นเก่า | พิมพ์ตัวแปรตรง ๆ (ค่าอาจเป็นค่าหลังอัปเดต) |

**คำถามท้าย Lab**

1. golden vector จาก Python นับว่า "อิสระ" จาก RTL เพราะอะไร และกรณีไหนที่มันจะไม่อิสระอีกต่อไป
2. ทำไม `cov.sample()` ใช้ค่า flag จาก reference model แทนค่าจาก DUT — ยกตัวอย่างจาก bug1 ที่จะทำให้ตัวเลข coverage ผิด
3. ยกตัวอย่างจาก Lab นี้ที่ functional coverage 100% แต่ code coverage ไม่ครบ และกรณีกลับกัน — ทำไมต้องใช้คู่กัน
4. ถ้าใส่ constraint `(op inside {5,6}) -> b < 8` ตามตัวอย่างใน 4.3 จะซ่อน bug แบบไหน และ coverpoint ตัวไหนจะเตือน
5. ทำไม `seq_det_sva` ต้องมีทั้ง `a_detect` และ `a_no_false` — บั๊กแบบไหนที่ตัวหนึ่งจับได้แต่อีกตัวจับไม่ได้
6. ถ้า `tb_traffic_v` รันแค่ 4 clock หลัง reset assertion `a_ns_g_len` จะรายงานอะไร และจะรู้ได้อย่างไรว่าผลนั้นไม่มีความหมาย
7. จากตาราง 4C จัดอันดับ testbench 4 แบบตามความสามารถจับ bug และต้นทุน แล้วเสนอแผนทดสอบ ALU 32 บิตที่ exhaustive ทำไม่ได้

**เฉลยสำหรับผู้สอน**

| ข้อ | แนวคำตอบ |
| --- | --- |
| 1 | คำนวณจากนิยามด้วยจำนวนเต็มคนละภาษา คนละวิธีกับสูตรบิตใน RTL และตรวจกับตารางคำนวณมือก่อน — จะไม่อิสระเมื่อคนเขียน model คัดสูตรจาก RTL (เช่น `slt = (d >> 7) ^ ovf`) หรือใช้สเปกฉบับเดียวกันที่ตีความผิดเหมือนกัน — สองฝั่งจะผิดตรงกันและ PASS |
| 2 | coverage ต้องบอกว่า "สถานการณ์ไหนถูกทดสอบ" — bug1 ทำให้ DUT ตอบ ovf = 1 ที่ SUB 00 − 01 ถ้า sample จาก DUT bin `<sub, c=1, v=1>` จะถูกนับทั้งที่ไม่เคยมี vector ที่ควรให้ c = 1, v = 1 จริง (ใน TB นี้ error จะฟ้องอยู่แล้ว แต่ตัวเลข coverage ที่รายงานจะหลอกตา) |
| 3 | functional 100% แต่ code ไม่ครบ: branch `default` ที่ไม่มีทางเกิด; code 100% แต่ functional ไม่ครบ: ตาราง directed 19 แถวรันทุกบรรทัดของ RTL แต่ `x_shift` ชนแค่ 4/16 — code coverage ไม่รู้จักสเปก ส่วน functional ไม่รู้จักโค้ดที่เกินมา |
| 4 | ซ่อน bug ที่ใช้ b ทั้ง 8 บิตเป็นจำนวน shift (เช่น `y = a >> b`) — กรณี b ≥ 8 จะไม่ถูกสุ่มเลย; `cp_hib` bin `hi_set` เป็น 0 ตลอดทำให้ coverage ไม่ถึง 100% (นี่คือเหตุผลที่เพิ่ม coverpoint นี้) |
| 5 | `a_detect` จับ "พลาด" (เช่น B1 ไม่ overlap) ส่วน `a_no_false` จับ "ตรวจเกิน" (เช่น FSM ที่ตอบ 1 ตอนเห็น 1001) — บั๊ก B3 ทำให้ผิดทั้งสองทิศเพราะขึ้นก่อน 1 clock |
| 6 | ไม่มี fail เพราะไฟเขียวยังไม่เคยดับ (antecedent `$fell` ไม่เกิด = vacuous pass) — รู้ได้จาก `c_ns_green_end` = 0 ใน Cover Directives จึงต้องมี cover คู่กับ assertion เสมอ |
| 7 | จับ bug: exhaustive = class+coverage ≥ golden > directed; ต้นทุน: directed < golden < class < exhaustive (และ exhaustive ใช้ได้เฉพาะอินพุตน้อย) — ALU 32 บิต: directed corner + constrained random หลาย seed ที่เน้นค่าขอบ + covergroup ที่ cross op กับกลุ่มค่า + golden จาก model อิสระ + assertion ที่ตรวจ flag + (ถ้ามี) formal สำหรับบล็อกเล็ก เช่น shifter |

**งานที่ต้องส่ง** (บีบอัด `lab04_verif/` โดยลบ `work/`, `*.wlf`, `*.ucdb` ยกเว้น `alu_merged.ucdb`)

1. Verification plan (ตาราง 4.0) ที่เขียนเอง
2. `gen_vectors.py`, `vectors/alu_vectors.txt`, testbench 4A ทั้งสองภาษา และ log `reports/4a_*.log` (รวมการทดลองไฟล์ผิดในขั้นที่ 5)
3. `tb_alu8_cls.sv`, `reports/cov_alu.txt`, หน้า HTML ของ coverage, รายการ exclusion พร้อมเหตุผล และผลการทดลอง +NOEDGE
4. ไฟล์ SVA 3 ไฟล์, log `reports/4b_sva_*.log`, screenshot Cover Directives และ assertion fail จากบั๊ก 3 ตัวในขั้นที่ 5
5. ตาราง 4C ที่กรอกครบ บทสรุป bug ทั้ง 3 ตัว และ log `reports/4c_*.log`
6. คำตอบคำถาม 7 ข้อ

**เกณฑ์ให้คะแนน Lab 4 (100 คะแนน + พิเศษ 5)**

| หัวข้อ | คะแนน | เต็ม | บางส่วน |
| --- | --- | --- | --- |
| Verification plan | 10 | ครบทุก feature พร้อมวิธีตรวจและเกณฑ์เป็นตัวเลข | ไม่มีเกณฑ์ตัวเลข |
| 4A golden vector | 20 | self-test ผ่าน, errors = 0 ทั้งสองภาษา, ทดลองไฟล์ผิดครบ 2 ข้อ | ภาษาเดียว |
| 4B random + coverage | 25 | functional 100% ทั้ง 3 seed, code coverage ≥ 95% หรือ exclusion มีเหตุผล, ผล +NOEDGE | coverage ไม่ครบแต่อธิบาย hole ได้ |
| 4B assertions | 20 | ไม่ fail, cover ทุกตัว > 0, แสดงว่าจับบั๊ก B3/C1/C4 ได้ | ไม่มีหลักฐานว่าจับบั๊กได้ |
| 4C bug hunt | 25 | ระบุ bug ครบ 3 ตัวจากอาการ และอธิบายได้ว่า TB ตัวไหนจับได้/ไม่ได้ เพราะอะไร | หาได้ 2 ตัว หรือเปิดโค้ดก่อนสืบ |
| พิเศษ | +5 | bug4 พร้อมการคำนวณความน่าจะเป็นที่ถูกต้อง | — |

**หมายเหตุสำหรับผู้สอน:** ควรคอมไพล์ `tb_alu8_cls.sv` และไฟล์ SVA บน Questa เครื่องในห้องก่อนสอนหนึ่งรอบ เพราะการรองรับ covergroup/SVA ต่างกันตามรุ่นและ license — ส่วน 4C ให้เก็บไฟล์ bug ไว้ในที่ที่ผู้เรียนเปิดดูเฉลยไม่ได้ และตั้งชื่อไฟล์ไม่ให้บอกใบ้ (คำอธิบายบรรทัด BUG ในโค้ดต้องลบออกก่อนแจก)

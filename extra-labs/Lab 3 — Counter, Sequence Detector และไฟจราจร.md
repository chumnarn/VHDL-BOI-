# Lab 3 — Counter, Sequence Detector และไฟจราจร

Oct 28, 2026 · @Chumnarn Punyasai

## ภาพรวม Lab 3

**เป้าหมาย:** เขียนวงจร sequential 3 ตัวทั้ง VHDL และ Verilog แล้วตรวจสอบด้วย testbench ที่ตรวจผลเองทุก clock (self-checking) — นับจำนวนผิด, นับ coverage และตรวจกฎเชิงเวลาโดยอัตโนมัติ จนได้บรรทัดสุดท้ายเป็น `*** PASS ***` หรือ `*** FAIL ***` โดยไม่ต้องเปิด waveform ดูเอง

**เมื่อจบ Lab ผู้เรียนจะ**

1. เขียน register ที่มี priority ของสัญญาณควบคุม (reset > load > enable) และ output แบบ combinational (`tc`) ได้ถูกต้อง
2. ออกแบบ Moore FSM จาก state diagram รวมถึงกรณี overlap และเขียนแบบ 2-process ที่ไม่มี latch
3. แยก FSM กับ timer ออกจากกัน และใช้ `tick` เป็น clock enable แทนการหาร clock
4. เขียน testbench สำหรับวงจร sequential: ป้อนค่าที่ขอบขาลง, ตรวจหลังขอบขาขึ้น, ใช้ reference model ที่อัปเดตทุก clock
5. เขียน checker ตรวจ "กฎ" (ห้ามเขียวพร้อมกัน, ต้องมีไฟแดง, เขียวนานเท่าที่กำหนด) แทนการเทียบค่าเป็นจุด ๆ

**ความรู้ที่ต้องมีก่อน:** Lab 1 (do-file, ModelSim พื้นฐาน), Lab 2 (testbench แบบ directed/exhaustive, reference model), Module 03 หัวข้อ 3.4 Counter และ 3.6 FSM

| ส่วน | วงจร | สิ่งที่ testbench ต้องตรวจ | เวลา |
| --- | --- | --- | --- |
| 3.0 | — (อ่านก่อนเข้า Lab) | รูปแบบ testbench สำหรับวงจร sequential | 15 นาที (ก่อนเรียน) |
| A | Counter 4 บิต (load / enable / tc) | นับถูก, load สำคัญกว่า en, tc ตอน 15, วนกลับ 0, en = 0 ค่าคงเดิม | 45 นาที |
| B | Moore FSM ตรวจ "1011" (overlap) | ลำดับ 1011011 ต้องพบ 2 ครั้ง + ลำดับสุ่มเทียบ reference | 60 นาที |
| C | ไฟจราจรสี่แยก (หัวข้อ 3.6) | ไม่เขียวพร้อมกัน, มีไฟแดงเสมอ, เขียวนาน T\_GREEN, เหลืองนาน T\_YELLOW | 75 นาที |
| D | Regression | รันทุก testbench ทั้งสองภาษาด้วยคำสั่งเดียว | 15 นาที (ท้ายคาบ/การบ้าน) |

**โครงสร้างโฟลเดอร์**

```text
lab03_seq/
├── vhdl/
│   ├── counter.vhd        seq_det_1011.vhd     traffic.vhd
│   └── tb_counter.vhd     tb_seq_det.vhd       tb_traffic.vhd
├── verilog/
│   ├── counter.v          seq_det_1011.v       traffic.v
│   └── tb_counter_v.sv    tb_seq_det_v.sv      tb_traffic_v.sv
├── doc/                   ← state diagram, timing diagram, บันทึก bug
├── run.do                 ← รัน 1 ชุด (เลือก RTL / TOP)
└── regress.sh             ← รันทุกชุดแบบ batch
```

**ข้อตกลงการตั้งชื่อ:** testbench ทั้งสองภาษา compile ลง library `work` เดียวกัน จึงต่อท้ายชื่อ testbench ภาษา SystemVerilog ด้วย `_v` (เช่น `tb_counter_v`) ไม่ให้ชนกับ testbench ภาษา VHDL — ต่างจากตัวอย่างใน Module 03 ที่ `tb_traffic` เป็น Verilog เพียงภาษาเดียว

**ข้อตกลงร่วมของทั้ง 3 วงจร:** clock ขอบขาขึ้น, reset แบบ synchronous active-low (`rst_n`), testbench ใช้ clock คาบ 10 ns

## 3.0 พื้นฐาน testbench สำหรับวงจร sequential (อ่านก่อนเข้า Lab)

ใน Lab 2 เอาต์พุตขึ้นกับอินพุตปัจจุบันอย่างเดียว จึงตรวจทีละ vector ได้ แต่วงจร sequential มีหน่วยความจำ เอาต์พุตขึ้นกับ **ประวัติของอินพุตทุก clock ที่ผ่านมา** testbench จึงต้องเดินไปพร้อม DUT ทีละ clock และมี reference model ที่จำ state เองด้วย

&#91;embedded content: จังหวะของ testbench วงจร sequential · ป้อน → อัปเดต → ตรวจ\]

**กฎ 6 ข้อที่ใช้ทุก testbench ใน Lab นี้**

1. **ป้อนค่าที่ขอบขาลง** (`wait until falling_edge(clk)` / `@(negedge clk)`) — อินพุตนิ่งครึ่งคาบก่อนขอบขาขึ้น ไม่มี race กับ DUT (ถ้าเปลี่ยนที่ขอบขาขึ้นพอดีด้วย blocking assignment ผลจะขึ้นกับลำดับการรันของ simulator)
2. **อัปเดต reference model ที่ขอบขาขึ้นเดียวกับ DUT** โดยใช้อินพุตชุดเดียวกัน model เขียนด้วย integer/variable ตามสเปก ไม่คัดลอกโค้ด RTL
3. **ตรวจหลังขอบขาขึ้น 1 ns** (`wait for 1 ns` / `#1`) — ตอนนั้น register และ output แบบ combinational นิ่งแล้ว
4. **นับ error และพิมพ์เฉพาะ 10 ตัวแรก** — บั๊กตัวเดียวอาจทำให้ผิดทุก clock หลังจากนั้น (state เพี้ยนแล้วเพี้ยนต่อ) ตัวแรกคือตัวที่บอกสาเหตุ
5. **นับ coverage** — นับว่าเกิดกรณีสำคัญจริงกี่ครั้ง (เช่นวนกลับ 0, load พร้อม en) PASS ต้องมี error = 0 **และ** coverage ครบ — testbench ที่ไม่เคยทดสอบกรณีนั้นก็ "ผ่าน" ได้เสมอ
6. **จบเอง** — VHDL หยุด clock ด้วยสัญญาณ `done` แล้ว `run -all` จะหยุดเอง, SystemVerilog ใช้ `$finish` บรรทัดสุดท้ายต้องมีคำว่า `PASS` หรือ `FAIL` เสมอ เพราะ `regress.sh` ใช้ `grep` หาคำนี้

**ประเภทการตรวจที่จะใช้ใน Lab นี้**

| ประเภท | ตรวจอะไร | ใช้ใน |
| --- | --- | --- |
| เทียบกับ model ทุก clock | ค่าเอาต์พุตตรงกับที่ควรเป็นทุกรอบ | A (q, tc), B (detected) |
| นับเหตุการณ์ | จำนวนครั้งที่เกิดตรงกับที่คาด | B (1011011 → 2 ครั้ง) |
| กฎที่ต้องจริงเสมอ (invariant) | สิ่งที่ห้ามเกิดทุก clock โดยไม่ต้องรู้ค่าที่ถูก | C (ไม่เขียวพร้อมกัน, มีไฟแดง) |
| ลำดับและระยะเวลา | การเปลี่ยนที่อนุญาต และความยาวของแต่ละช่วง | C (เขียว → เหลือง → แดง, เขียวนาน T\_GREEN) |

**โครง testbench ที่ใช้ซ้ำทั้ง Lab — VHDL**

```vhdl
signal clk  : std_logic := '0';
signal done : boolean   := false;
...
clk <= not clk after 5 ns when not done else '0';    -- คาบ 10 ns, หยุดเมื่อ done

stim: process
  variable model  : natural := 0;     -- reference model
  variable errors : natural := 0;

  procedure step(...) is              -- 1 เรียก = 1 clock
  begin
    wait until falling_edge(clk);     -- ① ป้อนค่า
    ...
    wait until rising_edge(clk);      -- ② อัปเดต model
    ...
    wait for 1 ns;                    -- ③ ตรวจ
    if <ผิด> then
      errors := errors + 1;
      if errors <= 10 then report "FAIL ..." severity error; end if;
    end if;
  end procedure;
begin
  ...                                  -- directed + random
  if errors = 0 and <coverage ครบ> then report "*** PASS ***";
  else report "*** FAIL ***" severity error; end if;
  done <= true;  wait;
end process;
```

**โครงเดียวกัน — SystemVerilog**

```systemverilog
logic clk = 0;
always #5 clk = ~clk;
int errors = 0;

task automatic step(...);
  @(negedge clk);   /* ① */  ...
  @(posedge clk);   /* ② */  ...
  #1;               /* ③ */
  if (<ผิด>) begin
    errors++;
    if (errors <= 10) $display("FAIL t=%0t ...", $time);
  end
endtask

initial begin
  ...
  if (errors == 0 && <coverage ครบ>) $display("*** PASS ***");
  else                                  $display("*** FAIL ***");
  $finish;
end
```

**ทำไมเขียนเป็น `procedure`/`task` ชื่อ `step`:** ทุกบรรทัดในส่วน stimulus จะอ่านเหมือนตาราง เช่น `step('1', '1', '1', 3);  -- load+en: load ต้องชนะ` — 1 บรรทัด = 1 clock = 1 การตรวจ เพิ่มกรณีใหม่ได้โดยไม่ต้องคิดเรื่องจังหวะอีก

> **ความต่างที่ต้องรู้:** procedure ที่ประกาศ**ภายใน** process เขียนสัญญาณและใช้ variable ของ process นั้นได้ตรง ๆ แต่ถ้าย้ายไปไว้ใน architecture หรือ package ต้องส่งสัญญาณเป็นพารามิเตอร์ `signal` เอง — ใน Lab นี้ประกาศใน process ทั้งหมดเพื่อให้โค้ดสั้น

## 3A — Counter 4 บิตพร้อม load / enable / tc (45 นาที)

### ขั้นที่ 1 — อ่านสเปกและลำดับความสำคัญ (5 นาที)

| พอร์ต | ทิศ | กว้าง | ความหมาย |
| --- | --- | --- | --- |
| `clk` | in | 1 | clock ขอบขาขึ้น |
| `rst_n` | in | 1 | reset แบบ synchronous, active-low |
| `load` | in | 1 | โหลดค่า `d` เข้า counter |
| `en` | in | 1 | นับขึ้น 1 |
| `d` | in | N (4) | ค่าที่จะโหลด |
| `q` | out | N (4) | ค่าปัจจุบัน (มาจาก register) |
| `tc` | out | 1 | terminal count = 1 เมื่อ `q = 2^N − 1` **และ** `en = 1` (combinational — ใช้เป็น enable ของ counter ตัวถัดไปตอน cascade) |

| ลำดับ | เงื่อนไขที่ขอบขาขึ้น | q ถัดไป |
| --- | --- | --- |
| 1 | `rst_n = 0` | 0 |
| 2 | `load = 1` | `d` (ไม่สน en) |
| 3 | `en = 1` | `q + 1` (15 → 0) |
| 4 | อื่น ๆ | คงเดิม |

### ขั้นที่ 2 — คำนวณ trace ด้วยมือก่อนเขียนโค้ด (5 นาที)

กรอกค่า q และ tc **หลัง**ขอบขาขึ้นแต่ละครั้ง (N = 4, เริ่มจาก q = 2) — ตารางนี้คือขั้นที่ 3–7 ของ testbench ในขั้นที่ 4

| clock | rst\_n | load | en | d | q หลังขอบ | tc | เหตุผล |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | 0 | 0 | – | 2 | 0 | en = 0 คงค่า |
| 2 | 1 | 1 | 0 | 9 | 9 | 0 | load |
| 3 | 1 | 1 | 1 | 3 | **3** | 0 | load ชนะ en (ไม่ใช่ 10) |
| 4 | 1 | 1 | 0 | 14 | 14 | 0 | load |
| 5 | 1 | 0 | 1 | – | 15 | **1** | q = 15 และ en = 1 |
| 6 | 1 | 0 | 0 | – | 15 | **0** | q = 15 แต่ en = 0 |
| 7 | 1 | 0 | 1 | – | **0** | 0 | วนกลับ |
| 8 | 0 | 1 | 1 | 5 | **0** | 0 | reset ชนะทุกอย่าง |

### ขั้นที่ 3 — เขียน RTL (10 นาที)

`vhdl/counter.vhd`

```vhdl
-- counter.vhd : N-bit up counter, sync reset, load > en, tc = (q = max) and en
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
  generic (N : positive := 4);
  port (
    clk, rst_n, en, load : in  std_logic;
    d  : in  std_logic_vector(N-1 downto 0);
    q  : out std_logic_vector(N-1 downto 0);
    tc : out std_logic
  );
end entity;

architecture rtl of counter is
  signal cnt : unsigned(N-1 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then    cnt <= (others => '0');   -- 1) reset
      elsif load = '1' then  cnt <= unsigned(d);       -- 2) load
      elsif en = '1' then    cnt <= cnt + 1;           -- 3) count (wrap เองที่ N บิต)
      end if;
    end if;
  end process;

  q  <= std_logic_vector(cnt);
  tc <= '1' when cnt = 2**N - 1 and en = '1' else '0';
end architecture;
```

`verilog/counter.v`

```verilog
// counter.v : N-bit up counter, sync reset, load > en, tc = (q = max) & en
module counter #(parameter N = 4) (
  input  wire         clk, rst_n, en, load,
  input  wire [N-1:0] d,
  output reg  [N-1:0] q,
  output wire         tc
);
  always @(posedge clk) begin
    if (!rst_n)     q <= {N{1'b0}};   // 1) reset
    else if (load)  q <= d;           // 2) load
    else if (en)    q <= q + 1'b1;    // 3) count
  end

  assign tc = (&q) & en;              // reduction AND: ทุกบิตเป็น 1 — ไม่ผูกกับความกว้าง
endmodule
```

จุดสังเกต: ลำดับ `if / elsif` คือลำดับความสำคัญในสเปกตรง ๆ — สลับบรรทัดก็คือเปลี่ยนสเปก (ดูบั๊ก A1) และไม่ต้องมี `else` สุดท้ายใน process ที่มี clock เพราะ register คงค่าเดิมเอง (ไม่ใช่ latch)

### ขั้นที่ 4 — เขียน testbench พร้อม reference model (15 นาที)

Testbench แบ่งเป็น 8 ช่วง: (1) reset (2) นับเกิน 1 รอบ (3) en = 0 (4) load (5) load + en (6) tc กับ en (7) reset ชนะ (8) สุ่ม 500 clock ทุกช่วงใช้ `MAXV = 2^N − 1` แทนเลข 15 จึงรันกับ N อื่นได้ด้วย `-gN=8` (N ต้อง ≥ 4 เพราะมีการโหลดค่า 9)

`vhdl/tb_counter.vhd`

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;                 -- uniform, floor

entity tb_counter is
  generic (N : positive := 4; NRAND : natural := 500);
end entity;

architecture sim of tb_counter is
  constant MAXV : natural := 2**N - 1;
  signal clk  : std_logic := '0';
  signal rst_n, en, load : std_logic := '0';
  signal d, q : std_logic_vector(N-1 downto 0) := (others => '0');
  signal tc   : std_logic;
  signal done : boolean := false;
begin
  clk <= not clk after 5 ns when not done else '0';

  dut: entity work.counter
    generic map (N => N)
    port map (clk => clk, rst_n => rst_n, en => en, load => load,
              d => d, q => q, tc => tc);

  stim: process
    variable model  : natural := 0;              -- reference model
    variable errors : natural := 0;
    variable wraps, tc_hits, ld_en : natural := 0;   -- coverage
    variable s1, s2 : positive := 7;
    variable r1, r2, r3, r4 : real;
    variable rb, lb, eb : std_logic;

    procedure step(r_n, ld, e : std_logic; dv : natural) is
      variable exp_tc : std_logic;
    begin
      wait until falling_edge(clk);                        -- (1) drive
      rst_n <= r_n;  load <= ld;  en <= e;
      d <= std_logic_vector(to_unsigned(dv, N));

      wait until rising_edge(clk);                         -- (2) model
      if r_n = '0' then
        model := 0;
      elsif ld = '1' then
        model := dv;
        if e = '1' then ld_en := ld_en + 1; end if;
      elsif e = '1' then
        if model = MAXV then model := 0;  wraps := wraps + 1;
        else                 model := model + 1;
        end if;
      end if;

      wait for 1 ns;                                       -- (3) check
      if model = MAXV and e = '1' then
        exp_tc := '1';  tc_hits := tc_hits + 1;
      else
        exp_tc := '0';
      end if;
      if to_integer(unsigned(q)) /= model or tc /= exp_tc then
        errors := errors + 1;
        if errors <= 10 then
          report "FAIL t=" & time'image(now) &
                 " q="      & integer'image(to_integer(unsigned(q))) &
                 " exp="    & integer'image(model) &
                 " tc="     & std_logic'image(tc) &
                 " exp_tc=" & std_logic'image(exp_tc) severity error;
        end if;
      end if;
    end procedure;

  begin
    -- (1) reset 2 clock
    step('0', '0', '0', 0);  step('0', '0', '0', 0);
    -- (2) นับต่อเนื่องเกิน 1 รอบ: ผ่าน MAXV (tc = 1) แล้ววนกลับ 0
    for i in 1 to MAXV + 3 loop step('1', '0', '1', 0); end loop;
    -- (3) en = 0: ค่าต้องคงเดิม
    for i in 1 to 3 loop step('1', '0', '0', 0); end loop;
    -- (4) load อย่างเดียว
    step('1', '1', '0', 9);
    -- (5) load + en พร้อมกัน: load ต้องชนะ (ได้ 3 ไม่ใช่ 10)
    step('1', '1', '1', 3);
    -- (6) tc ต้องขึ้นกับ en
    step('1', '1', '0', MAXV - 1);   -- q = MAXV-1
    step('1', '0', '1', 0);          -- q = MAXV, tc = 1
    step('1', '0', '0', 0);          -- q = MAXV, en = 0 -> tc = 0
    step('1', '0', '1', 0);          -- q = 0 (wrap)
    -- (7) reset ชนะ load และ en
    step('0', '1', '1', 5);
    -- (8) random: reset 2%, load 10%, en 70%
    for i in 1 to NRAND loop
      uniform(s1, s2, r1);  uniform(s1, s2, r2);
      uniform(s1, s2, r3);  uniform(s1, s2, r4);
      if r1 < 0.02 then rb := '0'; else rb := '1'; end if;
      if r2 < 0.10 then lb := '1'; else lb := '0'; end if;
      if r3 < 0.70 then eb := '1'; else eb := '0'; end if;
      step(rb, lb, eb, integer(floor(r4 * real(MAXV + 1))));
    end loop;

    report "errors="   & integer'image(errors) &
           " wraps="   & integer'image(wraps) &
           " tc_hits=" & integer'image(tc_hits) &
           " load+en=" & integer'image(ld_en);
    if errors = 0 and wraps > 0 and tc_hits > 0 and ld_en > 0 then
      report "*** PASS ***";
    else
      report "*** FAIL ***" severity error;
    end if;
    done <= true;
    wait;
  end process;
end architecture;
```

`verilog/tb_counter_v.sv`

```systemverilog
`timescale 1ns/1ps
module tb_counter_v;
  parameter int N = 4, NRAND = 500;
  localparam int MAXV = (1 << N) - 1;

  logic         clk = 0, rst_n = 0, en = 0, load = 0;
  logic [N-1:0] d = '0;
  wire  [N-1:0] q;
  wire          tc;
  int model = 0, errors = 0, wraps = 0, tc_hits = 0, ld_en = 0;

  counter #(.N(N)) dut (.clk, .rst_n, .en, .load, .d, .q, .tc);
  always #5 clk = ~clk;

  task automatic step(input logic r_n, ld, e, input int dv);
    logic exp_tc;
    @(negedge clk);                                   // (1) drive
    rst_n = r_n;  load = ld;  en = e;  d = dv[N-1:0];
    @(posedge clk);                                   // (2) model
    if (!r_n)      model = 0;
    else if (ld)   begin model = dv; if (e) ld_en++; end
    else if (e)    begin
      if (model == MAXV) begin model = 0; wraps++; end
      else model++;
    end
    #1;                                               // (3) check
    exp_tc = (model == MAXV) && e;
    if (exp_tc) tc_hits++;
    if (q !== model || tc !== exp_tc) begin           // !== จับ X/Z ด้วย
      errors++;
      if (errors <= 10)
        $display("FAIL t=%0t q=%0d exp=%0d tc=%b exp_tc=%b", $time, q, model, tc, exp_tc);
    end
  endtask

  initial begin
    step(0,0,0,0);  step(0,0,0,0);                    // (1)
    repeat (MAXV + 3) step(1,0,1,0);                  // (2)
    repeat (3)        step(1,0,0,0);                  // (3)
    step(1,1,0,9);                                    // (4)
    step(1,1,1,3);                                    // (5) load ชนะ
    step(1,1,0,MAXV-1);                               // (6)
    step(1,0,1,0);  step(1,0,0,0);  step(1,0,1,0);
    step(0,1,1,5);                                    // (7) reset ชนะ
    repeat (NRAND)                                    // (8) random
      step($urandom_range(0,49) != 0, $urandom_range(0,9) == 0,
           $urandom_range(0,9) < 7,   $urandom_range(0, MAXV));

    $display("errors=%0d wraps=%0d tc_hits=%0d load+en=%0d",
             errors, wraps, tc_hits, ld_en);
    if (errors == 0 && wraps > 0 && tc_hits > 0 && ld_en > 0) $display("*** PASS ***");
    else                                                       $display("*** FAIL ***");
    $finish;
  end
endmodule
```

### ขั้นที่ 5 — คอมไพล์และรัน (5 นาที)

```tcl
# ใน ModelSim Transcript (อยู่ที่ lab03_seq/)
vlib work
vcom -2008 vhdl/counter.vhd vhdl/tb_counter.vhd
vsim -voptargs=+acc work.tb_counter
add wave -radix unsigned /tb_counter/*
run -all

# รัน N = 8 แบบ batch (ไม่เปิด GUI)
vsim -c -gN=8 work.tb_counter -do "run -all; quit -f"
```

```tcl
# Verilog RTL + SV testbench — ล้าง work ก่อน เพราะ counter สองภาษาใช้ชื่อซ้ำกัน
vdel -lib work -all;  vlib work
vlog verilog/counter.v
vlog -sv verilog/tb_counter_v.sv
vsim -c work.tb_counter_v -do "run -all; quit -f"
```

ผลที่คาด (ตัวเลข coverage ต่างกันได้ตาม seed แต่ต้องมากกว่า 0 ทุกตัว):

```text
# ** Note: errors=0 wraps=... tc_hits=... load+en=...
# ** Note: *** PASS ***
```

> **ทำไมต้องล้าง `work`:** ทั้ง `counter.vhd` และ `counter.v` สร้าง design unit ชื่อ `counter` — คอมไพล์ตัวหลังจะทับตัวแรก ถ้าไม่ล้างอาจทดสอบผิดภาษาโดยไม่รู้ตัว (`run.do` ใน 3D ทำให้อัตโนมัติ)

### ขั้นที่ 6 — Bug injection (5 นาที)

แก้ RTL ทีละจุด รัน testbench บันทึกผล แล้วคืนโค้ดก่อนทำตัวถัดไป

| บั๊ก | แก้เป็น | ผลที่ควรเห็น |
| --- | --- | --- |
| A1 ลำดับความสำคัญสลับ | เช็ค `en` ก่อน `load` | FAIL ที่ช่วง (5): `q=10 exp=3` และในช่วงสุ่ม |
| A2 tc ไม่สน en | `tc <= '1' when cnt = 2**N-1 else '0'` / `assign tc = &q;` | FAIL ที่ช่วง (6) คลิกที่ q = 15, en = 0: `tc='1' exp_tc='0'` |
| A3 ผูกความกว้าง | `assign tc = (q == 4'hF) & en;` (หรือ VHDL `cnt = 15`) | N = 4 **PASS** — แต่ `-gN=8` FAIL ที่ q = 15: บั๊กที่เห็นได้เฉพาะเมื่อรันหลายค่า parameter |

บั๊ก A3 คือเหตุผลที่ testbench ใช้ `MAXV` แทนเลข 15 — testbench ที่ผูกเลขไว้จะรัน N = 8 ไม่ได้ จึงไม่มีโอกาสจับบั๊กนี้

## 3B — Moore FSM ตรวจลำดับ "1011" แบบ overlap (60 นาที)

**สเปก:** รับ `din` ทีละบิตทุกขอบขาขึ้น เมื่อ 4 บิตล่าสุดเป็น `1011` ให้ `detected = 1` นาน 1 clock — เป็น **Moore** (detected ขึ้นกับ state อย่างเดียว จึงสูงใน clock **ถัดจาก**ขอบที่รับบิตสุดท้าย) และ **overlap** (บิตท้ายของลำดับที่พบแล้วเป็นต้นของลำดับถัดไปได้) ดังนั้น `1011011` ต้องพบ 2 ครั้ง ไม่ใช่ 1

### ขั้นที่ 1 — หา state และ transition ด้วยมือ (15 นาที)

ตั้งชื่อ state ตาม "ส่วนต้นของ 1011 ที่เจอแล้ว": S0 (ยังไม่เจอ), S1, S10, S101, S1011 (เจอครบ) — ทุก transition หาได้ด้วยกฎเดียว: **ต่อบิตใหม่ท้ายชื่อ state แล้วหา suffix ที่ยาวที่สุดที่ยังเป็นส่วนต้นของ 1011**

| state | din = 0 | din = 1 | detected |
| --- | --- | --- | --- |
| S0 | "0" → S0 | "1" → S1 | 0 |
| S1 | "10" → S10 | "11" → suffix "1" → S1 | 0 |
| S10 | "100" → ไม่มี → S0 | "101" → S101 | 0 |
| S101 | "1010" → suffix "10" → S10 | "1011" → S1011 | 0 |
| S1011 | "10110" → suffix "10" → **S10** | "10111" → suffix "1" → **S1** | **1** |

แถว S1011 คือหัวใจของ overlap: ถ้าเป็นแบบ non-overlap จะกลับ S0 ทั้งสองทาง วาด state diagram ลง `doc/` ก่อนเขียนโค้ด แล้วเทียบกับรูปนี้

&#91;embedded content: state diagram ของ seq\_det\_1011 · 5 state, 10 transition\]

**Trace ด้วยมือของ `1011011`** (เริ่มจาก S0 หลัง reset)

| clock | din | state หลังขอบ | detected | 4 บิตล่าสุด |
| --- | --- | --- | --- | --- |
| 1 | 1 | S1 | 0 | 0001 |
| 2 | 0 | S10 | 0 | 0010 |
| 3 | 1 | S101 | 0 | 0101 |
| 4 | 1 | S1011 | **1** | **1011** |
| 5 | 0 | S10 | 0 | 0110 |
| 6 | 1 | S101 | 0 | 1101 |
| 7 | 1 | S1011 | **1** | **1011** |

คอลัมน์สุดท้ายคือ reference model ที่จะใช้ใน testbench: shift register 4 บิต — `detected` ต้องเป็น 1 **พอดี**ใน clock ที่ `hist = 1011` ไม่ต้องมี state เลย จึงเป็น model ที่อิสระจาก RTL

### ขั้นที่ 2 — เขียน RTL แบบ 2-process (10 นาที)

`vhdl/seq_det_1011.vhd`

```vhdl
-- seq_det_1011.vhd : Moore FSM, detect "1011" with overlap
library ieee;
use ieee.std_logic_1164.all;

entity seq_det_1011 is
  port (clk, rst_n, din : in std_logic; detected : out std_logic);
end entity;

architecture rtl of seq_det_1011 is
  type state_t is (S0, S1, S10, S101, S1011);   -- enum: ModelSim แสดงชื่อใน Wave
  signal state, next_state : state_t;
begin
  -- (1) state register
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then state <= S0;
      else                state <= next_state;
      end if;
    end if;
  end process;

  -- (2) next-state logic (combinational)
  process(all)
  begin
    next_state <= state;                           -- default กัน latch
    case state is
      when S0    => if din = '1' then next_state <= S1;    end if;
      when S1    => if din = '0' then next_state <= S10;   end if;
      when S10   => if din = '1' then next_state <= S101;  else next_state <= S0;  end if;
      when S101  => if din = '1' then next_state <= S1011; else next_state <= S10; end if;
      when S1011 => if din = '1' then next_state <= S1;    else next_state <= S10; end if;
    end case;
  end process;

  -- Moore output: ขึ้นกับ state เท่านั้น
  detected <= '1' when state = S1011 else '0';
end architecture;
```

`verilog/seq_det_1011.v`

```verilog
// seq_det_1011.v : Moore FSM, detect "1011" with overlap
module seq_det_1011 (
  input  wire clk, rst_n, din,
  output wire detected
);
  localparam S0 = 3'd0, S1 = 3'd1, S10 = 3'd2, S101 = 3'd3, S1011 = 3'd4;
  reg [2:0] state, next_state;

  always @(posedge clk)
    if (!rst_n) state <= S0;
    else        state <= next_state;

  always @(*) begin
    next_state = state;                              // default
    case (state)
      S0:      next_state = din ? S1    : S0;
      S1:      next_state = din ? S1    : S10;
      S10:     next_state = din ? S101  : S0;
      S101:    next_state = din ? S1011 : S10;
      S1011:   next_state = din ? S1    : S10;
      default: next_state = S0;                      // safe FSM: 3'd5..3'd7
    endcase
  end

  assign detected = (state == S1011);
endmodule
```

ใน VHDL `case` ครบทุกค่าของ enum แล้วจึงไม่ต้องมี `when others` (ใส่ได้แต่ compiler อาจเตือนว่าไม่มีทางเกิดขึ้น) ส่วน Verilog ใช้ 3 บิตแทน 5 state จึงมี 3 ค่าที่ไม่ได้ใช้ — `default` พากลับ S0

### ขั้นที่ 3 — เขียน testbench: directed 6 ลำดับ + สุ่ม 1,000 บิต (20 นาที)

แต่ละลำดับ directed ตั้งใจให้ผ่าน transition ที่ต่างกัน และ testbench ตรวจ 2 ชั้น: (ก) จำนวนครั้งที่พบต่อลำดับ (ข) เทียบ `detected` กับ `hist = 1011` **ทุก clock**

| ลำดับ | พบ | transition ที่ต้องผ่าน |
| --- | --- | --- |
| `1011011` | 2 | S1011 + 0 → S10 (overlap ตามโจทย์) |
| `10111011` | 2 | S1011 + 1 → S1 |
| `1001011` | 1 | S10 + 0 → S0 |
| `11011` | 1 | S1 + 1 → S1 |
| `1010110` | 1 | S101 + 0 → S10 |
| `0000111` | 0 | S0 + 0 → S0, ไม่มี 1011 |

`vhdl/tb_seq_det.vhd`

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity tb_seq_det is
  generic (NRAND : natural := 1000);
end entity;

architecture sim of tb_seq_det is
  signal clk  : std_logic := '0';
  signal rst_n, din, detected : std_logic := '0';
  signal done : boolean := false;
begin
  clk <= not clk after 5 ns when not done else '0';

  dut: entity work.seq_det_1011
    port map (clk => clk, rst_n => rst_n, din => din, detected => detected);

  stim: process
    variable hist : std_logic_vector(3 downto 0) := "0000";   -- reference model
    variable hits, exp_hits, errors, dir_fail : natural := 0;
    variable s1, s2 : positive := 11;
    variable r : real;

    procedure reset_dut is
    begin
      wait until falling_edge(clk);  rst_n <= '0';  din <= '0';
      wait until falling_edge(clk);  rst_n <= '1';
      hist := "0000";
    end procedure;

    procedure send(b : std_logic) is
      variable exp_det : std_logic;
    begin
      wait until falling_edge(clk);  din <= b;           -- (1) drive
      wait until rising_edge(clk);                       -- (2) model
      hist := hist(2 downto 0) & b;
      wait for 1 ns;                                     -- (3) check
      if hist = "1011" then exp_det := '1';  exp_hits := exp_hits + 1;
      else                  exp_det := '0';
      end if;
      if detected = '1' then hits := hits + 1; end if;
      if detected /= exp_det then
        errors := errors + 1;
        if errors <= 10 then
          report "FAIL t=" & time'image(now) & " hist=" & to_string(hist) &
                 " detected=" & std_logic'image(detected) severity error;
        end if;
      end if;
    end procedure;

    procedure check_pat(s : string; n_exp : natural) is
      variable h0 : natural;
    begin
      reset_dut;
      h0 := hits;
      for i in s'range loop
        if s(i) = '1' then send('1'); else send('0'); end if;
      end loop;
      if hits - h0 /= n_exp then
        dir_fail := dir_fail + 1;
        report "FAIL pattern " & s & ": detected " & integer'image(hits - h0) &
               " times (expect " & integer'image(n_exp) & ")" severity error;
      else
        report "ok   pattern " & s & ": " & integer'image(n_exp) & " hit(s)";
      end if;
    end procedure;

  begin
    check_pat("1011011",  2);
    check_pat("10111011", 2);
    check_pat("1001011",  1);
    check_pat("11011",    1);
    check_pat("1010110",  1);
    check_pat("0000111",  0);

    reset_dut;                                           -- random
    for i in 1 to NRAND loop
      uniform(s1, s2, r);
      if r < 0.5 then send('0'); else send('1'); end if;
    end loop;

    report "errors=" & integer'image(errors) & " dir_fail=" & integer'image(dir_fail) &
           " hits=" & integer'image(hits) & " exp_hits=" & integer'image(exp_hits);
    if errors = 0 and dir_fail = 0 and exp_hits >= 20 then
      report "*** PASS ***";
    else
      report "*** FAIL ***" severity error;
    end if;
    done <= true;
    wait;
  end process;
end architecture;
```

`verilog/tb_seq_det_v.sv`

```systemverilog
`timescale 1ns/1ps
module tb_seq_det_v;
  parameter int NRAND = 1000;
  logic       clk = 0, rst_n = 0, din = 0;
  wire        detected;
  logic [3:0] hist = '0;                               // reference model
  int hits = 0, exp_hits = 0, errors = 0, dir_fail = 0;

  seq_det_1011 dut (.clk, .rst_n, .din, .detected);
  always #5 clk = ~clk;

  task automatic reset_dut();
    @(negedge clk) begin rst_n = 0; din = 0; end
    @(negedge clk) rst_n = 1;
    hist = '0;
  endtask

  task automatic send(input logic b);
    logic exp_det;
    @(negedge clk) din = b;                            // (1) drive
    @(posedge clk) hist = {hist[2:0], b};              // (2) model
    #1;                                                // (3) check
    exp_det = (hist == 4'b1011);
    if (exp_det)  exp_hits++;
    if (detected) hits++;
    if (detected !== exp_det) begin
      errors++;
      if (errors <= 10) $display("FAIL t=%0t hist=%b detected=%b", $time, hist, detected);
    end
  endtask

  task automatic check_pat(input string s, input int n_exp);   // ห้ามใช้ชื่อ expect (keyword)
    int h0;
    reset_dut();
    h0 = hits;
    foreach (s[i]) send(s[i] == "1");
    if (hits - h0 != n_exp) begin
      dir_fail++;
      $display("FAIL pattern %s: detected %0d times (expect %0d)", s, hits - h0, n_exp);
    end else
      $display("ok   pattern %s: %0d hit(s)", s, n_exp);
  endtask

  initial begin
    check_pat("1011011",  2);
    check_pat("10111011", 2);
    check_pat("1001011",  1);
    check_pat("11011",    1);
    check_pat("1010110",  1);
    check_pat("0000111",  0);

    reset_dut();
    repeat (NRAND) send($urandom_range(0, 1));

    $display("errors=%0d dir_fail=%0d hits=%0d exp_hits=%0d",
             errors, dir_fail, hits, exp_hits);
    if (errors == 0 && dir_fail == 0 && exp_hits >= 20) $display("*** PASS ***");
    else                                                 $display("*** FAIL ***");
    $finish;
  end
endmodule
```

เกณฑ์ `exp_hits >= 20` คือ coverage: ลำดับสุ่ม 1,000 บิตควรมี `1011` ประมาณ 1000/16 ≈ 60 ครั้ง ถ้าต่ำกว่า 20 แปลว่าตัวสุ่มมีปัญหา ไม่ใช่ DUT ผ่าน

### ขั้นที่ 4 — รันและดูชื่อ state ใน Wave (5 นาที)

```tcl
vdel -lib work -all;  vlib work
vcom -2008 vhdl/seq_det_1011.vhd vhdl/tb_seq_det.vhd
vsim -voptargs=+acc work.tb_seq_det
add wave /tb_seq_det/clk /tb_seq_det/rst_n /tb_seq_det/din
add wave /tb_seq_det/dut/state /tb_seq_det/detected     ;# VHDL: เห็น S0, S1, ... เอง
run -all
```

RTL Verilog เก็บ state เป็นตัวเลข — สร้าง radix ของตัวเองให้ Wave แสดงชื่อ:

```tcl
vdel -lib work -all;  vlib work
vlog verilog/seq_det_1011.v
vlog -sv verilog/tb_seq_det_v.sv
vsim -voptargs=+acc work.tb_seq_det_v
radix define seq_state {
  3'd0 "S0", 3'd1 "S1", 3'd2 "S10", 3'd3 "S101", 3'd4 "S1011", -default unsigned
}
add wave -radix seq_state /tb_seq_det_v/dut/state
add wave /tb_seq_det_v/din /tb_seq_det_v/detected
run -all
```

ผลที่คาด (บรรทัด `ok` 6 บรรทัด, ตัวเลข hits ตาม seed):

```text
ok   pattern 1011011: 2 hit(s)
ok   pattern 10111011: 2 hit(s)
...
errors=0 dir_fail=0 hits=... exp_hits=...
*** PASS ***
```

ใน Wave ให้ซูมที่ลำดับแรก แล้วเทียบ state ทีละ clock กับตาราง trace ด้านบน — จับภาพหน้าจอเก็บไว้ส่ง

### ขั้นที่ 5 — Bug injection: ทำไมต้องตรวจทุก clock (10 นาที)

| บั๊ก | แก้เป็น | `1011011` อย่างเดียว | testbench เต็ม |
| --- | --- | --- | --- |
| B1 ไม่ overlap | S1011 + 0 → S0 | FAIL (พบ 1 ครั้ง) | FAIL |
| B2 overlap ครึ่งเดียว | S1011 + 1 → S0 | **PASS** (ไม่เคยผ่าน transition นี้) | FAIL ที่ `10111011` และช่วงสุ่ม |
| B3 output แบบ Mealy | `detected <= '1' when next_state = S1011` | **PASS** ถ้านับแค่จำนวนครั้ง | FAIL ทุกครั้งที่พบ: สูงเร็วกว่าสเปก 1 clock |

บั๊ก B3 สอนสองเรื่อง: (1) testbench ใน Module 03 ที่นับ `hits` ที่ขอบขาขึ้นอย่างเดียวจะได้ 2 เท่าเดิม — **นับถูกไม่ได้แปลว่าเวลาถูก** (2) สัญญาณที่ decode จาก `next_state` ขึ้นกับ `din` ตรง ๆ จึงมี glitch ได้เมื่อ din เปลี่ยน เป็นเหตุผลที่ 3.6 แนะนำ Moore สำหรับ output ที่ออกไปบล็อกอื่น

## 3C — ไฟจราจรสี่แยก: FSM + timer (75 นาที)

### ขั้นที่ 1 — สเปกและการนับเวลา (10 นาที)

ทิศเหนือ-ใต้ (NS) และตะวันออก-ตก (EW) สลับกัน เอาต์พุตแต่ละทิศเป็น `{R, Y, G}` (แดง `100`, เหลือง `010`, เขียว `001`) เวลานับเป็นจำนวน `tick` ไม่ใช่จำนวน clock — ในวงจรจริง `tick` มาจาก `tick_gen` (เช่น 1 ครั้งต่อวินาที) ใน testbench เราสร้างเองทุก K clock

| State | NS | EW | อยู่นาน | ไปต่อ |
| --- | --- | --- | --- | --- |
| NS\_G | เขียว | แดง | T\_GREEN tick | NS\_Y |
| NS\_Y | เหลือง | แดง | T\_YELLOW tick | EW\_G |
| EW\_G | แดง | เขียว | T\_GREEN tick | EW\_Y |
| EW\_Y | แดง | เหลือง | T\_YELLOW tick | NS\_G |

กลไกนับเวลา: เมื่อเข้า state ใหม่ timer ถูกตั้งเป็น T − 1 แล้วลดทุก tick เมื่อเจอ tick ตอน timer = 0 (`expire`) จึงเปลี่ยน state → แต่ละ state อยู่พอดี T tick

**Trace ด้วยมือ 1 รอบ** (T\_GREEN = 5, T\_YELLOW = 2, tick = 1 ทุก clock; "clock ที่ n" = ช่วงก่อนขอบขาขึ้นครั้งที่ n หลังปล่อย reset)

| clock ที่ | state | timer | NS | EW | เหตุการณ์ที่ขอบขาขึ้น |
| --- | --- | --- | --- | --- | --- |
| 1–4 | NS\_G | 4 → 1 | เขียว | แดง | timer − 1 |
| 5 | NS\_G | 0 | เขียว | แดง | expire → NS\_Y, timer = 1 |
| 6 | NS\_Y | 1 | เหลือง | แดง | timer − 1 |
| 7 | NS\_Y | 0 | เหลือง | แดง | expire → EW\_G, timer = 4 |
| 8–11 | EW\_G | 4 → 1 | แดง | เขียว | timer − 1 |
| 12 | EW\_G | 0 | แดง | เขียว | expire → EW\_Y, timer = 1 |
| 13 | EW\_Y | 1 | แดง | เหลือง | timer − 1 |
| 14 | EW\_Y | 0 | แดง | เหลือง | expire → NS\_G, timer = 4 (ครบรอบ 14 tick) |

### ขั้นที่ 2 — RTL (จากหัวข้อ 3.6) (10 นาที)

`vhdl/traffic.vhd`

```vhdl
-- traffic.vhd : 4-way traffic light, Moore FSM + tick-based timer
library ieee;
use ieee.std_logic_1164.all;

entity traffic is
  generic (T_GREEN : positive := 5; T_YELLOW : positive := 2);   -- หน่วย = tick, ≤ 256
  port (
    clk, rst_n, tick   : in  std_logic;
    ns_light, ew_light : out std_logic_vector(2 downto 0)       -- {R, Y, G}
  );
end entity;

architecture rtl of traffic is
  type state_t is (NS_G, NS_Y, EW_G, EW_Y);
  signal state, next_state : state_t;
  signal timer  : integer range 0 to 255;
  signal expire : std_logic;
begin
  expire <= '1' when tick = '1' and timer = 0 else '0';

  -- (1) state register + timer
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        state <= NS_G;
        timer <= T_GREEN - 1;
      else
        state <= next_state;
        if expire = '1' then                        -- เข้า state ใหม่: ตั้งเวลาใหม่
          if next_state = NS_Y or next_state = EW_Y then
            timer <= T_YELLOW - 1;
          else
            timer <= T_GREEN - 1;
          end if;
        elsif tick = '1' then
          timer <= timer - 1;
        end if;
      end if;
    end if;
  end process;

  -- (2) next-state logic
  process(all)
  begin
    next_state <= state;                            -- default
    if expire = '1' then
      case state is
        when NS_G => next_state <= NS_Y;
        when NS_Y => next_state <= EW_G;
        when EW_G => next_state <= EW_Y;
        when EW_Y => next_state <= NS_G;
      end case;
    end if;
  end process;

  -- (3) Moore output
  process(all)
  begin
    ns_light <= "100";  ew_light <= "100";          -- default: แดงทั้งคู่
    case state is
      when NS_G => ns_light <= "001";
      when NS_Y => ns_light <= "010";
      when EW_G => ew_light <= "001";
      when EW_Y => ew_light <= "010";
    end case;
  end process;
end architecture;
```

`verilog/traffic.v`

```verilog
// traffic.v : 4-way traffic light, Moore FSM + tick-based timer
module traffic #(parameter T_GREEN = 5, parameter T_YELLOW = 2) (
  input  wire       clk, rst_n, tick,
  output reg  [2:0] ns_light, ew_light          // {R, Y, G}
);
  localparam NS_G = 2'd0, NS_Y = 2'd1, EW_G = 2'd2, EW_Y = 2'd3;
  reg [1:0] state, next_state;
  reg [7:0] timer;
  wire      expire = tick && (timer == 8'd0);

  // (1) state register + timer
  always @(posedge clk)
    if (!rst_n) begin
      state <= NS_G;
      timer <= T_GREEN - 1;
    end else begin
      state <= next_state;
      if (expire)
        timer <= (next_state == NS_Y || next_state == EW_Y) ? T_YELLOW - 1 : T_GREEN - 1;
      else if (tick)
        timer <= timer - 1'b1;
    end

  // (2) next-state logic
  always @(*) begin
    next_state = state;
    if (expire)
      case (state)
        NS_G:    next_state = NS_Y;
        NS_Y:    next_state = EW_G;
        EW_G:    next_state = EW_Y;
        EW_Y:    next_state = NS_G;
        default: next_state = NS_G;             // safe FSM
      endcase
  end

  // (3) Moore output
  always @(*) begin
    ns_light = 3'b100;  ew_light = 3'b100;      // default: แดงทั้งคู่
    case (state)
      NS_G: ns_light = 3'b001;
      NS_Y: ns_light = 3'b010;
      EW_G: ew_light = 3'b001;
      EW_Y: ew_light = 3'b010;
      default: ;
    endcase
  end
endmodule
```

จุดออกแบบที่ควรชี้ให้ผู้เรียนเห็น: (ก) timer เป็น register แยก ไม่ใช่ state 14 ตัว (ข) ค่า default ของเอาต์พุตคือ "แดงทั้งคู่" ซึ่งเป็นสถานะปลอดภัย (ค) `tick` เป็น clock enable ไม่ใช่ clock

### ขั้นที่ 3 — แปลงสเปกเป็นกฎที่ checker ตรวจได้ (10 นาที)

ไฟจราจรไม่มีอินพุตให้สุ่ม สิ่งที่ต้องทดสอบคือ **พฤติกรรมตลอดเวลา** จึงเขียนสเปกเป็นกฎที่ตรวจได้ทุก clock โดยไม่ต้องรู้ว่า state ภายในเป็นอะไร (black-box)

| กฎ | ความหมาย | ตรวจเมื่อ |
| --- | --- | --- |
| R1 | NS และ EW ไม่เขียวพร้อมกัน | ทุก clock |
| R2 | มีอย่างน้อยหนึ่งทิศเป็นไฟแดง | ทุก clock |
| R3 | แต่ละทิศเปิดไฟดวงเดียว (one-hot, ไม่มี X) | ทุก clock |
| R4 | เปลี่ยนได้เฉพาะ เขียว → เหลือง → แดง → เขียว | เมื่อสีเปลี่ยน |
| R5 | เขียวนาน T\_GREEN tick พอดี | ตอนออกจากเขียว |
| R6 | เหลืองนาน T\_YELLOW tick พอดี | ตอนออกจากเหลือง |
| R7 | หลัง reset NS เขียว EW แดง | clock แรกหลัง reset (ตั้ง `prev` ตอน reset แล้วให้ R4 จับ) |
| Cov | ครบอย่างน้อย 3 รอบ (นับ NS แดง → เขียว) | ตอนจบ |

**วิธีวัดเวลา (R5/R6):** ที่ขอบขาขึ้นทุกครั้ง ถ้าไฟเป็นเขียวและ `tick = 1` ให้บวกตัวนับ พอไฟเปลี่ยนจากเขียวให้เทียบกับ T\_GREEN — นับเป็น tick ไม่ใช่ clock จึงใช้ได้ทุกค่า K และไม่ขึ้นกับจังหวะของ tick ตอนปล่อย reset

### ขั้นที่ 4 — เขียน testbench แบบ checker (25 นาที)

Testbench มี 3 ส่วนทำงานขนานกัน: ตัวสร้าง tick (ทุก K clock), stimulus (reset แล้วรอ 3 รอบ) และ checker (ตรวจ R1–R7 ทุกขอบขาขึ้น) — checker อ่านค่าที่ขอบขาขึ้นก่อน DUT อัปเดต จึงเห็น "ค่าของ clock ที่เพิ่งจบ" ตรงกับตาราง trace

`vhdl/tb_traffic.vhd`

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity tb_traffic is
  generic (T_GREEN : positive := 5; T_YELLOW : positive := 2;
           K       : positive := 1);                 -- K = clock ต่อ 1 tick (≤ 8)
end entity;

architecture sim of tb_traffic is
  constant R : std_logic_vector(2 downto 0) := "100";
  constant Y : std_logic_vector(2 downto 0) := "010";
  constant G : std_logic_vector(2 downto 0) := "001";
  signal clk  : std_logic := '0';
  signal rst_n, tick : std_logic := '0';
  signal ns_l, ew_l : std_logic_vector(2 downto 0);   -- ห้ามตั้งชื่อ ns: ชนกับหน่วยเวลา ns
  signal done : boolean := false;
begin
  clk <= not clk after 5 ns when not done else '0';

  dut: entity work.traffic
    generic map (T_GREEN => T_GREEN, T_YELLOW => T_YELLOW)
    port map (clk => clk, rst_n => rst_n, tick => tick,
              ns_light => ns_l, ew_light => ew_l);

  -- ตัวสร้าง tick: สูง 1 clock ทุก K clock (เปลี่ยนที่ขอบขาลง)
  tick_p: process(clk)
    variable kc : natural := 0;                      -- VHDL ไม่แยกตัวพิมพ์: ห้ามตั้งชื่อ k
  begin
    if falling_edge(clk) then
      if kc = K - 1 then tick <= '1';  kc := 0;
      else               tick <= '0';  kc := kc + 1;
      end if;
    end if;
  end process;

  stim: process
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst_n <= '1';
    for i in 1 to 3 * 2 * (T_GREEN + T_YELLOW) * K + 20 loop   -- 3 รอบ + เผื่อ
      wait until falling_edge(clk);
    end loop;
    done <= true;
    wait;
  end process;

  checker: process
    variable ns_prev : std_logic_vector(2 downto 0) := G;
    variable ew_prev : std_logic_vector(2 downto 0) := R;
    variable ns_g, ns_y, ew_g, ew_y : natural := 0;  -- จำนวน tick ในช่วงปัจจุบัน
    variable errors, cycles : natural := 0;

    procedure err(msg : string) is
    begin
      errors := errors + 1;
      if errors <= 10 then
        report "FAIL t=" & time'image(now) & " " & msg severity error;
      end if;
    end procedure;

    procedure chk_dir(nm : string; cur, prev : std_logic_vector(2 downto 0);
                      gcnt, ycnt : inout natural) is
    begin
      if cur /= R and cur /= Y and cur /= G then                       -- R3
        err(nm & " not one-hot: " & to_string(cur));
      end if;
      if cur /= prev and not ((prev = G and cur = Y) or
                              (prev = Y and cur = R) or
                              (prev = R and cur = G)) then              -- R4, R7
        err(nm & " illegal " & to_string(prev) & " -> " & to_string(cur));
      end if;
      if prev = G and cur /= G then                                     -- R5
        if gcnt /= T_GREEN then
          err(nm & " green = " & integer'image(gcnt) & " ticks (expect " &
              integer'image(T_GREEN) & ")");
        end if;
        gcnt := 0;
      end if;
      if prev = Y and cur /= Y then                                     -- R6
        if ycnt /= T_YELLOW then
          err(nm & " yellow = " & integer'image(ycnt) & " ticks (expect " &
              integer'image(T_YELLOW) & ")");
        end if;
        ycnt := 0;
      end if;
      if cur = G and tick = '1' then gcnt := gcnt + 1; end if;
      if cur = Y and tick = '1' then ycnt := ycnt + 1; end if;
    end procedure;

  begin
    loop
      wait until rising_edge(clk) or done;
      exit when done;
      if rst_n = '0' then                            -- R7: หลัง reset ต้องเริ่มที่ NS เขียว
        ns_prev := G;  ew_prev := R;
        ns_g := 0;  ns_y := 0;  ew_g := 0;  ew_y := 0;
      else
        if ns_l = G and ew_l = G then err("both green"); end if;        -- R1
        if ns_l /= R and ew_l /= R then                                   -- R2
          err("no red: ns=" & to_string(ns_l) & " ew=" & to_string(ew_l));
        end if;
        if ns_prev = R and ns_l = G then cycles := cycles + 1; end if; -- coverage
        chk_dir("NS", ns_l, ns_prev, ns_g, ns_y);
        chk_dir("EW", ew_l, ew_prev, ew_g, ew_y);
        ns_prev := ns_l;  ew_prev := ew_l;
      end if;
    end loop;

    report "errors=" & integer'image(errors) & " cycles=" & integer'image(cycles);
    if errors = 0 and cycles >= 3 then
      report "*** PASS ***";
    else
      report "*** FAIL ***" severity error;
    end if;
    wait;
  end process;
end architecture;
```

`verilog/tb_traffic_v.sv`

```systemverilog
`timescale 1ns/1ps
module tb_traffic_v;
  parameter int T_GREEN = 5, T_YELLOW = 2, K = 1;   // K = clock ต่อ 1 tick (≤ 8)
  localparam logic [2:0] R = 3'b100, Y = 3'b010, G = 3'b001;

  logic       clk = 0, rst_n = 0, tick = 0;
  wire  [2:0] ns, ew;                                // {R, Y, G}
  logic [2:0] ns_prev = G, ew_prev = R;
  int errors = 0, cycles = 0, kc = 0;
  int ns_g = 0, ns_y = 0, ew_g = 0, ew_y = 0;        // จำนวน tick ในช่วงปัจจุบัน

  traffic #(.T_GREEN(T_GREEN), .T_YELLOW(T_YELLOW)) dut (
    .clk, .rst_n, .tick, .ns_light(ns), .ew_light(ew));

  always #5 clk = ~clk;

  always @(negedge clk)                              // tick ทุก K clock
    if (kc == K - 1) begin tick <= 1; kc <= 0;      end
    else             begin tick <= 0; kc <= kc + 1; end

  function automatic void err(string msg);
    errors++;
    if (errors <= 10) $display("FAIL t=%0t %s", $time, msg);
  endfunction

  task automatic chk_dir(input string nm, input logic [2:0] cur, prev,
                         ref int gcnt, ref int ycnt);
    if (!(cur === R || cur === Y || cur === G))                       // R3 (=== จับ X)
      err($sformatf("%s not one-hot: %b", nm, cur));
    if (cur !== prev && !((prev === G && cur === Y) ||
                          (prev === Y && cur === R) ||
                          (prev === R && cur === G)))                 // R4, R7
      err($sformatf("%s illegal %b -> %b", nm, prev, cur));
    if (prev === G && cur !== G) begin                                // R5
      if (gcnt != T_GREEN) err($sformatf("%s green = %0d ticks (expect %0d)", nm, gcnt, T_GREEN));
      gcnt = 0;
    end
    if (prev === Y && cur !== Y) begin                                // R6
      if (ycnt != T_YELLOW) err($sformatf("%s yellow = %0d ticks (expect %0d)", nm, ycnt, T_YELLOW));
      ycnt = 0;
    end
    if (cur === G && tick) gcnt++;
    if (cur === Y && tick) ycnt++;
  endtask

  always @(posedge clk) begin                        // checker
    if (!rst_n) begin
      ns_prev = G;  ew_prev = R;
      ns_g = 0;  ns_y = 0;  ew_g = 0;  ew_y = 0;
    end else begin
      if (ns === G && ew === G) err("both green");                    // R1
      if (ns !== R && ew !== R) err($sformatf("no red: ns=%b ew=%b", ns, ew));  // R2
      if (ns_prev === R && ns === G) cycles++;
      chk_dir("NS", ns, ns_prev, ns_g, ns_y);
      chk_dir("EW", ew, ew_prev, ew_g, ew_y);
      ns_prev = ns;  ew_prev = ew;
    end
  end

  initial begin
    repeat (3) @(negedge clk);
    rst_n = 1;
    repeat (3 * 2 * (T_GREEN + T_YELLOW) * K + 20) @(negedge clk);
    $display("errors=%0d cycles=%0d", errors, cycles);
    if (errors == 0 && cycles >= 3) $display("*** PASS ***");
    else                            $display("*** FAIL ***");
    $finish;
  end
endmodule
```

สังเกตว่า checker ไม่ได้อ่าน `state` หรือ `timer` ของ DUT เลย — จึงใช้ตรวจไฟจราจรที่เขียนด้วยโครงสร้างอื่น (เช่น 1-process หรือ one-hot) ได้ทันทีโดยไม่ต้องแก้ testbench แม้แต่บรรทัดเดียว

### ขั้นที่ 5 — รันหลายค่า parameter (10 นาที)

```tcl
vdel -lib work -all;  vlib work
vcom -2008 vhdl/traffic.vhd vhdl/tb_traffic.vhd
vsim -voptargs=+acc work.tb_traffic
add wave /tb_traffic/clk /tb_traffic/tick /tb_traffic/rst_n
add wave /tb_traffic/dut/state
add wave -radix unsigned /tb_traffic/dut/timer
add wave -radix binary /tb_traffic/ns_l /tb_traffic/ew_l
run -all
wave zoom full
```

จากนั้นรัน batch ด้วย parameter ชุดอื่น (ทุกชุดต้อง PASS):

```tcl
vsim -c work.tb_traffic                          -do "run -all; quit -f"
vsim -c -gK=3 work.tb_traffic                    -do "run -all; quit -f"
vsim -c -gT_GREEN=3 -gT_YELLOW=1 work.tb_traffic -do "run -all; quit -f"
```

`-g` ตั้ง generic ของ testbench ซึ่งส่งต่อให้ DUT ผ่าน `generic map` อีกที คำสั่งเดียวกันใช้กับ `work.tb_traffic_v` ได้ (หลังคอมไพล์ Verilog RTL) ผลที่คาดที่ T\_GREEN = 5, T\_YELLOW = 2:

```text
# ** Note: errors=0 cycles=4
# ** Note: *** PASS ***
```

(เวลารัน 3 รอบ + เผื่อ 20 clock ทำให้ที่ K = 1 เห็น NS กลับเป็นเขียว 4 ครั้ง ส่วน K = 3 จะได้ 3 — เกณฑ์คือ `cycles >= 3`)

ใน Wave ให้วาง cursor ที่ต้นและท้ายช่วง NS\_G ตอน K = 3 — ควรห่างกัน 5 × 3 = 15 clock (150 ns) จับภาพครบ 1 รอบที่เห็นชื่อ state เก็บไว้ส่ง

### ขั้นที่ 6 — Bug injection (10 นาที)

| บั๊ก | แก้เป็น | ผลที่ควรเห็น |
| --- | --- | --- |
| C1 เหลืองใช้เวลาเขียว | timer ตั้ง `T_GREEN - 1` ทุก state | R6: `NS yellow = 5 ticks (expect 2)` |
| C2 ลืม default ของ EW | ลบ `ew_light <= "100"` ออกจากบรรทัด default | R3 ตอนต้น (EW เป็น U/X) และ R2 หลังรอบแรก (EW ค้างเหลือง = latch) |
| C3 timer ไม่รอ tick | `elsif tick = '1' then` → `else` (ลดทุก clock) | K = 1 **PASS** — K = 3: Verilog เขียวนานผิด (timer วนจาก 0 ไป 255), VHDL หยุดด้วย fatal เพราะ timer = −1 ออกนอก `range 0 to 255` |
| C4 ข้ามไฟเหลือง | `when EW_G => next_state <= NS_G;` | R4: `EW illegal 001 -> 100` |

บั๊ก C3 คือบทเรียนเดียวกับ A3 และ B2: testbench ที่รันแค่ "กรณีสะดวก" (tick ทุก clock) มองไม่เห็นบั๊ก และยังแสดงข้อดีของการจำกัดช่วง `integer range` ใน VHDL ที่ทำให้ simulator หยุดทันทีที่จุดเกิดเหตุ

## 3D — รวมทุกอย่างเป็น regression (15 นาที)

ตอนนี้มี RTL 3 ตัว × 2 ภาษา และ testbench 3 ตัว × 2 ภาษา บวก parameter หลายชุด — รันทีละตัวด้วยมือจะพลาดง่าย จึงทำ 2 ไฟล์: `run.do` รัน 1 ชุด และ `regress.sh` เรียก `run.do` ทุกชุดแล้วสรุปผล

### ขั้นที่ 1 — `run.do`

```tcl
# run.do — ตัวอย่างการใช้
#   GUI  : vsim -do "set RTL vhdl; set TOP tb_seq_det; do run.do"
#   batch: vsim -c -do "set RTL verilog; set TOP tb_traffic_v; set GEN {-gK=3}; set BATCH 1; do run.do"
onerror {quit -f -code 1}                    ;# compile error → ออกทันที (ไม่ค้างใน batch)
if {![info exists RTL]}   { set RTL vhdl }
if {![info exists TOP]}   { set TOP tb_counter }
if {![info exists GEN]}   { set GEN {} }
if {![info exists BATCH]} { set BATCH 0 }

if {[file exists work]} { vdel -lib work -all }
vlib work

# RTL ภาษาเดียว (ชื่อ design unit ซ้ำกันทั้งสองภาษา)
if {$RTL eq "vhdl"} {
  vcom -2008 vhdl/counter.vhd vhdl/seq_det_1011.vhd vhdl/traffic.vhd
} else {
  vlog verilog/counter.v verilog/seq_det_1011.v verilog/traffic.v
}

# testbench เฉพาะตัวที่จะรัน (ชื่อลงท้าย _v = SystemVerilog)
if {[string match *_v $TOP]} {
  vlog -sv verilog/$TOP.sv
} else {
  vcom -2008 vhdl/$TOP.vhd
}

if {$BATCH} {
  eval vsim -c -onfinish stop $GEN work.$TOP
  run -all
  quit -f
} else {
  eval vsim -voptargs=+acc -onfinish stop $GEN work.$TOP
  add wave -r /$TOP/*
  run -all
  wave zoom full
}
```

จุดสำคัญ:

- `-onfinish stop` ทำให้ `$finish` ใน SV แค่หยุด simulation แต่คืนการควบคุมให้สคริปต์ พฤติกรรมจึงเหมือน testbench VHDL ที่หยุดด้วย `done`
- บรรทัด batch ไม่ใส่ `+acc` และไม่เปิด Wave — เร็วกว่าและใช้หน่วยความจำน้อย
- compile เฉพาะ testbench ที่จะรัน เพราะ testbench อีกภาษาอาจต้องใช้ license mixed-language แม้ไม่ได้รัน

### ขั้นที่ 2 — `regress.sh`

```bash
#!/usr/bin/env bash
# regress.sh — รันทุก testbench แบบ batch แล้วสรุปผล
#   ./regress.sh            → 20 ชุด (รวมข้ามภาษา)
#   MIXED=0 ./regress.sh    → 10 ชุด (RTL กับ TB ภาษาเดียวกัน)
cd "$(dirname "$0")"
MIXED=${MIXED:-1}
mkdir -p logs
pass=0; fail=0

run() {   # run <rtl> <top> <generic> <tag>
  local rtl=$1 top=$2 gen=$3 tag=$4
  local log=logs/$tag.log
  vsim -c -do "set RTL $rtl; set TOP $top; set GEN {$gen}; set BATCH 1; do run.do" \
       < /dev/null > "$log" 2>&1
  if grep -q '\*\*\* PASS \*\*\*' "$log" && ! grep -q 'Fatal' "$log"; then
    echo "PASS  $tag";  pass=$((pass + 1))
  else
    echo "FAIL  $tag   (see $log)";  fail=$((fail + 1))
  fi
}

for rtl in vhdl verilog; do
  for tb in vhdl sv; do
    if [ "$MIXED" = 0 ]; then
      [ "$rtl" = vhdl ]    && [ "$tb" = sv ]   && continue
      [ "$rtl" = verilog ] && [ "$tb" = vhdl ] && continue
    fi
    s=""; [ "$tb" = sv ] && s="_v"
    t="rtl=${rtl}_tb=${tb}"
    run $rtl tb_counter$s  ""       "${t}_counter"
    run $rtl tb_counter$s  "-gN=8"  "${t}_counter_n8"
    run $rtl tb_seq_det$s  ""       "${t}_seqdet"
    run $rtl tb_traffic$s  ""       "${t}_traffic"
    run $rtl tb_traffic$s  "-gK=3"  "${t}_traffic_k3"
  done
done
echo "Summary: $pass pass, $fail fail"
[ "$fail" -eq 0 ]                       # exit code ใช้ใน CI ได้
```

บน Windows ให้รันผ่าน Git Bash หรือ WSL ที่มองเห็น `vsim` ใน PATH — เงื่อนไข `grep 'Fatal'` กันกรณี simulation หยุดกลางคัน (เช่นบั๊ก C3 ใน VHDL) และ `< /dev/null` กัน vsim ค้างรออินพุต

### ขั้นที่ 3 — รันและทดลองใส่บั๊ก

```bash
chmod +x regress.sh
./regress.sh
```

```text
PASS  rtl=vhdl_tb=vhdl_counter
PASS  rtl=vhdl_tb=vhdl_counter_n8
PASS  rtl=vhdl_tb=vhdl_seqdet
...
PASS  rtl=verilog_tb=sv_traffic_k3
Summary: 20 pass, 0 fail
```

จากนั้นใส่บั๊ก A3 (ผูกความกว้าง `4'hF`) ใน `verilog/counter.v` แล้วรันอีกครั้ง — ควร FAIL เฉพาะ `rtl=verilog_*_counter_n8` 2 ชุด เอา RTL กลับคืน แล้วลองบั๊ก C3 ใน `vhdl/traffic.vhd` — ควร FAIL เฉพาะ `rtl=vhdl_*_traffic_k3` รูปแบบของชุดที่ FAIL บอกทั้งไฟล์และเงื่อนไขที่ทำให้พัง ก่อนเปิด log ดูเสียอีก

> **กรณีข้ามภาษา:** testbench VHDL ใช้ `entity work.counter` กับ RTL ที่เป็น Verilog module — บางรุ่นของ ModelSim ต้องเปลี่ยนเป็น component declaration ตามที่อธิบายไว้ใน Lab 2 หัวข้อ 2E ถ้า license ไม่รองรับ mixed-language ให้ใช้ `MIXED=0 ./regress.sh` ผลที่คาดคือ `Summary: 10 pass, 0 fail`

## แก้ปัญหา, คำถามท้าย Lab และการประเมิน

**ตารางแก้ปัญหาที่พบบ่อยใน Lab 3** (ข้อความจริงอาจต่างตามรุ่น ModelSim)

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| ผล PASS/FAIL ต่างกันระหว่าง TB VHDL กับ SV หรือเปลี่ยนตามรุ่น simulator | TB เปลี่ยนอินพุตที่ขอบขาขึ้นพอดี (race) | ป้อนที่ขอบขาลงตาม 3.0 |
| FAIL ตั้งแต่ clock แรก `q=0 exp=...` หรือ detected ช้าไป 1 clock | ตรวจก่อนขอบขาขึ้น หรืออัปเดต model ผิดจังหวะ | ลำดับใน `step`/`send` ต้องเป็น ป้อน → ขอบขาขึ้น + model → 1 ns → ตรวจ |
| VHDL: `Cannot drive signal ... from this subprogram` | ประกาศ procedure ไว้ใน architecture แทนใน process | ย้ายเข้าไปในส่วนประกาศของ process |
| VHDL: `k is already declared` | VHDL ไม่แยกตัวพิมพ์เล็ก-ใหญ่ `k` ชน generic `K` | ตั้งชื่อใหม่เป็น `kc` |
| SV: syntax error ที่ `expect` | `expect` เป็น keyword ของ SystemVerilog | ใช้ `n_exp` |
| `run -all` ไม่จบ (VHDL) | clock ไม่หยุด เพราะลืม `done <= true` | ตั้ง `done` บรรทัดสุดท้ายของ stimulus |
| `regress.sh` ค้างที่ชุด SV | `$finish` ถามยืนยัน หรือ vsim รออินพุต | `-onfinish stop` ใน `run.do` + `< /dev/null` |
| `** Fatal: ... Value -1 is out of range 0 to 255` | timer ลดต่ำกว่า 0 (บั๊ก C3) หรือ T\_GREEN > 256 | ลดเฉพาะตอน `tick = 1` และตรวจช่วง generic |
| checker ฟ้อง `not one-hot: UUU` ตอนต้น | ตรวจตั้งแต่ก่อน reset หรือ output ไม่มี default (C2) | checker ทำงานเมื่อ `rst_n = 1` เท่านั้น; ใส่ default ใน output process |
| Wave แสดง state เป็นตัวเลข (Verilog) | `localparam` ไม่มีชื่อใน simulator | `radix define` (3B ขั้นที่ 4) หรือใช้ SV `typedef enum` |
| `Unable to find design unit tb_counter_v` | compile TB ผิดภาษา หรือล้าง `work` แล้วไม่ได้ compile ใหม่ | ใช้ `run.do` ซึ่งเลือก TB ตาม `_v` ให้เอง |
| coverage ไม่ครบ (`wraps=0` หรือ `cycles<3`) ทั้งที่ errors = 0 | stimulus สั้นเกินไป เช่นลด NRAND หรือ K ใหญ่เกิน 8 | เพิ่มเวลารัน — อย่าลดเกณฑ์ coverage |

**คำถามท้าย Lab**

1. ถ้าเปลี่ยน sequence detector เป็น Mealy จะใช้กี่ state และ detected เร็วขึ้นกี่ clock — ต้องแก้ reference ใน testbench อย่างไร
2. ไฟจราจรครบรอบใช้กี่ tick ถ้าต่อกับ `tick_gen` DIV = 100,000,000 ที่ clock 100 MHz จะใช้เวลาจริงกี่วินาที และทำไมจึงไม่จำลองด้วย DIV ค่านั้น
3. เพิ่มปุ่มคนข้ามถนน `ped_req` ที่ตัดไฟเขียว NS ให้เหลืองทันที ต้องแก้ next-state, timer และกฎ R5 ใน checker อย่างไร
4. ถ้า counter ใช้ asynchronous reset (`always @(posedge clk or negedge rst_n)`) testbench ใน 3A จะจับได้ไหมว่าไม่ตรงสเปก เพราะอะไร และต้องเพิ่มการตรวจตรงไหน
5. ต่อ counter 4 บิต 2 ตัวเป็น 8 บิต ต้องต่อ `en` ของตัวบนอย่างไร และถ้า `tc` ไม่สน `en` (บั๊ก A2) จะเกิดอะไร
6. บั๊ก A3, B2, B3 และ C3 มีอะไรเหมือนกัน และสอนอะไรเกี่ยวกับการออกแบบ testbench
7. ทำไม PASS ต้องมี coverage ครบด้วย — ยกตัวอย่าง testbench ที่ errors = 0 แต่ไม่ได้พิสูจน์อะไรเลย

**เฉลยสำหรับผู้สอน**

| ข้อ | แนวคำตอบ |
| --- | --- |
| 1 | 4 state (S0, S1, S10, S101) — detected = `(state = S101) and din = '1'` ขึ้นใน clock ที่บิตสุดท้ายยังอยู่ที่ din จึงเร็วขึ้น 1 clock; reference ต้องตรวจก่อนขอบขาขึ้น เทียบกับ `{hist[2:0], din} == 1011` (นี่คือพฤติกรรมของบั๊ก B3 ซึ่งผิดสเปก Moore แต่ถูกสเปก Mealy) |
| 2 | 2 × (5 + 2) = 14 tick = 14 วินาที; จำลองจริงต้องใช้ 1.4 พันล้าน clock — จึงทดสอบ `traffic` ด้วย tick ที่ testbench สร้างเอง และทดสอบ `tick_gen` แยกด้วย `-gDIV=10` |
| 3 | next-state: `NS_G` ไป `NS_Y` เมื่อ `expire or ped_req`; timer ต้องตั้งใหม่เมื่อ state เปลี่ยนด้วยเหตุใดก็ตาม (ใช้ `next_state /= state` แทน `expire`); checker R5 เปลี่ยนเป็น "เขียว ≤ T\_GREEN และถ้าสั้นกว่าต้องมี ped\_req" + กฎใหม่ "ped\_req ตอน NS เขียว → clock ถัดไปต้องเหลือง" (ควรกำหนดเวลาเขียวขั้นต่ำด้วย ไม่เช่นนั้นคนกดปุ่มค้างทำให้ NS แทบไม่ได้เขียว) |
| 4 | จับไม่ได้ — testbench ตั้ง `rst_n = 0` ที่ขอบขาลงและตรวจหลังขอบขาขึ้น ซึ่งทั้งสองแบบให้ q = 0 เหมือนกัน; ต้องเพิ่มการตรวจหลังตั้ง `rst_n = 0` 1 ns (ก่อนขอบขาขึ้น) ว่า q ยังไม่เปลี่ยน |
| 5 | `en_hi = tc_lo` (tc ของตัวล่างรวม en แล้ว) ถ้า tc ไม่สน en ตัวบนจะนับทุก clock ที่ตัวล่างค้างที่ 15 ขณะหยุดนับ (en = 0) — ผลรวม 8 บิตผิด |
| 6 | ทุกตัว PASS ใน "กรณีสะดวก" (N = 4, ลำดับเดียว, นับแค่จำนวน, tick ทุก clock) — testbench ต้องรันหลาย parameter, หลายลำดับ + สุ่ม และตรวจทุก clock ไม่ใช่แค่ผลรวม |
| 7 | เช่น TB ไฟจราจรที่รันแค่ 10 clock: ไม่เคยออกจากไฟเขียว R4–R6 ไม่เคยถูกตรวจ แต่ errors = 0; หรือ TB counter ที่ en = 0 ตลอด — coverage คือหลักฐานว่าสิ่งที่ต้องตรวจเกิดขึ้นจริง |

**งานที่ต้องส่ง** (บีบอัด `lab03_seq/` โดยลบ `work/`, `*.wlf`, `transcript` ออก เก็บ `logs/` ไว้)

1. `doc/`: ตาราง trace ด้วยมือทั้ง 3 ตาราง (counter, 1011011, ไฟจราจร 1 รอบ) และ state diagram ที่วาดเอง
2. RTL 3 ตัว × 2 ภาษา, testbench 3 ตัว × 2 ภาษา, `run.do`, `regress.sh`
3. Output ของ `./regress.sh` (`Summary: 20 pass, 0 fail` หรือ 10/10 พร้อมเหตุผลเรื่อง license)
4. บันทึก bug injection 10 ตัว (A1–A3, B1–B3, C1–C4): แก้อะไร, ชุดไหน FAIL, ข้อความ FAIL แรก
5. Screenshot Wave: ไฟจราจรครบ 1 รอบที่เห็นชื่อ state และ timer (K = 3, มี cursor วัดช่วงเขียว) และ sequence detector ที่ลำดับ 1011011
6. คำตอบคำถาม 7 ข้อ

**เกณฑ์ให้คะแนน Lab 3 (100 คะแนน)**

| หัวข้อ | คะแนน | เต็ม | บางส่วน |
| --- | --- | --- | --- |
| Trace ด้วยมือ + state diagram | 10 | 3 ตารางถูกต้อง, diagram มี 10 transition ครบ | ผิด ≤ 2 จุด |
| 3A Counter | 20 | RTL สองภาษา PASS ทั้ง N = 4 และ 8, coverage ครบ, A1–A3 | ภาษาเดียว หรือ N = 4 เท่านั้น |
| 3B Sequence detector | 25 | 6 ลำดับ + สุ่ม PASS สองภาษา, ตรวจทุก clock, อธิบาย B2/B3 ได้ | ตรวจแค่จำนวนครั้ง |
| 3C ไฟจราจร | 25 | checker R1–R7 + coverage, PASS ทุกชุด parameter, C1–C4 | ตรวจแค่ R1/R2 |
| 3D Regression | 10 | 20/20 (หรือ 10/10 + อธิบาย license), ทดลองใส่บั๊กแล้วอ่านรูปแบบ FAIL ได้ | รันได้เฉพาะ GUI |
| คำตอบ 7 ข้อ | 10 | ถูกต้องพร้อมหลักฐานจาก simulation | ไม่มีหลักฐาน |

**หมายเหตุสำหรับผู้สอน:** จุดที่ผู้เรียนติดมากที่สุดคือจังหวะ "ป้อน → อัปเดต → ตรวจ" ใน 3.0 — ควรเดิน trace ตาราง counter บนกระดานพร้อม waveform จริงก่อนเริ่ม 3A ส่วน 3C ใช้เวลามากที่สุด ถ้าเวลาไม่พอให้แจก testbench ภาษาหนึ่งแล้วให้ผู้เรียนแปลงเป็นอีกภาษาเอง

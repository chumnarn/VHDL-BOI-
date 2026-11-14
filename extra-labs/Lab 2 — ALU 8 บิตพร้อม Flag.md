# Lab 2 — ALU 8 บิตพร้อม Flag

Oct 28, 2026 · @Chumnarn Punyasai

## ภาพรวม Lab 2 (ประมาณ 4 ชั่วโมง)

Lab ประกอบ Module 03 — Practice RTL Design ใน คู่มือหลักสูตร Learn Digital IC Design from Scratch! ต่อยอดจาก Lab 1 — Logic Gate, Multiplexer และ Hierarchy (ใช้โครง `run.do` และ `regress.sh` แบบเดียวกัน)

**เป้าหมาย:** ออกแบบ ALU combinational 8 คำสั่ง ทั้ง VHDL และ Verilog แล้วพิสูจน์ด้วย testbench ที่เทียบกับ reference model ทุกค่า (exhaustive) ใน ModelSim

### สเปก

| op | คำสั่ง | y | carry | ovf |
| --- | --- | --- | --- | --- |
| 000 | ADD | a + b | carry out | signed overflow |
| 001 | SUB | a − b | 1 = borrow (a < b แบบ unsigned) | signed overflow |
| 010 | AND | a & b | 0 | 0 |
| 011 | OR | a \| b | 0 | 0 |
| 100 | XOR | a ^ b | 0 | 0 |
| 101 | SLL | a << b\[2:0\] | 0 | 0 |
| 110 | SRL | a >> b\[2:0\] (เติม 0) | 0 | 0 |
| 111 | SLT | 1 ถ้า signed(a) < signed(b) ไม่เช่นนั้น 0 | 0 | 0 |

`zero` = 1 เมื่อ y = 0 ทุกคำสั่ง · ALU เป็น combinational ล้วน (ไม่มี clock)

**Interface** (ชื่อเดียวกันทั้งสองภาษา — จำเป็นสำหรับการทดสอบข้ามภาษาใน 2E)

| พอร์ต | ทิศ | ชนิด VHDL | ชนิด Verilog |
| --- | --- | --- | --- |
| a, b | in | `std_logic_vector(7 downto 0)` | `wire [7:0]` |
| op | in | `std_logic_vector(2 downto 0)` | `wire [2:0]` |
| y | out | `std_logic_vector(7 downto 0)` | `reg [7:0]` |
| zero, carry, ovf | out | `std_logic` | `wire` / `reg` |

### ตารางเวลา

| ส่วน | งาน | เวลา |
| --- | --- | --- |
| 2.0 | ทฤษฎี flag + block diagram + คำนวณ corner case ด้วยมือ | 40 นาที |
| 2A | RTL VHDL | 40 นาที |
| 2B | RTL Verilog | 30 นาที |
| 2C | Directed testbench (corner case) | 40 นาที |
| 2D | Exhaustive testbench + reference model | 45 นาที |
| 2E | Mixed-language + run.do + regression | 30 นาที |
| — | คำถามท้าย Lab | 15 นาที |

### โครงโฟลเดอร์

```text
lab02_alu/
├── vhdl/      alu8.vhd        tb_alu8_dir.vhd   tb_alu8_exh.vhd
├── verilog/   alu8.v          tb_alu8_dir.sv    tb_alu8_exh.sv
├── doc/       block_diagram.png  hand_calc.md
├── run.do
└── regress.sh
```

**ความรู้ที่ต้องมี:** two's complement, การบวก/ลบเลขฐานสอง (Module 01), `numeric_std` และ `$signed` (Module 02), Lab 1 (do-file, self-checking testbench)

## Lab 2.0 — ทฤษฎี Flag, Block Diagram และคำนวณด้วยมือ (40 นาที)

**เป้าหมายย่อย:** เข้าใจว่า carry, borrow และ signed overflow คำนวณจากอะไร **ก่อน**เขียนโค้ด และสร้างตาราง corner case ที่คำนวณด้วยมือ — ตารางนี้คืออินพุตของ directed testbench ใน 2C

**ขั้นที่ 1 — วาด block diagram** (วาดลงกระดาษแล้วถ่ายรูปเก็บไว้ใน `doc/block_diagram.png`)

&#91;embedded content: Block diagram ALU · ทุก datapath คำนวณพร้อมกัน แล้ว op เลือกผล — carry/ovf มาจาก Add/Sub เท่านั้น\]

แนวคิดสำคัญ: ฮาร์ดแวร์คำนวณ**ทุก**ผลพร้อมกันตลอดเวลา แล้ว mux เลือกออกมาหนึ่งตัว — `case` ใน RTL คือ mux ไม่ใช่ "if แล้วค่อยคำนวณ" แบบซอฟต์แวร์

**ขั้นที่ 2 — ทำความเข้าใจสูตร flag**

| Flag | คำนวณจาก | ความหมาย |
| --- | --- | --- |
| carry (ADD) | บิตที่ 8 ของผลบวก 9 บิต `('0' & a) + ('0' & b)` | ผลบวก unsigned เกิน 255 |
| carry (SUB) = borrow | บิตที่ 8 ของผลลบ 9 บิต `('0' & a) − ('0' & b)` | a < b แบบ unsigned (ต้องยืม) |
| ovf (ADD) | `(a7 = b7) and (y7 /= a7)` | บวกเลขเครื่องหมายเดียวกันแล้วได้เครื่องหมายตรงข้าม |
| ovf (SUB) | `(a7 /= b7) and (y7 /= a7)` | ลบเลขต่างเครื่องหมายแล้วผลเครื่องหมายผิด |
| SLT | `diff7 xor ovf_sub` | เครื่องหมายของ a−b แก้ด้วย overflow (ใช้ diff7 อย่างเดียวผิดเมื่อ overflow) |
| zero | `y = 0` (NOR ทุกบิตของ y) | ทุกคำสั่ง |

จุดที่ผู้เรียนสับสนบ่อยที่สุด: **carry เป็นเรื่อง unsigned, ovf เป็นเรื่อง signed** — ผลบวกครั้งเดียวอาจมี carry แต่ไม่ ovf (0xFF + 0x01) หรือ ovf แต่ไม่มี carry (0x7F + 0x01) ส่วนเรื่อง borrow: บาง CPU (เช่น ARM) ใช้ carry = 1 เมื่อ**ไม่**ยืม แต่สเปกของ Lab นี้กำหนด carry = 1 เมื่อ**ยืม** — ต้องทำตามสเปกเสมอ

**ขั้นที่ 3 — คำนวณ corner case ด้วยมือ** เก็บใน `doc/hand_calc.md` (ผู้เรียนควรปิดคอลัมน์ผลแล้วคำนวณเองก่อน จากนั้นเทียบ)

| # | op | a | b | y | zero | carry | ovf | เหตุผลที่เลือกกรณีนี้ |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | ADD | 01 | 01 | 02 | 0 | 0 | 0 | กรณีปกติ |
| 2 | ADD | 7F | 01 | 80 | 0 | 0 | 1 | 127+1 ล้นฝั่งบวก (signed) |
| 3 | ADD | FF | 01 | 00 | 1 | 1 | 0 | −1+1 = 0: carry แต่ไม่ ovf |
| 4 | ADD | 80 | 80 | 00 | 1 | 1 | 1 | −128 + −128: ทั้ง carry และ ovf |
| 5 | SUB | 55 | 55 | 00 | 1 | 0 | 0 | ลบตัวเอง |
| 6 | SUB | 00 | 01 | FF | 0 | 1 | 0 | ยืม แต่ 0−1 = −1 ถูกต้องแบบ signed |
| 7 | SUB | 80 | 01 | 7F | 0 | 0 | 1 | −128−1 ล้นฝั่งลบ |
| 8 | SUB | 7F | FF | 80 | 0 | 1 | 1 | 127−(−1) = 128 ล้น + ยืม |
| 9 | AND | F0 | 0F | 00 | 1 | 0 | 0 | zero จากคำสั่ง logic |
| 10 | OR | F0 | 0F | FF | 0 | 0 | 0 |  |
| 11 | XOR | AA | FF | 55 | 0 | 0 | 0 | XOR กับ FF = NOT |
| 12 | SLL | 81 | 01 | 02 | 0 | 0 | 0 | บิตบนหลุดทิ้ง |
| 13 | SLL | 01 | 0F | 80 | 0 | 0 | 0 | ใช้เฉพาะ b\[2:0\] = 7 |
| 14 | SRL | 80 | 07 | 01 | 0 | 0 | 0 | shift สูงสุด |
| 15 | SRL | 80 | 08 | 80 | 0 | 0 | 0 | b\[2:0\] = 0 → ไม่ shift |
| 16 | SLT | 80 | 7F | 01 | 0 | 0 | 0 | −128 < 127 |
| 17 | SLT | 7F | 80 | 00 | 1 | 0 | 0 | กับดัก: a−b = FF (เครื่องหมายลบ) แต่ ovf = 1 → ผล 0 |
| 18 | SLT | FF | 00 | 01 | 0 | 0 | 0 | −1 < 0 (unsigned จะตอบผิด) |
| 19 | SLT | 05 | 05 | 00 | 1 | 0 | 0 | เท่ากัน |

(ค่าเป็นฐานสิบหก)

**ขั้นที่ 4 — ตรวจคำนวณแถวที่ 8 แบบละเอียด** (ให้ผู้เรียนทำตามทุกบรรทัด)

```text
  a = 0111_1111 (0x7F, +127)     b = 1111_1111 (0xFF, −1 / 255)
  9-bit: 0_0111_1111 − 0_1111_1111 = 1_1000_0000
                                     │ └─ y = 1000_0000 = 0x80
                                     └─── bit8 = 1 → borrow (127 < 255)
  ovf_sub = (a7 /= b7) and (y7 /= a7) = (0 /= 1) and (1 /= 0) = 1
  signed: 127 − (−1) = 128 เกิน +127 → ovf ถูกต้อง
```

✅ **Checkpoint 2.0:** block diagram ครบ 4 datapath + mux + flag และตาราง 19 แถวคำนวณเองแล้วตรงกับเฉลยทุกค่า

## Lab 2A — RTL ภาษา VHDL (40 นาที)

**เป้าหมายย่อย:** แปลง block diagram เป็น RTL ที่อ่านง่าย ไม่มี latch และตรวจเบื้องต้นด้วยคำสั่ง `force` ก่อนมี testbench

**ขั้นที่ 1 — ประกาศ entity ตาม interface ในสเปกและตั้งชื่อ opcode เป็น constant** (ห้ามใช้เลขฐานสองลอย ๆ ใน `case` — อ่านยากและพิมพ์ผิดง่าย)

**ขั้นที่ 2 — คำนวณ datapath ที่ใช้ร่วมกันเป็น signal นอก process** — ผลบวก/ลบ 9 บิต, overflow และ SLT (SLT ใช้ผลลบซ้ำ ไม่ต้องสร้าง comparator ใหม่)

**ขั้นที่ 3 — เลือกผลด้วย `case` ใน process แบบ combinational** — กำหนดค่า default ให้ทุกเอาต์พุตที่ต้น process (กัน latch และทำให้ carry/ovf เป็น 0 อัตโนมัติในคำสั่งที่ไม่ใช่ ADD/SUB)

**ขั้นที่ 4 — คำนวณ zero จาก y ที่เลือกแล้ว** (ไม่ใช่จากผลบวก)

`vhdl/alu8.vhd`:

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu8 is
  port (
    a, b             : in  std_logic_vector(7 downto 0);
    op               : in  std_logic_vector(2 downto 0);
    y                : out std_logic_vector(7 downto 0);
    zero, carry, ovf : out std_logic
  );
end entity;

architecture rtl of alu8 is
  -- ขั้นที่ 1: ชื่อ opcode
  constant OP_ADD : std_logic_vector(2 downto 0) := "000";
  constant OP_SUB : std_logic_vector(2 downto 0) := "001";
  constant OP_AND : std_logic_vector(2 downto 0) := "010";
  constant OP_OR  : std_logic_vector(2 downto 0) := "011";
  constant OP_XOR : std_logic_vector(2 downto 0) := "100";
  constant OP_SLL : std_logic_vector(2 downto 0) := "101";
  constant OP_SRL : std_logic_vector(2 downto 0) := "110";
  constant OP_SLT : std_logic_vector(2 downto 0) := "111";

  signal sum9, dif9               : unsigned(8 downto 0);
  signal ovf_add, ovf_sub, slt    : std_logic;
  signal y_i                      : std_logic_vector(7 downto 0);
begin
  -- ขั้นที่ 2: datapath แบบ 9 บิต (บิต 8 = carry/borrow)
  sum9    <= resize(unsigned(a), 9) + resize(unsigned(b), 9);
  dif9    <= resize(unsigned(a), 9) - resize(unsigned(b), 9);
  ovf_add <= (a(7) xnor b(7)) and (sum9(7) xor a(7));   -- เครื่องหมายเดียวกัน แต่ผลเปลี่ยนเครื่องหมาย
  ovf_sub <= (a(7) xor  b(7)) and (dif9(7) xor a(7));   -- เครื่องหมายต่างกัน และผลไม่ตาม a
  slt     <= dif9(7) xor ovf_sub;                       -- เครื่องหมายที่แก้ด้วย overflow

  -- ขั้นที่ 3: mux เลือกผล
  alu_mux : process (all)
    variable sh : natural range 0 to 7;
  begin
    sh    := to_integer(unsigned(b(2 downto 0)));       -- ใช้เฉพาะ 3 บิตล่าง
    y_i   <= (others => '0');                           -- default กัน latch
    carry <= '0';
    ovf   <= '0';
    case op is
      when OP_ADD =>
        y_i <= std_logic_vector(sum9(7 downto 0)); carry <= sum9(8); ovf <= ovf_add;
      when OP_SUB =>
        y_i <= std_logic_vector(dif9(7 downto 0)); carry <= dif9(8); ovf <= ovf_sub;
      when OP_AND => y_i <= a and b;
      when OP_OR  => y_i <= a or b;
      when OP_XOR => y_i <= a xor b;
      when OP_SLL => y_i <= std_logic_vector(shift_left(unsigned(a), sh));
      when OP_SRL => y_i <= std_logic_vector(shift_right(unsigned(a), sh));  -- unsigned → เติม 0
      when OP_SLT => y_i <= (0 => slt, others => '0');
      when others => null;                              -- ค่า X/U ใน op → คง default
    end case;
  end process;

  -- ขั้นที่ 4: zero จากผลลัพธ์สุดท้าย
  y    <= y_i;
  zero <= '1' when y_i = x"00" else '0';
end architecture;
```

จุดสอนสำคัญในโค้ด:

| บรรทัด | ทำไมเขียนแบบนี้ |
| --- | --- |
| `resize(unsigned(a), 9)` | ขยายเป็น 9 บิตก่อนบวก — numeric\_std ให้ผลบวกกว้างเท่าตัวตั้งที่กว้างที่สุด ถ้าบวก 8+8 จะได้ 8 บิตและ carry หาย |
| `process (all)` | VHDL-2008: sensitivity ครบอัตโนมัติ — ถ้าเขียนเองแล้วลืม `slt` หรือ `sum9` simulation จะผิดแต่ synthesis ถูก (simulation/synthesis mismatch) |
| default ก่อน `case` | ทุกเอาต์พุตได้ค่าทุก path → ไม่เกิด latch และตรงสเปกที่ carry/ovf = 0 ในคำสั่งอื่น |
| `shift_right(unsigned(...))` | บน unsigned เติม 0 (logical) — ถ้าใช้บน signed จะเติมบิตเครื่องหมาย (arithmetic) |
| `y_i` ภายใน | อ่านค่า port ชนิด `out` ได้ใน VHDL-2008 แต่การใช้ signal ภายในอ่านง่ายและใช้ได้กับเครื่องมือเก่าด้วย |

**ขั้นที่ 5 — Compile**

```tcl
cd C:/labs/lab02_alu        ;# หรือ path ของคุณ
vlib work
vmap work work
vcom -2008 vhdl/alu8.vhd
# -- Compiling entity alu8
# -- Compiling architecture rtl of alu8
# Errors: 0, Warnings: 0
```

**ขั้นที่ 6 — Smoke test ด้วย `force` (ยังไม่มี testbench)** — ทดสอบ 3 แถวจากตาราง 2.0 เพื่อดูว่าโค้ด "มีชีวิต" ก่อนลงทุนเขียน testbench

```tcl
vsim -voptargs=+acc work.alu8
add wave -radix hex /alu8/a /alu8/b /alu8/op /alu8/y
add wave /alu8/zero /alu8/carry /alu8/ovf

force a 16#7F ; force b 16#01 ; force op 000    ;# แถว 2: ADD 7F+01
run 10 ns
examine -radix hex y ; examine zero carry ovf   ;# คาด y=80, zero=0 carry=0 ovf=1

force a 16#7F ; force b 16#FF ; force op 001    ;# แถว 8: SUB 7F−FF
run 10 ns
examine -radix hex y ; examine zero carry ovf   ;# คาด y=80, zero=0 carry=1 ovf=1

force a 16#7F ; force b 16#80 ; force op 111    ;# แถว 17: SLT 7F,80
run 10 ns
examine -radix hex y ; examine zero carry ovf   ;# คาด y=00, zero=1 carry=0 ovf=0
```

ถ้าค่าตรงทั้ง 3 แถว ไปต่อ 2B ได้ — ถ้าไม่ตรง ให้เพิ่ม `/alu8/sum9 /alu8/dif9 /alu8/ovf_sub /alu8/slt` เข้า Wave แล้วไล่ทีละชั้นตาม block diagram (หมายเหตุ: `force` ใช้ได้เฉพาะตอน debug — ห้ามใช้แทน testbench เพราะตรวจผลเองไม่ได้)

✅ **Checkpoint 2A:** compile ไม่มี warning และ smoke test ตรงทั้ง 3 แถว

## Lab 2B — RTL ภาษา Verilog (30 นาที)

**เป้าหมายย่อย:** เขียน ALU ตัวเดียวกันใน Verilog โดยรักษาชื่อ port และพฤติกรรมให้ตรงกันทุกบิต และเข้าใจกฎความกว้างบิตของ Verilog ที่ต่างจาก VHDL

**ขั้นที่ 1 — เทียบการแปลงทีละส่วนจาก VHDL**

| VHDL (2A) | Verilog (2B) |
| --- | --- |
| `constant OP_ADD : ... := "000"` | `localparam [2:0] OP_ADD = 3'b000` |
| `resize(unsigned(a), 9) + resize(unsigned(b), 9)` | `{1'b0, a} + {1'b0, b}` ใส่ใน wire 9 บิต |
| `process (all)` + default | `always @(*)` + default ที่ต้น block |
| `shift_left(unsigned(a), sh)` | `a << b[2:0]` |
| `shift_right(unsigned(a), sh)` | `a >> b[2:0]` (`>>>` คือ arithmetic ใช้กับ signed) |
| `(0 => slt, others => '0')` | `{7'b0, slt}` |
| `when others => null;` | `default: ;` |

**ขั้นที่ 2 — เขียน `verilog/alu8.v`**

```verilog
module alu8 (
  input  wire [7:0] a, b,
  input  wire [2:0] op,
  output reg  [7:0] y,
  output wire       zero,
  output reg        carry, ovf
);
  localparam [2:0] OP_ADD = 3'b000, OP_SUB = 3'b001, OP_AND = 3'b010, OP_OR  = 3'b011,
                   OP_XOR = 3'b100, OP_SLL = 3'b101, OP_SRL = 3'b110, OP_SLT = 3'b111;

  // datapath 9 บิต (บิต 8 = carry/borrow)
  wire [8:0] sum9    = {1'b0, a} + {1'b0, b};
  wire [8:0] dif9    = {1'b0, a} - {1'b0, b};
  wire       ovf_add = (a[7] == b[7]) && (sum9[7] != a[7]);
  wire       ovf_sub = (a[7] != b[7]) && (dif9[7] != a[7]);
  wire       slt     = dif9[7] ^ ovf_sub;

  always @(*) begin
    y = 8'h00;  carry = 1'b0;  ovf = 1'b0;          // default กัน latch
    case (op)
      OP_ADD : begin y = sum9[7:0]; carry = sum9[8]; ovf = ovf_add; end
      OP_SUB : begin y = dif9[7:0]; carry = dif9[8]; ovf = ovf_sub; end
      OP_AND : y = a & b;
      OP_OR  : y = a | b;
      OP_XOR : y = a ^ b;
      OP_SLL : y = a << b[2:0];
      OP_SRL : y = a >> b[2:0];                      // logical: เติม 0
      OP_SLT : y = {7'b0, slt};
      default: ;                                     // op เป็น x → คง default
    endcase
  end

  assign zero = (y == 8'h00);
endmodule
```

**ขั้นที่ 3 — ทำความเข้าใจกับดักความกว้างบิตของ Verilog** — Verilog ไม่เตือนเมื่อบิตหาย (ต่างจาก VHDL ที่ compile ไม่ผ่าน) ความกว้างของนิพจน์ขึ้นกับ **context**:

```verilog
wire [8:0] s1 = a + b;          // ถูก: context 9 บิต → a, b ถูกขยายเป็น 9 บิตก่อนบวก
wire [8:0] s2 = {a + b};        // ผิด: ใน {} เป็น self-determined 8 บิต → carry หาย (s2[8] = 0 เสมอ)
wire       c3 = (a + b) > 8'hFF; // ผิด: เปรียบเทียบที่ 8 บิต → ไม่มีทางเป็นจริง
wire [8:0] s4 = {1'b0, a} + {1'b0, b};  // ดีที่สุด: กำหนดความกว้างชัดเจน อ่านแล้วไม่ต้องเดา
```

แบบฝึกสั้น: เปลี่ยน `sum9` เป็นแบบ `s2` แล้วทำ smoke test แถว 3 (FF + 01) — carry จะเป็น 0 ผิดสเปก และ `vlog` ไม่เตือนอะไรเลย (จะจับได้ด้วย testbench ใน 2C/2D หรือ lint เช่น `verilator --lint-only -Wall`)

**ขั้นที่ 4 — Compile และ smoke test** (ล้าง library ก่อน เพราะชื่อ `alu8` ซ้ำกับ VHDL)

```tcl
quit -sim
vdel -lib work -all ; vlib work ; vmap work work
vlog verilog/alu8.v
# -- Compiling module alu8
# Top level modules:
#     alu8

vsim -voptargs=+acc work.alu8
add wave -radix hex /alu8/a /alu8/b /alu8/op /alu8/y
add wave /alu8/zero /alu8/carry /alu8/ovf

force a 'h7F ; force b 'h01 ; force op 3'b000   ;# แถว 2 → คาด y=80 z=0 c=0 v=1
run 10 ns ; examine -radix hex y ; examine zero carry ovf
force a 'h7F ; force b 'hFF ; force op 3'b001   ;# แถว 8 → คาด y=80 z=0 c=1 v=1
run 10 ns ; examine -radix hex y ; examine zero carry ovf
force a 'h7F ; force b 'h80 ; force op 3'b111   ;# แถว 17 → คาด y=00 z=1 c=0 v=0
run 10 ns ; examine -radix hex y ; examine zero carry ovf
```

(รูปแบบเลขใน `force` สำหรับ Verilog ใช้ `'h7F` หรือ `3'b000` ได้ — ถ้า ModelSim รุ่นที่ใช้ไม่รับ ให้ใช้เลขฐานสองเต็มความกว้าง เช่น `force a 01111111`)

**ขั้นที่ 5 (ทางเลือก) — Lint** ถ้ามี Verilator: `verilator --lint-only -Wall verilog/alu8.v` — ต้องไม่มี warning WIDTH หรือ LATCH

✅ **Checkpoint 2B:** `vlog` ผ่าน, smoke test ตรง 3 แถวเหมือน VHDL, และอธิบายได้ว่าทำไม `s2` ผิด

## Lab 2C — Directed Testbench (40 นาที)

**เป้าหมายย่อย:** นำตาราง corner case 19 แถวจาก 2.0 มาเป็น testbench แบบ **table-driven** (ข้อมูลแยกจากโค้ดตรวจ) เพิ่มแถวใหม่ได้โดยไม่แก้ logic และรายงาน FAIL พร้อมค่าที่คาดหวังครบทุก flag

**ขั้นที่ 1 — ออกแบบโครง testbench**

```text
ตาราง VEC[i] = (op, a, b, y, z, c, v)        ← คัดจาก doc/hand_calc.md
วนทุกแถว: ป้อน op,a,b → รอ 10 ns → เทียบ y,zero,carry,ovf ทั้งหมด
พิมพ์ pass/FAIL รายแถว → สรุป *** PASS *** หรือ *** FAIL: n ***
```

**ขั้นที่ 2 — VHDL: ใช้ record เก็บแต่ละแถว** (`vhdl/tb_alu8_dir.vhd`)

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_alu8_dir is
end entity;

architecture sim of tb_alu8_dir is
  signal a, b, y : std_logic_vector(7 downto 0) := (others => '0');
  signal op      : std_logic_vector(2 downto 0) := "000";
  signal zero, carry, ovf : std_logic;

  type vec_t is record
    op      : std_logic_vector(2 downto 0);
    a, b, y : std_logic_vector(7 downto 0);
    z, c, v : std_logic;
  end record;
  type vec_arr_t is array (natural range <>) of vec_t;

  constant VEC : vec_arr_t := (
    --  op      a      b      y     z    c    v
    ("000", x"01", x"01", x"02", '0', '0', '0'),   -- 1  ADD ปกติ
    ("000", x"7F", x"01", x"80", '0', '0', '1'),   -- 2  ADD signed overflow
    ("000", x"FF", x"01", x"00", '1', '1', '0'),   -- 3  ADD carry ไม่ ovf
    ("000", x"80", x"80", x"00", '1', '1', '1'),   -- 4  ADD carry + ovf
    ("001", x"55", x"55", x"00", '1', '0', '0'),   -- 5  SUB เท่ากัน
    ("001", x"00", x"01", x"FF", '0', '1', '0'),   -- 6  SUB borrow
    ("001", x"80", x"01", x"7F", '0', '0', '1'),   -- 7  SUB ovf
    ("001", x"7F", x"FF", x"80", '0', '1', '1'),   -- 8  SUB borrow + ovf
    ("010", x"F0", x"0F", x"00", '1', '0', '0'),   -- 9  AND → zero
    ("011", x"F0", x"0F", x"FF", '0', '0', '0'),   -- 10 OR
    ("100", x"AA", x"FF", x"55", '0', '0', '0'),   -- 11 XOR
    ("101", x"81", x"01", x"02", '0', '0', '0'),   -- 12 SLL บิตบนหลุด
    ("101", x"01", x"0F", x"80", '0', '0', '0'),   -- 13 SLL ใช้ b[2:0]
    ("110", x"80", x"07", x"01", '0', '0', '0'),   -- 14 SRL 7
    ("110", x"80", x"08", x"80", '0', '0', '0'),   -- 15 SRL b[2:0]=0
    ("111", x"80", x"7F", x"01", '0', '0', '0'),   -- 16 SLT -128 < 127
    ("111", x"7F", x"80", x"00", '1', '0', '0'),   -- 17 SLT กับดัก overflow
    ("111", x"FF", x"00", x"01", '0', '0', '0'),   -- 18 SLT -1 < 0
    ("111", x"05", x"05", x"00", '1', '0', '0')    -- 19 SLT เท่ากัน
  );
begin
  dut : entity work.alu8
    port map (a => a, b => b, op => op, y => y, zero => zero, carry => carry, ovf => ovf);

  stim : process
    variable err : natural := 0;
  begin
    for i in VEC'range loop
      op <= VEC(i).op;  a <= VEC(i).a;  b <= VEC(i).b;
      wait for 10 ns;
      if y /= VEC(i).y or zero /= VEC(i).z or carry /= VEC(i).c or ovf /= VEC(i).v then
        err := err + 1;
        report "FAIL #" & integer'image(i + 1) &
               " op=" & to_string(VEC(i).op) & " a=" & to_hstring(VEC(i).a) & " b=" & to_hstring(VEC(i).b) &
               " got y=" & to_hstring(y) & " zcv=" & to_string(zero) & to_string(carry) & to_string(ovf) &
               " exp y=" & to_hstring(VEC(i).y) & " zcv=" &
               to_string(VEC(i).z) & to_string(VEC(i).c) & to_string(VEC(i).v)
          severity error;
      else
        report "pass #" & integer'image(i + 1) & " y=" & to_hstring(y) &
               " zcv=" & to_string(zero) & to_string(carry) & to_string(ovf);
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

**ขั้นที่ 3 — Verilog/SV: ใช้ task `check`** (`verilog/tb_alu8_dir.sv`) — หนึ่งบรรทัดต่อหนึ่งแถวของตาราง

```verilog
`timescale 1ns/1ps
module tb_alu8_dir;
  reg  [7:0] a, b;
  reg  [2:0] op;
  wire [7:0] y;
  wire       zero, carry, ovf;
  integer    err = 0, n = 0;

  alu8 dut (.a(a), .b(b), .op(op), .y(y), .zero(zero), .carry(carry), .ovf(ovf));

  task check(input [2:0] t_op, input [7:0] t_a, t_b, t_y, input t_z, t_c, t_v);
    begin
      op = t_op;  a = t_a;  b = t_b;
      #10;
      n = n + 1;
      if ({y, zero, carry, ovf} !== {t_y, t_z, t_c, t_v}) begin
        err = err + 1;
        $display("FAIL #%0d op=%b a=%h b=%h  got y=%h zcv=%b%b%b  exp y=%h zcv=%b%b%b",
                 n, t_op, t_a, t_b, y, zero, carry, ovf, t_y, t_z, t_c, t_v);
      end else
        $display("pass #%0d op=%b a=%h b=%h y=%h zcv=%b%b%b", n, t_op, t_a, t_b, y, zero, carry, ovf);
    end
  endtask

  initial begin
    //     op      a      b      y     z  c  v
    check(3'b000, 8'h01, 8'h01, 8'h02, 0, 0, 0);   // 1
    check(3'b000, 8'h7F, 8'h01, 8'h80, 0, 0, 1);   // 2
    check(3'b000, 8'hFF, 8'h01, 8'h00, 1, 1, 0);   // 3
    check(3'b000, 8'h80, 8'h80, 8'h00, 1, 1, 1);   // 4
    check(3'b001, 8'h55, 8'h55, 8'h00, 1, 0, 0);   // 5
    check(3'b001, 8'h00, 8'h01, 8'hFF, 0, 1, 0);   // 6
    check(3'b001, 8'h80, 8'h01, 8'h7F, 0, 0, 1);   // 7
    check(3'b001, 8'h7F, 8'hFF, 8'h80, 0, 1, 1);   // 8
    check(3'b010, 8'hF0, 8'h0F, 8'h00, 1, 0, 0);   // 9
    check(3'b011, 8'hF0, 8'h0F, 8'hFF, 0, 0, 0);   // 10
    check(3'b100, 8'hAA, 8'hFF, 8'h55, 0, 0, 0);   // 11
    check(3'b101, 8'h81, 8'h01, 8'h02, 0, 0, 0);   // 12
    check(3'b101, 8'h01, 8'h0F, 8'h80, 0, 0, 0);   // 13
    check(3'b110, 8'h80, 8'h07, 8'h01, 0, 0, 0);   // 14
    check(3'b110, 8'h80, 8'h08, 8'h80, 0, 0, 0);   // 15
    check(3'b111, 8'h80, 8'h7F, 8'h01, 0, 0, 0);   // 16
    check(3'b111, 8'h7F, 8'h80, 8'h00, 1, 0, 0);   // 17
    check(3'b111, 8'hFF, 8'h00, 8'h01, 0, 0, 0);   // 18
    check(3'b111, 8'h05, 8'h05, 8'h00, 1, 0, 0);   // 19
    if (err == 0) $display("*** PASS ***");
    else          $display("*** FAIL: %0d ***", err);
    $stop;
  end
endmodule
```

**ขั้นที่ 4 — Compile และรัน**

```tcl
# VHDL
quit -sim
vdel -lib work -all ; vlib work ; vmap work work
vcom -2008 vhdl/alu8.vhd vhdl/tb_alu8_dir.vhd
vsim -voptargs=+acc work.tb_alu8_dir
add wave -radix hex /tb_alu8_dir/op /tb_alu8_dir/a /tb_alu8_dir/b /tb_alu8_dir/y
add wave /tb_alu8_dir/zero /tb_alu8_dir/carry /tb_alu8_dir/ovf
run -all

# Verilog: vdel/vlib แล้ว  vlog verilog/alu8.v ; vlog -sv verilog/tb_alu8_dir.sv ; vsim -voptargs=+acc work.tb_alu8_dir
```

ผลที่คาดหวัง (ส่วนท้าย): `pass #17 ... y=00 zcv=100`, `pass #18 ... y=01 zcv=000`, `pass #19 ... y=00 zcv=100`, `*** PASS ***`

**ขั้นที่ 5 — อ่าน waveform เป็นตาราง** — เมนู **View → List** (หรือพิมพ์ `add list -radix hex /tb_alu8_dir/*`) จะได้ตารางค่าสัญญาณตามเวลา ใช้เทียบกับ `hand_calc.md` ทีละแถวได้ง่ายกว่า waveform — ส่งออกเป็นไฟล์ด้วย `write list alu_dir.lst`

**ขั้นที่ 6 — Bug injection 2 ตัว** (ทำทีละตัว บันทึกแถวที่ FAIL แล้วแก้กลับ)

| บั๊ก | แก้ใน RTL | แถวที่ควร FAIL |
| --- | --- | --- |
| B1: SLT ลืมแก้ overflow | `slt <= dif9(7);` / `wire slt = dif9[7];` | #16, #17 |
| B2: SRL เป็น arithmetic | VHDL: `shift_right(signed(a), sh)` / Verilog: `$signed(a) >>> b[2:0]` | #14 (ได้ FF แทน 01) |

คำถามชวนคิด: ถ้าตารางไม่มีแถว #17 บั๊ก B1 จะหลุดหรือไม่ — นี่คือจุดอ่อนของ directed test: จับได้เฉพาะกรณีที่เรานึกออก → เหตุผลของ 2D

✅ **Checkpoint 2C:** `*** PASS ***` ทั้งสองภาษา + บันทึกผล bug injection B1, B2

## Lab 2D — Exhaustive Testbench + Reference Model (45 นาที)

**เป้าหมายย่อย:** ตรวจทุก combination ของอินพุต และใช้ **reference model** ที่เขียนจากนิยามทางคณิตศาสตร์ (เลข integer) ไม่ใช่สูตรบิตชุดเดียวกับ RTL

**ขั้นที่ 1 — คำนวณว่า exhaustive ทำได้จริงไหม**

```text
อินพุตทั้งหมด = op(3) + a(8) + b(8) = 19 บิต → 2^19 = 524,288 vectors
ถ้า 1 vector = 1 ns → เวลาจำลอง 0.52 ms (เวลาจริงบนเครื่อง: ไม่กี่วินาทีถึงราวนาที)
เทียบ: ALU 32 บิต = 2^(3+32+32) ≈ 1.5×10^20 vectors → เป็นไปไม่ได้ → ต้องใช้ random + coverage (Module 04) หรือ formal
```

**ขั้นที่ 2 — เขียน reference model** — กฎ: ห้ามคัดลอกสูตรจาก RTL ให้คำนวณแบบ "คนทำการบ้าน": แปลงเป็น integer ทั้ง unsigned และ signed แล้วตรวจช่วงค่าตรง ๆ

| Flag | RTL (2A/2B) | Reference model |
| --- | --- | --- |
| carry ADD | `sum9[8]` | `ua + ub > 255` |
| carry SUB | `dif9[8]` | `ua < ub` |
| ovf ADD | สูตรบิตเครื่องหมาย | `sa + sb` อยู่นอกช่วง −128..127 |
| SLT | `dif9[7] xor ovf_sub` | `sa < sb` |

**ขั้นที่ 3 — SystemVerilog testbench** (`verilog/tb_alu8_exh.sv`)

```verilog
`timescale 1ns/1ps
module tb_alu8_exh;
  reg  [7:0] a, b;
  reg  [2:0] op;
  wire [7:0] y;
  wire       zero, carry, ovf;
  int          err = 0, n = 0;
  int          err_op [8];
  logic [10:0] exp_v, got_v;                 // {y, zero, carry, ovf}

  alu8 dut (.a(a), .b(b), .op(op), .y(y), .zero(zero), .carry(carry), .ovf(ovf));

  // reference model: คำนวณด้วย integer ตามนิยาม ไม่ใช้สูตรบิตเดียวกับ RTL
  function automatic logic [10:0] ref_alu(input logic [2:0] f_op, input logic [7:0] f_a, f_b);
    int ua, ub, sa, sb, r;
    logic [7:0] ry;
    logic rc, rv;
    ua = f_a;           ub = f_b;              // 0..255
    sa = $signed(f_a);  sb = $signed(f_b);     // -128..127
    rc = 1'b0;          rv = 1'b0;
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

  initial begin
    for (int o = 0; o < 8; o++) err_op[o] = 0;
    for (int o = 0; o < 8; o++)
      for (int ia = 0; ia < 256; ia++)
        for (int ib = 0; ib < 256; ib++) begin
          op = o;  a = ia;  b = ib;
          #1;
          exp_v = ref_alu(op, a, b);
          got_v = {y, zero, carry, ovf};
          n++;
          if (got_v !== exp_v) begin
            err++;  err_op[o]++;
            if (err <= 10)                     // พิมพ์แค่ 10 ตัวแรก ไม่ให้ transcript ท่วม
              $display("FAIL op=%0d a=%h b=%h  got y=%h zcv=%b  exp y=%h zcv=%b",
                       o, a, b, y, got_v[2:0], exp_v[10:3], exp_v[2:0]);
          end
        end
    $display("checked %0d vectors", n);
    for (int o = 0; o < 8; o++) $display("  op %0d : %0d errors", o, err_op[o]);
    if (err == 0) $display("*** PASS ***");
    else          $display("*** FAIL: %0d ***", err);
    $stop;
  end
endmodule
```

**ขั้นที่ 4 — VHDL testbench** (`vhdl/tb_alu8_exh.vhd`) — โครงเดียวกัน, reference model เป็น function ที่คืนค่า `y & zero & carry & ovf` (11 บิต)

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_alu8_exh is
end entity;

architecture sim of tb_alu8_exh is
  signal a, b, y          : std_logic_vector(7 downto 0) := (others => '0');
  signal op               : std_logic_vector(2 downto 0) := "000";
  signal zero, carry, ovf : std_logic;
  type int_arr_t is array (0 to 7) of natural;

  function ref_alu (o, ia, ib : natural) return std_logic_vector is
    variable sa, sb, r : integer;
    variable ry        : unsigned(7 downto 0);
    variable z, c, v   : std_logic;
  begin
    sa := ia;  if ia > 127 then sa := ia - 256; end if;     -- ตีความแบบ signed
    sb := ib;  if ib > 127 then sb := ib - 256; end if;
    c := '0';  v := '0';
    case o is
      when 0 =>
        r  := ia + ib;  ry := to_unsigned(r mod 256, 8);
        if r > 255 then c := '1'; end if;
        if sa + sb > 127 or sa + sb < -128 then v := '1'; end if;
      when 1 =>
        r  := ia - ib;  ry := to_unsigned(r mod 256, 8);      -- mod ของค่าลบใน VHDL ให้ผลบวก
        if ia < ib then c := '1'; end if;
        if sa - sb > 127 or sa - sb < -128 then v := '1'; end if;
      when 2 => ry := to_unsigned(ia, 8) and to_unsigned(ib, 8);
      when 3 => ry := to_unsigned(ia, 8) or  to_unsigned(ib, 8);
      when 4 => ry := to_unsigned(ia, 8) xor to_unsigned(ib, 8);
      when 5 => ry := shift_left (to_unsigned(ia, 8), ib mod 8);
      when 6 => ry := shift_right(to_unsigned(ia, 8), ib mod 8);
      when others =>
        if sa < sb then ry := to_unsigned(1, 8); else ry := to_unsigned(0, 8); end if;
    end case;
    if ry = 0 then z := '1'; else z := '0'; end if;
    return std_logic_vector(ry) & z & c & v;
  end function;
begin
  dut : entity work.alu8
    port map (a => a, b => b, op => op, y => y, zero => zero, carry => carry, ovf => ovf);

  stim : process
    variable err, n         : natural := 0;
    variable err_op         : int_arr_t := (others => 0);
    variable exp_v, got_v   : std_logic_vector(10 downto 0);
  begin
    for o in 0 to 7 loop
      for ia in 0 to 255 loop
        for ib in 0 to 255 loop
          op <= std_logic_vector(to_unsigned(o, 3));
          a  <= std_logic_vector(to_unsigned(ia, 8));
          b  <= std_logic_vector(to_unsigned(ib, 8));
          wait for 1 ns;
          exp_v := ref_alu(o, ia, ib);
          got_v := y & zero & carry & ovf;
          n := n + 1;
          if got_v /= exp_v then
            err := err + 1;  err_op(o) := err_op(o) + 1;
            if err <= 10 then
              report "FAIL op=" & integer'image(o) & " a=" & to_hstring(a) & " b=" & to_hstring(b) &
                     " got " & to_string(got_v) & " exp " & to_string(exp_v) severity error;
            end if;
          end if;
        end loop;
      end loop;
    end loop;
    report "checked " & integer'image(n) & " vectors";
    for o in 0 to 7 loop
      report "  op " & integer'image(o) & " : " & integer'image(err_op(o)) & " errors";
    end loop;
    if err = 0 then report "*** PASS ***";
    else report "*** FAIL: " & integer'image(err) & " ***" severity error;
    end if;
    std.env.stop;
    wait;
  end process;
end architecture;
```

**ขั้นที่ 5 — รันแบบไม่เก็บ waveform และจับเวลา** — เก็บสัญญาณครึ่งล้านจุดใน Wave ทำให้ช้าและไฟล์ .wlf ใหญ่ จึงไม่ใส่ `+acc` และไม่ `add wave`

```tcl
quit -sim
vdel -lib work -all ; vlib work ; vmap work work
vcom -2008 vhdl/alu8.vhd vhdl/tb_alu8_exh.vhd        ;# หรือ vlog verilog/alu8.v ; vlog -sv verilog/tb_alu8_exh.sv
vsim work.tb_alu8_exh
echo [time {run -all}]                               ;# Tcl: พิมพ์เวลาที่ใช้เป็น microseconds
```

ผลที่คาดหวัง:

```text
checked 524288 vectors
  op 0 : 0 errors
  op 1 : 0 errors
  ...
  op 7 : 0 errors
*** PASS ***
```

บันทึกเวลาที่ใช้ของทั้งสองภาษา (คำถามท้าย Lab) — ถ้ารันซ้ำโดยใส่ `-voptargs=+acc` และ `add wave -r /*` จะเห็นว่าช้าลงมาก

**ขั้นที่ 6 — Bug injection ที่ directed test มองไม่เห็น (B3)** — แทน SLL ด้วย barrel shifter แบบ 3 ชั้นที่เขียน select ผิดชั้นกลาง (Verilog — ประกาศ `reg [7:0] s1, s2;` ใน module และเพิ่ม s1 = 8'h00; s2 = 8'h00; ต่อท้ายบรรทัด default ก่อน case เพื่อไม่ให้ s1/s2 กลายเป็น latch)

```verilog
OP_SLL : begin
  s1 = b[0] ? {a[6:0],  1'b0} : a;     // ชั้น shift 1
  s2 = b[2] ? {s1[5:0], 2'b0} : s1;    // ชั้น shift 2  ← บั๊ก: ควรเป็น b[1]
  y  = b[2] ? {s2[3:0], 4'b0} : s2;    // ชั้น shift 4
end
```

1. รัน `tb_alu8_dir` → **ยัง PASS** เพราะตาราง directed ใช้ shift 1, 7 และ 0 ซึ่ง b\[1\] = b\[2\] ทุกกรณี
2. รัน `tb_alu8_exh` → FAIL จำนวนมาก **เฉพาะ op 5** (shift 2, 3, 4, 5) — ตาราง error ต่อ op ชี้ตำแหน่งบั๊กทันที
3. อ่าน 10 บรรทัด FAIL แรก แล้วอธิบายว่าทำไมค่า b ที่ผิดมีรูปแบบ b\[2:0\] ∈ {010, 011, 100, 101}
4. แก้เป็น `b[1]` → exhaustive PASS แล้วเพิ่มแถว directed ใหม่ (เช่น SLL a=01 b=02 → 04) เพื่อให้ตาราง directed จับบั๊กนี้ได้ในอนาคต

บทเรียน: directed เร็วและอ่านง่าย แต่จับได้เฉพาะที่คิดออก — exhaustive (หรือ random ที่มากพอ) + reference model อิสระ คือตาข่ายรองรับสิ่งที่ไม่ได้คิด

✅ **Checkpoint 2D:** `checked 524288 vectors` + `*** PASS ***` ทั้งสองภาษา, บันทึกเวลารัน, ผล B3 (directed ผ่าน / exhaustive จับได้)

## Lab 2E — Mixed-Language, run.do และ Regression (30 นาที)

**เป้าหมายย่อย:** ใช้ testbench ภาษาหนึ่งทดสอบ RTL อีกภาษา (พิสูจน์ว่า RTL สองภาษาทำงานเหมือนกันด้วย testbench ชุดเดียว) และรวมทุกอย่างเป็น regression 8 ชุด

**ขั้นที่ 1 — เข้าใจการเชื่อมต่อข้ามภาษาใน ModelSim**

| ประเด็น | กฎ |
| --- | --- |
| ชื่อ design unit | VHDL entity กับ Verilog module อยู่ใน library `work` เดียวกันได้ — ฝั่งที่สร้าง instance หาตามชื่อ `alu8` |
| ตัวพิมพ์เล็ก/ใหญ่ | VHDL ไม่สนใจตัวพิมพ์ ส่วน Verilog สนใจ → ตั้งชื่อ port/entity เป็นตัวเล็กทั้งหมดเสมอ |
| ชนิดสัญญาณ | `std_logic` ↔ `wire`/`logic` 1 บิต, `std_logic_vector(7 downto 0)` ↔ `[7:0]` — ความกว้างต้องเท่ากัน |
| ค่า 9 สถานะของ VHDL | `U`, `X`, `W`, `-` → เป็น `x` ใน Verilog; `Z` → `z`; `L`/`H` → 0/1 |
| VHDL TB สร้าง instance จาก Verilog module | ModelSim รองรับ `entity work.alu8` — ถ้ารุ่นที่ใช้ไม่ยอม ให้ใช้ component declaration (ขั้นที่ 3) |
| License | ต้องเป็น ModelSim/Questa edition ที่รองรับ mixed-language — บางรุ่น starter อนุญาตเฉพาะภาษาเดียว (จะขึ้น error ตอน `vsim`) |

**ขั้นที่ 2 — รัน SV testbench กับ RTL VHDL ด้วยมือ**

```tcl
quit -sim
vdel -lib work -all ; vlib work ; vmap work work
vcom -2008 vhdl/alu8.vhd                 ;# RTL = VHDL
vlog -sv  verilog/tb_alu8_exh.sv         ;# TB  = SystemVerilog
vsim work.tb_alu8_exh
run -all                                 ;# คาด: checked 524288 vectors / *** PASS ***
```

ตรวจในหน้าต่าง **sim/Structure**: `tb_alu8_exh` (ไอคอน Verilog) → `dut` (ไอคอน VHDL entity `alu8(rtl)`) — ยืนยันว่าผสมสองภาษาจริง

**ขั้นที่ 3 — กลับด้าน: VHDL testbench กับ RTL Verilog**

```tcl
quit -sim
vdel -lib work -all ; vlib work ; vmap work work
vlog verilog/alu8.v                      ;# RTL = Verilog (compile ก่อน TB เสมอ)
vcom -2008 vhdl/tb_alu8_exh.vhd          ;# TB  = VHDL
vsim work.tb_alu8_exh
run -all
```

ถ้า `vcom` ฟ้องว่าหา entity `alu8` ไม่พบ ให้เปลี่ยน testbench เป็นแบบ component (ใส่ในส่วนประกาศของ architecture):

```vhdl
component alu8
  port (
    a, b             : in  std_logic_vector(7 downto 0);
    op               : in  std_logic_vector(2 downto 0);
    y                : out std_logic_vector(7 downto 0);
    zero, carry, ovf : out std_logic
  );
end component;
-- แล้วใน body:  dut : alu8 port map (a => a, b => b, op => op, y => y,
--                                       zero => zero, carry => carry, ovf => ovf);
```

**ขั้นที่ 4 — เขียน `run.do` ที่เลือกภาษา RTL / TB / ชนิด TB ได้อิสระ**

```tcl
# run.do — ตัวแปร: DUT (ภาษา RTL)  TBL (ภาษา TB)  TB (dir|exh)  BATCH (0|1)
#   GUI   : set DUT vhdl; set TBL verilog; set TB dir; do run.do
#   Batch : vsim -c -do "set DUT verilog; set TBL vhdl; set TB exh; set BATCH 1; do run.do; quit -f"
if {![info exists DUT]}   { set DUT vhdl }
if {![info exists TBL]}   { set TBL $DUT }
if {![info exists TB]}    { set TB  dir }
if {![info exists BATCH]} { set BATCH 0 }
if {$BATCH} { onerror {quit -f -code 1} }

if {!$BATCH} { catch {quit -sim} }
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

# RTL ก่อน แล้วค่อย testbench
if {$DUT eq "vhdl"} { vcom -2008 -quiet vhdl/alu8.vhd } else { vlog -quiet verilog/alu8.v }
if {$TBL eq "vhdl"} { vcom -2008 -quiet vhdl/tb_alu8_$TB.vhd } else { vlog -sv -quiet verilog/tb_alu8_$TB.sv }

set TOP tb_alu8_$TB
if {$BATCH || $TB eq "exh"} {
  vsim work.$TOP                                 ;# ไม่เก็บ waveform → เร็ว
} else {
  vsim -voptargs=+acc work.$TOP
  add wave -radix hex /$TOP/op /$TOP/a /$TOP/b /$TOP/y
  add wave /$TOP/zero /$TOP/carry /$TOP/ovf
}
run -all
if {!$BATCH && $TB eq "dir"} { wave zoom full }
```

ข้อควรระวังใน GUI: ตัวแปรค้างอยู่ตลอด session — ถ้าเคย `set TBL verilog` แล้วอยากกลับไปใช้ค่า default ให้ `unset TBL`

**ขั้นที่ 5 — ทดลองใน GUI**

```tcl
set DUT vhdl;    set TBL vhdl;    set TB dir; do run.do   ;# เหมือน 2C
set DUT vhdl;    set TBL verilog; set TB dir; do run.do   ;# ข้ามภาษา
set DUT verilog; set TBL vhdl;    set TB exh; do run.do   ;# ข้ามภาษา + exhaustive
```

**ขั้นที่ 6 — Regression 8 ชุด `regress.sh`**

```bash
#!/usr/bin/env bash
# regress.sh — RTL {vhdl,verilog} × TB {vhdl,verilog} × {dir,exh}
# MIXED=0 ./regress.sh  → ข้ามคู่ข้ามภาษา (ถ้า license ไม่รองรับ mixed-language)
cd "$(dirname "$0")"
MIXED=${MIXED:-1}
pass=0; fail=0
for DUT in vhdl verilog; do
  for TBL in vhdl verilog; do
    if [ "$MIXED" = 0 ] && [ "$DUT" != "$TBL" ]; then continue; fi
    for TB in dir exh; do
      log="log_${DUT}_${TBL}_${TB}.txt"
      vsim -c -do "set DUT $DUT; set TBL $TBL; set TB $TB; set BATCH 1; do run.do; quit -f" \
           < /dev/null > "$log" 2>&1
      if grep -q '\*\*\* PASS \*\*\*' "$log" && ! grep -qE 'FAIL|\*\* Error|\*\* Fatal' "$log"; then
        echo "PASS  rtl=$DUT  tb=$TBL  $TB";  pass=$((pass+1))
      else
        echo "FAIL  rtl=$DUT  tb=$TBL  $TB  (ดู $log)";  fail=$((fail+1))
      fi
    done
  done
done
echo "Summary: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
```

ผลที่คาดหวัง (`./regress.sh`):

```text
PASS  rtl=vhdl  tb=vhdl  dir
PASS  rtl=vhdl  tb=vhdl  exh
PASS  rtl=vhdl  tb=verilog  dir
PASS  rtl=vhdl  tb=verilog  exh
PASS  rtl=verilog  tb=vhdl  dir
PASS  rtl=verilog  tb=vhdl  exh
PASS  rtl=verilog  tb=verilog  dir
PASS  rtl=verilog  tb=verilog  exh
Summary: 8 pass, 0 fail
```

(ถ้าใช้ `MIXED=0` จะได้ 4 แถว `Summary: 4 pass, 0 fail`) — ผู้ใช้ Windows ที่ไม่มี Git Bash ให้รันคำสั่ง `vsim -c -do ...` ทีละชุดจาก Command Prompt

**ขั้นที่ 7 — พิสูจน์ความสอดคล้องของ RTL สองภาษา** — ใส่บั๊ก B1 (จาก 2C) เฉพาะใน `verilog/alu8.v` แล้วรัน regression: ทุกชุดที่ `rtl=verilog` ต้อง FAIL แต่ `rtl=vhdl` ยัง PASS — ตาราง regression บอกทันทีว่าปัญหาอยู่ที่ RTL ภาษาไหน ไม่ใช่ที่ testbench

✅ **Checkpoint 2E:** `Summary: 8 pass, 0 fail` (หรือ 4/4 เมื่อ license ไม่รองรับ mixed), screenshot หน้าต่าง Structure ที่เห็น TB กับ DUT ต่างภาษา, ผลการทดลองขั้นที่ 7

## แก้ปัญหา, คำถามท้าย Lab และการประเมิน

**ตารางแก้ปัญหาที่พบบ่อยใน Lab 2** (ข้อความจริงอาจต่างตามรุ่น ModelSim)

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| carry เป็น 0 ตลอด (Verilog) | ผลบวกถูกคำนวณที่ 8 บิต (เช่นอยู่ใน `{}` หรือเทียบกับค่า 8 บิต) | ใช้ `{1'b0, a} + {1'b0, b}` ใส่ wire 9 บิต (2B ขั้นที่ 3) |
| VHDL: length mismatch ตอน compile หรือ fatal ตอนรัน | กำหนดผลบวก 8 บิตให้สัญญาณ 9 บิต | `resize(unsigned(a), 9)` ก่อนบวก |
| `NUMERIC_STD.TO_INTEGER: metavalue detected` ที่เวลา 0 | b ยังเป็น `U` ก่อน testbench ป้อนค่า | กำหนดค่าเริ่มต้นให้สัญญาณใน TB (`:= (others => '0')`) — ถ้าเกิดหลังเวลา 0 ต้องหาสาเหตุ |
| SLT ผิดที่ (7F, 80) และ (80, 7F) | ใช้ `dif9[7]` อย่างเดียว | `dif9[7] xor ovf_sub` |
| SRL เติม 1 เมื่อ a ติดลบ | ใช้ `signed` หรือ `>>>` | `shift_right(unsigned(...))` / `>>` |
| zero ผิดในคำสั่ง logic/shift | คำนวณ zero จาก `sum9` แทน y | คำนวณจาก y ที่เลือกแล้ว |
| synthesis เตือน latch ที่ carry/ovf | ไม่มี default ก่อน `case` | กำหนด default ให้ทุกเอาต์พุตที่ต้น process/always |
| Exhaustive รันช้ามาก | ใช้ `+acc` + `add wave` หรือพิมพ์ทุก vector | `vsim` ไม่ใส่ `+acc`, พิมพ์เฉพาะ FAIL 10 ตัวแรก |
| `vlog` ฟ้อง syntax ที่ `int`, `function automatic`, `return` | compile ไฟล์ .sv โดยไม่ใส่ `-sv` | `vlog -sv` (หรือใช้นามสกุล .sv) |
| หา `alu8` ไม่พบ ตอน compile/elaborate TB | compile TB ก่อน RTL หรือล้าง library ไปแล้ว | RTL ก่อน TB เสมอ; VHDL TB + Verilog RTL ใช้ component declaration |
| error เรื่อง mixed-language/license ตอน `vsim` | edition ไม่รองรับหลายภาษา | `MIXED=0 ./regress.sh` และทำ 2E บนเครื่องที่มี license |

**คำถามท้าย Lab**

1. สเปกนี้ให้ carry = 1 เมื่อ SUB ต้องยืม — ถ้าเปลี่ยนเป็นแบบ ARM (carry = 1 เมื่อไม่ยืม) ต้องแก้ RTL, reference model และตาราง directed ตรงไหนบ้าง
2. ทำไม SLT ต้องใช้ `diff7 xor ovf` — ยกตัวอย่าง a, b ที่ใช้ diff7 อย่างเดียวแล้วผิด พร้อมคำนวณให้ดู
3. Exhaustive ตรวจกี่ vector ใช้เวลาเท่าไร (จากขั้นที่ 5 ของ 2D) และถ้าเป็น ALU 16 บิตจะใช้เวลาประมาณเท่าไร
4. ทำไมบั๊ก B3 ผ่าน directed แต่ไม่ผ่าน exhaustive และในงานจริงควรใช้ test ทั้งสองแบบอย่างไร
5. ถ้า reference model เขียน ovf ด้วยสูตรบิตเดียวกับ RTL จะเกิดความเสี่ยงอะไร
6. RTL นี้มีตัวบวก 2 ตัว (`sum9`, `dif9`) — เขียนให้เหลือตัวเดียวได้อย่างไร และมี trade-off อะไร
7. ใน regression ขั้นที่ 7 ของ 2E รูปแบบ PASS/FAIL บอกอะไร และถ้าทุกชุด FAIL เฉพาะ `tb=vhdl` จะสงสัยอะไร

**เฉลยสำหรับผู้สอน**

| ข้อ | แนวคำตอบ |
| --- | --- |
| 1 | RTL: `carry <= not dif9(8)` (หรือคำนวณแบบ `a + not b + 1` แล้วใช้ carry out ตรง ๆ); reference: `rc = (ua >= ub)`; directed: กลับค่า c ของแถว SUB ทั้ง 4 แถว — สิ่งสำคัญคือสเปกต้องระบุชัด เพราะทั้งสองแบบ "ถูก" ได้ |
| 2 | a = 7F, b = 80: a−b = 7F − 80 = FF (bit7 = 1 ดูเหมือน a < b) แต่จริง 127 > −128 เพราะผลลบ 255 ล้นช่วง signed (ovf = 1) → ต้องกลับเครื่องหมาย: 1 xor 1 = 0 |
| 3 | 524,288 vectors; เวลาตามเครื่อง — ALU 16 บิตมี 2^(3+16+16) = 2^35 vectors = 65,536 เท่า → ถ้า 8 บิตใช้ 10 วินาที 16 บิตจะใช้ \~7.6 วัน → ไม่คุ้ม ต้องเปลี่ยนเป็น random + coverage หรือ formal |
| 4 | ตาราง directed ใช้ shift 0, 1, 7 ซึ่ง b\[1\] = b\[2\] บั๊กจึงไม่แสดงผล; directed = เอกสารความตั้งใจและ debug ง่าย, exhaustive/random = จับสิ่งที่ไม่ได้คิด — ใช้คู่กัน และทุกบั๊กที่ random เจอให้เพิ่มเป็น directed เพื่อกันกลับมาซ้ำ (regression) |
| 5 | ถ้าสูตรผิดเหมือนกัน ผลจะตรงกันทุก vector และรายงาน PASS — reference ต้องมาจากนิยามในสเปก (ช่วงค่า signed) ไม่ใช่จาก implementation |
| 6 | ใช้ adder ตัวเดียว: `bx = (op == SUB) ? ~b : b`, `cin = (op == SUB)`, `res9 = a + bx + cin` — ประหยัดพื้นที่แต่มี XOR/mux บน path ของ b และต้องระวังความหมาย carry ตอนลบ (ได้แบบ ARM ต้องกลับบิตให้เป็น borrow) — พิสูจน์ด้วย exhaustive TB ชุดเดิมและเทียบพื้นที่ด้วย Yosys `stat` |
| 7 | บั๊กอยู่ที่ RTL Verilog เท่านั้น — ถ้า FAIL เฉพาะ `tb=vhdl` ทุก RTL แปลว่าปัญหาอยู่ที่ testbench หรือ reference model ภาษา VHDL (เช่น mod ของค่าลบ, การแปลง signed) |

**งานที่ต้องส่ง** (บีบอัด `lab02_alu/` โดยลบ `work/`, `*.wlf`, `transcript`, log ออก ยกเว้น log ที่กำหนด)

1. `doc/block_diagram.png` และ `doc/hand_calc.md` (ตาราง 19 แถวคำนวณเอง + การคำนวณแถว 8)
2. RTL สองภาษา + testbench 4 ไฟล์, `run.do`, `regress.sh`
3. Output ของ `./regress.sh` (`Summary: 8 pass, 0 fail` หรือ 4/4) และเวลารัน exhaustive ทั้งสองภาษา
4. บันทึก bug injection B1, B2, B3 และการทดลองขั้นที่ 7 ของ 2E (แก้อะไร / test ไหน FAIL / กี่จุด)
5. Screenshot: waveform หรือ List window ของ directed test, หน้าต่าง Structure ที่เห็น TB/DUT ต่างภาษา
6. คำตอบคำถาม 7 ข้อ

**เกณฑ์ให้คะแนน Lab 2 (100 คะแนน)**

| หัวข้อ | คะแนน | เต็ม | บางส่วน |
| --- | --- | --- | --- |
| 2.0 block diagram + คำนวณด้วยมือ | 15 | ครบ 19 แถวถูกต้อง + แสดงวิธีคิด flag | ผิด ≤ 3 แถว |
| 2A/2B RTL สองภาษา | 20 | ไม่มี latch/warning, ใช้ constant opcode, ความกว้างบิตชัดเจน | ภาษาเดียวสมบูรณ์ |
| 2C directed TB | 15 | table-driven สองภาษา PASS + B1/B2 | ภาษาเดียว |
| 2D exhaustive + reference model | 25 | reference อิสระ, 524,288 vectors PASS สองภาษา, ตาราง error ต่อ op, B3 ครบ | reference คัดสูตรจาก RTL |
| 2E mixed-language + regression | 15 | 8/8 (หรือ 4/4 + อธิบายข้อจำกัด license) + ขั้นที่ 7 | รันได้เฉพาะ GUI |
| คำตอบ 7 ข้อ | 10 | ถูกต้องพร้อมตัวเลขจาก simulation | ไม่มีหลักฐาน |

**หมายเหตุสำหรับผู้สอน:** จุดที่ผู้เรียนติดมากที่สุดคือ 2.0 (แยก carry กับ ovf ไม่ออก) — ควรเฉลยแถว 3, 4, 8, 17 บนกระดานก่อนให้เริ่มเขียน RTL ถ้า license ในห้องแลบไม่รองรับ mixed-language ให้ทำ 2E เป็น demo หน้าห้องแทน

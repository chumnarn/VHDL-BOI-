# Lab 7 — Clock Gating, Power Report และ Scan Chain

Oct 28, 2026 · @Chumnarn Punyasai

## ภาพรวม

Lab นี้เป็นภาคปฏิบัติของ Module 07 — Explore Low Power and DFT Basics แบ่งเป็นสองครึ่ง: **low power** (7A–7B) พิสูจน์ว่า clock gating ไม่เปลี่ยนพฤติกรรมแต่ลด clock edge และกำลังไฟได้จริง และ **DFT** (7C–7E) สร้าง scan chain ด้วยมือ ทดสอบแบบ ATE แล้วฉีด fault ดูว่า scan test จับได้จริง

| ส่วน | งาน | เครื่องมือ | เวลา |
| --- | --- | --- | --- |
| 7A | พิสูจน์ clock gating: `regbank` เทียบ `regbank_icg` | ModelSim | 60 นาที |
| 7B | สังเคราะห์ + รายงาน power ทั้งสองแบบ | Yosys + OpenSTA | 60 นาที |
| 7C | scan chain 4 บิตด้วยมือ + testbench แบบ ATE | ModelSim | 45 นาที |
| 7D | fault injection ด้วย `force` คำนวณ fault coverage | ModelSim | 60 นาที |
| 7E | (ทางเลือก) scan insertion อัตโนมัติ | OpenROAD | 30 นาที |

**พื้นฐานที่ต้องมี:** สคริปต์ synthesis/STA และ `gls_cells.sh` จาก Lab 6, หลัก P = αCV²f และ ICG แบบ latch (หัวข้อ 7.2), ลำดับ shift → capture → shift (หัวข้อ 7.5)

### โครงสร้างโฟลเดอร์

```text
DICD-2/lab07_lp_dft/
├── rtl/        icg_model.v  icg_model.vhd  regbank.v  regbank.vhd
│               regbank_icg.v  regbank_icg.vhd
│               scan_dff.vhd  scan_counter_vhd.vhd  scan_counter.v  counter8.v
├── tb/         tb_regbank.sv  tb_regbank.vhd  vcd_dump.sv
│               tb_scan_counter.sv  tb_scan_counter.vhd  tb_chain_flush.sv
├── syn/        syn.tcl  power.tcl  power_vcd.tcl  gls_cells.sh  dft.tcl
├── run_7a.do  run_7a_vhdl.do  run_7c.do  run_7d.do  run_7d_chain.do
├── out/        netlist
├── sim/        ไฟล์ gate-level sim + VCD
└── reports/
```

**ทุกคำสั่งในคู่มือรันจากราก `lab07_lp_dft/`** (ไฟล์ .do อ้าง `rtl/...` และ `tb/...`)

### เตรียมเครื่อง (10 นาที)

```bash
mkdir -p ~/DICD-2/lab07_lp_dft/{rtl,tb,syn,out,sim,reports} && cd ~/DICD-2/lab07_lp_dft
cp ../lab06/scripts/gls_cells.sh syn/                      # จาก Lab 6
export LIB=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
# หรือใช้ .lib จาก ORFS: ~/OpenROAD-flow-scripts/flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
export SC_HD=~/sky130_fd_sc_hd                             # Verilog model ของ cell (Lab 6 ส่วน 6E)
which vsim yosys sta
```

| เครื่องมือ | เวอร์ชันที่ใช้ตรวจคู่มือนี้ |
| --- | --- |
| Yosys | 0.69 |
| OpenSTA | 3.1.0 (มี `read_vcd`) |
| Simulator สำรอง | Icarus Verilog 12, Verilator 5.020, GHDL 4.1 (ใช้แทน ModelSim ตอนเตรียมคู่มือ) |

> การเปลี่ยนแปลงจากโค้ดในเนื้อหา Module 07: `tb_regbank.sv` เพิ่ม `` `ifdef GLS `` ให้ใช้กับ netlist ได้, เพิ่ม `regbank_icg.vhd` / `tb_regbank.vhd` / `tb_scan_counter.vhd` สำหรับสาย VHDL ล้วน, `syn.tcl` เพิ่ม `read_liberty -lib` และ dont\_use จาก Lab 6, และ `dft.tcl` เพิ่ม `read_lef` กับ `create_clock` ที่ OpenROAD ต้องใช้

## 7A — พิสูจน์ Clock Gating ใน ModelSim (60 นาที)

**เป้าหมาย:** ยืนยัน 3 ข้อ — (1) `regbank` (enable ธรรมดา) กับ `regbank_icg` (ICG) ให้ q เท่ากันทุก cycle (2) gclk มีขอบขาขึ้นเท่ากับจำนวน cycle ที่ en = 1 พอดี (3) test\_en = 1 บังคับเปิด clock ได้แม้ en = 0

### ขั้นที่ 1 — RTL (15 นาที)

`rtl/regbank.v` — แบบอ้างอิง (enable ธรรมดา):

```verilog
// regbank.v : register W บิตใช้ enable ร่วมกัน — synthesis จะได้ mux หน้า FF ทุกตัว
module regbank #(parameter W = 32) (
  input  wire         clk, rst_n, en,
  input  wire [W-1:0] d,
  output reg  [W-1:0] q
);
  always @(posedge clk or negedge rst_n)
    if (!rst_n)  q <= {W{1'b0}};
    else if (en) q <= d;
endmodule
```

`rtl/icg_model.v` — model พฤติกรรมของ ICG แบบ latch (ใช้จำลองเท่านั้น — สังเคราะห์จริงใช้ cell `sdlclkp` ใน 7B):

```verilog
// icg_model.v — พฤติกรรมเหมือน ICG (ใช้จำลองเท่านั้น)
module icg_model (input wire CLK, GATE, SCE, output wire GCLK);
  reg en_l;
  always @(CLK or GATE or SCE)
    if (!CLK) en_l = GATE | SCE;           // latch โปร่งใสตอน CLK = 0
  assign GCLK = CLK & en_l;
endmodule
```

`rtl/regbank_icg.v`:

```verilog
// regbank_icg.v — register bank ที่ใช้ ICG ตัวเดียวคุม W บิต
module regbank_icg #(parameter W = 32) (
  input  wire         clk, rst_n, en, test_en,
  input  wire [W-1:0] d,
  output reg  [W-1:0] q
);
  wire gclk;
`ifdef USE_SKY130
  sky130_fd_sc_hd__sdlclkp_1 u_icg (.CLK(clk), .GATE(en), .SCE(test_en), .GCLK(gclk));
`else
  icg_model                  u_icg (.CLK(clk), .GATE(en), .SCE(test_en), .GCLK(gclk));
`endif

  // async reset: ถ้าใช้ sync reset ตอน en = 0 clock ถูกปิด จะ reset ไม่ได้!
  always @(posedge gclk or negedge rst_n)
    if (!rst_n) q <= {W{1'b0}};
    else        q <= d;
endmodule
```

ชื่อพอร์ต `CLK`/`GATE`/`SCE`/`GCLK` ตรงกับ cell จริง (ตรวจแล้วใน `sky130_fd_sc_hd__sdlclkp.functional.v` และ .lib) จึงสลับ model ได้ด้วย `+define+USE_SKY130` อย่างเดียว

### ขั้นที่ 2 — Testbench (10 นาที)

`tb/tb_regbank.sv` — เทียบสอง DUT นับขอบ clock และทดสอบโหมด test:

```systemverilog
`timescale 1ns/1ps
module tb_regbank;
  localparam int W = 32, NCYC = 200;
  logic clk = 0, rst_n = 0, en = 0, test_en = 0;
  logic [W-1:0] d = '0, q_ref, q_icg;
  int n_clk = 0, n_gclk = 0, n_en = 0, errors = 0;

`ifdef GLS                                             // netlist ไม่มี parameter แล้ว (W ฝังเป็น 32)
  regbank              dut_r (.clk, .rst_n, .en, .d, .q(q_ref));
  regbank_icg          dut_g (.clk, .rst_n, .en, .test_en, .d, .q(q_icg));
`else
  regbank     #(.W(W)) dut_r (.clk, .rst_n, .en, .d, .q(q_ref));
  regbank_icg #(.W(W)) dut_g (.clk, .rst_n, .en, .test_en, .d, .q(q_icg));
`endif

  always #5 clk = ~clk;                                  // 100 MHz
  always @(posedge clk)        if (rst_n) begin n_clk++; if (en) n_en++; end
  always @(posedge dut_g.gclk) if (rst_n) n_gclk++;

  // เทียบที่ negedge (ค่านิ่งแล้ว) ยกเว้นตอน test_en=1 ซึ่งตั้งใจให้ต่าง
  always @(negedge clk)
    if (rst_n && !test_en && q_ref !== q_icg) begin
      errors++;
      $error("t=%0t mismatch ref=%h icg=%h", $time, q_ref, q_icg);
    end

  initial begin
    int clk_a, gclk_a, en_a;
    repeat (2) @(negedge clk);
    rst_n = 1;
    for (int i = 0; i < NCYC; i++) begin
      @(negedge clk);                                    // เปลี่ยนอินพุตที่ negedge กัน race
      d  = $urandom;
      en = ($urandom_range(0, 3) == 0);                  // en = 1 ประมาณ 25%
    end
    @(posedge clk); #1;
    clk_a = n_clk; gclk_a = n_gclk; en_a = n_en;

    // Test mode: en = 0 แต่ test_en = 1 → gclk ต้องมาทุก cycle
    @(negedge clk); en = 0; test_en = 1;
    repeat (20) @(negedge clk);

    $display("--- functional mode ---");
    $display("clk edges=%0d  gclk edges=%0d  en=1 cycles=%0d  ratio=%.2f",
             clk_a, gclk_a, en_a, real'(gclk_a) / clk_a);
    if (gclk_a != en_a) begin errors++; $error("gclk edges != en cycles"); end
    $display("--- test mode: gclk edges in 20 cycles = %0d (expect 20) ---",
             n_gclk - gclk_a - (n_en - en_a));
    $display("RESULT errors=%0d", errors);
    $stop;
  end
endmodule
```

| จุดสำคัญ | เหตุผล |
| --- | --- |
| เปลี่ยน `d`, `en` ที่ negedge | gclk ช้ากว่า clk หลาย delta cycle — ถ้าเปลี่ยนที่ posedge FF ฝั่ง gclk อาจเห็นค่าใหม่ (race) |
| `posedge dut_g.gclk` | hierarchical reference นับขอบของสัญญาณภายใน DUT โดยไม่ต้องเพิ่มพอร์ต (ใน netlist ชื่อ `gclk` ยังอยู่ จึงใช้ได้ใน 7B ด้วย) |
| `gclk_a != en_a` → error | คำกล่าวหลักของ clock gating: ทุก cycle ที่ en = 1 ได้ 1 พัลส์ ไม่มากไม่น้อย |
| `` `ifdef GLS `` | ใช้ testbench เดิมกับ netlist ใน 7B (netlist ไม่มี parameter W) |

### ขั้นที่ 3 — รันใน ModelSim (10 นาที)

`run_7a.do`:

```tcl
vlib work
vlog -sv rtl/icg_model.v rtl/regbank.v rtl/regbank_icg.v tb/tb_regbank.sv
vsim -voptargs=+acc work.tb_regbank
add wave /tb_regbank/clk /tb_regbank/en /tb_regbank/test_en
add wave /tb_regbank/dut_g/u_icg/en_l /tb_regbank/dut_g/gclk
add wave -radix hex /tb_regbank/d /tb_regbank/q_ref /tb_regbank/q_icg
run -all
```

```bash
vsim -do run_7a.do          # GUI
vsim -c -do run_7a.do       # transcript อย่างเดียว
```

ผลจริง (Icarus 12 ด้วยโค้ดเดียวกัน; ตัวเลขขอบ gclk ต่างตาม seed ของ simulator):

```text
--- functional mode ---
clk edges=201  gclk edges=50  en=1 cycles=50  ratio=0.25
--- test mode: gclk edges in 20 cycles = 20 (expect 20) ---
RESULT errors=0
```

**สิ่งที่ต้องชี้ใน waveform** (ซูมช่วง en สลับ 0/1):

1. `en_l` เปลี่ยนเฉพาะตอน clk = 0 — ตอน clk = 1 ค่าค้างแม้ en จะเปลี่ยน
2. gclk เป็นพัลส์เต็มครึ่งคาบ (5 ns) หรือเป็น 0 ตลอด — ไม่มีพัลส์สั้น
3. ช่วงท้าย (test\_en = 1, en = 0) gclk มาทุก cycle และ `q_icg` ตาม `d` ทุก cycle ส่วน `q_ref` ค้าง — ตั้งใจให้ต่าง (checker ปิดตอน test\_en = 1)

### ขั้นที่ 4 — สาย VHDL (10 นาที)

`rtl/regbank.vhd` และ `rtl/icg_model.vhd` (จากหัวข้อ 7.2 — entity เต็ม):

```vhdl
-- regbank.vhd : register W บิต ใช้ enable ร่วมกัน (เทียบเท่า regbank.v)
library ieee;
use ieee.std_logic_1164.all;

entity regbank is
  generic (W : positive := 32);
  port (clk, rst_n, en : in  std_logic;
        d              : in  std_logic_vector(W-1 downto 0);
        q              : out std_logic_vector(W-1 downto 0));
end entity;

architecture rtl of regbank is
begin
  process (clk, rst_n)
  begin
    if rst_n = '0' then
      q <= (others => '0');
    elsif rising_edge(clk) then
      if en = '1' then
        q <= d;                 -- ไม่มี else → synthesis ทำ clock gating ได้
      end if;
    end if;
  end process;
end architecture;
```

```vhdl
-- icg_model.vhd
library ieee;
use ieee.std_logic_1164.all;

entity icg_model is
  port (CLK, GATE, SCE : in std_logic; GCLK : out std_logic);
end entity;

architecture beh of icg_model is
  signal en_l : std_logic := '0';
begin
  process(CLK, GATE, SCE)
  begin
    if CLK = '0' then en_l <= GATE or SCE; end if;
  end process;
  GCLK <= CLK and en_l;
end architecture;
```

`rtl/regbank_icg.vhd`:

```vhdl
-- regbank_icg.vhd : register W บิตที่ใช้ ICG ตัวเดียว (เทียบเท่า regbank_icg.v)
library ieee;
use ieee.std_logic_1164.all;

entity regbank_icg is
  generic (W : positive := 32);
  port (clk, rst_n, en, test_en : in  std_logic;
        d                       : in  std_logic_vector(W-1 downto 0);
        q                       : out std_logic_vector(W-1 downto 0));
end entity;

architecture rtl of regbank_icg is
  signal gclk : std_logic;
begin
  u_icg : entity work.icg_model
    port map (CLK => clk, GATE => en, SCE => test_en, GCLK => gclk);

  process (gclk, rst_n)          -- async reset: clock ถูกปิดตอน en = 0 จึง reset แบบ sync ไม่ได้
  begin
    if rst_n = '0' then
      q <= (others => '0');
    elsif rising_edge(gclk) then
      q <= d;
    end if;
  end process;
end architecture;
```

`tb/tb_regbank.vhd` — สำหรับ simulator ที่ไม่รองรับ mixed-language (ใช้ external name ของ VHDL-2008 แทน hierarchical reference):

```vhdl
-- tb_regbank.vhd : testbench สาย VHDL ล้วน (โครงเดียวกับ tb_regbank.sv)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_regbank is
  generic (NCYC : positive := 200);
end entity;

architecture sim of tb_regbank is
  constant W : positive := 32;
  signal clk, rst_n, en, test_en : std_logic := '0';
  signal d, q_ref, q_icg : std_logic_vector(W-1 downto 0) := (others => '0');
  signal done : boolean := false;
  signal n_clk, n_gclk, n_en, errors : natural := 0;
begin
  clk <= not clk after 5 ns when not done else '0';

  dut_r : entity work.regbank     generic map (W) port map (clk, rst_n, en, d, q_ref);
  dut_g : entity work.regbank_icg generic map (W) port map (clk, rst_n, en, test_en, d, q_icg);

  count_clk : process (clk) begin
    if rising_edge(clk) and rst_n = '1' then
      n_clk <= n_clk + 1;
      if en = '1' then n_en <= n_en + 1; end if;
    end if;
  end process;

  count_gclk : process                            -- external name ต้องประกาศหลัง dut_g ถูก elaborate แล้ว
    alias gclk is << signal .tb_regbank.dut_g.gclk : std_logic >>;   -- VHDL-2008
  begin
    wait until rising_edge(gclk);
    if rst_n = '1' then n_gclk <= n_gclk + 1; end if;
  end process;

  check : process (clk) begin
    if falling_edge(clk) and rst_n = '1' and test_en = '0' and q_ref /= q_icg then
      errors <= errors + 1;
      report "mismatch ref=" & to_hstring(q_ref) & " icg=" & to_hstring(q_icg) severity error;
    end if;
  end process;

  stim : process
    variable s1, s2 : positive := 7;
    variable r : real;
    variable clk_a, gclk_a, en_a : natural;
  begin
    wait until falling_edge(clk); wait until falling_edge(clk);
    rst_n <= '1';
    for i in 1 to NCYC loop
      wait until falling_edge(clk);               -- เปลี่ยนอินพุตที่ขอบขาลง กัน race
      for b in 0 to 3 loop                        -- d สุ่ม 32 บิต ทีละ 8 บิต
        uniform(s1, s2, r);
        d(8*b+7 downto 8*b) <= std_logic_vector(to_unsigned(integer(floor(r * 256.0)), 8));
      end loop;
      uniform(s1, s2, r);
      en <= '1' when r < 0.25 else '0';           -- en = 1 ประมาณ 25%
    end loop;
    wait until rising_edge(clk); wait for 1 ns;
    clk_a := n_clk; gclk_a := n_gclk; en_a := n_en;

    wait until falling_edge(clk); en <= '0'; test_en <= '1';   -- test mode
    for i in 1 to 20 loop wait until falling_edge(clk); end loop;

    report "functional: clk edges=" & integer'image(clk_a) & " gclk edges=" & integer'image(gclk_a)
         & " en=1 cycles=" & integer'image(en_a);
    report "test mode: gclk edges in 20 cycles = " & integer'image(n_gclk - gclk_a) & " (expect 20)";
    if gclk_a /= en_a or n_gclk - gclk_a /= 20 then
      report "gclk count wrong" severity error;
    end if;
    report "RESULT errors=" & integer'image(errors);
    done <= true;
    wait;
  end process;
end architecture;
```

`run_7a_vhdl.do`:

```tcl
vlib work
vcom -2008 rtl/icg_model.vhd rtl/regbank.vhd rtl/regbank_icg.vhd tb/tb_regbank.vhd
vsim -voptargs=+acc work.tb_regbank
add wave /tb_regbank/clk /tb_regbank/en /tb_regbank/test_en
add wave /tb_regbank/dut_g/u_icg/en_l /tb_regbank/dut_g/gclk
add wave -radix hex /tb_regbank/d /tb_regbank/q_ref /tb_regbank/q_icg
run -all
```

ผลจริง (GHDL 4.1, `--std=08`; seed ต่างจากสาย Verilog จำนวน en จึงต่าง):

```text
functional: clk edges=201 gclk edges=57 en=1 cycles=57
test mode: gclk edges in 20 cycles = 20 (expect 20)
RESULT errors=0
```

### ขั้นที่ 5 — แบบฝึก (15 นาที)

**แบบฝึก 1 — ทำไมห้าม AND ธรรมดา:** คัดลอกไฟล์แล้วแก้สองจุด

```verilog
// ex/icg_and.v — clock gate ผิดแบบ (อย่าใช้จริง)
module icg_model (input wire CLK, GATE, SCE, output wire GCLK);
  assign GCLK = CLK & (GATE | SCE);
endmodule
```

```bash
mkdir -p ex
sed 's/@(negedge clk);  *\/\/ .*race/@(posedge clk); #2;/' tb/tb_regbank.sv > ex/tb_regbank_late.sv
grep -n "posedge clk); #2" ex/tb_regbank_late.sv     # ต้องเจอ 1 บรรทัด (ใน loop)
```

| ชุด | ผลจริง |
| --- | --- |
| `ex/icg_and.v` + `tb_regbank_late.sv` | `gclk edges=90  en=1 cycles=50  ratio=0.45` · mismatch 41 ครั้ง · `RESULT errors=42` |
| `rtl/icg_model.v` (latch) + `tb_regbank_late.sv` | `gclk edges=50  en=1 cycles=50` · `RESULT errors=0` |

อธิบาย: en เปลี่ยนที่ 2 ns หลังขอบขาขึ้น (ตอน clk = 1 เหมือน en ที่มาจาก FF จริง) — AND ธรรมดาสร้างขอบขาขึ้นกลางคาบ (พัลส์สั้น 3 ns) ทำให้ FF จับข้อมูลผิดจังหวะ ส่วน latch ปิดอยู่ตลอดช่วง clk = 1 จึงไม่เห็น en ที่เปลี่ยนกลางคาบ — ให้จับภาพ waveform ที่เห็นพัลส์สั้นบน gclk

**แบบฝึก 2 — สัดส่วน en:** แก้ `$urandom_range(0, 3) == 0` เป็น `$urandom_range(0, 9) == 0` (10%), `$urandom_range(0, 1) == 0` (50%), `$urandom_range(0, 9) != 0` (90%) บันทึก ratio — จะใช้เทียบกับ power ใน 7B

**แบบฝึก 3 — reset แบบ sync:** แก้ `regbank_icg.v` เป็น `always @(posedge gclk) if (!rst_n) ...` แล้วให้ testbench ปล่อย reset ตอน en = 0 — อธิบายสิ่งที่เห็นใน q\_icg ช่วงแรก

✅ **Checkpoint 7A:** ทั้งสาย Verilog และ VHDL ได้ `RESULT errors=0`, gclk edges = en cycles, test mode = 20 และมีภาพ waveform ที่ชี้จุด latch ค้างค่า

## 7B — ประมาณกำลังไฟด้วย Yosys + OpenSTA (60 นาที)

**เป้าหมาย:** สังเคราะห์ทั้งสองแบบด้วย sky130 HD แล้วเทียบ cell, พื้นที่ และ power — ทั้งแบบประมาณ (vectorless) และแบบใช้ activity จริงจาก simulation (VCD)

### ขั้นที่ 1 — Synthesis (15 นาที)

`syn/syn.tcl` (ดัดแปลงจาก Lab 6: เพิ่ม `DEFS` สำหรับ `-DUSE_SKY130` และ `W` สำหรับเปลี่ยนความกว้าง):

```tcl
# syn.tcl — Yosys synthesis ไปยัง sky130_fd_sc_hd (ดัดแปลงจาก Module 06)
# ใช้งาน:  TOP=regbank RTL="rtl/regbank.v" yosys -c syn/syn.tcl
#          TOP=regbank_icg RTL="rtl/regbank_icg.v" DEFS="-DUSE_SKY130" yosys -c syn/syn.tcl
#          W=4 TAG=regbank_w4 TOP=regbank RTL="rtl/regbank.v" yosys -c syn/syn.tcl   (เปลี่ยนความกว้าง)
yosys -import
set TOP  $::env(TOP)
set TAG  [expr {[info exists ::env(TAG)] ? $::env(TAG) : $TOP}]
set LIB  $::env(LIB)
set DEFS [expr {[info exists ::env(DEFS)] ? $::env(DEFS) : ""}]

read_liberty -lib $LIB                        ;# รู้จักพอร์ตของทุก cell (รวม sdlclkp ที่ instantiate เอง)
foreach f $::env(RTL) { read_verilog -sv {*}$DEFS $f }
if {[info exists ::env(W)]} { chparam -set W $::env(W) $TOP }   ;# เปลี่ยนความกว้างโดยไม่แก้ RTL
hierarchy -check -top $TOP
synth -top $TOP -flatten
set DONT_USE {-dont_use *lpflow* -dont_use *probe*}
dfflibmap -liberty $LIB {*}$DONT_USE
abc -liberty $LIB {*}$DONT_USE
setundef -zero
hilomap -singleton -hicell sky130_fd_sc_hd__conb_1 HI -locell sky130_fd_sc_hd__conb_1 LO
opt_clean -purge

tee -o reports/${TAG}_stat.txt  stat -liberty $LIB
tee -o reports/${TAG}_check.txt check
write_verilog -noattr out/${TAG}_syn.v
```

```bash
TOP=regbank     RTL="rtl/regbank.v"     yosys -q -c syn/syn.tcl
TOP=regbank_icg RTL="rtl/regbank_icg.v" DEFS="-DUSE_SKY130" yosys -q -c syn/syn.tcl
tail -12 reports/regbank_stat.txt reports/regbank_icg_stat.txt
```

ผลจริง (Yosys 0.69):

```text
=== regbank ===                                   === regbank_icg ===
  64 1.16E+03 cells                                 33  819.536 cells
  32  800.768   sky130_fd_sc_hd__dfrtp_1            32  800.768   sky130_fd_sc_hd__dfrtp_1
  32  360.346   sky130_fd_sc_hd__mux2_1              1   18.768   sky130_fd_sc_hd__sdlclkp_1
Chip area: 1161.1136                              Chip area: 819.536
```

| ค่า | regbank | regbank\_icg | ต่าง |
| --- | --- | --- | --- |
| จำนวน cell | 64 | 33 | −48% |
| พื้นที่ (µm²) | 1161.11 | 819.54 | −29.4% |
| `check` | 0 problems | 0 problems | — |

**อ่านผล:** `regbank` ได้ `mux2_1` 32 ตัววน q กลับเข้า D (ตามที่ทฤษฎีบอก) เพราะ sky130 HD ไม่มี FF ที่มีทั้ง enable และ async reset ใน cell เดียว — ICG 1 ตัว (18.8 µm²) แทน mux 32 ตัว (360.3 µm²) ทำให้พื้นที่ *ลด* ด้วย ไม่ใช่แค่ประหยัดไฟ ใน library ที่มี enable-FF ผลด้านพื้นที่จะไม่มากขนาดนี้

### ขั้นที่ 2 — report\_power แบบ vectorless (15 นาที)

`syn/power.tcl`:

```tcl
read_liberty $::env(LIB)
read_verilog $::env(NETLIST)
link_design  $::env(TOP)

create_clock -name clk -period 10 [get_ports clk]
set_power_activity -input -activity 0.2                    ;# อินพุตอื่นสลับ 0.2 ครั้ง/cycle
set DUTY [expr {[info exists ::env(DUTY)] ? $::env(DUTY) : 0.25}]
set_power_activity -input_ports en -activity 0.2 -duty $DUTY ;# en = 1 ราว DUTY ของเวลา (ค่าเริ่ม 25%)
if {[llength [get_ports -quiet test_en]]} {
  set_power_activity -input_ports test_en -activity 0 -duty 0
}
report_power
exit
```

```bash
NETLIST=out/regbank_syn.v     TOP=regbank     sta -no_splash syn/power.tcl | tee reports/pwr_regbank.rpt
NETLIST=out/regbank_icg_syn.v TOP=regbank_icg sta -no_splash syn/power.tcl | tee reports/pwr_icg.rpt
```

ผลจริง (duty 0.25):

```text
# regbank
Group                  Internal  Switching    Leakage      Total
Sequential             1.55e-04   3.08e-06   3.76e-10   1.58e-04  89.2%
Combinational          1.52e-05   3.85e-06   1.29e-10   1.91e-05  10.8%
Clock                  0.00e+00   0.00e+00   0.00e+00   0.00e+00   0.0%
Total                  1.70e-04   6.93e-06   5.04e-10   1.77e-04 100.0%

# regbank_icg
Sequential             4.39e-05   0.00e+00   3.71e-10   4.39e-05  83.8%
Combinational          0.00e+00   0.00e+00   0.00e+00   0.00e+00   0.0%
Clock                  3.64e-06   4.85e-06   1.30e-11   8.49e-06  16.2%
Total                  4.76e-05   4.85e-06   3.84e-10   5.24e-05 100.0%
```

| ค่า (µW) | regbank | regbank\_icg | ต่าง |
| --- | --- | --- | --- |
| Internal | 170 | 47.6 | −72% |
| Switching | 6.93 | 4.85 | −30% |
| Leakage | 0.000504 | 0.000384 | −24% |
| **Total** | **177** | **52.4** | **−70%** |
| สัดส่วน gclk/clk (จาก 7A) | 1.00 | 0.25 | — |

**อ่านผลทีละบรรทัด:**

1. **Internal power คือตัวหลัก (96%)** — คือพลังงานภายใน cell ทุกครั้งที่ขา CLK ของ FF เปลี่ยน แม้ Q ไม่เปลี่ยน — นี่คือสิ่งที่ทฤษฎีบอกว่า "enable ธรรมดายังกินไฟ"
2. **Sequential ลดจาก 158 เหลือ 43.9 µW (0.28 เท่า)** — ใกล้ duty 0.25 ของ en แสดงว่า OpenSTA ส่ง activity ผ่าน `sdlclkp` ได้ (ในเวอร์ชันนี้)
3. **กลุ่ม Clock โผล่มาเฉพาะแบบ ICG** — คือกำลังไฟของ ICG เอง (8.5 µW) ซึ่งต้องจ่ายทุก cycle ไม่ว่า en เป็นอะไร ส่วน regbank กลุ่ม Clock = 0 เพราะยังไม่มี clock tree (ideal clock) — **ในชิปจริงหลัง CTS จะประหยัดมากกว่านี้** เพราะ buffer ของ clock tree หลัง ICG ก็หยุดด้วย
4. **Combinational หายไปทั้งหมด** — mux 32 ตัวถูกตัดออก
5. **Leakage เล็กจนไม่มีผล** (\~0.5 nW ที่ 25°C) — ที่อุณหภูมิสูง (corner 100°C) leakage จะเพิ่มแบบ exponential

### ขั้นที่ 3 — กวาด duty และความกว้าง (15 นาที)

```bash
W=4 TAG=regbank_w4     TOP=regbank     RTL="rtl/regbank.v"     yosys -q -c syn/syn.tcl
W=4 TAG=regbank_icg_w4 TOP=regbank_icg RTL="rtl/regbank_icg.v" DEFS="-DUSE_SKY130" yosys -q -c syn/syn.tcl
for d in 0.1 0.25 0.5 0.9; do
  for t in regbank regbank_icg regbank_w4 regbank_icg_w4; do
    P=$(DUTY=$d NETLIST=out/${t}_syn.v TOP=${t%_w4} sta -no_splash syn/power.tcl | awk '/^Total/{print $5; exit}')
    printf "duty=%-5s %-16s %s W\n" $d $t $P
  done
done | tee reports/duty_sweep.txt
```

&#91;embedded content: ผลจริง: OpenSTA 3.1.0 report\_power, sky130\_fd\_sc\_hd TT 25°C 1.8 V, clock 100 MHz, อินพุต activity 0.2 · netlist จาก Yosys 0.69\]

ที่ duty 90% แบบ 32 บิตยังประหยัดเล็กน้อย (ICG 1 ตัวแลก mux 32 ตัว) แต่แบบ 4 บิตกินไฟมากกว่าไม่ใส่ (23.5 เทียบ 20.6 µW) เพราะกำลังไฟคงที่ของ ICG แบ่งกันแค่ 4 FF — นี่คือเหตุผลของ `-minimum_bitwidth` ในหัวข้อ 7.2 และที่เครื่องมือเชิงพาณิชย์ไม่ gate register ที่เกือบเปิดตลอด

### ขั้นที่ 4 — report\_power จาก VCD ของ gate-level sim (15 นาที)

ตัวเลข vectorless ขึ้นกับ activity ที่เราตั้งเอง วิธีที่แม่นกว่าคือเอา activity จริงจาก simulation ของ netlist โดยใช้ testbench เดิมของ 7A:

`tb/vcd_dump.sv`:

```systemverilog
// vcd_dump.sv — คอมไพล์ร่วมกับ tb_regbank.sv เพื่อบันทึกกิจกรรมของสัญญาณใน DUT ทั้งสอง
module vcd_dump;
  initial begin
    $dumpfile("sim/regbank.vcd");
    $dumpvars(0, tb_regbank.dut_r, tb_regbank.dut_g);
  end
endmodule
```

```bash
cat out/regbank_syn.v out/regbank_icg_syn.v > sim/both_syn.v
./syn/gls_cells.sh sim/both_syn.v rb                # → 3 cell types (dfrtp, mux2, sdlclkp)
```

ModelSim:

```tcl
# gls_7b.do — vsim -c -do gls_7b.do
vlib work_gls
vlog -work work_gls -sv -timescale 1ns/1ps +define+GLS +define+FUNCTIONAL +define+UNIT_DELAY=#1 \
     -f sim/incdirs.f sim/cells_rb.v sim/both_syn.v tb/tb_regbank.sv tb/vcd_dump.sv
vsim -lib work_gls -c tb_regbank vcd_dump
run -all
quit -f
```

Icarus (ทางเลือก):

```bash
iverilog -g2012 -DGLS -DFUNCTIONAL -DUNIT_DELAY=#1 -c sim/incdirs.f -s tb_regbank -s vcd_dump \
         -o sim/gls_rb tb/tb_regbank.sv tb/vcd_dump.sv sim/cells_rb.v sim/both_syn.v
vvp -n sim/gls_rb
```

ผลจริง: netlist ทั้งสองผ่าน testbench เดิม (`gclk edges=50 en=1 cycles=50`, `RESULT errors=0`) — ยืนยันว่า cell `sdlclkp_1` จริงทำงานเหมือน `icg_model`

`syn/power_vcd.tcl`:

```tcl
# power_vcd.tcl — report_power จาก activity จริงใน VCD ของ gate-level sim
# ใช้งาน:  NETLIST=out/regbank_syn.v TOP=regbank SCOPE=tb_regbank/dut_r sta -no_splash syn/power_vcd.tcl
read_liberty $::env(LIB)
read_verilog $::env(NETLIST)
link_design  $::env(TOP)
create_clock -name clk -period 10 [get_ports clk]
read_vcd -scope $::env(SCOPE) sim/regbank.vcd
report_power
exit
```

```bash
NETLIST=out/regbank_syn.v     TOP=regbank     SCOPE=tb_regbank/dut_r sta -no_splash syn/power_vcd.tcl | tee reports/pwr_vcd_regbank.rpt
NETLIST=out/regbank_icg_syn.v TOP=regbank_icg SCOPE=tb_regbank/dut_g sta -no_splash syn/power_vcd.tcl | tee reports/pwr_vcd_icg.rpt
```

| ค่า (µW) | regbank | regbank\_icg | ต่าง |
| --- | --- | --- | --- |
| pin ที่ annotate จาก VCD | 323 | 200 | — |
| Total (VCD) | 152 | 62.3 | −59% |
| Total (vectorless, duty 0.25) | 177 | 52.4 | −70% |

ทำไม VCD ประหยัดน้อยกว่า: VCD ครอบคลุมทั้งช่วง reset และ test mode 20 cycle ที่ gclk ทำงานทุก cycle (activity จริงสูงกว่า 25%) ส่วน d จาก `$urandom` สลับเฉลี่ย 0.5 ครั้ง/cycle/บิต ไม่ใช่ 0.2 — บทเรียนคือ ตัวเลข power มีความหมายเท่ากับ activity ที่ป้อนเข้าไป ต้องรายงาน power คู่กับ workload เสมอ

✅ **Checkpoint 7B:** ตาราง cell/area, ตาราง power แยก internal/switching/leakage, ผล duty sweep และคำอธิบาย 3–5 บรรทัดว่า clock gating คุ้มเมื่อไร (ความกว้าง + duty)

## 7C — สร้าง Scan Chain ด้วยมือ (45 นาที)

**เป้าหมาย:** counter 4 บิตที่ FF ทุกตัวเป็น scan FF ต่อเป็น chain เดียว แล้วทดสอบด้วยลำดับ shift → capture → shift แบบที่เครื่อง ATE ทำจริง และนับ test cycle เทียบกับสูตร (P+1)L+P

```text
        se=1: shift                          se=0: capture
scan_in → [q0] → [q1] → [q2] → [q3] → scan_out     q ← d = q + 1 (เมื่อ en = 1)
          SI(i) = Q(i-1),  SI(0) = scan_in
```

### ขั้นที่ 1 — RTL สาย VHDL: ต่อ chain แบบ structural (10 นาที)

`rtl/scan_dff.vhd` — scan FF = mux 2:1 หน้า DFF:

```vhdl
-- scan_dff.vhd
library ieee; use ieee.std_logic_1164.all;
entity scan_dff is
  port (clk, rst_n, se, si, d : in std_logic; q : out std_logic);
end entity;
architecture rtl of scan_dff is
begin
  process (clk, rst_n) begin
    if rst_n = '0' then q <= '0';
    elsif rising_edge(clk) then
      if se = '1' then q <= si;      -- shift
      else             q <= d;       -- functional / capture
      end if;
    end if;
  end process;
end architecture;
```

`rtl/scan_counter_vhd.vhd`:

```vhdl
-- scan_counter_vhd.vhd
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
entity scan_counter_vhd is
  generic (N : positive := 4);
  port (clk, rst_n, en, se, scan_in : in  std_logic;
        cnt      : out std_logic_vector(N-1 downto 0);
        scan_out : out std_logic);
end entity;
architecture str of scan_counter_vhd is
  signal q, d, si : std_logic_vector(N-1 downto 0);
begin
  d  <= std_logic_vector(unsigned(q) + 1) when en = '1' else q;  -- ลอจิก combinational
  si <= q(N-2 downto 0) & scan_in;                              -- Q(i-1) → SI(i)
  g_chain : for i in 0 to N-1 generate
    u_ff : entity work.scan_dff
      port map (clk => clk, rst_n => rst_n, se => se, si => si(i), d => d(i), q => q(i));
  end generate;
  cnt      <= q;
  scan_out <= q(N-1);
end architecture;
```

| บรรทัด | ความหมาย |
| --- | --- |
| `si <= q(N-2 downto 0) & scan_in` | เวกเตอร์ si ตำแหน่ง 0 คือ scan\_in, ตำแหน่ง i คือ q(i-1) — บรรทัดเดียว "เดินสาย" chain ทั้งเส้น |
| `for ... generate` | สร้าง scan FF N ตัว — เหมือนสิ่งที่เครื่องมือ DFT ทำกับ netlist (แทน DFF ด้วย scan FF แล้วเดินสาย SI) |
| `scan_out <= q(N-1)` | ปลาย chain — บิตที่ออกมาก่อนคือ q(3) |

### ขั้นที่ 2 — RTL สาย Verilog (5 นาที)

`rtl/scan_counter.v` — พฤติกรรมเหมือนกันแต่เขียนแบบ behavioral และแยกสาย `d` ออกมาชัด ๆ เพื่อใช้เป็นเป้า fault ใน 7D:

```verilog
module scan_counter #(parameter N = 4) (
  input  wire         clk, rst_n, en, se, scan_in,
  output wire [N-1:0] cnt,
  output wire         scan_out
);
  reg  [N-1:0] q;
  wire [N-1:0] d = en ? q + 1'b1 : q;          // ลอจิก combinational (เป้า fault ใน 7D)

  always @(posedge clk or negedge rst_n)
    if (!rst_n)  q <= {N{1'b0}};
    else if (se) q <= {q[N-2:0], scan_in};     // shift: scan_in → q[0] → ... → q[N-1]
    else         q <= d;                        // capture

  assign cnt      = q;
  assign scan_out = q[N-1];
endmodule
```

### ขั้นที่ 3 — Testbench ที่ทำตัวเหมือน ATE (10 นาที)

`tb/tb_scan_counter.sv`:

```systemverilog
`timescale 1ns/1ps
module tb_scan_counter;
  localparam int N = 4, NP = 5;
  logic clk = 0, rst_n = 0, en = 0, se = 0, scan_in = 0;
  logic [N-1:0] cnt, got, exp_v;
  logic scan_out;
  logic [N-1:0] pats [NP] = '{4'b0000, 4'b0101, 4'b0111, 4'b1010, 4'b1111};
  int errors = 0, cyc = 0;
  bit running = 0;

`ifdef VHDL_DUT
  scan_counter_vhd #(.N(N)) dut (.*);
`else
  scan_counter     #(.N(N)) dut (.*);
`endif

  always #5 clk = ~clk;
  always @(posedge clk) if (running) cyc++;

  // เลื่อน pattern ใหม่เข้า (MSB ก่อน) พร้อมอ่านผลเก่าออก (q[N-1] ออกมาก่อน)
  task automatic scan_shift(input logic [N-1:0] pat, output logic [N-1:0] out);
    se = 1;
    for (int i = N-1; i >= 0; i--) begin
      scan_in = pat[i];
      out[i]  = scan_out;              // อ่านก่อนขอบ clock
      @(posedge clk); #1;
    end
  endtask

  task automatic capture();
    se = 0; en = 1;
    @(posedge clk); #1;
    en = 0;
  endtask

  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1;
    @(negedge clk);
    running = 1;
    scan_shift(pats[0], got);                               // โหลด pattern แรก (ผลที่ออกมาทิ้งได้)
    for (int k = 0; k < NP; k++) begin
      capture();
      exp_v = pats[k] + 1'b1;
      scan_shift((k < NP-1) ? pats[k+1] : '0, got);         // unload ผล k + load k+1
      if (got !== exp_v) begin
        errors++;
        $display("FAIL pattern %b : expect %b got %b", pats[k], exp_v, got);
      end else
        $display("pass pattern %b -> %b", pats[k], got);
    end
    running = 0;
    $display("test cycles = %0d (formula (P+1)L+P = %0d)", cyc, (NP+1)*N + NP);
    $display("RESULT errors=%0d", errors);
    $stop;
  end
endmodule
```

| จุดสำคัญ | เหตุผล |
| --- | --- |
| อ่าน `scan_out` **ก่อน** `@(posedge clk)` | หลังขอบ clock บิตถัดไปจะเลื่อนมาแทนแล้ว — อ่านหลังขอบ = ผลเลื่อนไป 1 บิต |
| ป้อน MSB ก่อน | บิตแรกที่เข้าจะเดินไกลที่สุดไปอยู่ที่ q\[3\] |
| unload พร้อม load | คือ overlap ที่ทำให้สูตรเป็น (P+1)L+P ไม่ใช่ P(2L+1) |
| `capture` ตั้ง en = 1 แค่ 1 cycle | เท่ากับการตั้งค่า primary input ตอน capture ตามที่ ATPG กำหนด |

### ขั้นที่ 4 — รัน (10 นาที)

`run_7c.do`:

```tcl
vlib work
vlog -sv rtl/scan_counter.v tb/tb_scan_counter.sv
vsim -voptargs=+acc work.tb_scan_counter
add wave /tb_scan_counter/clk /tb_scan_counter/se /tb_scan_counter/en
add wave /tb_scan_counter/scan_in /tb_scan_counter/scan_out
add wave -radix binary /tb_scan_counter/dut/q /tb_scan_counter/got
run -all

# สาย VHDL + testbench SV (ต้องใช้ simulator ที่รองรับ mixed-language):
# vcom -2008 rtl/scan_dff.vhd rtl/scan_counter_vhd.vhd
# vlog -sv +define+VHDL_DUT tb/tb_scan_counter.sv
```

ผลจริง (Verilator 5.020 — Icarus 12 ไม่รองรับการกำหนดค่าตั้งต้นทั้ง array `'{...}`):

```text
pass pattern 0000 -> 0001
pass pattern 0101 -> 0110
pass pattern 0111 -> 1000
pass pattern 1010 -> 1011
pass pattern 1111 -> 0000
test cycles = 29 (formula (P+1)L+P = 29)
RESULT errors=0
```

ใน waveform จะเห็น se = 1 นาน 4 clock สลับกับ se = 0 นาน 1 clock — ให้ซูม pattern `0111`: หลัง shift q = 0111, หลัง capture q = 1000, แล้ว scan\_out ให้ 1, 0, 0, 0 ตามลำดับ

### ขั้นที่ 5 — สาย VHDL ล้วน (10 นาที)

ถ้า ModelSim ที่ใช้ไม่รองรับ mixed-language ให้ใช้ `tb/tb_scan_counter.vhd` (ลำดับเดียวกันทุกขั้น):

```vhdl
-- tb_scan_counter.vhd : testbench สาย VHDL ล้วน (ลำดับเดียวกับ tb_scan_counter.sv)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_scan_counter is
end entity;

architecture sim of tb_scan_counter is
  constant N  : positive := 4;
  constant NP : positive := 5;
  type pat_array is array (0 to NP-1) of std_logic_vector(N-1 downto 0);
  constant PATS : pat_array := ("0000", "0101", "0111", "1010", "1111");

  signal clk, rst_n, en, se, scan_in, scan_out : std_logic := '0';
  signal cnt     : std_logic_vector(N-1 downto 0);
  signal done    : boolean := false;
  signal running : boolean := false;
  signal cyc     : natural := 0;
begin
  clk <= not clk after 5 ns when not done else '0';

  dut : entity work.scan_counter_vhd
    generic map (N => N)
    port map (clk => clk, rst_n => rst_n, en => en, se => se, scan_in => scan_in,
              cnt => cnt, scan_out => scan_out);

  process (clk) begin
    if rising_edge(clk) and running then cyc <= cyc + 1; end if;
  end process;

  ate : process
    variable got, exp_v : std_logic_vector(N-1 downto 0);
    variable errors : natural := 0;

    -- เลื่อน pattern ใหม่เข้า (MSB ก่อน) พร้อมอ่านผลเก่าออก (q(N-1) ออกมาก่อน)
    procedure scan_shift(pat : std_logic_vector(N-1 downto 0);
                         variable outv : out std_logic_vector(N-1 downto 0)) is
    begin
      se <= '1';
      for i in N-1 downto 0 loop
        scan_in <= pat(i);
        wait for 0 ns;                    -- ให้ se/scan_in มีผลก่อนอ่าน
        outv(i) := scan_out;              -- อ่านก่อนขอบ clock
        wait until rising_edge(clk); wait for 1 ns;
      end loop;
    end procedure;

    procedure capture is
    begin
      se <= '0'; en <= '1';
      wait until rising_edge(clk); wait for 1 ns;
      en <= '0';
    end procedure;
  begin
    wait until falling_edge(clk); wait until falling_edge(clk);
    rst_n <= '1';
    wait until falling_edge(clk);
    running <= true;
    scan_shift(PATS(0), got);                                 -- load pattern แรก
    for k in 0 to NP-1 loop
      capture;
      exp_v := std_logic_vector(unsigned(PATS(k)) + 1);
      if k < NP-1 then scan_shift(PATS(k+1), got);            -- unload k + load k+1
      else             scan_shift((others => '0'), got);
      end if;
      if got /= exp_v then
        errors := errors + 1;
        report "FAIL pattern " & to_string(PATS(k)) & " : expect " & to_string(exp_v)
             & " got " & to_string(got) severity error;
      else
        report "pass pattern " & to_string(PATS(k)) & " -> " & to_string(got);
      end if;
    end loop;
    running <= false;
    wait for 0 ns;
    report "test cycles = " & integer'image(cyc) & " (formula (P+1)L+P = "
         & integer'image((NP+1)*N + NP) & ")";
    report "RESULT errors=" & integer'image(errors);
    done <= true;
    wait;
  end process;
end architecture;
```

```tcl
# run_7c_vhdl — พิมพ์ใน transcript หรือเก็บเป็น .do
vlib work
vcom -2008 rtl/scan_dff.vhd rtl/scan_counter_vhd.vhd tb/tb_scan_counter.vhd
vsim -voptargs=+acc work.tb_scan_counter
add wave /tb_scan_counter/clk /tb_scan_counter/se /tb_scan_counter/en
add wave /tb_scan_counter/scan_in /tb_scan_counter/scan_out /tb_scan_counter/dut/q
run -all
```

ผลจริง (GHDL 4.1): pass ครบ 5 pattern, `test cycles = 29 (formula (P+1)L+P = 29)`, `RESULT errors=0` — และเมื่อแปลง `scan_counter_vhd` เป็น Verilog (`ghdl --synth`) แล้วรันกับ `tb_scan_counter.sv +define+VHDL_DUT` ก็ได้ผลเดียวกัน

✅ **Checkpoint 7C:** ทั้งสองสาย pass 5/5, test cycles = 29 ตรงสูตร และมีภาพ waveform ที่ชี้ช่วง shift 4 clock / capture 1 clock

## 7D — Fault Injection: Scan จับ Stuck-at ได้จริงไหม (60 นาที)

**แนวคิด:** ใช้ `force` ของ ModelSim จำลอง defect ที่สาย `d` (เอาต์พุตของลอจิก combinational) ทีละบิต แล้วรัน testbench เดิมของ 7C — ถ้าผลที่ unload ออกมาต่างจากค่าคาด แปลว่า scan test **ตรวจพบ (detected)** fault นั้น นี่คือสิ่งที่ fault simulator ในเครื่องมือ ATPG ทำ แต่ทำกับ fault นับล้านตัวพร้อมกัน

สังเกต: fault บน `d` มีผลเฉพาะตอน **capture** เพราะตอน shift mux เลือก SI — ดังนั้นการ shift เข้า/ออกยังทำงานปกติ และผลที่ผิดมาจากจังหวะ capture เท่านั้น

### ขั้นที่ 1 — ทำนายด้วยมือก่อนรัน (15 นาที)

ค่าที่ capture ได้คือ pat + 1 เขียนตารางค่าบิตก่อน:

| pattern | pat + 1 | บิต 3 | บิต 2 | บิต 1 | บิต 0 |
| --- | --- | --- | --- | --- | --- |
| 0000 | 0001 | 0 | 0 | 0 | 1 |
| 0101 | 0110 | 0 | 1 | 1 | 0 |
| 0111 | 1000 | 1 | 0 | 0 | 0 |
| 1010 | 1011 | 1 | 0 | 1 | 1 |
| 1111 | 0000 | 0 | 0 | 0 | 0 |

กฎ: `d[b]` s-a-0 ตรวจพบโดย pattern ที่ (pat+1)\[b\] = 1 (**activate**: ค่าปกติต้องตรงข้ามกับ fault) ส่วน s-a-1 ตรวจพบโดย pattern ที่บิตนั้น = 0 — การ **propagate/observe** ได้ฟรีเพราะ scan chain อ่าน FF ทุกตัวออกมาตรง ๆ กรอกคอลัมน์ "ทำนาย" ในตารางขั้นที่ 3 ให้ครบก่อน

### ขั้นที่ 2 — สคริปต์ฉีด fault (15 นาที)

`run_7d.do` — วนฉีด fault 8 ตัว (d\[0..3\] × s-a-0/s-a-1):

```tcl
vlib work
vlog -sv rtl/scan_counter.v tb/tb_scan_counter.sv
vsim -c -voptargs=+acc work.tb_scan_counter   ;# +acc กัน vopt ยุบสาย d ทิ้ง จน force ไม่ได้
set sig sim:/tb_scan_counter/dut/d
foreach b {0 1 2 3} {
  foreach v {0 1} {
    restart -f
    force -freeze "$sig\[$b\]" $v 0
    echo "===== FAULT d\[$b\] stuck-at-$v ====="
    run -all
    noforce "$sig\[$b\]"
  }
}
quit -f
```

```bash
vsim -c -do run_7d.do | tee reports/fault.log
grep -E "=====|FAIL|RESULT" reports/fault.log
```

| คำสั่ง | หน้าที่ |
| --- | --- |
| `restart -f` | เริ่ม simulation ใหม่ที่เวลา 0 โดยไม่ต้องคอมไพล์ใหม่ (ล้าง force เก่าด้วย) |
| `force -freeze <sig> v 0` | ตรึงสัญญาณที่ค่า v ตั้งแต่เวลา 0 ทับ driver เดิม = stuck-at |
| `run -all` | รันจนถึง `$stop` ใน testbench แล้วกลับมาทำบรรทัดถัดไปใน .do |
| `\[$b\]` | escape วงเล็บเหลี่ยมไม่ให้ Tcl ตีความเป็นคำสั่ง |

สาย VHDL: ชื่อสัญญาณใช้วงเล็บกลม เช่น `force -freeze sim:/tb_scan_counter/dut/d($b) $v 0` และคอมไพล์ด้วย `vcom -2008` ตาม 7C ขั้นที่ 5

### ขั้นที่ 3 — บันทึกผล (10 นาที)

ตารางให้ผู้เรียนกรอก:

| Fault | Pattern ที่ควร FAIL (ทำนาย) | ผลจาก simulation | Detected? |
| --- | --- | --- | --- |
| d\[0\] s-a-0 |  |  |  |
| d\[0\] s-a-1 |  |  |  |
| d\[1\] s-a-0 | 0101, 1010 (ตัวอย่าง) |  |  |
| d\[1\] s-a-1 | 0000, 0111, 1111 (ตัวอย่าง) |  |  |
| d\[2\] s-a-0 / s-a-1 |  |  |  |
| d\[3\] s-a-0 / s-a-1 |  |  |  |
| **Fault coverage** |  |  | \_\_ / 8 |

**เฉลยสำหรับผู้สอน** (ผลจริง — จำลองด้วย `force` ใน Icarus 12 ซึ่งให้ผลเท่ากัน ค่า got คือสิ่งที่ unload ได้):

| Fault | Pattern ที่ FAIL (expect → got) | errors | Detected |
| --- | --- | --- | --- |
| d\[0\] s-a-0 | 0000 (0001→0000), 1010 (1011→1010) | 2 | ✅ |
| d\[0\] s-a-1 | 0101 (0110→0111), 0111 (1000→1001), 1111 (0000→0001) | 3 | ✅ |
| d\[1\] s-a-0 | 0101 (0110→0100), 1010 (1011→1001) | 2 | ✅ |
| d\[1\] s-a-1 | 0000 (0001→0011), 0111 (1000→1010), 1111 (0000→0010) | 3 | ✅ |
| d\[2\] s-a-0 | 0101 (0110→0010) | 1 | ✅ |
| d\[2\] s-a-1 | 0000, 0111, 1010, 1111 | 4 | ✅ |
| d\[3\] s-a-0 | 0111 (1000→0000), 1010 (1011→0011) | 2 | ✅ |
| d\[3\] s-a-1 | 0000 (0001→1001), 0101 (0110→1110), 1111 (0000→1000) | 3 | ✅ |
| **Fault coverage** |  |  | **8 / 8 = 100%** |

ข้อสังเกต: ทุก FAIL ต่างจากค่าคาด **แค่บิตเดียว** (บิตที่ถูกฉีด) และ `d[2]` s-a-0 ถูกจับโดย pattern เดียว (0101) — ถ้าตัด 0101 ออก coverage จะเหลือ 7/8 นี่คือเหตุผลที่ ATPG ต้องคำนวณ pattern ไม่ใช่สุ่ม

### ขั้นที่ 4 — แบบฝึก (20 นาที)

**แบบฝึก 1 — ATPG ย่อส่วน:** ลดเหลือ 2 pattern ให้ได้ 8/8 (คำใบ้: ต้องมี pattern ที่ pat+1 มีทุกบิตเป็นทั้ง 0 และ 1) แก้ testbench:

```systemverilog
localparam int N = 4, NP = 2;
logic [N-1:0] pats [NP] = '{4'b1111, 4'b1110};   // pat+1 = 0000 และ 1111
```

เฉลย (ผลจริง): ไม่มี fault → `test cycles = 14 (formula ... = 14)`, `RESULT errors=0` · ฉีด fault ทั้ง 8 ตัว → `RESULT errors=1` ทุกตัว = **8/8 ด้วย 14 cycle แทน 29** (คำตอบอื่นที่ถูกต้องก็มี เช่น pat+1 = 0101 กับ 1010)

**แบบฝึก 2 — fault ที่อินพุต `en`:** เพิ่มใน .do:

```tcl
restart -f
force -freeze sim:/tb_scan_counter/dut/en 0 0
echo "===== FAULT en stuck-at-0 ====="
run -all
```

ผลจริง: FAIL ครบ 5 pattern (เช่น `expect 0001 got 0000`) `RESULT errors=5` — เพราะ en = 0 ทำให้ d = q ทุก pattern จะ capture ค่าเดิม จะต้องตอบให้ได้ว่า en s-a-1 จับได้ไหมกับ testbench นี้ (คำใบ้: testbench ตั้ง en = 1 ทุกครั้งที่ capture — ไม่มี pattern ไหนที่ capture ด้วย en = 0 จึงไม่ activate)

**แบบฝึก 3 — Chain integrity (flush) test:** ATE ทดสอบตัว chain ก่อน pattern อื่นเสมอ — ถ้า chain ขาด ผลทุก pattern หลังจากนั้นไม่มีความหมาย (แยกไม่ได้ว่าเสียที่ลอจิกหรือเสียที่ chain)

`tb/tb_chain_flush.sv`:

```systemverilog
// tb_chain_flush.sv — chain integrity (flush) test: shift อย่างเดียว ไม่มี capture
// ATE รันก่อน pattern อื่นเสมอ: ถ้า chain เสีย ผลของทุก pattern หลังจากนี้ไม่มีความหมาย
`timescale 1ns/1ps
module tb_chain_flush;
  localparam int N = 4, L = 8;
  localparam logic [L-1:0] SEQ = 8'b0011_0011;   // มีทั้ง 0→0, 0→1, 1→1, 1→0
  logic clk = 0, rst_n = 0, en = 0, se = 0, scan_in = 0;
  logic [N-1:0] cnt;
  logic scan_out;
  logic [L+N-1:0] stream, expect_s;
  int errors = 0;

  scan_counter #(.N(N)) dut (.*);
  always #5 clk = ~clk;

  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1;                                   // หลัง reset chain = 0000
    @(negedge clk);
    se = 1;                                      // shift ตลอด ไม่มี capture
    for (int i = L+N-1; i >= 0; i--) begin       // L+N clock: ป้อน SEQ แล้วตามด้วย 0
      scan_in   = (i >= N) ? SEQ[i-N] : 1'b0;
      stream[i] = scan_out;                      // อ่านก่อนขอบ clock
      @(posedge clk); #1;
    end
    expect_s = {{N{1'b0}}, SEQ};                 // ออกมาก่อน: ค่า reset N บิต แล้วจึงเป็น SEQ
    if (stream !== expect_s) begin
      errors++;
      $display("CHAIN FAIL: got %b expect %b", stream, expect_s);
    end else
      $display("chain ok: %b", stream);
    $display("RESULT errors=%0d", errors);
    $stop;
  end
endmodule
```

`run_7d_chain.do`:

```tcl
vlib work
vlog -sv rtl/scan_counter.v tb/tb_chain_flush.sv
vsim -c -voptargs=+acc work.tb_chain_flush
echo "===== chain ปกติ ====="
run -all
restart -f
force -freeze sim:/tb_chain_flush/dut/q\[2\] 1 0
echo "===== q\[2\] stuck-at-1 ====="
run -all
quit -f
```

ผลจริง:

```text
chain ok: 000000110011                                   <- chain ปกติ
CHAIN FAIL: got 011111111111 expect 000000110011         <- q[2] stuck-at-1
```

อ่านผล: บิตแรกเป็น 0 เพราะ q\[3\] ยังเป็นค่า reset หลังจากนั้นทุกบิตที่ไหลผ่าน q\[2\] กลายเป็น 1 — จากรูปแบบ "ค้าง 1 ตลอด" ATE บอกได้ว่า chain ขาดแบบ stuck-at-1 แต่บอกตำแหน่ง FF ไม่ได้จาก flush อย่างเดียว (ต้องใช้ chain diagnosis) ลำดับ `0011` เลือกเพราะมี transition ครบทุกแบบ จับได้ทั้ง stuck-at และ transition fault บน chain

✅ **Checkpoint 7D:** ตาราง 8 fault ครบพร้อมคำทำนายที่ตรงกับ simulation, coverage 8/8, ชุด 2 pattern ที่ยังได้ 8/8 และผล flush test ทั้งกรณีปกติและ chain เสีย

## 7E (ทางเลือก) — Scan Insertion อัตโนมัติด้วย OpenROAD (30 นาที)

**เป้าหมาย:** ให้เครื่องมือทำสิ่งที่เราทำด้วยมือใน 7C — แทน DFF ด้วย scan FF (`scan_replace`) แล้วเดินสาย chain (`execute_dft_plan`) บน netlist จริง

> ⚠️ ต้องใช้ OpenROAD รุ่นที่มีโมดูล `dft` (ประมาณปลาย 2023 ขึ้นไป) — ใช้ OpenROAD ใน container ORFS จาก Lab 5 ได้ ตรวจด้วย `openroad -version` และ `help set_dft_config` ถ้าได้ "no commands match" แปลว่ารุ่นเก่าเกินไป (เช่น build ปี 2022 จาก conda litex-hub ไม่มีคำสั่งเหล่านี้)

### ขั้นที่ 1 — counter 8 บิตธรรมดา (5 นาที)

`rtl/counter8.v`:

```verilog
// counter8.v — counter 8 บิตธรรมดา (ไม่มี scan) สำหรับ Lab 7E
module counter8 (
  input  wire       clk, rst_n, en,
  output reg  [7:0] cnt
);
  always @(posedge clk or negedge rst_n)
    if (!rst_n)  cnt <= 8'd0;
    else if (en) cnt <= cnt + 8'd1;
endmodule
```

```bash
TOP=counter8 RTL=rtl/counter8.v yosys -q -c syn/syn.tcl
grep -c dfrtp out/counter8_syn.v            # 8
```

ผลจริง: 24 cell, 306.544 µm² มี `sky130_fd_sc_hd__dfrtp_1` 8 ตัว (ส่วนที่เหลือเป็น xor/xnor/nand ของตัวบวก)

### ขั้นที่ 2 — สคริปต์ DFT (10 นาที)

`syn/dft.tcl` (เพิ่ม `read_lef` และ `create_clock` จากเนื้อหา Module — โมดูล dft ต้องรู้ LEF ของ cell และต้องรู้ clock domain จึงจะจัด chain ได้ ตามตัวอย่าง regression test ของ OpenROAD):

```tcl
# dft.tcl — รันด้วย: openroad -exit syn/dft.tcl
set PLAT $::env(PLATFORM_DIR)          ;# เช่น ~/OpenROAD-flow-scripts/flow/platforms/sky130hd
read_lef     $PLAT/lef/sky130_fd_sc_hd.tlef
read_lef     $PLAT/lef/sky130_fd_sc_hd_merged.lef
read_liberty $::env(LIB)
read_verilog out/counter8_syn.v
link_design  counter8
create_clock -name clk -period 10 [get_ports clk]

set_dft_config -max_length 4        ;# 8 FF → 2 chain
report_dft_config
scan_replace                        ;# DFF → scan FF (dfrtp → sdfrtp)
report_dft_plan -verbose            ;# ดูแผนก่อน (ไม่แก้ netlist)
execute_dft_plan                    ;# สร้างพอร์ต scan และต่อ chain
write_verilog out/counter8_scan.v
```

```bash
export PLATFORM_DIR=~/OpenROAD-flow-scripts/flow/platforms/sky130hd     # ใน container: /OpenROAD-flow-scripts/flow/platforms/sky130hd
openroad -exit syn/dft.tcl | tee reports/dft.log
```

| คำสั่ง | หน้าที่ | เทียบกับ 7C |
| --- | --- | --- |
| `set_dft_config -max_length 4` | กำหนดความยาว chain สูงสุด (มี `-max_chains`, `-clock_mixing` ด้วย) | L = 4 ในสูตร (P+1)L+P |
| `scan_replace` | แทน `dfrtp` ด้วย `sdfrtp` (มีขา SCD/SCE เพิ่ม) | `scan_dff.vhd` |
| `report_dft_plan -verbose` | แสดงลำดับ FF ในแต่ละ chain โดยไม่แก้ netlist | แผนภาพ chain |
| `execute_dft_plan` | สร้างพอร์ต scan\_enable/scan\_in และต่อ Q→SI | `si <= q(N-2 downto 0) & scan_in` |

### ขั้นที่ 3 — ตรวจผล (10 นาที)

```bash
grep -c sdfrtp out/counter8_scan.v                      # ควรได้ 8
grep -c dfrtp_1 out/counter8_syn.v                      # เทียบ: ก่อน insert ก็ 8
head -12 out/counter8_scan.v                             # ดูพอร์ตใหม่ เช่น scan_enable_0, scan_in_0, scan_in_1
grep -A3 "Scan chain" reports/dft.log
```

ผลที่ควรเห็น (รูปแบบจาก regression test ของ OpenROAD; ชื่อ instance จะเป็น `_xx_` จาก Yosys):

```text
Report DFT Plan
Number of chains: 2
Clock domain: No Mix
Scan chain 'chain_0' has 4 cells (4 bits)
  _xx_ (clk, rising)
  ...
Scan chain 'chain_1' has 4 cells (4 bits)
  ...
```

คำถาม 7E:

1. พื้นที่เพิ่มขึ้นเท่าไรหลัง `scan_replace` (เปรียบเทียบพื้นที่ `dfrtp_1` กับ `sdfrtp_1` ใน .lib) ตรงกับช่วง 5–15% ในหัวข้อ 7.5 ไหม สำหรับดีไซน์นี้ที่ FF เป็นส่วนใหญ่
2. เปลี่ยนเป็น `-max_chains 1` — L และจำนวน test cycle (สูตรจาก 7.5) เปลี่ยนอย่างไรถ้า P = 20
3. ทำไมใน ORFS จริงจึงเรียก `execute_dft_plan` หลัง global placement (คำใบ้: เรียง chain ตามตำแหน่งเพื่อลด wirelength และ hold violation บน chain)

> ส่วน 7E นี้เขียนตาม README และ regression test ของโมดูล dft ใน OpenROAD (ตุลาคม 2026) แต่ยังไม่ได้รันจริงตอนเตรียมคู่มือ (synthesis ของ counter8 รันแล้ว) — ผู้สอนควรลองใน container ORFS ก่อนใช้สอน

## แก้ปัญหา, คำถามท้าย Lab และเกณฑ์ให้คะแนน

### ตารางแก้ปัญหา

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| gclk มีพัลส์สั้น / gclk edges > en cycles | ใช้ AND ธรรมดาแทน ICG (7A แบบฝึก 1) | latch-based ICG หรือ cell `sdlclkp` |
| q\_ref กับ q\_icg ต่างกัน 1 cycle | delta race: testbench เปลี่ยน d ที่ posedge | เปลี่ยนอินพุตที่ negedge |
| `n_gclk` เป็น 0 ตลอด | vopt ยุบสัญญาณภายใน / อ้างชื่อ hierarchy ผิด | `vsim -voptargs=+acc`, ตรวจชื่อ `dut_g.gclk` |
| GHDL/ModelSim: "instance dut\_g is not yet elaborated" | ประกาศ external name ใน architecture ก่อน instance | ย้าย `alias ... << signal ... >>` เข้าไปใน process (ตาม `tb_regbank.vhd`) |
| Yosys: `sdlclkp_1` เป็น module ที่ไม่รู้จัก | ไม่ได้ `read_liberty -lib` หรือลืม `DEFS=-DUSE_SKY130` | ใช้ `syn/syn.tcl` ตามคู่มือ |
| `report_power` ไม่ต่างกัน | ไม่ได้ตั้ง activity, หรืออ่าน netlist ผิดตัว | ตรวจ `NETLIST`/`TOP`, `set_power_activity`; เทียบกับจำนวนขอบจาก 7A |
| `read_vcd` annotate 0 pin | `-scope` ไม่ตรง hierarchy ใน VCD | เปิด VCD ดูบรรทัด `$scope module` ใช้ `tb_regbank/dut_r` |
| GLS: `parameter W not found` | netlist ไม่มี parameter | คอมไพล์ด้วย `+define+GLS` |
| ผล unload กลับด้าน/เลื่อน 1 บิต | อ่าน scan\_out หลังขอบ clock หรือสับสนทิศ chain | อ่านก่อนขอบ, เขียนทิศ chain ในคอมเมนต์ |
| Icarus: "Assignment to an entire array ... not yet supported" | `pats = '{...}` ใน tb\_scan\_counter.sv | ใช้ ModelSim/Verilator หรือกำหนด `pats[0]=...` ทีละตัวใน `initial` |
| `force` ไม่มีผล / หาสัญญาณไม่เจอ | vopt ยุบสาย d | `vsim -voptargs=+acc` |
| Fault ที่ d ไม่เคยถูกตรวจพบ | pattern ไม่ activate (บิตนั้นไม่เคยเป็น 0 หรือ 1) | เพิ่ม pattern ตามตารางใน 7D ขั้นที่ 1 |
| OpenROAD: "no commands match set\_dft\_config" | OpenROAD รุ่นเก่าไม่มีโมดูล dft | ใช้ OpenROAD ใน container ORFS รุ่นใหม่ |

### คำถามท้าย Lab

1. จาก 7B กำลังไฟกลุ่ม Sequential ลดเกือบตาม duty ของ en — อธิบายด้วยสูตร P = αCV²f ว่า α ตัวไหนเปลี่ยน และทำไมกลุ่ม Clock ของ regbank เป็น 0
2. ในชิปจริงหลัง CTS ผลประหยัดของ ICG จะมากขึ้นหรือน้อยลงเทียบกับตัวเลขใน 7B เพราะอะไร
3. ทำไม VCD-based power (−59%) กับ vectorless (−70%) ให้ผลต่างกัน และควรเชื่อตัวไหนในกรณีไหน
4. ถ้า ICG ไม่มีขา SCE (หรือไม่ต่อ test\_en) จะเกิดอะไรตอน scan shift — อ้างผล test mode ใน 7A
5. คำนวณ test cycle ของ counter8 ใน 7E (2 chain × 4) ที่ P = 20 เทียบกับ 1 chain × 8
6. จาก 7D ทำไม fault ที่ `d` ไม่กระทบการ shift แต่ fault ที่ `q[2]` ทำให้ทุก pattern ผิด
7. en s-a-1 จับได้ด้วย testbench ใน 7C หรือไม่ ถ้าไม่ได้ ต้องแก้ testbench อย่างไร (activate + propagate)
8. fault coverage 100% บน `d` แปลว่าชิปที่ผ่าน test ไม่มี defect เลยหรือไม่ (คำใบ้: fault model vs defect, fault list ที่นับเฉพาะ 8 ตัว)

### สิ่งที่ต้องส่ง

1. Transcript ของ 7A (Verilog และ VHDL) และ 7C ที่แสดง `RESULT errors=0` พร้อม screenshot waveform: ช่วงที่ gclk ถูกปิด, latch ค้างค่า, จังหวะ shift/capture และพัลส์สั้นจากแบบฝึก AND
2. ตารางผล 7B (cell/area, power แยก 3 ส่วน, duty sweep, VCD) พร้อมคำอธิบาย 3–5 บรรทัดว่า clock gating คุ้มเมื่อไร
3. ตาราง fault 7D พร้อม coverage, ชุด pattern ที่ลดแล้ว และผล flush test
4. (ถ้าทำ 7E) ส่วนหนึ่งของ `report_dft_plan` และผล `grep -c sdfrtp`
5. คำตอบคำถามท้าย Lab

### เกณฑ์ให้คะแนน (100 คะแนน + โบนัส)

| หัวข้อ | คะแนน | ดีมาก | พอใช้ | ต้องปรับปรุง |
| --- | --- | --- | --- | --- |
| 7A Clock gating + waveform | 20 | errors = 0 ทั้งสองสาย, ชี้จุด latch/gclk ได้, ทำแบบฝึก AND และอธิบายได้ | ผ่านแต่อธิบายไม่ครบ | มี mismatch |
| 7B Power/area | 20 | ตารางครบ + วิเคราะห์ trade-off ตาม duty/ความกว้าง + VCD | มีตัวเลขแต่ไม่ตีความ | รันไม่สำเร็จ |
| 7C Scan chain + testbench | 25 | ทั้ง VHDL/Verilog ผ่าน, cycle ตรงสูตร | ภาษาเดียวผ่าน | shift/capture ผิดลำดับ |
| 7D Fault injection + coverage | 25 | ทำนายตรง sim, ลด pattern ได้ 8/8, ทำ flush test | coverage ถูกแต่ไม่ลด pattern | ตารางไม่ครบ |
| คุณภาพโค้ดและรายงาน | 10 | คอมเมนต์ชัด, ไม่มี warning, ตอบคำถามครบ | มี warning เล็กน้อย | ไม่มีสรุป |
| โบนัส 7E OpenROAD DFT | +5 | chain ถูกต้อง + อธิบาย report | รันได้ | — |

> **หมายเหตุสำหรับผู้สอน:** ตัวเลขใน Lab นี้มาจากการรันจริง — simulation ด้วย Icarus 12 / Verilator 5.020 / GHDL 4.1 (แทน ModelSim), synthesis ด้วย Yosys 0.69 และ power ด้วย OpenSTA 3.1.0 บน sky130\_fd\_sc\_hd TT 25°C — ไฟล์ .do ของ ModelSim เขียนตามรูปแบบมาตรฐานแต่ยังไม่ได้รันบน ModelSim จริง และ 7E ยังไม่ได้รัน OpenROAD จริง ควรลองก่อนสอน

# Lab 8 — Capstone Milestones (M0–M5)

Oct 28, 2026 · @Chumnarn Punyasai

## ภาพรวม

Lab 8 คือการทำโปรเจกต์ capstone ของ Module 08 ตั้งแต่ proposal จนถึง GDS และการนำเสนอ แบ่งเป็น 6 milestone (M0–M5) ผู้เรียนทำโปรเจกต์ของตนเอง (หรือ UART ตามตัวอย่างใน 8.3 ถ้าเป็นการอบรมแบบสั้น) คู่มือนี้ใช้ UART เป็นตัวอย่างเดินทุก milestone — ทุกสคริปต์และตัวเลข "ผลจริง" มาจากการรัน repo ตัวอย่างจริง

&#91;embedded content: Capstone milestones · 6 gates ใน 4 สัปดาห์\]

### กติกา 3 ข้อ

1. **ส่งงาน = push annotated git tag** (`git tag -a`) ไม่ใช่ไฟล์แนบ — ผู้สอน clone repo แล้วตรวจจาก tag ด้วยสคริปต์เดียวกันทุกคน (ส่วนสุดท้ายของคู่มือ)
2. **Gate ก่อนไปต่อ** — milestone ถัดไปเริ่มได้เมื่อผ่าน gate ของอันก่อนหน้า ถ้าไม่ผ่าน แก้แล้วส่ง tag ใหม่ต่อท้าย `-r1`, `-r2` (เช่น `m1-spec-r1`) **ห้ามย้าย tag เดิม** — ประวัติการแก้คือหลักฐานที่ผู้สอนใช้ให้คะแนน
3. **Gate ต้องตรวจซ้ำได้** — ทุก gate ที่เป็นตัวเลข (lint, test, timing) ต้องมีสคริปต์ใน repo ที่รันแบบ `-c` (ไม่พึ่ง GUI) และพิมพ์ PASS/FAIL ชัดเจน

### ตารางสรุป

| Milestone | สัปดาห์ | Git tag | สิ่งที่ต้องมีใน tag | Gate (ตรวจอย่างไร) | น้ำหนัก |
| --- | --- | --- | --- | --- | --- |
| M0 Proposal | 1 (ต้น) | `m0-proposal` | README.md | ผู้สอนอนุมัติขอบเขต | 5% |
| M1 Spec + vplan | 1 (ท้าย) | `m1-spec` | doc/spec.md, doc/vplan.md | peer review 3 คำถาม | 15% |
| M2 RTL freeze | 2 | `v0.9-rtl-freeze` | RTL, unit TB, check\_m2.sh | `./check_m2.sh` → PASS | 20% |
| M3 Verification | 3 | `m3-verif` | regression, coverage, bug log | `sim/regress.sh` หรือ `regress.do` ผ่านทุก seed + bug hunt | 25% |
| M4 Implementation | 4 (ต้น) | `m4-impl` | syn/, STA 3 corner, pnr/, layout | WNS ≥ 0 (ss setup, ff hold) หลัง route, DRC = 0 | 20% |
| M5 Final + demo | 4 (ท้าย) | `v1.0` | README, report, สไลด์ | clone ใหม่แล้วรัน Quick start ได้ | 15% |

### โครง repo ที่ทุกคนต้องใช้ (ผู้สอนตรวจจาก path เหล่านี้)

```text
capstone_uart/
├── README.md             # M0 proposal → M5 ฉบับสมบูรณ์
├── check_m2.sh           # gate M2
├── doc/   spec.md  vplan.md  buglog.md  report.md  img/
├── rtl/   vhdl/*.vhd  verilog/*.v
├── tb/    tb_uart.sv  tb_baud_margin.sv  tb_baud_gen.sv  tb_uart_tx.sv  uart_sva.sv
├── sim/   run_unit.do  run_unit.sh  regress.do  regress.sh
├── syn/   run_synth.sh  constraint.sdc  sta.tcl  (+ log/rpt ที่ M4)
├── pnr/   config.mk
└── .gitignore
```

**เครื่องมือที่ใช้ตรวจ repo ตัวอย่าง:** Verilator 5.020 (lint), GHDL 4.1, Icarus 12 (แทน ModelSim — สคริปต์ `.sh` ใน sim/ เลือก ModelSim อัตโนมัติถ้ามี `vsim`), Yosys 0.69, OpenSTA 3.1.0

## M0 — Proposal (สัปดาห์ 1 ต้น, \~3 ชั่วโมง)

**ส่ง:** README หน้าเดียว — ชื่อโปรเจกต์, คำอธิบาย 3 ประโยค, block diagram คร่าว ๆ, ตาราง MoSCoW, ความเสี่ยง 2 ข้อพร้อมแผนสำรอง · **Gate:** ผู้สอนอนุมัติขอบเขต (ตัดทอนถ้าใหญ่เกิน) · **Tag:** `m0-proposal`

### ขั้นที่ 1 — เลือกโปรเจกต์ (45 นาที)

เลือกจากเมนูใน 8.1 แล้วตอบเช็กลิสต์นี้ใน README (ต้อง "ใช่" อย่างน้อย 4 ข้อ):

- [ ] อธิบายฟังก์ชันได้ใน 3 ประโยค และระบุ interface ได้ครบ
- [ ] มี FSM อย่างน้อย 1 ตัว และ datapath ที่มี register หลายตัว
- [ ] มี reference model ที่เขียนง่าย (คำนวณคำตอบที่ถูกได้ใน testbench)
- [ ] ขนาดต่ำกว่า \~2,000 FF
- [ ] ทดสอบบน FPGA ได้ (ไม่บังคับ)
- [ ] มีจุดให้ฝึกหัวข้อขั้นสูง 1 เรื่อง (pipeline, CDC, clock gating หรือ DFT)

**ประมาณขนาดเป็น FF ก่อนเลือก** — นับจาก register ที่ต้องมี เช่น UART: baud counter 5 + tick 1 + TX (state 2 + tcnt 4 + bidx 3 + shreg 8 + tx 1) + RX (sync 2 + state 2 + tcnt 4 + bidx 3 + shreg 8 + rx\_data 8 + valid/err 2) ≈ 53 FF — ค่านี้จะถูกเทียบกับผล synthesis จริงใน M2/M4

### ขั้นที่ 2 — ตั้ง repo (30 นาที)

```bash
mkdir -p capstone_uart && cd capstone_uart
git init -b main
mkdir -p doc/img rtl/vhdl rtl/verilog tb sim syn pnr
cat > .gitignore <<'EOF'
# ไฟล์ที่เครื่องมือสร้าง — ห้าม commit (สคริปต์ผู้สอนตรวจหาไฟล์เหล่านี้ในทุก tag)
work/
*.wlf
transcript
*.vcd
*.ucdb
results/
logs/
objects/
*.vvp
sim/*.log
sim/uart_top_from_vhdl.v
sim/*_vhd.sv
EOF
git add . && git commit -m "M0: repo skeleton"

# สร้าง repo เปล่าบน GitHub/GitLab (ห้ามใส่ README ตอนสร้าง) แล้ว:
git remote add origin git@github.com:<user>/capstone_uart.git
git push -u origin main
```

ให้สิทธิ์อ่าน (Reporter/Read) แก่บัญชีผู้สอนถ้า repo เป็น private แล้วส่ง URL ในช่องทางที่ผู้สอนกำหนด **ครั้งเดียว** — หลังจากนี้ไม่ต้องส่งไฟล์อะไรอีก

### ขั้นที่ 3 — เขียน README proposal (90 นาที)

แม่แบบ (ตัวอย่าง UART — แทนด้วยโปรเจกต์ของตนเอง):

````markdown
# UART TX/RX (8N1) — Capstone Proposal

**ทีม:** <ชื่อ> · **ภาษาหลัก:** Verilog (VHDL ครบทุกโมดูลเป็น Should)

## หน้าที่ (3 ประโยค)
บล็อกรับ-ส่งข้อมูลอนุกรมแบบ 8N1 ที่ตั้ง baud ได้ด้วย parameter
ฝั่งส่งรับไบต์พร้อม tx_start และบอกสถานะด้วย tx_busy ฝั่งรับใช้ 16× oversampling
และให้ไบต์พร้อม rx_valid หรือ rx_err เมื่อ stop bit ผิด ทำงานที่ clock เดียว 50 MHz

## Block diagram
```
            +-----------+  tick (1 ใน 27 clk)
 clk ──────▶| baud_gen  |────────┬────────────────┐
            +-----------+        ▼                ▼
 tx_data/tx_start ───────▶ [ uart_tx ] ──▶ tx    [ uart_rx ] ◀── rx (async)
                          tx_busy ◀─┘             └──▶ rx_data/rx_valid/rx_err
```

## ขอบเขต (MoSCoW)
| ระดับ | ฟีเจอร์ |
|---|---|
| Must   | 8N1, baud จาก parameter, TX + RX, self-checking TB, synthesis + STA ผ่าน |
| Should | 16× oversampling, framing error, ORFS จนได้ GDS, VHDL ครบ |
| Could  | parity, FIFO 8 ช่อง, register interface, FPGA demo |
| Won't  | RTS/CTS, auto-baud, DMA |

## ประมาณขนาด
~53 FF (นับจาก register ใน RTL) — เป้าพื้นที่ < 5,000 µm² บน Sky130 HD

## ความเสี่ยงและแผนสำรอง
| ความเสี่ยง | สัญญาณเตือน | แผนสำรอง |
|---|---|---|
| ORFS ติดตั้ง/รันไม่ได้บนเครื่อง | Lab 5 ยังรัน gcd ไม่ผ่าน | ใช้ docker image ของ ORFS / เครื่องในห้อง lab |
| เวลาไม่พอทำ VHDL ครบ | สัปดาห์ 2 ยังไม่เสร็จ Verilog | ทำ VHDL เฉพาะ uart_rx (ตามเกณฑ์ขั้นต่ำ M2) |
````

| ส่วน | ผู้สอนดูอะไร |
| --- | --- |
| 3 ประโยค | บอก *อะไรเข้า-อะไรออก* ได้ครบ ไม่ใช่บอกแค่ชื่อโปรเจกต์ |
| MoSCoW | Must ต้องเล็กพอเสร็จใน 2 สัปดาห์แรก — ถ้า Must มี CPU + cache ผู้สอนจะตัด |
| ความเสี่ยง | มี *สัญญาณเตือน* ที่วัดได้ ไม่ใช่ "อาจจะไม่ทัน" |

### ขั้นที่ 4 — ส่งด้วย tag (5 นาที)

```bash
git add README.md
git commit -m "M0: proposal — UART 8N1, scope MoSCoW, risks"
git tag -a m0-proposal -m "M0 proposal"        # -a = annotated: มีผู้สร้าง เวลา และข้อความ
git push origin main
git push origin m0-proposal                     # push ธรรมดาไม่ส่ง tag ไปด้วย!
git ls-remote --tags origin                     # ยืนยันว่า tag อยู่บน server แล้ว
```

> ตั้ง `git config --global push.followTags true` ครั้งเดียว แล้ว `git push` จะส่ง annotated tag ที่ชี้ commit ที่ push ไปด้วยอัตโนมัติ

**ถ้าผู้สอนสั่งแก้:** แก้ README → commit → `git tag -a m0-proposal-r1 -m "M0 rev1: ตัด FIFO ออกจาก Should"` → push tag ใหม่ (ห้าม `git tag -f` หรือลบ tag เดิม)

✅ **Gate M0:** tag `m0-proposal` (หรือ `-rN` ล่าสุด) อยู่บน server, README มีครบ 5 ส่วน และผู้สอนตอบ "อนุมัติ" ใน issue/ช่องทางที่กำหนด

## M1 — Spec + Verification Plan (สัปดาห์ 1 ท้าย, \~6 ชั่วโมง)

**ส่ง:** `doc/spec.md` ตามแม่แบบ 8.2, `doc/vplan.md` ตามรูปแบบ 8.4, timing diagram อย่างน้อย 1 ภาพต่อ interface · **Gate:** peer review — เพื่อนอีกกลุ่มตอบ 3 คำถามได้จาก spec อย่างเดียว · **Tag:** `m1-spec`

### ขั้นที่ 1 — เขียน spec ทีละหัวข้อ (3 ชั่วโมง)

ใช้แม่แบบ 9 หัวข้อจาก 8.2 — สิ่งที่ต้องมีในแต่ละหัวข้อและตัวอย่าง UART:

| หัวข้อ | ต้องมี | ตัวอย่าง UART |
| --- | --- | --- |
| 3. Parameters | ค่า default + **ช่วงที่รองรับ** + สิ่งที่เกิดถ้าออกนอกช่วง | OS เป็นเลขคู่ ≥ 4 (RX ใช้ OS/2 หากึ่งกลางบิต), DIV = round(f\_clk/(BAUD·OS)) ≥ 2 |
| 4. Interface | ทุกพอร์ต: ทิศ, กว้าง, ความหมาย, **พัลส์หรือ level**, clock domain, **ค่าหลัง reset** | tx\_start = พัลส์ 1 clk; rx\_valid = พัลส์ 1 clk; tx = 1 หลัง reset; rx = async |
| 5. Functional | ลำดับเหตุการณ์เป็นข้อ ๆ + FSM + timing diagram | IDLE→START→DATA×8→STOP; RX sample ที่ tick ที่ 8 ของ start แล้วทุก 16 tick |
| 6. Clock & Reset | ความถี่, ชนิด reset, ทุกจุด CDC | 50 MHz, async assert / sync deassert, rx → 2-FF sync |
| 7. Error handling | ทุกกรณีผิดกติกา + พฤติกรรมที่คาด | tx\_start ขณะ busy → เมิน; glitch < ½ บิต → ไม่มีเอาต์พุต; stop = 0 → rx\_err 1 clk |
| 8. PPA targets | ตัวเลขที่ตรวจได้ (ไม่ใช่ "เร็วที่สุด") | ≥ 50 MHz (ss), < 5,000 µm², 0 latch |
| 9. Open issues | คำถามที่ยังตัดสินใจไม่ได้ + ใครตัดสิน | หลัง framing error สาย rx ที่ยังเป็น 0 (break) จะทำให้เกิด start ปลอม — ยอมรับใน v1.0? |

**การคำนวณที่ต้องอยู่ใน spec** (ผู้สอนจะตรวจว่ามีตัวเลขสนับสนุนการตัดสินใจ): baud error = baud จริง / baud เป้า − 1 โดย baud จริง = f\_clk / (DIV × OS)

| f\_clk | BAUD | OS | f/(BAUD·OS) | DIV | baud จริง | error | สรุป |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 50 MHz | 115,200 | 16 | 27.13 | 27 | 115,741 | +0.47% | ผ่าน |
| 50 MHz | 921,600 | 16 | 3.39 | 3 | 1,041,667 | +13.0% | **ใช้ไม่ได้** |
| 50 MHz | 921,600 | 8 | 6.78 | 7 | 892,857 | −3.1% | เกือบชนงบ \~±4% รวมสองฝั่ง |
| 58.9824 MHz | 921,600 | 16 | 4.00 | 4 | 921,600 | 0% | เปลี่ยน f\_clk เป็นผลคูณของ 1.8432 MHz |

(คำตอบแบบฝึก 921,600 baud ใน 8.2 — คำนวณด้วย Python แล้ว ผู้เรียนควรใส่สคริปต์คำนวณไว้ใน repo เช่น `doc/baud_calc.py`)

### ขั้นที่ 2 — Timing diagram (45 นาที)

ใช้ WaveDrom (wavedrom.com/editor.html) แล้ว export SVG เก็บใน `doc/img/` — เก็บไฟล์ JSON ต้นฉบับไว้ด้วยเพื่อแก้ได้ภายหลัง ตัวอย่าง interface TX:

```json
{ "signal": [
  { "name": "clk",      "wave": "p.........|..." },
  { "name": "tx_start", "wave": "0.10......|...", "node": "..a" },
  { "name": "tx_data",  "wave": "x.3x......|...", "data": ["0xA5"] },
  { "name": "tx_busy",  "wave": "0..1......|..0" },
  { "name": "tx",       "wave": "1..0...3..|1..", "data": ["d0..d7"] }
 ],
 "head": { "text": "uart_tx: พัลส์ tx_start 1 clk → tx_busy ขึ้นทันที → start bit" } }
```

ต้องมีอย่างน้อย: เฟรม TX 1 เฟรม, เฟรม RX พร้อมจุด sample และ rx\_valid, กรณี framing error

### ขั้นที่ 3 — Verification plan (1.5 ชั่วโมง)

`doc/vplan.md` — ทุกข้อใน spec ต้องมี ≥ 1 แถว เพิ่มคอลัมน์ **Spec ref**, **Test** และ **Status** จากตาราง 8.4 เพื่อใช้ต่อใน M3:

```markdown
| ID  | Spec ref | กรณี                          | วิธีตรวจ            | เกณฑ์ผ่าน                   | Test               | Status  |
|-----|----------|--------------------------------|-----------------------|------------------------------|--------------------|---------|
| V1  | 5.1      | ไบต์พิเศษ 00 FF 55 AA 01 80 | directed + scoreboard | ตรงทุกไบต์                 | tb_uart (loopback) | planned |
| V2  | 5.1      | สุ่ม 200 ไบต์ × 5 seed       | random + scoreboard   | 0 mismatch ทุก seed          | tb_uart +seed=N    | planned |
| V4  | 7.1      | tx_start ขณะ busy             | directed              | ถูกเมิน                     | tb_uart, tb_uart_tx| planned |
| V7b | 3, 5.3   | คาบบิตฝั่งส่ง ±5%           | sweep                 | รับถูกทุกจุดใน 95–105%     | tb_baud_margin     | planned |
| ... |          |                                |                       |                              |                    |         |
```

Status ใช้ได้ 4 ค่า: `planned` → `pass` / `fail` / `waived (เหตุผล)` — ที่ M3 ต้องไม่เหลือ `planned`

### ขั้นที่ 4 — Peer review (45 นาที, ทำในชั้น)

1. ผู้เขียน push spec แล้วเปิด issue ชื่อ `Spec review: <กลุ่มผู้ตรวจ>` (หรือใช้แบบฟอร์มกระดาษถ้าไม่ใช้ GitHub)
2. ผู้ตรวจอ่าน **เฉพาะ spec** (ห้ามถามผู้เขียน) แล้วตอบใน issue:
   - สัญญาณไหนเป็นพัลส์ สัญญาณไหนเป็น level?
   - หลัง reset เอาต์พุตทุกตัวเป็นอะไร?
   - ถ้าอินพุตผิดกติกา (เช่น tx\_start ขณะ busy, stop bit = 0) จะเกิดอะไร?
3. คำตอบที่ผิดหรือ "ไม่ระบุไว้" = จุดกำกวม → ผู้เขียนแก้ spec แล้วบันทึกใน Revision history
4. ผู้ตรวจปิด issue เมื่อตอบได้ครบทั้ง 3 ข้อ

```bash
git add doc/ && git commit -m "M1: spec v1.0 + vplan (after peer review #1)"
git tag -a m1-spec -m "M1 spec + vplan, reviewed by team B"
git push origin main m1-spec
```

✅ **Gate M1:** issue peer review ปิดแล้ว, spec มีครบ 9 หัวข้อ + Revision history, ทุกพอร์ตมีค่าหลัง reset, timing diagram ≥ 1 ต่อ interface และทุกข้อใน spec มีแถวใน vplan — หลังจากนี้จึงเริ่มเขียน RTL ได้

## M2 — RTL Freeze (สัปดาห์ 2, \~10 ชั่วโมง)

**ส่ง:** RTL ทุกโมดูล (ภาษาหนึ่งครบ อีกภาษาอย่างน้อย 1 โมดูล), unit testbench, `check_m2.sh` · **Gate:** `./check_m2.sh` พิมพ์ `M2 gate: PASS` · **Tag:** `v0.9-rtl-freeze`

### ขั้นที่ 1 — RTL ตาม spec (5 ชั่วโมง)

ทำทีละโมดูลบน branch ของตัวเอง และ merge เมื่อ unit test ของโมดูลนั้นผ่าน:

```bash
git switch -c feat/baud-gen
# เขียน rtl/verilog/baud_gen.v + tb/tb_baud_gen.sv → รัน unit test ผ่าน
git add rtl tb && git commit -m "baud_gen: tick every DIV clk + unit test"
git switch main && git merge --no-ff feat/baud-gen
```

UART ตัวอย่างใช้โค้ดจาก 8.3 — แต่ **โค้ดใน 8.3 ไม่ผ่าน gate M2 ตามที่เขียน** เพราะ lint ไม่สะอาด (ขั้นที่ 3) ซึ่งเป็นตัวอย่างจริงของงานใน milestone นี้

### ขั้นที่ 2 — Unit testbench ต่อโมดูล (3 ชั่วโมง)

กติกาเดียวกับ top-level: self-checking และจบด้วยบรรทัด `RESULT errors=N` (สคริปต์ gate อ่านบรรทัดนี้) ตัวอย่าง 2 ตัว — `uart_rx` ให้ผู้เรียนเขียนเองตามแบบ `drive_frame` ใน 8.4

`tb/tb_baud_gen.sv`:

```systemverilog
// tb_baud_gen.sv — unit test: tick กว้าง 1 clk และมาทุก DIV clk พอดี
`timescale 1ns/1ps
module tb_baud_gen;
  localparam int CLK_FREQ = 50_000_000, BAUD = 115_200, OS = 16;
  localparam int DIV = (CLK_FREQ + (BAUD*OS)/2) / (BAUD*OS);     // 27
  logic clk = 0, rst_n = 0, tick;
  int errors = 0, n_tick = 0, last = -1, cyc = 0;

  baud_gen #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD), .OS(OS)) dut (.*);
  always #10 clk = ~clk;

  always @(posedge clk) if (rst_n) begin
    cyc++;
    if (tick) begin
      if (last >= 0 && cyc - last != DIV) begin
        errors++; $error("tick interval %0d (expect %0d)", cyc - last, DIV);
      end
      last = cyc; n_tick++;
    end
  end

  initial begin
    repeat (3) @(negedge clk); rst_n = 1;
    repeat (DIV * 50) @(negedge clk);
    if (n_tick < 49) begin errors++; $error("only %0d ticks", n_tick); end
    $display("tb_baud_gen: DIV=%0d ticks=%0d", DIV, n_tick);
    $display("RESULT errors=%0d", errors);
    $stop;
  end
endmodule
```

`tb/tb_uart_tx.sv` — สร้าง tick เอง (ไม่พึ่ง baud\_gen) และอ่านเฟรมจากสาย tx ที่กึ่งกลางบิต:

```systemverilog
// tb_uart_tx.sv — unit test ของ uart_tx: รูปเฟรม 8N1, LSB ก่อน, tx_busy, ไม่รับ tx_start ขณะ busy
`timescale 1ns/1ps
module tb_uart_tx;
  localparam int OS = 16, DIV = 27, TBIT = DIV * OS;
  logic clk = 0, rst_n = 0, tick = 0, tx_start = 0;
  logic [7:0] tx_data = '0;
  logic tx, tx_busy;
  int errors = 0, cnt = 0, n_frames = 0;

  uart_tx #(.OS(OS)) dut (.*);
  always #10 clk = ~clk;
  always @(posedge tx_busy) n_frames++;                  // นับเฟรมจากขอบขึ้นของ tx_busy
  always @(posedge clk) begin                            // tick จำลอง: 1 ใน DIV clk
    cnt  <= (cnt == DIV-1) ? 0 : cnt + 1;
    tick <= (cnt == DIV-1);
  end

  // รับเฟรมจากสาย tx: รอขอบลงของ start แล้ว sample กลางบิต
  task automatic capture_frame(output logic [7:0] b, output logic stop);
    @(negedge tx);
    repeat (TBIT/2) @(posedge clk);
    if (tx !== 1'b0) begin errors++; $error("start bit not 0 at mid-bit"); end
    for (int i = 0; i < 8; i++) begin repeat (TBIT) @(posedge clk); b[i] = tx; end
    repeat (TBIT) @(posedge clk); stop = tx;
  endtask

  task automatic send(input logic [7:0] b);
    @(negedge clk); while (tx_busy) @(negedge clk);
    tx_data = b; tx_start = 1; @(negedge clk); tx_start = 0;
  endtask

  initial begin
    logic [7:0] got; logic stop;
    logic [7:0] vec [4];
    vec[0] = 8'h00; vec[1] = 8'hFF; vec[2] = 8'hA5; vec[3] = 8'h01;
    repeat (3) @(negedge clk); rst_n = 1;
    repeat (5) @(negedge clk);
    if (tx !== 1'b1 || tx_busy !== 1'b0) begin errors++; $error("not idle after reset"); end
    foreach (vec[k]) begin
      fork
        send(vec[k]);
        capture_frame(got, stop);
      join
      if (got !== vec[k] || stop !== 1'b1) begin
        errors++; $error("sent %h got %h stop=%b", vec[k], got, stop);
      end else $display("pass: frame %h", got);
    end
    // tx_start ขณะ busy ต้องถูกเมิน: ยิง 0xEE กลางเฟรม 0x3C แล้วตรวจว่าเฟรมที่ออกยังเป็น 0x3C และมีเฟรมเดียว
    begin
      int n0;
      n0 = n_frames;
      fork
        begin
          send(8'h3C);
          repeat (TBIT * 3) @(posedge clk);
          @(negedge clk); tx_data = 8'hEE; tx_start = 1; @(negedge clk); tx_start = 0;
        end
        capture_frame(got, stop);
      join
      repeat (TBIT * 12) @(posedge clk);
      if (got !== 8'h3C || stop !== 1'b1 || n_frames - n0 != 1) begin
        errors++; $error("busy test: got %h stop=%b frames=%0d", got, stop, n_frames - n0);
      end else $display("pass: tx_start while busy ignored");
    end
    $display("RESULT errors=%0d", errors);
    $stop;
  end
endmodule
```

> ทำไมตรวจทั้ง "ไบต์ที่ออก" และ "จำนวนเฟรม": รุ่นแรกของ test นี้นับแค่เฟรม พอลองแก้ RTL ให้ *รับ* tx\_start ขณะ busy (mutation) test กลับยังผ่าน เพราะ tx\_busy ไม่มีขอบขึ้นใหม่ — รุ่นนี้จับได้ (`busy test: got 70 stop=1 frames=1`) เป็นตัวอย่างว่า test ก็ต้องทดสอบด้วย bug ที่ใส่เอง

`sim/run_unit.do` (ModelSim) และ `sim/run_unit.sh` (เลือก ModelSim ถ้ามี ไม่มีใช้ Icarus):

```tcl
# run_unit.do — unit test ทุกโมดูล (รันจาก sim/: vsim -c -do run_unit.do)
vlib work
vlog -sv ../rtl/verilog/baud_gen.v ../rtl/verilog/uart_tx.v ../rtl/verilog/uart_rx.v ../rtl/verilog/uart_top.v
vlog -sv ../tb/tb_baud_gen.sv ../tb/tb_uart_tx.sv
foreach tb {tb_baud_gen tb_uart_tx} {
  vsim -c work.$tb
  run -all
  quit -sim
}
quit -f
```

```bash
#!/usr/bin/env bash
# run_unit.sh — รัน unit test: ใช้ ModelSim ถ้ามี ไม่มีก็ใช้ Icarus (ผลลัพธ์รูปแบบเดียวกัน)
cd "$(dirname "$0")"
if command -v vsim >/dev/null 2>&1; then
  vsim -c -do run_unit.do
else
  for tb in tb_baud_gen tb_uart_tx; do
    iverilog -g2012 -s $tb -o $tb.vvp ../tb/$tb.sv ../rtl/verilog/*.v && vvp -n $tb.vvp
  done
fi
```

ผลจริง: `tb_baud_gen: DIV=27 ticks=49` / `RESULT errors=0` และ `pass: frame 00, ff, a5, 01` / `pass: tx_start while busy ignored` / `RESULT errors=0`

### ขั้นที่ 3 — ทำ lint ให้สะอาด (1 ชั่วโมง)

รัน lint กับโค้ด 8.3 ตามที่เขียน (Verilator 5.020):

```text
%Warning-WIDTHEXPAND: rtl/verilog/uart_tx.v:26:20: Operator EQ expects 32 bits on the LHS,
                      but LHS's VARREF 'tcnt' generates 4 bits.
  ... (uart_tx 3 จุด, uart_rx 3 จุด, baud_gen 1 จุด — cnt 5 บิต)
%Error: Exiting due to 7 warning(s)
```

สาเหตุ: `tcnt == OS-1` เทียบ register 4 บิตกับ integer 32 บิต — ทำงานถูกแต่จงใจไม่ชัด แก้ด้วยค่าคงที่กว้างเท่า register (การเขียน `localparam [3:0] X = OS-1` ตรง ๆ ยังโดน WIDTHTRUNC ต้องตัดบิตจาก integer ก่อน):

```verilog
// uart_tx.v / uart_rx.v — เพิ่มหลังบรรทัด reg [$clog2(OS)-1:0] tcnt;
  localparam integer TW = $clog2(OS);
  localparam integer T_LAST_I = OS - 1;
  localparam [TW-1:0] T_LAST = T_LAST_I[TW-1:0];    // ค่าคงที่กว้างเท่า tcnt (lint: WIDTH)
  localparam integer T_HALF_I = OS/2 - 1;           // เฉพาะ uart_rx
  localparam [TW-1:0] T_HALF = T_HALF_I[TW-1:0];    // เฉพาะ uart_rx
// แล้วแทนทุก tcnt == OS-1 → tcnt == T_LAST,  tcnt == OS/2-1 → tcnt == T_HALF

// baud_gen.v — เพิ่มหลัง localparam W
  localparam integer LAST_I   = DIV - 1;
  localparam [W-1:0] CNT_LAST = LAST_I[W-1:0];      // ค่าคงที่กว้าง W บิตพอดี (lint: WIDTH)
// และ cnt == DIV-1 → cnt == CNT_LAST
```

หลังแก้: `verilator --lint-only -Wall` ไม่มี warning, regression เดิมยังผ่าน — บันทึกการแก้นี้เป็นแถวแรกของ bug log (พบด้วย: lint) ถ้าเลือก *ไม่แก้* warning ใด ต้องใส่ `/* verilator lint_off <RULE> */` เฉพาะบรรทัดนั้นพร้อมคอมเมนต์เหตุผล ห้ามปิดทั้งไฟล์

### ขั้นที่ 4 — สคริปต์ gate (30 นาที)

สคริปต์ใน Lab 8 ของ Module มีจุดต้องแก้ 2 จุด: `ghdl -s rtl/vhdl/*.vhd` เรียงไฟล์ตามตัวอักษร (uart\_top ก่อน uart\_tx) จึงฟ้อง `unit "uart_tx" not found` — ต้องระบุลำดับเอง และ `grep -q "RESULT errors=0"` ผ่านแม้ unit test ตัวอื่น fail — ต้องนับทุกบรรทัด `check_m2.sh` ฉบับแก้:

```bash
#!/usr/bin/env bash
# check_m2.sh — ตรวจ gate M2 (RTL freeze) — รันจากรากของ repo: ./check_m2.sh
set -e
: "${LIB:?ตั้งตัวแปร LIB (sky130_fd_sc_hd tt .lib) ก่อน}"
echo "== 1/4 lint Verilog";  verilator --lint-only -Wall rtl/verilog/*.v --top-module uart_top
echo "== 2/4 check VHDL";    ghdl -s --std=08 rtl/vhdl/baud_gen.vhd rtl/vhdl/uart_tx.vhd \
                                              rtl/vhdl/uart_rx.vhd rtl/vhdl/uart_top.vhd
echo "== 3/4 unit tests";    sim/run_unit.sh | tee sim/unit.log
n=$(grep -c "RESULT errors=" sim/unit.log); p=$(grep -c "RESULT errors=0" sim/unit.log)
[ "$n" -ge 2 ] && [ "$n" -eq "$p" ] || { echo "M2 gate: FAIL (unit $p/$n)"; exit 1; }
echo "== 4/4 synthesis: latch?"; (cd syn && ./run_synth.sh > /dev/null)
if grep -qE "dlxtp|dlxbp|dlxtn|\\\$dlatch" syn/stat_v.txt syn/stat_vhd.txt; then
  echo "M2 gate: FAIL (latch found)"; exit 1; fi
echo "M2 gate: PASS (lint clean, unit $p/$n, no latch)"
```

`syn/run_synth.sh` — ใช้ต่อใน M4 (flow เดียวกับ Lab 6: `read_liberty -lib` + dont\_use; สาย VHDL แปลงด้วย `ghdl --synth` จึงไม่ต้องมี ghdl-yosys-plugin):

```bash
#!/usr/bin/env bash
# run_synth.sh — synthesis ทั้งสองภาษา (รันจากโฟลเดอร์ syn/)
# ใช้งาน: LIB=<path>/sky130_fd_sc_hd__tt_025C_1v80.lib ./run_synth.sh
set -e
: "${LIB:?ตั้งตัวแปร LIB ให้ชี้ไปที่ .lib ของ sky130_fd_sc_hd tt ก่อน}"
V=../rtl/verilog; H=../rtl/vhdl
FLOW="synth -top uart_top -flatten;
  dfflibmap -liberty $LIB -dont_use *lpflow* -dont_use *probe*;
  abc -liberty $LIB -dont_use *lpflow* -dont_use *probe*;
  setundef -zero; opt_clean -purge;
  check -assert; tee -o STAT stat -liberty $LIB"

# สาย Verilog
yosys -q -l synth.log -p "read_liberty -lib $LIB;
  read_verilog $V/baud_gen.v $V/uart_tx.v $V/uart_rx.v $V/uart_top.v;
  ${FLOW//STAT/stat_v.txt}; write_verilog -noattr uart_top_syn.v"

# สาย VHDL: แปลงเป็น Verilog ด้วย GHDL ก่อน (ใช้แทน ghdl-yosys-plugin ได้)
ghdl --synth --std=08 --out=verilog $H/baud_gen.vhd $H/uart_tx.vhd $H/uart_rx.vhd $H/uart_top.vhd \
     -e uart_top > uart_top_from_vhdl.v
yosys -q -l synth_vhd.log -p "read_liberty -lib $LIB; read_verilog uart_top_from_vhdl.v;
  ${FLOW//STAT/stat_vhd.txt}; write_verilog -noattr uart_top_vhd_syn.v"

grep -h -E "cells$|dfrtp|dfstp|dlxtp|Chip area" stat_v.txt stat_vhd.txt
```

```bash
chmod +x check_m2.sh sim/run_unit.sh syn/run_synth.sh
export LIB=...                         # .lib tt ตาม Lab 6
./check_m2.sh
```

ผลจริง: กับโค้ด 8.3 เดิม → หยุดที่ขั้น 1/4 (exit 1) · หลังแก้ lint → `M2 gate: PASS (lint clean, unit 2/2, no latch)`

### ขั้นที่ 5 — Freeze (15 นาที)

```bash
git add -A && git commit -m "M2: RTL freeze — lint clean, unit tests pass"
git tag -a v0.9-rtl-freeze -m "M2 RTL freeze"
git push origin main v0.9-rtl-freeze
```

**กติกาหลัง freeze:** แก้ `rtl/` ได้เฉพาะการแก้บั๊ก — ทุก commit ที่แตะ rtl/ ต้องขึ้นต้นด้วย `fix(#N):` ที่ตรงกับแถวใน bug log ผู้สอนตรวจได้ด้วย:

```bash
git log --oneline v0.9-rtl-freeze..v1.0 -- rtl/      # ทุกบรรทัดต้องเป็น fix(#N): ...
```

✅ **Gate M2:** `./check_m2.sh` → PASS จาก clone ใหม่ที่ tag `v0.9-rtl-freeze` (ผู้สอนรันเองด้วย `grade_tags.sh --run`)

## M3 — Verification Sign-off (สัปดาห์ 3, \~10 ชั่วโมง)

**ส่ง:** top-level TB, `regress.do` (+ `regress.sh`), รายงาน coverage, vplan ที่ทุกแถวมีสถานะ, `doc/buglog.md` · **Gate:** ตาราง sign-off ด้านล่าง + ผ่าน bug hunt · **Tag:** `m3-verif`

| เกณฑ์ sign-off | ค่า |
| --- | --- |
| Regression | ผ่านทุก seed (≥ 5 seed) ทั้งสองภาษาที่ทำ |
| vplan | 100% มีสถานะ pass หรือ waived พร้อมเหตุผล |
| Code coverage | statement ≥ 95%, branch ≥ 90% (ถ้า license ใช้ได้) |
| Bug log | ทุกบั๊กมีสาเหตุ + commit ที่แก้ |
| Bug hunt | จับบั๊กที่ผู้สอนใส่ได้ หรือเพิ่ม test จนจับได้ หรืออธิบายได้ว่าทำไม simulation จับไม่ได้ |

### ขั้นที่ 1 — Top-level testbench (2 ชั่วโมง)

ใช้ `tb/tb_uart.sv` จาก 8.4 โดยแก้ 2 จุดเพื่อให้รันได้ทั้ง ModelSim และ Icarus และคุม seed จาก command line ได้:

```systemverilog
// (1) แทนบรรทัด byte_list — Icarus 12 ไม่รองรับการกำหนดค่าทั้ง array ด้วย '{...}
  logic [7:0] byte_list [6];
  initial begin byte_list[0]=8'h00; byte_list[1]=8'hFF; byte_list[2]=8'h55; byte_list[3]=8'hAA; byte_list[4]=8'h01; byte_list[5]=8'h80; end   // V1

// (2) ต้น initial หลัก ต่อจาก int v0, e0;
    int unsigned seed;
    if ($value$plusargs("seed=%d", seed)) begin            // เปลี่ยน seed ได้ทุก simulator: +seed=42
      $display("seed=%0d", seed);
      void'($urandom(seed));                              // seed RNG ของ process นี้ (seed ถูกแก้ค่า จึงพิมพ์ก่อน)
    end
```

ผลจริง (Icarus, seed ใดก็ได้):

```text
pass: V1-V4 loopback: all bytes received, none extra
pass: V5 glitch rejected
pass: V7 baud +3%
pass: V7 baud -3%
pass: V6 framing error flagged
bytes sent=206 received=206 rx_err=1
RESULT errors=0
```

สาย VHDL ให้ผลเดียวกัน (ทดสอบโดยแปลง VHDL เป็น Verilog ด้วย `ghdl --synth` แล้วรัน testbench เดิม)

### ขั้นที่ 2 — Regression หลาย seed (1 ชั่วโมง)

`sim/regress.do` (ModelSim, รวม coverage):

```tcl
# regress.do — regression 5 seed + baud margin + code coverage (รันจาก sim/: vsim -c -do regress.do)
set seeds {1 7 42 123 2026}
vlib work
vlog -sv +cover=bcesf ../rtl/verilog/baud_gen.v ../rtl/verilog/uart_tx.v \
                      ../rtl/verilog/uart_rx.v  ../rtl/verilog/uart_top.v
vlog -sv ../tb/tb_uart.sv ../tb/tb_baud_margin.sv
# สาย VHDL: vcom -2008 +cover=bcesf ../rtl/vhdl/baud_gen.vhd ../rtl/vhdl/uart_tx.vhd ../rtl/vhdl/uart_rx.vhd ../rtl/vhdl/uart_top.vhd

foreach s $seeds {
  vsim -c -coverage -sv_seed $s work.tb_uart +seed=$s
  run -all
  coverage save cov_$s.ucdb
  quit -sim
}
vsim -c work.tb_baud_margin
run -all
quit -sim
eval vcover merge cov_all.ucdb [glob cov_*.ucdb]
vcover report -details -output cov_report.txt cov_all.ucdb
quit -f
```

`sim/regress.sh` (Icarus — ใช้เมื่อไม่มี ModelSim หรือใน CI; ไม่มี coverage):

```bash
#!/usr/bin/env bash
# regress.sh — regression หลาย seed ด้วย Icarus (ทางเลือกของ regress.do เมื่อไม่มี ModelSim)
# ใช้งาน: cd sim && ./regress.sh [verilog|vhdl]
set -e
cd "$(dirname "$0")"
LANG_SEL=${1:-verilog}
SEEDS="1 7 42 123 2026"
if [ "$LANG_SEL" = vhdl ]; then
  H=../rtl/vhdl
  ghdl --synth --std=08 --out=verilog $H/baud_gen.vhd $H/uart_tx.vhd $H/uart_rx.vhd $H/uart_top.vhd \
       -e uart_top > uart_top_from_vhdl.v
  sed 's/uart_top #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD), .OS(OS)) dut/uart_top dut/' ../tb/tb_uart.sv > tb_uart_vhd.sv
  SRC="tb_uart_vhd.sv uart_top_from_vhdl.v"        # netlist จาก GHDL ไม่มี parameter (ฝังค่า default)
else
  SRC="../tb/tb_uart.sv ../rtl/verilog/baud_gen.v ../rtl/verilog/uart_tx.v ../rtl/verilog/uart_rx.v ../rtl/verilog/uart_top.v"
fi
iverilog -g2012 -s tb_uart -o tb_uart.vvp $SRC
: > regress.log
for s in $SEEDS; do vvp -n tb_uart.vvp +seed=$s | tee -a regress.log | grep -E "seed=|RESULT"; done
# V7b: ช่วงความคลาดของ baud (ไม่ขึ้นกับ seed — รันครั้งเดียว)
MSRC=$(echo "$SRC" | sed 's#[^ ]*tb_uart[^ ]*\.sv#../tb/tb_baud_margin.sv#')
[ "$LANG_SEL" = vhdl ] && sed 's/uart_top #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD), .OS(OS)) dut/uart_top dut/' \
                              ../tb/tb_baud_margin.sv > tb_baud_margin_vhd.sv && MSRC="tb_baud_margin_vhd.sv uart_top_from_vhdl.v"
iverilog -g2012 -s tb_baud_margin -o tb_baud_margin.vvp $MSRC
vvp -n tb_baud_margin.vvp | tee -a regress.log | grep -E "RESULT"
n=$(grep -c "RESULT errors=" regress.log); p=$(grep -c "RESULT errors=0" regress.log)
echo "regression ($LANG_SEL): $p/$n tests passed (5 seeds + baud margin)"
[ "$n" -eq 6 ] && [ "$p" -eq 6 ]
```

ผลจริง: `regression (verilog): 6/6 tests passed (5 seeds + baud margin)` และ `regression (vhdl): 6/6 ...` — รอบละประมาณ 13 วินาที

**Coverage:** ใช้ได้เฉพาะ ModelSim/Questa ที่ license เปิด code coverage — เปิด `cov_report.txt` หาบรรทัดที่ hit = 0 ทุกบรรทัดต้องมีคำอธิบายใน vplan (เช่น ค่า default ของ case ที่ไม่มีทางเกิด) ถ้าไม่มี license ให้ waive แถว V9 พร้อมเหตุผล

### ขั้นที่ 3 — Bug log (ตลอดสัปดาห์)

`doc/buglog.md` — บันทึกทันทีที่เจอ ไม่ใช่เขียนย้อนหลังตอนส่ง commit ที่แก้อ้าง `fix(#N)` ตามกติกา M2:

```markdown
| # | อาการ | สาเหตุราก | พบด้วย | แก้ไข (commit) |
|---|-------|------------|--------|-----------------|
| 1 | lint WIDTHEXPAND 7 จุด | เทียบ reg 4 บิตกับ integer | verilator -Wall | 1a2b3c4 — localparam กว้างเท่า reg |
| 2 | ไบต์ 0x01 → 0x80 | shift ซ้ายแทนขวา (LSB มาก่อน) | scoreboard V1 | ... |
```

กำหนดขั้นต่ำที่ v1.0: 3 รายการ (นับบั๊กจาก bug hunt ด้วยได้)

### ขั้นที่ 4 — Bug hunt (กิจกรรมบังคับ, 2 ชั่วโมง)

ผู้สอน (หรือเพื่อน) ใส่บั๊ก 1 ตัวบน branch แยก แล้วผู้เรียนรัน regression เดิม:

```bash
git fetch origin && git switch bughunt          # ผู้สอน push branch นี้เข้า repo ผู้เรียน (หรือส่ง patch)
sim/regress.sh                                   # หรือ cd sim && vsim -c -do regress.do
```

ผลจริงของบั๊กตัวอย่าง 3 ตัวจาก Module 08 (เฉลยสำหรับผู้สอน):

| บั๊ก | `tb_uart` (8.4 เดิม) | `tb_baud_margin` (V7b) | บทเรียน |
| --- | --- | --- | --- |
| A: `OS/2-1` → `OS/2` (sample ช้าไป 1/16 บิต) | **ผ่านหมด — จับไม่ได้** | FAIL ที่คาบบิต 95.0% (`RESULT errors=1`) | บั๊กที่กิน *margin* ต้องจับด้วย test ที่ไปถึงขอบ ไม่ใช่ test ที่ "ตรงกลาง" |
| B: shift ซ้ายแทนขวาใน RX | FAIL ตั้งแต่ V1 (`byte #2 exp 55 got aa`) | FAIL 21 จุด | scoreboard ที่คำนวณคำตอบเองจับบั๊กฟังก์ชันได้ทันที (0x00/0xFF ผ่าน เพราะสมมาตร) |
| C: ลบ synchronizer 1 ชั้น | **ผ่านหมด** | **ผ่านหมด** | simulation ไม่มี metastability — จับได้ด้วย code review, เครื่องมือ CDC หรือ assertion เชิงโครงสร้าง |

ช่วงที่รับได้จริง (คาบบิตฝั่งส่งเทียบกับค่าตาม spec, สแกนทีละ 0.5%): RTL ถูก **94.5%–105.5%** (สมมาตรรอบจุดกึ่งกลาง) · บั๊ก A **95.5%–105.5%** (ด้านเร็วหดไป 1%) — นี่คือเหตุผลที่ vplan ควรมีแถว V7b แทน V7 ที่ทดสอบแค่ ±3%

`tb/tb_baud_margin.sv`:

```systemverilog
// tb_baud_margin.sv — หาช่วงความคลาดของ baud ฝั่งส่งที่ RX ยังรับถูก (vplan V7 แบบละเอียด)
// ขับ rx เองด้วยคาบบิต = TBIT * pm / 1000 แล้วตรวจว่ารับได้ถูกครบทุกไบต์ทดสอบ
`timescale 1ns/1ps
module tb_baud_margin;
  localparam int CLK_FREQ = 50_000_000, BAUD = 115_200, OS = 16;
  localparam int DIV  = (CLK_FREQ + (BAUD*OS)/2) / (BAUD*OS);
  localparam int TBIT = DIV * OS;
  logic clk = 0, rst_n = 0, tx_start = 0, rx = 1;
  logic [7:0] tx_data = '0, rx_data;
  logic tx, tx_busy, rx_valid, rx_err;
  logic [7:0] got; bit got_v, got_e;
  int errors = 0;
  localparam int REQ_LO = 950, REQ_HI = 1050;            // spec: ต้องทนคาบบิต ±5% (V7b)

  uart_top #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD), .OS(OS)) dut (.*);
  always #10 clk = ~clk;
  always @(posedge clk) begin
    if (rx_valid) begin got = rx_data; got_v = 1; end
    if (rx_err)   got_e = 1;
  end

  task automatic drive_frame(input logic [7:0] b, input int nclk);
    rx = 0;                         repeat (nclk) @(posedge clk);
    for (int i = 0; i < 8; i++) begin rx = b[i]; repeat (nclk) @(posedge clk); end
    rx = 1;                         repeat (nclk) @(posedge clk);
    repeat (3*TBIT) @(posedge clk);                   // พักให้ RX กลับ IDLE แน่นอน
  endtask

  function automatic logic [7:0] pat(input int k);    // ไบต์ทดสอบที่มีบิตสลับมาก/น้อย
    case (k) 0: return 8'h55; 1: return 8'hAA; 2: return 8'h0F; 3: return 8'hF0;
             4: return 8'h01; default: return 8'h80; endcase
  endfunction

  initial begin
    repeat (5) @(negedge clk); rst_n = 1;
    for (int pm = 900; pm <= 1100; pm += 5) begin       // 90.0% .. 110.0% ของคาบบิต
      bit ok;
      ok = 1;                                         // ตั้งค่าทุกรอบ (ประกาศพร้อมค่าเริ่มใน loop = static ตั้งครั้งเดียว)
      for (int k = 0; k < 6; k++) begin
        got_v = 0; got_e = 0;
        drive_frame(pat(k), TBIT * pm / 1000);
        if (!got_v || got_e || got !== pat(k)) ok = 0;
      end
      $display("bit period %0d.%0d%% : %s", pm/10, pm%10, ok ? "ok" : "FAIL");
      if (!ok && pm >= REQ_LO && pm <= REQ_HI) begin
        errors++; $error("must tolerate %0d.%0d%% bit period", pm/10, pm%10);
      end
    end
    $display("RESULT errors=%0d", errors);
    $stop;
  end
endmodule
```

> บทเรียนจากการเขียน test นี้เอง: รุ่นแรกเขียน `bit ok = 1;` ใน loop — ตัวแปรใน block ของ `initial` เป็น static ค่าเริ่มต้นจึงถูกตั้งครั้งเดียว พอรอบแรก (90%) fail ทุกจุดหลังจากนั้นก็ fail ตาม — Icarus เตือน "Static variable initialization requires explicit lifetime" อย่ามองข้าม warning ใน testbench

**คำถามสะท้อนคิด (บั๊ก C):** เขียนคำตอบใน bug log — ทำไม simulation จับไม่ได้ และจะป้องกันอย่างไร ตัวอย่าง assertion เชิงโครงสร้าง (Questa; ยังไม่ได้ทดสอบในคู่มือนี้):

```systemverilog
// เพิ่มใน uart_sva.sv — ค่าที่ FSM เห็นต้องเป็น rx ที่ผ่าน FF มา 2 ชั้นพอดี
a_sync2 : assert property (@(posedge clk) disable iff (!rst_n) u_rx.rx_s == $past(rx, 2));
```

### ขั้นที่ 5 — ปิด vplan และส่ง (30 นาที)

อัปเดตคอลัมน์ Status ทุกแถว (อ้าง log/บรรทัด `pass:` ที่เป็นหลักฐาน) แล้ว:

```bash
grep -c "planned" doc/vplan.md                  # ต้องได้ 0
sim/regress.sh && sim/regress.sh vhdl           # หรือ regress.do บน ModelSim
git add -A && git commit -m "M3: verification sign-off — 6/6 regression, vplan closed, bug log"
git tag -a m3-verif -m "M3 verification sign-off"
git push origin main m3-verif
```

✅ **Gate M3:** regression ผ่านจาก clone ใหม่, vplan ไม่เหลือ `planned`, coverage ถึงเป้าหรือ waived พร้อมเหตุผล, bug log มีผล bug hunt

## M4 — Implementation (สัปดาห์ 4 ต้น, \~8 ชั่วโมง)

**ส่ง:** `syn/` (สคริปต์ + log), รายงาน STA 3 corner, `pnr/config.mk`, ภาพ layout `doc/img/layout.png`, ตาราง PPA ใน README · **Gate:** WNS ≥ 0 ที่ ss (setup) และ ff (hold) **หลัง route**, DRC = 0, ไม่มี latch, อธิบายผล VHDL vs Verilog ได้ · **Tag:** `m4-impl`

### ขั้นที่ 1 — Synthesis สองภาษา (1 ชั่วโมง)

```bash
cd syn && LIB=$LIB ./run_synth.sh
```

ผลจริง (Yosys 0.69, sky130\_fd\_sc\_hd tt):

|  | Verilog | VHDL (ผ่าน `ghdl --synth`) |
| --- | --- | --- |
| จำนวน cell | 205 | 226 |
| พื้นที่ (µm²) | 2,374.78 | 2,506.15 |
| FF (dfrtp + dfstp) | 51 + 4 = **55** | 52 + 5 = **57** |
| latch | 0 | 0 |
| `check -assert` | 0 problems | 0 problems |

**ทำไมไม่ใช่ 53 FF ตามที่นับจาก RTL และทำไมสองภาษาต่างกัน** (คำตอบที่ gate M4 ต้องการ): เปิด `syn/synth.log` หา `FSM_RECODE` — Yosys แปลง FSM เป็น one-hot (4 FF แทน 2 FF) ในสาย Verilog ทำเฉพาะ FSM ของ RX (state ของ TX ถูกใช้สร้างเอาต์พุต `tx_busy` จึงไม่ถูก extract: "Not marking uart\_top.u\_tx.state as FSM state register") → 53 + 2 = 55 ส่วนสาย VHDL ถูก recode ทั้งสอง FSM → 53 + 4 = 57

```bash
grep -E "Recoding FSM|Not marking|one-hot" syn/synth.log syn/synth_vhd.log
```

### ขั้นที่ 2 — STA 3 corner (1.5 ชั่วโมง)

`syn/constraint.sdc` ใช้ตาม 8.5 — `syn/sta.tcl` เพิ่มรายงานที่ gate ต้องใช้ (`report_worst_slack -min` สำหรับ hold และ `report_clock_min_period` สำหรับ Fmax — `report_wns` ดูแต่ setup):

```tcl
# sta.tcl — STA + power ของ netlist หลัง synthesis (รันจาก syn/)
# ใช้งาน: LIB=<.lib ของ corner> NETLIST=uart_top_syn.v sta -no_splash -exit sta.tcl
read_liberty $::env(LIB)
read_verilog $::env(NETLIST)
link_design  uart_top
read_sdc     constraint.sdc

report_checks -path_delay max -fields {slew cap fanout} -digits 3
report_checks -path_delay min -digits 3
report_checks -path_delay max -from [all_registers -clock_pins] -to [all_registers -data_pins] -digits 3
report_wns
report_tns
report_worst_slack -max -digits 3        ;# setup (ใช้ที่ corner ss)
report_worst_slack -min -digits 3        ;# hold  (ใช้ที่ corner ff)
report_check_types -max_slew -max_capacitance -violators
report_clock_min_period                  ;# Fmax ของ reg→reg

set_power_activity -input -activity 0.1
report_power
```

```bash
LIBDIR=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib
for c in tt_025C_1v80 ss_100C_1v60 ff_n40C_1v95; do
  LIB=$LIBDIR/sky130_fd_sc_hd__${c}.lib NETLIST=uart_top_syn.v sta -no_splash -exit sta.tcl > sta_${c}.rpt
  grep -E "^worst slack|period_min|^Total" sta_${c}.rpt
done
```

ผลจริง (netlist Verilog, period 20 ns):

| Corner | Setup worst slack | Hold worst slack | period\_min (reg→reg) | Total power |
| --- | --- | --- | --- | --- |
| tt 25°C 1.80 V | 14.654 | 0.115 | 1.86 ns (538 MHz) | 133 µW |
| ss 100°C 1.60 V | 13.529 | 0.466 | **3.72 ns (269 MHz)** | 104 µW |
| ff −40°C 1.95 V | 15.088 | **−0.009 (VIOLATED)** | 1.26 ns (795 MHz) | 157 µW |

**อ่านผล:**

1. **Setup เหลือมาก** — path แย่สุดจริง ๆ คือ input → FF เพราะ input delay 4 ns ส่วน reg→reg ที่ ss คือ `u_tx.state[0]` → or2 → and3 → a21oi → mux2 → `u_tx.state[0]` arrival 3.393 ns (ตรงกับที่ 8.5 คาด: เงื่อนไข tick/ตัวนับ → สถานะถัดไป)
2. **Hold พังที่ ff บน synchronizer** — `rx_m` → `rx_s` ต่อ Q→D ตรง ๆ: arrival 0.241 น้อยกว่า uncertainty 0.25 ที่ SDC ใช้กับ hold ด้วย — เป็นตัวอย่างจริงของคำเตือนใน Lab 6/7 (hold บน shift register/scan chain) ทางแก้: ปล่อยให้ ORFS ซ่อม hold หลัง CTS (ใส่ buffer) แล้วตรวจหลัง route หรือแยก `set_clock_uncertainty -hold` ให้สมจริง — **ห้าม**แก้ด้วย `set_false_path` ที่ synchronizer
3. **Fmax ss = 269 MHz** เกินเป้า 50 MHz หลายเท่า — ส่วนสาย VHDL ได้เพียง **6.33 ns (158 MHz)** เพราะ ABC เลือก cell `a2111oi_0` (drive เล็กสุด) ที่ช้า 2.795 ns ใน path เดียว — โครงสร้างหลัง synthesis ต่างกันแม้พฤติกรรมเหมือนกัน (ขั้น resize ใน P&R จะลดช่องว่างนี้) — ใส่ในหัวข้อ "เทียบ VHDL vs Verilog" ของ report
4. **Power** มี warning "activity propagation through registers did not converge" — ตัวเลข vectorless ใช้เปรียบเทียบได้ แต่ควรยืนยันด้วย VCD ตาม Lab 7B ถ้าจะอ้างใน report

### ขั้นที่ 3 — Place & Route ด้วย ORFS (3 ชั่วโมง)

ใช้ `pnr/config.mk` และคำสั่งตาม 8.5 ใน container ของ Lab 5 — UART เล็กมาก (\~2,400 µm²) ถ้า floorplan ฟ้องเรื่อง pin ไม่พอให้กำหนดขนาดเอง (ตัวเลขตัวอย่าง — ต้องปรับตามผลจริง):

```makefile
# pnr/config.mk — ถ้า CORE_UTILIZATION ทำให้ die เล็กเกินวาง pin 24 ตัว ให้ใช้ DIE_AREA/CORE_AREA แทน
export DESIGN_NAME      = uart_top
export PLATFORM         = sky130hd
export VERILOG_FILES    = $(sort $(wildcard $(DESIGN_HOME)/src/uart/*.v))
export SDC_FILE         = $(DESIGN_HOME)/$(PLATFORM)/uart/constraint.sdc
export CORE_UTILIZATION = 40
export PLACE_DENSITY    = 0.60
# export DIE_AREA  = 0 0 120 120
# export CORE_AREA = 10 10 110 110
```

สิ่งที่ต้องเก็บเข้า repo หลัง `make` จบ (ห้าม commit ทั้ง `results/`):

```bash
F=~/OpenROAD-flow-scripts/flow
mkdir -p pnr/reports doc/img
cp $F/reports/sky130hd/uart/base/6_finish.rpt  pnr/reports/       # WNS/TNS หลัง route
cp $F/reports/sky130hd/uart/base/*drc*         pnr/reports/ 2>/dev/null || true
grep -iE "wns|tns|worst slack" pnr/reports/6_finish.rpt
# ภาพ layout: make ... gui_final แล้ว save image หรือเปิด GDS ใน KLayout → File > Export → doc/img/layout.png
```

ชื่อไฟล์ report ต่างตามเวอร์ชัน ORFS (ดูจาก Lab 5) — hold ที่พังหลัง synthesis ในขั้นที่ 2 ต้องหายไปหลัง route ถ้ายังอยู่ gate ไม่ผ่าน

### ขั้นที่ 4 — ตาราง PPA (1 ชั่วโมง)

กรอกใน README — คอลัมน์ "หลัง synthesis" เติมจากผลจริงของ repo ตัวอย่างแล้ว คอลัมน์ "หลัง route" ผู้เรียนเติมเอง:

| ตัวชี้วัด | เป้าหมาย (spec) | หลัง synthesis | หลัง route |
| --- | --- | --- | --- |
| Clock period / setup WNS (ss) | 20 ns / ≥ 0 | 20 ns / 0 (worst slack 13.529) |  |
| Fmax reg→reg (ss) | ≥ 50 MHz | 269 MHz |  |
| Hold worst slack (ff) | ≥ 0 | −0.009 (รอ hold fix) |  |
| Cell area (µm²) | < 5,000 | 2,374.78 |  |
| จำนวน FF / latch | \~53 / 0 | 55 / 0 |  |
| Total power (tt, activity 0.1) | รายงาน | 133 µW |  |
| DRC / LVS | 0 / clean | — |  |

### ขั้นที่ 5 — งานเพิ่มคะแนน (เลือก 1) และส่ง

| ตัวเลือก | หลักฐานที่ต้องมีใน tag |
| --- | --- |
| หา Fmax จริงและแก้ critical path | sweep ตาม Lab 6C + รายงาน path ก่อน/หลังแก้ |
| Clock gating (8.5) | report\_power ก่อน-หลัง + regression เดิมผ่านทุก seed + พอร์ต test\_en |
| Scan insertion (Lab 7E) | `report_dft_plan` + พื้นที่ที่เพิ่ม |
| FPGA demo | ไฟล์ constraint ของบอร์ด + วิดีโอ/ภาพ terminal |

```bash
git add syn/*.sh syn/*.tcl syn/*.sdc syn/*.log syn/sta_*.rpt pnr/ doc/img/layout.png README.md
git commit -m "M4: synthesis + STA 3 corners + ORFS layout + PPA table"
git tag -a m4-impl -m "M4 implementation"
git push origin main m4-impl
```

✅ **Gate M4:** หลัง route — setup WNS ≥ 0 (ss), hold WNS ≥ 0 (ff), DRC = 0; ตาราง PPA ครบ; อธิบายความต่าง VHDL/Verilog ด้วยหลักฐานจาก log (จำนวน FF, critical path)

## M5 — Final Report + Demo (สัปดาห์ 4 ท้าย, \~8 ชั่วโมง)

**ส่ง:** README ฉบับสมบูรณ์, `doc/report.md`, สไลด์ 9 หน้า, demo · **Gate:** คนอื่น clone repo แล้วรันตาม Quick start ได้จริงบนเครื่องสะอาด · **Tag:** `v1.0`

### ขั้นที่ 1 — README ฉบับสมบูรณ์ (1.5 ชั่วโมง)

แทน proposal ด้วยแม่แบบใน 8.6 (ย้าย proposal ไป `doc/proposal.md` — ประวัติยังอยู่ที่ tag `m0-proposal`) สิ่งที่ต้องมีใน 30 วินาทีแรกที่คนเปิด:

| ส่วน | ตัวอย่าง UART (ตัวเลขจริงจาก M4) |
| --- | --- |
| บรรทัดสรุป | UART 8N1, VHDL + Verilog, 5-seed regression + baud-margin test, RTL→GDS บน Sky130 |
| ภาพ layout | `doc/img/layout.png` |
| ตาราง metric | Fmax (ss) 269 MHz post-synthesis · 2,375 µm² · 133 µW @50 MHz tt — แทนด้วยค่าหลัง route ถ้ามี |
| Quick start | คำสั่งที่คัดลอกไปรันได้เลย + ตัวแปร env ที่ต้องตั้ง (`LIB`) |
| Known limitations | ไม่มี parity/FIFO, break หลัง framing error อาจเกิด false start |

Quick start ที่ตรงกับ repo นี้:

```bash
export LIB=<path>/sky130_fd_sc_hd__tt_025C_1v80.lib
./check_m2.sh                          # lint + unit test + no latch
sim/regress.sh && sim/regress.sh vhdl  # หรือ: cd sim && vsim -c -do regress.do
cd syn && ./run_synth.sh && LIB=$LIB NETLIST=uart_top_syn.v sta -no_splash -exit sta.tcl
```

### ขั้นที่ 2 — Design report (3 ชั่วโมง)

`doc/report.md` 6–10 หน้าตามโครง 8.6 — ทุกตัวเลขต้องชี้ได้ว่ามาจากไฟล์ไหนใน repo:

| หัวข้อ | เนื้อหาหลัก (จากงานที่ทำมาแล้ว) | หลักฐาน |
| --- | --- | --- |
| 1. บทนำ | ปัญหา + เป้า PPA | doc/spec.md §8 |
| 2. สถาปัตยกรรม | block diagram, FSM, ทำไม OS = 16, ทำไม tick enable แทน clock หาร | spec §5–6, ตาราง baud error (M1) |
| 3. Verification | vplan + ผล regression, ช่วง baud 94.5–105.5%, bug hunt A/B/C, bug log | sim/regress.log, doc/buglog.md |
| 4. Implementation | ตาราง PPA, critical path, hold บน synchronizer ที่ ff, layout, VHDL vs Verilog (55 vs 57 FF, 269 vs 158 MHz) | syn/*.log, syn/sta\_*.rpt, pnr/reports |
| 5. Low power / DFT | สิ่งที่ทำ (เช่น clock gating พร้อมตัวเลข) หรือ DFT checklist 8.5 | — |
| 6. สรุป | สิ่งที่เรียนรู้, ข้อจำกัด, งานต่อยอด | — |

### ขั้นที่ 3 — ทดสอบ clone สะอาด (30 นาที)

ปัญหาอันดับ 1 ตอน demo คือ "เครื่องฉันรันได้" — เพราะมีไฟล์ที่ลืม commit หรือ path แบบ absolute `fresh_clone_test.sh`:

```bash
#!/usr/bin/env bash
# fresh_clone_test.sh — จำลอง "คนอื่น clone repo แล้วรันตาม Quick start" ก่อนติด tag v1.0
# ใช้งาน: ./fresh_clone_test.sh [ref]   (ค่าเริ่ม = HEAD ที่ push แล้วบน origin/main)
set -e
REF=${1:-origin/main}
URL=$(git remote get-url origin 2>/dev/null || pwd)
TMP=$(mktemp -d)
git clone -q "$URL" "$TMP/repo" && cd "$TMP/repo"
git -c advice.detachedHead=false checkout -q "$REF"
echo "== clean clone of $REF at $TMP/repo"
git status --short | head                       # ต้องว่าง: ไม่มีไฟล์ที่สคริปต์ต้องการแต่ลืม commit
./check_m2.sh        > m2.log 2>&1 && echo "M2 gate   : PASS" || { echo "M2 gate   : FAIL (ดู $TMP/repo/m2.log)"; exit 1; }
sim/regress.sh       > rg.log 2>&1 && echo "regression: PASS" || { echo "regression: FAIL (ดู $TMP/repo/rg.log)"; exit 1; }
(cd syn && ./run_synth.sh > ../syn.log 2>&1) && echo "synthesis : PASS" || { echo "synthesis : FAIL"; exit 1; }
echo "fresh clone OK — พร้อมติด tag v1.0"
```

ผลจริง (repo ตัวอย่าง):

```text
== clean clone of HEAD at /tmp/tmp.4ztlbDXWI0/repo
M2 gate   : PASS
regression: PASS
synthesis : PASS
fresh clone OK — พร้อมติด tag v1.0
```

### ขั้นที่ 4 — สไลด์ + ซ้อม (2 ชั่วโมง)

ใช้โครง 9 สไลด์ใน 8.6 (10 นาที + ถามตอบ 5 นาที) เก็บ PDF ไว้ที่ `doc/slides.pdf` — สไลด์ 8 (บั๊กที่ยากที่สุด) ควรเล่าเป็น อาการ → สมมติฐาน → หลักฐาน → แก้ (ตัวอย่างที่ดีจาก repo ตัวอย่าง: บั๊ก A ที่ testbench เดิมจับไม่ได้ จนเพิ่ม V7b)

**Demo สด (เลือก 1):** รัน `sim/regress.sh` ต่อหน้าผู้ฟัง (\~13 วินาที) · เปิด waveform เฟรม + framing error ใน ModelSim · FPGA คุยกับ terminal — เตรียมวิดีโอสำรองเสมอ

**เตรียมคำตอบ 5 คำถามใน 8.6** — คำตอบที่ดีอ้างหลักฐานใน repo เช่น "รู้ได้อย่างไรว่าทดสอบครบ" → ชี้ vplan ที่ไม่เหลือ planned + bug hunt ที่ C จับไม่ได้ด้วย simulation และเหตุผล; "ผลหลัง route ต่างจากหลัง synthesis เพราะอะไร" → wire delay, clock tree จริงแทน ideal clock, buffer ที่ hold fix แทรก (เทียบ hold slack −0.009 ns หลัง synthesis กับค่าหลัง route)

### ขั้นที่ 5 — ส่ง v1.0 (15 นาที)

ติ๊ก Checklist ก่อนส่ง v1.0 ใน Module 08 ให้ครบ แล้ว:

```bash
git add -A && git commit -m "M5: final README, report, slides"
git push origin main
./fresh_clone_test.sh                     # ต้อง OK ก่อนติด tag
git tag -a v1.0 -m "Capstone v1.0 — UART RTL to GDS"
git push origin v1.0
git log --oneline v0.9-rtl-freeze..v1.0 -- rtl/    # ทุกบรรทัดต้องเป็น fix(#N): (กติกา freeze)
```

ทางเลือก: สร้าง GitHub Release จาก tag `v1.0` แนบ `slides.pdf` และ `layout.png` — หน้า portfolio พร้อมใช้

✅ **Gate M5:** `fresh_clone_test.sh` OK ที่ tag `v1.0`, README/report/slides อยู่ใน tag, นำเสนอตรงเวลา 10 นาที

## การตรวจจาก tag, แก้ปัญหา และเกณฑ์ให้คะแนน

### สคริปต์ผู้สอน: grade\_tags.sh

ผู้สอน clone ทุก repo ด้วยสคริปต์เดียว — ตรวจว่า tag มีจริง (ใช้ revision `-rN` ล่าสุด), เป็น annotated, มีไฟล์ครบ **ภายใน tag** (ไม่ใช่ใน main ปัจจุบัน), ไม่มีไฟล์ต้องห้าม และ (เมื่อใส่ `--run`) รัน gate script ของผู้เรียนที่ tag นั้น

```bash
#!/usr/bin/env bash
# grade_tags.sh — ผู้สอนตรวจ milestone จาก git tag (ไม่ใช่ไฟล์แนบ)
# ใช้งาน:  ./grade_tags.sh <repo URL หรือ path> [--run] [tag ...]
#   --run  : checkout tag นั้นแล้วรัน gate script ที่ผู้เรียนใส่ไว้ (M2: check_m2.sh, M3: sim/regress.sh)
set -u
REPO=$1; shift
RUN=0; [ "${1:-}" = "--run" ] && { RUN=1; shift; }
TAGS=${*:-"m0-proposal m1-spec v0.9-rtl-freeze m3-verif m4-impl v1.0"}

WORK=$(mktemp -d)
git clone -q "$REPO" "$WORK/repo" || { echo "clone failed"; exit 1; }
cd "$WORK/repo"

required() {                       # ไฟล์ที่ต้องมี "ภายใน tag" ของแต่ละ milestone
  case $1 in
    m0-proposal)     echo "README.md" ;;
    m1-spec)         echo "README.md doc/spec.md doc/vplan.md" ;;
    v0.9-rtl-freeze) echo "rtl/verilog/uart_top.v rtl/vhdl tb sim/run_unit.do check_m2.sh syn/run_synth.sh" ;;
    m3-verif)        echo "tb/tb_uart.sv sim/regress.do doc/vplan.md doc/buglog.md" ;;
    m4-impl)         echo "syn/constraint.sdc syn/sta.tcl syn/synth.log pnr/config.mk doc/img/layout.png" ;;
    v1.0)            echo "README.md doc/report.md doc/spec.md doc/vplan.md doc/buglog.md" ;;
  esac
}
FORBID='(^|/)(work|results|logs|objects)/|\.wlf$|\.vcd$|\.ucdb$|(^|/)transcript$|\.(gds|lef|lib)$'

printf "%-16s %-10s %-11s %-6s %s\n" TAG DATE TYPE GATE NOTE
for base in $TAGS; do
  t=$(git tag -l "$base" "$base-r*" | sort -V | tail -1)       # ใช้ revision ล่าสุด (-r1, -r2, ...)
  if [ -z "$t" ]; then
    printf "%-16s %-10s %-11s %-6s %s\n" "$base" - - FAIL "tag not found"; continue
  fi
  kind=$(git cat-file -t "$t")                                   # tag = annotated, commit = lightweight
  date=$(git for-each-ref --format='%(taggerdate:short)%(committerdate:short)' "refs/tags/$t" | cut -c1-10)
  miss=""; for f in $(required "$base"); do git cat-file -e "$t:$f" 2>/dev/null || miss="$miss $f"; done
  bad=$(git ls-tree -r --name-only "$t" | grep -E "$FORBID" | head -3 | tr '\n' ' ')
  note=""; gate=PASS
  [ -n "$miss" ] && { gate=FAIL; note="missing:$miss "; }
  [ -n "$bad" ]  && { gate=FAIL; note="${note}forbidden: $bad"; }
  [ "$kind" != tag ] && note="${note}(lightweight tag — ใช้ git tag -a) "
  if [ $RUN = 1 ] && [ $gate = PASS ]; then
    git -c advice.detachedHead=false checkout -q "$t"
    case $base in
      v0.9-rtl-freeze) ./check_m2.sh > "$WORK/$t.log" 2>&1 || { gate=FAIL; note="${note}check_m2.sh failed"; } ;;
      m3-verif)        sim/regress.sh > "$WORK/$t.log" 2>&1 || { gate=FAIL; note="${note}regression failed"; } ;;
    esac
    git checkout -q - 2>/dev/null || true
  fi
  printf "%-16s %-10s %-11s %-6s %s\n" "$t" "$date" "$kind" "$gate" "$note"
done
echo "logs: $WORK"
```

ผลจริงจาก repo ทดสอบที่ตั้งใจใส่ความผิดพลาดที่พบบ่อย (`--run`, มี `LIB` ใน environment):

```text
TAG              DATE       TYPE        GATE   NOTE
m0-proposal      2026-10-28 tag         PASS
m1-spec-r1       2026-10-28 tag         PASS                 <- ใช้ revision ล่าสุดอัตโนมัติ
v0.9-rtl-freeze  2026-10-28 tag         PASS                 <- รัน check_m2.sh ที่ tag แล้วผ่าน
m3-verif         2026-10-28 tag         FAIL   missing: sim/regress.do doc/buglog.md forbidden: sim/work/_info
m4-impl          -          -           FAIL   tag not found
v1.0             2026-10-28 tag         FAIL   missing: doc/report.md doc/buglog.md
```

ก่อนหน้านี้ในการทดสอบ lightweight tag (`git tag m1-spec` ไม่มี `-a`) แสดงเป็น `commit ... (lightweight tag — ใช้ git tag -a)` — ไม่ตัดสิทธิ์แต่เตือน

**เรื่องเวลาส่ง:** วันที่ใน tag ตั้งเองได้บนเครื่องผู้เรียน ถ้าต้องการเส้นตายที่เชื่อถือได้ ให้ผู้สอนรัน `grade_tags.sh` ตอนหมดเวลา (สิ่งที่ไม่อยู่บน server ตอนนั้น = ไม่ได้ส่ง) และเก็บผลไว้

### ตารางแก้ปัญหา (เฉพาะที่เกิดจริงตอนทำ repo ตัวอย่าง + เรื่อง git)

| อาการ | สาเหตุ | วิธีแก้ |
| --- | --- | --- |
| ผู้สอนบอก "tag not found" ทั้งที่เห็นในเครื่อง | `git push` ไม่ส่ง tag | `git push origin <tag>` หรือตั้ง `push.followTags true`; ตรวจด้วย `git ls-remote --tags origin` |
| tag ชี้ commit ผิด | tag ก่อน commit ไฟล์สุดท้าย | ห้ามย้าย tag — commit เพิ่มแล้วส่ง `-r1` |
| `forbidden: sim/work/...` | ใช้ `git add -f` หรือ .gitignore ไม่ครบ | `git rm -r --cached sim/work` แล้ว commit + tag `-rN` |
| `verilator -Wall` หยุดด้วย WIDTHEXPAND/WIDTHTRUNC | เทียบ reg กับ integer หรือ localparam ที่กำหนดความกว้างจาก integer ตรง ๆ | ตัดบิตจาก integer: `localparam [TW-1:0] X = X_I[TW-1:0];` (M2 ขั้นที่ 3) |
| `ghdl -s rtl/vhdl/*.vhd` ฟ้อง unit not found | glob เรียงตามตัวอักษร | ระบุลำดับไฟล์ตาม dependency |
| Icarus: "Assignment to an entire array ... not yet supported" | `'{...}` กำหนดค่า array | กำหนดทีละช่องใน `initial` |
| Verilator: "disable isn't underneath a begin with name" | `disable <fork label>` ไม่รองรับ | ใช้ ModelSim หรือ Icarus กับ `tb_uart.sv` |
| test ใน loop fail ทุกรอบหลังจากรอบแรก | `bit ok = 1;` ใน block = static ตั้งค่าครั้งเดียว | ประกาศแยกแล้ว assign ทุกรอบ หรือใช้ `automatic` |
| `$urandom(seed)` ทำให้ seed ที่พิมพ์เป็นเลขแปลก | argument เป็น inout ถูกแก้ค่า | พิมพ์ก่อนเรียก |
| run\_synth.sh: "File \`$LIB' not found" | ตัวแปรอยู่ใน single quote | ใช้ double quote ตามสคริปต์ใน M2 |
| hold พังที่ ff หลัง synthesis | uncertainty 0.25 ใช้กับ hold, synchronizer ต่อ Q→D ตรง | ปล่อยให้ ORFS ซ่อม แล้วตรวจหลัง route — ห้าม false path |

### เกณฑ์ให้คะแนน

คะแนนรวมใช้ Rubric Capstone 100 คะแนนใน Module 08 — ตารางนี้บอกว่าแต่ละ milestone ให้หลักฐานกับหัวข้อไหน และกติกาหักคะแนนที่ตรวจได้จาก tag:

| Milestone | น้ำหนัก | หัวข้อ rubric ที่ใช้หลักฐาน | หักคะแนน (ตัวอย่างนโยบาย — ปรับได้) |
| --- | --- | --- | --- |
| M0 | 5% | Spec + การวางแผน | — |
| M1 | 15% | Spec + การวางแผน | แต่ละ revision หลัง peer review ไม่หัก (ส่งเสริมการแก้) |
| M2 | 20% | คุณภาพ RTL | `check_m2.sh` FAIL ตอนหมดเวลา → ได้ไม่เกิน 50% ของ milestone จนกว่าจะ PASS |
| M3 | 25% | Verification | bug hunt จับไม่ได้และไม่มีคำอธิบาย → −10% ของ milestone |
| M4 | 20% | Implementation (PPA) | ถึง synthesis + STA แต่ไม่ถึง GDS → ระดับ "พอใช้" ตาม rubric |
| M5 | 15% | เอกสาร + repo, การนำเสนอ | fresh clone รันไม่ได้ → หัวข้อเอกสาร + repo ได้ไม่เกิน "พอใช้" |
| ทุก milestone | — | — | ไฟล์ต้องห้ามใน tag, ย้าย tag เดิม (`-f`) → แก้และส่ง `-rN` |

**การอบรมแบบเข้มข้น 2–3 วัน:** ให้ clone repo UART ตัวอย่างที่ผ่าน M2 แล้วเป็นจุดเริ่ม ผู้เรียนทำ 1 ฟีเจอร์ (parity หรือ majority vote) ผ่าน M1 (spec ของฟีเจอร์) → M3 (เพิ่มแถว vplan + test) → M4 (เทียบพื้นที่ก่อน/หลัง) → M5 (นำเสนอ 5 นาที) — ใช้ `grade_tags.sh` ตัวเดิม

> **หมายเหตุสำหรับผู้สอน:** ทุกสคริปต์และ testbench ใน Lab นี้รันจริงแล้ว (Verilator 5.020, GHDL 4.1, Icarus 12, Yosys 0.69, OpenSTA 3.1.0) — ส่วนที่ยังไม่ได้รัน: ไฟล์ .do บน ModelSim จริง, code coverage, assertion `a_sync2`, ORFS P&R ของ UART และตัวเลขหลัง route ไฟล์ .lib ของ corner ss/ff ที่ใช้สร้างจาก JSON ใน repo skywater-pdk-libs-sky130\_fd\_sc\_hd ด้วยสคริปต์ของ skywater-pdk (ค่า tt ที่ได้ตรงกับ .lib ของ ORFS ทุกตัว) ตัวเลข ss/ff จาก .lib ของ open\_pdks อาจต่างเล็กน้อย

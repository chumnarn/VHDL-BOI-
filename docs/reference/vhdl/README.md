# VHDL Golden Reference for RTL Designers

> คู่มือฉบับนี้เขียนสำหรับผู้เรียนและผู้ออกแบบ RTL ที่ต้องเขียน VHDL
> ให้สามารถอ่านโค้ดของคนอื่นได้ แก้โค้ดได้อย่างปลอดภัย
> และรู้ว่าอะไรคือข้อผิดพลาดที่พบบ่อยที่สุด

**เครื่องมือที่ใช้ตรวจสอบตัวอย่างทั้งหมด:** GHDL 1.0.0 (Dunoon, mcode) ใน WSL2 Ubuntu 22.04
**ชุดตัวอย่างโค้ด:** [`code/reference/vhdl/`](../../../code/reference/vhdl/README.md)
**คู่มือการใช้ simulator:** [Questa SIM for RTL Designers](../questa/README.md)

---

## บทนี้เหมาะกับใคร

- นักศึกษาที่เรียนวิศวกรรมดิจิทัลไอซีและต้องเขียน RTL ที่สังเคราะห์ได้จริง
- ผู้ประกอบงานที่เคยใช้ Verilog แล้วต้องดูแลโค้ด VHDL
- อาจารย์ที่ต้องการตัวอย่างอ้างอิงที่ทดสอบแล้วจริง ไม่ใช่ตัวอย่างที่แต่งขึ้น

## คู่มือนี้ไม่ใช่อะไร

- ไม่ใช่คู่มือ VHDL ทุกเรื่อง — เป็นคู่มือที่เน้น "สิ่งที่ต้องรู้เพื่อออกแบบ RTL จริง"
- ไม่ใช่ผลการวัดของชิปจริง — ตัวเลขทุกอย่างในตัวอย่างเป็นข้อมูลสมมติเพื่อการสอน
- ไม่ได้อ้างว่า "ผ่าน sign-off" หรือ "ผ่านมาตรฐานโรงงาน" — ทุกตัวอย่างผ่าน
  เกณฑ์ที่ระบุไว้เท่านั้น และมี log ยืนยัน

---

## สารบัญ

### ภาคเริ่มต้น

| บท | ชื่อ | สิ่งที่จะได้ |
|---|---|---|
| [00](00-preface.md) | บทนำ | วิธีใช้คู่มือนี้ และภาพรวมของชุดตัวอย่าง |
| [01](01-language-basics.md) | พื้นฐานภาษา VHDL | design unit, context clause, library, package |
| [02](02-data-types.md) | ชนิดข้อมูล | `std_logic`, `unsigned`, `signed`, record, enum |
| [03](03-style-and-naming.md) | รูปแบบและการตั้งชื่อ | ตารางตั้งชื่อและกฎที่ใช้ทั้งคอร์ส |

### ภาคหลัก

| บท | ชื่อ | สิ่งที่จะได้ |
|---|---|---|
| [04](04-combinational-logic.md) | ตรรกะ combinational | sensitivity list, การกำหนดค่าให้ครบ, latch |
| [05](05-sequential-logic.md) | ตรรกะ sequential | clocked process, reset, enable, การอ่านค่าเก่า |
| [06](06-fsm.md) | เครื่องสถานะไฟ | FSM ด้วย enum, Moore/Mealy, การกู้สถานะเมื่อเป็น X |
| [07](07-interfaces-and-cdc.md) | อินเทอร์เฟซและ clock domain | handshake, synchronizer, async FIFO, CDC handshake |
| [08](08-arithmetic-and-pipeline.md) | การคำนวณและ pipeline | adder, overflow, pipeline ที่รองรับ back-pressure |
| [09](09-code-organization.md) | โครงสร้างโค้ดโปรเจกต์ | package, generic, generate, ลำดับการคอมไพล์ |
| [10](10-synthesis-subset.md) | สิ่งที่สังเคราะห์ได้ | synthesis subset, black box, `ghdl --synth` |
| [11](11-verification-style.md) | รูปแบบการทดสอบ | golden model, marker, watchdog, ตรวจค่า X, severity |
| [12](12-tools-and-commands.md) | เครื่องมือและคำสั่ง | GHDL, ModelSim, คำสั่งที่ใช้จริงในคอร์ส |
| [13](13-common-mistakes.md) | ข้อผิดพลาดที่พบบ่อย | ตารางอาการ → สาเหตุ → ทางแก้ |
| [14](14-verilog-cross-reference.md) | เทียบกับ Verilog | ตารางคำสั่งเทียบเท่า และจุดที่ให้ผลต่างกัน |
| [15](15-checklists.md) | เช็กลิสต์ก่อนส่งงาน | เช็กลิสต์ที่ใช้ได้จริงก่อน review |

### ภาคผนวก

| ภาคผนวก | ชื่อ | สิ่งที่จะได้ |
|---|---|---|
| [A](appendix-a-glossary.md) | ศัพท์อ้างอิง | ศัพท์ VHDL, RTL และ Verilog พร้อมคำอธิบาย |
| [B](appendix-b-references.md) | แหล่งอ้างอิง | มาตรฐาน IEEE, เอกสารเครื่องมือ, ตำรา |

---

## ชุดตัวอย่างโค้ด

ทุกตัวอย่างอยู่ใน `code/reference/vhdl/examples/` และผ่านเกณฑ์ 6 ข้อ
(คอมไพล์และจำลองด้วย VHDL-2008, คอมไพล์ด้วย VHDL-2002, และสังเคราะห์ด้วย `ghdl --synth`)

| ตัวอย่าง | บท | เนื้อหา |
|---|---|---|
| `ex00_minimal_dut` | 01 | โครงสร้างขั้นต่ำที่สุดของโมดูล VHDL — ใช้เป็นแม่แบบ |
| `ex01_alu_comb` | 04 | ALU แบบ combinational พร้อม golden model |
| `ex02_counter_sync` | 05 | ตัวนับแบบ synchronous พร้อมเคสขอบเขต |
| `ex03_shift_lfsr` | 05 | shift register และ LFSR ที่ให้ลำดับทำซ้ำได้ |
| `ex04_fsm_enum` | 06 | FSM ด้วย enum ทั้งแบบ Moore และ Mealy |
| `ex05_pipeline_valid_ready` | 07, 08 | pipeline ที่รองรับ back-pressure |
| `ex06_async_fifo` | 07 | FIFO ข้าม clock domain ด้วย Gray code pointer |
| `ex07_cdc_sync` | 07 | 2-flop synchronizer และกลไก pulse toggle |
| `ex08_pkg_rom` | 09 | package ที่รวม type, constant และ function สำหรับ ROM |
| `ex09_mem_sync` | 08, 10 | synchronous RAM และพฤติกรรม read-first |
| `ex10_uart_tx` | 06, 09 | FSM ส่งข้อมูล serial รูปแบบ UART 8N1 |
| `ex11_tb_patterns` | 11 | stimulus จากไฟล์, stimulus สุ่ม, scoreboard, ตรวจค่า X |
| `ex12_cdc_handshake` | 07 | handshake 4-phase พร้อมการรักษาข้อมูลข้าม domain |

ตรวจทุกตัวอย่างด้วยคำสั่งเดียว

```bash
cd code/reference/vhdl
bash run.sh
```

ผลที่ต้องเห็น

```text
  สรุป: ผ่าน 13 ตัวอย่าง, ไม่ผ่าน 0 ตัวอย่าง
```

---

## เส้นทางการอ่านที่แนะนำ

### ถ้าเพิ่งเริ่มเขียน VHDL

[01](01-language-basics.md) → [02](02-data-types.md) → [03](03-style-and-naming.md) →
[04](04-combinational-logic.md) → [05](05-sequential-logic.md) →
[12](12-tools-and-commands.md) แล้วทำ `ex00` ถึง `ex03`

### ถ้าเคยเขียน Verilog แล้ว

[03](03-style-and-naming.md) → [04](04-combinational-logic.md) →
[14](14-verilog-cross-reference.md) → [13](13-common-mistakes.md)

### ถ้ากำลังจะส่งงาน review

[15](15-checklists.md) → [13](13-common-mistakes.md) → [10](10-synthesis-subset.md)

### ถ้ากำลังออกแบบ interface ระหว่างโมดูล

[07](07-interfaces-and-cdc.md) → [09](09-code-organization.md) →
[12](12-tools-and-commands.md)

---

## ข้อตกลงที่ใช้ทั้งคู่มือและตัวอย่างโค้ด

สัญญารูปแบบฉบับเต็มอยู่ที่
[`code/reference/vhdl/STYLE-CONTRACT.md`](../../../code/reference/vhdl/STYLE-CONTRACT.md)
สรุปสั้น ๆ

1. มาตรฐานหลักคือ VHDL-2008 และต้องผ่าน `--std=02` ด้วย
   เพราะ ModelSim ของห้องเรียนตั้ง `VHDL93 = 2002`
2. ห้ามใช้ `ieee.std_logic_arith` ใช้ `ieee.numeric_std`
3. ทุก design unit ต้องมี context clause ของตัวเอง
4. ใน clocked process ใช้ `<=` กับ signal และ `:=` กับ variable เท่านั้น
5. combinational process ต้องกำหนดค่าเอาต์พุตครบทุก path
6. testbench ต้องเป็น self-checking มี marker `GOLDEN_<SHORT_ID>_PASS` และ watchdog
7. นาฬิกาใน testbench ต้องหยุดเมื่อ `done` เป็นจริง
8. ข้อความใน `report "..."` ต้องเป็น ASCII เท่านั้น ภาษาไทยใช้ได้เฉพาะในคอมเมนต์
9. ชื่อ entity/module และพอร์ตต้องตรงกันระหว่าง VHDL กับ Verilog

---

## ข้อจำกัดของคู่มือนี้

- ตรวจสอบด้วย GHDL 1.0.0 เท่านั้น ผลของ simulator รุ่นอื่นอาจต่างกัน
  โดยเฉพาะข้อความ warning
- ไม่มีผลการสังเคราะห์กับ PDK จริง (IHP SG13G2 หรือ SKY130) จึงไม่มีตัวเลข
  ด้านพื้นที่ กำลังไฟ หรือ timing
- ตัวอย่างทั้งหมดเป็นตัวอย่างเชิงไวยากรณ์และตรรกะ ไม่ใช่วงจรที่ผ่านการรับรอง
- `ghdl --synth` ยังไม่ทำ attribute `async_reg` จึงขึ้นคำเตือน
  `unhandled attribute "async_reg"` ใน log ของตัวอย่างที่มี synchronizer

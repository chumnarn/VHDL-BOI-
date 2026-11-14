# ภาคผนวก A: ศัพท์อ้างอิง

> ศัพท์ที่ใช้ในคู่มือนี้ เรียงตามตัวอักษรภาษาอังกฤษ
> คำที่มีคำอธิบายเพิ่มเติมจะระบุบทที่เกี่ยวข้อง

**วันที่จัดทำ:** 1 ธันวาคม 2026

---

## A.1 ศัพท์ทั่วไป

| ศัพท์ | ความหมาย | อ้างอิง |
|---|---|---|
| ASIC (Application-Specific Integrated Circuit) | ชิปที่ออกแบบมาเพื่องานเฉพาะทาง ไม่ใช่ชิปทั่วไป | บทที่ 1 |
| Back-pressure | แรงต้านกลับจากผู้รับ ทำให้ผู้ส่งต้องชะลอการส่งข้อมูล | บทที่ 7 |
| Black box | โมดูลที่มีเฉพาะส่วนติดต่อ (interface) แต่ไม่มีการทำงานภายใน ใช้เป็นจุดยึดกับโมดูลอื่น | บทที่ 10 |
| Bundled data | วิธีส่งข้อมูลข้าม clock domain โดยล็อกข้อมูลไว้นิ่งจนกว่าสัญญาณ handshake จะจบ | บทที่ 7 |
| Carry out | บิตที่บอกว่าผลบวกล้นความกว้างบิต | บทที่ 8 |
| Clock domain | ส่วนของวงจรที่ใช้นาฬิกาเดียวกันทั้งหมด | บทที่ 7 |
| Combinational logic | ตรรกะที่ผลลัพธ์ขึ้นกับอินพุตปัจจุบันเท่านั้น ไม่มีสถานะจำ | บทที่ 4 |
| CDC (Clock Domain Crossing) | การส่งสัญญาณหรือข้อมูลข้ามระหว่าง clock domain ต่าง ๆ | บทที่ 7 |
| Corner case | กรณีขอบเขตที่มักทำให้โค้ดพลาด เช่น ค่าสูงสุด ค่าต่ำสุด หรือค่าศูนย์ | บทที่ 11 |
| Deadlock | สถานการณ์ที่สองฝั่งรอกันและไม่มีใครเดินหน้า ทำให้ระบบค้าง | บทที่ 7 |
| Deferred constant | constant ที่ประกาศชนิดและชื่อไว้ใน package declaration แล้วกำหนดค่าใน package body | บทที่ 9 |
| Design unit | หน่วยของโค้ด VHDL ที่คอมไพล์แยกกันได้ เช่น entity, architecture, package, configuration | บทที่ 1 |
| Direct entity instantiation | การสร้าง instance ด้วย `entity work.name` ซึ่งตรวจชื่อพอร์ตได้ตั้งแต่ตอนคอมไพล์ | บทที่ 9 |
| Enumeration type (`enum`) | ชนิดข้อมูลที่กำหนดรายชื่อสมาชิกไว้ เช่นสถานะของ FSM | บทที่ 6 |
| Escape sequence | เครื่องหมายขีดกลาง (backslash) ใน string literal ที่ใช้แทนอักขระควบคุม | บทที่ 3 |
| Flip-flop | องค์ความจำ 1 บิตที่เก็บค่าจากขอบนาฬิกา | บทที่ 5 |
| Golden model | แบบจำลองอ้างอิงที่คำนวณผลลัพธ์ที่ถูกต้องโดยอิสระ เพื่อใช้เทียบกับ DUT | บทที่ 11 |
| Handshake | โปรโตคอลที่ทั้งสองฝั่งตกลงกันว่าใครส่งอะไรเมื่อใด | บทที่ 7 |
| Latch | ตรรกะที่จำค่าอินพุตเมื่ออินพุตเปลี่ยน มักเกิดจาก combinational process ที่กำหนดค่า output ไม่ครบ | บทที่ 4 |
| Library (VHDL) | กลุ่มของ design unit ที่คอมไพล์และอ้างอิงด้วยชื่อ เช่น `ieee`, `work` | บทที่ 1 |
| Metastability | สถานะของ flip-flop ที่ยังไม่นิ่ง ระหว่างเปลี่ยนจาก 0 เป็น 1 หรือกลับกัน | บทที่ 7 |
| Mux (multiplexer) | ตัวเลือกสัญญาณหนึ่งจากหลายทาง | บทที่ 4 |
| Netlist | รายการของ gate และสายเชื่อต่อระหว่างกันที่ได้จากการสังเคราะห์ | บทที่ 10 |
| Overriding | การกำหนดค่า generic หรือ parameter ใหม่ ณ ตำแหน่งที่สร้าง instance | บทที่ 9 |
| Padding | การเติมบิตศูนย์ทางด้านบนหรือด้านล่างเพื่อให้ความกว้างเท่ากัน | บทที่ 8 |
| Pipeline | โครงสร้างที่แบ่งการคำนวณออกเป็นหลายชั้น register เพื่อเพิ่มความถี่ | บทที่ 8 |
| Port map | การเชื่อมสัญญาณจริงเข้ากับพอร์ตของโมดูลที่กำลังสร้าง instance | บทที่ 9 |
| Procedural block | โครงสร้าง `process` ใน VHDL ที่บรรจุคำสั่งตามลำดับเวลา | บทที่ 4 |
| Read-first | พฤติกรรมของ RAM ที่อ่านและเขียน address เดียวกันในรอบเดียวกัน แล้วเอาต์พุตเป็นค่าเก่า | บทที่ 8 |
| Resize | การเปลี่ยนความกว้างของ `unsigned` หรือ `signed` โดยคงเครื่องหมายเดิม | บทที่ 8 |
| Resolution function | ฟังก์ชันที่กำหนดว่าจะได้ค่าสุดท้ายของ signal ที่มีหลาย driver เมื่อค่าของ driver ขัดกัน | บทที่ 2 |
| Safe state | สถานะของ FSM ที่ทำให้วงจรอยู่ในสถานะที่ปลอดภัยเมื่อเกิดความผิดพลาด | บทที่ 6 |
| Sensitivity list | รายการสัญญาณที่ process ต้องตื่นเมื่อมีการเปลี่ยนแปลง | บทที่ 4 |
| Sequential logic | ตรรกะที่มีสถานะจำ ผลลัพธ์ขึ้นกับอินพุตในอดีตด้วย | บทที่ 5 |
| Signal assignment (`<=`) | การกำหนดค่าที่มีผลหลังจาก process ปัจจุบันจบ (ซึ่งเป็นเหตุผลที่ process อ่านค่าเก่าเสมอ) | บทที่ 3 |
| Static sensitivity | sensitivity list ที่ระบุชัดเจน ต่างจาก `process (all)` ของ VHDL-2008 | บทที่ 4 |
| Synchronizer | วงจรที่ทำให้สัญญาณที่เปลี่ยนแบบไม่ต้องการ (asynchronous) เข้าสู่ clock domain ใหม่อย่างปลอดภัย | บทที่ 7 |
| Toggle synchronizer | กลไกส่งพัลส์ข้าม domain โดยสลับค่า toggle แล้วตรวจการเปลี่ยนแปลง | บทที่ 7 |
| Unconstrained array | array ที่ขอบเขตกำหนดในภายหลัง เช่น `std_logic_vector` | บทที่ 2 |
| Variable assignment (`:=`) | การกำหนดค่าที่มีผลทันทีภายใน process | บทที่ 3 |
| Vivado / Quartus | เครื่องมือสังเคราะห์สำหรับ FPGA ที่ใช้ในการเปรียบเทียบกับ ASIC | บทที่ 10 |
| Watchdog | กลไกใน testbench ที่ยิงข้อความ TIMEOUT เมื่อการทดสอบไม่จบในเวลาที่กำหนด | บทที่ 11 |

## A.2 ศัพท์เฉพาะของภาษา VHDL

| ศัพท์ | ความหมาย | อ้างอิง |
|---|---|---|
| Architecture | ส่วนที่บรรยายพฤติกรรมของ entity | บทที่ 1 |
| Attribute specification | ประกาศ attribute (เช่น `async_reg`) ให้กับ object ที่ประกาศไว้แล้ว | บทที่ 7 |
| Context clause | ส่วน `library` / `use` ที่ทำให้ชื่อใน namespace กลายเป็นชื่อที่อ้างอิงได้ | บทที่ 1 |
| Delta cycle | รอบการอัปเดตค่า signal ที่เกิดจากการ assign ใน process | บทที่ 5 |
| Enumeration literal | ชื่อสมาชิกของชนิดข้อมูลแบบ `enum` | บทที่ 6 |
| Generate statement | สร้างโครงสร้างซ้ำโดยไม่ต้องเขียนโค้ดซ้ำ | บทที่ 9 |
| Generic | พารามิเตอร์ของ entity ที่กำหนดค่าได้ตอนสร้าง instance | บทที่ 9 |
| Physical type | ชนิดข้อมูลที่แทนค่าทางกายภาพ เช่น `time` | บทที่ 2 |
| Port | ช่องทางการติดต่อของ entity | บทที่ 1 |
| Process | โครงสร้างที่รวมคำสั่งตามลำดับเวลาและมี sensitivity list | บทที่ 4 |
| Selected signal assignment | การกำหนดค่าแบบ `with ... select` | บทที่ 4 |
| Signal | วัตถุที่มี "ค่าเก่า" และเปลี่ยนแปลงตามเวลาที่กำหนด | บทที่ 2 |
| Signal parameter | พอร์ตโหมด `in` ที่เป็น signal ใช้กับ `buffer` ใน port mode แบบ `out` | บทที่ 2 |
| Subprogram | ฟังก์ชันหรือ procedure ที่ประกาศไว้ใน package, process หรือ architecture | บทที่ 9 |
| Type conversion | การแปลงค่าจากชนิดหนึ่งไปอีกชนิดหนึ่ง เช่น `unsigned(a)` | บทที่ 2 |
| Unconstrained element | สมาชิกของ array ที่ยังไม่มีขอบเขตจนกว่าจะถูกประกาศขณะสร้าง instance | บทที่ 2 |
| Variable | วัตถุที่มีค่าปัจจุบันเสมอ ไม่มี "ค่าเก่า" | บทที่ 2 |
| Wait statement | คำสั่งหยุด process จนกว่าจะมีเงื่อนไขที่รอไว้เป็นจริง | บทที่ 11 |
| `when others` | ทางเลือกใน `case` ที่ครอบคลุมค่าที่ไม่ได้ระบุไว้ รวมถึงค่าที่เป็น `'X'` | บทที่ 6 |

## A.3 ศัพท์เฉพาะของ Verilog

| ศัพท์ | ความหมาย | อ้างอิง |
|---|---|---|
| Blocking assignment (`=`) | การกำหนดค่าที่มีผลทันที ใช้ในบล็อก combinational | บทที่ 14 |
| Module | หน่วยของโค้ด Verilog ที่มีพอร์ตและพฤติกรรม | บทที่ 14 |
| Non-blocking assignment (`<=`) | การกำหนดค่าที่มีผลหลังจบบล็อก ใช้ในบล็อก clocked | บทที่ 14 |
| `wire` | ชนิดข้อมูลแบบ net ที่ไม่เก็บค่า | บทที่ 14 |
| `reg` | ชนิดข้อมูลแบบตัวแปรที่เก็บค่าได้ (ใน Verilog-2001) | บทที่ 14 |
| `logic` | ชนิดข้อมูลแบบตัวแปรที่เก็บค่าได้ (SystemVerilog) | บทที่ 14 |

---

## A.4 อักษรย่อที่ใช้ในคู่มือ

| อักษรย่อ | ความหมาย |
|---|---|
| CDC | Clock Domain Crossing |
| FSM | Finite State Machine |
| GHDL | GNU HDL — simulator และ synthesizer ที่ใช้ในคู่มือนี้ |
| HDL | Hardware Description Language |
| IEEE | Institute of Electrical and Electronics Engineers (ผู้กำหนดมาตรฐาน VHDL) |
| LRM | Language Reference Manual — เอกสารข้อกำหนดภาษา VHDL |
| RTL | Register Transfer Level — ระดับการอธิบายวงจรที่อยู่ระหว่างพฤติกรรมกับโครงสร้าง gate |
| STA | Static Timing Analysis |
| TB | Testbench |
| VCD | Value Change Dump — รูปแบบไฟล์ waveform |

---

**อ่านต่อ:** [ภาคผนวก B — แหล่งอ้างอิง](appendix-b-references.md)

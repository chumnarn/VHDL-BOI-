# Lab — VHDL RTL to Gate-Level Simulation

**ระยะเวลา 75–90 นาที** · **วงจร** Moore FSM ตรวจจับลำดับ 101 แบบซ้อนทับ · **ระดับภาษา** VHDL-2008

เมื่อเรียนจบ ผู้เรียนจะเขียน self-checking testbench ที่ใช้ร่วมกันได้ระหว่าง RTL และ gate netlist, สังเคราะห์ VHDL ผ่าน GHDL/Yosys, ตรวจผล GLS ใน Questa และอ่านหลักฐานสำหรับ post-layout timed GLS ได้

## ขั้นที่ 0 เตรียมเครื่องมือและไฟล์

ใช้ Bash บน Linux/WSL สำหรับ GNU Make, GHDL และ Yosys ส่วน Questa หรือ ModelSim ที่รองรับ mixed-language ต้องเรียก `vsim` จาก shell เดียวกันหากใช้เป้าหมาย Make ของ Lab หากใช้ Questa/ModelSim บน Windows แยกจาก WSL ให้เปิดโปรแกรมจากโฟลเดอร์ที่เข้าถึงไฟล์ Lab ได้ และใช้คำสั่ง GUI ในขั้นที่ 4

```bash
ghdl --version
yosys -V
make --version
vsim -version
```

| ไฟล์ | หน้าที่ |
|---|---|
| `seq_det_101.vhd` | DUT มี state register, next-state logic และ Moore output |
| `tb_seq_det_101.vhd` | ตัวสร้าง clock, stimulus และ scoreboard ภาษา VHDL |
| `synth.ys` | สังเคราะห์เป็น generic gates และส่งออก cell simulation models |
| `questa.do` | รัน RTL หรือ GLS ใน library ที่แยกกัน |
| `Makefile` | เรียกขั้นตอนผ่าน `make rtl`, `make synth`, `make questa-rtl`, `make questa-gls` |

## ขั้นที่ 1 อ่านและวิเคราะห์วงจร

DUT sample `din` ที่ขอบขาขึ้นของ `clk` และใช้ synchronous active-low reset เมื่อ `rst_n='0'` ที่ขอบขาขึ้น FSM ไปที่ `idle` และ `detected` กลับเป็น 0

| สถานะปัจจุบัน | din=0 → สถานะถัดไป | din=1 → สถานะถัดไป | detected |
|---|---|---|---:|
| idle | idle | seen_1 | 0 |
| seen_1 | seen_10 | seen_1 | 0 |
| seen_10 | idle | found | 0 |
| found | seen_10 | seen_1 | 1 |

ในสถานะ `found` บิต 1 ตัวท้ายของ match ยังเป็น prefix ของ match ถัดไป เมื่อรับ 0 ต่อจึงเข้าสู่ `seen_10` และเมื่อรับ 1 อีกครั้งจะพบ match ที่สอง

| ลำดับบิต | 1 | 2 | 3 | 4 | 5 |
|---|---:|---:|---:|---:|---:|
| din | 1 | 0 | 1 | 0 | 1 |
| State หลังขอบขาขึ้น | seen_1 | seen_10 | found | seen_10 | found |
| detected ที่จุด sample | 0 | 0 | 1 | 0 | 1 |

## ขั้นที่ 2 รัน RTL simulation

```bash
make rtl
gtkwave build/ghdl/rtl.vcd
```

หรือรัน RTL ด้วย Questa/ModelSim ผ่าน `make questa-rtl` จากนั้นเปิด `build/questa-rtl/vsim.wlf` ผ่าน GUI เพื่อดู waveform ที่บันทึกไว้

1. เพิ่ม `clk`, `rst_n`, `din` และ `detected` ใน waveform
2. ดูขอบขาลงที่ testbench เปลี่ยน `din` และขอบขาขึ้นถัดไปที่ DUT รับข้อมูล
3. อ่าน `detected` ที่ 4 ns หลังขอบขาขึ้น ภายใต้คาบ 10 ns จุดตรวจนี้เว้นเวลาให้เอาต์พุตตั้งตัวและอยู่ก่อนขอบขาลงถัดไป
4. มองหา `PASS checks=1031` จาก 7 รอบ directed test และ 128 ลำดับขนาด 7 บิต ลำดับละ 8 รอบรวม reset

Scoreboard เลื่อน `din` เข้า history 3 บิตแล้วเทียบกับ `101` โดยไม่อ่าน state ภายใน DUT ค่า `X`, `U` หรือ `Z` ที่ตรวจพบจะทำให้การเทียบกับค่าที่คาดเป็น 0 หรือ 1 ล้มเหลว

## ขั้นที่ 3 สังเคราะห์ VHDL เป็น gate-level netlist

```bash
make synth
```

1. GHDL วิเคราะห์และ elaborate VHDL แล้วส่งออก Verilog ไปที่ `build/seq_det_101_elab.v`
2. Yosys optimize และ map ลง generic logic cells ตรวจ cell inventory ใน `build/synthesis.log`
3. เปิด `build/seq_det_101_mapped.v` หา flip-flop และ combinational gates ชื่อและจำนวนเซลล์อาจเปลี่ยนตามเวอร์ชันและผล optimization
4. `build/generic_cells.v` คือ simulation models สำหรับเซลล์ generic ที่ netlist ใช้

แบบฝึกหัดนี้ใช้ generic cells เพื่อให้ทำขั้นตอน functional GLS ได้โดยไม่ต้องเตรียม PDK เมื่อนำไปใช้กับ ASIC PDK ให้ใช้ mapped netlist และ simulation models ของ standard-cell library ที่เลือกใน implementation run

## ขั้นที่ 4 รัน Gate-Level Simulation ด้วย VHDL testbench เดิม

```bash
make questa-gls
```

สคริปต์สร้าง working library สำหรับ GLS ในโฟลเดอร์แยก แล้ว compile Verilog cell models, Verilog netlist และ VHDL testbench เข้า library เดียวกัน เมื่อ elaboration ผูก `dut : seq_det_101` เข้ากับ Verilog module ให้ตรวจชื่อ module และพอร์ตที่ตรงกับ VHDL component ทุกพอร์ตใช้ชื่อแบบตัวพิมพ์เล็กเหมือนกัน

สำหรับ GUI ให้เปิด Questa/ModelSim Transcript จากโฟลเดอร์ Lab หลังรัน `make synth` และใช้คำสั่งต่อไปนี้

```tcl
vlib gls_gui
vlog -work gls_gui build/generic_cells.v build/seq_det_101_mapped.v
vcom -2008 -work gls_gui tb_seq_det_101.vhd
vsim -t 1ps -voptargs=+acc gls_gui.tb_seq_det_101
add wave sim:/tb_seq_det_101/clk sim:/tb_seq_det_101/rst_n
add wave sim:/tb_seq_det_101/din sim:/tb_seq_det_101/detected
run -all
```

ผลที่คาดคือ `PASS checks=1031` และลำดับเอาต์พุตเหมือน RTL ที่จุดตรวจ หาก instance unbound ให้ตรวจว่า simulator edition รองรับ mixed-language, compile netlist เข้า library เดียวกับ testbench และไม่มี RTL entity ของ DUT ปะปนอยู่ใน library GLS

## ขั้นที่ 5 ทดสอบว่า scoreboard จับความผิดพลาดได้

1. สำรอง `seq_det_101.vhd` แล้วแยก case branch `when seen_1 | found =>` เป็น `when seen_1 =>` และ `when found =>`
2. คง logic ของ `seen_1` ไว้ สำหรับ `found` ให้ไป `seen_1` เมื่อรับ 1 และจงใจให้ไป `idle` เมื่อรับ 0
3. รัน `make rtl` และ `make questa-gls` ผลที่คาดคือทั้งคู่ FAIL ที่ check 6 เพราะการตรวจพบครั้งที่สองของ `10101` หายไป
4. คืน RTL ต้นฉบับ และรันอีกครั้งเพื่อเก็บ PASS log กับ FAIL log คู่กัน

## ขั้นที่ 6 บทเสริม Post-layout Timed GLS

ใช้ post-route netlist, SDF และ timing cell models ของ PDK เช่น IHP SG13G2 จาก implementation revision เดียวกัน ตรวจว่า top-level ports ตรงกับ testbench หาก flow เพิ่ม pad หรือ power pins ให้ปรับการเชื่อมต่อหรือเพิ่ม wrapper ตาม netlist จริง แล้ว compile เข้า working library ใหม่ ตัวอย่างนี้สมมติว่า netlist ใช้ top และพอร์ตชุดเดิม และ SDF อ้าง hierarchy ภายใน DUT

```tcl
vlib timed_work
vlog -work timed_work timing_cells.v design_postroute.v
vcom -2008 -work timed_work tb_seq_det_101.vhd
vsim -t 1ps -sdfmax /tb_seq_det_101/dut=design_postroute.sdf timed_work.tb_seq_det_101
run -all
```

- เลือก `-sdfmin`, `-sdftyp` หรือ `-sdfmax` ตามวิธีสร้าง SDF และกรณีที่ตั้งใจทดสอบ
- ตรวจ annotation log สำหรับ instance, delay arcs และ timing checks ก่อนตีความผล PASS หากโมเดล macro อยู่แยก ให้ compile โมเดลนั้นร่วมด้วย
- หากเอาต์พุตตั้งตัวหลังจุดตรวจ 4 ns ให้เทียบกับ timing budget ที่ interface ก่อนเปลี่ยนจุด sample
- เมื่อพบ violation ให้เทียบ instance, endpoint, clock edge และ corner กับ STA หาก STA มี slack ติดลบแต่ GLS ผ่าน ให้ตรวจ waveform ว่ามี transition ที่ endpoint ในช่วงตรวจจริงหรือไม่

## หลักฐานที่ส่ง

1. Waveform RTL แสดง `10101` พร้อมจุดตรวจพบ 2 ครั้ง
2. Cell inventory หลัง synthesis พร้อมตัวอย่างเชื่อมต่อหนึ่ง gate และหนึ่ง flip-flop
3. Functional GLS log และ waveform เปรียบเทียบกับ RTL ที่จุด sample
4. FAIL log จากการแก้ transition และคำอธิบายว่าเหตุใด check 6 จึงล้มเหลว
5. สำหรับผู้ที่ทำขั้นที่ 6 ให้ส่ง SDF annotation log และ STA path report ของ corner ที่ศึกษา

สถานะชุดแจกจ่าย ตรวจแผนคำสั่งของ Make และทวน state transition กับเวกเตอร์ Lab แล้ว การรันผ่าน GHDL, Yosys และ Questa/ModelSim ยังไม่ได้ยืนยันในสภาพแวดล้อมที่จัดทำชุดนี้

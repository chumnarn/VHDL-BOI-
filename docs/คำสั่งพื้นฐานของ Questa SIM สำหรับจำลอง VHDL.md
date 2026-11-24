# คำสั่งพื้นฐานของ Questa SIM สำหรับจำลอง VHDL

ใน **Questa Transcript** ลำดับการทำงานทั่วไปคือ **สร้างไลบรารี → คอมไพล์ DUT และ testbench → โหลด testbench → เพิ่มสัญญาณใน Wave → รัน simulation**

## 1. คำสั่งที่ใช้บ่อย

| คำสั่ง | หน้าที่ |
|---|---|
| `pwd` | แสดงไดเรกทอรีปัจจุบัน |
| `cd {C:/FPGA/Lab 1}` | เปลี่ยนไปยังไดเรกทอรีที่เก็บไฟล์ ใช้ `{}` ครอบพาธที่มีช่องว่าง |
| `vlib work` | สร้างไลบรารี `work` สำหรับเก็บผลคอมไพล์ ทำครั้งแรกในไดเรกทอรีของ Lab |
| `vmap work ./work` | กำหนดให้ชื่อไลบรารี `work` ชี้ไปยังไดเรกทอรี `./work` หากต้องกำหนด mapping เอง |
| `vcom -2008 -work work and_gate.vhd` | คอมไพล์ไฟล์ด้วยมาตรฐาน VHDL-2008 |
| `vsim work.tb_lab1` | โหลด entity `tb_lab1` จากไลบรารี `work` เพื่อเริ่ม simulation |
| `view wave` | เปิดหน้าต่าง Wave |
| `add wave sim:/tb_lab1/*` | เพิ่มสัญญาณระดับบนของ testbench |
| `add wave -r sim:/tb_lab1/*` | เพิ่มสัญญาณใน testbench และ instance ภายในทุกระดับ |
| `run 100 ns` | เดินเวลาจำลองต่ออีก 100 ns จากเวลาปัจจุบัน |
| `run -all` | รันจน simulation หยุดหรือไม่มี event เหลือ |
| `wave zoom full` | ขยายมุมมองให้เห็นช่วงเวลาทั้งหมดที่บันทึกไว้ใน Wave |
| `examine sim:/tb_lab1/a` | อ่านค่าปัจจุบันของสัญญาณ `a` หากมีสัญญาณชื่อนี้ใน testbench |
| `restart -f` | เริ่ม simulation ที่โหลดอยู่ใหม่จากเวลา 0 โดยข้ามหน้าต่างยืนยัน |
| `quit -sim` | จบ simulation ปัจจุบันและคงหน้าต่าง Questa ไว้ |
| `do run_lab1.do` | รันชุดคำสั่งจากไฟล์ `.do` |

## 2. ตัวอย่าง `run_lab1.do` สำหรับ Lab 1

สคริปต์นี้สมมติว่าไฟล์ VHDL ทั้งห้าไฟล์อยู่ในไดเรกทอรีปัจจุบัน และชื่อ entity ของ testbench คือ `tb_lab1`

```tcl
# Create the working library on the first run
if {![file isdirectory work]} {
    vlib work
}

# Compile the DUTs before the testbench
vcom -2008 -work work and_gate.vhd
vcom -2008 -work work or_gate.vhd
vcom -2008 -work work mux2x1.vhd
vcom -2008 -work work dec2x4.vhd
vcom -2008 -work work tb_lab1.vhd

# Load the testbench and retain access to internal signals
vsim -voptargs=+acc work.tb_lab1

# Open Wave and add signals before running
view wave
add wave -r sim:/tb_lab1/*

run 1 us
wave zoom full
```

เปิด Questa SIM แล้วพิมพ์ใน Transcript

```tcl
cd {C:/FPGA/Lab 1}
do run_lab1.do
```

## 3. เลือกคำสั่งตามสิ่งที่ต้องการทำ

- **รันต่อเพื่อดูผลช่วงถัดไป** ใช้ `run 100 ns` เช่น จากเวลา `1 us` จะไปถึง `1.1 us`
- **รันใหม่ด้วยโค้ดเดิม** ใช้ `restart -f` แล้วตามด้วย `run 1 us`
- **แก้ไฟล์ VHDL แล้วจำลองใหม่** ใช้ `quit -sim` แล้วตามด้วย `do run_lab1.do` เพื่อคอมไพล์และโหลดโค้ดที่แก้ไขแล้ว
- **รัน testbench ที่สร้าง clock ตลอดเวลา** ใช้ `run 1 us` เพื่อกำหนดเวลาสิ้นสุด หรือให้ testbench เรียก `std.env.finish` เมื่อทดสอบครบ เพื่อให้ใช้ `run -all` ได้

`work.tb_lab1` คือชื่อ design unit ที่ใช้ตอน **โหลด testbench** ส่วน `sim:/tb_lab1/*` คือพาธใน simulation hierarchy ที่ใช้ตอน **เลือกสัญญาณมาแสดง** ครับ
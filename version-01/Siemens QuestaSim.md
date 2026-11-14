คู่มือการใช้งาน **Siemens QuestaSim (Questa Advanced Simulator)** ครอบคลุมตั้งแต่สถาปัตยกรรมพื้นฐาน คำสั่ง CLI/TCL การวิเคราะห์ Waveform การเปิดใช้งาน Code Coverage ตลอดจนการทำสคริปต์อัตโนมัติสำหรับ Regression Test

---

### 1. สถาปัตยกรรมและกระบวนการทำงานหลัก (QuestaSim Flow)

QuestaSim ใช้กระบวนการจำลองการทำงานแบบ **3-Step Flow** (Compile $\rightarrow$ Optimize/Elaborate $\rightarrow$ Simulate) ซึ่งออกแบบมาเพื่อเพิ่มความเร็วในการประมวลผลและการใช้หน่วยความจำอย่างมีประสิทธิภาพ:

```
[VHDL / Verilog / SystemVerilog Source Files]
                      │
                      ▼
 1. Compile       (vcom / vlog)  ──> จัดเก็บลงใน Work Library
                      │
                      ▼
 2. Optimize      (vopt)         ──> รวมระดับ Hierarchy, ปรับแต่ง Data Path, กำหนด Visibility
                      │
                      ▼
 3. Simulate      (vsim)         ──> รันเอนจินจำลอง, บันทึก Waveform (WLF) และ Coverage (UCDB)

```

---

### 2. ตารางคำสั่งพื้นฐาน (Essential CLI & TCL Commands)

| คำสั่ง | พารามิเตอร์หลัก | หน้าที่การทำงาน |
| --- | --- | --- |
| `vlib <dir>` | `<lib_name>` | สร้างโฟลเดอร์สำหรับเก็บผลการคอมไพล์ไลบรารี |
| `vmap <name> <dir>` | `<logical_name> <path>` | จับคู่ (Map) ชื่อไลบรารีเชิงตรรกะเข้ากับโฟลเดอร์จริง |
| `vcom` | `-93`, `-2008`, `-work <lib>` | คอมไพล์ไฟล์ซอร์สโค้ดภาษา **VHDL** |
| `vlog` | `-sv`, `-timescale "1ns/1ps"` | คอมไพล์ไฟล์ภาษา **Verilog / SystemVerilog** |
| `vopt` | `+acc`, `-o <opt_name>` | รวมและปรับแต่งโครงสร้าง (Elaboration & Optimization) |
| `vsim` | `-gui`, `-c`, `-coverage`, `-t 1ps` | เรียกเอนจินจำลองการทำงาน (GUI หรือ Batch Mode) |
| `add wave` | `-r /*`, `-radix hex` | เพิ่มสัญญาณลงในหน้าต่างแสดงผลคลื่นสัญญาณ |
| `run` | `<time>`, `-all` | ดำเนินการจำลองเวลาตามที่ระบุ หรือรันจนเจอ `$finish` / `wait` |
| `vcover report` | `-html`, `-summary` | สกัดข้อมูลความครอบคลุมจากการทดสอบเป็นรายงาน |

---

### 3. ตัวอย่างการทดลองจริงทีละขั้นตอน (Hands-on Walkthrough)

ตัวอย่างนี้จำลองการทำงานของโมดูล **4-bit Synchronous Up-Counter with Reset & Enable**

#### โค้ด RTL: `counter.sv`

```systemverilog
module counter (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       en,
    output logic [3:0] count
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 4'b0000;
        end else if (en) begin
            count <= count + 1'b1;
        end
    end

endmodule

```

#### โค้ด Testbench: `tb_counter.sv`

```systemverilog
`timescale 1ns/1ps

module tb_counter;
    logic       clk;
    logic       rst_n;
    logic       en;
    logic [3:0] count;

    // ติดตั้ง Device Under Test (DUT)
    counter dut (.*);

    // กำเนิดสัญญาณนาฬิกา 100 MHz (Period = 10 ns)
    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;
        en    = 0;

        // ปลด Reset
        #20 rst_n = 1;

        // นับต่อเนื่อง 5 คาบ
        #10 en = 1;
        #50;

        // หยุดนับชั่วคราว
        en = 0;
        #30;

        // กลับมานับต่อจน Overflow
        en = 1;
        #120;

        $display("Simulation Finished Successfully at %0t ps", $time);
        $stop;
    end
endmodule

```

---

### 4. การรันผ่านสคริปต์ QuestaSim TCL

สร้างไฟล์สคริปต์ชื่อ `simulate.do` ในไดเรกทอรีทำงาน:

```tcl
# 1. จัดเตรียมสภาพแวดล้อมและ Library
if [file exists work] {
    vdel -lib work -all
}
vlib work
vmap work work

# 2. คอมไพล์ไฟล์ RTL และ Testbench
vlog -sv -work work counter.sv
vlog -sv -work work tb_counter.sv

# 3. ขั้นตอน Elaboration และ Optimize (เปิด Visibility สำหรับสัญญาณเพื่อการ Debug)
vopt work.tb_counter +acc -o top_opt

# 4. เรียกใช้เอนจินจำลองการทำงาน
vsim -t 1ps work.top_opt

# 5. จัดระเบียบสัญญาณในหน้าต่าง Waveform
add wave -divider "Clock & Reset"
add wave -format logic /tb_counter/clk
add wave -format logic /tb_counter/rst_n
add wave -divider "Control & Output"
add wave -format logic /tb_counter/en
add wave -format literal -radix unsigned /tb_counter/count

# 6. ตั้งค่าหน้าต่างแสดงผลและเริ่มรัน
configure wave -namecolwidth 180
configure wave -valuecolwidth 100
configure wave -justifyvalue right
configure wave -signalnamestyle 1

run -all
wave zoom full

```

คำสั่งเปิดรันในโหมด GUI ผ่าน Terminal:

```bash
vsim -do simulate.do

```

---

### 5. การใช้งาน Code Coverage และการสร้างรายงาน

QuestaSim รองรับการตรวจวัดความครอบคลุมทั้ง **Statement (b)**, **Branch (c)**, **Condition (e)**, **Expression (s)**, **Toggle (t)** และ **FSM (f)**

#### สคริปต์คอมไพล์และเก็บค่า Coverage: `run_cov.do`

```tcl
vlib work
vmap work work

# เปิดใช้งาน Coverage Flag ขณะคอมไพล์
vlog -sv +cover=bcst -work work counter.sv
vlog -sv -work work tb_counter.sv

# Optimize พร้อมเก็บข้อมูล Coverage
vopt work.tb_counter +cover=bcst +acc -o top_cov_opt

# รัน Simulation ในโหมด Coverage
vsim -coverage work.top_cov_opt

run -all

# บันทึกฐานข้อมูล Coverage ในรูปไฟล์ .ucdb
coverage save counter_cov.ucdb

# สกัดรายงานสรุปทั้งแบบข้อความและเว็บเพจ HTML
vcover report -summary counter_cov.ucdb
vcover report -html -output html_cov_report counter_cov.ucdb

```

คำสั่งตรวจสอบผล Coverage ทางเว็บบราวเซอร์:

```bash
firefox html_cov_report/index.html &

```

---

### 6. การดีบัก Waveform ขั้นสูงใน Questa GUI

* **การตั้งค่า Radix:** คลิกขวาที่สัญญาณบัสในแถบ Waveform เลือก `Radix` $\rightarrow$ `Unsigned`, `Hexadecimal`, หรือ `ASCII`
* **การใช้งาน Cursor:**
* คลิกซ้ายบนแถบเวลาเพื่อสร้าง **Cursor 1**
* กดปุ่มไอคอน `Add Cursor` (แถบเครื่องมือด้านบน) เพื่อสร้าง Cursor ที่สองสำหรับวัดช่วงเวลาห่าง ($\Delta t$) และความถี่ ($1/\Delta t$)


* **Signal Tracing (Dataflow Window):** ดับเบิลคลิกที่สัญญาณใดๆ หรือกด `Ctrl+W` เพื่อส่งไปยังหน้าต่าง Dataflow ช่วยไล่เส้นทางจาก Output ย้อนกลับไปหาต้นทาง (Driver tracing)
* **Log All Signals:** หากต้องการดูสัญญาณย่อยภายในลำดับชั้นโดยไม่ต้องเติม Wave ทีละเส้น ใช้คำสั่ง:
```tcl
log -r /*

```



---

### 7. การทำ Automation สำหรับ CI/CD (Batch Mode & Makefile)

สำหรับการทดสอบในระบบ Continuous Integration ไม่จำเป็นต้องเปิดหน้าต่าง GUI ให้รันผ่านโหมดคอมมานด์ไลน์ (`-c`):

#### ตัวอย่าง `Makefile`

```makefile
TB       = tb_counter
DUT      = counter.sv
TB_SRC   = tb_counter.sv
UCDB_OUT = coverage_result.ucdb

all: clean compile opt sim report

compile:
	vlib work
	vmap work work
	vlog -sv +cover=bcst $(DUT)
	vlog -sv $(TB_SRC)

opt:
	vopt $(TB) +cover=bcst +acc -o top_opt

sim:
	vsim -c top_opt -coverage -do "run -all; coverage save $(UCDB_OUT); quit -f"

report:
	vcover report -summary $(UCDB_OUT)

gui:
	vsim -gui top_opt -do "add wave -r /*; run -all;"

clean:
	rm -rf work transcript *.wlf $(UCDB_OUT) html_cov_report

```

* รันแบบ Batch: `make`
* รันพร้อมเปิด GUI: `make gui`

---

### 8. แนวทางแก้ไขปัญหาที่พบบ่อย (Troubleshooting & Pro Tips)

* **สัญญาณแสดงสถานะ `HiZ` หรือ `X` (Unknown):** ตรวจสอบพฤติกรรมของขารีเซต หาก Flip-Flop ไม่ได้รับสัญญาณรีเซต ค่าเริ่มต้นในแบบจำลองฮาร์ดแวร์จะเป็น `X` ส่งผลให้ลอจิกถัดไปกลายเป็น `X` ทั้งหมด (X-Propagation)
* **เกิดข้อผิดพลาด License Checkout Failed:**
* ตรวจสอบตัวแปรระบบ: `echo $MGLS_LICENSE_FILE` หรือ `echo $LM_LICENSE_FILE`
* ตรวจสอบสถานะการเชื่อมต่อพอร์ตเซิร์ฟเวอร์ไลเซนส์ด้วย: `lmutil lmdiag`


* **การเพิ่มความเร็วในการรัน (Performance Tuning):**
* หลีกเลี่ยงการใช้ `+acc` ทั้งระบบในโปรเจกต์ขนาดใหญ่ เพราะทำให้เอนจิน Optimize ลดประสิทธิภาพลง ให้ระบุเฉพาะเจาะจง เช่น `+acc=rnb` (Registers, Nets, Variables) หรือกำหนดเจาะจงเฉพาะระดับโมดูล:
```tcl
vopt work.tb_counter +acc=dut -o top_opt

```
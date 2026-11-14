# impl.sdc - constraints สำหรับขั้นตอน Place & Route (pre-CTS)
#
# ใช้กับ OpenROAD ผ่าน OpenSTA

create_clock -name clk -period 10 [get_ports clk]

# input/output delay (ตัวอย่าง: เนื่องจากยังไม่มีข้อมูลระบบภายนอกจริง
# จึงตั้งเป็น 0 ns แล้วค่อยปรับตามสเปกของระบบจริง)
set_input_delay 0 -clock clk [all_inputs -no_clocks]
set_output_delay 0 -clock clk [all_outputs]

# reset เป็น asynchronous control -> ไม่ต้องตรวจ timing
set_false_path -from [get_ports rst]

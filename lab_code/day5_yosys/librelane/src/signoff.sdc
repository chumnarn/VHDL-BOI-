# signoff.sdc - constraints สำหรับขั้นตอน sign-off (post-route, multi-corner)
#
# ใช้กับ OpenSTA หลัง routing เสร็จ เพื่อยืนยัน timing ที่ทุก corner
# เพิ่มเติมระยะเวลาที่สัญญาณต้องเดินทางถึงขาเข้า/ออกของชิป
# (ในระบบจริงค่านี้มาจากสเปกของระบบภายนอกที่วงจรนี้ไปอยู่)

create_clock -name clk -period 10 [get_ports clk]

set_input_delay 0 -clock clk [all_inputs -no_clocks]
set_output_delay 0 -clock clk [all_outputs]

set_false_path -from [get_ports rst]

# signoff.sdc - constraints สำหรับขั้นตอน Sign-off (post-route, extracted RC)
#
# ใช้กับ OpenROAD หลัง Detailed Routing และ RC extraction

create_clock -name clk -period 10 [get_ports clk]
set_input_delay 0 -clock clk [all_inputs -no_clocks]
set_output_delay 0 -clock clk [all_outputs]
set_false_path -from [get_ports rst]

# ปิดการตรวจ hold ของ reset (เป็น asynchronous)
set_false_path -from [get_ports rst] -to [get_ports rst]

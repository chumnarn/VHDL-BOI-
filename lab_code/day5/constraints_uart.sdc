# constraints_uart.sdc
# SDC for UART TX synthesis
# 100 MHz system clock

create_clock -name sys_clk -period 10.0 -waveform {0 5} [get_ports clk]

set_input_delay  -clock sys_clk 2.0 -max [get_ports {din din_vld rst}]
set_input_delay  -clock sys_clk 1.0 -min [get_ports {din din_vld rst}]

set_output_delay -clock sys_clk 2.0 -max [get_ports {tx din_rdy}]
set_output_delay -clock sys_clk 1.0 -min [get_ports {tx din_rdy}]

set_false_path -from [get_ports rst]

set_driving_cell -lib_cell INVX1 -pin Y [get_ports {din din_vld rst}]
set_load 0.05 [get_ports {tx din_rdy}]

set_operating_conditions -process typical -voltage 1.0 -temp 25
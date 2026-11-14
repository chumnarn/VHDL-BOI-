# constraints.sdc
# SDC constraints for Precision RTL synthesis
# Assumes 100 MHz target clock

# Clock definition
create_clock -name sys_clk -period 10.0 -waveform {0 5} [get_ports clk]

# Input delays (relative to clock edge)
set_input_delay  -clock sys_clk 2.0 -max [get_ports {a b cin}]
set_input_delay  -clock sys_clk 1.0 -min [get_ports {a b cin}]

# Output delays
set_output_delay -clock sys_clk 2.0 -max [get_ports {sum cout}]
set_output_delay -clock sys_clk 1.0 -min [get_ports {sum cout}]

# Reset is asynchronous - ignore during timing
set_false_path -from [get_ports rst]

# Drive strength and load
set_driving_cell -lib_cell INVX1 -pin Y [get_ports {a b cin}]
set_load 0.05 [get_ports {sum cout}]

# Operating conditions (PVT corner)
set_operating_conditions -process typical -voltage 1.0 -temp 25
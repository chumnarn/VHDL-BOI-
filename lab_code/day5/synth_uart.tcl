# synth_uart.tcl
# Precision RTL batch script for UART TX project
# Usage: precision -shell -file synth_uart.tcl

set tech_lib    "/tech/gscl45nm"     ;# Adjust to your library path
set design_name "uart_top"
set rtl_dir     "."

if { [file exists work_$design_name] } {
    file delete -force work_$design_name
}
new_project -name $design_name -folder work_$design_name \
            -technology "$tech_lib"

add_source -type vhdl -work work -library work "$rtl_dir/baud_gen.vhd"
add_source -type vhdl -work work -library work "$rtl_dir/uart_tx.vhd"
add_source -type vhdl -work work -library work "$rtl_dir/uart_top.vhd"

add_constraint_file "$rtl_dir/constraints_uart.sdc"

set_top_module uart_top

elaborate

# Synthesize with optimization
compile -incremental_mapping -retiming

file mkdir reports
report_area   -file reports/area_uart.rpt -append
report_timing -delay max -num_paths 50 -file reports/timing_max_uart.rpt -append
report_timing -delay min -num_paths 50 -file reports/timing_min_uart.rpt -append
report_power  -file reports/power_uart.rpt  -append

file mkdir netlist
export_netlist -format verilog -output netlist/uart_top_netlist.v

puts "UART TX synthesis finished. See reports/ and netlist/"
exit
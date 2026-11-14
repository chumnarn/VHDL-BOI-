# synth.tcl
# Precision RTL batch synthesis script
# Usage: precision -shell -file synth.tcl

# ------- Setup -------
set tech_lib    "/tech/gscl45nm"     ;# Adjust to your technology library path
set design_name "top"
set rtl_dir     "."

# Create new project
if { [file exists work_$design_name] } {
    file delete -force work_$design_name
}
new_project -name $design_name -folder work_$design_name \
            -technology "$tech_lib"

# ------- Add Sources -------
# Note: full_adder_struct contains several gate definitions.
# Add it first so other files can use it as a component.
add_source -type vhdl -work work -library work "$rtl_dir/full_adder_struct.vhd"
add_source -type vhdl -work work -library work "$rtl_dir/adder8.vhd"
add_source -type vhdl -work work -library work "$rtl_dir/adder8_pipelined.vhd"
add_source -type vhdl -work work -library work "$rtl_dir/add_sub_shared.vhd"
add_source -type vhdl -work work -library work "$rtl_dir/top.vhd"

# ------- Constraints -------
add_constraint_file "$rtl_dir/constraints.sdc"

# ------- Set top module -------
set_top_module top

# ------- Elaborate (optional) -------
elaborate

# ------- Synthesize -------
# -retiming enables RTL retiming optimization
# -incremental_mapping does not re-elaborate if nothing changed
compile -incremental_mapping -retiming

# ------- Reports -------
file mkdir reports
report_area   -file reports/area.rpt   -append
report_timing -delay max -num_paths 50 -file reports/timing_max.rpt -append
report_timing -delay min -num_paths 50 -file reports/timing_min.rpt -append
report_power  -file reports/power.rpt  -append
report_constraints -file reports/constraints.rpt -append

# ------- Export netlist -------
file mkdir netlist
export_netlist -format verilog -output netlist/top_netlist.v

# ------- Done -------
puts "Synthesis finished. See reports/ and netlist/"
exit
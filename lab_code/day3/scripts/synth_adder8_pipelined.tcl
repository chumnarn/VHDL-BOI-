# ===========================================================================
# scripts/synth_adder8_pipelined.tcl
# Precision RTL Synthesis - batch script for `adder8_pipelined`  (Lab 3A)
#
#     precision -shell -file scripts/synth_adder8_pipelined.tcl
#
# This is the design to use for the "fix the timing violation" exercise:
# it has a real clock (sys_clk, 100 MHz) and a synchronous reset.
# ===========================================================================

set script_dir [file dirname [file normalize [info script]]]
set lab_dir    [file dirname $script_dir]

# >>> CHANGE THIS to the technology library of your organisation <<<
set tech_lib "gscl45nm"

set design_name "adder8_pipelined"
set project_dir "$lab_dir/work_$design_name"

if {[file exists $project_dir]} {
    file delete -force $project_dir
}
new_project -name $design_name -folder $project_dir -technology $tech_lib

add_source -type vhdl -work work -library work "$lab_dir/rtl/adder8_pipelined.vhd"

add_constraint_file "$lab_dir/sdc/adder8_pipelined.sdc"

set_top_module $design_name

elaborate

# -retiming is what makes this design interesting: the tool is allowed to
# move the pipeline register across the adder to balance the two stages.
compile -incremental_mapping -retiming

file mkdir "$lab_dir/reports"
report_area        -file "$lab_dir/reports/area_adder8_pipelined.rpt"
report_timing      -delay max -num_paths 50 -file "$lab_dir/reports/timing_max_adder8_pipelined.rpt"
report_timing      -delay min -num_paths 50 -file "$lab_dir/reports/timing_min_adder8_pipelined.rpt"
report_power       -file "$lab_dir/reports/power_adder8_pipelined.rpt"
report_constraints -file "$lab_dir/reports/constraints_adder8_pipelined.rpt"

file mkdir "$lab_dir/netlist"
export_netlist -format verilog -output "$lab_dir/netlist/${design_name}_netlist.v"
write_sdf -output "$lab_dir/netlist/${design_name}.sdf"

puts "Precision RTL synthesis of '$design_name' finished."
exit

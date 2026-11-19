# ===========================================================================
# scripts/synth_add_sub_shared.tcl
# Precision RTL Synthesis - batch script for `add_sub_shared`  (Lab 3A)
#
#     precision -shell -file scripts/synth_add_sub_shared.tcl
#
# Use it for the RESOURCE SHARING exercise: compare the area of this
# design (ONE adder that can add or subtract) against a design that uses
# two separate adders.
# ===========================================================================

set script_dir [file dirname [file normalize [info script]]]
set lab_dir    [file dirname $script_dir]

# >>> CHANGE THIS to the technology library of your organisation <<<
set tech_lib "gscl45nm"

set design_name "add_sub_shared"
set project_dir "$lab_dir/work_$design_name"

if {[file exists $project_dir]} {
    file delete -force $project_dir
}
new_project -name $design_name -folder $project_dir -technology $tech_lib

add_source -type vhdl -work work -library work "$lab_dir/rtl/add_sub_shared.vhd"

add_constraint_file "$lab_dir/sdc/add_sub_shared.sdc"

set_top_module $design_name

elaborate
compile -incremental_mapping

file mkdir "$lab_dir/reports"
report_area        -file "$lab_dir/reports/area_add_sub_shared.rpt"
report_timing      -delay max -num_paths 50 -file "$lab_dir/reports/timing_max_add_sub_shared.rpt"
report_power       -file "$lab_dir/reports/power_add_sub_shared.rpt"

file mkdir "$lab_dir/netlist"
export_netlist -format verilog -output "$lab_dir/netlist/${design_name}_netlist.v"
write_sdf -output "$lab_dir/netlist/${design_name}.sdf"

puts "Precision RTL synthesis of '$design_name' finished."
exit

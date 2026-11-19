# ===========================================================================
# scripts/synth_adder8.tcl
# Precision RTL Synthesis - batch script for the PURELY COMBINATIONAL
# entity `adder8`  (Lab 3A)
#
#     precision -shell -file scripts/synth_adder8.tcl
#
# Why a second script?  `adder8` has no clock and no register, so it needs
# a different SDC (sdc/adder8.sdc, virtual clock) and it is the design to
# use when you want to compare AREA between
#   - a ripple carry adder (this script)
#   - a resource shared adder (scripts/synth_add_sub_shared.tcl)
#   - a pipelined adder   (scripts/synth_adder8_pipelined.tcl)
# ===========================================================================

set script_dir [file dirname [file normalize [info script]]]
set lab_dir    [file dirname $script_dir]

# >>> CHANGE THIS to the technology library of your organisation <<<
set tech_lib "gscl45nm"

set design_name "adder8"
set project_dir "$lab_dir/work_$design_name"

if {[file exists $project_dir]} {
    file delete -force $project_dir
}
new_project -name $design_name -folder $project_dir -technology $tech_lib

add_source -type vhdl -work work -library work "$lab_dir/rtl/full_adder_struct.vhd"
add_source -type vhdl -work work -library work "$lab_dir/rtl/adder8.vhd"

add_constraint_file "$lab_dir/sdc/adder8.sdc"

set_top_module $design_name

elaborate
compile -incremental_mapping

file mkdir "$lab_dir/reports"
report_area        -file "$lab_dir/reports/area_adder8.rpt"
report_timing      -delay max -num_paths 50 -file "$lab_dir/reports/timing_max_adder8.rpt"
report_power       -file "$lab_dir/reports/power_adder8.rpt"

file mkdir "$lab_dir/netlist"
export_netlist -format verilog -output "$lab_dir/netlist/${design_name}_netlist.v"
write_sdf -output "$lab_dir/netlist/${design_name}.sdf"

puts "Precision RTL synthesis of '$design_name' finished."
exit

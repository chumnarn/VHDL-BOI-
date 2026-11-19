# ===========================================================================
# scripts/synth_top.tcl
# Precision RTL Synthesis - batch script for entity `top`  (Lab 3A)
#
# Run from ANY directory:
#     precision -shell -file scripts/synth_top.tcl
#
# NOTE: the script is written for the Precision RTL command set that the
# rest of this manual uses:
#     new_project / add_source / add_constraint_file / set_top_module /
#     elaborate / compile / report_* / export_netlist / write_sdf / exit
# If your installed version spells an option differently, check it with
#     precision -shell -file <script>      and `help <command>` in the shell.
#
# The file version-01/...Precision Synthesis....md in this repository uses
# a DIFFERENT command set (setup_design / add_input_file / read_sdc /
# write_output_file) which belongs to the Xilinx-flavoured flow. Do not
# mix the two.
# ===========================================================================

# ---- 0. Locate the lab folder --------------------------------------------
# [file dirname [file normalize [info script]]] gives the folder that holds
# THIS script, so the script works no matter where it is started from.
set script_dir [file dirname [file normalize [info script]]]
set lab_dir    [file dirname $script_dir]

# ---- 1. Technology library ------------------------------------------------
# >>> CHANGE THIS to the technology library of your organisation <<<
#   gscl45nm          - a generic GlobalFoundries 45 nm reference library
#   /pdk/.../stdcell  - an absolute path to your .lib files
# A wrong value here is the FIRST thing to check when the run fails.
set tech_lib "gscl45nm"

# ---- 2. Design under test -------------------------------------------------
set design_name "top"
set project_dir "$lab_dir/work_$design_name"

# ---- 3. Create the project ------------------------------------------------
if {[file exists $project_dir]} {
    file delete -force $project_dir
}
new_project -name $design_name -folder $project_dir -technology $tech_lib

# ---- 4. Add the RTL sources ----------------------------------------------
# The ORDER matters:
#   full_adder_struct.vhd defines the entity that adder8.vhd binds its
#   `component full_adder_struct` declaration to. Compile it first.
#   All files live in rtl/ of this lab folder - the script uses an absolute
#   path so a wrong working directory cannot break the run.
add_source -type vhdl -work work -library work "$lab_dir/rtl/full_adder_struct.vhd"
add_source -type vhdl -work work -library work "$lab_dir/rtl/adder8.vhd"
add_source -type vhdl -work work -library work "$lab_dir/rtl/adder8_pipelined.vhd"
add_source -type vhdl -work work -library work "$lab_dir/rtl/add_sub_shared.vhd"
add_source -type vhdl -work work -library work "$lab_dir/rtl/top.vhd"

# ---- 5. Constraints -------------------------------------------------------
# The SDC file must constrain ports that REALLY exist in the entity.
# Run `python3 scripts/check_sdc_ports.py --design top` before this script.
add_constraint_file "$lab_dir/sdc/top.sdc"

# ---- 6. Top module --------------------------------------------------------
set_top_module $design_name

# ---- 7. Elaborate ---------------------------------------------------------
# Elaborate resolves the hierarchy and checks that the design has a single
# unambiguous top and that every component is bound to an entity.
elaborate

# ---- 8. Compile (synthesise) ---------------------------------------------
#   -incremental_mapping : reuse the previous mapping when nothing changed
#   -retiming            : let the tool move registers across combinational
#                           logic to shorten the critical path
compile -incremental_mapping -retiming

# ---- 9. Reports -----------------------------------------------------------
file mkdir "$lab_dir/reports"
report_area        -file "$lab_dir/reports/area.rpt"
report_timing      -delay max -num_paths 50 -file "$lab_dir/reports/timing_max.rpt"
report_timing      -delay min -num_paths 50 -file "$lab_dir/reports/timing_min.rpt"
report_power       -file "$lab_dir/reports/power.rpt"
report_constraints -file "$lab_dir/reports/constraints.rpt"

# ---- 10. Export the netlist ----------------------------------------------
file mkdir "$lab_dir/netlist"
export_netlist -format verilog -output "$lab_dir/netlist/${design_name}_netlist.v"

# ---- 11. SDF (used by the gate-level simulation of Lab 4) -----------------
write_sdf -output "$lab_dir/netlist/${design_name}.sdf"

# ---- 12. Done -------------------------------------------------------------
puts "Precision RTL synthesis of '$design_name' finished."
puts "  reports : $lab_dir/reports"
puts "  netlist : $lab_dir/netlist"
exit

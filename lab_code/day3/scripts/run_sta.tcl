# ===========================================================================
# scripts/run_sta.tcl
# OpenSTA script for the Lab 3A reference flow.
#
# It is driven through environment variables so that the same script works
# for every design:
#
#   NETLIST  path of the mapped Verilog netlist
#   TOP      name of the top module
#   LIB      path of the Liberty file
#   SDC      path of the SDC file
#   OUT      path of the report file that is produced
#
# Usage:
#   NETLIST=... TOP=... LIB=... SDC=... OUT=... sta -exit scripts/run_sta.tcl
#
# The SDC file is the SAME file that the Precision RTL script loads
# (sdc/<design>.sdc).  That is the whole point: both tools must see exactly
# the same constraints, otherwise the slack numbers cannot be compared.
#
# NOTE on the report capture: the OpenSTA reporting commands print on the
# C++ standard output, they do NOT return the text to Tcl.  Writing them
# with `puts $fh [report_worst_slack -max]` would therefore produce an empty
# file.  The correct way is sta::redirect_file_begin / sta::redirect_file_end.
# ===========================================================================

set netlist $::env(NETLIST)
set top     $::env(TOP)
set lib     $::env(LIB)
set sdc     $::env(SDC)
set out     $::env(OUT)

# ---- library and netlist --------------------------------------------------
read_liberty $lib
read_verilog $netlist
link_design $top

# ---- constraints ----------------------------------------------------------
read_sdc $sdc

# The SDC files keep set_operating_conditions commented out because the
# command is not accepted by every tool/library combination.
#
# OpenSTA 2.7.0 does NOT implement set_operating_conditions at all - it uses
# the default operating conditions that are declared inside the Liberty file.
# The `catch` keeps the script working on both kinds of STA.
if {[catch {set_operating_conditions -process typical -voltage 1.0 -temp 25} msg]} {
    puts "note: set_operating_conditions is not supported by this STA ($msg)"
    puts "note: the default operating conditions of the Liberty file are used"
}

# ---- reports --------------------------------------------------------------
sta::redirect_file_begin $out

puts "=============================================================="
puts " OpenSTA static timing analysis"
puts "   top     : $top"
puts "   netlist : $netlist"
puts "   liberty : $lib"
puts "   sdc     : $sdc"
puts "=============================================================="
puts ""

puts "---------------- MAX (setup) --------------------------------"
report_checks -path_delay max -group_count 10 -digits 4
puts ""
puts "---------------- MIN (hold) ---------------------------------"
report_checks -path_delay min -group_count 10 -digits 4
puts ""
puts "---------------- SUMMARY ------------------------------------"
puts "worst_slack_max:"
report_worst_slack -max
puts "worst_slack_min:"
report_worst_slack -min
puts "tns_max:"
report_tns -max
puts "tns_min:"
report_tns -min
puts ""
puts "=============================================================="

sta::redirect_file_end

puts "STA report written to $out"

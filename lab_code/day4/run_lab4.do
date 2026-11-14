# run_lab4.do
# Questa/ModelSim batch script for Day 4 labs (Verification)
# Usage (command line):  vsim -do run_lab4.do -c
# Usage (Questa GUI):     File -> Source -> run_lab4.do
#
# IMPORTANT: every testbench is launched in its OWN simulator process via `exec`.
#            A plain nested "vsim -c ... quit -f" would make the child's quit -f
#            terminate this script after the first testbench.
#
# Each row of TestList: { testbench  description  run_time  completion_marker }
# The completion marker is the message the testbench prints when it has reached
# the end. Checking it catches a run time that is too short: the simulation
# would otherwise stop in the middle of the testbench and still look "passed".

# ---------------------------------------------------------------------------
# 1. Create the work library
# ---------------------------------------------------------------------------
if {![file exists work]} {
    vlib work
}

# ---------------------------------------------------------------------------
# 2. Compile design units
# ---------------------------------------------------------------------------
vcom -2008 -work work alu8.vhd ref_model_alu8.vhd handshake_protocol.vhd
vcom -2008 -work work tb_alu8_selfcheck.vhd tb_handshake.vhd

# ---------------------------------------------------------------------------
# 3. Run every testbench
#    tb_alu8_selfcheck sweeps 262144 patterns x 1 ns = ~262 us
# ---------------------------------------------------------------------------
set TestList [list \
  [list tb_alu8_selfcheck "8-bit ALU self-check (262K patterns)" "400 us" "ALL 262144 PATTERNS PASS"] \
  [list tb_handshake      "Handshake protocol"                  "5 us" "ALL HANDSHAKES COMPLETED"] \
]

set total [llength $TestList]
set failed 0
set idx 0

foreach test $TestList {
    set tb   [lindex $test 0]
    set name [lindex $test 1]
    set runT [lindex $test 2]
    set mark [lindex $test 3]
    incr idx
    puts ""
    puts "============================================================"
    puts "[format "%d/%d" $idx $total] Running testbench: $tb ($name)"
    puts "============================================================"
    if {[catch {exec vsim -c -do "add wave *; run $runT; quit -f" work.$tb} out]} {
        puts "** FAILED TO RUN $tb : $out"
        incr failed
    } else {
        puts $out
        if {[regexp -nocase {\*\* (Error|Failure|Fatal)|assertion failure|severity failure} $out]} {
            puts "** ASSERTION FAILURE DETECTED in $tb"
            incr failed
        } elseif {![string match -nocase "*$mark*" $out]} {
            puts "** INCOMPLETE: $tb did not reach the end of the testbench."
            puts "**            Expected marker \"$mark\" was not printed -"
            puts "**            the run time ($runT) is most likely too short."
            incr failed
        }
    }
}

puts ""
if {$failed == 0} {
    puts "All Day 4 functional labs completed successfully ($total/$total testbenches passed)."
} else {
    puts "Day 4 labs finished with $failed failure(s) out of $total testbenches."
}
puts ""
puts "For Gate-Level Simulation:"
puts "  do run_gls.do   ;# requires netlist/top_netlist.v and top.sdf"
quit -f

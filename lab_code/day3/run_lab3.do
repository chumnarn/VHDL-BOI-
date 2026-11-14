# run_lab3.do
# Questa/ModelSim batch script for Day 3 labs (Adder variants)
# Usage (command line):  vsim -do run_lab3.do -c
# Usage (Questa GUI):     File -> Source -> run_lab3.do
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
#    Day 2 full_adder_struct is a dependency (structural adder8 instantiates it)
# ---------------------------------------------------------------------------
vcom -2008 -work work ../day2/full_adder_struct.vhd
vcom -2008 -work work adder8.vhd adder8_pipelined.vhd add_sub_shared.vhd top.vhd
vcom -2008 -work work tb_adder8.vhd tb_add_sub_shared.vhd tb_adder8_pipelined.vhd

# ---------------------------------------------------------------------------
# 3. Run every testbench
#    tb_add_sub_shared needs ~2.6 us (2 x 16 x 16 patterns x 5 ns)
# ---------------------------------------------------------------------------
set TestList [list \
  [list tb_adder8           "8-bit Ripple Carry Adder"   "1 us" "ALL TESTS PASSED"] \
  [list tb_add_sub_shared   "ADD/SUB Resource Sharing"    "10 us" "ALL EXHAUSTIVE PATTERNS PASS"] \
  [list tb_adder8_pipelined "Pipelined 8-bit Adder"      "2 us" "ALL TESTS PASSED"] \
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
    puts "All Day 3 functional labs completed successfully ($total/$total testbenches passed)."
} else {
    puts "Day 3 labs finished with $failed failure(s) out of $total testbenches."
}
puts ""
puts "To synthesize with Precision RTL, run:"
puts "  precision -shell -file synth.tcl"
quit -f

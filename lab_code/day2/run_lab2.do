# run_lab2.do
# Questa/ModelSim batch script for Day 2 labs (FSM, Counter, Adder)
# Usage (command line):  vsim -do run_lab2.do -c
# Usage (Questa GUI):     File -> Source -> run_lab2.do
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
# 2. Compile design units (package first, then entities, then testbenches)
# ---------------------------------------------------------------------------
vcom -2008 -work work my_types_pkg.vhd
vcom -2008 -work work counter8.vhd seq_det_moore.vhd seq_det_mealy.vhd full_adder_struct.vhd adder4_struct.vhd
vcom -2008 -work work tb_counter8.vhd tb_seq_moore.vhd tb_seq_mealy.vhd tb_adder4.vhd

# ---------------------------------------------------------------------------
# 3. Run every testbench
#    tb_adder4 needs ~2.6 us (16 x 16 x 2 patterns x 5 ns)
# ---------------------------------------------------------------------------
set TestList [list \
  [list tb_counter8 "8-bit counter (synchronous + CE + load)" "2 us" "ALL TESTS PASSED"] \
  [list tb_seq_moore "Moore FSM 101 detector" "2 us" "ALL TESTS PASSED"] \
  [list tb_seq_mealy "Mealy FSM 101 detector"  "2 us" "ALL TESTS PASSED"] \
  [list tb_adder4    "4-bit ripple carry adder" "10 us" "patterns tested"] \
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
    puts "All Day 2 labs completed successfully ($total/$total testbenches passed)."
} else {
    puts "Day 2 labs finished with $failed failure(s) out of $total testbenches."
}
quit -f

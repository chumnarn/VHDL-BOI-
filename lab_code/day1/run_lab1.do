# run_lab1.do
# Questa/ModelSim batch script for Day 1 labs
# Usage (command line):  vsim -do run_lab1.do -c
# Usage (Questa GUI):     File -> Source -> run_lab1.do
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
vcom -2008 -work work and_gate.vhd or_gate.vhd nand4_gate.vhd mux2x1.vhd mux4x1_dataflow.vhd mux4x1_behavioral.vhd dec2x4.vhd dec3x8.vhd
vcom -2008 -work work tb_and_or.vhd tb_nand4_gate.vhd tb_mux2x1.vhd tb_mux4x1.vhd tb_dec2x4.vhd tb_dec3x8.vhd

# ---------------------------------------------------------------------------
# 3. Run every testbench
# ---------------------------------------------------------------------------
set TestList [list \
  [list tb_and_or     "AND/OR gate"      "1 us" "ALL TESTS PASSED"] \
  [list tb_nand4_gate "4-input NAND"     "1 us" "16 patterns PASSED"] \
  [list tb_mux2x1     "2-to-1 MUX"       "1 us" "ALL TESTS PASSED"] \
  [list tb_mux4x1     "4-to-1 MUX"       "1 us" "dataflow == behavioral, PASS"] \
  [list tb_dec2x4     "2-to-4 Decoder"   "1 us" "ALL TESTS PASSED"] \
  [list tb_dec3x8     "3-to-8 Decoder"   "1 us" "ALL TESTS PASSED"] \
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
    if {[catch {exec vsim -c -do "run $runT; quit -f" work.$tb} out]} {
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
    puts "All Day 1 labs completed successfully ($total/$total testbenches passed)."
} else {
    puts "Day 1 labs finished with $failed failure(s) out of $total testbenches."
}
quit -f

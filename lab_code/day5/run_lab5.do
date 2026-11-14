# run_lab5.do
# Questa/ModelSim batch script for Day 5 mini-project
# Usage (command line):  vsim -do run_lab5.do -c
# Usage (Questa GUI):     File -> Source -> run_lab5.do
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
vcom -2008 -work work baud_gen.vhd uart_tx.vhd uart_top.vhd
vcom -2008 -work work tb_uart_top.vhd

# ---------------------------------------------------------------------------
# 3. Run every testbench
#    6 UART frames x 10 bit periods x 8680 ns = ~521 us
# ---------------------------------------------------------------------------
set TestList [list \
  [list tb_uart_top "UART TX full flow" "2 ms" "ALL PATTERN FRAMES VERIFIED"] \
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
    puts "Day 5 RTL simulation done successfully ($total/$total testbenches passed)."
} else {
    puts "Day 5 finished with $failed failure(s) out of $total testbenches."
}
puts ""
puts "Next steps:"
puts "  1. precision -shell -file synth_uart.tcl"
puts "  2. vsim -do run_gls_uart.do"
quit -f

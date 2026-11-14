# run_lab5.do
# Questa batch script for Day 5 mini-project
vlib work
vcom -2008 -work work baud_gen.vhd uart_tx.vhd uart_top.vhd
vcom -2008 -work work tb_uart_top.vhd

set TestList [list \
  [list tb_uart_top "UART TX full flow" "20 ms"] \
]

foreach test $TestList {
    set tb   [lindex $test 0]
    set name [lindex $test 1]
    set runT [lindex $test 2]
    puts ""
    puts "============================================================"
    puts "Running testbench: $tb ($name)"
    puts "============================================================"
    vsim -c -do "add wave *; run $runT; quit -f" work.$tb
}

puts "Day 5 RTL simulation done."
puts ""
puts "Next steps:"
puts "  1. precision -shell -file synth_uart.tcl"
puts "  2. vsim -do run_gls_uart.do"
quit -f
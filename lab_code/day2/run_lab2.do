# run_lab2.do
# Questa batch script for Day 2 labs (FSM, Counter, Adder)
vlib work
vcom -2008 -work work my_types_pkg.vhd
vcom -2008 -work work counter8.vhd seq_det_moore.vhd seq_det_mealy.vhd full_adder_struct.vhd adder4_struct.vhd
vcom -2008 -work work tb_counter8.vhd tb_seq_moore.vhd tb_seq_mealy.vhd tb_adder4.vhd

set TestList [list \
  [list tb_counter8 "8-bit counter  (synchronous + CE + load)" "200 ns"] \
  [list tb_seq_moore "Moore FSM 101 detector" "300 ns"] \
  [list tb_seq_mealy "Mealy FSM 101 detector"  "300 ns"] \
  [list tb_adder4    "4-bit ripple carry adder" "200 ns"] \
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

puts "All Day 2 labs completed."
quit -f
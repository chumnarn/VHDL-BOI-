# run_lab3.do
# Questa batch script for Day 3 labs (Adder variants)
vlib work
# Add Day 2 full_adder_struct as dependency (structural adder8 uses it)
vcom -2008 -work work ../day2/full_adder_struct.vhd
vcom -2008 -work work adder8.vhd adder8_pipelined.vhd add_sub_shared.vhd top.vhd
vcom -2008 -work work tb_adder8.vhd tb_add_sub_shared.vhd tb_adder8_pipelined.vhd

set TestList [list \
  [list tb_adder8           "8-bit Ripple Carry Adder"           "100 ns"] \
  [list tb_add_sub_shared   "ADD/SUB Resource Sharing"          "1 us"] \
  [list tb_adder8_pipelined "Pipelined 8-bit Adder"              "500 ns"] \
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

puts "All Day 3 functional labs completed."
puts ""
puts "To synthesize with Precision RTL, run:"
puts "  precision -shell -file synth.tcl"
quit -f
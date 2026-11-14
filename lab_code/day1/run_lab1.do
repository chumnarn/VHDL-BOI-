# run_lab1.do
# Questa/ModelSim batch script for Day 1 labs
# Usage: vsim -do run_lab1.do -c
# Or open in Questa: File -> Source -> run_lab1.do

# Create work library
vlib work
vcom -2008 -work work and_gate.vhd or_gate.vhd nand4_gate.vhd mux2x1.vhd mux4x1_dataflow.vhd mux4x1_behavioral.vhd dec2x4.vhd dec3x8.vhd
vcom -2008 -work work tb_and_or.vhd tb_nand4_gate.vhd tb_mux2x1.vhd tb_mux4x1.vhd tb_dec2x4.vhd tb_dec3x8.vhd

# Run each testbench
set TestList [list \
  [list tb_and_or     "AND/OR gate"      "100 ns"] \
  [list tb_nand4_gate "4-input NAND"     "200 ns"] \
  [list tb_mux2x1     "2-to-1 MUX"       "200 ns"] \
  [list tb_mux4x1     "4-to-1 MUX"       "200 ns"] \
  [list tb_dec2x4     "2-to-4 Decoder"   "200 ns"] \
  [list tb_dec3x8     "3-to-8 Decoder"   "200 ns"] \
]

foreach test $TestList {
    set tb   [lindex $test 0]
    set name [lindex $test 1]
    set runT [lindex $test 2]
    puts ""
    puts "============================================================"
    puts "Running testbench: $tb ($name)"
    puts "============================================================"
    vsim -c -do "run $runT; quit -f" work.$tb
}

puts ""
puts "All Day 1 labs completed."
quit -f
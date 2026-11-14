# run_lab4.do
# Questa batch script for Day 4 labs (Verification)
vlib work
vcom -2008 -work work alu8.vhd ref_model_alu8.vhd handshake_protocol.vhd
vcom -2008 -work work tb_alu8_selfcheck.vhd tb_handshake.vhd

set TestList [list \
  [list tb_alu8_selfcheck "8-bit ALU self-check (262K patterns)" "300 us"] \
  [list tb_handshake      "Handshake protocol"                  "5 us"] \
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

puts "All Day 4 functional labs completed."
puts ""
puts "For Gate-Level Simulation:"
puts "  do run_gls.do   ;# requires netlist/top_netlist.v and top.sdf"
quit -f
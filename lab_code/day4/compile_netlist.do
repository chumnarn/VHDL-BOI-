# compile_netlist.do
# Compile synthesised netlist + VHDL testbench for Gate-Level Simulation

vlib work_gate
vlog -work work_gate ../day3/netlist/top_netlist.v   ;# Verilog netlist from Precision RTL
vcom -2008 -work work_gate ref_model_alu8.vhd
vcom -2008 -work work_gate tb_alu8_selfcheck.vhd
quit -f
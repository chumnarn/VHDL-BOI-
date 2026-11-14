# run_gls.do
# Run Gate-Level Simulation with SDF back-annotation
# Prerequisite: netlist/top_netlist.v + netlist/top.sdf exist
#               (from Precision RTL with -sdf_write option)

vlib work_gate

# Compile
vlog -work work_gate ../day3/netlist/top_netlist.v
vcom -2008 -work work_gate ref_model_alu8.vhd
vcom -2008 -work work_gate tb_alu8_selfcheck.vhd

# Launch simulation with SDF back-annotation
# -sdf specifies instance path + SDF file
# Note: SDF timing on tb/dut instance
vsim -t ps -sdf /tb_alu8_selfcheck/dut=../day3/netlist/top.sdf \
      work_gate.tb_alu8_selfcheck

# Open waveform, add key signals
add wave -position insertpoint sim:/tb_alu8_selfcheck/*
add wave -position insertpoint sim:/tb_alu8_selfcheck/dut/*

# Run with full pattern sweep (262144 patterns)
run 1 ms

quit -f
# run_gls_uart.do
# Gate-Level Simulation for UART TX with SDF back-annotation
# Requires: netlist/uart_top_netlist.v + netlist/uart_top.sdf (from Precision RTL)

vlib work_gate

vlog -work work_gate netlist/uart_top_netlist.v
vcom -2008 -work work_gate tb_uart_top.vhd

vsim -t ps -sdf /tb_uart_top/dut=netlist/uart_top.sdf work_gate.tb_uart_top

add wave -position insertpoint sim:/tb_uart_top/*
add wave -position insertpoint sim:/tb_uart_top/dut/*

run 10 ms

quit -f
# ===========================================================================
# sdc/adder8_pipelined.sdc
# SDC constraints for entity `adder8_pipelined` - Lab 3A
#
# Ports of `adder8_pipelined` (see rtl/adder8_pipelined.vhd):
#   in  : clk  rst  a[7:0]  b[7:0]  cin
#   out : sum[7:0]  cout
#
# Target clock : 100 MHz  ->  period 10.000 ns
# Latency      : 1 clock cycle
# ===========================================================================

set CLK_NAME    sys_clk
set CLK_PERIOD  10.000

create_clock -name $CLK_NAME -period $CLK_PERIOD -waveform {0.000 5.000} [get_ports clk]

# `rst` is SYNCHRONOUS here -> it is timed like a normal data input.
set_input_delay -clock $CLK_NAME 2.0 -max [get_ports {a b cin rst}]
set_input_delay -clock $CLK_NAME 1.0 -min [get_ports {a b cin rst}]

set_output_delay -clock $CLK_NAME 2.0 -max [get_ports {sum cout}]
set_output_delay -clock $CLK_NAME 1.0 -min [get_ports {sum cout}]

set_load 0.010 [get_ports {sum cout}]

# Optional driving cell - see sdc/top.sdc for the full explanation.
# set_driving_cell -lib_cell INVX1 -pin Y [get_ports {a b cin rst}]

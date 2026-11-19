# ===========================================================================
# sdc/adder8.sdc
# SDC constraints for entity `adder8` - Lab 3A (Precision RTL Synthesis)
#
# Ports of `adder8` (see rtl/adder8.vhd):
#   in  : a[7:0]  b[7:0]  cin
#   out : sum[7:0]  cout
#
# `adder8` is PURELY COMBINATIONAL - it has no clock and no register.
# A virtual clock (create_clock without a port) is used to constrain the
# input -> output path. Without any clock at all the timing report is
# empty and the tool has nothing to report.
# ===========================================================================

set CLK_NAME    io_clk
set CLK_PERIOD  10.000

# Virtual clock: no [get_ports ...] argument -> not attached to a real pin
create_clock -name $CLK_NAME -period $CLK_PERIOD

set_input_delay  -clock $CLK_NAME 2.0 -max [get_ports {a b cin}]
set_input_delay  -clock $CLK_NAME 1.0 -min [get_ports {a b cin}]

set_output_delay -clock $CLK_NAME 2.0 -max [get_ports {sum cout}]
set_output_delay -clock $CLK_NAME 1.0 -min [get_ports {sum cout}]

set_load 0.010 [get_ports {sum cout}]

# Optional driving cell - see sdc/top.sdc for the full explanation.
# set_driving_cell -lib_cell INVX1 -pin Y [get_ports {a b cin}]

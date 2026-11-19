# ===========================================================================
# sdc/add_sub_shared.sdc
# SDC constraints for entity `add_sub_shared` - Lab 3A
#
# Ports of `add_sub_shared` (see rtl/add_sub_shared.vhd):
#   in  : a[7:0]  b[7:0]  op
#   out : y[7:0]  ovf
#
# Purely combinational -> virtual clock (no real clock pin).
# ===========================================================================

set CLK_NAME    io_clk
set CLK_PERIOD  10.000

create_clock -name $CLK_NAME -period $CLK_PERIOD

set_input_delay  -clock $CLK_NAME 2.0 -max [get_ports {a b op}]
set_input_delay  -clock $CLK_NAME 1.0 -min [get_ports {a b op}]

set_output_delay -clock $CLK_NAME 2.0 -max [get_ports {y ovf}]
set_output_delay -clock $CLK_NAME 1.0 -min [get_ports {y ovf}]

set_load 0.010 [get_ports {y ovf}]

# Optional driving cell - see sdc/top.sdc for the full explanation.
# set_driving_cell -lib_cell INVX1 -pin Y [get_ports {a b op}]

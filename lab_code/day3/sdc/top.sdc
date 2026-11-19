# ===========================================================================
# sdc/top.sdc
# SDC constraints for entity `top` - Lab 3A (Precision RTL Synthesis)
#
# Ports of `top` (see rtl/top.vhd):
#   in  : clk  rst  a[7:0]  b[7:0]  cin  op
#   out : sum[7:0]  cout  psum[7:0]  pcout  sy[7:0]  ovf
#
# Target clock : 100 MHz  ->  period 10.000 ns
#
# IMPORTANT - this file was rewritten for Lab 3A.  The original
# lab_code/day3/constraints.sdc declared
#       create_clock ... [get_ports clk]
#       set_false_path -from [get_ports rst]
# but entity `top` of the original lab had NO clk and NO rst port at all.
# A get_ports on a non-existent port returns an EMPTY collection, so the
# constraint was silently dropped (or the tool aborted) and the timing
# report contained nothing meaningful.
# Run scripts/check_sdc_ports.py to catch that class of mistake.
# ===========================================================================

set CLK_NAME    sys_clk
set CLK_PERIOD  10.000

# ---- 1. Clock --------------------------------------------------------------
# -waveform {rise fall} : rising edge at 0.000 ns, falling edge at 5.000 ns
create_clock -name $CLK_NAME -period $CLK_PERIOD -waveform {0.000 5.000} [get_ports clk]

# ---- 2. Input delays -------------------------------------------------------
# External inputs reach the chip 2.0 ns after the launch clock edge.
# `rst` is a SYNCHRONOUS reset in every design of this lab, so it is timed
# like a normal data input - do NOT give it a set_false_path here.
# (set_false_path would remove the reset path from timing analysis and hide
#  a real violation if the reset fan-out is large.)
set_input_delay -clock $CLK_NAME 2.0 -max [get_ports {a b cin op rst}]
set_input_delay -clock $CLK_NAME 1.0 -min [get_ports {a b cin op rst}]

# ---- 3. Output delays ------------------------------------------------------
# The external receiver needs the data 2.0 ns after the capture edge.
set_output_delay -clock $CLK_NAME 2.0 -max [get_ports {sum cout psum pcout sy ovf}]
set_output_delay -clock $CLK_NAME 1.0 -min [get_ports {sum cout psum pcout sy ovf}]

# ---- 4. Load on the outputs ------------------------------------------------
# Output capacitance in pF. Replace with the real pad input capacitance.
set_load 0.010 [get_ports {sum cout psum pcout sy ovf}]

# ---- 5. Optional: driving cell on the inputs -------------------------------
# -lib_cell MUST name a cell that exists in YOUR technology library.
# INVX1 below is only a placeholder (it exists in some open libraries but
# not in all). Check your library first, or comment the line out.
# set_driving_cell -lib_cell INVX1 -pin Y [get_ports {a b cin op rst}]

# ---- 6. Optional: operating conditions (PVT) ------------------------------
# Uncomment only if the tool and the library accept it.
# The reference flow (scripts/run_reference_flow.sh) applies the same
# conditions through OpenSTA so that both flows see the same corner.
# set_operating_conditions -process typical -voltage 1.0 -temp 25

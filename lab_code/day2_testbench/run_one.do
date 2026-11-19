onerror {quit -f}
vsim -c work.$::env(MCO_UNIT) -do "run -all; quit -f"

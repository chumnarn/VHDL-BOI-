.PHONY: rtl synth questa-rtl questa-gls

rtl:
	mkdir -p build/ghdl
	cd build/ghdl && ghdl -a --std=08 ../../seq_det_101.vhd ../../tb_seq_det_101.vhd
	cd build/ghdl && ghdl -e --std=08 tb_seq_det_101
	cd build/ghdl && ghdl -r --std=08 tb_seq_det_101 --assert-level=error --vcd=rtl.vcd

synth:
	mkdir -p build
	ghdl --synth --std=08 --out=verilog seq_det_101.vhd -e seq_det_101 > build/seq_det_101_elab.v.tmp
	mv build/seq_det_101_elab.v.tmp build/seq_det_101_elab.v
	yosys -Q -l build/synthesis.log -s synth.ys

questa-rtl:
	mkdir -p build/questa-rtl
	cd build/questa-rtl && vsim -c -do "do ../../questa.do rtl"

questa-gls: synth
	mkdir -p build/questa-gls
	cd build/questa-gls && vsim -c -do "do ../../questa.do gls"

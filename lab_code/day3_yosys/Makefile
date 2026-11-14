# Makefile - Lab 3B: Open-source synthesis with Yosys (and LibreLane)
#
# ใช้งาน (ต้องอยู่ในโฟลเดอร์ lab_code/day3_yosys):
#   make            -> sim + synth + sim-gls  (ลำดับแนะนำสำหรับเริ่มต้น)
#   make sim        -> RTL simulation (Icarus Verilog)
#   make synth      -> Yosys generic synthesis + stat
#   make synth-gate -> Yosys gate-level netlist
#   make sim-gls    -> Gate-level simulation ของ netlist ที่ Yosys สร้าง
#   make ghdl       -> VHDL (GHDL) -> Verilog -> Yosys
#   make sky130     -> Yosys mapping เข้า standard cell library ของ sky130
#   make librelane  -> full open-source ASIC flow (ต้องมี PDK)
#   make clean      -> ล้าง build/

SHELL := /bin/bash

BUILD   := build
YOSYS   ?= yosys
IVERILOG?= iverilog
VVP     ?= vvp
GHDL    ?= ghdl

# sky130 liberty library (กำหนดได้ผ่าน environment variable)
SKY130_LIB ?= $(wildcard /root/.ciel/ciel/sky130/versions/*/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib)

.PHONY: all sim synth synth-gate sim-gls ghdl sky130 librelane clean dirs

all: sim synth synth-gate sim-gls

dirs:
	@mkdir -p $(BUILD)

# ---------------------------------------------------------------- RTL sim --
sim: dirs
	@echo "=== [1] RTL simulation (Icarus Verilog) ==="
	$(IVERILOG) -o $(BUILD)/tb_adder8.vvp      rtl/adder8.v        tb/tb_adder8.v
	$(IVERILOG) -o $(BUILD)/tb_adder8_pipe.vvp rtl/adder8_pipe.v   tb/tb_adder8_pipe.v
	$(VVP) $(BUILD)/tb_adder8.vvp
	$(VVP) $(BUILD)/tb_adder8_pipe.vvp

# ------------------------------------------------------- generic synthesis --
synth: dirs
	@echo "=== [2] Yosys generic synthesis ==="
	$(YOSYS) -s scripts/synth_generic.ys
	@echo "--- build/adder8_generic_stat.txt ---"
	@cat $(BUILD)/adder8_generic_stat.txt
	@echo "--- build/adder8_pipe_generic_stat.txt ---"
	@cat $(BUILD)/adder8_pipe_generic_stat.txt

# ---------------------------------------------------------- gate mapping --
synth-gate: dirs
	@echo "=== [3] Yosys gate-level mapping ==="
	$(YOSYS) -s scripts/synth_gates.ys
	@echo "--- build/adder8_gates_stat.txt ---"
	@cat $(BUILD)/adder8_gates_stat.txt
	@echo "--- build/adder8_pipe_gates_stat.txt ---"
	@cat $(BUILD)/adder8_pipe_gates_stat.txt

# ------------------------------------------------------ gate-level sim (GLS) --
sim-gls: dirs
	@echo "=== [4] Gate-Level Simulation ของ netlist ที่ Yosys สร้าง ==="
	$(IVERILOG) -o $(BUILD)/tb_adder8_gls.vvp      $(BUILD)/adder8_gates.v      tb/tb_adder8.v
	$(IVERILOG) -o $(BUILD)/tb_adder8_pipe_gls.vvp $(BUILD)/adder8_pipe_gates.v tb/tb_adder8_pipe.v
	$(VVP) $(BUILD)/tb_adder8_gls.vvp
	$(VVP) $(BUILD)/tb_adder8_pipe_gls.vvp

# ------------------------------------------------------- VHDL -> Yosys path --
ghdl: dirs
	@echo "=== [5] VHDL -> GHDL -> Verilog -> Yosys ==="
	bash scripts/ghdl_to_verilog.sh adder8
	$(YOSYS) -p "read_verilog $(BUILD)/adder8_from_vhdl.v; hierarchy -check -top adder8; synth -top adder8; stat; write_verilog -noattr $(BUILD)/adder8_from_vhdl_netlist.v"
	@echo "--- ทดสอบ netlist ที่ได้จาก VHDL ด้วย Icarus ---"
	$(IVERILOG) -o $(BUILD)/tb_adder8_ghdl.vvp $(BUILD)/adder8_from_vhdl_netlist.v tb/tb_adder8.v
	$(VVP) $(BUILD)/tb_adder8_ghdl.vvp

# ------------------------------------------------------ sky130 stdcell map --
sky130: dirs
	@echo "=== [6] Yosys mapping เข้า sky130 standard cell ==="
	@if [ -z "$(SKY130_LIB)" ]; then \
	  echo "SKY130_LIB ไม่ได้ถูกกำหนด - ต้องติดตั้ง PDK ก่อน (ดู lab_code/day3_yosys/librelane/README.md)"; \
	  echo "ตั้งค่า: make sky130 SKY130_LIB=/path/to/sky130_fd_sc_hd__tt_025C_1v80.lib"; \
	  exit 1; \
	fi
	@echo "liberty: $(SKY130_LIB)"
	$(YOSYS) -p "read_liberty -lib $(SKY130_LIB); read_verilog rtl/adder8.v; hierarchy -check -top adder8; synth -top adder8 -noabc; dfflibmap -liberty $(SKY130_LIB); abc -liberty $(SKY130_LIB); stat -liberty $(SKY130_LIB); write_verilog -noattr $(BUILD)/adder8_sky130.v"

# ----------------------------------------------------------- LibreLane flow --
# nix profile ไม่ถูกโหลดอัตโนมัติใน non-interactive shell
# จึงเพิ่ม path ของ nix profile เองก่อนเรียกคำสั่ง
LIBRELANE_BIN := $(shell command -v librelane 2>/dev/null || \
                   ls -1 $${HOME}/.nix-profile/bin/librelane /root/.nix-profile/bin/librelane 2>/dev/null | head -1)

librelane:
	@echo "=== [7] LibreLane full flow (ต้องมี PDK) ==="
	@if [ -z "$(LIBRELANE_BIN)" ]; then \
	  echo "ไม่พบคำสั่ง librelane - ติดตั้งด้วย: nix profile install nixpkgs#librelane"; \
	  exit 1; \
	fi
	cd librelane && $(LIBRELANE_BIN) --volare-pdk -p sky130A config.yaml

clean:
	rm -rf $(BUILD)

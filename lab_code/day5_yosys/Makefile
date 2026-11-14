# Makefile - Lab 5B: RTL-to-GDSII Full Chip Flow (Yosys + LibreLane)
#
# ใช้งาน (ต้องอยู่ในโฟลเดอร์ lab_code/day5_yosys):
#   make            -> sim + synth + sim-gls  (ลำดับแนะนำสำหรับเริ่มต้น)
#   make sim        -> RTL simulation (Icarus Verilog)
#   make synth      -> Yosys generic synthesis + stat
#   make synth-gate -> Yosys gate-level netlist
#   make sim-gls    -> Gate-Level Simulation ของ netlist ที่ Yosys สร้าง
#   make sky130     -> Yosys mapping เข้า standard cell library ของ sky130
#   make librelane  -> full open-source ASIC flow RTL -> GDSII (ต้องมี PDK)
#   make clean      -> ล้าง build/

SHELL := /bin/bash

BUILD   := build
YOSYS   ?= yosys
IVERILOG?= iverilog
VVP     ?= vvp
GHDL    ?= ghdl

# sky130 liberty library (กำหนดได้ผ่าน environment variable)
SKY130_LIB ?= $(wildcard /root/.ciel/ciel/sky130/versions/*/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib)

# nix profile ไม่ถูกโหลดอัตโนมัติใน non-interactive shell
# จึงค้นหา binary เองก่อนเรียก
LIBRELANE_BIN := $(shell command -v librelane 2>/dev/null || \
                   ls -1 $${HOME}/.nix-profile/bin/librelane /root/.nix-profile/bin/librelane 2>/dev/null | head -1)

.PHONY: all sim synth synth-gate sim-gls sky130 librelane clean dirs

all: sim synth synth-gate sim-gls

dirs:
	@mkdir -p $(BUILD)

# ---------------------------------------------------------------- RTL sim --
sim: dirs
	@echo "=== [1] RTL simulation (Icarus Verilog) ==="
	$(IVERILOG) -o $(BUILD)/tb_uart_top.vvp rtl/baud_gen.v rtl/uart_tx.v rtl/uart_top.v tb/tb_uart_top.v
	$(VVP) $(BUILD)/tb_uart_top.vvp

# ------------------------------------------------------- generic synthesis --
synth: dirs
	@echo "=== [2] Yosys generic synthesis ==="
	$(YOSYS) -s scripts/synth_generic.ys
	@echo "--- build/uart_top_generic_stat.txt ---"
	@cat $(BUILD)/uart_top_generic_stat.txt
	@echo "--- build/uart_top_flat_stat.txt ---"
	@cat $(BUILD)/uart_top_flat_stat.txt

# ---------------------------------------------------------- gate mapping --
synth-gate: dirs
	@echo "=== [3] Yosys gate-level mapping ==="
	$(YOSYS) -s scripts/synth_gates.ys
	@echo "--- build/uart_top_gates_stat.txt ---"
	@cat $(BUILD)/uart_top_gates_stat.txt

# ------------------------------------------------------ gate-level sim (GLS) --
sim-gls: dirs
	@echo "=== [4] Gate-Level Simulation ของ netlist ที่ Yosys สร้าง ==="
	$(IVERILOG) -o $(BUILD)/tb_uart_top_gls.vvp $(BUILD)/uart_top_gates.v tb/tb_uart_top.v
	$(VVP) $(BUILD)/tb_uart_top_gls.vvp

# ------------------------------------------------------ sky130 stdcell map --
sky130: dirs
	@echo "=== [5] Yosys mapping เข้า sky130 standard cell ==="
	@if [ -z "$(SKY130_LIB)" ]; then \
	  echo "SKY130_LIB ไม่ได้ถูกกำหนด - ต้องติดตั้ง PDK ก่อน (ดู lab_code/day5_yosys/librelane/README.md)"; \
	  echo "ตั้งค่า: make sky130 SKY130_LIB=/path/to/sky130_fd_sc_hd__tt_025C_1v80.lib"; \
	  exit 1; \
	fi
	@echo "liberty: $(SKY130_LIB)"
	$(YOSYS) -p "read_liberty -lib $(SKY130_LIB); read_verilog rtl/baud_gen.v; read_verilog rtl/uart_tx.v; read_verilog rtl/uart_top.v; hierarchy -check -top uart_top; synth -top uart_top -flatten -noabc; dfflibmap -liberty $(SKY130_LIB); abc -liberty $(SKY130_LIB); stat -liberty $(SKY130_LIB); write_verilog -noattr $(BUILD)/uart_top_sky130.v"

# ----------------------------------------------------------- LibreLane flow --
librelane:
	@echo "=== [6] LibreLane full flow (RTL -> GDSII) ==="
	@if [ -z "$(LIBRELANE_BIN)" ]; then \
	  echo "ไม่พบคำสั่ง librelane - ติดตั้งด้วย: nix profile install nixpkgs#librelane"; \
	  exit 1; \
	fi
	cd librelane && $(LIBRELANE_BIN) --volare-pdk -p sky130A config.yaml

clean:
	rm -rf $(BUILD)

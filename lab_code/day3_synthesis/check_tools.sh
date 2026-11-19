#!/usr/bin/env bash
# ตรวจสอบเครื่องมือ synthesis ที่ต้องใช้ในหัวข้อ 3.8 (VHDL Synthesis เชิงลึก)
# ใช้: bash check_tools.sh
set -u

echo "=================================================================="
echo " ENVIRONMENT PROBE — VHDL Synthesis"
echo "=================================================================="
echo

echo "--- GHDL ---"
if command -v ghdl >/dev/null 2>&1; then
  ghdl --version | head -3
  echo "ghdl path : $(command -v ghdl)"
else
  echo "NOT FOUND"
fi
echo

echo "--- GHDL synth (ตัวแปลง VHDL -> Verilog) ---"
if command -v ghdl >/dev/null 2>&1; then
  ghdl synth --help 2>&1 | sed -n '1,30p'
fi
echo

echo "--- Yosys ---"
if command -v yosys >/dev/null 2>&1; then
  yosys -V
  echo "yosys path: $(command -v yosys)"
else
  echo "NOT FOUND"
fi
echo

echo "--- Yosys: plugin ที่เกี่ยวกับ VHDL ---"
if command -v yosys >/dev/null 2>&1; then
  yosys -Q -p "help ghdl" 2>&1 | sed -n '1,12p'
fi
echo

echo "--- Icarus Verilog (สำหรับ gate-level simulation) ---"
if command -v iverilog >/dev/null 2>&1; then
  iverilog -V 2>&1 | head -2
else
  echo "NOT FOUND"
fi
echo

echo "--- Verilator ---"
if command -v verilator >/dev/null 2>&1; then
  verilator --version
else
  echo "NOT FOUND"
fi
echo

echo "--- Liberty files ที่มีในเครื่อง ---"
for f in /usr/share/yosys/cells.lib /usr/share/yosys/abc9_map.v; do
  if [ -f "$f" ]; then
    echo "FOUND   $f"
  else
    echo "MISSING $f"
  fi
done
echo

echo "--- nix profile (LibreLane) ---"
if [ -x "$HOME/.nix-profile/bin/librelane" ]; then
  echo "FOUND   $HOME/.nix-profile/bin/librelane"
  "$HOME/.nix-profile/bin/librelane" --version 2>&1 | head -2
else
  echo "MISSING $HOME/.nix-profile/bin/librelane"
fi
echo

echo "--- ModelSim (Windows) ---"
if [ -x "/mnt/c/Siemens/modelsim_dlx64_2026.1/win64pe/vcom.exe" ]; then
  echo "FOUND   /mnt/c/Siemens/modelsim_dlx64_2026.1/win64pe/vcom.exe"
else
  echo "MISSING /mnt/c/Siemens/modelsim_dlx64_2026.1/win64pe/vcom.exe"
fi
echo
echo "DONE"

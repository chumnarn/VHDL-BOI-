#!/usr/bin/env bash
# =============================================================================
#  run_gls.sh — Gate-Level Simulation ของ netlist ที่สังเคราะห์แล้ว
#
#  ใช้:  bash run_gls.sh
#
#  รูปแบบรายการ: netlist : module : testbench : ผลที่คาดหวัง (PASS/FAIL)
# =============================================================================
set -u

cd "$(dirname "$0")"
mkdir -p reports/gls

echo "=================================================================="
echo " GATE-LEVEL SIMULATION (Icarus Verilog)"
echo "=================================================================="

# ---- เตรียม netlist ของ latch_ok (เขียน Verilog ตรง ๆ ไม่ผ่าน GHDL) ----------
if [ ! -s build/latch_ok_generic.v ]; then
  yosys -Q -p "
    read_verilog verilog/latch_ok.v
    hierarchy -check -top latch_ok
    synth -top latch_ok
    write_verilog -noattr build/latch_ok_generic.v
  " > reports/latch_ok_generic.log 2>&1
  echo "  (สังเคราะห์ latch_ok จาก verilog/latch_ok.v แล้ว)"
fi

CASES=(
  "build/alu4_generic.v:alu4:tb/tb_alu4.v:PASS"
  "build/adder8_generic.v:adder8:tb/tb_adder8.v:PASS"
  "build/latch_bad_latched_generic.v:latch_bad:tb/tb_latch_bad.v:FAIL"
  "build/latch_ok_generic.v:latch_ok:tb/tb_latch_ok.v:PASS"
)

OK=0
BAD=0

for c in "${CASES[@]}"; do
  NET="${c%%:*}";   R1="${c#*:}"
  MOD="${R1%%:*}";  R2="${R1#*:}"
  TB="${R2%%:*}";   EXP="${R2#*:}"
  TAG=$(basename "$NET" _generic.v)

  echo
  echo "--- $TAG : $NET + $TB  (คาดหวัง $EXP) ---"
  if [ ! -s "$NET" ]; then
    echo "    SKIP — ไม่พบ netlist"
    BAD=$((BAD+1))
    continue
  fi

  iverilog -g2012 -o "reports/gls/${TAG}_gls.vvp" "$NET" "$TB" 2>&1 | sed 's/^/    /'
  vvp "reports/gls/${TAG}_gls.vvp" > "reports/gls/${TAG}_gls.log" 2>&1
  RC=$?

  tail -4 "reports/gls/${TAG}_gls.log" | sed 's/^/    /'

  if grep -q "GLS RESULT: $EXP" "reports/gls/${TAG}_gls.log"; then
    echo "    -> ตรงตามที่คาดหวัง ($EXP) — iverilog exit ${RC}"
    OK=$((OK+1))
  else
    echo "    -> ❌ ไม่ตรงกับที่คาดหวัง ($EXP) — iverilog exit ${RC}"
    BAD=$((BAD+1))
  fi
done

echo
echo "=================================================================="
echo " GLS SUMMARY: ตรงตามคาด ${OK} เคส / ไม่ตรง ${BAD} เคส (ทั้งหมด ${#CASES[@]} เคส)"
echo "=================================================================="
echo "หมายเหตุ: latch_bad_latched คาดหวัง FAIL โดยตั้งใจ"
echo "         เพราะพิสูจน์ว่า netlist ที่ได้จาก GHDL --latches ทำงานผิด"
echo "         (ดูคู่มือข้อ 3.8.6.7)"
echo "DONE"

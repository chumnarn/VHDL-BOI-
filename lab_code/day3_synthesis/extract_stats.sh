#!/usr/bin/env bash
# extract_stats.sh — ดึงตัวเลขสรุปจาก reports/ ทั้งหมด เพื่อใช้เขียนเอกสาร
set -u
cd "$(dirname "$0")"

for f in reports/*_generic.log; do
  TAG=$(basename "$f" _generic.log)
  echo "=============================================================="
  echo " $TAG"
  echo "=============================================================="
  echo "--- generic cell types ---"
  awk '/Printing statistics/{f=1} f && /Number of cells:/{c=1} c && /^ +\$/{print} c && /Number of cells/{print}' "$f" \
    | sed -n '1,25p'
  echo "--- DFF / LATCH / MUX count ---"
  for k in 'DFF' 'DLATCH' 'MUX' 'XOR' 'AND' 'OR'; do
    n=$(grep -cE "^ +\\\$${k}" "$f")
    echo "   \$${k} = $n"
  done
  echo "--- sky130 ---"
  grep -E "Chip area for module" "reports/${TAG}_sky130.log" 2>/dev/null | sed 's/^/   /'
  echo "--- ghdl errors ---"
  grep -E "error:|note:" "reports/${TAG}_ghdl.log" 2>/dev/null | sed 's/^/   /' | head -4
  echo
done

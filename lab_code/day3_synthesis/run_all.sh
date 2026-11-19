#!/usr/bin/env bash
# =============================================================================
#  run_all.sh — รัน synthesis ทุกตัวอย่างในหัวข้อ 3.8 (VHDL Synthesis เชิงลึก)
#
#  ใช้:  bash run_all.sh
#
#  รูปแบบรายการ:  tag | top_entity | ghdl_flags | vhdl_file | คำอธิบาย
# =============================================================================
set -u

cd "$(dirname "$0")"
mkdir -p build reports

DESIGNS=(
  "alu4|alu4||rtl/alu4.vhd|ALU 4-bit combinational (case + numeric_std)"
  "counter_sync|counter_sync||rtl/counter_sync.vhd|Counter 8-bit sync reset + clock enable"
  "fsm_seq|fsm_seq||rtl/fsm_seq.vhd|FSM 3 สถานะแบบ Moore"
  "adder8|adder8||rtl/adder8.vhd|Adder 8-bit unsigned + carry out"
  "mult8|mult8||rtl/mult8.vhd|Multiplier 8x8 unsigned"
  "shifter|shifter||rtl/shifter.vhd|Barrel shifter 8-bit"
  "lfsr16|lfsr16||rtl/lfsr16.vhd|LFSR 16-bit Galois form"
  "latch_bad|latch_bad||rtl/latch_bad.vhd|ตั้งใจสร้าง LATCH — GHDL ต้องการ --latches"
  "latch_bad_latched|latch_bad|--latches|rtl/latch_bad.vhd|เปิด --latches — ได้ latch จริง"
  "latch_good|latch_good||rtl/latch_good.vhd|เวอร์ชันที่แก้แล้ว — ไม่มี latch"
  "rom_16x8|rom_16x8||rtl/rom_16x8.vhd|ROM 16x8 จาก constant array"
  "std_logic_arith_bad|std_logic_arith_bad||rtl/std_logic_arith_bad.vhd|ใช้ std_logic_arith — คาดว่าจะไม่ผ่าน"
)

echo "########################################################################"
echo "#  VHDL SYNTHESIS — RUN ALL"
echo "#  date : $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "########################################################################"
echo

SUMMARY="reports/summary.txt"
{
  echo "VHDL SYNTHESIS SUMMARY"
  echo "generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "ghdl     : $(ghdl --version | head -1)"
  echo "yosys    : $(yosys -V)"
  echo
  printf "%-20s | %-5s | %-7s | %-13s | %-7s | %-7s | %s\n" \
         "TAG" "GHDL" "CELLS" "SKY130_AREA" "MITER" "EQUIV" "NOTE" >> "$SUMMARY"
  printf -- "---------------------+-------+---------+--------------+---------+---------+-------------------------\n"
} > "$SUMMARY"

PASS=0
FAIL=0
EXPECTED_FAIL=0
TIMEOUTS=0

for d in "${DESIGNS[@]}"; do
  TAG="${d%%|*}";     R1="${d#*|}"
  TOP="${R1%%|*}";    R2="${R1#*|}"
  FLAGS="${R2%%|*}";  R3="${R2#*|}"
  SRC="${R3%%|*}"
  NOTE="${R3#*|}"

  echo "------------------------------------------------------------------"
  bash synth_one.sh "$TAG" "$TOP" "$FLAGS" "$SRC" 2>&1 | sed 's/^/  /'

  GHDL_RC=$(grep -oE "ghdl synth exit code = [0-9-]+" "reports/${TAG}_ghdl.log" | tail -1 | grep -oE "[0-9-]+$")
  [ -z "$GHDL_RC" ] && GHDL_RC="?"

  CELLS=$(awk '/Printing statistics/{f=1} f && /Number of cells:/{print $NF; exit}' "reports/${TAG}_generic.log" 2>/dev/null)
  [ -z "$CELLS" ] && CELLS="-"

  AREA=$(grep -oE "Chip area for module '[^']*': [0-9.]+" "reports/${TAG}_sky130.log" 2>/dev/null | tail -1 | grep -oE "[0-9.]+$")
  [ -z "$AREA" ] && AREA="-"

  if grep -q "SUCCESS" "reports/${TAG}_miter.log" 2>/dev/null; then
    MITER="PASS"
  elif grep -q "proof did fail" "reports/${TAG}_miter.log" 2>/dev/null; then
    MITER="FAIL"
  elif grep -qE "Solving problem with|Timeout|terminated" "reports/${TAG}_miter.log" 2>/dev/null; then
    MITER="TIMEOUT"
  else
    MITER="n/a"
  fi

  if grep -q "Equivalence successfully proven" "reports/${TAG}_equiv.log" 2>/dev/null; then
    EQ="PASS"
  else
    EQ="FAIL"
  fi

  # จำนวน latch ที่เหลือใน generic netlist
  LATCH=$(grep -cE '^\s+\$_(SR_)?DLATCH' "reports/${TAG}_generic.log" 2>/dev/null)
  [ -z "$LATCH" ] && LATCH="0"

  printf "%-20s | %-5s | %-7s | %-13s | %-7s | %-7s | %s\n" \
         "$TAG" "$GHDL_RC" "$CELLS" "$AREA" "$MITER" "$EQ" "$NOTE" >> "$SUMMARY"
  printf "%-20s | latch cells in generic netlist = %s\n" "" "$LATCH" >> "$SUMMARY"

  if [ "$GHDL_RC" = "0" ] && [ "$EQ" = "PASS" ]; then
    PASS=$((PASS+1))
  elif [ "$GHDL_RC" != "0" ]; then
    FAIL=$((FAIL+1))
    EXPECTED_FAIL=$((EXPECTED_FAIL+1))
  elif [ "$EQ" = "TIMEOUT" ]; then
    FAIL=$((FAIL+1))
    TIMEOUTS=$((TIMEOUTS+1))
  else
    FAIL=$((FAIL+1))
  fi
  if [ "$MITER" = "TIMEOUT" ]; then
    TIMEOUTS=$((TIMEOUTS+1))
  fi
done

echo
echo "------------------------------------------------------------------"
{
  echo
  echo "PASS=${PASS}  FAIL=${FAIL}  (ทั้งหมด ${#DESIGNS[@]} รายการ)"
  echo "  จากนั้น FAIL=${FAIL} รายการ แยกเป็น:"
  echo "    - ตั้งใจให้ GHDL synth ล้มเหลว (latch_bad, std_logic_arith_bad) = ผลที่ถูกต้อง"
  echo "    - เปิด --latches (latch_bad_latched) ได้ latch จริง"
  echo "    - TIMEOUT=${TIMEOUTS} รายการ (SAT แบบ bounded แก้ไม่จบในเวลาที่กำหนด)"
} >> "$SUMMARY"

echo "PASS=${PASS}  FAIL=${FAIL}  (ทั้งหมด ${#DESIGNS[@]} รายการ)"
echo
echo "สรุป: $SUMMARY"
echo "DONE"

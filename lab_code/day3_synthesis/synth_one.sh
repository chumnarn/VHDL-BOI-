#!/usr/bin/env bash
# =============================================================================
#  synth_one.sh — สังเคราะห์ design หนึ่งตัวแล้วเก็บหลักฐานทุกขั้นตอน
#
#  ใช้:  bash synth_one.sh <tag> <top_entity> <ghdl_flags> <vhdl_file> [...]
#        tag  = ชื่อที่ใช้ตั้งชื่อไฟล์รายงาน (เช่น latch_bad_latched)
#        top  = ชื่อ entity ที่ต้องการสังเคราะห์
#        flags= ตัวเลือกเพิ่มเติมให้ ghdl synth (เช่น "--latches" หรือ "")
#
#  ขั้นตอน:
#    1. GHDL synth   : VHDL  -> Verilog        (reports/<tag>_ghdl.log)
#    2. Yosys generic: Verilog -> RTLIL/gates  (reports/<tag>_generic.log)
#    3. Yosys sky130 : map เข้า PDK จริง + area (reports/<tag>_sky130.log)
#    4. Formal equiv : RTL vs generic netlist  (reports/<tag>_equiv.log)
# =============================================================================
set -u

TAG="$1"; shift
TOP="$1"; shift
GHDL_FLAGS="$1"; shift
SRC=( "$@" )

cd "$(dirname "$0")"
mkdir -p build reports

# ---- หา Liberty ของ sky130A (ถ้ามี) -----------------------------------------
SKY130_LIB=""
for c in \
  "/root/.ciel/ciel/sky130/versions"/*/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib \
  "/home/cxp/labs2/lab2_yosys/sky130_fd_sc_hd__tt_025C_1v80.lib" ; do
  if [ -f "$c" ]; then SKY130_LIB="$c"; break; fi
done

# ---- 1) GHDL synth -----------------------------------------------------------
echo "=============================================================="
echo " TAG : $TAG   TOP: $TOP   FLAGS: ${GHDL_FLAGS:-<none>}"
echo " SRC : ${SRC[*]}"
echo "=============================================================="

{
  echo "### ghdl synth ${GHDL_FLAGS} --std=08 --out=verilog ${SRC[*]} -e ${TOP}"
  echo "### GHDL version:"
  ghdl --version | head -1
  echo
} > "reports/${TAG}_ghdl.log"

# shellcheck disable=SC2086
ghdl synth $GHDL_FLAGS --std=08 --out=verilog "${SRC[@]}" -e "$TOP" \
     > "build/${TAG}.v" 2>> "reports/${TAG}_ghdl.log"
GHDL_RC=$?

{
  echo
  echo "### ghdl synth exit code = ${GHDL_RC}"
  echo "### Verilog output size  = $(wc -c < "build/${TAG}.v") bytes"
  echo "### module names in output:"
  grep -E '^module ' "build/${TAG}.v" | sed 's/^/###   /'
  echo "### always blocks (บอกว่าเป็น edge-triggered หรือ level-sensitive):"
  grep -nE 'always @' "build/${TAG}.v" | sed 's/^/###   /'
} >> "reports/${TAG}_ghdl.log"

if [ "$GHDL_RC" -ne 0 ] || [ ! -s "build/${TAG}.v" ]; then
  echo "  -> GHDL SYNTH FAILED (exit ${GHDL_RC})"
  grep -E 'error:|warning:' "reports/${TAG}_ghdl.log" | sed 's/^/       /'
  exit "$GHDL_RC"
fi

# ---- 2) Yosys generic synthesis ----------------------------------------------
yosys -Q -p "
  read_verilog build/${TAG}.v
  hierarchy -check -top ${TOP}
  synth -top ${TOP}
  check -assert
  stat
  write_verilog -noattr build/${TAG}_generic.v
" > "reports/${TAG}_generic.log" 2>&1
GEN_RC=$?
echo "  -> Yosys generic synth exit = ${GEN_RC}"
grep -E "^\s+\\\$_" "reports/${TAG}_generic.log" | tail -12 | sed 's/^/       /'

# ---- 3) Yosys + sky130 technology mapping -----------------------------------
if [ -n "$SKY130_LIB" ]; then
  yosys -Q -p "
    read_verilog build/${TAG}.v
    hierarchy -check -top ${TOP}
    synth -top ${TOP} -noabc
    dfflibmap -liberty ${SKY130_LIB}
    abc -liberty ${SKY130_LIB}
    opt_clean
    stat -liberty ${SKY130_LIB}
    write_verilog -noattr build/${TAG}_sky130.v
  " > "reports/${TAG}_sky130.log" 2>&1
  echo "  -> Yosys sky130 map exit = $?"
else
  echo "  -> SKY130 LIBERTY NOT FOUND — ข้ามขั้นตอน technology mapping"
  echo "     liberty not found" > "reports/${TAG}_sky130.log"
fi

# ---- 4a) Formal equivalence แบบ miter + SAT (วิธีที่คนมักใช้) -------------
# จำกัดเวลา 90 วินาที เพราะ SAT ของ design ขนาดใหญ่ (เช่น multiplier) แก้ไม่จบ
timeout 90 yosys -Q -p "
  read_verilog build/${TAG}.v
  prep -top ${TOP} -flatten
  memory_map
  opt_clean
  design -stash gold

  read_verilog build/${TAG}_generic.v
  prep -top ${TOP} -flatten
  memory_map
  opt_clean
  design -stash gate

  design -copy-from gold -as gold ${TOP}
  design -copy-from gate -as gate ${TOP}
  miter -equiv -flatten -make_assert gold gate miter
  hierarchy -top miter
  sat -verify -prove-asserts -seq 12 miter
" > "reports/${TAG}_miter.log" 2>&1
MITER_RC=$?
if grep -q "SUCCESS" "reports/${TAG}_miter.log"; then
  MITER="PASS"
elif [ "$MITER_RC" -eq "124" ]; then
  MITER="TIMEOUT"
else
  MITER="FAIL"
fi
echo "  -> miter + sat -seq 12 : ${MITER} (exit ${MITER_RC})"

# ---- 4b) Formal equivalence แบบ equiv_make + equiv_induct (flow ที่ถูกต้อง) ---
# เลือกวิธีพิสูจน์ตามชนิดของ design:
#   - ไม่มี DFF  => combinational ใช้ equiv_simple อย่างเดียว (จบเร็ว)
#   - มี DFF     => sequential ต้องใช้ equiv_induct ด้วย (พิสูจน์แบบ induction)
HAS_DFF=$(grep -cE '\$dff|\$_DFF' "reports/${TAG}_generic.log" 2>/dev/null)
[ -z "$HAS_DFF" ] && HAS_DFF=0
if [ "$HAS_DFF" -gt 0 ]; then
  EQ_STEPS="equiv_simple -seq 5
    equiv_induct -seq 5"
  EQ_KIND="sequential (equiv_simple + equiv_induct)"
else
  EQ_STEPS="equiv_simple -seq 5"
  EQ_KIND="combinational (equiv_simple)"
fi
echo "  -> เลือกวิธีพิสูจน์: ${EQ_KIND} (พบ DFF ${HAS_DFF} จุด)"

timeout 300 yosys -Q -p "
  read_verilog build/${TAG}.v
  prep -top ${TOP} -flatten
  memory_map
  opt_clean
  design -stash gold

  read_verilog build/${TAG}_generic.v
  prep -top ${TOP} -flatten
  memory_map
  opt_clean
  design -stash gate

  design -copy-from gold -as gold ${TOP}
  design -copy-from gate -as gate ${TOP}
  equiv_make gold gate equiv
  hierarchy -top equiv
  ${EQ_STEPS}
  equiv_status -assert
" > "reports/${TAG}_equiv.log" 2>&1
EQ_RC=$?
if grep -q "Equivalence successfully proven" "reports/${TAG}_equiv.log"; then
  EQ="PASS"
elif [ "$EQ_RC" -eq "124" ]; then
  EQ="TIMEOUT"
else
  EQ="FAIL"
fi
echo "  -> equiv_make + ${EQ_KIND} : ${EQ} (exit ${EQ_RC})"
if [ "$EQ" = "FAIL" ]; then
  grep -E "ERROR|unproven" "reports/${TAG}_equiv.log" | tail -3 | sed 's/^/       /'
fi

# ---- สรุปตัวเลขจาก stat ------------------------------------------------------
CELLS=$(awk '/Printing statistics/{f=1} f && /Number of cells:/{print $NF; exit}' "reports/${TAG}_generic.log" 2>/dev/null)
AREA=$(grep -oE "Chip area for module '[^']*': [0-9.]+" "reports/${TAG}_sky130.log" 2>/dev/null | tail -1 | grep -oE "[0-9.]+$")
echo "  -> generic cells = ${CELLS:-n/a}   sky130 area = ${AREA:-n/a}"
exit 0

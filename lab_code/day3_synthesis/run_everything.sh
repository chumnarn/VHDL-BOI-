#!/usr/bin/env bash
# run_everything.sh — รันทุกอย่างของหัวข้อ 3.8 แล้วเก็บ log รวมไว้ที่เดียว
# ใช้:  bash run_everything.sh
set -u
cd "$(dirname "$0")"

LOG="reports/run_everything.log"
mkdir -p reports

{
  echo "########################################################################"
  echo "#  VHDL SYNTHESIS — RUN EVERYTHING"
  echo "#  date : $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "########################################################################"
  echo
  echo "########## PART 1: environment probe ##########"
  bash check_tools.sh
  echo
  echo "########## PART 2: synthesis ทุกตัวอย่าง ##########"
  bash run_all.sh
  echo
  echo "########## PART 3: gate-level simulation ##########"
  bash run_gls.sh
  echo
  echo "########## PART 4: สรุปจาก reports/summary.txt ##########"
  cat reports/summary.txt
} > "$LOG" 2>&1

echo "บันทึก log รวมไว้ที่ $LOG"
echo "--- สรุป ---"
cat reports/summary.txt
echo "DONE"

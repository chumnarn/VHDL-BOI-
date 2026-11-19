#!/usr/bin/env bash
# dump_logs.sh — ดู log ของตัวอย่างที่ระบุ
set -u
cd "$(dirname "$0")"
for t in "$@"; do
  echo "=============================================================="
  echo " reports/${t}_ghdl.log"
  echo "=============================================================="
  cat "reports/${t}_ghdl.log"
  echo
done

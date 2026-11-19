#!/bin/bash
# ==========================================================================
# run_all.sh — รันตัวอย่าง VHDL Testbench ทั้งหมดของ lab_code/day2_testbench
#
# ใช้งาน (WSL Ubuntu ที่มี GHDL 5.x):
#   wsl -d Ubuntu -u root --cd '<workspace>/lab_code/day2_testbench' -- bash run_all.sh
#
# ตัวอย่างที่รันจะพิมพ์ผลจริง รวมถึง exit code ของแต่ละเคส
# ==========================================================================
set -u
cd "$(dirname "$0")" || exit 1

STD="--std=08"
WORK="_work"
mkdir -p "$WORK" reports

# ล้าง work library เดิม (ใช้คำสั่งของ GHDL เอง ไม่ใช้ rm -rf)
ghdl --remove --std=08 --workdir="$WORK" >/dev/null 2>&1

echo "=============================================================="
echo " ANALYZE"
echo "=============================================================="
# ลำดับสำคัญ: package ต้องถูกวิเคราะห์ก่อนไฟล์ที่เรียกใช้มัน
if ! ghdl -a $STD --workdir="$WORK" \
        counter_pkg.vhd tb_support_pkg.vhd uart_sb_pkg.vhd \
        rtl/seq_det_moore.vhd rtl/counter8.vhd rtl/uart_tx.vhd \
        ex*.vhd; then
    echo "ANALYZE FAILED"
    exit 1
fi
echo "analyze: OK"

run_one () {
    local unit="$1"; shift
    echo ""
    echo "--------------------------------------------------------------"
    echo " RUN $unit $*"
    echo "--------------------------------------------------------------"
    timeout 120 ghdl -r $STD --workdir="$WORK" "$unit" "$@" 2>&1
    local rc=$?
    echo "[exit code = $rc]"
}

echo ""
echo "=============================================================="
echo " RUN EXAMPLES"
echo "=============================================================="

for u in ex01_delta_cycle ex02_signal_vs_variable ex03_wait_statements \
         ex04_clock_bug ex04_clock_fixed ex05_procedure_checker \
         ex06_random_stimulus ex07_uart_scoreboard ex08_file_io \
         ex10_external_name; do
    run_one "$u"
done

# ex12 + ดู waveform ผ่าน VCD ของ GHDL
run_one ex12_event_log --vcd=reports/ex12_wave.vcd

echo ""
echo "=============================================================="
echo " RUN ex09 -- SEVERITY LEVELS (ดูผลของ exit code)"
echo "=============================================================="
for lvl in 0 1 2 3; do
    run_one ex09_assertion_severity "-gLEVEL=$lvl"
done

echo ""
echo "=============================================================="
echo " RUN ex11 -- CONFIGURATION DECLARATION"
echo "=============================================================="
for cfg in cfg_using_rtl cfg_using_alt; do
    if ghdl -e $STD --workdir="$WORK" "$cfg" >/dev/null 2>&1; then
        echo ""
        echo "--------------------------------------------------------------"
        echo " RUN $cfg"
        echo "--------------------------------------------------------------"
        timeout 60 ghdl -r $STD --workdir="$WORK" "$cfg" 2>&1
        echo "[exit code = $?]"
    else
        echo "[ELABORATE FAILED] $cfg"
    fi
done

echo ""
echo "=============================================================="
echo " ARTIFACTS"
echo "=============================================================="
ls -la reports 2>/dev/null || echo "(no reports dir)"
echo ""
echo "DONE"

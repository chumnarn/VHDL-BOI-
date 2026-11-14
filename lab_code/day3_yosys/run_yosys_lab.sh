#!/usr/bin/env bash
# run_yosys_lab.sh
# Batch runner ของ Lab 3B - Open-source synthesis with Yosys / LibreLane
#
# คู่ขนานกับ run_labX.do ของฝั่ง Questa (Windows) — เป็นสคริปต์ฝั่ง Linux/WSL
#
# ใช้งาน:
#   bash run_yosys_lab.sh            # รันทุกขั้น (ยกเว้น LibreLane ที่ต้องมี PDK)
#   bash run_yosys_lab.sh --full     # รวมขั้นตอน LibreLane ด้วย
#   bash run_yosys_lab.sh --quick    # เฉพาะ sim + synth + GLS
#
# ผลลัพธ์สรุปจะถูกพิมพ์ท้ายสุด พร้อมบอก PASS/FAIL ของแต่ละขั้น

set -uo pipefail
cd "$(dirname "$0")"

MODE="${1:-normal}"
FAILED=0
STEP=0

hr()   { printf '%s\n' "────────────────────────────────────────────────────────────────────────"; }
step() { STEP=$((STEP+1)); hr; printf 'STEP %d — %s\n' "$STEP" "$1"; hr; }

check() {   # check <description> <ERE pattern> <file>
    if grep -qE "$2" "$3" 2>/dev/null; then
        printf '  [PASS] %s\n' "$1"
    else
        printf '  [FAIL] %s\n' "$1"
        FAILED=$((FAILED+1))
    fi
}

checkfile() {   # checkfile <description> <file>
    if [ -s "$2" ]; then
        printf '  [PASS] %s\n' "$1"
    else
        printf '  [FAIL] %s\n' "$1"
        FAILED=$((FAILED+1))
    fi
}

# ─────────────────────────────────────────────────────────── 0. environment ──
step "ตรวจสอบเครื่องมือ"
for t in yosys iverilog vvp make; do
    if command -v "$t" >/dev/null 2>&1; then
        printf '  [ OK ] %-10s -> %s\n' "$t" "$(command -v $t)"
    else
        printf '  [MISS] %-10s  (ติดตั้งด้วย: sudo apt install %s)\n' "$t" "$t"
    fi
done
if command -v ghdl >/dev/null 2>&1; then
    printf '  [ OK ] %-10s -> %s\n' "ghdl" "$(command -v ghdl)"
    HAVE_GHDL=1
else
    printf '  [MISS] %-10s  (ไม่บังคับ - ข้ามขั้นตอนสะพาน VHDL ได้)\n' "ghdl"
    HAVE_GHDL=0
fi
if command -v librelane >/dev/null 2>&1; then
    printf '  [ OK ] %-10s -> %s\n' "librelane" "$(command -v librelane)"
    HAVE_LL=1
else
    # nix profile ไม่ถูกโหลดอัตโนมัติใน non-interactive shell
    # ลองเพิ่ม path ของ nix profile เองก่อนสรุปว่าไม่มี
    for p in "$HOME/.nix-profile/bin" /root/.nix-profile/bin; do
        if [ -x "$p/librelane" ]; then
            export PATH="$p:$PATH"
            printf '  [ OK ] %-10s -> %s (เพิ่ม nix profile ใน PATH ให้)\n' "librelane" "$p/librelane"
            HAVE_LL=1
            break
        fi
    done
fi
if [ "${HAVE_LL:-0}" = "0" ]; then
    printf '  [MISS] %-10s  (ไม่บังคับ - ข้ามขั้นตอน LibreLane ได้)\n' "librelane"
    printf '          ติดตั้ง: nix profile install nixpkgs#librelane\n'
    printf '          แล้วเพิ่ม PATH: export PATH="$HOME/.nix-profile/bin:$PATH"\n'
fi
echo

# ────────────────────────────────────────────────────────────── 1. RTL sim ──
step "RTL Simulation (Icarus Verilog)"
if make sim > build_log_sim.txt 2>&1; then
    grep -E "PASS=|ALL " build_log_sim.txt | sed 's/^/  /'
    check "tb_adder8 ผ่าน"          "tb_adder8 PASS=131072 FAIL=0" build_log_sim.txt
    check "tb_adder8_pipe ผ่าน"      "tb_adder8_pipe PASS=64 FAIL=0" build_log_sim.txt
else
    echo "  [FAIL] make sim ล้มเหลว — ดู build_log_sim.txt"
    FAILED=$((FAILED+1))
fi
echo

# ────────────────────────────────────────────────────────── 2. synthesis ────
step "Yosys Generic Synthesis"
if make synth > build_log_synth.txt 2>&1; then
    sed -n '/=== adder8 ===/,$p' build/adder8_generic_stat.txt | sed 's/^/  /'
    sed -n '/=== adder8_pipe ===/,$p' build/adder8_pipe_generic_stat.txt | sed 's/^/  /'
    check "adder8 มี cell มากกว่า 0"        "Number of cells: +[1-9]" build/adder8_generic_stat.txt
    check "adder8_pipe มี 26 flip-flop"      'SDFF_PP0_ +26'            build/adder8_pipe_generic_stat.txt
else
    echo "  [FAIL] make synth ล้มเหลว"
    FAILED=$((FAILED+1))
fi
echo

# ─────────────────────────────────────────────────────── 3. gate-level map ──
step "Yosys Gate-Level Mapping"
if make synth-gate > build_log_gate.txt 2>&1; then
    checkfile "สร้าง netlist adder8_gates.v"       build/adder8_gates.v
    checkfile "สร้าง netlist adder8_pipe_gates.v" build/adder8_pipe_gates.v
    grep -E "Number of cells" build/adder8_gates_stat.txt | sed 's/^/  /'
    grep -E "Number of cells" build/adder8_pipe_gates_stat.txt | sed 's/^/  /'
else
    echo "  [FAIL] make synth-gate ล้มเหลว"
    FAILED=$((FAILED+1))
fi
echo

# ────────────────────────────────────────────────────────────── 4. GLS ──────
step "Gate-Level Simulation ของ netlist ที่ Yosys สร้าง"
if make sim-gls > build_log_gls.txt 2>&1; then
    grep -E "PASS=|ALL " build_log_gls.txt | sed 's/^/  /'
    check "netlist ผ่านทุก pattern เท่ากับ RTL" "tb_adder8 PASS=131072 FAIL=0" build_log_gls.txt
else
    echo "  [FAIL] make sim-gls ล้มเหลว"
    FAILED=$((FAILED+1))
fi
echo

# ─────────────────────────────────────────────────── 5. VHDL -> Yosys ──────
if [ "$HAVE_GHDL" = "1" ]; then
    step "สะพาน VHDL -> GHDL -> Verilog -> Yosys"
    if make ghdl > build_log_ghdl.txt 2>&1; then
        grep -E "PASS=|Number of cells" build_log_ghdl.txt | sed 's/^/  /'
        check "netlist ที่ได้จาก VHDL ผ่านทุก pattern" "tb_adder8 PASS=131072 FAIL=0" build_log_ghdl.txt
    else
        echo "  [FAIL] make ghdl ล้มเหลว"
        FAILED=$((FAILED+1))
    fi
    echo
fi

# ─────────────────────────────────────────────────────── 6. sky130 mapping ──
step "Yosys -> sky130 standard cell"
SKY130_LIB=$(ls /root/.ciel/ciel/sky130/versions/*/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib 2>/dev/null | head -1)
if [ -n "$SKY130_LIB" ]; then
    if make sky130 SKY130_LIB="$SKY130_LIB" > build_log_sky130.txt 2>&1; then
        grep -E "Number of cells|Chip area" build_log_sky130.txt | sed 's/^/  /'
        check "ได้พื้นที่จริงจาก liberty" "Chip area for module" build_log_sky130.txt
    else
        echo "  [FAIL] make sky130 ล้มเหลว"
        FAILED=$((FAILED+1))
    fi
else
    echo "  [SKIP] ยังไม่มี PDK sky130 - รัน 'make librelane' ก่อนเพื่อติดตั้ง"
fi
echo

# ─────────────────────────────────────────────────────── 7. LibreLane flow ──
if [ "$MODE" = "--full" ] || [ "$MODE" = "--librelane" ]; then
    step "LibreLane full flow (RTL -> GDSII)"
    if [ "$HAVE_LL" = "0" ]; then
        echo "  [SKIP] ไม่พบคำสั่ง librelane"
    else
        ( cd librelane && librelane --volare-pdk -p sky130A config.yaml ) > build_log_librelane.txt 2>&1
        if [ $? -eq 0 ]; then
            grep -E "Stage 80|DRC|LVS|Antenna|Passed" build_log_librelane.txt | tail -12 | sed 's/^/  /'
            RUN=$(ls -dt librelane/runs/RUN_* 2>/dev/null | head -1)
            if [ -n "$RUN" ] && [ -f "$RUN/final/metrics.json" ]; then
                python3 - "$RUN/final/metrics.json" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
def g(k,d="n/a"): return m.get(k,d)
print(f"  instance count : {g('design__instance__count')}")
print(f"  instance area  : {g('design__instance__area')} um^2")
print(f"  die area       : {g('design__die__area')} um^2")
print(f"  utilization    : {g('design__instance__utilization')}")
print(f"  setup slack    : {g('timing__setup__ws')} ns  (violations {g('design__violations')})")
print(f"  hold slack     : {g('timing__hold__ws')} ns")
PY
            fi
        else
            echo "  [FAIL] LibreLane flow ล้มเหลว — ดู build_log_librelane.txt"
            FAILED=$((FAILED+1))
        fi
    fi
    echo
fi

# ─────────────────────────────────────────────────────────────── summary ────
hr
if [ "$FAILED" -eq 0 ]; then
    echo "สรุป: ผ่านทั้งหมด — ไม่มีขั้นตอนไหนล้มเหลว"
    exit 0
else
    echo "สรุป: มี $FAILED ขั้นตอนที่ไม่ผ่าน"
    exit 1
fi

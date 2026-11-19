#!/bin/bash
# ===========================================================================
# scripts/run_reference_flow.sh
#
# Open-source REFERENCE flow for the Lab 3A designs.  It runs completely
# offline with free tools:
#
#   GHDL 5.0.1   VHDL  -> behavioural Verilog
#   Yosys 0.52   synthesis + mapping into the sky130A standard cell library
#   OpenSTA      static timing analysis on the mapped netlist
#   Yosys        formal equivalence between the RTL and the generic netlist
#   Icarus       gate-level simulation with the sky130A Verilog cell models
#
# WHY THIS EXISTS
#   Precision RTL is a commercial tool and needs a licence, and every
#   student does NOT use the same technology library.  This flow produces a
#   BASELINE with a public PDK (sky130A) so that the numbers can be
#   compared, discussed and reproduced by everybody - including on a machine
#   where Precision is not installed.
#
#   The numbers produced here are NOT Precision numbers.  They are the
#   reference values that you compare your Precision run against.
#
# Usage
#   bash scripts/run_reference_flow.sh              # all designs
#   bash scripts/run_reference_flow.sh top          # one design
#
# Environment overrides
#   GHDL, YOSYS, STA, IVERILOG, VVP, SKY130_LIB, SKY130_VERILOG
# ===========================================================================

set -u
cd "$(dirname "$0")/.." || exit 1
LAB="$(pwd)"
BUILD="$LAB/build"
REPORTS="$LAB/reports"
mkdir -p "$BUILD" "$REPORTS"

GHDL=${GHDL:-ghdl}
YOSYS=${YOSYS:-yosys}
IVERILOG=${IVERILOG:-iverilog}
VVP=${VVP:-vvp}
SKY130_LIB=${SKY130_LIB:-$(ls -1 /root/.ciel/ciel/sky130/versions/*/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib 2>/dev/null | head -1)}
SKY130_VERILOG=${SKY130_VERILOG:-$(ls -1 /root/.ciel/ciel/sky130/versions/*/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v 2>/dev/null | head -1)}
SKY130_PRIMITIVES=${SKY130_PRIMITIVES:-$(ls -1 /root/.ciel/ciel/sky130/versions/*/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v 2>/dev/null | head -1)}
STA=${STA:-$(ls -1 /nix/store/*-opensta/bin/sta 2>/dev/null | head -1)}

echo "================================================================"
echo " Lab 3A - open-source reference synthesis flow"
echo "================================================================"
echo "  GHDL        : $(command -v "$GHDL" || echo MISSING)"
echo "  Yosys       : $(command -v "$YOSYS" || echo MISSING)"
echo "  OpenSTA     : ${STA:-MISSING}"
echo "  Icarus      : $(command -v "$IVERILOG" || echo MISSING)"
echo "  Liberty     : ${SKY130_LIB:-MISSING}"
echo "  Cell models : ${SKY130_VERILOG:-MISSING}"
echo "  UDP models  : ${SKY130_PRIMITIVES:-MISSING}"
echo

if [ -z "$SKY130_LIB" ] || [ ! -f "$SKY130_LIB" ]; then
    echo "ERROR: the sky130A Liberty file was not found."
    echo "       Set SKY130_LIB=/path/to/sky130_fd_sc_hd__tt_025C_1v80.lib"
    exit 2
fi
if [ -z "$STA" ] || [ ! -x "$STA" ]; then
    echo "ERROR: OpenSTA was not found.  Set STA=/path/to/sta"
    exit 2
fi

# ---------------------------------------------------------------------------
# Step 0 - build the filtered Liberty
#
# `abc -liberty` maps a gate to whatever cell in the Liberty has the best
# area/delay.  The sky130A library contains cells that look like ordinary
# 2-input gates to ABC but are NOT ordinary gates - for example
# sky130_fd_sc_hd__lpflow_inputiso1p_1, which is an ISOLATION cell
# (is_isolation_cell : "true", function X = A & !SLEEP).  ABC maps a 2-input
# OR to it, the netlist compiles, the area report looks plausible - and the
# circuit computes "a AND NOT b" instead of "a OR b".
#
# The fix is to mark those cells with `dont_use : true ;` so that ABC never
# selects them.  This is what every production open-source flow does.
# ---------------------------------------------------------------------------
FILTERED_LIB="$BUILD/sky130_filtered.lib"
echo "----------------------------------------------------------------"
echo " Step 0: building the filtered Liberty (dont_use list)"
echo "----------------------------------------------------------------"
python3 "$LAB/scripts/make_filtered_liberty.py" "$SKY130_LIB" "$FILTERED_LIB" \
    > "$REPORTS/liberty_filter.log" 2>&1
if [ ! -s "$FILTERED_LIB" ]; then
    echo "ERROR: could not build the filtered Liberty - see reports/liberty_filter.log"
    exit 2
fi
grep -E '^(cells|cells marked)' "$REPORTS/liberty_filter.log"
echo

# ---------------------------------------------------------------------------
# design table:  name | VHDL sources | top | SDC | GLS testbench
# ---------------------------------------------------------------------------
ALL_DESIGNS=(
    "adder8|rtl/full_adder_struct.vhd rtl/adder8.vhd|adder8|adder8|tb/tb_gls_adder8.v"
    "adder8_pipelined|rtl/adder8_pipelined.vhd|adder8_pipelined|adder8_pipelined|tb/tb_gls_adder8_pipelined.v"
    "add_sub_shared|rtl/add_sub_shared.vhd|add_sub_shared|add_sub_shared|tb/tb_gls_add_sub_shared.v"
    "top|rtl/full_adder_struct.vhd rtl/adder8.vhd rtl/adder8_pipelined.vhd rtl/add_sub_shared.vhd rtl/top.vhd|top|top|tb/tb_gls_top.v"
)

SELECTED=${1:-}
if [ -n "$SELECTED" ]; then
    FILTERED=()
    for d in "${ALL_DESIGNS[@]}"; do
        case "$d" in
            "$SELECTED|"*) FILTERED+=("$d") ;;
        esac
    done
    ALL_DESIGNS=("${FILTERED[@]}")
fi

SUMMARY="$REPORTS/summary.txt"
{
    echo "Lab 3A - reference flow summary (open-source baseline)"
    echo "generated by scripts/run_reference_flow.sh"
    echo "GHDL    : $("$GHDL" --version 2>&1 | head -1)"
    echo "Yosys   : $("$YOSYS" -V 2>&1 | head -1)"
    echo "OpenSTA : $("$STA" -version 2>&1 | head -1)"
    echo "Icarus  : $("$IVERILOG" -V 2>&1 | head -1)"
    echo "Liberty : $FILTERED_LIB"
    echo ""
    printf '%-18s %7s %7s %13s %11s %11s %9s %6s\n' \
           "design" "gen_cl" "sky_cl" "area_um2" "slack_max" "slack_min" "equiv" "gls"
    printf '%-18s %7s %7s %13s %11s %11s %9s %6s\n' \
           "------------------" "-------" "-------" "-------------" "-----------" \
           "-----------" "---------" "------"
} > "$SUMMARY"

FAILED=0
PROCESSED=0

for entry in "${ALL_DESIGNS[@]}"; do
    NAME="${entry%%|*}";    REST="${entry#*|}"
    SRCS="${REST%%|*}";    REST2="${REST#*|}"
    TOP="${REST2%%|*}";    REST3="${REST2#*|}"
    SDCNAME="${REST3%%|*}"; GLSTB="${REST3#*|}"

    echo ""
    echo "================================================================"
    echo " DESIGN: $NAME   (top = $TOP)"
    echo "================================================================"

    # ---- 1. VHDL -> Verilog ------------------------------------------------
    VH="$BUILD/${NAME}_vhdl.v"
    # shellcheck disable=SC2086
    if "$GHDL" synth --std=08 --out=verilog $SRCS -e "$TOP" > "$VH" 2>"$BUILD/${NAME}_ghdl.log"; then
        echo "[1/6] GHDL synth            : $(wc -l < "$VH") lines of Verilog"
    else
        echo "[1/6] GHDL synth FAILED - see build/${NAME}_ghdl.log"
        sed -n '1,10p' "$BUILD/${NAME}_ghdl.log"
        FAILED=$((FAILED + 1))
        printf '%-18s %7s %7s %13s %11s %11s %9s %6s\n' "$NAME" "GHDL-FAIL" "-" "-" "-" "-" "-" "-"
        continue
    fi

    # ---- 2. generic synthesis ---------------------------------------------
    GEN="$BUILD/${NAME}_generic.v"
    GLOG="$REPORTS/${NAME}_yosys_generic.rpt"
    if "$YOSYS" -Q -p "
            read_verilog $VH
            hierarchy -check -top $TOP
            synth -top $TOP
            check -assert
            stat
            write_verilog -noattr $GEN
         " > "$GLOG" 2>&1; then
        GCELLS=$(grep -E '^\s+Number of cells:' "$GLOG" | tail -1 | awk '{print $NF}')
        echo "[2/6] Yosys generic synth   : $GCELLS cells"
    else
        echo "[2/6] Yosys generic synth FAILED - see $GLOG"
        FAILED=$((FAILED + 1))
        GCELLS="-"
    fi

    # ---- 3. map into the sky130A standard cells ---------------------------
    NET="$BUILD/${NAME}_sky130.v"
    SLOG="$REPORTS/${NAME}_yosys_sky130.rpt"
    if "$YOSYS" -Q -p "
            read_verilog $VH
            hierarchy -check -top $TOP
            synth -top $TOP -noabc
            dfflibmap -liberty $FILTERED_LIB
            abc -liberty $FILTERED_LIB
            opt_clean
            stat -liberty $FILTERED_LIB
            write_verilog -noattr $NET
         " > "$SLOG" 2>&1; then
        SCELLS=$(grep -E '^\s+Number of cells:' "$SLOG" | tail -1 | awk '{print $NF}')
        # the area line is printed as
        #   "Chip area for module '\adder8_pipelined': 954.665600"     (flat design)
        #   "Chip area for top module '\adder8': 290.278400"          (hierarchical)
        AREA=$(grep -E "Chip area for (top )?module '\\\\$TOP'" "$SLOG" | tail -1 | awk '{print $NF}')
        echo "[3/6] Yosys -> sky130A      : $SCELLS cells, area $AREA um^2"
    else
        echo "[3/6] Yosys -> sky130A FAILED - see $SLOG"
        FAILED=$((FAILED + 1))
        SCELLS="-"; AREA="-"
    fi

    # ---- 4. static timing analysis ----------------------------------------
    STAREP="$REPORTS/${NAME}_sta.rpt"
    SMAX="-"; SMIN="-"
    if [ -f "$NET" ]; then
        NETLIST="$NET" TOP="$TOP" LIB="$FILTERED_LIB" \
        SDC="$LAB/sdc/${SDCNAME}.sdc" OUT="$STAREP" \
        "$STA" -exit "$LAB/scripts/run_sta.tcl" > "$BUILD/${NAME}_sta.log" 2>&1
        if [ -s "$STAREP" ]; then
            # the report has one "worst_slack_max:" label followed by the
            # value on the NEXT line - read exactly that line, otherwise the
            # value of the following field is picked up as well
            SMAX=$(awk '/^worst_slack_max:/{getline; print; exit}' "$STAREP" \
                   | grep -Eo '[-+]?[0-9]+\.[0-9]+' | head -1)
            SMIN=$(awk '/^worst_slack_min:/{getline; print; exit}' "$STAREP" \
                   | grep -Eo '[-+]?[0-9]+\.[0-9]+' | head -1)
            echo "[4/6] OpenSTA               : setup slack ${SMAX:-?} ns, hold slack ${SMIN:-?} ns"
        else
            echo "[4/6] OpenSTA FAILED - see $BUILD/${NAME}_sta.log"
            FAILED=$((FAILED + 1))
        fi
    fi

    # ---- 5. formal equivalence RTL <-> generic netlist ---------------------
    EQLOG="$REPORTS/${NAME}_equivalence.rpt"
    EQ="n/a"
    if [ -f "$GEN" ] && [ -f "$VH" ]; then
        HAS_DFF=$(grep -cE '\$dff|\$_DFF' "$GLOG" 2>/dev/null || echo 0)
        if [ "$HAS_DFF" -gt 0 ]; then
            EQ_STEPS="equiv_simple -seq 5
    equiv_induct -seq 5"
        else
            EQ_STEPS="equiv_simple -seq 5"
        fi
        if timeout 300 "$YOSYS" -Q -p "
                read_verilog $VH
                prep -top $TOP -flatten
                memory_map
                opt_clean
                design -stash gold

                read_verilog $GEN
                prep -top $TOP -flatten
                memory_map
                opt_clean
                design -stash gate

                design -copy-from gold -as gold $TOP
                design -copy-from gate -as gate $TOP
                equiv_make gold gate equiv
                hierarchy -top equiv
                $EQ_STEPS
                equiv_status -assert
             " > "$EQLOG" 2>&1; then
            EQ="PROVEN"
            echo "[5/6] Formal equivalence    : PROVEN (RTL == netlist)"
        else
            EQ="NOT-PROVEN"
            echo "[5/6] Formal equivalence    : NOT PROVEN - see $EQLOG"
            FAILED=$((FAILED + 1))
        fi
    fi

    # ---- 6. gate-level simulation ------------------------------------------
    GLS="n/a"
    if [ -n "$GLSTB" ] && [ -f "$NET" ] && [ -f "$SKY130_VERILOG" ]; then
        VVPF="$BUILD/${NAME}_gls.vvp"
        GLSLOG="$REPORTS/${NAME}_gls.rpt"
        # Two things are needed here:
        #
        # 1) primitives.v holds the User Defined Primitives (udp_dff, udp_mux,
        #    ...) that the cell models in sky130_fd_sc_hd.v instantiate.
        #    Without it iverilog stops with
        #       error: Unknown module type: sky130_fd_sc_hd__udp_dff$NSR_pp$PG$N
        #
        # 2) -D FUNCTIONAL selects the FUNCTIONAL cell models.  Without that
        #    macro the PDK file compiles the TIMING models, whose clock and
        #    data path is driven by a `specify` block.  Icarus does not
        #    support timing checks and leaves CLK_delayed / D_delayed at X:
        #       warning: Timing checks are not supported and delayed signal
        #                 "CLK_delayed" will not be driven.
        #    Every flip-flop output then stays X and the whole circuit looks
        #    broken even though the netlist is correct.
        if "$IVERILOG" -g2012 -D FUNCTIONAL -o "$VVPF" "$NET" \
                       "$SKY130_PRIMITIVES" "$SKY130_VERILOG" "$GLSTB" \
                       > "$BUILD/${NAME}_gls_build.log" 2>&1; then
            if "$VVP" "$VVPF" > "$GLSLOG" 2>&1; then
                if grep -q "FAIL" "$GLSLOG"; then
                    GLS="FAIL"
                    echo "[6/6] Gate-level simulation : FAIL - see $GLSLOG"
                    FAILED=$((FAILED + 1))
                else
                    GLS="PASS"
                    echo "[6/6] Gate-level simulation : PASS ($(grep -o 'GLS [^:]*: PASS.*' "$GLSLOG" | head -1))"
                fi
            else
                GLS="ERROR"
                echo "[6/6] Gate-level simulation : ERROR - see $GLSLOG"
                FAILED=$((FAILED + 1))
            fi
        else
            GLS="BUILD-ERR"
            echo "[6/6] Gate-level simulation : BUILD ERROR - see $BUILD/${NAME}_gls_build.log"
            FAILED=$((FAILED + 1))
        fi
    fi

    printf '%-18s %7s %7s %13s %11s %11s %9s %6s\n' "$NAME" \
           "${GCELLS:--}" "${SCELLS:--}" "${AREA:--}" "${SMAX:--}" "${SMIN:--}" \
           "$EQ" "$GLS" >> "$SUMMARY"
    PROCESSED=$((PROCESSED + 1))
done

{
    echo ""
    echo "designs processed : $PROCESSED"
    echo "failures          : $FAILED"
    echo ""
    echo "How to read this table"
    echo "  gen_cl   : number of generic cells after Yosys 'synth'"
    echo "  sky_cl   : number of cells after mapping into the sky130A library"
    echo "  area_um2 : chip area of the top module in um^2"
    echo "  slack_max: worst setup slack in ns (positive = timing met)"
    echo "  slack_min: worst hold slack in ns"
    echo "  equiv    : formal equivalence between the RTL and the netlist"
    echo "  gls      : gate-level simulation with the sky130A cell models"
} >> "$SUMMARY"

echo ""
echo "================================================================"
echo " summary written to reports/summary.txt"
echo " designs processed : $PROCESSED"
echo " failures          : $FAILED"
echo "================================================================"
cat "$SUMMARY"

[ "$FAILED" -eq 0 ]

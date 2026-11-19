#!/usr/bin/env python3
# ===========================================================================
# scripts/make_filtered_liberty.py
#
# Build a filtered copy of a Liberty file in which the cells that must never
# be used for logic mapping are marked with  `dont_use : true ;`.
#
# WHY
# ---
# `abc -liberty` maps a generic gate to WHATEVER cell in the Liberty file
# has the smallest area / best delay.  The sky130A library contains cells
# that look like ordinary 2-input gates to ABC but are NOT ordinary gates:
#
#   sky130_fd_sc_hd__lpflow_inputiso1p_1   area 6.256
#       is_isolation_cell : "true"
#       function: X = A & !SLEEP        <- an isolation cell, not an OR gate
#
# ABC happily maps a 2-input OR to that cell.  The result is a netlist that
# compiles, passes `check -assert`, has a plausible cell count and a
# plausible area - and is FUNCTIONALLY WRONG.
#
# This was observed while building the Lab 3A reference flow:
#   or_gate  ->  sky130_fd_sc_hd__lpflow_inputiso1p_1  (.A(a) .SLEEP(b) .X(y))
# The structural OR of the ripple-carry adder became "a AND NOT b".
#
# The formal equivalence check (equiv_make / equiv_induct) caught it, and
# so does a gate-level simulation.  Neither `check -assert` nor the area
# report would.
#
# The fix is the same one every production open-source flow uses: mark the
# unusable cells with `dont_use` so that ABC never selects them.
#
# USAGE
#   python3 scripts/make_filtered_liberty.py <input.lib> <output.lib>
#
# Exit code 0 = success.
# ===========================================================================

import re
import sys


def classify(cell_name, block):
    """
    Return (dont_use, reason).
    """
    low = cell_name.lower()

    # 1. low-power flow cells (isolation / retention / level shifter)
    if "lpflow" in low:
        return True, "low-power flow cell"
    for attr in ("is_isolation_cell", "is_retention_cell",
                 "is_level_shifter", "is_clock_gating_cell"):
        if re.search(attr + r'\s*:\s*"true"', block):
            return True, attr

    # 2. cells without any timing function: filler, taps, diodes, decaps
    has_function = re.search(r"\bfunction\s*:", block) is not None
    has_ff = re.search(r"\bff\s*\(", block) is not None
    has_latch = re.search(r"\blatch\s*\(", block) is not None
    if not (has_function or has_ff or has_latch):
        return True, "no timing function (fill / tap / decap / diode)"

    return False, ""


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 2

    src, dst = sys.argv[1], sys.argv[2]
    with open(src, "r", encoding="utf-8", errors="replace") as fh:
        lines = fh.read().splitlines()

    out = []
    i = 0
    marked = {}
    total_cells = 0

    cell_re = re.compile(r'^(\s*)cell\s*\("([^"]+)"\)\s*\{')

    while i < len(lines):
        line = lines[i]
        m = cell_re.match(line)
        if not m:
            out.append(line)
            i += 1
            continue

        indent, name = m.group(1), m.group(2)
        total_cells += 1

        # collect the block until the matching closing brace
        depth = 0
        block_lines = []
        j = i
        while j < len(lines):
            block_lines.append(lines[j])
            depth += lines[j].count("{") - lines[j].count("}")
            if depth == 0 and j > i:
                break
            j += 1
        block = "\n".join(block_lines)

        dont_use, reason = classify(name, block)
        if dont_use:
            marked[name] = reason
        # the header line first, then the (optional) dont_use attribute, then
        # the rest of the cell block - the block must be written COMPLETELY,
        # otherwise the closing brace of the cell is lost and the whole
        # Liberty file becomes unparsable
        out.append(block_lines[0])
        if dont_use:
            out.append('%sdont_use : true ;' % indent)
        out.extend(block_lines[1:])
        i = j + 1

    with open(dst, "w", encoding="utf-8") as fh:
        fh.write("\n".join(out))
        fh.write("\n")

    print("filtered liberty written : %s" % dst)
    print("cells in the source      : %d" % total_cells)
    print("cells marked dont_use    : %d" % len(marked))
    print("")
    print("dont_use list:")
    for name in sorted(marked):
        print("  %-58s %s" % (name, marked[name]))
    return 0


if __name__ == "__main__":
    sys.exit(main())

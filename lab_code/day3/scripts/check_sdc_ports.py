#!/usr/bin/env python3
# ===========================================================================
# scripts/check_sdc_ports.py
# Cross-check the ports used in an SDC file against the ports that really
# exist in the VHDL entity.
#
# WHY THIS TOOL EXISTS
# --------------------
# In SDC, `get_ports clk` returns an EMPTY collection when the design has no
# `clk` port. An empty collection does not raise an error - the constraint
# is simply dropped. The synthesis run "succeeds", the timing report is
# printed, and it contains no constrained path at all. This is the single
# most common silent failure in a synthesis lab.
#
# The original lab_code/day3/constraints.sdc had exactly this bug:
#   create_clock ... [get_ports clk]        <- entity `top` had NO clk port
#   set_false_path -from [get_ports rst]    <- entity `top` had NO rst port
#
# USAGE
#   python3 scripts/check_sdc_ports.py --vhdl rtl/top.vhd --sdc sdc/top.sdc
#   python3 scripts/check_sdc_ports.py --design top      (uses the naming
#                                                       convention below)
#
# Exit code 0 = no ERROR, 1 = at least one ERROR.
#
# Requires: Python 3.8+  (no third-party packages)
# ===========================================================================

import argparse
import os
import re
import sys

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

def strip_vhdl_comments(src):
    """Remove -- comments (VHDL has no block comments)."""
    return re.sub(r"--[^\n]*", "", src)


def strip_sdc_comments(src):
    """Remove # comments that start a line (after optional whitespace)."""
    return re.sub(r"(?m)^[ \t]*#[^\n]*", "", src)


def parse_vhdl_entity(path):
    """
    Return (entity_name, [(port, direction), ...]) for the first entity
    declaration found in `path`.
    """
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        src = strip_vhdl_comments(fh.read())

    m = re.search(r"\bentity\s+(\w+)\s+is\b", src, re.I)
    if not m:
        return None, []
    ent_name = m.group(1)
    rest = src[m.end():]

    pm = re.search(r"\bport\s*\(", rest, re.I)
    if not pm:
        return ent_name, []

    # find the matching closing parenthesis of the port clause
    start = pm.end() - 1
    depth = 0
    body = None
    for j in range(start, len(rest)):
        ch = rest[j]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                body = rest[start + 1:j]
                break
    if body is None:
        return ent_name, []

    ports = []
    for decl in body.split(";"):
        decl = decl.strip()
        if not decl or ":" not in decl:
            continue
        names_part, rest2 = decl.split(":", 1)
        dm = re.match(r"\s*(inout|in|out|buffer|linkage)\b", rest2, re.I)
        direction = dm.group(1).lower() if dm else "in"
        for nm in names_part.split(","):
            nm = nm.strip()
            if re.fullmatch(r"\w+", nm):
                ports.append((nm, direction))
    return ent_name, ports


def normalise_port(name):
    """
    'a[7]' / 'a[*]' / 'a[0]' -> 'a'  so that a bus reference and the
    entity declaration of the bus are considered the same port.
    """
    return re.sub(r"\[.*?\]", "", name).strip()


def parse_sdc_ports(path):
    """
    Return the set of port names referenced by get_ports in an SDC file.
    """
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        src = strip_sdc_comments(fh.read())

    used = set()
    # get_ports {a b c}   |  get_ports a   |  get_ports "a"  |  get_ports [a]
    pattern = re.compile(r"get_ports\s*(\{[^}]*\}|\[[^\]]*\]|\"[^\"]*\"|[^\s\]\)]+)")
    for m in pattern.finditer(src):
        tok = m.group(1)
        if tok.startswith("{") or tok.startswith("["):
            inner = tok[1:-1]
        elif tok.startswith("\""):
            inner = tok[1:-1]
        else:
            inner = tok
        for p in inner.split():
            p = p.strip()
            if p:
                used.add(normalise_port(p))
    return used


def parse_create_clock_ports(path):
    """
    Return (targets, count) where
      targets : port names used as the target of create_clock
      count   : number of create_clock commands in the file
    A create_clock WITHOUT a port target is a *virtual* clock - legal and
    intentional for a purely combinational block.
    """
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        src = strip_sdc_comments(fh.read())

    targets = set()
    count = 0
    for m in re.finditer(r"create_clock\b[^\n]*", src):
        count += 1
        line = m.group(0)
        pm = re.search(r"get_ports\s*(\{[^}]*\}|\"[^\"]*\"|[^\s\]\)]+)", line)
        if not pm:
            continue
        tok = pm.group(1)
        inner = tok[1:-1] if tok[0] in "{[" else tok.strip('"')
        for p in inner.split():
            p = p.strip()
            if p:
                targets.add(normalise_port(p))
    return targets, count


# ---------------------------------------------------------------------------
# main check
# ---------------------------------------------------------------------------

def check(vhdl_path, sdc_path, verbose=False):
    ent_name, ports = parse_vhdl_entity(vhdl_path)
    if ent_name is None:
        print("ERROR  : no entity declaration found in %s" % vhdl_path)
        return 1
    if not ports:
        print("ERROR  : entity '%s' in %s has no port clause" % (ent_name, vhdl_path))
        return 1

    entity_ports = {p for p, _ in ports}
    direction = dict(ports)
    sdc_used = parse_sdc_ports(sdc_path)
    clk_targets, clk_count = parse_create_clock_ports(sdc_path)

    errors = 0
    warnings = 0

    print("=" * 74)
    print("SDC / VHDL port cross-check")
    print("  VHDL : %s   (entity '%s', %d ports)" % (vhdl_path, ent_name, len(ports)))
    print("  SDC  : %s   (%d distinct get_ports names)" % (sdc_path, len(sdc_used)))
    print("=" * 74)

    # --- 1. ports used in SDC that do not exist in the entity ---------------
    unknown = sorted(sdc_used - entity_ports)
    for p in unknown:
        print("ERROR  : SDC references port '%s' but entity '%s' has no such port"
              % (p, ent_name))
        errors += 1
    if not unknown:
        print("OK     : every get_ports name in the SDC exists in the entity")

    # --- 2. create_clock target ---------------------------------------------
    if clk_count == 0:
        print("WARN   : the SDC has no create_clock -> no constrained timing path")
        warnings += 1
    elif not clk_targets:
        print("OK     : %d virtual clock(s) in the SDC (no port target) - "
              "legal for a combinational block" % clk_count)
    for p in sorted(clk_targets):
        if p not in entity_ports:
            print("ERROR  : create_clock is attached to port '%s' which does not "
                  "exist in entity '%s'" % (p, ent_name))
            errors += 1
        else:
            print("OK     : create_clock is attached to port '%s' (exists)" % p)

    # --- 3. entity ports that the SDC never mentions -----------------------
    uncovered = sorted(entity_ports - sdc_used)
    for p in uncovered:
        kind = direction.get(p, "?")
        print("WARN   : port '%s' (%s) of entity '%s' is not constrained by the SDC"
              % (p, kind, ent_name))
        warnings += 1
    if not uncovered:
        print("OK     : every port of the entity is constrained by the SDC")

    print("-" * 74)
    print("RESULT : %d error(s), %d warning(s)" % (errors, warnings))
    print("=" * 74)
    return 1 if errors else 0


def selftest():
    """
    Reproduce the exact bug that existed in the original
    lab_code/day3/constraints.sdc and prove that this checker catches it.

    The original entity `top` of the lab had only these ports:
        a, b : in  std_logic_vector(7 downto 0)
        cin  : in  std_logic
        sum  : out std_logic_vector(7 downto 0)
        cout : out std_logic
    but the original constraints.sdc constrained `clk` and `rst`, which
    that entity does not have.
    """
    import tempfile

    old_vhdl = """\
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
    port (
        a, b : in  std_logic_vector(7 downto 0);
        cin  : in  std_logic;
        sum  : out std_logic_vector(7 downto 0);
        cout : out std_logic
    );
end entity top;

architecture struct of top is
begin
end architecture struct;
"""

    old_sdc = """\
create_clock -name sys_clk -period 10.0 -waveform {0 5} [get_ports clk]
set_input_delay  -clock sys_clk 2.0 -max [get_ports {a b cin}]
set_output_delay -clock sys_clk 2.0 -max [get_ports {sum cout}]
set_false_path -from [get_ports rst]
"""

    tmp = tempfile.mkdtemp(prefix="sdc_check_")
    vhdl_path = os.path.join(tmp, "top.vhd")
    sdc_path = os.path.join(tmp, "constraints.sdc")
    with open(vhdl_path, "w", encoding="utf-8") as fh:
        fh.write(old_vhdl)
    with open(sdc_path, "w", encoding="utf-8") as fh:
        fh.write(old_sdc)

    print("### SELFTEST: reproduce the historical Lab 3A SDC bug ###")
    print("-" * 74)
    rc = check(vhdl_path, sdc_path)
    print("-" * 74)
    if rc == 1:
        print("SELFTEST PASSED : the checker rejected the buggy SDC "
              "(exit code 1, errors reported above)")
        return 0
    print("SELFTEST FAILED : the checker did NOT catch the historical bug")
    return 1


def main():
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    ap = argparse.ArgumentParser(
        description="Cross-check SDC get_ports against the VHDL entity ports.")
    ap.add_argument("--vhdl", help="path to the VHDL file holding the entity")
    ap.add_argument("--sdc", help="path to the SDC file")
    ap.add_argument("--design", help="design name; uses rtl/<design>.vhd and "
                                     "sdc/<design>.sdc under the lab folder")
    ap.add_argument("--selftest", action="store_true",
                    help="run the built-in regression test on the historical "
                         "Lab 3A SDC bug and exit")
    ap.add_argument("-v", "--verbose", action="store_true")
    args = ap.parse_args()

    if args.selftest:
        return selftest()

    vhdl = args.vhdl
    sdc = args.sdc
    if args.design:
        vhdl = vhdl or os.path.join(here, "rtl", args.design + ".vhd")
        sdc = sdc or os.path.join(here, "sdc", args.design + ".sdc")

    if not vhdl or not sdc:
        ap.error("need --vhdl/--sdc or --design")
    if not os.path.isfile(vhdl):
        print("ERROR  : VHDL file not found: %s" % vhdl)
        return 2
    if not os.path.isfile(sdc):
        print("ERROR  : SDC file not found: %s" % sdc)
        return 2

    return check(vhdl, sdc, args.verbose)


if __name__ == "__main__":
    sys.exit(main())

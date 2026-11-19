#!/usr/bin/env python3
# ===========================================================================
# scripts/check_precision_tcl.py
# Static checker for the Precision RTL batch scripts of Lab 3A.
#
# It catches the mistakes that a Tcl script makes silently:
#
#   1. A file that add_source / add_constraint_file refers to does not exist.
#      The original lab_code/day3/synth.tcl did exactly this:
#          set rtl_dir "."
#          add_source ... "$rtl_dir/full_adder_struct.vhd"
#      but full_adder_struct.vhd lives in lab_code/day2/, not in day3/,
#      so the script died on the FIRST add_source.
#
#   2. Unbalanced braces or quotes -> the script is a syntax error.
#
#   3. set_top_module names an entity that does not exist in rtl/.
#
#   4. The SDC that the script loads does not match the ports of the entity
#      that the script sets as top (delegated to check_sdc_ports.py).
#
#   5. The technology library is still the placeholder value.
#
# USAGE
#    python3 scripts/check_precision_tcl.py            # check every .tcl
#    python3 scripts/check_precision_tcl.py scripts/synth_top.tcl
#    python3 scripts/check_precision_tcl.py --selftest
#
# Exit code 0 = no ERROR, 1 = at least one ERROR.
# Requires: Python 3.8+ (no third-party packages)
# ===========================================================================

import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_sdc_ports import (parse_vhdl_entity, parse_sdc_ports,   # noqa: E402
                             normalise_port)

LAB_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# the placeholder technology library that every script starts with
PLACEHOLDER_TECH = {"gscl45nm"}

# scripts that are NOT Precision RTL batch scripts and therefore do not have
# to contain add_source / set_top_module
SKIP_SCRIPTS = {"run_sta.tcl"}


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

def strip_tcl_comments(src):
    """Remove # comments that are not inside a quoted string."""
    out = []
    for line in src.splitlines():
        # remove a trailing comment only when the # is outside quotes
        in_q = False
        cut = len(line)
        for i, ch in enumerate(line):
            if ch == '"':
                in_q = not in_q
            elif ch == "#" and not in_q:
                cut = i
                break
        out.append(line[:cut])
    return "\n".join(out)


def check_balance(src):
    """Return a list of imbalance problems (braces / brackets / quotes)."""
    problems = []
    depth = 0
    paren = 0
    in_q = False
    line_no = 1
    for ch in src:
        if ch == "\n":
            line_no += 1
        if in_q:
            if ch == '"':
                in_q = False
            continue
        if ch == '"':
            in_q = True
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth < 0:
                problems.append("line %d: closing '}' without a matching '{'" % line_no)
                depth = 0
        elif ch == "[":
            paren += 1
        elif ch == "]":
            paren -= 1
            if paren < 0:
                problems.append("line %d: closing ']' without a matching '['" % line_no)
                paren = 0
    if depth != 0:
        problems.append("script ends with %d unclosed '{'" % depth)
    if paren != 0:
        problems.append("script ends with %d unclosed '['" % paren)
    if in_q:
        problems.append("script ends inside an unterminated quoted string")
    return problems


def expand_path(token, script_dir, vars_=None):
    """
    Turn the string that is inside a Tcl double quote into a real path.
    $lab_dir    -> the lab folder (parent of scripts/)
    $script_dir -> the folder that holds the script
    any other $NAME -> the value of the matching `set NAME ...`
    A relative path is resolved against the lab folder.
    """
    if vars_:
        token = resolve_vars(token, vars_)
    t = token.replace("$lab_dir", LAB_DIR).replace("$script_dir", script_dir)
    t = t.replace("/", os.sep)
    if not os.path.isabs(t):
        t = os.path.join(LAB_DIR, t)
    return os.path.normpath(t)


def quoted_args(line):
    """Return every "..." string found in a Tcl line."""
    return re.findall(r'"([^"]*)"', line)


# variables that are computed by the script itself - they must not be
# substituted by their literal source text
RESERVED_VARS = ("lab_dir", "script_dir")


def collect_vars(src):
    """Collect `set NAME value` assignments so that $NAME can be resolved."""
    vars_ = {}
    for m in re.finditer(
            r'(?m)^\s*set\s+(\w+)\s+(?:"([^"]*)"|([^\s\][;]+))', src):
        name = m.group(1)
        value = m.group(2) if m.group(2) is not None else m.group(3)
        vars_[name] = value
    return vars_


def resolve_vars(text, vars_):
    """Substitute $NAME with the value of the matching `set NAME ...`."""
    def repl(m):
        name = m.group(1)
        if name in RESERVED_VARS:
            return m.group(0)
        return vars_.get(name, m.group(0))
    return re.sub(r"\$(\w+)", repl, text)


def find_top_entity(rtl_dir):
    """Map entity name -> vhdl file, for every entity in rtl/."""
    found = {}
    if not os.path.isdir(rtl_dir):
        return found
    for name in sorted(os.listdir(rtl_dir)):
        if not name.endswith(".vhd"):
            continue
        path = os.path.join(rtl_dir, name)
        ent, _ports = parse_vhdl_entity(path)
        if ent:
            found[ent] = path
    return found


# ---------------------------------------------------------------------------
# main check
# ---------------------------------------------------------------------------

def check_script(path, entities):
    script_dir = os.path.dirname(os.path.abspath(path))
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        raw = fh.read()
    src = strip_tcl_comments(raw)

    errors = 0
    warnings = 0
    vars_ = collect_vars(src)

    print("=" * 74)
    print("Precision Tcl checker : %s" % path)
    print("=" * 74)

    # --- 1. balance --------------------------------------------------------
    balance = check_balance(src)
    for p in balance:
        print("ERROR  : %s" % p)
        errors += 1
    if not balance:
        print("OK     : braces, brackets and quotes are balanced")

    # --- 2. referenced files exist ----------------------------------------
    checked = 0
    for line in src.splitlines():
        s = line.strip()
        if s.startswith("add_source") or s.startswith("add_constraint_file"):
            for tok in quoted_args(s):
                resolved = expand_path(tok, script_dir, vars_)
                checked += 1
                if not os.path.isfile(resolved):
                    print("ERROR  : %s refers to a file that does not exist:\n"
                          "          %s\n"
                          "          (resolved to %s)"
                          % (s.split()[0], tok, resolved))
                    errors += 1
                else:
                    print("OK     : %-18s -> %s"
                          % (s.split()[0], os.path.relpath(resolved, LAB_DIR)))
    if checked == 0:
        print("WARN   : the script never calls add_source / add_constraint_file")
        warnings += 1

    # --- 3. set_top_module -------------------------------------------------
    top = None
    for line in src.splitlines():
        s = line.strip()
        if s.startswith("set_top_module"):
            m = re.search(r"set_top_module\s+\"?([^\"\s]+)\"?", s)
            if m:
                top = resolve_vars(m.group(1), vars_)
    if top is None:
        print("WARN   : no set_top_module command - the tool would ask for it")
        warnings += 1
    else:
        if top in entities:
            print("OK     : set_top_module '%s' exists in rtl/ (%s)"
                  % (top, os.path.relpath(entities[top], LAB_DIR)))
        else:
            print("ERROR  : set_top_module '%s' does not match any entity in rtl/"
                  % top)
            print("          known entities: %s" % ", ".join(sorted(entities)))
            errors += 1

    # --- 4. SDC matches the entity ----------------------------------------
    sdc_file = None
    for line in src.splitlines():
        s = line.strip()
        if s.startswith("add_constraint_file"):
            toks = quoted_args(s)
            if toks:
                sdc_file = expand_path(toks[-1], script_dir, vars_)
    if sdc_file and os.path.isfile(sdc_file) and top and top in entities:
        ent_name, ports = parse_vhdl_entity(entities[top])
        entity_ports = {p for p, _ in ports}
        sdc_used = parse_sdc_ports(sdc_file)
        unknown = sorted(sdc_used - entity_ports)
        if unknown:
            for p in unknown:
                print("ERROR  : %s constrains port '%s' which entity '%s' "
                      "does not have" % (os.path.relpath(sdc_file, LAB_DIR), p, top))
                errors += 1
        else:
            print("OK     : every port in %s exists in entity '%s'"
                  % (os.path.relpath(sdc_file, LAB_DIR), top))

    # --- 5. technology library placeholder --------------------------------
    for m in re.finditer(r'set\s+tech_lib\s+"([^"]*)"', src):
        tech = m.group(1)
        if tech in PLACEHOLDER_TECH:
            print("WARN   : tech_lib is still the placeholder '%s' - replace it "
                  "with the technology library of your organisation" % tech)
            warnings += 1
        else:
            print("OK     : tech_lib = '%s'" % tech)

    print("-" * 74)
    print("RESULT : %d error(s), %d warning(s)" % (errors, warnings))
    print("=" * 74)
    return errors


def selftest():
    """Reproduce the historical bug of the original synth.tcl and prove that
    this checker rejects it."""
    import tempfile

    buggy_tcl = """\
set tech_lib    "/tech/gscl45nm"
set design_name "top"
set rtl_dir     "."

new_project -name $design_name -folder work_$design_name \\
            -technology "$tech_lib"

add_source -type vhdl -work work -library work "$rtl_dir/full_adder_struct.vhd"
add_source -type vhdl -work work -library work "$rtl_dir/adder8.vhd"
add_constraint_file "$rtl_dir/constraints.sdc"
set_top_module top
compile -incremental_mapping -retiming
exit
"""
    tmp = tempfile.mkdtemp(prefix="tcl_check_")
    path = os.path.join(tmp, "synth.tcl")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(buggy_tcl)

    print("### SELFTEST: reproduce the historical Lab 3A synth.tcl bug ###")
    print("-" * 74)
    errors = check_script(path, find_top_entity(os.path.join(LAB_DIR, "rtl")))
    print("-" * 74)
    if errors > 0:
        print("SELFTEST PASSED : the checker rejected the buggy script "
              "(%d error(s) reported above)" % errors)
        return 0
    print("SELFTEST FAILED : the checker did NOT catch the historical bug")
    return 1


def main():
    ap = argparse.ArgumentParser(description="Static checker for Precision RTL Tcl scripts.")
    ap.add_argument("scripts", nargs="*", help="Tcl script(s) to check")
    ap.add_argument("--selftest", action="store_true")
    args = ap.parse_args()

    if args.selftest:
        return selftest()

    scripts = args.scripts
    if not scripts:
        sdir = os.path.join(LAB_DIR, "scripts")
        scripts = [os.path.join(sdir, f) for f in sorted(os.listdir(sdir))
                   if f.endswith(".tcl") and f not in SKIP_SCRIPTS]
    if not scripts:
        print("ERROR  : no Tcl script found")
        return 2

    entities = find_top_entity(os.path.join(LAB_DIR, "rtl"))
    total = 0
    for s in scripts:
        if not os.path.isfile(s):
            print("ERROR  : script not found: %s" % s)
            total += 1
            continue
        total += check_script(s, entities)
        print()
    print("### %d error(s) over %d script(s)" % (total, len(scripts)))
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())

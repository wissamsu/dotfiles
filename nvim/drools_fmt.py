#!/usr/bin/env python3
"""drools_fmt: a small, conservative formatter for Drools Rule Language (.drl).

Reads DRL from stdin (or a file argument) and writes formatted DRL to stdout.

What it does:
  * re-indents rules, queries, declares and functions from their structure
  * indents continuation lines by bracket depth ( ), { }, [ ]
  * strips trailing whitespace, collapses runs of blank lines
  * puts one blank line between top-level blocks
  * ends the file with exactly one newline

What it deliberately does NOT do: touch spacing inside a line, reflow long
lines, or reorder anything. DRL embeds Java/MVEL, so that is too risky.

Usage:
  drools_fmt.py [--indent N | --tabs] [file]
"""
import argparse
import re
import sys

OPEN, CLOSE = "([{", ")]}"
TOP_STARTERS = re.compile(r"^(rule|query|declare|function)\b")
RULE_RE = re.compile(r"^rule\b")
QUERY_RE = re.compile(r"^query\b")
DECLARE_RE = re.compile(r"^declare\b")
FUNCTION_RE = re.compile(r"^function\b")
WHEN_RE = re.compile(r"^when\b")
THEN_RE = re.compile(r"^then\b(\s*\[[^\]]*\])?")
END_RE = re.compile(r"^end\s*(//.*)?$")

# base indent level (in units) of body lines for each state
BASE = {"top": 0, "attrs": 1, "lhs": 2, "rhs": 2, "query": 1, "declare": 1}


def scan(line, in_block):
    """Scan one line, ignoring strings and comments.

    Returns (delta, leading_closers, in_block_after, has_code).
    """
    delta = 0
    leading = 0
    seen_code = False
    still_leading = True
    i, n = 0, len(line)
    while i < n:
        if in_block:
            j = line.find("*/", i)
            if j == -1:
                return delta, leading, True, seen_code
            in_block = False
            i = j + 2
            continue
        c = line[i]
        two = line[i:i + 2]
        if two == "//":
            break
        if two == "/*":
            in_block = True
            i += 2
            continue
        if c in "\"'":
            quote = c
            seen_code = True
            still_leading = False
            i += 1
            while i < n:
                if line[i] == "\\":
                    i += 2
                    continue
                if line[i] == quote:
                    break
                i += 1
            i += 1
            continue
        if c in OPEN:
            delta += 1
            seen_code = True
            still_leading = False
        elif c in CLOSE:
            delta -= 1
            seen_code = True
            if still_leading:
                leading += 1
        elif not c.isspace():
            seen_code = True
            still_leading = False
        i += 1
    return delta, leading, in_block, seen_code


def format_drl(text, unit):
    out = []
    state = "top"
    depth = 0
    in_block = False
    fn_opened = False

    def emit(s=""):
        out.append(s)

    def last_nonblank():
        for s in reversed(out):
            if s.strip():
                return s.strip()
        return None

    def ensure_blank():
        if out and out[-1].strip():
            emit("")

    for raw in text.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        line = raw.rstrip()
        stripped = line.strip()

        # inside a multi-line block comment: keep content, tidy the margin
        if in_block:
            _, _, in_block, _ = scan(line, True)
            level = (BASE[state] if state != "top" else 0) + depth
            if state == "function":
                level = depth
            if stripped.startswith("*"):
                emit(unit * level + " " + stripped)
            else:
                emit(line)
            continue

        if not stripped:
            if out and out[-1] != "":
                emit("")
            continue

        # ---- structural keywords -----------------------------------
        if state == "top":
            if TOP_STARTERS.match(stripped):
                prev = last_nonblank()
                if prev is not None and not prev.startswith(("//", "/*", "*", "@")):
                    ensure_blank()
                if RULE_RE.match(stripped):
                    state = "attrs"
                elif QUERY_RE.match(stripped):
                    state = "query"
                elif DECLARE_RE.match(stripped):
                    state = "declare"
                else:
                    state = "function"
                    fn_opened = False
                depth = 0
                delta, _, in_block, _ = scan(stripped, False)
                emit(stripped)
                if state == "function":
                    depth = max(delta, 0)
                    fn_opened = "{" in stripped
                    if fn_opened and depth == 0:
                        state = "top"
                continue
            # package / import / global / comments / annotations at top level
            if last_nonblank() in ("end", "}") and out and out[-1].strip():
                ensure_blank()
            _, _, in_block, _ = scan(stripped, False)
            emit(stripped)
            continue

        if state == "function":
            delta, leading, in_block, _ = scan(stripped, False)
            level = max(depth - leading, 0)
            emit(unit * level + stripped)
            depth = max(depth + delta, 0)
            if "{" in stripped:
                fn_opened = True
            if fn_opened and depth == 0:
                state = "top"
            continue

        # rule / query / declare bodies
        if depth == 0 and END_RE.match(stripped):
            while out and out[-1] == "":
                out.pop()  # no blank line before `end`
            emit(stripped)
            state = "top"
            depth = 0
            continue
        if state == "attrs" and depth == 0 and WHEN_RE.match(stripped):
            emit(unit + stripped)
            state = "lhs"
            continue
        if state in ("attrs", "lhs") and depth == 0 and THEN_RE.match(stripped):
            emit(unit + stripped)
            state = "rhs"
            continue

        delta, leading, in_block, _ = scan(stripped, False)
        level = BASE[state] + max(depth - leading, 0)
        emit(unit * level + stripped)
        depth = max(depth + delta, 0)

    while out and out[-1] == "":
        out.pop()
    while out and out[0] == "":
        out.pop(0)
    return "\n".join(out) + "\n"


def main():
    ap = argparse.ArgumentParser(description="Format Drools .drl files")
    ap.add_argument("file", nargs="?", help="input file (default: stdin)")
    ap.add_argument("--indent", type=int, default=4, help="spaces per level")
    ap.add_argument("--tabs", action="store_true", help="indent with tabs")
    args = ap.parse_args()
    unit = "\t" if args.tabs else " " * args.indent
    text = open(args.file).read() if args.file else sys.stdin.read()
    sys.stdout.write(format_drl(text, unit))


if __name__ == "__main__":
    main()

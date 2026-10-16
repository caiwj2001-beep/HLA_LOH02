#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Prove that the README_upload_steps template embedded in `.tools/assemble_deposit.py`
and the rendered `V3/06_compliance/deposit/README_upload_steps.md` are the *same document*.

The historical patch tool that used to live here carried OLD/NEW hunks full of the withdrawn
archival-DOI placeholders.  The archival-DOI route has been withdrawn (see
`00_pinned/PINNED_PACK_CORRECTIONS.md` section (xiii)): the single and complete public route for
the code and the derived data is the GitHub repository
`https://github.com/caiwj2001-beep/HLA_LOH02`.  The generator now emits the GitHub-only text
directly, so all this file has to do is verify that the two copies have not drifted.

Exit 0 iff the generator literal equals the rendered file, after newline translation.
"""
import ast
import os
import sys

ROOT = r"C:\Users\Administrator\科研文件\HLA_LOH02"
GEN = os.path.join(ROOT, ".tools", "assemble_deposit.py")
OUT = os.path.join(ROOT, "iscience投稿版本", "V3", "06_compliance", "deposit",
                   "README_upload_steps.md")

tree = ast.parse(open(GEN, encoding="utf-8").read())
target = None
for node in ast.walk(tree):
    if (isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute)
            and node.func.attr == "write" and node.args
            and isinstance(node.args[0], ast.Constant)
            and isinstance(node.args[0].value, str)
            and node.args[0].value.startswith("# Deposit instructions")):
        target = node.args[0].value
assert target, "template literal not found in %s" % GEN

rendered = open(OUT, encoding="utf-8", newline="").read().replace("\r\n", "\n")
lit = target.replace("\r\n", "\n")
same = (lit == rendered)
print("generator literal == rendered README_upload_steps.md :", same,
      "| len(literal)=%d len(file)=%d" % (len(lit), len(rendered)))
if not same:
    import difflib
    for l in list(difflib.unified_diff(lit.split("\n"), rendered.split("\n"), lineterm=""))[:40]:
        print("   ", l)
    sys.exit(1)
print("[OK]")

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sync the README_upload_steps template in .tools/assemble_deposit.py and the rendered
V3/06_compliance/deposit/README_upload_steps.md, then prove they are byte-identical
after newline translation.
"""
import ast, io, sys, os

ROOT = r"C:\Users\Administrator\科研文件\HLA_LOH02"
GEN = os.path.join(ROOT, ".tools", "assemble_deposit.py")
OUT = os.path.join(ROOT, "iscience投稿版本", "V3", "06_compliance", "deposit", "README_upload_steps.md")

OLD = [
 """**The authors must log in themselves at every step below. No DOI in this package is real:**
`[REPO-URL-PENDING]` and `[DOI-PENDING-ZENODO]` are placeholders and must be replaced only after
the records exist. Do not invent or reserve a DOI.""",
 """1. Sign in at https://github.com and create the public repository
   `https://github.com/caiwj2001-beep/HLA_LOH02` (this exact URL replaces `[REPO-URL-PENDING]`
   in the three places listed in section D).""",
 """3. Copy the version DOI into `[DOI-PENDING-ZENODO]` — it is the **single** DOI covering both the
   code and the derived data — in `Data_and_Code_Availability.md`, in the Key Resources Table and
   in the STAR Methods "Data and code availability" section of the manuscript. Replace
   `[REPO-URL-PENDING]` with the repository URL in the same three places.""",
 """- [ ] `[REPO-URL-PENDING]` replaced with `https://github.com/caiwj2001-beep/HLA_LOH02`
      in `Data_and_Code_Availability.md`, the Key Resources Table and the manuscript""",
]

NEW = [
 """**The authors must log in themselves at every step below. The repository URL is final; the DOI
is not yet real:** the single remaining placeholder is `[DOI-PENDING-ZENODO]`, and it must be
replaced only after the archived record exists. Do not invent or reserve a DOI.""",
 """1. The public repository already exists at
   `https://github.com/caiwj2001-beep/HLA_LOH02`; sign in at https://github.com and confirm you
   can push to it. This exact URL is already written into the three places listed in section D.""",
 """3. Copy the version DOI into `[DOI-PENDING-ZENODO]` — it is the **single** DOI covering both the
   code and the derived data — in `Data_and_Code_Availability.md`, in the Key Resources Table and
   in the STAR Methods "Data and code availability" section of the manuscript. The repository URL
   is already filled in at those same three places, so no URL edit remains.""",
 """- [x] `https://github.com/caiwj2001-beep/HLA_LOH02` written into `Data_and_Code_Availability.md`,
      the Key Resources Table and the manuscript (no `[REPO-URL-PENDING]` remains anywhere)""",
]


def apply(path, nl):
    raw = open(path, "rb").read().decode("utf-8")
    n = 0
    for o, w in zip(OLD, NEW):
        oo = o.replace("\n", nl)
        ww = w.replace("\n", nl)
        if oo not in raw:
            if oo.replace("- [ ]", "- [x]") in raw:
                print("   (already applied)", path)
                continue
            raise SystemExit("MISSING in %s:\n%s" % (path, oo[:120]))
        raw = raw.replace(oo, ww, 1)
        n += 1
    open(path, "wb").write(raw.encode("utf-8"))
    print("   patched %d hunk(s) in %s" % (n, path))


print("[1] patching generator (.py, LF):")
apply(GEN, "\n")
print("[2] patching rendered README (.md, CRLF):")
apply(OUT, "\r\n")

# ---- proof: literal in the generator == the rendered file (after newline translation)
src = open(GEN, encoding="utf-8").read()
tree = ast.parse(src)
target = None
for node in ast.walk(tree):
    if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute) and node.func.attr == "write" \
       and node.args and isinstance(node.args[0], ast.Constant) and isinstance(node.args[0].value, str) \
       and node.args[0].value.startswith("# Deposit instructions"):
        target = node.args[0].value
assert target, "template literal not found"
rendered = open(OUT, encoding="utf-8", newline="").read().replace("\r\n", "\n")
lit = target.replace("\r\n", "\n")
print("[3] generator literal == rendered README_upload_steps.md :", lit == rendered,
      "| len(lit)=%d len(file)=%d" % (len(lit), len(rendered)))
if lit != rendered:
    import difflib
    for l in list(difflib.unified_diff(lit.split("\n"), rendered.split("\n"), lineterm=""))[:30]:
        print("   ", l)
    sys.exit(1)
print("[OK]")

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_repo_vs_zip.py — prove that the deposit archives are byte-identical to this repository.

The submission package advertises the public repository as a byte-reproducible snapshot of
`code.zip` and `derived_data.zip`.  Because `README_CODE.md` and `PINNED_PACK.md` are shipped in
both places, "same text, different bytes" (CRLF vs LF) is a real failure mode.  This script checks
the property that matters: for every member of every archive there must exist a file under the
repository tree whose **sha256 is identical**, i.e. the same bytes, not merely the same text.

Usage
-----
    python tools/check_repo_vs_zip.py --repo .. ../06_compliance/deposit/code.zip \
                                                 ../06_compliance/deposit/derived_data.zip

Exit code 0 iff every member matches.  Intended to be run on the working tree of a fresh clone.
"""
import argparse
import hashlib
import os
import sys
import zipfile


def sha(b):
    return hashlib.sha256(b).hexdigest()


def repo_index(repo):
    idx = {}
    for root, dirs, files in os.walk(repo):
        dirs[:] = [d for d in dirs if d != ".git"]
        for fn in files:
            p = os.path.join(root, fn)
            rel = os.path.relpath(p, repo).replace(os.sep, "/")
            try:
                h = sha(open(p, "rb").read())
            except OSError:
                continue
            idx.setdefault(h, []).append(rel)
    return idx


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("zips", nargs="+", help="deposit archives to check")
    ap.add_argument("--repo", default="..", help="repository tree to compare against "
                                                 "(default: the parent of tools/)")
    args = ap.parse_args()

    idx = repo_index(args.repo)
    total = matched = 0
    for zp in args.zips:
        print("=" * 84)
        print(os.path.basename(zp))
        z = zipfile.ZipFile(zp)
        for zi in z.infolist():
            total += 1
            h = sha(z.read(zi.filename))
            hit = idx.get(h)
            if hit:
                matched += 1
                print("  OK       %-54s -> %s" % (zi.filename, hit[0]))
            else:
                print("  MISMATCH %-54s %s  *** no repository file has these bytes ***"
                      % (zi.filename, h))
    print("=" * 84)
    print("members: %d   byte-identical to a repository file: %d   mismatches: %d"
          % (total, matched, total - matched))
    return 0 if matched == total else 1


if __name__ == "__main__":
    sys.exit(main())

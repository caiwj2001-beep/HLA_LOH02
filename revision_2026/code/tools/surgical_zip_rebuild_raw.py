#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Surgical rebuild of the two deposit archives — RAW member copy.

Copies each member's **raw local file record** (local header + compressed bytes)
byte-for-byte, so no member is ever re-compressed or re-timestamped. Only the members
listed in REPLACE get a freshly written local record. The central directory and EOCD are
rebuilt with corrected offsets.

Verification per archive:
  * member list and order identical, nothing added or dropped
    (in particular derived_data/README_DATA.md must survive);
  * every non-replaced member's raw local record byte-identical to the source;
  * decompressed sha256 per member matches (except the replaced ones, which must equal
    the new on-disk source file);
  * zipfile.testzip() clean.
"""
import os, sys, json, zlib, struct, shutil, zipfile, hashlib

ROOT = r"C:\Users\Administrator\科研文件\HLA_LOH02"
V3 = os.path.join(ROOT, "iscience投稿版本", "V3")
DEP = os.path.join(V3, "06_compliance", "deposit")
QC = os.path.join(V3, "QC")
BK = os.path.join(ROOT, ".tools", "_pre_unify")

PINNED = os.path.join(V3, "00_pinned", "PINNED_PACK.md")
BTD = os.path.join(ROOT, ".tools", "build_tables_docx.py")

JOBS = [
    ("code.zip", {"code/PINNED_PACK.md": PINNED, "code/build_tables_docx.py": BTD}),
    ("derived_data.zip", {"derived_data/number_dictionary/PINNED_PACK.md": PINNED}),
]

LFH = "<IHHHHHIIIHH"
CDH = "<IHHHHHHIIIHHHHHII"


def sha(b):
    return hashlib.sha256(b).hexdigest()


def dos_time_date(zi):
    dt = zi.date_time
    return (dt[3] << 11 | dt[4] << 5 | dt[5] // 2,
            (dt[0] - 1980) << 9 | dt[1] << 5 | dt[2])


def parse(path):
    """-> raw bytes + [(ZipInfo, local_record_bytes)] ; local record = header+name+extra+data"""
    raw = open(path, "rb").read()
    z = zipfile.ZipFile(path)
    recs = []
    for zi in z.infolist():
        off = zi.header_offset
        (sig, ver, flag, comp, t, d, crc, csize, usize, fnlen, exlen) = \
            struct.unpack_from(LFH, raw, off)
        assert sig == 0x04034b50, "bad local header sig: " + zi.filename
        assert not (flag & 0x08), "data-descriptor entry unsupported: " + zi.filename
        start = off + 30 + fnlen + exlen
        end = start + zi.compress_size
        assert end <= len(raw)
        assert csize == zi.compress_size and usize == zi.file_size and crc == zi.CRC, zi.filename
        recs.append((zi, raw[off:end]))
    z.close()
    return raw, recs


def rebuild(src, dst, repl, report):
    raw, recs = parse(src)
    out = bytearray()
    entries = []
    for zi, rec in recs:
        name = zi.filename
        off = len(out)
        if name in repl:
            data = open(repl[name], "rb").read()
            co = zlib.compressobj(6, zlib.DEFLATED, -15)
            comp = co.compress(data) + co.flush()
            crc = zlib.crc32(data) & 0xFFFFFFFF
            t, d = dos_time_date(zi)
            hdr = struct.pack(LFH, 0x04034b50, zi.extract_version, zi.flag_bits,
                              zi.compress_type, t, d, crc, len(comp), len(data),
                              len(name.encode()), 0)
            out += hdr + name.encode() + comp
            entries.append((zi, off, crc, len(comp), len(data), zi.compress_type))
        else:
            out += rec
            entries.append((zi, off, zi.CRC, zi.compress_size, zi.file_size,
                            zi.compress_type))
    cd_off = len(out)
    for zi, off, crc, csize, usize, comp in entries:
        nameb = zi.filename.encode()
        t, d = dos_time_date(zi)
        out += struct.pack(CDH, 0x02014b50, zi.create_version, zi.extract_version,
                           zi.flag_bits, comp, t, d, crc, csize, usize,
                           len(nameb), 0, 0, zi.volume, zi.internal_attr,
                           zi.external_attr, off)
        out += nameb
    cd_size = len(out) - cd_off
    n = len(entries)
    out += struct.pack("<IHHHHIIH", 0x06054b50, 0, 0, n, n, cd_size, cd_off, 0)
    open(dst, "wb").write(bytes(out))

    # ---------------- verification ----------------
    a = zipfile.ZipFile(src); b = zipfile.ZipFile(dst)
    assert a.namelist() == b.namelist(), "member list/order changed"
    assert b.testzip() is None, "CRC failure in rebuilt archive"
    _, ra_all = parse(src); _, rb_all = parse(dst)
    bad = []
    for (zia, ra), (zib, rb) in zip(ra_all, rb_all):
        nm = zia.filename
        da, db = a.read(nm), b.read(nm)
        if nm in repl:
            want = sha(open(repl[nm], "rb").read())
            ok = sha(db) == want and sha(da) != want
            st = "REPLACED (== new source, != old)" if ok else "FAILED replacement"
        else:
            ok = (ra == rb) and sha(da) == sha(db)
            st = "verbatim raw record (byte-identical)" if ok else "DIFFERS"
        if not ok:
            bad.append(nm)
        report.append({"member": nm, "status": st, "old_sha256": sha(da),
                       "new_sha256": sha(db), "bytes": len(db)})
    a.close(); b.close()
    return bad


def main():
    out = {"archives": {}, "members": {}}
    for name, repl in JOBS:
        src = os.path.join(DEP, name)
        shutil.copy(src, os.path.join(BK, name + ".old"))
        old_sha = sha(open(src, "rb").read())
        old_size = os.path.getsize(src)
        old_list = zipfile.ZipFile(src).namelist()
        tmp = src + ".new"
        report = []
        bad = rebuild(src, tmp, repl, report)
        os.replace(tmp, src)
        new_sha = sha(open(src, "rb").read())
        new_size = os.path.getsize(src)
        new_list = zipfile.ZipFile(src).namelist()
        print("=" * 100)
        print(f"{name}   ({'OK' if not bad else 'FAILED'})")
        print("=" * 100)
        print(f"  members : old {len(old_list)} / new {len(new_list)}")
        print(f"  README_DATA.md preserved : {'derived_data/README_DATA.md' in new_list}")
        print(f"  bytes   : old {old_size} / new {new_size}")
        print(f"  sha256  : OLD {old_sha}")
        print(f"            NEW {new_sha}")
        for r in report:
            if r["old_sha256"] != r["new_sha256"]:
                print("  %-58s %-42s CHANGED" % (r["member"], r["status"]))
        print("  unchanged members kept byte-identical: %d/%d"
              % (sum(1 for r in report if "verbatim" in r["status"]), len(report)))
        print(f"  FAILURES: {bad if bad else 'none'}")
        out["archives"][name] = {"old_sha256": old_sha, "new_sha256": new_sha,
                                 "old_bytes": old_size, "new_bytes": new_size,
                                 "members_old": len(old_list), "members_new": len(new_list),
                                 "failures": bad,
                                 "changed_members": [r["member"] for r in report
                                                     if r["old_sha256"] != r["new_sha256"]]}
        out["members"][name] = report
        if bad:
            print("!! ABORT:", name)
            return 1
    json.dump(out, open(os.path.join(QC, "_zip_surgical_rebuild.json"), "w"), indent=1)
    print("\nwrote", os.path.join(QC, "_zip_surgical_rebuild.json"))
    return 0


if __name__ == "__main__":
    sys.exit(main())

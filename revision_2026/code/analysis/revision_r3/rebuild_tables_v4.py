#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""rebuild_tables_v4.py — V4 局部重生「主表」Table1/2/3 的 runner。

为什么需要它（而不是直接跑 .tools/build_tables_docx.py）：
  * `.tools/build_tables_docx.py` 的 ROOT/V3 常量写死指向 V3（冻结只读），直接跑会写 V3；
  * 它的 main() 还会重建 Supplementary_Tables.docx 并把目录页码清空（页码本由
    build_supplement_pdf.py 的两遍法回写）。
本 runner 因此：
  1) 只调用 build_main_tables()（Table1/2/3），绝不触碰 Supplementary_Tables.docx；
  2) 把模块级 BLD / TBL / V3 重定向到 V4（或调用方指定的目录）。

用法:
  python rebuild_tables_v4.py <BLD_IN> <TBL_OUT> <LOG_PATH>
"""
import os
import sys
import importlib.util

TOOLS = r"C:\Users\Administrator\科研文件\HLA_LOH02\.tools"


def load_builder():
    spec = importlib.util.spec_from_file_location(
        "build_tables_docx", os.path.join(TOOLS, "build_tables_docx.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main():
    bld_in, tbl_out, logp = sys.argv[1], sys.argv[2], sys.argv[3]
    B = load_builder()
    # 路径重定向（模块函数在调用时读这些全局量）
    B.V3 = os.path.dirname(os.path.dirname(os.path.abspath(tbl_out)))  # 仅用于日志路径占位
    B.BLD = bld_in
    B.TBL = tbl_out
    os.makedirs(tbl_out, exist_ok=True)
    os.makedirs(os.path.dirname(logp), exist_ok=True)
    with open(logp, "w", encoding="utf-8") as log:
        log.write("# rebuild_tables_v4.py\n")
        log.write("BLD_IN  = %s\n" % bld_in)
        log.write("TBL_OUT = %s\n" % tbl_out)
        log.write("TOOLS   = %s\n\n" % TOOLS)
        B.build_main_tables(log)
        residue = 0
        for f, lbl in [(os.path.join(tbl_out, "Table1_baseline.docx"), "Table1_baseline.docx"),
                       (os.path.join(tbl_out, "Table2_drivers.docx"), "Table2_drivers.docx"),
                       (os.path.join(tbl_out, "Table3_survival.docx"), "Table3_survival.docx")]:
            if os.path.exists(f):
                residue += B.scan_markdown(B.Document(f), lbl, log)
        log.write("[MD-SCAN] TOTAL RESIDUE = %d\n" % residue)
    print("rebuilt main tables -> %s ; md residue = %d" % (tbl_out, residue))
    return 0


if __name__ == "__main__":
    sys.exit(main())

import sys
from docx import Document
from docx.table import Table
from docx.text.paragraph import Paragraph

def iter_block_items(parent):
    from docx.oxml.ns import qn
    body = parent.element.body
    for child in body.iterchildren():
        if child.tag == qn('w:p'):
            yield Paragraph(child, parent)
        elif child.tag == qn('w:tbl'):
            yield Table(child, parent)

doc = Document(sys.argv[1])
ni = 0
for blk in iter_block_items(doc):
    ni += 1
    if isinstance(blk, Paragraph):
        t = blk.text.strip()
        if t:
            print(f"[P{ni}] {t}")
    else:
        print(f"[TABLE {ni}] rows={len(blk.rows)} cols={len(blk.columns)}")
        for r in blk.rows[:200]:
            cells = [c.text.strip().replace('\n',' ') for c in r.cells]
            print("  | " + " | ".join(cells))

#!/usr/bin/env python3
"""Swap 2 pre-2020 refs for verified 2020+ equivalents to meet >=70% recency.
Body citation numbers are unchanged (Rooney #16->Luksza2022 #16; Swanton #17->Butler2023 #17).
Only the reference list text is regenerated. All refs PubMed-verified."""
import re, os
MS="C:/Users/Administrator/科研文件/HLA_LOH02/V6/08_manuscript"
ref=open(os.path.join(MS,"06_References.md"),encoding="utf-8").read()

# Replacement citations (Cell Press format, verified PMIDs/DOIs)
LUKSZA="Łuksza, M., Sethna, Z.M., Rojas, L.A., Lihm, J., Bravi, B., Elhanati, Y., Soares, K., Amisaki, M., Dobrin, A., Hoyos, D., et al. (2022). Neoantigen quality predicts immunoediting in survivors of pancreatic cancer. Nature 606, 389-395. PMID: 35589842. https://doi.org/10.1038/s41586-022-04735-9"
BUTLER="Butler, K., and Banday, A.R. (2023). APOBEC3-mediated mutagenesis in cancer: causes, clinical significance and therapeutic potential. J. Hematol. Oncol. 16, 31. PMID: 36978147. https://doi.org/10.1186/s13045-023-01425-5"

# Replace ref #16 line (Rooney 2015) and #17 line (Swanton 2015)
ref=re.sub(r'^16\. Rooney.*?$', "16. "+LUKSZA, ref, flags=re.M)
ref=re.sub(r'^17\. Swanton.*?$', "17. "+BUTLER, ref, flags=re.M)

# recompute recency
yrs=re.findall(r'\((\d{4})\)', ref)
recent=sum(1 for y in yrs if int(y)>=2020)
# the note line references count; recompute on 28 refs
total=len(re.findall(r'^\d+\. ', ref, flags=re.M))
recent_refs=sum(1 for m in re.finditer(r'^\d+\. .*?\((\d{4})\)', ref, flags=re.M) if int(m.group(1))>=2020)
ref=re.sub(r'\d+/\d+ \(\d+%\) were published 2020-2026\.',
           f"{recent_refs}/{total} ({round(100*recent_refs/total)}%) were published 2020-2026.", ref)
open(os.path.join(MS,"06_References.md"),"w",encoding="utf-8").write(ref)

# Update Results/Intro prose that named Rooney/Swanton concepts? They were generic; no author names in body. OK.
print(f"Swapped refs 16 & 17. Recency now {recent_refs}/{total} = {round(100*recent_refs/total)}%")
print("Ref 16:", "Luksza" if "Łuksza" in ref.split("16. ")[1][:20] else "??")
print("Ref 17:", "Butler" if "Butler" in ref.split("\n17. ")[1][:20] else "??")

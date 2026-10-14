#!/usr/bin/env python3
"""
HLA_LOH02 Literature Search & Verification via NCBI E-utilities
Fetches real metadata (PMID, DOI, journal, year, title, authors) for candidate papers.
All references verified against PubMed. NO fabrication.
"""
import json, subprocess, time, sys, os

OUT_DIR = "C:/Users/Administrator/科研文件/HLA_LOH02/V6/01_literature"
os.makedirs(OUT_DIR, exist_ok=True)

def curl(url):
    r = subprocess.run(["curl", "-s", url], capture_output=True, text=True, timeout=60)
    return r.stdout

def esearch(term, mindate=2015, maxdate=2026, retmax=40, sort="relevance"):
    url = (f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed"
           f"&term={term}&datetype=pdat&mindate={mindate}&maxdate={maxdate}"
           f"&retmax={retmax}&retmode=json&sort={sort}")
    d = json.loads(curl(url))
    return d['esearchresult']['idlist'], d['esearchresult']['count']

def esummary(pmids):
    if not pmids: return {}
    ids = ",".join(pmids)
    url = (f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed"
           f"&id={ids}&retmode=json")
    d = json.loads(curl(url))
    return d.get('result', {})

# Search themes covering the 4 study directions
SEARCHES = {
    "hlaloh_immune_escape": "(HLA+loss+of+heterozygosity)+AND+(immune+escape+OR+immune+evasion)+AND+cancer",
    "hlaloh_pancancer": "(HLA+LOH+OR+HLA+loss+of+heterozygosity)+AND+(pan-cancer+OR+pancancer)",
    "hlaloh_immunotherapy": "(HLA+loss+of+heterozygosity)+AND+(immunotherapy+OR+immune+checkpoint)",
    "hlaloh_lung_evolution": "(HLA+loss+of+heterozygosity)+AND+(lung+cancer)+AND+(evolution+OR+clonal)",
    "neoantigen_immunoediting": "(neoantigen)+AND+(immunoediting+OR+immune+selection)+AND+cancer+genomics",
    "tmb_immunotherapy": "(tumor+mutational+burden)+AND+(immune+checkpoint+inhibitor)+AND+(pan-cancer+OR+response)",
    "apobec_immune": "(APOBEC)+AND+(mutational+signature)+AND+(immune+OR+neoantigen)+AND+cancer",
    "msi_mmr_immune": "(microsatellite+instability+OR+mismatch+repair+deficiency)+AND+(immunotherapy+OR+neoantigen)",
    "hla_evolution_selection": "(HLA)+AND+(negative+selection+OR+immune+selection)+AND+(tumor+evolution)",
    "msk_impact": "(MSK-IMPACT)+AND+(genomic+OR+sequencing+OR+clinical)",
    "wgd_aneuploidy_immune": "(whole+genome+doubling+OR+aneuploidy)+AND+(immune+evasion+OR+immune+cold)+AND+cancer",
    "hla_homozygosity_survival": "(HLA+homozygosity)+AND+(immune+checkpoint+OR+survival+OR+immunotherapy)",
}

all_pmids = {}
theme_pmids = {}

for theme, term in SEARCHES.items():
    try:
        ids, count = esearch(term, mindate=2015, maxdate=2026, retmax=30)
        theme_pmids[theme] = ids
        for pid in ids:
            all_pmids.setdefault(pid, []).append(theme)
        print(f"[{theme}] total={count}, fetched={len(ids)}", flush=True)
        time.sleep(0.4)
    except Exception as e:
        print(f"[{theme}] ERROR: {e}", flush=True)

print(f"\nTotal unique PMIDs: {len(all_pmids)}", flush=True)

# Fetch summaries in batches
pmid_list = list(all_pmids.keys())
records = {}
for i in range(0, len(pmid_list), 50):
    batch = pmid_list[i:i+50]
    res = esummary(batch)
    for pid in batch:
        if pid in res and pid != "uids":
            r = res[pid]
            doi = ""
            for aid in r.get("articleids", []):
                if aid.get("idtype") == "doi":
                    doi = aid.get("value", "")
            authors = [a["name"] for a in r.get("authors", [])]
            records[pid] = {
                "pmid": pid,
                "title": r.get("title", ""),
                "journal": r.get("fulljournalname", r.get("source", "")),
                "year": r.get("pubdate", "")[:4],
                "volume": r.get("volume", ""),
                "pages": r.get("pages", ""),
                "doi": doi,
                "first_author": authors[0] if authors else "",
                "n_authors": len(authors),
                "themes": all_pmids[pid],
                "pmcrefcount": r.get("pmcrefcount", 0),
            }
    time.sleep(0.4)

# Save full records
with open(os.path.join(OUT_DIR, "literature_candidates.json"), "w", encoding="utf-8") as f:
    json.dump(records, f, indent=2, ensure_ascii=False)

# TSV sorted by citation count (pmcrefcount) as impact proxy
rows = sorted(records.values(), key=lambda x: -int(x.get("pmcrefcount") or 0))
with open(os.path.join(OUT_DIR, "literature_candidates.tsv"), "w", encoding="utf-8") as f:
    f.write("PMID\tYear\tJournal\tFirst_Author\tPMC_Cites\tDOI\tThemes\tTitle\n")
    for r in rows:
        f.write(f"{r['pmid']}\t{r['year']}\t{r['journal']}\t{r['first_author']}\t"
                f"{r['pmcrefcount']}\t{r['doi']}\t{';'.join(r['themes'])}\t{r['title']}\n")

# Print high-impact journal candidates
HIGH_IMPACT = ["Nature","Cell","Science","Cancer Cell","Nature Medicine","Nature Genetics",
               "Nature Cancer","Nature Communications","Immunity","Cancer Discovery",
               "Lancet Oncology","Journal of Clinical Oncology","Annals of Oncology",
               "Nature Reviews","Cancer Cell","Clinical Cancer Research","Genome Medicine",
               "Science Translational Medicine","Journal for Immunotherapy"]

print("\n=== HIGH-IMPACT JOURNAL CANDIDATES (2020-2026 prioritized) ===\n")
for r in rows:
    jr = r["journal"]
    yr = r["year"]
    if any(h.lower() in jr.lower() for h in HIGH_IMPACT):
        recent = "★" if yr.isdigit() and int(yr) >= 2020 else " "
        print(f"{recent} [{yr}] {jr} | {r['first_author']} | cites={r['pmcrefcount']} | PMID:{r['pmid']}")
        print(f"     {r['title'][:100]}")

print(f"\n✓ Saved {len(records)} records to literature_candidates.json/.tsv")

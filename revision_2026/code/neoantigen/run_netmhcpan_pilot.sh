#!/bin/bash
# netMHCpan-4.2e per-allele run (pilot).  One process per allele file,
# -BA so that BOTH %Rank_EL and IC50 (Aff nM) are emitted.
NM=/home/nmuser/netMHCpan-4.2/netMHCpan
IN=/home/nmuser/nmwork/pep
RES=/home/nmuser/nmwork/res
RAW=/home/nmuser/nmwork/raw
mkdir -p "$RES" "$RAW"
rm -f /home/nmuser/nmwork/timings.*.txt
export IN RES RAW NM

process() {
  f="$1"; b="$(basename "$f" .pep)"; al="${b/_/:}"
  if [ -s "$RES/$b.tsv" ]; then printf '%s\tSKIP\t%s\t0\n' "$b" "$(wc -l < "$RES/$b.tsv")" >> /home/nmuser/nmwork/timings.$$.txt; return 0; fi
  t0=$(date +%s%N)
  ( cd /home/nmuser/netMHCpan-4.2 && ./netMHCpan -p "$f" -a "$al" -BA ) > "$RAW/$b.out" 2>&1
  rc=$?
  # keep peptide / %Rank_EL / %Rank_BA / Aff(nM); skip the '#' header + separator lines
  awk -v al="$al" 'BEGIN{OFS="\t"} /^ *[0-9]+ +HLA-/{print $3,$13,$15,$16,al}' "$RAW/$b.out" > "$RES/$b.tsv"
  n=$(wc -l < "$RES/$b.tsv")
  t1=$(date +%s%N)
  printf '%s\t%s\t%s\t%s\n' "$b" "$rc" "$n" "$(( (t1-t0)/1000000 ))" >> /home/nmuser/nmwork/timings.$$.txt
}
export -f process

ls "$IN"/*.pep | xargs -P 4 -n 1 -I{} bash -c 'process "$@"' _ {}

cat /home/nmuser/nmwork/timings.*.txt > /home/nmuser/nmwork/timings.txt
rm -f /home/nmuser/nmwork/timings.*.txt
echo "DONE $(date -Is)"

#!/bin/bash
# netMHCpan-4.2e FULL-cohort per-allele runner -- RUNS INSIDE THE VirtualBox GUEST
# (netmhcpan / nmvm).  One .tsv + one .done per allele; resumable (an allele with a
# non-empty $RES/<stem>.tsv and its .done marker is skipped).  The per-allele log
# written here ($BASE/run.log) is mirrored to the host by run_netmhcpan_full_host.sh.
#
# Launch (detached, survives ssh/host/agent exit):
#   cd $BASE && setsid nohup bash run_full.sh > $BASE/driver.log 2>&1 < /dev/null &
BASE=/home/nmuser/nmwork/full
NM=/home/nmuser/netMHCpan-4.2/netMHCpan
IN=$BASE/pep
RES=$BASE/res
RAW=$BASE/raw
LOG=$BASE/run.log
NPROC=${NPROC:-4}
mkdir -p "$RES" "$RAW"
export NM IN RES RAW LOG

# ---- single-instance guard (flock auto-releases when this process + children exit) ----
exec 9>"$BASE/run.lock"
if ! flock -n 9; then
  printf '=== run_full: another instance already holds the lock, exiting %s ===\n' \
    "$(date -Is)" >> "$LOG"
  exit 0
fi

printf '=== run_full started %s  workers=%s  alleles=%s ===\n' \
  "$(date -Is)" "$NPROC" "$(ls -1 "$IN"/*.pep 2>/dev/null | wc -l)" >> "$LOG"

process() {
  f="$1"; b="$(basename "$f" .pep)"; al="${b/_/:}"
  if [ -s "$RES/$b.tsv" ] && [ -f "$RES/$b.done" ]; then
    printf '%s\tSKIP\t%s\t%s\t0\n' "$b" "$al" "$(wc -l < "$RES/$b.tsv")" >> "$LOG"
    return 0
  fi
  t0=$(date +%s%N)
  ( cd /home/nmuser/netMHCpan-4.2 && ./netMHCpan -p "$f" -a "$al" -BA ) > "$RAW/$b.out" 2>&1
  rc=$?
  # columns: Peptide  %Rank_EL  %Rank_BA  Aff(nM)  Allele  (identical to the pilot awk)
  awk -v al="$al" 'BEGIN{OFS="\t"} /^ *[0-9]+ +HLA-/{print $3,$13,$15,$16,al}' \
      "$RAW/$b.out" > "$RES/$b.tsv.tmp"
  mv -f "$RES/$b.tsv.tmp" "$RES/$b.tsv"
  n=$(wc -l < "$RES/$b.tsv")
  t1=$(date +%s%N)
  printf '%s\t%s\t%s\t%s\t%s\n' "$b" "$al" "$rc" "$n" "$(( (t1-t0)/1000000 ))" >> "$LOG"
  [ "$rc" -eq 0 ] && touch "$RES/$b.done"
}
export -f process

ls "$IN"/*.pep | xargs -P "$NPROC" -I{} bash -c 'process "$@"' _ {}

nd=$(ls -1 "$RES"/*.done 2>/dev/null | wc -l)
nt=$(ls -1 "$IN"/*.pep 2>/dev/null | wc -l)
printf '=== ALLDONE %s  %s/%s alleles ===\n' "$(date -Is)" "$nd" "$nt" >> "$LOG"

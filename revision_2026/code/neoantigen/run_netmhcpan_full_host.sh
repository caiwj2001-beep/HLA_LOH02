#!/bin/bash
# NetMHCpan-4.2e FULL-cohort run -- HOST-side orchestrator + monitor.
#
#  * syncs the per-allele peptide lists (output/netmhcpan_input/all/*.pep) into the guest
#  * launches the guest runner DETACHED (setsid nohup) so it keeps running even if this
#    host process / the parent agent / the ssh session dies
#  * mirrors guest -> host:  output/predictions/netmhcpan_full/{per_allele/*.tsv,.done,run.log}
#  * exits 0 only when all alleles are done (Hermes then fires the completion notification)
#
# Fully idempotent / resumable: re-run any time; completed alleles are skipped both in the
# guest (non-empty .tsv + .done) and on the host (existing .done).
set -u
VM="netmhcpan"
VBM="/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
CRED="E:/数据库汇总/vm/vm_credentials.txt"
NEO_WIN="C:/Users/Administrator/科研文件/HLA_LOH02/neoantigen"
NEO="/c/Users/Administrator/科研文件/HLA_LOH02/neoantigen"
INP="$NEO/output/netmhcpan_input/all"
HOSTDIR="$NEO/output/predictions/netmhcpan_full"
HOSTDIR_WIN="$NEO_WIN/output/predictions/netmhcpan_full"
PA="$HOSTDIR/per_allele"
PA_WIN="$HOSTDIR_WIN/per_allele"
RUNLOG_WIN="$HOSTDIR_WIN/run.log"
RUNLOG="$HOSTDIR/run.log"
MONLOG="$HOSTDIR/monitor.log"
STATUS="$HOSTDIR/_STATUS.txt"
BASE=/home/nmuser/nmwork/full
POLL=90

mkdir -p "$PA"

printf '[%s] monitor start\n' "$(date '+%F %T')" >> "$MONLOG"

# ---- credentials (parsed from file; NEVER printed) --------------------------
_vmu=$(sed -n 's/^[[:space:]]*[Uu]sername[[:space:]]*[:][[:space:]]*//p' "$CRED" | tr -d '\r')
_vmp=$(sed -n 's/^[[:space:]]*[Pp]assword[[:space:]]*[:][[:space:]]*//p' "$CRED" | tr -d '\r')
if [ -z "$_vmu" ] || [ -z "$_vmp" ]; then
  echo "FATAL: could not parse VM credentials" > "$STATUS"; exit 2
fi

vm_run(){ "$VBM" guestcontrol "$VM" run --username "$_vmu" --password "$_vmp" --exe=/bin/bash -- -c "$1" 2>/dev/null | tr -d '\r'; }
vcopyto(){ "$VBM" guestcontrol "$VM" copyto --username "$_vmu" --password "$_vmp" "$@" 2>&1 | tr -d '\r'; }
# NOTE: VBox 7.2 copyfrom requires the EXACT host destination path -- copying a file
# into an existing directory is refused ("already exists and is a directory").
vcopyfrom(){ "$VBM" guestcontrol "$VM" copyfrom --username "$_vmu" --password "$_vmp" "$1" "$2" >/dev/null 2>&1; }
vcopyfrom_dir(){ "$VBM" guestcontrol "$VM" copyfrom --recursive --username "$_vmu" --password "$_vmp" "$1" "$2" >/dev/null 2>&1; }
log(){ printf '[%s] %s\n' "$(date '+%F %T')" "$*" >> "$MONLOG"; }

# ---- 1. guest dirs ---------------------------------------------------------
vm_run "mkdir -p $BASE/pep $BASE/res $BASE/raw"

# ---- 2. sync peptide files -------------------------------------------------
host_n=$(ls -1 "$INP/"*.pep 2>/dev/null | wc -l)
gus_n=$(vm_run "ls -1 $BASE/pep/*.pep 2>/dev/null | wc -l"); [ -z "$gus_n" ] && gus_n=0
log "pep files: host=$host_n guest=$gus_n"
if [ "$gus_n" -ne "$host_n" ]; then
  log "copyto peptide lists -> guest (this may take a few minutes)"
  vcopyto --recursive "$NEO_WIN/output/netmhcpan_input/all/." "$BASE/pep"
  gus_n=$(vm_run "ls -1 $BASE/pep/*.pep 2>/dev/null | wc -l")
  log "after copyto guest=$gus_n"
fi
if [ "$gus_n" -ne "$host_n" ]; then
  echo "FATAL: pep sync host=$host_n guest=$gus_n" > "$STATUS"; log "FATAL pep sync"; exit 3
fi

# ---- 3. runner script -> guest (LF only) -----------------------------------
vcopyto "$NEO_WIN/scripts/vm_full_runner.sh" "$BASE/run_full.sh"
vm_run "sed -i 's/\r\$//' $BASE/run_full.sh; chmod +x $BASE/run_full.sh"

# ---- 4. launch detached (single-instance enforced by flock in the runner) ---
launch_runner(){
  vm_run "cd $BASE && (setsid nohup bash run_full.sh >> $BASE/driver.log 2>&1 < /dev/null &) ; echo launch_issued"
}
if [ -z "$(vm_run "pgrep -f '[r]un_full.sh' | head -1")" ]; then
  launch_runner; log "guest runner launched"
else
  log "guest runner already running"
fi

# ---- 5. monitor loop -------------------------------------------------------
last=-1; last_change=$(date +%s)
while true; do
  st=$(vm_run "n=\$(ls -1 $BASE/res/*.done 2>/dev/null|wc -l); t=\$(ls -1 $BASE/pep/*.pep|wc -l); a=\$(grep -c ALLDONE $BASE/run.log 2>/dev/null); r=\$(pgrep -f '[r]un_full.sh' | wc -l); echo \$n \$t \$a \$r")
  n=$(echo "$st" | awk '{print $1}'); t=$(echo "$st" | awk '{print $2}')
  a=$(echo "$st" | awk '{print $3}'); r=$(echo "$st" | awk '{print $4}')
  [ -z "${n:-}" ] && n=0; [ -z "${a:-}" ] && a=0; [ -z "${r:-}" ] && r=0
  [ -z "${t:-}" ] && t=$host_n; [ "$t" -gt 0 ] || t=$host_n

  # mirror the guest per-allele log verbatim
  vcopyfrom "$BASE/run.log" "$RUNLOG_WIN"
  # mirror newly-completed alleles (result + marker)
  for s in $(vm_run "ls -1 $BASE/res/*.done 2>/dev/null"); do
    b=$(basename "$s" .done)
    if [ ! -f "$PA/$b.done" ]; then
      vcopyfrom "$BASE/res/$b.tsv" "$PA_WIN/$b.tsv"
      vcopyfrom "$BASE/res/$b.done" "$PA_WIN/$b.done"
    fi
  done
  hist=$(ls -1 "$PA"/*.done 2>/dev/null | wc -l)
  pct=$(( n * 100 / t ))
  log "progress guest=$n/$t ${pct}% ALLDONE=$a runner_procs=$r host_mirrored=$hist"

  # self-healing: keep exactly one runner alive while work remains (flock makes this safe)
  if [ "$r" -eq 0 ] && [ "$n" -lt "$t" ]; then
    launch_runner; log "runner not alive (n=$n/$t) -> (re)launched"
  fi

  [ "$n" != "$last" ] && { last=$n; last_change=$(date +%s); }

  if [ "$n" -ge "$t" ] && [ "$a" -ge 1 ]; then
    vcopyfrom_dir "$BASE/res/." "$PA_WIN"
    nd=$(ls -1 "$PA"/*.done 2>/dev/null | wc -l)
    log "COMPLETE: host per_allele done=$nd / $t"
    printf 'DONE %s  per_allele=%s/%s\n' "$(date '+%F %T')" "$nd" "$t" > "$STATUS"
    exit 0
  fi

  if [ $(( $(date +%s) - last_change )) -gt 1800 ]; then
    log "WARN: no progress for >30min (n=$n/$t runner_procs=$r) -- check guest"
    last_change=$(date +%s)
  fi
  sleep "$POLL"
done

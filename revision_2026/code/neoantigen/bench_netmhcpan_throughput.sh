#!/bin/bash
# Controlled throughput benchmark, single process at a time, run AFTER the
# pilot batch so there is no CPU contention.
cd /home/nmuser/netMHCpan-4.2/test || exit 1
NM=/home/nmuser/netMHCpan-4.2/netMHCpan
B=/home/nmuser/nmwork/bench
mkdir -p $B

make_rand() {  # $1 = outfile, $2 = length, $3 = seed
  awk -v L=$2 -v sd=$3 'BEGIN{srand(sd); aa="ACDEFGHIKLMNPQRSTVWY";
    for(i=0;i<10000;i++){s=""; for(j=0;j<L;j++) s=s substr(aa,int(rand()*20)+1,1); print s}}' > $1
}
make_rand $B/r9.pep  9  7
make_rand $B/r10.pep 10 9
awk 'BEGIN{srand(11); aa="ACDEFGHIKLMNPQRSTVWY";
  for(i=0;i<10000;i++){L=(i%2)?9:10; s=""; for(j=0;j<L;j++) s=s substr(aa,int(rand()*20)+1,1); print s}}' > $B/rmix.pep
head -10000 /home/nmuser/nmwork/pep/HLA-A02_01.pep > $B/real.pep

echo "length composition of real.pep:"; awk '{print length($0)}' $B/real.pep | sort | uniq -c

run() {  # $1 = label, $2 = file, $3 = extra args
  t0=$(date +%s%N)
  $NM -p "$2" -a HLA-A02:01 $3 >/dev/null 2>&1
  rc=$?
  t1=$(date +%s%N)
  ms=$(( (t1-t0)/1000000 ))
  printf '%-26s %-12s rc=%s  %6d ms  %.3f ms/pep\n' "$1" "$3" "$rc" "$ms" \
     "$(awk -v m=$ms 'BEGIN{printf "%.4f", m/10000}')"
}

echo "--- single-process, 10,000 peptides each, allele HLA-A02:01 ---"
run "random 9-mers  -BA"    $B/r9.pep   "-BA"
run "random 9-mers  (no -BA)" $B/r9.pep ""
run "random 10-mers -BA"    $B/r10.pep  "-BA"
run "random mixed 9/10 -BA" $B/rmix.pep "-BA"
run "REAL mut peptides -BA" $B/real.pep "-BA"
run "REAL mut peptides (no -BA)" $B/real.pep ""
run "REAL mut peptides -BA (repeat)" $B/real.pep "-BA"
echo "BENCHMARK_DONE $(date -Is)"

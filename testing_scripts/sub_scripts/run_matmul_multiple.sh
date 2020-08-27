#!/bin/bash
set -u
if [ $# -lt 5 ]; then
	echo "usage: $0 blockM blockB #nodes wall-time #iterations" >&2
	echo -e "\twall-time in minutes" >&2
	exit 1
fi
blockM="${1}"
blockB="${2}"
nnodes="${3}"
wtime="${4}"
niter="${5}"
EXE_DIR="matmul"
EXE="${EXE_DIR}"/matmul.py
logdir="${HOME}"
workerwd=scratch
masterwd=scratch
tmpfile=`mktemp`
opt_enqueue="--exec_time=${wtime} --master_working_dir='${masterwd}' --base_log_dir='${logdir}' --worker_working_dir='${workerwd}' --worker_in_master_cpus=0 --pythonpath='${EXE_DIR}' --lang=python"
enqueue_compss --num_nodes="${nnodes}" ${opt_enqueue} "${EXE}" "${blockM}" "${blockB}" | tee "$tmpfile"
# Modify job submission file
iters=(`seq 2 ${niter}`)
string="Temp submit script is: "
if [ -n "${iters:-}" ]; then
	newsubfile=`mktemp`
	oldsubfile=`grep "$string" "$tmpfile" | sed -e "s/$string//"`
	cmd=`grep launch_compss "$oldsubfile"`
	new_cmd=`echo "$cmd" | sed -e "s|$cmd|for iter in ${iters[@]}\; do mkdir -p '${logdir}'\; & \; cleanup_shma \; done|" -e 's,'"'${logdir}'"',&/tmp/${iter},g'`
	sed -e "s|${cmd}|${new_cmd}|" "$oldsubfile" > "$newsubfile"
	bsub < "$newsubfile"
fi
rm "$tmpfile"

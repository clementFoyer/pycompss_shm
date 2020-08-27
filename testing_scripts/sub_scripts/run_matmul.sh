#!/bin/bash
if [ $# -lt 4 ]; then
	echo "usage: $0 blockM blockB #nodes wall-time [<tracing> [debug-flag [matrix-identity]]]" >&2
	echo -e "\twall-time in minutes\n\ttracing as a boolean ('true' or 'false'). Default: 'true'." >&2
	exit 1
fi
blockM="${1}"
blockB="${2}"
nnodes="${3}"
wtime="${4}"
tracing="${5:-true}"
debug="${6}"
EXE_DIR="matmul"
EXE="${EXE_DIR}"/matmul.py
logdir="${HOME}"
if [ -n "$debug" -o "true" == "$tracing" ]; then
	jvm_workers_opts='-Dcompss.worker.removeWD=false'
	jvm_workers_opts=''
fi
workerwd=scratch
#workerwd="${logdir}"
masterwd=scratch
#masterwd="${logdir}"
opt_enqueue="${debug} --exec_time=${wtime} --tracing='${tracing}' --master_working_dir='${masterwd}' --base_log_dir='${logdir}' --worker_working_dir='${workerwd}' --worker_in_master_cpus=0 --jvm_workers_opts='$jvm_workers_opts' --pythonpath='${EXE_DIR}' --lang=python"
enqueue_compss --num_nodes="${nnodes}" ${opt_enqueue} "${EXE}" "${blockM}" "${blockB}" ${7:+true}

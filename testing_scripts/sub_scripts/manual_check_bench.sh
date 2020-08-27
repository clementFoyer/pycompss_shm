#!/bin/bash
set -eu
if [ $# -ne 4 ]; then
	echo "usage: $0 file_for_results.res file_for_raw_timings.csv [matmul|kmeans] \"[jobids]bench-id:p1:p2:nnodes:(with|without):job-id1(,job-id2...)\"" 1>&2
	exit 1
fi
vars=($(echo "${4#\[jobids\]}" | sed -e 's/:/ /g'))
scripts/sub_scripts/check_benchs.sh "${1}" "${2}" "`printf "bench%02d (%-7s shm):" "${vars[0]}" "${vars[4]}"`" ${3} ${vars[@]:1:3} `echo ${vars[5]} | sed 's/,/ /g'`

#!/bin/bash

function usage() {
	echo "usage: $1 resfile csvfile \"header\" matmul bm bb nnodes jobid1 [jobid2 [...]]"
	echo "usage: $1 resfile csvfile \"header\" kmeans #points maxiter #dimensions #centers #fragments nnodes jobid1 [jobid2 [...]]"
}

function check_num_param() {
	local script="$1"
	local nparamexp=$2
	local nparam=$3
	if [ $nparam -lt $nparamexp ]; then
		usage "$script" 1>&2
		exit 1
	fi
}

check_num_param "$0" 4 $#

outfile="$1"
csvfile="$2"
header="$3"
btype="$4"
shift 4
# format parameter output depending on the bench
case "$btype" in
	matmul)
		check_num_param "$0" 4 $#
		bm=$1
		bb=$2
		param_format="blocks: ${bm}x${bm}, block-size: ${bb}x${bb}"
		csv_format="${bm},${bb}"
		shift 2
		;;
	kmeans)
		check_num_param "$0" 7 $#
		points=$1
		maxiter=$2
		dims=$3
		centers=$4
		frags=$5
		param_format="npoints: ${points}, max. iter: ${maxiter}, ${dims}d, ${centers} centres, ${frags} frags"
		csv_format="${points},${maxiter},${dims},${centers},${frags}"
		shift 5
		;;
	*)
		echo "unknown bench type \"$btype\"."
		usage "$0" 1>&2
		exit 1
		;;
esac
nnodes=$1
WD=/gpfs/projects/bsc19/"${USER}"
# Check whether it is with or without shm
with=`echo "${header}" | grep -o "with\|without"`
shift 1
sum=0
num=0
for jobid in $@; do
	runtimes=(`grep 'time:' "${WD}"/compss-${jobid}.out | sed 's/.*[[:space:]]\+\([[:digit:]]\+\.[[:digit:]]\+\)[[:space:]]\+s$/\1/'`)
	for runtime in "${runtimes[@]}"; do
		((num += 1))
		sum=$(echo "scale=8;${sum:-0} + ${runtime:-0}" | bc)
		if [ 1 -eq `echo "scale=10;${runtime:-0} > 0" | bc` ]; then
			echo "${csv_format},${nnodes},${with},${runtime}" >> "${csvfile}"
		fi
	done
done
avg=$(echo "scale=8;${sum:-0}/$num" | bc)
if [ 0 -eq `echo "scale=8;0 < ${avg}" | bc` ]; then
	avg="#ERROR!"
fi
sed -i -e "s/${header}/& $avg s - ${param_format}, #nodes: ${nnodes} (${num} iter)/" "$outfile"

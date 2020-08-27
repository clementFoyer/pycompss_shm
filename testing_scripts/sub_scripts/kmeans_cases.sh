#!/bin/bash

# mandatory variables:
#   * with

ncenters=4
nfragments=16
ndimensions=4

function run_kmeans() {
	local points=$1
	local maxiter=$2
	local nnodes=$3
	local wtime=$4
	local tracing=${5:-$tracing}
	local niters=${6:-1}
	local debug="${7:-}"
	echo "## With${with} SHMA, ${points} points, ${maxiter} maximum iteration on ${nnodes} nodes"
	for iter in `seq 1 ${niters}`; do
		"${sub_scriptdir}"/run_kmeans.sh "${nnodes}" "${wtime}" "${tracing}" -n "${points}" -i "${maxiter}" -d ${ndimensions} -c ${ncenters} -f ${nfragments}
	done
}

function run_kmeans_batch() {
	local points=$1
	local maxiter=$2
	local nnodes=$3
	local wtime=$4
	local niters=${6:-1}
	echo "## With${with} SHMA, ${points} points, ${maxiter} maximum iteration on ${nnodes} nodes"
	"${sub_scriptdir}"/run_kmeans_multiple.sh "${nnodes}" "$((${niters}*${wtime}))" "${niters}" -n "${points}" -i "${maxiter}" -d ${ndimensions} -c ${ncenters} -f ${nfragments}
}

function process_bench_kmeans() {
	local benchid=$1
	shift 1
	local points=$1
	local maxiter=$2
	local nnodes=$3
	local niters=$6
	local tmp=`mktemp`
	run_kmeans_batch $@ | tee "${tmp}"
	# Enqueue result gathering
	local res_file="${outfile%.out}.res"
	local csv_file="${outfile%.out}.csv"
	local header="bench${benchid} (with${with:-   } shm):"
	local idx=(`${batch_sched}_get_idx "$tmp"`)
	local deps=`IFS=':' && echo "${idx[*]}"`
	echo "$header" >> "$res_file"
	local batch_cmd=`${batch_sched}_get_batch_cmd "$deps"`
	$batch_cmd "${sub_scriptdir}"/check_benchs.sh "$res_file" "$csv_file" "$header" kmeans $points $maxiter $ndimensions $ncenters $nfragments $nnodes ${idx[@]}
	rm "${tmp}"
	# Report the jobid's to the ${outfile}
	# #points:maxiter:#nodes:[with|without]:jobids
	echo "[jobids]${benchid}:$points:$maxiter:$ndimensions:$ncenters:$nfragments:$nnodes:with${with}:`IFS=',' && echo "${idx[*]}"`"
}

function run_bench_kmeans_select() {
	local iters=50
	local tracing=false
	local benchid="$1"
	ncenters=4
	ndimensions=64
	case "$benchid" in
		01)
			local points=$((2**22)) maxiter=20 nnodes=2 tw=5
			ncenters=1
			;;
		02)
			local points=$((2**22)) maxiter=50 nnodes=2 tw=40
			;;
		03)
			local points=$((2**22)) maxiter=20 nnodes=2 tw=20
			;;
		04)
			local points=$((2**22)) maxiter=20 nnodes=2 tw=30
			ndimensions=128
			;;
		05)
			local points=$((2**11)) maxiter=20 nnodes=2 tw=5
			;;
		06)
			local points=$((2**23)) maxiter=20 nnodes=2 tw=40
			;;
		07)
			local points=$((2**15)) maxiter=20 nnodes=2 tw=15
			;;
		08)
			local points=$((2**18)) maxiter=20 nnodes=2 tw=25
			;;
		09)
			local points=$((2**20)) maxiter=20 nnodes=2 tw=30
			;;
		10)
			local points=$((2**22)) maxiter=20 nnodes=2 tw=15
			ncenters=2
			;;
		11)
			local points=$((2**19)) maxiter=20 nnodes=2 tw=10
			;;
		12)
			local points=$((2**21)) maxiter=20 nnodes=2 tw=10
			;;
		13)
			local points=$((2**25)) maxiter=20 nnodes=2 tw=160 iters=15
			;;
		14)
			local points=$((2**24)) maxiter=20 nnodes=2 tw=80 iters=30
			;;
		15)
			local points=$((2**22)) maxiter=20 nnodes=2 tw=30
			ncenters=3
			;;
		16)
			local points=$((2**22)) maxiter=20 nnodes=2 tw=50
			ncenters=5
			;;
		*)
			echo "Invalid bench number: \"$benchid\""
			return 1
			;;
	esac
	process_bench_kmeans "$benchid" $points $maxiter $nnodes $tw $tracing $iters
}

function run_bench_kmeans() {
	local select=(01 02 03 04 05 06)
	if [ 1 -le $# ]; then
		select=($@)
	fi
	for b in ${select[*]}; do
		run_bench_kmeans_select $b
	done
}

function run_batch_kmeans() {
	ncenters=4
	ndimensions=128
	run_kmeans $((2**22)) 20 2 60 true
}

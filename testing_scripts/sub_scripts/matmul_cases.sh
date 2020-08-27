#!/bin/bash

function run_matmul() {
	local blockM=$1
	local blockB=$2
	local nnodes=$3
	local wtime=$4
	local tracing=${5:-$tracing}
	local niters=${6:-1}
	local debug="${7:-}"
	echo "## With${with} SHMA, ${blockM}x${blockM} blocks of ${blockB}x${blockB} ${nnodes} nodes"
	for iter in `seq 1 ${niters}`; do
		"${sub_scriptdir}"/run_matmul.sh "${blockM}" "${blockB}" "${nnodes}" "${wtime}" "${tracing}" $debug
	done
}

function run_matmul_batch() {
	local blockM=$1
	local blockB=$2
	local nnodes=$3
	local wtime=$4
	local niters=${6:-1}
	echo "## With${with} SHMA, ${blockM}x${blockM} blocks of ${blockB}x${blockB} ${nnodes} nodes"
	"${sub_scriptdir}"/run_matmul_multiple.sh "${blockM}" "${blockB}" "${nnodes}" "$((${niters}*${wtime}))" "${niters}"
}

function process_bench_matmul() {
	local benchid=$1
	shift 1
	local bm=$1
	local bb=$2
	local nnodes=$3
	local niters=$6
	local tmp=`mktemp`
	run_matmul_batch $@ | tee "${tmp}"
	# Enqueue result gathering
	local res_file="${outfile%.out}.res"
	local csv_file="${outfile%.out}.csv"
	local header="bench${benchid} (with${with:-   } shm):"
	local idx=(`${batch_sched}_get_idx "$tmp"`)
	local deps=`IFS=':' && echo "${idx[*]}"`
	echo "$header" >> "$res_file"
	local batch_cmd=`${batch_sched}_get_batch_cmd "$deps"`
	$batch_cmd "${sub_scriptdir}"/check_benchs.sh "$res_file" "$csv_file" "$header" matmul $bm $bb $nnodes ${idx[@]}
	rm "${tmp}"
	# Report the jobid's to the ${outfile}
	# #blocks:block-size:#nodes:[with|without]:jobids
	echo "[jobids]${benchid}:$bm:$bb:$nnodes:with${with}:`IFS=',' && echo "${idx[*]}"`"
}

function run_bench_matmul_select() {
	local iters=50
	local tracing=false
	local benchid="$1"
	case "$benchid" in
		01)
			local bm=8 bb=128 nnodes=2 tw=5
			;;
		02)
			local bm=16 bb=128 nnodes=2 tw=10
			;;
		03)
			local bm=16 bb=512 nnodes=2 tw=15
			;;
		04)
			local bm=16 bb=1024 nnodes=2 tw=10
			;;
		05)
			local bm=16 bb=1024 nnodes=4 tw=20
			;;
		06)
			local bm=24 bb=128 nnodes=2 tw=10
			;;
		07)
			local bm=24 bb=512 nnodes=2 tw=15
			;;
		08)
			local bm=24 bb=1024 nnodes=2 tw=25
			;;
		09)
			local bm=24 bb=1024 nnodes=4 tw=20
			;;
		10)
			# local bm=32 bb=128 nnodes=2 tw=20
			;;
		11)
			local bm=8 bb=512 nnodes=2 tw=10
			;;
		12)
			local bm=12 bb=128 nnodes=2 tw=10
			;;
		13)
			local bm=12 bb=512 nnodes=2 tw=15
			;;
		14)
			local bm=20 bb=128 nnodes=2 tw=10
			;;
		15)
			local bm=20 bb=512 nnodes=2 tw=10
			;;
		16)
			# total memory footprint should be about 195 GB. Need to free the matrices over time to do so.
			# local bm=16 bb=8192 nnodes=4 tw=120 # -> 128kx128k double. not sure we will be able to do it...
			;;
		20)
			local bm=8 bb=1024 nnodes=2 tw=5
			;;
		21)
			local bm=16 bb=1024 nnodes=2 tw=10
			;;
		22)
			local bm=20 bb=1024 nnodes=2 tw=15
			;;
		23)
			local bm=24 bb=1024 nnodes=2 tw=25
			;;
		24)
			local bm=8 bb=2048 nnodes=2 tw=5
			;;
		25)
			local bm=16 bb=2048 nnodes=2 tw=30
			;;
		26)
			local bm=20 bb=2048 nnodes=2 tw=55
			;;
		27)
			# /!\ LOOOOOOOONG: up to 1h30... /!\
			local bm=24 bb=2048 nnodes=2 tw=90
			;;
		28)
			local bm=8 bb=4096 nnodes=2 tw=20
			;;
		29)
			local bm=16 bb=4096 nnodes=2 tw=120
			;;
		30)
			local bm=20 bb=4096 nnodes=2 tw=20
			;;
		31)
			local bm=24 bb=4096 nnodes=2 tw=25
			;;
		32)
			local bm=12 bb=1024 nnodes=2 tw=10
			;;
		33)
			local bm=12 bb=2048 nnodes=2 tw=20
			;;
		34)
			local bm=12 bb=4096 nnodes=2 tw=60
			;;
		35)
			local bm=20 bb=128 nnodes=2 tw=15
			;;
		36)
			local bm=24 bb=128 nnodes=2 tw=15
			;;
		*)
			echo "Invalid bench number: \"$benchid\""
			return 1
			;;
	esac
	process_bench_matmul "$benchid" $bm $bb $nnodes $tw $tracing $iters
}

function run_bench_matmul() {
	local select=(02 03 04 05 06 07 08 09 10)
	if [ 1 -le $# ]; then
		select=($@)
	fi
	for b in ${select[*]}; do
		run_bench_matmul_select $b
	done
}

function run_batch_matmul() {
	run_matmul 8 512 2 60 true
	run_matmul 8 2048 2 60 true
}


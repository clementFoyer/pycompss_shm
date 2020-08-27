#!/bin/bash

set -e

tracing=false
outfile="${HOME}/run_tests.$(date -I'second').out"
sub_scriptdir="$(dirname "$0")"/sub_scripts

source "${sub_scriptdir}"/utils.sh # Has to be sourced first
source "${sub_scriptdir}"/matmul_cases.sh
source "${sub_scriptdir}"/kmeans_cases.sh

function usage() {
	echo "usage: $1 [batch|bench] [matmul|kmeans]"
}

case "${1}" in
	batch|bench)
		cmd="$1"
	;;
	*)
		usage "$0" >&2
		exit 1
	;;
esac

case "${2}" in
	matmul|kmeans)
		btype="$2"
	;;
	*)
		usage "$0" >&2
		exit 1
	;;
esac

shift 2

set -u

with=""
get_batch_sched
for shma_enabled in 1 0; do
	if [ ${shma_enabled} -eq 0 ]; then
		with=out
	fi
	export COMPSS_SHAREDARRAY_ENABLED=${shma_enabled}
	run_${cmd}_${btype} $@ | tee -a "${outfile}"
done

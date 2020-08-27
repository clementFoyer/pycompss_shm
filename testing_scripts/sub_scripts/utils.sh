#!/bin/bash

set -e

logdir="${HOME}"

# mandatory variables:
#   * tracing
#   * outfile
#   * sub_scriptdir

function get_batch_sched() {
	if [ -n "`which sbatch 2>/dev/null`" ]; then
		batch_sched=slurm
	elif [ -n "`which bsub 2>/dev/null`" ]; then
		batch_sched=lsf
	elif [ -n "`which qsub 2>/dev/null`" ]; then
		batch_sched=pbs
	fi
}

# Slurm
function slurm_get_idx() {
	local tmp="$1"
	local re='Submitted batch job '
	grep "${re}" "${tmp}" | sed "s/${re}//"
}

function slurm_get_batch_cmd() {
	local deps="$1"
	echo "sbatch -n 1 --dependency=\"afterany:$deps\""
}

# LSF
function lsf_get_idx() {
	local tmp="$1"
	local re='is submitted to default queue'
	grep "${re}" "${tmp}" | sed "s/Job <\([[:digit:]]\{1,\}\)> ${re} .*/\1/"
}

function lsf_get_batch_cmd() {
	local deps=`echo "${1}" | sed 's/:/) -w ended(/g'`
	echo "bsub -n 1 -w ended($deps) -W 5 -q bsc_cs -J check_compss -oo ${logdir}/compss-%J.out -eo ${logdir}/compss-%J.err"
}

# PBS
function pbs_get_idx() {
	local tmp="$1"
	local re='Submitted batch job '
	grep "${re}" "${tmp}" | sed "s/${re}//"
}

function pbs_get_batch_cmd() {
	local deps=`echo "$1" | sed 's/:/,/g'`
	echo "sbatch -l nodes=1 -hold_jid \"$deps\""
}


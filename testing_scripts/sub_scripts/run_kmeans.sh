#!/bin/bash -e

if [ $# -lt 3 ]; then
	echo "usage: $0 #nodes wall-time [<tracing>] [application parameters]" >&2
	echo -e "\twall-time in minutes\n\ttracing as a boolean ('true' or 'false'). Default: 'true'." >&2
	exit 1
fi

  # Define script variables
  appPythonpath="kmeans"
  execFile="${appPythonpath}"/kmeans.py

  WORKER_WORKING_DIR=scratch
  logdir="${HOME}"/debug

  # Retrieve arguments
  numNodes=$1
  executionTime=$2
  tracing=$3

  # Leave application args on $@
  shift 3

  # Enqueue the application
  enqueue_compss \
    --queue=debug \
    --num_nodes=$numNodes \
    --exec_time=$executionTime \
    --master_working_dir=$WORKER_WORKING_DIR \
    --worker_working_dir=$WORKER_WORKING_DIR \
    --base_log_dir=$logdir \
    --pythonpath=$appPythonpath \
    --lang=python \
    --tracing=$tracing \
    $execFile $@

  # $@ should contain all the app arguments
  # The available app arguments are:
  # -s / --seed Pseudo random seed
  # -n / --num_points Number of points
  # -d / --dimensions Dimensions of the points
  # -c / --centres Number of centres
  # -f / --fragments Number of fragments
  # -m / --mode Uniform or normal
  # -i / --iterations Number of MAXIMUM iterations
  # -e / --epsilon Epsilon tolerance
  # -l / --lnorm Norm of vectors (l1 or l2)
  # --plot_result Plot clustering. Only works if dimensions = 2
  # --use_storage

  # ./launch.sh None 3 5 16 false 160 3 4 4

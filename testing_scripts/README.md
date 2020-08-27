# Run benchmarks for matrix multiplication:

```bash
./run_tests.sh bench matmul
```

`run_tests.sh` requires to be run with an installed version of COMPSs
from branch 'add-shared-memory-arrays' from the
[repository](http://compss.bsc.es/gitlab/compss/framework). The current
version may need to be rebase on the current trunk. The module file from
[TrunkSHMA](TrunkSHMA) is an example of a working
module file for this version of COMPSs.

Each execution is run with or without the export of the environment
variable `COMPSS_SHAREDARRAY_ENABLED` with value 0 or 1, to enable or
disable the usage of shared memory, respectively.

`./run_tests.sh` generate a file named `run_tests.YYYY-MM-DDTHH:MM:SS+diff.out`.
This file contains all the output that have been generated in while
enqueuing the tasks.

In addition to all the bench launched, on extra task is started to pick
up the times of each execution and return the average timing in the file
`run_tests.YYYY-MM-DDTHH:MM:SS+diff.res`, in addition of the parameter of each
test case.

Finally all the times are gathered into the corresponding file named
`run_tests.YYYY-MM-DDTHH:MM:SS+diff.csv`, ready to be imported in order to
process data.

Each timing can be found as well by grepping the proper files on the line
starting with "time: ". The timings are given in seconds. The indices of
the jobs corresponding to a test case can be found in
`run_tests.YYYY-MM-DDTHH:MM:SS+diff.out`.

  * Given one jobid, to find the timing:
    * `grep 'time:' <jobid>`
    * The value can be extracted with
      * `sed 's/time:[[:space:]]\{1,\}\([[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\)[[:space:]]\{1,\}s/\1/'`
  * Given the output file, to find all the relevant jobids:
    * `grep '[jobids]' run_tests.YYYY-MM-DDTHH:MM:SS+diff.out`
        The line contains all the parameters of the test case in addition
        to the jobids. The line can be parsed with each parameters being
        separated with ':'. The format is:
          * `num-blocks-in-1D:size-block-in-1D:number-of-nodes:with/without:jobids`
        The sizes are given for one dimension only as the matrix is
        considered to be square.

/!\ WARNING: The extraction of the timings may fail on MacOSX because of
the syntax of the option `-i` from the sed program. For MacOSX, line 18
of [./sub_scripts/check_benchs.sh] has to be changed to add `''` between
the `-i` and the `-e` in order to avoid having the creation of the
back-up file.

All the tests are run on square matrices, on at least 2 nodes, with no worker on
the master CPUs. By default, the working dir in "${HOME}". This can be changed
in [run_matmul.sh script file](./sub_scripts/run_matmul.sh) at line 15 (variable
name `logdir`). If working dir is changed in `run_matmul.sh`, remember to change
it in [check_benchs.sh](./sub_scripts/check_benchs.sh) at line 53 as well
(variable name `WD`) and in
[check_benchs_multiple.sh](./sub_scripts/check_benchs_multiple.sh).

The tests cases are the following listed in
[matmul_cases.sh](../sub_scripts/matmul_cases.sh):

Each case is run with and without the usage of the SHM (shared memory) module.
The failing cases should have "#ERROR!" reported as the average timing.
Hopefully, either all benches will run for each test-case or none of them
(so the computation of the average does not break).

You can check the validity of the blocked matrix-multiplication python
script by calling `sub_scripts/run_matmul.sh blockM blockB nnodes wtime tracing debug ident`
where:
  - **blockM** is the number of blocks.
  - **blockB** is the size of each block (in number of doubles).
  - **nnodes** is the number of nodes used.
  - **wtime** is the wall-time for the application execution.
  - **tracing** is either `true` or `false` (without the quotes),
      depending on whether you want to generate the traces.
  - **debug** is an optional final `-d` (without the quotes).
  - **ident** is anything that would trigger the running of the
      [matmul.py](matmul/matmul.py)
      where the multiplication is done between a random and an identity matrix.

# Run benchmark for kmeans

```bash
./run_tests.sh bench matmul
```
The prerequisites are the same as for the matrix multiplication case, and it
creates the same 3 files, .out, .res and .csv.

You can manually call the kmeans application script with
`sub_scripts/run_kmeans.sh <#NODES> <WALLTIME> <TRACING> -n <NUM_POINTS> -d
<DIMENSIONS> -c <CENTRES> -f <FRAGMENTS>`

    - Where:
        <TRACING>............... Enable or disable tracing ( true | false )
        <NUM_POINTS>............ Number of points
        <DIMENSIONS>............ Number of dimensions
        <CENTRES>............... Number of centres
        <FRAGMENTS>............. Number of fragments

     - Other available options:
         -s <SEED>.............. Define a seed
         -m <MODE>.............. Distribution of points ( uniform | normal )
         -i <ITERATIONS>........ Maximum number of iterations
         -e <EPSILON>........... Epsilon value. Convergence value.
         -l <NORM>.............. Norm for vectors ( l1 | l2 )
         --plot_result.......... Plot the resulting clustering (only for 2D)



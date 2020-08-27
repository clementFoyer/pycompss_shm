Structure of the archive:

pycompss_shm/
├── README.txt
├── Trunkcfoyer
├── compss
├── install_compss.sh
├── kmeans_results
│   ├── README.txt
│   └── ...
├── matmul_results
│   ├── README.txt
│   └── ...
├── results.R
└── testing_scripts
    ├── README.md
    ├── TrunkSHMA
    ├── kmeans
    │   ├── README
    │   └── kmeans.py
    ├── matmul
    │   ├── README
    │   └── matmul.py
    ├── run_tests.sh
    └── sub_scripts
        ├── check_benchs.sh
        ├── kmeans_cases.sh
        ├── manual_check_bench.sh
        ├── matmul_cases.sh
        ├── run_kmeans.sh
        ├── run_kmeans_multiple.sh
        ├── run_matmul.sh
        ├── run_matmul_multiple.sh
        └── utils.sh

kmeans_results and matmul_results contain the resulting files from the bench
application scripts. .csv files contain the raw times with the corresponding
parameters, and the .res files contain basic summarized results.

The tests were run with Python 2.7.3 and Java 1.8.0_112. COMPSs version was a
development version at commit
[d4cf73dd66ea1a1af8b63d00a51685623d964489](https://github.com/bsc-wdc/compss/tree/add-shared-memory-arrays).

results.R is a RStudio script (version used: Version 1.1.447 – © 2009-2018
RStudio, Inc.), that contain the functions used to aggregate the results,
process data and generate the output images.

You may need to adapt the working directory path on [results.R](./results.R), at
line 22 in order to use the provided script.

Two main data processing have been used, mainly Welsh's t-test to evaluate the
statistical significance of the results, and the generation of box plots to have
a glimpse at the distribution of data.

Note that not all generated images are used. In addition, RStudio is also used
to generate the LaTeX tables presenting the results for the article. However,
the code generated have been modified for a better presentation of the results.

In order to install the version of PyCOMPSs used in the paper, you have to clone
the repository with the following command:

```bash
install_compss.sh
```

Please note that you may have to may have to adapt the line line 13 of the
[install_compss.sh script](./install_compss.sh) in order to have the framework
properly installed on any platform. However, please note that this version
installation process does not differ from the normal COMPSs installation.

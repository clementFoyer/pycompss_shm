#!/usr/bin/python
#
#  Copyright 2002-2019 Barcelona Supercomputing Center (www.bsc.es)
#  Copyright 2019-2020 Cray UK Ltd., a Hewlett Packard Enterprise
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

# -*- coding: utf-8 -*-

import sys
import numpy as np

from timeit import default_timer as timer

from pycompss.api.api import compss_wait_on, compss_barrier
from pycompss.api.task import task
from pycompss.api.parameter import *


def initialize_variables(identity=False):
    import numpy as np
    for matrix in [A, B, C]:
        for i in range(MSIZE):
            matrix.append([])
            for j in range(MSIZE):
                if matrix == C:
                    block = np.array(np.zeros((BSIZE, BSIZE)),
                                     dtype=np.double, copy=False)
                elif identity and matrix == B:
                    if i == j:
                        block = np.array(np.identity(BSIZE, dtype=np.double),
                                         dtype=np.double, copy=False)
                    else:
                        block = np.array(np.zeros((BSIZE, BSIZE)),
                                         dtype=np.double, copy=False)
                else:
                    block = np.array(np.random.random((BSIZE, BSIZE)),
                                     dtype=np.double, copy=False)
                mb = np.matrix(block)
                matrix[i].append(mb)


# ## TASK SELECTION ## #

@task(a={Type: IN, RRO: True}, b={Type: IN, RRO: True}, c=INOUT)
def multiply(a, b, c):
    import numpy as np
    c += np.matrix(a)*np.matrix(b)


# ## MAIN PROGRAM ## #

if __name__ == "__main__":

    args = sys.argv[1:]

    MSIZE = int(args[0])
    BSIZE = int(args[1])

    if len(args) == 3:
        identity=True
    else:
        identity=False

    A = []
    B = []
    C = []

    initialize_variables(identity)

    begin = timer()

    for i in range(MSIZE):
        for j in range(MSIZE):
            for k in range(MSIZE):
                multiply(A[i][k], B[k][j], C[i][j])

    if identity:
        for i in range(MSIZE):
            for j in range(MSIZE):
                C[i][j] = compss_wait_on(C[i][j])
                if not np.array_equal(C[i][j], A[i][j]):
                    print('Error: bad value in array' + str(i) + str(j) + '.')
                    print("C" + str(i) + str(j) + "=" + str(C[i][j]))
                    print("A" + str(i) + str(j) + "=" + str(A[i][j]))
                    print("B" + str(i) + str(j) + "=" + str(B[i][j]))
                    exit(1)
        print('Check is valid.')
    else:
        compss_barrier()
        end = timer()
        print("time: " + str(end-begin) + " s")

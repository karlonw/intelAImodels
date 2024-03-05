#!/bin/bash
set -x
srun -n 2 --ntasks-per-node=1 --mpi=pmix -p ecb \
  singularity run --nv --bind /scratch2,/usr:/host/usr \
  /scratch2/karlon/intel-extension-for-pytorch-prebuilt:2.1.10-202401301513.sif \
  `pwd`/wrapper.sh \
  env CCL_LOG_LEVEL=info FI_LOG_LEVEL=info FI_PROVIDER=cxi \
  python `pwd`/srunmain.py --dummy 2>&1 |\
  tee out.log

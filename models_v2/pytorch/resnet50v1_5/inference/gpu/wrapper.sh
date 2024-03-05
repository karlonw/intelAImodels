#!/bin/bash

export CCL_LOG_LEVEL=info
#export CCL_ZE_IPC_EXCHANGE=sockets
export ONEAPI_ROOT=/opt/intel/oneapi/redist
export CCL_KERNEL_PATH=/opt/intel/oneapi/redist/lib/ccl/kernels/
#export ONECCL_ROOT=/opt/intel/oneapi
export CCL_ATL_TRANSPORT=ofi
#export CCL_PROCESS_LAUNCHER=pmix
#export CCL_PROCESS_LAUNCHER=torch
export CCL_PROCESS_LAUNCHER=none
export CCL_LOCAL_RANK=$SLURM_LOCALID
export CCL_LOCAL_SIZE=$SLURM_TASKS_PER_NODE

# Allow us to see xpu-smi and it's dependencies inside the container
export PATH=$PATH:/host/usr/bin
export LD_LIBRARY_PATH=/scratch2/crickett/lib/libfabric-1.21.1:$LD_LIBRARY_PATH:/host/usr/lib64
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/host/usr/lib64

export FI_MR_CACHE_MONITOR=userfaultfd
export CXI_FORK_SAFE=1
export FI_EFA_FORK_SAFE=${CXI_FORK_SAFE}

export FI_CXI_DEFAULT_TX_SIZE=1024
export FI_CXI_DISABLE_CQ_HUGETLB=1
export FI_CXI_DEFAULT_CQ_SIZE=131072
export FI_CXI_DISABLE_HOST_REGISTER=1
export FI_CXI_RX_MATCH_MODE=software
export FI_CXI_RDZV_PROTO=alt_read
#export FI_PROVIDER=^ofi_rxm,efa,ofi_rxd
#export FI_HMEM_CUDA_USE_GDRCOPY=1
export FI_CXI_REQ_BUF_SIZE=8338608
export FI_LOG_PROV=cxi
export FI_LOG_LEVEL=info
export FI_LOG_SUBSYS=domain
export FI_CXI_TELEMENTRY=pct_no_mst_nacks,pct_mst_hit_on_som,pct_sct_timeouts,pct_spt_timeouts,pct_tct_timeouts

# Try setting up the info for torch distributed from slurm to avoid
# their launch.py
# Taken from:
# https://github.com/PrincetonUniversity/multi_gpu_training/tree/main/02_pytorch_ddp
export MASTER_PORT=$(expr 10000 + $(echo -n $SLURM_JOBID | tail -c 4))
export WORLD_SIZE=$(($SLURM_NNODES * $SLURM_NTASKS_PER_NODE))
echo "WORLD_SIZE="$WORLD_SIZE
master_addr=`echo $SLURM_JOB_NODELIST | sed 's/\[//;s/-.*//;s/,.*//;s/\]//'`
export MASTER_ADDR=$master_addr
echo "MASTER_ADDR="$MASTER_ADDR

export RANK=$SLURM_PROCID
export SLURM_GPUS_ON_NODE=4

# Execute what we were told to execute
exec "${@}"

#!/bin/bash
# redirect stdout/stderr to a file
#exec &> /save/ec2-user/OWP/laura/schism_cloud_sandbox_log.txt

set -e       # exit immediately on error
set -x       # verbose with command expansion
set -u       # forces exit on undefined variables

module purge
module use -a /mnt/efs/fs1/save/environments/spack.v0.22.5/share/spack/modules/linux-rhel8-x86_64

module load intel-oneapi-compilers/2023.1.0-gcc-11.2.1-3rbcwfi
module load intel-oneapi-mpi/2021.12.1-intel-2021.9.0-6nra3z4
module load hdf5/1.14.3-intel-2021.9.0-jjst2zs
module load netcdf-c/4.9.2-intel-2021.9.0-vkckbzk
module load netcdf-fortran/4.6.1-intel-2021.9.0-cpxxwci

export FC=mpiifort
export CXX=mpiicpc
export CC=mpiicc

export I_MPI_OFI_LIBRARY_INTERNAL=0   # Using AWS EFA Fabric on AWS
export FI_PROVIDER=efa
export I_MPI_FABRICS=ofi
export I_MPI_OFI_PROVIDER=efa

export MODEL_DIR=$1
export DFLOW_LIB=$2
export EXEC=$3


export LD_LIBRARY_PATH=$DFLOW_LIB:$LD_LIBRARY_PATH

echo "NPROCS is $NPROCS"
echo "---" 
echo "------------------------"
echo "DFlowFM model working directory is $MODEL_DIR"
echo "------------------------"
cd $MODEL_DIR

SECONDS=0

echo "--- "
echo "--- Partitioning DFlowFM domain-----------------"
echo "---"

$EXEC --partition:ndomains=$NPROCS:icgsolver=7: FlowFM.mdu
result=$?
if [ $result -ne 0 ]; then
  echo "ERROR returned from $EXEC"
  exit $result
fi

echo "--- " 
echo "--- Running DFlowFM -----------------"
echo "---"

mpirun $MPIOPTS $EXEC FlowFM.mdu -autostartstop
result=$?

if [ $result -ne 0 ]; then
  echo "ERROR returned from mpirun"
  exit $result
else
  echo "DFlowFM model has succesfully completed on the cloud!"
  duration=$SECONDS
  echo "DFlowFM simulation took $((duration / 60)) minutes and $((duration % 60)) seconds elapsed."
fi

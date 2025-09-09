#!/bin/bash

# Required in order for your
# script to properly exit if an
# error is thrown within the shell
# script or model execution so the
# AWS cluster can properly shutdown
set -e       # exit immediately on error
set -x       # verbose with command expansion
set -u       # forces exit on undefined variables


# Purge current modules loaded and use latest spack
# module installations compatible with hpc7as
module purge
module use -a /mnt/efs/fs1/save/environments/spack.v0.22.5/share/spack/modules/linux-rhel8-x86_64

# User needs to load up the defined compilers and libraries
# they used for compiling their model within this block here

module load intel-oneapi-compilers/2023.1.0-gcc-11.2.1-3rbcwfi
module load intel-oneapi-mpi/2021.12.1-intel-2021.9.0-6nra3z4
module load hdf5/1.14.3-intel-2021.9.0-jjst2zs
module load netcdf-c/4.9.2-intel-2021.9.0-vkckbzk
module load netcdf-fortran/4.6.1-intel-2021.9.0-cpxxwci

# Export required variables
# for your model executable
# if required
export FC=mpiifort
export CXX=mpiicpc
export CC=mpiicc

# Define the AWS MPI options to utilize
# the efa fabric for hpc7as
export I_MPI_OFI_LIBRARY_INTERNAL=0   # Using AWS EFA Fabric on AWS
export FI_PROVIDER=efa
export I_MPI_FABRICS=ofi
export I_MPI_OFI_PROVIDER=efa

# This is where you define your 
# shell script required inputs
# to execute your model run
export MODEL_DIR=$1
export EXEC=$2


echo "---" 
echo "------------------------"
echo "Model XXX working directory is $MODEL_DIR"
echo "------------------------"
cd $MODEL_DIR

SECONDS=0
echo "--- " 
echo "--- Running MODEL XXXX -----------------"
echo "---"

##### Example model executable syntax required
#mpiexec $MPIOPTS $EXEC
result=$?

# Capture the exit/end result and propagate it down the stack.
if [ $result -ne 0 ]; then
  echo "ERROR returned from mpirun"
  exit $result
else
  echo "XXX model has succesfully completed on the cloud!"
  duration=$SECONDS
  echo "XXX model simulation took $((duration / 60)) minutes and $((duration % 60)) seconds to complete."
fi
